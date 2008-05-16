﻿
------------------------------
--      Are you local?      --
------------------------------

local UPDATEPERIOD = 0.5
local prevmem, elapsed, tipshown = collectgarbage("count"), 0.5
local string_format, math_modf, GetNetStats, GetFramerate, collectgarbage = string.format, math.modf, GetNetStats, GetFramerate, collectgarbage


local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math_modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("FPSBlock")
dataobj.text = "75.0 FPS"


---------------------------
--      Init/Enable      --
---------------------------

function f:ADDON_LOADED(event, addon)
	if addon ~= "FPSBlock" then return end

	if FPSBlockDB and FPSBlockDB.profiles then FPSBlockDB = nil end
	FPSBlockDB = FPSBlockDB or {}

	block = LibStub:GetLibrary("tekBlock"):new("FPSBlock", FPSBlockDB)

	f:UnregisterEvent("ADDON_LOADED")
	f.ADDON_LOADED = nil
end


--------------------------------
--      OnUpdate Handler      --
--------------------------------

f:SetScript("OnUpdate", function(self, elap)
	elapsed = elapsed + elap
	if elapsed < UPDATEPERIOD then return end

	elapsed = 0
	local fps = GetFramerate()
	local r, g, b = ColorGradient(fps/75, 1,0,0, 1,1,0, 0,1,0)
	dataobj.text = string_format("|cff%02x%02x%02x%.1f|r FPS", r*255, g*255, b*255, fps)

	if tipshown then dataobj.OnEnter(tipshown) end
end)


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


function dataobj.OnLeave()
	GameTooltip:Hide()
	tipshown = nil
end


function dataobj.OnEnter(self)
	tipshown = self
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("FPSBlock")

	local fps = GetFramerate()
	local r, g, b = ColorGradient(fps/75, 1,0,0, 1,1,0, 0,1,0)
	GameTooltip:AddDoubleLine("FPS:", string_format("%.1f", fps), nil,nil,nil, r,g,b)

	local _, _, lag = GetNetStats()
	local r, g, b = ColorGradient(lag/1000, 1,0,0, 1,1,0, 0,1,0)
	GameTooltip:AddDoubleLine("Lag:", lag.. " ms", nil,nil,nil, r,g,b)

	local mem = collectgarbage("count")
	local deltamem = mem - prevmem
	prevmem = mem
	local r, g, b = ColorGradient(mem/(60*1024), 0,1,0, 1,1,0, 1,0,0)
	GameTooltip:AddDoubleLine("Memory:", string_format("%.2f MiB", mem/1024), nil,nil,nil, r,g,b)

	local r, g, b = ColorGradient(deltamem/15, 0,1,0, 1,1,0, 1,0,0)
	GameTooltip:AddDoubleLine("Garbage churn:", string_format("%.2f KiB/sec", deltamem), nil,nil,nil, r,g,b)

	GameTooltip:Show()
end