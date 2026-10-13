local _, KHQOL = ...
local CFA = KHQOL.modules.campfire

local function Remaining(aura)
    local duration, expiration = tonumber(aura.duration) or 0, tonumber(aura.expirationTime) or 0
    if duration <= 0 or expiration <= 0 then return "permanent", "n/a" end
    return string.format("%.1f", duration), string.format("%.1f", math.max(0, expiration - GetTime()))
end

function CFA:DumpAuras()
    local auras = self:GetAllPlayerBuffs()
    self:Print("읽을 수 있는 BUFF " .. #auras .. "개:")
    for _, aura in ipairs(auras) do
        local duration, remaining = Remaining(aura)
        self:Print(string.format("ID: %s | Name: %s | Duration: %s | Remaining: %s", tostring(aura.spellId or "?"), tostring(aura.name or "?"), duration, remaining))
    end
end

function CFA:PrintStatus()
    local nearby = self:HasPlayerAura(self.SPELLS.NEARBY_CAMPFIRE)
    local resting = self:HasPlayerAura(self.SPELLS.REST_PROCESS)
    local benefit = self:HasAnyCampBenefit()
    self:Print("Status")
    self:Print("Nearby Campfire: " .. (nearby and "YES" or "NO") .. " | Spell: " .. self.SPELLS.NEARBY_CAMPFIRE)
    self:Print("Resting: " .. (resting and "YES" or "NO") .. " | Spell: " .. self.SPELLS.REST_PROCESS)
    self:Print("Camp Benefits: " .. (benefit and "YES" or "NO") .. " | Spell: " .. tostring(benefit and benefit.spellId or self.SPELLS.CAMP_BENEFITS[1]))
    self:UpdateCampfireDistance()
    self:Print("Campfire distance: " .. (self.nearestCampfireDistance and string.format("%.1f yd", self.nearestCampfireDistance) or "unavailable"))
    local remaining = self.timer and math.max(0, self.timer.expiration - GetTime()) or nil
    self:Print("Timer: " .. (remaining and string.format("%.1f sec", remaining) or "inactive") .. " | State: " .. self.state)
end

function CFA:RunTest(argument)
    argument = (argument or "detect"):lower()
    if argument == "detect" then
        self:HideDiscovery()
        self:SetState(self.STATES.DETECTED)
        self:ShowDiscovery()
        self:SetStatusText("테스트: 감지 UI")
        self:Print("테스트 감지 UI를 표시했습니다.")
    elseif argument == "timer" then
        self:HideDiscovery()
        self:SetState(self.STATES.DETECTED)
        self:ShowDiscovery()
        self:StartWaiting(nil)
        self:Print("테스트 60초 타이머를 시작했습니다. 실제 성공 판정에는 영향을 주지 않습니다.")
    elseif argument == "complete" then
        self:HideDiscovery()
        self:ShowComplete()
        self:Print("테스트 완료 메시지를 표시했습니다.")
    else
        self:Print("사용법: /cfa test detect | timer | complete")
    end
end

local function HandleSlash(message)
    local command, argument = message:match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()
    if command == "debug" then
        CFA.db.debug = not CFA.db.debug
        CFA:Print("Debug " .. (CFA.db.debug and "ON" or "OFF"))
    elseif command == "auras" then
        CFA:DumpAuras()
    elseif command == "status" then
        CFA:PrintStatus()
    elseif command == "distance" then
        CFA:DiagnoseCampfireDistance()
    elseif command == "test" then
        CFA:RunTest(argument)
    else
        CFA:Print("명령: /cfa debug | auras | status | distance | test detect|timer|complete")
    end
end

SLASH_CAMPFIREALERT1 = "/cfa"
SLASH_CAMPFIREALERT2 = "/campfirealert"
SlashCmdList.CAMPFIREALERT = HandleSlash
