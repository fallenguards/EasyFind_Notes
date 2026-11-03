-- Every chat line EasyFind prints, each with why it may (2026-10-26: lines
-- that only confirmed a click, an arrival or an import were spam). A new
-- chat line fails here until listed with one of these reasons:
--   error    something broke
--   refusal  what was asked cannot be done (combat, a bad code, a full list)
--   asked    the player asked for this text (/ef help)
--   alert    news the player did not click for (a reminder due, a reply)
--   release  the What's New and tour offers
--   dev      dev mode only
--   helper   a local print helper's own body
local H = require("Harness")

local ALLOWED = {
    ["Notes.lua|NOTES_LINK_ASKING_FMT"] = { 1, "alert" },
    ["Notes.lua|NOTES_LINK_NO_ANSWER_FMT"] = { 1, "alert" },
    ["Notes.lua|NOTES_NOTHING_TO_UNDO"] = { 1, "refusal" },
    ["Notes.lua|NOTES_READER_EMPTY"] = { 1, "refusal" },
    ["Reminders.lua|NOTES_REMINDER_FMT"] = { 1, "alert" },
    ["Notes.lua|SHORTKEY_IMPORT_BAD"] = { 3, "refusal" },
    -- A newer EasyFind or extension heard from a guild or group member, once a session.
}

-- Every shipped Lua file but the locales, once.
local function Files()
    local out, seen = {}, {}
    for _, toc in ipairs(H.TOCS) do
        for _, rel in ipairs((H.TocFiles(toc))) do
            if rel:match("%.lua$") and not rel:match("^Locales/") and not seen[rel] then
                seen[rel] = true
                out[#out + 1] = rel
            end
        end
    end
    return out
end

-- What a print line says: its first locale key, else its first string,
-- else the argument as written.
local function Token(line)
    return line:match('L%["([%w_]+)"%]') or line:match('_G%["([%w_]+)"%]') or line:match('"([^"]+)"')
        or line:match("[Pp]rint%((.-)%)%s*$") or line:match("[Pp]rint%((.-)%)") or "?"
end

local function Found()
    local found = {}
    for _, rel in ipairs(Files()) do
        local f = io.open(H.ADDON_ROOT .. "/" .. rel, "rb")
        if f then
            for line in f:lines() do
                local code = line:gsub("%-%-.*$", "")
                local call = code:find("EasyFind:Print%(") or code:find("%f[%w_.:]Print%(")
                    or code:find("%f[%w_.:]print%(")
                if call and not code:find("function [%w_.:]*[Pp]rint%(") then
                    local key = rel .. "|" .. Token(code)
                    found[key] = (found[key] or 0) + 1
                end
            end
            f:close()
        end
    end
    return found
end

local tests = {}

function tests.everyChatLineHasItsReason()
    local found = Found()
    local new, gone = {}, {}
    for key, n in pairs(found) do
        local allowed = ALLOWED[key]
        if not allowed or n > allowed[1] then new[#new + 1] = key .. " x" .. n end
    end
    for key, allowed in pairs(ALLOWED) do
        if (found[key] or 0) < allowed[1] then gone[#gone + 1] = key end
    end
    table.sort(new)
    table.sort(gone)
    H.assertEq(table.concat(new, "; "), "",
        "a chat line that only confirms what the player just did is spam; list it in ALLOWED with its reason or drop it")
    H.assertEq(table.concat(gone, "; "), "", "listed lines no longer printed: take them off ALLOWED")
end

local pass, fail, failures = H.runSuite("ChatLines", tests)
return { pass = pass, fail = fail, failures = failures }
