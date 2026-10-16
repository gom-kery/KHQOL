local _,K=...
local UI,T=K.UI,K.UI.Theme
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
  local wanted=c:GetWidth()
  remember(parent,c,x,y,function(control,w,ox) control:SetWidth(math.max(26,math.min(w-ox,control.layoutPreferredWidth or wanted))) end)
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
  remember(parent,c,x,y,function(control,w,ox) control.layoutWidth=math.max(60,w-ox);control:SetWidth(control.layoutWidth) end)
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
  local b=createBuilder(self,parent,y);parent.uiBuilder=b
  self.layoutVersion=(self.layoutVersion or 0)+1;parent.layoutCells=nil
  parent.uiBuilders=parent.uiBuilders or {};parent.uiBuilders[#parent.uiBuilders+1]=b;b.order=#parent.uiBuilders;b.flowGroup=0
  b.cells={};b.startY=y or 0;b.originalBottom=b.startY
  local cell=b.Cell;local flush=b.Flush;local section=b.Section;local description=b.Description
  function b:Flush() self.activeCell=nil;self.flowGroup=self.flowGroup+1;flush(self) end
  function b:Cell(kind,columns,height)
    parent.uiBuilder=self
    local width=parent:GetWidth()>0 and parent:GetWidth() or T.ContentWidth
    local actual=width<(kind=="check" and T.CheckTwoColumnWidth or T.FieldTwoColumnWidth) and 1 or columns
    local saved=T.ContentWidth;T.ContentWidth=width
    local x,top,w=cell(self,kind,actual,height);T.ContentWidth=saved
    local item={builder=self,group=self.flowGroup,order=#self.cells+1,kind=kind,columns=columns,height=height,x=x,top=top,width=w,regions={},disclosure=self.currentDisclosure}
    if self.lastCell and top==self.lastCell.top then item.gap=0
    else item.gap=math.max(0,(self.lastCell and self.lastCell.top-self.lastCell.height or self.originalBottom)-top) end
    parent.layoutCells=nil;self.cells[#self.cells+1]=item;self.lastCell=item;self.activeCell=item;self.originalBottom=self.y
    return x,top,w
  end
  function b:Section(title)
    self:Flush();parent.uiBuilder=self;parent.khqolSection=title
    local top=self.y;local item={builder=self,group=self.flowGroup,order=#self.cells+1,kind="section",columns=1,height=T.SectionGap+36,x=0,top=top-T.SectionGap,width=parent:GetWidth(),regions={},gap=0,full=true,disclosure=self.currentDisclosure}
    if self.lastCell then item.gap=math.max(0,self.lastCell.top-self.lastCell.height-top) end
    parent.layoutCells=nil;self.cells[#self.cells+1]=item;self.lastCell=item;self.activeCell=item
    self.y=UI:CreateSection(parent,title,self.y)
    local hint=CreateFrame("Frame",nil,parent);hint:SetPoint("TOPLEFT",0,top-T.SectionGap);hint:SetSize(parent:GetWidth(),24);hint:EnableMouse(false);hint.tooltipRegion=true
    remember(parent,hint,0,top-T.SectionGap,function(region,width) region:SetWidth(width) end)
    self.activeCell=nil;self.originalBottom=self.y
    self.lastControl,self.lastTitle=hint,title
    local root=parent
    while root and root~=UIParent and not root.settingsModuleKey do root=root:GetParent() end
    local key=root and root.settingsModuleKey
    if key and title:find("위치",1,true) and not root.positionShortcut and UI.SettingsRegistry.positionModules[key] then
      root.positionShortcut=true;local button=self:Button("통합 위치 편집",function() K.PositionEditor:Enter(key,"group") end);button.navigationOnly=true;self:Flush()
    end
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
    self:Section(title)
    UI.disclosureStates=UI.disclosureStates or {}
    local route=UI.SettingsNavigation and UI.SettingsNavigation:Context(parent) or {}
    local id=(route.module or "general").."/"..(route.tab or "").."/"..key
    local group={builder=self,id=id,parent=self.currentDisclosure}
    function group:Expand()
      if self.parent then self.parent:Expand() end
      UI.disclosureStates[self.id]=true;self.builder:Reflow()
    end
    local toggle=self:Button("",function()
      UI:CloseDropdown();UI.disclosureStates[id]=not UI.disclosureStates[id]
      self:Reflow()
      if K.settings then K.settings:UpdateContentHeight() end
    end)
    toggle.navigationOnly=true;toggle.ignoreModuleEnabled=true;toggle.layoutPreferredWidth=T.FormMaxWidth
    self.activeCell.full=true
    group.toggle=toggle;group.title=title;group.count=count
    if UI.SettingsNavigation then UI.SettingsNavigation:Attach(parent,toggle,"고급 옵션 펼치기") end
    self:Flush();self.currentDisclosure=group
    self.disclosures=self.disclosures or {};self.disclosures[#self.disclosures+1]=group
    return group
  end
  function b:Track(region,x,y,adjust) remember(parent,region,x,y,adjust) end
  function b:EndDisclosure() self:Flush();self.currentDisclosure=self.currentDisclosure and self.currentDisclosure.parent end
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
    for _,builder in ipairs(parent.uiBuilders) do for _,g in ipairs(builder.disclosures or {}) do
      g.toggle:SetText((UI.disclosureStates[g.id] and "− 접기" or "+ 펼치기").." · "..g.title.." ("..g.count..")")
    end end
    if #cells==0 then parent.buildersReflowing=nil;return end
    local width=parent.settingsFullWidth and parent:GetWidth() or math.min(T.FormMaxWidth,parent:GetWidth())
    local top=baseline(cells[1]);local count,kind,rowHeight,lastColumns=0,nil,0,0
    local previous,originalBottom
    for _,item in ipairs(cells) do
      local shown=true;local disclosure=item.disclosure
      while disclosure do
        if not UI.disclosureStates[disclosure.id] then shown=false end
        disclosure=disclosure.parent
      end
      for _,r in ipairs(item.regions) do
        r.region:SetShown(shown and (not r.region.khqolInputFeedback or (r.region:GetText() or "")~=""))
        if r.region.khqolTooltipArea then r.region.khqolTooltipArea:SetShown(shown) end
      end
      if shown then
        local minimum=item.kind=="check" and T.CheckTwoColumnWidth or T.FieldTwoColumnWidth
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
        local gap=previous and baseline(previous)~=baseline(item) and math.max(0,originalBottom-baseline(item)) or 0
        local newRow=kind~=item.kind or columns~=lastColumns or count>=columns or gap>0 or item.full or previous and (previous.builder~=item.builder or previous.group~=item.group)
        if newRow then top=top-rowHeight-gap;count=0;rowHeight=0;kind=item.kind end
        local w=(width-(columns-1)*T.ColumnGap)/columns;local x=count*(w+T.ColumnGap)
        local anchorTop=top-(item.kind=="section" and T.SectionGap or 0)
        local labelHeight=18
        for _,r in ipairs(item.regions) do
          local ox=r.x+(r.right and w-item.width or 0)
          if r.adjust then r.adjust(r.region,w,ox) end
          if r.region:GetObjectType()=="FontString" and r.y>=-6 and not r.region.khqolInputFeedback then labelHeight=math.max(labelHeight,r.region:GetStringHeight()) end
        end
        local extra=math.max(0,labelHeight-18);local height=item.height
        for _,r in ipairs(item.regions) do
          local c=r.region;local ox=r.x+(r.right and w-item.width or 0)
          local dy=r.y-(r.y<=-20 and extra or 0)
          c:ClearAllPoints();c:SetPoint("TOPLEFT",parent,"TOPLEFT",x+ox,anchorTop+dy)
          if c.text then
            c.text:SetWordWrap(true);height=math.max(height,-dy+c.text:GetStringHeight()+12)
          end
          if c.khqolSkinned and c:GetFontString() then
            local fs=c:GetFontString();fs:SetWordWrap(true);fs:SetWidth(math.max(10,c:GetWidth()-(c.swatch and 42 or 20)))
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
  s:SetPageScrollLayout(s.page or "general");s:UpdateContentHeight();self.settingsReflowing=nil
end
