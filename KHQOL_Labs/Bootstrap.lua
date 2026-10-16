local addonName = ...
local K = assert(_G.KHQOL, "Install and enable KHQOL.")
assert(not K.installationReady, "KHQOL features require a UI reload; late hot-loading is unsupported.")
K.modules.buffReminder = K.modules.buffReminder or {}
K.modules.procAlert = K.modules.procAlert or {}
K.modules.objectHighlight = K.modules.objectHighlight or {}
K.modules.frameInspector = K.modules.frameInspector or {}
K.modules.performanceMonitor = K.modules.performanceMonitor or {}
K.modules.procAlert.experimental = true
K.modules.performanceMonitor.experimental = true
