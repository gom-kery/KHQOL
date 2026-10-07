local ADDON_NAME, KHQOL = ...
local CFA = KHQOL.modules.campfire

CFA.NAME = ADDON_NAME or "CampfireAlert"
CFA.PREFIX = "[CampfireAlert]"
CFA.VERSION = "1.0.13"
CFA.SPELLS = {
    NEARBY_CAMPFIRE = 1283391,
    REST_PROCESS = 1229739,
    CAMP_BENEFITS = {
        1229741,
        -- Add future Camp Benefits IDs here.
    },
}
CFA.ICON_FILE_ID = 7808147
-- Experimental: item 279981 uses spell 1307227. Its primary summoned campfire
-- is 529161, with temporary camp components 573022 and 529148. 29784 remains
-- for the legacy Spell 818 small campfire.
CFA.CAMPFIRE_GAMEOBJECT_IDS = {
    529161,
    573022,
    529148,
    29784,
}
-- Keep discovery visible while a Camp Benefit is active. This is useful because
-- Forever camp benefits cannot always be removed manually for repeat testing.
CFA.SHOW_DETECTION_WITH_BENEFIT = true
CFA.STATES = {
    IDLE = "IDLE",
    DETECTED = "CAMPFIRE_DETECTED",
    WAITING = "SITTING_WAITING",
    COMPLETE = "CAMP_BENEFIT_ACQUIRED",
}
CFA.state = CFA.STATES.IDLE
CFA.timer = nil
CFA.distanceTicker = nil
CFA.nearestCampfireDistance = nil
CFA.lastAuraState = {}
CFA.lastBenefitExpiration = nil
CFA.inCombat = false
CFA.dismissedForCurrentCampfire = false

local defaults = {
    version = 1,
    debug = false,
    position = { point = "CENTER", x = 0, y = 80 },
    iconSize = 100,
    fontSize = 50,
    message = "모닥불 발견!",
    locked = false,
}

function CFA:Print(message)
    local chat = DEFAULT_CHAT_FRAME or ChatFrame1
    if chat then chat:AddMessage(self.PREFIX .. " " .. tostring(message)) end
end

function CFA:Debug(message)
    if self.db and self.db.debug then
        self:Print("Debug: " .. tostring(message))
    end
end

function CFA:SetState(state)
    self.state = state
end

function CFA:CancelTimer()
    if self.timer and self.timer.ticker and self.timer.ticker.Cancel then
        self.timer.ticker:Cancel()
    end
    if self.ui and self.ui.progress then
        self.ui.progress:SetScript("OnUpdate", nil)
    end
    self.timer = nil
end

function CFA:CancelDistanceScan()
    if self.distanceTicker and self.distanceTicker.Cancel then
        self.distanceTicker:Cancel()
    end
    self.distanceTicker = nil
end

function CFA:UpdateCampfireDistance()
    if not self.ui or not self.ui.distance then return end
    if type(ClosestGameObjectPosition) ~= "function" then
        self.nearestCampfireDistance = nil
        self.ui.distance:Hide()
        return
    end

    local nearestDistance, nearestObjectID = nil, nil
    for _, objectID in ipairs(self.CAMPFIRE_GAMEOBJECT_IDS) do
        local ok, _, _, distance = pcall(ClosestGameObjectPosition, objectID)
        if ok and type(distance) == "number" and distance >= 0 and (not nearestDistance or distance < nearestDistance) then
            nearestDistance, nearestObjectID = distance, objectID
        end
    end
    self.nearestCampfireDistance = nearestDistance
    if nearestDistance then
        -- ClosestGameObjectPosition returns yards; show the Korean UI in metres.
        local meters = math.max(1, math.floor(nearestDistance * 0.9144 + 0.5))
        self.ui.distance:SetText("모닥불까지 약 " .. meters .. "m")
        self.ui.distance:Show()
    else
        self.ui.distance:Hide()
    end
end

function CFA:StartDistanceScan()
    self:CancelDistanceScan()
    self:UpdateCampfireDistance()
    if type(ClosestGameObjectPosition) == "function" and C_Timer and C_Timer.NewTicker then
        self.distanceTicker = C_Timer.NewTicker(0.5, function() CFA:UpdateCampfireDistance() end)
    end
end

function CFA:DiagnoseCampfireDistance()
    if type(ClosestGameObjectPosition) ~= "function" then
        self:Print("Distance API: unavailable (ClosestGameObjectPosition 없음)")
        return
    end
    self:Print("Distance API: available")
    for _, objectID in ipairs(self.CAMPFIRE_GAMEOBJECT_IDS) do
        local ok, _, _, distance = pcall(ClosestGameObjectPosition, objectID)
        if not ok then
            self:Print("Object " .. objectID .. ": query failed")
        elseif type(distance) == "number" and distance >= 0 then
            self:Print("Object " .. objectID .. ": " .. string.format("%.1f yd", distance))
        else
            self:Print("Object " .. objectID .. ": not found")
        end
    end
end

function CFA:StopWaiting(message)
    self:CancelTimer()
    if self.ui then
        self.ui.progress:Hide()
        if message then self:SetStatusText(message) end
    end
    if self:HasPlayerAura(self.SPELLS.NEARBY_CAMPFIRE) then
        self:SetState(self.STATES.DETECTED)
    else
        self:SetState(self.STATES.IDLE)
    end
end

function CFA:StartWaiting(aura)
    self:CancelTimer()
    local duration, expiration = 60, nil
    if aura and tonumber(aura.duration) and tonumber(aura.expirationTime) and aura.duration > 0 and aura.expirationTime > 0 then
        duration = aura.duration
        expiration = aura.expirationTime
    else
        expiration = GetTime() + duration
    end

    self.timer = { expiration = expiration, duration = duration, usingAura = aura ~= nil and aura.duration and aura.duration > 0 }
    self:SetState(self.STATES.WAITING)
    self:SetStatusText("야영 효과를 얻는 중...")
    self.ui.progress:Show()
    self:UpdateProgress()
    if C_Timer and C_Timer.NewTicker then
        self.timer.ticker = C_Timer.NewTicker(0.1, function() CFA:UpdateProgress() end)
    else
        -- Legacy fallback: attached only for this active timer and removed by CancelTimer.
        local elapsed = 0
        self.ui.progress:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta
            if elapsed >= 0.1 then
                elapsed = 0
                CFA:UpdateProgress()
            end
        end)
        self:Debug("C_Timer.NewTicker is unavailable; using an active-timer OnUpdate fallback.")
    end
end

function CFA:SyncWaitingWithRestAura(aura)
    if self.state ~= self.STATES.WAITING or not aura then return end
    local duration, expiration = tonumber(aura.duration), tonumber(aura.expirationTime)
    if not duration or duration <= 0 or not expiration or expiration <= 0 then return end
    if not self.timer or math.abs((self.timer.expiration or 0) - expiration) > 0.15 then
        self:Debug("Synchronizing progress with rest aura duration.")
        self:StartWaiting(aura)
    end
end

function CFA:UpdateProgress()
    local timer = self.timer
    if not timer or self.state ~= self.STATES.WAITING then return end
    local remaining = math.max(0, timer.expiration - GetTime())
    local ratio = timer.duration > 0 and (remaining / timer.duration) or 0
    self.ui.progress:SetValue(ratio)
    self.ui.progress.text:SetText(math.ceil(remaining) .. "초")
    if remaining <= 0 then
        self:CancelTimer()
        -- Success is never inferred from elapsed time. This also supports
        -- re-sitting while an older non-removable benefit remains active.
        self.ui.progress:SetValue(0)
        self.ui.progress.text:SetText("0초")
        self:SetStatusText("새 야영 효과를 확인 중... 다시 앉아주세요")
        self:SetState(self.STATES.DETECTED)
    end
end

function CFA:OnCampfireClick()
    if self.inCombat or (InCombatLockdown and InCombatLockdown()) then
        self:Print("전투 중에는 자동 앉기를 사용할 수 없습니다.")
        return
    end
    if not self:HasPlayerAura(self.SPELLS.NEARBY_CAMPFIRE) then
        self:HideDiscovery()
        self:SetState(self.STATES.IDLE)
        return
    end
    -- Forever Beta does not execute this addon's SecureActionButton macro
    -- reliably. DoEmote is run only from this physical button click.
    if type(DoEmote) == "function" then
        local ok = pcall(DoEmote, "SIT")
        if not ok then self:Debug("DoEmote(SIT) was rejected by the client.") end
    else
        self:Print("앉기 API를 사용할 수 없습니다.")
    end
    local restAura = self:GetPlayerAura(self.SPELLS.REST_PROCESS)
    self:CancelTimer()
    self:SetState(self.STATES.WAITING)
    self.ui.progress:Hide()
    self:SetStatusText("야영 진행 효과를 기다리는 중...")
    -- Do not start a guessed local timer in normal gameplay. The bar begins
    -- only after the client exposes the actual rest-process Aura.
    if restAura then self:StartWaiting(restAura) end
end

function CFA:HideDiscovery()
    self:CancelTimer()
    self:CancelDistanceScan()
    if self.ui then
        self.ui.discovery:Hide()
        self.ui.progress:Hide()
        if self.ui.distance then self.ui.distance:Hide() end
    end
end

function CFA:DismissDiscovery()
    -- Do not recreate the same alert until the player leaves this camp's range.
    self.dismissedForCurrentCampfire = true
    self:HideDiscovery()
    self:SetState(self.STATES.IDLE)
end

function CFA:ShowDiscovery()
    if self:HasAnyCampBenefit() and not self.SHOW_DETECTION_WITH_BENEFIT then
        self:HideDiscovery()
        return
    end
    self.ui.discovery:Show()
    self.ui.complete:Hide()
    self.ui.progress:Hide()
    self:StartDistanceScan()
    if self.inCombat then
        self:SetStatusText("전투 중에는 자동 앉기를 사용할 수 없습니다.")
    elseif self:HasAnyCampBenefit() then
        self:SetStatusText("이미 야영 효과를 보유 중입니다")
    else
        self:SetStatusText("")
    end
end

function CFA:SetStatusText(message)
    if self.ui and self.ui.status then
        self.ui.status:SetText(message or "")
        self.ui.status:SetShown(message ~= nil and message ~= "")
    end
end

function CFA:ShowComplete()
    self:HideDiscovery()
    self:SetState(self.STATES.COMPLETE)
    self.ui.complete:Show()
    if C_Timer and C_Timer.After then
        C_Timer.After(3, function()
            if CFA.ui then CFA.ui.complete:Hide() end
            if CFA:HasAnyCampBenefit() then CFA:SetState(CFA.STATES.IDLE) end
        end)
    end
end

function CFA:ProcessAuras(reason)
    if _G.KHQOL and _G.KHQOL.db and not _G.KHQOL:GetEnabled("campfire") then self:HideDiscovery(); return end
    if not self.initialized then return end
    local nearby = self:HasPlayerAura(self.SPELLS.NEARBY_CAMPFIRE)
    local restAura = self:GetPlayerAura(self.SPELLS.REST_PROCESS)
    local benefit = self:HasAnyCampBenefit()
    local previous = self.lastAuraState
    local previousExpiration = self.lastBenefitExpiration
    local expiration = benefit and tonumber(benefit.expirationTime) or nil
    local benefitRefreshed = expiration and previousExpiration and expiration > (previousExpiration + 30)

    self:ReportAuraTransition("proximity", self.SPELLS.NEARBY_CAMPFIRE, nearby, previous.nearby, "Detected proximity aura")
    self:ReportAuraTransition("rest", self.SPELLS.REST_PROCESS, restAura ~= nil, previous.rest, "Rest aura detected")
    self:ReportAuraTransition("benefit", benefit and benefit.spellId or self.SPELLS.CAMP_BENEFITS[1], benefit ~= nil, previous.benefit, "Camp benefit acquired")
    self.lastAuraState.nearby, self.lastAuraState.rest, self.lastAuraState.benefit = nearby, restAura ~= nil, benefit ~= nil
    self.lastBenefitExpiration = expiration

    if benefit and reason ~= "initial" and reason ~= "test" and (not previous.benefit or benefitRefreshed) then
        -- Existing benefits often persist. A substantial expiration increase is
        -- the reliable signal that the 60-minute camp benefit was refreshed.
        if benefitRefreshed then self:Debug("Camp benefit duration refreshed to 60 minutes.") end
        self:ShowComplete()
        return
    end
    if not nearby then
        self.dismissedForCurrentCampfire = false
        self:HideDiscovery()
        self:SetState(self.STATES.IDLE)
        return
    end
    if self.dismissedForCurrentCampfire then
        self:HideDiscovery()
        self:SetState(self.STATES.IDLE)
        return
    end
    -- Existing, non-removable Camp Benefits must not suppress the detection UI.
    -- This keeps the actual proximity Aura testable after a successful camp visit.
    if self.state == self.STATES.WAITING then
        if restAura then
            self:SyncWaitingWithRestAura(restAura)
        else
            self:CancelTimer()
            self.ui.progress:Hide()
            self:SetStatusText("야영 진행 효과를 기다리는 중...")
        end
        return
    end
    self:SetState(self.STATES.DETECTED)
    self:ShowDiscovery()
end

function CFA:ReportAuraTransition(kind, spellId, active, oldActive, message)
    if not self.db or not self.db.debug or oldActive == nil or active == oldActive then return end
    if active then
        self:Print("Debug: " .. message .. ": " .. tostring(spellId))
    else
        self:Print("Debug: " .. ({ proximity = "Proximity aura removed", rest = "Rest aura removed", benefit = "Camp benefit removed" })[kind] .. ": " .. tostring(spellId))
    end
end

function CFA:Initialize()
    if self.initialized then return end
    CampfireAlertDB = CampfireAlertDB or {}
    KHQOL.MergeDefaults(CampfireAlertDB, defaults, "tables")
    self.db = CampfireAlertDB
    self:CreateUI()
    self.initialized = true
    self:ProcessAuras("initial")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == CFA.NAME then CFA:Initialize() end
    elseif event == "PLAYER_LOGIN" then
        CFA:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CFA:Initialize(); CFA:ProcessAuras("initial")
    elseif event == "UNIT_AURA" and arg1 == "player" then
        CFA:ProcessAuras("event")
    elseif event == "PLAYER_REGEN_DISABLED" then
        CFA.inCombat = true
        if CFA.state == CFA.STATES.DETECTED then CFA:SetStatusText("전투 중에는 자동 앉기를 사용할 수 없습니다.") end
    elseif event == "PLAYER_REGEN_ENABLED" then
        CFA.inCombat = false
        if CFA.state == CFA.STATES.DETECTED then CFA:SetStatusText("") end
    end
end)
