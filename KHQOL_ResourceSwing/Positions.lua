local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
KHQOL.PositionProviders.resourceSwing=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local rs=KHQOLResourceSwingDB
  if rs and rs.enabled~=false then
    add("resource","resourceSwing","Resource Swing · 자원 / 스윙",KHQOLResourceSwingFrame,pointWriter(rs),lock(rs),function() m.resourceSwing:ApplyPosition() end,{bounds=function(x,y,w,h) return m.resourceSwing:GetEditorBounds(x,y,w,h) end})
    if rs.showCombo and rs.comboPosition=="FREE" and select(2,m.resourceSwing:GetComboData()) then
      local combo=m.resourceSwing.comboFrame
      if combo then
        local p={point=rs.comboPoint,relativePoint=rs.comboRelativePoint,x=rs.comboX,y=rs.comboY}
        local preview=combo:IsShown() and combo or E:Virtual("resource.combo",p,combo:GetWidth(),combo:GetHeight())
        add("resource.combo","resourceSwing","Resource Swing · 콤보 포인트",preview,pointWriter(rs,"comboX","comboY"),lock(rs,"comboLocked"),function() m.resourceSwing:ApplyPosition() end,{sample="콤보 포인트",sampleSize=12})
      end
    end
  end
  PU:ConfigureResets(list,function(t,point)
    local d=m.resourceSwing.defaults
    if t.id=="resource" then point(t,function() return KHQOLResourceSwingDB end,d)
    elseif t.id=="resource.combo" then point(t,function() return KHQOLResourceSwingDB end,{point=d.comboPoint,relativePoint=d.comboRelativePoint,x=d.comboX,y=d.comboY},{point="comboPoint",relativePoint="comboRelativePoint",x="comboX",y="comboY"}) end
  end)
  return list
end
