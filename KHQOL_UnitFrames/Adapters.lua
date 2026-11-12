local _,addon=...
if not addon.loadUnitFrames then return end
local K=_G.KHQOL
K.ModuleRegistry:Register("unitFrames",{
  profile=true,requires={"basicUI"},defaults=function(m) return m.defaults end,
  setEnabled=function(m,on) m:SetEnabled(on) end,
  positions=function(m,focus) return m:EditorTargets(focus) end,
  dragFrames=function() return {K.PlayerAux.frame} end,
  closeEditors=function() K.PlayerAux:StopEditor() end,
  profileChanged=function() K.PlayerAux:StopEditor() end,
  resetScope=function() return "현재 프로필의 개인 유닛 프레임과 직업 보조 표시를 초기화합니다. 공통 직업 색상과 파티·공격대 설정은 유지합니다." end,
})
