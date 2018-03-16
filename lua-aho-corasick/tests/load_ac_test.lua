-- This script is to test load_ac.lua
--
-- Some notes:
--   1. The purpose of this script is not to check if the libac.so work
--      properly, it is to check if there are something stupid in load_ac.lua
--
--   2. There are bunch of collectgarbage() calls, the purpose is to make
--      sure the shared lib is not unloaded after GC.

-- load_ac.lua looks up libac.so via package.cpath rather than LD_LIBRARY_PATH,
-- prepend (instead of appending) some insane paths here to see if it quit
-- prematurely.
--
package.cpath = ".;./?.so;" .. package.cpath

local ac = require "load_ac"

local ac_create = ac.create_ac
local ac_match = ac.match
local string_fmt = string.format
local string_sub = string.sub

local err_cnt = 0
local function mytest(testname, dict, match, notmatch)
    print(">Testing ", testname)

    io.write(string_fmt("Dictionary: "));
    for i=1, #dict do
       io.write(string_fmt("%s, ", dict[i]))
    end
    print ""

    local ac_inst = ac_create(dict);
    collectgarbage()
    for i=1, #match do
        local str = match[i]
        io.write(string_fmt("Matching %s, ", str))
        local b = ac_match(ac_inst, str)
        if b then
            print "pass"
        else
            err_cnt = err_cnt + 1
            print "fail"
        end
        collectgarbage()
    end

    if notmatch == nil then
        return
    end

    collectgarbage()

    for i = 1, #notmatch do
        local str = notmatch[i]
        io.write(string_fmt("*Matching %s, ", str))
        local r = ac_match(ac_inst, str)
        if r then
            err_cnt = err_cnt + 1
            print("fail")
        else
            print("succ")
        end
        collectgarbage()
    end
    ac_inst = nil
    collectgarbage()
end

print("")
print("====== Test to see if load_ac.lua works properly ========")

mytest("test1",
    {"he", "she", "his", "her", "str\0ing"},
    -- matching cases
    { "he", "she", "his", "hers", "ahe", "shhe", "shis2", "ahhe", "str\0ing" },

    -- not matching case
    {"str\0", "str"}
    )

os.exit((err_cnt == 0) and 0 or 1)
