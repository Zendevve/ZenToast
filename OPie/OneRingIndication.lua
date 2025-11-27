local max, min, abs, sin, cos = math.max, math.min, math.abs, sin, cos; -- Note: those trig functions want degrees
local OR_AddonName, ORI_ConfigCache, LBF, LBFGroup, LBFConfig = "OPie", {}, false, false, {};
local ORI_OptionDefaults = {ShowCenterIcon=false, ShowCenterCaption=false, ShowCooldowns=false, MultiIndication=true, UseGameTooltip=true, ShowKeys=true,
	MIDisjoint=false, MIScale=true, MISpinOnHide=true, GhostMIRings=true, UseBF=false, ColorBF = true, GhostOldDirection=false,
	XTPointerSpeed=0, XTScaleSpeed=0, XTZoomTime=0.3};

local function SetDimensions(frame, w, h)
	frame:SetWidth(w); frame:SetHeight(h or w);
end

-- Create the indication UI
local OR_IndicationPos = CreateFrame("Frame", nil, UIParent);
SetDimensions(OR_IndicationPos, 1); OR_IndicationPos:Hide(); OR_IndicationPos:SetPoint("CENTER");
local OR_IndicationFrame, ORI_Circle, ORI_Pointer, ORI_Glow = CreateFrame("Frame", "OneRingIndicator", UIParent);
SetDimensions(OR_IndicationFrame, 128); OR_IndicationFrame:SetFrameStrata("FULLSCREEN"); OR_IndicationFrame:SetPoint("CENTER", OR_IndicationPos);
do -- Spawn indication textures
	local basepath = "Interface\\AddOns\\" .. OR_AddonName;
	ORI_Pointer = OR_IndicationFrame:CreateTexture(nil, "ARTWORK");
	SetDimensions(ORI_Pointer, 192); ORI_Pointer:SetPoint("CENTER");
	ORI_Pointer:SetTexture(basepath .. "\\gfx\\pointer.tga");

	local quad, quadPoints = {}, {"BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT", "TOPLEFT"};
	for i=1,4 do
		local f = CreateFrame("Frame", nil, OR_IndicationFrame);
		SetDimensions(f, 32);	f:SetPoint(quadPoints[i], OR_IndicationFrame, "CENTER");
		local g = f:CreateAnimationGroup(); g:SetLooping("REPEAT");
		local a = g:CreateAnimation("Rotation"); a:SetDuration(4); a:SetDegrees(-360);
		a:SetOrigin(quadPoints[i], 0, 0);
		g:Play();
		quad[i] = f;
	end
	local function quadFunc(f)
		return function (self, ...)
			for i=1,4 do
				self[i][f](self[i], ...);
			end
		end
	end
	local quadTemplate = {SetVertexColor=quadFunc("SetVertexColor"), Hide=quadFunc("Hide"), Show=quadFunc("Show"), SetAlpha=quadFunc("SetAlpha")};
	local function makequadtex(layer, size, path)
		local group = OneRingLib.xlu.copy(quadTemplate);
		for i=1,4 do
			local tex, DOWN, LEFT = quad[i]:CreateTexture(nil, layer), i > 2, i > 1 and i < 4;
			SetDimensions(tex, size/2);
			tex:SetPoint(quadPoints[i]);
			tex:SetTexture(basepath .. path);
			tex:SetTexCoord(LEFT and 0 or 1, LEFT and 1 or 0, DOWN and 1 or 0, DOWN and 0 or 1);
			group[i] = tex;
		end
		return group;
	end
	ORI_Circle = makequadtex("ARTWORK", 64, "\\gfx\\circle.tga");
	ORI_Glow = makequadtex("BACKGROUND", 128, "\\gfx\\glow.tga");
end

local OR_SpellCaption = OR_IndicationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	OR_SpellCaption:SetPoint("TOP", OR_IndicationFrame, "CENTER", 0, -20-32); OR_SpellCaption:SetJustifyH("CENTER");
local OR_SpellCD = OR_IndicationFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge");
	OR_SpellCD:SetJustifyH("CENTER"); OR_SpellCD:SetJustifyV("CENTER"); OR_SpellCD:SetPoint("CENTER");
local OR_CenterIndication = CreateFrame("CheckButton", "ORI_CenterContainer", OR_IndicationFrame);
	SetDimensions(OR_CenterIndication, 28); OR_CenterIndication:SetPoint("CENTER"); OR_CenterIndication:EnableMouse(false);
	OR_CenterIndication:SetCheckedTexture(""); OR_CenterIndication:SetHighlightTexture("");
	local OR_SpellIcon = OR_CenterIndication:CreateTexture(nil, "ARTWORK");
	OR_SpellIcon:SetAllPoints(); OR_SpellIcon:SetAlpha(0.8);
	local OR_SpellCount = OR_CenterIndication:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge");
	OR_SpellCount:SetPoint("BOTTOMRIGHT", -1, 1);
local ORMI_Parent = CreateFrame("Frame", "ORI_MIParent", OR_IndicationFrame);
	SetDimensions(ORMI_Parent, 256); ORMI_Parent:SetPoint("CENTER");

local function memoize(func)
	return setmetatable({}, {__index=function(t,k) return rawset(t,k, func(k))[k]; end});
end
local function ORI_FinishSplash(self)
	ORI_FinishSplash = nil;
	LBF = LibStub and LibStub("LibButtonFacade",true);
	if LBF and OneRingLib:GetOption("UseBF") then
		LBFGroup = LBF:Group(OR_AddonName);
		LBFGroup:AddButton(OR_CenterIndication, {Icon=OR_SpellIcon, Count=OR_SpellCount});
		if type(LBFConfig) == "table" then
			LBFGroup.Colors = LBFConfig.Colors or {};
			LBFGroup:Skin(LBFConfig.SkinID, LBFConfig.Gloss, LBFConfig.Backdrop);
		end
	end
end
local function ORMI_SetAngle(self, angle, radius)
	self:ClearAllPoints();
	self:SetPoint("CENTER", radius*cos(90+angle), radius*sin(90+angle));
end
local function ORMI_SetScaleSmoothly(self, scale)
	local old, limit = self:GetScale(), 2^(ORI_ConfigCache.XTScaleSpeed)/GetFramerate();
	self:SetScale(old + min(limit, max(-limit, scale-old)));
end
local function ORMI_SetVertexTint(self)
	local faded = self:IsEnabled() == 0;
	if not LBFGroup then
		self.edge:SetVertexColor(unpack(self.vc, faded and 4 or 1, faded and 6 or 3));
	elseif ORI_ConfigCache.ColorBF then
		pcall(LBF.SetNormalVertexColor, LBF, self, unpack(self.vc, faded and 4 or 1, faded and 6 or 3));
	else
		pcall(LBF.SetNormalVertexColor, LBF, self, 1,1,1);
	end
end
local function ORMI_SetPredominantColor(self, r, g, b)
	r, g, b = r or 0.80, g or 0.80, b or 0.80;
	local t = (0.3 * r + 0.59 * g + 0.11 * b)*2;
	self.vc[1], self.vc[2], self.vc[3], self.vc[4], self.vc[5], self.vc[6] = r,g,b, (r+t)/3, (g+t)/3, (b+t)/3;
	if not LBFGroup then
		self:GetHighlightTexture():SetVertexColor(r, g, b);
		self:GetCheckedTexture():SetVertexColor(r, g, b);
	end
	self.text:SetTextColor(r, g, b);
	self:Tint();
end
local function ORI_SpawnIndicator(name, parent)
	local e = CreateFrame("CheckButton", name, parent);
	e.icon, e.text, e.count, e.key, e.vc = e:CreateTexture(nil, "ARTWORK"),
		e:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge"),
		e:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge"),
		e:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray"), {};
	e.SetAngle, e.SetScaleSmoothly, e.SetPredominantColor, e.Tint = ORMI_SetAngle, ORMI_SetScaleSmoothly, ORMI_SetPredominantColor, ORMI_SetVertexTint;
	SetDimensions(e, 48); e.icon:SetPoint("CENTER");
	e.text:SetPoint("CENTER");
	e.key:SetPoint("TOPRIGHT", -1, -4); e.key:SetJustifyH("RIGHT");
	e:EnableMouse(false);
	e:SetHighlightTexture("Interface\\AddOns\\OPie\\gfx\\borderhi");
	e:SetCheckedTexture("Interface\\AddOns\\OPie\\gfx\\iglow");
	if LBFGroup then
		pcall(LBFGroup.AddButton, LBFGroup, e, {Icon=e.icon, Count=e.count, HotKey=e.key});
	else
		e:GetHighlightTexture():SetBlendMode("BLEND");
		SetDimensions(e.icon, 45);
		e.edge = e:CreateTexture(nil, "OVERLAY");
		e.edge:SetTexture("Interface\\AddOns\\OPie\\gfx\\borderlo");
		e.edge:SetAllPoints();
		e.count:SetPoint("BOTTOMRIGHT", -4, 4);
	end
	return e;
end
local function ORI_RadiusCalc(n, fLength, aLength, min)
	local radius, mLength, abs, astep = min, (fLength+aLength)/2, math.abs, 360 / n;
	repeat
		local ox, oy, clear = radius, 0, true;
		for i=1,n-1 do
			local nx, ny, sideLength = radius*cos(i*astep), radius*sin(i*astep), (i == 1 or i == n) and mLength or aLength;
			if abs(ox - nx) < sideLength and abs(oy - ny) < sideLength then
				clear, radius = false, radius + 5;
				break;
			end
			ox, oy = nx, ny;
		end
	until clear;
	return radius;
end
local function ORMI_ComputeRadius(n)
	return ORI_RadiusCalc(n, 48, 48, 95);
end
local OR_MultiIndicators = setmetatable({}, {__index=function(t, k) return rawset(t,k, ORI_SpawnIndicator("ORMI_Container" .. k, ORMI_Parent))[k]; end});
local ORMI_Radius = memoize(ORMI_ComputeRadius);

local GhostIndication = {};
do -- Ghost Indication widget details
	local spareGPool, spareBPool, currentGroups, allocatedBCount, activeGroup = {}, {}, {}, 0;
	local function freeGroup(g)
		g:Hide(); g.incident, g.count = nil, nil;
		for i, button in ipairs(g) do
			spareBPool[button], g[i] = nil; -- Release buttons;
		end
	end
	local function makeGroup()
		local g = CreateFrame("Frame", nil, ORMI_Parent);
		g:Hide(); g:SetWidth(20); g:SetHeight(20); g:SetScale(0.80);
		return g;
	end
	setmetatable(spareGPool, {__newindex=function(self, k, v) rawset(self, k, v and freeGroup(k) or nil); end});
	local function AnimateHide(self, elapsed)
		local total = ORI_ConfigCache.XTZoomTime;
		self.expire = (self.expire or total) - elapsed;
		if self.expire < 0 then
			self.expire = nil; self:SetScript("OnUpdate", nil); self:Hide();
		else
			self:SetAlpha(self.expire/total);
		end
	end
	local function AnimateShow(self, elapsed)
		local total = ORI_ConfigCache.XTZoomTime/2;
		self.expire = (self.expire or total) - elapsed;
		if self.expire < 0 then
			self.expire = nil; self:SetScript("OnUpdate", nil); self:SetAlpha(1);
		else
			self:SetAlpha(1-self.expire/total);
		end
	end
	function GhostIndication:ActivateGroup(index, count, incidentAngle, mainRadius, mainScale)
		local ret, config = currentGroups[index] or next(spareGPool) or makeGroup(), ORI_ConfigCache;
		currentGroups[index], spareGPool[ret] = ret, nil;
		if not ret:IsShown() then ret:SetScript("OnUpdate", AnimateShow); ret:Show(); end
		if activeGroup ~= ret then GhostIndication:Deactivate(); end
		if ret.incident ~= incidentAngle or ret.count ~= count then
			local radius, angleStep = ORI_RadiusCalc(count, 48*mainScale, 48*0.80, 30)/0.80, 360/count;
			if config.GhostOldDirection then
				angleStep = ((incidentAngle + 90) % 360 >= 180) and -angleStep or angleStep;
			end
			local angle = 90 + incidentAngle + angleStep;
			for i=2,count do
				local cell = ret[i] or next(spareBPool);
				if not cell then
					cell, allocatedBCount = ORI_SpawnIndicator("ORI_Ghost" .. allocatedBCount), allocatedBCount + 1;
					if not LBFGroup then cell:GetCheckedTexture():SetAlpha(0.60); end
				end
				cell:ClearAllPoints();
				cell:SetParent(ret); cell:SetAngle(angle, radius); cell:Show();
				spareBPool[cell], ret[i], angle = nil, cell, angle + angleStep;
			end
			ret.incident, ret.count = incidentAngle, count;
			ret:ClearAllPoints();
			ret:SetPoint("CENTER", (mainRadius/0.80+radius)*cos(incidentAngle), (mainRadius/0.80+radius)*sin(incidentAngle));
			ret:Show();
		end
		activeGroup = ret;
		return ret;
	end
	function GhostIndication:Deactivate()
		if activeGroup then
			activeGroup:SetScript("OnUpdate", AnimateHide);
			activeGroup = nil;
		end
	end
	function GhostIndication:Reset()
		for k, v in pairs(currentGroups) do
			currentGroups[k], spareGPool[v] = nil, true;
		end
		activeGroup = nil;
	end
end

local function GetSelectedSlice(x, y, slices, offset)
	local radius, segAngle = (x*x + y*y)^0.5, 360 / slices;
	if radius < 40 or slices <= 0 then return 0; end
	local angle = (math.deg(math.atan2(x, y)) + segAngle/2 - offset) % 360;
	return floor(angle / segAngle) + 1;
end

local function shortBindName(bind)
	if not bind then return "" end
	local a, s, c, k = bind:match("ALT%-"), bind:match("SHIFT%-"), bind:match("CTRL%-"), bind:match("[^-]*.$"):gsub("^(.).-(%d+)$","%1%2");
	return (a and "A" or "") .. (s and "S" or "") .. (c and "C" or "") .. k;
end
local function ORI_CooldownFormat(cd)
	if cd == 0 or not cd then return ""; end
	local f, n, unit = cd > 10 and "%d%s" or "%.1f", cd, "";
	if n > 86400 then n, unit = ceil(n/86400), "d";
	elseif n > 3600 then n, unit = ceil(n/3600), "h";
	elseif n > 60 then n, unit = ceil(n/60), "m";
	elseif n > 10 then n = ceil(n); end
	return f, n, unit;
end
local function ORI_UpdateCenterIndication(self, si, osi)
	local config, count, offset, isUpdated, time = ORI_ConfigCache, self.count, self.offset, si ~= osi, GetTime();
	local sliceExists, r,g,b = OneRingLib:GetOpenRingSlice(si);
	local usable, cd, cd2, icon, caption, icount, active, nature, ident = OneRingLib:GetOpenRingSliceAction(si);
	if sliceExists then
		ORI_Pointer:SetVertexColor(r,g,b, 0.9);
		ORI_Circle:SetVertexColor(r,g,b, 0.9);
		ORI_Glow:SetVertexColor(r,g,b, 0.9);
		OR_SpellCaption:SetTextColor(r,g,b);
		OR_SpellCD:SetTextColor(r,g,b);
	elseif isUpdated then
		ORI_Pointer:SetVertexColor(1,1,1,0.1);
		ORI_Circle:SetVertexColor(1,1,1,0.3);
		ORI_Glow:SetVertexColor(0.75,0.75,0.75);
		GameTooltip:Hide();
	end

	if sliceExists then
		OR_SpellIcon:SetTexture(icon);
		if icon and not LBGroup then OR_SpellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); end
		if config.UseGameTooltip then
			local ifunc, iarg = GameTooltip.SetHyperlink;
			GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
			if nature == "item" and ident then
				local ok, _, ilink = pcall(GetItemInfo, ident);
				iarg = ok and ilink or ident;
			elseif nature == "spell" and ident then
				local t, i = OneRingLib.xlu.companionSpellCache(ident);
				if t and i then iarg = select(3, GetCompanionInfo(t, i)); end
				iarg = iarg and ("spell:" .. iarg) or GetSpellLink(ident);
			elseif nature == "equipmentset" and ident then
				ifunc, iarg = GameTooltip.SetEquipmentSet, ident;
			end
			if iarg == nil then
				ifunc, iarg = caption and GameTooltip.AddLine or GameTooltip.Hide, caption;
			end
			if pcall(ifunc, GameTooltip, iarg) and iarg and iarg ~= "" then
				GameTooltip:Show();
			end
		end
		OR_CenterIndication:SetChecked(active and 1 or nil);
	end
	OR_CenterIndication[sliceExists and icon and config.ShowCenterIcon and (not config.MultiIndication) and "Show" or "Hide"](OR_CenterIndication);
	OR_SpellCD:SetFormattedText(ORI_CooldownFormat(sliceExists and config.ShowCooldowns and cd or 0));
	OR_SpellCaption:SetText(sliceExists and config.ShowCenterCaption and caption or "");
	OR_SpellCount:SetText(sliceExists and icount and icount > 0 and icount or "");

	usable = usable == true;
	local gAnim, gEnd, oIG = self.gAnim, self.gEnd, self.oldIsGlowing;
	if usable ~= oIG then
		gAnim, gEnd = usable and "in" or "out",  time + 0.3 - (gEnd and gEnd > time and (gEnd-time) or 0);
		self.oldIsGlowing, self.gAnim, self.gEnd = usable, gAnim, gEnd;
		ORI_Glow:Show();
	end
	if (gAnim and gEnd <= time) or oIG == nil then
		self.gAnim, self.gEnd = nil, nil;
		ORI_Glow[gAnim == "in" and "Show" or "Hide"](ORI_Glow);
		ORI_Glow:SetAlpha(0.5);
	elseif gAnim then
		local pg = (gEnd-time)/0.6;
		ORI_Glow:SetAlpha(gAnim == "out" and (pg) or (0.5 - pg));
	end
	self.oldSlice = si;
	return sliceExists;
end
local function ORMI_UpdateSlice(indic, usable, cd, cd2, icon, caption, count, active, nature, ident)
	local config = ORI_ConfigCache;
	local faded = (cd or 0) > 0 or not usable;
	indic.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark");
	if not LBFGroup then
		local tex = indic.icon:GetTexture();
		if tex:match("^[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee]\\[Ii][Cc][Oo][Nn][Ss]\\") or tex:match("^Interface\\AddOns\\") then
			indic.icon:SetTexCoord(2/64, 62/64, 2/64, 62/64);
		else
			indic.icon:SetTexCoord(-2/64,66/64,-2/64,66/64);
		end
	end
	SetDesaturation(indic.icon, faded and 1 or nil);
	indic:Tint();
	indic.text:SetFormattedText(ORI_CooldownFormat(config.ShowCooldowns and cd or 0));
	indic.count:SetText(count and count > 0 and count or "");
	if (indic:IsEnabled() == 0) ~= faded then
		indic[faded and "Disable" or "Enable"](indic);
	end
	indic:SetChecked(active and 1 or nil);
end
local function ORI_GhostUpdate(self, slice)
	local config, count, offset = ORI_ConfigCache, self.count, self.offset;
	local ghostCount = slice and select(5,OneRingLib:GetOpenRingSlice(slice));
	if (ghostCount or 0) == 0 then return GhostIndication:Deactivate(); end
	local scaleM = config.MIScale and 1.10 or 1;
	local group = GhostIndication:ActivateGroup(slice, ghostCount, 90 - 360/count*(slice-1) - offset, ORMI_Radius[count]*scaleM, scaleM);
	for i=2,ghostCount do
		group[i]:SetPredominantColor(OneRingLib:GetOpenRingSliceColor(slice, i));
		ORMI_UpdateSlice(group[i], OneRingLib:GetOpenRingSliceGhost(slice, i));
	end
end
local function pround(n, precision, half)
	local remainder = n % precision;
	return remainder >= half and (n - remainder + precision) or (n - remainder);
end
local function ORI_Update(self, elapsed)
	local time, config, count, offset = GetTime(), ORI_ConfigCache, self.count, self.offset

	local scale, l, b, w, h = self:GetEffectiveScale(), self:GetRect();
	local x, y = GetCursorPosition();
	local dx, dy = (x / scale) - (l + w / 2), (y / scale) - (b + h / 2);
	dx, dy = pround(dx, 0.005, 0.0025), pround(dy, 0.005, 0.0025);
	local radius = (dx*dx+dy*dy)^0.5;

	-- Calculate pointer location
	local angle, isInFastClick = (math.deg(math.atan2(dx, dy)) -180) % 360, config.CenterAction and radius <= 20 and self.fastClickSlice > 0 and self.fastClickSlice <= self.count;
	if isInFastClick then
		angle = (offset + (self.fastClickSlice-1)*360/count - 180) % 360;
	end

	local oangle = (not isInFastClick) and self.angle or angle;
	local adiff, arate = math.min((angle-oangle) % 360, (oangle-angle) % 360), 180;
	if adiff > 60 then
		arate = 420 + 120*sin(min(90, adiff-60));
	elseif adiff > 15 then
		arate = 180 + 240*sin(min(90, max((adiff-15)*2, 0)));
	else
		arate = 20 + 160*sin(min(90, adiff*6));
	end
	local abound, arotDirection = arate/GetFramerate(), ((oangle - angle) % 360 < (angle - oangle) % 360) and -1 or 1;
	abound = abound * 2^config.XTPointerSpeed;
	self.angle = (adiff < abound) and angle or (oangle + arotDirection * abound) % 360;
	ORI_Pointer:SetRotation((1-self.angle/180)*3.1415926535898);

	-- What is selected?
	local si, osi = isInFastClick and self.fastClickSlice or GetSelectedSlice(dx, dy, count, offset), self.oldSlice;
	local sliceExists = ORI_UpdateCenterIndication(self, si, osi);

	-- Multiple indication
	if config.MultiIndication and count > 0 then
		local cmState, mut = (IsShiftKeyDown() and 1 or 0) + (IsControlKeyDown() and 2 or 0) + (IsAltKeyDown() and 4 or 0), self.schedMultiUpdate or 0;
		if self.omState ~= cmState or mut >= 0  then
			self.omState, self.schedMultiUpdate = cmState, -0.05;
			for i=1,count do
				OR_MultiIndicators[i]:SetPredominantColor(select(2,OneRingLib:GetOpenRingSlice(i)));
				ORMI_UpdateSlice(OR_MultiIndicators[i], OneRingLib:GetOpenRingSliceAction(i));
			end
			if config.GhostMIRings then
				ORI_GhostUpdate(self, si);
			end
		else
			self.schedMultiUpdate = mut + elapsed;
		end

		local cangle, astep = config.MIDisjoint and ((angle - 180) % 360) or ((self.angle - 180) % 360), 360/count;
		cangle = (cangle - offset) % 360;
		if config.MIScale then
			for i=1,count do
				local adiff = math.min((astep*(i-1)-cangle) % 360, (cangle-astep*(i-1)) % 360);
				if not sliceExists then
					OR_MultiIndicators[i]:SetScaleSmoothly(0.95);
				else
					local mmul = count > 5 and count/6 or 1.25;
					if adiff <= astep / 2 then
						local toprange = math.max(10, astep / 6);
						local range, delta = math.max(0.1, astep / 2 - toprange), adiff - toprange;
						OR_MultiIndicators[i]:SetScaleSmoothly(1.07 + 0.03*cos(max(0, delta) * 90 / range));
					elseif adiff <= astep * mmul then
						local range, delta = math.max(0.1, astep * mmul - astep / 2), adiff - astep / 2;
						OR_MultiIndicators[i]:SetScaleSmoothly(1 + 0.07*cos(delta * 90 / range));
					else
						OR_MultiIndicators[i]:SetScaleSmoothly(1);
					end
				end
			end
		end
		if si ~= osi then
			if osi then OR_MultiIndicators[osi]:UnlockHighlight(); end
			if si then OR_MultiIndicators[si]:LockHighlight(); end
		end
	end
end
local function ORI_ZoomIn(self, elapsed)
	self.eleft = self.eleft - elapsed;
	local delta, config = max(0, self.eleft/ORI_ConfigCache.XTZoomTime), ORI_ConfigCache;
	if delta == 0 then self:SetScript("OnUpdate", ORI_Update); end
	self:SetScale(config.RingScale/max(0.2,cos(65*delta))); self:SetAlpha(1-delta);
	return ORI_Update(self, elapsed);
end
local function ORI_ZoomOut(self, elapsed)
	self.eleft = self.eleft - elapsed;
	local delta, config = max(0, self.eleft/ORI_ConfigCache.XTZoomTime), ORI_ConfigCache;
	if delta == 0 then return self:Hide(), self:SetScript("OnUpdate", nil); end
	if config.MultiIndication and config.MISpinOnHide then
		local offset, count =  self.offset, self.count;
		local baseAngle, angleStep, radius, prog = 45 - offset + 45*delta, 360/count, ORMI_Radius[count], (1-delta)*150*max(0.5, min(1, GetFramerate()/60));
		for i=1,count do
			OR_MultiIndicators[i]:SetPoint("CENTER", cos(baseAngle)*radius + cos(baseAngle-90)*prog, sin(baseAngle)*radius + sin(baseAngle-90)*prog);
			baseAngle = baseAngle - angleStep;
		end
		self:SetScale(config.RingScale*(1.75 - .75*delta));
	else
		self:SetScale(config.RingScale*delta);
	end
	self:SetAlpha(delta);
end

-- Animator Interface
local function ORI_Show(ringID, fcSlice, fastOpen)
	local frame, config, _ = OR_IndicationFrame, ORI_ConfigCache;
	if ORI_FinishSplash then ORI_FinishSplash(frame); end

	-- Copy ring configuration to indication frame.
	OneRingLib:GetOpenRingOptions(config);
	_, frame.count, frame.offset = OneRingLib:GetOpenRing();

	-- Zoom in to the ring's indication option
	frame:SetScript("OnUpdate", ORI_ZoomIn);
	frame.eleft, frame.fastClickSlice = config.XTZoomTime * (fastOpen and 0.5 or 1), fcSlice;
	MouselookStop();

	-- Show/Hide multiple indication icons as required
	local useMultipleIndication, astep, radius = config.MultiIndication, -360/frame.count, ORMI_Radius[frame.count];
	for i=1,(useMultipleIndication and frame.count or 0) do
		local indic, _, r,g,b, subRingId, sliceBind = OR_MultiIndicators[i], OneRingLib:GetOpenRingSlice(i);
		indic.key:SetText(config.ShowKeys and sliceBind and shortBindName(sliceBind) or "");
		indic:SetAngle((i - 1) * astep - frame.offset, radius);
		indic:SetPredominantColor(r,g,b);
		indic:Show(); indic:UnlockHighlight();
	end
	for i=(useMultipleIndication and (frame.count+1) or 1),#OR_MultiIndicators do
		OR_MultiIndicators[i]:Hide();
	end
	for i, v in ipairs(OR_MultiIndicators) do v:SetAlpha(1); v:SetScale(1); end
	ORMI_Parent:SetAlpha(1); ORMI_Parent:SetScale(1);

	-- Show the indication frame
	config.RingScale = max(0.1, config.RingScale);
	frame:SetScale(config.RingScale); OR_IndicationPos:SetScale(frame:GetScale());
	if config.RingAtMouse then
		local es, cx, cy = frame:GetEffectiveScale(), GetCursorPosition()
		OR_IndicationPos:SetPoint("CENTER", nil, "BOTTOMLEFT", cx/es+ config.IndicationOffsetX, cy/es - config.IndicationOffsetY);
	else
		OR_IndicationPos:SetPoint("CENTER", nil, "CENTER", config.IndicationOffsetX, -config.IndicationOffsetY);
	end
	frame:Show();

	-- And reset all visual indication elements
	frame.oldSlice, frame.angle, frame.omState, frame.oldIsGlowing = -1;
	GhostIndication:Reset();
	ORI_Update(frame, 0);
end
local function ORI_Hide()
	OR_IndicationFrame:SetScript("OnUpdate", ORI_ZoomOut);
	OR_IndicationFrame.eleft = ORI_ConfigCache.XTZoomTime;
	GhostIndication:Deactivate();
	GameTooltip:Hide();
end
OR_IndicationFrame:Hide();

local function switchProfile(event, key, t)
	if (event == "SAVE" or event == "LOGOUT") and LBFGroup then
		t.SkinID, t.Gloss, t.Backdrop, t.Colors = LBFGroup.SkinID, LBFGroup.Gloss, LBFGroup.Backdrop, LBFGroup.Colors;
	elseif event == "UPDATE" and t.SkinID and LBFGroup then
		LBFGroup.Colors = t.Colors or {};
		LBFGroup:Skin(t.SkinID, t.Gloss, t.Backdrop);
	end
end
OneRingLib:RegisterPVar("LBFConfig", LBFConfig, switchProfile, true);
OneRingLib:RegisterAnimator(ORI_Show, ORI_Hide);
for k,v in pairs(ORI_OptionDefaults) do
	OneRingLib:RegisterOption(k,v);
end