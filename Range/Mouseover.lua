local _, KHQOL = ...
local FR = KHQOL.modules.range
local Mouseover = {}
local UNKNOWN_COLOR = {1,.82,0,1}
FR.Mouseover = Mouseover

local function secret(value)
  return type(issecretvalue)=="function" and issecretvalue(value)
end
local function collect(...) return {n=select("#",...),...} end
local function publicCall(fn,...)
  if type(fn)~="function" then return end
  for i=1,select("#",...) do if secret(select(i,...)) then return end end
  local result=collect(pcall(fn,...))
  if not result[1] then return end
  for i=2,result.n do if secret(result[i]) then return end end
  return unpack(result,2,result.n)
end

function Mouseover:Hide()
  if self.frame then self.frame:Hide() end
  self.lastLayout=nil
  self.lastColor=nil
end

function Mouseover:GetState()
  local tooltip=GameTooltip
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) or not tooltip:IsShown() then return end
  -- Read only the public token. Secret tooltip names/lines are not inspected.
  if type(tooltip.GetUnit)~="function" then return end
  local ok,_,unit=pcall(tooltip.GetUnit,tooltip)
  if not ok or secret(unit) or type(unit)~="string" or unit=="" then return end
  if publicCall(UnitExists,"mouseover")~=true then return end
  if unit~="mouseover" and publicCall(UnitIsUnit,unit,"mouseover")~=true then return end
  local attackable=publicCall(UnitCanAttack,"player","mouseover")
  local enemy=publicCall(UnitIsEnemy,"player","mouseover")
  -- Neutral, attackable creatures count; friendly NPC/item tooltips do not.
  if attackable~=true and enemy~=true then return end
  local dead=publicCall(UnitIsDeadOrGhost,"mouseover")
  if dead==true then return end
  if attackable==false then return "RED" end
  if dead==nil or attackable~=true then return "UNKNOWN" end
  local checked,inRange=pcall(FR.Range.CheckConfiguredSpell,FR.Range,"mouseover")
  if not checked or secret(inRange) then return "UNKNOWN" end
  local _,class=publicCall(UnitClass,"player")
  if class=="HUNTER" then
    local checked,state=pcall(FR.Range.GetHunterState,FR.Range,inRange,"mouseover")
    if not checked or secret(state) then return "UNKNOWN" end
    return state or "UNKNOWN"
  end
  if inRange==nil then return "UNKNOWN" end
  return inRange and "GREEN" or "RED"
end

function Mouseover:Update()
  if not self.frame then return end
  local options=FR.db and FR.db.mouseover
  if not options or not options.enabled or not KHQOL.db or not KHQOL:GetEnabled("range") then self:Hide(); return end
  local state=self:GetState()
  if not state then self:Hide(); return end
  local frame=self.frame
  local font=(KHQOL.modules.clock and KHQOL.modules.clock.FONT_PATH) or STANDARD_TEXT_FONT
  local x,y=options.x or 0,options.y or 0
  local layout=self.lastLayout
  local layoutChanged=not layout or layout.position~=options.position
    or layout.fontSize~=options.fontSize or layout.x~=x or layout.y~=y or layout.font~=font
  if layoutChanged then
    frame.text:SetFont(font,options.fontSize,"OUTLINE")
    frame:ClearAllPoints()
    if options.position=="LEFT" then frame:SetPoint("RIGHT",GameTooltip,"LEFT",x,y)
    else frame:SetPoint("TOPLEFT",GameTooltip,"BOTTOMLEFT",x,y) end
    self.lastLayout={position=options.position,fontSize=options.fontSize,x=x,y=y,font=font}
  end
  local text,color
  if state=="GREEN" then text=options.availableText or "공격 가능"; color=FR.db.colors.GREEN
  elseif state=="RED" or state=="ORANGE" then text=options.unavailableText or "공격 불가"; color=FR.db.colors.RED
  else text="판정 불가"; color=UNKNOWN_COLOR end
  local textChanged=frame.text:GetText()~=text
  if textChanged then frame.text:SetText(text) end
  local old=self.lastColor
  if not old or old[1]~=color[1] or old[2]~=color[2] or old[3]~=color[3] or old[4]~=color[4] then
    frame.text:SetTextColor(unpack(color)); self.lastColor={unpack(color)}
  end
  if textChanged or layoutChanged then frame:SetSize(frame.text:GetStringWidth()+8,frame.text:GetStringHeight()+6) end
  if not frame:IsShown() then frame:Show() end
end

function Mouseover:Initialize()
  if self.frame then return end
  -- A noninteractive child follows tooltip motion/fade without touching its
  -- contents, owner, anchors or native lifecycle. Tooltip module can be OFF.
  local frame=CreateFrame("Frame","KHQOLRangeMouseover",GameTooltip)
  frame:SetFrameLevel(GameTooltip:GetFrameLevel()+1)
  frame:EnableMouse(false)
  frame.text=frame:CreateFontString(nil,"OVERLAY")
  frame.text:SetPoint("CENTER"); frame.text:SetJustifyH("CENTER")
  frame:Hide(); self.frame=frame
  GameTooltip:HookScript("OnHide",function() Mouseover:Hide() end)
  if not GameTooltip.HasScript or GameTooltip:HasScript("OnTooltipCleared") then
    GameTooltip:HookScript("OnTooltipCleared",function() Mouseover:Hide() end)
  end
  GameTooltip:HookScript("OnShow",function() Mouseover:Update() end)
  if not GameTooltip.HasScript or GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit",function() Mouseover:Update() end)
  end
end
