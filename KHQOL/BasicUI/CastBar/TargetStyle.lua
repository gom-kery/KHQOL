local _,K=...
local C=K.modules.castBar
local call=K.PublicCall

-- Blizzard owns the cast lifecycle. Forward widget values as-is to the
-- corresponding display setters. A restricted value never drives Lua logic.
local function copyValue(destination,setter,source,getter)
  if not source or type(source[getter])~="function" then return false end
  local ok,a,b=pcall(source[getter],source)
  if not ok then return false end
  local sent
  if getter=="GetMinMaxValues" then sent=pcall(destination[setter],destination,a,b)
  else sent=pcall(destination[setter],destination,a) end
  return sent
end

function C:SyncTargetCastVisibility(owner)
  local bar,source=owner.bar,owner.source
  if not owner.active or not self:IsEnabled() or not self.db.targetPosition.enabled
    or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true then
    self:SetTargetNativeAlpha(owner,false)
    bar:Hide()
    return
  end
  if not owner.valuesReady then return end
  if not copyValue(bar,"SetShown",source,"IsVisible") then
    self:SetTargetNativeAlpha(owner,false)
    bar:Hide()
    return
  end
  if not self:SetTargetNativeAlpha(owner,true) then bar:Hide() end
end

function C:SetTargetNativeAlpha(owner,suppress)
  if suppress==owner.suppressed then return true end
  owner.writingAlpha=true
  local ok=pcall(owner.source.SetAlpha,owner.source,suppress and 0 or owner.nativeAlpha)
  owner.writingAlpha=false
  if ok then owner.suppressed=suppress end
  return ok
end

function C:SyncTargetCastValues(owner)
  if not owner.active then return end
  local bar,source=owner.bar,owner.source
  owner.valuesReady=copyValue(bar,"SetMinMaxValues",source,"GetMinMaxValues")
    and copyValue(bar,"SetValue",source,"GetValue")
  if not owner.valuesReady then
    self:SetTargetNativeAlpha(owner,false)
    bar:Hide()
    return
  end
  if not copyValue(owner.icon,"SetTexture",source.Icon,"GetTexture") then owner.icon:SetTexture(nil) end
  if not copyValue(owner.name,"SetText",source.Text,"GetText") then owner.name:SetText("") end
  if not copyValue(owner.time,"SetText",source.CastTimeText,"GetText") then owner.time:SetText("") end
  self:SyncTargetCastVisibility(owner)
end

function C:CreateTargetCastDisplay(source,root)
  self.targetDisplays=self.targetDisplays or setmetatable({}, {__mode="k"})
  local owner=self.targetDisplays[source]
  if owner then return owner end
  -- An independent UIParent bar is never moved by TargetSpellBar:AdjustPosition.
  local bar=CreateFrame("StatusBar",nil,UIParent)
  bar:EnableMouse(false);bar:SetFrameStrata("MEDIUM");bar:Hide()
  local background=bar:CreateTexture(nil,"BACKGROUND",nil,-1)
  background:SetTexture(self.textures.FLAT);background:SetAllPoints(bar)
  owner={bar=bar,source=source,background=background,active=false,suppressed=false,nativeAlpha=1}
  owner.icon=bar:CreateTexture(nil,"ARTWORK")
  owner.name=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  owner.time=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  owner.name:SetWordWrap(false);owner.name:SetMaxLines(1)
  self.targetDisplays[source]=owner

  for _,method in ipairs({"SetMinMaxValues","SetValue"}) do
    if type(source[method])=="function" then
      hooksecurefunc(source,method,function(_,...)
        if owner.active and not pcall(bar[method],bar,...) then
          owner.valuesReady=false
          C:SetTargetNativeAlpha(owner,false);bar:Hide()
        end
      end)
    end
  end
  hooksecurefunc(source,"SetAlpha",function(_,alpha)
    if owner.writingAlpha then return end
    owner.nativeAlpha=alpha
    if owner.active then
      pcall(bar.SetAlpha,bar,alpha)
      if owner.suppressed then
        owner.suppressed=false
        if not C:SetTargetNativeAlpha(owner,true) then bar:Hide() end
      end
    end
  end)
  for _,entry in ipairs({{source.Text,owner.name,"SetText"},{source.CastTimeText,owner.time,"SetText"},
      {source.Icon,owner.icon,"SetTexture"}}) do
    local original,copy,method=unpack(entry)
    if original and type(original[method])=="function" then
      hooksecurefunc(original,method,function(_,value)
        if owner.active and not pcall(copy[method],copy,value) then copy[method](copy,method=="SetText" and "" or nil) end
      end)
    end
  end
  source:HookScript("OnShow",function() C:SyncTargetCastValues(owner) end)
  source:HookScript("OnHide",function() if owner.active then bar:Hide() end end)
  root:HookScript("OnHide",function() if owner.active then bar:Hide() end end)
  root:HookScript("OnShow",function()
    if K.WindowLayers:OutsideCombat() then C:ApplyTargetPosition()
    else C:SyncTargetCastValues(owner) end
  end)
  if type(source.UpdateBarFillTexture)=="function" then
    hooksecurefunc(source,"UpdateBarFillTexture",function()
      if owner.active then bar:SetStatusBarColor(unpack(owner.normalColor)) end
    end)
  end
  if type(source.PlayInterruptAnims)=="function" then
    hooksecurefunc(source,"PlayInterruptAnims",function()
      if owner.active then bar:SetStatusBarColor(unpack(owner.interruptedColor)) end
    end)
  end
  return owner
end

function C:ReleaseTargetCastDisplay()
  local owner=self.targetDisplay
  if not owner then return end
  owner.active=false
  owner.bar:Hide()
  self:SetTargetNativeAlpha(owner,false)
  if not owner.suppressed then self.targetDisplay=nil end
end

function C:ApplyTargetCastDisplay(source,root,left,top,scale)
  local owner=self:CreateTargetCastDisplay(source,root)
  if self.targetDisplay~=owner then
    self:ReleaseTargetCastDisplay()
    if self.targetDisplay then return false end
    self.targetDisplay=owner
  end
  if not owner.suppressed then owner.nativeAlpha=call(source.GetAlpha,source) or 1 end
  local db=self:GetDB()
  local style=db.targetStyle
  local art=style.appearance
  local bar=owner.bar
  local icon=style.icon
  local width=math.max(1,art.width-(icon.enabled and icon.size+2 or 0))
  owner.normalColor,owner.interruptedColor=art.barColor,art.interruptedColor
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/scale,top/scale)
  bar:SetScale(scale)
  bar:SetSize(width,art.height)
  bar:SetStatusBarTexture(self.textures[art.texture])
  bar:SetStatusBarColor(unpack(art.barColor))
  owner.background:SetVertexColor(unpack(art.backgroundColor))
  local iconLeft=icon.position=="left"
  owner.icon:ClearAllPoints();owner.icon:SetPoint(iconLeft and "RIGHT" or "LEFT",bar,iconLeft and "LEFT" or "RIGHT",iconLeft and -2 or 2,0)
  owner.icon:SetSize(icon.size,icon.size);owner.icon:SetShown(icon.enabled and source.Icon~=nil)
  local function text(region,settings,available,fraction)
    self:AnchorText(region,settings,bar)
    region:SetWidth(math.max(1,width*fraction))
    region:SetShown(settings.enabled and available)
  end
  text(owner.name,style.spellName,source.Text~=nil,.65)
  text(owner.time,db.castTime,source.CastTimeText~=nil,.3)
  pcall(bar.SetAlpha,bar,owner.nativeAlpha)
  owner.active=true
  self:SyncTargetCastValues(owner)
  return true
end
