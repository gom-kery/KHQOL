local addonName = ...
local K = assert(_G.KHQOL, "Install and enable KHQOL.")
assert(not K.installationReady, "KHQOL features require a UI reload; late hot-loading is unsupported.")
K.modules.basicUI = K.modules.basicUI or {}
K.modules.frameMover = K.modules.frameMover or {}
K.modules.unitFrames = K.modules.unitFrames or {}
K.modules.castBar = K.modules.castBar or {}
