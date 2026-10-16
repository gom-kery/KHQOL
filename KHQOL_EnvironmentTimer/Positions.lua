local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.environmentTimer=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local env=m.environmentTimer
  if env.db and self:CanRunModule("environmentTimer") then
    local db=env.db;local hud=db.style=="hud";local scale=hud and 1 or db.scale
    local timers={};for _,id in ipairs({"BREATH","EXHAUSTION","FEIGNDEATH"}) do if db.timers[id] then timers[#timers+1]=id end end
    if #timers==0 then timers[1]="BREATH" end
    if #timers>0 then
      local width=hud and math.max(480,db.hudGap+2*(db.hudSize*128/420*(db.hudThickness/8))*104/128+32) or db.width
      local height=hud and (db.hudSize*464/420+100) or (db.height*#timers+32*(#timers-1))
      local frame=E:Virtual("environment",{x=db.x/scale,y=db.y/scale},width,height);frame:SetScale(scale)
      add("environment","environmentTimer","환경 타이머 · 그룹",frame,function(dx,dy)
        db.x=self.PositionStore:Round(db.x+dx*scale);db.y=self.PositionStore:Round(db.y+dy*scale)
      end,function() env.unlocked=false end,function() env.layoutCount=nil;env:Render(0) end,
        {sample="호흡 · 피로도 · 죽은척",suppress={env.frame},mirror=env.frame})
      if hud then
        local names={BREATH="호흡",EXHAUSTION="피로도",FEIGNDEATH="죽은척"}
        for index,timer in ipairs(timers) do
          local id=timer;local p=db.hudTextPositions[id]
          local dx=index<=2 and (index==1 and -1 or 1)*(db.hudGap/2+db.hudThickness+db.hudSize*.12) or 0
          local dy=-db.hudSize/2-(index<=2 and 24 or 56)
          local original={x=p and p.x or dx,y=p and p.y or dy}
          local text=E:Virtual("environment.text."..id,{x=db.x+original.x,y=db.y+original.y},math.max(80,db.hudTextSize*7),db.hudTextSize+16)
          local target=add("environment.text."..id,"environmentTimer","환경 · "..names[id].." 텍스트",text,function(x,y)
            db.hudTextPositions[id]={x=original.x+x,y=original.y+y}
          end,function() env.unlocked=false end,nil,{parentID="environment",sample=names[id].." 42초",sampleSize=db.hudTextSize})
          target.textDefault={x=dx,y=dy};target.textOriginal=original;target.textTimer=id
        end
      end
    end
  end
  PU:ConfigureResets(list,function(t,point)
    if t.textDefault then
      point(t,function() local db=m.environmentTimer.db.hudTextPositions;db[t.textTimer]=db[t.textTimer] or {};return db[t.textTimer] end,t.textDefault,{x="x",y="y"})
      t.write=function(dx,dy)
        local p=t.handle.resetting and t.textDefault or t.textOriginal
        m.environmentTimer.db.hudTextPositions[t.textTimer]={x=self.PositionStore:Round(p.x+dx),y=self.PositionStore:Round(p.y+dy)}
      end
    else point(t,function() return m.environmentTimer.db end,m.environmentTimer.defaults,{x="x",y="y"});t.resetPhysical=true end
  end)
  return list
end
