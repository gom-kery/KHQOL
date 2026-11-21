local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
KHQOL.PositionProviders.range=function(focus)
  local self=KHQOL
  local m=self.modules
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local fr=m.range
  if fr.db then
    if fr.db.displayMode=="distance" then
      local cfg=fr.db.distance
      local frame=PU:Preview("range.distance",{point="CENTER",relativePoint="CENTER",x=cfg.x,y=cfg.y},400,fr.Distance:FrameHeight(cfg.size))
      add("range.distance","range","사거리 · 대상 거리",frame,pointWriter(cfg),lock(cfg),function() fr.Display:ApplyLayout(true) end,
        {sample=fr.Distance:Format({kind="range",lower=8,upper=15}),sampleSize=cfg.size,
          settingsRoute={module="range",section="대상 거리"}})
    else
      add("range","range","Range · 사거리",fr.Display.frame,pointWriter(fr.db),lock(fr.db),function() fr.Display:ApplyLayout(true) end,{sample=fr.db.shape,sampleSize=fr.db.size,bounds=function(x,y) local w,h=fr.Display.frame:GetSize();return x,y,math.max(16,w),math.max(16,h) end})
    end
  end
  PU:ConfigureResets(list,function(t,point)
    if t.id=="range.distance" then point(t,function() return m.range.db.distance end,m.range.defaults.distance)
    else point(t,function() return m.range.db end,m.range.defaults) end
  end)
  return list
end
