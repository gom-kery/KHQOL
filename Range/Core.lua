local ADDON, KHQOL = ...
local FR = KHQOL.modules.range

FR.name = ADDON
FR.testState, FR.testUntil = nil, 0

function FR:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff4dff66[FRange]|r " .. tostring(message))
end

local function read(fn,...) return KHQOL.PublicCall(fn,...) end
local function validID(id) return KHQOL.IsPublicValue(id) and type(id)=="number" and id>0 and id<2147483648 and id==math.floor(id) end
local function professionSpell(index)
  if not index or type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then return false end
  local a,b,c,d,e=read(GetProfessions)
  for _,profession in pairs({a,b,c,d,e}) do
    if validID(profession) then
      local _,_,_,_,count,offset=read(GetProfessionInfo,profession)
      if type(count)=="number" and type(offset)=="number" and count>=0 and offset>=0
        and count==math.floor(count) and offset==math.floor(offset) and offset+count<=1024
        and index>offset and index<=offset+count then return true end
    end
  end
  return false
end
function FR:ParseSpell(input)
  if not KHQOL.IsPublicValue(input) then return end
  input=tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local id=tonumber(input) or tonumber(input:match("spell:(%d+)"))
  if not id and input~="" then
    local info=read(C_Spell and C_Spell.GetSpellInfo,input)
    id=self.Range.PublicField(info,"spellID")
    if not id then local _,_,_,_,_,_,legacyID=read(GetSpellInfo,input);id=legacyID end
  end
  if not validID(id) then return end
  local name,resolved=self.Range:GetSpellInfo(id)
  if not validID(resolved) then resolved=id end
  return resolved,name
end
function FR:ValidateReferenceSpell(input)
  local id,name=self:ParseSpell(input)
  if not id or not name then return nil,"주문 정보를 확인할 수 없습니다. SpellID를 확인하세요." end
  local index=self.Range:FindSpellBookIndex(id,name)
  local known=read(IsPlayerSpell,id)==true or read(IsSpellKnown,id)==true
  if not known and not index then return nil,"이 캐릭터의 학습한 주문을 확인할 수 없습니다." end
  local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  local info=index and read(C_SpellBook and C_SpellBook.GetSpellBookItemInfo,index,bank)
  local passive=self.Range.PublicField(info,"isPassive")
  if passive==nil and index then passive=read(C_SpellBook and C_SpellBook.IsSpellBookItemPassive,index,bank) end
  if passive==nil then passive=read(IsPassiveSpell,id) end
  if passive==true then return nil,"지속효과 주문은 사거리 기준으로 등록할 수 없습니다." end
  if validID(read(C_MountJournal and C_MountJournal.GetMountFromSpell,id)) then return nil,"탈것 주문은 등록할 수 없습니다." end
  if professionSpell(index) then return nil,"전문기술 주문은 등록할 수 없습니다." end
  local hasRange=read((C_Spell and C_Spell.SpellHasRange) or SpellHasRange,id)
  if hasRange==false then return nil,"사거리 판정이 없는 주문입니다. 전문기술·탈것 등은 제외합니다." end
  if self.Range.PublicField(info,"isOffSpec")==true then return nil,"현재 활성화되지 않은 전문화의 주문입니다." end
  local spellInfo=read(C_Spell and C_Spell.GetSpellInfo,id)
  local icon=self.Range.PublicField(spellInfo,"iconID") or self.Range.PublicField(info,"iconID")
  if not icon then local _,_,legacyIcon=read(GetSpellInfo,id);icon=legacyIcon end
  -- No target/range nil is not a rejection; don't run a unit range query here.
  return {id=id,name=name,icon=icon or "Interface\\Icons\\INV_Misc_QuestionMark"},
    hasRange==nil and "등록 가능. 사거리 지원 여부는 대상 선택 후 확인하세요." or "등록 가능."
end
function FR:SetReferenceSpell(slot,input)
  if slot~="melee" and slot~="ranged" then return false end
  if not KHQOL.db or not KHQOL:GetEnabled("range") then return false,"사거리 모듈을 먼저 켜세요." end
  local empty=KHQOL.IsPublicValue(input) and tostring(input or ""):match("^%s*$")
  local item,message
  if not empty then
    item,message=self:ValidateReferenceSpell(input)
    if not item then self:Print(message);self.registrationMessage=message;self:UpdateSettings();return false,message end
  end
  self.db[slot.."SpellID"]=item and item.id or nil
  self.db[slot.."SpellName"]=item and item.name or nil
  if slot=="ranged" then self.db.rangeSpellID,self.db.rangeSpellName=self.db.rangedSpellID,self.db.rangedSpellName
  elseif select(2,UnitClass("player"))=="HUNTER" then self.db.hunterMeleeSpellID,self.db.hunterMeleeSpellName=self.db.meleeSpellID,self.db.meleeSpellName end
  self.Range:ClearActionSlotCache()
  self.registrationMessage=item and ((slot=="melee" and "근거리" or "원거리").." 등록: "..item.name.." ("..item.id..")") or "등록 해제."
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
  self:RefreshDisplay(true);self:UpdateSettings()
  if self.RefreshSpellBookPanel then self:RefreshSpellBookPanel() end
  return true,self.registrationMessage
end
function FR:SetRangeSpell(input) return self:SetReferenceSpell("ranged",input) end
function FR:SetMeleeSpell(input) return self:SetReferenceSpell("melee",input) end
function FR:CaptureCursorSpell(slot)
  -- The fourth return is a SpellID on the referenced client. The second is a
  -- spellbook index and is never guessed to be a SpellID on unknown clients.
  local kind,_,_,id=read(GetCursorInfo)
  if kind~="spell" or not validID(id) then self:Print("지원되는 주문 커서 정보가 없습니다. KHQOL 주문 목록 또는 SpellID 입력을 사용하세요.");return false end
  local ok=self:SetReferenceSpell(slot or "ranged",id)
  if ok and type(ClearCursor)=="function" then ClearCursor() end
  return ok
end


function FR:SetNumber(key, value, minValue, maxValue)
  value = tonumber(value)
  if not value then return end
  self.db[key] = math.max(minValue, math.min(maxValue, math.floor(value + 0.5)))
  self:RefreshDisplay(true); self:UpdateSettings()
end

local function parseRGB(text)
  local r, g, b = tostring(text):match("^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$")
  r, g, b = tonumber(r), tonumber(g), tonumber(b)
  if not r or not g or not b then return nil end
  return math.max(0, math.min(1, r)), math.max(0, math.min(1, g)), math.max(0, math.min(1, b))
end

function FR:SetColorText(state, text)
  local r, g, b = parseRGB(text)
  if not r then self:Print("Use color format: 0.00, 0.00, 0.00"); return end
  self:SetColor(state, r, g, b, 1); self:UpdateSettings()
end

function FR:SetOutlineColor(text)
  local r, g, b = parseRGB(text)
  if not r then self:Print("Use color format: 0.00, 0.00, 0.00"); return end
  local c = self.db.outline.color; c[1], c[2], c[3], c[4] = r, g, b, 1
  self:RefreshDisplay(true); self:UpdateSettings()
end

function FR:SetOutlineThickness(value)
  self.db.outline.thickness = math.max(0, math.min(4, math.floor((tonumber(value) or 1) + 0.5)))
  self:RefreshDisplay(true); self:UpdateSettings()
end

function FR:ToggleLock(force)
  self.db.locked = force == nil and not self.db.locked or force
  self:RefreshDisplay(true); self:UpdateSettings()
  self:Print(self.db.locked and "Indicator locked." or "Indicator unlocked. Drag it to move.")
end

function FR:CycleTest()
  local states = { "GREEN", "RED", "ORANGE" }
  local index = 0
  for i, state in ipairs(states) do if state == self.testState then index = i end end
  self.testState = states[index % #states + 1]
  self.testUntil = GetTime() + 3
  self:RefreshDisplay(true)
end

function FR:RefreshDisplay(force)
  if self.Mouseover then self.Mouseover:Update() end
  if _G.KHQOL and _G.KHQOL.db and not _G.KHQOL:GetEnabled("range") then if self.Display.frame then self.Display:Hide() end; return end
  if not self.Display.frame then return end
  if self.testState and GetTime() < self.testUntil then self.Display:ShowState(self.testState, force); return end
  self.testState = nil
  local state = self.Range:GetTargetState()
  if state then self.Display:ShowState(state, force) else self.Display:Hide() end
end

function FR:OnEvent(event, ...)
  if event == "PLAYER_LOGIN" then
    self:InitializeDB(); self.Display:Create(); self.Mouseover:Initialize()
    if select(2,UnitClass("player"))=="HUNTER" then self.Range:PrepareHunterRangeItems() end
    self:RefreshDisplay(true)
    if self.TryAttachSpellBook then self:TryAttachSpellBook() end
  else
    if event == "SPELLS_CHANGED" or event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
      self.Range:ClearActionSlotCache()
      if self.RefreshSpellBookPanel then self:RefreshSpellBookPanel(true) end
    end
    if event=="ADDON_LOADED" or event=="PLAYER_REGEN_ENABLED" then
      if self.TryAttachSpellBook then self:TryAttachSpellBook() end
    end
    self:RefreshDisplay()
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("UNIT_TARGET")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, ...) FR:OnEvent(event, ...) end)

local elapsed = 0
local function updateRange(_, delta)
  elapsed = elapsed + delta
  if elapsed < 0.08 then return end
  elapsed = 0
  if FR.db then FR:RefreshDisplay() end
end
eventFrame:SetScript("OnUpdate", updateRange)

function FR:SetEnabled(enabled)
  if enabled and self.TryAttachSpellBook then self:TryAttachSpellBook() end
  if self.SyncSpellBook then self:SyncSpellBook(enabled) end
  if not enabled and self.Mouseover then self.Mouseover:Hide() end
  -- Retain cache-invalidation events while disabled, so re-enabling uses the
  -- current action bar. Only the idle polling callback is detached.
  eventFrame:SetScript("OnUpdate", enabled and updateRange or nil)
  if self.Display and self.Display.frame then
    self.Display.frame:SetShown(enabled)
    if enabled and self.RefreshDisplay then self:RefreshDisplay(true) end
  end
end

SLASH_FRANGE1 = "/frange"
SlashCmdList.FRANGE = function(message)
  local command = (message or ""):lower():match("^%s*(%S*)")
  if command == "" then if _G.KHQOL and _G.KHQOL.OpenModule then _G.KHQOL:OpenModule("range") else FR:OpenSettings() end
  elseif command == "test" then FR:CycleTest()
  elseif command == "lock" then FR:ToggleLock(true)
  elseif command == "unlock" then FR:ToggleLock(false)
  elseif command == "reset" then FR:ResetDB(); FR:Print("Character settings reset.")
  elseif command == "api" then FR.Range:DescribeAPI()
  else FR:Print("/frange, /frange test, /frange lock, /frange unlock, /frange reset, /frange api") end
end
