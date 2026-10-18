local addonName, A = ...
A.name, A.version = addonName, "1.11.4.6"
local K = assert(_G.KHQOL, "Install and enable KHQOL.")
K.modules.minimap = A
A.geometryEpsilon = 0.01
A.defaults = {
    appearance = true, shape = "ROUND", size = 200,
    border = { r = 0.72, g = 0.74, b = 0.77 }, zone = true, zoneLocation = "ABOVE", locked = true,
    elementPositions = {}, elements = {mail=true,tracking=true,diel=true}, zoneScale=100, elementScale=100,
    drawer = true, drawerDirection = "LEFT", drawerLayout = "VERTICAL", iconSize = 24, angle = 225, excluded = {},
}
A.messages, A.writing = {}, 0

function A:IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

function A:Number(value)
    return not self:IsSecret(value) and type(value) == "number" and
        value == value and value > -10000000 and value < 10000000
end

function A:Pack(...)
    local n = select("#", ...)
    for i = 1, n do if self:IsSecret(select(i, ...)) then return nil end end
    return { n = n, ... }
end

function A:Same(a, b, key)
    if not a or not b or a.n ~= b.n then return false end
    for i = 1, a.n do
        local x, y = a[i], b[i]
        if self:IsSecret(x) or self:IsSecret(y) then return false end
        if x ~= y then
            -- Resolved UI rectangles can drift slightly after anchoring or
            -- reparenting. Identity, scripts, anchor counts and levels stay exact.
            local tolerance
            if key == "size" or (key == "points" and i > 1 and (i%5 == 0 or i%5 == 1)) then
                tolerance = self.geometryEpsilon
            elseif key == "scale" or key == "alpha" then tolerance = 0.00001 end
            if not tolerance or not self:Number(x) or not self:Number(y) or math.abs(x-y) > tolerance then return false end
        end
    end
    return true
end

-- pcall handles unavailable getters, after explicit access and secret checks.
-- A successful pcall is never treated as proof that its result is public.
function A:Accessible(frame, allowProtected)
    if self:IsSecret(frame) or not frame then return false end
    local kind = type(frame)
    if kind ~= "table" and kind ~= "userdata" then return false end
    if canaccessobject and not canaccessobject(frame) then return false end
    if frame.CanBeAccessedInContext then
        local v = frame:CanBeAccessedInContext()
        if self:IsSecret(v) or v ~= true then return false end
    end
    if frame.IsForbidden then
        local v = frame:IsForbidden()
        if self:IsSecret(v) or v then return false end
    end
    if frame.HasSecretValues then
        local v = frame:HasSecretValues()
        if self:IsSecret(v) or v then return false end
    end
    if not allowProtected and frame.IsProtected then
        local v = frame:IsProtected()
        if self:IsSecret(v) or v then return false end
    end
    return true
end

function A:Read(frame, getter)
    if not self:Accessible(frame, true) then return nil end
    local ok, value = pcall(getter, frame)
    if not ok or not value then return nil end
    return value
end

function A:CanAnchor(frame)
    if not self:Accessible(frame, true) then return false end
    for _, method in ipairs({"IsAnchoringRestricted", "IsAnchoringSecret"}) do
        if frame[method] then
            local value = frame[method](frame)
            if self:IsSecret(value) or value then return false end
        end
    end
    return true
end

function A:GetPoints(frame)
    local count = frame:GetNumPoints()
    if not self:Number(count) or count < 0 or count > 12 then return nil end
    local result = { n = 1 + count * 5, count }
    for i = 1, count do
        local point = self:Pack(frame:GetPoint(i))
        if not point then return nil end
        for j = 1, 5 do result[1 + (i - 1) * 5 + j] = point[j] end
    end
    return result
end

function A:SetPoints(frame, ...)
    local p = { ... }
    frame:ClearAllPoints()
    for i = 1, p[1] do
        local j = 2 + (i - 1) * 5
        frame:SetPoint(unpack(p, j, j + 4))
    end
end

A.get = {
    points = function(f) return A:GetPoints(f) end,
    parent = function(f) return A:Pack(f:GetParent()) end,
    size = function(f) return A:Pack(f:GetSize()) end,
    scale = function(f) return A:Pack(f:GetScale()) end,
    alpha = function(f) return A:Pack(f:GetAlpha()) end,
    shown = function(f) return A:Pack(f:IsShown()) end,
    strata = function(f) return A:Pack(f:GetFrameStrata()) end,
    level = function(f) return A:Pack(f:GetFrameLevel()) end,
    clamped = function(f) return A:Pack(f:IsClampedToScreen()) end,
    fixedLevel = function(f) return A:Pack(f:HasFixedFrameLevel()) end,
    fixedStrata = function(f) return A:Pack(f:HasFixedFrameStrata()) end,
    mouse = function(f) return A:Pack(f:IsMouseEnabled()) end,
}
A.set = {
    points = function(f, ...) A:SetPoints(f, ...) end,
    parent = function(f, v) f:SetParent(v) end,
    size = function(f, w, h) f:SetSize(w, h) end,
    scale = function(f, v) f:SetScale(v) end,
    alpha = function(f, v) f:SetAlpha(v) end,
    shown = function(f, v) f:SetShown(v) end,
    strata = function(f, v) f:SetFrameStrata(v) end,
    level = function(f, v) f:SetFrameLevel(v) end,
    clamped = function(f, v) f:SetClampedToScreen(v) end,
    fixedLevel = function(f, v) f:SetFixedFrameLevel(v) end,
    fixedStrata = function(f, v) f:SetFixedFrameStrata(v) end,
    mouse = function(f, v) f:EnableMouse(v) end,
}

-- Only values still equal to our last write are restored. This journal exists
-- solely in memory; no frame, function, or userdata enters SavedVariables.
function A:NewJournal()
    local journal = { entries = {}, byFrame = {} }
    function journal:Capture(frame, key, getter, setter)
        getter, setter = getter or A.get[key], setter or A.set[key]
        local current = A:Read(frame, getter)
        if not current then return false end
        local props = self.byFrame[frame]
        if not props then props = {}; self.byFrame[frame] = props end
        if not props[key] then
            local entry = {frame=frame, key=key, old=current, get=getter, set=setter}
            props[key] = entry; self.entries[#self.entries+1] = entry
        end
        return true
    end
    function journal:Write(frame, key, getter, setter, ...)
        if key == "points" and not A:CanAnchor(frame) then return false end
        local current = A:Read(frame, getter)
        if not current then return false end
        local props = self.byFrame[frame]
        if not props then props = {}; self.byFrame[frame] = props end
        local entry = props[key]
        if entry and entry.last and not A:Same(current, entry.last, key) then
            entry.lost = true
            return false
        end
        if entry and entry.lost then return false end
        if not entry then
            entry = { frame = frame, key = key, old = current, get = getter, set = setter }
            props[key] = entry
            self.entries[#self.entries + 1] = entry
        end
        local wanted = A:Pack(...)
        if not wanted then return false end
        if not A:Same(current, wanted, key) then
            A.writing = A.writing + 1
            setter(frame, ...)
            A.writing = A.writing - 1
        end
        entry.last = A:Read(frame, getter)
        return entry.last ~= nil
    end
    function journal:Set(frame, key, ...)
        return self:Write(frame, key, A.get[key], A.set[key], ...)
    end
    function journal:Rebase(frame, key, authoritative)
        local entry = self.byFrame[frame] and self.byFrame[frame][key]
        if not entry then return end
        local value = A:Read(frame, entry.get)
        if value and (authoritative or not A:Same(value, entry.last, key)) then
            entry.old, entry.last, entry.lost = value, nil, nil
        end
    end
    function journal:Restore()
        -- Snapshot ownership before restoring dependencies: changing a parent
        -- can itself alter frame levels. Such side effects are still our work.
        local snapshot = {}
        for _, e in ipairs(self.entries) do
            if not e.done then
                local current = A:Read(e.frame, e.get)
                if not current or (e.key == "points" and not A:CanAnchor(e.frame)) then return false end
                snapshot[e] = current
            end
        end
        for i = #self.entries, 1, -1 do
            local e = self.entries[i]
            if not e.done then
                local current = snapshot[e]
                local owned = e.last and A:Same(current, e.last, e.key) and not e.lost
                local target = owned and e.old or (e.key == "level" and current or nil)
                local now = target and A:Read(e.frame, e.get)
                if target and now and not A:Same(now, target, e.key) then
                    A.writing = A.writing + 1
                    e.set(e.frame, unpack(target, 1, target.n))
                    A.writing = A.writing - 1
                end
                e.done = true
            end
        end
        return true
    end
    return journal
end

function A:Clamp(v, low, high) return math.max(low, math.min(high, v)) end

local function Fill(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then target[key] = {}; Fill(target[key], value)
            else target[key] = value end
        elseif type(value) == "table" and type(target[key]) == "table" then
            Fill(target[key], value)
        end
    end
end

function A:InitDB()
    -- The optional KH_map data-only addon loads the old account file first.
    -- Prefer an existing new store; copy once without aliasing or mutating the
    -- old variable. Each TOC keeps a unique SavedVariables owner.
    if type(KHQOLMapDB) ~= "table" then
        local legacy=type(KHminimapDB)=="table"
        KHQOLMapDB=legacy and K.CopyProfileValue(KHminimapDB) or {}
        self.importedLegacySettings=legacy or nil
    end
    Fill(KHQOLMapDB, self.defaults)
    self.db = KHQOLMapDB
    -- Discard retired development data if an older account file loaded it.
    KHminimapDebugDB = nil
    local db = self.db
    for _, key in ipairs({"appearance", "zone", "locked", "drawer"}) do
        if type(db[key]) ~= "boolean" then db[key] = self.defaults[key] end
    end
    for key, range in pairs({size = {180, 300}, iconSize = {20, 30}, angle = {0, 360},zoneScale={100,200},elementScale={70,150}}) do
        if not self:Number(db[key]) then db[key] = self.defaults[key] end
        db[key] = self:Clamp(db[key], range[1], range[2])
    end
    if db.shape ~= "ROUND" and db.shape ~= "SQUARE" then db.shape = "ROUND" end
    if db.zoneLocation ~= "ABOVE" and db.zoneLocation ~= "INSIDE" then db.zoneLocation = "ABOVE" end
    if type(db.elementPositions) ~= "table" then db.elementPositions = {} end
    for _, key in ipairs({"tracking", "diel", "mail"}) do
        local p = db.elementPositions[key]
        if p and (type(p) ~= "table" or not self:Number(p.x) or not self:Number(p.y)) then
            db.elementPositions[key] = nil
        elseif p then p.x = self:Clamp(p.x,-4000,4000); p.y = self:Clamp(p.y,-4000,4000) end
    end
    if type(db.elements)~="table" then db.elements={} end
    for _,key in ipairs({"mail","tracking","diel"}) do if type(db.elements[key])~="boolean" then db.elements[key]=true end end
    if not ({RIGHT=true,LEFT=true,UP=true,DOWN=true})[db.drawerDirection] then db.drawerDirection="LEFT" end
    if db.drawerLayout~="HORIZONTAL" and db.drawerLayout~="VERTICAL" then db.drawerLayout="VERTICAL" end
    local settingsPosition=db.settingsPosition
    if settingsPosition and (type(settingsPosition)~="table" or not self:Number(settingsPosition.x) or not self:Number(settingsPosition.y)) then
        db.settingsPosition=nil
    elseif settingsPosition then
        settingsPosition.x=self:Clamp(settingsPosition.x,0,1); settingsPosition.y=self:Clamp(settingsPosition.y,0,1)
    end
    if type(db.border) ~= "table" then db.border = {}; Fill(db.border, self.defaults.border) end
    for _, key in ipairs({"r", "g", "b"}) do
        if not self:Number(db.border[key]) then db.border[key] = self.defaults.border[key] end
        db.border[key] = self:Clamp(db.border[key], 0, 1)
    end
    if type(db.excluded) ~= "table" then db.excluded = {} end
    if db.position and (type(db.position) ~= "table" or not self:Number(db.position.x) or
        not self:Number(db.position.y)) then db.position = nil end
    if db.position then
        db.position.x = self:Clamp(db.position.x, 0, 1)
        db.position.y = self:Clamp(db.position.y, 0, 1)
    end
    if db.buttonPosition and (type(db.buttonPosition)~="table" or not self:Number(db.buttonPosition.x) or not self:Number(db.buttonPosition.y)) then
        db.buttonPosition=nil
    end
    if db.buttonPosition then
        db.buttonPosition.x=self:Clamp(db.buttonPosition.x,0,1)
        db.buttonPosition.y=self:Clamp(db.buttonPosition.y,0,1)
    end
end

function A:IsLoaded(name)
    local fn = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if not fn then return false end
    local v = fn(name)
    return not self:IsSecret(v) and v == true
end

function A:FindConflict(names)
    for _, name in ipairs(names) do if self:IsLoaded(name) then return name end end
end

-- Read only the verified public option flags; never change another addon's DB.
function A:EnhanceConflict(keys)
    if not self:IsLoaded("EnhanceQoL") then return end
    local addon = _G.EnhanceQoL
    if self:IsSecret(addon) or type(addon) ~= "table" then return "EnhanceQoL 설정 확인 대기" end
    local db = addon.db
    if self:IsSecret(db) or type(db) ~= "table" then return "EnhanceQoL 설정 확인 대기" end
    for _, key in ipairs(keys) do
        local value = db[key]
        if self:IsSecret(value) or value == true then return "EnhanceQoL 미니맵 기능" end
    end
end

function A:Request(scan)
    self.scanWanted = self.enabled and (self.scanWanted or scan) or nil
    self.dirty = true
    if not self.ready or self.scheduled then return end
    self.scheduled = true
    C_Timer.After(0, function()
        self.scheduled = false
        self:Apply()
    end)
end

function A:Apply()
    if not self.ready then return end
    if InCombatLockdown() then
        self.messages.combat = "전투 종료 후 현재 설정을 적용합니다."
        self:RefreshSettings()
        return
    end
    self.messages.combat = nil
    self.dirty = false
    self.Minimap:Apply()
    if self.scanWanted then self.scanWanted = nil; self.Buttons:Discover() end
    self.Buttons:Apply()
    self:RefreshSettings()
    if self.openWanted then self.openWanted = nil; self:OpenSettings() end
    if self.colorWanted then self.colorWanted = nil; self:OpenColor() end
end

function A:Start()
    if self.ready or not self.enabled or InCombatLockdown() then return end
    self.ready = true
    self.Minimap:Initialize()
    self.Buttons:Initialize()
    self:InitializeSettings()
    self:Request(true)
    -- Three bounded retries; no ticker, frame enumeration, or idle OnUpdate.
    for _, delay in ipairs({1, 3, 8}) do C_Timer.After(delay, function() if self.enabled then self:Request(true) end end) end
end

function A:InstallSlash()
    local function Taken(command)
        for key, value in pairs(_G) do
            if type(key) == "string" and key:match("^SLASH_") and
                not A:IsSecret(value) and value == command then return true end
        end
    end
    local command, suffix = "/khmap", 1
    while Taken(command) do suffix = suffix + 1; command = "/khmap" .. suffix end
    local id = "KH_MAP"
    while SlashCmdList[id] do id = id .. "_KH" end
    _G["SLASH_" .. id .. "1"] = command
    SlashCmdList[id] = function() A:OpenSettings() end
    local index=2
    for _,alias in ipairs({"/kh_map","/khminimap"}) do
        if not Taken(alias) then _G["SLASH_"..id..index]=alias;index=index+1 end
    end
    self.command = command
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        A:InitDB()
        A:InstallSlash()
    elseif event == "PLAYER_LOGIN" then
        if not A.db then A:InitDB(); A:InstallSlash() end
        A.loggedIn = true
        -- KHQOL dispatches the module after profiles and settings are ready.
    elseif event == "PLAYER_REGEN_ENABLED" and A.loggedIn and not A.ready then
        A:Start()
    elseif A.ready and event == "PLAYER_REGEN_DISABLED" then
        A.Minimap:StopDrag()
        A.Buttons:StopDrag()
    elseif A.ready then
        A:Request(event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD")
    end
end)
A.events = events
