local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local X=KHQOL.modules.experienceBar
function X:BuildSettings(content,y)
  local UI,T,db=KHQOL.UI,KHQOL.UI.Theme,self:GetDB()
  local function enabled() return self:IsEnabled() end
  local function check(b,title,key,available)
    return b:Checkbox(title,function() return db[key] end,function(v) db[key]=v; self:Changed() end,available or enabled)
  end
  local function slider(b,title,key,lo,hi,step)
    return b:Slider(title,lo,hi,step or 1,function() return db[key] end,function(v) db[key]=v; self:Changed() end,
      function(v) return (key=="scale" or key=="alpha") and string.format("%.0f%%",v*100) or string.format("%.0f px",v) end,enabled)
  end
  local function dropdown(b,title,key,options,available)
    return b:Dropdown(title,options,function() return db[key] end,function(v) db[key]=v; self:Changed() end,available or enabled)
  end
  local b=UI:CreateBuilder(content,y)
  b:Flush()
  local groupY=b.y
  local function panel()
    local f=CreateFrame("Frame",nil,content); f:SetWidth(T.ContentWidth)
    return f,UI:CreateBuilder(f,0)
  end
  local horizontal,h=panel()
  h:Section("위치")
  slider(h,"X 위치","x",-3000,3000); slider(h,"Y 위치","y",-3000,3000)
  h:PositionLock("위치 잠금",function() return not self.unlocked end,function(locked)
    if locked then self:SavePosition() end
    self.unlocked=not locked; self:Changed()
  end,enabled)
  h:Button("위치 기본값 복원",function() db.x,db.y=self.defaults.x,self.defaults.y; self:Changed() end,nil,enabled)
  h:Description("잠금 해제 후 바를 드래그합니다. 잠긴 상태에서는 클릭을 통과시킵니다.")

  h:Section("크기·모양")
  slider(h,"폭","width",120,1200); slider(h,"높이","height",8,80)
  horizontal:SetHeight(-h.y)
  local common,c=panel()
  slider(c,"배율","scale",.5,2,.05); slider(c,"투명도","alpha",.1,1,.05)
  c:Section("텍스트")
  check(c,"현재 레벨 표시","showLevel"); check(c,"경험치 텍스트 표시","showText")
  local function levelVisible() return enabled() and db.showLevel end
  local function levelPosition() return levelVisible() and db.mode=="horizontal" end
  dropdown(c,"레벨 배치","levelPlacement",{{value="outside",text="바 외부"},{value="inside",text="바 내부"}},levelPosition)
  dropdown(c,"레벨 위치","levelSide",{{value="left",text="왼쪽"},{value="right",text="오른쪽"}},levelPosition)
  dropdown(c,"레벨 표시 문구","levelLabel",{{value="lv",text="영문 (Lv)"},{value="ko",text="한글 (레벨)"}},levelVisible)
  dropdown(c,"경험치 텍스트 형식","textMode",{
    {value="percent",text="퍼센트"},{value="currentMax",text="현재 / 필요"},
    {value="remaining",text="남은 경험치"},{value="remainingPercent",text="남은 경험치 + 남은 퍼센트"},{value="currentMaxPercent",text="현재 / 필요 + 퍼센트"}},
    function() return enabled() and db.showText end)
  dropdown(c,"가로형 텍스트 위치","textPosition",{{value="left",text="왼쪽"},{value="center",text="중앙"},{value="right",text="오른쪽"}},
    function() return enabled() and db.showText and db.mode=="horizontal" end)
  c:Section("색상 / 스타일")
  local function color(title,key)
    c:Color(title,function() return unpack(db[key]) end,function(r,g,bl,a)
      local color=db[key]; color[1],color[2],color[3]=r,g,bl; if a~=nil then color[4]=a end; self:Changed()
    end,enabled,nil,true)
  end
  color("경험치 바 색상","color"); color("배경 색상","backgroundColor"); color("텍스트 색상","textColor")
  c:Description("평판 표시 중에는 평판 단계에 따른 바 색상을 사용합니다. 경험치로 돌아오면 설정한 경험치 바 색상으로 복원합니다.")
  c:Section("휴식 경험치")
  check(c,"휴식 경험치 표시","showRested"); c:Flush(); color("휴식 경험치 색상","restedColor")
  c:Section("퀘스트 완료 예상 경험치")
  local function preview() return enabled() and db.showQuestPreview end
  local previewRow=CreateFrame("Frame",nil,common);previewRow:SetSize(T.ContentWidth,T.RowHeight+T.RowGap)
  local use=UI:CreateCheckbox(previewRow,"완료 퀘스트 경험치 표시",0,0,function() return db.showQuestPreview end,function(v) db.showQuestPreview=v;self:Changed() end,enabled)
  local function getPreviewColor() return unpack(db.questPreviewColor) end
  local function setPreviewColor(r,g,b,a)
    local value=db.questPreviewColor;value[1],value[2],value[3]=r,g,b;if a~=nil then value[4]=a end;self:Changed()
  end
  local previewColor=UI:CreateColorPicker(previewRow,"",0,24,getPreviewColor,setPreviewColor,preview,nil,true)
  previewColor:SetText("색상 변경")
  previewColor:SetWidth(math.ceil(previewColor:GetFontString():GetStringWidth())+48)
  for _,caption in ipairs(previewColor.uiCaptions or {}) do if caption.region==previewColor:GetFontString() then caption.text="색상 변경" end end
  UI.SettingsNavigation:Attach(previewRow,previewColor,"예상 경험치 색상",getPreviewColor,setPreviewColor,preview)
  UI:AttachTooltip(previewColor,"예상 경험치 색상","퀘스트 완료 예상 경험치 구간의 색상을 변경합니다.")
  c:Block(previewRow,function()
    local width=previewRow:GetWidth()
    previewRow:SetWidth(width)
    local colorX=math.max(0,width-previewColor:GetWidth())
    use.text:SetWidth(math.max(80,colorX-40));use.text:SetWordWrap(true)
    previewColor:ClearAllPoints();previewColor:SetPoint("TOPLEFT",previewRow,"TOPLEFT",colorX,0)
    return math.max(T.RowHeight,use:GetHeight(),use.text:GetStringHeight()+8,previewColor:GetHeight())+T.RowGap
  end)
  check(c,"레벨업 예상 표시","showQuestLevelPrediction",preview)
  c:Description("현재 경험치 → 예상 경험치 → 휴식 경험치 순서로 표시합니다.",true)
  c:Section("툴팁")
  check(c,"경험치 툴팁 표시","tooltip")
  c:Description("잠긴 상태에서 바에 마우스를 올리면 현재·필요·남은 경험치와 휴식 경험치를 표시합니다.")
  c:Section("기타 설정")
  check(c,"최대 레벨에서 숨김","hideAtMaxLevel")
  check(c,"기본 UI 평판 표시 연동","followReputation")
  c:Description("기본 UI 평판의 ‘경험치바에 표시’를 켜면 KHQOL 바 모양으로 평판만 표시하고 기본 경험치·평판 바를 숨깁니다. 해제하면 경험치로 돌아오며, 평판은 최대 레벨에서도 표시합니다.")
  common:SetHeight(-c.y)
  b:EndSection()
  b:Block(horizontal,nil,function() return db.mode=="horizontal" end)
  b:Block(common)
  local function refresh()
    if content.experienceReflowing then return end;content.experienceReflowing=true
    if db.mode~="horizontal" then self.unlocked=false end
    b:Reflow();content.contentHeight=-(b.reflowBottom or b.y);content:SetHeight(content.contentHeight)
    UI:Refresh(content);content.experienceReflowing=nil
  end
  content.Reflow=refresh
  self.RefreshSettings=refresh
  content:SetScript("OnShow",refresh)
  content:SetScript("OnHide",function() if self.dragging then self:SavePosition() end end)
  refresh()
  return -content.contentHeight
end
