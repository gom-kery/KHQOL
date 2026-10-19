local _,K=...
local UI,T=K.UI,K.UI.Theme
function UI:SettingsAccordionID(parent,title)
  local route=self.SettingsNavigation and self.SettingsNavigation:Context(parent) or {}
  return "settings/"..(self.SettingsNavigation and self.SettingsNavigation:ID(route,title) or title).."/"..(route.scope or "")
end
function UI:RefreshAccordionLayout(parent)
  if self.accordionReflowing then return end
  self.accordionReflowing=true
  local s=K.settings;local root=s and s.activeContent
  -- Nested fields change height before their enclosing rows can move. Refresh
  -- the active layout owner as well as the section, including detail sentinels.
  local target,node=parent,parent
  for _=1,64 do
    if root and node==root then target=root;break end
    if not node or node==UIParent then break end;node=node:GetParent()
  end
  self:Refresh(target)
  local panel=root and (root.activePanel or root) or parent
  if panel.Reflow then panel:Reflow() end
  if root then self:ReflowSettingsRoot(root);s:UpdateContentHeight() end
  self.accordionReflowing=nil
  -- ScrollFrame/font geometry can settle after this click's reflow. Reuse the
  -- coalesced display pass used by tab changes, after the final visibility.
  self:QueueDisplayRefresh(root or parent)
end
function UI:CreateSettingsAccordion(parent,title,id,changed,ancestor,expanded)
  self.disclosureStates=self.disclosureStates or {}
  if self.disclosureStates[id]==nil then self.disclosureStates[id]=expanded~=false end
  local group={id=id,title=title,parent=ancestor}
  local row=CreateFrame("Frame",nil,parent);row:SetSize(parent:GetWidth(),T.ButtonHeight);row:EnableMouse(false);row.settingsNoIndex=true
  local toggle=self:CreateButton(row,"",0,0,T.ButtonHeight,function()
    if group.collapsible==false then return end
    UI:CloseDropdown();UI:CloseColorPicker()
    UI.disclosureStates[id]=not UI.disclosureStates[id];group:Refresh();changed()
  end)
  toggle:SetSize(T.ButtonHeight,T.ButtonHeight);toggle.ignoreModuleEnabled=true;toggle.navigationOnly=true
  local fs=toggle:GetFontString();fs:SetWidth(T.ButtonHeight);fs:SetWordWrap(false);fs:SetJustifyH("CENTER")
  local label=self:CreateLabel(row,title,T.ButtonHeight+T.RowGap,-6,T.SectionFontSize)
  label:SetWidth(math.max(1,parent:GetWidth()-T.ButtonHeight-T.RowGap))
  local function fit()
    local x=group.collapsible==false and 0 or T.ButtonHeight+T.RowGap
    label:ClearAllPoints();label:SetPoint("TOPLEFT",x,-6)
    label:SetWidth(math.max(1,row:GetWidth()-x));row:SetHeight(math.max(T.ButtonHeight,label:GetStringHeight()+12))
  end
  row:HookScript("OnSizeChanged",fit)
  group.row,group.toggle,group.label=row,toggle,label;toggle.settingsDisclosure=group
  function group:IsExpanded() return self.collapsible==false or UI.disclosureStates[self.id] end
  function group:Refresh()
    self.toggle:SetText(UI.disclosureStates[self.id] and "▼" or "▶");self.toggle:SetShown(self.collapsible~=false)
    local info=self.toggle.tooltipDescription
    row.tooltipDescription=info~="클릭하여 설정 항목을 접거나 펼칩니다." and info or ""
    row:EnableMouse(self.collapsible==false and row.tooltipDescription~="");fit()
  end
  function group:SetOptionCount(count)
    self.optionCount=count;self.collapsible=count>1;self:Refresh()
  end
  function group:Expand()
    if self.parent then self.parent:Expand() end
    if not UI.disclosureStates[self.id] then UI.disclosureStates[self.id]=true;self:Refresh();changed() end
  end
  local refresh=toggle.Refresh;toggle.Refresh=function() refresh();group:Refresh() end
  self:AttachTooltip(toggle,title,"클릭하여 설정 항목을 접거나 펼칩니다.")
  self:AttachTooltip(row,title,"")
  toggle:Refresh();return group
end
function UI:SettingsCellOptionCount(cell)
  if cell.optionCount~=nil then return cell.optionCount end
  if cell.kind=="accordion" or cell.kind=="auraHeading" or cell.kind=="description" or cell.kind=="lookupStatus" or cell.kind=="effectPreview" then return 0 end
  if cell.kind=="minimap-list" then return 2 end
  if cell.block then return cell.block:GetObjectType()=="FontString" and 0 or 2 end
  return #cell.regions>0 and 1 or 0
end
function UI:ReflowRegisteredPanels(root)
  local list=root.registeredLayoutFrames
  if not list or root.registeredLayoutVersion~=self.layoutVersion then
  list={}
  for frame in pairs(self.refreshParents) do
    if frame~=root and frame.uiBuilders then
      local p=frame:GetParent();local depth=0
      while p and p~=UIParent and depth<64 do
        depth=depth+1;if p==root then list[#list+1]={frame=frame,depth=depth};break end;p=p:GetParent()
      end
    end
  end
  table.sort(list,function(a,b) return a.depth<b.depth end)
  root.registeredLayoutFrames=list;root.registeredLayoutVersion=self.layoutVersion
  end
  for _,item in ipairs(list) do
    local frame=item.frame
    if frame:IsVisible() then
      local width=frame:GetParent():GetWidth()
      if frame:GetWidth()~=width then frame:SetWidth(width) end
      if frame.layoutWidth~=width then frame.uiBuilders[1]:Reflow() end
    end
  end
end
function UI:RefreshLayoutOnly(root)
  if not root then return end
  for parent in pairs(self.refreshParents) do
    if parent:IsVisible() then
      local f=parent
      for _=1,64 do
        if f==root then
          for _,control in ipairs(parent.uiControls or {}) do if control.layoutRefresh then control:Refresh() end end
          break
        end
        if not f or f==UIParent then break end
        f=f:GetParent()
      end
    end
  end
end
-- Reflow only controls registered by the existing KHQOL builder. Never inspect
-- UIParent or Blizzard descendants. Values/callbacks and input editors survive.
local function remember(parent,region,x,y,adjust)
  local b=parent.uiBuilder;local cell=b and b.activeCell
  if not cell or not region then return end
  local ox=(x or 0)-cell.x
  region.settingsDisclosure=cell.disclosure
  cell.regions[#cell.regions+1]={region=region,x=ox,y=(y or 0)-cell.top,adjust=adjust,right=ox>cell.width*.7}
end
local originalLabel=UI.CreateLabel
local originalDivider=UI.CreateDivider
function UI:CreateDivider(parent,y)
  local line=originalDivider(self,parent,y)
  remember(parent,line,0,y,function(region,width) region:SetWidth(width) end)
  return line
end
function UI:CellBackground() end
function UI:CreateLabel(parent,text,x,y,size)
  local f=originalLabel(self,parent,text,x,y,size)
  local cell=parent.uiBuilder and parent.uiBuilder.activeCell
  if cell and text and text~="" and not f.khqolInputFeedback then cell.caption=text end
  remember(parent,f,x,y,function(region,width,ox) region:SetWidth(math.max(40,width-ox)) end)
  return f
end
local originals={}
for _,name in ipairs({"CreateCheckbox","CreateButton","CreateSlider","CreateDropdown","CreateEditBox","CreateColorPicker"}) do originals[name]=UI[name] end
function UI:CreateCheckbox(parent,title,x,y,get,set,enabled)
  local c=originals.CreateCheckbox(self,parent,title,x,y,get,set,enabled)
  remember(parent,c,x,y,function(control,width,ox) control.text:SetWidth(math.max(40,width-ox-T.CheckboxSize-T.CheckboxLabelGap-(control.layoutLabelReserve or 0))) end)
  if UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,title,get,set,enabled) end
  return c
end
function UI:CreateButton(parent,title,x,y,width,click,enabled)
  local c=originals.CreateButton(self,parent,title,x,y,width,click,enabled)
  remember(parent,c,x,y,function(control,w,ox)
    local wanted=control.layoutPreferredWidth or UI:MeasureButtonText(control,control:GetText())+24
    control:SetWidth(math.max(26,math.min(w-ox,wanted)))
  end)
  if UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,title,nil,click,enabled) end
  return c
end
function UI:CreateSlider(parent,title,description,x,y,min,max,step,get,set,format,enabled,normalize)
  local c,box=originals.CreateSlider(self,parent,title,description,x,y,min,max,step,get,set,format,enabled,normalize)
  remember(parent,c,x,y-24)
  remember(parent,box,x+T.SliderWidth+14,y-20,function(control,width,ox) control:SetWidth(math.max(56,math.min(86,width-ox))) end)
  if UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,title,get,set,enabled,description) end
  return c,box
end
function UI:CreateDropdown(parent,x,y,width,options,get,set,enabled)
  local c=originals.CreateDropdown(self,parent,x,y,width,options,get,set,enabled)
  remember(parent,c,x,y,function(control,w,ox) control:FitDropdownWidth(math.max(1,w-ox)) end)
  local cell=parent.uiBuilder and parent.uiBuilder.activeCell
  if cell and cell.caption and UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,cell.caption,get,set,enabled) end
  return c
end
function UI:CreateEditBox(parent,x,y,width,get,set,enabled)
  local c=originals.CreateEditBox(self,parent,x,y,width,get,set,enabled)
  local cell=parent.uiBuilder and parent.uiBuilder.activeCell
  local difference=cell and cell.width-(x-cell.x)-(width or T.DropdownWidth) or 0
  remember(parent,c,x,y,function(control,w,ox) control:SetWidth(math.max(56,w-ox-difference)) end)
  if cell and cell.caption and UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,cell.caption,get,set,enabled) end
  return c
end
function UI:CreateColorPicker(parent,title,x,y,get,set,enabled,restore,alpha)
  local c=originals.CreateColorPicker(self,parent,title,x,y,get,set,enabled,restore,alpha)
  if UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,title,get,set,enabled) end
  return c
end
local createBuilder=UI.CreateBuilder
function UI:CreateBuilder(parent,y)
  parent.settingsFieldTwoColumnWidth=parent.settingsFieldTwoColumnWidth or 480
  parent.settingsCompactDisclosures=true
  local b=createBuilder(self,parent,y);parent.uiBuilder=b
  self.layoutVersion=(self.layoutVersion or 0)+1;parent.layoutCells=nil
  parent.uiBuilders=parent.uiBuilders or {};parent.uiBuilders[#parent.uiBuilders+1]=b;b.order=#parent.uiBuilders;b.flowGroup=0
  b.cells={};b.startY=y or 0;b.originalBottom=b.startY
  local cell=b.Cell;local flush=b.Flush;local section=b.Section;local description=b.Description
  function b:Flush() self.activeCell=nil;self.flowGroup=self.flowGroup+1;flush(self) end
  function b:Cell(kind,columns,height)
    parent.uiBuilder=self
    local width=parent:GetWidth()>0 and parent:GetWidth() or T.ContentWidth
    local actual=width<(kind=="check" and T.CheckTwoColumnWidth or parent.settingsFieldTwoColumnWidth or T.FieldTwoColumnWidth) and 1 or columns
    local saved=T.ContentWidth;T.ContentWidth=width
    local x,top,w=cell(self,kind,actual,height);T.ContentWidth=saved
    local item={builder=self,group=self.flowGroup,order=#self.cells+1,kind=kind,columns=columns,height=height,x=x,top=top,width=w,regions={},disclosure=self.currentDisclosure}
    if self.lastCell and top==self.lastCell.top then item.gap=0
    else item.gap=math.max(0,(self.lastCell and self.lastCell.top-self.lastCell.height or self.originalBottom)-top) end
    parent.layoutCells=nil;self.cells[#self.cells+1]=item;self.lastCell=item;self.activeCell=item;self.originalBottom=self.y
    return x,top,w
  end
  function b:EndSection()
    if self.sectionDisclosure then self.currentDisclosure=self.sectionDisclosure.parent;self.sectionDisclosure=nil end
    self:Flush()
  end
  function b:Accordion(title,key,expanded)
    self:EndSection();parent.uiBuilder=self;parent.khqolSection=title
    local x,top,width=self:Cell("accordion",1,T.SectionGap+T.ButtonHeight+T.RowGap)
    self.activeCell.full=true
    local group=UI:CreateSettingsAccordion(parent,title,key or UI:SettingsAccordionID(parent,title),function()
      b:Reflow();UI:RefreshAccordionLayout(parent)
    end,self.currentDisclosure,expanded)
    group.builder=self;group.row:SetPoint("TOPLEFT",x,top-T.SectionGap)
    remember(parent,group.row,x,top-T.SectionGap,function(region,w) region:SetWidth(w) end)
    self.disclosures=self.disclosures or {};self.disclosures[#self.disclosures+1]=group
    self.lastControl,self.lastTitle=group.toggle,title
    self:Flush();self.currentDisclosure=group
    return group
  end
  function b:Section(title)
    local group=self:Accordion(title,nil,true);self.sectionDisclosure=group
  end
  function b:Color(title,get,set,enabled,restore,alpha)
    local x,top,width=self:Cell("inlineColor",2,T.RowHeight+T.RowGap)
    local row=CreateFrame("Frame",nil,parent);row:SetSize(width,T.ButtonHeight);row:SetPoint("TOPLEFT",x,top)
    row.settingsNoIndex=true;row.settingsDisclosure=self.currentDisclosure
    local label=UI:CreateLabel(row,title,0,-6);label:SetWordWrap(true)
    local c=UI:CreateColorPicker(row,"",0,24,get,set,enabled,restore,alpha)
    local preferred=c:GetWidth();local textWidth=label:GetUnboundedStringWidth()
    local function fit(w)
      local labelWidth=math.max(40,math.min(textWidth,w-preferred-T.RowGap))
      label:SetWidth(labelWidth);c:ClearAllPoints();c:SetPoint("TOPLEFT",labelWidth+T.RowGap,0)
      row:SetHeight(math.max(T.ButtonHeight,label:GetStringHeight()+12))
    end
    local refresh=c.Refresh;c.Refresh=function() refresh();UI:ApplyAvailability(c,enabled,{label});fit(row:GetWidth()) end
    c.inlineLabel,c.inlineRow=label,row;c.settingsDisclosure=self.currentDisclosure
    remember(parent,row,x,top,function(region,w) region:SetWidth(w);fit(w) end)
    if UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,c,title,get,set,enabled,"색과 투명도를 변경합니다.") end
    c:Refresh();self.lastControl,self.lastTitle=c,title;return c
  end
  function b:Block(frame,height,visible)
    local h=type(height)=="function" and height() or height or frame:GetHeight()
    local x,top,width=self:Cell("block",1,math.max(1,h));self.activeCell.full=true
    local item=self.activeCell;item.visible=visible;item.block=frame
    frame:ClearAllPoints();frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,top)
    remember(parent,frame,x,top,function(region,w)
      region:SetWidth(w)
      if region.uiBuilder then region.uiBuilder:Reflow() end
      if type(height)=="function" then region:SetHeight(math.max(1,height())) end
    end)
    return item
  end
  function b:Description(text,important)
    if not important and self.lastControl then return description(self,text,important) end
    self:Flush();parent.uiBuilder=self;local top=self.y
    local item={builder=self,group=self.flowGroup,order=#self.cells+1,kind="description",columns=1,height=26,x=0,top=top,width=parent:GetWidth(),regions={},gap=0,full=true,disclosure=self.currentDisclosure}
    if self.lastCell then item.gap=math.max(0,self.lastCell.top-self.lastCell.height-top) end
    parent.layoutCells=nil;self.cells[#self.cells+1]=item;self.lastCell=item;self.activeCell=item
    local f=UI:CreateDescription(parent,text,0,top);self.y=top-math.max(18,f:GetStringHeight())-T.RowGap
    item.height=top-self.y;item.description=f;self.activeCell=nil;self.originalBottom=self.y
    return f
  end
  for _,method in ipairs({"Dropdown","Edit"}) do
    local original=b[method]
    b[method]=function(self,title,...)
      local control=original(self,title,...)
      if UI.SettingsNavigation then
        local args={...};local get,set,enabled
        if method=="Dropdown" then get,set,enabled=args[2],args[3],args[4] else get,set,enabled=args[1],args[2],args[3] end
        UI.SettingsNavigation:Attach(parent,control,title,get,set,enabled)
      end
      return control
    end
  end
  function b:BeginDisclosure(title,key,count)
    local route=UI.SettingsNavigation and UI.SettingsNavigation:Context(parent) or {}
    local id=(route.module or "general").."/"..(route.tab or "").."/"..key
    return self:Accordion(title,id,false)
  end
  function b:Track(region,x,y,adjust) remember(parent,region,x,y,adjust) end
  function b:EndDisclosure() self:EndSection();self.currentDisclosure=self.currentDisclosure and self.currentDisclosure.parent end
  function b:Reflow()
    if parent.buildersReflowing then return end
    parent.buildersReflowing=true
    local function baseline(item) return item.top+(item.kind=="section" and T.SectionGap or 0) end
    local cells=parent.layoutCells
    if not cells then
      cells={}
      for _,builder in ipairs(parent.uiBuilders) do for _,item in ipairs(builder.cells) do cells[#cells+1]=item end end
      table.sort(cells,function(a,b)
        if baseline(a)~=baseline(b) then return baseline(a)>baseline(b) end
        if a.builder~=b.builder then return a.builder.order<b.builder.order end
        return a.order<b.order
      end)
      parent.layoutCells=cells
    end
    local groups={}
    for _,builder in ipairs(parent.uiBuilders) do for _,g in ipairs(builder.disclosures or {}) do groups[g]=0 end end
    for _,item in ipairs(cells) do
      local amount=UI:SettingsCellOptionCount(item);local group=item.disclosure
      while group do if groups[group]~=nil then groups[group]=groups[group]+amount end;group=group.parent end
    end
    for group,amount in pairs(groups) do group:SetOptionCount(amount) end
    if #cells==0 then parent.buildersReflowing=nil;return end
    local width=parent.settingsFullWidth and parent:GetWidth() or math.min(T.FormMaxWidth,parent:GetWidth())
    local top=baseline(cells[1]);local count,kind,rowHeight,lastColumns=0,nil,0,0;local buttonRight=0
    local previous,originalBottom
    for _,item in ipairs(cells) do
      local shown=not item.visible or item.visible();local disclosure=item.disclosure
      while disclosure do
        if not (disclosure.IsExpanded and disclosure:IsExpanded() or not disclosure.IsExpanded and UI.disclosureStates[disclosure.id]) then shown=false end
        disclosure=disclosure.parent
      end
      for _,r in ipairs(item.regions) do
        r.region:SetShown(shown and (not r.region.khqolInputFeedback or (r.region:GetText() or "")~=""))
        if r.region.khqolTooltipArea then r.region.khqolTooltipArea:SetShown(shown) end
      end
      if shown then
        local minimum=item.kind=="check" and T.CheckTwoColumnWidth or parent.settingsFieldTwoColumnWidth or T.FieldTwoColumnWidth
        local columns=item.full and 1 or width<minimum and 1 or item.columns
        if item.kind=="check" and columns>1 then
          for _,r in ipairs(item.regions) do
            local c=r.region
            if c.text and c.text.GetStringWidth then
              c.text:SetWidth(width)
              if c.text:GetStringWidth()+T.CheckboxSize+T.CheckboxLabelGap+(c.layoutLabelReserve or 0)>(width-(columns-1)*T.ColumnGap)/columns then columns=1 end
            end
          end
        end
        -- Action pairs use their text width and a small gap, keeping order/groups.
        local buttonWidth
        if item.kind=="button" and not item.full then
          columns=item.columns;buttonWidth=26
          for _,r in ipairs(item.regions) do
            local c=r.region
            if c.khqolSkinned then buttonWidth=math.max(buttonWidth,r.x+(c.layoutPreferredWidth or UI:MeasureButtonText(c,c:GetText())+24)) end
          end
          buttonWidth=math.min(width,buttonWidth)
        end
        local gap=previous and baseline(previous)~=baseline(item) and math.max(0,originalBottom-baseline(item)) or 0
        local newRow=kind~=item.kind or columns~=lastColumns or count>=columns or gap>0 or item.full or previous and (previous.builder~=item.builder or previous.group~=item.group)
        if buttonWidth and count>0 and buttonRight+T.RowGap+buttonWidth>width then newRow=true end
        if newRow then top=top-rowHeight-gap;count=0;rowHeight=0;kind=item.kind;buttonRight=0 end
        local w=buttonWidth or (width-(columns-1)*T.ColumnGap)/columns
        local x=buttonWidth and (count>0 and buttonRight+T.RowGap or 0) or count*(w+T.ColumnGap)
        if buttonWidth then buttonRight=x+w end
        local anchorTop=top-(item.kind=="section" and T.SectionGap or 0)
        local labelHeight=18
        for _,r in ipairs(item.regions) do
          local ox=r.x+(r.right and w-item.width or 0)
          if r.adjust then r.adjust(r.region,w,ox) end
          if r.region:GetObjectType()=="FontString" and r.y>=-6 and not r.region.khqolInputFeedback then labelHeight=math.max(labelHeight,r.region:GetStringHeight()) end
        end
        local extra=math.max(0,labelHeight-18);local height=item.block and 1 or item.height
        for _,r in ipairs(item.regions) do
          local c=r.region;local ox=r.x+(r.right and w-item.width or 0)
          local dy=r.y-(r.y<=-20 and extra or 0)
          c:ClearAllPoints();c:SetPoint("TOPLEFT",parent,"TOPLEFT",x+ox,anchorTop+dy)
          if c.text then
            c.text:SetWordWrap(true);height=math.max(height,-dy+c.text:GetStringHeight()+12)
          end
          if c.khqolSkinned and c:GetFontString() then
            local fs=c:GetFontString();fs:SetWordWrap(not c.layoutGlyph);fs:SetWidth(math.max(10,c:GetWidth()-(c.layoutGlyph and 0 or c.swatch and 42 or 20)))
            c:SetHeight(math.max(T.ButtonHeight,fs:GetStringHeight()+10))
          end
          if c:GetObjectType()=="FontString" then
            if c:IsShown() then height=math.max(height,-dy+c:GetStringHeight()+T.RowGap) end
          else height=math.max(height,-dy+c:GetHeight()+T.RowGap) end
          local area=c.khqolTooltipArea
          if area then area:SetSize(math.max(1,c:GetWidth()),math.max(1,c:GetStringHeight())) end
        end
        if item.description then height=math.max(18,item.description:GetStringHeight())+T.RowGap end
        item.layoutX,item.layoutTop,item.layoutWidth,item.layoutHeight=x,anchorTop,w,height
        rowHeight=math.max(rowHeight,height);count=count+1;lastColumns=columns
        if not previous or baseline(previous)~=baseline(item) then originalBottom=baseline(item)-item.height
        else originalBottom=math.min(originalBottom,baseline(item)-item.height) end
        previous=item
      elseif parent.settingsCompactDisclosures then
        originalBottom=math.min(originalBottom or baseline(item),baseline(item)-item.height)
      end
    end
    local height=math.max(1,-top+rowHeight)
    self.reflowBottom=top-rowHeight
    if parent:GetHeight()~=height then parent:SetHeight(height) end
    parent.layoutWidth=parent:GetWidth();parent.buildersReflowing=nil
  end
  if not parent.khqolBuilderSizeHook then
    parent.khqolBuilderSizeHook=true
    parent:HookScript("OnSizeChanged",function(_,w)
      if parent.layoutWidth~=w then parent.uiBuilders[1]:Reflow() end
    end)
  end
  return b
end

function UI:ReflowSettingsRoot(parent)
  local s=K.settings;local active=s and s.activeContent
  if self.settingsReflowing or not active or (parent~=active and parent~=active.activePanel) then return end
  self.settingsReflowing=true
  local panel=active.activePanel or active
  if panel.uiBuilders then panel.uiBuilders[1]:Reflow() end
  self:ReflowRegisteredPanels(panel)
  if panel.Reflow then panel:Reflow() end
  if panel~=active and active.Reflow then active:Reflow() end
  if panel==active and panel.uiBuilders then
    local bottom=panel.uiBuilders[1].reflowBottom
    if bottom then active.contentHeight=-bottom+T.ContentPadding end
  end
  s:SetPageScrollLayout(s.page or "general");s:UpdateContentHeight();self.settingsReflowing=nil
end
