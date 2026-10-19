local K=assert(_G.KHQOL)
local M=K.modules.partyFrames
local call=K.PublicCall
M.defaults.debuffs.excludeSpellIDs={}
local function spellID(value)
 if type(value)=="string" then
  if not value:match("^%s*%d+%s*$") then return end
  value=tonumber(value)
 end
 if K.IsPublicNumber(value) and value>=1 and value<=2147483647 and value==math.floor(value) then return value end
end
function M:NormalizeDebuffFilter(cfg)
 local clean={}
 for key,value in pairs(type(cfg.excludeSpellIDs)=="table" and cfg.excludeSpellIDs or {}) do
  local id=spellID(key);if id and value==true then clean[tostring(id)]=true end
 end
 cfg.excludeSpellIDs=clean
end
function M:DebuffFilterEntries(cfg)
 local list={}
 for key,on in pairs((cfg or self:GetDB().debuffs).excludeSpellIDs or {}) do
  local id=spellID(key);if on==true and id then list[#list+1]=id end
 end
 table.sort(list);return list
end
function M:CanExcludeDebuffID(id)
 local level=call(C_Secrets and C_Secrets.GetSpellAuraSecrecy,id)
 local never=Enum and Enum.SecrecyLevel and Enum.SecrecyLevel.NeverSecret
 if level==nil or never==nil then return nil end
 return level==never
end
function M:DebuffFilterStatus(id)
 local allowed=self:CanExcludeDebuffID(id)
 if allowed==nil then return "게임 판정에 따름" end
 return allowed and "제외 가능" or "게임 보호 · 제외 불가"
end
function M:DebuffFilterLabel(id)
 local info=call(C_Spell and C_Spell.GetSpellInfo,id)
 local name=type(info)=="table" and call(function() return info.name end)
 return tostring(id).." · "..(type(name)=="string" and name or "주문명 미확인").." · "..self:DebuffFilterStatus(id)
end
function M:AddExcludedDebuff(value)
 local id=spellID(value);if not id then return false,"주문 ID는 1 이상의 정수로 입력하세요." end
 if call(C_Spell and C_Spell.DoesSpellExist,id)==false then return false,"존재하는 주문 ID를 입력하세요." end
 local cfg=self:GetDB().debuffs;local key=tostring(id)
 if cfg.excludeSpellIDs[key] then return false,"이미 등록된 주문 ID입니다." end
 cfg.excludeSpellIDs[key]=true
 K.PositionStore:Committed(function() M:RequestApply() end)
 if self:CanExcludeDebuffID(id)==false then return true,"목록에 저장했지만 게임 보호 주문이므로 제외되지 않습니다." end
 return true,"등록했습니다. "..self:DebuffFilterStatus(id)
end
function M:RemoveExcludedDebuff(value)
 local id=spellID(value);if not id then return false end
 local cfg=self:GetDB().debuffs;local key=tostring(id)
 if not cfg.excludeSpellIDs[key] then return false end
 cfg.excludeSpellIDs[key]=nil
 K.PositionStore:Committed(function() M:RequestApply() end)
 return true
end
function M:BuildDebuffFilterSettings(content,b)
 local UI=K.UI;local draft,selected="",nil
 local function selection()
  local entries=M:DebuffFilterEntries()
  for _,id in ipairs(entries) do if id==selected then return selected end end
  selected=entries[1];return selected or 0
 end
 b:Section("디버프 필터")
 b:Description("공개 주문만 ID로 제외할 수 있습니다. 게임 보호 주문은 목록에 저장되어도 계속 표시됩니다. 파티·공격대의 현재 프레임 프로필에 저장합니다.",true)
 local input=b:Edit("제외할 주문 ID",function() return draft end,function(v) draft=v end)
 input:SetMaxLetters(10)
 local add=b:Button("제외 목록에 추가",function()
  local ok,message=M:AddExcludedDebuff(draft);M.debuffFilterMessage=message
  if ok then draft="" end
  UI:Refresh(content)
 end)
 add.navigationOnly=true
 b:Dropdown("등록된 제외 주문",function()
  local options={};for _,id in ipairs(M:DebuffFilterEntries()) do options[#options+1]={value=id,text=M:DebuffFilterLabel(id)} end
  if #options==0 then options[1]={value=0,text="등록된 주문 없음"} end
  return options
 end,selection,function(v) selected=v;M.debuffFilterMessage=nil end)
 local remove=b:Button("선택한 주문 삭제",function()
  if M:RemoveExcludedDebuff(selection()) then M.debuffFilterMessage="제외 목록에서 삭제했습니다.";selected=nil end
  UI:Refresh(content)
 end,nil,function() return selection()~=0 end)
 remove.navigationOnly=true
 local feedback=b:Description("",true)
 local function refreshFeedback()
  local id=selection()
  if id~=0 and M:CanExcludeDebuffID(id)==false then
   feedback:SetText(tostring(id).." · 게임 보호 주문이므로 현재 ID로 제외할 수 없습니다. 아이콘은 계속 표시됩니다.")
  else feedback:SetText(M.debuffFilterMessage or "제외 주문 "..#M:DebuffFilterEntries().."개 · 주문별 적용 가능 여부는 등록 목록에서 확인하세요.") end
 end
 content.uiControls[#content.uiControls+1]={Refresh=refreshFeedback}
 refreshFeedback()
 UI:RegisterDraft(content,function() draft="";M.debuffFilterMessage=nil end)
end
-- Native candidate filtering runs inside the client. No aura records, IDs,
-- child visibility or secret dimensions are read by addon Lua.
function M:StyleFilteredDebuffs(b,cfg)
 if #self:DebuffFilterEntries(cfg)==0 then return end
 if b.khqolFilteredDebuffsFailed then return end
 local f=b.khqolFilteredDebuffs
 local ok=pcall(function()
  assert(AnchorUtil and AnchorUtil.FlowDirection)
  if not f then f=CreateFrame("AuraContainer",nil,b,"CustomAuraContainerTemplate");b.khqolFilteredDebuffs=f;f:SetEnabled(false) end
  for _,method in ipairs({"AddAuraGroup","SetAuraGroupCandidateFilters","SetAuraGroupMaxFrameCount","SetAuraGroupLayout","SetFlowLayoutMaximumLineSize","SetFlowLayoutAnchorPoint","SetFlowLayoutGrowthDirection"}) do assert(type(f[method])=="function",method) end
  local excluded={};for _,id in ipairs(self:DebuffFilterEntries(cfg)) do excluded[id]=true end
  if not b.khqolFilteredDebuffsGroup then
   f:AddAuraGroup("KHQOLDebuffs","HARMFUL",{maxFrameCount=cfg.count,sortMethod=AuraContainerSortMethod.UnitFrameDebuff,
    candidateFilters={excludeSpellIDs=excluded},initializeFrame=function(button)
     button:SetSize(20,20);button:SetTooltipAnchorPoint("ANCHOR_RIGHT")
     local icon=button:CreateTexture(nil,"ARTWORK");icon:SetAllPoints(button);button:SetIcon(icon)
     local cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate");cooldown:SetAllPoints(button)
     cooldown:SetReverse(true);cooldown:SetHideCountdownNumbers(true);button:SetDurationCooldown(cooldown)
     local count=button:CreateFontString(nil,"OVERLAY");count:SetFont(K.UI:Font(),11,"OUTLINE");count:SetPoint("BOTTOMRIGHT",0,0)
     button:SetApplicationCount(count,{})
    end})
   b.khqolFilteredDebuffsGroup=true
  else
   f:SetAuraGroupCandidateFilters("KHQOLDebuffs",{excludeSpellIDs=excluded})
  end
  local ratio=cfg.size/20
  f:SetScale(ratio);f:SetAuraGroupMaxFrameCount("KHQOLDebuffs",cfg.count)
  f:SetAuraGroupLayout("KHQOLDebuffs",{elementWidth=20,elementHeight=20,elementSpacing=cfg.gap/ratio,lineSpacing=cfg.gap/ratio})
  f:SetFlowLayoutMaximumLineSize(cfg.perRow*20+(cfg.perRow-1)*cfg.gap/ratio)
  local up=cfg.position=="TOP"
  f:SetFlowLayoutAnchorPoint(up and "BOTTOMLEFT" or "TOPLEFT")
  f:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,up and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down)
  self:AnchorDebuffs(f,b,cfg,ratio);f:SetFrameLevel(b:GetFrameLevel()+5)
 end)
 if not ok then
  b.khqolFilteredDebuffsFailed=true
  if f then call(f.SetEnabled,f,false) end
  self:SetFeatureReason("debuffFilter","디버프 제외 표시기를 확인할 수 없어 기본 아이콘을 표시합니다. 제외 목록은 보존됩니다.")
  return
 end
 return f
end
