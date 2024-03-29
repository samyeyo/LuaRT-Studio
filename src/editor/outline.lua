-- Copyright 2014-17 Paul Kulchenko, ZeroBrane LLC

local globals = { ["arg"] = true, ["assert"] = true, ["collectgarbage"] = true, ["dofile"] = true, ["error"] = true, ["getmetatable"] = true, ["ipairs"] = true, ["load"] = true, ["loadfile"] = true, ["next"] = true, ["Object"] = true, ["pairs"] = true, ["ipairs"] = true, ["each"] = true, ["is"] = true, ["pcall"] = true, ["print"] = true, ["rawequal"] = true,
["rawget"] = true, ["rawset"] = true, ["rawlen"] = true, ["require"] = true, ["select"] = true, ["setmetatable"] = true, ["tonumber"] = true, ["tostring"] = true, ["type"] = true, ["unpack"] = true, ["warn"] = true, ["xpcall"] = true, ["_G"] = true, ["_VERSION"] = true }

local globals_mod = { ["sys"] = true, ["coroutine"] = true, ["package"] = true, ["string"] = true, ["table"] = true, ["math"] = true, ["debug"] = true }

local ide = ide
local config = ide.config
ide.outline = {
  outlineCtrl = nil,
  imglist = ide:CreateImageList("OUTLINE", "FILE-NORMAL", "FUNC-LOCAL","FUNC-GLOBAL", "FUNC-ANON", "FUNC-METHOD", "FUNC-SELF", "VAR-LOCAL", "VAR-GLOBAL"),
  typelist = { nil, "local function", "global function", "anonymous function", "member function", "method", "local variable", "global variable" }, 
  settings = {
    symbols = {},
    ignoredirs = {},
  },
  needsaving = false,
  needrefresh = nil,
  indexqueue = {[0] = {}},
  indexpurged = false, -- flag that the index has been purged from old records; once per session
}

local outline = ide.outline
local image = { FILE = 0, LFUNCTION = 1, GFUNCTION = 2, AFUNCTION = 3,
  SMETHOD = 4, METHOD = 5, LVARIABLE = 6, GVARIABLE = 7
}
local q = EscapeMagic
local caches = {}
outline.caches = caches

local function setData(ctrl, item, value)
  if ide.wxver >= "2.9.5" then
    local data = wx.wxLuaTreeItemData()
    data:SetData(value)
    ctrl:SetItemData(item, data)
  end
end

local function resetOutlineTimer()
  if ide.config.outlineinactivity then
    ide.timers.outline:Start(ide.config.outlineinactivity*1000, wx.wxTIMER_ONE_SHOT)
  end
end

local function resetIndexTimer(interval)
  if ide.timers.symbolindex and ide.config.symbolindexinactivity and not ide.timers.symbolindex:IsRunning() then
    ide.timers.symbolindex:Start(interval or ide.config.symbolindexinactivity*1000, wx.wxTIMER_ONE_SHOT)
  end
end

local function outlineRefresh(editor, force)
  if not editor then return end
  local tokens = editor:GetTokenList()
  local sep = editor.spec.sep
  local varname = "([%w_][%w_"..q(sep:sub(1,1)).."]*)"
  local funcs = {updated = ide:GetTime()}
  local vars = {updated = ide:GetTime()}
  local var = {}
  local varnames = {}
  local outcfg = ide.config.outline or {}
  local scopes = {}
  local funcnum = 0
  local SCOPENUM, FUNCNUM = 1, 2
  local text
  for _, token in ipairs(tokens) do
    local op = token[1]
    if op == 'Var' or op == 'Id' then 
      var = {name = token.name, pos = token.fpos, global =  token.context[token.name] == nil, func = token.context['function'] and funcs[scopes[#scopes][FUNCNUM]] or nil, mainfunc = token.at == 1, forcelocal = op == 'Var' }
      var.image = var.global and image.GVARIABLE or image.LVARIABLE
      vars[#vars+1] = var
    elseif outcfg.showcurrentfunction and op == 'Scope' then
      local fundepth = #scopes
      if token.name == '(' then -- a function starts a new scope
        funcnum = funcnum + 1 -- increment function count
        local nested = fundepth == 0 or scopes[fundepth][SCOPENUM] > 0
        scopes[fundepth + (nested and 1 or 0)] = {1, funcnum}
      elseif fundepth > 0 then
        scopes[fundepth][SCOPENUM] = scopes[fundepth][SCOPENUM] + 1
      end
    elseif outcfg.showcurrentfunction and op == 'EndScope' then
      local fundepth = #scopes
      if fundepth > 0 and scopes[fundepth][SCOPENUM] > 0 then
        scopes[fundepth][SCOPENUM] = scopes[fundepth][SCOPENUM] - 1
        if scopes[fundepth][SCOPENUM] == 0 then
          local funcnum = scopes[fundepth][FUNCNUM]
          if funcs[funcnum] then
            funcs[funcnum].poe = token.fpos-1 + (token.name and #token.name or 0)
          end
          table.remove(scopes)
        end
      end
    elseif op == 'Function' then      
      local depth = token.context['function'] or 1
      local name, pos = token.name, token.fpos
      text = text or editor:GetTextDyn()
      local _, _, rname, params = text:find('([^(]*)(%b())', pos)
      if rname then rname = rname:gsub("%s+$","") end
      -- if something else got captured, then don't show any parameters
      if name and rname and name ~= rname then params = "" end
      if not name then
        local s = editor:PositionFromLine(editor:LineFromPosition(pos-1))
        local rest
        rest, pos, name = text:sub(s+1, pos-1):match('%s*(.-)()'..varname..'%s*=%s*function%s*$')
        if rest then
          pos = s + pos
          -- guard against "foo, bar = function() end" as it would get "bar"
          if #rest>0 and rest:find(',') then name = nil end
        end
      end
      local ftype = image.LFUNCTION
      if not name then
        ftype = image.AFUNCTION
      elseif outcfg.showmethodindicator and name:find('['..q(sep)..']') then
        ftype = name:find(q(sep:sub(1,1))) and image.SMETHOD or image.METHOD
      else
        if var.name == name and var.pos == pos or var.name and name:find('^'..var.name..'['..q(sep)..']') then
          ftype = token.context[token.name] == nil and image.GFUNCTION or image.LFUNCTION
        end
      end
      vars[#vars] = nil
      name = name or outcfg.showanonymous
      funcs[#funcs+1] = {
        name = ((name or '~')..(params or "")):gsub("%s+", " "),
        skip = (not name) and true or nil,
        depth = depth,
        image = ftype,
        pos = name and pos or token.fpos,
      }
    end
  end

  if force == nil then return funcs end

  local ctrl = outline.outlineCtrl
  if not ctrl then return end -- outline can be completely removed/disabled

  local cache = caches[editor] or {}
  caches[editor] = cache

  -- add file
  local filename = ide:GetDocument(editor):GetTabText()
  local fileitem = cache.fileitem
  ctrl:SetItemText(ctrl:GetRootItem(), filename)
  if not fileitem or not fileitem:IsOk() then
    local root = ctrl:GetRootItem()
    if not root or not root:IsOk() then return end

       fileitem = root
       ctrl:SetItemText(fileitem, filename:gsub("*", ""))
       outline.imglist:Replace(image.FILE, ide:CreateFileIcon(GetFileExt(filename)) or ide.filetree.imglist:GetBitmap(2))
       setData(ctrl, fileitem, editor)
       ctrl:SetItemImage(fileitem, image.FILE)
       ctrl:SetEvtHandlerEnabled(true)
    -- if outcfg.showonefile then
    --   fileitem = root
    -- else
    --   outline.imglist:Replace(image.FILE, ide:CreateFileIcon(GetFileExt(filename)) or ide.filetree.imglist:GetBitmap(2))
    --   fileitem = ctrl:AppendItem(root, filename, image.FILE)
    --   setData(ctrl, fileitem, editor)
    --   ctrl:SetItemBold(fileitem, true)
    --   ctrl:SortChildren(root)
    -- end
    cache.fileitem = fileitem
  end

  local nochange

  do -- check if any changes in the cached function list
    local prevvars = cache.vars or {}
    local vnochange = #vars == #prevvars
    local resort = {} -- items that need to be re-sorted
    if vnochange then
      for n, _var in ipairs(vars) do
        _var.item = prevvars[n].item -- carry over cached items
       if prevvars[n].item then
          if _var.name ~= prevvars[n].name then
            ctrl:SetItemText(prevvars[n].item, _var.name)
            if outcfg.sort then resort[ctrl:GetItemParent(prevvars[n].item)] = true end
          end
          if _var.image ~= prevvars[n].image then
            ctrl:SetItemImage(prevvars[n].item, _var.image)
          end
        end
      end
    end
    cache.vars = vars -- set new cache as positions may change
    if vnochange and not force then -- return if no visible changes
      if outcfg.sort then -- resort items for all parents that have been modified
        for item in pairs(resort) do ctrl:SortChildren(item) end
      end
    end
    nochange = vnochange
  end

  do -- check if any changes in the cached function list
    local prevfuncs = cache.funcs or {}
    local fnochange = #funcs == #prevfuncs
    local resort = {} -- items that need to be re-sorted
    if fnochange then
      for n, func in ipairs(funcs) do
        func.item = prevfuncs[n].item -- carry over cached items
        if func.depth ~= prevfuncs[n].depth then
          fnochange = false
        elseif fnochange and prevfuncs[n].item then
          if func.name ~= prevfuncs[n].name then
            ctrl:SetItemText(prevfuncs[n].item, func.name)
            if outcfg.sort then resort[ctrl:GetItemParent(prevfuncs[n].item)] = true end
          end
          if func.image ~= prevfuncs[n].image then
            ctrl:SetItemImage(prevfuncs[n].item, func.image)
          end
        end
      end
    end
    cache.funcs = funcs -- set new cache as positions may change
    if fnochange and not force then -- return if no visible changes
      if outcfg.sort then -- resort items for all parents that have been modified
        for item in pairs(resort) do ctrl:SortChildren(item) end
      end
      if vnochange then
        return
      end
    end
  end
  -- refresh the tree
  -- refreshing shouldn't change the focus of the current element,
  -- but it appears that DeleteChildren (wxwidgets 2.9.5 on Windows)
  -- moves the focus from the current element to wxTreeCtrl.
  -- need to save the window having focus and restore after the refresh.
  local win = ide:GetMainFrame():FindFocus()

  ctrl:Freeze()

  -- disabling event handlers is not strictly necessary, but it's expected
  -- to fix a crash on Windows that had DeleteChildren in the trace (#442).
  ctrl:SetEvtHandlerEnabled(false)
  ctrl:DeleteChildren(fileitem)
  ctrl:SetEvtHandlerEnabled(true)

  local edpos = editor:GetCurrentPos()+1
  local stack = {fileitem}
  local resort = {} -- items that need to be re-sorted
  local funcvars = {}
  local globalvars = {}
  for n, func in ipairs(funcs) do
    local depth = outcfg.showflat and 1 or func.depth
    local parent = stack[depth]
    local funcname = func.name:gsub("%(.*%)", "")
    funcvars[funcname] = {}
    while not parent do depth = depth - 1; parent = stack[depth] end
    if not func.skip then
      if func.image == image.GFUNCTION or (func.depth == 1 and func.image == image.LFUNCTION) then
        globalvars[funcname] = true
      elseif parent ~= nil then
        local p = funcvars[ctrl:GetItemText(parent):gsub("%(.*%)", "")]
        if p ~= nil then
          p[funcname] = true
        end
      end
      local item = ctrl:AppendItem(parent, func.name, func.image)
      if ide.config.outline.showcurrentfunction and edpos >= func.pos and func.poe and (edpos <= func.poe) then
        ctrl:SetItemBold(item, true)
      end
      if outcfg.sort then resort[parent] = true end
      setData(ctrl, item, n)
      func.item = item
      stack[func.depth+1] = item
    end   
    func.skip = nil
  end

  local item
  for n, var in ipairs(vars) do
    if not globals[var.name] and not globals_mod[var.name] and not funcvars[var.name] and not globalvars[var.name] and (var.mainfunc or var.func == nil) then
      item = ctrl:AppendItem(fileitem, var.name, var.image)
      globalvars[var.name] = true
      setData(ctrl, item, -n)
      var.item = item
    end
  end
  for n, var in ipairs(vars) do
    local funcname = var.func and var.func.name:gsub("%(.*%)", "") or false
    if not globals[var.name] and (var.forcelocal or globalvars[var.name] == nil) and not globals_mod[var.name] and var.func ~= nil and funcvars[funcname][var.name] == nil then
      item = ctrl:AppendItem(var.func.item, var.name, var.image)
      funcvars[funcname][var.name] = true
      setData(ctrl, item, -n)
      var.item = item
    end
  end
  cache.funcvars = funcvars
  if outcfg.sort then -- resort items for all parents that have been modified
    for item in pairs(resort) do ctrl:SortChildren(item) end
  end
  if outcfg.showcompact then ctrl:Expand(fileitem) else ctrl:ExpandAllChildren(fileitem) end

  -- scroll to the fileitem, but only if it's not a root item (as it's hidden)
  if fileitem:GetValue() ~= ctrl:GetRootItem():GetValue() then
    ctrl:ScrollTo(fileitem)
    ctrl:SetScrollPos(wx.wxHORIZONTAL, 0, true)
  else -- otherwise, scroll to the top
    ctrl:SetScrollPos(wx.wxVERTICAL, 0, true)
  end
  ctrl:Thaw()

  if win and win ~= ide:GetMainFrame():FindFocus() then win:SetFocus() end
end

local failures = {}
local function indexFromQueue()
  if #outline.indexqueue == 0 then return end

  local editor = ide:GetEditor()
  local inactivity = ide.config.symbolindexinactivity
  if editor and inactivity and editor:GetModifiedTime() > ide:GetTime()-inactivity then
    -- reschedule timer for later time
    resetIndexTimer()
  else
    local fname = table.remove(outline.indexqueue, 1)
    outline.indexqueue[0][fname] = nil
    -- check if fname is already loaded
    ide:SetStatusFor(TR("Indexing %d files: '%s'..."):format(#outline.indexqueue+1, fname))
    local content, err = FileRead(fname)
    if content then
      local editor = ide:CreateBareEditor()
      editor:SetupKeywords(GetFileExt(fname))
      editor:SetTextDyn(content)
      editor:Colourise(0, -1)
      editor:ResetTokenList()
      while editor:IndicateSymbols() do end

      outline:UpdateSymbols(fname, outlineRefresh(editor))
      editor:Destroy()
    elseif not failures[fname] then
      ide:Print(TR("Can't open file '%s': %s"):format(fname, err))
      failures[fname] = true
    end
    if #outline.indexqueue == 0 then
      outline:SaveSettings()
      ide:SetStatusFor(TR("Indexing completed."))
    end
    ide:DoWhenIdle(indexFromQueue)
  end
  return
end

local function createOutlineWindow()
  local width, height = 360, 200
  local ctrl = ide:CreateTreeCtrl(ide.frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxSize(width, height), wx.wxTR_HAS_BUTTONS + wx.wxTR_NO_LINES +
    wx.wxTR_TWIST_BUTTONS + wx.wxNO_BORDER)

  outline.outlineCtrl = ctrl
  ide.timers.outline = ide:AddTimer(ctrl, function() outlineRefresh(ide:GetEditor(), false) end)
  ide.timers.symbolindex = ide:AddTimer(ctrl, function() ide:DoWhenIdle(indexFromQueue) end)
  ctrl:AddRoot("")
  ctrl:SetImageList(outline.imglist)
  ctrl:SetFont(ide:CreateFont(config.outline.fontsize or 9, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,wx.wxFONTWEIGHT_NORMAL, false, config.outline.fontname or "Segoe UI", config.fontencoding or wx.wxFONTENCODING_DEFAULT))

  function ctrl:ActivateItem(item_id)
    local data = ctrl:GetItemData(item_id)
    if ctrl:GetItemImage(item_id) == image.FILE then
      -- activate editor tab
      local editor = data:GetData()
      if not ide:GetEditorWithFocus(editor) then ide:GetDocument(editor):SetActive() end
    else
      -- activate tab and move cursor based on stored pos
      -- get file parent
      local onefile = (ide.config.outline or {}).showonefile
      local parent = ctrl:GetItemParent(item_id)
      if not onefile then -- find the proper parent
        while parent:IsOk() and ctrl:GetItemImage(parent) ~= image.FILE do
          parent = ctrl:GetItemParent(parent)
        end
        if not parent:IsOk() then return end
      end
      -- activate editor tab
      local editor = onefile and ide:GetEditor() or ctrl:GetItemData(parent):GetData()
      local cache = caches[editor]
      if editor and cache then
        ctrl:SelectItem(item_id)
        local n = data:GetData()
        local item = n > 0 and cache.funcs[n] or cache.vars[-n]
        -- if n > 0 then
        -- move to position in the file
          editor:GotoPosEnforcePolicy(item.pos-1)
        -- else
          -- editor:GotoPosEnforcePolicy(cache.vars[-n].pos-1)
          -- editor:CmdKeyExecute(wxstc.wxSTC_CMD_WORDRIGHTEXTEND)
        -- end
        editor:SetSelectionEnd(item.pos-1+#item.name)
        -- only set editor active after positioning as this may change focus,
        -- which may regenerate the outline, which may invalidate `data` value
        if not ide:GetEditorWithFocus(editor) then ide:GetDocument(editor):SetActive() end
      end
    end
  end

  local function activateByPosition(event)
    local mask = (wx.wxTREE_HITTEST_ONITEMINDENT + wx.wxTREE_HITTEST_ONITEMLABEL
      + wx.wxTREE_HITTEST_ONITEMICON)
    local item_id, flags = ctrl:HitTest(event:GetPosition())

    if item_id and item_id:IsOk() and bit.band(flags, mask) > 0 then
      ctrl:ActivateItem(item_id)
    else
      event:Skip()
    end
    return true
  end

  if (ide.config.outline or {}).activateonclick then
    ctrl:Connect(wx.wxEVT_LEFT_DOWN, activateByPosition)
  end
  ctrl:Connect(wx.wxEVT_LEFT_DCLICK, activateByPosition)
  ctrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED, function(event)
      ctrl:ActivateItem(event:GetItem())
    end)
  ctrl:Connect(wx.wxEVT_MOTION, function(event)
    local mask = (wx.wxTREE_HITTEST_ONITEMINDENT + wx.wxTREE_HITTEST_ONITEMLABEL
      + wx.wxTREE_HITTEST_ONITEMICON)
    local item_id, flags = ctrl:HitTest(event:GetPosition())
    if bit.band(flags, mask) > 0 then
      ctrl:SetCursor(wx.wxCursor(wx.wxCURSOR_HAND))
    else
      ctrl:SetCursor(wx.wxCursor(wx.wxCURSOR_ARROW))
    end
    end)

  ctrl:Connect(ID.OUTLINESORT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function()
      ide.config.outline.sort = not ide.config.outline.sort
      local ed = ide:GetEditor()
      if not ed then return end
      -- when showing one file only refresh outline for the current editor
      for editor, cache in pairs(caches) do 
        ide:SetStatus(("Refreshing '%s'..."):format(ide:GetDocument(editor):GetFileName()))
        local isexpanded = ctrl:IsExpanded(cache.fileitem)
        outlineRefresh(editor, true)
        if not isexpanded then ctrl:Collapse(cache.fileitem) end
      end
      ide:SetStatus('')
    end)

  ctrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_MENU,
    function (event)
      local menu = ide:MakeMenu {
        { ID.OUTLINESORT, TR("Sort By Name"), "", wx.wxITEM_CHECK },
      }
      menu:Check(ID.OUTLINESORT, ide.config.outline.sort)

      PackageEventHandle("onMenuOutline", menu, ctrl, event)

      ctrl:PopupMenu(menu)
    end)


  local function reconfigure(pane)
    pane:TopDockable(false):BottomDockable(false)
        :MinSize(150,-1):BestSize(300,-1):FloatingSize(200,300)
  end

  local layout = ide:GetSetting("/view", "uimgrlayout")
  local iconsize = ide:GetBestIconSize()
  if not layout or not layout:find("outlinepanel") then
    ide:AddPanelDocked(ide:GetProjectNotebook(), ctrl, "outlinepanel", TR("Symbols"), reconfigure, false, ide:GetBitmap("PROJECT", "OUTLINE", wx.wxSize(iconsize, iconsize)))
  else
    ide:AddPanel(ctrl, "outlinepanel", TR("Symbols"), reconfigure, ide:GetBitmap("PROJECT", "OUTLINE", wx.wxSize(iconsize, iconsize)))
  end
end

local function eachNode(eachFunc, root, recursive)
  local ctrl = outline.outlineCtrl
  if not ctrl then return end
  root = root or ctrl:GetRootItem()
  if not (root and root:IsOk()) then return end
  local item = ctrl:GetFirstChild(root)
  while true do
    if not item:IsOk() then break end
    if eachFunc and eachFunc(ctrl, item) then break end
    if recursive and ctrl:ItemHasChildren(item) then eachNode(eachFunc, item, recursive) end
    item = ctrl:GetNextSibling(item)
  end
end

local pathsep = GetPathSeparator()
local function isInSubDir(name, path)
  return #name > #path and path..pathsep == name:sub(1, #path+#pathsep)
end

local function isIgnoredInIndex(name)
  local ignoredirs = outline.settings.ignoredirs
  if ignoredirs[name] then return true end

  -- check through ignored dirs to see if any of them match the file;
  -- skip those that are outside of the current project tree to allow
  -- scanning of the projects that may be inside ignored directories.
  local proj = ide:GetProject() -- `nil` when not set
  for path in pairs(ignoredirs) do
    if (not proj or isInSubDir(path, proj)) and isInSubDir(name, path) then return true end
  end

  return false
end

local function purgeIndex(path)
  local symbols = outline.settings.symbols
  for name in pairs(symbols) do
    if isInSubDir(name, path) then outline:UpdateSymbols(name, nil) end
  end
end

local function purgeQueue(path)
  local curqueue = outline.indexqueue
  local newqueue = {[0] = {}}
  for _, name in ipairs(curqueue) do
    if not isInSubDir(name, path) then
      table.insert(newqueue, name)
      newqueue[0][name] = true
    end
  end
  outline.indexqueue = newqueue
end

local function disableIndex(path)
  outline.settings.ignoredirs[path] = true
  outline:SaveSettings(true)

  -- purge the path from the index and the (current) queue
  purgeIndex(path)
  purgeQueue(path)
end

local function enableIndex(path)
  outline.settings.ignoredirs[path] = nil
  outline:SaveSettings(true)
  outline:RefreshSymbols(path)
end

local lastfocus
local package = ide:AddPackage('core.outline', {
    onRegister = function(self)
      if not ide.config.outlineinactivity then return end

      createOutlineWindow()
    end,

    -- remove the editor from the list
    onEditorClose = function(self, editor)
      local cache = caches[editor]
      local fileitem = cache and cache.fileitem
      caches[editor] = nil -- remove from cache

      if fileitem and fileitem:IsOk() then
        local ctrl = outline.outlineCtrl
        ctrl:DeleteChildren(fileitem)
        ctrl:SetEvtHandlerEnabled(false)        
        if ide:GetEditorNotebook():GetPageCount() == 1 then
          ctrl:SetItemText(fileitem, "No file open")
          ctrl:SetItemImage(fileitem, -1)
          ctrl:ClearFocusedItem(fileitem)
        end
      end
    end,

    -- handle rename of the file in the current editor
    onEditorSave = function(self, editor)
      if (ide.config.outline or {}).showonefile then return end
      local cache = caches[editor]
      local fileitem = cache and cache.fileitem
      local doc = ide:GetDocument(editor)
      local ctrl = outline.outlineCtrl
      if doc and fileitem and ctrl:GetItemText(fileitem) ~= doc:GetTabText() then
        ctrl:SetItemText(fileitem, doc:GetTabText())
      end
      local path = doc and doc:GetFilePath()
      if path and cache and cache.funcs then
        outline:UpdateSymbols(path, cache.funcs.updated > editor:GetModifiedTime() and cache.funcs or nil)
        outline:SaveSettings()
      end
    end,

    -- go over the file items to turn bold on/off or collapse/expand
    onEditorFocusSet = function(self, editor)
      local cache = caches[editor]

      -- if the editor is not in the cache, which may happen if the user
      -- quickly switches between tabs that don't have outline generated,
      -- regenerate it manually
      if not cache then resetOutlineTimer() end
      resetIndexTimer()

      if (ide.config.outline or {}).showonefile and ide.config.outlineinactivity then
        -- this needs to be done when editor gets focus, but during active auto-complete
        -- the focus shifts between the editor and the popup after each character;
        -- the refresh is not necessary in this case, so only refresh when the editor changes
        if not lastfocus or editor:GetId() ~= lastfocus then
          outlineRefresh(editor, true)
          lastfocus = editor:GetId()
          local fileitem = cache and cache.fileitem
          local doc = ide:GetDocument(editor)
          local ctrl = outline.outlineCtrl
          if doc and fileitem and ctrl:GetItemText(fileitem) ~= doc:GetTabText() then
            ctrl:SetItemText(fileitem, doc:GetTabText():gsub("*", ""))
          end          
        end
        return
      end

      local fileitem = cache and cache.fileitem
      local ctrl = outline.outlineCtrl
      local itemname = ide:GetDocument(editor):GetTabText()

      -- update file name if it changed in the editor
      if fileitem and ctrl:GetItemText(fileitem) ~= itemname then
        ctrl:SetItemText(fileitem, itemname)
      end

      eachNode(function(ctrl, item)
          local found = fileitem and item:GetValue() == fileitem:GetValue()
          if not found and ctrl:IsBold(item) then
            ctrl:SetItemBold(item, false)
            ctrl:CollapseAllChildren(item)
          end
        end)

      if fileitem and not ctrl:IsBold(fileitem) then
        -- run the following changes on idle as doing them inline is causing a strange
        -- issue on OSX when clicking on a tab may skip several tabs (#546);
        -- this is somehow caused by `ExpandAllChildren` triggered from `SetFocus` inside
        -- `PAGE_CHANGED` handler for the notebook.
        ide:DoWhenIdle(function()
            -- check if this editor is still in the cache,
            -- as it may be closed before this handler is executed
            if not caches[editor] then return end
            ctrl:SetItemBold(fileitem, true)
            if (ide.config.outline or {}).showcompact then
              ctrl:Expand(fileitem)
            else
              ctrl:ExpandAllChildren(fileitem)
            end
            ctrl:ScrollTo(fileitem)
            ctrl:SetScrollPos(wx.wxHORIZONTAL, 0, true)
          end)
      end
    end,

    onMenuFiletree = function(self, menu, tree, event)
      local item_id = event:GetItem()
      local name = tree:GetItemFullName(item_id)
      local symboldirmenu = ide:MakeMenu {
        {ID.SYMBOLDIRREFRESH, TR("Refresh Index"), TR("Refresh indexed symbols from files in the selected directory")},
        {ID.SYMBOLDIRDISABLE, TR("Disable Indexing For '%s'"):format(name), TR("Ignore and don't index symbols from files in the selected directory")},
      }
      local _, _, projdirpos = ide:FindMenuItem(ID.PROJECTDIR, menu)
      if projdirpos then
        local ignored = isIgnoredInIndex(name)
        local enabledirmenu = ide:MakeMenu {}
        local paths = {}
        for path in pairs(outline.settings.ignoredirs) do table.insert(paths, path) end
        table.sort(paths)
        for i, path in ipairs(paths) do
          local id = ID("file.enablesymboldir."..i)
          enabledirmenu:Append(id, path, "")
          tree:Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED, function() enableIndex(path) end)
        end

        symboldirmenu:Append(wx.wxMenuItem(symboldirmenu, ID.SYMBOLDIRENABLE,
          TR("Enable Indexing"), "", wx.wxITEM_NORMAL, enabledirmenu))
        menu:Insert(projdirpos+1, wx.wxMenuItem(menu, ID.SYMBOLDIRINDEX,
          TR("Symbol Index"), "", wx.wxITEM_NORMAL, symboldirmenu))

        -- disable "enable" if it's empty
        menu:Enable(ID.SYMBOLDIRENABLE, #paths > 0)
        -- disable "refresh" and "disable" if the directory is ignored
        -- or if any of the directories above it are ignored
        menu:Enable(ID.SYMBOLDIRREFRESH, tree:IsDirectory(item_id) and not ignored)
        menu:Enable(ID.SYMBOLDIRDISABLE, tree:IsDirectory(item_id) and not ignored)

        tree:Connect(ID.SYMBOLDIRREFRESH, wx.wxEVT_COMMAND_MENU_SELECTED, function()
            -- purge files in this directory as some might have been removed;
            -- files will be purged based on time, but this is a good time to clean.
            purgeIndex(name)
            outline:RefreshSymbols(name)
            resetIndexTimer(1) -- start after 1ms
          end)
        tree:Connect(ID.SYMBOLDIRDISABLE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
            disableIndex(name)
          end)
       end
    end,

    onEditorUpdateUI = function(self, editor, event)
      -- only update when content or selection changes; ignore scrolling events
      if bit.band(event:GetUpdated(), wxstc.wxSTC_UPDATE_CONTENT + wxstc.wxSTC_UPDATE_SELECTION) > 0 then
        ide.outline.needrefresh = editor
      end
    end,

    onIdle = function(self)
      local editor = ide.outline.needrefresh
      if not editor then return end

      ide.outline.needrefresh = nil

      local ctrl = ide.outline.outlineCtrl
      if not ide:IsWindowShown(ctrl) then return end

      local cache = ide:IsValidCtrl(editor) and caches[editor]
      if not cache or not ide.config.outline.showcurrentfunction then return end

      local edpos = editor:GetCurrentPos()+1
      local edline = editor:LineFromPosition(edpos-1)+1
      if cache.pos and cache.pos == edpos then return end
      if cache.line and cache.line == edline then return end

      cache.pos = edpos
      cache.line = edline

      local n = 0
      local MIN, MAX = 1, 2
      local visible = {[MIN] = math.huge, [MAX] = 0}
      local needshown = {[MIN] = math.huge, [MAX] = 0}

      -- ctrl:Unselect()
      -- scan all items recursively starting from the current file
      eachNode(function(ctrl, item)
          local func = cache.funcs[ctrl:GetItemData(item):GetData()]
          if not func then
            return
          end
          local val = edpos >= func.pos and func.poe and edpos <= func.poe
          if edline == editor:LineFromPosition(func.pos)+1
          or (func.poe and edline == editor:LineFromPosition(func.poe)+1) then
            cache.line = nil
          end
          ctrl:SetItemBold(item, val)
          -- if val then ctrl:SelectItem(item, val) end

          if not ide.config.outline.jumptocurrentfunction then return end
          n = n + 1
          -- check that this and the items around it are all visible;
          -- this is to avoid the situation when the current item is only partially visible
          local isvisible = ctrl:IsVisible(item) and ctrl:GetNextVisible(item):IsOk() and ctrl:GetPrevVisible(item):IsOk()
          if val and not isvisible then
            needshown[MIN] = math.min(needshown[MIN], n)
            needshown[MAX] = math.max(needshown[MAX], n)
          elseif isvisible then
            visible[MIN] = math.min(visible[MIN], n)
            visible[MAX] = math.max(visible[MAX], n)
          end
        end, cache.fileitem, true)

      if not ide.config.outline.jumptocurrentfunction then return end
      if needshown[MAX] > visible[MAX] then
        ctrl:ScrollLines(needshown[MAX]-visible[MAX]) -- scroll forward to the last hidden line
      elseif needshown[MIN] < visible[MIN] then
        ctrl:ScrollLines(needshown[MIN]-visible[MIN]) -- scroll backward to the first hidden line
      end
    end,
  })

local function queuePath(path)
  -- only queue if symbols inactivity is set, so files will be indexed
  if ide.config.symbolindexinactivity and not outline.indexqueue[0][path] then
    outline.indexqueue[0][path] = true
    table.insert(outline.indexqueue, 1, path)
  end
end

function outline:GetFileSymbols(path)
  local symbols = self.settings.symbols[path]
  -- queue path to process when appropriate
  if not symbols then queuePath(path) end
  return symbols
end

function outline:GetEditorSymbols(editor)
  -- force token refresh (as these may be not updated yet)
  if #editor:GetTokenList() == 0 then
    while editor:IndicateSymbols() do end
  end

  -- only refresh the functions when none is present
  if not caches[editor] or #(caches[editor].funcs or {}) == 0 then outlineRefresh(editor, true) end
  return caches[editor] and caches[editor].funcs or {}
end

function outline:RefreshSymbols(path, callback)
  if isIgnoredInIndex(path) then return end

  local exts = {}
  for _, ext in pairs(ide:GetKnownExtensions()) do
    local spec = ide:FindSpec(ext)
    if spec and spec.marksymbols then table.insert(exts, ext) end
  end

  local opts = {sort = false, folder = false, skipbinary = true, yield = true,
    -- skip those directories that are on the "ignore" list
    ondirectory = function(name) return outline.settings.ignoredirs[name] == nil end
  }
  local nextfile = coroutine.wrap(function() ide:GetFileList(path, true, table.concat(exts, ";"), opts) end)
  while true do
    local file = nextfile()
    if not file then break end
    if not isIgnoredInIndex(file) then (callback or queuePath)(file) end
  end
end

function outline:UpdateSymbols(fname, symb)
  local symbols = self.settings.symbols
  symbols[fname] = symb

  -- purge outdated records
  local threshold = ide:GetTime() - 60*60*24*7 -- cache for 7 days
  if not self.indexpurged then
    for k, v in pairs(symbols) do
      if v.updated < threshold then symbols[k] = nil end
    end
    self.indexpurged = true
  end

  self.needsaving = true
end

function outline:SaveSettings(force)
  if self.needsaving or force then
    ide:PushStatus(TR("Updating symbol index and settings..."))
    package:SetSettings(self.settings, {keyignore = {depth = true, image = true, poe = true, item = true, skip = true}})
    ide:PopStatus()
    self.needsaving = false
  end
end

MergeSettings(outline.settings, package:GetSettings())
