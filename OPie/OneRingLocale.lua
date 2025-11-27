local ADDON_NAME = "OPie";
local assert = OneRingLib.xlu.assert;

local lockedLocales, desiredLocale, localeTables, localeCache, lang = {}, GetLocale(), {}, {}, {};
function lang:GetLocale()
	return desiredLocale;
end
function lang:SetLocale(locale)
	assert(type(locale) == "string", "Usage: OneRingLang:SetLocale(\"locale\");", 2);
	if desiredLocale ~= locale then
		desiredLocale, OPie_Locale, localeCache = locale, locale, {};
	end
end
function lang:GetString(token, format)
	assert(type(token) == "string" and (format == nil or type(format) == "string"), "Usage: OneRingLang:GetString(\"token\"[, \"format\"]);", 2);
	if not localeCache[token] then
		localeCache[token] = localeTables[desiredLocale] and localeTables[desiredLocale][token] or localeTables.enUS[token] or ("#" .. token .. "#");
	end
	return format and format:format(localeCache[token]) or localeCache[token];
end
function lang:AddLocalization(lang, data, lock)
	assert(type(lang) == "string" and type(data) == "table", "Usage: OneRingLang:AddLocalization(\"locale\", localizationTable)", 2);
	assert(not lockedLocales[lang], "Locale %q is already available and locked.", 2, lang);
	localeTables[lang], lockedLocales[lang] = data, lock == true;
end
EC_Register("ADDON_LOADED", "OPie.Locale.Loaded", function(e, a)
	if a == ADDON_NAME and type(OPie_Locale) == "string" and localeTables[OPie_Locale] then
		lang:SetLocale(OPie_Locale);
	end
end);
setmetatable(lang, {__call=lang.GetString});
OneRingLib.lang = lang;

--[[
	Official enUS locale follows.

	Localization should be handled through downloadable, third-party plug-ins.
	If you're a localization author, see http://www.go-hero.net/opie/api/localize for a description and instructions.
]]
lang:AddLocalization("enUS", {
	title="OPie",
	locale="English",
	BindingName="An OPie ring",

	cfgMainIntro="Customize indication options; right click on a checkbox to set to default (or global) value.",
	cfgGlobalDomain="Defaults for all rings",
	cfgDomain="Alter options for:",
	cfgRingDomain="Ring: |cffaaffff%s|r (%d entries)",
	cfgProfile="Profile: %s",
	cfgProfileNew="Create a new profile",
	cfgProfileDel="Delete current profile",
	cfgProfileName="New profile name:",
	cfgRingAtMouse="Center rings at mouse",
	cfgHeaderBehavior="Ring behavior",
	cfgHeaderIndication="Indication elements",
	cfgHeaderAnimation="Animations",
	cfgShowCenterIcon="Center icon",
	cfgShowCenterCaption="Center caption",
	cfgShowCooldowns="Numeric cooldowns",
	cfgMultiIndication="Per-slice icons",
	cfgIndication="Indication elements",
	cfgClickActivation="Activate on left click",
	cfgHideStanceBar="Hide stance bar",
	cfgIndicationOffset="Position offset:",
	cfgRingScale="Ring Scale |cffffd500(%0.1f)|r",
	cfgUseGameTooltip="Show tooltips",
	cfgClickPriority="Make rings top-most",
	cfgGhostMIRings="Nested rings",
	cfgMouseBucket="Scroll wheel sensitivity",
	cfgNoClose="Leave open after use",
	cfgSliceBinding="Bind numeric keys to slices",
	cfgShowKeys="Show slice bindings",
	cfgUseBF="Use ButtonFacade",
	cfgColorBF="Color BF slices",

	cfgMIScale="Animate slice scale",
	cfgMIDisjoint="Animate scale separately",
	cfgXTScaleSpeed="Scale animation speed",
	cfgXTPointerSpeed="Pointer rotation speed",
	cfgXTZoomTime="Zoom-in/out time |cffffd500(%.1f sec)|r",
	cfgCenterAction="Quick action at ring center",

	cfgBindingTitle="Ring Bindings",
	cfgBindingIntro="Customize OPie key bindings below. |cffa0a0a0Gray|r and |cffFA2800red|r bindings conflict with others and are not currently bound. " ..
		"Alt+Left Click on a button to set a conditional binding, indicated by |cff4CFF40[+]|r.",
	cfgBinding="Binding",
	cfgNoBinding="Not bound",
	cfgBindingCond="|cff4CFF40[+] |r%s%s",
	cfgBindingMacro="Use the following command to open |cffFFD029%s|r ring in macros:",
	cfgBindingThis="this",
	cfgName="Ring",
	bndRingName="%s |cffa0a0a0(%d)|r",
	cfgUnbind="Unbind Ring",
	cfgBindConditionalExplain="F.ex. |cff4CFF40[combat] ALT-C; CTRL-F|r. Press ENTER to save.",

	cfgRKTitle="Custom Rings",
	cfgRKIntro="Create, modify and share rings containing abilities, items and macros.",
	cfgRKSelectARing="Select a ring",
	cfgRKNewRing="Create new ring",
	cfgRKNewName="New ring name:",
	cfgRKDRemove="Delete slice",
	cfgRKDRemoveRing="Delete ring",
	cfgRKDUprankSingle="Spell: |cff0077ff%s|r",
	cfgRKDUprankDouble="Spell: |cff0077ff%s|r or |cff0077ff%s|r",
	cfgRKDItem="Item: %s",
	cfgRKDMacro="Macro: %s",
	cfgRKDCompanion="Companion: |cff77aaff%s|r",
	cfgRKDCustomMacro="Add a custom macro slice",
	cfgRKDCMacro="Custom macro",
	cfgRKDEquipSet="Equipment set: |cffe040ff%s|r",
	cfgRKDropInstructions="Drop items, abilities, or macros here to add them to the ring.",
	cfgRKDByName="Also use items with the same name",
	cfgRKDExactRank="Use specified rank instead of max rank",
	cfgRKRotate="Ring rotation |cffffd500(%d\194\176)|r:",
	cfgRKScope="Make this ring available to:",
	cfgRKScopeAll="All characters",
	cfgRKScopeClass="All %s characters",
	cfgRKScopeMe="Only %s",
	cfgRKSliceCaption="Slice caption:",
	cfgRKModifyHint="Set text/icon",
	cfgRKBackToDetail="View slice detail",
	cfgRKDWhilePresent="Show this slice only while its object is present",
	cfgRKFastClickSlice="Allow this slice to be used as the ring's quick action",
	cfgRKSubring="Add a sub-ring slice",
	cfgRKDRing="Sub-ring: |cffD278FF%2$s|r",
	cfgRKDRingUnknown="Unknown sub-ring: |cffD278FF%s|r",
	cfgRKDefaultBinding="Default ring binding:",
	cfgRKClickToEdit="(click to edit)",
	cfgRKGhostOffset="Default slice |cffffd500(%d)|r:",
	cfgRKOpenStuff="Open UI Panels",
	cfgRKOpenSpellBook="Spellbook",
	cfgRKOpenMacros="Macro editor",
	cfgRKOpenBags="Bags",
	cfgRKEquipmentSets="Add an equipment set slice",
	cfgRKSliceIcon="Slice icon: |cffffffff(based on slice action when none are selected)|r",
}, true);