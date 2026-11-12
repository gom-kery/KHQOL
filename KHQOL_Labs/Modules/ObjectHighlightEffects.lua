local K=_G.KHQOL
-- Supplied reticle images and the existing independent procedural effects.
local E={entries={},options={},imageStyles={}}
K.ObjectHighlightEffects=E
function E:Register(key,title,draw)
  self.entries[key]=draw;self.options[#self.options+1]={value=key,text=title}
end
local media="Interface\\AddOns\\KHQOL_Labs\\Media\\ObjectReticles\\"
function E:Image(frame,path,size,color,alpha)
  local texture=frame.reticleImage
  if not texture then
    texture=frame:CreateTexture(nil,"OVERLAY");frame.reticleImage=texture
    texture:SetBlendMode("BLEND");texture:SetPoint("CENTER",frame,"CENTER",0,0)
  end
  if frame.reticleImagePath~=path then
    frame.reticleImagePath=nil
    local loaded=texture:SetTexture(path)
    if loaded==false then
      texture:Hide();error("오브젝트 조준선 이미지 로드 실패: "..path)
    end
    frame.reticleImagePath=path
  end
  texture:SetSize(size,size);texture:SetVertexColor(color[1],color[2],color[3],alpha);texture:Show()
  return 0
end
for _,item in ipairs({
  {"imageCross","이미지 01 · 십자선 (Cross)","ObjectReticle_01_Cross.tga"},
  {"imageDiamond","이미지 02 · 마름모 (Diamond)","ObjectReticle_02_Diamond.tga"},
  {"imageRing","이미지 03 · 분할 원형 (Segmented Ring)","ObjectReticle_03_SegmentedRing.tga"},
  {"imageSwirl","이미지 04 · 납작한 회오리 (Flat Swirl)","ObjectReticle_04_FlatSwirl.tga"},
  {"imageOrbit","이미지 05 · 궤도 별빛 (Orbit Star)","ObjectReticle_05_OrbitStar.tga"},
}) do
  local key,title,path=item[1],item[2],media..item[3]
  E.imageStyles[key]=path
  E:Register(key,title,function(frame,size,color,alpha) return E:Image(frame,path,size,color,alpha) end)
end
function E:Line(frame,index,x1,y1,x2,y2,width,alpha,color)
  local line=frame.lines[index]
  if not line then line=frame:CreateLine(nil,"OVERLAY");frame.lines[index]=line end
  line:SetStartPoint("CENTER",frame,x1,y1);line:SetEndPoint("CENTER",frame,x2,y2);line:SetThickness(width)
  line:SetColorTexture(color[1],color[2],color[3],alpha);line:Show()
end
local function ring(frame,size,color,alpha,subtle)
  local n=subtle and 24 or 16;local radius=size*.34
  for i=1,n do
    local a,b=(i-1)*2*math.pi/n,i*2*math.pi/n
    E:Line(frame,i,math.cos(a)*radius,math.sin(a)*radius,math.cos(b)*radius,math.sin(b)*radius,subtle and 3 or 2,alpha*(subtle and .4 or .85),color)
  end
  if not subtle then
    for i=0,3 do
      local a=i*math.pi/2
      E:Line(frame,n+i+1,math.cos(a)*size*.40,math.sin(a)*size*.40,math.cos(a)*size*.49,math.sin(a)*size*.49,3,alpha,color)
    end
    n=n+4
  end
  return n
end
E:Register("subtle","기존 Subtle · 은은한 테두리",function(f,s,c,a) return ring(f,s,c,a,true) end)
E:Register("reticle","기존 Reticle · 조준 테두리",function(f,s,c,a) return ring(f,s,c,a,false) end)
E:Register("brackets","기존 Brackets · 모서리",function(f,s,c,a)
  local index=0
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
    index=index+1;E:Line(f,index,x*s*.38,y*s*.38,x*s*.20,y*s*.38,3,a,c)
    index=index+1;E:Line(f,index,x*s*.38,y*s*.38,x*s*.38,y*s*.20,3,a,c)
  end end
  return index
end)
function E:Stop(frame,keepImage)
  if frame.reticleImage and not keepImage then frame.reticleImage:Hide() end
  for _,p in ipairs(frame.sparkles or {}) do
    if p.animating then p.animation:Stop();p.animating=false end
    p:Hide()
  end
end
local positions={{.32,.17,8},{-.28,.26,6},{-.34,-.20,9},{.25,-.31,7}}
local function animate(group,kind,order,duration,delay,from,to)
  local a=group:CreateAnimation(kind)
  a:SetOrder(order);a:SetDuration(duration);a:SetStartDelay(delay);a:SetSmoothing("IN_OUT")
  if kind=="Alpha" then a:SetFromAlpha(from);a:SetToAlpha(to)
  else a:SetScaleFrom(from,from);a:SetScaleTo(to,to);a:SetOrigin("CENTER",0,0) end
end
E:Register("sparkle","기존 Sparkle · 작은 반짝임",function(frame,size,color,alpha)
  frame.sparkles=frame.sparkles or {}
  for i,point in ipairs(positions) do
    local p=frame.sparkles[i]
    if not p then
      p=CreateFrame("Frame",nil,frame);frame.sparkles[i]=p;p:EnableMouse(false);p.lines={}
      local group=p:CreateAnimationGroup();p.animation=group;group:SetLooping("REPEAT")
      local duration=.45+i*.035;local delay=(i-1)*.16
      animate(group,"Alpha",1,duration,delay,0,1);animate(group,"Alpha",2,.65,0,1,0)
      animate(group,"Scale",1,duration,delay,.55,1.15);animate(group,"Scale",2,.65,0,1.15,.55)
    end
    local radius=point[3]*size/100
    p:SetSize(radius*2,radius*2);p:ClearAllPoints();p:SetPoint("CENTER",frame,"CENTER",point[1]*size,point[2]*size)
    -- Two narrow strokes form a small four-point star; no imported media.
    E:Line(p,1,-radius*.55,0,radius*.55,0,1,alpha,color)
    E:Line(p,2,0,-radius,0,radius,1.4,alpha,color)
    p:Show()
    if not p.animating then p:SetAlpha(0);p.animation:Play();p.animating=true end
  end
  return 0
end)
function E:Render(frame,effect,size,color,alpha)
  local draw=self.entries[effect];if not draw then return false end
  if effect~="sparkle" then self:Stop(frame,self.imageStyles[effect]~=nil)
  elseif frame.reticleImage then frame.reticleImage:Hide() end
  frame.lines=frame.lines or {}
  local n=draw(frame,size,color,alpha)
  for i=n+1,#frame.lines do frame.lines[i]:Hide() end
  return true
end
