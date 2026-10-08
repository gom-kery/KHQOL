local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local function campfireSettings(content,y)
  local cfa=KHQOL.modules.campfire
  local b=UI:CreateBuilder(content,y)
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return cfa.db.locked end,function(on)
    cfa.db.locked=on
    if on then cfa:HideDiscovery()
    else cfa.ui.discovery:Show(); cfa.ui.complete:Hide(); cfa:ApplyLayout() end
  end)
  b:Description("위치 잠금을 해제하면 아이콘과 문구를 미리 보고 드래그로 이동할 수 있습니다.")
  b:Button("위치 초기화",function()
    cfa.db.position={point="CENTER",x=0,y=80}
    cfa.ui.root:ClearAllPoints(); cfa.ui.root:SetPoint("CENTER",UIParent,"CENTER",0,80)
  end)
  b:Section("알림 모양")
  b:Slider("아이콘 크기",100,140,5,function() return cfa.db.iconSize end,function(v) cfa.db.iconSize=v; cfa:ApplyLayout() end,function(v) return v.." px" end)
  b:Slider("글자 크기",40,70,5,function() return cfa.db.fontSize end,function(v) cfa.db.fontSize=v; cfa:ApplyLayout() end,function(v) return v.." px" end)
  b:Section("알림 문구")
  UI:CreateLabel(content,"표시할 문구",0,b.y); b.y=b.y-24
  local input=UI:CreateEditBox(content,0,b.y,360,function() return cfa.db.message or "모닥불 발견!" end,function(v) cfa.db.message=v; cfa:ApplyLayout() end)
  UI:CreateButton(content,"적용",376,b.y,86,function() cfa.db.message=input:GetText(); input:ClearFocus(); cfa:ApplyLayout() end)
  b.y=b.y-T.DropdownRowHeight+24
  return b.y
end

local function register(id,title,key,description,build)
  KHQOL.AlertSettings:RegisterTab(id,title,function(content,y)
    content.moduleKey=key
    y=UI:CreatePage(content,title,description,function() return KHQOL:GetEnabled(key) end,function(on)
      KHQOL:SetEnabled(key,on); UI:Refresh(content)
    end)
    local b=UI:CreateBuilder(content,y)
    local reset=b:Button("모듈 설정 초기화",function() StaticPopup_Show("KHQOL_RESET_MODULE",title,nil,key) end)
    reset.ignoreModuleEnabled=true; reset:Refresh()
    local bottom=build(content,b.y)
    return bottom
  end)
end
register("combat","전투","combatStatus","전투 시작과 종료 알림을 설정합니다.",function(content,y)
  return KHQOL.modules.combatStatus:BuildSettings(content,y)
end)
register("campfire","모닥불","campfire","근처 모닥불과 야영 효과 알림을 설정합니다.",campfireSettings)
register("buff","버프","buffReminder","유지할 버프와 만료 전 알림을 설정합니다.",function(content,y)
  local FBR=ForeverBuffReminder
  local panel=FBR.settings
  panel:SetParent(content); panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",0,y)
  panel:SetScale(1); panel:SetWidth(T.ContentWidth); panel:SetFrameStrata("DIALOG")
  local function resize() content:SetHeight(-y+panel:GetHeight()+T.ContentPadding) end
  panel:HookScript("OnSizeChanged",resize)
  function content:RefreshTab() FBR:RefreshSettings(); resize() end
  content:RefreshTab(); panel:Show(); UI:Refresh(panel)
  return -content:GetHeight()
end)
register("pvp","PvP","pvpAlert","적 플레이어의 주시, 접근 및 시전 경고를 설정합니다.",function(content,y)
  return KHQOL.modules.pvpAlert:BuildSettings(content,y)
end)
