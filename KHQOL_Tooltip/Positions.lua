local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.tooltip=function()
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local list={}
  local function sample(...) return PU:Sample(list,...) end
  local cx,cy=call(UIParent.GetCenter,UIParent)
  if not finite(cx) or not finite(cy) then return list end
  local tooltip=m.tooltip:GetDB();local tx,ty,tw,th= cx+18+(tooltip.x or 0),cy+(tooltip.y or 0),250,90
  if tooltip.mouseRight and self:CanRunModule("tooltip") then
    sample("tooltip.position","tooltip","툴팁 · 고정 커서 기준",tx+tw/2,ty+th/2,tw,th,function(dx,dy)
      tooltip.x=math.max(-150,math.min(150,self.PositionStore:Round((tooltip.x or 0)+dx)));tooltip.y=math.max(-150,math.min(150,self.PositionStore:Round((tooltip.y or 0)+dy)))
    end,nil,{resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx+18+tw/2,y=cy+th/2},resetPhysical=true,
      resetWrite=function() tooltip.x=0;tooltip.y=0 end,sample="커서 오른쪽 툴팁\n커서 기준 위치 예시"})
  end
  return list
end
