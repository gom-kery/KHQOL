local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.range=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local fr=m.range
  if fr.db then add("range","range","Range · 사거리",fr.Display.frame,pointWriter(fr.db),lock(fr.db),function() fr.Display:ApplyLayout(true) end,{sample=fr.db.shape,sampleSize=fr.db.size,bounds=function(x,y) local w,h=fr.Display.frame:GetSize();return x,y,math.max(16,w),math.max(16,h) end}) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.range.db end,m.range.defaults)
  end)
  return list
end
local rangeBase=KHQOL.PositionProviders.range
KHQOL.PositionProviders.range=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local list={}
  local function sample(...) return PU:Sample(list,...) end
  local cx,cy=call(UIParent.GetCenter,UIParent)
  if not finite(cx) or not finite(cy) then return list end
  local tooltip=m.tooltip and m.tooltip:GetDB() or {}
  local tx,ty,tw,th=cx+18+(tooltip.x or 0),cy+(tooltip.y or 0),250,90
  if not tooltip.mouseRight or not self:CanRunModule("tooltip") then tx,ty=cx+18,cy end
  local range=m.range;local d=range.db and range.db.mouseover
  if d and d.enabled then
    local w,h=math.max(90,(d.fontSize or 14)*6), (d.fontSize or 14)+6
    local x,y=d.position=="LEFT" and tx+(d.x or 0)-w/2 or tx+(d.x or 0)+w/2,
      d.position=="LEFT" and ty+th/2+(d.y or 0) or ty+(d.y or 0)-h/2
    local parentID=tooltip.mouseRight and self:CanRunModule("tooltip") and "tooltip.position" or nil
    local resetX,resetY=x-(d.x or 0),y-(d.y or 0)
    if parentID then resetX=resetX-(tx+tw/2);resetY=resetY-(ty+th/2) end
    sample("range.mouseover","range","사거리 · 마우스오버 문구",x,y,w,h,function(dx,dy)
      d.x=math.max(-100,math.min(200,self.PositionStore:Round((d.x or 0)+dx)));d.y=math.max(-100,math.min(100,self.PositionStore:Round((d.y or 0)+dy)))
    end,function() range.Mouseover:Update() end,{parentID=parentID,
      sample=d.availableText or "공격 가능",sampleSize=d.fontSize or 14,
      resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=resetX,y=resetY},resetPhysical=true,
      resetWrite=function() d.x=0;d.y=0 end})
  end
  for _,target in ipairs(rangeBase(focus)) do list[#list+1]=target end
  return list
end
