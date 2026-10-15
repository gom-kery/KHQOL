local _, KHQOL = ...
local E=KHQOL.PositionEditor
local function applyPoint(frame,p)
  if not frame or not p then return end
  frame:ClearAllPoints(); frame:SetPoint(p.point or "CENTER",UIParent,p.relativePoint or p.point or "CENTER",p.x or 0,p.y or 0)
end
function KHQOL:ApplyEditorPositions()
  local fc=self.modules.clock; if not fc.db then return end
  local positions=fc.db.clockTools.positions or {}
  applyPoint(fc.alertMessageFrame,positions.alert or {y=160}); applyPoint(fc.clockToolsFrame,positions.tools or {y=-80}); applyPoint(fc.stopwatchFrame,positions.stopwatch or {y=110})
  local cfa=self.modules.campfire
  if cfa.db and cfa.ui then applyPoint(cfa.ui.complete,cfa.db.completePosition or {y=80}) end
end
function E:Virtual(id,p,width,height)
  self.virtuals=self.virtuals or {}; local frame=self.virtuals[id]
  if not frame then frame=CreateFrame("Frame",nil,UIParent); frame:Hide(); self.virtuals[id]=frame end
  frame:SetSize(width,height); applyPoint(frame,p); return frame
end
function KHQOL:BuildPositionTargets(focus)
  local list={}; local m=self.modules; local fc=m.clock
  local function add(id,key,name,frame,write,lock,apply,extra)
    if key and not self:CanRunModule(key) then return end
    -- Buff runtime is a legacy exception, but its editor remains behind lab access.
    if key=="buffReminder" and not self.LabLock:IsUnlocked() then return end
    if not frame or (key and not self:GetEnabled(key)) then return end
    local t=extra or {}; t.id=id; t.key=key; t.name=name; t.frame=frame; t.write=write; t.lock=lock; t.apply=apply
    list[#list+1]=t; return t
  end
  local function pointWriter(p,xKey,yKey)
    xKey=xKey or "x"; yKey=yKey or "y"
    return function(dx,dy) p[xKey]=self.PositionStore:Round((p[xKey] or 0)+dx); p[yKey]=self.PositionStore:Round((p[yKey] or 0)+dy) end
  end
  local function lock(db,key) return function() db[key or "locked"]=true end end
  local function clockApply() fc:ApplyClock(); fc:ApplyLayout() end
  if fc.db then
    add("clock","clock","Clock · 시간",fc.clockFrame,pointWriter(fc.db.position),lock(fc.db),clockApply,{bounds=function(x,y)
      return x,y,fc.clockFrame.timeText:GetStringWidth()+8,fc.clockFrame.timeText:GetStringHeight()+8
    end})
    for _,key in ipairs({"date","weekday","money","performance","professions"}) do
      local cfg=fc.db.modules[key]
      if cfg.enabled then
        local names={date="날짜",weekday="요일",money="소지금",performance="FPS / 지연시간",professions="전문기술"}
        add("clock."..key,"clock","Clock · "..names[key],key=="professions" and fc.professionsButton or fc.modules[key],pointWriter(cfg.position),lock(fc.db),clockApply,{parentID="clock"})
      end
    end
    if fc.db.modules.professions.enabled and fc.professionsPanel and fc.professionsPanel:IsShown() then
      add("clock.professions.panel","clock","Clock · 전문기술 목록 (연결)",fc.professionsPanel,nil,lock(fc.db),clockApply,{parentID="clock.professions",linked=true})
    end
    for _,entry in ipairs({{"alert","중앙 알림",fc.alertMessageFrame,560,64},{"tools","알람 / 타이머",fc.clockToolsFrame,390,282},{"stopwatch","스톱워치",fc.stopwatchFrame,300,58}}) do
      local key=entry[1]; local frame=entry[3]
      add("clock."..key,"clock","Clock · "..entry[2],frame,function(dx,dy)
        local positions=fc.db.clockTools.positions
        if not positions then positions={}; fc.db.clockTools.positions=positions end
        if not positions[key] then
          local status,point,relative,relativePoint,x,y=self.ReadPublicAPI(frame.GetPoint,frame,1)
          if status~="ok" or (relative and relative~=UIParent) or type(point)~="string" or type(relativePoint)~="string"
            or not self.PositionStore:Number(x) or not self.PositionStore:Number(y) then return end
          positions[key]={point=point,relativePoint=relativePoint,x=x,y=y}
        end
        pointWriter(positions[key])(dx,dy)
      end,lock(fc.db.clockTools,"positionLocked"),function() self:ApplyEditorPositions() end,{alwaysSave=true})
    end
    local p=fc.db.todo.window
    local note=fc.todoFrame or E:Virtual("note",p,p.width or 430,p.height or 310)
    add("note","todo","Forever Note",note,pointWriter(p),lock(p,"positionLocked"),function() if fc.todoFrame then applyPoint(fc.todoFrame,p) end end,{bounds=function(x,y,w,h)
      local children={}
      if fc.todoFrame then
        if fc.todoFrame.favoriteList then children[#children+1]=fc.todoFrame.favoriteList end
        if fc.todoFrame.pageJump then children[#children+1]=fc.todoFrame.pageJump end
      end
      return KHQOL.PositionStore:Bounds(note,x,y,w,h,children)
    end})
  end
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
  local fr=m.range
  if fr.db then add("range","range","Range · 사거리",fr.Display.frame,pointWriter(fr.db),lock(fr.db),function() fr.Display:ApplyLayout(true) end,{sample=fr.db.shape,sampleSize=fr.db.size,bounds=function(x,y) local w,h=fr.Display.frame:GetSize();return x,y,math.max(16,w),math.max(16,h) end}) end
  local rs=KHQOLResourceSwingDB
  if rs and rs.enabled~=false then
    add("resource","resourceSwing","Resource Swing · 자원 / 스윙",KHQOLResourceSwingFrame,pointWriter(rs),lock(rs),function() m.resourceSwing:ApplyPosition() end,{bounds=function(x,y,w,h) return m.resourceSwing:GetEditorBounds(x,y,w,h) end})
    if m.resourceSwing:CanShowAux() then
      add("ammo","resourceSwing","Resource Swing · 탄약 / 영혼의 조각",_G.KHQOLResourceSwingAmmoAnchor,pointWriter(rs,"ammoX","ammoY"),lock(rs,"ammoLocked"),function() m.resourceSwing:ApplyPosition() end,{sample="탄약 / 영혼의 조각"})
    end
    if rs.showCombo and rs.comboPosition=="FREE" and select(2,m.resourceSwing:GetComboData()) then
      local combo=m.resourceSwing.comboFrame
      if combo then
        local p={point=rs.comboPoint,relativePoint=rs.comboRelativePoint,x=rs.comboX,y=rs.comboY}
        local preview=combo:IsShown() and combo or E:Virtual("resource.combo",p,combo:GetWidth(),combo:GetHeight())
        add("resource.combo","resourceSwing","Resource Swing · 콤보 포인트",preview,pointWriter(rs,"comboX","comboY"),lock(rs,"comboLocked"),function() m.resourceSwing:ApplyPosition() end,{sample="콤보 포인트",sampleSize=12})
      end
    end
  end
  local cfa=m.campfire
  if cfa.ui then
    add("campfire","campfire","Campfire · 발견 / 진행",cfa.ui.root,pointWriter(cfa.db.position),lock(cfa.db),function() applyPoint(cfa.ui.root,cfa.db.position) end,{sample=cfa.db.message,sampleY=-28,art={{texture=cfa.ICON_FILE_ID,width=cfa.db.iconSize,height=cfa.db.iconSize,y=80}}})
    local complete=cfa.ui.complete
    add("campfire.complete","campfire","Campfire · 효과 획득",complete,function(dx,dy)
      cfa.db.completePosition=cfa.db.completePosition or {point="CENTER",x=0,y=80}
      pointWriter(cfa.db.completePosition)(dx,dy)
    end,lock(cfa.db),function() self:ApplyEditorPositions() end,{sample="야영 효과를 받았습니다!",bounds=function(x,y) return x,y,complete:GetStringWidth()+8,complete:GetStringHeight()+8 end})
  end
  local cb=m.castBar
  if cb.db then
    local t=cb:TargetPositionPreview()
    if t then add(t.id,"castBar",t.name,t.frame,t.write,nil,t.apply,t) end
    local linked=cb.linked and true or false
    add("cast","castBar","Cast Bar"..(linked and " · 자원바 연결" or " · 자유 위치"),cb.frame,not linked and pointWriter(cb.db.position.free) or nil,lock(cb.db.position),function() cb:ApplyLayout() end,{parentID=linked and "resource" or nil,linked=linked,sample="주문 시전 · 2.0초"})
  end
  local cs=m.combatStatus
  if cs.db then
    local width=cs.db.swordWidth;local showSwords=cs.db.showSwords
    local sample=cs.db.showEnter and cs.db.enterText or (cs.db.showLeave and cs.db.leaveText or "")
    local textWidth=math.max(cs.db.showEnter and #cs.db.enterText or 0,cs.db.showLeave and #cs.db.leaveText or 0)/3*cs.db.fontSize
    local art=showSwords and {{texture="Interface\\AddOns\\KHQOL\\Media\\CombatStatus\\Sword_Blue.tga",width=width,height=width*1.5,crop=.75,x=-45*width/56},{texture="Interface\\AddOns\\KHQOL\\Media\\CombatStatus\\Sword_Blue.tga",width=width,height=width*1.5,crop=.75,x=45*width/56}} or {}
    add("combat","combatStatus","Combat Status · 전투 알림",cs.root,pointWriter(cs.db.position),lock(cs.db),function() cs:ApplyLayout() end,
      {sample=sample,sampleSize=cs.db.fontSize,sampleY=showSwords and -width*.75-18 or 0,
       art=art,
       bounds=function(x,y) return x,y,math.max(220,showSwords and width*3 or 0,textWidth),(showSwords and width*1.5 or 0)+2*cs.db.fontSize+40 end})
  end
  local qn=m.questNavigator
  local noteNavigation=fc.db and fc.db.todo.navigation and fc.db.todo.navigation.enabled and self:GetEnabled("todo")
  if qn.db then add("quest",self:GetEnabled("questNavigator") and "questNavigator" or noteNavigation and "todo" or "questNavigator","퀘스트 / 노트 · 공용 안내 HUD",qn.root,pointWriter(qn.db,"positionX","positionY"),lock(qn.db),function() qn:ApplyLayout() end,{sample="퀘스트 방향 · 120 m",sampleY=-30,art={{texture="Interface\\AddOns\\KHQOL\\Media\\QuestNavigator\\Arrow.tga",width=qn.db.arrowSize,height=qn.db.arrowSize,y=30}}}) end
  local th=m.threat
  if th.db then add("threat","threat","Threat · 위협 수준",th.root,pointWriter(th.db.position),lock(th.db),function() th:ApplyLayout() end,{sample="위협 수준 78%"}) end
  local pa=m.pvpAlert
  if pa.db then add("pvp","pvpAlert","PvP Alert · 경고 / 보조 목록",pa.frame,pointWriter(pa.db),function() pa.moving=false; pa.frame:EnableMouse(false); pa.moveText:Hide() end,function() pa:ApplyLayout() end,{sample="상대 플레이어 · 주시 중"}) end
  local xp=m.experienceBar
  if xp.db and xp.db.mode=="horizontal" then
    add("experience","experienceBar","경험치 바",xp.frame,function(dx,dy)
      xp.db.x=self.PositionStore:Round(xp.db.x+dx*xp.db.scale);xp.db.y=self.PositionStore:Round(xp.db.y+dy*xp.db.scale)
    end,function() xp.unlocked=false end,function() xp:ApplyLayout();xp:Update() end,{sample="경험치 / 평판"})
  end
  local env=m.environmentTimer
  if env.db and self:CanRunModule("environmentTimer") then
    local db=env.db;local hud=db.style=="hud";local scale=hud and 1 or db.scale
    local timers={};for _,id in ipairs({"BREATH","EXHAUSTION","FEIGNDEATH"}) do if db.timers[id] then timers[#timers+1]=id end end
    if #timers==0 then timers[1]="BREATH" end
    if #timers>0 then
      local width=hud and math.max(480,db.hudGap+2*(db.hudSize*128/420*(db.hudThickness/8))*104/128+32) or db.width
      local height=hud and (db.hudSize*464/420+100) or (db.height*#timers+32*(#timers-1))
      local frame=E:Virtual("environment",{x=db.x/scale,y=db.y/scale},width,height);frame:SetScale(scale)
      add("environment","environmentTimer","환경 타이머 · 그룹",frame,function(dx,dy)
        db.x=self.PositionStore:Round(db.x+dx*scale);db.y=self.PositionStore:Round(db.y+dy*scale)
      end,function() env.unlocked=false end,function() env.layoutCount=nil;env:Render(0) end,
        {sample="호흡 · 피로도 · 죽은척",suppress={env.frame},mirror=env.frame})
      if hud then
        local names={BREATH="호흡",EXHAUSTION="피로도",FEIGNDEATH="죽은척"}
        for index,timer in ipairs(timers) do
          local id=timer;local p=db.hudTextPositions[id]
          local dx=index<=2 and (index==1 and -1 or 1)*(db.hudGap/2+db.hudThickness+db.hudSize*.12) or 0
          local dy=-db.hudSize/2-(index<=2 and 24 or 56)
          local original={x=p and p.x or dx,y=p and p.y or dy}
          local text=E:Virtual("environment.text."..id,{x=db.x+original.x,y=db.y+original.y},math.max(80,db.hudTextSize*7),db.hudTextSize+16)
          local target=add("environment.text."..id,"environmentTimer","환경 · "..names[id].." 텍스트",text,function(x,y)
            db.hudTextPositions[id]={x=original.x+x,y=original.y+y}
          end,function() env.unlocked=false end,nil,{parentID="environment",sample=names[id].." 42초",sampleSize=db.hudTextSize})
          target.textDefault={x=dx,y=dy};target.textOriginal=original;target.textTimer=id
        end
      end
    end
  end
  local proc=m.procAlert
  if proc.db then add("proc","procAlert","발동 버프 · HUD",proc.frame,function(dx,dy)
    proc.db.hud.x=self.PositionStore:Round(proc.db.hud.x+dx*proc.db.hud.scale);proc.db.hud.y=self.PositionStore:Round(proc.db.hud.y+dy*proc.db.hud.scale)
  end,function() proc.unlocked=false;proc.testUntil=nil end,function() proc:Layout();proc:Render() end,{sample="발동 버프 미리보기"}) end
  local monitor=m.performanceMonitor
  if monitor.db then add("monitor","performanceMonitor","성능 모니터",monitor.frame,pointWriter(monitor.db),lock(monitor.db,"positionLocked"),function() monitor:ApplyLayout() end) end
  -- Minimap buttons keep their circular relationship, rather than becoming free HUDs.
  local function minimap(id,key,name,frame,db,apply)
    if not db or db.show==false then return end
    local t=add(id,key,name,frame,nil,lock(db,"positionLocked"),apply)
    if t then t.write=function()
      local h=t.handle; local x,y=self.PositionStore:Center(h)
      local status,mx,my=self.ReadPublicAPI(Minimap.GetCenter,Minimap)
      local ss,scale=self.ReadPublicAPI(Minimap.GetEffectiveScale,Minimap)
      local ps,parentScale=self.ReadPublicAPI(UIParent.GetEffectiveScale,UIParent)
      if not x or status~="ok" or ss~="ok" or ps~="ok" or not self.PositionStore:Number(mx) or not self.PositionStore:Number(my)
        or not self.PositionStore:Number(scale) or not self.PositionStore:Number(parentScale) or parentScale<=0 then return end
      local ratio=scale/parentScale
      db.angle=math.deg(math.atan2(y-my*ratio,x-mx*ratio))
    end; t.minimap=true end
  end
  minimap("minimap",nil,"KHQOL · 미니맵",self.minimapButton,self.db.minimap,function() self:UpdateMinimapButton() end)
  if fc.db then minimap("note.minimap","todo","Note · 미니맵",fc.todoMinimapButton,fc.db.todo.minimap,function() fc:UpdateTodoMinimapButton() end) end
  for _,t in ipairs(self:ExtraPositionTargets()) do add(t.id,t.key,t.name,t.frame,t.write,t.lock,t.apply,t) end
  self.ModuleRegistry:PositionTargets(focus,add)
  self:ConfigurePositionResets(list)
  return list
end

function KHQOL:ConfigurePositionResets(list)
  local m,fc=self.modules,self.modules.clock
  local function point(t,getDB,defaults,fields)
    if not defaults then return end
    fields=fields or {point="point",relativePoint="relativePoint",x="x",y="y"}
    local p={point=defaults.point or "CENTER",relativePoint=defaults.relativePoint or defaults.point or "CENTER",x=defaults.x or 0,y=defaults.y or 0}
    t.resetPoint=p
    t.resetWrite=function()
      local db=getDB()
      for k,field in pairs(fields) do if field then db[field]=p[k] end end
    end
  end
  for _,t in ipairs(list) do
    local id=t.id
    if id=="clock" then point(t,function() return fc.db.position end,fc.DEFAULTS.position)
    elseif id=="note" then point(t,function() return fc.db.todo.window end,fc.DEFAULTS.todo.window)
    elseif id=="range" then point(t,function() return m.range.db end,m.range.defaults)
    elseif id=="resource" then point(t,function() return KHQOLResourceSwingDB end,m.resourceSwing.defaults)
    elseif id=="ammo" then local d=m.resourceSwing.defaults;point(t,function() return KHQOLResourceSwingDB end,{point=d.ammoPoint,relativePoint=d.ammoRelativePoint,x=d.ammoX,y=d.ammoY},{point="ammoPoint",relativePoint="ammoRelativePoint",x="ammoX",y="ammoY"})
    elseif id=="resource.combo" then local d=m.resourceSwing.defaults;point(t,function() return KHQOLResourceSwingDB end,{point=d.comboPoint,relativePoint=d.comboRelativePoint,x=d.comboX,y=d.comboY},{point="comboPoint",relativePoint="comboRelativePoint",x="comboX",y="comboY"})
    elseif id=="campfire" then point(t,function() return m.campfire.db.position end,m.campfire.defaults.position)
    elseif id=="campfire.complete" then point(t,function() m.campfire.db.completePosition=m.campfire.db.completePosition or {};return m.campfire.db.completePosition end,{y=80})
    elseif id=="cast" and not t.linked then point(t,function() return m.castBar.db.position.free end,m.castBar.defaults.position.free)
    elseif id=="combat" then point(t,function() return m.combatStatus.db.position end,m.combatStatus.defaults.position)
    elseif id=="threat" then point(t,function() return m.threat.db.position end,m.threat.defaults.position)
    elseif id=="pvp" then point(t,function() return m.pvpAlert.db end,{y=165})
    elseif id=="quest" then point(t,function() return m.questNavigator.db end,{x=0,y=180},{x="positionX",y="positionY"})
    elseif id=="buffs" then point(t,function() return ForeverBuffReminderDB.position end,ForeverBuffReminder.profileDefaults.position)
    elseif id=="experience" then point(t,function() return m.experienceBar.db end,m.experienceBar.defaults,{x="x",y="y"});t.resetPhysical=true
    elseif id=="environment" then point(t,function() return m.environmentTimer.db end,m.environmentTimer.defaults,{x="x",y="y"});t.resetPhysical=true
    elseif id=="proc" then point(t,function() return m.procAlert.db.hud end,m.procAlert.defaults.hud,{x="x",y="y"});t.resetPhysical=true
    elseif id=="monitor" then point(t,function() return m.performanceMonitor.db end,m.performanceMonitor.defaults,{x="x",y="y"})
    elseif t.textDefault then
      point(t,function() local db=m.environmentTimer.db.hudTextPositions;db[t.textTimer]=db[t.textTimer] or {};return db[t.textTimer] end,t.textDefault,{x="x",y="y"})
      t.write=function(dx,dy)
        local p=t.handle.resetting and t.textDefault or t.textOriginal
        m.environmentTimer.db.hudTextPositions[t.textTimer]={x=self.PositionStore:Round(p.x+dx),y=self.PositionStore:Round(p.y+dy)}
      end
    elseif id:match("^clock%.") then
      local key=id:match("^clock%.(.+)$")
      if fc.db.modules[key] then point(t,function() return fc.db.modules[key].position end,fc.DEFAULTS.modules[key].position,{x="x",y="y"})
      elseif key=="alert" or key=="tools" or key=="stopwatch" then
        point(t,function() local d=fc.db.clockTools;d.positions=d.positions or {};d.positions[key]=d.positions[key] or {};return d.positions[key] end,{y=key=="alert" and 160 or key=="tools" and -80 or 110})
      end
    elseif t.minimap then t.resetAngle=id=="minimap" and 225 or 135 end
  end
end
