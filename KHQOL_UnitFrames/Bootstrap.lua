local _,addon=...
local K=_G.KHQOL
if not K or K.installationReady or not K.NativePosition or not K.NativeAppearance then return end
local basicUI=K.modules.basicUI
if not basicUI or not basicUI.GetPointBaseline then return end
addon.loadUnitFrames=true
-- An unmodified legacy folder can load in either order. Allow at most that
-- one party implementation until the old folder has been removed.
addon.loadParty=not K:HasLegacyPartyPackage() and not K.ModuleRegistry.entries.partyFrames
