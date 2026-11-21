local _,addon=...
if not addon.loadUnitFrames then return end
local K=_G.KHQOL
local M=K.modules.unitFrames
local call=K.PublicCall
for _,unit in ipairs({"player","target"}) do M.defaults[unit].markOffsets={faction={x=0,y=0},skull={x=0,y=0}} end
function M:MarkSettings(unit,kind)
  local cfg=self:GetDB()[unit].markOffsets[kind]
  for _,axis in ipairs({"x","y"}) do cfg[axis]=K.IsPublicNumber(cfg[axis]) and math.max(-400,math.min(400,cfg[axis])) or 0 end
  return cfg
end
function M:MarkParts(unit,p)
  p=p or self:UnitParts(unit);if not p then return {} end
  local c=p.context or {};local m=p.main or {}
  local owner=self.units and self.units[unit]
  return {circle=c.PvpBackgroundCircle or m.PvpBackgroundCircle,badge=c.PvpBackgroundIcon or m.PvpBackgroundIcon,
    flag=c.PvpIcon or m.PvpIcon,skull=owner and owner.levelSkull or c.HighLevelTexture}
end
function M:MarkAvailable(unit,kind)
  local p=self:MarkParts(unit)
  return kind=="faction" and (p.circle or p.badge or p.flag)~=nil or kind=="skull" and (unit=="target" or p.skull~=nil) or false
end
function M:PositionPlayerFaction(owner,p)
  if not owner.compactActive then return end
  if call(InCombatLockdown)~=false then self.pending=true;return end
  local parts=self:MarkParts("player",p);local cfg=self:MarkSettings("player","faction")
  local bar=owner.healthDisplay or p.health
  local circle=parts.circle or parts.badge
  if circle then self:Write(owner,circle,"points",{{"CENTER",bar,"LEFT",-22+cfg.x,cfg.y}}) end
  if parts.badge and parts.badge~=circle then self:Write(owner,parts.badge,"points",{{"CENTER",circle,"CENTER",0,0}}) end
  if parts.flag then
    local extra=circle and call(circle.IsShown,circle)==true and -38 or 0
    self:Write(owner,parts.flag,"points",{{"CENTER",bar,"LEFT",-22+cfg.x+extra,cfg.y}})
  end
end
function M:BuildMarkSettings(builder,unit,compact)
  for _,entry in ipairs({{"faction","진영·PvP 마크"},{"skull","해골 마크"}}) do
    local kind,title=entry[1],entry[2]
    builder:Section(title)
    local function available() return compact() and self:MarkAvailable(unit,kind) end
    for _,axis in ipairs({"x","y"}) do
      local key=axis
      builder:Slider(title.." "..key:upper().." 위치 보정",-400,400,1,
        function() return self:MarkSettings(unit,kind)[key] end,
        function(v) self:MarkSettings(unit,kind)[key]=v;self:ApplySettings() end,function(v) return v.." px" end,available)
    end
    local reset
    reset=builder:Button(title.." 위치 초기화",function()
      K.UsageDiagnostics:Begin(reset,"click")
      local cfg=self:MarkSettings(unit,kind);cfg.x,cfg.y=0,0;self:ApplySettings()
      K.UsageDiagnostics:Finish(reset)
    end,nil,available)
    K.UI.SettingsNavigation:Attach(builder.parent,reset,title.." 위치 초기화",function() local cfg=self:MarkSettings(unit,kind);return cfg.x,cfg.y end)
  end
  if unit=="player" then builder:Description("기본 플레이어 프레임에 해골 표시기가 없는 경우 해당 위치 설정은 사용할 수 없습니다.",true) end
end
