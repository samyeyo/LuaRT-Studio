-- Copyright 2011-18 Paul Kulchenko, ZeroBrane LLC

local ide = ide

--[[
Accelerator general syntax is any combination of "CTRL", "ALT", "RAWCTRL" and
"SHIFT" strings (case doesn't matter) separated by either '-' or '+' characters
and followed by the accelerator itself. The accelerator may be any alphanumeric
character, any function key (from F1 to F12) or one of the special characters
listed below (again, case doesn't matter):

  DEL/DELETE   Delete key
  INS/INSERT   Insert key
  ENTER/RETURN Enter key
  PGUP         PageUp key
  PGDN         PageDown key
  LEFT         Left cursor arrow key
  RIGHT        Right cursor arrow key
  UP           Up cursor arrow key
  DOWN         Down cursor arrow key
  HOME         Home key
  END          End key
  SPACE        Space
  TAB          Tab key
  ESC/ESCAPE   Escape key (Windows only)

"CTRL" accelerator is mapped to "Cmd" key on OSX and to "Ctrl" key on other platforms.
"RAWCTRL" accelerator is mapped to "Ctrl" key on all platforms. For example, to specify
a combination of "Ctrl" with "PGUP" use "RawCtrl-PgUp".
--]]

ide.config.keymap = {
-- File menu
  [ID.NEW]              = "Ctrl-N",
  [ID.OPEN]             = "Ctrl-O",
  [ID.CLOSE]            = "Ctrl-W",
  [ID.SAVE]             = "Ctrl-S",
  [ID.SAVEAS]           = "Ctrl-Shift-S",
  [ID.SAVEALL]          = "Ctrl-Alt-S",
  [ID.RECENTFILES]      = "",
  [ID.RECENTFILESPREV]  = "Ctrl-,",
  [ID.RECENTFILESNEXT]  = "Ctrl-.",
  [ID.EXIT]             = "Ctrl-Q",
  [ID.RECENTPROJECTSPREV] = "Ctrl-Shift-<",
-- Edit menu
  [ID.CUT]              = "Ctrl-X",
  [ID.COPY]             = "Ctrl-C",
  [ID.PASTE]            = "Ctrl-V",
  [ID.SELECTALL]        = "Ctrl-A",
  [ID.UNDO]             = "Ctrl-Z",
  [ID.REDO]             = "Ctrl-Y",
  [ID.SHOWTOOLTIP]      = "Ctrl-T",
  [ID.AUTOCOMPLETE]     = "Ctrl-K",
  [ID.AUTOCOMPLETEENABLE] = "",
  [ID.COPYLINEUP]       = "Alt-Shift-UP",
  [ID.COPYLINEDOWN]     = "Alt-Shift-DOWN",
  [ID.MOVELINEUP]       = "Alt-UP",
  [ID.MOVELINEDOWN]     = "Alt-DOWN",
  [ID.COMMENT]          = "Ctrl-:",
  [ID.FORMAT]           = "Alt-F",
  [ID.FOLD]             = "F12",
  [ID.FOLDLINE]         = "Shift-F12",
  [ID.CLEARDYNAMICWORDS] = "",
  [ID.REINDENT]         = "Ctrl-I",
  [ID.BOOKMARKTOGGLE]   = "Ctrl-F2",
  [ID.BOOKMARKNEXT]     = "F2",
  [ID.BOOKMARKPREV]     = "Shift-F2",
  [ID.NAVIGATETOFILE]   = "Ctrl-P",
  [ID.NAVIGATETOLINE]   = "Ctrl-G",
  [ID.NAVIGATETOSYMBOL] = "Ctrl-B",
  [ID.NAVIGATETOMETHOD] = "Ctrl-;",
-- Search menu
  [ID.FIND]             = "Ctrl-F",
  [ID.FINDNEXT]         = "F3",
  [ID.FINDPREV]         = "Shift-F3",
  [ID.FINDSELECTNEXT]   = "Ctrl-F3",
  [ID.FINDSELECTPREV]   = "Ctrl-Shift-F3",
  [ID.REPLACE]          = "Ctrl-H",
  [ID.FINDINFILES]      = "Ctrl-Shift-F",
  [ID.REPLACEINFILES]   = "Ctrl-Shift-H",
  [ID.SORT]             = "",
-- View menu
  [ID.VIEWFILETREE]     = "Ctrl-Shift-P",
  [ID.VIEWOUTPUT]       = "Ctrl-Shift-O",
  [ID.VIEWCALLSTACK]    = "",
  [ID.VIEWDEFAULTLAYOUT] = "",
  [ID.VIEWFULLSCREEN]   = "Ctrl-Shift-A",
  [ID.ZOOMRESET]        = "Ctrl-0",
  [ID.ZOOMIN]           = "Ctrl-+",
  [ID.ZOOMOUT]          = "Ctrl--",
-- Project menu
  [ID.RUN]              = "F6",
  [ID.RUNNOW]           = "Ctrl-F6",
  [ID.COMPILE]          = "F7",
  [ID.ANALYZE]          = "Shift-F7",
  [ID.STARTDEBUG]       = "F5",
  [ID.ATTACHDEBUG]      = "",
  [ID.DETACHDEBUG]      = "",
  [ID.STOPDEBUG]        = "Shift-F5",
  [ID.STEP]             = "F10",
  [ID.STEPOVER]         = "Shift-F10",
  [ID.STEPOUT]          = "Ctrl-F10",
  [ID.RUNTO]            = "Ctrl-Shift-F10",
  [ID.TRACE]            = "",
  [ID.BREAK]            = "",
  [ID.BREAKPOINTTOGGLE] = "Ctrl-F9",
  [ID.BREAKPOINTNEXT]   = "F9",
  [ID.BREAKPOINTPREV]   = "Shift-F9",
  [ID.CLEAROUTPUT]      = "",
  [ID.CLEAROUTPUTENABLE] = "",
  [ID.INTERPRETER]      = "",
  [ID.PROJECTDIR]       = "",
-- Help menu
  [ID.ABOUT]            = "F1",
  -- Watch window menu items
  [ID.ADDWATCH]         = "Ins",
  [ID.EDITWATCH]        = "",
  [ID.DELETEWATCH]      = "",
-- Editor popup menu items
  [ID.GOTODEFINITION]   = "",
  [ID.RENAMEALLINSTANCES] = "",
  [ID.REPLACEALLSELECTIONS] = "",
  [ID.QUICKADDWATCH]    = "",
  [ID.QUICKEVAL]        = "",
  [ID.ADDTOSCRATCHPAD]  = "",
-- Filetree popup menu items
  [ID.RENAMEFILE]       = "F2",
  [ID.DELETEFILE]       = "Del",
-- Special global accelerators
  [ID.NOTEBOOKTABNEXT]  = "RawCtrl-PgDn",
  [ID.NOTEBOOKTABPREV]  = "RawCtrl-PgUp",
}

function KSC(id, default)
  -- this is only for the rare case of someone assigning a complete list
  -- to ide.config.keymap.
  local keymap = ide.config.keymap
  return (keymap[id] and "\t"..keymap[id]) or (default and "\t"..default) or ""
end

function TSC(id) -- shortcut converted to system-dependent text
  local osx = ide.osname == "Macintosh"
  local shortcut = KSC(id):gsub("\t","")
  -- replace Ctrl with Cmd, but not in RawCtrl
  return shortcut and #shortcut > 0 and shortcut:gsub("%f[%w]Ctrl", osx and "Cmd" or "Ctrl") or ""
end

ide.config.editor.keymap = {
  -- key, modifier, command, os: http://www.scintilla.org/ScintillaDoc.html#KeyboardCommands
  -- Cmd+Left/Right moves to start/end of line
  ["Ctrl-Left"] = {wxstc.wxSTC_KEY_LEFT, wxstc.wxSTC_SCMOD_CTRL, wxstc.wxSTC_CMD_HOME, "Macintosh"},
  ["Ctrl-Right"] = {wxstc.wxSTC_KEY_RIGHT, wxstc.wxSTC_SCMOD_CTRL, wxstc.wxSTC_CMD_LINEEND, "Macintosh"},
  -- Cmd+Shift+Left/Right selects to the beginning/end of the line
  ["Ctrl-Shift-Left"] = {wxstc.wxSTC_KEY_LEFT, wxstc.wxSTC_SCMOD_CTRL+wxstc.wxSTC_SCMOD_SHIFT, wxstc.wxSTC_CMD_HOMEEXTEND, "Macintosh"},
  ["Ctrl-Shift-Right"] = {wxstc.wxSTC_KEY_RIGHT, wxstc.wxSTC_SCMOD_CTRL+wxstc.wxSTC_SCMOD_SHIFT, wxstc.wxSTC_CMD_LINEENDEXTEND, "Macintosh"},
  -- Cmd+Shift+Up/Down selects to the beginning/end of the text
  ["Ctrl-Shift-Up"] = {wxstc.wxSTC_KEY_UP, wxstc.wxSTC_SCMOD_CTRL+wxstc.wxSTC_SCMOD_SHIFT, wxstc.wxSTC_CMD_LINEUPEXTEND, "Macintosh"},
  ["Ctrl-Shift-Down"] = {wxstc.wxSTC_KEY_DOWN, wxstc.wxSTC_SCMOD_CTRL+wxstc.wxSTC_SCMOD_SHIFT, wxstc.wxSTC_CMD_LINEDOWNEXTEND, "Macintosh"},
  -- Opt+Left/Right moves one word left (to the beginning)/right (to the end)
  ["Alt-Left"] = {wxstc.wxSTC_KEY_LEFT, wxstc.wxSTC_SCMOD_ALT, wxstc.wxSTC_CMD_WORDLEFT, "Macintosh"},
  ["Alt-Right"] = {wxstc.wxSTC_KEY_RIGHT, wxstc.wxSTC_SCMOD_ALT, wxstc.wxSTC_CMD_WORDRIGHTEND, "Macintosh"},
}
