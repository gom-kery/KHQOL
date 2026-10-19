local K=assert(_G.KHQOL)
local M=K.modules.unitFrames
local sides={CENTER=true,LEFT=true,RIGHT=true}
local function offset(n) return K.IsPublicNumber(n) and math.max(-50,math.min(50,n)) or 0 end
for _,unit in ipairs({"player","target"}) do
 for _,kind in ipairs({"health","power"}) do
  local d=M.defaults[unit];d[kind.."TextPosition"]="CENTER";d[kind.."TextX"]=0;d[kind.."TextY"]=0
 end
end
function M:NormalizeValueTextPositions(db)
 for _,unit in ipairs({"player","target"}) do
  for _,kind in ipairs({"health","power"}) do
   local d=db[unit];local key=kind.."TextPosition"
   if not sides[d[key]] then d[key]="CENTER" end
   d[kind.."TextX"]=offset(d[kind.."TextX"]);d[kind.."TextY"]=offset(d[kind.."TextY"])
  end
 end
end
function M:HasValueTextPosition(unit) return unit=="player" or unit=="target" end
function M:ValueTextPosition(unit,kind)
 local d=self:GetDB()[unit];local side=d and d[kind.."TextPosition"]
 return sides[side] and side or "CENTER",offset(d and d[kind.."TextX"]),offset(d and d[kind.."TextY"])
end
function M:LayoutValueText(text,bar,unit,kind,ratio)
 local side,x,y=self:ValueTextPosition(unit,kind);ratio=ratio or 1
 text:ClearAllPoints()
 -- Move the anchor when alignment changes, instead of changing justification
 -- inside the same stretched box. Never read a rendered/secret text width.
 text:SetWidth(0);text:SetWordWrap(false)
 local inset=side=="LEFT" and 2 or side=="RIGHT" and -2 or 0
 text:SetPoint(side,bar,side,(inset+x)*ratio,y*ratio)
 text:SetJustifyH(side);text:SetJustifyV("MIDDLE")
end
-- Forward native display strings directly to C text setters. In BOTH mode,
-- preserve both pieces in one movable text rather than overlapping copies.
function M:RenderDefaultValue(text,bar)
 local function shown(source) return source and K.PublicCall(source.IsShown,source)==true end
 local function read(source)
  if not source or type(source.GetText)~="function" then return false end
  local ok,value=pcall(source.GetText,source)
  if ok and type(value)=="string" then
   if K.IsPublicValue(value) and value=="" then return false end
   return true,value
  end
  return false
 end
 if shown(bar.LeftText) and shown(bar.RightText) then
  local hasLeft,left=read(bar.LeftText);local hasRight,right=read(bar.RightText)
  if hasLeft and hasRight then return pcall(text.SetFormattedText,text,"%s %s",left,right) end
 end
 for _,source in ipairs({bar.TextString or false,bar.LeftText or false,bar.RightText or false}) do
  if source and shown(source) then
   local ok,value=read(source);if ok then return pcall(text.SetText,text,value) end
  end
 end
 return false
end
function M:CopyDefaultValueStyle(text,bar,kind)
 local source=bar.TextString or bar.LeftText or bar.RightText;if not source then return end
 local font,size,flags=K.PublicCall(source.GetFont,source)
 if font and K.IsPublicNumber(size) then text:SetFont(font,size,kind=="health" and self:HealthTextFlags(flags) or flags or "") end
 local ok,r,g,b,a=pcall(source.GetTextColor,source)
 if ok and type(r)=="number" and type(g)=="number" and type(b)=="number" and type(a)=="number" then pcall(text.SetTextColor,text,r,g,b,a) end
end
