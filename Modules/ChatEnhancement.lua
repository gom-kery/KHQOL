local _, KHQOL = ...
local Chat={frames={},boxes={},hooks={}}
KHQOL.modules.chatEnhancement=Chat
local function public(fn,...)
  if type(fn)~="function" then return end
  local values={pcall(fn,...)}
  if not values[1] then return end
  for i=2,8 do
    if type(issecretvalue)=="function" and issecretvalue(values[i]) then return end
  end
  return unpack(values,2,8)
end
local function locked(frame)
  return frame and InCombatLockdown and InCombatLockdown() and public(frame.IsProtected,frame)==true
end
function Chat:IsEnabled()
  return KHQOL.db and KHQOL.db.general and KHQOL.db.general.chatEnhancement==true
end
-- Keep native cursor/IME/Alt behavior. A bounded, per-editbox session mirror
-- of native AddHistoryLine calls supplies Up/Down on clients where native
-- recall does not run after releasing the autocomplete arrow script.
-- No chat-log scan, keyboard bindings, cursor arithmetic or saved history.
function Chat:ResetHistoryNavigation(record)
  record.historyIndex=nil;record.historyDraft=nil;record.historyPending=nil
end
function Chat:RememberHistory(box,text)
  local record=self.boxes[box]
  if not record or not self:IsEnabled() then return end
  if type(issecretvalue)=="function" and issecretvalue(text) then return end
  if type(text)~="string" or #text>8192 or not text:find("%S") then return end
  local limit=public(box.GetHistoryLines,box)
  if limit==0 then return end
  if type(limit)~="number" or limit~=limit or limit<1 or limit>128 then limit=32 end
  limit=math.floor(limit)
  record.history=record.history or {}
  local history=record.history
  if history[#history]~=text then history[#history+1]=text end
  while #history>limit do table.remove(history,1) end
  self:ResetHistoryNavigation(record)
end
local function completing(box)
  return public(function() return AutoCompleteBox and AutoCompleteBox.parent==box and AutoCompleteBox:IsShown() end)==true
end
local function historyArrowAvailable(box)
  local status,arrow=KHQOL.ReadPublicAPI(box.GetScript,box,"OnArrowPressed")
  return status=="ok" and (arrow==nil or arrow==AutoCompleteEditBox_OnArrowPressed)
end
function Chat:HistoryKey(box,key)
  if key~="UP" and key~="DOWN" then
    local record=self.boxes[box]
    if record and record.historyPending~=nil and key~="LEFT" and key~="RIGHT" then self:ResetHistoryNavigation(record) end
    return
  end
  local record=self.boxes[box];local history=record and record.history
  if not history or #history==0 or not self:IsEnabled() or locked(box) or completing(box)
    or public(box.IsShown,box)~=true or public(box.HasFocus,box)~=true then return end
  if public(IsAltKeyDown)==true or public(IsControlKeyDown)==true or public(IsShiftKeyDown)==true then return end
  -- Leave a different addon's arrow handler in control. Do not install our
  -- own OnArrowPressed: its presence can also change Left/Right behavior.
  if not historyArrowAvailable(box) then return end
  if not C_Timer or type(C_Timer.After)~="function" or type(box.SetText)~="function" then return end
  local index=record.historyIndex
  if not index then
    if key=="DOWN" then return end
    local draft=public(box.GetText,box)
    if type(draft)~="string" then return end
    record.historyDraft=draft;index=#history+1
  end
  index=math.max(1,math.min(#history+1,index+(key=="UP" and -1 or 1)))
  record.historyIndex=index
  record.historyPending=index<=#history and history[index] or record.historyDraft or ""
  if record.historyQueued then return end
  record.historyQueued=true
  -- Let native input/autocomplete finish first. A single queued callback per
  -- box coalesces key repeats and prevents a native recall from advancing twice.
  C_Timer.After(0,function()
    record.historyQueued=nil
    local text=record.historyPending;record.historyPending=nil
    if text==nil then return end
    if not Chat:IsEnabled() or locked(box) or completing(box)
      or public(box.IsShown,box)~=true or public(box.HasFocus,box)~=true or not historyArrowAvailable(box) then
      Chat:ResetHistoryNavigation(record);return
    end
    public(box.SetText,box,text)
  end)
end
function Chat:ApplyHistoryHandler(box,record,completion,active)
  if type(box.GetScript)~="function" or type(box.SetScript)~="function" then return end
  local current=public(box.GetScript,box,"OnArrowPressed")
  -- The inherited autocomplete script receives Up/Down even with no popup.
  -- Release only that stock script so the EditBox's built-in history handles
  -- those keys. Reattach it while autocomplete is visible, or when OFF.
  if active and not completion and type(AutoCompleteEditBox_OnArrowPressed)=="function"
    and current==AutoCompleteEditBox_OnArrowPressed then
    record.arrowScript=current;record.arrowReleased=true;box:SetScript("OnArrowPressed",nil)
  elseif (completion or not active) and record.arrowReleased then
    if current==nil then box:SetScript("OnArrowPressed",record.arrowScript) end
    record.arrowReleased=nil;record.arrowScript=nil
  end
end
function Chat:ApplyNavigation(box)
  local record=self.boxes[box]
  if not record or record.writing then return end
  if locked(box) then self.pending=true; return end
  local active=self:IsEnabled() and public(box.IsShown,box) and public(box.HasFocus,box)
  if not active then self:ResetHistoryNavigation(record) end
  if not self:IsEnabled() then record.history=nil end
  local completion,completionMode=public(function()
    if AutoCompleteBox then return AutoCompleteBox.parent==box and AutoCompleteBox:IsShown(),AutoCompleteBox.parentArrows end
  end)
  self:ApplyHistoryHandler(box,record,completion,active)
  if active then
    -- Autocomplete owns Up/Down while its choices are visible. Its native
    -- cached parentArrows field is left untouched; reapply after it closes.
    if completion then return end
    if not record.applied then
      local original=public(box.GetAltArrowKeyMode,box)
      if completion and type(completionMode)=="boolean" then original=completionMode end
      if type(original)~="boolean" then return end
      record.original=original; record.applied=true
    end
    if public(box.GetAltArrowKeyMode,box)~=false then
      record.writing=true;public(box.SetAltArrowKeyMode,box,false);record.writing=false
    end
  elseif not active and record.applied then
    -- Let the visible native autocomplete keep its arrow selection. Restore
    -- after it closes without rewriting its cached parentArrows field.
    if completion and public(box.IsShown,box) and public(box.HasFocus,box) then return end
    if public(box.GetAltArrowKeyMode,box)==false then
      record.writing=true;public(box.SetAltArrowKeyMode,box,record.original);record.writing=false
    end
    record.applied=nil
  end
end
function Chat:RegisterBox(box)
  if not box or self.boxes[box] or type(box.SetAltArrowKeyMode)~="function" then return end
  if locked(box) then self.pending=true; return end
  self.boxes[box]={}
  if type(box.AddHistoryLine)=="function" then
    hooksecurefunc(box,"AddHistoryLine",function(_,text) Chat:RememberHistory(box,text) end)
    if type(box.ClearHistory)=="function" then
      hooksecurefunc(box,"ClearHistory",function()
        local record=Chat.boxes[box];record.history=nil;Chat:ResetHistoryNavigation(record)
      end)
    end
    box:HookScript("OnKeyDown",function(_,key) Chat:HistoryKey(box,key) end)
    box:HookScript("OnTextChanged",function(_,userInput)
      local record=Chat.boxes[box]
      -- Native history may report its own arrow change as user input. It must
      -- not cancel the pending selection; actual typing/paste cancels below.
      if userInput==true and record.historyPending==nil then Chat:ResetHistoryNavigation(record) end
    end)
    box:HookScript("OnChar",function() Chat:ResetHistoryNavigation(Chat.boxes[box]) end)
  end
  box:HookScript("OnEditFocusGained",function() Chat:ApplyNavigation(box) end)
  box:HookScript("OnEditFocusLost",function() Chat:ApplyNavigation(box) end)
  box:HookScript("OnShow",function() Chat:ApplyNavigation(box) end)
  box:HookScript("OnHide",function() Chat:ApplyNavigation(box) end)
  -- Activation/autocomplete and other native paths can reset ignoreArrows
  -- after a focus callback. Follow that setter, without keyboard replacement,
  -- cursor arithmetic, text reads, or an independent history database.
  hooksecurefunc(box,"SetAltArrowKeyMode",function() Chat:ApplyNavigation(box) end)
  self:ApplyNavigation(box)
end
function Chat:LeaveLink(frame)
  local r=self.frames[frame]; if r then r.hoverLink=nil end
  if self.tooltipOwner==frame then
    if GameTooltip and public(GameTooltip.GetOwner,GameTooltip)==frame then
      if locked(GameTooltip) then self.pendingTooltipOwner=frame else GameTooltip:Hide() end
    end
    self.tooltipOwner=nil
  end
end
function Chat:EnterLink(frame,link)
  local hidden=type(issecretvalue)=="function" and issecretvalue(link)
  local r=self.frames[frame]; if r then r.hoverLink=hidden and true or link end
  if hidden then return end
  if not self:IsEnabled() or type(link)~="string" then return end
  if not link:match("^item:") and not link:match("^quest:") then return end
  if not GameTooltip or public(GameTooltip.IsForbidden,GameTooltip)==true then return end
  if public(GameTooltip.IsProtected,GameTooltip)==true and InCombatLockdown and InCombatLockdown() then return end
  local ok=pcall(function()
    -- Reuse the default anchor lifecycle so the existing Tooltip module keeps
    -- its native cursor anchoring, fonts, item providers and hold-time policy.
    if type(GameTooltip_SetDefaultAnchor)=="function" then GameTooltip_SetDefaultAnchor(GameTooltip,frame)
    else GameTooltip:SetOwner(frame,"ANCHOR_CURSOR_RIGHT") end
    GameTooltip:SetHyperlink(link); GameTooltip:Show()
    local tooltip=KHQOL.modules.tooltip
    if tooltip and public(tooltip.IsEnabled,tooltip) then public(tooltip.ApplyTextSize,tooltip,GameTooltip) end
  end)
  if ok then self.tooltipOwner=frame end
end
local function acceptedURL(token)
  local lower=token:lower()
  return lower:match("^https?://[^/]+") or lower:match("^www%.[%w%-]+%.")
    or lower:match("^discord%.gg/") or lower:match("^youtu%.be/")
    or lower:match("^youtube%.com/") or lower:match("^github%.com/")
end
function Chat:FindURLs(message)
  local result={}
  if type(issecretvalue)=="function" and issecretvalue(message) then return result end
  if type(message)~="string" or #message>8192 then return result end
  local function plain(segment,base)
    for start,token,finish in segment:gmatch('()([^%s<>"|]+)()') do
      local lead=token:match("^[%(%[]*") or ""
      token=token:sub(#lead+1):gsub("[.,;!%?%)%]%}]+$","")
      if #token<=2048 and acceptedURL(token) then
        local first=base+start-1+#lead
        result[#result+1]={url=token,first=first,last=first+#token-1}
      end
    end
  end
  -- Keep every Blizzard hyperlink/texture/atlas span opaque, including its label.
  -- Raw offsets feed Blizzard's own FontString character-span hit testing.
  local cursor=1
  while cursor<=#message do
    local marker=message:find("|",cursor,true)
    if not marker then plain(message:sub(cursor),cursor); break end
    plain(message:sub(cursor,marker-1),cursor)
    local tag=message:sub(marker+1,marker+1)
    if tag=="H" then
      local a=message:find("|h",marker+2,true)
      local b=a and message:find("|h",a+2,true)
      if not b then break end
      cursor=b+2
    elseif tag=="T" or tag=="A" then
      local closing=message:find(tag=="T" and "|t" or "|a",marker+2,true)
      if not closing then break end
      cursor=closing+2
    elseif tag=="c" then cursor=marker+10
    else cursor=marker+2 end
  end
  return result
end
function Chat:URLAtCursor(frame)
  if type(frame.GetScaledCursorPosition)~="function" or type(frame.FindCharacterAndLineIndexAtCoordinate)~="function" then return end
  local x,y=public(frame.GetScaledCursorPosition,frame)
  if type(x)~="number" or type(y)~="number" then return end
  local _,index=public(frame.FindCharacterAndLineIndexAtCoordinate,frame,x,y)
  local line=frame.visibleLines and frame.visibleLines[index]
  if not line then return end
  local _,inside=public(line.FindCharacterIndexAtCoordinate,line,x,y)
  if not inside then return end -- native lookup can return a nearby line outside its bounds
  local message=public(line.GetText,line)
  if type(message)~="string" then return end
  local left,bottom=public(line.GetLeft,line),public(line.GetBottom,line)
  if type(left)~="number" or type(bottom)~="number" then return end
  for _,entry in ipairs(self:FindURLs(message)) do
    local areas=public(line.CalculateScreenAreaFromCharacterSpan,line,entry.first,entry.last)
    if type(areas)=="table" then
      for _,area in ipairs(areas) do
        if x>=left+area.left and x<=left+area.left+area.width
          and y>=bottom+area.bottom and y<=bottom+area.bottom+area.height then return entry.url end
      end
    end
  end
end
function Chat:MouseDown(frame,button)
  if button~="LeftButton" or not self:IsEnabled() or frame.isUninteractable then return end
  local r=self.frames[frame]; if not r then return end
  local x,y=public(GetCursorPosition)
  r.downX=x; r.downY=y; r.wasLink=r.hoverLink~=nil
end
function Chat:MouseUp(frame,button)
  local r=self.frames[frame]; if not r then return end
  local x,y=public(GetCursorPosition)
  local valid=button=="LeftButton" and self:IsEnabled() and not frame.isUninteractable and not r.wasLink and not r.hoverLink
    and type(x)=="number" and type(y)=="number" and type(r.downX)=="number" and type(r.downY)=="number"
    and math.abs(x-r.downX)<=3 and math.abs(y-r.downY)<=3
  r.downX=nil; r.downY=nil; r.wasLink=nil
  if not valid then return end
  -- Read only the clicked visible line. Never convert messages or scan history.
  local ok,url=pcall(self.URLAtCursor,self,frame)
  if ok and url then self:ShowCopy(url) end
end
function Chat:CloseCopy()
  self.copyGeneration=(self.copyGeneration or 0)+1
  if self.copyBox then self.copyBox:ClearFocus(); self.copyFrame:Hide() end
end
function Chat:ShowCopy(url)
  if type(issecretvalue)=="function" and issecretvalue(url) then return end
  if not self:IsEnabled() or type(url)~="string" or #url>2048 or url:find("|",1,true) or not acceptedURL(url) then return end
  if not self.copyFrame then
    local UI,T=KHQOL.UI,KHQOL.UI.Theme
    local f=CreateFrame("Frame","KHQOLChatURLCopy",UIParent,"BackdropTemplate")
    self.copyFrame=f; f:SetSize(440,132); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); UI:Surface(f); f:Hide()
    UI:CreateLabel(f,"링크 복사",T.ContentPadding,-T.ContentPadding,T.SectionFontSize)
    UI:CreateButton(f,"X",400,-12,26,function() Chat:CloseCopy() end)
    local box=UI:CreateEditBox(f,T.ContentPadding,-52,400)
    self.copyBox=box
    box:SetMaxLetters(0)
    box:SetScript("OnEscapePressed",function() Chat:CloseCopy() end)
    box:SetScript("OnEnterPressed",function() Chat:CloseCopy() end)
    box:SetScript("OnKeyDown",function(_,key)
      if key=="C" and IsControlKeyDown() and C_Timer and C_Timer.After then
        local generation=Chat.copyGeneration
        -- Yield until the native EditBox has processed Ctrl+C before clearing focus.
        C_Timer.After(0,function() if Chat.copyGeneration==generation then Chat:CloseCopy() end end)
      end
    end)
    box:SetScript("OnKeyUp",function(_,key)
      if key=="C" and IsControlKeyDown() and not (C_Timer and C_Timer.After) then Chat:CloseCopy() end
    end)
    UI:CreateDescription(f,"Ctrl+C로 복사 · Esc / Enter로 닫기",T.ContentPadding,-94)
    f:SetScript("OnHide",function() box:ClearFocus() end)
    if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLChatURLCopy") end
  end
  self.copyGeneration=(self.copyGeneration or 0)+1
  self.copyFrame:Show(); self.copyBox:SetText(url); self.copyBox:SetFocus(); self.copyBox:HighlightText()
end
function Chat:ApplyFrameInput(frame)
  local r=self.frames[frame]; if not r then return end
  if locked(frame) then self.pending=true; return end
  if type(r.mouseClick)=="boolean" and type(frame.SetMouseClickEnabled)=="function" then
    local enabled=r.mouseClick
    if self:IsEnabled() then enabled=not frame.isUninteractable end
    frame:SetMouseClickEnabled(enabled)
  end
  if type(r.mouseMotion)=="boolean" and type(frame.SetMouseMotionEnabled)=="function" then
    local enabled=r.mouseMotion
    if self:IsEnabled() then enabled=not frame.isUninteractable end
    frame:SetMouseMotionEnabled(enabled)
  end
end
function Chat:RegisterFrame(frame)
  if not frame or self.frames[frame] then return end
  if locked(frame) then self.pending=true; return end
  local click=public(frame.IsMouseClickEnabled,frame)
  local motion=public(frame.IsMouseMotionEnabled,frame)
  self.frames[frame]={mouseClick=click,mouseMotion=motion}
  frame:HookScript("OnHyperlinkEnter",function(_,link) Chat:EnterLink(frame,link) end)
  frame:HookScript("OnHyperlinkLeave",function() Chat:LeaveLink(frame) end)
  frame:HookScript("OnMouseDown",function(_,button) Chat:MouseDown(frame,button) end)
  frame:HookScript("OnMouseUp",function(_,button) Chat:MouseUp(frame,button) end)
  frame:HookScript("OnHide",function() Chat:LeaveLink(frame) end)
  -- Hooking mouse scripts may auto-enable input. Restore motion immediately;
  -- enable plain-text clicks only while ON, and restore original click state OFF.
  if type(motion)=="boolean" and type(frame.SetMouseMotionEnabled)=="function" then frame:SetMouseMotionEnabled(motion) end
  self:ApplyFrameInput(frame)
  self:RegisterBox(frame.editBox or public(frame.GetEditBox,frame))
end
function Chat:DiscoverFrames()
  for _,name in ipairs(CHAT_FRAMES or {}) do self:RegisterFrame(_G[name]) end
  if not CHAT_FRAMES then
    for index=1,(NUM_CHAT_WINDOWS or 10) do self:RegisterFrame(_G["ChatFrame"..index]) end
  end
end
function Chat:ApplySettings()
  if self.pendingTooltipOwner and not locked(GameTooltip) then
    if public(GameTooltip.GetOwner,GameTooltip)==self.pendingTooltipOwner then GameTooltip:Hide() end
    self.pendingTooltipOwner=nil
  end
  self.pending=nil
  if self:IsEnabled() then self:DiscoverFrames() end
  for frame in pairs(self.frames) do self:ApplyFrameInput(frame) end
  for box in pairs(self.boxes) do self:ApplyNavigation(box) end
  if not self:IsEnabled() then
    for frame,r in pairs(self.frames) do
      self:LeaveLink(frame); r.downX=nil; r.downY=nil; r.wasLink=nil
    end
    self:CloseCopy()
  end
end
function Chat:Initialize()
  self:DiscoverFrames()
  for _,name in ipairs({"FCF_OpenNewWindow","FCF_OpenTemporaryWindow"}) do
    if type(_G[name])=="function" and not self.hooks[name] then
      self.hooks[name]=true; hooksecurefunc(name,function() Chat:DiscoverFrames() end)
    end
  end
  if type(FCF_SetUninteractable)=="function" and not self.hooks.FCF_SetUninteractable then
    self.hooks.FCF_SetUninteractable=true
    hooksecurefunc("FCF_SetUninteractable",function(frame) Chat:ApplyFrameInput(frame) end)
  end
  if type(AutoComplete_HideIfAttachedTo)=="function" and not self.hooks.AutoComplete_HideIfAttachedTo then
    self.hooks.AutoComplete_HideIfAttachedTo=true
    hooksecurefunc("AutoComplete_HideIfAttachedTo",function(box) Chat:ApplyNavigation(box) end)
  end
  if AutoCompleteBox and not self.hooks[AutoCompleteBox] then
    self.hooks[AutoCompleteBox]=true
    local function refresh() for box in pairs(Chat.boxes) do Chat:ApplyNavigation(box) end end
    AutoCompleteBox:HookScript("OnShow",refresh);AutoCompleteBox:HookScript("OnHide",refresh)
  end
  if EventRegistry and EventRegistry.RegisterCallback and not self.focusCallback then
    self.focusCallback=true
    for _,event in ipairs({"ChatFrame.OnEditBoxShow","ChatFrame.OnEditBoxFocusGained"}) do
      EventRegistry:RegisterCallback(event,function(_,box)
        if not box then return end
        Chat:RegisterFrame(box.chatFrame);Chat:RegisterBox(box);Chat:ApplyNavigation(box)
      end,self)
    end
  end
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:RegisterEvent("ADDON_LOADED"); self.events:RegisterEvent("PLAYER_ENTERING_WORLD"); self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.events:SetScript("OnEvent",function(_,event,addon)
      if event=="PLAYER_REGEN_ENABLED" then
        if Chat.pending or Chat.pendingTooltipOwner then Chat:DiscoverFrames(); Chat:ApplySettings() end
      elseif event=="PLAYER_ENTERING_WORLD" or addon=="Blizzard_ChatFrameBase" or addon=="Blizzard_ChatFrame" or addon=="Blizzard_AutoComplete" then Chat:Initialize() end
    end)
  end
  self:ApplySettings()
end
