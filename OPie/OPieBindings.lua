local config, lang = OneRingLib.ext.config, OneRingLib.lang;

local frame = config.createFrame("Ring Bindings", "OPie", true);

local lRing = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
local lBinding = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	lBinding:SetPoint("TOPLEFT", frame.desc, "BOTTOMLEFT", 0, -10);
	lRing:SetPoint("LEFT", lBinding, "LEFT", 190, 0);
	lBinding:SetWidth(160);
local bindLines = {};
local function mClick(self) frame.showMacroPopup(self:GetParent():GetID()); end
for i=1,15 do
	local bind = config.createBindingButton("OPC_BindKey" .. i, frame);
	local label = bind:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	bind:SetPoint("TOPLEFT", lBinding, "BOTTOMLEFT", 0, 16-20*i);
	bind.macro = CreateFrame("BUTTON", "OPC_BindKeyM" .. i, bind, "UIPanelButtonTemplate2");
	bind.macro:SetWidth(24); bind.macro:SetPoint("LEFT", bind, "RIGHT", 1, 0);
	bind.macro:SetText("|TInterface\\RaidFrame\\UI-RaidFrame-Arrow:40:40:0:-2|t");
	bind.macro:SetScript("OnClick", mClick);
	bind:SetWidth(160); bind:GetFontString():SetWidth(150);
	label:SetPoint("LEFT", 190, 2);
	bind:SetNormalFontObject(GameFontNormalSmall);
	bind:SetHighlightFontObject(GameFontHighlightSmall);
	bindLines[i], bind.label = bind, label;
end
local btnUnbind = config.createUnbindButton("OPC_Unbind", frame);
	btnUnbind:SetPoint("TOP", bindLines[#bindLines], "BOTTOM", 0, -3);
local btnUp = CreateFrame("Button", "OPC_SUp", frame, "UIPanelScrollUpButtonTemplate");
	btnUp:SetPoint("RIGHT", btnUnbind, "LEFT", -10);
local btnDown = CreateFrame("Button", "OPC_SDown", frame, "UIPanelScrollDownButtonTemplate");
	btnDown:SetPoint("LEFT", btnUnbind, "RIGHT", 10);

local alternateFrame = CreateFrame("Frame", nil, frame);
	alternateFrame:SetBackdrop({
	  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	  edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]], tile = true, tileSize = 32, edgeSize = 32,
	  insets = { left = 11, right = 11, top = 12, bottom = 10 }
	});
	alternateFrame:SetWidth(350); alternateFrame:SetHeight(115);
	alternateFrame:SetBackdropColor(0,0,0, 0.85);
	alternateFrame:EnableMouse();
	frame:SetScript("OnHide", function() alternateFrame:Hide() end);
	frame:HookScript("OnShow", function() alternateFrame:SetFrameStrata("DIALOG"); end);
local conditionalBindingCaption = alternateFrame:CreateFontString("OVERLAY", nil, "GameFontHighlightSmall");
	conditionalBindingCaption:SetPoint("TOPLEFT", 13, -12);
local scroller = CreateFrame("ScrollFrame", "OPC_BindInputScroll", alternateFrame, "UIPanelScrollFrameTemplate")
	scroller:SetPoint("TOPLEFT", 10, -28);
	scroller:SetPoint("BOTTOMRIGHT", -33, 10);
local txtAlternateInput = CreateFrame("Editbox", "OPC_BindInput", scroller);
	txtAlternateInput:SetMaxBytes(1023); txtAlternateInput:SetMultiLine(true);
	txtAlternateInput:SetWidth(305); txtAlternateInput:SetAutoFocus(false);
	txtAlternateInput:SetTextInsets(2, 0,0,0);
	txtAlternateInput:SetFontObject(GameFontHighlight);
	txtAlternateInput:SetScript("OnEscapePressed", function(s) alternateFrame:Hide(); end);
	scroller:SetScrollChild(txtAlternateInput);
	alternateFrame:SetScript("OnMouseDown", function() txtAlternateInput:SetFocus() end);
	txtAlternateInput.bar = _G["OPC_BindInputScrollScrollBar"];
	do -- Macro text box scrolling
		local occH, occP; -- Height, Pos
		txtAlternateInput:SetScript("OnCursorChanged", function(s, x,y,w,h)
			occH, occP, y = scroller:GetHeight(), scroller:GetVerticalScroll(), -y;
			if occP > y then occP = y; -- too far
			elseif (occP + occH) < (y+h) then occP = y+h-occH; -- not far enough
			else return; end -- is fine
			scroller:SetVerticalScroll(occP);
			local _, mx = s.bar:GetMinMaxValues();
			s.bar:SetMinMaxValues(0, occP < mx and mx or occP);
			s.bar:SetValue(occP);
		end);
	end
	txtAlternateInput:SetScript("OnChar", function(s, c)
		if c == "\n" then
			local bind = strtrim((s:GetText():gsub("[\r\n]", "")));
			if bind ~= "" then
				frame.SetBinding(alternateFrame.key, bind);
			end
			alternateFrame:Hide();
		end
	end);

StaticPopupDialogs["OBC_MACRO"] = {button2=TEXT(OKAY), hasEditBox=1, hasWideEditBox=1, whileDead=1, timeout = 0, hideOnEscape=true};

local firstShownRing, lastShownRing, prevRing, nextRing = 0, 0;

function frame.showMacroPopup(id)
	local key = id;
	local name, key, count, index, macro = OneRingLib:GetRingInfo(key);
	StaticPopupDialogs["OBC_MACRO"].text = lang("cfgBindingMacro"):format(name or key or lang("cfgBindingThis"));
	local dialog = StaticPopup_Show("OBC_MACRO");
	dialog.wideEditBox:SetText(macro);
	dialog.wideEditBox:HighlightText(0, #macro);
end
function frame.OnAltClick(self, button)
	local key = self:GetID();
	if alternateFrame:IsShown() and alternateFrame.key == key then
		alternateFrame:Hide();
	else
		alternateFrame.key = key;
		alternateFrame:SetFrameStrata("DIALOG");
		alternateFrame:ClearAllPoints();
		alternateFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -10, 5);
		txtAlternateInput:SetText(OneRingLib:GetRingBinding(key) or "");
		alternateFrame:Show();
		txtAlternateInput:SetFocus();
	end
end
local function updateContent()
	local nextLine, numRings, secondRing = 1, OneRingLib:GetNumRings(), 1;
	for ring=math.max(1, firstShownRing), numRings do
		if not bindLines[nextLine] then break end
		local name, key, slices, id, macro, internal = OneRingLib:GetRingInfo(ring);
		if not internal then
			local bind, isOverride, isActive, cBind = OneRingLib:GetRingBinding(ring);
			local color = (cBind and isActive == false and (isOverride and "|cffFA2800" or "|cffa0a0a0")) or (isOverride and "|cffffffff") or "";
			local bindText = color .. config.bindingFormat(bind);
			if cBind ~= bind then bindText = lang("cfgBindingCond"):format(color, config.bindingFormat(cBind)); end
			bindLines[nextLine].label:SetFormattedText(lang("bndRingName"), name or key or "?", slices);
			bindLines[nextLine]:SetText(bindText);
			bindLines[nextLine]:SetID(ring);
			bindLines[nextLine]:Show();
			lastShownRing, nextLine, secondRing = ring, nextLine + 1, (nextLine == 2) and ring or secondRing;
		end
	end
	while bindLines[nextLine] do bindLines[nextLine]:Hide(); nextLine = nextLine + 1; end

	btnUp:Disable(); btnDown:Disable();
	for ring=firstShownRing - 1, 1, -1 do
		if not select(6, OneRingLib:GetRingInfo(ring)) then
			btnUp:SetID(ring); btnUp:Enable();
			break;
		end
	end
	for ring=lastShownRing + 1, numRings do
		if not select(6, OneRingLib:GetRingInfo(ring)) then
			btnDown:SetID(secondRing); btnDown:Enable();
			break;
		end
	end
end
local function scroll(self)
	firstShownRing = self:GetID();
	updateContent();
end
function frame.SetBinding(button, bind)
	local key = type(button) == "number" and button or (button:GetID());
	local okey, over = OneRingLib:GetRingBinding(key);
	config.pushUndo("Bind" .. key, OneRingLib.SetRingBinding, OneRingLib, key, over and okey or nil);
	OneRingLib:SetRingBinding(key, bind);
	updateContent();
end

function frame.localize()
	frame.title:SetText(lang("cfgBindingTitle"));
	frame.desc:SetText(lang("cfgBindingIntro"));
	lRing:SetText(lang("cfgName"));
	lBinding:SetText(lang("cfgBinding"));
	btnUnbind:SetText(lang("cfgUnbind"));
	conditionalBindingCaption:SetText(lang("cfgBindConditionalExplain"));
end
function frame.refresh()
	if not frame:IsShown() then return; end
	frame.localize();
	updateContent();
end
function frame.default()
	for i=1,OneRingLib:GetNumRings() do
		OneRingLib:SetRingBinding(i, nil);
	end
	updateContent()
end

btnUp:SetScript("OnClick", scroll);
btnDown:SetScript("OnClick", scroll);