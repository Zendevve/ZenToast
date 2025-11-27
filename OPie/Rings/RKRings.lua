local RingKeeper = type(OneRingLib) == "table" and type(OneRingLib.RingKeeper) == "table" and OneRingLib.RingKeeper or false;
if not (RingKeeper and RingKeeper.AddRing) then return; end

RingKeeper:AddRing("DruidShift", {
	{c="cc66ff", id=24858}, -- Moonkin
	{c="4cff66", id=33891}, -- Tree
	{c="ff4c4c", id=5487, id2=9634}, -- Bear
	{c="33b2ff", rtype="macrotext", id="#rkrequire {{spell:40120/33943/1066/783}}\n/cancelform [noflyable]\n/cast [flyable,outdoors,nocombat,noswimming,nomod][flying] {{spell:40120/33943}}; [swimming] {{spell:1066}}; [outdoors] {{spell:783}}"}, -- Travel
	{c="ffff00", id=768}, -- Cat
	name="Druid Shapeshifting", hotkey="BUTTON4", class="DRUID", version=3
});
RingKeeper:AddRing("DruidUtility", {
	{c="117aed", id=29166}, -- innervate
	{c="dd002b", id="/cast [combat][mod] {{spell:20484}}; {{spell:50763}}"}, -- rebirth/revive
	{c="e8a50f", id=22812}, -- bark
	{c="9919e5", id=18960}, -- moonglade
	name="Utility", hotkey="BUTTON5", class="DRUID", version=2
});
RingKeeper:AddRing("HunterAspects", {
	{c="997f2d", id=13163}, -- monkey
	{c="35b58e", id=13165}, -- hawk
	{c="ba6802", id=5118}, -- cheetah
	{c="ffb200", id=13159}, -- pack
	{c="96003d", id=13161}, -- beast
	{c="96ff14", id=20043}, -- wild
	{c="1933cc", id=34074}, -- viper
	name="Aspects", hotkey="BUTTON4", class="HUNTER"
});
RingKeeper:AddRing("HunterTraps", {
	{c="4ca0ff", id=13809}, -- frost
	{c="e57505", id=13795}, -- immo
	{c="4416f7", id=1499}, -- freeze
	{c="4cff00", id=34600}, -- snake
	{c="c15100", id=13813}, -- explo
	name="Traps", hotkey="BUTTON5", class="HUNTER"
});
RingKeeper:AddRing("MageArmor", {
	{c="f97200", id=30482}, -- molten
	{c="1966ff", id=168, id2=7302}, -- ice
	{c="7fe5e5", id=6117}, -- mage
	name="Armor spells", hotkey="ALT-A", class="MAGE"
});
RingKeeper:AddRing("MageShields", {
	{c="66ccff", id=1463}, -- mana
	{c="0066ff", id=6143}, -- frost
	{c="7f4cff", id=45438}, -- block;
	{c="33ffcc", id=11426}, -- ice
	{c="ff6633", id=543}, -- fire
	name="Mage Shields", hotkey="BUTTON4", class="MAGE"
});
do -- MageTravel
	local m = "/cast [nomod] {{spell:%s}}; {{spell:%s}}";
	RingKeeper:AddRing("MageTravel", {
		{c="64bbce", id=m:format(53140, 53142)}, -- Dalaran
		{c="77e0c4", id=m:format(33690, "35717/33691")}, -- Shattrath
		{c="8cb73d", id=m:format(3561, 10059)}, -- Stormwind
		{c="a826e0", id=m:format(3565, 11419)}, -- Darnassus
		{c="70a5b2", id=m:format(3566, 11420)}, -- Thunder Bluff
		{c="77e51e", id=m:format(3563, 11418)}, -- Undercity
		{c="68a8d1", id=m:format(3562, 11416)}, -- Ironforge
		{c="e87c21", id=m:format(3567, 11417)}, -- Orgrimmar
		{c="426ba5", id=m:format(49359, 49360)}, -- Theramore
		{c="72721e", id=m:format(49358, 49361)}, -- Stonard
		{c="7cc6f9", id=m:format(32272, 32267)}, -- Silvermoon
		{c="e89bd1", id=m:format(32271, 32266)}, -- Exodar
	  name="Mage Travel", hotkey="BUTTON5", class="MAGE", version=3
	});
end
RingKeeper:AddRing("PaladinAuras", {
	{c="b8a671", id=465}, -- devotion
	{c="493ad3", id=19746}, -- concentration
	{c="2d7fcc", id=19888}, -- frost
	{c="ffffa5", id=32223}, -- crusader
	{c="2602d6", id=19876}, -- shadow
	{c="e0b207", id=19891}, -- fire
	{c="9e5bc6", id=7294}, -- retribution
	name="Paladin Auras", hotkey="BUTTON4", class="PALADIN", version=2
});
RingKeeper:AddRing("ShamanWeapons", {
	{c="8cbff2", id=8232}, -- windfury
	{c="ff8419", id=8024}, -- flametongue
	{c="adff4c", id=8017}, -- rockbiter
	{c="3570ff", id=8033}, -- frostbrand
	name="Weapon Buffs", hotkey="BUTTON5", class="SHAMAN"
});
RingKeeper:AddRing("WarlockDemons", {
	{c="ec3923", id=30146}, -- felguard
	{c="771ed8", id=697}, -- void
	{c="f7380f", id=688}, -- imp
	{c="ff33b2", id=712}, -- succubus
	{c="1966cc", id=691}, -- felhunter
	name="Warlock Demons", class="WARLOCK", hotkey="BUTTON4"
});
RingKeeper:AddRing("WarlockStones", {
	{c="66ff0c", id=6201}, -- health
	{c="b20ce5", id=693}, -- soul
	{c="d872ff", id=29893}, -- ritual
	{c="ff7f00", id=6366}, -- fire
	{c="0033ff", id=2362}, -- spell
	name="Stones", hotkey="BUTTON5", class="WARLOCK"
});
RingKeeper:AddRing("WarriorStances", {
	{c="ff4c4c", id=2457},
	{c="4c4cff", id=71},
	{c="ffcc4c", id=2458},
	name="Warrior Stances", hotkey="BUTTON4", class="WARRIOR", version=2
});
RingKeeper:AddRing("DeathKnightPresence", {
	{c="52ff5a", id="/cast [help,dead] {{spell:61999}}; [nopet,nomounted][target=pet,dead] {{spell:46584}}; [target=pet,nodead,exists][] {{spell:49895}}"}, -- ghoul
	{c="e54c19", id=48266}, -- blood
	{c="1999e5", id=48263}, -- frost
	{c="4ce519", id=48265}, -- unholy
	{c="a93ae8", id=50977}, -- gate
	{c="E8C682", id="/cast [flyable,outdoors][flying] {{spell:54729}}; {{spell:48778}}"},
	{c="63eaff", id=3714}, -- path of frost
	name="Death Knight Presence", hotkey="BUTTON4", class="DEATHKNIGHT",version=3
});
RingKeeper:AddRing("DKCombat", {
	{c="fff4b2", id=57623}, -- horn
	{c="5891ea", id=48792}, -- fortitude
	{c="bcf800", id=48707}, -- shell
	{c="3d63cc", id=51052}, -- Zone
	{c="995ffe", id=49222}, -- shield
	{c="b31500", id=55233}, -- blood
	{c="ffeac4", id=51271}, -- armor
	{c="d0d0d0", id=49039}, -- lich
	name="Death Knight Combat", hotkey="BUTTON5", class="DEATHKNIGHT",version=2
});
RingKeeper:AddRing("CommonTrades", {
	{c="d8d1ad", id=3908, id2=51309}, -- tailoring
	{c="b57f49", id=2108, id2=51302}, -- leatherworking
	{c="f4aa0f", id=2018, id2=51300}, -- blacksmithing
	{c="3319e5", id=25229, id2=51311}, -- jewelcrafting
	{c="f4ef28", id=7411, id2=51313}, -- enchanting
	{c="11ba9b", id=2259, id2=51304}, -- alchemy
	{c="c13f0f", id=2550, id2=51296}, -- cooking
	{c="85de60", id=45357, id2=45363}, -- inscription
	{c="bf2626", id=3273, id2=45542}, -- first aid
	{c="e6b725", id=4036, id2=51306}, -- engineering
	{c="ffac3d", id=2656}, -- smelting
	name="Trade Skills", hotkey="ALT-T", version=4
});