local _, KHQOL = ...
local CFA = KHQOL.modules.campfire

local function SetFont(fontString, size, r, g, b)
    fontString:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "THICKOUTLINE")
    fontString:SetTextColor(r, g, b)
    fontString:SetJustifyH("CENTER")
end

function CFA:CreateUI()
    if self.ui then return end
    local db = self.db
    db.iconSize = math.max(100, math.min(140, tonumber(db.iconSize) or 100))
    db.fontSize = math.max(40, math.min(70, tonumber(db.fontSize) or 50))
    local root = CreateFrame("Frame", nil, UIParent)
    root:SetPoint(db.position.point, UIParent, db.position.point, db.position.x, db.position.y)
    root:SetSize(360, 260)
    root:SetFrameStrata("HIGH")
    root:SetMovable(true)
    root:SetClampedToScreen(true)
    -- A transparent parent must never intercept world mouse drags/camera turns.
    root:EnableMouse(false)

    local discovery = CreateFrame("Frame", nil, root)
    discovery:SetAllPoints(root)
    discovery:Hide()

    -- Forever Beta does not execute this addon's secure macro reliably. A normal
    -- button is intentional: Core.lua runs DoEmote only from a physical click,
    -- and this lets the alert safely hide while the player is in combat.
    local button = CreateFrame("Button", nil, discovery)
    button:SetSize(db.iconSize, db.iconSize)
    button:SetPoint("TOP", discovery, "TOP", 0, 0)
    button:RegisterForClicks("LeftButtonUp")
    button:SetNormalTexture(CFA.ICON_FILE_ID)
    local normal = button:GetNormalTexture()
    if normal then
        normal:SetTexCoord(0, 1, 0, 1)
    elseif GetSpellTexture then
        button:SetNormalTexture(GetSpellTexture(CFA.SPELLS.NEARBY_CAMPFIRE))
    end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then CFA:OnCampfireClick() end
    end)

    local close = CreateFrame("Button", nil, discovery)
    close:SetSize(26, 26)
    close:SetPoint("TOPRIGHT", button, "TOPRIGHT", 13, 13)
    close:SetFrameLevel(button:GetFrameLevel() + 5)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetAllPoints(close)
    SetFont(closeText, 26, 1, 0.85, 0.85)
    closeText:SetText("×")
    close:SetScript("OnClick", function() CFA:DismissDiscovery() end)
    close:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("알림 닫기")
        GameTooltip:AddLine("범위를 벗어날 때까지 다시 표시하지 않습니다.", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local function StartMove()
        if db.locked then return end
        if CFA.inCombat or (InCombatLockdown and InCombatLockdown()) then
            CFA:Print("전투 중에는 위치를 이동할 수 없습니다.")
            return
        end
        root:StartMoving()
        root.cfaMoving = true
    end
    local function StopMove()
        if not root.cfaMoving then return end
        root.cfaMoving = nil
        root:StopMovingOrSizing()
        local point, _, _, x, y = root:GetPoint(1)
        CFA.db.position.point = point or "CENTER"
        CFA.db.position.x = x or 0
        CFA.db.position.y = y or 80
        -- The root is always anchored to UIParent; retain a valid saved anchor.
        root:ClearAllPoints()
        root:SetPoint(CFA.db.position.point, UIParent, CFA.db.position.point, CFA.db.position.x, CFA.db.position.y)
    end
    -- Positioning is attached to the visible icon only, so transparent space
    -- and the message area continue passing drags through to the game camera.
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", StartMove)
    button:SetScript("OnDragStop", StopMove)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("모닥불에 앉기")
        GameTooltip:AddLine("클릭하여 /sit 실행", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local title = discovery:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", button, "BOTTOM", 0, -12)
    title:SetWidth(360)
    SetFont(title, db.fontSize, 1, 0, 0)
    title:SetText(db.message or "모닥불 발견!")

    local distance = discovery:CreateFontString(nil, "OVERLAY")
    distance:SetPoint("TOP", title, "BOTTOM", 0, -7)
    distance:SetWidth(360)
    SetFont(distance, 24, 0.35, 0.85, 1)
    distance:Hide()

    local status = discovery:CreateFontString(nil, "OVERLAY")
    status:SetPoint("TOP", distance, "BOTTOM", 0, -5)
    status:SetWidth(360)
    SetFont(status, 22, 1, 0.82, 0.25)
    status:Hide()

    local progress = CreateFrame("StatusBar", nil, discovery)
    progress:SetSize(300, 20)
    progress:SetPoint("TOP", status, "BOTTOM", 0, -15)
    progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progress:SetStatusBarColor(1, 0.52, 0.05)
    progress:SetMinMaxValues(0, 1)
    progress:SetValue(1)
    local bg = progress:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(progress)
    bg:SetColorTexture(0.15, 0.06, 0.01, 0.85)
    progress.text = progress:CreateFontString(nil, "OVERLAY")
    progress.text:SetAllPoints(progress)
    SetFont(progress.text, 16, 1, 0.95, 0.7)
    progress:Hide()

    local complete = root:CreateFontString(nil, "OVERLAY")
    complete:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    SetFont(complete, 46, 0.15, 1, 0.25)
    complete:SetText("야영 효과를 받았습니다!")
    complete:Hide()

    self.ui = { root = root, discovery = discovery, button = button, title = title, distance = distance, status = status, progress = progress, complete = complete }

    button:EnableMouseWheel(false)
    button:SetScript("OnMouseWheel", nil)
end

function CFA:ApplyLayout()
    if not self.ui then return end
    local db, ui = self.db, self.ui
    ui.button:SetSize(db.iconSize, db.iconSize)
    SetFont(ui.title, db.fontSize, 1, 0, 0)
    ui.title:SetText(db.message or "모닥불 발견!")
end
