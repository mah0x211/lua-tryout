local getcwd = require('process').getcwd;
local chdir = require('process').chdir;
local exists = require('path').exists;
local stat = require('path').stat;
local basename = require('path').basename;
local dirname = require('path').dirname;
local isReg = require('path').isReg;
local isDir = require('path').isDir;
local cl = require('ansicolors');

if arg[1] == nil then
    arg[1] = '.'
end

local function label( name )
    return cl('    %{yellow}%-15s%{reset}'):format( name );
end

local function setcwd()
    local rpath = raise.ifNil( exists( arg[1] ) ); 
    local info = raise.ifNil( stat( rpath ) );
    local name;
    
    if isReg( info.mode ) then
        raise.ifNil( rpath:find('^.+_try[.]lua$' ), 'invalid target file' );
        printf( '%s: %s', label('TARGET FILE'), rpath );
        name = rpath:match( '(.+)[.]lua$' );
        _G.TRYOUT_FILE = { 
            [1] = name,
            [name] = basename( rpath )
        };
        rpath = dirname( rpath );
    else
        raise.ifFalse( isDir( info.mode ), '%q is invalid file', rpath );
    end

    -- change dir
    raise.ifNotNil( chdir( rpath ) );
    printf( '%s: %s', label('WORKING DIR'), getcwd() );
    _G.TRYOUT_DIR = rpath;
end


local function setSearchPath()
    local pathz = {};
    
    -- set search path
    package.path = '?.lua;' .. getcwd() .. '/?.lua;' .. package.path;
    
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
setcwd();
setSearchPath();
