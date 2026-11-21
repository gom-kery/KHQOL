local K=_G.KHQOL
local M=K.modules.generalConvenience
local call=K.PublicCall
local HUD=K.HUDText
local PU=K.PositionUtils
local thanks="감사합니다."
local home=LE_PARTY_CATEGORY_HOME or 1
local instance=LE_PARTY_CATEGORY_INSTANCE or 2
local defaults={enabled=false,locked=true,direction="right",duration=20,size=72,message=thanks,
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
  if self.drag and (cfg~=self.drag.cfg or cfg.locked~=false or not cfg.enabled
      or self.drag.generation~=K.profileGeneration or K.PositionEditor.active or not K.WindowLayers:OutsideCombat()) then
    self:FinishDrag();return
  end
  local direction=cfg.direction=="left" and -1 or 1
  local size=self:IconSize(cfg)
  local spacing=math.max(size+20,math.floor(size*112/72+.5))
  local point=cfg.position
  for i,entry in ipairs(self.alerts) do
    entry.button:SetSize(size,size)
    entry.button.label:SetWidth(spacing-6)
    if not self.drag or entry.button~=self.drag.frame then
      entry.button:ClearAllPoints()
      if self.drag then
        entry.button:SetPoint("CENTER",self.drag.frame,"CENTER",direction*(i-1)*spacing-self.drag.offset,0)
      else
        entry.button:SetPoint(point.point,UIParent,point.relativePoint,point.x+direction*(i-1)*spacing,point.y)
      end
    end
  end
  local editable=cfg.enabled and cfg.locked==false and not K.PositionEditor.active and K.WindowLayers:OutsideCombat()
  if editable and not self.movePreview then self.movePreview=self:CreateButton(true) end
  local preview=self.movePreview
  if preview then
    local moving=self.drag and self.drag.frame==preview
    if not moving then preview:SetSize(size,size);PU.ApplyPoint(preview,point) end
    preview.label:SetWidth(spacing-6)
    preview:SetShown(editable and (#self.alerts==0 or moving))
  end
end

function T:SetLocked(value)
  self:FinishDrag()
  M:GetDB().buffThanks.locked=value
  self:Layout()
end

function T:StartDrag(frame)
  -- Some clients deliver OnClick after OnDragStop; consume that release only.
  frame.suppressClick=true
  local cfg=M:GetDB().buffThanks
  if self.drag or not cfg.enabled or cfg.locked~=false or K.PositionEditor.active
    or not K.WindowLayers:OutsideCombat() or call(CursorHasItem)~=false or not K.PositionStore:Safe(frame) then return end
  local offset
  if frame==self.movePreview then offset=0 else
    local size=self:IconSize(cfg);local spacing=math.max(size+20,math.floor(size*112/72+.5))
    for i,entry in ipairs(self.alerts) do
      if entry.button==frame and frame.entry==entry then offset=(cfg.direction=="left" and -1 or 1)*(i-1)*spacing;break end
    end
  end
  if offset==nil then return end
  self.drag={frame=frame,offset=offset,cfg=cfg,generation=K.profileGeneration}
  frame.positionMoving=true;frame:StartMoving()
  if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
  self:Layout()
end

function T:FinishDrag()
  local drag=self.drag;if not drag then return end
  self.drag=nil
  local frame=drag.frame
  frame.positionMoving=nil;frame:StopMovingOrSizing()
  local point={}
  local current=M:GetDB().buffThanks
  local saved=current==drag.cfg and drag.generation==K.profileGeneration and K.PositionStore:Point(frame,point)
  if saved then
    point.x=K.PositionStore:Round(point.x-drag.offset)
    for _,key in ipairs({"point","relativePoint","x","y"}) do current.position[key]=point[key] end
  end
  self:Layout()
  if saved then K.PositionStore:Committed() end
end

function T:IconSize(cfg)
  return K.IsPublicNumber(cfg.size) and math.max(32,math.min(112,cfg.size)) or defaults.size
end

function T:GetMessage()
  local text=K.modules.chatAutomation:ValidateText(M:GetDB().buffThanks.message,255,255)
  return text and text~="" and text or thanks
end

function T:SetMessage(value)
  local text,reason=K.modules.chatAutomation:ValidateText(value,255,255)
  if not text then M:Message(reason);return end
  M:GetDB().buffThanks.message=text~="" and text or thanks
end

function T:AddPositionTarget(list)
  local cfg=M:GetDB().buffThanks
  if not cfg.enabled then return end
  local size=self:IconSize(cfg)
  local preview=PU:Preview("buffThanks",cfg.position,size,size)
  local target=PU:Add(list,"buffThanks","generalConvenience","버프 알림",preview,PU:PointWriter(cfg.position),PU:Lock(cfg),
    function() PU.ApplyPoint(preview,cfg.position);self:Layout() end,
    {sample="버프 알림",sampleY=-size/2-8,
      art={{texture="Interface\\Icons\\Spell_Holy_WordFortitude",width=size,height=size}},
      settingsRoute={module="generalConvenience",section="버프 알림"}})
  if target then PU:ConfigureResets({target},function(t,point) point(t,function() return cfg.position end,defaults.position) end) end
end

function T:Close(entry)
  for index,current in ipairs(self.alerts) do
    if current==entry then
      if self.drag and self.drag.frame==entry.button then self:FinishDrag() end
      table.remove(self.alerts,index)
      local button=entry.button
      button.entry=nil;button:Hide()
      self:Layout()
      return
    end
  end
end

function T:Clear()
  self:FinishDrag()
  for _,entry in ipairs(self.alerts) do
    entry.button.entry=nil;entry.button:Hide()
  end
  self.alerts={}
  self:Layout()
end

function T:Click(entry,button)
  if K.PositionEditor.active or self.drag then return end
  if entry and entry.button.suppressClick then entry.button.suppressClick=nil;return end
  if not M:GetDB().buffThanks.enabled or not self:IsSolo() then self:Clear();return end
  if not entry or entry.button.entry~=entry then return end
  if button=="RightButton" then self:Close(entry);return end
  if button~="LeftButton" or entry.sending then return end
  K.UsageDiagnostics:Emit("feature.thanks.click","execute","click")

  local chat=K.modules.chatEnhancement
  local ch=C_ChatInfo
  local sender=ch and ch.SendChatMessage
  local message=self:GetMessage()
  -- Hardware click supplies user intent. Respect the chat-specific
  -- lockdown state independently of combat and never retry a send.
  if type(sender)~="function" or call(ch.InChatMessagingLockdown)~=false then
    if chat:OpenWhisperDraft(entry.name,message) then
      K.UsageDiagnostics:Emit("feature.thanks.draft","draft","click")
      self:Close(entry)
    else
      K.modules.chatAutomation:Message("입력 중인 내용을 보존했습니다. 채팅 입력창을 비운 뒤 감사 알림을 다시 클릭하세요.")
    end
    return
  end
  entry.sending=true
  self:Close(entry)
  local status=K.ReadPublicAPI(sender,message,"WHISPER",nil,entry.name)
  if status=="ok" or status=="error" then K.UsageDiagnostics:Emit("feature.thanks.send_request","request","click") end
  if status~="ok" then
    K.modules.chatAutomation:Message("감사 귓속말의 전송 결과를 확인할 수 없습니다.")
  end
end

function T:CreateButton(preview)
  local button=CreateFrame("Button",nil,UIParent,"BackdropTemplate")
  HUD.MakeBackdrop(button,.95,.73,.15,.93)
  button:SetFrameStrata("HIGH")
  button:RegisterForClicks("LeftButtonUp","RightButtonUp")
  button:SetMovable(true);button:SetClampedToScreen(true);button:RegisterForDrag("LeftButton")
  button.icon=button:CreateTexture(nil,"ARTWORK")
  button.icon:SetPoint("TOPLEFT",3,-3);button.icon:SetPoint("BOTTOMRIGHT",-3,3)
  button.label=button:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  button.label:SetFont(HUD.FONT_PATH,13,"OUTLINE");button.label:SetPoint("TOP",button,"BOTTOM",0,-3)
  button.label:SetWordWrap(false)
  button:SetScript("OnMouseDown",function(f) if not f.positionMoving then f.suppressClick=nil end end)
  button:SetScript("OnDragStart",function(f) T:StartDrag(f) end)
  button:SetScript("OnDragStop",function(f) if T.drag and T.drag.frame==f then T:FinishDrag() end end)
  button:SetScript("OnClick",function(f,key)
    if f.suppressClick then f.suppressClick=nil;return end
    T:Click(f.entry,key)
  end)
  button:SetScript("OnEnter",function(f)
    if T.drag or K.PositionEditor.active or not f.entry and not preview then return end
    GameTooltip:SetOwner(f,"ANCHOR_RIGHT");GameTooltip:SetText(preview and "버프 감사 알림 위치" or f.entry.name)
    if not preview then
      GameTooltip:AddLine(f.entry.spell,1,1,1)
      GameTooltip:AddLine("좌클릭: 감사 귓속말 · 우클릭: 닫기",.82,.82,.82,true)
    end
    if M:GetDB().buffThanks.locked==false then GameTooltip:AddLine("좌클릭 드래그: 알림 묶음 이동",.82,.82,.82,true) end
    GameTooltip:Show()
  end)
  local function hide(f) if GameTooltip:IsOwned(f) then GameTooltip:Hide() end end
  button:SetScript("OnLeave",hide)
  button:SetScript("OnHide",function(f) hide(f);if T.drag and T.drag.frame==f then T:FinishDrag() end end)
  if preview then
    button.icon:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude");button.label:SetText("버프 감사 알림 · 이동")
  else self.buttons[#self.buttons+1]=button end
  return button
end

function T:Show(name,icon,spell)
  local button
  for _,candidate in ipairs(self.buttons) do if not candidate.entry then button=candidate;break end end
  if not button then button=self:CreateButton(false) end
  button.suppressClick=nil
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
  if not self:IsSolo() then return end
  local snapshot={}
  local reader=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
  for index=1,255 do
    local status,aura=K.ReadPublicAPI(reader,"player",index,"HELPFUL")
    if status~="ok" then return end
    if not aura then self.auras=snapshot;self.armed=true;return true end
    local id,spell=auraFields(aura)
    if not positive(id) or not positive(spell) then return end
    snapshot[id]=spell
  end
end

function T:PrepareBaseline(reset)
  local solo=self:IsSolo()
  reset=reset or solo~=self.wasSolo
  self.wasSolo=solo
  if reset then
    self.auras={};self.armed=false;self.baselineRetry=nil
    self.soloSince=call(GetTime)
  end
  if not solo then return end
  if self:Baseline() then self.baselineRetry=nil;return end
  self.armed=false
  if self.baselineRetry then return end
  local ticket={};self.baselineRetry=ticket
  local function retry(attempt)
    if self.baselineRetry~=ticket or not self.enabled or not self:IsSolo() then return end
    if self:Baseline() or attempt>=8 then self.baselineRetry=nil;return end
    C_Timer.After(.4,function() retry(attempt+1) end)
  end
  C_Timer.After(.15,function() retry(1) end)
end

function T:OnAura(update)
  if not self:IsSolo() then self:Clear();self:PrepareBaseline(true);return end
  if self.wasSolo==false then self:PrepareBaseline(true);return end
  if type(update)~="table" or not K.IsPublicValue(update) then self:PrepareBaseline();return end
  local status,full,added,removed=K.ReadPublicAPI(function()
    return update.isFullUpdate,update.addedAuras,update.removedAuraInstanceIDs
  end)
  if status~="ok" or full~=false then self:PrepareBaseline();return end

  local recovering=not self.armed
  local previous={}
  for _,spell in pairs(self.auras) do previous[spell]=true end
  if recovering then
    if not self:Baseline() then self:PrepareBaseline();return end
    self.baselineRetry=nil
  end
  if type(removed)=="table" then
    for _,id in ipairs(removed) do if positive(id) then self.auras[id]=nil end end
  end
  if type(added)~="table" then return end
  for _,aura in ipairs(added) do
    local id,spell,helpful=auraFields(aura)
    if helpful==true and positive(id) and positive(spell) then
      local new=not self.auras[id]
      if recovering then
        local expires,duration=call(function() return aura.expirationTime,aura.duration end)
        local now=call(GetTime)
        new=K.IsPublicNumber(expires) and K.IsPublicNumber(duration) and duration>0
          and K.IsPublicNumber(self.soloSince) and K.IsPublicNumber(now)
          and expires-duration>self.soloSince and expires-duration<=now+.1
      end
      new=new and not previous[spell]
      self.auras[id]=spell;previous[spell]=true
      if new and classes[spell] then self:CheckCaster(aura,id,classes[spell]) end
    end
  end
end

function T:CheckCaster(aura,id,expectedClass)
  local icon,spell=call(function() return aura.icon,aura.name end)
  if not positive(icon) or type(spell)~="string" then return end
  local unit=call(function() return aura.sourceUnit end)
  local name
  if type(unit)=="string" and unit~="" then
    if unit=="player" or call(UnitIsUnit,unit,"player")~=false or call(UnitIsPlayer,unit)~=true then return end
    local _,class=call(UnitClass,unit)
    if class~=expectedClass then return end
    name=K.modules.chatEnhancement:ReadUnitWhisperName(unit)
  else
    local guid=call(C_UnitAuras and C_UnitAuras.GetAuraCasterGUID,"player",id)
    local mine=call(UnitGUID,"player")
    if type(mine)~="string" or type(guid)~="string" or not guid:match("^Player%-%d+%-%x+$") or guid==mine then return end
    local class,fullName=call(function()
      local _,token,_,_,_,name,realm=GetPlayerInfoByGUID(guid)
      if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
        if K.IsPublicValue(name) and type(name)=="string" and name:match("^[^%s|%-]+ [^%s|%-]+$") then return token,name end
      elseif K.IsPublicValue(name) and type(name)=="string" and K.IsPublicValue(realm) and type(realm)=="string" then
        return token,realm~="" and (name.."-"..realm:gsub(" ","")) or name
      end
    end)
    if class==expectedClass then name=fullName end
  end
  if name then self:Show(name,icon,spell) end
end

function T:Configure()
  local cfg=M:GetDB().buffThanks
  self:FinishDrag()
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event,unit,update)
      if event=="UNIT_AURA" and unit=="player" then T:OnAura(update)
      elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" then T:FinishDrag();T:Layout()
      elseif event~="UNIT_AURA" then
        local moved=event=="PLAYER_ENTERING_WORLD" or event=="GROUP_JOINED" or event=="GROUP_LEFT"
        local solo=T:IsSolo()
        if moved or not solo then T:Clear() end
        if moved or not T.armed or not solo then T:PrepareBaseline(moved or not solo) end
      end
    end)
    hooksecurefunc(K.PositionEditor,"Enter",function() T:FinishDrag();T:Layout() end)
    hooksecurefunc(K.PositionEditor,"Finish",function() T:Layout() end)
  end
  if self.enabled~=cfg.enabled or self.generation~=K.profileGeneration then
    self.events:UnregisterAllEvents()
    self:Clear()
    self.enabled,self.generation=cfg.enabled,K.profileGeneration
    if cfg.enabled then
      self.events:RegisterUnitEvent("UNIT_AURA","player")
      self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
      self.events:RegisterEvent("GROUP_ROSTER_UPDATE")
      self.events:RegisterEvent("PLAYER_REGEN_DISABLED")
      self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
      pcall(self.events.RegisterEvent,self.events,"GROUP_JOINED")
      pcall(self.events.RegisterEvent,self.events,"GROUP_LEFT")
      self:PrepareBaseline(true)
    else self.armed=false;self.auras={};self.baselineRetry=nil end
  end
  self:Layout()
end
