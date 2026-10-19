local K = assert(_G.KHQOL)
local RS, UI = K.PlayerAux, K.UI
local read, api = K.PublicCall, K.ReadPublicAPI
local SHARD = 6265
local function integer(v, low, high)
    return K.IsPublicNumber(v) and v == math.floor(v) and v >= low and v <= high
end
local function config() return KHQOLResourceSwingDB end
local function container(name) return C_Container and C_Container[name] or _G[name] end
local function itemField(info, key)
    if not K.IsPublicValue(info) or type(info) ~= "table" then return end
    return read(function() return info[key] end)
end
function RS:GetShardLimit()
    local d = config()
    return d and integer(d.soulShardMax, 0, 1000) and d.soulShardMax or nil
end
-- Capacity is all carried normal/soul-bag slots, not the fluctuating free space.
-- Never include bank slots or unrelated specialty bags, or lower a saved limit
-- automatically when a bag is removed or replaced.
function RS:GetShardCapacity()
    if not integer(NUM_BAG_SLOTS, 1, 20) then return end
    local total = 0
    local shardFamily = read(C_Item and C_Item.GetItemFamily or GetItemFamily, SHARD)
    for bag = 0, NUM_BAG_SLOTS do
        local slots = read(container("GetContainerNumSlots"), bag)
        if not integer(slots, 0, 1000) then return end
        if slots > 0 then
            local _, family = read(container("GetContainerNumFreeSlots"), bag)
            if bag == 0 then family = 0 end
            if not integer(family, 0, 2147483647) then return end
            local soul = integer(shardFamily, 1, 2147483647) and
                (family == shardFamily or bit and bit.band and bit.band(family, shardFamily) > 0)
            if family == 0 or soul then total = total + slots end
        end
    end
    return total
end
function RS:SetShardLimit(value)
    if type(value) == "string" then
        if not value:match("^%s*%d+%s*$") then return false, "0 이상의 정수를 입력하세요." end
        value = tonumber(value)
    end
    local capacity = self:GetShardCapacity()
    if not integer(value, 0, 1000) then return false, "0 이상의 정수를 입력하세요." end
    if not capacity then return false, "가방 용량을 확인할 수 없습니다. 잠시 후 다시 시도하세요." end
    if value > capacity then return false, "일반·영혼 가방의 전체 칸 수(" .. capacity .. ") 이내로 입력하세요." end
    local d = config()
    if not d then return false end
    d.soulShardMax = value
    K.PositionStore:Committed(function() RS:RefreshAux() end)
    return true
end
function RS:CanUseShardClicks()
    local d = config()
    return d and self:IsEnabled() and d.showSoulShards and d.ammoLocked == true
        and self:IsWarlock()
        and read(InCombatLockdown) == false and read(UnitAffectingCombat, "player") == false
        and not (K.PositionEditor and K.PositionEditor.active) or false
end
local function slotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = read(C_Container.GetContainerItemInfo, bag, slot)
        return itemField(info, "stackCount"), itemField(info, "isLocked")
    end
    local _, count, locked = read(GetContainerItemInfo, bag, slot)
    return count, locked
end
local function carriedShards()
    if not integer(NUM_BAG_SLOTS, 1, 20) then return end
    local total, chosenBag, chosenSlot = 0
    for bag = 0, NUM_BAG_SLOTS do
        local slots = read(container("GetContainerNumSlots"), bag)
        if not integer(slots, 0, 1000) then return end
        for slot = 1, slots do
            local status, id = api(container("GetContainerItemID"), bag, slot)
            if status ~= "ok" or id ~= nil and not integer(id, 1, 2147483647) then return end
            if id == SHARD then
                local count, locked = slotInfo(bag, slot)
                if not integer(count, 1, 1000000) or type(locked) ~= "boolean" then return end
                total = total + count
                -- Forever shards are individual items. Fail closed for an
                -- unexpected stack rather than destroying more than one.
                if count == 1 and not locked and not chosenBag then chosenBag, chosenSlot = bag, slot end
            end
        end
    end
    return total, chosenBag, chosenSlot
end
-- Called only by the real icon OnClick, synchronously within that hardware
-- event. No bag/combat event, timer, macro, or automatic deletion calls it.
function RS:DestroyExcessShard()
    if not self:CanUseShardClicks() then return false end
    local limit = self:GetShardLimit()
    local label, count = self:GetAuxData() -- Includes the cached item-name check.
    if not limit or not label or not integer(count, 0, 100000000) or count <= limit then return false end
    local cursorStatus, cursor = api(GetCursorInfo)
    if cursorStatus ~= "ok" or cursor ~= nil then return false end
    local total, bag, slot = carriedShards()
    if total ~= count or not bag then return false end
    local pickup = container("PickupContainerItem")
    if type(pickup) ~= "function" or type(DeleteCursorItem) ~= "function" or type(ClearCursor) ~= "function" then return false end
    -- Recheck the selected slot and threshold immediately before pickup.
    local id = read(container("GetContainerItemID"), bag, slot)
    local quantity, locked = slotInfo(bag, slot)
    if id ~= SHARD or quantity ~= 1 or locked ~= false or not self:CanUseShardClicks() then return false end
    local _, latest = self:GetAuxData()
    if latest ~= total or latest <= limit then return false end
    if not pcall(pickup, bag, slot) then return false end
    local status, kind, cursorID = api(GetCursorInfo)
    local deleted = false
    if status == "ok" and kind == "item" and cursorID == SHARD and self:CanUseShardClicks() then
        -- This path bypasses the generic destroy dialog only for item 6265.
        local ok = pcall(DeleteCursorItem)
        local after, remaining = api(GetCursorInfo)
        deleted = ok and after == "ok" and remaining == nil
    end
    -- Return our pickup if the client refused it. A pre-existing cursor was
    -- rejected before pickup and is never cleared or destroyed.
    if not deleted then pcall(ClearCursor) end
    self:RefreshAux()
    if not deleted and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("KHQOL: 영혼의 조각을 파괴하지 못했습니다. 가방 상태를 확인한 후 다시 클릭하세요.")
    end
    return deleted
end
function RS:OpenShardLimit()
    if not self:CanUseShardClicks() then return false end
    local panel = self.shardLimitPanel
    if not panel then
        panel = CreateFrame("Frame", "KHQOLSoulShardLimit", UIParent, "BackdropTemplate")
        self.shardLimitPanel = panel
        panel:SetSize(340, 180); panel:SetPoint("CENTER"); panel:SetFrameStrata("FULLSCREEN_DIALOG")
        panel:SetClampedToScreen(true); panel:EnableMouse(true); UI:Surface(panel, 1)
        UI:CreateLabel(panel, "영혼의 조각 최대 보관 수량", 14, -14, 16)
        panel.hint = UI:CreateDescription(panel, "", 14, -42); panel.hint:SetWidth(312); panel.hint:SetHeight(40)
        panel.input = UI:CreateEditBox(panel, 14, -90, 100)
        panel.input:SetMaxLetters(4)
        local function save()
            if panel.generation ~= K.profileGeneration or not RS:CanUseShardClicks() then panel:Hide(); return end
            local ok, message = RS:SetShardLimit(panel.input:GetText())
            if ok then panel:Hide() else panel.hint:SetText(message) end
        end
        panel.input:SetScript("OnEnterPressed", save)
        panel.input:SetScript("OnEscapePressed", function() panel:Hide() end)
        UI:CreateButton(panel, "저장", 14, -136, 100, save)
        UI:CreateButton(panel, "취소", 126, -136, 100, function() panel:Hide() end)
        panel:SetScript("OnEvent", function() panel:Hide() end)
        panel:SetScript("OnHide", function() panel:UnregisterAllEvents(); panel.input:ClearFocus() end)
        if UISpecialFrames then table.insert(UISpecialFrames, "KHQOLSoulShardLimit") end
    end
    local capacity = self:GetShardCapacity()
    panel.generation = K.profileGeneration
    panel.hint:SetText(capacity and "입력 범위: 0~" .. capacity .. "개\n일반·영혼 가방의 전체 칸 수 기준" or "가방 용량을 확인할 수 없습니다.")
    panel.input:SetText(tostring(self:GetShardLimit() or 20))
    panel:RegisterEvent("PLAYER_REGEN_DISABLED"); panel:RegisterEvent("PLAYER_LEAVING_WORLD")
    panel:Show(); panel.input:SetFocus(); panel.input:HighlightText()
    return true
end
function RS:CreateShardControls(parent, icon, text)
    local iconButton = CreateFrame("Button", nil, parent)
    self.shardDestroyButton = iconButton
    iconButton:SetAllPoints(icon); iconButton:RegisterForClicks("LeftButtonUp")
    iconButton:SetScript("OnClick", function(_, button) if button == "LeftButton" then RS:DestroyExcessShard() end end)
    local numberButton = CreateFrame("Button", nil, parent)
    self.shardNumberButton = numberButton
    numberButton:SetAllPoints(text); numberButton:RegisterForClicks("RightButtonUp")
    numberButton:SetScript("OnClick", function(_, button) if button == "RightButton" then RS:OpenShardLimit() end end)
    for _, button in ipairs({iconButton, numberButton}) do
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("영혼의 조각")
            GameTooltip:AddLine("최대 보관 수량: " .. tostring(RS:GetShardLimit() or "?"), 1, 1, 1)
            GameTooltip:AddLine(self == iconButton and "좌클릭: 최대 수량을 넘는 조각 1개를 확인창 없이 파괴" or "우클릭: 최대 보관 수량 변경", .85, .88, .9, true)
            GameTooltip:AddLine("보조 표시 위치 잠금 ON · 비전투에서 사용", .7, .8, .8, true); GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    parent:HookScript("OnHide", function() if RS.shardLimitPanel then RS.shardLimitPanel:Hide() end end)
end
function RS:RefreshShardControls()
    local enabled = self:CanUseShardClicks() and self.auxStatus == nil and self.auxCount ~= nil
    for _, button in pairs({self.shardDestroyButton, self.shardNumberButton}) do button:EnableMouse(enabled) end
    if self.shardLimitPanel and (not enabled or self.shardLimitPanel.generation ~= K.profileGeneration) then self.shardLimitPanel:Hide() end
end
