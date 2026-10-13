local ADDON_NAME, KHQOL = ...
local FBR = CreateFrame("Frame")
_G.ForeverBuffReminder = FBR

local function isSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

FBR.VERSION = 1
FBR.DEFAULT_THRESHOLD = 10
FBR.DEFAULT_ICON_SIZE = 80
FBR.BUFF_STATE_ACTIVE = "ACTIVE"
FBR.BUFF_STATE_MISSING = "MISSING"
FBR.BUFF_STATE_UNKNOWN = "UNKNOWN"
FBR.CLASS_TOKENS = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}
FBR.CLASS_NAMES = {
    WARRIOR = "전사", PALADIN = "성기사", HUNTER = "사냥꾼", ROGUE = "도적",
    PRIEST = "사제", SHAMAN = "주술사", MAGE = "마법사", WARLOCK = "흑마법사", DRUID = "드루이드",
}
FBR.SHAMAN_TOTEM_SLOTS = { EARTH = 2, FIRE = 1, WATER = 3, AIR = 4 }
FBR.SHAMAN_TOTEM_LABELS = { EARTH = "대지", FIRE = "불", WATER = "물", AIR = "바람" }
FBR.SHAMAN_WEAPON_AURA_SPELLS = {
    [8017] = true, [8018] = true, [8019] = true, [10399] = true, [16314] = true, [16315] = true, [16316] = true, -- Rockbiter
    [8024] = true, [8027] = true, [8030] = true, [16339] = true, [16341] = true, [16342] = true, -- Flametongue
    [8033] = true, [8038] = true, [10456] = true, [16355] = true, [16356] = true, [16357] = true, -- Frostbrand
    [8232] = true, [8235] = true, [10486] = true, [16362] = true, [25505] = true, -- Windfury
}
FBR.SHAMAN_WEAPON_NAME_SPELLS = { 8017, 8024, 8033, 8232 }
FBR.SHAMAN_TOTEM_SPELLS = {
    EARTH = { 2484, 5730, 6390, 6391, 6392, 10427, 10428, 8071, 8154, 8155, 10406, 10407, 10408, 8075, 8160, 8161, 10442, 25361, 8143 },
    FIRE = { 3599, 6363, 6364, 6365, 10437, 10438, 8190, 10585, 10586, 10587, 8227, 8249, 10526, 16387, 1535, 8498, 8499, 11314, 11315, 8181, 10478, 10479, 10480 },
    WATER = { 5394, 6375, 6377, 10462, 10463, 5675, 10495, 10496, 10497, 8184, 10537, 10538, 8166, 8170, 8177, 16190 },
    AIR = { 8512, 10613, 10614, 8835, 10627, 25359, 10595, 10600, 10601, 6495, 15107, 25908 },
}

function FBR:Debug(message)
    if ForeverBuffReminderDB and ForeverBuffReminderDB.debug then
        print("|cffefb54aFBR:|r " .. tostring(message))
    end
end

function FBR:Print(message)
    print("|cffefb54aForeverBuffReminder:|r " .. tostring(message))
end

function FBR:GetCurrentClass()
    local _, token = UnitClass("player")
    return token
end

function FBR:InitializeDatabase()
    if KHQOL.InitializeProfiles then KHQOL:InitializeProfiles() end
    local defaults = {
        version = self.VERSION, iconSize = self.DEFAULT_ICON_SIZE,
        thresholdSeconds = self.DEFAULT_THRESHOLD, locked = true,
        position = { point = "CENTER", x = 0, y = 0 },
        settingsPosition = { point = "CENTER", x = 0, y = 0 },
        layoutDirection = "RIGHT",
        classes = {}, selectedClass = nil, debug = false,
    }
    self.profileDefaults = defaults
    ForeverBuffReminderDB = ForeverBuffReminderDB or {}
    KHQOL.MergeDefaults(ForeverBuffReminderDB, defaults)
    for _, classToken in ipairs(self.CLASS_TOKENS) do
        ForeverBuffReminderDB.classes[classToken] = ForeverBuffReminderDB.classes[classToken] or { buffs = {} }
        ForeverBuffReminderDB.classes[classToken].buffs = ForeverBuffReminderDB.classes[classToken].buffs or {}
        -- 0.0.11's experimental name-only records are intentionally discarded.
        -- This release supports only verified numeric Spell IDs.
        for index = #ForeverBuffReminderDB.classes[classToken].buffs, 1, -1 do
            if type(ForeverBuffReminderDB.classes[classToken].buffs[index].spellID) ~= "number" then
                table.remove(ForeverBuffReminderDB.classes[classToken].buffs, index)
            end
        end
        for _, buff in ipairs(ForeverBuffReminderDB.classes[classToken].buffs) do
            if buff.displayMode == nil then buff.displayMode = "ALWAYS" end
            if buff.displayMode == "REST" then buff.displayMode = "ALWAYS" end
        end
    end
    local shaman = ForeverBuffReminderDB.classes.SHAMAN
    shaman.specials = shaman.specials or {}
    shaman.specials.weapon = shaman.specials.weapon or {}
    shaman.specials.weapon.mainHand = shaman.specials.weapon.mainHand or { enabled = false }
    shaman.specials.weapon.offHand = shaman.specials.weapon.offHand or { enabled = false }
    shaman.specials.totems = shaman.specials.totems or {}
    for key in pairs(self.SHAMAN_TOTEM_SLOTS) do
        shaman.specials.totems[key] = shaman.specials.totems[key] or { enabled = false }
    end
    local currentClass = self:GetCurrentClass()
    -- The account-wide last selection may belong to another character.
    -- Start each login/reload on this character; keep all class presets intact.
    if currentClass and self.CLASS_NAMES[currentClass] then
        ForeverBuffReminderDB.selectedClass = currentClass
    end
end

function FBR:GetShamanSpecialSettings()
    local shaman = ForeverBuffReminderDB.classes.SHAMAN
    return shaman and shaman.specials
end

function FBR:IsKnownSpell(spellID)
    local known
    if IsPlayerSpell then
        local ok, value = pcall(IsPlayerSpell, spellID)
        if ok and not isSecret(value) then known = value end
    elseif IsSpellKnown then
        local ok, value = pcall(IsSpellKnown, spellID)
        if ok and not isSecret(value) then known = value end
    end
    return known == true
end

function FBR:IsShamanWeaponAuraName(name)
    if type(name) ~= "string" then return false end
    for _, spellID in ipairs(self.SHAMAN_WEAPON_NAME_SPELLS) do
        local spellName = self:GetSpellDetails(spellID)
        if spellName and name:find(spellName, 1, true) == 1 then return true end
    end
    return false
end

function FBR:GetSelectedClassData()
    local token = ForeverBuffReminderDB.selectedClass or self:GetCurrentClass() or self.CLASS_TOKENS[1]
    ForeverBuffReminderDB.selectedClass = token
    ForeverBuffReminderDB.classes[token] = ForeverBuffReminderDB.classes[token] or { buffs = {} }
    return ForeverBuffReminderDB.classes[token]
end

function FBR:GetCurrentClassBuffs()
    local token = self:GetCurrentClass()
    local data = ForeverBuffReminderDB.classes[token]
    return data and data.buffs or {}
end

-- All game API calls and values which may be protected are contained here.
-- A failure deliberately returns UNKNOWN; it is never converted into MISSING.
function FBR:GetSpellDetails(spellID)
    local ok, name, icon
    if C_Spell and C_Spell.GetSpellInfo then
        ok, name = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(name) == "table" then
            local info = name
            ok, name, icon = pcall(function()
                local spellName, spellIcon = info.name, info.iconID
                if isSecret(spellName) or isSecret(spellIcon) then return nil, nil end
                return spellName, spellIcon
            end)
        end
    elseif GetSpellInfo then
        ok, name, _, icon = pcall(GetSpellInfo, spellID)
    end
    if not ok or isSecret(name) or isSecret(icon) or type(name) ~= "string" or name == "" then
        if C_Spell and C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, spellID) end
        return nil
    end
    return name, icon
end

function FBR:ResolveSpellInput(input)
    input = (input or ""):match("^%s*(.-)%s*$")
    if input == "" then return nil, "주문 ID 또는 버프 이름을 입력하세요." end
    local numericID = tonumber(input)
    if numericID and numericID > 0 and numericID == math.floor(numericID) then
        local name, icon = self:GetSpellDetails(numericID)
        if not name then return nil, "클라이언트에서 확인할 수 없는 Spell ID입니다." end
        return { spellID = numericID, name = name, icon = icon }
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, input)
        if ok and type(info) == "table" and type(info.spellID) == "number" and info.name == input then
            return { spellID = info.spellID, name = info.name, icon = info.iconID }
        end
    end
    return nil, "이름만으로는 안전하게 Spell ID를 확인할 수 없습니다. Spell ID를 입력하세요."
end

function FBR:FindPlayerAura(spellID,spellName)
    local result=self.auraBatch or KHQOL.AuraReader:Read({[spellID]={name=spellName}})
    local value=result[spellID]
    if not value or value.state=="UNKNOWN" then return nil end
    if value.state=="MISSING" then return false end
    return value
end

function FBR:RecordBuffState(spellID, state, source, aura)
    self.buffStateCache = self.buffStateCache or {}
    local entry = self.buffStateCache[spellID] or {}
    entry.state = state
    entry.source = source
    if state == self.BUFF_STATE_UNKNOWN then
        entry.confidence = "UNKNOWN"
        entry.duration=nil;entry.expirationTime=nil
        entry.lastAttemptAt = GetTime()
    else
        entry.confidence = "CONFIRMED"
        entry.observedAt = GetTime()
        entry.lastConfirmedState = state
        if state == self.BUFF_STATE_ACTIVE and type(aura) == "table" then
            entry.duration = type(aura.duration) == "number" and aura.duration or nil
            entry.expirationTime = type(aura.expirationTime) == "number" and aura.expirationTime or nil
        else
            entry.duration = nil
            entry.expirationTime = nil
        end
    end
    self.buffStateCache[spellID] = entry
    return entry
end

function FBR:EvaluateAuraState(spellID, spellName)
    local aura = self:FindPlayerAura(spellID, spellName)
    if aura == nil then return self.BUFF_STATE_UNKNOWN, nil, "aura-unreadable" end
    if aura == false then return self.BUFF_STATE_MISSING, nil, "aura-scan" end
    return self.BUFF_STATE_ACTIVE, aura, "aura-scan"
end

function FBR:GetBuffState(buff)
    local name, icon = self:GetSpellDetails(buff.spellID)
    if not name then
        self:RecordBuffState(buff.spellID, self.BUFF_STATE_UNKNOWN, "spell-data")
        return self.BUFF_STATE_UNKNOWN, nil, nil, nil
    end
    local auraState, aura, source = self:EvaluateAuraState(buff.spellID, name)
    self:RecordBuffState(buff.spellID, auraState, source, aura)
    if auraState == self.BUFF_STATE_UNKNOWN then return self.BUFF_STATE_UNKNOWN, nil, name, icon end
    if auraState == self.BUFF_STATE_MISSING then return self.BUFF_STATE_MISSING, nil, name, icon end
    local duration, expiration = aura.duration, aura.expirationTime
    if type(duration) ~= "number" or type(expiration) ~= "number" or duration <= 0 or expiration <= 0 then
        return "NORMAL", nil, name, icon
    end
    local ok, remaining = pcall(function() return expiration - GetTime() end)
    if not ok or type(remaining) ~= "number" or remaining<=0 then return "UNKNOWN", nil, name, icon end
    if remaining <= self:GetThreshold() then
        return "EXPIRING", math.max(0, remaining), name, icon
    end
    return "NORMAL", remaining, name, icon
end

function FBR:GetWeaponAuraFallback()
    local registered={}
    for id in pairs(self.SHAMAN_WEAPON_AURA_SPELLS) do registered[id]={} end
    for _,id in ipairs(self.SHAMAN_WEAPON_NAME_SPELLS) do
        local name=self:GetSpellDetails(id)
        if KHQOL.IsPublicValue(name) and type(name)=="string" then registered[id].name=name end
    end
    local observations=KHQOL.AuraReader:Read(registered)
    local unreadable=false
    for _,aura in pairs(observations) do
        if aura.state=="ACTIVE" then return aura.remaining or "NORMAL" end
        if aura.state=="UNKNOWN" then unreadable=true end
    end
    if unreadable then return nil end
    return false
end

function FBR:GetWeaponEnchantInfo(slot)
    local modern=C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo
    if type(modern)=="function" then
        local status,info=KHQOL.ReadPublicAPI(modern,slot)
        if status~="ok" then return nil end
        if type(info)=="table" then
            local fieldStatus,remaining=KHQOL.ReadPublicAPI(function() return info.remainingTimeMs end)
            if fieldStatus~="ok" or not KHQOL.PositionStore:Number(remaining) or remaining<=0 then return nil end
            return "ACTIVE",remaining/1000
        elseif info~=nil and info~=false then return nil end
    end
    if type(GetWeaponEnchantInfo)=="function" then
        local status,hasMain,mainMs,_,_,hasOff,offMs=KHQOL.ReadPublicAPI(GetWeaponEnchantInfo)
        if status~="ok" then return nil end
        local active,remaining=hasMain,mainMs
        if slot~=16 then active,remaining=hasOff,offMs end
        if active==true then
            if not KHQOL.PositionStore:Number(remaining) or remaining<=0 then return nil end
            return "ACTIVE",remaining/1000
        elseif active~=false then return nil end
    end
    -- Forever may expose an imbue only as an aura. It cannot identify the hand.
    if slot==16 then
        local remaining=self:GetWeaponAuraFallback()
        if remaining==nil then return nil end
        if remaining==false then return false end
        if remaining=="NORMAL" then return "NORMAL",nil end
        return "ACTIVE",remaining
    end
    return false
end

function FBR:GetTotemState(slot)
    if C_Secrets and type(C_Secrets.ShouldTotemSlotBeSecret)=="function" then
        local state,value=KHQOL.ReadPublicAPI(C_Secrets.ShouldTotemSlotBeSecret,slot)
        if state~="ok" or value~=false then return nil end
    end
    local status,haveTotem,name,startTime,duration,icon=KHQOL.ReadPublicAPI(GetTotemInfo,slot)
    if status~="ok" then return nil end
    if haveTotem==false then return false end
    if type(name)~="string" then return nil end
    if name=="" then return false end
    if not KHQOL.PositionStore:Number(startTime) or not KHQOL.PositionStore:Number(duration) or startTime<0 or duration<0 then return nil end
    if duration==0 then return "NORMAL",nil,icon end
    local timeStatus,now=KHQOL.ReadPublicAPI(GetTime)
    if timeStatus~="ok" or not KHQOL.PositionStore:Number(now) then return nil end
    local remaining=startTime+duration-now
    if remaining<=0 then return nil end
    if remaining<=self:GetThreshold() then return "EXPIRING",remaining,icon end
    return "NORMAL",remaining,icon
end

function FBR:GetShamanSpecialAlerts()
    if self:GetCurrentClass() ~= "SHAMAN" then return {} end
    local specials = self:GetShamanSpecialSettings()
    if not specials then return {} end
    local alerts = {}
    local weaponSlots = { { key = "mainHand", slot = 16, label = "주무기 강화" }, { key = "offHand", slot = 17, label = "보조무기 강화" } }
    for _, entry in ipairs(weaponSlots) do
        if specials.weapon[entry.key].enabled then
            local state, remaining = self:GetWeaponEnchantInfo(entry.slot)
            if state == false or state == "ACTIVE" and remaining <= self:GetThreshold() then
                local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
                if GetInventoryItemTexture then
                    local ok, icon = pcall(GetInventoryItemTexture, "player", entry.slot)
                    if ok and KHQOL.IsPublicValue(icon) and icon then texture = icon end
                end
                alerts[#alerts + 1] = { key = "shaman-weapon-" .. entry.key, state = state == false and "MISSING" or "EXPIRING", remaining = remaining, name = entry.label, icon = texture }
            end
        end
    end
    for _, key in ipairs({ "EARTH", "FIRE", "WATER", "AIR" }) do
        local slot = self.SHAMAN_TOTEM_SLOTS[key]
        if specials.totems[key].enabled then
            local state, remaining, icon = self:GetTotemState(slot)
            if state == false or state == "EXPIRING" then
                local selectedSpellID = specials.totems[key].spellID
                local selectedIcon
                if selectedSpellID then
                    local _, resolvedIcon = self:GetSpellDetails(selectedSpellID)
                    selectedIcon = resolvedIcon
                end
                alerts[#alerts + 1] = { key = "shaman-totem-" .. key, state = state == false and "MISSING" or "EXPIRING", remaining = remaining, name = self.SHAMAN_TOTEM_LABELS[key] .. " 토템", icon = icon or selectedIcon or "Interface\\Icons\\INV_Misc_QuestionMark" }
            end
        end
    end
    return alerts
end

function FBR:IsDisplayModeActive(buff)
    local mode = buff.displayMode or "ALWAYS"
    local inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() or false
    return mode == "ALWAYS" or (mode == "COMBAT" and inCombat)
end

function FBR:GetThreshold()
    return tonumber(ForeverBuffReminderDB.thresholdSeconds) or self.DEFAULT_THRESHOLD
end

function FBR:RefreshAlerts()
    if _G.KHQOL and _G.KHQOL.db and not _G.KHQOL:GetEnabled("buffReminder") then
        self:StopCountdown()
        if self.HideAlerts then self:HideAlerts() end
        return
    end
    if not self.initialized then return end
    local alerts = {}
    local nextRefreshDelay
    local function scheduleAt(delay)
        if type(delay) ~= "number" then return end
        if delay < 0 then delay = 0 end
        if not nextRefreshDelay or delay < nextRefreshDelay then nextRefreshDelay = delay end
    end
    if self.testMode then
        alerts = self:GetTestAlerts()
        scheduleAt(0.5)
    else
        local registered={}
        for _,buff in ipairs(self:GetCurrentClassBuffs()) do
            if buff.enabled then local name=self:GetSpellDetails(buff.spellID);registered[buff.spellID]={name=name} end
        end
        self.auraBatch=KHQOL.AuraReader:Read(registered)
        for index, buff in ipairs(self:GetCurrentClassBuffs()) do
            if buff.enabled then
                local state, remaining, name, icon = self:GetBuffState(buff)
                if self:IsDisplayModeActive(buff) and (state == "MISSING" or state == "EXPIRING") then
                    alerts[#alerts + 1] = { key = buff.spellID, index = index, state = state, remaining = remaining, name = name, icon = icon }
                end
                if state == "EXPIRING" then
                    scheduleAt(0.5)
                elseif state == "NORMAL" and type(remaining) == "number" then
                    scheduleAt(remaining - self:GetThreshold())
                end
            end
        end
        self.auraBatch=nil
        if self:GetCurrentClass() == "SHAMAN" then
            for _, alert in ipairs(self:GetShamanSpecialAlerts()) do alerts[#alerts + 1] = alert end
        end
    end
    self:ShowAlerts(alerts)
    self:ScheduleNextRefresh(nextRefreshDelay)
end

function FBR:ScheduleNextRefresh(delay)
    self:StopCountdown()
    if type(delay) ~= "number" or not C_Timer or not C_Timer.NewTimer then return end
    self.countdownTicker = C_Timer.NewTimer(math.max(0.1, delay), function()
        FBR.countdownTicker = nil
        FBR:RefreshAlerts()
    end)
end

function FBR:StopCountdown()
    if self.countdownTicker then self.countdownTicker:Cancel(); self.countdownTicker = nil end
end

function FBR:GetTestAlerts()
    local questionMark = "Interface\\Icons\\INV_Misc_QuestionMark"
    return {
        { key = "test-missing", index = 1, state = "MISSING", name = "테스트: 버프 없음", icon = questionMark },
        { key = "test-nine", index = 2, state = "EXPIRING", remaining = 9, name = "테스트: 9초", icon = questionMark },
        { key = "test-five", index = 3, state = "EXPIRING", remaining = 5, name = "테스트: 5초", icon = questionMark },
    }
end

function FBR:PrintStatus()
    local current = self:GetCurrentClass() or "UNKNOWN"
    self:Print("접속 직업: " .. current .. ", 감시 기준: " .. self:GetThreshold() .. "초")
    for _, buff in ipairs(self:GetCurrentClassBuffs()) do
        if buff.enabled then
            local state, remaining, name = self:GetBuffState(buff)
            self:Print((name or ("Spell " .. buff.spellID)) .. " — " .. state .. (remaining and (" (" .. math.floor(remaining) .. "초)") or ""))
        end
    end
end

FBR:RegisterEvent("PLAYER_LOGIN")
FBR:RegisterEvent("PLAYER_ENTERING_WORLD")
FBR:RegisterEvent("UNIT_AURA")
FBR:RegisterEvent("SPELL_DATA_LOAD_RESULT")
FBR:RegisterEvent("PLAYER_REGEN_DISABLED")
FBR:RegisterEvent("PLAYER_REGEN_ENABLED")
FBR:RegisterEvent("PLAYER_DEAD")
FBR:RegisterEvent("PLAYER_ALIVE")
FBR:RegisterEvent("PLAYER_TOTEM_UPDATE")
FBR:RegisterEvent("WEAPON_ENCHANT_CHANGED")
FBR:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        self:InitializeDatabase()
        self:CreateAlertUI()
        -- Settings controls are created in their owning tab on first use.
        self:CreateMinimapButton()
        self.initialized = true
        self:RefreshAlerts()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_TOTEM_UPDATE" or event == "WEAPON_ENCHANT_CHANGED" then
        self:RefreshAlerts()
    elseif event == "UNIT_AURA" and unit == "player" then
        self:RefreshAlerts()
    elseif event == "SPELL_DATA_LOAD_RESULT" then
        self:RefreshSettings()
        self:RefreshAlerts()
    end
end)

SLASH_FOREVERBUFFREMINDER1 = "/fbr"
SlashCmdList.FOREVERBUFFREMINDER = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "test" then FBR.testMode = true; FBR:RefreshAlerts(); FBR:Print("테스트 알림을 표시합니다.")
    elseif message == "test off" then FBR.testMode = false; FBR:RefreshAlerts(); FBR:Print("테스트 알림을 종료했습니다.")
    elseif message == "status" then FBR:PrintStatus()
    elseif message == "weapon" then
        local mainState, mainRemaining = FBR:GetWeaponEnchantInfo(16)
        local offState, offRemaining = FBR:GetWeaponEnchantInfo(17)
        FBR:Print("무기 강화 — 주: " .. tostring(mainState) .. (mainRemaining and (" (" .. math.floor(mainRemaining) .. "초)") or "") .. ", 보조: " .. tostring(offState) .. (offRemaining and (" (" .. math.floor(offRemaining) .. "초)") or ""))
    elseif message == "debug" then ForeverBuffReminderDB.debug = not ForeverBuffReminderDB.debug; FBR:Print("디버그: " .. (ForeverBuffReminderDB.debug and "ON" or "OFF"))
    else if _G.KHQOL and _G.KHQOL.OpenModule then _G.KHQOL:OpenModule("buffReminder") else FBR:ToggleSettings() end end
end
