local inspect = require('util').inspect;
local MODULE_DIR = require('path').dirname( debug.getinfo( 1 ).short_src );
local PRINT_FN = print;
local logstack = {};
local unpack = unpack or table.unpack;

local function printHook( ... )
    local date = os.date('%Y/%m/%dT%T');
    local info = debug.getinfo( 2 );
    
    if info.short_src:find( '^' .. MODULE_DIR ) then
        local args = {...};
        
        args[1] = ('%s'):format( tostring( args[1] ) or '' );
        PRINT_FN( unpack( args ) );
    else
        PRINT_FN( ... );
        logstack[#logstack+1] = {
            info = info,
            date = date,
            log = {...}
        };
    end
end

local function printf( fmt, ... )
    local date = os.date('%Y/%m/%dT%T');
    local info = debug.getinfo( 2 );
    
    if #{...} > 0 then
        fmt = fmt:format( ... );
    else
        fmt = inspect( fmt );
    end
    
    if info.short_src:find( '^' .. MODULE_DIR ) then
        PRINT_FN( fmt );
    else
        PRINT_FN( fmt );
        logstack[#logstack+1] = {
            info = info,
            date = date,
            log = fmt
        };
    end
end

local function getLogs()
    return logstack;
end

for k,v in pairs({
    print = printHook,
    printf = printf
}) do
    _G[k] = v;
    _G.TRYOUT_SANDBOX[k] = v;
end

return {
    getLogs = getLogs
};

