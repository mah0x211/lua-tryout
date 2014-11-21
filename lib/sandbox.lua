-- setup sandbox
local SANDBOX = {};
for k,v in pairs( _G ) do
    if k ~= '_G' then
        SANDBOX[k] = v;
    end
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
