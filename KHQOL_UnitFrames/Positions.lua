local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
KHQOL.PositionProviders.castBar=function(focus)
  local self=KHQOL
  local m=self.modules
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local cb=m.castBar
  if cb.db then
    local t=cb:TargetPositionPreview()
    if t then add(t.id,"castBar",t.name,t.frame,t.write,nil,t.apply,t) end
    local linked=cb.linked and true or false
    add("cast","castBar","Cast Bar"..(linked and " · 자원바 연결" or " · 자유 위치"),cb.frame,not linked and pointWriter(cb.db.position.free) or nil,lock(cb.db.position),function() cb:ApplyLayout() end,{parentID=linked and "resource" or nil,linked=linked,sample="주문 시전 · 2.0초"})
  end
  PU:ConfigureResets(list,function(t,point)
    if t.id=="cast" and not t.linked then point(t,function() return m.castBar.db.position.free end,m.castBar.defaults.position.free) end
  end)
  return list
end
KHQOL.PositionProviders.frameMover=function()
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local list={}
  local function sample(...) return PU:Sample(list,...) end
  local cx,cy=call(UIParent.GetCenter,UIParent)
  if not finite(cx) or not finite(cy) then return list end
  local mover=m.frameMover;local db=mover:GetDB()
  if db.enabled then
    local titles={Map="지도",Character="캐릭터창",Talents="특성",Spellbook="마법책",Macro="매크로창"}
    for _,key in ipairs({"Map","Character","Talents","Spellbook","Macro"}) do
      local k=key;local entry=mover.registry[k];local native=_G[entry.name];local x,y,w,h=rect(native)
      local originalX,originalY=x or cx,y or cy
      local saved=db.positions[k]
      if saved then x,y=saved.x,saved.y end
      x,y,w,h=x or cx,y or cy,w or 380,h or 270
      local record=native and mover.byFrame[native]
      if record and record.original then
        local readable=true
        for _,point in ipairs(record.original) do for i=1,5 do if not KHQOL.IsPublicValue(point[i]) then readable=false end end end
        if readable then
          local reset=E:Virtual("basicUI.reset."..k,{x=0,y=0},call(native.GetWidth,native) or 380,call(native.GetHeight,native) or 270)
          local scale=call(native.GetEffectiveScale,native);local ps=call(UIParent.GetEffectiveScale,UIParent)
          if finite(scale) and finite(ps) and ps>0 then
            local ok=pcall(function() reset:SetScale(scale/ps);reset:ClearAllPoints();for _,point in ipairs(record.original) do reset:SetPoint(unpack(point)) end end)
            if ok then local ox,oy=rect(reset);if ox then originalX,originalY=ox,oy end end
          end
        end
      end
      local t=sample("basicUI."..k,nil,"기본창 · "..titles[k],x,y,w,h,nil,function() mover:Refresh() end,{settingsKey="basicUI",sample="기본창 · "..titles[k].."\n닫힌 창도 위치 예시로 이동",resetPhysical=true,
        resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=originalX,y=originalY},
        resetWrite=function() db.positions[k]=nil;if record then mover:Restore(record) end end})
      t.write=function()
        local hx,hy=call(t.handle.GetCenter,t.handle)
        if finite(hx) and finite(hy) then db.positions[k]={point="CENTER",relativePoint="BOTTOMLEFT",x=self.PositionStore:Round(hx),y=self.PositionStore:Round(hy)} end
      end
    end
  end
  return list
end
