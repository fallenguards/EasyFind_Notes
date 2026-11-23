-- This extension's settings page takes over EasyFind's Notes page when it
-- loads: it shows EasyFind's switches for notes too (the tooltip hint's,
-- chat names...), and so do its settings search rows. They went missing
-- (2026-11-23: "why no way to hide the tip for ctrl+right click").
local H = require("Harness")

local function Body(src, header)
    local s = assert(src:find(header, 1, true), header)
    local e = assert(src:find("\nend\n", s, true), header .. " end")
    return src:sub(s, e)
end

local tests = {}

function tests.pageAndSearchRows_carryEasyFindsSwitches()
    local f = assert(io.open(H.ADDON_ROOT .. "/Notes.lua", "rb"))
    local src = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    H.assertTrue(Body(src, "function notesNS.BuildSettingsPage(page, kit)"):find("ns.NotesSaveSwitches(page, kit,", 1, true) ~= nil,
        "the page adds EasyFind's switches")
    H.assertTrue(Body(src, "function notesNS.SettingRows()"):find("ns.NotesSaveSwitchRows()", 1, true) ~= nil,
        "the settings search lists them")
end

local pass, fail, failures = H.runSuite("SettingsKeepEasyFindSwitches", tests)
return { pass = pass, fail = fail, failures = failures }
