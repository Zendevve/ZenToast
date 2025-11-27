local lang, RingKeeper, config, RingLineCount = OneRingLib.lang, OneRingLib.RingKeeper, OneRingLib.ext.config;
-- Build Configuration dialog frames/widgets for RK
local SetDimensions = config.SetDimensions;
local configPanel = config.createFrame(lang("cfgRKTitle"), "OPie", true);
	local ringDropdown = CreateFrame("Frame", "RKC_RingDropdown", configPanel, "UIDropDownMenuTemplate");
		ringDropdown:SetPoint("TOPLEFT", configPanel.desc, "BOTTOMLEFT", -5, -10);
		UIDropDownMenu_SetWidth(ringDropdown, 200);
	local btnNewRing = CreateFrame("Button", "RKC_AddNewRing", configPanel, "UIPanelButtonTemplate2");
		btnNewRing:SetPoint("LEFT", ringDropdown, "RIGHT", -6, 2); btnNewRing:SetWidth(135);
	local ringFrame = CreateFrame("Frame", "RKC_DetailFrame", configPanel);
		ringFrame:SetWidth(385); ringFrame:SetPoint("TOPLEFT", ringDropdown, "BOTTOMLEFT", 5, -2); ringFrame:SetPoint("BOTTOM", 0, 15);
		ringFrame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16, insets={left=5,right=5, top=5, bottom=5}});
		ringFrame:SetBackdropBorderColor(.6, .6, .6, 1);
	local RKCD_Name = CreateFrame("EditBox", nil, ringFrame);
		SetDimensions(RKCD_Name, 370, 20); RKCD_Name:SetPoint("TOPLEFT", 7, -7); RKCD_Name:SetFontObject(GameFontNormalLarge); RKCD_Name:SetAutoFocus(false);
		RKCD_Name.posLabel = RKCD_Name:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); RKCD_Name.posLabel:SetPoint("LEFT"); RKCD_Name.posLabel:Hide();
		RKCD_Name.hintLabel = RKCD_Name:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		RKCD_Name.hintLabel:SetPoint("BOTTOMLEFT", RKCD_Name.posLabel, "BOTTOMRIGHT", 10, 0); RKCD_Name.hintLabel:Hide();
		RKCD_Name:SetScript("OnEnter", function(self) if GetCurrentKeyBoardFocus() ~= self then self.posLabel:SetText(self:GetText()); self.hintLabel:Show() end end)
		RKCD_Name:SetScript("OnEditFocusGained", function(self) self.hintLabel:Hide() end)
		RKCD_Name:SetScript("OnLeave", function(self) self.hintLabel:Hide() end);
	local dropInstructions = ringFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		dropInstructions:SetJustifyH("CENTER"); dropInstructions:SetJustifyV("TOP"); dropInstructions:SetHeight(60);
	local spellDropZone = ringFrame:CreateTexture(nil, "BACKGROUND");
		SetDimensions(spellDropZone, 380, 64); spellDropZone:SetPoint("TOPLEFT", RKCD_Name, "BOTTOMLEFT", -5, -2);
		spellDropZone:SetTexture(1,1,1); spellDropZone:Hide();

	local RKCD_Buttons = {};
	local function RKCD_Desc_Enter(self)
		self.border:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end
	local function RKCD_Desc_Exit(self)
		self.border:SetVertexColor(1,1,1);
	end
	local function RKCD_CreateDescButton(id)
		local btn = CreateFrame("Frame", nil, ringFrame);
			SetDimensions(btn, 32, 54);
		btn.ico = CreateFrame("CheckButton", nil, btn);
			SetDimensions(btn.ico, 32); btn.ico:SetPoint("TOP");
			btn.ico:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square");
			btn.ico:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight");
		btn.tex = btn.ico:CreateTexture(nil, "ARTWORK"); btn.tex:SetAllPoints();
		btn.color = CreateFrame("Button", nil, btn);
			SetDimensions(btn.color, 32, 16); btn.color:SetPoint("TOP", btn.ico, "BOTTOM", 0, -6);
		btn.ctex = btn.color:CreateTexture(nil, "OVERLAY");
			SetDimensions(btn.ctex, 26, 10); btn.ctex:SetPoint("CENTER");
			btn.ctex:SetTexture(1,1,1);
		local bg = btn.color:CreateTexture(nil, "BORDER");
			SetDimensions(bg, 30, 14); bg:SetPoint("CENTER");
		btn.color.border = btn.color:CreateTexture(nil, "BACKGROUND");
			SetDimensions(btn.color.border, 32, 16); btn.color.border:SetPoint("CENTER");
		bg:SetTexture(0,0,0); btn.color.border:SetTexture(1,1,1);
		btn.color:SetScript("OnEnter", RKCD_Desc_Enter); btn.color:SetScript("OnLeave", RKCD_Desc_Exit);
		btn:SetID(id);
		return btn;
	end
	local RKCD_Prev = CreateFrame("Button", nil, ringFrame);	SetDimensions(RKCD_Prev, 32); RKCD_Prev:SetID(1);
	RKCD_Prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
	RKCD_Prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
	RKCD_Prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
	RKCD_Prev:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
	local RKCD_Next = CreateFrame("Button", nil, ringFrame); SetDimensions(RKCD_Next, 32); RKCD_Next:SetID(3);
	RKCD_Next:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
	RKCD_Next:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
	RKCD_Next:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
	RKCD_Next:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");

	RKCD_Buttons[1] = RKCD_CreateDescButton(1);
	RKCD_Buttons[1]:SetPoint("TOPLEFT", RKCD_Name, "BOTTOMLEFT", 30, -5);
	for i=2,9 do
		RKCD_Buttons[i] = RKCD_CreateDescButton(i);
		RKCD_Buttons[i]:SetPoint("LEFT", RKCD_Buttons[i-1], "RIGHT", 3, 0);
	end
	RKCD_Prev:SetPoint("RIGHT", RKCD_Buttons[1], "LEFT", -1, 12);
	RKCD_Next:SetPoint("LEFT", RKCD_Buttons[#RKCD_Buttons], "RIGHT", 1, 12);

	local RKC_InnerDetail = CreateFrame("Frame", nil, ringFrame);
		RKC_InnerDetail:SetWidth(370);	RKC_InnerDetail:SetPoint("TOP", RKCD_Buttons[1], "BOTTOM", 0, -8);
		RKC_InnerDetail:SetPoint("BOTTOMLEFT", 8, 8);
		RKC_InnerDetail:SetBackdrop(ringFrame:GetBackdrop());
		RKC_InnerDetail:SetBackdropBorderColor(ringFrame:GetBackdropBorderColor());

	local RKCD_EntryDetail = CreateFrame("Frame", "RKCD_EntryFrame", RKC_InnerDetail);
		RKCD_EntryDetail:SetPoint("TOPLEFT"); RKCD_EntryDetail:SetPoint("BOTTOMRIGHT");
	local RKCD_SpellDetail = RKCD_EntryDetail:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		SetDimensions(RKCD_SpellDetail, 310, 0); RKCD_SpellDetail:SetPoint("TOPLEFT", 10, -10);
		RKCD_SpellDetail:SetJustifyH("LEFT");
	local RKCD_EntryFastClick = CreateFrame("CheckButton", "RKCD_EntryFastClick", RKCD_EntryDetail, "InterfaceOptionsCheckButtonTemplate");
		RKCD_EntryFastClick:SetWidth(290); RKCD_EntryFastClickText:SetJustifyH("LEFT");
		SetDimensions(RKCD_EntryFastClick, 24); RKCD_EntryFastClick:SetPoint("TOPLEFT", RKCD_SpellDetail, "BOTTOMLEFT", 0, -2);
	local RKCD_EntryByName = CreateFrame("CheckButton", "RKCD_EntryByName", RKCD_EntryDetail, "InterfaceOptionsCheckButtonTemplate");
		RKCD_EntryByNameText:SetWidth(290); RKCD_EntryByNameText:SetJustifyH("LEFT"); SetDimensions(RKCD_EntryByName, 24);
		RKCD_EntryByName:Hide();
	local RKCD_OnlyWhilePresent = CreateFrame("CheckButton", "RKCD_OnlyWhilePresent", RKCD_EntryDetail, "InterfaceOptionsCheckButtonTemplate");
		RKCD_OnlyWhilePresentText:SetWidth(290); RKCD_OnlyWhilePresentText:SetJustifyH("LEFT"); SetDimensions(RKCD_OnlyWhilePresent, 24);
		RKCD_OnlyWhilePresent:Hide();
	local RKCD_UseExactRank = CreateFrame("CheckButton", "RKCD_ExactRank", RKCD_EntryDetail, "InterfaceOptionsCheckButtonTemplate");
		RKCD_ExactRankText:SetWidth(290); RKCD_ExactRankText:SetJustifyH("LEFT"); SetDimensions(RKCD_UseExactRank, 24);
		RKCD_UseExactRank:Hide();

	local RKCD_MacroBG = CreateFrame("Frame", "RK_MBG", RKCD_EntryDetail);
		RKCD_MacroBG:SetBackdrop(ringFrame:GetBackdrop());
		RKCD_MacroBG:SetPoint("TOPLEFT", RKCD_EntryFastClick, "BOTTOMLEFT", 0, 2);
		RKCD_MacroBG:Hide();
	local RKCD_MacroScroll = CreateFrame("ScrollFrame", "RKCD_MacroFrame", RKCD_MacroBG, "UIPanelScrollFrameTemplate");
		RKCD_MacroScroll:SetPoint("TOPLEFT", 5, -7); RKCD_MacroScroll:SetPoint("BOTTOMRIGHT", -28, 7); RKCD_MacroScroll:EnableMouse();
	local RKCD_EntryMacro = CreateFrame("EditBox", "RKCD_EntryMacroText", RKCD_MacroScroll);
		RKCD_EntryMacro:SetWidth(300); RKCD_EntryMacro:SetMaxBytes(1023);
		RKCD_EntryMacro:SetMultiLine(true); RKCD_EntryMacro:SetAutoFocus(false);
		RKCD_EntryMacro:SetFontObject(GameFontHighlight);
		RKCD_MacroScroll:SetScrollChild(RKCD_EntryMacro);
		RKCD_EntryMacro.bar = _G["RKCD_MacroFrameScrollBar"];
		RKCD_MacroScroll:SetScript("OnMouseDown", function() RKCD_EntryMacro:SetFocus(); end);
		do -- Macro text box scrolling
			local occH, occP; -- Height, Pos
			RKCD_EntryMacro:SetScript("OnCursorChanged", function(s, x,y,w,h)
				occH, occP, y = RKCD_MacroScroll:GetHeight(), RKCD_MacroScroll:GetVerticalScroll(), -y;
				if occP > y then occP = y; -- too far
				elseif (occP + occH) < (y+h) then occP = y+h-occH; -- not far enough
				else return; end -- is fine
				RKCD_MacroScroll:SetVerticalScroll(occP);
				local _, mx = s.bar:GetMinMaxValues();
				s.bar:SetMinMaxValues(0, occP < mx and mx or occP);
				s.bar:SetValue(occP);
			end);
		end

	local RKCD_SliceHint = CreateFrame("Frame", "RKCD_SliceHintFrame", RKC_InnerDetail);
		RKCD_SliceHint:SetPoint("TOPLEFT");	RKCD_SliceHint:SetPoint("BOTTOMRIGHT");
		RKCD_SliceHint:Hide();
	local RKCD_SliceCaption = RKCD_SliceHint:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		RKCD_SliceCaption:SetPoint("TOPLEFT", 8, -10);
		RKCD_SliceCaption:SetText("");
	local RKCD_SliceCaptionInput = CreateFrame("EditBox", "RKCD_SliceCaptionInput", RKCD_SliceHint, "InputBoxTemplate");
		RKCD_SliceCaptionInput:SetPoint("TOPLEFT", 120, -5);
		SetDimensions(RKCD_SliceCaptionInput, 240, 20);
		RKCD_SliceCaptionInput:SetAutoFocus(false);
		RKCD_SliceCaptionInput:SetFontObject(GameFontHighlight);
	local RKCD_EntryBackToDetail = CreateFrame("BUTTON", "RKCD_ShowEntryDetail", RKCD_SliceHint, "UIPanelButtonTemplate2");
		SetDimensions(RKCD_EntryBackToDetail, 130, 22); RKCD_EntryBackToDetail:SetPoint("BOTTOM", -30, 7);
	local RKCD_SliceIconLabel = RKCD_SliceHint:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		RKCD_SliceIconLabel:SetPoint("TOPLEFT", 8, -32);
	local RKCD_IconButtons = {};
	for y=0,2 do	for x=0,7 do
			local btn = CreateFrame("CheckButton", "RKCD_Icon" .. y .. "c" .. x, RKCD_SliceHint, "PopupButtonTemplate");
			btn:SetPoint("TOPLEFT", 10+x*42, -50-y*42);
			btn.icon, RKCD_IconButtons[y*8+x+1] = _G["RKCD_Icon" .. y .. "c" .. x .. "Icon"], btn;
	end end
	local RKCD_SliceIconScrollBar = CreateFrame("SLIDER", "RKCD_SliceIconScrollBar", RKCD_SliceHint, "UIPanelScrollBarTemplate");
		RKCD_SliceIconScrollBar:SetPoint("TOPLEFT", RKCD_IconButtons[8], "TOPRIGHT", 5, -14);
		RKCD_SliceIconScrollBar:SetPoint("BOTTOMLEFT", RKCD_IconButtons[#RKCD_IconButtons], "BOTTOMRIGHT", 5, 12);
		RKCD_SliceIconScrollBar.GetHeight = function() return 4; end
		RKCD_SliceIconScrollBar.up, RKCD_SliceIconScrollBar.down = RKCD_SliceIconScrollBarScrollUpButton, RKCD_SliceIconScrollBarScrollDownButton;
	local RKCD_SliceIconWheelScroller = CreateFrame("FRAME", nil, RKCD_SliceHint);
		RKCD_SliceIconWheelScroller:SetPoint("TOPLEFT", RKCD_IconButtons[1], -2, 2);
		RKCD_SliceIconWheelScroller:SetPoint("BOTTOMRIGHT", RKCD_IconButtons[#RKCD_IconButtons], 20, -2);
		RKCD_SliceIconWheelScroller:EnableMouseWheel(1);
		RKCD_SliceIconWheelScroller:SetScript("OnMouseWheel", function(self, dir)
			RKCD_SliceIconScrollBar[dir == 1 and "up" or "down"]:Click();
		end);

	local RKCD_AddEntryMenu = CreateFrame("Frame", "RKCD_AddEntryMenu", UIParent, "UIDropDownMenuTemplate");
	local RKCD_AddEntry = CreateFrame("Button", nil, ringFrame);
		SetDimensions(RKCD_AddEntry, 16);
		RKCD_AddEntry:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
		RKCD_AddEntry:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down");
		RKCD_AddEntry:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
		RKCD_AddEntry:SetPoint("TOP", RKCD_Prev, "BOTTOM", 1, -6);
	local RKCD_EntryMoveLeft = CreateFrame("BUTTON", "RKCD_MoveEntryLeft", RKCD_EntryDetail, "UIPanelButtonTemplate2");
		SetDimensions(RKCD_EntryMoveLeft, 24, 22); RKCD_EntryMoveLeft:SetID(1); RKCD_EntryMoveLeft:SetText("<");
		RKCD_EntryMoveLeft:SetPoint("BOTTOMLEFT", 10, 7);
	local RKCD_EntryMoveRight = CreateFrame("BUTTON", "RKCD_MoveEntryRight", RKCD_EntryDetail, "UIPanelButtonTemplate2");
		SetDimensions(RKCD_EntryMoveRight, 24, 22); RKCD_EntryMoveRight:SetID(3); RKCD_EntryMoveRight:SetText(">");
		RKCD_EntryMoveRight:SetPoint("LEFT", RKCD_EntryMoveLeft, "RIGHT", 3, 0);
	local RKCD_EntryAlterHint = CreateFrame("BUTTON", "RKCD_ShowHintDetail", RKCD_EntryDetail, "UIPanelButtonTemplate2");
		SetDimensions(RKCD_EntryAlterHint, 130, 22); RKCD_EntryAlterHint:SetPoint("BOTTOM", -30, 7);
	local RKCD_RemoveSlice = CreateFrame("Button", "RKCD_RemoveElement", RKCD_EntryDetail, "UIPanelButtonTemplate2,UIPanelButtonGrayTemplate");
		SetDimensions(RKCD_RemoveSlice, 120, 22); RKCD_RemoveSlice:SetPoint("BOTTOMRIGHT", -10, 7);
		RKCD_MacroBG:SetPoint("BOTTOMRIGHT", RKCD_RemoveSlice, "TOPRIGHT", 3, 3);
	local RKCD_GhostOffsetSlider = CreateFrame("Slider", "RKC_GhostOffset", RKCD_EntryDetail, "OptionsSliderTemplate");
		RKCD_GhostOffsetSlider:SetWidth(145); RKCD_GhostOffsetSlider:SetMinMaxValues(0, 2); RKCD_GhostOffsetSlider:SetValueStep(1);
		RKC_GhostOffsetText:ClearAllPoints(); RKC_GhostOffsetText:SetPoint("TOPLEFT", -170, 0);
		RKCD_GhostOffsetSlider.hi, RKCD_GhostOffsetSlider.text = RKC_GhostOffsetHigh, RKC_GhostOffsetText; RKC_GhostOffsetLow:SetText("1");

	local RKC_RingDetail = CreateFrame("Frame", "RKCD_RingFrame", RKC_InnerDetail);
		RKC_RingDetail:SetPoint("TOPLEFT");	RKC_RingDetail:SetPoint("BOTTOMRIGHT");
	local RKC_RingScopeMenu = CreateFrame("Frame", "RKC_RingScopeMenu", RKC_RingDetail, "UIDropDownMenuTemplate");
		RKC_RingScopeMenu:SetPoint("TOPLEFT", 170, -10); UIDropDownMenu_SetWidth(RKC_RingScopeMenu, 151);
		local RKC_RingScopeMenuLabel = RKC_RingScopeMenu:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
		RKC_RingScopeMenuLabel:SetPoint("TOPLEFT", RKC_RingDetail, 15, -18);
	local RKCD_Hotkey = config.createBindingButton("RKCD_Hotkey", RKC_RingDetail);
		RKCD_Hotkey:SetPoint("TOPLEFT", 185, -42); RKCD_Hotkey:SetWidth(170);
		local defaultBindingLabel = RKCD_Hotkey:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
		defaultBindingLabel:SetPoint("TOPLEFT", RKC_RingDetail, 15, -45); defaultBindingLabel:SetJustifyH("LEFT");
	local RKC_OffsetSlider = CreateFrame("Slider", "RKC_RingOffset", RKC_RingDetail, "OptionsSliderTemplate");
		RKC_OffsetSlider:SetPoint("TOPLEFT", 187, -69); RKC_OffsetSlider:SetWidth(164);
		RKC_OffsetSlider:SetMinMaxValues(0, 345); RKC_OffsetSlider:SetValueStep(15);
		RKC_RingOffsetLow:SetText("0\194\176"); RKC_RingOffsetHigh:SetText("345\194\176");
		RKC_RingOffsetText:ClearAllPoints();
		RKC_RingOffsetText:SetPoint("TOPLEFT", RKC_RingDetail, "TOPLEFT", 15, -72);

	local RKCD_RemoveRing = CreateFrame("Button", "RKCD_RemoveRing", RKC_RingDetail, "UIPanelButtonTemplate2,UIPanelButtonGrayTemplate");
		SetDimensions(RKCD_RemoveRing, 120, 22); RKCD_RemoveRing:SetPoint("BOTTOMLEFT", 15, 7);

StaticPopupDialogs["RK_NAMEPROMPT"] = {button1=TEXT(ACCEPT), button2=TEXT(CANCEL), hasEditBox=1, maxLetters=255, whileDead=1, timeout=0, hideOnEscape=true, OnHide = function() _G[this:GetName().."EditBox"]:SetText(""); end};

local RK_SelectedRing, RK_SelectedRingID, RK_ElementOffset;
local RK_cInstance, desc, RK_SelectedRingEntry, RK_SelectedRingEntryID;

local RKCD_SelectRingEntryByID;
function RKC_RingDetail.SetBinding(button, bind)
	desc.hotkey = bind;
	RKCD_Hotkey:SetText(config.bindingFormat(desc.hotkey));
end
local function RKC_SaveEditBoxState(n)
	local cf = GetCurrentKeyBoardFocus();
	if cf and ((n == cf) or ((n == nil) and (cf == RKCD_SliceCaptionInput or cf == RKCD_Name))) then
		cf:GetScript("OnEnterPressed")(cf);
		cf:ClearFocus();
	end
end
local function RKCD_ClearSelection()
	RKCD_EntryDetail:Hide();
	if RK_SelectedRingEntry then
		RK_SelectedRingEntry:SetChecked(nil);
		RK_SelectedRingEntry = nil; RK_SelectedRingEntryID = nil;
		RKCD_SpellDetail:SetText("");
	end
	RKC_RingDetail:Show();
	RKCD_SliceHint:Hide();
end
local function RKC_ClearSelection()
	RK_SelectedRing = nil; ringFrame:Hide();
	UIDropDownMenu_SetText(ringDropdown, lang("cfgRKSelectARing"));
	RKCD_ClearSelection();
	RKC_RingDetail:Hide();
end
local function RKCD_UpdateDisplay()
	RK_SelectedRingEntry = nil;
	for i=RK_ElementOffset,#desc do
		local btn, rtype, rid = RKCD_Buttons[i-RK_ElementOffset+1], desc[i].rtype, desc[i].id;
		if not btn then break; end
		btn:SetID(i);	btn.ico:SetChecked(RK_SelectedRingEntryID == i and 1 or nil);
		if RK_SelectedRingEntryID == i then RK_SelectedRingEntry = btn.ico; end
		if (rtype == "macrotext" or rtype == nil) and type(rid) == "string" then
			rtype, rid = OneRingLib.xlu.parseMacro(rid);
			if rtype == "item" and rid:match("^{{spell:[^;]*}}$") then
				rtype, rid = "spell", tonumber(rid:match("^{{spell:(%d+)"));
			elseif rtype == "spell" and OneRingLib.xlu.companionSpellCache(rid) then
				rid = select(3, GetCompanionInfo(OneRingLib.xlu.companionSpellCache(rid)));
			end
		end
		if type(desc[i].icon) == "string" then
			btn.tex:SetTexture(desc[i].icon);
		elseif rtype == "item" then
			btn.tex:SetTexture(GetItemIcon(rid) or "Interface\\Icons\\INV_Misc_QuestionMark");
		elseif rtype == "macro" then
			btn.tex:SetTexture(select(2,GetMacroInfo(rid)));
		elseif rtype == "ring" then
			btn.tex:SetTexture("Interface\\AddOns\\OPie\\gfx\\icon");
		elseif type(rid) == "number" or rtype == "spell" or rtype == "companion" then
			btn.tex:SetTexture(select(3,GetSpellInfo(rid)) or "Interface\\Icons\\INV_Misc_QuestionMark");
		elseif rtype == "equipmentset" and type(rid) == "string" and GetEquipmentSetInfoByName(rid) then
			btn.tex:SetTexture("Interface\\Icons\\" .. GetEquipmentSetInfoByName(rid));
		else
			btn.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end
		SetDesaturation(btn.tex, not ((desc[i].action and desc[i].type) or desc[i].new));
		btn.ctex:SetVertexColor(desc[i].r, desc[i].g, desc[i].b);
		btn:Show();
	end
	for i=#desc+2-RK_ElementOffset,#RKCD_Buttons do
		RKCD_Buttons[i]:Hide();
	end
	if (#desc-RK_ElementOffset+1) >= #RKCD_Buttons then
		dropInstructions:Hide();
	else
		dropInstructions:ClearAllPoints();
		dropInstructions:SetPoint("TOPRIGHT", RKCD_Buttons[#RKCD_Buttons], "TOPRIGHT", 0, -2);
		local left = #desc-RK_ElementOffset+1;
		dropInstructions:SetPoint("TOPLEFT", RKCD_Buttons[math.max(1, left)], left > 0 and "TOPRIGHT" or "TOPLEFT", 3, -2);
		dropInstructions:SetWidth(10); -- Forces wrap
		dropInstructions:Show();
	end
	RKCD_Prev[#desc <= #RKCD_Buttons and "Hide" or "Show"](RKCD_Prev);
	RKCD_Next[#desc <= #RKCD_Buttons and "Hide" or "Show"](RKCD_Next);
	RKCD_Prev[(RK_ElementOffset <= 1) and "Disable" or "Enable"](RKCD_Prev);
	RKCD_Next[(RK_ElementOffset+#RKCD_Buttons > #desc) and "Disable" or "Enable"](RKCD_Next);
	RKCD_AddEntry:Show();
end
local function RKC_SelectRing(self, cID)
	local id = RK_cInstance[cID];
	local pname = RK_cInstance[id].name or id;
	RKC_SaveEditBoxState();

	RK_SelectedRing, RK_SelectedRingID, RK_ElementOffset = id, cID, 1;
	UIDropDownMenu_SetText(ringDropdown, pname);
	RKCD_Name:SetText(pname);
	RKCD_Name:ClearFocus();
	
	RKCD_ClearSelection();

	desc = RK_cInstance[id];
	RKCD_UpdateDisplay();
	RKCD_Hotkey:SetText(config.bindingFormat(desc.hotkey));
	RKC_RingScopeMenu.update();
	RKC_OffsetSlider:SetValue(desc.offset or 0);
	RKC_RingOffsetText:SetFormattedText(lang("cfgRKRotate"), desc.offset or 0);

	ringFrame:Show();
end
function ringDropdown.menu(self, level)
	if not RK_cInstance then return; end
	local info = UIDropDownMenu_CreateInfo();
	info.func = RKC_SelectRing;
	for i, v in ipairs(RK_cInstance) do
		info.text, info.arg1, info.checked = RK_cInstance[v].name or v, i, RK_SelectedRing == v and 1 or nil;
		UIDropDownMenu_AddButton(info);
	end
end
local function RKCD_ChangeColor(self)
	local id, ctex = self:GetParent():GetID(), self:GetParent().ctex;
	local cp = ColorPickerFrame;
	cp.func, cp.previousValues, cp.hasOpacity = function(v)
		if v then
			ctex:SetVertexColor(unpack(v));
		else
			local r,g,b = cp:GetColorRGB();
			ctex:SetVertexColor(r,g,b)
		end
		desc[id].r, desc[id].g, desc[id].b = ctex:GetVertexColor();
	end, {ctex:GetVertexColor()}, false;
	cp.cancelFunc = cp.func;
	cp:SetColorRGB(ctex:GetVertexColor()); ColorSwatch:SetTexture(ctex:GetVertexColor()); cp:Show();
end
local function RKCD_InsertSlice(self, id, stype, cid, cid2)
	if stype == "item" then
		table.insert(desc, id, {id=cid, rtype="item", r=0, g=0.43, b=0.88});
	elseif stype == "companion" then
		local cID, cName, cSpellID, icon, issummoned = GetCompanionInfo(cid2, cid);
		table.insert(desc, id, {id=cSpellID, rtype="companion", r=0.54, g=0.75, b=0.83});
	elseif stype == "spell" then
		local spellId = tonumber(GetSpellLink(cid, cid2):match("spell:(%d+)"));
		local useExactRank = not (select(2, GetSpellInfo(spellId)) == select(2, GetSpellInfo((GetSpellInfo(spellId))))) or nil;
		table.insert(desc, id, {id=spellId, r=0, g=0.9, b=1, erank=useExactRank});
	elseif stype == "macro" then
		table.insert(desc, id, {id=GetMacroInfo(cid), rtype="macro", r=1, g=0.5, b=0});
	elseif stype == "macrotext" then
		table.insert(desc, id, {id=cid, rtype="macrotext", r=1, g=0.7, b=0});
	elseif stype == "ring" then
		table.insert(desc, id, {id=cid, rtype="ring", r=0.5, g=1, b=0});
	elseif stype == "equipmentset" then
		table.insert(desc, id, {id=cid, rtype=stype, r=1, g=0, b=0.7});
	else
		return false;
	end
	desc[id].new = true;
	RKCD_UpdateDisplay();
end
local function RKCD_InsertFromCursor(self, id)
	if RKCD_InsertSlice(self, id, GetCursorInfo()) ~= false then
		ClearCursor();
		RKCD_SelectRingEntryByID(id);
	end
end
local function RKCD_GetSpellDescription(exactRank, id, id2)
	local s1, r1 = GetSpellInfo(id or 0);
	local s2, r2 = GetSpellInfo(id2 or 0);
	if exactRank and r1 ~= "" and s1 then s1 = s1 .. " (" .. r1 .. ")" end
	if exactRank and r2 ~= "" and s2 then s2 = s2 .. " (" .. r2 .. ")"; end
	return lang(id2 and "cfgRKDUprankDouble" or "cfgRKDUprankSingle"):format(s1, s2);
end
local function RKCD_SelectRingEntry(self, forceSelectOnly)
	local eid = self:GetParent():GetID();
	RKC_SaveEditBoxState();
	if GetCursorInfo() and forceSelectOnly ~= true then
		RKCD_InsertFromCursor(self, eid);
	elseif RK_SelectedRingEntryID == eid and forceSelectOnly ~= true then
		return RKCD_ClearSelection();
	end
	RK_SelectedRingEntryID = eid;

	if RK_SelectedRingEntry ~= nil then
		RK_SelectedRingEntry:SetChecked(nil);
	end
	self:SetChecked(1);
	RK_SelectedRingEntry = self;

	RKCD_EntryByName:Hide();
	RKCD_MacroBG:Hide();
	RKCD_UseExactRank:Hide();
	RKCD_OnlyWhilePresent:Hide();
	RKCD_GhostOffsetSlider:Hide();

	local rtype, id, id2 = desc[eid].rtype, desc[eid].id, desc[eid].id2;
	if (rtype == "macrotext" or rtype == nil) and type(id) == "string" then
		RKCD_SpellDetail:SetText("");
		RKCD_MacroBG:Show();
		RKCD_EntryMacro:SetText(id or "");
		RKCD_MacroScroll:SetVerticalScroll(0);
	elseif rtype == nil and type(id) == "number" then
		RKCD_SpellDetail:SetText(RKCD_GetSpellDescription(desc[eid].erank, id, id2));
		RKCD_UseExactRank:SetChecked(desc[eid].erank and 1 or nil);
		RKCD_UseExactRank:Show();
	elseif rtype == "item" then
		RKCD_SpellDetail:SetFormattedText(lang("cfgRKDItem"), select(2, GetItemInfo(id)) or ("#" .. id));
		RKCD_EntryByName:Show();
		RKCD_EntryByName:SetChecked(desc[eid].byName and 1 or nil);
		RKCD_OnlyWhilePresent:Show();
	elseif rtype == "macro" then
		RKCD_SpellDetail:SetFormattedText(lang("cfgRKDMacro"), GetMacroInfo(type(id) == "string" and GetMacroIndexByName(id) or id) or id);
		RKCD_OnlyWhilePresent:Show();
	elseif rtype == "equipmentset" then
		RKCD_SpellDetail:SetFormattedText(lang("cfgRKDEquipSet"), id);
	elseif rtype == "companion" then
		RKCD_SpellDetail:SetFormattedText(lang("cfgRKDCompanion"), GetSpellInfo(id));
	elseif rtype == "ring" then
		local name, rkey, rcount = OneRingLib:GetRingInfo(id);
		RKCD_SpellDetail:SetFormattedText(name and lang("cfgRKDRing") or lang("cfgRKDRingUnknown"), id, name);
		RKCD_OnlyWhilePresent:Show();
		if name and rcount > 0 then
			RKCD_GhostOffsetSlider:SetMinMaxValues(0, rcount-1);
			RKCD_GhostOffsetSlider:SetValue(desc[eid].rotation or 0);
			RKCD_GhostOffsetSlider.hi:SetText(rcount);
			RKCD_GhostOffsetSlider.text:SetText(lang("cfgRKGhostOffset"):format((desc[eid].rotation or 0) + 1));
			RKCD_GhostOffsetSlider:Show();
		end
	end
	RKCD_EntryFastClick:SetChecked(desc[eid].fcSlice and 1 or nil);
	RKCD_OnlyWhilePresent:SetChecked(desc[eid].onlyWhilePresent and 1 or nil);

	local lastVisible = RKCD_EntryFastClick;
	if RKCD_OnlyWhilePresent:IsShown() then RKCD_OnlyWhilePresent:SetPoint("TOPLEFT", lastVisible, "BOTTOMLEFT", 0, 2); lastVisible = RKCD_OnlyWhilePresent; end
	if RKCD_EntryByName:IsShown() then RKCD_EntryByName:SetPoint("TOPLEFT", lastVisible, "BOTTOMLEFT", 0, 2); lastVisible = RKCD_EntryByName; end
	if RKCD_UseExactRank:IsShown() then RKCD_UseExactRank:SetPoint("TOPLEFT", lastVisible, "BOTTOMLEFT", 0, 2); lastVisible = RKCD_UseExactRank; end
	if RKCD_GhostOffsetSlider:IsShown() then RKCD_GhostOffsetSlider:SetPoint("TOPLEFT", lastVisible, "BOTTOMLEFT", 195, -5); lastVisible = RKCD_GhostOffsetSlider; end

	RKCD_EntryDetail:Show();
	RKC_RingDetail:Hide();
	RKCD_SliceHint:Hide();
end
local function RKCD_ButtonDrag(self)
	if GetCursorInfo() then
		RKCD_SelectRingEntry(self:GetParent().ico);
	end
end
function RKCD_SelectRingEntryByID(id)
	local bi = id-RK_ElementOffset+1;
	if not RKCD_Buttons[bi] then
		if bi <= 0 then
			RK_ElementOffset, bi = id, 1;
		else
			RK_ElementOffset, bi = math.max(1, id - #RKCD_Buttons + 1), #RKCD_Buttons;
		end
		RKCD_UpdateDisplay();
	end
	RKCD_SelectRingEntry(RKCD_Buttons[bi].ico, true);
end
local function RKCD_RemoveRingEntry(self)
	if RK_SelectedRingEntry then
		table.remove(desc, RK_SelectedRingEntryID);
		RKCD_ClearSelection();
		RKCD_UpdateDisplay();
	end
end
local function RKC_RingAuthor()
	return ("%s-%s-%s"):format(GetCVar("realmList"):match("^([^.]+)"):upper(), GetRealmName(), UnitName("player"));
end
local function RKC_DoAddNew()
	local eb = _G[this:GetParent():GetName().."EditBox"];
	local name = eb:GetText(); eb:SetText("");
	local kn = name:gsub("%s", "");
	if name == "" or kn == "" then return; end
	RK_SelectedRing = RingKeeper:GenFreeRingName(kn);
	local okay, author = pcall(RKC_RingAuthor);
	RK_cInstance[#RK_cInstance+1], RK_cInstance[RK_SelectedRing] = RK_SelectedRing, {name=name, isNewConfigRing=true, author=okay and author or nil};
	RKC_SelectRing(nil, #RK_cInstance);
	StaticPopup_Hide("RK_NAMEPROMPT");
end
local function RKC_SelectNew()
	local prompt = StaticPopupDialogs["RK_NAMEPROMPT"];
	prompt.text, prompt.OnAccept, prompt.EditBoxOnEnterPressed = lang("cfgRKNewName"), RKC_DoAddNew, RKC_DoAddNew;
	StaticPopup_Show("RK_NAMEPROMPT");
end
local function RKCD_ChangeByName(self)
	desc[RK_SelectedRingEntryID].byName = self:GetChecked() and true or nil;
end
local function RKCD_ChangeWhenPresent(self)
	desc[RK_SelectedRingEntryID].onlyWhilePresent = self:GetChecked() and true or nil;
end
local function RKCD_ChangeExactRank(self)
	local id = RK_SelectedRingEntryID;
	desc[id].erank = self:GetChecked() and true or nil;
	RK_SelectedRingEntryID = nil;
	RKCD_SelectRingEntryByID(id);
end
local function RKCD_ChangeFastClick(self)
	desc[RK_SelectedRingEntryID].fcSlice = self:GetChecked() and true or nil;
end
local function RKCD_ChangeGhostRotation(self)
	if not self:IsShown() then return; end
	local id = RK_SelectedRingEntryID;
	desc[id].rotation = self:GetValue() ~= 0 and self:GetValue() or nil;
	self.text:SetText(lang("cfgRKGhostOffset"):format(self:GetValue()));
end
local function color_UnitClass(unit, text)
	local cl, c = UnitClass(unit);
	c = RAID_CLASS_COLORS[c] or RAID_CLASS_COLORS.PRIEST;
	return ("|cff%02x%02x%02x%s|r"):format(c.r * 255, c.g*255, c.b*255, text or cl);
end
local function RKC_ChangeScope_Do(self, newScope)
	desc.limitToChar, desc.class = newScope == "me" and UnitName("player") or nil, newScope == "class" and select(2, UnitClass("player")) or nil;
	RKC_RingScopeMenu.update();
end
function RKC_RingScopeMenu.menu()
	if not desc then return; end
	local info = UIDropDownMenu_CreateInfo();
	info.func = RKC_ChangeScope_Do;
	info.text, info.arg1, info.checked = lang("cfgRKScopeAll"), "all", not (desc.limitToChar or desc.class);
	UIDropDownMenu_AddButton(info);
	info.text, info.arg1, info.checked = lang("cfgRKScopeClass"):format(color_UnitClass("player")), "class", desc.class;
	UIDropDownMenu_AddButton(info);
	info.text, info.arg1, info.checked = lang("cfgRKScopeMe"):format(color_UnitClass("player", UnitName("player"))), "me", desc.limitToChar;
	UIDropDownMenu_AddButton(info);
end
function RKC_RingScopeMenu.update()
	UIDropDownMenu_SetText(RKC_RingScopeMenu, desc.limitToChar and lang("cfgRKScopeMe"):format(color_UnitClass("player", UnitName("player"))) or
		desc.class and lang("cfgRKScopeClass"):format(color_UnitClass("player")) or lang("cfgRKScopeAll"));
end
local function RKC_ChangeRingOffset(self)
	desc.offset = self:GetValue();
	if desc.offset == 0 then desc.offset = nil; end
	RKC_RingOffsetText:SetFormattedText(lang("cfgRKRotate"), desc.offset or 0);
end
local function RKCD_ShiftDisplay(self)
	RK_ElementOffset = math.max(1, RK_ElementOffset+self:GetID()-2);
	RKCD_UpdateDisplay();
end
local function RKCD_IsOverDropZone()
	local x, y = GetCursorPosition();
	local scale, l, b, w, h = spellDropZone:GetParent():GetEffectiveScale(), spellDropZone:GetRect();
	y, x = y / scale, x / scale;
	return y <= (b+h) and y >= b and x <= (l+w) and x >= l;
end
local function RKCD_StrayClick(self)
	if RKCD_IsOverDropZone() and GetCursorInfo() then
		RKCD_InsertFromCursor(self, #desc+1);
	end
end
local function RKCD_NameSet(self, key)
	if self:GetText():gsub("%s", "") == "" then return; end
	desc.name = self:GetText();
	self:ClearFocus();
end
local function RKCD_NameForget(self)
	self:SetText(desc.name or RK_SelectedRing);
	self:ClearFocus();
end
local function RKCD_SaveRing(rid, saveOnly)
	if rid == -1 then
		RKCD_SaveNewRing(desc.name:gsub("%s", ""));
		rid = #RK_cInstance;
	end
	local rdesc, ringName = RK_cInstance[RK_cInstance[rid]], RK_cInstance[rid];
	for _, r in pairs(rdesc) do if type(r) == "table" then r.new = nil; end end
	if rdesc.isNewConfigRing then
		rdesc.isNewConfigRing, rdesc.save = nil, true;
		RingKeeper:AddRing(ringName, rdesc);
	elseif ringName then
		RingKeeper:ModifyRing(ringName, rdesc);
	end
	RKCD_EntryMacro:ClearFocus();
	if saveOnly ~= true then
		RK_cInstance[ringName] = RingKeeper:GetRingDescription(ringName);
		if RK_SelectedRing == ringName then
			desc = RK_cInstance[ringName];
		end
		RKCD_UpdateDisplay();
	end
end
local function RKCD_DeleteRing(self)
	if RK_SelectedRing then
		RK_cInstance[RK_SelectedRing] = "remove";
		table.remove(RK_cInstance, RK_SelectedRingID);
		RKC_ClearSelection();
	end
end
local function RKCD_MacroTextEdit(self)
	desc[RK_SelectedRingEntryID].id = self:GetText();
end
local function RKCD_AddEntry_OpenSpellbook()
	ToggleSpellBook(BOOKTYPE_SPELL);
end
local function RKCD_AddEntry_Do(self, ...)
	RKCD_InsertSlice(self, RK_ElementOffset or 1, ...);
	HideDropDownMenu(1);
	RKCD_SelectRingEntryByID(RK_ElementOffset or 1);
end
local function RKCD_AddEntry_Menu(self, level)
	local info = UIDropDownMenu_CreateInfo();
	if level == 1 then
		info.text, info.arg1, info.arg2, info.func = lang("cfgRKDCustomMacro"), "macrotext", "", RKCD_AddEntry_Do;
		UIDropDownMenu_AddButton(info);
		info.text, info.hasArrow, info.value = lang("cfgRKSubring"), true, "rings";
		UIDropDownMenu_AddButton(info);
		if GetNumEquipmentSets() > 0 then
			info.text, info.hasArrow, info.value = lang("cfgRKEquipmentSets"), true, "equip";
			UIDropDownMenu_AddButton(info);
		end
		info.text, info.hasArrow, info.value = lang("cfgRKOpenStuff"), true, "open";
		UIDropDownMenu_AddButton(info);
	elseif UIDROPDOWNMENU_MENU_VALUE == "equip" then
		info.func, info.arg1 = RKCD_AddEntry_Do, "equipmentset";
		for i=1,GetNumEquipmentSets() do
			info.text, info.arg2 = GetEquipmentSetInfo(i), GetEquipmentSetInfo(i);
			UIDropDownMenu_AddButton(info, 2);
		end
	elseif UIDROPDOWNMENU_MENU_VALUE == "rings" then
		info.func, info.arg1 = RKCD_AddEntry_Do, "ring";
		for i=1, OneRingLib:GetNumRings() do
			info.text, info.arg2 = OneRingLib:GetRingInfo(i);
			UIDropDownMenu_AddButton(info,2);
		end
	elseif UIDROPDOWNMENU_MENU_VALUE == "open" then
		info.text, info.func, info.arg1, info.arg2 = lang("cfgRKOpenSpellBook"), RKCD_AddEntry_OpenSpellbook;
		UIDropDownMenu_AddButton(info,2);
		info.text, info.func = lang("cfgRKOpenMacros"), ShowMacroFrame;
		UIDropDownMenu_AddButton(info,2);
		info.text, info.func = lang("cfgRKOpenBags"), OpenAllBags;
		UIDropDownMenu_AddButton(info,2);
	end
end
local function RKCD_EntryMove(self)
	local dir, sel = self:GetID()-2, RK_SelectedRingEntryID;
	if desc[sel + dir] then
		desc[sel + dir], desc[sel] = desc[sel], desc[sel+dir];
		RK_SelectedRingEntryID = sel + dir;
		RKCD_UpdateDisplay();
	end
end
local droppableTypes = {spell=true,item=true,companion=true,macro=true,equipmentset=true};
local function RKC_DropZoneUpdate(event)
	local type = GetCursorInfo();
	if droppableTypes[type] then
		spellDropZone:Show();
		local isOver = RKCD_IsOverDropZone();
		if isOver ~= spellDropZone.isOver then
			spellDropZone.isOver = isOver;
			spellDropZone:SetVertexColor(isOver and 0.4 or 1, 1.0, isOver and 0 or 1, isOver and 0.35 or 0.15);
		end
	else
		spellDropZone:Hide();
	end
end
do -- Hook linking for edit box
	local O_ChatEdit_InsertLink = ChatEdit_InsertLink;
	function ChatEdit_InsertLink(link, ...)
		if GetCurrentKeyBoardFocus() == RKCD_EntryMacro then
			if link:match("item:") then
				if isEmpty then
					RKCD_EntryMacro:Insert((GetItemSpell(link) and SLASH_USE1 or SLASH_EQUIP1) .. " " .. GetItemInfo(link));
				else
					RKCD_EntryMacro:Insert(" " .. GetItemInfo(link));
				end
			elseif link:match("spell:") and not IsPassiveSpell((GetSpellInfo(link:match("spell:(%d+)")))) then
				RKCD_EntryMacro:Insert((isEmpty and SLASH_CAST1 or "") .. " " .. GetSpellInfo(link:match("spell:(%d+)")));
			else
				RKCD_EntryMacro:Insert(link);
			end
			return true;
		else
			return O_ChatEdit_InsertLink(link, ...);
		end
	end
end

-- Action Hinting
local function RKC_PopHintList(ofs)
	local offset = type(ofs) == "number" and ofs or (RKCD_SliceIconScrollBar:GetValue()*8+1);
	local numIcons, sliceIcon = GetNumMacroIcons(), desc[RK_SelectedRingEntryID].icon;
	local lastIconOffset = numIcons-#RKCD_IconButtons+1;
	offset = math.min(math.max(1, offset or 1), lastIconOffset);
	for j=offset,numIcons do
		local btn, ico = RKCD_IconButtons[j-offset+1], GetMacroIconInfo(j);
		if not btn then break; end
		btn.icon:SetTexture(ico);
		btn:SetChecked(ico == sliceIcon);
	end
	RKCD_SliceIconScrollBar:SetMinMaxValues(0, math.ceil(numIcons/8 - 3));
	RKCD_SliceIconScrollBar.up[offset == 1 and "Disable" or "Enable"](RKCD_SliceIconScrollBar.up);
	RKCD_SliceIconScrollBar.down[offset == lastIconOffset and "Disable" or "Enable"](RKCD_SliceIconScrollBar.down);
end
local function RKC_HintIconSet(self)
	desc[RK_SelectedRingEntryID].icon = self:GetChecked() and self.icon:GetTexture() or nil;
	if self:GetChecked() then
		for k,v in pairs(RKCD_IconButtons) do
			v:SetChecked(v == self or nil);
		end
	end
end
local function RKC_HintCaptionSave(self)
	local text = self:GetText();
	desc[RK_SelectedRingEntryID].caption = text ~= "" and text or nil;
	self:ClearFocus();
end
local function RKC_HintCaptionRestore(self)
	self:SetText(desc[RK_SelectedRingEntryID].caption or "");
	self:ClearFocus();
end
local function RKC_ShowHintConfig(self)
	RKCD_SliceHint:Show();
	RKCD_SliceCaptionInput:SetText(desc[RK_SelectedRingEntryID].caption or "");
	self:GetParent():Hide();
	local offset, icon = 0, desc[RK_SelectedRingEntryID].icon;
	if icon then
		for i=1,GetNumMacroIcons() do
			if GetMacroIconInfo(i) == icon then
				offset = 1 + i - (i % 8);
				break;
			end
		end
	end
	RKC_PopHintList(offset);
	RKCD_SliceIconScrollBar:SetValue(math.floor(offset/8));
end
local function RKC_ReturnToEntryDetail(self)
	RKC_SaveEditBoxState(RKCD_SliceCaptionInput);
	RKCD_SliceHint:Hide();
	RKCD_EntryDetail:Show();
end

local function RKC_CopyConfig()
	if RK_cInstance == nil then
		RK_cInstance = {};
		for i=1,RingKeeper:GetManagedRings() do
			local index, name, active = RingKeeper:GetManagedRingName(i);
			if active then
				table.insert(RK_cInstance, index);
				RK_cInstance[index] = RingKeeper:GetRingDescription(index);
			end
		end
	end
end
function configPanel.refresh()
	if not configPanel:IsShown() then return; end
	RK_SelectedRing = nil; ringFrame:Hide();
	configPanel.version:SetFormattedText("%d.%d", RingKeeper:GetVersion());
	configPanel.desc:SetText(lang("cfgRKIntro"));
	RKCD_RemoveSlice:SetText(lang("cfgRKDRemove"));
	btnNewRing:SetText(lang("cfgRKNewRing"));
	RKCD_RemoveRing:SetText(lang("cfgRKDRemoveRing"));
	dropInstructions:SetText(lang("cfgRKDropInstructions"));
	RKCD_EntryByNameText:SetText(lang("cfgRKDByName"));
	RKCD_EntryFastClickText:SetText(lang("cfgRKFastClickSlice"));
	RKCD_OnlyWhilePresentText:SetText(lang("cfgRKDWhilePresent"));
	RKCD_ExactRankText:SetText(lang("cfgRKDExactRank"));
	RKCD_SliceCaption:SetText(lang("cfgRKSliceCaption"));
	RKCD_EntryAlterHint:SetText(lang("cfgRKModifyHint"));
	RKCD_EntryBackToDetail:SetText(lang("cfgRKBackToDetail"));
	defaultBindingLabel:SetText(lang("cfgRKDefaultBinding"));
	RKCD_Name.hintLabel:SetText(lang("cfgRKClickToEdit"));
	RKCD_SliceIconLabel:SetText(lang("cfgRKSliceIcon"));
	RKC_RingScopeMenuLabel:SetText(lang("cfgRKScope"));
	configPanel.name = lang("cfgRKTitle");
	configPanel.title:SetText(configPanel.name);
	RKC_ClearSelection();
	RKC_CopyConfig();
end
function configPanel.cancel()
	RK_cInstance = nil; -- and the rest will follow.
end
function configPanel.okay()
	for i, v in ipairs(RK_cInstance) do
		RKCD_SaveRing(i, true);
		RK_cInstance[v] = nil;
	end
	for k, v in pairs(RK_cInstance) do
		if type(k) == "string" and v == "remove" then
			RingKeeper:RemoveRing(k);
		end
	end
	RK_cInstance = nil;
end
function configPanel.default()
	RingKeeper:RestoreDefaults();
	RK_cInstance = nil;
end

local function RKC_AdjustOptionsPosition(self)
	local r = InterfaceOptionsFrame:IsVisible() and configPanel:IsVisible() and math.max(SpellBookFrame:IsVisible() and SpellBookFrame:GetRight() or 0, MacroFrame and MacroFrame:IsVisible() and MacroFrame:GetRight() or 0) or 0;
	if not InterfaceOptionsFrame:IsUserPlaced() then
		local tdiff = (InterfaceOptionsFrame:GetWidth() - UIParent:GetWidth())/2 + r+5;
		InterfaceOptionsFrame:ClearAllPoints();
		InterfaceOptionsFrame:SetPoint("CENTER", math.max(tdiff, 0), 0);
	end
end
local function RKC_MacroListen(event, addon)
	if event == "ADDON_LOADED" and MacroFrame and MacroFrame.HookScript then
		MacroFrame:HookScript("OnShow", RKC_AdjustOptionsPosition);
		MacroFrame:HookScript("OnHide", RKC_AdjustOptionsPosition);
		return "remove";
	end
end

configPanel:HookScript("OnShow", RKC_AdjustOptionsPosition);
configPanel:SetScript("OnHide", RKC_AdjustOptionsPosition);
UIDropDownMenu_Initialize(ringDropdown, ringDropdown.menu);
RKCD_Name:SetScript("OnEscapePressed", RKCD_NameForget);
RKCD_Name:SetScript("OnEnterPressed", RKCD_NameSet);
RKCD_Prev:SetScript("OnClick", RKCD_ShiftDisplay);
RKCD_Next:SetScript("OnClick", RKCD_ShiftDisplay);
for k, v in ipairs(RKCD_Buttons) do
	v.color:SetScript("OnClick", RKCD_ChangeColor);
	v.ico:SetScript("OnClick", RKCD_SelectRingEntry);
	v.ico:SetScript("OnReceiveDrag", RKCD_ButtonDrag);
	v.color:SetScript("OnReceiveDrag", RKCD_ButtonDrag);
end
ringFrame:SetScript("OnMouseDown", RKCD_StrayClick);
ringFrame:SetScript("OnReceiveDrag", RKCD_StrayClick);
ringFrame:EnableMouse(true);
RKCD_RemoveSlice:SetScript("OnClick", RKCD_RemoveRingEntry);
RKCD_RemoveRing:SetScript("OnClick", RKCD_DeleteRing);
SpellBookFrame:HookScript("OnShow", RKC_AdjustOptionsPosition);
SpellBookFrame:HookScript("OnHide", RKC_AdjustOptionsPosition);
RKCD_EntryByName:SetScript("OnClick", RKCD_ChangeByName);
RKCD_EntryFastClick:SetScript("OnClick", RKCD_ChangeFastClick);
RKCD_OnlyWhilePresent:SetScript("OnClick", RKCD_ChangeWhenPresent);
RKCD_UseExactRank:SetScript("OnClick", RKCD_ChangeExactRank);
UIDropDownMenu_Initialize(RKCD_AddEntryMenu, RKCD_AddEntry_Menu, "MENU");
UIDropDownMenu_Initialize(RKC_RingScopeMenu, RKC_RingScopeMenu.menu);
RKCD_AddEntry:SetScript("OnClick", function() ToggleDropDownMenu(1, nil, RKCD_AddEntryMenu, "cursor"); end);
RKCD_EntryMacro:SetScript("OnEscapePressed", function(self) self:ClearFocus() end);
RKCD_EntryMacro:SetScript("OnTextChanged", RKCD_MacroTextEdit);
RKCD_EntryMoveLeft:SetScript("OnClick", RKCD_EntryMove);
RKCD_EntryMoveRight:SetScript("OnClick", RKCD_EntryMove);
RKC_OffsetSlider:SetScript("OnValueChanged", RKC_ChangeRingOffset);
btnNewRing:SetScript("OnClick", RKC_SelectNew);
RKCD_EntryAlterHint:SetScript("OnClick", RKC_ShowHintConfig);
RKCD_SliceIconScrollBar:SetScript("OnValueChanged", RKC_PopHintList);
RKCD_SliceCaptionInput:SetScript("OnEnterPressed", RKC_HintCaptionSave);
RKCD_SliceCaptionInput:SetScript("OnEscapePressed", RKC_HintCaptionRestore);
RKCD_EntryBackToDetail:SetScript("OnClick", RKC_ReturnToEntryDetail);
RKCD_GhostOffsetSlider:SetScript("OnValueChanged", RKCD_ChangeGhostRotation);
for i, b in pairs(RKCD_IconButtons) do b:SetScript("OnClick", RKC_HintIconSet); end
EC_Register("ADDON_LOADED", "RKC.MacroListen", RKC_MacroListen);
ringFrame:SetScript("OnUpdate", RKC_DropZoneUpdate);

SLASH_RINGKEEPER1, SLASH_RINGKEEPER2 = "/ringkeeper", "/rk";
SlashCmdList["RINGKEEPER"] = function (args)
	if not configPanel:IsVisible() then
		InterfaceOptionsFrame_OpenToCategory(configPanel);
	end
end

do -- Allow interface elements to be shown concurrently with the config panel
	local fenv, lastFrame = setmetatable({}, {__index=_G});
	_G["RKC-ForceShow"] = function (frame)
		if configPanel:IsVisible() and not InCombatLockdown() then
			if lastFrame and lastFrame:IsShown() then lastFrame:Hide(); end
			frame:SetPoint("LEFT", 50, 0);
			frame:Show(); frame:Raise();
			lastFrame = frame;
		end
	end
	configPanel:SetScript("OnHide", function()
		if lastFrame and lastFrame:IsVisible() and not InCombatLockdown() then
			lastFrame:Hide(); lastFrame = nil;
		end
	end);
	EC_Register("ADDON_LOADED", "RKC.HookMacro", function(e, a)
		if a == "Blizzard_MacroUI" then
			MacroFrame:SetAttribute("UIPanelLayout-showFailedFunc", "RKC-ForceShow");
			return "remove";
		end
	end);
	function fenv.IsOptionFrameOpen()
		return (not configPanel:IsVisible()) and IsOptionFrameOpen() or false;
	end
	pcall(setfenv, ToggleBag, fenv);
	pcall(setfenv, ToggleBackpack, fenv);
	SpellBookFrame:SetAttribute("UIPanelLayout-showFailedFunc", "RKC-ForceShow");
	CharacterFrame:SetAttribute("UIPanelLayout-showFailedFunc", "RKC-ForceShow");
end