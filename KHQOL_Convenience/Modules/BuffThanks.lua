local K=_G.KHQOL
local M=K.modules.generalConvenience
local call=K.PublicCall
local HUD=K.HUDText
local PU=K.PositionUtils
local thanks="감사합니다."
local home=LE_PARTY_CATEGORY_HOME or 1
local instance=LE_PARTY_CATEGORY_INSTANCE or 2
local defaults={enabled=false,direction="right",duration=20,size=72,
  position={point="CENTER",relativePoint="CENTER",x=0,y=80}}

M.defaults.buffThanks=defaults
local T={alerts={},auras={},buttons={}}
M.buffThanks=T

-- Only recognized class spell aura IDs qualify. Items, food, world buffs
-- and effects of unknown origin stay out even if they have a player caster.
local classes={}
local function add(class,ids)
  for _,id in ipairs(ids) do classes[id]=class end
end
add("MAGE",{1459,1460,1461,10156,10157,23028}) -- Intellect / Brilliance
add("DRUID",{1126,5232,6756,5234,8907,9884,9885,21849,21850,467,782,1075,8914,9756,9910}) -- Mark / Gift / Thorns
add("PRIEST",{1243,1244,1245,2791,10937,10938,21562,21564}) -- Fortitude / Prayer
add("PALADIN",{19740,19834,19835,19836,19837,19838,25291,25782,25916,20217,25898,1044,1022,5599,10278}) -- Blessings

local function positive(v) return K.IsPublicNumber(v) and v>0 and v%1==0 end
function T:IsSolo()
  return call(IsInGroup,home)==false and call(IsInRaid,home)==false
    and call(IsInGroup,instance)==false and call(IsInRaid,instance)==false
end

function T:Layout()
  local cfg=M:GetDB().buffThanks
  local direction=cfg.direction=="left" and -1 or 1
  local size=self:IconSize(cfg)
  local spacing=math.max(size+20,math.floor(size*112/72+.5))
  local point=cfg.position
  for i,entry in ipairs(self.alerts) do
    entry.button:ClearAllPoints()
    entry.button:SetSize(size,size)
    entry.button.label:SetWidth(spacing-6)
    entry.button:SetPoint(point.point,UIParent,point.relativePoint,point.x+direction*(i-1)*spacing,point.y)
  end
end

function T:IconSize(cfg)
  return K.IsPublicNumber(cfg.size) and math.max(32,math.min(112,cfg.size)) or defaults.size
end

function T:AddPositionTarget(list)
  local cfg=M:GetDB().buffThanks
  if not cfg.enabled then return end
  local size=self:IconSize(cfg)
  local preview=K.PositionEditor:Virtual("buffThanks",cfg.position,size,size)
  local target=PU:Add(list,"buffThanks","generalConvenience","버프 감사 알림",preview,PU:PointWriter(cfg.position),nil,
    function() PU.ApplyPoint(preview,cfg.position);self:Layout() end,
    {sample="버프 감사 알림",sampleY=-size/2-8,
      art={{texture="Interface\\Icons\\Spell_Holy_WordFortitude",width=size,height=size}},
      settingsRoute={module="convenienceChat",section="버프 감사 알림"}})
  if target then PU:ConfigureResets({target},function(t,point) point(t,function() return cfg.position end,defaults.position) end) end
end

function T:Close(entry)
  for index,current in ipairs(self.alerts) do
    if current==entry then
      table.remove(self.alerts,index)
      local button=entry.button
      button.entry=nil;button:Hide()
      self:Layout()
      return
    end
  end
end

function T:Clear()
  for _,entry in ipairs(self.alerts) do
    entry.button.entry=nil;entry.button:Hide()
  end
  self.alerts={}
end

function T:Click(entry,button)
  if K.PositionEditor.active then return end
  if not M:GetDB().buffThanks.enabled or not self:IsSolo() then self:Clear();return end
  if not entry or entry.button.entry~=entry then return end
  if button=="RightButton" then self:Close(entry);return end
  if button~="LeftButton" or entry.sending then return end

  local chat=K.modules.chatEnhancement
  local ch=C_ChatInfo
  local sender=ch and ch.SendChatMessage
  -- Hardware click supplies user intent. Respect the chat-specific
  -- lockdown state independently of combat and never retry a send.
  if type(sender)~="function" or call(ch.InChatMessagingLockdown)~=false then
    if chat:OpenWhisperDraft(entry.name,thanks) then
      self:Close(entry)
    else
      K.modules.chatAutomation:Message("입력 중인 내용을 보존했습니다. 채팅 입력창을 비운 뒤 감사 알림을 다시 클릭하세요.")
    end
    return
  end
  entry.sending=true
  self:Close(entry)
  local status=K.ReadPublicAPI(sender,thanks,"WHISPER",nil,entry.name)
  if status~="ok" then
    K.modules.chatAutomation:Message("감사 귓속말의 전송 결과를 확인할 수 없습니다.")
  end
end

function T:Show(name,icon,spell)
  local button
  for _,candidate in ipairs(self.buttons) do if not candidate.entry then button=candidate;break end end
  if not button then
    button=CreateFrame("Button",nil,UIParent,"BackdropTemplate")
    HUD.MakeBackdrop(button,.95,.73,.15,.93)
    button:SetFrameStrata("HIGH")
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button.icon=button:CreateTexture(nil,"ARTWORK")
    button.icon:SetPoint("TOPLEFT",3,-3);button.icon:SetPoint("BOTTOMRIGHT",-3,3)
    button.label=button:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    button.label:SetFont(HUD.FONT_PATH,13,"OUTLINE");button.label:SetPoint("TOP",button,"BOTTOM",0,-3)
    button.label:SetWordWrap(false)
    button:SetScript("OnClick",function(f,key) T:Click(f.entry,key) end)
    button:SetScript("OnEnter",function(f)
      if not f.entry then return end
      GameTooltip:SetOwner(f,"ANCHOR_RIGHT");GameTooltip:SetText(f.entry.name)
      GameTooltip:AddLine(f.entry.spell,1,1,1)
      GameTooltip:AddLine("좌클릭: 감사 귓속말 · 우클릭: 닫기",.82,.82,.82,true)
      GameTooltip:Show()
    end)
    local function hide(f) if GameTooltip:IsOwned(f) then GameTooltip:Hide() end end
    button:SetScript("OnLeave",hide);button:SetScript("OnHide",hide)
    self.buttons[#self.buttons+1]=button
  end
  local entry={button=button,name=name,spell=spell}
  button.entry=entry;button.icon:SetTexture(icon);button.label:SetText(name)
  self.alerts[#self.alerts+1]=entry
  self:Layout();button:Show()

  local duration=M:GetDB().buffThanks.duration
  duration=K.IsPublicNumber(duration) and math.max(10,math.min(30,duration)) or 20
  C_Timer.After(duration,function() T:Close(entry) end)
end

local function auraFields(aura)
  if type(aura)~="table" or not K.IsPublicValue(aura) then return end
  return call(function() return aura.auraInstanceID,aura.spellId,aura.isHelpful end)
end

function T:Baseline()
  self.auras={};self.armed=false
  if not self:IsSolo() then return end
  local reader=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
  for index=1,255 do
    local status,aura=K.ReadPublicAPI(reader,"player",index,"HELPFUL")
    if status~="ok" then return end
    if not aura then self.armed=true;return end
    local id,spell=auraFields(aura)
    if positive(id) and positive(spell) then self.auras[id]=spell end
  end
end

function T:OnAura(update)
  if not self:IsSolo() then self:Clear();self.armed=false;return end
  if not self.armed or type(update)~="table" or not K.IsPublicValue(update) then self:Baseline();return end
  local status,full,added,removed=K.ReadPublicAPI(function()
    return update.isFullUpdate,update.addedAuras,update.removedAuraInstanceIDs
  end)
  if status~="ok" or full~=false then self:Baseline();return end

  local previous={}
  for _,spell in pairs(self.auras) do previous[spell]=true end
  if type(removed)=="table" then
    for _,id in ipairs(removed) do if positive(id) then self.auras[id]=nil end end
  end
  if type(added)~="table" then return end
  for _,aura in ipairs(added) do
    local id,spell,helpful=auraFields(aura)
    if helpful==true and positive(id) and positive(spell) then
      local new=not self.auras[id] and not previous[spell]
      self.auras[id]=spell;previous[spell]=true
      if new and classes[spell] then self:CheckCaster(aura,classes[spell]) end
    end
  end
end

function T:CheckCaster(aura, expectedClass)
  local unit,icon,spell=call(function() return aura.sourceUnit,aura.icon,aura.name end)
  if type(unit)~="string" or unit=="player" or call(UnitIsUnit,unit,"player")~=false
    or call(UnitIsPlayer,unit)~=true or not positive(icon) or type(spell)~="string" then return end
  local _,class=call(UnitClass,unit)
  if class~=expectedClass then return end
  local name=K.modules.chatEnhancement:ReadUnitWhisperName(unit)
  if name then self:Show(name,icon,spell) end
end

function T:Configure()
  local cfg=M:GetDB().buffThanks
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event,unit,update)
      if event=="UNIT_AURA" and unit=="player" then T:OnAura(update)
      elseif event~="UNIT_AURA" then
        local moved=event=="PLAYER_ENTERING_WORLD" or event=="GROUP_JOINED" or event=="GROUP_LEFT"
        local solo=T:IsSolo()
        if moved or not solo then T:Clear() end
        if moved or not T.armed or not solo then T:Baseline() end
      end
    end)
  end
  if self.enabled~=cfg.enabled or self.generation~=K.profileGeneration then
    self.events:UnregisterAllEvents()
    self:Clear()
    self.enabled,self.generation=cfg.enabled,K.profileGeneration
    if cfg.enabled then
      self.events:RegisterUnitEvent("UNIT_AURA","player")
      self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
      self.events:RegisterEvent("GROUP_ROSTER_UPDATE")
      pcall(self.events.RegisterEvent,self.events,"GROUP_JOINED")
      pcall(self.events.RegisterEvent,self.events,"GROUP_LEFT")
      self:Baseline()
    else self.armed=false;self.auras={} end
  end
  self:Layout()
end
