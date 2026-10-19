local K = assert(_G.KHQOL)
local M = K.modules.unitFrames
local call, api, finite = K.PublicCall, K.ReadPublicAPI, K.IsPublicNumber
local names = {player="플레이어", target="대상", pet="소환수", targettarget="대상의 대상", focus="주시대상"}
local function combat() return call(InCombatLockdown) ~= false end
local function editing() return call(EditModeManagerFrame and EditModeManagerFrame.IsShown, EditModeManagerFrame) == true end
local function allowed(root)
    return root and (not root.IsForbidden or call(root.IsForbidden, root) == false)
end
local function points(root)
    if not allowed(root) then return end
    local n = call(root.GetNumPoints, root)
    if not finite(n) or n < 0 or n > 32 or n ~= math.floor(n) then return end
    local out = {}
    for i=1,n do
        local status, point, relative, relativePoint, x, y = api(root.GetPoint, root, i)
        if status ~= "ok" or type(point) ~= "string" or type(relativePoint) ~= "string" or not finite(x) or not finite(y) then return end
        out[i] = {point, relative, relativePoint, x, y}
    end
    return out
end
local function same(a, b)
    if not a or not b or #a ~= #b then return false end
    for i=1,#a do for j=1,5 do if a[i][j] ~= b[i][j] then return false end end end
    return true
end
-- Use the native anchor primitives when EditMode has decorated SetPoint.
-- Its snap/layout metadata and saved layouts remain owned by the game.
local function put(root, value)
    local clear, set = root.ClearAllPointsBase or root.ClearAllPoints, root.SetPointBase or root.SetPoint
    if type(clear) ~= "function" or type(set) ~= "function" then return false end
    M.writingRootPosition = true
    local ok = pcall(function()
        clear(root)
        for _, p in ipairs(value) do set(root, unpack(p)) end
    end)
    M.writingRootPosition = nil
    return ok
end
local function deferred() M.pending=true; M.propertyDeferred=true end
function M:HasRootPosition(unit)
    local d = self:GetDB()[unit]
    local p = d and d.rootPosition
    return type(p) == "table" and p.enabled == true and finite(p.x) and finite(p.y) and math.abs(p.x) <= 20000 and math.abs(p.y) <= 20000
end
function M:ReleaseRootPosition(owner)
    local record = owner.rootPositionOwner
    if not record then return true end
    if combat() then deferred(); return false end
    local current = points(record.root)
    if not current then deferred(); return false end
    if same(current, record.last) and not put(record.root, record.original) then deferred(); return false end
    owner.rootPositionOwner = nil
    return true
end
function M:CancelRootPositionQueue()
    local work = self.rootPositionQueued
    if work then
        self.rootPositionQueued = nil
        if work.timer then work.timer:Cancel() end
        K.ModuleRegistry:Release("unitFrames", work)
    end
end
function M:QueueRootPositions()
    if self.writingRootPosition or self.applyingUnits or self.rootPositionQueued then return end
    local needed = false
    for _,unit in ipairs(self.unitTokens) do
        local owner = self.units and self.units[unit]
        if self:IsEnabled() and self:GetDB()[unit].compact and self:HasRootPosition(unit) or owner and owner.rootPositionOwner then needed=true; break end
    end
    if not needed then return end
    if combat() then deferred(); return end
    local work = {generation=K.profileGeneration}
    self.rootPositionQueued = work
    K.ModuleRegistry:Own("unitFrames", work, function() M:CancelRootPositionQueue() end)
    local function run()
        if M.rootPositionQueued ~= work then return end
        M.rootPositionQueued = nil; K.ModuleRegistry:Release("unitFrames", work)
        if work.generation ~= K.profileGeneration then return end
        for _,unit in ipairs(M.unitTokens) do
            local owner = M.units and M.units[unit]
            local p = M:UnitParts(unit)
            if owner and p then M:ApplyRootPosition(owner, p, unit)
            elseif owner and (not M:IsEnabled() or not M:GetDB()[unit].compact or editing()) then M:ReleaseRootPosition(owner) end
        end
    end
    if C_Timer and C_Timer.NewTimer then work.timer=C_Timer.NewTimer(0, run)
    elseif C_Timer and C_Timer.After then C_Timer.After(0, run)
    else run() end
end
function M:HookRootPosition(root)
    self.rootPositionHooks = self.rootPositionHooks or setmetatable({}, {__mode="k"})
    local hooks = self.rootPositionHooks[root]
    if not hooks then hooks={}; self.rootPositionHooks[root]=hooks end
    for _,method in ipairs({"SetPoint", "ClearAllPoints", "SetPointBase", "ClearAllPointsBase", "ApplySystemAnchor", "SetScale", "SetSize", "SetWidth", "SetHeight"}) do
        if type(root[method]) == "function" and hooks[method] ~= root[method] then
            hooksecurefunc(root, method, function() M:QueueRootPositions() end)
            hooks[method]=root[method]
        end
    end
end
function M:ApplyRootPosition(owner, p, unit)
    if self.writingRootPosition then return end
    self:HookRootPosition(p.root)
    if combat() then
        if owner.rootPositionOwner or self:HasRootPosition(unit) then deferred() end
        return
    end
    if owner.rootPositionOwner and owner.rootPositionOwner.root ~= p.root and not self:ReleaseRootPosition(owner) then return end
    local active = self:IsEnabled() and self:GetDB()[unit].compact and not editing() and self:HasRootPosition(unit)
    if not active then
        self:ReleaseRootPosition(owner)
        -- Retain old target-of-target offsets until an explicit new placement.
        if unit == "targettarget" and not self:HasRootPosition(unit) then self:ApplyFramePosition(owner, p) end
        return
    end
    if owner.positionOwner then self:Release(owner.positionOwner) end
    local current = points(p.root)
    local scale, parentScale = call(p.root.GetEffectiveScale, p.root), call(UIParent.GetEffectiveScale, UIParent)
    if not current or not finite(scale) or scale <= 0 or not finite(parentScale) or parentScale <= 0 then deferred(); return end
    local saved = self:GetDB()[unit].rootPosition
    local value = {{"TOPLEFT", UIParent, "BOTTOMLEFT", saved.x*parentScale/scale, saved.y*parentScale/scale}}
    local record = owner.rootPositionOwner
    if not record then record={root=p.root, original=current}; owner.rootPositionOwner=record
    elseif not same(current, record.last) then record.original=current end
    if not same(current, value) and not put(p.root, value) then deferred(); return end
    record.last = points(p.root) or value
end
function M:ResetRootPosition(unit)
    local d = self:GetDB()[unit]
    d.rootPosition = nil
    if unit == "targettarget" then d.frameX=0; d.frameY=0 end
    self:ApplySettings()
end
function M:OpenUnitPositionEditor(unit)
    return K.PositionEditor:Enter(unit=="targettarget" and "unitFrames.targettarget" or "unitFrames."..(unit or "player")..".root", "unitRoots")
end
local function rect(root)
    if not allowed(root) then return end
    local x,y = call(root.GetCenter, root)
    local w,h = call(root.GetSize, root)
    local s, ps = call(root.GetEffectiveScale, root), call(UIParent.GetEffectiveScale, UIParent)
    if not finite(x) or not finite(y) or not finite(w) or not finite(h) or w<=0 or h<=0 or not finite(s) or s<=0 or not finite(ps) or ps<=0 then return end
    local r=s/ps
    return x*r,y*r,w*r,h*r,r
end
function M:RootEditorTargets()
    if not self:IsEnabled() or combat() or editing() then return {} end
    local list={}
    local cx,cy=call(UIParent.GetCenter,UIParent)
    if not finite(cx) or not finite(cy) then return list end
    for index,unit in ipairs(self.unitTokens) do
        local d=self:GetDB()[unit];local p=self:UnitParts(unit);local root=p and p.root
        local x,y,rw,rh,r=rect(root)
        local movable=d.compact==true
        local width,height,gap,hh,ph,showPower=self:CompactLayout(d)
        local auxiliary=unit=="pet" or unit=="targettarget"
        if not x then
            r=1;rw=width+(auxiliary and 8 or 32);rh=height+(auxiliary and 4 or 48)
            x,y=cx+(index%2==0 and 180 or -180),cy+160-math.floor((index-1)/2)*130
            if self:HasRootPosition(unit) then x=d.rootPosition.x+rw/2;y=d.rootPosition.y-rh/2 end
        end
        local rootX,rootY=x-rw/2,y+rh/2
        local left,top=movable and (auxiliary and 4 or 16)*r or 0,movable and (auxiliary and -16 or -40)*r or 0
        local w,h=movable and width*r or rw,movable and (hh+(showPower and gap+ph or 0))*r or rh
        local vx,vy=rootX+left+w/2,rootY+top-h/2
        local frame=K.PositionEditor:Virtual("unitRoots."..unit,{point="CENTER",relativePoint="BOTTOMLEFT",x=vx,y=vy},w,h)
        local spec={id=unit=="targettarget" and "unitFrames.targettarget" or "unitFrames."..unit..".root",
            key="unitFrames",name=names[unit].." · 전체 프레임",frame=frame,representative=true,exactBounds=movable,
            linked=not movable,readOnly=not movable,settingsRoute={module="unitFrames",unit=unit,part="basic"},
            sample=names[unit]..(movable and " · 드래그 이동" or " · 간결한 프레임 OFF"),sampleSize=12,
            current=function() local now=M:UnitParts(unit);return M:GetDB()[unit]==d and d.compact==movable and (now and now.root)==root end,
            apply=function() M:ApplySettings() end}
        if movable then
            spec.rootVisual={unit=unit,parts=p,ratio=r,config=d,width=w,health=hh*r,power=ph*r,gap=gap*r,showPower=showPower,left=left,top=top}
            spec.render=function(handle) return M:RenderRootPreview(handle,spec) end
            if allowed(root) then
                spec.suppressAlpha={root}
                spec.inputBlockRect={x=x,y=y,width=rw,height=rh}
                spec.blockOriginal=function() return call(UnitExists,unit)==true and call(root.IsVisible,root)==true end
            end
            spec.write=function(dx,dy)
                local hx,hy
                if spec.handle then hx,hy=call(spec.handle.GetCenter,spec.handle) end
                if not finite(hx) or not finite(hy) then hx,hy=vx+dx,vy+dy end
                -- The visible bar outline has a different origin than the
                -- native unit root. Preserve the existing stored root format.
                d.rootPosition={enabled=true,x=K.PositionStore:Round(hx-w/2-left),y=K.PositionStore:Round(hy+h/2-top)}
                if unit=="targettarget" then d.frameX=0;d.frameY=0 end
            end
            local owner=self.units and self.units[unit]
            local record=owner and owner.rootPositionOwner
            local reset=record and record.original
            local rx,ry=vx,vy
            if reset and root then
                local original=K.PositionEditor:Virtual("unitRoots.reset."..unit,{x=0,y=0},rw/r,rh/r)
                original:SetScale(r);original:ClearAllPoints()
                local ok=pcall(function() for _,point in ipairs(reset) do original:SetPoint(unpack(point)) end end)
                if ok then local ox,oy=rect(original);if ox then rx=ox-rw/2+left+w/2;ry=oy+rh/2+top-h/2 end end
            end
            spec.resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=rx,y=ry};spec.resetPhysical=true
            spec.resetWrite=function() d.rootPosition=nil;if unit=="targettarget" then d.frameX=0;d.frameY=0 end end
        end
        list[#list+1]=spec
    end
    return list
end
