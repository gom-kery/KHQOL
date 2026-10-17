local _, A = ...
local B = { records = {}, ordered = {}, hooks = setmetatable({}, {__mode = "k"}), page = 1 }
A.Buttons = B
local conflicts = { "KHminimap", "MinimapButtonButton", "MBB", "HidingBar", "SexyMap", "ElvUI", "Tukui",
    "EllesmereUI", "EllesmereUIMinimap", "EllesmereUI_Minimap", "EUI_Minimap", "Mappy", "MappyContinued", "ForeverUI" }
local custom = { {"KHQOLMinimapButton", "KHQOL"}, {"ForeverNoteMinimapButton", "Forever Note"},
    {"BooksOnMapForeverMinimapButton", "Books on map"} }
local positionRule={keys={"points"},ops={SetPoint=true,ClearAllPoints=true}}
local dragRule={keys={"OnDragStart","OnDragStop"},ops={["SetScript:OnDragStart"]=true,["SetScript:OnDragStop"]=true}}
local refreshRule={keys={"points","OnDragStart","OnDragStop"},ops={SetPoint=true,ClearAllPoints=true,
    ["SetScript:OnDragStart"]=true,["SetScript:OnDragStop"]=true}}
local sizeRule={keys={},ops={SetSize=true,SetWidth=true,SetHeight=true}}

function B:Initialize()
    if not A:Accessible(Minimap, true) then return end
    self.hidden = CreateFrame("Frame",nil,UIParent); self.hidden:Hide(); self.hidden.ignoreInLayout=true
    self.drawer = CreateFrame("Frame", nil, Minimap)
    self.drawer:SetFrameStrata("MEDIUM"); self.drawer:SetFrameLevel(40)
    self.drawer:SetClampedToScreen(true); self.drawer:EnableMouse(true)
    local bg = self.drawer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(31/255,31/255,31/255,1)
    self.background=bg
    self.empty = self.drawer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.empty:SetPoint("CENTER"); self.empty:SetText("수납할 버튼이 없습니다.\n설정에서 목록을 새로고침하세요.")
    local function Pager(text, x, change)
        local b = CreateFrame("Button", nil, self.drawer, "UIPanelButtonTemplate")
        b:SetSize(30, 20); b:SetPoint("BOTTOM", x, 5); b:SetText(text)
        b:SetScript("OnClick", function()
            if not InCombatLockdown() then
                self.page=self.page+change; self:Layout()
            end
        end)
        return b
    end
    self.prev, self.next = Pager("<", -60, -1), Pager(">", 60, 1)
    self.pageText = self.drawer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.pageText:SetPoint("BOTTOM", 0, 9)
    self.drawer:Hide()
    local toggle = CreateFrame("Button", nil, Minimap)
    toggle:SetSize(27, 27); toggle:SetFrameStrata("MEDIUM"); toggle:SetFrameLevel(50)
    local back = toggle:CreateTexture(nil, "ARTWORK")
    back:SetAllPoints(); back:SetTexture("Interface\\AddOns\\KH_map\\Media\\Storage.tga")
    self.toggleArt=back
    local text = toggle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetAllPoints(); text:SetText("")
    self.toggleText = text
    toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp"); toggle:RegisterForDrag("LeftButton")
    toggle:SetScript("OnMouseDown", function() self.dragged = nil end)
    toggle:SetScript("OnClick", function(_, button)
        if self.dragged then self.dragged = nil; return end
        if button == "RightButton" then A:OpenSettings(); return end
        self.open = not self.open
        A:Request(true)
    end)
    toggle:SetScript("OnEnter", function(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT"); GameTooltip:SetText(A.name)
        GameTooltip:AddLine("좌클릭: 수납함 펼치기 / 접기", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("우클릭: 설정 · 드래그: 가장자리 이동", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    toggle:SetScript("OnDragStart", function()
        if InCombatLockdown() or A.editing then return end
        self.dragged = true
        toggle:SetScript("OnUpdate", function()
            if InCombatLockdown() then self:StopDrag(); return end
            local x, y = GetCursorPosition()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            if not (A:Number(x) and A:Number(y) and A:Number(mx) and A:Number(my) and
                A:Number(scale) and scale > 0) then return end
            A.db.angle = math.deg(math.atan2(y / scale - my, x / scale - mx)) % 360
            self:PositionToggle()
            if self.open then self:Layout() end
        end)
    end)
    toggle:SetScript("OnDragStop", function() self:StopDrag(); A:Request() end)
    toggle:Hide()
    self.toggle = toggle
end

function B:StopDrag()
    if self.toggle then self.toggle:SetScript("OnUpdate", nil) end
end

function B:PositionToggle()
    if not A:Accessible(Minimap, true) then return end
    local ms, us = Minimap:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local w, h = Minimap:GetWidth(), Minimap:GetHeight()
    if not (A:Number(ms) and A:Number(us) and ms > 0 and us > 0 and A:Number(w) and A:Number(h)) then return end
    self.toggle:SetScale(us / ms)
    self.drawer:SetScale(us / ms)
    local angle = math.rad(A.db.angle)
    local x, y = math.cos(angle), math.sin(angle)
    local square = A.Minimap.active and A.db.shape == "SQUARE"
    if square then local d = math.max(math.abs(x), math.abs(y)); x, y = x / d, y / d end
    self.toggle:ClearAllPoints()
    x,y=x * (w * ms / us / 2 + 4),y * (h * ms / us / 2 + 4)
    self.toggle:SetPoint("CENTER", Minimap, "CENTER", x,y)
    local cx,cy=Minimap:GetCenter()
    local center=A.Minimap.active and A.Minimap.centerUI
    if center then cx,cy=center.x,center.y
    elseif A:Number(cx) and A:Number(cy) then cx,cy=cx*ms/us,cy*ms/us end
    if A:Number(cx) and A:Number(cy) then self.toggleCenterUI={x=cx+x,y=cy+y} end
    return true
end

function B:HookOwner(owner,method,callback)
    if A:IsSecret(owner) or type(owner)~="table" or A:IsSecret(owner[method]) or type(owner[method])~="function" then return end
    self.ownerHooks=self.ownerHooks or setmetatable({}, {__mode="k"})
    local hooks=self.ownerHooks[owner]
    if not hooks then hooks={};self.ownerHooks[owner]=hooks end
    if hooks[method]==owner[method] then return end
    hooksecurefunc(owner,method,callback);hooks[method]=owner[method]
end

function B:OwnerUpdated(r,rule)
    if not r or not r.collecting or not r.journal or A.writing~=0 then return end
    local previous=r.ownerIntent and r.ownerIntent.serial or 0
    for op,serial in pairs(r.externalWrites or {}) do
        if serial>previous and not rule.ops[op] then return end
    end
    local intent=r.ownerIntent or {keys={}}
    for _, key in ipairs(rule.keys) do intent.keys[key]=true end
    intent.serial=r.externalSerial or 0; r.ownerIntent=intent
    A:Request()
end

function B:WatchOwners(lib)
    if lib then
        for method,rule in pairs({Show=positionRule,Refresh=refreshRule,Lock=dragRule,Unlock=dragRule,
            SetButtonToPosition=positionRule,SetButtonRadius=positionRule,SetButtonSize=sizeRule,ResetButtonSize=sizeRule}) do
            local name,policy=method,rule
            self:HookOwner(lib,name,function(_, target)
                if name=="SetButtonRadius" then
                    for _,r in pairs(self.records) do if r.kind=="lib" then self:OwnerUpdated(r,policy) end end
                elseif not A:IsSecret(target) then
                    local r=type(target)=="string" and self.records["lib:"..target]
                    if r then self:OwnerUpdated(r,policy)
                    elseif type(target)=="table" or type(target)=="userdata" then
                        for _,record in pairs(self.records) do
                            if record.kind=="lib" and record.frame==target then self:OwnerUpdated(record,policy);break end
                        end
                    end
                end
            end)
        end
    end
    local q=_G.KHQOL
    if not A:IsSecret(q) and type(q)=="table" then
        self:HookOwner(q,"UpdateMinimapButton",function()
            self:OwnerUpdated(self.records["custom:KHQOLMinimapButton"],positionRule)
        end)
        local modules=q.modules
        if not A:IsSecret(modules) and type(modules)=="table" then
            local clock=modules.clock
            self:HookOwner(clock,"UpdateTodoMinimapButton",function()
                self:OwnerUpdated(self.records["custom:ForeverNoteMinimapButton"],positionRule)
            end)
        end
    end
end

function B:RecoverOwner(r)
    local intent=r.ownerIntent
    r.ownerIntent=nil
    if not intent or intent.serial~=(r.externalSerial or 0) or not r.collecting or not r.journal or not r.present then return end
    if self:Check(r) then return end
    local parent=r.frame:GetParent()
    if A:IsSecret(parent) or parent~=r.slot then return end
    for key in pairs(intent.keys) do r.journal:Rebase(r.frame,key,true) end
    r.yielded=nil; r.externalWrites=nil
end

function B:IsNative(frame)
    local c = MinimapCluster
    local candidates = {Minimap, self.toggle, GameTimeFrame, QueueStatusButton, AddonCompartmentFrame,
        Minimap.ZoomIn, Minimap.ZoomOut, c and c.ZoneTextButton, c and c.Tracking,
        c and c.Tracking and c.Tracking.Button, c and c.IndicatorFrame,
        c and c.IndicatorFrame and c.IndicatorFrame.MailFrame, ExpansionLandingPageMinimapButton}
    for _, f in pairs(candidates) do if frame == f then return true end end
    return false
end

function B:Check(r)
    local f = r.frame
    if not A:Accessible(f, false) then return "보호·접근 제한 버튼" end
    for _, name in ipairs({"GetObjectType", "GetWidth", "GetHeight", "GetScale", "GetParent", "GetNumPoints", "GetPoint",
        "GetScript", "SetScript", "SetParent", "SetPoint", "ClearAllPoints", "GetFrameLevel", "GetFrameStrata", "HookScript",
        "HasFixedFrameLevel","HasFixedFrameStrata","SetFixedFrameLevel","SetFixedFrameStrata"}) do
        if type(f[name]) ~= "function" then return "지원하지 않는 버튼 구조" end
    end
    if self:IsNative(f) then return "기본 게임 기능" end
    for _, method in ipairs({"HasAccessConstraints", "IsAnchoringRestricted", "IsAnchoringSecret"}) do
        if f[method] then local v = f[method](f); if A:IsSecret(v) or v then return "접근·앵커 제한 버튼" end end
    end
    local kind = f:GetObjectType()
    if A:IsSecret(kind) or kind ~= "Button" then return "지원하지 않는 프레임 구조" end
    local w, h, scale = f:GetWidth(), f:GetHeight(), f:GetScale()
    local epsilon = A.geometryEpsilon
    if not (A:Number(w) and A:Number(h) and A:Number(scale)) or
        math.min(w,h) < 16-epsilon or math.max(w,h) > 64+epsilon or math.abs(w-h) > epsilon or scale <= 0 then
        return "확인할 수 없는 버튼 크기"
    end
    local update = f:GetScript("OnUpdate")
    if A:IsSecret(update) or update then return "독자적인 상시 갱신 동작" end
    local moving = f.positionMoving
    if A:IsSecret(moving) or moving then return "원래 버튼을 이동하는 중" end
    if r.kind == "lib" then
        local hover = f.showOnMouseover
        if A:IsSecret(hover) or hover then return "원래 애드온의 마우스 오버 숨김 사용 중" end
    end
    if not r.journal then
        local parent = f:GetParent()
        if A:IsSecret(parent) or (parent ~= Minimap and parent ~= MinimapBackdrop and
            parent ~= (MinimapCluster and MinimapCluster.MinimapContainer)) then return "다른 컨테이너가 관리 중" end
    end
    if not A:Read(f, A.get.points) then return "원래 위치 확인 불가" end
end

function B:Discover()
    for _, r in pairs(self.records) do r.present = false end
    local stub = LibStub
    local lib = not A:IsSecret(stub) and type(stub) == "table" and type(stub.GetLibrary) == "function" and
        stub:GetLibrary("LibDBIcon-1.0", true)
    if not A:IsSecret(lib) and type(lib) == "table" and type(lib.GetButtonList) == "function" and type(lib.GetMinimapButton) == "function" then
        if self.lib ~= lib then
            self.lib = lib
            if lib.RegisterCallback then lib.RegisterCallback(self, "LibDBIcon_IconCreated", function() A:Request(true) end) end
        end
        local names = lib:GetButtonList()
        if not A:IsSecret(names) and type(names) == "table" then
            for _, name in ipairs(names) do
                if not A:IsSecret(name) and type(name) == "string" then
                    self:Remember("lib:" .. name, name, lib:GetMinimapButton(name), "lib")
                end
            end
        end
    end
    for _, item in ipairs(custom) do
        local frame = _G[item[1]]
        if not A:IsSecret(frame) and frame then self:Remember("custom:" .. item[1], item[2], frame, "custom") end
    end
    self:WatchOwners(self.lib)
    self:DiscoverCompartment()
    self.ordered = {}
    for _, r in pairs(self.records) do self.ordered[#self.ordered + 1] = r end
    table.sort(self.ordered, function(a, b) return a.id < b.id end)
end

local function PlainLabel(text)
    if A:IsSecret(text) or type(text)~="string" then return end
    return text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a",""):gsub("^%s+",""):gsub("%s+$","")
end

function B:DiscoverCompartment()
    local source=AddonCompartmentFrame
    self.compartmentReady=false
    if not A:Accessible(source,true) then return end
    if not self.compartmentHooked then
        self.compartmentHooked=true
        for _, method in ipairs({"RegisterAddon","UpdateDisplay"}) do
            if type(source[method])=="function" then hooksecurefunc(source,method,function() A:Request(true) end) end
        end
    end
    local entries=source.registeredAddons
    if A:IsSecret(entries) or type(entries)~="table" or getmetatable(entries) or #entries>500 then return end
    self.compartmentReady=true
    local occurrences={}
    for _, data in ipairs(entries) do
        if A:IsSecret(data) or type(data)~="table" or getmetatable(data) then self.compartmentReady=false
        else
            local label=PlainLabel(data.text)
            if not label or label=="" or A:IsSecret(data.func) or type(data.func)~="function" then self.compartmentReady=false
            else
                local canonical=label:lower():gsub("[%s_%-]","")
                local represented=false
                for _, record in pairs(self.records) do
                    if record.present and record.kind~="compartment" and A:Accessible(record.frame,false) then
                        local f=record.frame
                        local shown=f:IsShown()
                        local realLabel=PlainLabel(record.label)
                        local registered=f.compartmentData
                        if not A:IsSecret(shown) and shown and ((not A:IsSecret(registered) and registered==data) or
                            (realLabel and realLabel:lower():gsub("[%s_%-]","")==canonical)) then represented=true; break end
                    end
                end
                if not represented then
                    occurrences[canonical]=(occurrences[canonical] or 0)+1
                    local id="compartment:" .. canonical .. (occurrences[canonical]>1 and ("#" .. occurrences[canonical]) or "")
                    local r=self.records[id]
                    if not r then
                        r={id=id,label=label,kind="compartment"}; self.records[id]=r
                        local f=CreateFrame("Button",nil,Minimap); f:SetSize(32,32); f:SetPoint("CENTER",Minimap,"CENTER",0,0)
                        f:RegisterForClicks("AnyUp"); f:Hide(); r.frame=f
                        local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.12,0.13,0.16,1)
                        r.icon=f:CreateTexture(nil,"ARTWORK"); r.icon:SetPoint("TOPLEFT",3,-3); r.icon:SetPoint("BOTTOMRIGHT",-3,3)
                        f:SetScript("OnClick",function(frame,button)
                            if InCombatLockdown() then
                                A.messages.drawer="애드온 메뉴 실행은 전투가 끝난 뒤 다시 클릭하세요."; A:RefreshSettings(); return
                            end
                            local callback=r.data and r.data.func
                            if r.present and r.collecting and not A:IsSecret(callback) and type(callback)=="function" then
                                callback(r.data,{buttonName=button},frame)
                            end
                        end)
                        f:SetScript("OnEnter",function(frame)
                            local callback=r.data and r.data.funcOnEnter
                            if not InCombatLockdown() and not A:IsSecret(callback) and type(callback)=="function" then
                                r.entered=r.data; callback(frame,r.data)
                            else GameTooltip:SetOwner(frame,"ANCHOR_RIGHT"); GameTooltip:SetText(r.label); GameTooltip:Show() end
                        end)
                        f:SetScript("OnLeave",function(frame)
                            local callback=r.entered and r.entered.funcOnLeave
                            if not InCombatLockdown() and not A:IsSecret(callback) and type(callback)=="function" then callback(frame,r.entered) end
                            r.entered=nil; GameTooltip:Hide()
                        end)
                    end
                    r.data,r.label,r.present=data,label,true
                    local icon=data.icon
                    if A:IsSecret(icon) or (type(icon)~="string" and type(icon)~="number") then icon="Interface\\Icons\\INV_Misc_QuestionMark" end
                    if type(icon)=="string" and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(icon) then r.icon:SetAtlas(icon)
                    else r.icon:SetTexture(icon) end
                end
            end
        end
    end
end

function B:ParkCompartment(enabled)
    if enabled and self.compartmentReady and A:CanAnchor(AddonCompartmentFrame) then
        if not self.compartmentJournal then self.compartmentJournal=A:NewJournal() end
        local frame=AddonCompartmentFrame
        local level=A:Read(frame,A.get.level)
        local j=self.compartmentJournal
        if level and j:Capture(frame,"level") and j:Set(frame,"parent",self.hidden) and j:Set(frame,"level",level[1]) then return end
        A.messages.drawer="애드온 모음 버튼의 접근·복원 상태를 확인하세요."
    end
    if self.compartmentJournal and self.compartmentJournal:Restore() then self.compartmentJournal=nil end
end

function B:Remember(id, label, frame, kind)
    if A:IsSecret(frame) or not frame then return end
    local r = self.records[id]
    if not r then r = {id = id, label = label}; self.records[id] = r end
    if r.frame and r.frame ~= frame and r.journal then
        if not self:ReleaseRecord(r) then return end
    end
    r.frame, r.kind, r.present = frame, kind, true
end

function B:Watch(r)
    local f = r.frame
    if self.hooks[f] then self.hooks[f].record = r; return end
    local watch = {record = r}; self.hooks[f] = watch
    local function Changed(operation)
        local current = watch.record
        if A.writing == 0 and current.collecting then
            current.externalSerial=(current.externalSerial or 0)+1
            current.externalWrites=current.externalWrites or {};current.externalWrites[operation]=current.externalSerial
            local key=operation=="SetFixedFrameLevel" and "fixedLevel" or operation=="SetFixedFrameStrata" and "fixedStrata"
            local entry=key and current.journal and current.journal.byFrame[f] and current.journal.byFrame[f][key]
            if entry then entry.lost=true end
            current.yielded = true
            A:Request()
        end
    end
    for _, method in ipairs({"SetPoint", "ClearAllPoints", "SetParent", "SetScale", "SetSize", "SetWidth", "SetHeight",
        "SetFrameStrata", "SetFrameLevel", "SetFixedFrameLevel", "SetFixedFrameStrata"}) do
        local operation=method
        hooksecurefunc(f, method, function() Changed(operation) end)
    end
    hooksecurefunc(f, "SetScript", function(_, script)
        if not A:IsSecret(script) and (script == "OnDragStart" or script == "OnDragStop" or script == "OnUpdate") then Changed("SetScript:" .. script) end
    end)
    local function VisibilityChanged()
        if watch.record.collecting and A.writing == 0 and self.open and not self.layingOut then A:Request() end
    end
    -- Show/Hide intent may change while a slot's parent is hidden, in which
    -- case an OnShow/OnHide visibility notification need not fire.
    for _, method in ipairs({"Show", "Hide", "SetShown"}) do hooksecurefunc(f, method, VisibilityChanged) end
    for _, script in ipairs({"OnShow", "OnHide"}) do f:HookScript(script, VisibilityChanged) end
end

function B:ReleaseRecord(r)
    r.collecting = false
    r.ownerIntent=nil; r.externalWrites=nil
    if r.journal and not r.journal:Restore() then r.status = "접근 가능 시 복원 대기"; return false end
    r.journal = nil
    if r.kind=="compartment" then r.frame:Hide() end
    if r.slot then r.slot:Hide() end
    return true
end

function B:Collect(r)
    if not r.slot then r.slot = CreateFrame("Frame", nil, self.drawer); r.slot:Hide() end
    if not r.journal then r.journal = A:NewJournal() end
    local f, j = r.frame, r.journal
    -- Reverse restore order: parent first, then anchors/scale/strata/level.
    for _, key in ipairs({"fixedLevel", "fixedStrata", "level", "strata", "scale", "points", "parent"}) do
        if not j:Capture(f, key) then r.yielded = true; self:ReleaseRecord(r); return false end
    end
    local function Script(name)
        return j:Write(f, name, function(frame) return A:Pack(frame:GetScript(name)) end,
            function(frame, value) frame:SetScript(name, value) end, nil)
    end
    local layer=self.drawer:GetFrameLevel()+3
    local ok = j:Set(f,"fixedLevel",false) and j:Set(f,"fixedStrata",false) and
        j:Set(f, "parent", r.slot) and Script("OnDragStart") and Script("OnDragStop") and
        j:Set(f, "points", 1, "CENTER", r.slot, "CENTER", 0, 0) and
        j:Set(f, "strata", "MEDIUM") and j:Set(f, "level", layer)
    if ok and (f:GetFrameLevel()~=layer or f:GetFrameStrata()~="MEDIUM") then ok=false end
    if not ok then r.yielded = true; self:ReleaseRecord(r); return false end
    self:Watch(r)
    r.collecting = true
    if r.kind=="compartment" then
        A.writing=A.writing+1; f:Show(); A.writing=A.writing-1
    end
    r.status = "수납 중"
    return true
end

function B:Refresh()
    for _, r in pairs(self.records) do r.yielded = nil end
    A:Request(true)
end

function B:Apply()
    A.messages.drawer = nil
    if not self.drawer then A.messages.drawer = "미니맵 수납함을 만들 수 없어 보류합니다."; return end
    local conflict = A:FindConflict(conflicts) or A:EnhanceConflict({"enableMinimapButtonBin", "minimapButtonsMouseover"})
    local enabled = A.enabled and A.db.drawer and not conflict and not A.editing
    if conflict then A.messages.drawer = conflict .. " 감지: 버튼 수납을 보류합니다." end
    for _, r in ipairs(self.ordered) do
        self:RecoverOwner(r)
        local reason
        if r.present then reason = self:Check(r) else reason = "현재 버튼 없음" end
        if r.yielded then reason = "외부 변경 감지 · 새로고침으로 재확인" end
        r.lastReason=reason or "eligible"
        if not enabled or A.db.excluded[r.id] or reason then
            if self:ReleaseRecord(r) then
                r.status = reason or (A.db.excluded[r.id] and "수납 제외" or "수납 기능 꺼짐 / 편집 중")
            end
        else self:Collect(r) end
    end
    self:ParkCompartment(enabled)
    if not enabled then
        self:StopDrag(); self.open = false; self.toggle:Hide(); self.drawer:Hide()
        return
    end
    if self:PositionToggle() then self.toggle:Show() end
    self:Layout()
end

function B:Layout()
    if InCombatLockdown() or not self.drawer then A:Request(); return end
    local w, h = A.Minimap:Bounds()
    if not w then return end
    local visible = {}
    for _, r in ipairs(self.ordered) do
        if r.collecting and A:Accessible(r.frame, false) then
            local shown = r.frame:IsShown()
            if not A:IsSecret(shown) and shown then visible[#visible + 1] = r
            else r.status = "원래 애드온에서 숨김" end
        end
    end
    local size, gap, pad = A.db.iconSize, 8, 10
    local maxCols=math.max(1,math.floor((w-2*pad-16)/(size+gap)))
    local vertical=A.db.drawerLayout=="VERTICAL"
    local cols = math.min(6,maxCols)
    local maxRows = math.max(1, math.floor((h - 2*pad - 40) / (size + gap)))
    local baseRows=math.min(6,maxRows)
    local capacity = vertical and maxCols*baseRows or cols*maxRows
    local pages = math.max(1, math.ceil(#visible / capacity))
    self.page = A:Clamp(self.page, 1, pages)
    local count = math.min(capacity, math.max(0, #visible - (self.page - 1) * capacity))
    local rows
    if vertical then rows=math.max(1,math.min(baseRows,count));cols=math.max(1,math.ceil(count/rows))
    else cols=math.max(1,math.min(cols,count));rows=math.max(1,math.ceil(count/cols)) end
    local footer = pages > 1 and 26 or 0
    local dw, dh = 2*pad + cols*(size+gap)-gap, 2*pad + rows*(size+gap)-gap + footer
    if count == 0 then dw, dh = math.min(260, w - 16), 72 end
    self.drawer:SetSize(dw, dh)
    local tx, ty = self.toggle:GetCenter()
    local ts, us = self.toggle:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not (A:Number(tx) and A:Number(ty) and A:Number(ts) and A:Number(us) and us > 0) then return end
    if self.toggleCenterUI then tx,ty=self.toggleCenterUI.x,self.toggleCenterUI.y
    else tx, ty = tx * ts/us, ty * ts/us end
    local direction=A.db.drawerDirection
    local x,y=tx+20,ty-dh/2
    if direction=="LEFT" then x=tx-20-dw
    elseif direction=="UP" then x,y=tx-dw/2,ty+20
    elseif direction=="DOWN" then x,y=tx-dw/2,ty-20-dh end
    x, y = A:Clamp(x, 8, math.max(8, w-dw-8)), A:Clamp(y, 8, math.max(8, h-dh-8))
    self.drawer:ClearAllPoints(); self.drawer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    local onPage = {}
    for index = 1, count do
        local r = visible[(self.page - 1) * capacity + index]
        local col,row
        if vertical then col,row=math.floor((index-1)/rows),(index-1)%rows
        else col,row=(index-1)%cols,math.floor((index-1)/cols) end
        r.slot:SetSize(size, size); r.slot:ClearAllPoints()
        r.slot:SetPoint("TOPLEFT", self.drawer, "TOPLEFT", pad + col*(size+gap), -pad - row*(size+gap))
        local width = r.frame:GetWidth()
        if A:Number(width) and width > 0 and r.journal:Set(r.frame, "scale", size / width) then
            onPage[r] = true
        else r.yielded = true; A:Request() end
    end
    self.prev:SetShown(pages > 1); self.next:SetShown(pages > 1); self.pageText:SetShown(pages > 1)
    self.prev:SetEnabled(self.page > 1); self.next:SetEnabled(self.page < pages)
    self.pageText:SetText(self.page .. " / " .. pages)
    self.empty:SetShown(count == 0)
    self.toggleText:SetText("")
    self.layingOut = true
    for _, r in ipairs(self.ordered) do if r.slot then r.slot:SetShown(onPage[r] == true) end end
    self.drawer:SetShown(self.open == true)
    self.layingOut = nil
    self.lastLayout = {x=x,y=y,width=dw,height=dh,pages=pages,count=#visible,direction=direction,layout=A.db.drawerLayout,columns=cols,rows=rows,capacity=capacity}
end
