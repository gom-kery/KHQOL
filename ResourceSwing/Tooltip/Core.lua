local _, KHQOL = ...
local Tooltip = KHQOL.modules.tooltip
Tooltip.providers = {}; Tooltip.weaponGuide = {}
Tooltip.defaults = { textSize = 0, weaponGuide = true, showHealthBar = true, showTarget = false, mouseRight = false, x = 0, y = 0, holdTimeOffset = 0, showPlayerInfo = true, hideUnitTooltipInCombat = false }
-- Retail tooltips can contain secret values even when their Lua type is string.
-- Never inspect, compare, concatenate, or forward those values to unit APIs.
local function isSecret(value) return type(issecretvalue)=="function" and issecretvalue(value) end
local function publicUnit(value) return not isSecret(value) and type(value)=="string" and value~="" end
local publicCall = KHQOL.PublicCall
local function unitToken(tooltip,fallback)
  if tooltip and tooltip.GetUnit then
    local ok,_,unit=pcall(tooltip.GetUnit,tooltip)
    -- A public fallback must not bypass a secret current tooltip unit.
    if not ok or isSecret(unit) then return end
    if publicUnit(unit) then return unit end
  end
  if publicUnit(fallback) then return fallback end
end
local function unitGUID(unit)
  if not publicUnit(unit) then return end
  local guid=publicCall(UnitGUID,unit)
  if publicUnit(guid) then return guid end
end
Tooltip.PublicCall=publicCall
Tooltip.IsSecretValue=isSecret
Tooltip.IsPublicUnit=publicUnit
function Tooltip:GetReadableUnit(tooltip,fallback) return unitToken(tooltip,fallback) end
function Tooltip:GetReadableGUID(unit) return unitGUID(unit) end
function Tooltip:CanModifyTooltip(tooltip)
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return false end
  if tooltip.GetUnit then
    local ok,_,unit=pcall(tooltip.GetUnit,tooltip)
    if not ok or isSecret(unit) then return false end
  end
  local name=publicCall(tooltip.GetName,tooltip)
  local count=publicCall(tooltip.NumLines,tooltip)
  if type(name)~="string" or type(count)~="number" then return false end
  for i=1,count do
    for _,side in ipairs({"TextLeft","TextRight"}) do
      local line=_G[name..side..i]
      if line then
        for _,method in ipairs({"GetText","GetFont","GetTextColor"}) do
          if line[method] then
            local function readable(...)
              for j=1,select("#",...) do if isSecret(select(j,...)) then return false end end
              return true
            end
            local ok,valuesPublic=pcall(function() return readable(line[method](line)) end)
            if not ok or not valuesPublic then return false end
          end
        end
      end
    end
  end
  return true
end
local function copyMissing(target, source) for key, value in pairs(source) do if target[key] == nil then target[key] = value end end return target end
function Tooltip:GetDB() local db=copyMissing(KHQOL.db.modules.tooltip or {}, self.defaults); if db.mouseRight==nil then db.mouseRight=db.position and db.position~="DEFAULT" or false end; db.position=nil; KHQOL.db.modules.tooltip=db; return db end
function Tooltip:IsEnabled() return KHQOL:GetEnabled("tooltip") end
function Tooltip:RegisterProvider(key, provider) self.providers[key] = provider end
function Tooltip:ApplyTextSize(tooltip)
  if not self:CanModifyTooltip(tooltip) then return end
  local name, delta = tooltip:GetName(), self:GetDB().textSize or 0; if not name then return end
  local unit=unitToken(tooltip)
  local player=unit and publicCall(UnitIsPlayer,unit)==true
  local body=_G[name.."TextLeft2"]
  if body and not body.__KHQOLTooltipFont then body.__KHQOLTooltipFont={body:GetFont()} end
  local bodySize=body and body.__KHQOLTooltipFont and body.__KHQOLTooltipFont[2]
  local changed=false
  for _, suffix in ipairs({ "TextLeft", "TextRight" }) do
    for index = 1, tooltip:NumLines() do
      local line = _G[name .. suffix .. index]
      if line and line.GetFont and line.SetFont then
        line.__KHQOLTooltipFont = line.__KHQOLTooltipFont or { line:GetFont() }
        local font,size,flags=unpack(line.__KHQOLTooltipFont)
        if player and suffix=="TextLeft" and index==1 and bodySize then size=bodySize+2 end
        local path=KHQOL.modules.clock and KHQOL.modules.clock.FONT_PATH or font
        if path and size then
          local desired=math.max(1,size+delta)
          local currentFont,currentSize,currentFlags=line:GetFont()
          if currentFont~=path or currentSize~=desired or (currentFlags or "")~=(flags or "") then
            line:SetFont(path,desired,flags or ""); changed=true
          end
        end
      end
    end
  end
  -- Show performs native size/layout calculation; AppendText("") does not
  -- reliably remeasure font changes.  Never change tooltip frame anchors.
  if changed and tooltip:IsShown() and not tooltip.__KHQOLMeasuring then
    tooltip.__KHQOLMeasuring=true; tooltip:Show(); tooltip.__KHQOLMeasuring=nil
  end
  return changed
end
function Tooltip:EnsurePlayerNameSize(tooltip,unit)
  local current=unitToken(tooltip)
  local guid=unitGUID(unit)
  if guid and unitGUID(current)==guid then self:ApplyTextSize(tooltip) end
end
function Tooltip:ApplyHealthBar(tooltip)
  if self:GetDB().showHealthBar ~= false then return end
  local name = tooltip and tooltip.GetName and tooltip:GetName(); local bar = name and _G[name .. "StatusBar"]; if bar then bar:Hide() end
end
function Tooltip:ApplyUnitFont(tooltip)
  if not self:CanModifyTooltip(tooltip) then return end
  local path=KHQOL.modules.clock and KHQOL.modules.clock.FONT_PATH
  local name=tooltip and tooltip.GetName and tooltip:GetName()
  if not path or not name then return end
  for _,side in ipairs({"TextLeft","TextRight"}) do for i=1,tooltip:NumLines() do local line=_G[name..side..i]; if line and line.GetFont and line.SetFont then local _,size,flags=line:GetFont(); if size then line:SetFont(path,size,flags or "") end end end end
end
local localizedSpecs={
  WARRIOR={"무기","분노","방어"}, PALADIN={"신성","보호","징벌"}, HUNTER={"야수","사격","생존"},
  ROGUE={"암살","전투","잠행"}, PRIEST={"수양","신성","암흑"}, SHAMAN={"정기","고양","복원"},
  MAGE={"비전","화염","냉기"}, WARLOCK={"고통","악마","파괴"}, DRUID={"조화","야성","회복"},
}
local localizedClasses={
  WARRIOR="전사", PALADIN="성기사", HUNTER="사냥꾼", ROGUE="도적", PRIEST="사제",
  SHAMAN="주술사", MAGE="마법사", WARLOCK="흑마법사", DRUID="드루이드",
}
local englishSpecs={
  WARRIOR={"Arms","Fury","Protection"}, PALADIN={"Holy","Protection","Retribution"}, HUNTER={"Beast Mastery","Marksmanship","Survival"},
  ROGUE={"Assassination","Combat","Subtlety"}, PRIEST={"Discipline","Holy","Shadow"}, SHAMAN={"Elemental","Enhancement","Restoration"},
  MAGE={"Arcane","Fire","Frost"}, WARLOCK={"Affliction","Demonology","Destruction"}, DRUID={"Balance","Feral Combat","Restoration"},
}
function Tooltip:ClearInformationRightColumn(tooltip,index)
  if not self:IsEnabled() or tooltip.__KHQOLClearingRight then return end
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  local name=tooltip:GetName(); if not name then return end
  local left=_G[name.."TextLeft"..index]; local right=_G[name.."TextRight"..index]
  local text=left and left:GetText()
  if isSecret(text) or type(text)~="string" or not right then return end
  local plain=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  -- These are single-column information rows.  A tooltip FontString may
  -- still hold the right-hand target name from an earlier row at this index.
  if plain:find("전문화:",1,true) or plain:find("특성 :",1,true) or plain:find("아이템 레벨:",1,true) then
    if not self:CanModifyTooltip(tooltip) then return end
    tooltip.__KHQOLClearingRight=true
    if (right:GetText() or "")~="" then right:SetText("") end
    right:Hide()
    tooltip.__KHQOLClearingRight=nil
  end
end
function Tooltip:FormatSpecializationText(text,unit)
  if isSecret(text) or type(text)~="string" or not publicUnit(unit) then return text end
  if not text:find("전문화:",1,true) or publicCall(UnitIsPlayer,unit)~=true then return text end
  local _,token=publicCall(UnitClass,unit); local names=localizedSpecs[token]
  if not names then return text end
  local plain=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  local a,b,c=plain:match("%((%d+)%/(%d+)%/(%d+)%)")
  local index
  if a and tonumber(a)+tonumber(b)+tonumber(c)>0 then
    a,b,c=tonumber(a),tonumber(b),tonumber(c)
    index=1; if b>a and b>=c then index=2 elseif c>a and c>b then index=3 end
  else
    for i=1,3 do
      if plain:find(englishSpecs[token][i],1,true) or plain:find(names[i],1,true) then index=i; break end
    end
  end
  if not index then return text end
  local icon=plain:match("|T.-|t%s*(|T.-|t)") or plain:match("(|T.-|t)") or ""
  local points=a and string.format(" (%d/%d/%d)",tonumber(a),tonumber(b),tonumber(c)) or ""
  return "|cffffd100전문화:|r "..icon..(icon~="" and " " or "").."|cffffffff"..names[index].."|r|cffffd100"..points.."|r"
end
function Tooltip:WatchSpecializationLines(tooltip)
  if not self:IsEnabled() or tooltip.__KHQOLFormattingSpec then return end
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  local unit=unitToken(tooltip); local prefix=tooltip:GetName()
  if not unit or not prefix or publicCall(UnitIsPlayer,unit)~=true or not self:CanModifyTooltip(tooltip) then return end
  for i=1,tooltip:NumLines() do
    local line=_G[prefix.."TextLeft"..i]
    if line then
      local function localize(current)
        if tooltip.__KHQOLFormattingSpec or not Tooltip:IsEnabled() then return end
        local liveUnit=unitToken(tooltip)
        if not liveUnit or publicCall(UnitIsPlayer,liveUnit)~=true or not Tooltip:CanModifyTooltip(tooltip) then return end
        local text=current:GetText(); local formatted=Tooltip:FormatSpecializationText(text,liveUnit)
        if text~=formatted then
          tooltip.__KHQOLFormattingSpec=true; current:SetText(formatted); tooltip.__KHQOLFormattingSpec=nil
        end
      end
      if not line.__KHQOLSpecWatched and type(hooksecurefunc)=="function" then
        line.__KHQOLSpecWatched=true
        hooksecurefunc(line,"SetText",localize)
      end
      localize(line)
    end
    local right=_G[prefix.."TextRight"..i]
    if right and not right.__KHQOLInfoRightWatched and type(hooksecurefunc)=="function" then
      right.__KHQOLInfoRightWatched=true
      local index=i
      hooksecurefunc(right,"SetText",function() Tooltip:ClearInformationRightColumn(tooltip,index) end)
    end
    self:ClearInformationRightColumn(tooltip,i)
  end
end
function Tooltip:RemoveTooltipLine(tooltip,index)
  if not self:CanModifyTooltip(tooltip) then return end
  local name=tooltip:GetName(); local last=tooltip:NumLines()
  for row=index,last-1 do
    for _,side in ipairs({"TextLeft","TextRight"}) do
      local here=_G[name..side..row]; local nextLine=_G[name..side..(row+1)]
      if here and nextLine then
        here:SetText(nextLine:GetText() or "")
        local r,g,b,a=nextLine:GetTextColor(); if r then here:SetTextColor(r,g,b,a) end
      end
    end
  end
  for _,side in ipairs({"TextLeft","TextRight"}) do local tail=_G[name..side..last]; if tail then tail:SetText("") end end
end
function Tooltip:NormalizeSpecializationLines(tooltip,unit)
  if not publicUnit(unit) or publicCall(UnitIsPlayer,unit)~=true or not self:CanModifyTooltip(tooltip) then return end
  local _,classToken=publicCall(UnitClass,unit); local names=localizedSpecs[classToken]
  if not names then return end
  local prefix=tooltip:GetName(); if not prefix then return end
  local rows={}
  for i=1,tooltip:NumLines() do
    local line=_G[prefix.."TextLeft"..i]; local text=line and line:GetText()
    if text and text:find("전문화:",1,true) then rows[#rows+1]={index=i,line=line,text=text} end
  end
  if #rows==0 then return end
  -- A zero-value row can arrive before the actual inspect payload.  Prefer
  -- whichever specialization row already has real invested ranks.
  local first,a,b,c
  for _,row in ipairs(rows) do
    local plain=row.text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local x,y,z=plain:match("%((%d+)%/(%d+)%/(%d+)%)")
    x,y,z=tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0
    if x+y+z>0 then first,a,b,c=row,x,y,z; break end
  end
  if not first then
    -- Keep one temporary row only; a later real-rank row will replace it.
    for n=#rows,2,-1 do self:RemoveTooltipLine(tooltip,rows[n].index) end
    return
  end
  local index=1; if b>a and b>=c then index=2 elseif c>a and c>b then index=3 end
  local icon=first.text:match("|T.-|t%s*(|T.-|t)") or first.text:match("(|T.-|t)") or ""
  local points=string.format("(%d/%d/%d)",a,b,c)
  local keep=rows[1].line
  local formatted="전문화: "..icon..(icon~="" and " " or "").."|cffffffff"..names[index].."|r "..points
  formatted=self:FormatSpecializationText(formatted,unit)
  if keep:GetText()~=formatted then keep:SetText(formatted) end
  keep:SetTextColor(1,.82,0)
  -- Other modules may add the same row after KHQOL.  Keep exactly one.
  for n=#rows,2,-1 do self:RemoveTooltipLine(tooltip,rows[n].index) end
end
function Tooltip:ApplyUnitPresentation(tooltip,unit)
  if not publicUnit(unit) or publicCall(UnitIsPlayer,unit)~=true or not self:CanModifyTooltip(tooltip) then return end
  local className,classToken=publicCall(UnitClass,unit)
  local displayClass=(classToken and localizedClasses[classToken]) or className
  local classColor=classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
  local guildName=publicCall(GetGuildInfo,unit)
  local name=tooltip.GetName and tooltip:GetName()
  if not name then return end
  local levelLine,levelText,separateClassRow,separateClassText
  local function plainText(text)
    return (text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  end
  for i=1,tooltip:NumLines() do
    local left=_G[name.."TextLeft"..i]
    local value=left and left.GetText and left:GetText()
    if value then
      if guildName and value==guildName then
        left:SetText("<"..guildName..">")
      elseif displayClass and (value:find("(플레이어)",1,true) or value:find("(Player)",1,true)) then
        levelLine,levelText=left,value
      elseif displayClass and (plainText(value)==displayClass or plainText(value)==className) then
        separateClassRow,separateClassText=i,value
      end
    end
  end
  -- Reuse Blizzard's own class row, including its native color markup, rather
  -- than computing or applying a class color ourselves.
  if levelLine and separateClassRow and separateClassText then
    levelLine:SetText((levelText:gsub("%s*%b()"," "..separateClassText,1)))
    self:RemoveTooltipLine(tooltip,separateClassRow)
  end
  -- Color the current name directly; FontStrings are reused between units.
  local title=_G[name.."TextLeft1"]
  if title and classColor then
    title:SetTextColor(classColor.r,classColor.g,classColor.b)
  end
  self:NormalizeSpecializationLines(tooltip,unit)
  self:EnsurePlayerNameSize(tooltip,unit)
end
function Tooltip:ConfigureHealthBar()
  local bar = _G.GameTooltipStatusBar
  if not bar then return end
  if not self.healthBarHooked then
    self.healthBarHooked = true
    bar:HookScript("OnShow", function(statusBar)
      if Tooltip:IsEnabled() and Tooltip:GetDB().showHealthBar == false then statusBar:Hide() end
    end)
  end
  if self:GetDB().showHealthBar == false then bar:Hide() end
end
function Tooltip:Anchor(tooltip)
  local mode = self:GetDB().position
  if mode == "DEFAULT" or not tooltip or tooltip ~= GameTooltip then return end
  if not self.anchorFrame then
    self.anchorFrame = CreateFrame("Frame", "KHQOLTooltipCursorAnchor", UIParent)
    self.anchorFrame:SetSize(1, 1)
  end
  self:MoveAnchorFrame()
  -- GameTooltip itself is anchored only once.  Moving the tiny anchor frame
  -- avoids repeated ClearAllPoints calls that could transiently stretch the
  -- tooltip while Blizzard is rebuilding its contents.
  tooltip:ClearAllPoints(); tooltip:SetPoint("BOTTOMLEFT", self.anchorFrame, "BOTTOMLEFT"); tooltip:SetClampedToScreen(true)
end
function Tooltip:MoveAnchorFrame()
  if not self.anchorFrame then return end
  local mode = self:GetDB().position
  local x, y = GetCursorPosition(); local scale = UIParent:GetEffectiveScale(); x, y = x / scale, y / scale
  local offsetX, offsetY = 18, 0
  if mode == "CURSOR_TOPRIGHT" then offsetY = 18 end
  if mode == "CURSOR_BOTTOMRIGHT" then offsetY = -18 end
  self.anchorFrame:ClearAllPoints(); self.anchorFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
  self.anchorFrame.cursorX, self.anchorFrame.cursorY = x, y
end
function Tooltip:FollowCursor(tooltip)
  if not self:IsEnabled() or self:GetDB().position == "DEFAULT" or not tooltip:IsShown() then return end
  local now = GetTime()
  if now < (tooltip.__KHQOLTooltipReadyAt or 0) or now < (tooltip.__KHQOLTooltipNextFollow or 0) then return end
  tooltip.__KHQOLTooltipNextFollow = now + .05
  local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale(); x,y=x/scale,y/scale
  if self.anchorFrame and (self.anchorFrame.cursorX ~= x or self.anchorFrame.cursorY ~= y) then self:MoveAnchorFrame() end
end
function Tooltip:ScheduleAnchor(tooltip)
  if not self:IsEnabled() or self:GetDB().position == "DEFAULT" or not tooltip or tooltip.__KHQOLAnchorQueued then return end
  tooltip.__KHQOLAnchorQueued = true
  local function apply()
    tooltip.__KHQOLAnchorQueued = nil
    if Tooltip:IsEnabled() and tooltip:IsShown() then Tooltip:Anchor(tooltip) end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0, apply) else apply() end
end
function Tooltip:ApplyCursorAnchor(tooltip, parent)
  local db=self:GetDB()
  if not db.mouseRight or not tooltip or not tooltip.SetOwner then return end
  -- Native cursor anchoring: this is the same lifecycle pattern used by the
  -- referenced Tooltip addons.  Blizzard owns cursor tracking; KHQOL applies
  -- the anchor once while the default anchor is being established.
  tooltip:SetOwner(parent or UIParent, "ANCHOR_CURSOR_RIGHT", db.x or 0, db.y or 0)
end
function Tooltip:ApplyHoldTime()
  if type(GameTooltip.fadeOutTime) ~= "number" then return end
  self.originalFadeOutTime = self.originalFadeOutTime or GameTooltip.fadeOutTime
  GameTooltip.fadeOutTime = math.max(0, self.originalFadeOutTime + (self:GetDB().holdTimeOffset or 0))
end
function Tooltip:RunProviders(tooltip, itemID)
  if not self:IsEnabled() then return end
  local lines = {}; for _, provider in pairs(self.providers) do if (provider.IsEnabled == nil or provider:IsEnabled()) and provider.GetLines then local result=provider:GetLines({kind="item",id=itemID,itemID=itemID}); if result then for _,line in ipairs(result) do lines[#lines+1]=line end end end end
  if #lines == 0 then return end; tooltip:AddLine("────────────",.55,.55,.55,true); for _,line in ipairs(lines) do tooltip:AddLine(line.text or line,line.r or 1,line.g or 1,line.b or 1,line.wrap ~= false) end; tooltip:Show()
end
function Tooltip:OnItem(tooltip,itemID)
  if isSecret(itemID) or not self:CanModifyTooltip(tooltip) or not self:IsEnabled() or tooltip.__KHQOLTooltipItemID == itemID then return end
  tooltip.__KHQOLTooltipItemID=itemID; self:RunProviders(tooltip,itemID); self:ApplyTextSize(tooltip)
  -- Data processors can finish before Blizzard applies the bag-tooltip anchor.
  -- Reattach once on the next frame, then let only the anchor frame move.
end
local function targetDisplayName(unit)
  if not publicUnit(unit) or not publicCall(UnitExists,unit) then return end
  if publicCall(UnitIsUnit,unit,"player")==true then return "< 나 >" end
  if type(UnitName)~="function" then return end
  -- Forever returns the surname separately, not as a realm suffix.
  local ok,name,surname=pcall(UnitName,unit)
  if not ok or isSecret(name) or isSecret(surname) or type(name)~="string" or name=="" then return end
  if type(surname)=="string" and surname~="" then
    local separator=Constants and Constants.CharacterNameSeparatorConsts and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR
    if isSecret(separator) or type(separator)~="string" or separator=="" then separator=" " end
    local suffix=separator..surname
    if name:sub(-#suffix)~=suffix then name=name..suffix end
  end
  return name
end
function Tooltip:UpdateUnitTarget(tooltip)
  if not self:IsEnabled() or self:GetDB().showTarget~=true or not publicUnit(tooltip.__KHQOLTargetUnit) or not unitToken(tooltip) then return end
  if not self:CanModifyTooltip(tooltip) then return end
  local target=tooltip.__KHQOLTargetUnit.."target"
  local text=targetDisplayName(target) or "-"
  local prefix=tooltip:GetName(); local count=tooltip:NumLines()
  local cached=tooltip.__KHQOLTargetLine
  if cached and tooltip.__KHQOLTargetCount==count and tooltip.__KHQOLTargetText==text then
    local left=_G[prefix.."TextLeft"..cached]; local right=_G[prefix.."TextRight"..cached]
    local stable=left and left:GetText()=="대상" and right and right:GetText()==text
    -- Existing blank rows can receive late data without AddLine. Don't let
    -- a stable footer shortcut conceal that data or leave the target above it.
    for i=cached+1,count do
      local l,r=_G[prefix.."TextLeft"..i],_G[prefix.."TextRight"..i]
      if (l and (l:GetText() or "")~="") or (r and (r:GetText() or "")~="") then stable=false; break end
    end
    if stable then return end
  end
  -- Inspect results can add rows after the target.  Reuse the existing rows
  -- and place the target after the last nonempty content row on every layout.
  local targetRows={}; local rows={}
  for i=1,tooltip:NumLines() do
    self:ClearInformationRightColumn(tooltip,i)
    local left=_G[prefix.."TextLeft"..i]
    local right=_G[prefix.."TextRight"..i]
    local label=left and left:GetText() or ""
    local plain=label:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    if plain=="대상" then targetRows[#targetRows+1]=i
    elseif label~="" or (right and (right:GetText() or "")~="") then
      rows[#rows+1]={left=label,right=right and right:GetText() or "",lc={left:GetTextColor()},rc=right and {right:GetTextColor()} or {1,1,1}}
    end
  end
  local index=#rows+1
  if #targetRows~=1 or targetRows[1]~=index then
    for i,row in ipairs(rows) do
      local left=_G[prefix.."TextLeft"..i]; local right=_G[prefix.."TextRight"..i]
      if left then left:SetText(row.left); left:SetTextColor(unpack(row.lc)) end
      if right then right:SetText(row.right); right:SetTextColor(unpack(row.rc)); if row.right=="" then right:Hide() else right:Show() end end
    end
    for i=index,tooltip:NumLines() do
      local left=_G[prefix.."TextLeft"..i]; local right=_G[prefix.."TextRight"..i]
      if left then left:SetText("") end
      if right then right:SetText(""); right:Hide() end
    end
  end
  if index>tooltip:NumLines() then
    tooltip:AddDoubleLine("대상",text,1,.82,0,1,1,1)
  end
  local left=_G[prefix.."TextLeft"..index]; local right=_G[prefix.."TextRight"..index]
  if left then if left:GetText()~="대상" then left:SetText("대상") end; left:SetTextColor(1,.82,0); left:SetJustifyH("LEFT") end
  if right then if right:GetText()~=text then right:SetText(text) end; right:SetTextColor(1,1,1); right:SetJustifyH("RIGHT"); right:Show() end
  tooltip.__KHQOLTargetLine=index; tooltip.__KHQOLTargetText=text
  tooltip.__KHQOLTargetCount=tooltip:NumLines()
end
function Tooltip:OnUnit(tooltip, fallback)
  if tooltip~=GameTooltip or not self:IsEnabled() then return end
  if not self:CanModifyTooltip(tooltip) then return end
  local db=self:GetDB(); local unit=unitToken(tooltip,fallback)
  if not unit then return end
  if db.hideUnitTooltipInCombat and publicCall(UnitAffectingCombat,"player")==true then tooltip:Hide(); return end
  tooltip.__KHQOLTargetUnit=db.showTarget==true and unit or nil
  self:ApplyUnitPresentation(tooltip,unit)
  -- NPC tooltips have no delayed guild/class/name presentation to repair.
  -- Coalesce repeated callbacks for the same live player tooltip revision.
  if publicCall(UnitIsPlayer,unit)==true and C_Timer and C_Timer.After then
    local guid=unitGUID(unit)
    tooltip.__KHQOLRevision=tooltip.__KHQOLRevision or 0
    local revision=tooltip.__KHQOLRevision
    local alreadyQueued=tooltip.__KHQOLPresentationQueuedGUID==guid and tooltip.__KHQOLPresentationQueuedRevision==revision
    local function stillCurrent()
      local current=unitToken(tooltip)
      return guid and Tooltip:IsEnabled() and tooltip:IsShown() and tooltip.__KHQOLRevision==revision and current and unitGUID(current)==guid
    end
    if guid and not alreadyQueued then
    tooltip.__KHQOLPresentationQueuedGUID=guid; tooltip.__KHQOLPresentationQueuedRevision=revision
    C_Timer.After(0,function()
      if stillCurrent() then Tooltip:ApplyUnitPresentation(tooltip,unit) end
    end)
    C_Timer.After(.2,function()
      if stillCurrent() then Tooltip:EnsurePlayerNameSize(tooltip,unit) end
    end)
    end
  end
  if self.playerInfo then self.playerInfo:OnUnit(tooltip,unit) end
  self:FinalizeUnitLines(tooltip)
  self:ApplyTextSize(tooltip)
end
function Tooltip:FinalizeUnitLines(tooltip)
  if not self:IsEnabled() or tooltip.__KHQOLFinalizing then return end
  local unit=unitToken(tooltip); if not unit then return end
  local player=publicCall(UnitIsPlayer,unit)==true
  if not player and self:GetDB().showTarget~=true then return end
  if not self:CanModifyTooltip(tooltip) then return end
  tooltip.__KHQOLFinalizing=true
  if player then self:WatchSpecializationLines(tooltip); self:NormalizeSpecializationLines(tooltip,unit) end
  tooltip.__KHQOLTargetUnit=self:GetDB().showTarget==true and unit or nil
  self:UpdateUnitTarget(tooltip)
  -- TipTac's layout helper uses native padding invalidation, which recalculates
  -- geometry without restarting Show/Hide or altering cursor anchors.
  -- Show/SetPadding may be called repeatedly while a world tooltip moves.
  -- Invalidate geometry only when our final text/font layout actually changed.
  local parts={}
  local prefix=tooltip:GetName()
  for i=1,tooltip:NumLines() do
    for _,side in ipairs({"TextLeft","TextRight"}) do
      local line=_G[prefix..side..i]
      if line then
        local font,size,flags=line:GetFont()
        local text=line:GetText()
        -- Another addon's synchronous text hook may have introduced a secret
        -- after our initial scan. Do not cache or serialize that value.
        if isSecret(text) or isSecret(font) or isSecret(size) or isSecret(flags) then tooltip.__KHQOLFinalizing=nil; return end
        parts[#parts+1]=text or ""; parts[#parts+1]=font or ""
        parts[#parts+1]=tostring(size or 0); parts[#parts+1]=flags or ""
      end
    end
  end
  local layout=table.concat(parts,"\031")
  if layout~=tooltip.__KHQOLFinalLayout and tooltip.GetPadding and tooltip.SetPadding then
    local r,b,l,t=publicCall(tooltip.GetPadding,tooltip)
    if r~=nil then
      tooltip:SetPadding(r,b,l,t)
      if tooltip.GetWidth then tooltip:GetWidth() end
    end
  end
  tooltip.__KHQOLFinalLayout=layout
  tooltip.__KHQOLFinalizing=nil
end
function Tooltip:RefreshUnitTooltip()
  local tooltip=GameTooltip
  if not tooltip:IsShown() then return end
  local unit=unitToken(tooltip)
  if unit and tooltip.SetUnit then
    -- Rebuild through the native lifecycle to remove our line when the option is OFF.
    pcall(tooltip.SetUnit,tooltip,unit)
  end
end
function Tooltip:InitializeUnitTarget()
  if self.targetHooked then return end
  self.targetHooked=true
  local function clear(tooltip)
    tooltip.__KHQOLRevision=(tooltip.__KHQOLRevision or 0)+1
    tooltip.__KHQOLTargetUnit=nil; tooltip.__KHQOLTargetLine=nil
    tooltip.__KHQOLInfoGUID=nil; tooltip.__KHQOLInfoUnitGUID=nil
    tooltip.__KHQOLInfoFreeRow=nil
    tooltip.__KHQOLFinalLayout=nil; tooltip.__KHQOLTargetCount=nil
    tooltip.__KHQOLPresentationQueuedGUID=nil; tooltip.__KHQOLPresentationQueuedRevision=nil
    tooltip.__KHQOLPresentationNextUpdate=nil
      tooltip.__KHQOLTargetText=nil; tooltip.__KHQOLTargetNextUpdate=nil; tooltip.__KHQOLTargetQueued=nil; tooltip.__KHQOLTargetQueuedUnit=nil
  end
  if not GameTooltip.HasScript or GameTooltip:HasScript("OnTooltipCleared") then GameTooltip:HookScript("OnTooltipCleared",clear) end
  GameTooltip:HookScript("OnHide",clear)
  if type(hooksecurefunc)=="function" then
    hooksecurefunc(GameTooltip,"AddLine",function(tooltip) Tooltip:WatchSpecializationLines(tooltip) end)
    hooksecurefunc(GameTooltip,"Show",function(tooltip) Tooltip:FinalizeUnitLines(tooltip) end)
    if GameTooltip.SetPadding then hooksecurefunc(GameTooltip,"SetPadding",function(tooltip) Tooltip:FinalizeUnitLines(tooltip) end) end
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(tooltip,data) Tooltip:OnUnit(tooltip,data and data.unitToken) end)
  elseif not GameTooltip.HasScript or GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit",function(tooltip) Tooltip:OnUnit(tooltip) end)
  end
  -- Observe the existing tooltip; never rebuild it periodically or restart its fade.
  GameTooltip:HookScript("OnUpdate",function(tooltip)
    local now=GetTime()
      if Tooltip:IsEnabled() and tooltip:IsShown() and now>=(tooltip.__KHQOLPresentationNextUpdate or 0) then
        tooltip.__KHQOLPresentationNextUpdate=now+.4
        local unit=unitToken(tooltip)
        -- Only specialization rows may arrive late.  Avoid reapplying fonts or
        -- title text here, which caused visible name jitter while hovering.
        if unit and publicCall(UnitIsPlayer,unit)==true then
          if Tooltip.playerInfo then Tooltip.playerInfo:OnUnit(tooltip,unit) end
          Tooltip:NormalizeSpecializationLines(tooltip,unit)
        end
      end
      if not Tooltip:IsEnabled() or Tooltip:GetDB().showTarget~=true or not tooltip.__KHQOLTargetUnit then return end
    if now<(tooltip.__KHQOLTargetNextUpdate or 0) then return end
    tooltip.__KHQOLTargetNextUpdate=now+.2
    Tooltip:UpdateUnitTarget(tooltip)
  end)
end
function Tooltip:SetEnabled(enabled)
  if enabled then self:GetDB(); self:ApplyHoldTime()
  else
    if self.playerInfo then self.playerInfo:Cancel(true) end
    if self.originalFadeOutTime ~= nil then GameTooltip.fadeOutTime=self.originalFadeOutTime end
  end
  self:RefreshUnitTooltip()
end
function Tooltip:RefreshVisibleTooltip() if GameTooltip:IsShown() then self:ApplyTextSize(GameTooltip) end end
function Tooltip:Initialize()
  if self.initialized then return end; self.initialized=true; self:GetDB(); self:ApplyHoldTime()
  Tooltip:ConfigureHealthBar()
  if Tooltip.playerInfo and Tooltip.playerInfo.Initialize then Tooltip.playerInfo:Initialize() end
  Tooltip:InitializeUnitTarget()
  -- Use the native cursor anchor at the same lifecycle point as Blizzard's
  -- default anchor.  No OnUpdate movement or frame-point mutation is needed.
  if type(hooksecurefunc) == "function" and type(GameTooltip_SetDefaultAnchor) == "function" then
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent) Tooltip:ApplyCursorAnchor(tooltip, parent) end)
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,function(tooltip,data) tooltip.__KHQOLTooltipItemID=nil; if data and not isSecret(data.id) and data.id then Tooltip:OnItem(tooltip,data.id) end end)
  else GameTooltip:HookScript("OnTooltipSetItem",function(tooltip) tooltip.__KHQOLTooltipItemID=nil; local _,link=publicCall(tooltip.GetItem,tooltip); local itemID=link and C_Item and publicCall(C_Item.GetItemInfoInstant,link); if itemID then Tooltip:OnItem(tooltip,itemID) end end) end
end
