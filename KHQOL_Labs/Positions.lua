local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.buffReminder=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local fbr=_G.ForeverBuffReminder
  if fbr and ForeverBuffReminderDB then
    local db=ForeverBuffReminderDB
    add("buffs","buffReminder","Buff Reminder · 버프 그룹",fbr.anchor,pointWriter(db.position),lock(db),function()
      applyPoint(fbr.anchor,db.position); fbr:SetLocked(true)
    end,{sample="버프 미리보기",sampleY=-20,art={{texture="Interface\\Icons\\Spell_Holy_WordFortitude",width=db.iconSize,height=db.iconSize}},mirror=fbr.alertContainer,suppress={fbr.alertContainer},bounds=function(x,y)
      local size=db.iconSize; local left,bottom,right,top
      for _,frame in ipairs(fbr.alertFrames or {}) do if frame:IsShown() then
        local l,b,w,h=frame:GetRect()
        local ratio=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        if l then l,b,w,h=l*ratio,b*ratio,w*ratio,h*ratio end
        if l then left=math.min(left or l,l); bottom=math.min(bottom or b,b); right=math.max(right or l+w,l+w); top=math.max(top or b+h,b+h) end
      end end
      if left then
        local ax,ay=KHQOL.PositionStore:Center(fbr.anchor)
        return x+(left+right)/2-ax,y+(bottom+top)/2-ay,right-left,top-bottom
      end
      return x+size/2,y-size/2,size,size
    end})
  end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return ForeverBuffReminderDB.position end,ForeverBuffReminder.profileDefaults.position)
  end)
  return list
end
KHQOL.PositionProviders.procAlert=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local proc=m.procAlert
  if proc.db then add("proc","procAlert","발동 버프 · HUD",proc.frame,function(dx,dy)
    proc.db.hud.x=self.PositionStore:Round(proc.db.hud.x+dx*proc.db.hud.scale);proc.db.hud.y=self.PositionStore:Round(proc.db.hud.y+dy*proc.db.hud.scale)
  end,function() proc.unlocked=false;proc.testUntil=nil end,function() proc:Layout();proc:Render() end,{sample="발동 버프 미리보기"}) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.procAlert.db.hud end,m.procAlert.defaults.hud,{x="x",y="y"});t.resetPhysical=true
  end)
  return list
end
KHQOL.PositionProviders.performanceMonitor=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local monitor=m.performanceMonitor
  if monitor.db then add("monitor","performanceMonitor","성능 모니터",monitor.frame,pointWriter(monitor.db),lock(monitor.db,"positionLocked"),function() monitor:ApplyLayout() end) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.performanceMonitor.db end,m.performanceMonitor.defaults,{x="x",y="y"})
  end)
  return list
end
