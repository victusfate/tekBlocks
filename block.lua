
local MINOR = 1
local lib = LibStub:NewLibrary("tekBlock2", MINOR)
if not lib then return end


lib.init = lib.init or 0
function lib:new(dataobjname, db)
	-- Delayed init, don't init until first call, and only upgrade that which needs it if previously init'd
	if self.init < 1 then
		self.backdrop = {
--~ 			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
--~ 			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
--~ 			edgeSize = 16,
--~ 			insets = {left = 5, right = 5, top = 5, bottom = 5},
--~ 			tile = true, tileSize = 16,
			bgFile = "Interface\\AddOns\\tekBlocks\\solid", tile = true, tileSize = 16,
			edgeFile = "Interface\\AddOns\\tekBlocks\\tekstures", edgeSize = 8,
			insets = {left = 8, right = 8, top = 8, bottom = 8},
		}


		function self:OnDragStart()
			if self.db.locked then return end
			local OnLeave = self:GetScript("OnLeave")
			if OnLeave then OnLeave(self) end
			self.OnEnter = self:GetScript("OnEnter")
			self:SetScript("OnEnter", nil)
			self:StartMoving()
		end


		function self:OnDragStop()
			if self.db.locked then return end
			self:SetScript("OnEnter", self.OnEnter)
			if self.OnEnter then self.OnEnter(self) end
			self.OnEnter = nil
			self:StopMovingOrSizing()
			self.db.x, self.db.y = self:GetCenter()
		end


		function self:TextUpdate(event, name, key, value)
			self.text:SetText(value)
			if self.db.resize then self:SetWidth(self.text:GetStringWidth() + 8) end
		end


		function self:SetDObjScript(event, name, key, value) self:SetScript(key, value) end
	end

	self.init = MINOR


	-- And now the good bits
	local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
	local dataobj = ldb:GetDataObjectByName(dataobjname)

	local frame = CreateFrame("Button", nil, UIParent)
	frame:SetHeight(24)

	frame.db = db
	frame:SetPoint("CENTER", UIParent, db.x and "BOTTOMLEFT" or "TOP", db.x or 0, db.y or -100)

--~ 	frame:EnableMouse(true)
--~ 	frame:RegisterForClicks("AnyUp")
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetClampedToScreen(true)

	frame:SetBackdrop(self.backdrop)
	frame:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)

	frame:SetScript("OnDragStart", self.OnDragStart)
	frame:SetScript("OnDragStop", self.OnDragStop)

	frame.text = frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	frame.text:SetPoint("CENTER")
	frame.text:SetText(dataobj.text or dataobjname)
	frame:SetWidth(frame.text:GetStringWidth() + 8)
	frame.TextUpdate = self.TextUpdate
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..dataobjname.."_text", "TextUpdate")

	local function GetQuadrant(frame)
		local x,y = frame:GetCenter()
		if not x or not y then return "BOTTOMLEFT", "BOTTOM", "LEFT" end
		local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
		return vhalf..hhalf, vhalf, hhalf
	end

	frame.SetDObjScript = self.SetDObjScript
	frame:SetScript("OnEnter", function(self)
		print("OnEnter", dataobj.OnEnter, dataobj.OnTooltipShow)
		if dataobj.OnEnter then return dataobj.OnEnter(self) end
		if dataobj.OnTooltipShow then
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			local quad, vhalf, hhalf = GetQuadrant(self)
			local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
			GameTooltip:SetPoint(quad, self, anchpoint)

			dataobj.OnTooltipShow(GameTooltip)
			return GameTooltip:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self) if dataobj.OnLeave then dataobj.OnLeave(self) else GameTooltip:Hide() end end)
	--ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..dataobjname.."_OnLeave", "SetDObjScript")

	return frame
end
