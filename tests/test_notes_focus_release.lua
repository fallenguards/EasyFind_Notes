local H = require("Harness")

local tests = {}

-- Both note editors release, the window, the toolbar and the flyouts
-- hanging under it counted inside.
function tests.theNoteEditorsReleaseOutsideTheirWindow()
    local f = assert(io.open(H.ADDON_ROOT .. "/Notes.lua", "rb"))
    local src = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    H.assertTrue(src:find("Utils.ReleaseFocusOnOutsideClick(frame.editor, function()\n        return frame:IsMouseOver()"
        .. " or Over(frame.toolbar) or Over(frame.listMenuFlyout) or Over(frame.fontSizeFlyout)", 1, true) ~= nil,
        "the note's text")
    H.assertTrue(src:find("Utils.ReleaseFocusOnOutsideClick(editor, function()\n        return parent:IsMouseOver()", 1, true) ~= nil,
        "a snippet's text")
    H.assertNil(src:find("-- keeps focus: the note's text", 1, true))
end

local pass, fail, failures = H.runSuite("NotesFocusRelease", tests)
return { pass = pass, fail = fail, failures = failures }
