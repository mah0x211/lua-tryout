local util = require('util');
local inspect = util.inspect;
local cl = require('ansicolors');
local path = require('path');
local process = require('process');
local gettimeofday = process.gettimeofday;
local sort = table.sort;
local concat = table.concat;
local CWD = process.getcwd();

local function getFormats( targets )
    local fmtSuccess, fmtFailure;
    -- setup output format
    local fmt = 'cost %20f sec %%{reset}| ';
    local len = 0;
    
    for _, name in ipairs( targets ) do
        name = targets[name];
        if #name > len then
            len = #name + 2;
        end
    end
    
    fmt = '%%{underline}%f sec%%{reset} ';
    fmtSuccess = '%%{yellow}%-' .. len .. 's %%{green}SUCCESS %d TEST(s)%%{reset} ' .. fmt;
    fmtFailure = '%%{yellow}%-' .. len .. 's %%{red}FAILURE%%{reset} ' .. fmt .. '\n%%{magenta}%s';
    
    return fmtSuccess, fmtFailure;
end


local function getFiles()
    local targets;
    
    if TRYOUT_FILE then
        targets = TRYOUT_FILE;
    else
        local name;
        
        targets = {};
        for _, file in ipairs( path.readdir('./') ) do
            if not file:find( '^[.]' ) and file:find('_try[.]lua$' ) then
                name = file:match( '(.+)[.]lua$' );
                targets[#targets+1] = name;
                targets[name] = file;
            end
        end
    end
    
    return targets;
end


local function runOnSandbox( rpath )
    local fn, err = loadfile( rpath, 't', TRYOUT_SANDBOX );
    
    if err then
        return false, err;
    end
    
    raise.nraise();
    return pcall( fn );
end


local function addPadding( msg )
    return '    ' .. msg:gsub( '([\r\n]+)', '%1    ' );
end


local function runTryFiles()
    local targets = getFiles();
    local fmtSuccess, fmtFailure = getFormats( targets );
    local costAll = 0;
    local ntryAll = 0;
    local success = {};
    local failure = {};
    local file, ok, err, sec, cost, ntry;
    
    print( 
'==============================================================================' 
    );
    print( cl( ('%%{cyan}TEST %d FILE(s)\n'):format( #targets ) ) );
    
    sec = gettimeofday();
    for _, name in ipairs( targets ) do
        file = targets[name];
        cost = gettimeofday();
        ok, err = runOnSandbox( file );
        cost = gettimeofday() - cost;
        costAll = costAll + cost;
        ntry = raise.nraise();
        ntryAll = ntryAll + ntry;
        
        if ok then
            success[#success+1] = {
                file = file,
                cost = cost,
                ntry = ntry
            };
            print( cl( fmtSuccess:format( file, ntry, cost ) ) );
        else
            err = ('pass: %d test(s)\n%s'):format( ntry, err );
            err = addPadding( err );
            failure[#failure+1] = err;
            print( cl( fmtFailure:format( file, cost, err ) ) );
        end
    end
    sec = gettimeofday() - sec;

    print( 
'==============================================================================' 
    );
    print( cl( ('%%{cyan}TIME: %f sec, TOTAL COST: %f sec\n'):format( sec, costAll ) ) );
    print( cl( ('%%{green}PASS   : %d TEST(s)'):format( ntryAll ) ) );
    print( cl( ('%%{green}SUCCESS: %d FILE(s)'):format( #success ) ) );
    print( cl( ('%%{red}FAILURE: %d FILE(s)'):format( #failure ) ) );
    print( concat( failure, '\n' ) );
    
    -- print perf rank
    if #success > 0 then
        sort( success, function(a,b)
            return a.cost > b.cost;
        end);
        print(
'------------------------------------------------------------------------------' 
        );
        for _, v in ipairs( success ) do
            print(cl(
                ('%%{green}%-10f sec, %d TEST(s)%%{reset} | %%{yellow}%s')
                :format( v.cost, v.ntry, v.file )
            ));
        end

    end
    
    print( '\n' );
    
    return #failure;
end

--print( inspect( require('tryout.hooks').getLogs() ) );

return runTryFiles();

