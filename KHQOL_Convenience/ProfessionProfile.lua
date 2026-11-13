local K=_G.KHQOL
local M=K.modules.professions
local HUD=K.HUDText

M.defaults=K.professionProfileDefaults
-- Old anchors referred to the clock's working frame. Its width was computed
-- at runtime, so reconstruct the layout using this client's font and money.
local anchors={CENTER={0,0},TOP={0,.5},BOTTOM={0,-.5},LEFT={-.5,0},RIGHT={.5,0},
  TOPLEFT={-.5,.5},TOPRIGHT={.5,.5},BOTTOMLEFT={-.5,-.5},BOTTOMRIGHT={.5,-.5}}
local function oldClockWidth(clock)
  if not M.migrationMeasure then
    local measure=CreateFrame("Frame",nil,UIParent);measure:Hide()
    M.migrationMeasure=measure:CreateFontString()
  end
  local label=M.migrationMeasure
  local function width(value,size)
    if not label:SetFont(HUD.FONT_PATH,size,"") then return end
    label:SetText(value)
    return K.PublicCall(label.GetStringWidth,label)
  end
  local timeWidth=width(date("%H:%M"),clock.fontSize or 48)
  local money=clock.modules.money or {}
  local moneyWidth=175
  if money.enabled~=false then
    local amount=K.PublicCall(GetMoney)
    if not K.IsPublicNumber(amount) then return end
    local units=money.units
    if not units and money.displayUnits then
      units={gold=true,silver=money.displayUnits=="GS" or money.displayUnits=="GSC",copper=money.displayUnits=="GSC"}
    end
    local measured=width(HUD.FormatMoney(amount,units or HUD.moneyUnits),(money.fontSize or clock.moduleFontSize or 14))
    if not K.IsPublicNumber(measured) then return end
    moneyWidth=math.max(28,measured+16)
  end
  if K.IsPublicNumber(timeWidth) then return math.max(430,timeWidth+2*moneyWidth+40) end
end

function M:MigrateProfile(profile,legacyClock)
  local settings=profile.settings
  local modules=settings.modules or {};settings.modules=modules
  if type(modules.professions)=="table" and next(modules.professions) then return end
  local function source(clock)
    if type(clock)~="table" then return end
    local archived=clock.professionMigrationSource
    if type(archived)=="table" then clock=archived end
    if type(clock.modules)=="table" and type(clock.modules.professions)=="table" then return clock end
  end
  local clock=source(profile.legacy and profile.legacy.clock) or source(legacyClock)
  local old=type(clock)=="table" and type(clock.modules)=="table" and clock.modules.professions
  if type(old)~="table" then return end

  local cfg=K.CopyProfileValue(self.defaults)
  cfg.enabled=old.enabled~=false and clock.enabled~=false and (not settings.enabled or settings.enabled.clock~=false)
  cfg.locked=clock.locked~=false
  cfg.iconSize=old.iconSize or cfg.iconSize
  cfg.layout=old.layout or cfg.layout
  cfg.showSkill=old.showSkill~=false
  cfg.skillPosition="outside"
  cfg.fontSize=old.fontSize or clock.moduleFontSize or cfg.fontSize
  cfg.skillFontSize=math.max(10,cfg.fontSize-2)
  local styles=clock.textStyle or {}
  local target,common=styles.professions or {},styles.common or {}
  cfg.style.color=K.CopyProfileValue(target.color or common.color or cfg.style.color)
  cfg.style.effect=target.effect or common.effect or cfg.style.effect

  local relative=type(old.position)=="table" and old.position or {x=160,y=0}
  local pos=type(clock.position)=="table" and clock.position or {}
  local point,relativePoint=pos.point or "CENTER",pos.relativePoint or "CENTER"
  local anchor,screen=anchors[point],anchors[relativePoint]
  local x,y,px,py=relative.x or 160,relative.y or 0,pos.x or 0,pos.y or 0
  if K.IsPublicNumber(x) and K.IsPublicNumber(y) then
    cfg.direction=math.abs(x)>math.abs(y) and (x<0 and "left" or "right") or (y<0 and "down" or "up")
    local width=anchor and (anchor[1]==0 and 0 or oldClockWidth(clock))
    if anchor and screen and width and K.IsPublicNumber(px) and K.IsPublicNumber(py) then
      cfg.position.relativePoint=relativePoint
      cfg.position.x=px+x-anchor[1]*width
      cfg.position.y=py+y-anchor[2]*190
    end
  end
  -- Keep the original clock snapshot, including offsets that could not be converted.
  if clock==legacyClock then
    profile.legacy=profile.legacy or {}
    profile.legacy.clock=K.CopyProfileValue(clock)
    -- Clock content stays in its own SavedVariables.
    profile.legacy.clock.todo=nil
    if profile.legacy.clock.clockTools then profile.legacy.clock.clockTools.alarmMessage=nil end
  end
  modules.professions=cfg
end
