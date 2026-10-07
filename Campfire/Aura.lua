local _, KHQOL = ...
local CFA = KHQOL.modules.campfire

-- Compatibility layer: every gameplay module uses these functions, never a raw aura API.
local function NormalizeAura(first, icon, count, dispelType, duration, expirationTime, sourceUnit, _, _, spellId)
    if type(first) == "table" then
        return {
            name = first.name,
            icon = first.icon or first.iconFileID,
            applications = first.applications or first.count,
            duration = first.duration,
            expirationTime = first.expirationTime,
            sourceUnit = first.sourceUnit,
            spellId = first.spellId or first.spellID,
        }
    end
    if first then
        return { name = first, icon = icon, applications = count, dispelType = dispelType, duration = duration, expirationTime = expirationTime, sourceUnit = sourceUnit, spellId = spellId }
    end
end

function CFA:GetPlayerAura(spellID)
    if not spellID then return nil end
    -- Mainline-style API, present on current retail-derived clients.
    if C_UnitAuras and type(C_UnitAuras.GetPlayerAuraBySpellID) == "function" then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, "player", spellID)
        if ok and aura then return NormalizeAura(aura) end
    end
    -- AuraUtil works across several client generations, but its return shape differs.
    if AuraUtil and type(AuraUtil.FindAuraBySpellID) == "function" then
        local ok, a, b, c, d, e, f, g, h, i, j = pcall(AuraUtil.FindAuraBySpellID, spellID, "player", "HELPFUL")
        if ok and a then
            local aura = NormalizeAura(a, b, c, d, e, f, g, h, i, j)
            if aura then
                aura.spellId = aura.spellId or spellID
                return aura
            end
        end
    end
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        for index = 1, 80 do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
            if not ok or not auraData then break end
            local aura = NormalizeAura(auraData)
            if aura and aura.spellId == spellID then return aura end
        end
    end
    -- Old and beta fallback. This scan runs only during an aura event, login, or slash command.
    if type(UnitAura) == "function" then
        for index = 1, 80 do
            local a, b, c, d, e, f, g, h, i, j = UnitAura("player", index, "HELPFUL")
            if not a then break end
            local aura = NormalizeAura(a, b, c, d, e, f, g, h, i, j)
            if aura and aura.spellId == spellID then return aura end
        end
    end
    return nil
end

function CFA:HasPlayerAura(spellID)
    return self:GetPlayerAura(spellID) ~= nil
end

function CFA:HasAnyCampBenefit()
    for _, spellID in ipairs(self.SPELLS.CAMP_BENEFITS) do
        local aura = self:GetPlayerAura(spellID)
        if aura then return aura end
    end
    return nil
end

function CFA:GetAllPlayerBuffs()
    local auras = {}
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        for index = 1, 80 do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
            if not ok or not auraData then break end
            local aura = NormalizeAura(auraData)
            if aura then table.insert(auras, aura) end
        end
        return auras
    end
    if type(UnitAura) ~= "function" then return auras end
    for index = 1, 80 do
        local a, b, c, d, e, f, g, h, i, j = UnitAura("player", index, "HELPFUL")
        if not a then break end
        local aura = NormalizeAura(a, b, c, d, e, f, g, h, i, j)
        if aura then table.insert(auras, aura) end
    end
    return auras
end
