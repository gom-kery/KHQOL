local _,K=...
local M=K.modules.partyFrames
local call=K.PublicCall
M.anchorOptions={{value="TOPLEFT",text="왼쪽 위"},{value="TOP",text="위 가운데"},{value="TOPRIGHT",text="오른쪽 위"},
  {value="LEFT",text="왼쪽 가운데"},{value="CENTER",text="가운데"},{value="RIGHT",text="오른쪽 가운데"},
  {value="BOTTOMLEFT",text="왼쪽 아래"},{value="BOTTOM",text="아래 가운데"},{value="BOTTOMRIGHT",text="오른쪽 아래"}}
function M:IsAnchorPoint(point) for _,p in ipairs(self.anchorOptions) do if point==p.value then return true end end;return false end
function M:MaxLayoutGroups(key) return key=="party" and 1 or key=="raid10" and 2 or key=="raid20" and 4 or 8 end
function M:RaidGroups()
  local groups,seen={},{}
  if call(IsInRaid)==true then
    local n=call(GetNumGroupMembers)
    if K.IsPublicNumber(n) and n>=0 and n<=40 then
      for i=1,n do
        local group=select(3,call(GetRaidRosterInfo,i))
        if K.IsPublicNumber(group) and group==math.floor(group) and group>=1 and group<=8 and not seen[group] then seen[group]=true;groups[#groups+1]=group end
      end
    end
  end
  table.sort(groups)
  if #groups==0 then groups[1]=1 end
  return groups
end
function M:RaidGroupSignature() return table.concat(self:RaidGroups(),",") end
function M:GroupExtent(d)
  if d.orientation=="HORIZONTAL" then return d.width*5+d.gap*4,d.height end
  return d.width,d.height*5+d.gap*4
end
function M:Grid(key,d,count)
  local gw,gh=self:GroupExtent(d)
  if key=="party" then return gw,gh,1,gw,gh end
  count=math.max(1,count or self:MaxLayoutGroups(key))
  local cols=math.min(d.groupsPerRow,self:MaxLayoutGroups(key),count)
  local rows=math.ceil(count/cols);local gx=d.groupGapX or d.groupGap;local gy=d.groupGapY or d.groupGap
  return cols*gw+(cols-1)*gx,rows*(gh+18)+(rows-1)*gy,cols,gw,gh
end
function M:Extent(kind,d,count)
  local w,h=self:Grid(kind=="raid" and self:RaidLayoutKey() or kind,d,count)
  return w,h
end
function M:GroupOffset(key,d,index,count)
  local _,_,cols,gw,gh=self:Grid(key,d,count)
  local right=d.groupAnchor=="RIGHT";local x=(index%cols)*(gw+(d.groupGapX or d.groupGap or 0))
  return right and -x or x,-math.floor(index/cols)*(gh+18+(d.groupGapY or d.groupGap or 0))-18,right and "TOPRIGHT" or "TOPLEFT"
end
function M:PlaceLayoutRoot(root,key,d,count)
  local w,h=self:Grid(key,d,count)
  root:SetSize(w,h);root:ClearAllPoints();root:SetPoint(d.point,UIParent,d.point,d.x,d.y)
  root:SetClampedToScreen(true)
end
function M:SetLayoutAnchor(key,point)
  if not self:IsAnchorPoint(point) then return end
  local d=self:GetDB()[key];if d.point==point then return end
  d.point=point;d.x=0;d.y=0;self:RequestApply()
end
function M:ApplyLayout()
  local db=self.visual;local groups=self:RaidGroups();local slots={}
  for i,group in ipairs(groups) do slots[group]=i-1 end
  local tail=#groups
  for group=1,8 do if not slots[group] then slots[group]=tail;tail=tail+1 end end
  self:PlaceLayoutRoot(self.partyRoot,"party",db.party,1)
  self:PlaceLayoutRoot(self.raidRoot,self.layoutKey,db.raid,#groups)
  for _,header in ipairs(self.headers) do
    local kind=header.khqolKind;local d=db[kind];local horizontal=d.orientation=="HORIZONTAL";local right=d.groupAnchor=="RIGHT"
    header:SetAttribute("_ignore",true)
    header:SetAttribute("point",horizontal and (right and "RIGHT" or "LEFT") or "TOP")
    header:SetAttribute("xOffset",horizontal and (right and -d.gap or d.gap) or 0)
    header:SetAttribute("yOffset",not horizontal and -d.gap or 0)
    header:SetAttribute("kh-width",d.width);header:SetAttribute("kh-height",d.height)
    header:SetAttribute("showSolo",kind=="party" and db.showSolo)
    local x,y,point=0,0,right and "TOPRIGHT" or "TOPLEFT"
    if kind=="raid" then x,y,point=self:GroupOffset(self.layoutKey,d,slots[header.khqolGroup],#groups) end
    header:ClearAllPoints();header:SetPoint(point,header:GetParent(),point,x,y)
    header:SetAttribute("_ignore",nil)
    RegisterStateDriver(header,"visibility",kind=="raid" and "[group:raid] show; hide" or (db.showSolo and "[group:raid] hide; show" or "[group:raid] hide; [group:party] show; hide"))
  end
  for _,button in ipairs(self.buttons) do self:StyleButton(button,db[button.khqolKind],db);self:StyleDebuffs(button) end
  for _,header in ipairs(self.headers) do
    header:RegisterEvent("GROUP_ROSTER_UPDATE");header:RegisterEvent("UNIT_NAME_UPDATE")
    header:SetAttribute("kh-layout-revision",(header:GetAttribute("kh-layout-revision") or 0)+1)
  end
end
