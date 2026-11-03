-- Guard.lua: an EasyFind older than the one it names gets one chat line,
-- and every code file stops before it touches anything (Context.lua stops
-- on the guard, the rest on Context).
local H = require("Harness")

local tests = {}

local function Read(path)
    local f = assert(io.open(H.Path(path), "rb"))
    local s = f:read("a"):gsub("\r\n", "\n")
    f:close()
    return s
end

local function RunGuard(version, loggedIn)
    local printed, frames = {}, {}
    local env = setmetatable({
        C_AddOns = { GetAddOnMetadata = function(addon, field)
            if addon == "EasyFind" and field == "Version" then return version end
            if field == "Title" then return "EasyFind [Notes]" end
        end },
        IsLoggedIn = function() return loggedIn end,
        print = function(s) printed[#printed + 1] = s end,
        CreateFrame = function()
            local f = { events = {} }
            function f:Hide() end
            function f:RegisterEvent(e) self.events[e] = true end
            function f:UnregisterAllEvents() self.events = {} end
            function f:SetScript(_, fn) self.onEvent = fn end
            frames[#frames + 1] = f
            return f
        end,
        EasyFind = { _ns = { L = { EXT_NEEDS_EASYFIND_FMT = "Needs EasyFind %s or later: update EasyFind." } } },
    }, { __index = _G })
    local own = {}
    assert(loadfile(H.Path("Guard.lua"), "t", env))("EasyFind_Notes", own)
    return own, printed, frames
end

local function CodeFiles()
    local out = {}
    for _, file in ipairs(H.TocFiles("EasyFind_Notes.toc")) do
        if not (file:find("^Locales/") or file == "Guard.lua") then out[#out + 1] = file end
    end
    return out
end

function tests.anOlderEasyFind_oneLineNamingTheOldest()
    local own, printed = RunGuard("3.4.4", true)
    H.assertTrue(own.tooOld, "the files are told to stop")
    H.assertEq(#printed, 1, "Notes loads after login: the line at once")
    H.assertTrue(printed[1]:find("EasyFind [Notes]", 1, true) and printed[1]:find("4.0.0", 1, true),
        "the addon and the version it needs: " .. printed[1])
end

function tests.theOldestAndNewer_runAsIs()
    for _, v in ipairs({ "4.0.0", "4.2.0", "4.3.0", "5.0.0", "10.0.0", "@project-version@" }) do
        local own, printed = RunGuard(v, true)
        H.assertNil(own.tooOld, v)
        H.assertEq(#printed, 0, v)
    end
    H.assertNil(RunGuard(nil, true).tooOld, "a version it cannot read never stops anything")
end

function tests.theOldestIsALineCIReads()
    H.assertTrue(Read("Guard.lua"):find('\nlocal MIN_EASYFIND = "%d+%.%d+%.%d+"\n') ~= nil,
        "ci.yml reads the version from this line")
end

function tests.theGuardLoadsBeforeEveryCodeFile()
    local order = {}
    for i, file in ipairs(H.TocFiles("EasyFind_Notes.toc")) do order[file] = i end
    H.assertNotNil(order["Guard.lua"], "listed in the toc")
    for _, file in ipairs(CodeFiles()) do
        H.assertTrue(order[file] > order["Guard.lua"], file .. " after the guard")
    end
end

function tests.everyCodeFile_stopsBeforeTouchingAnything()
    local files = CodeFiles()
    H.assertTrue(#files >= 5, "the code files: " .. #files)
    local wrote
    local proxy = setmetatable({}, { __newindex = function(_, k) wrote = wrote or k end })
    local env = setmetatable({ EasyFind = { _ns = proxy } }, { __index = _G })
    local own = { tooOld = true }
    for _, file in ipairs(files) do
        local ok, err = pcall(assert(loadfile(H.Path(file), "t", env)), "EasyFind_Notes", own)
        H.assertTrue(ok, file .. ": " .. tostring(err))
        H.assertNil(wrote, file .. " wrote ns." .. tostring(wrote))
    end
    for k in pairs(own) do H.assertEq(k, "tooOld", "nothing of Notes' own was set") end
end

local pass, fail, failures = H.runSuite("Notes guard", tests)
return { pass = pass, fail = fail, failures = failures }
