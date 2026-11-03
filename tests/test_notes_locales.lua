-- Notes' own text (Locales/*.lua, set into EasyFind's L): every locale
-- carries the English file's keys, and every key Notes' code names is
-- defined in its English file or in EasyFind's, which loads first.
local H = require("Harness")

local LOCALES = { "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

local function Read(path)
    local f = assert(io.open(path, "rb"))
    local src = f:read("*a")
    f:close()
    return src
end

local function Keys(src)
    local out = {}
    for key in src:gmatch('\nL%["([^"]+)"%]%s*=') do out[key] = true end
    return out
end

local tests = {}

function tests.everyLocaleHasTheEnglishKeys()
    local en = Keys("\n" .. Read(H.ADDON_ROOT .. "/Locales/enUS.lua"))
    for _, loc in ipairs(LOCALES) do
        local own = Keys("\n" .. Read(H.ADDON_ROOT .. "/Locales/" .. loc .. ".lua"))
        local missing, stray = {}, {}
        for k in pairs(en) do if not own[k] then missing[#missing + 1] = k end end
        for k in pairs(own) do if not en[k] then stray[#stray + 1] = k end end
        table.sort(missing)
        table.sort(stray)
        H.assertEq(table.concat(missing, " "), "", loc .. " lacks")
        H.assertEq(table.concat(stray, " "), "", loc .. " has keys English lacks")
    end
end

function tests.everyKeyNamedIsDefined()
    if not H.CoreAtLeast("4.3.0") then return end
    local defined = Keys("\n" .. Read(H.ADDON_ROOT .. "/Locales/enUS.lua"))
    for k in pairs(Keys("\n" .. Read(H.EASYFIND_ROOT .. "/Locales/enUS.lua"))) do defined[k] = true end
    local missing = {}
    for _, rel in ipairs((H.TocFiles(H.TOCS[1]))) do
        if rel:match("%.lua$") and not rel:match("^Locales/") then
            for key in Read(H.ADDON_ROOT .. "/" .. rel):gmatch('L%["([%w_]+)"%]') do
                if not defined[key] then missing[#missing + 1] = rel .. " " .. key end
            end
        end
    end
    table.sort(missing)
    H.assertEq(table.concat(missing, "; "), "", "named but defined nowhere")
end

local pass, fail, failures = H.runSuite("NotesLocales", tests)
return { pass = pass, fail = fail, failures = failures }
