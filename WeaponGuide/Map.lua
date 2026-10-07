local ADDON, KHQOL = ...
local FWG = KHQOL.modules.weaponGuide

-- Forever's custom World Map pin provider contract has not been verified for this beta.
-- Keep this adapter inert rather than creating frames with guessed map APIs or coordinates.
FWG.MapPinsSupported = false
function FWG:RefreshMapPins()
  -- Deliberate no-op. Tooltip guidance remains fully safe when pins are unavailable.
end
