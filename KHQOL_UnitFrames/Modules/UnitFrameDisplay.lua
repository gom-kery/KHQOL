local _,KHQOL=...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=KHQOL.modules.unitFrames
local call=KHQOL.PublicCall
local function raw(fn,...)
  if type(fn)~="function" then return false end
  return pcall(fn,...)
end
-- Native bars keep their values and scripts. This display has no Blizzard
-- callbacks and forwards opaque numbers only to secret-capable C widgets.
function M:SyncHealthDisplay(owner,p)
  local display=owner.healthDisplay
  if not display or owner.displaySyncing or not owner.compactActive or not self:IsEnabled() then return end
  owner.displaySyncing=true
  local minOK,lo,hi=raw(p.health.GetMinMaxValues,p.health)
  local valueOK,value=raw(p.health.GetValue,p.health)
  local visible=minOK and valueOK and type(lo)=="number" and type(hi)=="number" and type(value)=="number"
  if visible then
    pcall(display.SetMinMaxValues,display,lo,hi);pcall(display.SetValue,display,value)
  end
  -- This child belongs to a protected unit frame. Its values can still update
  -- in combat, but PLAYER_REGEN_ENABLED must re-evaluate visibility afterward.
  if call(InCombatLockdown)==true then
    owner.healthVisibilityPending=true;self.pending=true
  else
    if visible then display:Show() else display:Hide() end
    owner.healthVisibilityPending=nil
  end
  owner.displaySyncing=false
end
function M:PrepareHealthDisplay(owner,p,unit,width,height,left,top)
  if unit~="player" and unit~="target" and unit~="focus" then return end
  if not owner.healthDisplay then
    local f=CreateFrame("StatusBar",nil,p.root)
    f:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");f:EnableMouse(false)
    local fill=call(f.GetStatusBarTexture,f);if fill and type(fill.SetDrawLayer)=="function" then fill:SetDrawLayer("BACKGROUND",-1) end
    owner.healthDisplay=f;owner.nativeTextCopies={}
    for _,method in ipairs({"SetValue","SetMinMaxValues"}) do
      if type(p.health[method])=="function" then hooksecurefunc(p.health,method,function()
        if M:IsEnabled() then M:SyncHealthDisplay(owner,owner.parts) end
      end) end
    end
  end
  local display=owner.healthDisplay
  display:ClearAllPoints();display:SetPoint("TOPLEFT",p.root,"TOPLEFT",left,top);display:SetSize(width,height)
  local levelHost=p.main or p.root
  local nativeLevel=call(levelHost.GetFrameLevel,levelHost) or 1;display:SetFrameLevel(nativeLevel)
  if owner.background then owner.background:ClearAllPoints();owner.background:SetPoint("TOPLEFT",display,"TOPLEFT",0,0) end
  local texture=call(p.health.GetStatusBarTexture,p.health)
  self:HideNativeDecoration(owner,texture)
  self:SyncHealthDisplay(owner,p)
  self:SyncDisplayText(owner,p)
end
function M:SyncDisplayText(owner,p,fromNativeHook)
  local display=owner.healthDisplay
  if not display or not owner.compactActive or owner.displayTextWriting or owner.artWriting then return end
  owner.displayTextWriting=true
  local mode=self:GetDB()[p.unit].health
  local objects={{p.health.TextString,"CENTER"},{p.health.LeftText,"LEFT"},{p.health.RightText,"RIGHT"},
    {p.healthContainer.DeadText,"CENTER",true},{p.healthContainer.UnconsciousText,"CENTER",true}}
  for _,entry in ipairs(objects) do
    local source,side,always=entry[1],entry[2],entry[3]
    if source then
      local record=owner.nativeTextCopies[source]
      if not record then
        record={copy=display:CreateFontString(nil,"OVERLAY",nil,7)};owner.nativeTextCopies[source]=record
        for _,method in ipairs({"SetText","SetFormattedText","Show","Hide","SetAlpha","SetTextColor"}) do
          if type(source[method])=="function" then hooksecurefunc(source,method,function() M:SyncDisplayText(owner,owner.parts,true) end) end
        end
      end
      local copy=record.copy
      if call(InCombatLockdown)~=true then
        local font,size,flags=call(source.GetFont,source)
        if font and size then copy:SetFont(font,size,M:HealthTextFlags(flags)) else copy:SetFont(KHQOL.UI:Font(),12,M:HealthTextFlags()) end
        if copy.SetShadowColor then copy:SetShadowColor(0,0,0,1) end
        if copy.SetShadowOffset then copy:SetShadowOffset(1,-1) end
        copy:ClearAllPoints();copy:SetPoint("LEFT",display,"LEFT",2,0);copy:SetPoint("RIGHT",display,"RIGHT",-2,0)
        copy:SetJustifyH(side);copy:SetJustifyV("MIDDLE")
      end
      if mode=="default" or always then
        local textOK,text=raw(source.GetText,source)
        if textOK and type(text)=="string" then pcall(copy.SetText,copy,text) else copy:SetText("") end
        local colorOK,r,g,b,a=raw(source.GetTextColor,source)
        if colorOK and type(r)=="number" and type(g)=="number" and type(b)=="number" then pcall(copy.SetTextColor,copy,r,g,b,a)
        else copy:SetTextColor(1,1,1,1) end
        local shownOK,shown=raw(source.IsShown,source)
        if shownOK and type(shown)=="boolean" and type(copy.SetAlphaFromBoolean)=="function" then
          pcall(copy.SetAlphaFromBoolean,copy,shown,1,0);copy:Show()
        elseif call(source.IsShown,source)==true then copy:Show() else copy:Hide() end
      else copy:Hide() end
      -- Native alpha hooks capture the external value before suppressing it.
      -- A text mirror hook must not overwrite it or restart suppression.
      if not fromNativeHook then self:HideNativeDecoration(owner,source) end
    end
  end
  owner.displayTextWriting=false
end
