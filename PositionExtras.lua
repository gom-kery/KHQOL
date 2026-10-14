local _,KHQOL=...
local call=KHQOL.PublicCall
local function finite(v) return KHQOL.IsPublicValue(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
local function rect(f)
  if not f then return end
  local x,y=call(f.GetCenter,f);local w,h=call(f.GetSize,f);local s=call(f.GetEffectiveScale,f);local ps=call(UIParent.GetEffectiveScale,UIParent)
  if not finite(x) or not finite(y) or not finite(w) or w<=0 or not finite(h) or h<=0 or not finite(s) or s<=0 or not finite(ps) or ps<=0 then return end
  return x*s/ps,y*s/ps,w*s/ps,h*s/ps,s/ps
end
function KHQOL:ExtraPositionTargets()
  local E,m=self.PositionEditor,self.modules;local list={}
  local function sample(id,key,name,x,y,w,h,write,apply,extra)
    if key and not self:CanRunModule(key) then return end
    local f=E:Virtual(id,{point="CENTER",relativePoint="BOTTOMLEFT",x=x,y=y},w,h)
    local t=extra or {};t.id=id;t.key=key;t.name=name;t.frame=f;t.write=write;t.apply=apply;t.sample=t.sample or name.." · 위치 예시"
    list[#list+1]=t;return t
  end
  local cx,cy=call(UIParent.GetCenter,UIParent);if not finite(cx) or not finite(cy) then return list end
  local tooltip=m.tooltip:GetDB();local tx,ty,tw,th= cx+18+(tooltip.x or 0),cy+(tooltip.y or 0),250,90
  if tooltip.mouseRight and self:CanRunModule("tooltip") then
    sample("tooltip.position","tooltip","툴팁 · 고정 커서 기준",tx+tw/2,ty+th/2,tw,th,function(dx,dy)
      tooltip.x=math.max(-150,math.min(150,self.PositionStore:Round((tooltip.x or 0)+dx)));tooltip.y=math.max(-150,math.min(150,self.PositionStore:Round((tooltip.y or 0)+dy)))
    end,nil,{resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx+18+tw/2,y=cy+th/2},resetPhysical=true,
      resetWrite=function() tooltip.x=0;tooltip.y=0 end,sample="커서 오른쪽 툴팁\n커서 기준 위치 예시"})
  else tx,ty=cx+18,cy end
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
  local settings=self.settings;local x,y,w,h=rect(settings)
  if x then
    sample("settings.window",nil,"KHQOL 설정창",x,y,w,h,function(dx,dy)
      KHQOL.db.toolWindows=KHQOL.db.toolWindows or {};local positions=KHQOL.db.toolWindows
      local p=positions.settings or {x=x-cx,y=y-cy};positions.settings=p;p.x=self.PositionStore:Round(p.x+dx);p.y=self.PositionStore:Round(p.y+dy)
    end,function() KHQOL.PositionStore:ApplySettingsWindow(settings) end,
    {sample="KHQOL 설정창 · 위치 예시",resetPhysical=true,resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx,y=cy},
      resetWrite=function() KHQOL.db.toolWindows=KHQOL.db.toolWindows or {};KHQOL.db.toolWindows.settings={x=0,y=0} end})
  end
  return list
end
