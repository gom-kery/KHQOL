local K=assert(_G.KHQOL)
local M=K.modules.unitFrames
local call=K.PublicCall
local WHITE="Interface\\Buttons\\WHITE8X8"
local names={player="플레이어",target="대상",pet="소환수",targettarget="대상의 대상",focus="주시대상"}
local function bounded(v,default,low,high)
    return K.IsPublicNumber(v) and math.max(low,math.min(high,v)) or default
end
local function text(parent)
    local f=parent:CreateFontString(nil,"OVERLAY")
    f:SetTextColor(1,1,1,1);f:SetJustifyV("MIDDLE")
    if f.SetShadowColor then f:SetShadowColor(0,0,0,1);f:SetShadowOffset(1,-1) end
    return f
end
local function bar(parent)
    local f=CreateFrame("StatusBar",nil,parent);f:EnableMouse(false)
    f:SetStatusBarTexture(WHITE);f:SetMinMaxValues(0,100);f:SetValue(100)
    f.background=f:CreateTexture(nil,"BACKGROUND");f.background:SetAllPoints(f);f.background:SetColorTexture(.04,.04,.04,1)
    f.text=text(f);f.text:SetPoint("LEFT",f,"LEFT",2,0);f.text:SetPoint("RIGHT",f,"RIGHT",-2,0);f.text:SetJustifyH("CENTER")
    return f
end
-- A preview is owned by the unprotected drag handle. It never reparents a
-- native unit frame or reads its private health geometry. Values may be
-- forwarded, without arithmetic or comparisons, to secret-capable C widgets.
local function copyBar(copy,source)
    if not source then return end
    local ok,lo,hi=pcall(source.GetMinMaxValues,source)
    if ok and type(lo)=="number" and type(hi)=="number" then pcall(copy.SetMinMaxValues,copy,lo,hi) end
    local valueOK,value=pcall(source.GetValue,source)
    if valueOK and type(value)=="number" then pcall(copy.SetValue,copy,value) end
    local colorOK,r,g,b,a=pcall(source.GetStatusBarColor,source)
    if colorOK and type(r)=="number" and type(g)=="number" and type(b)=="number" then
        if type(a)~="number" then a=1 end
        pcall(copy.SetStatusBarColor,copy,r,g,b,a)
    end
end
local function copyText(copy,source)
    local value=call(source and source.GetText,source)
    if type(value)~="string" or value=="" then return false end
    copy:SetText(value);return true
end
local function sampleText(mode)
    if mode=="hide" then return "" end
    if mode=="percent" then return "100%" end
    if mode=="currentPercent" then return "100 (100%)" end
    return mode=="current" and "100" or "100 / 100"
end
local function valueText(copy,p,unit,kind,mode,actual)
    if mode=="hide" then copy:SetText("");return end
    local source=p and p[kind]
    if actual then
        if mode=="default" and source and M:RenderDefaultValue(copy,source) then return end
        if M:RenderValue(copy,unit,kind,mode=="default" and "both" or mode) then return end
    end
    copy:SetText(sampleText(mode))
end
local function labelPosition(f,health,power,d,kind,ratio,width,showPower,hasLevel)
    local side=d[kind.."Side"]=="RIGHT" and "RIGHT" or "LEFT"
    local pos=d[kind.."Position"]
    local x=bounded(d[kind.."X"],0,-100,100)
    local y=bounded(d[kind.."Y"],0,-100,100)
    local point,relative,rp
    if pos=="left" then point="RIGHT";relative=health;rp="LEFT";side="RIGHT";x=x-4
    elseif pos=="right" then point="LEFT";relative=health;rp="RIGHT";side="LEFT";x=x+4
    else
        if kind~="name" or pos=="inside" then x=x+(side=="RIGHT" and -4 or 4) end
        if pos=="inside" then point=side;relative=health;rp=side
        elseif pos=="below" then point="TOP"..side;relative=showPower and power or health;rp="BOTTOM"..side;y=y-2
        else point="BOTTOM"..side;relative=health;rp="TOP"..side;y=y+2 end
    end
    f:ClearAllPoints();f:SetPoint(point,relative,rp,x*ratio,y*ratio);f:SetJustifyH(side)
    if kind=="name" then
        local reserve=(pos=="above" or pos=="below") and 0 or 8
        if hasLevel and d.namePosition==d.levelPosition and d.nameSide~=d.levelSide then
            reserve=math.max(42,M:LabelSize(d.previewUnit,"level")*3+8)
        end
        f:SetWidth(math.max(20,width-reserve)*ratio)
    end
end
function M:RenderRootPreview(handle,spec)
    local v=spec.rootVisual
    if not v then return false end
    local f=handle.unitPreview
    if not f then
        f=CreateFrame("Frame",nil,handle);f:EnableMouse(false);handle.unitPreview=f
        f.health=bar(f);f.power=bar(f);f.name=text(f);f.level=text(f)
        f.edge=CreateFrame("Frame",nil,f,"BackdropTemplate");f.edge:EnableMouse(false)
        f.edge:SetAllPoints(handle);f.edge:SetBackdrop({edgeFile=WHITE,edgeSize=1})
        f.edge:SetBackdropBorderColor(unpack(K.UI.Theme.Accent))
    end
    f:SetAllPoints(handle);f:SetAlpha(1);f:Show()
    f:SetFrameLevel(handle:GetFrameLevel()+1)
    f.edge:SetFrameLevel(handle:GetFrameLevel()+6)
    local d,unit,p,r=v.config,v.unit,v.parts,v.ratio
    local actual=p and call(UnitExists,unit)==true
    local owner=self.units and self.units[unit]
    local health=owner and owner.healthDisplay or p and p.health
    f.health:ClearAllPoints();f.health:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);f.health:SetSize(v.width,v.health)
    f.power:ClearAllPoints();f.power:SetPoint("TOPLEFT",f.health,"BOTTOMLEFT",0,-v.gap);f.power:SetSize(v.width,v.power)
    f.power:SetShown(v.showPower)
    f.health:SetMinMaxValues(0,100);f.health:SetValue(100)
    f.power:SetMinMaxValues(0,100);f.power:SetValue(100)
    local cr,cg,cb=self:HealthColor(d,unit)
    f.health:SetStatusBarColor(cr or 0,cg or .63,cb or .094,1)
    f.power:SetStatusBarColor(0,.35,1,1)
    f.health.background:SetAlpha(bounded(d.borderAlpha,.85,0,1))
    if actual then copyBar(f.health,health);copyBar(f.power,p.power) end
    local fontSize=bounded(d.textSize,12,8,24)*r
    for _,b in ipairs({f.health,f.power}) do b.text:SetFont(K.UI:Font(),fontSize,"OUTLINE") end
    valueText(f.health.text,p,unit,"health",d.health or "default",actual)
    valueText(f.power.text,p,unit,"power",d.power or "default",actual)
    if self:HasValueTextPosition(unit) then
        self:LayoutValueText(f.health.text,f.health,unit,"health",r)
        self:LayoutValueText(f.power.text,f.power,unit,"power",r)
    end
    local name=actual and call(UnitName,unit)
    f.name:SetText(type(name)=="string" and name or names[unit].." · 예시")
    if actual and p.name then copyText(f.name,p.name) end
    local hasLevel=unit=="player" or unit=="target" or unit=="focus" or p and p.level~=nil
    local level=actual and call(UnitLevel,unit)
    f.level:SetText(K.IsPublicNumber(level) and tostring(level) or "30");f.level:SetShown(hasLevel and true or false)
    local layout=K.CopyProfileValue(d);layout.previewUnit=unit
    for _,kind in ipairs({"name","level"}) do
        local label=f[kind];local size=self:LabelSize(unit,kind)*r
        label:SetFont(K.UI:Font(),size,"OUTLINE");label:SetHeight(size+4*r)
        if kind=="level" then label:SetWidth(size*3+8*r) end
        labelPosition(label,f.health,f.power,layout,kind,r,v.width/r,v.showPower,hasLevel)
        local color=d[kind.."Color"]
        if d[kind.."ColorMode"]=="custom" and type(color)=="table" then
            label:SetTextColor(bounded(color.r,1,0,1),bounded(color.g,1,0,1),bounded(color.b,1,0,1),1)
        else
            local source=p and p[kind]
            local rr,gg,bb,aa=call(source and source.GetTextColor,source)
            if K.IsPublicNumber(rr) and K.IsPublicNumber(gg) and K.IsPublicNumber(bb) then label:SetTextColor(rr,gg,bb,aa or 1)
            else label:SetTextColor(1,kind=="name" and .82 or 1,kind=="name" and 0 or 1,1) end
        end
    end
    -- The hit outline hugs the bars, while labels remain at their configured
    -- positions outside/inside them. Captions sit clear of the real name row.
    handle.caption:ClearAllPoints();handle.caption:SetPoint("BOTTOMLEFT",handle,"TOPLEFT",0,math.max(self:LabelSize(unit,"name"),self:LabelSize(unit,"level"))*r+10)
    handle:SetBackdropColor(0,0,0,0)
    handle.sample:Hide()
    return true
end
