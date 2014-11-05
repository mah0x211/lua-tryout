local inspect = require('util').inspect;
local CRLF2SPC = {
    ['\r'] = ' ',
    ['\n'] = ' '
};
local NRAISE = 0;

local function getInfo()
    local info = debug.getinfo( 4 );
    local file = assert( io.open( info.short_src ) );
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
    
    val = inspect( val ):gsub( '[\r\n]', CRLF2SPC ):gsub( '[ ]+', ' ' );
    raiseof = ('raise %s on %q'):format( info.name, val );
    
    if msg == nil then
        msg = raiseof;
    elseif type( msg ) == 'string' and msg:find('%%') then
        msg = msg:format( ... );
    end
    
    error( table.concat({
        raiseof,
        'raise from:',
        '\t' .. info.caller:gsub('^%s+',''),
        'message: ',
        '\t' .. msg
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


local function ifFalse( val, msg, ... )
    NRAISE = NRAISE + 1;
    if val == false then
        raiseMsg( val, msg, ... );
    end
    
    return val;
end

local function ifNotEqual( a, b, msg, ... )
    NRAISE = NRAISE + 1;
    if a ~= b then
        raiseMsg( { a = a, b = b == nil and 'nil' or b }, msg, ... );
    end
end

_G.raise = {};
for k,v in pairs({
    ifNotNil = ifNotNil,
    ifNil = ifNil,
    ifNotTrue = ifNotTrue,
    ifTrue = ifTrue,
    ifFalse = ifFalse,
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

