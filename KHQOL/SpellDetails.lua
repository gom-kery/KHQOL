local _,K=...
local function isSecret(v) return not K.IsPublicValue(v) end
function K:GetSpellDetails(spellID)
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
        self.spellDetailsRequested=self.spellDetailsRequested or {}
        if self.IsPublicNumber(spellID) and spellID>0 and not self.spellDetailsRequested[spellID]
            and C_Spell and type(C_Spell.RequestLoadSpellData)=="function" then
            self.spellDetailsRequested[spellID]=true
            pcall(C_Spell.RequestLoadSpellData,spellID)
        end
        return nil
    end
    return name, icon
end

