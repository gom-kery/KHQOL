local _,K=...
local M=K.modules.unitFrames
local call=K.PublicCall
M.defaults.target.monsterMarks={quest=true,classification=true,size=20,x=0,y=0}
local questAtlas="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Quest"
local gold,silver="nameplates-icon-elite-gold","nameplates-icon-elite-silver"
local function clamp(v,default,lo,hi) return math.max(lo,math.min(hi,K.IsPublicNumber(v) and v or default)) end
function M:MonsterMarkSettings()
  local d=self:GetDB().target.monsterMarks
  d.size=clamp(d.size,20,8,40);d.x=clamp(d.x,0,-400,400);d.y=clamp(d.y,0,-400,400)
  return d
end
function M:MonsterMarkAtlases()
  if call(UnitExists,"target")~=true or call(UnitIsPlayer,"target")~=false then return end
  local d=self:MonsterMarkSettings();local quest,classification
  if d.quest then
    local related=call(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest,"target")
    if related==true or call(UnitIsQuestBoss,"target")==true then quest=questAtlas end
  end
  if d.classification then
    local value=call(UnitClassification,"target")
    if value=="elite" or value=="worldboss" then classification=gold
    elseif value=="rare" or value=="rareelite" then classification=silver end
  end
  return quest,classification
end
local function atlas(texture,name)
  if not name then texture:Hide();return false end
  local info=call(C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo,name)
  if type(info)~="table" or not pcall(texture.SetAtlas,texture,name,false) then texture:Hide();return false end
  texture:Show();return true
end
function M:ApplyMonsterMarks(owner,p,layout)
  local host=self.monsterMarkFrame
  local d=self:MonsterMarkSettings()
  if not self:IsEnabled() or not owner or not owner.compactActive or call(p.root.IsShown,p.root)~=true
    or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true
    or not d.quest and not d.classification then if host then host:Hide() end;return end
  if not host then
    if call(InCombatLockdown)==true then self.pending=true;return end
    host=CreateFrame("Frame",nil,UIParent);self.monsterMarkFrame=host;host:EnableMouse(false)
    host:SetFrameStrata("MEDIUM");host:SetSize(44,20)
    host.quest=host:CreateTexture(nil,"OVERLAY");host.classification=host:CreateTexture(nil,"OVERLAY")
    host.quest:SetPoint("LEFT",host,"LEFT",0,0);host.classification:SetPoint("RIGHT",host,"RIGHT",0,0)
  end
  if layout then
    if call(InCombatLockdown)==true then self.pending=true
    else
      local bar=owner.healthDisplay or p.health
      host:ClearAllPoints();host:SetPoint("RIGHT",bar,"LEFT",-6+d.x,d.y)
      host.quest:SetSize(d.size,d.size);host.classification:SetSize(d.size,d.size)
      host.markSize=d.size
    end
  end
  local quest,classification=self:MonsterMarkAtlases()
  local q=atlas(host.quest,quest);local c=atlas(host.classification,classification)
  -- This is an unprotected, owned display. Only public booleans control it.
  if call(InCombatLockdown)~=true then
    host:SetSize((q and c) and 2*(host.markSize or d.size)+4 or (host.markSize or d.size),host.markSize or d.size)
  end
  if q or c then host:Show() else host:Hide() end
end
function M:RefreshMonsterMarks()
  local owner=self.units and self.units.target
  if owner then self:ApplyMonsterMarks(owner,owner.parts,false)
  elseif self.monsterMarkFrame then self.monsterMarkFrame:Hide() end
end
