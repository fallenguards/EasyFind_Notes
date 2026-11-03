-- EasyFind's own settings rows in the search bar come from declarations
-- (Core/SettingsRows.lua, each extension's settingsRows), not from the
-- built options window: building it at login was a 220 ms frame. Every
-- control in the window is a row, the 68 the window gave stay (fixture from
-- /efd optrows), every row works with no window, and the feed never loads it.
local H = require("Harness")

local function source(path)
    local f = assert(io.open(H.Path(path), "rb"))
    local src = f:read("*a")
    f:close()
    return src
end

local function slice(src, from, to)
    local s = assert(src:find(from, 1, true), from .. " not found")
    local e = assert(src:find(to, s + #from, true), to .. " not found")
    return src:sub(s, e - 1)
end

local function Setup()
    local env = H.newEnv()
    env.EasyFind = { db = {}, API = {}, UpdateMinimapButton = function() end }
    local ns = H.newNs(env)
    ns.L = {}
    assert(loadfile(H.EASYFIND_ROOT .. "/Locales/enUS.lua", "t", env))("EasyFind", ns)
    env.EasyFind._ns = ns
    assert(loadfile(H.ADDON_ROOT .. "/Locales/enUS.lua", "t", env))("EasyFind_Notes", {})
    setmetatable(ns.L, { __index = function(_, k) return k end })
    ns.UI_THEME_ORDER = { "Black", "Midnight", "Classic" }
    ns.FONT_CHOICES = { "Default", "Inter" }
    ns.WOWHEAD_LOCALES = { { value = "auto", label = "Auto" }, { value = "en", label = "English" } }
    ns.VISIBILITY_AUTO, ns.VISIBILITY_SMART, ns.VISIBILITY_ALWAYS = 1, 2, 3
    ns.GetVisibilityMode = function() return 1 end
    ns.SetVisibilityMode = function() end
    ns.RESULT_ROWS_MIN, ns.RESULT_ROWS_MAX = 4, 12
    ns.DEFAULT_FONT_SIZE, ns.SEARCH_WINDOW_ALPHA = 0.9, 0.95
    ns.ThemeHasChrome = function() return true end
    ns.CLASSIC_TREES = {}
    ns.Caps = { iconSearch = true }
    ns.IsCompanionLoadable = function() return true end
    ns.Profiles = {
        SECTIONS = { { id = "settings" }, { id = "aliases" } },
        Names = function() return { "Default", "Raid" } end, Suggestions = function() return {} end,
        DisplayName = function(_, name) return name end, Active = function() return "Default" end,
        ClassSpecs = function() return { { id = 62, name = "Arcane" } } end,
        SpecProfile = function() return "Default" end, SetSpecProfile = function() end,
        SpecProfilesEnabled = function() return false end, SetSpecProfilesEnabled = function() end,
        ExportIncluded = function() return true end, SetExportIncluded = function() end,
        Pick = function() end,
    }
    local menu = { rows = 6, labels = "right", labelSize = 1, iconSize = 1 }
    ns.AppsMenu = { Settings = function() return menu end, LABEL_POSITIONS = { "right", "below", "above", "left", "hidden" },
        ROWS_CHOICES = { 4, 6, 8, 10, 12 }, ROWS_DEFAULT = 6,
        ICON_SIZES = { { "OPT_FONT_SMALL", 0.85 }, { "OPT_FONT_MED", 1 }, { "OPT_FONT_LARGE", 1.25 }, { "OPT_FONT_XL", 1.5 } },
        LABEL_SIZES = { { "OPT_FONT_SMALL", 0.85 }, { "OPT_FONT_MED", 1 }, { "OPT_FONT_LARGE", 1.15 }, { "OPT_FONT_XL", 1.3 } } }
    H.loadModule("Search/Results/Gestures.lua", env, ns)
    ns.ExtensionPages = {
        { id = "notes", name = "Notes" }, { id = "chat", name = "Chat" },
        { id = "clipboard", name = "Clipboard History" },
    }
    H.loadModule("Core/SettingsRows.lua", env, ns)
    return env, ns
end

-- The extensions' row functions, cut from their files with what they read.
local function ExtensionRows(env, ns)
    local L, Utils = ns.L, ns.Utils
    Utils.OffOrNil = function(on) if on then return nil end return false end
    local notesNS = {}
    local notesEnv = setmetatable({ L = L, Utils = Utils, ns = ns, notesNS = notesNS, UI = {},
        NormalizeDB = function() return {} end,
        Ctx = { KindList = function() return { { label = "Quests", types = { "quest" } } } end },
        UI_SCALE_MIN = 0.65, UI_SCALE_MAX = 1.5, UI_SCALE_DEFAULT = 0.9, UI_SCALE_STEP = 0.05,
        OPACITY_MIN = 0.4, OPACITY_DEFAULT = 1, OPACITY_STEP = 0.05 }, { __index = env })
    assert(load(slice(source("Notes.lua"), "local function NotesBorderChoices()",
        "\n-- The extension's settings page") .. "\nreturn nil", "=Notes rows", "t", notesEnv))()
    return { { "notes", "Notes", notesNS.SettingRows } }
end

local function LabelMatches(label, name)
    if label == name then return true end
    local cut = label:match("^(.-)%.%.%.$")
    return cut ~= nil and cut ~= "" and name:sub(1, #cut) == cut
end

local function DeclaredRows()
    local env, ns = Setup()
    for _, ext in ipairs(ExtensionRows(env, ns)) do ns.SettingsRows.AddExtension(ext[1], ext[2], ext[3]) end
    return ns.SettingsRows.Rows(), env, ns
end

-- A row's name or, for one under a heading ("Heading: name"), its tail.
local function Declares(rows, text)
    for _, row in ipairs(rows) do
        if row.name == text or row.name:sub(-(#text + 2)) == ": " .. text then return true end
    end
    return false
end

local tests = {}

function tests.theWindowsRowsAllStay()
    local rows = DeclaredRows()
    local baseline = dofile(H.Path("tests/fixtures/options_rows_baseline.lua"))
    local used, missing = {}, {}
    for _, b in ipairs(baseline) do
        -- Notes' own rows; core's test holds the rest.
        if b[2] == "Notes" then
            local found
            for i, row in ipairs(rows) do
                if not used[i] and row.path[1] == b[1] and (row.path[2] or "") == b[2]
                    and row.control.kind == b[4] and LabelMatches(b[3], row.name) then
                    found = i
                    break
                end
            end
            if found then used[found] = true else missing[#missing + 1] = table.concat(b, " | ") end
        end
    end
    H.assertEq(table.concat(missing, "; "), "", "rows the window had and the declarations lack")
end

-- Every control on Notes' settings page has a row.
function tests.everyPageControlIsARow()
    local rows, _, ns = DeclaredRows()
    local L = ns.L
    local missing = {}
    for _, path in ipairs({ "Notes.lua" }) do
        for call, key in source(path):gmatch("kit%.([%a]+)%(page, L%[\"([%u%d_]+)\"%]") do
            if call ~= "Title" and not Declares(rows, L[key]) then missing[#missing + 1] = path .. " " .. key end
        end
    end
    H.assertEq(table.concat(missing, "; "), "", "controls with no settings row")
end

function tests.everyRowWorksWithNoWindow()
    local rows, env = DeclaredRows()
    local seen = {}
    for _, row in ipairs(rows) do
        local c = row.control
        local label = table.concat(row.path, " | ") .. " | " .. row.name
        H.assertFalse(seen[label] == true, label .. " twice")
        seen[label] = true
        H.assertEq(type(row.open), "function", label .. " open")
        if c.kind == "keybind" then
            H.assertEq(type(c.action), "string", label .. " action")
        elseif c.kind == "button" then
            H.assertEq(type(c.press), "function", label .. " press")
        else
            H.assertNotNil(c.get(), label .. " get")
            if c.kind == "choice" then H.assertTrue(#c.choices > 0, label .. " choices") end
            if c.kind == "slider" then H.assertTrue(c.min < c.max, label .. " range") end
        end
    end
    -- A set writes the saved setting, with no window built.
    for _, row in ipairs(rows) do
        if row.name == "Show Minimap Button" then row.control.set(false) end
        if row.name == "Result rows" then row.control.set(9) end
        if row.name == "Lock Position" then row.control.set(true) end
    end
    H.assertEq(env.EasyFind.db.showMinimapButton, false, "check row writes")
    H.assertEq(env.EasyFind.db.uiResultsRows, 9, "choice row writes")
    H.assertEq(env.EasyFind.db.lockPosition, true, "a once hidden check row writes")
    for _, row in ipairs(rows) do
        if row.name == "Beacon style" then H.assertEq(row.control.get(), "flame", "beacon row reads the beacon's style") end
    end
end

local pass, fail, failures = H.runSuite("NotesSettingsRows", tests)
return { pass = pass, fail = fail, failures = failures }
