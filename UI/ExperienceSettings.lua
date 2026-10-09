local _, KHQOL = ...
local X=KHQOL.modules.experienceBar
function X:BuildSettings(content,y)
  local UI,T,db=KHQOL.UI,KHQOL.UI.Theme,self:GetDB()
  local function enabled() return self:IsEnabled() end
  local function check(b,title,key,available)
    return b:Checkbox(title,function() return db[key] end,function(v) db[key]=v; self:Changed() end,available or enabled)
  end
  local function slider(b,title,key,lo,hi,step)
    return b:Slider(title,lo,hi,step or 1,function() return db[key] end,function(v) db[key]=v; self:Changed() end,
      function(v) return string.format(step and step<1 and "%.2f" or "%d",v) end,enabled)
  end
  local function dropdown(b,title,key,options,available)
    return b:Dropdown(title,options,function() return db[key] end,function(v) db[key]=v; self:Changed() end,available or enabled)
  end
  local b=UI:CreateBuilder(content,y)
  b:Section("경험치 바")
  local native=check(b,"Blizzard 기본 경험치 바 숨김","hideBlizzard",function() return true end)
  native.ignoreModuleEnabled=true; native:Refresh()
  b:Description("두 옵션은 독립적입니다. KHQOL 바를 꺼도 기본 바 숨김 설정은 유지됩니다.")
  b:Section("표시 형태")
  dropdown(b,"표시 형태","mode",{{value="horizontal",text="기본 가로형"},{value="wrapTop",text="PlayerFrame 위쪽 감싸기"},{value="wrapBottom",text="PlayerFrame 아래쪽 감싸기"}})
  b:Flush()
  local groupY=b.y
  local function panel()
    local f=CreateFrame("Frame",nil,content); f:SetWidth(T.ContentWidth)
    return f,UI:CreateBuilder(f,0)
  end
  local horizontal,h=panel()
  h:Section("크기 및 위치")
  slider(h,"폭","width",120,1200); slider(h,"높이","height",8,80)
  slider(h,"X 위치","x",-3000,3000); slider(h,"Y 위치","y",-3000,3000)
  h:Checkbox("위치 잠금",function() return not self.unlocked end,function(locked)
    if locked then self:SavePosition() end
    self.unlocked=not locked; self:Changed()
  end,enabled)
  h:Button("위치 기본값 복원",function() db.x,db.y=self.defaults.x,self.defaults.y; self:Changed() end,nil,enabled)
  h:Description("잠금 해제 후 바를 드래그합니다. 잠긴 상태에서는 클릭을 통과시킵니다.")
  horizontal:SetHeight(-h.y)
  local wrap,w=panel()
  w:Section("PlayerFrame 감싸기")
  slider(w,"가로 길이","wrapHorizontalLength",160,600); slider(w,"세로 길이","wrapVerticalLength",16,180)
  slider(w,"바 두께","wrapThickness",2,16); slider(w,"PlayerFrame과의 간격","wrapOffset",0,60)
  slider(w,"X 오프셋","wrapX",-500,500); slider(w,"Y 오프셋","wrapY",-500,500)
  w:Button("위치 기본값 복원",function() db.wrapOffset,db.wrapX,db.wrapY=self.defaults.wrapOffset,0,0; self:Changed() end,nil,enabled)
  w:Description("PlayerFrame을 기준으로 세로 구간부터 가로 구간까지 채웁니다. 위치는 오프셋으로 조절합니다.")
  wrap:SetHeight(-w.y)
  local common,c=panel()
  slider(c,"배율","scale",.5,2,.05); slider(c,"투명도","alpha",.1,1,.05)
  c:Section("텍스트")
  check(c,"현재 레벨 표시","showLevel"); check(c,"경험치 텍스트 표시","showText")
  dropdown(c,"경험치 텍스트 형식","textMode",{
    {value="percent",text="퍼센트"},{value="currentMax",text="현재 / 필요"},
    {value="remaining",text="남은 경험치"},{value="currentMaxPercent",text="현재 / 필요 + 퍼센트"}},
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
  c:Section("휴식 경험치")
  check(c,"휴식 경험치 표시","showRested"); c:Flush(); color("휴식 경험치 색상","restedColor")
  c:Section("툴팁")
  check(c,"경험치 툴팁 표시","tooltip")
  c:Description("잠긴 상태에서 바에 마우스를 올리면 현재·필요·남은 경험치와 휴식 경험치를 표시합니다.")
  c:Section("고급 설정")
  check(c,"최대 레벨에서 숨김","hideAtMaxLevel")
  common:SetHeight(-c.y)
  local function refresh()
    local isHorizontal=db.mode=="horizontal"
    if not isHorizontal then self.unlocked=false end
    local selected=isHorizontal and horizontal or wrap
    horizontal:SetShown(isHorizontal); wrap:SetShown(not isHorizontal)
    selected:ClearAllPoints(); selected:SetPoint("TOPLEFT",0,groupY)
    common:ClearAllPoints(); common:SetPoint("TOPLEFT",0,groupY-selected:GetHeight())
    local height=-groupY+selected:GetHeight()+common:GetHeight()
    content.contentHeight=height; content:SetHeight(height)
    UI:Refresh(content)
  end
  self.RefreshSettings=refresh
  content:SetScript("OnShow",refresh)
  content:SetScript("OnHide",function() if self.dragging then self:SavePosition() end end)
  refresh()
  return -content.contentHeight
end
