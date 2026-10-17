local K=_G.KHQOL
local Tooltip=K.modules.tooltip
local call,secret=K.PublicCall,Tooltip.IsSecretValue
local states=setmetatable({},{__mode="k"})
local hooked=setmetatable({},{__mode="k"})
local options={spell="showSpellID",item="showItemID",unit="showNPCID"}
local labels={spell="|cffffd100주문 ID|r",item="|cffffd100아이템 ID|r",unit="|cffffd100NPC ID|r"}
local function positiveID(value)
  if secret(value) then return end
  if type(value)=="string" and value:match("^%d+$") then value=tonumber(value) end
  if K.IsPublicNumber(value) and value>0 and value==math.floor(value) then return value end
end
local function npcID(tooltip,fallback)
  local unit=Tooltip:GetReadableUnit(tooltip,fallback)
  local guid=Tooltip:GetReadableGUID(unit)
  if not guid then return end
  local kind,id=guid:match("^([^-]+)%-[^-]*%-[^-]*%-[^-]*%-[^-]*%-(%d+)%-")
  if kind=="Creature" or kind=="Vehicle" then return positiveID(id) end
end
local function lineAt(tooltip,index,side)
  return _G[tooltip:GetName()..(side or "TextLeft")..index]
end
local function idLine(tooltip,index)
  local line=lineAt(tooltip,index)
  local text=line and line:GetText()
  if secret(text) then return false end
  return text==labels.spell or text==labels.item or text==labels.unit
end
function Tooltip:IsIDInfoRow(tooltip,index)
  if not states[tooltip] then return false end
  if idLine(tooltip,index) then return true end
  local line=lineAt(tooltip,index)
  local text=line and line:GetText()
  return not secret(text) and text==" " and idLine(tooltip,index+1)
end
local function snapshot(tooltip,index)
  local left,right=lineAt(tooltip,index),lineAt(tooltip,index,"TextRight")
  return {left=left and left:GetText() or "",right=right and right:GetText() or "",
    lc=left and {left:GetTextColor()} or {1,1,1,1},rc=right and {right:GetTextColor()} or {1,1,1,1}}
end
local function isEmpty(row) return row.left=="" and row.right=="" end
function Tooltip:UpdateIDInfo(tooltip)
  local state=states[tooltip]
  if not state or state.updating then return end
  local active=self:IsEnabled() and self:GetDB()[options[state.kind]]==true
  -- With every option OFF, do not even scan text or resolve unit identities.
  if not active and not state.displayed then return end
  if not self:CanModifyTooltip(tooltip) then return end
  local id=state.id
  if active and state.kind=="unit" then id=npcID(tooltip,state.unit) end
  local enabled=active and id~=nil
  -- OFF must do no layout work unless this tooltip already owns ID rows.
  if not enabled and not state.displayed then return end
  state.updating=true
  local rows={}
  local count=tooltip:NumLines()
  for i=1,count do
    if not self:IsIDInfoRow(tooltip,i) then rows[#rows+1]=snapshot(tooltip,i) end
  end
  while #rows>0 and isEmpty(rows[#rows]) do table.remove(rows) end
  if enabled then
    rows[#rows+1]={left=" ",right="",lc={1,1,1,1},rc={1,1,1,1}}
    rows[#rows+1]={left=labels[state.kind],right=string.format("%d",id),lc={1,.82,0,1},rc={1,1,1,1}}
  end
  local changed=false
  for i=1,math.max(count,#rows) do
    local row=rows[i] or {left="",right="",lc={1,1,1,1},rc={1,1,1,1}}
    if i>tooltip:NumLines() then
      tooltip:AddDoubleLine(row.left,row.right,row.lc[1],row.lc[2],row.lc[3],row.rc[1],row.rc[2],row.rc[3]);changed=true
    end
    for _,side in ipairs({"TextLeft","TextRight"}) do
      local line=lineAt(tooltip,i,side)
      local text=side=="TextLeft" and row.left or row.right
      local color=side=="TextLeft" and row.lc or row.rc
      if line and line:GetText()~=text then
        line:SetText(text);line:SetTextColor(unpack(color));changed=true
        if side=="TextRight" then if text=="" then line:Hide() else line:Show() end end
      end
    end
  end
  state.displayed=enabled
  if changed then
    self:ApplyTextSize(tooltip)
    if tooltip:IsShown() then tooltip:Show() end
  end
  state.updating=nil
end
function Tooltip:RefreshIDInfo()
  for tooltip in pairs(states) do if tooltip:IsShown() then self:UpdateIDInfo(tooltip) end end
end
local function observe(tooltip,kind,id,unit)
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  -- Keep only public identifiers; a protected tooltip must never reuse an old ID.
  local old=states[tooltip]
  states[tooltip]={kind=kind,id=positiveID(id),unit=not secret(unit) and unit or nil,displayed=old and old.displayed}
  if not hooked[tooltip] then
    hooked[tooltip]=true
    if not tooltip.HasScript or tooltip:HasScript("OnTooltipCleared") then
      tooltip:HookScript("OnTooltipCleared",function(frame) states[frame]=nil end)
    end
    hooksecurefunc(tooltip,"Show",function(frame) Tooltip:UpdateIDInfo(frame) end)
  end
  Tooltip:UpdateIDInfo(tooltip)
end
function Tooltip:InitializeIDInfo()
  if self.idInfoInitialized then return end
  self.idInfoInitialized=true
  local types=Enum and Enum.TooltipDataType
  local registered={}
  local function register(typeName,kind)
    local value=types and types[typeName]
    if value==nil or not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall then return end
    TooltipDataProcessor.AddTooltipPostCall(value,function(tooltip,data)
      local id,unit=call(function() return data and data.id,data and data.unitToken end)
      observe(tooltip,kind,id,unit)
    end)
    registered[kind]=true
  end
  register("Item","item");register("Spell","spell");register("Unit","unit")
  register("UnitAura","spell")
  -- Older clients use tooltip scripts instead of the data processor.
  local function script(frame,event,callback)
    if frame and (not frame.HasScript or frame:HasScript(event)) then frame:HookScript(event,callback) end
  end
  for _,frame in ipairs({GameTooltip,ItemRefTooltip,ShoppingTooltip1,ShoppingTooltip2}) do
    if not registered.item then script(frame,"OnTooltipSetItem",function(t)
      local _,link=call(t.GetItem,t)
      local id=link and C_Item and call(C_Item.GetItemInfoInstant,link)
      if not id and type(link)=="string" then id=link:match("item:(%d+)") end
      observe(t,"item",id)
    end) end
    if not registered.spell then script(frame,"OnTooltipSetSpell",function(t)
      local _,id=call(t.GetSpell,t);observe(t,"spell",id)
    end) end
    if not registered.unit then script(frame,"OnTooltipSetUnit",function(t) observe(t,"unit") end) end
  end
end
