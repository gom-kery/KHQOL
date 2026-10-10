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
function KHQOL:BuildPositionTargets()
  local list={}; local m=self.modules; local fc=m.clock
  local function add(id,key,name,frame,write,lock,apply,extra)
    if key and m[key] and m[key].experimental then return end
    if not frame or (key and not self:GetEnabled(key)) then return end
    local t=extra or {}; t.id=id; t.name=name; t.frame=frame; t.write=write; t.lock=lock; t.apply=apply
    list[#list+1]=t; return t
  end
  local function pointWriter(p,xKey,yKey)
    xKey=xKey or "x"; yKey=yKey or "y"
    return function(dx,dy) p[xKey]=(p[xKey] or 0)+dx; p[yKey]=(p[yKey] or 0)+dy end
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
          local point,_,relativePoint,x,y=frame:GetPoint(1)
          positions[key]={point=point,relativePoint=relativePoint,x=x,y=y}
        end
        pointWriter(positions[key])(dx,dy)
      end,lock(fc.db.clockTools,"positionLocked"),function() self:ApplyEditorPositions() end,{alwaysSave=true})
    end
    local p=fc.db.todo.window
    local note=fc.todoFrame or E:Virtual("note",p,p.width or 430,p.height or 310)
    add("note","todo","Forever Note",note,pointWriter(p),lock(p,"positionLocked"),function() if fc.todoFrame then applyPoint(fc.todoFrame,p) end end,{bounds=function(x,y,w,h)
      local left,bottom,right,top=x-w/2,y-h/2,x+w/2,y+h/2
      if fc.todoFrame then for _,child in ipairs({fc.todoFrame.favoriteList,fc.todoFrame.pageJump}) do
        if child and child:IsShown() then
          local l,b,cw,ch=child:GetRect(); local scale=child:GetEffectiveScale()/UIParent:GetEffectiveScale()
          if l then left=math.min(left,l*scale);bottom=math.min(bottom,b*scale);right=math.max(right,(l+cw)*scale);top=math.max(top,(b+ch)*scale) end
        end
      end end
      return (left+right)/2,(bottom+top)/2,right-left,top-bottom
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
        if l then left=math.min(left or l,l); bottom=math.min(bottom or b,b); right=math.max(right or l+w,l+w); top=math.max(top or b+h,b+h) end
      end end
      if left then return (left+right)/2,(bottom+top)/2,right-left,top-bottom end
      return x+size/2,y-size/2,size,size
    end})
  end
  local fr=m.range
  if fr.db then add("range","range","Range · 사거리",fr.Display.frame,pointWriter(fr.db),lock(fr.db),function() fr.Display:ApplyLayout(true) end,{sample=fr.db.shape,sampleSize=fr.db.size,bounds=function(x,y) local size=fr.db.size+8;return x,y,size,size end}) end
  local rs=KHQOLResourceSwingDB
  if rs and rs.enabled~=false then
    add("resource","resourceSwing","Resource Swing · 자원 / 스윙",KHQOLResourceSwingFrame,pointWriter(rs),lock(rs),function() m.resourceSwing:ApplyPosition() end)
    if m.resourceSwing:CanShowAux() then
      add("ammo","resourceSwing","Resource Swing · 탄약 / 영혼의 조각",_G.KHQOLResourceSwingAmmoAnchor,pointWriter(rs,"ammoX","ammoY"),lock(rs,"ammoLocked"),function() m.resourceSwing:ApplyPosition() end,{sample="탄약 / 영혼의 조각"})
    end
    if rs.showCombo and rs.comboPosition=="FREE" and m.resourceSwing:IsComboClass() then
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
    end,lock(cfa.db),function() self:ApplyEditorPositions() end,{sample="야영 효과를 받았습니다!"})
  end
  local cb=m.castBar
  if cb.db then
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
  if qn.db then add("quest","questNavigator","Quest Navigator · 안내 / 완료",qn.root,pointWriter(qn.db,"positionX","positionY"),lock(qn.db),function() qn:ApplyLayout() end,{sample="퀘스트 방향 · 120 m",sampleY=-30,art={{texture="Interface\\AddOns\\KHQOL\\Media\\QuestNavigator\\Arrow.tga",width=qn.db.arrowSize,height=qn.db.arrowSize,y=30}}}) end
  local th=m.threat
  if th.db then add("threat","threat","Threat · 위협 수준",th.root,pointWriter(th.db.position),lock(th.db),function() th:ApplyLayout() end,{sample="위협 수준 78%"}) end
  local pa=m.pvpAlert
  if pa.db then add("pvp","pvpAlert","PvP Alert · 경고 / 보조 목록",pa.frame,pointWriter(pa.db),function() pa.moving=false; pa.frame:EnableMouse(false); pa.moveText:Hide() end,function() pa:ApplyLayout() end,{sample="상대 플레이어 · 주시 중"}) end
  -- Minimap buttons keep their circular relationship, rather than becoming free HUDs.
  local function minimap(id,key,name,frame,db,apply)
    if not db or db.show==false then return end
    local t=add(id,key,name,frame,nil,lock(db,"positionLocked"),apply)
    if t then t.write=function()
      local h=t.handle; local x,y=h:GetCenter(); local mx,my=Minimap:GetCenter()
      local ratio=Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
      db.angle=math.deg(math.atan2(y-my*ratio,x-mx*ratio))
    end; t.minimap=true end
  end
  minimap("minimap",nil,"KHQOL · 미니맵",self.minimapButton,self.db.minimap,function() self:UpdateMinimapButton() end)
  if fc.db then minimap("note.minimap","todo","Note · 미니맵",fc.todoMinimapButton,fc.db.todo.minimap,function() fc:UpdateTodoMinimapButton() end) end
  return list
end
