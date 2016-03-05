local inspect = require('util').inspect;
local strsplit = require('util.string').split;
local traceback = debug.traceback;
local tblconcat = table.concat;
local INSPECT_OPT = { depth = 0 };
local CRLF2SPC = {
    ['\r'] = ' ',
    ['\n'] = ' '
};
local NRAISE = 0;

local function getInfo()
    local info = debug.getinfo( 4 );
    local filepath = string.gsub( info.source, '^@', '' );
    local file = assert( io.open( filepath ) );
    local lineno = 1;
    
    for line in file:lines() do
        if lineno == info.currentline then
            info.caller = line;
            break;
        end
        lineno = lineno + 1;
    end
    file:close();

    info.name = debug.getinfo( 3 ).name;
    
    return info;
end

local function raiseMsg( val, msg, ... )
    local lv = 3;
    local info = getInfo();
    local raiseof;
    local backtrace = {};
    local lines = strsplit( traceback(), '[\r\n]+' )

    -- remove lines of test module
    for i = 1, #lines do
        if lines[i]:find( 'runOnSandbox', 1, true ) then
            break;
        elseif not lines[i]:find('/tryout/', 1, true ) then
            backtrace[#backtrace + 1] = lines[i];
        end
    end
    backtrace = tblconcat( backtrace, '\n' );

    -- convert CRLF to space
    val = inspect( val ):gsub( '[\r\n]', CRLF2SPC ):gsub( '[ ]+', ' ' );
    raiseof = ('raise %s on %q'):format( info.name, val );
    
    if msg == nil then
        msg = raiseof;
    elseif type( msg ) == 'string' and msg:find('%%') then
        msg = msg:format( ... );
    end
    
    error( tblconcat({
        raiseof,
        'raise from:',
        '\t' .. info.caller:gsub('^%s+',''),
        'message: ',
        '\t' .. inspect( msg ),
        backtrace
    }, '\n' ), lv );
end


local function ifNotNil( val )
    NRAISE = NRAISE + 1;
    if val ~= nil then
        raiseMsg( val );
    end
end


local function ifNil( val, msg, ... )
    NRAISE = NRAISE + 1;
    if val == nil then
        raiseMsg( val, msg, ... );
    end
    
    return val;
end


local function ifNotTrue( val, msg, ... )
    NRAISE = NRAISE + 1;
    if val ~= true then
        raiseMsg( val, msg, ... );
    end
    
    return val;
end

local function ifTrue( val, msg, ... )
    NRAISE = NRAISE + 1;
    if val == true then
        raiseMsg( val, msg, ... );
    end
    
    return val;
end


local function ifNotFalse( val, msg, ... )
    NRAISE = NRAISE + 1;
    if val ~= false then
        raiseMsg( val, msg, ... );
    end
    
    return val;
end

local function ifFalse( val, msg, ... )
    NRAISE = NRAISE + 1;
    if val == false then
        raiseMsg( val, msg, ... );
    end
    
    return val;
end


local function ifEqual( a, b, msg, ... )
    NRAISE = NRAISE + 1;
    if type( a ) == 'table' then
        if type( b ) == 'table' and 
           inspect( a, INSPECT_OPT ) == inspect( b, INSPECT_OPT ) then
            raiseMsg({ 
                a = a,
                b = b
            }, msg, ... );
        end
    elseif a == b then
        raiseMsg({
            a = a == nil and 'nil' or a,
            b = b == nil and 'nil' or b
        }, msg, ... );
    end
    
    return a, b;
end


local function ifNotEqual( a, b, msg, ... )
    NRAISE = NRAISE + 1;
    if type( a ) == 'table' then
        if type( b ) ~= 'table' or 
           inspect( a, INSPECT_OPT ) ~= inspect( b, INSPECT_OPT ) then
            raiseMsg({
                a = a,
                b = b == nil and 'nil' or b
            }, msg, ... );
        end
    elseif a ~= b then
        raiseMsg({
            a = a == nil and 'nil' or a,
            b = b == nil and 'nil' or b
        }, msg, ... );
    end

    return a, b;
end


_G.raise = {};
for k,v in pairs({
    ifNotNil = ifNotNil,
    ifNil = ifNil,
    ifNotTrue = ifNotTrue,
    ifTrue = ifTrue,
    ifNotFalse = ifNotFalse,
    ifFalse = ifFalse,
    ifEqual = ifEqual,
    ifNotEqual = ifNotEqual
}) do
    _G.raise[k] = v;
    _G.TRYOUT_SANDBOX[k] = v;
end

_G.raise.nraise = function()
    local n = NRAISE;
    NRAISE = 0;
    return n;
end

