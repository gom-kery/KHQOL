local K=_G.KHQOL
local FR=K.modules.range
local D=FR.Distance
local number=K.IsPublicNumber
local UI=K.UI
local anchors={start=0,near=1,dead=2,ranged=3,far=4,neutral=5}
local baseOrder={"near","dead","ranged","far","neutral"}
D.maxColorYards=200/.9144
function D:ValidateColorRanges(rows)
  if type(rows)~="table" or #rows>3 then return nil,"구간은 최대 3개입니다." end
  local out,seen={},{}
  for key in pairs(rows) do if not number(key) or key~=math.floor(key) or key<1 or key>#rows then return nil,"구간 목록을 확인하세요." end end
  for i,row in ipairs(rows) do
    if type(row)~="table" or not number(row.id) or row.id<1 or row.id>1000000 or row.id~=math.floor(row.id) or seen[row.id] then return nil,"구간 ID를 확인하세요." end
    if type(row.name)~="string" or #row.name>96 or row.name:find("[%z\1-\31\127|]") then return nil,"구간 이름을 확인하세요." end
    if not number(row.min) or not number(row.max) or row.min<0 or row.min>row.max or row.max>self.maxColorYards then return nil,"0~200m 범위와 최소 ≤ 최대를 확인하세요." end
    if type(row.enabled)~="boolean" or type(row.color)~="table" then return nil,"구간 색상·활성을 확인하세요." end
    local c={}
    for j=1,4 do if not number(row.color[j]) or row.color[j]<0 or row.color[j]>1 then return nil,"RGBA는 0~1 범위입니다." end;c[j]=row.color[j] end
    seen[row.id]=true;out[i]={id=row.id,name=row.name,min=row.min,max=row.max,color=c,enabled=row.enabled,after=anchors[row.after] and row.after or "neutral"}
  end
  return out
end
function D:NormalizeColorRanges(cfg)
  local rows=self:ValidateColorRanges(cfg.colorRanges)
  cfg.colorRanges=rows or {}
  local nextID=number(cfg.nextColorRangeID) and math.max(1,math.floor(cfg.nextColorRangeID)) or 1
  for _,row in ipairs(cfg.colorRanges) do nextID=math.max(nextID,row.id+1) end
  cfg.nextColorRangeID=nextID
  self.colorRangeRevision=(self.colorRangeRevision or 0)+1
end
function D:RowTicket(id)
  return {id=id,rows=FR.db.distance.colorRanges,profile=K.profileGeneration,revision=self.colorRangeRevision}
end
function D:ColorRow(ticket)
  if not ticket or ticket.profile~=K.profileGeneration or ticket.rows~=FR.db.distance.colorRanges
    or ticket.revision~=self.colorRangeRevision then return end
  for i,row in ipairs(ticket.rows) do if row.id==ticket.id then return row,i end end
end
function D:RowsChanged(structure)
  if structure then self.colorRangeRevision=(self.colorRangeRevision or 0)+1 end
  FR.Display.lastDistanceColor=nil
  FR:RefreshDisplay(true)
  if self.colorRowsPanel then self:RefreshColorRows() end
  if FR.Settings and FR.Settings.panel and FR.Settings.panel.uiBuilder then FR.Settings.panel.uiBuilder:Reflow() end
end
function D:ChangeColorRow(ticket,field,value)
  local row=self:ColorRow(ticket)
  if not row then return false,"대상이 변경되었습니다." end
  local candidate=K.CopyProfileValue(row)
  if field=="min" or field=="max" then
    local n=tonumber(value)
    if not number(n) or n<0 or n~=math.floor(n) then return false,"0 이상의 정수를 입력하세요." end
    local raw=tostring(value);local decimals=raw:match("%.(%d+)")
    if #raw>5 then return false,"최대 5글자까지 입력하세요." end
    candidate[field]=n/self:Multiplier()
  elseif field=="name" then
    local n=0;for _ in tostring(value):gmatch("[%z\1-\127\194-\244][\128-\191]*") do n=n+1 end
    if n>5 then return false,"이름은 최대 5글자입니다." end
    candidate.name=value
  elseif field=="enabled" or field=="color" then candidate[field]=value
  else return false end
  local valid,message=self:ValidateColorRanges({candidate})
  if not valid then return false,message end
  for key,v in pairs(valid[1]) do row[key]=v end
  self:RowsChanged();return true
end
function D:AddColorRow()
  local cfg=FR.db.distance
  if #cfg.colorRanges>=3 or cfg.nextColorRangeID>1000000 then return false end
  UI:CancelInputs(self.colorRowsPanel);UI:CloseColorPicker()
  cfg.colorRanges[#cfg.colorRanges+1]={id=cfg.nextColorRangeID,name="구간",min=0,max=10,color={1,1,1,1},enabled=true,after="neutral"}
  cfg.nextColorRangeID=cfg.nextColorRangeID+1;self:RowsChanged(true);return true
end
function D:ColorLayout()
  local out={}
  local function append(anchor)
    for _,row in ipairs(FR.db.distance.colorRanges) do
      if (row.after or "neutral")==anchor then out[#out+1]={row=row,id=row.id} end
    end
  end
  append("start")
  for _,key in ipairs(baseOrder) do out[#out+1]={base=key};append(key) end
  return out
end
function D:ColorRowIndex(id)
  local layout=self:ColorLayout()
  for i,entry in ipairs(layout) do if entry.id==id then return i,#layout end end
end
function D:MoveColorRow(ticket,delta)
  local row=self:ColorRow(ticket)
  local layout=self:ColorLayout();local index
  for i,entry in ipairs(layout) do if entry.row==row then index=i end end
  if not row or (delta~=-1 and delta~=1) or not index or not layout[index+delta] then return false end
  UI:CancelInputs(self.colorRowsPanel);UI:CloseColorPicker()
  local entry=table.remove(layout,index);table.insert(layout,index+delta,entry)
  local anchor="start";local rows={}
  for _,item in ipairs(layout) do
    if item.base then anchor=item.base else item.row.after=anchor;rows[#rows+1]=item.row end
  end
  for i,item in ipairs(rows) do ticket.rows[i]=item end
  self:RowsChanged(true);return true
end
function D:DeleteColorRow(ticket)
  local row,i=self:ColorRow(ticket);if not row then return false end
  UI:CancelInputs(self.colorRowsPanel);UI:CloseColorPicker()
  table.remove(ticket.rows,i);self:RowsChanged(true);return true
end
function D:CustomColor(result)
  if not result or result.kind=="unknown" then return end
  local lo,hi
  if result.kind=="exact" then lo,hi=result.value,result.value
  elseif result.kind=="range" then lo,hi=result.lower,result.upper;lo=lo or 0 end
  if not number(lo) or not number(hi) or lo>hi then return end
  -- Inclusive rows contain even an open measurement boundary at the same value.
  -- An unbounded upper estimate cannot be contained in a finite user row.
  for _,row in ipairs(FR.db.distance.colorRanges) do
    if row.enabled and lo>=row.min and hi<=row.max then return row.color,row.id end
  end
end
function D:Color(result,unit)
  if result and self:IsBeyond(result) then return FR.db.distance.colors.far end
  return self:CustomColor(result) or FR.db.distance.colors[self:ColorKey(result,unit)]
end
local function valueText(n)
  return string.format("%.0f",math.floor(n+.5))
end
function D:RefreshColorRows()
  local panel=self.colorRowsPanel;if not panel then return end
  for i,view in ipairs(panel.rows) do
    local row=FR.db.distance.colorRanges[i]
    view.ticket=row and self:RowTicket(row.id) or nil
    view:SetShown(row~=nil)
    if row then UI:Refresh(view) end
  end
  panel.add:Refresh()
end
function D:BuildColorRows(b,panel,header)
  local body=CreateFrame("Frame",nil,panel);body:SetWidth(panel:GetWidth());body.rows={}
  self.colorRowsPanel=body
  local label=header and header.label
  body.add=UI:CreateButton(header and header.row or body,"+",0,0,28,function()
    K.UsageDiagnostics:Begin(body.add,"click");self:AddColorRow();K.UsageDiagnostics:Finish(body.add)
  end,function() return #FR.db.distance.colorRanges<3 end)
  UI.SettingsNavigation:Attach(body,body.add,"사용자 구간 추가",function() return #FR.db.distance.colorRanges end)
  local feedback=UI:CreateDescription(body,"",0,0)
  self.colorRowsFeedback=feedback
  for slot=1,3 do
    local view=CreateFrame("Frame",nil,body);body.rows[slot]=view;view:SetSize(body:GetWidth(),42)
    -- Three fixed UI slots need separate search/getter records. Data identity
    -- is still row.id; telemetry uses the same closed field ID for every slot.
    view.settingsRoute={module="range",scope="현재 프로필",section="사용자 색상 구간 "..slot}
    local function current() return self:ColorRow(view.ticket) end
    local function available() return current()~=nil end
    local function field(key,default) return function() local row=current();return row and row[key] or default end end
    local function change(key,value)
      local ok,message=self:ChangeColorRow(view.ticket,key,value)
      feedback:SetText(ok and "" or (message or "입력을 확인하세요."))
    end
    local up,down,remove
    local function operate(control,fn) K.UsageDiagnostics:Begin(control,"click");fn();K.UsageDiagnostics:Finish(control) end
    up=UI:CreateButton(view,"▲",0,0,24,function() operate(up,function() self:MoveColorRow(view.ticket,-1) end) end,function() local row=current();local i=row and D:ColorRowIndex(row.id);return i and i>1 end)
    down=UI:CreateButton(view,"▼",0,0,24,function() operate(down,function() self:MoveColorRow(view.ticket,1) end) end,function() local row=current();local i,n=row and D:ColorRowIndex(row.id);if row then i,n=D:ColorRowIndex(row.id) end;return i and i<n end)
    local enabled=UI:CreateCheckbox(view,"",0,0,field("enabled",false),function(v) change("enabled",v) end,available)
    local function shortName()
      local text=field("name","")();local chars={}
      for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=char;if #chars==5 then break end end
      return table.concat(chars)
    end
    local name=UI:CreateEditBox(view,0,0,70,shortName,function(v) if v~=shortName() then change("name",v) end end,available);name:SetMaxLetters(5)
    local inputs={}
    for _,key in ipairs({"min","max"}) do
      local function get() local row=current();return row and valueText(row[key]*D:Multiplier()) or "" end
      inputs[#inputs+1]=UI:CreateEditBox(view,0,0,64,get,function(v) if v~=get() then change(key,v) end end,available)
      inputs[#inputs]:SetMaxLetters(5)
    end
    local sep=UI:CreateLabel(view,"~",0,-6)
    local picker=UI:CreateColorPicker(view,"",0,24,function() local row=current();return unpack(row and row.color or {1,1,1,1}) end,
      function(r,g,bl,a) change("color",{r,g,bl,a or 1}) end,available,nil,true)
    remove=UI:CreateButton(view,"삭제",0,0,48,function() operate(remove,function() self:DeleteColorRow(view.ticket) end) end,available)
    view.widgets={up,down,enabled,name,inputs[1],sep,inputs[2],picker,remove}
    for _,entry in ipairs({{up,"순서 위로"},{down,"순서 아래로"},{enabled,"활성"},{name,"이름"},{inputs[1],"최소"},{inputs[2],"최대"},{picker,"색상"},{remove,"삭제"}}) do
      local widget,title=entry[1],entry[2]
      local function snapshot()
        if widget==up or widget==down then
          local ids={};for _,row in ipairs(FR.db.distance.colorRanges) do ids[#ids+1]=row.id..":"..(row.after or "neutral") end;return table.concat(ids,",")
        elseif widget==remove then return #FR.db.distance.colorRanges end
        local row=current();if not row then return nil end
        if widget==enabled then return row.enabled elseif widget==name then return row.name
        elseif widget==inputs[1] then return row.min elseif widget==inputs[2] then return row.max
        elseif widget==picker then return unpack(row.color) end
      end
      UI.SettingsNavigation:Attach(view,widget,"사용자 구간 "..title,snapshot)
    end
  end
  for _,entry in pairs(self.thresholdControls or {}) do entry.row:SetParent(body) end
  b:Block(body,function()
    local width=body:GetWidth()
    if header then
      body.add:ClearAllPoints();body.add:SetPoint("LEFT",header.row,"LEFT",K.UI.Theme.ButtonHeight+K.UI.Theme.RowGap+label:GetUnboundedStringWidth()+10,0)
    end
    self:RefreshColorRows()
    local y=0
    local views={};for i,view in ipairs(body.rows) do local row=FR.db.distance.colorRanges[i];if row then views[row.id]=view end end
    for _,entry in ipairs(self:ColorLayout()) do
      local view=entry.base and self.thresholdControls[entry.base].row or views[entry.id]
      view:ClearAllPoints();view:SetPoint("TOPLEFT",body,"TOPLEFT",0,y);view:SetWidth(width)
      if entry.base then self.thresholdControls[entry.base].fit();y=y-44
      else
        local w=view.widgets
        -- ON/name keep the left edge. Numeric fields align with default rows.
        -- Narrow windows wrap only the trailing colour/order/delete controls.
        local compact=width<590
        local start=math.min(180,math.max(138,width*.28))
        local inputWidth=math.max(46,math.min(76,(width-start-128)/2))
        local pickerX=start+2*inputWidth+36
        local positions={pickerX+78,pickerX+104,0,34,start,start+inputWidth+6,start+inputWidth+24,pickerX,pickerX+134}
        for i,widget in ipairs(w) do
          local x=positions[i];local top=i==6 and -6 or 0
          if compact and (i==1 or i==2 or i==8 or i==9) then
            x=i==8 and start or i==1 and start+82 or i==2 and start+108 or start+138;top=-34
          end
          widget:ClearAllPoints();widget:SetPoint("TOPLEFT",view,"TOPLEFT",x,top)
        end
        w[4]:SetWidth(math.max(62,math.min(88,start-46)));w[5]:SetWidth(math.min(56,inputWidth));w[7]:SetWidth(math.min(56,inputWidth))
        view:SetHeight(compact and 76 or 44);y=y-view:GetHeight()
      end
    end
    feedback:ClearAllPoints();feedback:SetPoint("TOPLEFT",body,"TOPLEFT",0,y);feedback:SetWidth(width)
    return -y+(feedback:GetText()~="" and 30 or 0)
  end)
  b:Description("사용자 구간은 최대 3개이며 색상을 우선 적용합니다. ▲ ▼로 기본 항목 사이에 배치합니다. 입력은 최대 5글자, 실제 경계값은 단위 전환 시 유지됩니다.",true)
end
