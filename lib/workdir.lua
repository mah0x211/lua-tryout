local process = require('process');
local path = require('path');
local cl = require('ansicolors');

raise.ifNil( arg[1], 'path not found' );

local function label( name )
    return cl('    %{yellow}%-15s%{reset}'):format( name );
end

local function chdir()
    local rpath = raise.ifNil( path.exists( arg[1] ) ); 
    local stat = raise.ifNil( path.stat( rpath ) );
    local err;

    if path.isReg( stat.mode ) then
        raise.ifNil( rpath:find('^.+_try[.]lua$' ), 'invalid target file' );
        printf( '%s: %s', label('TARGET FILE'), rpath );
        name = rpath:match( '(.+)[.]lua$' );
        _G.TRYOUT_FILE = { 
            [1] = name,
            [name] = path.basename( rpath )
        };
        rpath = path.dirname( rpath );
    else
        raise.ifFalse( path.isDir( stat.mode ), '%q is invalid file', rpath );
    end

    -- change dir
    raise.ifNotNil( process.chdir( rpath ) );
    printf( '%s: %s', label('WORKING DIR'), process.getcwd() );
    _G.TRYOUT_DIR = rpath;
end


local function setSearchPath()
    local pathz = {};
    
    -- set search path
    package.path = '?.lua;' .. process.getcwd() .. '/?.lua;' .. package.path;
    
    for line in package.path:gmatch('[^;]+') do
        pathz[#pathz+1] = line;
    end
    printf( '%s: %s', label('LUA_PATH'), table.concat( pathz, '  ' ) );

    pathz = {};
    for line in package.cpath:gmatch('[^;]+') do
        pathz[#pathz+1] = line;
    end
    printf( '%s: %s', label('LUA_CPATH'), table.concat( pathz, '  ' ) );
end


printf( cl('%{cyan underline}ENVIRONMENTS:%{reset}') );
chdir();
setSearchPath();
