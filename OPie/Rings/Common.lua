if not (type(OneRingLib) == "table" and type(OneRingLib.CreateRing) == "function") then
	return;
end

local function generateColor(c, n)
	local hue, v, s = (15+(c-1)*360/n)%360, 1, 0.85;

	local h = floor(hue/60) % 6;
	local f = (hue/60) % 1;
	local p, q, t = v - v * s, v - v * f * s, v - v*s + v * f * s;
	if h == 0 then return v, t, p;
	elseif h == 1 then return q, v, p;
	elseif h == 2 then return p, v, t;
	elseif h == 3 then return p, q, v;
	elseif h == 4 then return t, p, v;
	elseif h == 5 then return v, p, q;
	end
end

do -- OPieTrinkets
	OneRingLib:CreateRing("OPieTrinkets", {
		{"item", (GetInventorySlotInfo("Trinket0Slot")), r=0.05, g=0.75, b=0.95}, -- top
		{"item", (GetInventorySlotInfo("Trinket1Slot")), r=0.95, g=0.75, b=0.05}, -- bottom
		name="Trinkets"
	});
end
do -- OPieRaidSymbols
	local rname, rdesc = "OPieRaidSymbols", {
		{"func", r=1, g=1, b=0}, -- yellow star
		{"func", r=1, g=0.5, b=0.05}, -- orange circle
		{"func", r=1, g=0.30, b=1}, -- purple diamond
		{"func", r=0.20, g=1, b=0.20}, -- green triangle
		{"func", r=0.65, g=0.84, b=1}, -- silver moon
		{"func", r=0.20, g=0.20, b=1}, -- blue square
		{"func", r=1, g=0.10, b=0.10}, -- red cross
		{"func", r=0.74, g=0.70, b=0.60}, -- white skull
		name="Raid Markers", hotkey="ALT-R"
	};
	local function ringClick(ring, id)
		if GetRaidTargetIndex("target") == id then id = 0; end
		SetRaidTarget("target", id);
	end
	local function ringActive(stype, sfunc, sid)
		return GetRaidTargetIndex("target") == sid;
	end
	for i=1,8 do
		rdesc[i][2], rdesc[i][3], rdesc[i].icon, rdesc[i].active, rdesc[i].caption = ringClick, i, "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i, ringActive, _G["RAID_TARGET_" .. i];
	end
	OneRingLib:CreateRing(rname, rdesc);
end
do -- OPieTracker
	local rname, rdesc, ringID = "OPieTracker", {
		name="Tracking", hotkey="ALT-F"
	};
	local function setTracking(ring, id)
		local name, tex = GetTrackingInfo(id);
		SetTracking(tex ~= GetTrackingTexture() and id or nil);
	end
	local function actionHint(etype, earg, eid)
		local name, tex = GetTrackingInfo(eid);
		return name and true or false, 0, 0, tex, name, 0, tex == GetTrackingTexture();
	end
	function rdesc.preClick()
		local n = GetNumTrackingTypes();
		if n ~= #rdesc then
			for i=1,n do
				rdesc[i] = rdesc[i] or {}; local t = rdesc[i];
				t[1], t[2], t[3], t.actionHint = "func", setTracking, i, actionHint;
				t.r, t.g, t.b = generateColor(i,n);
			end
			for i=n+1,#rdesc do
				rdesc[i] = nil;
			end
			OneRingLib:SetRingData(ringID, rdesc);
		end
	end
	ringID = OneRingLib:CreateRing(rname, rdesc);
	EC_Register("PLAYER_ENTERING_WORLD", "OPie.AutoTracker", function() return "remove", rdesc.preClick(ringID); end);
end
do -- OPieAutoQuest
	local whitelist = {[37888]=true, [37860]=true, [37859]=true, [37815]=true, [46847]=true, [47030]=true, [39213]=true, [42986]=true, [49278]=true};
	local rname, rdesc, rid = "OPieAutoQuest", {
		name="Quest Items", hotkey="ALT-Q"
	};
	rid = OneRingLib:CreateRing(rname, rdesc);

	local inring, fastClickItem = {};
	local function scanInventory()
		local changed = false;

		-- Save which item is the /current/ fast click item so syncRing can later restore that status
		fastClickItem = select(7, OneRingLib:GetRingInfo(rid));
		fastClickItem = rdesc and rdesc[fastClickItem] and rdesc[fastClickItem][2];

		-- Shuffle through the bags
		for bag=0,4 do
			for slot=1,GetContainerNumSlots(bag) do
				local iid = GetContainerItemID(bag, slot);
				local isQuest, startQuestId, isQuestActive = GetContainerItemQuestInfo(bag, slot);
				isQuest = iid and ((isQuest and (GetItemSpell(iid) or (startQuestId and not isQuestActive))) or whitelist[iid]);
				if isQuest then
					if not inring[iid] then
						rdesc[#rdesc+1], inring[iid], changed = {"item", "item:" .. iid, used=true, xiid=iid}, #rdesc+1, true;
					else
						rdesc[inring[iid]].used = true;
					end
				end
			end
		end

		-- Check whether any of our quest items are equipped... Hi, Egan's Blaster.
		for i=0,19 do
			local j = inring[GetInventoryItemID("player", i)];
			if j and rdesc[j] then rdesc[j].used = true; end
		end

		-- Drop any items in the ring we haven't found.
		local t = 1;
		for k=1,#rdesc do local v = rdesc[k];
			if v.used then
				rdesc[t], inring[v.xiid], v.used, t = rdesc[k], t, nil, t + 1;
			else
				inring[v.xiid] = nil;
			end
		end
		for k=t,#rdesc do rdesc[k], changed = nil, true; end

		return changed;
	end
	local function syncRing()
		local n = #rdesc;
		for i, d in ipairs(rdesc) do
			d.fastClick, d.r, d.g, d.b = true, generateColor(i, n);
			if fastClickItem and d[2] == fastClickItem then rdesc.fastClickSlice = i; end
		end
		OneRingLib:SetRingData(rid, rdesc);
	end
	local function pvarNotify(event, name, var)
		if event == "LOADED" then
			fastClickItem, var.fastClick = var.fastClick, fastClickItem;
			syncRing();
		elseif event == "LOGOUT" and rid then
			local fcslice = select(7, OneRingLib:GetRingInfo(rid)) or nil;
			var.fastClick = fcslice and rdesc[fcslice] and rdesc[fcslice][2] or nil;
		end
	end
	function rdesc.preClick(ring, id, force)
		if scanInventory() then
			syncRing();
		end
	end
	EC_Register("PLAYER_REGEN_DISABLED", "OPie.AutoQuest", function()
		if scanInventory() then
			syncRing();
		end
	end);
end