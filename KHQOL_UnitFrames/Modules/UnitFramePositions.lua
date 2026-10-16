local _,KHQOL=...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=KHQOL.modules.unitFrames
local call=KHQOL.PublicCall
local function finite(v) return KHQOL.IsPublicNumber(v) end
local function offset(v,limit) return finite(v) and math.max(-limit,math.min(limit,v)) or 0 end
local function rect(frame)
  if not frame then return end
  local x,y=call(frame.GetCenter,frame);local w,h=call(frame.GetSize,frame)
  local scale=call(frame.GetEffectiveScale,frame);local parent=call(UIParent.GetEffectiveScale,UIParent)
  if not finite(x) or not finite(y) or not finite(w) or not finite(h) or not finite(scale) or not finite(parent) or parent<=0 or scale<=0 then return end
  return x,y,w,h,scale/parent
end
function M:PositionPreviews(focus)
  if not self:IsEnabled() or call(InCombatLockdown)==true or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true then return {} end
  local list={};self.editorProxies=self.editorProxies or {}
  local function add(id,name,x,y,w,h,ratio,cfg,xKey,yKey,limit,art)
    local f=self.editorProxies[id]
    if not f then f=CreateFrame("Frame",nil,UIParent);f:EnableMouse(false);f:Hide();self.editorProxies[id]=f end
    f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x*ratio,y*ratio);f:SetSize(w*ratio,h*ratio)
    local spec={id=id,name=name,frame=f,sample=name.." · 위치 미리보기",sampleY=-h*ratio/2-14,art=art,
      write=function(dx,dy) cfg[xKey]=KHQOL.PositionStore:Round(offset((cfg[xKey] or 0)+dx/ratio,limit));cfg[yKey]=KHQOL.PositionStore:Round(offset((cfg[yKey] or 0)+dy/ratio,limit)) end,
      apply=function() M:ApplySettings() end,
      resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=(x-offset(cfg[xKey],limit))*ratio,y=(y-offset(cfg[yKey],limit))*ratio},
      resetPhysical=true,resetWrite=function() cfg[xKey]=0;cfg[yKey]=0 end}
    list[#list+1]=spec;return spec
  end
  local names={player="플레이어",target="대상",pet="소환수",targettarget="대상의 대상",focus="주시대상"}
  for _,unit in ipairs(self.unitTokens) do
    local d=self:GetDB()[unit];local p=self:UnitParts(unit);local owner=self.units and self.units[unit]
    local bar=owner and owner.compactActive and owner.healthDisplay or p and p.health
    local x,y,w,h,ratio=rect(bar)
    if x and p then
      if unit~="targettarget" then
        local rx,ry,rw,rh,rr=rect(p.root)
        if rx then
          local f=self.editorProxies[unit..".root"]
          if not f then f=CreateFrame("Frame",nil,UIParent);f:EnableMouse(false);f:Hide();self.editorProxies[unit..".root"]=f end
          f:SetSize(rw*rr,rh*rr);f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",rx*rr,ry*rr)
          list[#list+1]={id="unitFrames."..unit..".root",name=names[unit].." · 전체 프레임",frame=f,linked=true,readOnly=true,representative=true,
            settingsRoute={module="unitFrames",unit=unit,part="basic"},sample="기본 게임 편집 모드에서 전체 위치 조절",sampleSize=12,art={}}
        end
      end
      if d.compact then
        for _,kind in ipairs({"name","level"}) do
          if p[kind] then
            local size=self:LabelSize(unit,kind);local fw=call(p[kind].GetWidth,p[kind],true)
            if not finite(fw) or fw<=0 then fw=kind=="name" and d.width or size*3 end
            local fh=size+4;local pos=d[kind.."Position"];local side=d[kind.."Side"]=="RIGHT" and "RIGHT" or "LEFT"
            local ax,ay,aw,ah,ar=x,y,w,h,ratio
            if pos=="below" and d.showPower~=false then
              local px,py,pw,ph,pr=rect(p.power);if px then ax,ay,aw,ah,ar=px,py,pw,ph,pr end
            end
            local ox,oy=offset(d[kind.."X"],100),offset(d[kind.."Y"],100);local cx,cy
            if pos=="left" then cx=ax-aw/2-4+ox-fw/2;cy=ay+oy;side="RIGHT"
            elseif pos=="right" then cx=ax+aw/2+4+ox+fw/2;cy=ay+oy;side="LEFT"
            else
              local inset=(kind~="name" or pos=="inside") and 4 or 0
              cx=side=="RIGHT" and ax+aw/2-inset+ox-fw/2 or ax-aw/2+inset+ox+fw/2
              cy=pos=="inside" and ay+oy or pos=="below" and ay-ah/2-2+oy-fh/2 or ay+ah/2+2+oy+fh/2
            end
            local spec=add("unitFrames."..unit.."."..kind,names[unit].." · "..(kind=="name" and "이름" or "레벨"),cx,cy,fw,fh,ar,d,kind.."X",kind.."Y",100,{})
            spec.sample=kind=="name" and names[unit].." 이름" or "30";spec.sampleY=0;spec.sampleSize=size*ar;spec.sampleJustify=side
            if unit=="targettarget" then
              local rx,ry,_,_,rr=rect(p.root)
              if rx then spec.parentID="unitFrames.targettarget";spec.resetPoint.x=spec.resetPoint.x-rx*rr;spec.resetPoint.y=spec.resetPoint.y-ry*rr end
            end
          end
        end
        local sx,sy=offset(d.statusX,200),offset(d.statusY,200)
        local icons={{x=x+sx+offset(d.markerX,600),y=y+h/2+13+sy+offset(d.markerY,600),size=18,
          texture="Interface\\TargetingFrame\\UI-RaidTargetingIcons",texCoord={0,.25,0,.25}}}
        if unit=="player" then
          local attack=p.context and p.context.AttackIcon
          local cw,ch
          if attack then cw,ch=call(attack.GetSize,attack) end
          if not finite(cw) or cw<=0 or cw>64 then cw=14 end
          if not finite(ch) or ch<=0 or ch>64 then ch=14 end
          icons[#icons+1]={x=x-w/2-9+sx+offset(d.restX,600),y=y+h/2+7+sy+offset(d.restY,600),size=14,texture="Interface\\Icons\\Spell_Nature_Sleep"}
          icons[#icons+1]={x=x-w/2+14+sx+offset(d.combatX,600),y=y-h/2+3-ch/2+sy+offset(d.combatY,600),size=math.max(cw,ch),texture="Interface\\Icons\\Ability_DualWield"}
        end
        if unit=="player" or unit=="target" then
          local kinds=unit=="player" and {"marker","rest","combat"} or {"marker"}
          local titles={marker="대상 징표",rest="휴식 상태",combat="전투 상태"}
          for index,kind in ipairs(kinds) do
            local i=icons[index]
            local spec=add("unitFrames."..unit.."."..kind,names[unit].." · "..titles[kind],i.x,i.y,i.size,i.size,ratio,d,kind.."X",kind.."Y",600,
              {{texture=i.texture,texCoord=i.texCoord,width=i.size*ratio,height=i.size*ratio}})
            spec.resetPoint.x=(i.x-M:StatusOffset(unit,kind,"X"))*ratio
            spec.resetPoint.y=(i.y-M:StatusOffset(unit,kind,"Y"))*ratio
            spec.write=function(dx,dy)
              d[kind.."X"]=KHQOL.PositionStore:Round(offset(M:StatusOffset(unit,kind,"X")+dx/ratio,400))-offset(d.statusX,200)
              d[kind.."Y"]=KHQOL.PositionStore:Round(offset(M:StatusOffset(unit,kind,"Y")+dy/ratio,400))-offset(d.statusY,200)
            end
            spec.resetWrite=function() d[kind.."X"]=-offset(d.statusX,200);d[kind.."Y"]=-offset(d.statusY,200) end
          end
        end
        local left,right,bottom,top
        for _,i in ipairs(icons) do left=math.min(left or i.x,i.x-i.size/2);right=math.max(right or i.x,i.x+i.size/2);bottom=math.min(bottom or i.y,i.y-i.size/2);top=math.max(top or i.y,i.y+i.size/2) end
        local cx,cy=(left+right)/2,(bottom+top)/2;local art={}
        for _,i in ipairs(icons) do art[#art+1]={texture=i.texture,texCoord=i.texCoord,width=i.size*ratio,height=i.size*ratio,x=(i.x-cx)*ratio,y=(i.y-cy)*ratio} end
        local spec=add("unitFrames."..unit..".status",names[unit].." · 상태·징표 전체",cx,cy,right-left,top-bottom,ratio,d,"statusX","statusY",200,art)
        if unit=="targettarget" then
          local rx,ry,_,_,rr=rect(p.root)
          if rx then spec.parentID="unitFrames.targettarget";spec.resetPoint.x=spec.resetPoint.x-rx*rr;spec.resetPoint.y=spec.resetPoint.y-ry*rr end
        end
      end
      local function aura(id,title,cfg,kind)
        if not cfg or not cfg.enabled then return end
        local anchor=bar
        if cfg.position~="above" and d.showPower~=false then anchor=p.power or bar end
        local ax,ay,aw,ah,ar=rect(anchor);if not ax then return end
        local size=math.max(8,math.min(64,cfg.size or 20));local above=cfg.position=="above"
        if unit=="target" and cfg.layoutEnabled then
          local first=id:find("friendlyPlayer",1,true) and "buffs" or "debuffs"
          local second=first=="buffs" and "debuffs" or "buffs"
          local baseY=ay+(above and ah/2+4 or -ah/2-4)+offset(cfg.y,300)
          local grids={};local previous
          local leftEdge,rightEdge,bottomEdge,topEdge
          for _,key in ipairs({first,second}) do
            local n,rows,left,up=self:AuraLayout(cfg[key]);local width=n*size+(n-1)*3;local height=rows*size+(rows-1)*3
            local originX=(left and ax+aw/2 or ax-aw/2)+offset(cfg.x,300)
            local bottom,top
            if previous then
              originX=previous.origin
              if above then bottom=previous.top+3;top=bottom+height else top=previous.bottom-3;bottom=top-height end
            elseif up then bottom=baseY-(above and 0 or size);top=bottom+height
            else top=baseY+(above and size or 0);bottom=top-height end
            local l=left and originX-width or originX;local r=l+width
            local grid={left=l,right=r,bottom=bottom,top=top,origin=originX,n=n,rows=rows,up=up,reverse=left,kind=key};grids[#grids+1]=grid;previous=grid
            leftEdge=math.min(leftEdge or l,l);rightEdge=math.max(rightEdge or r,r);bottomEdge=math.min(bottomEdge or bottom,bottom);topEdge=math.max(topEdge or top,top)
          end
          local cx,cy=(leftEdge+rightEdge)/2,(bottomEdge+topEdge)/2;local art={}
          for _,grid in ipairs(grids) do for i=1,grid.n*grid.rows do
            local col=(i-1)%grid.n;local row=math.floor((i-1)/grid.n)
            local ix=grid.reverse and grid.right-size/2-col*(size+3) or grid.left+size/2+col*(size+3)
            local iy=grid.up and grid.bottom+size/2+row*(size+3) or grid.top-size/2-row*(size+3)
            art[#art+1]={texture=grid.kind=="debuffs" and "Interface\\Icons\\Spell_Shadow_ShadowWordPain" or "Interface\\Icons\\Spell_Holy_WordFortitude",width=size*ar,height=size*ar,x=(ix-cx)*ar,y=(iy-cy)*ar}
          end end
          local spec=add(id,title,cx,cy,rightEdge-leftEdge,topEdge-bottomEdge,ar,cfg,"x","y",300,art)
          spec.sample="최대 행 범위 예시 · 실제 아이콘 수에 따라 경계가 달라집니다."
          return
        end
        local height=unit=="player" and size*4/3 or size;local width=size*3+6
        local n,rows,left,up=self:AuraLayout(cfg)
        local spacing=unit=="player" and size/6 or 3
        if cfg.layoutEnabled then width=n*size+(n-1)*spacing;height=rows*(unit=="player" and size*4/3 or size)+(rows-1)*spacing end
        local cx=(cfg.layoutEnabled and left and ax+aw/2-width/2 or ax-aw/2+width/2)+offset(cfg.x,300)
        local cy=ay+(above and ah/2+4+height/2 or -ah/2-4-height/2)+offset(cfg.y,300)
        -- Native aura data, private children and timers are never read by previews.
        local art={}
        local count=cfg.layoutEnabled and n*rows or 3
        for i=1,count do
          local col=(i-1)%(cfg.layoutEnabled and n or 3);local row=math.floor((i-1)/(cfg.layoutEnabled and n or 3))
          art[i]={texture=(kind=="debuffs" or i==3) and "Interface\\Icons\\Spell_Shadow_ShadowWordPain" or "Interface\\Icons\\Spell_Holy_WordFortitude",width=size*ar,height=size*ar,
            x=(cfg.layoutEnabled and left and width/2-size/2-col*(size+spacing) or -width/2+size/2+col*(size+spacing))*ar,
            y=(cfg.layoutEnabled and up and -height/2+size/2+row*(size*4/3+spacing) or height/2-size/2-row*(size*4/3+spacing))*ar}
        end
        add(id,title,cx,cy,width,height,ar,cfg,"x","y",300,art)
      end
      if unit=="player" then
        for _,kind in ipairs({"buffs","debuffs"}) do
          if self:PlayerAuraFrame(kind) then aura("unitFrames.player."..kind,"플레이어 · "..(kind=="buffs" and "버프" or "디버프"),d.auras[kind],kind) end
        end
      elseif unit=="target" and self:TargetAuraContainer(p) then
        local requested=type(focus)=="string" and focus:match("^unitFrames%.target%.auras%.([^.]+)")
        for _,category in ipairs({"friendlyPlayer","attackableNPC"}) do
          if not requested or requested==category then
            local cfg=d.auras[category];local caption="대상 · "..(category=="friendlyPlayer" and "아군 플레이어" or "공격 가능한 NPC")
            if cfg.enabled and cfg.separatePositions then
              for _,kind in ipairs({"buffs","debuffs"}) do
                local position,ox,oy=self:TargetAuraPosition(cfg,kind)
                local anchor=(position=="above" or d.showPower==false) and bar or p.power
                local ax,ay,aw,ah,ar=rect(anchor)
                if ax then
                  local size=math.max(8,math.min(64,cfg.size or 20));local above=position=="above"
                  local flow=cfg.layoutEnabled and cfg[kind] or {perRow=8,maxRows=kind=="buffs" and 4 or 2,growth=above and "RIGHT_UP" or "RIGHT_DOWN"}
                  local n,rows,left,up=self:AuraLayout(flow);local width=n*size+(n-1)*3;local height=rows*size+(rows-1)*3
                  local origin=(left and ax+aw/2 or ax-aw/2)+offset(ox,300)
                  local base=ay+(above and ah/2+4 or -ah/2-4)+offset(oy,300)
                  local bottom=up and base-(above and 0 or size) or base+(above and size or 0)-height
                  local cx=(left and origin-width/2 or origin+width/2);local cy=bottom+height/2;local art={}
                  for i=1,n*rows do
                    local col,row=(i-1)%n,math.floor((i-1)/n)
                    art[i]={texture=kind=="debuffs" and "Interface\\Icons\\Spell_Shadow_ShadowWordPain" or "Interface\\Icons\\Spell_Holy_WordFortitude",width=size*ar,height=size*ar,
                      x=(left and width/2-size/2-col*(size+3) or -width/2+size/2+col*(size+3))*ar,
                      y=(up and -height/2+size/2+row*(size+3) or height/2-size/2-row*(size+3))*ar}
                  end
                  local item=cfg[kind];local spec=add("unitFrames.target.auras."..category.."."..kind,caption.." · "..(kind=="buffs" and "버프" or "디버프"),cx,cy,width,height,ar,item,"x","y",300,art)
                  spec.sample="최대 행 범위 예시 · 실제 표시 아님"
                end
              end
            else aura("unitFrames.target.auras."..category,caption.." 버프·디버프",cfg) end
          end
        end
      end
    end
  end
  local p=self:UnitParts("player");local d=self:GetDB().player;local f=self:BottomFrame()
  if p and f and d.compact then
    local x,y,w,h,r=rect(f)
    if not x then
      local rx,ry,rw,rh,rr=rect(p.root)
      if rx then x,y,w,h,r=rx+rw/2-18.5+(d.bottomX or 0),ry-rh/2+20-22.5+(d.bottomY or 0),37,45,rr end
    end
    if x then add("unitFrames.player.totems","플레이어 · 토템·임시 소환",x,y,math.max(37,w),math.max(45,h),r,d,"bottomX","bottomY",100,{{texture="Interface\\Icons\\Spell_Nature_StoneClawTotem",width=28*r,height=28*r}}) end
  end
  local p=self:UnitParts("target");local owner=self.units and self.units.target
  if p and owner and owner.compactActive then
    local x,y,w,_,ratio=rect(owner.healthDisplay or p.health)
    local cfg=self:MonsterMarkSettings()
    if x and (cfg.quest or cfg.classification) then
      local size=cfg.size
      add("unitFrames.target.monster","대상 · 몬스터 마크",x-w/2-8-size+cfg.x,y+cfg.y,2*size+4,size,ratio,cfg,"x","y",400,
        {{atlas="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Quest",width=size*ratio,height=size*ratio,x=-(size+4)*ratio/2},
         {atlas="nameplates-icon-elite-gold",width=size*ratio,height=size*ratio,x=(size+4)*ratio/2}})
    end
  end
  return list
end

-- This module supplies safe proxies; native unit roots stay in Blizzard edit mode.
function M:EditorTargets(focus)
  local list=self:PositionPreviews(focus)
  local proxy,ratio=self:PositionProxy()
  if proxy then
    local d=self:GetDB().targettarget
    local status,x,y=KHQOL.ReadPublicAPI(proxy.GetCenter,proxy)
    if status=="ok" and KHQOL.PositionStore:Number(x) and KHQOL.PositionStore:Number(y)
      and KHQOL.PositionStore:Number(ratio) and ratio>0 then
      list[#list+1]={id="unitFrames.targettarget",name="대상의 대상",frame=proxy,
        write=function(dx,dy)
          d.frameX=math.max(-1000,math.min(1000,KHQOL.PositionStore:Round((d.frameX or 0)+dx/ratio)))
          d.frameY=math.max(-1000,math.min(1000,KHQOL.PositionStore:Round((d.frameY or 0)+dy/ratio)))
        end,
        apply=function() self:ApplySettings() end,sample="대상의 대상 · 위치 미리보기",
        resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=x-(d.frameX or 0)*ratio,y=y-(d.frameY or 0)*ratio},
        resetPhysical=true,resetWrite=function() d.frameX=0;d.frameY=0 end}
    end
  end
  return list
end
