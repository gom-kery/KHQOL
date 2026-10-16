local _,K=...
local E=K.PositionEditor
local call=K.PublicCall
local function finite(v) return K.IsPublicNumber(v) end
local PU={}
K.PositionUtils=PU
function PU.ApplyPoint(frame,p)
  if not frame or not p then return end
  frame:ClearAllPoints();frame:SetPoint(p.point or "CENTER",UIParent,p.relativePoint or p.point or "CENTER",p.x or 0,p.y or 0)
end
function PU.Rect(f)
  if not f then return end
  local x,y=call(f.GetCenter,f);local w,h=call(f.GetSize,f)
  local s=call(f.GetEffectiveScale,f);local ps=call(UIParent.GetEffectiveScale,UIParent)
  if not finite(x) or not finite(y) or not finite(w) or w<=0 or not finite(h) or h<=0 or not finite(s) or s<=0 or not finite(ps) or ps<=0 then return end
  return x*s/ps,y*s/ps,w*s/ps,h*s/ps,s/ps
end
function PU:Add(list,id,key,name,frame,write,lock,apply,extra)
  if key and not K:CanRunModule(key) then return end
  if key=="buffReminder" and not K.LabLock:IsUnlocked() then return end
  if not frame or key and not K:GetEnabled(key) then return end
  local t=extra or {};t.id=id;t.key=key;t.name=name;t.frame=frame;t.write=write;t.lock=lock;t.apply=apply
  list[#list+1]=t;return t
end
function PU:PointWriter(p,xKey,yKey)
  xKey=xKey or "x";yKey=yKey or "y"
  return function(dx,dy) p[xKey]=K.PositionStore:Round((p[xKey] or 0)+dx);p[yKey]=K.PositionStore:Round((p[yKey] or 0)+dy) end
end
function PU:Lock(db,key) return function() db[key or "locked"]=true end end
function PU:Sample(list,id,key,name,x,y,w,h,write,apply,extra)
  if key and not K:CanRunModule(key) then return end
  local f=E:Virtual(id,{point="CENTER",relativePoint="BOTTOMLEFT",x=x,y=y},w,h)
  local t=extra or {};t.sample=t.sample or name.." · 위치 예시"
  return self:Add(list,id,key,name,f,write,nil,apply,t)
end
function PU:ConfigureResets(list,configure)
  local function point(t,getDB,defaults,fields)
    if not defaults then return end
    fields=fields or {point="point",relativePoint="relativePoint",x="x",y="y"}
    local p={point=defaults.point or "CENTER",relativePoint=defaults.relativePoint or defaults.point or "CENTER",x=defaults.x or 0,y=defaults.y or 0}
    t.resetPoint=p
    t.resetWrite=function() local db=getDB();for k,field in pairs(fields) do if field then db[field]=p[k] end end end
  end
  for _,t in ipairs(list) do configure(t,point) end
end
function E:Virtual(id,p,width,height)
  self.virtuals=self.virtuals or {};local frame=self.virtuals[id]
  if not frame then frame=CreateFrame("Frame",nil,UIParent);frame:Hide();self.virtuals[id]=frame end
  frame:SetSize(width,height);PU.ApplyPoint(frame,p);return frame
end
function K:ApplyEditorPositions()
  for _,id in ipairs(self.ModuleRegistry.order) do
    local spec=self.ModuleRegistry.entries[id]
    if spec.editorPositions then spec.editorPositions(self.modules[id],self) end
  end
end
function K:BuildPositionTargets(focus)
  local list={}
  self.ModuleRegistry:PositionTargets(focus,function(...) PU:Add(list,...) end)
  -- Navigation is a shared core service used by both Quest and ForeverNote.
  local nav=self.NavigationUI
  local key=self:CanRunModule("questNavigator") and "questNavigator" or self:CanRunModule("todo") and "todo"
  if key and nav.root and nav.db then
    local db=nav.db
    local t=PU:Add(list,"quest",key,"퀘스트 / 노트 · 공용 안내 HUD",nav.root,PU:PointWriter(db,"positionX","positionY"),PU:Lock(db),function() nav:ApplyLayout() end,
      {sample="퀘스트 방향 · 120 m",sampleY=-30,art={{texture="Interface\\AddOns\\KHQOL\\Media\\QuestNavigator\\Arrow.tga",width=db.arrowSize,height=db.arrowSize,y=30}}})
    if t then PU:ConfigureResets({t},function(target,point) point(target,function() return nav.db end,{x=0,y=180},{x="positionX",y="positionY"}) end) end
  end
  local settings=self.settings;local x,y,w,h=PU.Rect(settings)
  local cx,cy=call(UIParent.GetCenter,UIParent)
  if x and finite(cx) and finite(cy) then
    PU:Sample(list,"settings.window",nil,"KHQOL 설정창",x,y,w,h,function(dx,dy)
      self.db.toolWindows=self.db.toolWindows or {};local positions=self.db.toolWindows
      local p=positions.settings or {x=x-cx,y=y-cy};positions.settings=p
      p.x=self.PositionStore:Round(p.x+dx);p.y=self.PositionStore:Round(p.y+dy)
    end,function() self.PositionStore:ApplySettingsWindow(settings) end,
    {sample="KHQOL 설정창 · 위치 예시",resetPhysical=true,resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx,y=cy},
      resetWrite=function() self.db.toolWindows=self.db.toolWindows or {};self.db.toolWindows.settings={x=0,y=0} end})
  end
  return list
end
