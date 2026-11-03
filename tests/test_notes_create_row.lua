-- Notes offers its own Create note row first (2026-10-30), a create row
-- (createRow: the renderer's green plus badge).
local H = require("Harness")

local function Read(path)
    local f = assert(io.open(H.Path(path), "rb"))
    local src = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return src
end

local tests = {}

function tests.notesOfferTheCreateRowFirst()
    local env = setmetatable({
        NotesStore = function() return { { id = 1, name = "Mats" } } end,
        notesNS = { NoteShown = function() return true end,
                    NoteSearchRow = function(n) return { name = n.name, noteID = n.id } end },
        L = setmetatable({}, { __index = function(_, k) return k end }),
        slower = string.lower,
        ns = { NOTES_ICON_TEX = "tex" },
    }, { __index = _G })
    local src = Read("Notes.lua")
    local s = assert(src:find("function notesNS.BuildSearchData()", 1, true))
    local _, e = src:find("\nend\n", s)
    assert(load(src:sub(s, e), "=Notes.lua BuildSearchData", "t", env))()
    local rows = env.notesNS.BuildSearchData()
    H.assertEq(rows[1].name, "NOTES_CREATE")
    H.assertTrue(rows[1].createRow == true, "the first row makes a note")
    H.assertEq(rows[1].category, "Notes")
    H.assertEq(rows[2].noteID, 1, "then the notes")
end


local pass, fail, failures = H.runSuite("NotesCreateRow", tests)
return { pass = pass, fail = fail, failures = failures }
