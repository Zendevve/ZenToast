local assert, frame = OneRingLib.xlu.assert, ShapeshiftBarFrame;
local keeper, parent = CreateFrame("Frame"), frame:GetParent();
keeper:Hide();

local function SetStanceBarVisibility(...)
	if select("#", ...) == 0 then
		return SetStanceBarVisibility("HideStanceBar", (OneRingLib:GetOption("HideStanceBar")));
	end
	local option, hidden, id = ...;
	if hidden == nil then hidden = true; end
	if id ~= nil then return false; end
	if InCombatLockdown() then
		pendingValue = hidden;
	else
		frame:SetParent(hidden and keeper or parent);
		if hidden == false and frame:IsShown() then frame:Show(); end
		pendingValue = nil;
	end
end
local function syncPending(event)
	if pendingValue ~= nil then
		SetStanceBarVisibility(pendingValue);
	end
end

OneRingLib:RegisterOption("HideStanceBar", false, SetStanceBarVisibility);
EC_Register("PLAYER_REGEN_ENABLED", "OPie.StanceBar.Combat", syncPending);