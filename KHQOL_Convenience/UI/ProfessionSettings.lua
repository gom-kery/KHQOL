local K=_G.KHQOL
local M=K.modules.professions
local UI=K.UI

function M:BuildSettings(parent,y)
  self.settingsPanel=parent
  local b=UI:CreateBuilder(parent,y)
  local function get(key) return function() return self:GetDB()[key] end end
  local function set(key) return function(value) self:GetDB()[key]=value;self:ApplySettings() end end
  local function enabled() return self:GetDB().enabled end
  local function skillShown() return enabled() and self:GetDB().showSkill end
  local function pixels(value) return value.." px" end
  b:Section("전문기술 버튼")
  b:Checkbox("전문기술 버튼 표시",get("enabled"),set("enabled"))
  b:Checkbox("위치 잠금",get("locked"),set("locked"),enabled)
  local move=b:Button("통합 위치 편집",function() K.PositionEditor:Enter("professions") end,nil,enabled)
  move.navigationOnly=true
  b:Button("전문기술 위치 초기화",function()
    K.ReplaceProfileValue(self:GetDB().position,self.defaults.position)
    self:ApplySettings()
  end,nil,enabled)
  b:Slider("버튼 글자 크기",10,28,1,get("fontSize"),set("fontSize"),pixels,enabled)
  b:Color("글자 색상",function() return unpack(self:GetDB().style.color) end,function(r,g,bl,a)
    self:GetDB().style.color={r,g,bl,a};self:ApplySettings()
  end,enabled,nil,true)
  b:Dropdown("텍스트 효과",{{value="NONE",text="없음"},{value="OUTLINE",text="외곽선"},
    {value="THICKOUTLINE",text="두꺼운 외곽선"},{value="SHADOW",text="그림자"}},
    function() return self:GetDB().style.effect end,function(v) self:GetDB().style.effect=v;self:ApplySettings() end,enabled)

  b:Section("펼친 목록")
  b:Dropdown("펼침 방향",{{value="up",text="위"},{value="down",text="아래"},
    {value="left",text="왼쪽"},{value="right",text="오른쪽"}},get("direction"),set("direction"),enabled)
  b:Dropdown("배치 방향",{{value="horizontal",text="가로형"},{value="vertical",text="세로형"}},
    get("layout"),set("layout"),enabled)
  b:Slider("아이콘 크기",24,56,1,get("iconSize"),set("iconSize"),pixels,enabled)
  b:Slider("전문기술 사이 간격",2,16,1,get("cellGap"),set("cellGap"),pixels,enabled)
  b:Slider("목록 배경 불투명도",0,100,1,function() return math.floor(self:GetDB().backgroundAlpha*100+.5) end,
    function(v) self:GetDB().backgroundAlpha=v/100;self:ApplySettings() end,function(v) return v.."%" end,enabled)
  b:Checkbox("숙련도 표시",get("showSkill"),set("showSkill"),enabled)
  b:Slider("숙련도 글자 크기",8,26,1,get("skillFontSize"),set("skillFontSize"),pixels,skillShown)
  b:Dropdown("숙련도 위치",{{value="inside",text="아이콘 안쪽 아래"},{value="outside",text="아이콘 바깥쪽 아래"}},
    get("skillPosition"),set("skillPosition"),skillShown)

  b:Section("버튼 순서")
  local function choices()
    local options={}
    for _,entry in ipairs(self:OrderedProfessions()) do options[#options+1]={value=entry.skillLineID,text=entry.name} end
    return options
  end
  for slot=1,5 do
    b:Dropdown("전문기술 순서 "..slot,choices,function()
      local entry=self:OrderedProfessions()[slot]
      return entry and entry.skillLineID
    end,function(id) self:MoveProfession(slot,id) end,function()
      return enabled() and self:OrderedProfessions()[slot]~=nil
    end)
  end
  return b.y
end
