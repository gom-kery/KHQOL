local _,K=...
K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
local WHITE="Interface\\Buttons\\WHITE8X8"
M.debuffTypes={
 {key="Curse",name="저주",id=2,hex="9600FF",rgb={150/255,0,1}},
 {key="Disease",name="질병",id=3,hex="966400",rgb={150/255,100/255,0}},
 {key="Magic",name="마법",id=1,hex="3296FF",rgb={50/255,150/255,1}},
 {key="Poison",name="독",id=4,hex="009600",rgb={0,150/255,0}},
 {key="Bleed",name="출혈",id=11,hex="C80000",rgb={200/255,0,0}},
}
M.absorbTextures={{value="shield",text="보호막 무늬",atlas="RaidFrame-Shield-Overlay"},
 {value="absorb",text="흡수 무늬",atlas="raidframe-shield-fill"},{value="solid",text="단색"}}
M.defaults.debuffTint={enabled=true,colors={}}
for _,v in ipairs(M.debuffTypes) do M.defaults.debuffTint.colors[v.key]={r=v.rgb[1],g=v.rgb[2],b=v.rgb[3],a=1} end
M.defaults.absorb={enabled=true,texture="shield",color={r=.75,g=.9,b=1,a=.8}}
local function raw(fn,...) if type(fn)~="function" then return false end;return pcall(fn,...) end
local function bound(v,default)
 return K.IsPublicNumber(v) and math.max(0,math.min(1,v)) or default
end
function M:NormalizeEffectSettings(db)
 for _,v in ipairs(self.debuffTypes) do
  local c,default=db.debuffTint.colors[v.key],self.defaults.debuffTint.colors[v.key]
  for _,key in ipairs({"r","g","b","a"}) do c[key]=bound(c[key],default[key]) end
 end
 local c=db.absorb.color
 for _,key in ipairs({"r","g","b","a"}) do c[key]=bound(c[key],self.defaults.absorb.color[key]) end
 if db.absorb.texture~="shield" and db.absorb.texture~="absorb" and db.absorb.texture~="solid" then db.absorb.texture="shield" end
end
function M:CreateEffectVisuals(b)
 b.absorb=CreateFrame("StatusBar",nil,b.health);b.absorb:SetAllPoints(b.health)
 b.absorb:SetStatusBarTexture(WHITE);b.absorb:EnableMouse(false);b.absorb:SetAlpha(0)
 if type(b.absorb.SetReverseFill)=="function" then b.absorb:SetReverseFill(true) end
 -- Death shading stays above health tint and shields, below the labels.
 b.deadShade:SetParent(b.labels);b.deadShade:SetDrawLayer("BACKGROUND",-1)
end
function M:StyleAbsorb(b,db)
 local bar=b.absorb;if not bar then return end
 bar:SetFrameLevel(b:GetFrameLevel()+3);bar:SetAllPoints(b.health)
 bar:SetStatusBarTexture(WHITE)
 local cfg=db.absorb;local t=call(bar.GetStatusBarTexture,bar)
 for _,entry in ipairs(self.absorbTextures) do
  if entry.value==cfg.texture and entry.atlas and t then
   local info=call(C_Texture and C_Texture.GetAtlasInfo,entry.atlas)
   if info then raw(t.SetAtlas,t,entry.atlas,false) end
   break
  end
 end
 local c=cfg.color;bar:SetStatusBarColor(c.r,c.g,c.b,c.a)
 if not cfg.enabled then bar:SetAlpha(0) end
end
function M:PrepareDebuffTintCurve(db)
 local ok,err=pcall(function()
  assert(C_CurveUtil and type(C_CurveUtil.CreateColorCurve)=="function" and type(CreateColor)=="function")
  assert(Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step)
  local signature={}
  for _,v in ipairs(self.debuffTypes) do
   local c=db.debuffTint.colors[v.key]
   for _,key in ipairs({"r","g","b","a"}) do signature[#signature+1]=tostring(c[key]) end
  end
  signature=table.concat(signature,":")
  if self.debuffTintCurve and self.debuffTintStamp==signature then return end
  local curve=self.debuffTintCurve or C_CurveUtil.CreateColorCurve()
  curve:ClearPoints();curve:SetType(Enum.LuaCurveType.Step)
  local byID={};for _,v in ipairs(self.debuffTypes) do byID[v.id]=db.debuffTint.colors[v.key] end
  for i=0,12 do
   local c=byID[i]
   curve:AddPoint(i,c and CreateColor(c.r,c.g,c.b,c.a) or CreateColor(0,0,0,0))
  end
  self.debuffTintCurve=curve;self.debuffTintStamp=signature
 end)
 if not ok then self:SetFeatureReason("debuffTint","디버프 색상 표시를 위한 게임 기본 표시기 API를 확인할 수 없습니다.");return nil end
 return self.debuffTintCurve
end
function M:StyleDebuffTint(b,db)
 local c=b.khqolDebuffTint
 if not db.debuffTint.enabled then if c then call(c.SetEnabled,c,false) end;return end
 if b.khqolDebuffTintFailed then self:SetFeatureReason("debuffTint","디버프 색상 표시기를 준비하지 못했습니다. 게임 재접속 후 확인하세요.");return end
 local curve=self:PrepareDebuffTintCurve(db);if not curve then return end
 local ok=pcall(function()
  if not c then
   c=CreateFrame("AuraContainer",nil,b.health,"CustomAuraContainerTemplate");c:SetEnabled(false)
   b.khqolDebuffTint=c
   c:EnableMouse(false);c:SetFrameLevel(b:GetFrameLevel()+2)
  end
  if not b.khqolDebuffTintReady then
   assert(type(c.AddAuraSlot)=="function" and type(c.UpdateAllAuras)=="function")
   local accepted,assets={},{}
   for _,v in ipairs(self.debuffTypes) do accepted[v.key]=true;assets[v.key]={asset=WHITE} end
   -- All aura identity, priority, visibility and color evaluation stay in the
   -- client's secure partition. Never read slot state or aura records here.
   c:AddAuraSlot("KHQOLHealthTint","HARMFUL",{
    candidateFilters={includeDispelTypes=accepted},
    sortMethod=AuraContainerSortMethod.UnitFrameDebuff,
    initializeFrame=function(f)
     f:EnableMouse(false);f:SetAllPoints(b.health);f:SetFrameLevel(b:GetFrameLevel()+2)
     local t=f:CreateTexture(nil,"ARTWORK");t:SetTexture(WHITE)
     t:SetAllPoints(b.health:GetStatusBarTexture())
     f:AddDispelTypeTexture(t,{style=Enum.CustomAuraButtonDispelTypeTextureStyle.CustomAsset,
      showWhenHarmful=true,showWhenHelpful=false,showWithoutDispelType=false,
      customDispelAssetMap=assets,customDispelColorCurve=curve})
    end,
   })
   b.khqolDebuffTintReady=true
  end
  c:UpdateAllAuras()
 end)
 if not ok then
  b.khqolDebuffTintFailed=true
  if c then call(c.SetEnabled,c,false) end
  self:SetFeatureReason("debuffTint","디버프 색상 표시를 위한 게임 기본 표시기 API를 확인할 수 없습니다.")
 end
end
function M:StyleEffects(b,db)
 self:StyleAbsorb(b,db);self:StyleDebuffTint(b,db)
 if db.absorb.enabled and type(UnitGetTotalAbsorbs)~="function" then self:SetFeatureReason("absorb","보호막 흡수량을 표시할 게임 API를 확인할 수 없습니다.") end
end
function M:SyncEffectUnit(b)
 local c=b.khqolDebuffTint;if not c then return end
 local unit=self:ReadUnit(b)
 local enabled=b.khqolDebuffTintReady and not b.khqolDebuffTintFailed and self.applied and self.visual and self.visual.debuffTint.enabled and unit and call(b.IsVisible,b)==true and call(UnitExists,unit)==true
 if not enabled then call(c.SetEnabled,c,false);return end
 local ok=pcall(function() c:SetUnit(unit);c:SetEnabled(true) end)
 if not ok then call(c.SetEnabled,c,false);self:SetFeatureReason("debuffTintUnit","현재 유닛의 디버프 색상 적용이 보류되었습니다.") end
end
function M:UpdateAbsorb(b,unit)
 local cfg=self.visual.absorb;local bar=b.absorb;if not bar then return end
 if not cfg.enabled or type(UnitGetTotalAbsorbs)~="function" then bar:SetAlpha(0);return end
 -- Opaque amounts go straight into C status-bar setters. No arithmetic,
 -- comparisons, formatting, anchor reads or data-dependent visibility.
 local maxOK,maximum=raw(UnitHealthMax,unit);local amountOK,amount=raw(UnitGetTotalAbsorbs,unit)
 local rangeOK,valueOK=false,false
 if maxOK then rangeOK=raw(bar.SetMinMaxValues,bar,0,maximum) end
 if amountOK then valueOK=raw(bar.SetValue,bar,amount) end
 bar:SetAlpha(rangeOK and valueOK and 1 or 0)
end
function M:PreviewEffects(b,db,kind,shieldFraction)
 local cfg=db.debuffTint;local c=cfg.colors[kind]
 if c and cfg.enabled then
  if not b.sampleTint then b.sampleTint=b.health:CreateTexture(nil,"ARTWORK") end
  b.sampleTint:SetAllPoints(b.health:GetStatusBarTexture());b.sampleTint:SetColorTexture(c.r,c.g,c.b,c.a);b.sampleTint:Show()
 elseif b.sampleTint then b.sampleTint:Hide() end
 self:StyleAbsorb(b,db);b.absorb:SetMinMaxValues(0,100);b.absorb:SetValue(shieldFraction or 25)
 b.absorb:SetAlpha(db.absorb.enabled and 1 or 0)
end
