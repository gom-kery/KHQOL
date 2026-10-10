local addonName, NS = ...

local ADDON = "KHQOLResourceSwing"
local defaults = {
    enabled = true, width = 320, height = 24, locked = false,
    point = "CENTER", relativePoint = "CENTER", x = 0, y = -150,
    showResourceText = true, showSwingText = false, showAmmo = true,
    autoResourceColor = true,
    showCombo = true, comboShape = "BAR", comboPosition = "ABOVE",
    comboWidth = 240, comboHeight = 10, comboOrbSize = 18, comboGap = 4,
    comboActiveColor = {1,.78,.16,1}, comboInactiveColor = {.18,.18,.18,.85},
    comboLocked = true, comboPoint = "CENTER", comboRelativePoint = "CENTER", comboX = 0, comboY = -100,
    showSoulShards = true,
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

-- New auxiliary data never enters comparisons/arithmetic before public checks.
local RS=NS.modules.resourceSwing
local comboFrame,auxIcon
local function read(fn,...) return NS.PublicCall(fn,...) end
local function field(info,key)
    if not NS.IsPublicValue(info) or type(info)~="table" then return end
    local ok,value=pcall(function() return info[key] end)
    if ok and NS.IsPublicValue(value) then return value end
end
local function integer(v,min,max)
    return NS.IsPublicValue(v) and type(v)=="number" and v==v and v>=min and v<=max and v==math.floor(v)
end
local function bagTotal(itemID)
    local container=C_Container
    local slots=(container and container.GetContainerNumSlots) or GetContainerNumSlots
    local idFn=(container and container.GetContainerItemID) or GetContainerItemID
    local infoFn=(container and container.GetContainerItemInfo) or GetContainerItemInfo
    if type(slots)~="function" or type(idFn)~="function" or type(infoFn)~="function" then return end
    local last=NUM_BAG_SLOTS
    if not integer(last,1,20) then return end
    local reagent=Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
    if integer(reagent,0,20) then last=math.max(last,reagent) end
    local total=0
    for bag=0,last do
        local count=read(slots,bag)
        if not integer(count,0,1000) then return end
        for slot=1,count do
            local status,id=NS.ReadPublicAPI(idFn,bag,slot)
            if status~="ok" then return end
            if id~=nil and not integer(id,1,2147483647) then return end
            if id==itemID then
                local quantity
                if container and container.GetContainerItemInfo then
                    quantity=field(read(infoFn,bag,slot),"stackCount")
                else
                    local _,n=read(infoFn,bag,slot);quantity=n
                end
                if not integer(quantity,0,1000000) then return end
                total=total+quantity
            end
        end
    end
    return total
end
function RS:GetCarriedItemCount(itemID)
    if not integer(itemID,1,2147483647) then return end
    local fn=(C_Item and C_Item.GetItemCount) or GetItemCount
    if type(fn)=="function" then
        -- Inventory only: no character/reagent/account bank, no charge counts.
        local n=read(fn,itemID,false,false,false,false)
        if integer(n,0,100000000) then return n end
        return nil
    end
    return bagTotal(itemID)
end
function RS:GetAuxData()
    if not db or not db.enabled then return nil,nil,nil,"MODULE_OFF" end
    local _,class=read(UnitClass,"player")
    if class=="WARLOCK" then
        if not db.showSoulShards then return nil,nil,nil,"DISABLED" end
        -- Candidate Classic item ID is accepted only after client metadata matches.
        -- A soulstone item/buff or Retail power value is never used as a substitute.
        local fn=(C_Item and C_Item.GetItemInfo) or GetItemInfo
        local name,_,_,_,_,_,_,_,_,icon=read(fn,6265)
        if name~="Soul Shard" and name~="영혼의 조각" and not (type(SOUL_SHARD)=="string" and name==SOUL_SHARD) then
            if C_Item and C_Item.RequestLoadItemDataByID and not RS.shardDataRequested then
                RS.shardDataRequested=true;pcall(C_Item.RequestLoadItemDataByID,6265)
            end
            return nil,nil,nil,"SHARD_ITEM_UNCONFIRMED"
        end
        local n=self:GetCarriedItemCount(6265)
        if n==nil or not icon then return nil,nil,nil,"ITEM_COUNT_UNREADABLE" end
        return "영혼의 조각",n,icon
    end
    if not db.showAmmo then return nil,nil,nil,"DISABLED" end
    local uses=read(UnitUsesAmmo,"player")
    local needed=read(C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded)
    if uses==false or needed==false then return nil,nil,nil,"NO_AMMO_REQUIRED" end
    if C_PaperDollInfo and type(C_PaperDollInfo.AmmoNeeded)=="function" and needed~=true then
        return nil,nil,nil,"AMMO_USAGE_UNCONFIRMED"
    end
    -- Older builds may lack UnitUsesAmmo. Only the existing Hunter fallback is kept.
    if uses~=true and not (type(UnitUsesAmmo)~="function" and class=="HUNTER") then return nil,nil,nil,"AMMO_USAGE_UNCONFIRMED" end
    local slotInfo=(C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo) or GetInventorySlotInfo
    local ammoSlot=read(slotInfo,"AmmoSlot")
    local rangedSlot=read(slotInfo,"RangedSlot")
    if not integer(ammoSlot,0,100) or not integer(rangedSlot,1,100) then return nil,nil,nil,"SLOTS_UNAVAILABLE" end
    local ranged=read(GetInventoryItemID,"player",rangedSlot)
    if not integer(ranged,1,2147483647) then return nil,nil,nil,"NO_RANGED_WEAPON" end
    local instant=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _,_,_,loc=read(instant,ranged)
    if loc=="INVTYPE_THROWN" then return nil,nil,nil,"THROWN_CONSUMPTION_UNCONFIRMED" end
    if loc~="INVTYPE_RANGED" and loc~="INVTYPE_RANGEDRIGHT" then return nil,nil,nil,"RANGED_WEAPON_UNCONFIRMED" end
    local id=read(GetInventoryItemID,"player",ammoSlot)
    if not integer(id,1,2147483647) then return nil,nil,nil,"NO_AMMO_ITEM" end
    local icon=read(GetInventoryItemTexture,"player",ammoSlot)
    local n=self:GetCarriedItemCount(id)
    if n==nil or not icon then return nil,nil,nil,"ITEM_COUNT_UNREADABLE" end
    return "Ammo",n,icon
end
function RS:CanShowAux()
    local _,class=read(UnitClass,"player")
    return db and db.enabled and ((class=="WARLOCK" and db.showSoulShards)
      or (class~="WARLOCK" and db.showAmmo and (class=="HUNTER" or read(UnitUsesAmmo,"player")==true))) or false
end
local function updateAuxText()
    if not ammoFrame then return end
    local label,count,icon,reason=RS:GetAuxData()
    RS.auxStatus=reason;RS.auxCount=count
    auxText:SetText(label and (label.." "..count) or "")
    if label then
        local width=auxText:GetStringWidth()
        if NS.IsPublicValue(width) and type(width)=="number" then ammoFrame:SetWidth(math.max(180,width+26)) end
    end
    auxIcon:SetTexture(icon);auxIcon:SetShown(label~=nil)
    ammoFrame:SetShown(label~=nil)
end
function RS:IsComboClass()
    local _,class=read(UnitClass,"player")
    return class=="ROGUE" or class=="DRUID"
end
function RS:GetComboData()
    if not db or not db.enabled or not db.showCombo then return nil,nil,"DISABLED" end
    local _,class=read(UnitClass,"player")
    if class=="DRUID" then
        local form=read(GetShapeshiftFormID)
        local cat=DRUID_CAT_FORM or CAT_FORM
        if not integer(cat,1,100) or form~=cat then return nil,nil,"NOT_CAT_FORM" end
    elseif class~="ROGUE" then return nil,nil,"NOT_COMBO_CLASS" end
    if read(UnitExists,"target")~=true then return nil,nil,"NO_TARGET" end
    local power=Enum and Enum.PowerType and Enum.PowerType.ComboPoints
    if not integer(power,0,100) then return nil,nil,"COMBO_POWER_UNAVAILABLE" end
    -- Camelot ComboFrame uses the target-dependent API, not primary UnitPower.
    local status,current=NS.ReadPublicAPI(GetComboPoints,"player","target")
    local maxStatus,maximum=NS.ReadPublicAPI(UnitPowerMax,"player",power)
    if status~="ok" or maxStatus~="ok" or not integer(maximum,1,32) or not integer(current,0,maximum) then
        return nil,nil,"COMBO_UNREADABLE"
    end
    return current,maximum
end
local function layoutCombo(maximum)
    if not comboFrame then return end
    local circle=db.comboShape=="ORB"
    local height=circle and db.comboOrbSize or db.comboHeight
    local width=circle and (maximum*height+(maximum-1)*db.comboGap) or db.comboWidth
    local cellWidth=(width-(maximum-1)*db.comboGap)/maximum
    if cellWidth<1 then return false end
    comboFrame:SetSize(width,height)
    if comboFrame.dragging and (db.comboPosition~="FREE" or db.comboLocked) then
        comboFrame.dragging=false;comboFrame:StopMovingOrSizing()
    end
    if not comboFrame.dragging then
        comboFrame:ClearAllPoints()
        if db.comboPosition=="FREE" then
            comboFrame:SetPoint(db.comboPoint,UIParent,db.comboRelativePoint,db.comboX,db.comboY)
        else
            local gap=4+(db.swingPosition==db.comboPosition and db.swingHeight+2 or 0)
            if db.comboPosition=="ABOVE" then comboFrame:SetPoint("BOTTOM",resourceArea,"TOP",0,gap)
            else comboFrame:SetPoint("TOP",resourceArea,"BOTTOM",0,-gap) end
        end
    end
    comboFrame:SetFrameStrata(db.frameStrata)
    comboFrame:SetFrameLevel(frame:GetFrameLevel()+math.max(db.resourcePriority,db.swingPriority)+2)
    comboFrame:EnableMouse(db.comboPosition=="FREE" and not db.comboLocked)
    for i=1,maximum do
        local cell=comboFrame.cells[i]
        if not cell then
            cell=comboFrame:CreateTexture(nil,"ARTWORK");comboFrame.cells[i]=cell
            if comboFrame.CreateMaskTexture and cell.AddMaskTexture then
                cell.mask=comboFrame:CreateMaskTexture(nil,"ARTWORK")
                cell.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
                cell.mask:SetAllPoints(cell)
            end
        end
        cell:ClearAllPoints();cell:SetPoint("LEFT",comboFrame,"LEFT",(i-1)*(cellWidth+db.comboGap),0);cell:SetSize(cellWidth,height)
        if circle and not cell.mask then return false end
        if cell.mask then
            if circle and not cell.masked then cell:AddMaskTexture(cell.mask);cell.masked=true
            elseif not circle and cell.masked then cell:RemoveMaskTexture(cell.mask);cell.masked=false end
        end
        cell:Show()
    end
    for i=maximum+1,#comboFrame.cells do comboFrame.cells[i]:Hide() end
    return true
end
local function updateCombo()
    if not comboFrame then return end
    local current,maximum,reason=RS:GetComboData()
    RS.comboStatus=reason;RS.comboCurrent=current;RS.comboMaximum=maximum
    if not maximum or not layoutCombo(maximum) then
        if maximum then RS.comboStatus="COMBO_LAYOUT_UNAVAILABLE" end
        comboFrame.dragging=false;comboFrame:StopMovingOrSizing();comboFrame:EnableMouse(false);comboFrame:Hide();return
    end
    for i=1,maximum do comboFrame.cells[i]:SetColorTexture(unpack(i<=current and db.comboActiveColor or db.comboInactiveColor)) end
    comboFrame:Show()
end
local function createCombo()
    comboFrame=CreateFrame("Frame",ADDON.."ComboAnchor",UIParent)
    comboFrame:SetMovable(true);comboFrame:SetClampedToScreen(true);comboFrame:RegisterForDrag("LeftButton")
    comboFrame.cells={};RS.comboFrame=comboFrame
    comboFrame:SetScript("OnDragStart",function(self) if db.comboPosition=="FREE" and not db.comboLocked then self.dragging=true;self:StartMoving() end end)
    comboFrame:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing();local dragging=self.dragging;self.dragging=false
        if not dragging or db.comboPosition~="FREE" then return end
        local point,_,relativePoint,x,y=self:GetPoint(1)
        db.comboPoint,db.comboRelativePoint,db.comboX,db.comboY=point,relativePoint,x,y
        if NS.SaveCurrentProfile then NS:SaveCurrentProfile() end
    end)
    comboFrame:Hide()
end
function RS:RefreshExtraDisplays() updateAuxText();updateCombo() end


local function saveAmmoPosition()
    local point, _, relativePoint, x, y = ammoFrame:GetPoint(1)
    db.ammoPoint, db.ammoRelativePoint, db.ammoX, db.ammoY = point, relativePoint, x, y
    if NS.SaveCurrentProfile then NS:SaveCurrentProfile() end
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
    updateResource(); updateAuxText(); updateCombo(); updateSwingBars()
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
    auxIcon = ammoFrame:CreateTexture(nil,"ARTWORK")
    auxIcon:SetSize(18,18); auxIcon:SetPoint("LEFT",ammoFrame,"LEFT",2,0)
    auxText:ClearAllPoints();auxText:SetPoint("LEFT",auxIcon,"RIGHT",4,0)
    ammoFrame:SetSize(180,22)
    createCombo(); applyLayout()
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
    b:Section("탄약 / 영혼의 조각 위치")
    check("탄약 표시", "showAmmo")
    check("흑마법사 영혼의 조각 표시", "showSoulShards")
    b:Description("장착 무기와 탄약 사용 조건을 확인합니다. 소지 수량만 표시하며 은행은 제외합니다. 투척 소비 규칙이나 아이템 정보를 확인하지 못하면 숨깁니다.")
    check("보조 표시 위치 잠금", "ammoLocked", function() return RS:CanShowAux() end)
    b:Button("보조 표시 위치 초기화", function() db.ammoPoint,db.ammoRelativePoint,db.ammoX,db.ammoY="CENTER","CENTER",0,-120; applyLayout() end,180,available(function() return RS:CanShowAux() end))
    adjust("글자 크기", "ammoTextSize", 8, 24, 1, function() return RS:CanShowAux() end)
    b:Section("콤보 포인트")
    check("콤보 포인트 표시", "showCombo", function() return RS:IsComboClass() end)
    local function comboEnabled() return db.showCombo and RS:IsComboClass() end
    dropdown("표시 형태", "comboShape", {"BAR","ORB"}, {BAR="분할 바",ORB="원형 구슬"},comboEnabled)
    dropdown("배치", "comboPosition", {"ABOVE","BELOW","FREE"}, {ABOVE="자원바 외부 위",BELOW="자원바 외부 아래",FREE="자유 배치"},comboEnabled)
    adjust("분할 바 폭", "comboWidth", 100,600,5,function() return comboEnabled() and db.comboShape=="BAR" end)
    adjust("분할 바 높이", "comboHeight", 4,30,1,function() return comboEnabled() and db.comboShape=="BAR" end)
    adjust("구슬 크기", "comboOrbSize", 8,40,1,function() return comboEnabled() and db.comboShape=="ORB" end)
    adjust("포인트 간격", "comboGap", 0,12,1,comboEnabled)
    for _,entry in ipairs({{"comboActiveColor","활성 색상"},{"comboInactiveColor","비활성 색상"}}) do
        local key,title=entry[1],entry[2]
        b:Color(title,function() return unpack(db[key]) end,function(r,g,bl,a) db[key]={r,g,bl,a};updateCombo() end,available(comboEnabled),nil,true)
    end
    local function freeCombo() return comboEnabled() and db.comboPosition=="FREE" end
    check("콤보 자유 배치 잠금", "comboLocked",freeCombo)
    adjust("콤보 X 위치", "comboX", -3000,3000,1,freeCombo)
    adjust("콤보 Y 위치", "comboY", -3000,3000,1,freeCombo)
    b:Description("도적과 표범 드루이드에 표시합니다. 현재 값·최대값을 읽을 수 없으면 숨깁니다. 자유 배치만 전체 위치 편집에서 독립 이동합니다.")
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
    NS.MergeDefaults(db,defaults,"tables"); migrateLegacyResourceColor(); applyLayout(); updateResource(); updateAuxText(); updateCombo(); updateSwingBars()
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
        for _,event in ipairs({"UNIT_POWER_FREQUENT","PLAYER_TARGET_CHANGED","UPDATE_SHAPESHIFT_FORM","PLAYER_ENTERING_WORLD","GET_ITEM_INFO_RECEIVED"}) do self:RegisterEvent(event) end
    elseif event == "PLAYER_LOGIN" then playerGUID = UnitGUID("player"); migrateLegacyResourceColor(); updateResource(); updateAuxText(); updateCombo()
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then if eventArg == "player" then updateResource();updateCombo() end
    elseif event == "UNIT_POWER_FREQUENT" then if eventArg=="player" then updateCombo() end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" then updateCombo()
    elseif event == "PLAYER_ENTERING_WORLD" then updateCombo();updateAuxText()
    elseif event == "GET_ITEM_INFO_RECEIVED" then updateAuxText()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then updateAuxText()
    elseif event == "BAG_UPDATE_DELAYED" then updateAuxText()
    elseif event == "PLAYER_REGEN_DISABLED" then swingLane:SetShown(true);updateCombo()
    elseif event == "PLAYER_REGEN_ENABLED" then stopAllSwings(); swingFill:SetWidth(0); swingText:SetText(""); swingLane:SetShown(db.swingVisibility == "ALWAYS"); updateSwingBars();updateCombo()
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
            "PLAYER_SWING","WEAPON_SLOT_CHANGED","UNIT_POWER_FREQUENT","PLAYER_TARGET_CHANGED","UPDATE_SHAPESHIFT_FORM","PLAYER_ENTERING_WORLD","GET_ITEM_INFO_RECEIVED"}) do eventFrame:RegisterEvent(event) end
        playerGUID=UnitGUID("player"); applyLayout()
    else
        stopAllSwings(); frame:SetScript("OnUpdate",nil)
    end
    frame:SetShown(enabled)
    if enabled then updateAuxText();updateCombo()
    else ammoFrame:Hide();comboFrame:Hide();comboFrame:EnableMouse(false);comboFrame:StopMovingOrSizing() end
end
SlashCmdList.KHQOLRESOURCESWING = function()
    local settings=NS.settings
    if settings and settings:IsShown() and settings.page=="bars" and NS.BarsSettings.selected=="resource" then
        settings:Hide()
    else NS:ShowSettings("resourceSwing") end
end
