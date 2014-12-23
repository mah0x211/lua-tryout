-- child process creation wrapper
local sleep = require('process').sleep;
local fork = require('process').fork;
local exec = require('process').exec;
local waitpid = require('process').waitpid;
local WNOHANG = require('process').WNOHANG;
local SIGKILL = require('signal').SIGKILL;
local CHILDPROC = {};
-- setup sandbox
local SANDBOX = {};
for k,v in pairs( _G ) do
    if k ~= '_G' then
        SANDBOX[k] = v;
    end
end

function cleanupChild()
    local stat, err;
    
    for _, chd in ipairs( CHILDPROC ) do
        chd:kill();
        sleep(1);
        stat, err = waitpid( chd:pid(), WNOHANG );
        if not err and stat.nohang then
            chd:kill( SIGKILL );
        end
    end
    CHILDPROC = {};
end


function SANDBOX.execChild( ... )
    local chd, err = exec( ... );
    
    if chd then
        CHILDPROC[#CHILDPROC+1] = chd;
    end
    
    return chd, err;
end


-- export utility function
for mod, list in pairs({
    process = {
        'sleep'
    },
    util = {
        'inspect'
    }
}) do
    mod = require(mod);
    for _, fn in ipairs( list ) do
        if type( mod[fn] ) == 'function' then
            SANDBOX[fn] = mod[fn];
        end
    end
end


_G.TRYOUT_SANDBOX = SANDBOX;

require('tryout.raise');
