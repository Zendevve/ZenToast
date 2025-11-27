do -- ext.config
	local config = {};
	function config.SetDimensions(frame, w, h)
		frame:SetWidth(w); frame:SetHeight(h or w);
	end
	local function onShowRestore()
		InterfaceOptionsFrame:SetFrameStrata("HIGH");
	end
	local function onShowRefresh(self)
		InterfaceOptionsFrame:SetFrameStrata("HIGH");
		self.refresh();
	end
	function config.createFrame(name, parent, refreshOnShow)
		local frame = CreateFrame("Frame", nil, UIParent);
			config.SetDimensions(frame, 400, 400); frame.name, frame.parent = name, parent; InterfaceOptions_AddCategory(frame); frame:Hide();
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
			frame.title:SetPoint("TOPLEFT", 15, -15); frame.title:SetText(name);
		frame.version = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			frame.version:SetPoint("TOPRIGHT", -15, -15);
		frame.desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			frame.desc:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10); frame.desc:SetWidth(385); frame.desc:SetJustifyH("LEFT");
		frame:SetScript("OnShow", refreshOnShow and onShowRefresh or onShowRestore);
		frame:Hide();
		return frame;
	end
	do -- undo
		local undoStack = {};
		function config.unwindUndo()
			local entry;
			for i=#undoStack,1,-1 do
				entry, undoStack[i] = undoStack[i];
				EC_pcall("OPC.Undo", "[" .. entry.key .. "]", entry.func, unpack(entry, 1, entry.n));
			end
		end
		function config.clearUndo()
			table.wipe(undoStack);
		end
		function config.pushUndo(key, func, ...)
			if key ~= "Profile" then
				for i=#undoStack,1,-1 do
					if undoStack[i].key == key then
						return;
					elseif undoStack[i].key == "Profile" then
						break;
					end
				end
			end
			table.insert(undoStack, {key=key, func=func, n=select("#", ...), ...});
		end
	end
	do -- bind
		local unbindMap, activeCaptureButton = {};
		local function MapMouseButton(button)
			if button == "MiddleButton" then return "BUTTON3" end
			if type(button) == "string" and (tonumber(button:match("^Button(%d+)"))) or 1 > 3 then
				return button:upper();
			end
		end
		local function Deactivate(self)
			self:UnlockHighlight(); self:EnableKeyboard(false);
			self:SetScript("OnKeyDown", nil); self:SetScript("OnHide", nil);
			activeCaptureButton = activeCaptureButton ~= self and activeCaptureButton or nil;
			if unbindMap[self:GetParent()] then unbindMap[self:GetParent()]:Disable(); end
			return self
		end
		local function SetBind(self, bind)
			if not (bind and (bind:match("^[LR]?ALT$") or bind:match("^[LR]?CTRL$") or bind:match("^[LR]?SHIFT$"))) then
				Deactivate(self);
				if bind == "ESCAPE" then return; end
				local bind, p = bind and ((IsAltKeyDown() and "ALT-" or "") ..  (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. bind), self:GetParent();
				if p and type(p.SetBinding) == "function" then p.SetBinding(self, bind); end
			end
		end
		local function OnClick(self, button)
			if activeCaptureButton then
				local deactivated, mappedButton = Deactivate(activeCaptureButton), MapMouseButton(button);
				if deactivated == self and (mappedButton or button == "RightButton") then SetBind(self, mappedButton); end
				if deactivated == self then return; end
			end
			if IsAltKeyDown() and activeCaptureButton == nil and self:GetParent().OnAltClick then return self:GetParent().OnAltClick(self, button); end
			activeCaptureButton = self;
			self:LockHighlight();	self:EnableKeyboard(true);
			self:SetScript("OnKeyDown", SetBind); self:SetScript("OnHide", Deactivate);
			if unbindMap[self:GetParent()] then unbindMap[self:GetParent()]:Enable(); end
		end
		local function UnbindClick(self)
			if activeCaptureButton and unbindMap[activeCaptureButton:GetParent()] == self then
				local p = activeCaptureButton:GetParent();
				if p and type(p.SetBinding) == "function" then p.SetBinding(activeCaptureButton, false); end
				Deactivate(activeCaptureButton);
			end
		end
		local function IsCapturingBinding(self)
			return activeCaptureButton == self;
		end
		function config.createBindingButton(name, parent)
			local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate2");
			config.SetDimensions(btn, 120, 22); btn:RegisterForClicks("AnyUp"); btn:SetScript("OnClick", OnClick);
			btn:SetText(" "); btn:GetFontString():SetWidth(120); btn:GetFontString():SetHeight(1);
			btn.IsCapturingBinding = IsCapturingBinding;
			return btn, unbindMap[parent];
		end
		function config.createUnbindButton(name, parent)
			local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate2");
			btn:Disable(); config.SetDimensions(btn, 120, 22); unbindMap[parent] = btn;
			btn:SetScript("OnClick", UnbindClick);
			return btn;
		end
		local function bindNameLookup(capture) return _G["KEY_" .. capture]; end
		function config.bindingFormat(bind)
			return bind and bind:gsub("[^%-]+$", bindNameLookup) or OneRingLib.lang("cfgNoBinding");
		end
	end
	OneRingLib.ext.config = config;
end

local lang, config = OneRingLib.lang, OneRingLib.ext.config;
local OPC_OptionSets = {
	{ "Behavior",
		{"bool", "RingAtMouse"},
		{"bool", "CenterAction"},
		{"bool", "SliceBinding"},
		{"bool", "ClickActivation"},
		{"bool", "ClickPriority", depOn="ClickActivation", depValue=true, otherwise=false},
		{"bool", "NoClose", depOn="ClickActivation", depValue=true, otherwise=false},
		{"range", "MouseBucket", 5, 1, 1, stdLabels=true},
		{"range", "RingScale", 0.1, 2},
	}, { "Indication",
		{"bool", "MultiIndication"},
		{"bool", "GhostMIRings", depOn="MultiIndication", depValue=true, otherwise=false},
		{"bool", "ShowCenterCaption"},
		{"bool", "ShowCooldowns"},
		{"bool", "UseGameTooltip"},
		{"bool", "ShowKeys", depOn="SliceBinding", depValue=true, otherwise=false},
		{"bool", "ShowCenterIcon", depOn="MultiIndication", depValue=false, otherwise=false},
		{"bool", "HideStanceBar", global=true},
		{"bool", "UseBF", global=true, req=function() return LibStub and LibStub("LibButtonFacade", true) and true; end, reload=true},
		{"bool", "ColorBF", depOn="UseBF", depValue=true, otherwise=false},
	}, { "Animation",
		{"bool", "MIScale"},
		{"bool", "MIDisjoint", depOn="MIScale", depValue=true, otherwise=false},
		{"range", "XTScaleSpeed", -4, 4},
		{"range", "XTPointerSpeed", -4, 4},
		{"range", "XTZoomTime", 0, 1}
	}
};

local frame = config.createFrame("OPie", nil, true);
	frame.version:SetFormattedText("%s (%d.%d)", OneRingLib:GetVersion());
local OPC_Profile = CreateFrame("Frame", "OPC_Profile", frame, "UIDropDownMenuTemplate");
	OPC_Profile:SetPoint("TOPLEFT", frame.desc, "BOTTOMLEFT", -16, -5); UIDropDownMenu_SetWidth(OPC_Profile, 130);
local OPC_OptionDomain = CreateFrame("Frame", "OPC_OptionDomain", frame, "UIDropDownMenuTemplate");
	OPC_OptionDomain:SetPoint("LEFT", OPC_Profile, "RIGHT", -16, 0);	UIDropDownMenu_SetWidth(OPC_OptionDomain, 200);

local OPC_Widgets, OPC_AlterOption, OPC_BlockInput = {};
do -- Widget construction
	local build = {};
	local function notifyChange(self, ...)
		if not OPC_BlockInput then
			OPC_AlterOption(self, self.id, self:IsObjectType("Slider") and self:GetValue() or (not not self:GetChecked()), ...);
		end
	end
	local function OnStateChange(self)
		local a = self:IsEnabled() == 1 and 1 or 0.6;
		self.text:SetVertexColor(a,a,a);
	end
	function build.bool(v, rel, ofsY, halfpoint, rowHeight)
		local b = CreateFrame("CheckButton", "OPC_Option_" .. v[2], frame, "InterfaceOptionsCheckButtonTemplate");
		config.SetDimensions(b, 24); b:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		b.id, b.text = v[2], _G["OPC_Option_" .. v[2] .. "Text"];
		b.text:SetText(v[2]);
		b:SetPoint("TOPLEFT", rel, "BOTTOMLEFT", halfpoint and 200 or 5, ofsY);
		b:SetScript("OnClick", notifyChange); hooksecurefunc(b, "Enable", OnStateChange); hooksecurefunc(b, "Disable", OnStateChange);
		return b, ofsY - (halfpoint and rowHeight or 0), not halfpoint, halfpoint and 0 or 18;
	end
	function build.range(v, rel, ofsY, halfpoint, rowHeight)
		if halfpoint then ofsY = ofsY - rowHeight; end
		local b = CreateFrame("Slider", "OPC_Slider_" .. v[2], frame, "OptionsSliderTemplate");
		b:SetMinMaxValues(v[3] < v[4] and v[3] or -v[3], v[4] > v[3] and v[4] or -v[4]); b:SetValueStep(v[5] or 0.1); b:SetHitRectInsets(0,0,0,0);
		b.id, b.text, b.hi, b.lo = v[2], _G["OPC_Slider_" .. v[2] .. "Text"], _G["OPC_Slider_" .. v[2] .. "High"], _G["OPC_Slider_" .. v[2] .. "Low"];
		b.hi:ClearAllPoints(); b.hi:SetPoint("LEFT", b, "RIGHT", 2, 1);
		b.lo:ClearAllPoints(); b.lo:SetPoint("RIGHT", b, "LEFT", -2, 1);
		b.text:ClearAllPoints(); b.text:SetPoint("TOPLEFT", rel, "BOTTOMLEFT", 30, ofsY-3);
		b.text:SetText(v[2]); if not v.stdLabels then b.lo:SetText(v[3]); b.hi:SetText(v[4]); end
		b:SetPoint("TOPRIGHT", rel, "BOTTOMRIGHT", -30, ofsY-3);
		b:SetScript("OnValueChanged", notifyChange)
		return b, ofsY - 16, false, 0;
	end

	local cRel, cY, halfpoint, rowHeight = frame.desc, -30, false;
	for i, v in ipairs(OPC_OptionSets) do
		v.label = frame:CreateFontString("OPC_Section" .. i, "OVERLAY", "GameFontNormal");
		v.label:SetPoint("TOP", cRel, "BOTTOM", 0, cY-10); v.label:SetWidth(frame:GetWidth());
		cRel, cY, halfpoint, rowHeight = v.label, -2, false, 0;
		for j=2,#v do
			v[j].widget, cY, halfpoint, rowHeight = build[v[j][1]](v[j], cRel, cY, halfpoint, rowHeight);
			if (v[j].reload) then v[j].widget.tooltipText = "|cffffffff" .. OPTION_LOGOUT_REQUIREMENT; end
			OPC_Widgets[v[j][2]], v[j].widget.control = v[j].widget, v[j];
		end
		if halfpoint then cY = cY - rowHeight; end
	end
end

local OR_DeletedProfiles, OR_CurrentOptionsDomain = {};

function OPC_AlterOption(widget, option, newval, ...)
	if (...) == "RightButton" then newval = nil; end
	if widget.control[1] == "range" and widget.control[3] > widget.control[4] and type(newval) == "number" then newval = -newval; end
	local _, oldval = OneRingLib:GetOption(option, OR_CurrentOptionsDomain);
	OneRingLib:SetOption(option, OR_CurrentOptionsDomain, newval);
	local key = ("Option%s:%s"):format(OR_CurrentOptionsDomain and ("." .. OR_CurrentOptionsDomain) or "#G", option);
	config.pushUndo(key, OneRingLib.SetOption, OneRingLib, option, OR_CurrentOptionsDomain, oldval);
	local setval = OneRingLib:GetOption(option, OR_CurrentOptionsDomain);
	if widget:IsObjectType("Slider") then
		widget.text:SetText(lang("cfg" .. option):format(setval));
		OPC_BlockInput = true; widget:SetValue(setval * (widget.control[3] > widget.control[4] and -1 or 1)); OPC_BlockInput = false;
	elseif setval ~= newval then
		widget:SetChecked(setval and 1 or nil);
	end
	for i,set in ipairs(OPC_OptionSets) do for j=2,#set do
		if set[j].depOn == option then
			local match = setval == set[j].depValue;
			set[j].widget[match and "Enable" or "Disable"](set[j].widget);
			if match then
				set[j].widget:SetChecked(OneRingLib:GetOption(set[j][2], OR_CurrentOptionsDomain) or nil);
			else
				set[j].widget:SetChecked(set[j].otherwise or nil);
			end
		end
	end end
end
function OPC_OptionDomain.click(self, ringID)
	OR_CurrentOptionsDomain = ringID;
	frame.refresh();
end
function OPC_OptionDomain.menu()
	local info = UIDropDownMenu_CreateInfo();
	info.func, info.arg1, info.text, info.checked = OPC_OptionDomain.click, nil, lang("cfgGlobalDomain"), OR_CurrentOptionsDomain == nil and 1 or nil;
	UIDropDownMenu_AddButton(info);
	for i=1,OneRingLib:GetNumRings() do
		local name, key, count, id, macro, internal = OneRingLib:GetRingInfo(i);
		if not internal then
			info.text, info.arg1, info.checked = lang("cfgRingDomain"):format(name or key, count), i, i == OR_CurrentOptionsDomain and 1 or nil;
			UIDropDownMenu_AddButton(info);
		end
	end
end
local function OPC_Profile_AddNew()
	local eb = _G[this:GetParent():GetName().."EditBox"];
	local name = eb:GetText():match("^%s*(.-)%s*$"); eb:SetText("");
	if name == "" or OneRingLib:ProfileExists(kn) then return; end
	StaticPopup_Hide("ORC_PNAME");
	config.pushUndo("ProfileCreate", OneRingLib.DeleteProfile, OneRingLib, name);
	OPC_Profile.switch(nil, name, true);
	frame.refresh()
end
function OPC_Profile.switch(self, arg1, isNew)
	config.pushUndo("Profile", OneRingLib.SwitchProfile, OneRingLib, (OneRingLib:GetCurrentProfile()));
	OneRingLib:SwitchProfile(arg1, isNew);
	frame.refresh();
end
function OPC_Profile.new(self)
	StaticPopupDialogs["ORC_PNAME"] = StaticPopupDialogs["ORC_PNAME"] or {button1=TEXT(ACCEPT), button2=TEXT(CANCEL), hasEditBox=1, maxLetters=80, whileDead=1, timeout=0, hideOnEscape=true, OnHide = function() _G[this:GetName().."EditBox"]:SetText(""); end, OnAccept=OPC_Profile_AddNew, EditBoxOnEnterPressed=OPC_Profile_AddNew};
	StaticPopupDialogs["ORC_PNAME"].text = lang("cfgProfileName");
	StaticPopup_Show("ORC_PNAME");
end
function OPC_Profile.delete(self)
	OR_DeletedProfiles[OneRingLib:GetCurrentProfile()] = true;
	OPC_Profile.switch(self, "default");
	frame.refresh();
end
function OPC_Profile.menu()
	local info = UIDropDownMenu_CreateInfo();
	info.func = OPC_Profile.switch;
	for ident, isActive in OneRingLib.Profiles do
		if not OR_DeletedProfiles[ident] then
			info.text, info.arg1, info.arg2, info.checked = ident, ident, nil, isActive or nil;
			UIDropDownMenu_AddButton(info);
		end
	end
	info.text, info.disabled, info.checked = "", true, nil; UIDropDownMenu_AddButton(info);
	info.text, info.disabled, info.func = lang("cfgProfileNew"), false, OPC_Profile.new; UIDropDownMenu_AddButton(info);
	if OneRingLib:GetCurrentProfile() ~= "default" then
		info.text, info.func = lang("cfgProfileDel"), OPC_Profile.delete; UIDropDownMenu_AddButton(info);
	end
end
function frame.localize()
	frame.desc:SetText(lang("cfgMainIntro"));
	for i, v in pairs(OPC_OptionSets) do
		v.label:SetText(lang("cfgHeader" .. v[1]));
		for j=2,#v do
			v[j].widget.text:SetText(lang("cfg" .. v[j][2]));
		end
	end
	local label = lang("cfgGlobalDomain");
	if OR_CurrentOptionsDomain then
		local name, key, count = OneRingLib:GetRingInfo(OR_CurrentOptionsDomain);
		label = lang("cfgRingDomain"):format(name or key, count);
	end
	UIDropDownMenu_SetText(OPC_OptionDomain, label);
	UIDropDownMenu_SetText(OPC_Profile, lang("cfgProfile"):format(OneRingLib:GetCurrentProfile()));
end
function frame.refresh()
	if not frame:IsShown() then return; end
	OPC_BlockInput = true;
	frame.localize();
	for i, set in pairs(OPC_OptionSets) do for j=2,#set do
		local v, opttype, option = set[j], set[j][1], set[j][2];
		if opttype == "range" then
			v.widget:SetValue(OneRingLib:GetOption(option) * (v[3] < v[4] and 1 or -1));
			v.widget.text:SetFormattedText(lang("cfg" .. v[2]), v.widget:GetValue());
		elseif opttype == "bool" then
			v.widget:SetChecked(OneRingLib:GetOption(option, OR_CurrentOptionsDomain) or nil);
		end
		if v.depOn then
			local match = OneRingLib:GetOption(v.depOn) == v.depValue;
			v.widget[match and "Enable" or "Disable"](v.widget);
			if not match then v.widget:SetChecked(v.otherwise or nil); end
		end
		if v.global then
			v.widget[OR_CurrentOptionsDomain == nil and "Show" or "Hide"](v.widget);
		end
		if v.req and v.widget:IsShown() then
			local ok, res = pcall(v.req);
			if not (ok and res) then v.widget:Hide(); end
		end
	end end
	OPC_BlockInput = false;
end
function frame.cancel()
	table.wipe(OR_DeletedProfiles);
	config.unwindUndo();
end
function frame.default()
	OneRingLib:ResetOptions(true);
	frame.okay(); -- Unfortunately, there's no going back
end
function frame.okay()
	config.clearUndo();
	for k in pairs(OR_DeletedProfiles) do
		OR_DeletedProfiles[k] = nil;
		OneRingLib:DeleteProfile(k);
	end
end

UIDropDownMenu_Initialize(OPC_OptionDomain, OPC_OptionDomain.menu);
UIDropDownMenu_Initialize(OPC_Profile, OPC_Profile.menu);

SLASH_OPIE1, SLASH_OPIE2 = "/opie", "/op";
SlashCmdList["OPIE"] = function (args)
	if not frame:IsVisible() then
		InterfaceOptionsFrame_OpenToCategory(frame);
		if frame.collapsed then
			for i, button in pairs(InterfaceOptionsFrameAddOns.buttons) do
				if (type(button) == "table" and button.element == frame) then
					OptionsListButtonToggle_OnClick(button.toggle);
					break
				end
			end
		end
	end
end