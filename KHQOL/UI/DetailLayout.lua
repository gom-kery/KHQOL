local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
-- Responsive detail rows. Height changes
-- use the presenter's existing OnSizeChanged path, including cached tabs.
function UI:CreateDetailLayout(parent,y,key)
  local rows={}; local page=CreateFrame("Frame",nil,parent)
  local currentGroup,refresh
  page:SetPoint("TOPLEFT",0,y); page:SetWidth(parent:GetWidth()); page.moduleKey=key
  local function row(height,visible,indent)
    local f=CreateFrame("Frame",nil,page); f:SetWidth(page:GetWidth()-(indent or 0)); f:SetHeight(height)
    rows[#rows+1]={frame=f,height=height,visible=visible,indent=indent or 0,disclosure=currentGroup};f.settingsDisclosure=currentGroup;return f
  end
  local L={page=page,rows=rows,disclosures={}}
  function L:Fields(frame,height,visible)
    local f=row(height,visible); frame:SetParent(f); frame:SetPoint("TOPLEFT",0,0); frame:SetHeight(height);rows[#rows].child=frame
  end
  function L:Section(title)
    currentGroup=nil
    local f=row(T.SectionGap+T.ButtonHeight+T.RowGap)
    local group=UI:CreateSettingsAccordion(f,title,UI:SettingsAccordionID(parent,title),function() refresh();UI:RefreshAccordionLayout(parent) end,nil,true)
    group.row:SetPoint("TOPLEFT",0,-T.SectionGap);rows[#rows].heading=group
    self.disclosures[#self.disclosures+1]=group;currentGroup=group
  end
  function L:EndSection() currentGroup=nil end
  function L:Description(text,visible)
    local f=row(T.RowHeight+T.RowGap,visible)
    local label=UI:CreateDescription(f,type(text)=="function" and text() or text,0,-6); label:SetWidth(f:GetWidth())
    rows[#rows].label=label
    if type(text)=="function" then rows[#rows].text=text end
  end
  function L:Check(title,get,set,visible,tooltip,ignore,enabled)
    local f=row(T.RowHeight+T.RowGap,visible)
    f.settingsRoute=self.controlRoute
    local c=UI:CreateCheckbox(f,title,0,0,get,set,enabled)
    rows[#rows].columns=2;rows[#rows].kind="check"
    c.ignoreModuleEnabled=ignore;rows[#rows].check=c; c:Refresh(); UI:AttachTooltip(c,title,tooltip); return c
  end
  function L:Children(items,visible,label)
    local f=row(T.RowHeight+T.RowGap,visible,T.ContentPadding)
    local prefix=0
    if label then
      local text=UI:CreateLabel(f,label,0,-6); text:SetWidth(100); prefix=108
    end
    local controls={}
    for _,item in ipairs(items) do
      local c=UI:CreateCheckbox(f,item[1],0,0,item[2],item[3]); c.text:SetWidth(100)
      c.text:SetWidth(math.max(100,c.text:GetStringWidth()))
      UI:AttachTooltip(c,item[1],item[4]); controls[#controls+1]=c
    end
    rows[#rows].flow=function(width)
      local x,line=prefix,0
      for _,c in ipairs(controls) do
        local w=T.CheckboxSize+T.CheckboxLabelGap+c.text:GetStringWidth()+T.RowGap
        if x+w>width and x>prefix then line=line+1; x=prefix end
        c:ClearAllPoints(); c:SetPoint("TOPLEFT",x,-line*(T.RowHeight+T.RowGap)); x=x+w
      end
      return (line+1)*(T.RowHeight+T.RowGap)
    end
  end
  function L:Dropdown(title,options,get,set,visible,tooltip,enabled)
    local f=row(T.DropdownRowHeight,visible);local label=UI:CreateLabel(f,title,0,0)
    local c=UI:CreateDropdown(f,0,-24,math.min(T.DropdownWidth,f:GetWidth()),options,get,set,enabled)
    rows[#rows].dropdown=c;rows[#rows].fieldLabel=label;rows[#rows].columns=2;rows[#rows].kind="field";UI:AttachTooltip(c,title,tooltip); return c
  end
  function L:Slider(title,min,max,step,get,set,format,visible)
    local f=row(T.SliderRowHeight)
    local c=UI:CreateSlider(f,title,"",0,0,min,max,step,get,set,format,visible);rows[#rows].slider=c
    rows[#rows].columns=2;rows[#rows].kind="field"
  end
  function L:Compare(title,kind,options,db,module)
    local f=row(T.DropdownRowHeight)
    local label=UI:CreateLabel(f,title,0,-6); label:SetWidth(170)
    local controls,captions={},{}
    for index,unit in ipairs({"player","target"}) do
      local u=unit
      captions[index]=UI:CreateLabel(f,u=="player" and "플레이어" or "대상",0,0)
      if kind=="compact" or kind=="showPower" then
        controls[index]=UI:CreateCheckbox(f,"사용",0,0,function() return kind=="showPower" and db()[u][kind]~=false or kind=="compact" and db()[u][kind] end,function(v) db()[u][kind]=v; module:ApplySettings() end,function() return module:UnitParts(u)~=nil end)
        controls[index].text:SetWidth(40)
      else
        controls[index]=UI:CreateDropdown(f,0,0,T.DropdownWidth,options,function() return db()[u][kind] end,function(v) db()[u][kind]=v; module:ApplySettings() end,function() return module:UnitParts(u)~=nil end)
      end
    end
    rows[#rows].flow=function(width)
      local wide=width>=560
      local labelWidth=wide and 170 or width; label:SetWidth(labelWidth)
      for index,c in ipairs(controls) do
        local x=wide and (180+(index-1)*(width-180+T.ColumnGap-T.ContentPadding)/2) or T.ContentPadding
        local top=wide and -24 or (-28-(index-1)*T.DropdownRowHeight)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT",x,top)
        if kind~="compact" and kind~="showPower" then c:FitDropdownWidth(wide and (width-180-T.ColumnGap-T.ContentPadding)/2 or math.min(T.DropdownWidth,width-T.ContentPadding)) end
        captions[index]:ClearAllPoints(); captions[index]:SetPoint("TOPLEFT",x,top+20)
        captions[index]:SetWidth(wide and (width-180-T.ColumnGap)/2 or width-T.ContentPadding)
      end
      return wide and T.DropdownRowHeight or (28+2*T.DropdownRowHeight)
    end
  end
  refresh=function()
    local top,rowHeight,count,kind,lastColumns,previousGroup=0,0,0,nil,0,nil
    local width=math.min(T.FormMaxWidth,parent:GetWidth())
    page:SetWidth(width)
    local counts={};for _,group in ipairs(L.disclosures) do counts[group]=0 end
    for _,r in ipairs(rows) do if r.disclosure then
      local amount=0
      if r.child and r.child.uiBuilders then
        for _,builder in ipairs(r.child.uiBuilders) do for _,cell in ipairs(builder.cells) do amount=amount+UI:SettingsCellOptionCount(cell) end end
      elseif r.check or r.slider or r.dropdown or r.flow then amount=r.flow and 2 or 1 end
      counts[r.disclosure]=counts[r.disclosure]+amount
    end end
    for group,amount in pairs(counts) do group:SetOptionCount(amount) end
    for _,r in ipairs(rows) do
      local show=not r.visible or r.visible()
      if r.disclosure and not r.disclosure:IsExpanded() then show=false end
      r.frame:SetShown(show)
      if show then
        local columns=r.columns and width>=480 and r.columns or 1
        if r.check then
          r.check.text:SetWidth(width)
          if r.check.text:GetStringWidth()+T.CheckboxSize+T.CheckboxLabelGap>(width-T.ColumnGap)/2 then columns=1 end
        end
        if columns==1 or count>=columns or kind~=r.kind or lastColumns~=columns or previousGroup~=r.disclosure then
          top=top-rowHeight;rowHeight=0;count=0
        end
        local cellWidth=(width-(columns-1)*T.ColumnGap)/columns
        local available=cellWidth-r.indent
        r.frame:ClearAllPoints(); r.frame:SetPoint("TOPLEFT",count*(cellWidth+T.ColumnGap)+r.indent,top); r.frame:SetWidth(available)
        local height=r.flow and r.flow(available) or r.height
        if r.heading then r.heading.row:SetWidth(available);height=T.SectionGap+r.heading.row:GetHeight()+T.RowGap end
        if r.child then r.child:SetWidth(available);if r.child.uiBuilder then r.child.uiBuilder:Reflow() end;height=r.child:GetHeight() end
        if r.label then
          if r.text then r.label:SetText(r.text()) end
          r.label:SetWidth(available); height=math.max(height,r.label:GetStringHeight()+T.RowGap)
        end
        if r.check then
          r.check.text:SetWidth(math.max(40,available-T.CheckboxSize-T.CheckboxLabelGap))
          height=math.max(height,r.check.text:GetStringHeight()+12)
        end
        if r.dropdown then
          r.fieldLabel:SetWidth(available);r.dropdown:FitDropdownWidth(available)
          local labelHeight=math.max(18,r.fieldLabel:GetStringHeight())
          r.dropdown:ClearAllPoints();r.dropdown:SetPoint("TOPLEFT",0,-labelHeight-6)
          r.dropdown:Refresh();height=math.max(height,labelHeight+6+r.dropdown:GetHeight()+T.RowGap)
        end
        if r.slider then
          local c=r.slider;c.tooltipLabel:SetWidth(available)
          local labelHeight=math.max(18,c.tooltipLabel:GetStringHeight())
          c:ClearAllPoints();c:SetPoint("TOPLEFT",0,-labelHeight-6)
          c.numberBox:ClearAllPoints();c.numberBox:SetPoint("TOPLEFT",T.SliderWidth+14,-labelHeight-2)
          c.inputFeedback:ClearAllPoints();c.inputFeedback:SetPoint("TOPLEFT",0,-labelHeight-34);c.inputFeedback:SetWidth(available)
          height=math.max(height,labelHeight+34+(c.inputFeedback:IsShown() and c.inputFeedback:GetStringHeight()+T.RowGap or 0))
        end
        r.frame:SetHeight(height);rowHeight=math.max(rowHeight,height);count=count+1;kind=r.kind;lastColumns=columns;previousGroup=r.disclosure
      end
    end
    top=top-rowHeight
    page:SetHeight(math.max(1,-top)); parent:SetHeight(math.max(1,-y+page:GetHeight()))
  end
  local sentinel=CreateFrame("Frame",nil,page); sentinel.Refresh=refresh; sentinel.layoutRefresh=true; sentinel.ignoreModuleEnabled=true
  UI:RegisterControl(page,sentinel)
  function L:Finish() refresh(); return y-page:GetHeight() end
  return L
end
