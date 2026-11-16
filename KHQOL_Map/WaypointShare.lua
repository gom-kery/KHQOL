local K=_G.KHQOL
local call=K.PublicCall
local template="WaypointLocationPinTemplate"
local dialogKey="KHQOL_MAP_PIN_COPY"

local function showWaypointCommand()
  -- The stock pin has already inserted the link in the current chat draft.
  local chat=ChatFrameUtil
  if call(chat and chat.GetActiveWindow or ChatEdit_GetActiveWindow) then return end

  local point=call(C_Map and C_Map.GetUserWaypoint)
  if not point or not StaticPopupDialogs or type(SLASH_MAPPIN1)~="string" then return end
  local mapID,x,y=call(function() return point.uiMapID,point.position.x,point.position.y end)
  if not K.IsPublicNumber(mapID) or mapID<1 or mapID%1~=0 or not K.IsPublicNumber(x) or not K.IsPublicNumber(y) then return end
  if x<0 or x>1 or y<0 or y>1 then return end
  if not StaticPopupDialogs[dialogKey] then
    StaticPopupDialogs[dialogKey]={
      text="지도 핀 명령을 Ctrl+C로 복사하세요.",
      button1=CLOSE or "닫기",hasEditBox=true,timeout=0,whileDead=true,hideOnEscape=true,
      OnShow=function(dialog,command)
        local box=dialog:GetEditBox()
        box:SetText(command)
        box:SetFocus()
        box:HighlightText()
      end,
      EditBoxOnEscapePressed=StaticPopup_StandardEditBoxOnEscapePressed,
    }
  end
  call(StaticPopup_Show,dialogKey,nil,nil,("%s %d %.1f %.1f"):format(SLASH_MAPPIN1,mapID,x*100,y*100))
end

local function updatePins(map)
  for pin in map:EnumeratePinsByTemplate(template) do
    -- Replace only the clipboard step on this pooled user waypoint. The
    -- native link insertion, tracking and removal hooks remain intact.
    if K.WindowLayers:Readable(pin) and type(pin.CopySlashCommandToClipboard)=="function"
      and pin.CopySlashCommandToClipboard~=showWaypointCommand then
      pin.CopySlashCommandToClipboard=showWaypointCommand
    end
  end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(self,event,name)
  if event=="ADDON_LOADED" and name~="Blizzard_WorldMap" and name~="KHQOL_Map" then return end
  local map=WorldMapFrame
  if not K.WindowLayers:Readable(map) or type(map.AcquirePin)~="function" or type(map.EnumeratePinsByTemplate)~="function" then return end
  hooksecurefunc(map,"AcquirePin",function(frame,pinTemplate)
    if pinTemplate==template then updatePins(frame) end
  end)
  updatePins(map)
  self:UnregisterAllEvents()
end)
