local addonName = ...
local K = assert(_G.KHQOL, "Install and enable KHQOL.")
assert(not K.installationReady, "KHQOL features require a UI reload; late hot-loading is unsupported.")
K.modules.general = K.modules.general or {}
K.modules.generalConvenience = K.modules.generalConvenience or {}
K.modules.chatEnhancement = K.modules.chatEnhancement or {}
