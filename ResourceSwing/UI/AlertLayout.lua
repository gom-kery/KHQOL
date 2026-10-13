local _, KHQOL = ...
-- A bounded set of KHQOL transient alerts; no polling, global frame traversal,
-- queue or saved-coordinate changes. Lower-priority overlaps move temporarily.
local L={entries={}}
KHQOL.AlertLayout=L
local function restore(e)
  if not e.home then return end
  e.frame:ClearAllPoints();e.frame:SetPoint(unpack(e.home))
end
function L:Reflow()
  if self.applying then return end
  self.applying=true
  for _,e in ipairs(self.entries) do restore(e) end
  if not self.suspended then
    local occupied={}
    for _,e in ipairs(self.entries) do
      local f=e.frame
      if f:IsVisible() and (not e.allowed or e.allowed()) then
        local x,y,scale=KHQOL.PositionStore:Center(f)
        if x then
          local w,h=f:GetSize();w,h=w*scale,h*scale
          local original=y
          -- At most N comparisons per placement; different alerts stay visible.
          for _=1,#self.entries do
            local collision
            for _,r in ipairs(occupied) do
              if math.abs(x-r.x)<(w+r.w)/2+8 and math.abs(y-r.y)<(h+r.h)/2+8 then
                y=r.y-(r.h+h)/2-12;collision=true;break
              end
            end
            if not collision then break end
          end
          if y~=original then
            if y-h/2<8 then y=math.min(UIParent:GetHeight()-h/2-8,original+h+12) end
            f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
          end
          occupied[#occupied+1]={x=x,y=y,w=w,h=h}
        end
      end
    end
  end
  self.applying=nil
end
function L:Suspend(on) self.suspended=on and true or false;self:Reflow() end
function L:Register(frame,priority,allowed)
  if not KHQOL.PositionStore:Safe(frame) or frame.khqolAlertLayout then return end
  local e={frame=frame,priority=priority,allowed=allowed,home={frame:GetPoint(1)}}
  frame.khqolAlertLayout=e;self.entries[#self.entries+1]=e
  table.sort(self.entries,function(a,b) return a.priority>b.priority end)
  if frame.HookScript then
    frame:HookScript("OnShow",function() L:Reflow() end)
    frame:HookScript("OnHide",function() L:Reflow() end)
  elseif hooksecurefunc then
    hooksecurefunc(frame,"Show",function() L:Reflow() end)
    hooksecurefunc(frame,"Hide",function() L:Reflow() end)
  end
  if hooksecurefunc then hooksecurefunc(frame,"SetPoint",function()
    if not L.applying then e.home={frame:GetPoint(1)};L:Reflow() end
  end) end
end
function L:Initialize()
  local m=KHQOL.modules
  if m.environmentTimer.warning then self:Register(m.environmentTimer.warning,100) end
  if m.npcAlert.banner then self:Register(m.npcAlert.banner,90) end
  if m.pvpAlert.frame then self:Register(m.pvpAlert.frame,80,function() return not m.pvpAlert.moving end) end
  if m.threat.root then self:Register(m.threat.root,70,function() return m.threat.db.locked and not m.threat.testing end) end
  if m.campfire.ui then
    self:Register(m.campfire.ui.root,50,function() return m.campfire.db.locked and m.campfire.ui.discovery:IsVisible() end)
    self:Register(m.campfire.ui.complete,45,function() return m.campfire.db.locked end)
  end
  if m.combatStatus.root then self:Register(m.combatStatus.root,30,function() return m.combatStatus.db.locked end) end
  if m.clock.alertMessageFrame then self:Register(m.clock.alertMessageFrame,20,function() return not m.clock.alertMessageFrame.isTest end) end
  self:Reflow()
end
local events=CreateFrame("Frame");events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(self)
  self:UnregisterAllEvents()
  if C_Timer and C_Timer.After then C_Timer.After(0,function() L:Initialize() end) else L:Initialize() end
end)
