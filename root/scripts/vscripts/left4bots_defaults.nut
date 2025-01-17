::Left4Bots.DefaultConfigFiles <- function ()
{
	local defaults = {};
	
	// -------------------------------------------------------
	
	// Default settings overrides for 'Advanced' difficulty
	defaults["left4bots2/cfg/settings_hard.txt"] <- @"close_saferoom_door_highres = 1
heal_interrupt_minhealth = 40
horde_nades_chance = 35
jockey_redirect_damage = 45
manual_attack_common_head_radius = 300
manual_attack_dual_pistol_nerf = 1
manual_attack_mindot = 0.65
manual_attack_special_head_radius = 300
manual_attack_wandering = 0
shove_deadstop_chance = 100
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 250";
	
	// Default settings overrides for 'Expert' difficulty
	defaults["left4bots2/cfg/settings_impossible.txt"] <- @"automation_autostart = 0
close_saferoom_door_all_chance = 0
close_saferoom_door_highres = 1
heal_interrupt_minhealth = 30
horde_nades_chance = 35
jockey_redirect_damage = 50
manual_attack_always = 1
manual_attack_common_head_radius = 450
manual_attack_dual_pistol_nerf = 0
manual_attack_mindot = 0.6
manual_attack_special_head_radius = 400
manual_attack_wandering = 1
scavenge_max_bots = 1
shove_deadstop_chance = 100
signal_chat = 1
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 260
witch_autocrown = 0";
	
	// -------------------------------------------------------
	
	// Default settings overrides for 'c1m4_atrium' in 'Advanced' difficulty
	defaults["left4bots2/cfg/settings_c1m4_atrium_hard.txt"] <- @"close_saferoom_door_highres = 1
heal_interrupt_minhealth = 40
horde_nades_chance = 35
jockey_redirect_damage = 45
manual_attack_common_head_radius = 300
manual_attack_dual_pistol_nerf = 1
manual_attack_mindot = 0.65
manual_attack_special_head_radius = 300
manual_attack_wandering = 0
shove_deadstop_chance = 100
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 250
throw_molotov = 0";
	
	// Default settings overrides for 'c1m4_atrium' in 'Expert' difficulty
	defaults["left4bots2/cfg/settings_c1m4_atrium_impossible.txt"] <- @"automation_autostart = 0
close_saferoom_door_all_chance = 0
close_saferoom_door_highres = 1
heal_interrupt_minhealth = 30
horde_nades_chance = 35
jockey_redirect_damage = 50
manual_attack_always = 1
manual_attack_common_head_radius = 450
manual_attack_dual_pistol_nerf = 0
manual_attack_mindot = 0.6
manual_attack_special_head_radius = 400
manual_attack_wandering = 1
scavenge_max_bots = 1
shove_deadstop_chance = 100
signal_chat = 1
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 260
throw_molotov = 0
witch_autocrown = 0";
	
	// Default settings overrides for 'c1m4_atrium' in the other difficulties
	defaults["left4bots2/cfg/settings_c1m4_atrium.txt"] <- @"throw_molotov = 0";
	
	// -------------------------------------------------------
	
	// Default settings overrides for 'c6m1_riverbank'
	defaults["left4bots2/cfg/settings_c6m1_riverbank.txt"] <- @"handle_l4d1_survivors = 1";
	
	// Default settings overrides for 'c6m2_bedlam'
	defaults["left4bots2/cfg/settings_c6m2_bedlam.txt"] <- @"handle_l4d1_survivors = 1";
	
	// Default settings overrides for 'c6m3_port' in 'Advanced' difficulty
	defaults["left4bots2/cfg/settings_c6m3_port_hard.txt"] <- @"close_saferoom_door_highres = 1
file_weapons_prefix = ""left4bots2/cfg/weapons/c6m3_port/""
heal_interrupt_minhealth = 40
handle_l4d1_survivors = 1
horde_nades_chance = 35
jockey_redirect_damage = 45
manual_attack_common_head_radius = 450
manual_attack_dual_pistol_nerf = 0
manual_attack_mindot = 0.65
manual_attack_special_head_radius = 400
manual_attack_wandering = 1
scavenge_items_flow_distance = 0
shove_deadstop_chance = 100
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 250";
	
	// Default settings overrides for 'c6m3_port' in 'Expert' difficulty
	defaults["left4bots2/cfg/settings_c6m3_port_impossible.txt"] <- @"automation_autostart = 0
close_saferoom_door_all_chance = 0
close_saferoom_door_highres = 1
file_weapons_prefix = ""left4bots2/cfg/weapons/c6m3_port/""
handle_l4d1_survivors = 1
heal_interrupt_minhealth = 30
horde_nades_chance = 35
jockey_redirect_damage = 50
manual_attack_always = 1
manual_attack_common_head_radius = 450
manual_attack_dual_pistol_nerf = 0
manual_attack_mindot = 0.6
manual_attack_special_head_radius = 400
manual_attack_wandering = 1
scavenge_items_flow_distance = 0
scavenge_max_bots = 1
shove_deadstop_chance = 100
signal_chat = 1
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 260
witch_autocrown = 0";
	
	// Default settings overrides for 'c6m3_port' in the other difficulties
	defaults["left4bots2/cfg/settings_c6m3_port.txt"] <- @"handle_l4d1_survivors = 1
file_weapons_prefix = ""left4bots2/cfg/weapons/c6m3_port/""
scavenge_items_flow_distance = 0";
	
	// -------------------------------------------------------
	
	// Default convars.txt file
	defaults["left4bots2/cfg/convars.txt"] <- @"allow_all_bot_survivor_team 1"; // "sb_unstick 0" // TODO: unstick logic

	// Default itemstoavoid.txt file
	defaults["left4bots2/cfg/itemstoavoid.txt"] <- @"weapon_ammo
weapon_upgrade_item
upgrade_ammo_explosive
upgrade_ammo_incendiary
upgrade_laser_sight
pain_pills
adrenaline";
	
	// Default vocalizer.txt file
	defaults["left4bots2/cfg/vocalizer.txt"] <- @"PlayerLeadOn = bots lead,botname lead
PlayerWaitHere = bots wait,botname wait
PlayerEmphaticGo = bots goto,botname goto
PlayerWarnWitch = bot witch,botname witch
PlayerMoveOn = bot use,botname use
PlayerStayTogether = bots cancel,botname cancel
PlayerFollowMe = bot follow me,botname follow me
iMT_PlayerSuggestHealth = bots heal,botname heal
PlayerHurryUp = bots hurry,botname hurry
AskForHealth2 = bot heal me,botname heal me
PlayerAnswerLostCall = bot give,botname give
iMT_PlayerHello = bot swap,botname swap
PlayerImWithYou = bots automation all,botname automation all";
//"TODO PlayerYellRun = ?
//"TODO = bots warp,botname warp
//"TODO = bot tempheal,botname tempheal
//"TODO = bot deploy,botname deploy
//"TODO = bot throw,botname throw
//"TODO = bots die,botname die

	// -------------------------------------------------------

	// Default weapon preference file for Bill
	defaults["left4bots2/cfg/weapons/bill.txt"] <- @"rifle_ak47,rifle_sg552,rifle_desert,rifle,autoshotgun,shotgun_spas,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
*,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,riotshield,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw
pipe_bomb,molotov,vomitjar
first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary
pain_pills,adrenaline";
	
	// Default weapon preference file for Coach
	defaults["left4bots2/cfg/weapons/coach.txt"] <- @"autoshotgun,shotgun_spas,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,shotgun_chrome,smg_mp5,pumpshotgun,smg_silenced,smg
*,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw,riotshield
pipe_bomb,molotov,vomitjar
first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary
pain_pills,adrenaline";
	
	// Default weapon preference file for Ellis
	defaults["left4bots2/cfg/weapons/ellis.txt"] <- @"sniper_military,hunting_rifle,rifle_ak47,rifle_sg552,rifle_desert,rifle,shotgun_spas,autoshotgun,sniper_scout,sniper_awp,rifle_m60,grenade_launcher,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
pistol_magnum,pistol,chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive
pain_pills,adrenaline";
	
	// Default weapon preference file for Francis
	defaults["left4bots2/cfg/weapons/francis.txt"] <- @"autoshotgun,shotgun_spas,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,shotgun_chrome,smg_mp5,pumpshotgun,smg_silenced,smg
riotshield,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary
*,pain_pills,adrenaline";
	
	// Default weapon preference file for Louis
	defaults["left4bots2/cfg/weapons/louis.txt"] <- @"shotgun_spas,autoshotgun,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,sniper_scout,sniper_awp,rifle_m60,grenade_launcher,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
pistol_magnum,pistol,chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive
pain_pills,adrenaline";
	
	// Default weapon preference file for Nick
	defaults["left4bots2/cfg/weapons/nick.txt"] <- @"rifle_ak47,rifle_sg552,rifle_desert,rifle,autoshotgun,shotgun_spas,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield,pistol_magnum,pistol,chainsaw
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary
*,pain_pills,adrenaline";
	
	// Default weapon preference file for Rochelle
	defaults["left4bots2/cfg/weapons/rochelle.txt"] <- @"rifle_sg552,rifle_desert,rifle_ak47,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,smg,shotgun_chrome,pumpshotgun
chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield,pistol_magnum,pistol
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive
*,pain_pills,adrenaline";
	
	// Default weapon preference file for Zoey
	defaults["left4bots2/cfg/weapons/zoey.txt"] <- @"sniper_military,hunting_rifle,rifle_sg552,rifle_desert,rifle_ak47,rifle,shotgun_spas,autoshotgun,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,smg,shotgun_chrome,pumpshotgun
chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield,pistol_magnum,pistol
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive
*,pain_pills,adrenaline";

	// -------------------------------------------------------

	// Default weapon preference file for Bill in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/bill.txt"] <- @"rifle_ak47,rifle_sg552,rifle_desert,rifle,autoshotgun,shotgun_spas,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
*,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,riotshield,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw";
	
	// Default weapon preference file for Coach in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/coach.txt"] <- @"autoshotgun,shotgun_spas,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,shotgun_chrome,smg_mp5,pumpshotgun,smg_silenced,smg
*,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw,riotshield
pipe_bomb,molotov,vomitjar
first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary
pain_pills,adrenaline";
	
	// Default weapon preference file for Ellis in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/ellis.txt"] <- @"rifle_ak47,rifle_sg552,rifle_desert,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,sniper_scout,sniper_awp,rifle_m60,grenade_launcher,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
pistol_magnum,pistol,chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive
pain_pills,adrenaline";
	
	// Default weapon preference file for Francis in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/francis.txt"] <- @"autoshotgun,shotgun_spas,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,shotgun_chrome,smg_mp5,pumpshotgun,smg_silenced,smg
riotshield,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw";
	
	// Default weapon preference file for Louis in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/louis.txt"] <- @"shotgun_spas,autoshotgun,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,sniper_scout,sniper_awp,rifle_m60,grenade_launcher,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
pistol_magnum,pistol,chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield";
	
	// Default weapon preference file for Nick in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/nick.txt"] <- @"rifle_ak47,rifle_sg552,rifle_desert,rifle,autoshotgun,shotgun_spas,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun
machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield,pistol_magnum,pistol,chainsaw
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary
*,pain_pills,adrenaline";
	
	// Default weapon preference file for Rochelle in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/rochelle.txt"] <- @"rifle_sg552,rifle_desert,rifle_ak47,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,smg,shotgun_chrome,pumpshotgun
chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield,pistol_magnum,pistol
molotov,pipe_bomb,vomitjar
first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive
*,pain_pills,adrenaline";
	
	// Default weapon preference file for Zoey in c6m3_port
	defaults["left4bots2/cfg/weapons/c6m3_port/zoey.txt"] <- @"sniper_military,hunting_rifle,rifle_sg552,rifle_desert,rifle_ak47,rifle,shotgun_spas,autoshotgun,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,smg,shotgun_chrome,pumpshotgun
chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,riotshield,pistol_magnum,pistol";
	
	// -------------------------------------------------------
	
	foreach (filename, content in defaults)
	{
		if (!Left4Utils.FileExists(filename))
		{
			Left4Utils.StringToFileCRLF(filename, content);
			Logger.Info("Config file '" + filename + "' was not found and has been recreated");
		}
	}
}