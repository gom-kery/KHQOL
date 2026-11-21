local K=_G.KHQOL
local M=K.modules.professions
local G=M.guide
local function validNumber(v) return K.IsPublicNumber(v) and v>=0 and v==math.floor(v) end
local function publicText(v) return K.IsPublicValue(v) and type(v)=="string" and v~="" end
local function faction()
  local value=K.PublicCall(UnitFactionGroup,"player")
  return value=="Alliance" and "alliance" or value=="Horde" and "horde" or nil
end
function G:Condition(state,key,current)
  local next_=state.next
  local status=next_ and next_[key.."Status"] or "UNKNOWN"
  local value=next_ and next_[key]
  if status=="NONE" then return {status=status,met=true,display="없음"} end
  if status~="VERIFIED" or not validNumber(value) then return {status="UNKNOWN",display="-"} end
  local met;if validNumber(current) then met=current>=value end
  return {status=status,required=value,display=tostring(value),met=met,insufficient=met==false}
end
function G:Places(state)
  local next_=state.next;local side=faction()
  local catalog=self.siteCatalog
  local coverage=catalog and catalog.coverage[state.id] and next_ and catalog.coverage[state.id][next_.id]
  local known=side~=nil and coverage and coverage.status=="COMPLETE_SOURCE_LIST"
  local keys,count={},0
  for _,a in ipairs(next_ and next_.candidates or {}) do
    if not publicText(a.npc) or not publicText(a.kind) or not publicText(a.side) then known=false
    else keys[#keys+1]=a.npc..":"..a.kind..":"..tostring(a.ref or 0)..":"..a.side end
    count=count+1
    if not M.rankCatalog.locations[a.npc] then known=false end
    if a.side~="alliance" and a.side~="horde" and a.side~="both" then known=false end
    if a.kind~="trainer" and a.kind~="book" and a.kind~="quest" then known=false end
    if (a.kind=="book" or a.kind=="quest") and (not publicText(a.title) or not validNumber(a.ref) or a.ref==0) then known=false end
  end
  table.sort(keys)
  if not coverage or count~=coverage.count or table.concat(keys,"|")~=coverage.signature then known=false end
  local result,byID={},{}
  for _,c in ipairs(self:Candidates(state)) do
    local site=catalog and catalog.sites[c.point.id]
    if not site or site.status~="VERIFIED" or not publicText(site.id) or not publicText(site.label) or not publicText(c.point.name) then known=false
    else
      local place=byID[site.id]
      if not place then place={id=site.id,label=site.label,candidates={},candidate=c};byID[site.id]=place;result[#result+1]=place end
      place.candidates[#place.candidates+1]=c
    end
  end
  local signature={side or "unknown"}
  for _,place in ipairs(result) do signature[#signature+1]=place.id.."="..place.candidate.id end
  return result,known==true,table.concat(signature,"|")
end
function G:Presentation(id)
  local state=self:State(id)
  local view={state=state,faction=faction()}
  view.level=self:Condition(state,"level",state.level)
  view.skill=self:Condition(state,"skill",state.skill)
  view.eligible=state.status=="next" and state.next~=nil and view.level.met==true and view.skill.met==true
  view.places,view.placesKnown,view.signature=self:Places(state)
  view.showPlaces=view.eligible and M:GetDB().rankGuide.locations==true and view.placesKnown and #view.places>=1 and #view.places<=2
  local trainers=true
  for _,place in ipairs(view.places) do for _,candidate in ipairs(place.candidates) do if candidate.method.kind~="trainer" then trainers=false end end end
  view.trainerSummary=view.eligible and M:GetDB().rankGuide.locations==true and view.placesKnown and #view.places>=4 and trainers
  view.registrable=0
  if view.showPlaces then
    for _,place in ipairs(view.places) do
      place.point,place.reason=self:Point(place.candidate)
      if place.point then view.registrable=view.registrable+1 end
    end
  end
  view.canRegister=view.showPlaces and view.registrable>0 and self:NoteReason()==nil
  return view
end
