local _, KHQOL = ...
local CastBar=KHQOL.modules.castBar
local positionLabels={inside_left="바 내부 - 왼쪽",inside_center="바 내부 - 중앙",inside_right="바 내부 - 오른쪽",outside_left="바 외부 - 왼쪽",outside_center="바 외부 - 중앙",outside_right="바 외부 - 오른쪽"}
function CastBar:BuildSettings(content,y)
  local UI,db=KHQOL.UI,self:GetDB()
  local b=UI:CreateBuilder(content,y)
  local controls={}; self.controls=controls
  local function add(control) controls[#controls+1]=control; return control end
  local function enabled() return self:IsEnabled() end
  local function checkbox(title,group,key,kind,available)
    return add(b:Checkbox(title,function() return group[key] end,function(v) group[key]=v; self:Changed(kind) end,available or enabled))
  end
  local function slider(title,group,key,min,max,available)
    return add(b:Slider(title,min,max,1,function() return group[key] end,function(v) group[key]=v; self:Changed() end,function(v) return tostring(math.floor(v+.5)) end,available or enabled))
  end
  local function dropdown(title,group,key,options,kind,available)
    return add(b:Dropdown(title,options,function() return group[key] end,function(v) group[key]=v; self:Changed(kind) end,available or enabled))
  end
  local function color(title,key)
    return add(b:Color(title,function() return unpack(db.appearance[key]) end,function(r,g,bl,a)
      local c=db.appearance[key]; c[1],c[2],c[3]=r,g,bl; if a~=nil then c[4]=a end; self:Changed()
    end,enabled,nil,key=="barColor" or key=="backgroundColor"))
  end
  local function textPosition(kind)
    local options={}
    for _,id in ipairs(self.positions) do
      local position=id
      options[#options+1]={value=position,text=positionLabels[position],disabled=function() return not self:IsTextPositionAvailable(kind,position) end}
    end
    dropdown("표시 위치",db[kind],"position",options,kind,function() return enabled() and db[kind].enabled end)
  end
  b:Section("시전바")
  add(b:Checkbox("시전바 사용",enabled,function(v) KHQOL:SetEnabled("castBar",v); UI:Refresh(content) end))
  b:Section("위치")
  dropdown("배치 기준",db.position,"mode",{{value="free",text="독립 배치"},{value="resource_above",text="ResourceSwing 위"},{value="resource_below",text="ResourceSwing 아래"}})
  local function freeEnabled() return enabled() and not self.linked end
  checkbox("위치 잠금",db.position,"locked",nil,freeEnabled)
  slider("X 위치",db.position.free,"x",-3000,3000,freeEnabled)
  slider("Y 위치",db.position.free,"y",-3000,3000,freeEnabled)
  local function resourceEnabled() return enabled() and db.position.mode~="free" end
  checkbox("ResourceSwing 폭에 맞춤",db.position.resource,"matchWidth",nil,resourceEnabled)
  slider("간격",db.position.resource,"gap",0,20,resourceEnabled)
  b:Description("ResourceSwing이 꺼지면 저장된 독립 위치를 사용합니다.")
  add(b:Button("위치 초기화",function()
    local p=db.position; p.free.point,p.free.relativePoint,p.free.x,p.free.y="CENTER","CENTER",0,-120
    p.resource.gap=4; self:Changed()
  end,180,enabled))
  add(b:Button("미리보기 켜기 / 끄기",function() self:SetPreview(not self.preview) end,210,enabled))
  content:SetScript("OnHide",function()
    if KHQOL.PositionEditor and KHQOL.PositionEditor.active then return end
    self.controls=nil; if self.frame then self:SetPreview(false) end
  end)
  content:SetScript("OnShow",function() self.controls=controls; self:ApplyLayout(); self:RefreshControls() end)
  b:Section("바 모양")
  slider("높이",db.appearance,"height",8,80)
  slider("폭",db.appearance,"width",80,800,function() return enabled() and not (self.linked and db.position.resource.matchWidth) end)
  dropdown("텍스처",db.appearance,"texture",{{value="DEFAULT",text="Blizzard 기본"},{value="FLAT",text="단색"},{value="RAID",text="Raid"},{value="SKILL",text="Skill"}})
  b:Flush()
  color("바 색상","barColor"); color("배경 색상","backgroundColor"); color("시전 중단 색상","interruptedColor")
  b:Section("아이콘")
  checkbox("스킬 아이콘 표시",db.icon,"enabled")
  local function iconEnabled() return enabled() and db.icon.enabled end
  dropdown("아이콘 위치",db.icon,"position",{{value="left",text="왼쪽"},{value="right",text="오른쪽"}},nil,iconEnabled)
  slider("아이콘 크기",db.icon,"size",8,80,iconEnabled)
  b:Section("스킬명")
  checkbox("스킬명 표시",db.spellName,"enabled","spellName"); textPosition("spellName")
  slider("글자 크기",db.spellName,"fontSize",8,32,function() return enabled() and db.spellName.enabled end)
  b:Section("시전 시간")
  checkbox("시전 시간 표시",db.castTime,"enabled","castTime")
  dropdown("표시 형식",db.castTime,"format",{{value="remaining",text="남은 시간"},{value="total",text="전체 시간"},{value="remaining_total",text="남은 시간 / 전체 시간"}},nil,function() return enabled() and db.castTime.enabled end)
  textPosition("castTime")
  slider("글자 크기",db.castTime,"fontSize",8,32,function() return enabled() and db.castTime.enabled end)
  b:Section("동작")
  dropdown("진행 방향",db.behavior,"direction",{{value="left_to_right",text="왼쪽 → 오른쪽"},{value="right_to_left",text="오른쪽 → 왼쪽"}})
  checkbox("Blizzard 시전 바 숨김",db.behavior,"hideBlizzard")
  b:Section("기본값 복원")
  b:Button("시전바 설정 초기화",function() StaticPopup_Show("KHQOL_RESET_MODULE","시전바",nil,"castBar") end)
  return b.y
end
