local KHQOL = _G.KHQOL
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local function layout(...) return UI:CreateDetailLayout(...) end
local barModes={{value="default",text="기본 표시"},{value="hide",text="항상 숨김"},{value="hover",text="마우스 오버 시 표시"}}
function KHQOL.modules.basicUI:BuildSettings(parent,y)
  local M=self; local l=layout(parent,y,"basicUI")
  local function db() return M:GetDB() end
  l:Description("전투 중 변경은 전투 종료 후 적용합니다.",function() return M.pending==true end)
  l:Section("가방·메뉴바")
  -- Shared builder fields use two columns and refresh preserves their width.
  local f=CreateFrame("Frame",nil,l.page); f:SetWidth(parent:GetWidth())
  local b=UI:CreateBuilder(f,0)
  local bags=b:Dropdown("가방 버튼 표시 방식",barModes,function() return db().bags end,function(v) db().bags=v; M:ApplySettings() end,function() return _G.BagsBar~=nil end)
  local micro=b:Dropdown("메뉴바 표시 방식",barModes,function() return db().micro end,function(v) db().micro=v; M:ApplySettings() end,function() return _G.MicroMenu~=nil end)
  UI:AttachTooltip(bags,"가방 버튼 표시 방식","마우스 오버 모드에서는 버튼 영역에 마우스를 올리면 표시합니다.")
  UI:AttachTooltip(micro,"메뉴바 표시 방식","마우스 오버 모드에서는 메뉴 영역에 마우스를 올리면 표시합니다.")
  -- The detail layout owns this fixed two-column row.
  l:Fields(f,-b.y)
  l:Slider("공통 숨김 지연",0,2,.1,function() return db().hideDelay end,function(v) db().hideDelay=v; M:ApplySettings() end,function(v) return string.format("%.1f초",v) end,function() return db().bags=="hover" or db().micro=="hover" end)
  l:Description("상단 모듈 사용과 하단 모듈 초기화는 가방·메뉴바에 적용됩니다. 기본창 이동은 아래 별도 스위치와 위치 초기화를 사용합니다.")
  local mover=CreateFrame("Frame",nil,l.page); mover:SetWidth(parent:GetWidth())
  l:EndSection()
  l:Fields(mover,-KHQOL.modules.frameMover:BuildSettings(mover,0))
  return l:Finish()
end
KHQOL.InterfaceSettings:RegisterTab("basic",nil,function(content,y) return KHQOL.modules.basicUI:BuildSettings(content,y) end)
