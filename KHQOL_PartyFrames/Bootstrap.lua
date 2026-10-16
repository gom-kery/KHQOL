local addonName = ...
local K = assert(_G.KHQOL, "Install and enable KHQOL.")
assert(not K.installationReady, "KHQOL features require a UI reload; late hot-loading is unsupported.")
K.modules.partyFrames = K.modules.partyFrames or {}
