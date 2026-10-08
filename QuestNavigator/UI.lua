local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
local UI=KHQOL.NavigationUI
-- Only compatibility with existing settings/profile/position-editor entry points.
-- The frame and geometry belong to the common renderer and engine respectively.
function QN:ConfigureView()
  UI:Configure(self.db)
  self.root=UI.root
  self:SyncPresentation()
end
function QN:SyncPresentation()
  local turnIn=self.navigationMode=="TURN_IN_LOCATION"
  UI:SetPresentation({progressText=self.progressText,completionTitle=UI.presentation.completionTitle,
    noWaypointText=turnIn and "반납 위치 없음" or "경로 없음",
    unavailableText=turnIn and "반납 위치 안내 불가" or "경로 안내 불가",
    moveHint="Quest Navigator · 드래그 이동"})
end
function QN:ApplyLayout() UI:ApplyLayout() end
function QN:ResetPosition() UI:ResetPosition() end
