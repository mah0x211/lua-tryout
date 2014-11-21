#!/usr/bin/env lua

-- required modules
require('tryout.sandbox');
require('tryout.hooks');
require('tryout.raise');
-- change working diretory
require('tryout.workdir');
-- run test
return require('tryout.run');