local _, A = ...
local U = {controls={}}
A.UI = U
-- Standalone settings skin, matching the user's KHQOL theme palette.
-- No KHQOL runtime, assets, saved variables or refresh registry is required.
U.theme = {
    background={.065,.065,.065,1}, border={.36,.36,.36,1}, text={.92,.92,.92,1}, muted={.68,.68,.68,1},
    accent={114/255,173/255,165/255,1}, divider={.29,.29,.29,.6}, fill={.13,.13,.13,1},
    hover={.20,.20,.20,1}, selected={.24,.24,.24,1}, pressed={.08,.08,.08,1}, track={.30,.30,.30,1},
}
local T=U.theme

function U:Label(parent,text,x,y,width,size,color)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    f:SetPoint("TOPLEFT",x,-y);f:SetWidth(width or 240);f:SetJustifyH("LEFT")
    f:SetFont(STANDARD_TEXT_FONT or "Fonts\\2002.TTF",size or 13,"")
    f:SetTextColor(unpack(color or T.text));f:SetText(text or "")
    return f
end

function U:Surface(frame,fill,border)
    local bg=frame:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(unpack(fill or T.fill))
    local edges={}
    for _,edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
        local t=frame:CreateTexture(nil,"BORDER");t:SetColorTexture(unpack(border or T.border))
        if edge=="TOP" or edge=="BOTTOM" then t:SetHeight(1);t:SetPoint(edge.."LEFT");t:SetPoint(edge.."RIGHT")
        else t:SetWidth(1);t:SetPoint("TOP"..edge);t:SetPoint("BOTTOM"..edge) end
        edges[#edges+1]=t
    end
    return {fill=bg,edges=edges}
end

function U:Paint(surface,fill,border)
    if surface.rounded then
        surface.fill:SetVertexColor(unpack(fill))
        for _,edge in ipairs(surface.edges) do edge:SetVertexColor(unpack(border)) end
    else
        surface.fill:SetColorTexture(unpack(fill))
        for _,edge in ipairs(surface.edges) do edge:SetColorTexture(unpack(border)) end
    end
end

function U:RoundedSurface(frame)
    local path="Interface\\AddOns\\KH_map\\Media\\Switch.tga"
    local outline=frame:CreateTexture(nil,"BACKGROUND");outline:SetAllPoints();outline:SetTexture(path)
    outline:SetTexCoord(.5/256,63.5/256,.5/64,63.5/64)
    local fill=frame:CreateTexture(nil,"ARTWORK");fill:SetAllPoints();fill:SetTexture(path)
    fill:SetTexCoord(64.5/256,127.5/256,.5/64,63.5/64)
    return {fill=fill,edges={outline},rounded=true}
end

function U:Tip(frame,text)
    frame:HookScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(text,.9,.9,.9,1,true);GameTooltip:Show()
    end)
    frame:HookScript("OnLeave",function() GameTooltip:Hide() end)
end

function U:Button(parent,text,x,y,width,fn,height)
    local b=CreateFrame("Button",nil,parent)
    b:SetPoint("TOPLEFT",x,-y);b:SetSize(width,height or 26)
    b.surface=self:Surface(b)
    b.label=self:Label(b,"",0,6,width,13);b.label:ClearAllPoints();b.label:SetPoint("CENTER");b.label:SetJustifyH("CENTER")
    b:SetFontString(b.label);b:SetText(text)
    function b:Paint()
        U:Paint(self.surface,self.pressed and T.pressed or self.selected and T.selected or self.hovered and T.hover or T.fill,
            self.selected and T.accent or self.hovered and {.72,.72,.72,1} or T.border)
        self.label:SetTextColor(unpack(self.selected and T.accent or T.text))
    end
    function b:SetSelected(value) self.selected=value==true;self:Paint() end
    b:SetScript("OnEnter",function(self) self.hovered=true;self:Paint() end)
    b:SetScript("OnLeave",function(self) self.hovered=nil;self.pressed=nil;self:Paint() end)
    b:SetScript("OnMouseDown",function(self) self.pressed=true;self:Paint() end)
    b:SetScript("OnMouseUp",function(self) self.pressed=nil;self:Paint() end)
    b:SetScript("OnClick",fn)
    return b
end

function U:Divider(parent,y,width)
    local line=parent:CreateTexture(nil,"ARTWORK");line:SetPoint("TOPLEFT",0,-y);line:SetSize(width,1)
    line:SetColorTexture(unpack(T.divider));return line
end

function U:Switch(parent,text,x,y,getter,setter)
    local b=CreateFrame("CheckButton",nil,parent);b:SetPoint("TOPLEFT",x,-y);b:SetSize(190,26)
    b.label=self:Label(b,text,0,6,78)
    local track=CreateFrame("Frame",nil,b);track:SetPoint("TOPLEFT",80,-3);track:SetSize(46,20)
    b.surface=self:RoundedSurface(track)
    b.knob=track:CreateTexture(nil,"OVERLAY");b.knob:SetSize(14,14)
    b.knob:SetTexture("Interface\\AddOns\\KH_map\\Media\\Switch.tga")
    b.knob:SetTexCoord(128.5/256,191.5/256,.5/64,63.5/64)
    b.state=self:Label(b,"",134,7,50,11)
    function b:Refresh()
        local on=getter()==true;self:SetChecked(on)
        U:Paint(self.surface,on and T.accent or T.fill,on and T.accent or T.border)
        self.knob:SetVertexColor(unpack(on and {.10,.10,.10,1} or T.muted))
        self.knob:ClearAllPoints();self.knob:SetPoint(on and "RIGHT" or "LEFT",track,on and "RIGHT" or "LEFT",on and -3 or 3,0)
        self.state:SetText(on and "ON" or "OFF");self.state:SetTextColor(unpack(on and T.accent or T.muted))
    end
    b:SetScript("OnClick",function(self) setter(self:GetChecked()==true);self:Refresh() end)
    self.controls[#self.controls+1]=b;b:Refresh();return b
end

function U:Check(parent,text,x,y,getter,setter,radio,width)
    local b=CreateFrame("CheckButton",nil,parent);b:SetPoint("TOPLEFT",x,-y);b:SetSize(width or 180,26)
    local square=CreateFrame("Frame",nil,b);square:SetSize(18,18);square:SetPoint("TOPLEFT",0,-4)
    b.surface=self:Surface(square)
    b.mark=self:Label(b,"",0,6,18,radio and 16 or 13);b.mark:SetJustifyH("CENTER")
    if not radio then
        b.check=square:CreateTexture(nil,"ARTWORK");b.check:SetAllPoints(square)
        b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");b.check:SetVertexColor(.08,.08,.08,1)
    end
    b.label=self:Label(b,text,26,6,(width or 180)-26)
    if radio then b.surface.fill:Hide();for _,edge in ipairs(b.surface.edges) do edge:Hide() end end
    function b:Refresh()
        local on=getter()==true;self:SetChecked(on)
        U:Paint(self.surface,on and T.accent or T.fill,on and T.accent or T.border)
        self.mark:SetText(radio and (on and "●" or "○") or "")
        if self.check then self.check:SetShown(on) end
        self.mark:SetTextColor(unpack(radio and (on and T.accent or T.muted) or {.08,.08,.08,1}))
    end
    b:SetScript("OnClick",function(self) setter(radio and true or self:GetChecked()==true);self:Refresh() end)
    self.controls[#self.controls+1]=b;b:Refresh();return b
end

function U:Slider(parent,text,x,y,low,high,key,unit,width)
    width=width or 180
    self:Label(parent,text,x,y,width,13)
    local value=self:Label(parent,"",x+width+12,y,74,12,T.muted)
    local s=CreateFrame("Slider",nil,parent);s:SetPoint("TOPLEFT",x,-y-30);s:SetSize(width,14)
    s:SetOrientation("HORIZONTAL");s:SetMinMaxValues(low,high);s:SetValueStep(1);s:SetObeyStepOnDrag(true)
    local track=s:CreateTexture(nil,"BACKGROUND");track:SetPoint("LEFT");track:SetPoint("RIGHT");track:SetHeight(3);track:SetColorTexture(unpack(T.track))
    s:SetThumbTexture("Interface\\Buttons\\WHITE8X8");s:GetThumbTexture():SetSize(10,18);s:GetThumbTexture():SetVertexColor(unpack(T.accent))
    self:Label(parent,tostring(low)..unit,x,y+50,72,11,T.muted)
    local maximum=self:Label(parent,tostring(high)..unit,x+width-72,y+50,72,11,T.muted);maximum:SetJustifyH("RIGHT")
    s:SetScript("OnValueChanged",function(_,number)
        if not A:Number(number) then return end
        number=math.floor(A:Clamp(number,low,high)+.5);value:SetText(number..unit)
        if not A.refreshing then A.db[key]=number;A:Request() end
    end)
    function s:Refresh() self:SetValue(A.db[key]);value:SetText(A.db[key]..unit) end
    self.controls[#self.controls+1]=s;s:Refresh();return s
end

function U:CloseDropdown()
    if self.openDropdown then self.openDropdown:Hide();self.openDropdown=nil end
    if self.dropdownBlocker then self.dropdownBlocker:Hide() end
end

function U:Dropdown(parent,x,y,width,options,getter,setter)
    local b=self:Button(parent,"",x,y,width,function() end)
    local menu=CreateFrame("Frame",nil,A.window);menu:SetSize(width,#options*28+8)
    menu:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,-3);menu:SetFrameStrata(A.window:GetFrameStrata());menu:SetFrameLevel(110)
    menu:SetClampedToScreen(true);menu:EnableMouse(true);self:Surface(menu,T.background);menu:Hide()
    b.menu,b.options,b.rows=menu,options,{}
    function b:Select(value)
        for _,item in ipairs(options) do if item[1]==value then setter(value);U:CloseDropdown();self:Refresh();return end end
    end
    function b:Refresh()
        local selected=getter()
        for i,item in ipairs(options) do
            if item[1]==selected then self:SetText(item[2].."  ▼") end
            self.rows[i]:SetSelected(item[1]==selected)
        end
    end
    for i,item in ipairs(options) do
        local choice=item[1]
        b.rows[i]=self:Button(menu,item[2],4,4+(i-1)*28,width-8,function() b:Select(choice) end)
    end
    b:SetScript("OnClick",function()
        if menu:IsShown() then self:CloseDropdown();return end
        self:CloseDropdown()
        if not self.dropdownBlocker then
            local blocker=CreateFrame("Frame",nil,A.window);blocker:SetAllPoints(UIParent)
            blocker:SetFrameStrata(A.window:GetFrameStrata());blocker:SetFrameLevel(100);blocker:EnableMouse(true)
            blocker:SetScript("OnMouseDown",function() self:CloseDropdown() end)
            self.dropdownBlocker=blocker
        end
        self.dropdownBlocker:Show();self.openDropdown=menu;b:Refresh();menu:Show()
    end)
    self.controls[#self.controls+1]=b;b:Refresh();return b
end

function U:Refresh()
    for _,control in ipairs(self.controls) do control:Refresh() end
end
