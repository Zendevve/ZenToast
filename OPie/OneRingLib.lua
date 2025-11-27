local OR_AddonName, versionMajor, versionRev, OneRing = "OPie", 1, 49, {ext={}};
local OR_Rings, OR_PendingUpdates = {}, {};
local defaultConfig = {ClickActivation=false, IndicationOffsetX=0, IndicationOffsetY=0, RingAtMouse=false, RingScale=1, ClickPriority=true, CenterAction=true, MouseBucket=3, NoClose=false, SliceBinding=false, SliceBindingString="1 2 3 4 5 6 7 8 9 0"};
local configRoot, configInstance, activeProfile, PersistentStorageInfo, optionValidators = {}, nil, nil, {}, {};
local propsMeta, optionsMeta = {__index={offset=0,r=0,g=0,b=0}}, {__index=defaultConfig};
local unlocked, ORI_Show, ORI_Hide = false;

-- Some basic utility methods
local function assert(condition, text, level, ...)
	return (not condition) and error(tostring(text):format(...), 1 + (level or 1)) or condition;
end
local function SetAttributes(frame, ...)
	assert(frame, "You're doing it wrong.", 2);
	for i=1,select("#", ...), 2 do
		frame:SetAttribute(select(i, ...), (select(i+1, ...)));
	end
end
local function copy(t, lib, into)
	assert((lib == nil or type(lib) == "table"), "Syntax: copy(t[, tLib[, into]]);", 2);
	local nt, lib = type(into) == "table" and into or {}, lib or (t and {});
	if type(into) == "table" then for k, v in pairs(nt) do if t == nil or t[k] == nil then nt[k] = nil; end end end
	if t == nil then return nt; end lib[t] = nt;
	for k, v in pairs(t) do
		if type(v) == "table" then
			nt[k] = lib[v] or copy(v, lib, nt[k]);
		else nt[k] = v; end
	end
	return nt;
end
local companionSpells, companionSpellsLL = {}, {};
local function updateSpellCache(event)
	local changed, inorder, last = false, true, select(2, GetCompanionInfo("CRITTER", 1));
	for i=1,GetNumCompanions("CRITTER") do
		local sname, cname = GetSpellInfo((select(3, GetCompanionInfo("CRITTER",i)))), select(2, GetCompanionInfo("CRITTER", i));
		companionSpellsLL[sname:lower()], companionSpells[sname], changed = sname, i, changed or (companionSpells[csID] == nil);
		inorder, last = last and cname and inorder and cname >= last, cname;
	end
	last = select(2,GetCompanionInfo("MOUNT", 1));
	for i=1,GetNumCompanions("MOUNT") do
		local sname, cname = GetSpellInfo((select(3, GetCompanionInfo("MOUNT",i)))), select(2, GetCompanionInfo("MOUNT", i));
		companionSpellsLL[sname:lower()], companionSpells[sname], changed = sname, -i, changed or (companionSpells[csID] == nil);
		inorder, last = last and cname and inorder and (cname >= last), cname;
	end
	if changed then EC_Raise("ORL.COMPANION_CACHE_UPDATE"); end
	if inorder and event == "COMPANION_UPDATE" then return "remove"; end
end
local function getCompanion(spell)
	local i = companionSpells[spell];
	if i then return i < 0 and "MOUNT" or "CRITTER", i < 0 and -i or i; end
end
local parseMacro; do -- (text, binding)
	local compactMacros, bindingCache, mod = {}, {}, {};
	local castAlias = {[SLASH_CAST1]=true,[SLASH_CAST2]=true,[SLASH_CAST3]=true,[SLASH_CAST4]=true,[SLASH_USE1]=true,[SLASH_USE2]=true,["#showtooltip"]=1,["#show"]=1,[SLASH_STOPMACRO1]=2,[SLASH_STOPMACRO2]=2,[SLASH_CASTSEQUENCE1]=3,[SLASH_CASTSEQUENCE2]=3,[SLASH_CASTRANDOM1]=4,[SLASH_CASTRANDOM2]=4};
	local function compact(macro)
		local gen = "";
		for name, args in ("\n"..macro):gmatch("\n([#/]%a+)[ \t]+([^\n]+)") do
			local ctype = castAlias[name];
			if ctype == 1 and args ~= "" then gen = args; break
			elseif ctype then
				if ctype == 2 then args = args:gsub("[^%]]+$",""); end
				gen = gen .. args .. "; ";
			end
		end
		compactMacros[macro] = gen;
		return gen;
	end
	local function fixModifierClause(open, inv, sel, close)
		if mod[sel] then
			return inv == "no" and "" or (open .. "nomod:" .. sel .. close);
		elseif sel == "" then
			local ms = "";
			for k, v in pairs(mod) do
				if not v then ms = ms .. (ms == "" and "" or "/") .. k; end
			end
			return open .. inv .. "mod:" .. ms .. close;
		else
			local ms = "";
			for m in sel:gmatch("[^/]+") do
				if not mod[m] then ms = ms .. (ms == "" and "" or "/") .. m; end
			end
			if ms == "" then
				return inv == "no" and "" or (open .. "nomod:" .. sel .. close);
			end
			return open .. inv .. "mod:" .. ms .. close;
		end
	end
	local function fixConditions(m)
		return m:gsub("([,%s%[])(n?o?)modi?f?i?e?r?:?([^,%s%]]*)([,%s%]])", fixModifierClause);
	end
	local function fixBindingModifiers(conditionedLine, binding)
		if type(binding) ~= "string" or type(conditionedLine) ~= "string" then return conditionedLine; end
		local key = binding .. "#" .. conditionedLine;
		if not bindingCache[key] then
			local bMod = binding:match("^(.-)%-?[^-]*$"):lower();
			mod.ctrl, mod.alt, mod.shift = bMod:match("ctrl") ~= nil, bMod:match("alt") ~= nil, bMod:match("shift") ~= nil;
			bindingCache[key] = bMod and conditionedLine:gsub("%b[]", fixConditions) or conditionedLine;
		end
		return bindingCache[key];
	end
	function parseMacro(text, binding)
	  if type(text) ~= "string" then return; end
		local cl, targ = compactMacros[text] or compact(text);
		if cl ~= "" then
			cl, targ = SecureCmdOptionParse(fixBindingModifiers(cl, binding));
			if cl then
				local i,a,b = QueryCastSequence(cl);
				cl = a or b and GetSpellInfo(b) or companionSpellsLL[b] or b;
			end
		end
		if (not cl) or cl == "" then return; end
		return ((GetSpellInfo(cl) and cl:match("[^%d%s]")) or companionSpells[cl]) and "spell" or "item", cl, targ;
	end
end
OneRing.xlu = {copy=copy, assert=assert, parseMacro=parseMacro, companionSpellCache=getCompanion};
OneRing.xlu.charId = ("%s-%s-%s"):format(GetCVar("realmList"):match("^([^.]+)"):upper(), GetRealmName(), UnitName("player"));
local function getSpecCharIdent()
	local tg = GetActiveTalentGroup();
	return (tg == 1 and "%s" or "%s-%d"):format(OneRing.xlu.charId, tg);
end
local isConditionalBinding = setmetatable({}, {__mode="k", __index=function(t, b)
	if type(b) == "string" then
		t[b] = b:upper():gsub("^ALT%-", ""):gsub("^CTRL%-", ""):gsub("^SHIFT%-", ""):gsub("^BUTTON(%d*)", ""):gsub(".$", "") ~= "";
		return t[b];
	end
end});

local function OR_GetRingOption(ringName, option)
	local v = configInstance.RingOptions[ringName .. "#" .. option], true;
	if v == nil then
		return configInstance[option], nil;
	end
	return v, v;
end
local function pscall(ep, f, ...)
	local o, v = pcall(f, ...);
	if o then
		return v;
	else
		pcall(geterrorhandler(), ep .. tostring(v));
	end
end
local function OR_GetActionInfoEntry(e, binding)
	if type(e) ~= "table" then return false, 0, 0, "Interface\\AddOns\\OPie\\gfx\\icon", "", 0; end
	if type(e.actionHint) == "function" then return e.actionHint(e[1], e[2], e[3]); end

	local caption, icon, active, usable, cooldown, cd, enabled, t, n, count, micon, mcaption = e.caption, e.icon, e.active;
	if type(caption) == "function" then caption = pscall("Error in custom caption handler: ", caption, e[1], e[2], e[3]); end
	if type(icon) == "function" then icon = pscall("Error in custom icon handler: ", icon, e[1], e[2], e[3]); end
	if type(active) == "function" then active = pscall("Error in custom active handler: ", active, e[1], e[2], e[3]); end

	-- Attempt to determine what this button does.
	local btype, bcontent, mTarget, _ = e[1], e[2];
	if btype == "macro" then btype, bcontent, mcaption, micon = "macrotext", GetMacroBody(bcontent) or "", GetMacroInfo(bcontent); end
	if btype == "macrotext" then btype, bcontent, mTarget = parseMacro(bcontent, binding); end
	if btype == "spell" or btype == "item" then t, n = btype, bcontent;	end
	if not (t and n) then return true, 0, 0, icon or micon or nil, caption or mcaption, 0, active, e.tipType, e.tipDetail; end -- Failed, decry own inadequacy.
	if t == "item" then n = SecureCmdItemParse(n); caption = caption or (n and GetItemInfo(n)); end

	-- Now determine whether the action is ready
	if t == "spell" then
		local cType, cId = getCompanion(n);
		if cType then
			usable, icon, cooldown, cd, enabled = (cType == "CRITTER" or (not (InCombatLockdown() or IsIndoors()))) and not UnitIsDeadOrGhost("player"), icon or select(4, GetCompanionInfo(cType, cId)), GetCompanionCooldown(cType, cId);
			if active == nil then active, usable = select(5, GetCompanionInfo(cType, cId)), usable and not UnitOnTaxi("player"); end
		else
			usable, icon, count, cooldown, cd, enabled = IsUsableSpell(n) and IsSpellInRange(n, mTarget) ~= 0, icon or GetSpellTexture(n), GetSpellCount(n), GetSpellCooldown(n);
			if active == nil then
				active = IsSelectedSpell(n) or n == UnitChannelInfo("player");
				if GetShapeshiftForm() > 0 and not active then
					local _, form, isInForm = GetShapeshiftFormInfo(GetShapeshiftForm());
					if form == n then active = isInForm; end
				end
			end
		end
	elseif t == "item" then
		usable, icon, count, cooldown, cd, enabled = IsUsableItem(n) and IsItemInRange(n, mTarget) ~= 0, icon or GetItemIcon(n), IsConsumableItem(n) and GetItemCount(n, nil, 1), GetItemCooldown(n);
	end
	if cooldown and cooldown ~= 0 then cooldown = cooldown + cd - GetTime(); end
	enabled = enabled == 0;
	usable = not not (usable and (cooldown == nil or cooldown == 0) or enabled);

	return usable, enabled and 0 or cooldown, cd, icon or nil, caption or n or "", count or 0, active, t or e.tipType, n or e.tipDetail;
end

-- Secure Environment
local OR_SecCore, OR_OpenProxy = CreateFrame("Button", "ORL_RTrigger", UIParent, "SecureActionButtonTemplate,SecureHandlerAttributeTemplate"), CreateFrame("Button", "ORLOpen", UIParent, "SecureFrameTemplate");
local OR_SRSRings, OR_SecEnv, OR_SecData, OR_ActiveProps = {};
OR_SecCore:SetWidth(9001); OR_SecCore:SetHeight(9001); OR_SecCore:SetFrameStrata("FULLSCREEN"); OR_SecCore:RegisterForClicks("AnyUp", "AnyDown"); OR_SecCore:EnableMouseWheel(); OR_SecCore:Hide();
local function OR_SpawnProxy(id)
	local f = CreateFrame("Button", "ORL_RProxy" .. id, UIParent, "SecureActionButtonTemplate");
	SetAttributes(f, "type","click", "clickbutton",OR_SecCore); f:RegisterForClicks("AnyUp", "AnyDown");
	OR_SecCore:WrapScript(f, "OnClick", "return control:RunFor(self, ORL_OnClick, button, down) or false;");
	OR_SecCore:SetFrameRef("proxy" .. id, f);
	_G["BINDING_NAME_CLICK ".. f:GetName() .. ":r" .. id] = OneRing.lang and OneRing.lang("BindingName") or "An OPie ring";
end
do -- Click dispatcher
	local OR_CancelProxy = CreateFrame("Button", "ORL_CancelProxy", UIParent, "SecureFrameTemplate");
	OR_CancelProxy:RegisterForClicks("AnyUp","AnyDown");
	OR_SecCore:SetFrameRef("tmpBindProxy", OR_CancelProxy);
	OR_SecCore:Execute([=[
		ORL_RingData, ORL_RingChain, ORL_Rotation, ORL_RingAlias = newtable(), newtable(), newtable(), newtable();
		sizeSq, bindProxy = 9001^2, self:GetFrameRef("tmpBindProxy");
		ORL_CloseActiveRing = [[ local oaid, shouldKeepOwner = activeRingID, ...;
			if not shouldKeepOwner then	owner:Hide();	end bindProxy:ClearBindings();
			activeRingID, activeRing = nil, nil;
			control:CallMethod("NotifyState", "close", oaid);
		]];
		ORL_RegisterVariations = [[	local binding, mapkey, downmix = ...;
			for alt=0,downmix:match("ALT") and 1 or 0 do for ctrl=0,downmix:match("CTRL") and 1 or 0 do for shift=0,downmix:match("SHIFT") and 1 or 0 do
				bindProxy:SetBindingClick(true, (alt == 1 and "ALT-" or "") .. (ctrl == 1 and "CTRL-" or "") .. (shift == 1 and "SHIFT-" or "") .. binding, owner, mapkey);
			end end end
		]];
		ORL_OpenRing = [[ local ring, ringID, forceLC, fastSwitch = ORL_RingData[...], ...;
			control:CallMethod("NotifyState", "pre", ringID);
			leftActivation = not not (forceLC or ring.ClickActivation);
			bindProxy:SetBindingClick(true, "BUTTON2", bindProxy, "close");
			bindProxy:SetBindingClick(true, "ESCAPE", bindProxy, "close");
			control:RunFor(self, ORL_RegisterVariations, "MOUSEWHEELUP", "mwup", "ALT-CTRL-SHIFT");
			control:RunFor(self, ORL_RegisterVariations, "MOUSEWHEELDOWN", "mwdown", "ALT-CTRL-SHIFT");
			if not (ring.bind or ""):match("BUTTON3$") then control:RunFor(self, ORL_RegisterVariations, "BUTTON3", "mwin", "ALT-CTRL-SHIFT"); end
			if leftActivation and ring.bind then bindProxy:SetBindingClick(true, ring.bind, self, "close"); end
			if ring.SliceBinding then
				local prefix = ring.bind and not leftActivation and ring.bind:match("^(.-)[^-]*$") or "";
				for i=1,ring.count do
					if ring.SliceBinding[i] then
						control:RunFor(self, ORL_RegisterVariations, ring.SliceBinding[i], "slice" .. i, prefix);
					end
				end
			end
			bindProxy:SetBindingClick(true, leftActivation and "BUTTON1" or ring.bind, self, "use");
			owner:SetScale(ring.scale); owner:SetPoint('CENTER', ring.ofs, ring.ofsx, ring.ofsy);
			if ring.ClickPriority then owner:Show(); end
			activeRingID, activeRing, fastClick, wheelBucket = ringID, ring, ring.fastClick and ring.fcSlice and ring.fastClick[ring.fcSlice] or nil, 0;
			control:CallMethod("NotifyState", "open", ringID, fastClick, fastSwitch);
		]];
		ORL_GetPureSlice = [[
			local x, y = owner:GetMousePosition(); x, y = x - 0.5, y - 0.5;
			local radius, segAngle = (x*x*sizeSq + y*y*sizeSq)^0.5, 360/activeRing.count;
			if radius >= 40 then return floor(((math.deg(math.atan2(x, y)) + segAngle/2 - activeRing.ofsRad) % 360) / segAngle) + 1, false;
			elseif radius <= 20 then return fastClick, true; end
		]];
		ORL_GetSlice = [[	local ring, slice = ...;
			if not slice then return; end
			local rkey = "r" .. ring .. "s" .. slice;
			local stype, sring = owner:GetEffectiveAttribute("type", rkey), owner:GetEffectiveAttribute("ring", rkey);
			if stype == "ring" and ORL_RingChain[rkey] then
				return;
			elseif stype == "ring" and ORL_RingData[sring] then
				ORL_RingChain[rkey] = true;
				local abtn, aring, aslice = control:Run(ORL_GetSlice, sring, ((ORL_Rotation[sring .. "#" .. ring .. "." .. slice] or 0) % ORL_RingData[sring].count) + 1);
				return abtn, aring, aslice, slice;
			end
			return "r" .. ring .. "s" .. slice, ring, slice, slice;
		]];
		ORL_OnWheel = [[ local slice = control:Run(ORL_GetPureSlice);
			if (not slice) or owner:GetEffectiveAttribute("type", "r" .. activeRingID .. "s" .. slice) ~= "ring" then return; end
			if slice ~= wheelSlice then wheelSlice, wheelBucket = slice, 0; end
			wheelBucket = wheelBucket + (...); if abs(wheelBucket) >= activeRing.bucket then wheelBucket = 0; else return; end
			local ring = owner:GetEffectiveAttribute("ring", "r" .. activeRingID .. "s" .. slice);
			if ORL_RingData[ring] then
				local rkey = ring .. "#" .. activeRingID .. "." .. slice;
				local c, s, count, step = 0, ORL_Rotation[rkey] or 0, ORL_RingData[ring].count, ...;
				repeat
					s, c = (s % count) + step, c + 1;
					table.wipe(ORL_RingChain); ORL_RingChain[activeRingID] = true;
					ORL_Rotation[rkey] = s;
				until control:Run(ORL_GetSlice, ring, s % count + 1) or c == count;
			end
		]];
		ORL_PerformSliceAction = [[ local slice = ...;
			table.wipe(ORL_RingChain);
			local btn, ring, slice, pureSlice = control:Run(ORL_GetSlice, activeRingID, slice);
			if btn then
				activeRing.fcSlice = activeRing.fastClick and activeRing.fastClick[pureSlice] and pureSlice or activeRing.fcSlice;
				control:CallMethod("NotifyState", "use", ring, slice);
			end
			if not (leftActivation and activeRing.NoClose) then control:Run(ORL_CloseActiveRing); end
			return btn or false;
		]];
		ORL_OnClick = [[ local button, down = ...;
			local b2 = "-" .. (IsAltKeyDown() and "ALT-" or "") ..  (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. button:upper();
			local isOpenHotkey = tonumber(button:match("^r(%d+)$"));
			if button == "LeftButton" and activeRing and leftActivation then button = "use"; end
			if button == "RightButton" or (activeRing and activeRing.ClickPriority and leftActivation and activeRing.bind and b2:match(activeRing.bindMatch)) then button = "close"; end
			if button == "mwup" or button == "mwdown" and down then return false, control:Run(ORL_OnWheel, button == "mwup" and 1 or -1); end
			if button == "MiddleButton" then button = "mwin"; end
			if activeRing and not down and ((button == "use") or (button == "close" and leftActivation and fastClick)) then
				local slice, isFC = control:Run(ORL_GetPureSlice);
				if button == "close" and not (isFC and slice) then return false; end
				return control:RunFor(self, ORL_PerformSliceAction, slice);
			elseif activeRing and down and button == "close"  then
				return false, control:Run(ORL_CloseActiveRing);
			elseif button == "close" or button == "use" then
				-- NOOP.
			elseif activeRing and button:match("slice(%d+)") then
				if down then return false; end
				local b = tonumber(button:match("slice(%d+)"));
				if b > 0 and b <= activeRing.count then
					return control:RunFor(self, ORL_PerformSliceAction, b);
				end
			elseif activeRing and leftActivation and button == "Button1" then
				return control:RunFor(self, ORL_OnClick, "use", down);
			elseif activeRing and activeRing.bind and b2:match(activeRing.bindMatch) then
				return control:RunFor(self, ORL_OnClick, leftActivation and "close" or "use", down);
			elseif button:match("Button%d+") then
				-- When a ring is open and waiting for left clicks, it can catch Button3/4/5
				-- The correct behavior is to handle those as if they were binding hits.
				local lvalue, lkey = 0, nil;
				for k, v in pairs(ORL_RingData) do
					if v.bind and b2:match(v.bindMatch) and #v.bind > lvalue then
						lkey, lvalue = k, #v.bind;
					end
				end
				if lkey then
					return control:RunFor(self, ORL_OnClick, "r" .. lkey, down);
				end
			elseif button == "mwin" and activeRingID and down then
				local slice = control:Run(ORL_GetPureSlice);
				local ring = slice and owner:GetEffectiveAttribute("ring", "r" .. activeRingID .. "s" .. slice);
				if slice and ORL_RingData[ring] then
					-- Tricky: a ring is already open; but we don't close it; this lets us use the original binding
					--  for the nested ring. If the current ring doesn't require its binding to be held down, we have to use LMB activation.
					return control:RunFor(self, ORL_OpenRing, ring, leftActivation, true);
				end
			elseif isOpenHotkey and (activeRingID == nil or activeRingID ~= isOpenHotkey) and down then
				if activeRingID then
					-- When the capturing frame handles a binding down event (self == owner), the regular
					--  binding UP will not fire. We tell CAR not to hide the capturing frame, and use its OnClick.
					control:Run(ORL_CloseActiveRing, self == owner);
				end
				return control:RunFor(self, ORL_OpenRing, isOpenHotkey);
			end
		]];
		ORL_OpenClick = [[ local button = ...;
			local rid, cid = ORL_RingAlias[button], activeRingID;
			if not rid then
				return print("|cffff0000[ORL] Unknown ring alias: "..button);
			end
			if cid then	control:Run(ORL_CloseActiveRing); end
			if cid == rid then return; end
			return control:RunFor(self, ORL_OpenRing, rid, true);
		]];
	]=]);
	OR_SecCore:WrapScript(OR_SecCore, "OnMouseWheel", "return control:Run(ORL_OnWheel, offset)");
	OR_SecCore:WrapScript(OR_SecCore, "OnClick", "return control:Run(ORL_OnClick, button, down)");
	OR_SecCore:WrapScript(OR_CancelProxy, "OnClick", "return control:Run(ORL_OnClick, button, down)");
	OR_SecCore:WrapScript(OR_OpenProxy, "OnClick", "control:Run(ORL_OpenClick, button)");
	OR_SecEnv = GetManagedEnvironment(OR_SecCore);
	OR_SecData = OR_SecEnv.ORL_RingData;
end
do -- Binding management
	OR_SecCore:Execute("bindOwners, bindRingKeys, bindAlias = newtable(), newtable(), newtable(); bindAlias['SEMICOLON'], bindAlias.OPEN, bindAlias.CLOSE = ';', '[', ']'");
	OR_SecCore:SetAttribute("_onattributechanged", [=[
		local rkey, id = name:match("state%-(r(%d+))");
		if not id then return; end
		local proxy, data = self:GetFrameRef("proxy" .. id), ORL_RingData[tonumber(id)];
		if not (proxy and data) then return; end
		local newbind, link = value ~= "" and value or nil, bindRingKeys[rkey];
		if newbind then newbind = rtgsub(newbind, "[^-]+$", bindAlias); end
		if link and link.active then
			local parent, child = link.parent, link.child;
			if parent then parent.child = child; else bindOwners[link.bind] = child; end
			if child then child.parent = parent; end
			if child and not parent then
				self:SetBindingClick(false, child.bind, child.proxy, child.rkey);
				child.data.bind, child.data.bindMatch = child.bind, child.bind:gsub("[%-%[%]%*%+%?%.]", "%%%1") .. "$";
			elseif not parent then
				self:ClearBinding(link.bind);
			end
			link.active = false;
		end
		if newbind then
			local child, link = bindOwners[newbind], link or newtable();
			self:SetBindingClick(false, newbind, proxy, rkey);
			link.active, link.child, link.parent = true, child, nil;
			link.bind, link.proxy, link.rkey, link.data = newbind, proxy, rkey, data;
			if child then child.parent, child.data.bind, child.data.bindMatch = link, nil, nil; end
			bindOwners[newbind], bindRingKeys[rkey] = link, link;
		end
		data.bind, data.bindMatch = newbind, newbind and newbind:gsub("[%-%[%]%*%+%?%.]", "%%%1") .. "$";
	]=]);
end
local OR_CallPreClicks; do
	local called = {};
	function OR_CallPreClicks(ring, outer)
		if called[ring] then return; else called[ring] = true; end
		if type(ring.preClick) == "function" then
			EC_pcall("OPie", OR_Rings[ring.ringID] .. ".preClick", ring.preClick, ring.ringID, outer);
		end
		for i,slice in ipairs(ring) do
			if slice[1] == "ring" and OR_Rings[slice[2]] then
				OR_CallPreClicks(OR_Rings[slice[2]], false);
			end
		end
		if outer then table.wipe(called); end
	end
end
local function tostringb(b)
	return b and "true" or "false";
end
local bindingEncodeChars = {["["]="OPEN", ["]"]="CLOSE", [";"]="SEMICOLON"}
local function OR_CompareSlices(a, b)
	if a[1] ~= b[1] or a[2] ~= b[2] or a[3] ~= b[3] then return false; end
	local score = 0;
	for k,v in pairs(a) do score = score + (b[k] == v and 1 or -1); end
	for k,v in pairs(b) do score = score + (a[k] == v and 1 or -1); end
	return score;
end
local function OR_SyncRing(name, props, forceSliceSync)
	local ringID = OR_Rings[name] and OR_Rings[name].ringID or (#OR_Rings+1);
	if InCombatLockdown() or OR_SecEnv.activeRingID == ringID or not unlocked then
		OR_PendingUpdates[name], OR_Rings[name], OR_Rings[ringID] = props, OR_Rings[name] or {ringID=ringID}, name;
		return OR_Rings[name].ringID, false, "locked";
	else
		OR_PendingUpdates[name] = nil;
	end

	local oldSelectedSlice = OR_Rings[name] and OR_Rings[name][OR_SecData[ringID] and OR_SecData[ringID].fastClick and OR_SecData[ringID].fastClick[OR_SecData[ringID].fcSlice]];
	local isSimpleUpdate, postExec = OR_Rings[name] == props, ("ORL_RingAlias[%q] = %d;\n"):format(name, ringID);
	OR_Rings[name] = isSimpleUpdate and OR_Rings[name] or copy(props, nil, OR_Rings[name]);
	OR_Rings[name].ringID, OR_Rings[ringID], props = ringID, name, setmetatable(OR_Rings[name], propsMeta);
	if forceSliceSync or not isSimpleUpdate then -- slices may have been altered
		local fcOut, fcScore, fcSlice, fcUsed = "", -math.huge;
		for i=1,#props do
			local sliceType, actionID, target, mask = props[i][1], props[i][2], props[i][3], "*%s-r" .. ringID .. "s" .. i;
			if (sliceType == "macro" and (type(actionID) == "number" or type(actionID) == "string")) or
				 (sliceType == "macrotext" and type(actionID) == "string") then
				SetAttributes(OR_SecCore, mask:format("type"),"macro", mask:format(sliceType),actionID);
			elseif (sliceType == "item" or sliceType == "spell") and (type(actionID) == "number" or type(actionID) == "string") then
				SetAttributes(OR_SecCore, mask:format("type"),sliceType, mask:format(sliceType),actionID, mask:format("target"),target or "player");
			elseif sliceType == "func" and type(actionID) == "function" then
				if type(target) == "table" then props[i][3] = copy(props[i][3]); end
				OR_SecCore:SetAttribute(mask:format("type"), nil); -- Fired from NotifyState handler
			elseif sliceType == "ring" and type(actionID) == "string" then
				if not OR_Rings[actionID] then
					OR_SRSRings[actionID] = OR_SRSRings[actionID] or {};
					table.insert(OR_SRSRings[actionID], name); -- Subscribe to be notified when the ghost becomes available
				elseif props[i].rotation ~= 0 and type(props[i].rotation) == "number" then
					postExec = postExec .. ([[local k="%d#%d.%d"; ORL_Rotation[k] = ORL_Rotation[k] or %d;]]):format(OR_Rings[actionID].ringID, ringID, i, props[i].rotation);
				end
				SetAttributes(OR_SecCore, mask:format("type"),"ring", mask:format("ring"),OR_Rings[actionID] and OR_Rings[actionID].ringID or 0);
			else
				assert(false, "Slice %d of ring %q is invalid (%q, %q)", 2, i, name, tostring(sliceType), tostring(actionID));
			end
			fcOut, fcUsed, fcSlice = fcOut .. (i == 1 and "" or ", ") .. (props[i].fastClick and i or "nil"), fcUsed or props[i].fastClick, fcSlice or (props[i].fastClick and i);
			if oldSelectedSlice and props[i].fastClick then
				local score = OR_CompareSlices(oldSelectedSlice, props[i]);
				if score and score > fcScore then
					fcSlice, fcScore = i, score;
				end
			end
		end
		if OR_GetRingOption(name, "CenterAction") and fcUsed then
			if fcScore == -math.huge and tonumber(props.fastClickSlice) then
				if props[tonumber(props.fastClickSlice)] and props[tonumber(props.fastClickSlice)].fastClick then
					fcSlice = tonumber(props.fastClickSlice);
				end
			end
			postExec = postExec .. ("t.fastClick = newtable(%s); t.fcSlice = %s;"):format(fcOut, tostring(tonumber(props.fastClickSliceForce) or fcSlice or "nil"));
			props.fastClickSliceForce = nil;
		end
	end

	local sliceBindString = "false";
	if OR_GetRingOption(name, "SliceBinding")	then
		sliceBindString = "";
		local idx, bound = 1, false;
		for s in OR_GetRingOption(name, "SliceBindingString"):gmatch("%S+") do
			local psb = type(props[idx] and props[idx].psbind) == "string" and props[idx].psbind or s;
			local v, u = ("%q"):format(psb), psb:upper();
			if u:match("BUTTON[123]$") or u:match("ESCAPE") then v = "false"; end
			sliceBindString, idx, bound = sliceBindString .. (sliceBindString == "" and "newtable(" or ", ") .. v, idx + 1, bound or (v ~= "false");
		end
		for i=idx,#props do
			local psb = type(props[i].psbind) == "string" and props[i].psbind;
			local v, u = psb and ("%q"):format(psb) or "false", psb and psb:upper() or "";
			if u:match("BUTTON[123]$") or u:match("ESCAPE") then v = "false"; end
			sliceBindString, idx, bound = sliceBindString .. (sliceBindString == "" and "newtable(" or ", ") .. v, idx + 1, bound or (v ~= "false");
		end
		if bound then
			sliceBindString = sliceBindString .. ")";
		else
			sliceBindString = "false";
		end
	end

	OR_SecCore:Execute(("local id = %d; t = ORL_RingData[id] or newtable(); ORL_RingData[id] = t;"):format(ringID));
	OR_SecCore:Execute(("t.ofs, t.ofsx, t.ofsy, t.fastClick = '%s', %d, %d;"):format(OR_GetRingOption(name, "RingAtMouse") and "$cursor" or "$screen", OR_GetRingOption(name, "IndicationOffsetX"), -OR_GetRingOption(name, "IndicationOffsetY")));
	OR_SecCore:Execute(("t.ClickActivation, t.ClickPriority, t.scale, t.bucket = %s, %s, %f, %d;"):format(tostringb(OR_GetRingOption(name, "ClickActivation")), tostringb(OR_GetRingOption(name, "ClickPriority")), math.max(0.1, (OR_GetRingOption(name, "RingScale"))), (OR_GetRingOption(name, "MouseBucket"))));
	OR_SecCore:Execute(("t.count, t.ofsRad, t.NoClose, t.SliceBinding = %d, %f, %s, %s;"):format(#props, props.offset, tostringb(OR_GetRingOption(name, "NoClose")), sliceBindString));
	OR_SecCore:Execute(postExec .. "t = nil;");

	local hotkey, proxy = configInstance.Bindings[name], OR_SecCore:GetAttribute("frameref-proxy".. ringID) or OR_SpawnProxy(ringID);
	OR_SpawnProxy(ringID);
	if hotkey == nil then
		hotkey = props.hotkey;
		if type(hotkey) == "string" and not isConditionalBinding[hotkey] and GetBindingAction(hotkey) ~= "" then
			hotkey = nil;
		else
			for k,v in pairs(configInstance.Bindings) do
				if v == hotkey and OR_Rings[k] then hotkey = nil; break; end
			end
		end
	end
	if hotkey and not isConditionalBinding[hotkey] then
		hotkey = hotkey:gsub("[^-]+$", bindingEncodeChars);
	end
	RegisterStateDriver(OR_SecCore, "r" .. ringID, (hotkey or "") .. ";");

	local SRSqueue = OR_SRSRings[name];
	if SRSqueue then
		-- Slice ring update queue needs to be notified that this ring now exists
		OR_SRSRings[name] = nil;
		for k,v in pairs(SRSqueue) do
			OR_SyncRing(v, OR_PendingUpdates[v] or OR_Rings[v], true);
		end
	end

	return ringID;
end
local OR_FindFinalSlice; do
	local seen, secRotation, secData = {}, OR_SecEnv.ORL_Rotation, OR_SecData;
	function OR_FindFinalSlice(ring, id, from, map)
		if from ~= nil then seen[from] = map; end
		local slice = OR_Rings[ring] and OR_Rings[OR_Rings[ring]][id];
		if type(id) ~= "number" or not slice then table.wipe(seen); return; end
		local activeRingID = OR_SecEnv.activeRingID;
		if slice[1] == "ring" then
			local subRing, rotation = OR_Rings[slice[2]];
			local skey = subRing and (subRing.ringID .. "#" .. ring .. "." .. id);
			if subRing and seen[skey] ~= true then
				rotation, seen[skey] = seen[skey] or secRotation[skey] or 0, true;
				return OR_FindFinalSlice(subRing.ringID, (rotation % #subRing) + 1);
			else
				table.wipe(seen);
				return false;
			end
		end
		table.wipe(seen);
		return slice;
	end
end
function OR_SecCore:NotifyState(state, ring, slice, ...)
	local props = OR_Rings[OR_Rings[ring]];
	if state == "use" then
		if slice and props[slice] and props[slice][1] == "func" then
			EC_pcall("OPie", "R" .. ring .. "S" .. slice .. ".use", props[slice][2], ring, props[slice][3]);
		end
	elseif state == "pre" then
		OR_CallPreClicks(props, true);
	elseif state == "open" then
		OR_ActiveProps = props;
		if ORI_Show then EC_pcall("OPie", "ORI_Show", ORI_Show, ring, slice or 0, ...); end
	elseif state == "close" then
		if ORI_Hide then EC_pcall("OPie", "ORI_Hide", ORI_Hide); end
		OR_ActiveProps = nil;
		local pending = OR_PendingUpdates[OR_Rings[props.ringID]];
		if not InCombatLockdown() and pending then
			OR_SyncRing(OR_Rings[props.ringID], pending);
		end
	end
end

-- Responding to WoW Events
local function OR_NotifyPVars(event, filter, perProfile)
	for k, v in pairs(PersistentStorageInfo) do
		if type(v.f) == "function" and v.t == (filter or v.t) and (perProfile == nil or perProfile == v.perProfile) then
			EC_pcall("OPie", "NotifyPVar:" .. k, v.f, event, k, v.t);
		end
	end
end
local function OR_SyncProps()
	if not InCombatLockdown() then
		for k, props in pairs(OR_PendingUpdates) do
			OR_SyncRing(k, props);
		end
	end
end
local function OR_ForceResync(filter)
	for k,v in ipairs(OR_Rings) do
		OR_PendingUpdates[v] = OR_PendingUpdates[v] or ((filter == nil or filter == v) and OR_Rings[v]) or nil;
	end
	OR_SyncProps();
end
local function OR_CheckBindings()
	if InCombatLockdown() then return; end
	local updated = false;
	for k, v in pairs(OR_Rings) do
		local key = v.hotkey;
		if configInstance.Bindings[k] == nil and type(key) == "string" and not isConditionalBinding[key] and ((GetBindingAction(key) == "") == (OR_SecEnv.bindOwners[key] == nil)) then
			OR_PendingUpdates[k], updated = v, true;
		end
	end
	if updated then OR_SyncProps(); end
end
local function OR_SwitchCombatState(event)
	if event == "PLAYER_REGEN_ENABLED" then
		OR_CheckBindings();	OR_SyncProps();
	end
end
local function OR_UnserializeConfigInstance(profile)
	activeProfile = configRoot.ProfileStorage[profile] and profile or "default";
	local configInstance = configRoot.ProfileStorage[activeProfile];
	if type(configInstance.RingOptions) ~= "table" then configInstance.RingOptions = {}; end
	if type(configInstance.Bindings) ~= "table" then configInstance.Bindings = {}; end
	for k,v in pairs(PersistentStorageInfo) do if v.perProfile then	copy(configInstance[k], nil, v.t); end end
	return setmetatable(configInstance, optionsMeta);
end
local function OR_NotifyOptions()
	local notified = {};
	for option, func in pairs(optionValidators) do
		if type(func) == "function" and not notified[func] then
			notified[func] = EC_pcall("OPie", "optionNotifier: " .. option, func);
		end
	end
end
local function OR_InitConfigState()
	if type(OneRing_Config) == "table" then
		for k, v in pairs(OneRing_Config) do
			configRoot[k] = v;
		end
	end

	-- And a few special tables.
	for t in ("CharProfiles;PersistentStorage;ProfileStorage"):gmatch("[^;]+") do
		if type(configRoot[t]) ~= "table" then configRoot[t] = {}; end
	end
	if type(configRoot.ProfileStorage.default) ~= "table" then
		configRoot.ProfileStorage.default = {Bindings=configRoot.Bindings or {}, RingOptions=configRoot.RingOptions or {}, LBFConfig=configRoot.LBFConfig};
	end

	-- Load the profile
	local profile = configRoot.CharProfiles[getSpecCharIdent()] or configRoot.CharProfiles[OneRing.xlu.charId];
	configInstance = OR_UnserializeConfigInstance(profile);

	-- Load variables into relevant tables, unlock core and fire notifications.
	for k, v in pairs(configRoot.PersistentStorage) do
		if PersistentStorageInfo[k] and not PersistentStorageInfo[k].perProfile then
			copy(v, nil, PersistentStorageInfo[k].t);
		end
	end
	OneRing_Config, unlocked = nil, true;
	OR_NotifyPVars("LOADED");
	OR_NotifyOptions();
end
local function OR_LibState(event, addon)
	if event == "ADDON_LOADED" and addon == OR_AddonName then
		OR_InitConfigState();
	elseif not unlocked then
		return;
	end
	if event == "PLAYER_LOGIN" then
		updateSpellCache();
		OR_NotifyPVars("LOGIN");
		OR_SyncProps();
		-- Blizzard tends to load bindings between A_L and P_L, so let's reaffirm our overrides.
		OR_SecCore:Execute("for k, v in pairs(bindOwners) do self:SetBindingClick(false, k, v.proxy, v.rkey);	end");
	elseif event == "PLAYER_LOGOUT" then
		OneRing_Config = configRoot;
		OR_NotifyPVars("LOGOUT");
		configInstance.LBFConfig = LBFGroup and {SkinID=LBFGroup.SkinID, Gloss=LBFGroup.Gloss, Backdrop=LBFGroup.Backdrop, Colors=LBFGroup.Colors} or configInstance.LBFConfig or nil;
		for k, v in pairs(configInstance) do
			if v == defaultConfig[k] then
				configInstance[k] = nil;
			end
		end
		for k, v in pairs(PersistentStorageInfo) do
			local store = v.perProfile and configInstance or configRoot.PersistentStorage;
			store[k] = next(v.t) ~= nil and v.t or nil;
		end
		for k,v in pairs(configRoot.ProfileStorage) do
			if v.RingOptions and next(v.RingOptions) == nil then v.RingOptions = nil; end
			if v.Bindings and next(v.Bindings) == nil then v.Bindings = nil; end
		end
	end
	return "remove";
end
local function OR_SwitchProfile(ident)
	OR_NotifyPVars("SAVE", nil, true);
	for k, v in pairs(PersistentStorageInfo) do
		if v.perProfile then
			configInstance[k] = next(v.t) and copy(v.t);
		end
	end
	configInstance = OR_UnserializeConfigInstance(ident);
	OR_NotifyPVars("UPDATE", nil, true);
	OR_NotifyOptions();
	OR_ForceResync();
end
local function OR_TalentProfileSwitch(event, newGroup, oldGroup)
	local newProfile = configRoot.CharProfiles[getSpecCharIdent()];
	if configRoot.ProfileStorage[newProfile] and newProfile ~= activeProfile then
		OR_SwitchProfile(newProfile);
	end
end

-- Public API
function OneRing:CreateRing(name, props)
	assert(type(name) == "string" and type(props) == "table", "Syntax: header, button = OneRing:CreateRing(\"name\", propsTable)", 2);
	assert(OR_Rings[name] == nil and OR_PendingUpdates[name] == nil, "Ring name %q is already created.", 2, name);
	assert(name:match("^%a[%a%d]*$"), "Ring name (%q) must be alphanumeric, begin with a letter.", 2, name);
	local id, a1, a2 = OR_SyncRing(name, props);
	EC_Raise("ORL.CREATE_RING", name, id);
	return id, a1, a2;
end
function OneRing:SetRingData(id, props)
	assert(type(id) == "number" and type(props) == "table", "Syntax: OneRing:SetRingData(index, propsTable);", 2);
	local key = assert(OR_Rings[id], "Ring index out of range.", 2);
	return OR_SyncRing(key, props);
end
function OneRing:GetNumRings()
	return #OR_Rings;
end
function OneRing:GetRingData(id)
	assert(type(id) == "number", "Syntax: propsTable = OneRing:GetRingData(index);", 2);
	local key = assert(OR_Rings[id], "Ring index out of bounds", 2);
	local ret = copy(OR_PendingUpdates[key] or OR_Rings[key]);
	ret.codename = key;
	return ret;
end
function OneRing:GetRingInfo(id)
	assert(type(id) == "number" or type(id) == "string", "Syntax: name, key, numSlices, id, macro, internal, fcid = OneRing:GetRingInfo(index or \"name\");", 2);
	local key = type(id) == "string" and OR_Rings[id] and id or OR_Rings[id];
	if not key then return; end
	local ret = OR_PendingUpdates[key] or OR_Rings[key];
	return ret.name, key, #ret, ret.ringID, "/click "..OR_OpenProxy:GetName().." "..key, ret.internal, OR_SecData[ret.ringID] and OR_SecData[ret.ringID].fcSlice;
end
function OneRing:GetOption(option, ringID)
	assert(type(option) == "string" and (ringID == nil or type(ringID) == "number"), "Syntax: value = OneRing:GetOption(\"option\"[, ringID]);", 2);
	if defaultConfig[option] == nil then return; end
	return OR_GetRingOption(assert(ringID == nil and "" or OR_Rings[ringID], "Ring index out of bounds", 2), option);
end
function OneRing:SetOption(option, ...)
	local id, value = ...;
	if select("#", ...) == 1 then id, value = nil, ...; end
	assert(type(option) == "string" and (id == nil or type(id) == "number"), "Syntax: OneRing:SetOption(\"option\"[, id], value or nil);", 2);
	assert(defaultConfig[option] ~= nil, "Option %q is undefined.", 2, option);
	assert(value == nil or type(defaultConfig[option]) == type(value), "Type mismatch: %q expected to be a %s.", 2, option, type(defaultConfig[option]));
	local rkey = assert(id == nil or OR_Rings[id], "Ring index out of bounds.", 2);
	assert(not optionValidators[option] or optionValidators[option](option, value, id) ~= false, "Value rejected by option validator.", 2);
	local t, tkey = id and configInstance.RingOptions or configInstance, id and (rkey .. "#" .. option) or option;
	t[tkey] = value;
	if optionValidators[option] == nil then
		OR_ForceResync(OR_Rings[id]);
	end
end
function OneRing:ClearRingOptions(id)
	assert(type(id) == "number", "Syntax: OneRing:ClearRingOptions(id);", 2);
	local key = assert(OR_Rings[id], "Ring index out of bounds.", 2);
	for k, v in pairs(defaultConfig) do
		configInstance.RingOptions[key .. "#" .. k] = nil;
	end
	OR_ForceResync(key);
end
function OneRing:ResetOptions(includePerRing)
	assert(type(includePerRing) == "boolean" or includePerRing == nil, "Syntax: OneRing:ResetOptions([includePerRing])", 2);
	for k in pairs(defaultConfig) do
		configInstance[k] = nil;
	end
	if includePerRing then
		configInstance.RingOptions = {};
	end
	OR_ForceResync();
end
function OneRing:SetRingBinding(id, bind)
	assert(type(id) == "number" and (type(bind) == "string" or bind == false or bind == nil), "Syntax: OneRing:SetRingBinding(id, \"binding\" or false or nil);", 2);
	local key = assert(OR_Rings[id], "Ring index out of range", 2);
	if bind == configInstance.Bindings[key] then return; end
	local obind = OneRing:GetRingBinding(id);
	for i=1,#OR_Rings do
		local ikey, cbind, over = OR_Rings[i], OneRing:GetRingBinding(i);
		if cbind == bind or cbind == obind then
			OR_PendingUpdates[ikey] = OR_Rings[ikey];
			if over and cbind == bind and cbind then
				configInstance.Bindings[ikey] = nil; -- Remove old binding
			end
		end
	end
	configInstance.Bindings[key], OR_PendingUpdates[key] = bind, OR_Rings[key];
	if not InCombatLockdown() then OR_SyncProps(); end
end
function OneRing:GetRingBinding(id)
	assert(type(id) == "number", "Syntax: binding, override, active, cndbinding = OneRing:GetRingBinding(id);", 2);
	local rkey = assert(OR_Rings[id], "Ring index out of range", 2);
	local key, over = configInstance.Bindings[rkey], true;
	if key == nil then key, over = OR_Rings[rkey].hotkey, false; end
	local link, key2 = OR_SecEnv.bindRingKeys["r" .. id], key;
	if isConditionalBinding[key] then key2 = link and link.active and link.bind; end
	return key, over, link and link.active and not link.parent, key2;
end
function OneRing:GetVersion()
	return GetAddOnMetadata(OR_AddonName, "X-Version-Name-Wrath"), versionMajor, versionRev;
end
function OneRing:RegisterPVar(name, into, notifier, perProfile)
	assert(type(name) == "string" and (into == nil or type(into) == "table") and (notifier == nil or type(notifier) == "function"), "Syntax: OneRing:RegisterPVar(\"name\"[, storageTable[, notifierFunc[, perProfile]]]", 2);
	assert(PersistentStorageInfo[name] == nil and defaultConfig[name] == nil, "PVar %q already declared.", 2, name);
	local store, into = ((perProfile == true) and configInstance or configRoot.PersistentStorage), into or {};
	PersistentStorageInfo[name] = {t=into, f=notifier, perProfile=perProfile == true};
	if unlocked then
		if store and store[name] then copy(store[name], nil, into); end
		OR_NotifyPVars("LOADED", into);
	end
	return into;
end
function OneRing:SwitchProfile(ident, inherit)
	assert(type(ident) == "string" and (inherit == nil or type(inherit) == "boolean"), "Syntax: OneRing:SwitchProfile(\"ident\"[, deriveFromCurrent])", 2);
	if not configRoot.ProfileStorage[ident] then
		configRoot.ProfileStorage[ident] = inherit and copy(configInstance) or {RingOptions={},Bindings={}};
	end
	OR_SwitchProfile(ident);
	configRoot.CharProfiles[getSpecCharIdent()] = activeProfile;
end
function OneRing:DeleteProfile(ident)
	assert(type(ident) == "string", "Syntax: OneRing:DeleteProfile(\"ident\")", 2);
	local oldP = assert(configRoot.ProfileStorage[ident], "Profile %q does not exist.", 2, ident);
	if configRoot.CharProfiles then
		for k,v in pairs(configRoot.CharProfiles) do
			if v == ident then configRoot.CharProfiles[k] = nil; end
		end
	end
	configRoot.ProfileStorage[ident] = nil;
	if configInstance == oldP then self:SwitchProfile("default"); end
end
function OneRing:GetCurrentProfile()
	return activeProfile;
end
function OneRing:Profiles(prev)
	if not unlocked then return; end
	local ident, data = next(configRoot.ProfileStorage, prev);
	return ident, data == configInstance;
end
function OneRing:ProfileExists(ident)
	return configRoot.ProfileStorage[ident] ~= nil;
end
function OneRing:GetOpenRing()
	if not OR_ActiveProps then return; end
	return OR_ActiveProps.ringID, #OR_ActiveProps, OR_ActiveProps.offset;
end
function OneRing:GetOpenRingSlice(id)
	local slice = OR_ActiveProps and OR_ActiveProps[id];
	if type(id) ~= "number" or not slice then return false; end
	local fslice, sbt = OR_FindFinalSlice(OR_ActiveProps.ringID, id) or slice, OR_SecEnv.activeRing.SliceBinding;
	return true, fslice.r, fslice.g, fslice.b, slice[1] == "ring" and OR_Rings[slice[2]] and #OR_Rings[slice[2]] or false, sbt and sbt[id];
end
function OneRing:GetOpenRingSliceAction(id)
	if OR_ActiveProps == nil or id < 1 or id > #OR_ActiveProps then return end
	local s = OR_FindFinalSlice(OR_ActiveProps.ringID, id);
	return OR_GetActionInfoEntry(s, OR_SecEnv.leftActivation and "" or OR_SecEnv.activeRing.bind);
end
function OneRing:GetOpenRingSliceGhost(id, id2)
	local slice = OR_ActiveProps and OR_ActiveProps[id];
	if type(id) ~= "number" or not slice then return false; end
	local ghostRingProps = OR_Rings[slice[2]];
	if not ghostRingProps then return false; end
	local rotRing, actRing = OR_Rings[slice[2]].ringID, OR_ActiveProps.ringID;
	local rotation = OR_SecEnv.ORL_Rotation[rotRing .. "#" .. actRing .. "." .. id] or 0;
	local ghostIndex = ((id2 + rotation - 1) % #ghostRingProps) + 1;
	local s = OR_FindFinalSlice(rotRing, ghostIndex, rotRing .. "#" .. actRing .. "." .. id, ghostIndex-1);
	return OR_GetActionInfoEntry(s, OR_SecEnv.leftActivation and "" or OR_SecEnv.activeRing.bind);
end
function OneRing:GetOpenRingSliceColor(id, id2)
	local slice = OR_ActiveProps and OR_ActiveProps[id];
	if type(id) ~= "number" or not slice then return false; end
	local ghostRingProps = OR_Rings[slice[2]];
	if not ghostRingProps then return false; end
	local rotRing, actRing = OR_Rings[slice[2]].ringID, OR_ActiveProps.ringID;
	local rotation = OR_SecEnv.ORL_Rotation[rotRing .. "#" .. actRing .. "." .. id] or 0;
	local ghostIndex = ((id2 + rotation - 1) % #ghostRingProps) + 1;
	local s = OR_FindFinalSlice(rotRing, ghostIndex, rotRing .. "#" .. actRing .. "." .. id, ghostIndex-1);
	if not s then return; end
	return s.r, s.g, s.b;
end
function OneRing:GetOpenRingOptions(t)
	local t, rname = type(t) == "table" and t or {}, OR_Rings[OR_SecEnv.activeRingID];
	if not rname then return; end
	for k,v in pairs(defaultConfig) do
		t[k] = OR_GetRingOption(rname, k);
	end
	return t;
end
function OneRing:RegisterAnimator(show, hide)
	assert(type(show) == "function" and type(hide) == "function", "Syntax: OneRing:RegisterAnimator(showFunc, hideFunc);", 2);
	ORI_Show, ORI_Hide = show, hide;
end
function OneRing:RegisterOption(name, default, validator)
	assert(type(name) == "string" and default ~= nil and (validator == nil or type(validator) == "function"), "Syntax: OneRing:RegisterOption(\"name\", defaultValue[, validatorFunc])", 2);
	assert(defaultConfig[name] == nil and PersistentStorageInfo[name] == nil, "Option %q has a conflicting name", 2, name);
	defaultConfig[name], optionValidators[name] = default, validator or false;
end

EC_Register("ADDON_LOADED", "ORL.State", OR_LibState);
EC_Register("PLAYER_LOGIN", "ORL.State", OR_LibState);
EC_Register("PLAYER_LOGOUT", "ORL.State", OR_LibState);
EC_Register("PLAYER_REGEN_ENABLED", "ORL.OutOfCombat", OR_SwitchCombatState);
EC_Register("PLAYER_REGEN_DISABLED", "ORL.IntoCombat", OR_SwitchCombatState);
EC_Register("UPDATE_BINDINGS", "ORL.Bindings", OR_CheckBindings);
EC_Register("COMPANION_LEARNED", "ORL.Companions", updateSpellCache);
EC_Register("COMPANION_UPDATE", "ORL.Companions", updateSpellCache);
EC_Register("ACTIVE_TALENT_GROUP_CHANGED", "ORL.ProfileSwap", OR_TalentProfileSwitch);

_G.OneRingLib = OneRing;