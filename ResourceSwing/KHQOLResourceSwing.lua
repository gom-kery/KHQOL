local addonName, NS = ...

local ADDON = "KHQOLResourceSwing"
local defaults = {
    enabled = true, width = 320, height = 24, locked = false,
    point = "CENTER", relativePoint = "CENTER", x = 0, y = -150,
    showResourceText = true, showSwingText = false, showAmmo = true,
    autoResourceColor = true,
    resourceTextPosition = "CENTER", ammoTextPosition = "RIGHT",
    swingPosition = "INSIDE", swingHeight = 5, barTexture = "DEFAULT",
    swingVisibility = "COMBAT",
    resourceTextSize = 12, ammoTextSize = 12,
    frameStrata = "MEDIUM", resourcePriority = 2, ammoPriority = 5, swingPriority = 4,
    ammoLocked = false, ammoPoint = "CENTER", ammoRelativePoint = "CENTER", ammoX = 0, ammoY = -120,
    resourceColorOverrides = {}, resourceColorsMigrated = false,
    colors = {
        resource = { 0.15, 0.55, 1.00, 1 }, background = { 0.05, 0.05, 0.05, 0.85 },
        mainHand = { 1.00, 0.82, 0.15, 1 }, offHand = { 0.95, 0.35, 0.20, 1 }, ranged = { 0.30, 0.85, 0.35, 1 },
    },
}

local db, frame, resourceArea, resourceFill, resourceTextLayer, resourceText, ammoFrame, auxText, swingLane, swingFill, swingText, minimapButton
NS.modules.resourceSwing.defaults = defaults
local swings = { main = { active = false }, off = { active = false }, ranged = { active = false } }
local playerGUID
local lastSafePercent, powerPercentCurve
local barTextures = {
    DEFAULT = "Interface\\TargetingFrame\\UI-StatusBar",
    FLAT = "Interface\\Buttons\\WHITE8X8",
    RAID = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    SKILL = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
}

local function usableNumber(value)
    if issecretvalue and issecretvalue(value) then return false end
    return type(value) == "number" and value > 0
end

local function displayNumber(value)
    -- This Blizzard formatter is allowed to turn a Secret number into display text.
    if AbbreviateNumbers then return AbbreviateNumbers(value) end
    if issecretvalue and issecretvalue(value) then return "?" end
    return tostring(value)
end

local function characterKey()
    local name, realm = UnitFullName("player")
    name = name or UnitName("player") or "unknown"
    realm = realm or GetRealmName() or ""
    return name .. "-" .. realm
end

local function resourceColor()
    local overrides = db.resourceColorOverrides or {}
    local custom = overrides[characterKey()]
    if custom then return unpack(custom) end
    local powerType, powerToken = UnitPowerType("player")
    local color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if color then
        if color.GetRGB then local r, g, b = color:GetRGB(); return r, g, b, 1 end
        if color.r then return color.r, color.g, color.b, 1 end
    end
    return unpack(db.colors.resource)
end

local function migrateLegacyResourceColor()
    if db.autoResourceColor == false and not db.resourceColorsMigrated then
        db.resourceColorOverrides[characterKey()] = { unpack(db.colors.resource) }
        db.resourceColorsMigrated, db.autoResourceColor = true, true
    end
end

local function getPowerPercent(powerType, current, maximum)
    if not powerPercentCurve then
        powerPercentCurve = CurveConstants and CurveConstants.ScaleTo100
        if not powerPercentCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
            powerPercentCurve = C_CurveUtil.CreateCurve()
            powerPercentCurve:SetType(Enum.LuaCurveType.Linear)
            powerPercentCurve:AddPoint(0, 0); powerPercentCurve:AddPoint(1, 100)
        end
    end
    -- Forever returns 0 for the unmodified (true) variant of some primary powers.
    local ok, percent = pcall(UnitPowerPercent, "player", powerType, false, powerPercentCurve)
    if ok then return percent end
    -- Some Forever builds do not expose a usable curve result outside restrictions.
    -- In ordinary player contexts raw current/max values remain readable.
    local safe, fallback = pcall(function() return (current / maximum) * 100 end)
    return safe and fallback or nil
end

local function updateResource()
    if not frame then return end
    local powerType = UnitPowerType("player")
    local current, maximum = UnitPower("player", powerType), UnitPowerMax("player", powerType)
    -- StatusBar is a native widget and can consume Secret values without Lua arithmetic.
    resourceFill:SetMinMaxValues(0, maximum)
    resourceFill:SetValue(current)
    resourceFill:SetStatusBarColor(resourceColor())
    if db.showResourceText then
        local percent = getPowerPercent(powerType, current, maximum)
        local readable, rounded = pcall(function() return math.max(0, math.min(100, math.floor(percent + 0.5))) end)
        if readable then
            percent = rounded
            lastSafePercent = percent
            -- 40%: white, 20%: orange, 0%: red.
            if percent >= 40 then resourceText:SetTextColor(1, 1, 1)
            elseif percent >= 20 then resourceText:SetTextColor(1, 0.5 + 0.5 * ((percent - 20) / 20), 0)
            else resourceText:SetTextColor(1, 0.5 * (percent / 20), 0) end
            resourceText:SetText(percent .. "%")
        else
            resourceText:SetTextColor(1, 1, 1)
            -- Native formatting can render a Secret percentage without exposing it to Lua math.
            resourceText:SetFormattedText("%.0f%%", percent)
        end
    else
        resourceText:SetText("")
    end
end

local function ammoCount()
    if select(2, UnitClass("player")) ~= "HUNTER" or not db.showAmmo then return nil end
    local ammoSlot = GetInventorySlotInfo and GetInventorySlotInfo("AmmoSlot")
    if not ammoSlot or not GetInventoryItemTexture("player", ammoSlot) then return nil end
    local count = GetInventoryItemCount and GetInventoryItemCount("player", ammoSlot)
    return type(count) == "number" and count or nil
end

local function updateAuxText()
    local ammo = ammoCount()
    auxText:SetText(ammo and ("Ammo " .. ammo) or "")
end

local function saveAmmoPosition()
    local point, _, relativePoint, x, y = ammoFrame:GetPoint(1)
    db.ammoPoint, db.ammoRelativePoint, db.ammoX, db.ammoY = point, relativePoint, x, y
end

local function speedFor(kind)
    if kind == "ranged" then
        local speed = UnitRangedDamage("player")
        return usableNumber(speed) and speed or nil
    end
    local mainSpeed, offSpeed = UnitAttackSpeed("player")
    local speed = kind == "main" and mainSpeed or offSpeed
    return usableNumber(speed) and speed or nil
end

local function startSwing(kind, duration)
    -- PLAYER_SWING supplies an authoritative, non-secret duration on Forever.
    local speed = duration or speedFor(kind)
    if not speed then return end
    swings[kind].started, swings[kind].duration, swings[kind].active = GetTime(), speed, true
end

local function stopAllSwings()
    for _, swing in pairs(swings) do swing.active = false end
end

local function updateSwingBars()
    if not UnitAffectingCombat("player") then
        stopAllSwings(); swingFill:SetWidth(0); swingText:SetText("")
        swingLane:SetShown(db.swingVisibility == "ALWAYS")
        frame:SetScript("OnUpdate", nil); return
    end
    local now, anyActive, visibleKind, visibleProgress, visibleStarted = GetTime(), false
    for kind, swing in pairs(swings) do
        if swing.active then
            local progress = (now - swing.started) / swing.duration
            if progress >= 1 then
                swing.active = false
            else
                anyActive = true
                -- A single lane shows the most recently restarted swing.
                if not visibleStarted or swing.started > visibleStarted then
                    visibleKind, visibleProgress, visibleStarted = kind, progress, swing.started
                end
            end
        end
    end
    if visibleKind then
        local colorKey = visibleKind == "main" and "mainHand" or visibleKind == "off" and "offHand" or "ranged"
        swingFill:SetTexture(barTextures[db.barTexture] or barTextures.DEFAULT)
        swingFill:SetVertexColor(unpack(db.colors[colorKey]))
        swingFill:SetWidth(math.max(0, (db.width - 4) * visibleProgress))
        if db.showSwingText then
            local label = visibleKind == "main" and "MH" or visibleKind == "off" and "OH" or "R"
            swingText:SetText(string.format("%s %d%%", label, visibleProgress * 100))
        else
            swingText:SetText("")
        end
    else
        swingFill:SetWidth(0); swingText:SetText("")
    end
    if not anyActive then frame:SetScript("OnUpdate", nil) end
end

local function ensureUpdate()
    if not frame:GetScript("OnUpdate") then frame:SetScript("OnUpdate", updateSwingBars) end
end

local function applyLayout()
    local laneHeight = db.swingHeight
    local outside = db.swingPosition ~= "INSIDE"
    frame:SetSize(db.width, db.height + (outside and laneHeight + 2 or 0))
    frame:SetFrameStrata(db.frameStrata)
    frame:ClearAllPoints(); frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
    resourceArea:ClearAllPoints(); resourceArea:SetSize(db.width, db.height)
    resourceArea:SetFrameLevel(frame:GetFrameLevel() + db.resourcePriority)
    if db.swingPosition == "ABOVE" then resourceArea:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0) else resourceArea:SetPoint("TOP", frame, "TOP", 0, 0) end
    resourceFill:ClearAllPoints(); resourceFill:SetPoint("TOPLEFT", resourceArea, "TOPLEFT", 0, 0); resourceFill:SetPoint("TOPRIGHT", resourceArea, "TOPRIGHT", 0, 0); resourceFill:SetPoint("BOTTOMLEFT", resourceArea, "BOTTOMLEFT", 0, 0)
    resourceFill:SetStatusBarTexture(barTextures[db.barTexture] or barTextures.DEFAULT)
    swingLane:ClearAllPoints()
    if db.swingPosition == "ABOVE" then swingLane:SetPoint("BOTTOMLEFT", resourceArea, "TOPLEFT", 2, 2); swingLane:SetPoint("BOTTOMRIGHT", resourceArea, "TOPRIGHT", -2, 2)
    elseif db.swingPosition == "BELOW" then swingLane:SetPoint("TOPLEFT", resourceArea, "BOTTOMLEFT", 2, -2); swingLane:SetPoint("TOPRIGHT", resourceArea, "BOTTOMRIGHT", -2, -2)
    else swingLane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1); swingLane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1) end
    swingLane:SetHeight(laneHeight); swingLane:SetAlpha(1); swingLane:SetFrameLevel(frame:GetFrameLevel() + db.swingPriority)
    swingLane:SetBackdropColor(unpack(db.colors.background))
    swingLane:SetShown(db.swingVisibility == "ALWAYS" or UnitAffectingCombat("player"))
    resourceTextLayer:ClearAllPoints(); resourceTextLayer:SetAllPoints(resourceArea)
    resourceTextLayer:SetFrameLevel(frame:GetFrameLevel() + math.max(db.resourcePriority, db.swingPriority) + 1)
    swingFill:SetHeight(laneHeight)
    frame:SetBackdropColor(unpack(db.colors.background))
    resourceText:ClearAllPoints()
    resourceText:SetDrawLayer("OVERLAY", 7)
    resourceText:SetFont(STANDARD_TEXT_FONT, db.resourceTextSize, "OUTLINE"); auxText:SetFont(STANDARD_TEXT_FONT, db.ammoTextSize, "OUTLINE")
    local pos = { LEFT = "LEFT", CENTER = "CENTER", RIGHT = "RIGHT" }
    resourceText:SetPoint(pos[db.resourceTextPosition] or "CENTER", resourceFill, pos[db.resourceTextPosition] or "CENTER", db.resourceTextPosition == "LEFT" and 5 or db.resourceTextPosition == "RIGHT" and -5 or 0, 0)
    ammoFrame:ClearAllPoints(); ammoFrame:SetPoint(db.ammoPoint, UIParent, db.ammoRelativePoint, db.ammoX, db.ammoY)
    ammoFrame:EnableMouse(not db.ammoLocked); ammoFrame:SetBackdropColor(0, 0, 0, db.ammoLocked and 0 or 0.35)
    frame:SetShown(db.enabled)
    updateResource(); updateAuxText(); updateSwingBars()
end

local function savePosition()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y
end

local function createUI()
    frame = CreateFrame("Frame", ADDON .. "Frame", UIParent, "BackdropTemplate")
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not db.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); savePosition() end)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    frame:SetBackdropColor(unpack(db.colors.background))

    resourceArea = CreateFrame("Frame", nil, frame)
    resourceFill = CreateFrame("StatusBar", nil, resourceArea)
    resourceFill:SetStatusBarTexture(barTextures.DEFAULT)
    resourceTextLayer = CreateFrame("Frame", nil, frame)
    resourceText = resourceTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ammoFrame = CreateFrame("Frame", ADDON .. "AmmoAnchor", UIParent, "BackdropTemplate")
    ammoFrame:SetSize(140, 20); ammoFrame:SetMovable(true); ammoFrame:SetClampedToScreen(true); ammoFrame:RegisterForDrag("LeftButton")
    ammoFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    ammoFrame:SetScript("OnDragStart", function(self) if not db.ammoLocked then self:StartMoving() end end)
    ammoFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); saveAmmoPosition() end)
    auxText = ammoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); auxText:SetPoint("CENTER")
    swingLane = CreateFrame("Frame", nil, frame, "BackdropTemplate"); swingLane:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); swingLane:SetBackdropColor(0, 0, 0, 0.55)
    swingFill = swingLane:CreateTexture(nil, "ARTWORK"); swingFill:SetPoint("LEFT", swingLane, "LEFT", 0, 0); swingFill:SetTexture(barTextures.DEFAULT)
    swingText = swingLane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); swingText:SetPoint("CENTER", swingLane, "CENTER", 0, 0)
    applyLayout()
end

local function refreshColors()
    frame:SetBackdropColor(unpack(db.colors.background))
    updateResource()
end

local function playerSwingEvent(duration, swingType)
    if not Enum or not Enum.PlayerSwingType then return end
    local kind
    if swingType == Enum.PlayerSwingType.MainHand then kind = "main"
    elseif swingType == Enum.PlayerSwingType.OffHand then kind = "off"
    elseif swingType == Enum.PlayerSwingType.Ranged then kind = "ranged" end
    if kind and UnitAffectingCombat("player") then startSwing(kind, duration); ensureUpdate() end
end

-- Build the existing controls directly in the cached Bars Settings tab.
-- Keep local runtime/database references and all original setters intact.
function NS.modules.resourceSwing:BuildSettings(content,y)
    local UI = NS.UI
    local b = UI:CreateBuilder(content,y)
    local function moduleEnabled() return NS:GetEnabled("resourceSwing") end
    local function available(condition)
        return function() return moduleEnabled() and (not condition or condition()) end
    end
    b:Section("리소스/스윙")
    b:Checkbox("리소스/스윙 사용",moduleEnabled,function(v) NS:SetEnabled("resourceSwing",v); UI:Refresh(content) end)
    local function check(title, key, enabled)
        b:Checkbox(title, function() return db[key] end, function(v) db[key]=v; applyLayout() end, available(enabled))
    end
    local function adjust(title, key, min, max, step, enabled)
        b:Slider(title, min, max, step, function() return db[key] end, function(v) db[key]=v; applyLayout() end, tostring, available(enabled))
    end
    local function dropdown(title, key, order, labels, enabled)
        local items={}
        for _, value in ipairs(order) do items[#items+1]={value=value,text=labels[value]} end
        b:Dropdown(title, items, function() return db[key] end, function(v) db[key]=v; applyLayout() end, available(enabled))
    end
    local function color(title, key)
        b:Color(title, function()
            if key=="resource" then return resourceColor() end
            return unpack(db.colors[key])
        end, function(r,g,bl,a)
            db.colors[key]={r,g,bl,a}
            if key=="resource" then db.resourceColorOverrides[characterKey()]={r,g,bl,a} end
            applyLayout()
        end, moduleEnabled, function()
            local old={unpack(db.colors[key])}
            local previous=db.resourceColorOverrides[characterKey()]
            local custom=previous and {unpack(previous)} or nil
            return function()
                db.colors[key]=old
                if key=="resource" then db.resourceColorOverrides[characterKey()]=custom end
                applyLayout()
            end
        end, true)
    end
    b:Section("위치")
    check("위치 잠금", "locked")
    adjust("X 위치", "x", -3000, 3000, 1)
    adjust("Y 위치", "y", -3000, 3000, 1)
    b:Button("위치 초기화", function() db.point,db.relativePoint,db.x,db.y="CENTER","CENTER",0,-150; applyLayout() end,nil,moduleEnabled)
    b:Section("탄약 위치 / 모양")
    check("사냥꾼 탄약 표시", "showAmmo")
    check("탄약 위치 잠금", "ammoLocked", function() return db.showAmmo end)
    b:Button("탄약 위치 초기화", function() db.ammoPoint,db.ammoRelativePoint,db.ammoX,db.ammoY="CENTER","CENTER",0,-120; applyLayout() end,180,available(function() return db.showAmmo end))
    adjust("글자 크기", "ammoTextSize", 8, 24, 1, function() return db.showAmmo end)
    b:Section("크기")
    adjust("폭", "width", 200, 600, 10)
    adjust("높이", "height", 10, 50, 1)
    adjust("스윙 바 높이", "swingHeight", 3, 20, 1)
    b:Section("모양 / 색상")
    dropdown("바 텍스처", "barTexture", {"DEFAULT","FLAT","RAID","SKILL"}, {DEFAULT="기본",FLAT="단색",RAID="공격대",SKILL="기술"})
    color("자원 색상", "resource"); color("배경 색상", "background")
    color("주무기 색상", "mainHand"); color("보조무기 색상", "offHand"); color("원거리 색상", "ranged")
    b:Button("자원 기본 색상 복원", function() db.resourceColorOverrides[characterKey()]=nil; updateResource() end,210,moduleEnabled)
    b:Section("자원 텍스트")
    check("자원 수치 표시", "showResourceText")
    local function resourceTextEnabled() return db.showResourceText end
    adjust("글자 크기", "resourceTextSize", 8, 24, 1, resourceTextEnabled)
    dropdown("표시 위치", "resourceTextPosition", {"LEFT","CENTER","RIGHT"}, {LEFT="왼쪽",CENTER="가운데",RIGHT="오른쪽"}, resourceTextEnabled)
    b:Section("스윙")
    check("스윙 텍스트 표시", "showSwingText")
    dropdown("스윙 바 위치", "swingPosition", {"ABOVE","BELOW","INSIDE"}, {ABOVE="자원바 위",BELOW="자원바 아래",INSIDE="자원바 내부"})
    dropdown("스윙 바 표시", "swingVisibility", {"COMBAT","ALWAYS"}, {COMBAT="전투 중만",ALWAYS="항상 표시"})
    b:Section("고급 / 표시 레이어")
    dropdown("전체 표시 레이어", "frameStrata", {"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG"}, {BACKGROUND="배경",LOW="낮음",MEDIUM="보통",HIGH="높음",DIALOG="대화창 위"})
    adjust("자원 바 내부 레이어", "resourcePriority", 1, 7, 1)
    adjust("스윙 바 내부 레이어", "swingPriority", 1, 7, 1)
    b:Section("기본값 복원")
    b:Button("리소스/스윙 설정 초기화",function() StaticPopup_Show("KHQOL_RESET_MODULE","리소스/스윙",nil,"resourceSwing") end)
    return b.y
end

local function createMinimapButton()
    minimapButton = CreateFrame("Button", ADDON .. "MinimapButton", Minimap)
    minimapButton:SetSize(28, 28); minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3, -3)
    minimapButton:SetFrameStrata("MEDIUM"); minimapButton:RegisterForClicks("LeftButtonUp")
    local background = minimapButton:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\MiniMap-TrackingBackground"); background:SetAllPoints(minimapButton)
    local label = minimapButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE"); label:SetPoint("CENTER", 0, 0); label:SetText("RS"); label:SetTextColor(1, 0.82, 0)
    minimapButton:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then NS:ShowSettings("resourceSwing") end
    end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("KHQOL 자원 / 스윙 바"); GameTooltip:AddLine("좌클릭: 설정창 열기", 1, 1, 1); GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Reapply existing frames after an in-place profile update; the local db and
-- settings callbacks deliberately retain their original table identities.
function NS.modules.resourceSwing:ApplyPosition() applyLayout() end
function NS.modules.resourceSwing:ApplyProfile()
    if not frame then return end
    migrateLegacyResourceColor(); applyLayout(); updateResource(); updateAuxText(); updateSwingBars()
end
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, eventArg, ...)
    if event == "ADDON_LOADED" then
        -- This source is now loaded by the unified KHQOL TOC, while its frame
        -- names intentionally retain the legacy prefix for saved-layout compatibility.
        if eventArg ~= addonName then return end
        if NS.InitializeProfiles then NS:InitializeProfiles() end
        KHQOLResourceSwingDB = KHQOLResourceSwingDB or {}; NS.MergeDefaults(KHQOLResourceSwingDB, defaults, "tables"); db = KHQOLResourceSwingDB
        -- 0.0.4 used this key for weapon selection; 0.0.5 uses it for frame layering.
        if type(db.swingPriority) ~= "number" then db.swingPriority = defaults.swingPriority end
        createUI(); createMinimapButton()
        self:RegisterEvent("PLAYER_LOGIN"); self:RegisterEvent("UNIT_POWER_UPDATE"); self:RegisterEvent("UNIT_MAXPOWER"); self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED"); self:RegisterEvent("UNIT_INVENTORY_CHANGED"); self:RegisterEvent("PLAYER_REGEN_DISABLED"); self:RegisterEvent("PLAYER_REGEN_ENABLED"); self:RegisterEvent("BAG_UPDATE_DELAYED")
        self:RegisterEvent("PLAYER_SWING"); self:RegisterEvent("WEAPON_SLOT_CHANGED")
    elseif event == "PLAYER_LOGIN" then playerGUID = UnitGUID("player"); migrateLegacyResourceColor(); updateResource(); updateAuxText()
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then if eventArg == "player" then updateResource() end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then updateAuxText()
    elseif event == "BAG_UPDATE_DELAYED" then updateAuxText()
    elseif event == "PLAYER_REGEN_DISABLED" then swingLane:SetShown(true)
    elseif event == "PLAYER_REGEN_ENABLED" then stopAllSwings(); swingFill:SetWidth(0); swingText:SetText(""); swingLane:SetShown(db.swingVisibility == "ALWAYS"); updateSwingBars()
    elseif event == "PLAYER_SWING" then playerSwingEvent(eventArg, select(1, ...))
    elseif event == "WEAPON_SLOT_CHANGED" then updateAuxText()
    end
end)

SLASH_KHQOLRESOURCESWING1 = "/krsb"
function NS.modules.resourceSwing:SetEnabled(enabled)
    if not frame then return end
    db.enabled=enabled and true or false
    eventFrame:UnregisterAllEvents()
    if enabled then
        for _,event in ipairs({"PLAYER_LOGIN","UNIT_POWER_UPDATE","UNIT_MAXPOWER","PLAYER_EQUIPMENT_CHANGED",
            "UNIT_INVENTORY_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","BAG_UPDATE_DELAYED",
            "PLAYER_SWING","WEAPON_SLOT_CHANGED"}) do eventFrame:RegisterEvent(event) end
        playerGUID=UnitGUID("player"); applyLayout()
    else
        stopAllSwings(); frame:SetScript("OnUpdate",nil)
    end
    frame:SetShown(enabled); ammoFrame:SetShown(enabled and db.showAmmo)
end
SlashCmdList.KHQOLRESOURCESWING = function()
    local settings=NS.settings
    if settings and settings:IsShown() and settings.page=="bars" and NS.BarsSettings.selected=="resource" then
        settings:Hide()
    else NS:ShowSettings("resourceSwing") end
end
