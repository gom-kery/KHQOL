local _, A = ...
local K = assert(_G.KHQOL, "Install and enable KHQOL.")
local UI, T = K.UI, K.UI.Theme
A.settingsPanels = {}
-- This optional module owns one sidebar page, immediately after Interface.
local registry=UI.SettingsRegistry
registry.groups.minimap={};registry.orders.minimap={}
K.MinimapSettings=UI:NewSettingsGroup("minimap")
for index,page in ipairs(registry.pages) do
    if page[1]=="interface" then
        table.insert(registry.pages,index+1,{"minimap","미니맵","미니맵과 버튼 정리를 설정합니다."});break
    end
end
for index,group in ipairs(registry.moduleGroups) do
    if group.title=="인터페이스" then table.insert(registry.moduleGroups,index+1,{title="미니맵",items={}});break end
end

local function commit(key)
    return function(value) A.db[key] = value; A:Request() end
end
local function checkbox(builder, title, key)
    return builder:Checkbox(title, function() return A.db[key] end, commit(key))
end
local function slider(builder, title, key, low, high, unit)
    return builder:Slider(title, low, high, 1, function() return A.db[key] end,
        commit(key), function(value) return value .. unit end)
end
local function dropdown(builder, title, key, options)
    return builder:Dropdown(title, options, function() return A.db[key] end, commit(key))
end
local function statusText()
    local lines = {}
    for _, key in ipairs({"combat", "appearance", "drawer", "color"}) do
        if A.messages[key] then lines[#lines + 1] = A.messages[key] end
    end
    return table.concat(lines, "\n")
end
local function finishPanel(content, builder, id)
    builder:Flush()
    local status = builder:Description("", true)
    status:SetTextColor(unpack(T.Warning))
    content.mapStatus = status
    content.settingsRoute.scope = "계정 공용 미니맵 설정"
    A.settingsPanels[id] = content
    function content:RefreshTab()
        if self:IsShown() then A.currentTab = id end
        A:RefreshSettings()
    end
    content:HookScript("OnHide", function() A:CloseSettingsEditors() end)
    return builder.y - T.ContentPadding
end

function A:OpenColor()
    if InCombatLockdown() then self.colorWanted = true; self:Request(); return end
    if not ColorPickerFrame and C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_ColorPickerFrame") end
    if not ColorPickerFrame or not ColorPickerFrame.GetColorRGB then
        self.messages.color = "현재 클라이언트에서 색상 선택기를 열 수 없습니다."
        self:RefreshSettings(); return
    end
    self.messages.color = nil
    UI:OpenColorPicker(function() local c = A.db.border; return c.r, c.g, c.b end,
        function(r, g, b)
            if A:Number(r) and A:Number(g) and A:Number(b) then
                local c = A.db.border; c.r, c.g, c.b = r, g, b; A:Request()
            end
        end, function() A:RefreshSettings() end)
    self.colorGeneration = UI.colorGeneration
end
function A:CloseSettingsEditors()
    if self.colorGeneration and self.colorGeneration == UI.colorGeneration then UI:CloseColorPicker() end
    self.colorGeneration = nil
end
function A:InitializeSettings() end
function A:FitWindow() end
function A:StopSettingsDrag() end
function A:ShowSettingsTab(id)
    local tab = id == "buttons" and "minimapButtons" or "minimap"
    if not K.settings then self.currentTab = id; self.openWanted = true; return end
    return UI.SettingsNavigation:Open({module="minimap", tab=tab})
end
function A:OpenSettings() return self:ShowSettingsTab(self.currentTab or "minimap") end

local function buildMinimap(content, y)
    content.settingsRoute.scope = "계정 공용 미니맵 설정"
    local b = UI:CreateBuilder(content, y)
    b:Section("미니맵")
    checkbox(b, "외형 사용", "appearance")
    b:Flush()
    dropdown(b, "모양", "shape", {{value="ROUND",text="원형"},{value="SQUARE",text="사각형"}})
    slider(b, "미니맵 크기", "size", 180, 300, " px")
    local color = b:Button("색상 변경", function() A:OpenColor() end)
    color.navigationOnly = true
    color.swatch = color:CreateTexture(nil, "OVERLAY")
    color.swatch:SetSize(14,14); color.swatch:SetPoint("LEFT",8,0)
    local refreshColor = color.Refresh
    color.Refresh = function(self)
        refreshColor(self)
        local c=A.db.border;self.swatch:SetColorTexture(c.r,c.g,c.b,1)
    end
    color:GetFontString():ClearAllPoints();color:GetFontString():SetPoint("LEFT",28,0);color:GetFontString():SetPoint("RIGHT",-8,0)
    color.layoutPreferredWidth = math.max(color:GetWidth()+24,140)
    color:SetWidth(color.layoutPreferredWidth)
    b:Section("지역명 표시")
    checkbox(b, "표시", "zone")
    b:Flush()
    dropdown(b, "위치", "zoneLocation", {{value="ABOVE",text="지도 외부-위"},{value="INSIDE",text="지도 내부-위"}})
    slider(b, "지역명 크기", "zoneScale", 100, 200, "%")
    b:Section("위치 · 지도 및 주변 아이콘")
    checkbox(b, "잠금", "locked")
    b:Flush()
    slider(b, "아이콘 크기", "elementScale", 70, 150, "%")
    b:Flush()
    for _, item in ipairs({{"mail","우편"},{"tracking","검색"},{"diel","낮/밤"}}) do
        local key=item[1]
        b:Checkbox(item[2],function() return A.db.elements[key] end,function(value) A.db.elements[key]=value;A:Request() end)
    end
    b:Flush()
    b:Button("미니맵 위치 초기화",function() A.db.position=nil;A:Request() end)
    b:Button("주변 아이콘 위치 초기화",function() A.db.elementPositions={};A:Request() end)
    return finishPanel(content,b,"minimap")
end

function A:RefreshButtonList()
    if not self.list or not self.Buttons then return end
    local records=self.Buttons.ordered
    local width=math.max(180,self.list:GetWidth())
    local narrow=width<500
    local rowHeight=narrow and 56 or 36
    for i, record in ipairs(records) do
        local row=self.rows[i]
        if not row then
            row=CreateFrame("Frame",nil,self.list)
            row.reference={record=record}
            local reference=row.reference
            row.check=UI:CreateCheckbox(row,"",0,0,function() return not A.db.excluded[reference.record.id] end,
                function(value)
                    local r=reference.record;A.db.excluded[r.id]=not value or nil;r.yielded=nil;A:Request()
                end)
            row.status=UI:CreateLabel(row,"",0,-4,11)
            row.status:SetTextColor(unpack(T.TextSecondary))
            self.rows[i]=row
        end
        row.reference.record=record
        row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(i-1)*rowHeight);row:SetSize(width,rowHeight)
        row.check.text:SetText(record.label);row.check.text:SetWordWrap(false)
        row.check.text:SetWidth(narrow and width-40 or width*.45-40)
        row.status:ClearAllPoints();row.status:SetPoint("TOPLEFT",narrow and 34 or width*.48,narrow and -30 or -4)
        row.status:SetWidth(narrow and width-40 or width*.52);row.status:SetWordWrap(false)
        local status=(record.status or "확인 대기"):gsub("수납 중","보관 중"):gsub("수납 제외","보관 제외")
        row.status:SetText(status)
        row.check.tooltipDescription=nil
        UI:AttachTooltip(row.check,record.label,status)
        row:Show();UI:Refresh(row)
    end
    for i=#records+1,#self.rows do self.rows[i]:Hide() end
    self.list:SetHeight(math.max(162,#records*rowHeight))
    self.noButtons:SetShown(#records==0)
end

local function buildButtons(content,y)
    content.settingsRoute.scope = "계정 공용 미니맵 설정"
    local b=UI:CreateBuilder(content,y)
    b:Section("버튼 보관")
    checkbox(b,"사용","drawer")
    b:Flush()
    b:Description("수납 버튼을 드래그해 화면 어디든 배치할 수 있습니다. 위치는 계정 공용으로 저장됩니다.",true)
    b:Button("수납 버튼 위치 초기화",function() A.Buttons:StopDrag();A.db.buttonPosition=nil;A:Request() end)
    b:Button("목록 새로고침",function() A.Buttons:Refresh() end)
    b:Flush()
    slider(b,"아이콘 크기","iconSize",20,30," px")
    dropdown(b,"방향","drawerDirection",{{value="UP",text="위"},{value="DOWN",text="아래"},{value="LEFT",text="왼쪽"},{value="RIGHT",text="오른쪽"}})
    b:Section("정렬")
    for _,item in ipairs({{"HORIZONTAL","가로형"},{"VERTICAL","세로형"}}) do
        local value=item[1]
        b:Checkbox(item[2],function() return A.db.drawerLayout==value end,function() A.db.drawerLayout=value;A:Request() end)
    end
    b:Section("보관 버튼 목록")
    b:Flush()
    local scroll=CreateFrame("ScrollFrame",nil,content,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",0,b.y);scroll:SetPoint("RIGHT",content,"RIGHT",-24,0);scroll:SetHeight(162)
    local list=CreateFrame("Frame",nil,scroll);list:SetSize(math.max(180,content:GetWidth()-24),162);scroll:SetScrollChild(list)
    list.settingsNoIndex=true
    A.list,A.listScroll,A.rows=list,scroll,{}
    A.noButtons=UI:CreateLabel(list,"보관할 버튼이 없습니다.",0,-8,13)
    A.noButtons:SetTextColor(unpack(T.TextSecondary))
    content:HookScript("OnSizeChanged",function()
        list:SetWidth(math.max(180,content:GetWidth()-24));A:RefreshButtonList()
    end)
    -- Enroll the viewport as one full-width cell in the existing layout.
    local marker=b:Description("",true)
    local cell=b.lastCell
    marker:Hide();cell.description=nil;cell.kind="minimap-list";cell.full=true;cell.height=162+T.SectionGap
    cell.regions={{region=scroll,x=0,y=0,adjust=function(region,width)
        region:SetWidth(math.max(180,width-24));list:SetWidth(math.max(180,width-24));A:RefreshButtonList()
    end}}
    b.y=cell.top-cell.height;b.originalBottom=b.y
    A:RefreshButtonList()
    return finishPanel(content,b,"buttons")
end

function A:RefreshSettings()
    if self.refreshing then return end
    self.refreshing=true
    for _,panel in pairs(self.settingsPanels) do
        if panel.mapStatus then panel.mapStatus:SetText(statusText()) end
        UI:Refresh(panel)
        if panel:IsShown() and panel.uiBuilders then panel.uiBuilders[1]:Reflow() end
    end
    self:RefreshButtonList()
    self.refreshing=false
end
function A:SetEnabled(enabled)
    self.enabled=enabled and true or false
    if not self.enabled then
        self.openWanted=nil;self.colorWanted=nil;self:CloseSettingsEditors()
        self.Minimap:StopDrag();self.Buttons:StopDrag()
    elseif not self.ready then self:Start() end
    self:Request(self.enabled)
end
function A:ResetSettings()
    self.Buttons:StopDrag()
    local copy=K.CopyProfileValue
    for key,value in pairs(self.defaults) do self.db[key]=copy(value) end
    self.db.position=nil
    self.db.buttonPosition=nil
    self:InitDB();self:Request(true)
end

K.ModuleRegistry:Register("minimap",{
    defaultEnabled=true,
    initialize=function(m) if not m.db then m:InitDB() end end,
    setEnabled=function(m,on) m:SetEnabled(on) end,
    profileChanged=function(m) m.colorWanted=nil;m:CloseSettingsEditors();m.Minimap:StopDrag();m.Buttons:StopDrag() end,
    applyProfile=function(m) m:Request() end,
    resetProfile=function(m) m:ResetSettings() end,
    resetScope=function() return "계정 공용 미니맵·버튼 정리 설정과 위치·보관 제외 목록을 기본값으로 복원합니다. 다른 모듈과 현재 프로필의 사용 ON/OFF는 유지합니다." end,
    availability=function(m) if m.messages.combat then return "pending",m.messages.combat end end,
    settings={group="minimap",id="minimap",title="미니맵",description="미니맵과 버튼 정리를 설정합니다. 세부 설정은 계정 공용입니다.",
        commands={"minimap","map","khmap"},build=buildMinimap,
        subtabs={{id="minimapButtons",title="버튼 정리",build=buildButtons}},
        search={
            {title="미니맵 모양·크기·테두리",description="원형·사각형, 크기, 색상",aliases="minimap map shape size border",route={tab="minimap",scope="계정 공용 미니맵 설정"}},
            {title="지역명·주변 아이콘·위치",description="우편·검색·낮/밤·잠금",aliases="zone mail tracking diel lock",route={tab="minimap",scope="계정 공용 미니맵 설정"}},
            {title="버튼 정리·보관 목록",description="방향·가로형·세로형·제외",aliases="drawer buttons storage",route={tab="minimapButtons",scope="계정 공용 미니맵 설정"}},
        }},
})
