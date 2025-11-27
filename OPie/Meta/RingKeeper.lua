local RingKeeper, assert, copy = {}, OneRingLib.xlu.assert, OneRingLib.xlu.copy;
local RK_RingDesc, RK_RingData, RK_RingIDs, RK_Version, RK_Rev, SV = {}, {}, {}, 1, 21;
local RK_ManagedRingNames, RK_ConditionedRings, RK_DeletedRings, RK_FastClick = {}, {item={},ring={},fly={},equipmentset={}};
local unlocked, queue = false, {}; -- Waiting for SVs

-- ORL/API adapter functions
local function RK_DoEquipSet(r, set)
	EquipmentManager_EquipSet(set);
end

-- Ring description -> OneRing propsTable conversion and updates code
local RK_RingPreClick, RK_ParseMacro; -- local functions defined later
do -- Macro parser
	local castAlias = {[SLASH_CAST1]=true,[SLASH_CAST2]=true,[SLASH_CAST3]=true,[SLASH_CAST4]=true,[SLASH_USE1]=true,[SLASH_USE2]=true,[SLASH_CASTSEQUENCE1]=true,[SLASH_CASTSEQUENCE2]=true,[SLASH_CASTRANDOM1]=true,[SLASH_CASTRANDOM2]=true};
	local function RK_MacroSpellIDReplace(sidlist)
		for id in sidlist:gmatch("%d+") do
			local sname, srank = GetSpellInfo(tonumber(id));
			if not OneRingLib.xlu.companionSpellCache(sname) and sname then sname, srank = GetSpellInfo(sname); end
			if sname then return sname; end
		end
		return "";
	end
	local function RK_RemoveEmptyClauses(clause)
		return clause:gsub("%b[]", ""):match("^%s*;?$") and "" or nil;
	end
	local function RK_MacroLineParse(prefix, command, args)
		if command == "#show" or command == "#showtooltip" or castAlias[command:lower()] then
			args = args:gsub("[^;]+;?", RK_RemoveEmptyClauses);
			return args:match("%S") and prefix .. args or "";
		end
	end
	function RK_ParseMacro(mtext)
		local text = mtext:gsub("{{spell:([%d/]+)}}", RK_MacroSpellIDReplace);
		text = ("\n" .. text):gsub("(\n([#/]%S+) )([^\n]+)", RK_MacroLineParse):gsub("[%s;]*\n", "\n"):gsub("[%s;]*$", "");
		local req = (text:match("[\n\r]#rkrequire %s*([^\n\r]+)") or ""):match("^(%S.-)%s*$");
		if req and not (GetSpellInfo(req) or OneRingLib.xlu.companionSpellCache(req)) then return ""; end
		return (text:gsub("\n#rkrequire[^\n]*", ""):gsub("^\n", ""));
	end
end
local function RK_IsRelevantRingDescription(desc)
	if (desc.class ~= nil and desc.class ~= select(2, UnitClass("player"))) or
		 (desc.limitToChar ~= nil and desc.limitToChar ~= UnitName("player")) then
		return false;
	end
	return true;
end
local function RK_Initializer(event, name, sv)
	if event == "LOADED" then
		SV, unlocked = sv, true;
		local pname, deleted = UnitName("player"), sv.OPieDeletedRings or {};
		RK_DeletedRings, RK_FastClick, sv.OPieDeletedRings, sv.OPieFastClick = {}, sv.OPieFastClick or {};

		for k, v in pairs(queue) do
			if deleted[k] == nil and (sv[k] == nil or (sv[k].version or 0) < (v.version or 0)) then
				local ok, err = pcall(RingKeeper.AddRing, RingKeeper, k, v);
				if not ok then
					EC_Error("RingKeeper", k, err:gsub("Interface\\AddOns\\[^\\]+\\", ""));
				end
				sv[k] = nil;
			elseif deleted[k] then
				RK_DeletedRings[k] = true;
			end
		end
		for k, v in pairs(sv) do -- Compatibility with ORL 1.39+
			if not k:match("^%a[%a%d]+$") then
				sv[k], sv[RingKeeper:GenFreeRingName(k)] = nil, v;
			end
		end
		for k, v in pairs(sv) do
			local ok, err = pcall(RingKeeper.AddRing, RingKeeper, k, v);
			if not ok then
				EC_Error("RingKeeper", k, err:gsub("Interface\\AddOns\\[^\\]+\\", ""));
			end
		end
	elseif event == "LOGOUT" then
		for k, v in pairs(sv) do sv[k] = nil; end
		for k, v in pairs(RK_RingDesc) do
			if type(v) == "table" and v.save and not RK_DeletedRings[k] then
				for i, v2 in ipairs(v) do
					v2.c = ("%02x%02x%02x"):format((v2.r or 0) * 255, (v2.g or 0) * 255, (v2.b or 0) * 255);
					v2.spell, v2.spell2, v2.type, v2.action = nil, nil, nil, nil;
					v2.b, v2.g, v2.r, v2.autocaption, v2.autoicon = nil, nil, nil, nil, nil;
				end
				sv[k] = v;
			end
			if RK_RingIDs[k] then
				local rslice = select(7, OneRingLib:GetRingInfo(RK_RingIDs[k])) or nil;
				RK_FastClick[k] = rslice and RK_RingData[k][rslice] and RK_RingData[k][rslice].rkId or nil;
			end
		end
		sv.OPieDeletedRings, sv.OPieFastClick = next(RK_DeletedRings) and RK_DeletedRings or nil, next(RK_FastClick) and RK_FastClick or nil;
	end
end
local function GetPlayerSpell(spell, exact)
	if exact then
		local o, s,r = pcall(GetSpellInfo, GetSpellInfo(spell));
		return o and s and (s .."("..r..")") or nil;
	else
		local o, s,r = pcall(GetSpellInfo, (GetSpellInfo(spell)));
		return o and (s and s:match("%(") and (s .. "(" .. r .. ")") or s);
	end
end
local function RK_SyncRingEntry(e)
	local oldtype, oldaction, oldtarget, oldfc = e.type, e.action, e.target, e.fastClick;
	local rtype, rid, rid2, needPreClick = e.rtype, e.id, e.id2, false;
	e.fastClick, e.type, e.action, e.target, e.autocaption, e.autoicon, e.tipType, e.tipDetail = (not not e.fcSlice) or nil;

	if (rtype == nil or rtype == "macrotext") and type(rid) == "string" then
		e.action = RK_ParseMacro(rid);
		e.type = e.action:match("%S") and "macrotext" or nil;
	elseif (rtype == nil) and type(rid) == "number" then
		e.type, e.action = "spell", (rid2 and GetPlayerSpell(rid2, e.erank)) or GetPlayerSpell(rid, e.erank) or nil;
	elseif rtype == "item" and type(rid) == "number" then
		e.action = e.byName ~= true and ("item:"..rid) or GetItemInfo(rid);
		e.type, needPreClick = ((not e.onlyWhilePresent) or (e.action and GetItemCount(e.action) > 0)) and "item" or nil, true;
	elseif rtype == "macro" and rid then
		e.type, e.action = rtype, (GetMacroInfo(rid) or not e.onlyWhilePresent) and rid;
	elseif rtype == "ring" and rid then
		local _, exists = OneRingLib:GetRingInfo(rid);
		e.type, e.action = rtype, (exists or not e.onlyWhilePresent) and rid;
	elseif rtype == "companion" and rid then
		local name, _, icon = GetSpellInfo(rid);
		e.type, e.action, e.autocaption, e.autoicon = "spell", OneRingLib.xlu.companionSpellCache(name) and name or nil, name, icon;
	elseif rtype == "equipmentset" and type(rid) == "string" and GetEquipmentSetInfoByName(rid) then
		e.type, e.action, e.target, e.autocaption, e.autoicon, e.tipType, e.tipDetail =
			"func", RK_DoEquipSet, rid, rid, "Interface\\Icons\\" .. GetEquipmentSetInfoByName(rid), "equipmentset", rid;
	end

	return e.type ~= oldtype or e.action ~= oldaction or e.target ~= oldtarget or oldfc ~= e.fastClick, needPreClick;
end
local function RK_SyncRing(name, force)
	local desc, ring, changed = RK_RingDesc[name], RK_RingData[name], (force == true);
	if not RK_IsRelevantRingDescription(desc) then return; end
	if not ring then
		RK_RingData[name] = {};
		ring, changed = RK_RingData[name], true;
	end
	
	local needPreClick;
	for i, e in ipairs(desc) do
		local sliceChanged, sliceNeedsPreClick = RK_SyncRingEntry(e);
		changed, needPreClick = changed or sliceChanged, needPreClick or sliceNeedsPreClick;
	end
	for k,v in pairs(RK_ConditionedRings) do v[name] = nil; end

	if changed or ((not ring.preClick) ~= (not needPreClick)) or not RK_RingIDs[name] then
		-- Clear previous ring entries, copy metadata again
		for k, v in pairs(ring) do
			ring[k] = nil;
		end
		for k, v in pairs(desc) do 
			if type(k) ~= "number" then 
				ring[k] = v; 
			end
		end
		
		-- Copy well-defined ring entries from parsed description
		for i, e in ipairs(desc) do
			if e.type and e.action then
				ring[#ring+1] = {e.type, e.action, e.target, r=e.r, g=e.g, b=e.b, psbind=e.psbind, caption=e.caption or e.autocaption, icon=e.icon or e.autoicon, rotation=e.rotation, tipType=e.tipType, tipDetail=e.tipDetail, fastClick=e.fastClick, rkId=i};
				if (e.fastClick and RK_FastClick[name] == i) then
					ring.fastClickSlice = #ring;
				end
			end
		end
		ring.preClick = needPreClick and RK_RingPreClick or nil;

		-- Submit ring for update
		if not RK_RingIDs[name] then
			local ok, id = EC_pcall("OPie.CRSync", name, OneRingLib.CreateRing, OneRingLib, name, ring);
			if ok then
				RK_RingIDs[name], RK_RingIDs[id] = id, name;
			end
		else
			EC_pcall("OPie.CRSync", name, OneRingLib.SetRingData, OneRingLib, RK_RingIDs[name], ring);
		end
	end

	-- Restore conditioning; this run around avoids an infite (but quickly broken) loop caused by CreateRing firing its notifier event.
	for i,e in ipairs(desc) do
		if (e.onlyWhilePresent or e.rtype == "equipmentset") and RK_ConditionedRings[e.rtype] then
			RK_ConditionedRings[e.rtype][name] = true;
		elseif type(e.id) == "string" and (e.rtype == "macrotext" or e.rtype == nil) and e.id:match("%[[^%]]*flyable") then
			RK_ConditionedRings.fly[name] = true;
		end
	end
end
local function RK_CheckSliceColors(props)
	for i, v2 in ipairs(props) do
		if v2.c and not (v2.r and v2.g and v2.b) then
			local r,g,b = v2.c:match("^(%x%x)(%x%x)(%x%x)$");
			if r then
				v2.r, v2.g, v2.b = tonumber(r, 16)/255, tonumber(g, 16)/255, tonumber(b, 16)/255;
			end
		end
	end
	return props;
end
function RK_RingPreClick(ring, slice)
	RK_SyncRing(RK_RingIDs[ring]);
end
local rkEventMap = {PLAYER_REGEN_DISABLED="item", ["ORL.CREATE_RING"]="ring", EQUIPMENT_SETS_CHANGED="equipmentset"};
local function RK_Event(event, ...)
	if rkEventMap[event] then
		for k in pairs(RK_ConditionedRings[rkEventMap[event]]) do
			EC_pcall("RK.Sync", "Ring " .. k, RK_SyncRing, k);
		end
	else
		for k,v in pairs(RK_RingDesc) do
			EC_pcall("RK.Sync", "Ring " .. k, RK_SyncRing, k);
		end
	end
end

-- Public API
function RingKeeper:AddRing(name, desc)
	assert(type(name) == "string" and type(desc) == "table", "Syntax: RingKeeper:AddRing(name, descTable);", 2);
	assert(RK_RingDesc[name] == nil, "Ring %q is already described.", 2, name);
	assert(unlocked == true or not queue[name], "Ring %q is already described.", 2, name);
	for k,v in pairs(desc) do if type(v) == "table" and v.rtype == "nitem" then v.rtype, v.byName = "item", true; end end
	if not unlocked then
		queue[name] = desc;
		return;
	end
	local rid = RK_RingIDs[name] or (#RK_ManagedRingNames + 1);
	RK_ManagedRingNames[rid], RK_RingDesc[name], RK_DeletedRings[name] = name, RK_CheckSliceColors(copy(desc)), nil;
	RK_SyncRing(name, true);
end
function RingKeeper:ModifyRing(name, desc)
	assert(type(name) == "string" and type(desc) == "table", "Syntax: RingKeeper:ModifyRing(name, descTable);", 2);
	assert(RK_RingDesc[name], "Ring %q is not described.", 2, name);
	desc.save = true; -- modifications must be saved.
	RK_RingDesc[name] = RK_CheckSliceColors(copy(desc, nil, RK_RingDesc[name]));
	RK_SyncRing(name, true);
end
function RingKeeper:RemoveRing(name)
	assert(type(name) == "string", "Syntax: RingKeeper:RemoveRing(name);", 2);
	assert(RK_RingDesc[name], "Ring %q is not described.", 2, name);
	if RK_RingIDs[name] then
		-- Replace ring with dummy, unbind.
		OneRingLib:SetRingData(RK_RingIDs[name], {name="Remnant", removed=true, internal=true});
		OneRingLib:SetRingBinding(RK_RingIDs[name], nil);
		OneRingLib:ClearRingOptions(RK_RingIDs[name]);
	end
	RK_RingDesc[name], SV[name], RK_DeletedRings[name] = nil, nil, true;

	for i,n in ipairs(RK_ManagedRingNames) do
		if n == name then
			table.remove(RK_ManagedRingNames, i);
			return;
		end
	end
end
function RingKeeper:GetRingDescription(name)
	assert(type(name) == "string", "Syntax: descTable = RingKeeper:GetRingDescription(name);", 2);
	local ring = assert(RK_RingDesc[name], "Ring %q is not described.", 2, name);
	return copy(ring);
end
function RingKeeper:GetVersion()
	return RK_Version, RK_Rev;
end
function RingKeeper:GetManagedRings()
	return #RK_ManagedRingNames;
end
function RingKeeper:GetManagedRingName(id)
	assert(type(id) == "number", "Syntax: name, hname, active, numSlices = RingKeeper:GetManagedRingName(index);", 2);
	local id = assert(RK_ManagedRingNames[id], "Index out of range", 2);
	return id, RK_RingDesc[id].name or id, RK_RingIDs[id] ~= nil, #RK_RingDesc[id];
end
function RingKeeper:RestoreDefaults()
	for k, v in pairs(queue) do
		if RK_IsRelevantRingDescription(v) then -- Do not reset rings that cannot be "seen".
			if RK_RingDesc[k] ~= nil then
				self:ModifyRing(k, queue[k]);
			else
				self:AddRing(k, queue[k]);
			end
		end
	end
end
function RingKeeper:GenFreeRingName(base)
	assert(type(base) == "string", "Syntax: name = RingKeeper:GenFreeRingName(\"base\");", 2);
	base = base:gsub("[^%a%d]", "");
	if base:match("^OPie") or not base:match("^%a") then base = "x" .. base; end
	local ap, c = "", 1;
	while RK_RingDesc[base .. ap] or SV[base .. ap] do ap, c = math.random(2^c), c+1; end
	return base .. ap;
end
function RingKeeper:ParseMacro(mtext, removeImpossibleClauses)
	assert(type(mtext) == "string" and (removeImpossibleClauses == nil or type(removeImpossibleClauses) == "boolean"), "Syntax: macro = RingKeeper:ParseMacro(\"macrotext\"[, removeImpossibleClauses]);", 2);
	return removeImpossibleClauses == false and (mtext:gsub("{{spell:(%d+)[^}]*}}", GetSpellInfo)) or RK_ParseMacro(mtext);
end

if type(OneRingLib) == "table" then
	OneRingLib.RingKeeper = RingKeeper;
	SV = OneRingLib:RegisterPVar("RingKeeper", SV, RK_Initializer);
	EC_Register("SPELLS_CHANGED", "RingKeeper.Update", RK_Event);
	EC_Register("PLAYER_REGEN_DISABLED", "RingKeeper.Items", RK_Event);
	EC_Register("ORL.COMPANION_CACHE_UPDATE", "RingKeeper.Update", RK_Event);
	EC_Register("EQUIPMENT_SETS_CHANGED", "RingKeeper.Update", RK_Event);
	EC_Register("ORL.CREATE_RING", "RingKeeper.Update", RK_Event);
end