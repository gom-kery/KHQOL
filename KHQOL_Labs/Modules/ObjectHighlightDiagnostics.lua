local K=_G.KHQOL
local H,J=K.modules.objectHighlight,K.SoftTargetJournal
local G=H.gathering
G.diagnosticBuild="1.11.7.4"
local call,read,public=K.PublicCall,K.ReadPublicAPI,K.IsPublicValue
local function value(v)
  if not public(v) then return "<unreadable>" end
  if type(v)=="string" then return v:gsub("[\r\n]"," "):gsub("|","||"):sub(1,400) end
  if type(v)=="boolean" or K.IsPublicNumber(v) then return tostring(v) end
  return v==nil and "nil" or "<"..type(v)..">"
end
local function field(fn,...)
  local status,v=read(fn,...)
  return status=="ok" and value(v) or "<"..status..">"
end
local function metadata(name)
  local fn=C_CVar and C_CVar.GetCVarInfo or GetCVarInfo
  local status,v,_,_,_,locked,secure,readonly=read(fn,name)
  local shape=type(v)
  if status=="ok" and type(v)=="table" then
    status,v,locked,secure,readonly=read(function()
      return v.value,v.isLockedFromUser,v.isSecure,v.isReadOnly
    end)
  end
  return "info="..status.."/"..shape.." value="..value(v).." locked="..value(locked)
    .." secure="..value(secure).." readOnly="..value(readonly)
end
-- Read-only, on-demand evidence. No Sync/Tick/CVar writes, target selection,
-- tracking changes or saved diagnostic history. Cursor writes touch only our
-- hidden probe texture, never the game cursor or a native nameplate.
function G:DiagnosticText()
  local db=H:GetDB()
  local lines={"KHQOL "..value(K.VERSION).." / "..self.diagnosticBuild}
  local function add(s) lines[#lines+1]=s end
  add("module="..value(K:GetEnabled("objectHighlight")).." labUnlocked="..value(K.LabLock:IsUnlocked())
    .." canRun="..value(K:CanRunModule("objectHighlight")).." gather="..value(db.gatherEnabled))
  add("categories herb="..value(db.categories.herb.enabled).." ore="..value(db.categories.ore.enabled).." chest="..value(db.categories.chest.enabled))
  add("display offsetX="..value(db.offsetX).." offsetY="..value(db.offsetY).." px")
  add("styles herb="..value(db.categories.herb.effect).." ore="..value(db.categories.ore.effect).." chest="..value(db.categories.chest.effect))
  add("image="..value(self.frame and self.frame.reticleImagePath))
  add("active="..value(self.active).." stage="..value(self.stage).." shown="..field(self.frame and self.frame.IsShown,self.frame))
  add("reason="..value(self.status).." / journal="..value(J.status))
  add("journalActive="..value(J.active).." pending="..value(J.pending).." Lueur="..value(J:Conflict())
    .." combat="..value(K.GraphicsJournal.compat.combat()))
  add("softinteract gameObject="..field(UnitIsGameObject,self.unit).." exists="..field(UnitExists,self.unit))
  add("object="..field(UnitName,self.unit).." GUID="..field(UnitGUID,self.unit))
  add("questRelated="..field(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest,self.unit)
    .." interactRange="..field(UnitIsInInteractRange,self.unit))
  local guid=call(UnitGUID,self.unit)
  local ok,kind,blocked=pcall(self.ReadCursor,self)
  if not ok then kind,blocked=nil,nil end
  add("cursor category="..value(kind).." blocked="..value(blocked))
  add("cursor texture="..field(self.probe and self.probe.GetTexture,self.probe)
    .." atlas="..field(self.probe and self.probe.GetAtlas,self.probe))
  local plate=call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,self.unit)
  local resolved,why
  if public(guid) and type(guid)=="string" then resolved,why=self:ResolveTarget(guid) end
  add("nameplate direct="..value(plate~=nil).." alias="..value(self.alias).." resolved="..value(resolved~=nil).." / "..value(why))
  if resolved then
    add("plate shown="..field(resolved.IsShown,resolved).." forbidden="..field(resolved.IsForbidden,resolved)
      .." protected="..field(resolved.IsProtected,resolved))
  end
  add("lastRenderError="..value(self.lastRenderError))
  for _,name in ipairs({"UnitIsGameObject","UnitGUID","UnitName","SetUnitCursorTexture","GetFileIDFromPath"}) do
    add("API "..name.."="..type(_G[name]))
  end
  add("API NamePlate="..type(C_NamePlate and C_NamePlate.GetNamePlateForUnit)
    .." Quest="..type(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest)
    .." Line="..type(UIParent and UIParent.CreateLine).." Ticker="..type(C_Timer and C_Timer.NewTicker))
  add("SoftTargetInteract globalGet="..field(GetCVar,"SoftTargetInteract")
    .." namespacedGet="..field(C_CVar and C_CVar.GetCVar,"SoftTargetInteract"))
  for _,name in ipairs({"SoftTargetInteract","SoftTargetNameplateInteract","SoftTargetInteractRange","SoftTargetInteractArc",
    "SoftTargetInteractOnlyInRange","SoftTargetInteractRangeIsHard","SoftTargetIconGameObject","nameplateGameObjectMaxDistance","SoftTargetIconInteract"}) do
    local writable,why=K.GraphicsJournal.compat.writable(name)
    add("CVar "..name.."="..value(J:Read(name)).." writable="..value(writable).." / "..value(why).." / "..metadata(name))
  end
  return table.concat(lines,"\n")
end
function G:PrintDiagnostics()
  local output=self:DiagnosticText()
  if DEFAULT_CHAT_FRAME then
    for line in output:gmatch("[^\n]+") do DEFAULT_CHAT_FRAME:AddMessage("|cff80dfff[오브젝트 진단]|r "..line) end
  end
  return output
end
SLASH_KHQOLOBJECTDEBUG1="/khobjectdebug"
SLASH_KHQOLOBJECTDEBUG2="/오브젝트진단"
SlashCmdList.KHQOLOBJECTDEBUG=function() G:PrintDiagnostics() end
