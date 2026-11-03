-- Notes fills in its extension and its search results through the API
-- with the ids EasyFind's own stubs stand under before it loads
-- (Core/Extensions.lua), so the tile and the @notes rows are one each.
local H = require("Harness")

local function Read(path)
    local f = assert(io.open(H.Path(path), "rb"))
    local src = f:read("*a")
    f:close()
    return src
end

local function Registers(src, fn, field, id)
    for call in src:gmatch(fn .. "%b()") do
        if call:find(field .. '%s*=%s*"' .. id .. '"') then return true end
    end
    return false
end

local tests = {}

function tests.notesRegistersUnderCoresIds()
    local notes, core = Read("Notes.lua"), Read("Core/Extensions.lua")
    for _, src in ipairs({ notes, core }) do
        H.assertTrue(Registers(src, "RegisterExtension", "id", "notes"), "the extension")
        H.assertTrue(Registers(src, "RegisterSearchProvider", "key", "notes"), "its results")
    end
end

local pass, fail, failures = H.runSuite("NotesRegisters", tests)
return { pass = pass, fail = fail, failures = failures }
