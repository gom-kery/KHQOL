local _,K=...
local T,UI=K.ProfileTransfer,K.UI
local theme=UI.Theme
UI.SettingsNavigation:Register({module="profiles",scope="계정 공용",section="프로필 백업 및 복원"},"프로필 내보내기","현재 프로필 설정을 복사 가능한 문자열로 백업","export backup 백업")
UI.SettingsNavigation:Register({module="profiles",scope="계정 공용",section="프로필 백업 및 복원"},"프로필 가져오기","문자열 검사 후 새 프로필로 복원. 기존 선택 유지","import restore 복원")
function T:CloseWindow() if self.window then self.window:Hide() end end
function T:CreateWindow()
  if self.window then return self.window end
  local f=CreateFrame("Frame","KHQOLProfileTransferWindow",UIParent,"BackdropTemplate")
  self.window=f;f:Hide();f:SetSize(740,660);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetToplevel(true)
  UI:Surface(f);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function() f:StartMoving() end)
  f:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
  f.title=UI:CreateLabel(f,"",18,-18,theme.TitleFontSize)
  f.meta=UI:CreateDescription(f,"",18,-54);f.meta:SetWidth(700)
  f.hint=UI:CreateDescription(f,"",18,-86);f.hint:SetWidth(700)
  local border=CreateFrame("Frame",nil,f,"BackdropTemplate");UI:Surface(border)
  border:SetPoint("TOPLEFT",18,-132);border:SetPoint("BOTTOMRIGHT",-18,234)
  local scroll=CreateFrame("ScrollFrame",nil,border)
  scroll:SetPoint("TOPLEFT",8,-8);scroll:SetPoint("BOTTOMRIGHT",-26,8)
  f.scroll=scroll
  local box=CreateFrame("EditBox",nil,scroll)
  box:SetMultiLine(true);box:SetAutoFocus(false);box:SetFont(UI:Font(),12,"")
  box:SetTextColor(unpack(theme.TextPrimary));box:SetTextInsets(2,2,2,2)
  box:SetWidth(650);box:SetHeight(1);box:SetMaxLetters(T.maxText)
  if box.SetMaxBytes then box:SetMaxBytes(T.maxText) end
  scroll:SetScrollChild(box);f.box=box
  local bar=CreateFrame("Slider",nil,border);bar:SetOrientation("VERTICAL")
  bar:SetPoint("TOPRIGHT",-6,-8);bar:SetPoint("BOTTOMRIGHT",-6,8);bar:SetWidth(10)
  bar:SetMinMaxValues(0,0);bar:SetValueStep(1)
  local track=bar:CreateTexture(nil,"BACKGROUND");track:SetAllPoints();track:SetColorTexture(unpack(theme.SliderTrack))
  local thumb=bar:CreateTexture(nil,"OVERLAY");thumb:SetSize(10,32);thumb:SetColorTexture(unpack(theme.FocusAccent));bar:SetThumbTexture(thumb)
  local function setScroll(value)
    local max=math.max(0,(box:GetHeight() or 0)-scroll:GetHeight())
    scroll:SetVerticalScroll(math.max(0,math.min(max,value)))
  end
  local function size()
    box:SetWidth(math.max(100,scroll:GetWidth()))
    local max=math.max(0,(box:GetHeight() or 0)-scroll:GetHeight())
    bar:SetMinMaxValues(0,max);bar:SetShown(max>0)
    setScroll(scroll:GetVerticalScroll() or 0)
  end
  bar:SetScript("OnValueChanged",function(_,value) setScroll(value) end)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel",function(_,delta) bar:SetValue((scroll:GetVerticalScroll() or 0)-delta*48) end)
  scroll:SetScript("OnSizeChanged",size)
  box:SetScript("OnSizeChanged",size)
  box:SetScript("OnCursorChanged",function(_,_,y,_,height)
    local cursor=-y;local top=scroll:GetVerticalScroll() or 0
    if cursor<top then bar:SetValue(cursor)
    elseif cursor+(height or 16)>top+scroll:GetHeight() then bar:SetValue(cursor+(height or 16)-scroll:GetHeight()) end
  end)
  box:SetScript("OnEscapePressed",function() f:Hide() end)
  f.result=UI:CreateLabel(f,"",18,-440);f.result:ClearAllPoints()
  f.result:SetPoint("BOTTOMLEFT",18,132);f.result:SetSize(700,90);f.result:SetJustifyV("TOP");f.result:SetWordWrap(true)
  f.notice=UI:CreateDescription(f,T.scopeNotice,18,-540);f.notice:ClearAllPoints()
  f.notice:SetPoint("BOTTOMLEFT",18,68);f.notice:SetWidth(700)
  local resultView=CreateFrame("ScrollFrame",nil,f)
  local resultBody=CreateFrame("Frame",nil,resultView);resultView:SetScrollChild(resultBody)
  f.result:SetParent(resultBody)
  resultView:EnableMouseWheel(true)
  resultView:SetScript("OnMouseWheel",function(_,delta)
    resultView:SetVerticalScroll(math.max(0,math.min(math.max(0,resultBody:GetHeight()-resultView:GetHeight()),resultView:GetVerticalScroll()-delta*34)))
  end)
  UI:AttachTooltip(resultView,"전송 결과","긴 검사 결과는 이 영역을 마우스 휠로 내려 확인하세요.")
  f.resultView=resultView
  function f:ReflowTransfer()
    local width=self:GetWidth()-36
    self.meta:SetWidth(width);self.hint:SetWidth(width);self.notice:SetWidth(width);self.result:SetWidth(width)
    self.meta:ClearAllPoints();self.meta:SetPoint("TOPLEFT",18,-54)
    local hintTop=54+self.meta:GetStringHeight()+10
    self.hint:ClearAllPoints();self.hint:SetPoint("TOPLEFT",18,-hintTop)
    self.notice:ClearAllPoints();self.notice:SetPoint("BOTTOMLEFT",18,58)
    local resultBottom=58+self.notice:GetStringHeight()+12
    self.result:SetHeight(math.max(48,self.result:GetStringHeight()+4))
    self.result:ClearAllPoints();self.result:SetPoint("TOPLEFT",0,0)
    resultBody:SetSize(width,self.result:GetHeight())
    resultView:ClearAllPoints();resultView:SetPoint("BOTTOMLEFT",18,resultBottom)
    resultView:SetSize(width,math.min(128,self.result:GetHeight()))
    resultView:SetVerticalScroll(math.min(resultView:GetVerticalScroll(),math.max(0,resultBody:GetHeight()-resultView:GetHeight())))
    border:ClearAllPoints();border:SetPoint("TOPLEFT",18,-hintTop-self.hint:GetStringHeight()-12)
    border:SetPoint("BOTTOMRIGHT",-18,resultBottom+resultView:GetHeight()+12)
  end
  hooksecurefunc(f.result,"SetText",function() f:ReflowTransfer() end)
  local function invalidate()
    T:Discard(f.ticket);f.ticket=nil
    f.result:SetText("검사 전 · 문자열을 붙여 넣은 뒤 [검사]를 누르세요.")
    if f.confirm then f.confirm:Refresh() end
  end
  box:SetScript("OnTextChanged",function()
    if f.settingText then return end
    if f.mode=="export" then
      f.settingText=true;box:SetText(f.exportText or "");f.settingText=nil
    else invalidate() end
    size()
  end)
  f.select=UI:CreateButton(f,"전체 선택",18,-614,130,function() box:SetFocus();box:HighlightText() end)
  f.check=UI:CreateButton(f,"검사",18,-614,100,function()
    T:Discard(f.ticket);f.ticket=nil
    local ticket,message=T:Inspect(box:GetText())
    f.ticket=ticket
    if not ticket then f.result:SetText("가져오기 불가: "..T.SafeLabel(message))
    else
      local report=ticket.report
      f.result:SetText("원본: "..T.SafeLabel(ticket.profileName).." / KHQOL "..T.SafeLabel(ticket.addonVersion)
        .."\n호환 상태: "..ticket.status.." · 정상 설정 "..report.normal.." / 확인 필요 "..report.review.." / 제외 "..report.unsupported
        .."\n새 이름: "..T.SafeLabel(T:SuggestName(ticket.profileName)).."\n가져와도 현재 프로필과 캐릭터별 선택은 변경하지 않습니다.")
      f.confirm.tooltipDescription=(#report.details>0 and table.concat(report.details,"\n").."\n\n" or "")..T.scopeNotice
    end
    f.confirm:Refresh()
  end)
  f.confirm=UI:CreateButton(f,"새 프로필로 가져오기",130,-614,240,function()
    local ok,message=T:Import(f.ticket)
    if ok then
      f.ticket=nil;f.result:SetText("가져오기 완료: "..T.SafeLabel(message).."\n사용하려면 프로필 화면의 [활성 프로필]에서 직접 선택하세요.")
      K:ProfileMessage("'"..T.SafeLabel(message).."' 프로필을 추가했습니다. 현재 사용 프로필은 유지됩니다.")
    else f.result:SetText(T.SafeLabel(message)) end
    f.confirm:Refresh()
  end,function() return f.ticket~=nil end)
  UI:AttachTooltip(f.confirm,"검사 상세",T.scopeNotice)
  f.close=UI:CreateButton(f,"닫기",640,-614,80,function() f:Hide() end)
  for _,button in ipairs({f.select,f.check,f.confirm,f.close}) do button.navigationOnly=true end
  f:SetScript("OnHide",function()
    box:ClearFocus();T:Discard(f.ticket);f.ticket=nil;f.exportText=nil
    f.settingText=true;box:SetText("");f.settingText=nil
    f:UnregisterEvent("PLAYER_REGEN_DISABLED")
  end)
  f:SetScript("OnEvent",function() f:Hide() end)
  UI.draftEditors=UI.draftEditors or {};UI.draftEditors[f]=function() f:Hide() end
  if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="KHQOLProfileTransferWindow" end
  hooksecurefunc(K,"CloseProfileEditors",function() T:CloseWindow() end)
  return f
end
function T:OpenWindow(mode)
  local allowed,reason=K:CanChangeProfile();if not allowed then K:ProfileMessage(reason);return end
  local value,report
  if mode=="export" then value,report=self:Export();if not value then K:ProfileMessage(report);return end end
  local f=self:CreateWindow();f:Hide();f.mode=mode;f.exportText=value
  local scale=math.min(1,(UIParent:GetWidth()-32)/740,(UIParent:GetHeight()-32)/660)
  f:SetScale(math.max(.3,scale));f:ClearAllPoints();f:SetPoint("CENTER")
  f.title:SetText(mode=="export" and "프로필 내보내기" or "프로필 가져오기")
  f.meta:SetText(mode=="export" and ("프로필: "..self.SafeLabel(K:GetCurrentProfileName()).." · KHQOL "..K.VERSION)
    or ("현재 프로필: "..self.SafeLabel(K:GetCurrentProfileName()).." · 새 프로필로만 가져옵니다."))
  f.hint:SetText(mode=="export" and "[전체 선택] 또는 Ctrl+A → Ctrl+C로 복사하여 별도 문서에 보관하세요.\n문자열은 읽기 전용이며 암호화된 비밀 정보가 아닙니다."
    or "프로필 문자열 전체를 붙여 넣고 [검사] → 결과 확인 → [새 프로필로 가져오기] 순서로 진행하세요.")
  f.select:SetShown(mode=="export");f.check:SetShown(mode=="import");f.confirm:SetShown(mode=="import")
  f.result:SetText(mode=="export" and ("내보내기 준비 완료 · "..#value.."자 · 설정 "..report.normal.."개\n지원 범위 밖의 항목 "..report.unsupported.."개 제외. 현재 프로필은 변경하지 않았습니다.") or "검사 전 · 문자열을 붙여 넣으세요.")
  f.settingText=true;f.box:SetText(value or "");f.settingText=nil
  f:SetFrameLevel(math.max(250,K.settings and K.settings:GetFrameLevel()+20 or 250))
  f:ReflowTransfer();f.confirm:Refresh();f:RegisterEvent("PLAYER_REGEN_DISABLED");f:Show();f:Raise()
  if K.settings and not f.settingsHooked then f.settingsHooked=true;K.settings:HookScript("OnHide",function() T:CloseWindow() end) end
  f.box:SetFocus();if mode=="export" then f.box:HighlightText() end
end
