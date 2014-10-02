#!/usr/bin/env lua
-- setup sandbox
local SANDBOX = {};
for k,v in pairs( _G ) do
    if k ~= '_G' then
        SANDBOX[k] = v;
    end
end
_G.TRYOUT_SANDBOX = SANDBOX;

-- required modules
require('tryout.hooks');
require('tryout.raise');
-- change working diretory
require('tryout.workdir');
-- run test
return require('tryout.run');
