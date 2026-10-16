local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
-- One-column detail rows. Only short child checks share a row. Height changes
-- use the presenter's existing OnSizeChanged path, including cached tabs.
function UI:CreateDetailLayout(parent,y,key)
  local rows={}; local page=CreateFrame("Frame",nil,parent)
  page:SetPoint("TOPLEFT",0,y); page:SetWidth(parent:GetWidth()); page.moduleKey=key
  local function row(height,visible,indent)
    local f=CreateFrame("Frame",nil,page); f:SetWidth(page:GetWidth()-(indent or 0)); f:SetHeight(height)
    rows[#rows+1]={frame=f,height=height,visible=visible,indent=indent or 0}; return f
  end
  local L={page=page}
  function L:Fields(frame,height,visible)
    local f=row(height,visible); frame:SetParent(f); frame:SetPoint("TOPLEFT",0,0); frame:SetHeight(height);rows[#rows].child=frame
  end
  function L:Section(title)
    local f=row(T.SectionGap+36); UI:CreateSection(f,title,0)
  end
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
    rows[#rows].dropdown=c;rows[#rows].fieldLabel=label;UI:AttachTooltip(c,title,tooltip); return c
  end
  function L:Slider(title,min,max,step,get,set,format,visible)
    local f=row(T.SliderRowHeight)
    local c=UI:CreateSlider(f,title,"",0,0,min,max,step,get,set,format,visible);rows[#rows].slider=c
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
        if kind~="compact" and kind~="showPower" then c.layoutWidth=wide and (width-180-T.ColumnGap-T.ContentPadding)/2 or math.min(T.DropdownWidth,width-T.ContentPadding); c:SetWidth(c.layoutWidth) end
        captions[index]:ClearAllPoints(); captions[index]:SetPoint("TOPLEFT",x,top+20)
        captions[index]:SetWidth(wide and (width-180-T.ColumnGap)/2 or width-T.ContentPadding)
      end
      return wide and T.DropdownRowHeight or (28+2*T.DropdownRowHeight)
    end
  end
  local function refresh()
    local top=0; local width=parent:GetWidth()
    page:SetWidth(width)
    for _,r in ipairs(rows) do
      local show=not r.visible or r.visible()
      r.frame:SetShown(show)
      if show then
        r.frame:ClearAllPoints(); r.frame:SetPoint("TOPLEFT",r.indent,top); r.frame:SetWidth(width-r.indent)
        local height=r.flow and r.flow(width-r.indent) or r.height
        if r.child then r.child:SetWidth(width-r.indent);if r.child.uiBuilder then r.child.uiBuilder:Reflow() end;height=r.child:GetHeight() end
        if r.label then
          if r.text then r.label:SetText(r.text()) end
          r.label:SetWidth(width-r.indent); height=math.max(height,r.label:GetStringHeight()+T.RowGap)
        end
        if r.check then
          r.check.text:SetWidth(math.max(40,width-r.indent-T.CheckboxSize-T.CheckboxLabelGap))
          height=math.max(height,r.check.text:GetStringHeight()+12)
        end
        if r.dropdown then
          r.fieldLabel:SetWidth(width-r.indent);r.dropdown.layoutWidth=width-r.indent;r.dropdown:SetWidth(width-r.indent)
          local labelHeight=math.max(18,r.fieldLabel:GetStringHeight())
          r.dropdown:ClearAllPoints();r.dropdown:SetPoint("TOPLEFT",0,-labelHeight-6)
          r.dropdown:Refresh();height=math.max(height,labelHeight+6+r.dropdown:GetHeight()+T.RowGap)
        end
        if r.slider then
          local c=r.slider;c.tooltipLabel:SetWidth(width-r.indent)
          local labelHeight=math.max(18,c.tooltipLabel:GetStringHeight())
          c:ClearAllPoints();c:SetPoint("TOPLEFT",0,-labelHeight-6)
          c.numberBox:ClearAllPoints();c.numberBox:SetPoint("TOPLEFT",T.SliderWidth+14,-labelHeight-2)
          c.inputFeedback:ClearAllPoints();c.inputFeedback:SetPoint("TOPLEFT",0,-labelHeight-34);c.inputFeedback:SetWidth(width-r.indent)
          height=math.max(height,labelHeight+34+(c.inputFeedback:IsShown() and c.inputFeedback:GetStringHeight()+T.RowGap or 0))
        end
        r.frame:SetHeight(height); top=top-height
      end
    end
    page:SetHeight(math.max(1,-top)); parent:SetHeight(math.max(1,-y+page:GetHeight()))
  end
  local sentinel=CreateFrame("Frame",nil,page); sentinel.Refresh=refresh; sentinel.layoutRefresh=true; sentinel.ignoreModuleEnabled=true
  UI:RegisterControl(page,sentinel)
  function L:Finish() refresh(); return y-page:GetHeight() end
  return L
end
