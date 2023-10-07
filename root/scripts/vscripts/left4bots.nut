/* TODO:

- Some orders must be unique (like 'carry', 'scavenge'...). Only one order of this type can be added at a time. Maybe replace the previous one (if already present) when a new one is added. Also make sure that only one order with a certain DestEnt is added
- Must find a good algorithm to cancel the carry/scavenge orders when the item is dropped in an unreachable area to avoid the bots jump to death
- auto pause the lead order if behind humans
- "use_nopause" etc.
- Check if gascans nearby and scavenge started before throwing molotov
- Auto follow
- Auto warp when too far
- Force ammo replenish while in saferoom
- Invece di GetScriptScope... DoEntFire("!self", "RunScriptCode", "AutomaticShot()", 0.01, null, bot);  oppure  DoEntFire("!self", "CallScriptFunction", "AutomaticShot", 0.01, null, bot);
- Weapon/Item spotted -> check dist/... and add as pickup
- Remove cmdattack su special (bugga i bot)?
- sb_unstick 0 e gestire l'unstick (magari teleportarlo dietro, davanti solo se sta da solo o è indietro?)
- manual attack headshot
- Reset should reset pause?
- Cancel heal near saferoom

- [L4D][INFO]   900 |                             prop_physics |                                            barricade_gas_can | -05355.0000,-00964.0000,000016.0000 | models/props_unique/wooden_barricade_gascans.mdl

- [L4D][INFO]   254 |                              func_button |                                                bridge_button | 000123.5000,005638.0000,000305.0600 | *21
- [L4D][INFO]   255 |                           func_breakable |                                                 bridge_dummy | 000123.5000,005637.0000,000305.0600 | *22
- [L4D][INFO]   331 |                             prop_dynamic |                                               bridge_barrels | 000124.3540,005650.7798,000280.0000 | models/props/de_train/pallet_barrels.mdl

*/

//--------------------------------------------------------------------------------------------------
//     GitHub:		https://github.com/smilz0/Left4Bots
//     Workshop:	https://steamcommunity.com/sharedfiles/filedetails/?id=3022416274
//--------------------------------------------------------------------------------------------------

Msg("Including left4bots...\n");

if (!IncludeScript("left4lib_users"))
	error("[L4B][ERROR] Failed to include 'left4lib_users', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_timers"))
	error("[L4B][ERROR] Failed to include 'left4lib_timers', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_concepts"))
	error("[L4B][ERROR] Failed to include 'left4lib_concepts', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_simplehud"))
	error("[L4F][ERROR] Failed to include 'left4lib_simplehud', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");

IncludeScript("left4bots_requirements");

// Log levels
const LOG_LEVEL_NONE = 0; // Log always
const LOG_LEVEL_ERROR = 1;
const LOG_LEVEL_WARN = 2;
const LOG_LEVEL_INFO = 3;
const LOG_LEVEL_DEBUG = 4;

::Left4Bots <-
{
	Initialized = false
	ModeName = ""
	MapName = ""
	Difficulty = "" // easy, normal, hard, impossible
	SurvivorSet = 2
	OrderPriorities = // Orders and their priorities (orders with lower priority are shifted back in the queue when orders with higher priority are added)
	{
		carry = 0
		follow = 0
		lead = 0
		scavenge = 0 // TODO: maybe this should be 1 and all the next should be increased by 1 while scavenge, follow and lead should remain to 0 and must be made exlusive (only 1 of them at a time: replace any previous with the last added)
		goto = 1
		wait = 1
		deploy = 2
		heal = 2
		use = 2
		witch = 3
	}
	AllCommands =
	{
		cancel = 0
		carry = 0
		come = 0
		deploy = 0
		die = 0
		dump = 0
		follow = 0
		give = 0
		goto = 0
		heal = 0
		hurry = 0
		lead = 0
		move = 0
		pause = 0
		scavenge = 0
		swap = 0
		tempheal = 0
		//throw = 0  // Maybe there is a way to do this?
		use = 0
		usereset = 0
		wait = 0
		warp = 0
		witch = 0
	}

	Events = {}
	Survivors = {}		// Used for performance reasons, instead of doing (very slow) Entities search every time
	Bots = {}			// Same as above ^
	Deads = {}			// Same ^
	Specials = {}		// Idem ^
	Tanks = {}			// ^
	Witches = {}		// Guess what? ^
	L4D1Survivors = {}	// Used to store the extra L4D1 bots when handle_l4d1_survivors = 1
	ModeStarted = false
	EscapeStarted = false
	ChatBGLines = []
	ChatGGLines = []
	ChatHelloReplies = []
	ChatHelloAlreadyReplied = {}
	VocalizerLeadStart = []
	VocalizerLeadStop = []
	VocalizerGotoStop = []
	VocalizerYes = []
	VocalizerCommands = {}
	VocalizerBotSelection = {}
	BtnStatus_Shove = {}
	GiveItemIndex1 = 0
	GiveItemIndex2 = 0
	LastGiveItemTime = 0
	LastMolotovTime = 0
	LastNadeTime = 0
	LastLeadStartVocalize = 0
	NiceShootSurv = null
	NiceShootTime = 0
	ItemsToAvoid = []
	TeamShotguns = 0
	TeamMolotovs = 0
	TeamPipeBombs = 0
	TeamVomitJars = 0
	TeamMedkits = 0
	TeamDefibs = 0
	TeamChainsaws = 0
	TeamMelee = 0
	ScavengeStarted = false
	ScavengeUseTarget = null
	ScavengeUseTargetPos = null
	ScavengeUseType = 0
	ScavengeBots = {}
	L4F = false
	LastSignalType = ""
	LastSignalTime = 0
	OnTankSettings = {}
	OnTankSettingsBak = {}
	OnTankCvars = {}
	OnTankCvarsBak = {}
}

::Left4Bots.AllCommands["throw"] <- 0;

IncludeScript("left4bots_settings");

::Left4Bots.Log <- function (level, text)
{
	if (level > Left4Bots.Settings.loglevel)
		return;

	switch (level)
	{
		case LOG_LEVEL_DEBUG:
			printl("[L4B][DEBUG][" + Time() + "] " + text);
			break;
		case LOG_LEVEL_INFO:
			printl("[L4B][INFO][" + Time() + "] " + text);
			break;
		case LOG_LEVEL_WARN:
			error("[L4B][WARNING][" + Time() + "] " + text + "\n");
			break;
		case LOG_LEVEL_ERROR:
			error("[L4B][ERROR][" + Time() + "] " + text + "\n");
			break;
		default:
			error("[L4B][" + level + "][" + Time() + "] " + text + "\n");
			break;
	}
}

// Left4Bots main initialization function
::Left4Bots.Initialize <- function ()
{
	if (Left4Bots.Initialized)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots already initialized");
		return;
	}

	Left4Bots.ModeName = SessionState.ModeName;
	Left4Bots.MapName = SessionState.MapName;
	Left4Bots.Difficulty = Convars.GetStr("z_difficulty").tolower();
	Left4Bots.SurvivorSet = Director.GetSurvivorSet();

	Left4Bots.Log(LOG_LEVEL_INFO, "Initializing for game mode: " + Left4Bots.ModeName + " - map name: " + Left4Bots.MapName + " - difficulty: " + Left4Bots.Difficulty);

	Left4Bots.Log(LOG_LEVEL_INFO, "Loading settings...");
	Left4Utils.LoadSettingsFromFile("left4bots2/cfg/settings.txt", "Left4Bots.Settings.", Left4Bots.Log);
	Left4Utils.SaveSettingsToFile("left4bots2/cfg/settings.txt", ::Left4Bots.Settings, Left4Bots.Log);

	// Create the missing config files with their default values
	Left4Bots.DefaultConfigFiles();

	Left4Bots.LoadSettingsOverride();

	Left4Utils.PrintSettings(::Left4Bots.Settings, Left4Bots.Log, "[Settings] ");

	if (Left4Bots.Settings.load_convars && Left4Bots.Settings.file_convars != "")
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loading convars from file: " + Left4Bots.Settings.file_convars);
		local c = Left4Utils.LoadCvarsFromFile(Left4Bots.Settings.file_convars, Left4Bots.Log);
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded " + c + " convars");
	}
	else
		Left4Bots.Log(LOG_LEVEL_INFO, "Convars file was not loaded due to settings.load_convars and settings.file_convars");

	if (Left4Bots.Settings.file_itemstoavoid != "")
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loading items to avoid from file: " + Left4Bots.Settings.file_itemstoavoid);
		Left4Bots.ItemsToAvoid = Left4Bots.LoadItemsToAvoidFromFile(Left4Bots.Settings.file_itemstoavoid);
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded " + Left4Bots.ItemsToAvoid.len() + " items");
	}
	else
		Left4Bots.Log(LOG_LEVEL_INFO, "Itemstoavoid file was not loaded (settings.file_itemstoavoid is empty)");

	if (Left4Bots.Settings.file_vocalizer != "")
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loading vocalizer command mapping from file: " + Left4Bots.Settings.file_vocalizer);
		::Left4Bots.VocalizerCommands = Left4Bots.LoadVocalizerCommandsFromFile(Left4Bots.Settings.file_vocalizer);
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded " + Left4Bots.VocalizerCommands.len() + " orders");
	}
	else
		Left4Bots.Log(LOG_LEVEL_INFO, "Vocalizer file was not loaded (settings.file_vocalizer is empty)");

	if (Left4Utils.FileExists("left4bots2/cfg/ontank_settings.txt"))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loading OnTank settings...");
		Left4Utils.LoadSettingsFromFile("left4bots2/cfg/ontank_settings.txt", "Left4Bots.OnTankSettings.", Left4Bots.Log, true);
	}
	Left4Utils.PrintSettings(::Left4Bots.OnTankSettings, Left4Bots.Log, "[OnTank Settings] ");

	if (Left4Utils.FileExists("left4bots2/cfg/ontank_convars.txt"))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loading OnTank convars...");
		local c = Left4Bots.LoadOnTankCvarsFromFile("left4bots2/cfg/ontank_convars.txt");
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded " + c + " OnTank convars");
	}

	// Put the vocalizer lines into arrays
	if (Left4Bots.Settings.vocalizer_lead_start != "")
		Left4Bots.VocalizerLeadStart = split(Left4Bots.Settings.vocalizer_lead_start, ",");
	if (Left4Bots.Settings.vocalizer_lead_stop != "")
		Left4Bots.VocalizerLeadStop = split(Left4Bots.Settings.vocalizer_lead_stop, ",");
	if (Left4Bots.Settings.vocalizer_goto_stop != "")
		Left4Bots.VocalizerGotoStop = split(Left4Bots.Settings.vocalizer_goto_stop, ",");
	if (Left4Bots.Settings.vocalizer_yes != "")
		Left4Bots.VocalizerYes = split(Left4Bots.Settings.vocalizer_yes, ",");

	// And the BG/GG chat lines too
	if (Left4Bots.Settings.chat_bg_lines != "")
		Left4Bots.ChatBGLines = split(Left4Bots.Settings.chat_bg_lines, ",");
	if (Left4Bots.Settings.chat_gg_lines != "")
		Left4Bots.ChatGGLines = split(Left4Bots.Settings.chat_gg_lines, ",");

	if (Left4Bots.Settings.chat_hello_replies != "")
		Left4Bots.ChatHelloReplies = split(Left4Bots.Settings.chat_hello_replies, ",");

	for (local i = 1; i <= 4; i++)
	{
		local name = "l4b2debug" + i;
		Left4Hud.HideHud(name);
		Left4Hud.RemoveHud(name);
		if (Left4Bots.Settings.orders_debug)
		{
			Left4Hud.AddHud(name, g_ModeScript["HUD_SCORE_" + i], g_ModeScript.HUD_FLAG_NOTVISIBLE | g_ModeScript.HUD_FLAG_ALIGN_LEFT);
			Left4Hud.PlaceHud(name, 0.01, 0.15 + (0.05 * (i - 1)), 0.8, 0.05);
			Left4Hud.ShowHud(name);
		}
	}

	Left4Bots.Initialized = true;

	try
	{
		IncludeScript("left4bots_afterinit");
	}
	catch(exception)
	{
		error("[L4B][ERROR] Exception in left4bots_afterinit.nut: " + exception + "\n");
	}
}

::Left4Bots.DefaultConfigFiles <- function ()
{
	// Default settings overrides for 'Advanced' difficulty
	if (!Left4Utils.FileExists("left4bots2/cfg/settings_hard.txt"))
	{
		local defaultText = @"close_saferoom_door_highres = 1
heal_interrupt_minhealth = 40
horde_nades_chance = 35
jockey_redirect_damage = 45
manual_attack_mindot = 0.90
shove_deadstop_chance = 100
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 250";

		Left4Utils.StringToFileCRLF("left4bots2/cfg/settings_hard.txt", defaultText);
		Left4Bots.Log(LOG_LEVEL_INFO, "Settings override file for 'Advanced' difficulty was not found and has been recreated");
	}

	// Default settings overrides for 'Expert' difficulty
	if (!Left4Utils.FileExists("left4bots2/cfg/settings_impossible.txt"))
	{
		local defaultText = @"close_saferoom_door_all_chance = 0
close_saferoom_door_highres = 1
heal_interrupt_minhealth = 30
horde_nades_chance = 35
jockey_redirect_damage = 50
manual_attack_mindot = 0.90
scavenge_max_bots = 1
shove_deadstop_chance = 100
signal_chat = 1
spit_block_nav = 1
tank_molotov_chance = 50
tank_throw_survivors_mindistance = 260
witch_autocrown = 0";

		Left4Utils.StringToFileCRLF("left4bots2/cfg/settings_impossible.txt", defaultText);
		Left4Bots.Log(LOG_LEVEL_INFO, "Settings override file for 'Expert' difficulty was not found and has been recreated");
	}

	// Default convars.txt file
	if (!Left4Utils.FileExists("left4bots2/cfg/convars.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"allow_all_bot_survivor_team 1",
			"sb_all_bot_game 1",
			"sb_debug_apoproach_wait_time 0.5" // This is how long the bot will jiggle on the destination spot of a MOVE command before returning the control to the vanilla AI (default: 5)
			// "sb_unstick 0" // TODO: unstick logic
		];

		Left4Utils.StringListToFile("left4bots2/cfg/convars.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Convars file was not found and has been recreated");
	}

	// Default itemstoavoid.txt file
	if (!Left4Utils.FileExists("left4bots2/cfg/itemstoavoid.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"weapon_ammo",
			"weapon_upgrade_item",
			"upgrade_ammo_explosive",
			"upgrade_ammo_incendiary",
			"upgrade_laser_sight",
			"pain_pills",
			"adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/itemstoavoid.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Itemstoavoid file was not found and has been recreated");
	}

	// Default vocalizer.txt file
	if (!Left4Utils.FileExists("left4bots2/cfg/vocalizer.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"PlayerLeadOn = bots lead",
			"PlayerWaitHere = bots wait",
			"PlayerEmphaticGo = bots goto",
			"PlayerWarnWitch = bot witch",
			//"PlayerMoveOn = bots cancel current",
			"PlayerMoveOn = bot use",
			"PlayerStayTogether = bots cancel",
			"PlayerFollowMe = bot follow me",
			"iMT_PlayerSuggestHealth = bots heal",
			//"PlayerHurryUp = bots cancel defib",
			"PlayerHurryUp = bots hurry",
			"AskForHealth2 = bot heal me"
			"PlayerAnswerLostCall = bot give",
			"iMT_PlayerHello = bot swap",
			//"TODO = bots warp",
			//"TODO = bot tempheal",
			//"TODO = bot deploy",
			//"TODO = bot throw",
			//"TODO = bots die",
			//"PlayerYellRun = ?",
			//"PlayerImWithYou = next thing to do" // TODO:
		];

		Left4Utils.StringListToFile("left4bots2/cfg/vocalizer.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Vocalizer orders mapping file was not found and has been recreated");
	}

	// Default weapon preference file for Bill
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/bill.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"rifle_ak47,rifle_sg552,rifle_desert,rifle,autoshotgun,shotgun_spas,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun",
			"machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/bill.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Bill was not found and has been recreated");
	}

	// Default weapon preference file for Coach
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/coach.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"autoshotgun,shotgun_spas,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,shotgun_chrome,smg_mp5,pumpshotgun,smg_silenced,smg",
			"machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/coach.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Coach was not found and has been recreated");
	}

	// Default weapon preference file for Ellis
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/ellis.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"rifle_ak47,rifle_sg552,rifle_desert,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,sniper_scout,sniper_awp,rifle_m60,grenade_launcher,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun",
			"pistol_magnum,pistol,chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/ellis.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Ellis was not found and has been recreated");
	}

	// Default weapon preference file for Francis
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/francis.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"autoshotgun,shotgun_spas,rifle_ak47,rifle_sg552,rifle_desert,rifle,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,shotgun_chrome,smg_mp5,pumpshotgun,smg_silenced,smg",
			"machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/francis.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Francis was not found and has been recreated");
	}

	// Default weapon preference file for Louis
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/louis.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"rifle_ak47,rifle_sg552,rifle_desert,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,sniper_scout,sniper_awp,rifle_m60,grenade_launcher,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun",
			"pistol_magnum,pistol,chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/louis.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Louis was not found and has been recreated");
	}

	// Default weapon preference file for Nick
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/nick.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"rifle_ak47,rifle_sg552,rifle_desert,rifle,autoshotgun,shotgun_spas,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,shotgun_chrome,smg,pumpshotgun",
			"machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol,chainsaw",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_explosive,upgradepack_incendiary",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/nick.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Nick was not found and has been recreated");
	}

	// Default weapon preference file for Rochelle
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/rochelle.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"rifle_sg552,rifle_desert,rifle_ak47,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,smg,shotgun_chrome,pumpshotgun",
			"chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/rochelle.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Rochelle was not found and has been recreated");
	}

	// Default weapon preference file for Zoey
	if (!Left4Utils.FileExists("left4bots2/cfg/weapons/zoey.txt"))
	{
		// using array instead of table to keep the order
		local defaultValues =
		[
			"rifle_sg552,rifle_desert,rifle_ak47,rifle,shotgun_spas,autoshotgun,sniper_military,hunting_rifle,rifle_m60,grenade_launcher,sniper_scout,sniper_awp,smg_mp5,smg_silenced,smg,shotgun_chrome,pumpshotgun",
			"chainsaw,machete,golfclub,katana,fireaxe,crowbar,cricket_bat,baseball_bat,tonfa,shovel,electric_guitar,knife,frying_pan,pitchfork,pistol_magnum,pistol",
			"molotov,pipe_bomb,vomitjar",
			"first_aid_kit,defibrillator,upgradepack_incendiary,upgradepack_explosive",
			"pain_pills,adrenaline"
		];

		Left4Utils.StringListToFile("left4bots2/cfg/weapons/zoey.txt", defaultValues, false);

		Left4Bots.Log(LOG_LEVEL_INFO, "Weapon preference file for Zoey was not found and has been recreated");
	}
}

::Left4Bots.LoadSettingsOverride <- function ()
{
	// 1. settings_[map]_[difficulty]_[mode].txt
	local fileName = "left4bots2/cfg/settings_" + Left4Bots.MapName + "_" + Left4Bots.Difficulty + "_" + Left4Bots.ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}

	// 2. settings_[difficulty]_[mode].txt
	fileName = "left4bots2/cfg/settings_" + Left4Bots.Difficulty + "_" + Left4Bots.ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}

	// 3. settings_[map]_[mode].txt
	fileName = "left4bots2/cfg/settings_" + Left4Bots.MapName + "_" + Left4Bots.ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}

	// 4. settings_[mode].txt
	fileName = "left4bots2/cfg/settings_" + Left4Bots.ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}

	// 5. settings_[map]_[difficulty].txt
	fileName = "left4bots2/cfg/settings_" + Left4Bots.MapName + "_" + Left4Bots.Difficulty + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}

	// 6. settings_[difficulty].txt
	fileName = "left4bots2/cfg/settings_" + Left4Bots.Difficulty + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}

	// 7. settings_[map].txt
	fileName = "left4bots2/cfg/settings_" + Left4Bots.MapName + ".txt"
	if (Left4Utils.LoadSettingsFromFile(fileName, "Left4Bots.Settings.", Left4Bots.Log))
	{
		Left4Bots.Log(LOG_LEVEL_INFO, "Loaded settings overrides from: " + fileName);
		return;
	}
}

::Left4Bots.LoadItemsToAvoidFromFile <- function (fileName)
{
	local ret = [];

	local items = Left4Utils.FileToStringList(fileName);
	if (!items)
		return ret;

	foreach (item in items)
	{
		item = Left4Utils.StripComments(item);
		if (item != "")
			ret.append(item);
	}
	return ret;
}

::Left4Bots.LoadOnTankCvarsFromFile <- function (fileName)
{
	Left4Bots.OnTankCvars.clear();

	local count = 0;

	local cvars = Left4Utils.FileToStringList(fileName);
	if (!cvars)
		return count;

	foreach (cvar in cvars)
	{
		cvar = Left4Utils.StringReplace(cvar, "\\t", "");
		cvar = Left4Utils.StripComments(cvar);
		if (cvar && cvar != "")
		{
			cvar = strip(cvar);
			if (cvar && cvar != "")
			{
				local idx = cvar.find(" ");
				if (idx != null)
				{
					local command = cvar.slice(0, idx);
					command = Left4Utils.StringReplace(command, "\"", "");
					command = strip(command);

					local value = cvar.slice(idx + 1);
					value = Left4Utils.StringReplace(value, "\"", "");
					value = strip(value);

					Left4Bots.Log(LOG_LEVEL_DEBUG, "CVAR: " + command + " " + value);

					Left4Bots.OnTankCvars[command] <- value;

					count++;
				}
			}
		}
	}

	return count;
}

::Left4Bots.AddonStop <- function ()
{
	// This prevents the crash
	foreach (bot in ::Left4Bots.Bots)
		Left4Bots.CarryItemStop(bot);

	// Stop the thinker
	Left4Timers.RemoveThinker("L4BThinker");

	// Stop the inventory manager
	Left4Timers.RemoveTimer("InventoryManager");

	// Stop the scavenge logics
	Left4Bots.ScavengeStop();

	// Stop the cleaner
	Left4Timers.RemoveTimer("Cleaner");

	// Stop receiving concepts
	::ConceptsHub.RemoveHandler("Left4Bots");

	// Stop receiving user commands
	::HooksHub.RemoveChatCommandHandler("l4b");
	::HooksHub.RemoveConsoleCommandHandler("l4b");
	::HooksHub.RemoveAllowTakeDamage("L4B");

	// Remove all the bots think functions
	Left4Bots.ClearBotThink();

	// Clear the lists
	Left4Bots.Survivors.clear();
	Left4Bots.Bots.clear();
	Left4Bots.Deads.clear();
	Left4Bots.Specials.clear();
	Left4Bots.Tanks.clear();
	Left4Bots.Witches.clear();
}

// Is player a valid survivor? (if player is a bot also checks whether it should be handled by the AI)
::Left4Bots.IsValidSurvivor <- function (player)
{
	if (player.GetZombieType() != 9)
		return false; // Not a survivor

	local team = NetProps.GetPropInt(player, "m_iTeamNum"); // Certain mutations for some reason can spawn special infected with TEAM_SURVIVORS
	if (team == TEAM_SURVIVORS)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidSurvivor - " + player.GetPlayerName() + " is a valid survivor");
		return true;
	}

	if (team == TEAM_L4D1_SURVIVORS && Left4Bots.Settings.handle_l4d1_survivors == 2)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidSurvivor - " + player.GetPlayerName() + " is a valid survivor (L4D1)");
		return true;
	}

	//Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidSurvivor - " + player.GetPlayerName() + " is not a valid survivor");
	return false;
}

// Is survivor an handled survivor? (basically is survivor in Left4Bots.Survivors?)
::Left4Bots.IsHandledSurvivor <- function (survivor)
{
	if (!survivor || !survivor.IsValid())
		return false;

	return (survivor.GetPlayerUserId() in Left4Bots.Survivors);
}

// Is bot an AI handled survivor bot? (basically is bot in Left4Bots.Bots?)
::Left4Bots.IsHandledBot <- function (bot)
{
	if (!bot || !bot.IsValid())
		return false;

	return (bot.GetPlayerUserId() in Left4Bots.Bots);
}

// Is bot an AI handled extra L4D1 survivor bot? (basically is bot in Left4Bots.L4D1Survivors?)
::Left4Bots.IsHandledL4D1Bot <- function (bot)
{
	if (!bot || !bot.IsValid())
		return false;

	return (bot.GetPlayerUserId() in Left4Bots.L4D1Survivors);
}

::Left4Bots.PrintSurvivorsCount <- function ()
{
	local sn = ::Left4Bots.Survivors.len();
	local bn = ::Left4Bots.Bots.len();
	local hn = sn - bn;
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[Alive survivors: " + sn + " - " + bn + " bot(s) - " + hn + " human(s)]");
}

::Left4Bots.PrintL4D1SurvivorsCount <- function ()
{
	local sn = ::Left4Bots.L4D1Survivors.len();
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[L4D1 bots: " + sn + "]");
}

// Returns the entity (if found) of the survivor with that actor name
// useRR = whether to use rr_GetResponseTargets or not
// ^ Apparently rr_GetResponseTargets returns the wrong chars for the L4D1 suvivors in L4D1 maps when extra L4D2 bots are spawned by the "VScript Survivor Manager" addon
::Left4Bots.GetSurvivorFromActor <- function (actor, useRR = false)
{
	local r;

	if (useRR)
	{
		r = Left4Utils.GetSurvivorFromActor(actor);
		if (r != null)
			return r;
	}

	r = Left4Utils.GetCharacterFromActor(actor, Left4Bots.SurvivorSet);
	if (r == null)
		return null;

	return Left4Bots.GetSurvivorByCharacter(r);
}

// Returns the entity (if found) of the survivor with that character id
::Left4Bots.GetSurvivorByCharacter <- function (character)
{
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && NetProps.GetPropInt(surv, "m_survivorCharacter") == character)
			return surv;
	}
	foreach (surv in ::Left4Bots.L4D1Survivors)
	{
		if (surv.IsValid() && NetProps.GetPropInt(surv, "m_survivorCharacter") == character)
			return surv;
	}
	return null;
}

// Returns the bot with the given name
::Left4Bots.GetBotByName <- function (name)
{
	local n = name.tolower();
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid() && bot.GetPlayerName().tolower() == n)
			return bot;
	}
	return null;
}

// Is the given survivor actually immobilized and cannot do anything?
::Left4Bots.SurvivorCantMove <- function (survivor, waiting = false) // 'wait' order sets movetype to 0, which makes IsImmobilized() return true and we don't want to return true for that
{
	// IsHangingFromLedge = hanging from ledge
	// IsIncapacitated = down or hanging from ledge
	// IsDominatedBySpecialInfected = dominated by special infected
	// IsStaggering = staggering
	// IsGettingUp = ?
	// IsDying = dying
	// IsImmobilized = down, hanging from ledge, dominated by special (except jockey), dying, healing, being healed, reviving, being revived, punched by tank

	return ((!waiting && survivor.IsImmobilized()) || survivor.IsDominatedBySpecialInfected() || survivor.IsStaggering());
}

// Should the bot's AI start the pause and temporarily give control to the vanilla AI?
// Returns:
// - false: if no need to start the pause
// - ent: if should start the pause (ent is the entity of the special infected / tank / witch that is the reason to start the pause)
// - 1: if should start the pause and the reason is because of a common infected horde
// - true: if should start the pause for any other reason
::Left4Bots.BotShouldStartPause <- function (bot, userid, orig, isstuck, isHealOrder = false, maxSeparation = 0)
{
	//local aw = bot.GetActiveWeapon();
	//if (maxSeparation)
	//	return isstuck || bot.IsIT() || (!isHealOrder && aw && aw.GetClassname() == "weapon_first_aid_kit") || /*Left4Bots.IsFarFromOtherSurvivors(userid, orig, maxSeparation)*/ Left4Bots.IsFarFromHumanSurvivors(userid, orig, maxSeparation) || Left4Bots.HasTanksWithin(orig, 800) || Left4Bots.BotWillUseMeds(bot) || Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) || Left4Bots.HasWitchesWithin(orig, 300, 100) || Left4Bots.SurvivorsHeldOrIncapped() || Left4Bots.HasAngryCommonsWithin(orig, 4, 160, 100);
	//else
	//	return isstuck || bot.IsIT() || (!isHealOrder && aw && aw.GetClassname() == "weapon_first_aid_kit") || Left4Bots.HasTanksWithin(orig, 800) || Left4Bots.BotWillUseMeds(bot) || Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) || Left4Bots.HasWitchesWithin(orig, 300, 100) || Left4Bots.SurvivorsHeldOrIncapped() || Left4Bots.HasAngryCommonsWithin(orig, 4, 160, 100);

	if (isstuck || bot.IsIT() || (maxSeparation && /*Left4Bots.IsFarFromOtherSurvivors(userid, orig, maxSeparation)*/ Left4Bots.IsFarFromHumanSurvivors(userid, orig, maxSeparation)) || Left4Bots.BotWillUseMeds(bot) || Left4Bots.SurvivorsHeldOrIncapped())
		return true;

	local tmp;
	if (!isHealOrder)
	{
		tmp = bot.GetActiveWeapon();
		if (tmp && tmp.GetClassname() == "weapon_first_aid_kit")
			return true;
	}

	tmp = Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400);
	if (tmp)
		return tmp;

	tmp = Left4Bots.HasTanksWithin(orig, 800);
	if (tmp)
		return tmp;

	tmp = Left4Bots.HasWitchesWithin(orig, 300, 100);
	if (tmp)
		return tmp;

	if (Left4Bots.HasAngryCommonsWithin(orig, 4, 160, 100))
		return 1;

	return false;
}

// Should the bot's AI stop the pause?
::Left4Bots.BotShouldStopPause <- function (bot, userid, orig, isstuck, isHealOrder = false, maxSeparation = 0)
{
	local aw = bot.GetActiveWeapon();
	if (maxSeparation)
		return !isstuck && /*!bot.IsIT() &&*/ (isHealOrder || !aw || aw.GetClassname() != "weapon_first_aid_kit") && !bot.IsInCombat() && /*!Left4Bots.IsFarFromOtherSurvivors(userid, orig, maxSeparation)*/ !Left4Bots.IsFarFromHumanSurvivors(userid, orig, maxSeparation) && !Left4Bots.HasTanksWithin(orig, 800) && !Left4Bots.BotWillUseMeds(bot) && !Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) && !Left4Bots.HasWitchesWithin(orig, 300, 100) && !Left4Bots.SurvivorsHeldOrIncapped();
	else
		return !isstuck && /*!bot.IsIT() &&*/ (isHealOrder || !aw || aw.GetClassname() != "weapon_first_aid_kit") && !bot.IsInCombat() && !Left4Bots.HasTanksWithin(orig, 800) && !Left4Bots.BotWillUseMeds(bot) && !Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) && !Left4Bots.HasWitchesWithin(orig, 300, 100) && !Left4Bots.SurvivorsHeldOrIncapped();
}

// Will the vanilla AI use meds?
::Left4Bots.BotWillUseMeds <- function (bot)
{
	local totalHealth = bot.GetHealth() + bot.GetHealthBuffer();
	if (totalHealth >= 45) // It's actually < 50 for the pills/adrenaline
		return false;

	local inv = {};
	GetInvTable(bot, inv);

	// It's actually < 30 for the medkit
	return ((INV_SLOT_PILLS in inv) || (totalHealth < 29 && (INV_SLOT_MEDKIT in inv) && inv[INV_SLOT_MEDKIT].GetClassname() == "weapon_first_aid_kit"));
}

// Are there at least 'num' angry commons within 'radius' and 'maxAltDiff' from 'orig'?
::Left4Bots.HasAngryCommonsWithin <- function (orig, num, radius = 1000, maxAltDiff = 1000)
{
	local n = 0;
	local ent = null;
	local a = orig.z;
	while (ent = Entities.FindByClassnameWithin(ent, "infected", orig, radius))
	{
		if (ent.IsValid() && abs(a - ent.GetOrigin().z) <= maxAltDiff && NetProps.GetPropInt(ent, "m_lifeState") == 0 && (NetProps.GetPropInt(ent, "m_mobRush") || NetProps.GetPropInt(ent, "m_clientLookatTarget"))) // <- still alive and angry
		{
			if (++n >= num)
				return true;
		}
	}
	return false;
}

// Same as HasAngryCommonsWithin but returns:
// 	- 'false' if the conditions were not met
//	- 'true' if enough angry commons were found but no one of them was visible
//	- the entity of the farthest visible common (choosen from the checked ones only)
::Left4Bots.CheckAngryCommonsWithin <- function (player, orig, num, radius = 1000, maxAltDiff = 1000)
{
	local t = true;
	local d = 0;
	local n = 0;
	local ent = null;
	local a = orig.z;
	while (ent = Entities.FindByClassnameWithin(ent, "infected", orig, radius))
	{
		if (ent.IsValid() && NetProps.GetPropInt(ent, "m_lifeState") == 0) // <- still alive
		{
			local dist = (ent.GetOrigin() - orig).Length();
			if (dist > d && dist >= Left4Bots.Settings.throw_nade_mindistance && Left4Utils.CanTraceTo(player, ent, Left4Bots.Settings.tracemask_others))
			{
				t = ent;
				d = dist;
			}

			if (abs(a - ent.GetOrigin().z) <= maxAltDiff && (NetProps.GetPropInt(ent, "m_mobRush") || NetProps.GetPropInt(ent, "m_clientLookatTarget")))
			{
				if (++n >= num)
					return t;
			}
		}
	}
	return false;
}

// Does 'player' have at least one visible special infected within 'radius'?
// Returns the ent of the first special infected found or null if none
::Left4Bots.HasVisibleSpecialInfectedWithin <- function (player, orig, radius = 1000)
{
	foreach (ent in ::Left4Bots.Specials)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= radius && !ent.IsGhost() && Left4Utils.CanTraceTo(player, ent, Left4Bots.Settings.tracemask_others))
			return ent;
	}
	return null;
}

// Does 'player' have at least one special infected within 'radius'?
::Left4Bots.HasSpecialInfectedWithin <- function (orig, radius = 1000)
{
	foreach (ent in ::Left4Bots.Specials)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= radius && !ent.IsGhost())
			return true;
	}
	return false;
}

// Is there at least one tank within 'radius' from 'orig'?
// Returns the ent of the first tank found or null if none
::Left4Bots.HasTanksWithin <- function (orig, radius = 1000)
{
	foreach (ent in ::Left4Bots.Tanks)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= radius && !ent.IsGhost())
			return ent;
	}
	return null;
}

// Is there at least one witch within 'radius' and 'maxAltDiff' from 'orig'?
// Returns the ent of the first witch found or null if none
::Left4Bots.HasWitchesWithin <- function (orig, radius = 1000, maxAltDiff = 1000)
{
	foreach (witch in ::Left4Bots.Witches)
	{
		if (witch.IsValid() && abs(orig.z - witch.GetOrigin().z) <= maxAltDiff && (witch.GetOrigin() - orig).Length() <= radius && NetProps.GetPropInt(witch, "m_lifeState") == 0 && !NetProps.GetPropInt(witch, "m_bIsBurning"))
			return witch;
	}
	return null;
}

// Is there at least one survivor to defib within 'radius' from 'orig'?
::Left4Bots.HasDeathModelWithin <- function (orig, radius = 1000)
{
	foreach (chr, death in ::Left4Bots.Deads)
	{
		if (death.dmodel.IsValid() && (orig - death.dmodel.GetOrigin()).Length() <= radius)
			return true;
	}
	return false;
}

// Returns the first tongue victim teammate to shove
::Left4Bots.GetTongueVictimToShove <- function (player, orig) // TODO: add trace check?
{
	foreach (surv in ::Left4Bots.GetOtherAliveSurvivors(player.GetPlayerUserId()))
	{
		if ((surv.GetOrigin() - orig).Length() <= Left4Bots.Settings.shove_tonguevictim_radius && NetProps.GetPropInt(surv, "m_tongueOwner") > 0)
			return surv;
	}
	return null;
}

// Returns the first special infected to shove (only smokers, hunters, spitters or jockeys)
::Left4Bots.GetSpecialInfectedToShove <- function (player, orig) // TODO: add trace check?
{
	foreach (ent in ::Left4Bots.Specials)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= Left4Bots.Settings.shove_specials_radius && !ent.IsGhost())
		{
			local zType = ent.GetZombieType();
			if (zType == Z_SMOKER || zType == Z_HUNTER || zType == Z_SPITTER || zType == Z_JOCKEY)
				return ent;
		}
	}
	return null;
}

// Returns the closest visible tank within 'min' and 'max' from 'player'
::Left4Bots.GetNearestVisibleTankWithin <- function (player, orig, min = 80, max = 1000)
{
	local ret = null;
	local minDist = 1000000;
	foreach (id, tank in ::Left4Bots.Tanks)
	{
		if (tank.IsValid())
		{
			local dist = (orig - tank.GetOrigin()).Length();
			if (dist >= min && dist <= max && dist < minDist && Left4Utils.CanTraceTo(player, tank, Left4Bots.Settings.tracemask_others))
			{
				ret = tank;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Is there at least one survivor who is being held by SI or incapacitated?
::Left4Bots.SurvivorsHeldOrIncapped <- function ()
{
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && (surv.IsIncapacitated() || surv.IsDominatedBySpecialInfected()))
			return true;
	}
	return false;
}

// Given bot will speak a random vocalizer command (from the commands array) after the given delay
::Left4Bots.SpeakRandomVocalize <- function (bot, commands, delay)
{
	if (commands.len() > 0)
		DoEntFire("!self", "SpeakResponseConcept", commands[RandomInt(0, commands.len() - 1)], delay, null, bot);
}

// Force the given bot to fire a single bullet with the active weapon at the position of the witch's attachment with the given id
::Left4Bots.BotShootAtEntityAttachment <- function (bot, witch, attachmentid, lockLook = false, unlockLookDelay = 0)
{
	if (!bot || !bot.IsValid())
		return;

	if (!witch || !witch.IsValid())
	{
		if (lockLook) // Make sure to unfreeze the bot anyway
			NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN

		return;
	}

	Left4Bots.Log(LOG_LEVEL_DEBUG, "BotShootAtEntityAttachment - bot: " + bot.GetPlayerName() + " - witch: " + witch + " - attachmentid: " + attachmentid);

	Left4Utils.PlayerPressButton(bot, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, witch.GetAttachmentOrigin(attachmentid), 0, 0, lockLook, unlockLookDelay);
}

// Returns the closest valid enemy for the given bot within the given radius and minimum dot
// Valid enemies are common and special infected (including tank), witch excluded
::Left4Bots.FindBotNearestEnemy <- function (bot, orig, radius, minDot = 0.96)
{
	local botFacing = bot.EyeAngles().Forward();
	local ret = null;
	local minDist = 1000000;
	foreach (ent in ::Left4Bots.Specials)
	{
		if (ent.IsValid())
		{
			local toEnt = ent.GetOrigin() - orig;
			local dist = toEnt.Length();
			toEnt.Norm();
			if (dist <= radius && dist < minDist && botFacing.Dot(toEnt) >= minDot && !ent.IsGhost() && Left4Utils.CanTraceTo(bot, ent, Left4Bots.Settings.tracemask_others))
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	// TODO: Just return the special if it's within a certain range?

	local ent = null;
	while (ent = Entities.FindByClassnameWithin(ent, "infected", orig, radius)) // If only we had a infected_spawned event for the commons...
	{
		if (ent.IsValid())
		{
			local toEnt = ent.GetOrigin() - orig;
			local dist = toEnt.Length();
			toEnt.Norm();
			if (dist < minDist && botFacing.Dot(toEnt) >= minDot && NetProps.GetPropInt(ent, "m_lifeState") == 0 && Left4Utils.CanTraceTo(bot, ent, Left4Bots.Settings.tracemask_others))
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Called when the bot's pick-up algorithm decides to pick the item up
// Checks if the pick-up via button press worked and the item went into the bot's inventory. if it didn't it will force it via USE input on the item
// It is meant to prevent the bot getting stuck in a loop if the button press, for some reason, didn't pick the item up
::Left4Bots.PickupFailsafe <- function (bot, item)
{
	if (!bot || !bot.IsValid() || !Left4Bots.IsValidPickup(item))
		return;

	//Left4Utils.HasWeaponEnt <- function (player, weaponEnt)
	local weaponid = Left4Utils.GetWeaponId(item);
	if (Left4Utils.HasWeaponId(bot, weaponid, Left4Utils.GetAmmoPercent(item)))
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "PickupFailsafe - " + bot.GetPlayerName() + " -> " + item + " (" + weaponid + ")");

	DoEntFire("!self", "Use", "", 0, bot, item); // <- make sure i pick this up even if the real pickup (with the button) fails or i will be stuck here forever
	Left4Bots.OnPlayerUse(bot, item, 1); // ^this doesn't trigger the event so i do it myself
}

// Called when the bot opens/closes a door
// Checks if opening/closing the door via USE button press worked and the door is actually opening/open or closing/closed. if it didn't work it will force the open/close via direct input on the door's entity
::Left4Bots.DoorFailsafe <- function (bot, door, action)
{
	if (!bot || !bot.IsValid() || !door || !door.IsValid() || (action != AI_DOOR_ACTION.Open && action != AI_DOOR_ACTION.Close))
		return;

	local state = NetProps.GetPropInt(door, "m_eDoorState"); // 0 = closed - 1 = opening - 2 = open - 3 = closing
	if ((action == AI_DOOR_ACTION.Close && (state == 3 || state == 0)) || action == AI_DOOR_ACTION.Open && (state == 1 || state == 2))
		return;

	if (action == AI_DOOR_ACTION.Close)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "DoorFailsafe - " + bot.GetPlayerName() + " -> " + door + " (Close)");
		DoEntFire("!self", "Close", "", 0, bot, door);
	}
	else
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "DoorFailsafe - " + bot.GetPlayerName() + " -> " + door + " (Open)");
		DoEntFire("!self", "Open", "", 0, bot, door);
	}
	//DoEntFire("!self", "Use", "", 0, bot, door);

	// Let's pretend we are closing it the normal way
	Left4Utils.BotLookAt(bot, door, 0, 0);
}

// Is the survivor with the given userid (likely a bot) too far from the other human survivors?
::Left4Bots.IsFarFromHumanSurvivors <- function (userid, orig, range)
{
	local aliveHumans = Left4Bots.GetOtherAliveHumanSurvivors(userid);
	if (aliveHumans.len() == 0)
		return false; // Return false if there are no other human survivors alive

	foreach (surv in aliveHumans)
	{
		if ((orig - surv.GetOrigin()).Length() <= range)
			return false;
	}
	return true;
}

// Is the survivor with the given userid (likely a bot) too far from the other (any) survivors?
::Left4Bots.IsFarFromOtherSurvivors <- function (userid, orig, range)
{
	if (Left4Bots.Survivors.len() == 1)
		return false; // Return false if the given survivor is the only survivor alive

	foreach (id, surv in ::Left4Bots.Survivors)
	{
		if (id != userid && surv.IsValid() && (orig - surv.GetOrigin()).Length() <= range)
			return false;
	}
	return true;
}

// Returns the list of survivors alive (excluding the one with the given userid)
::Left4Bots.GetOtherAliveSurvivors <- function (userid)
{
	local t = {};
	local i = -1;
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && surv.GetPlayerUserId() != userid)
			t[++i] <- surv;
	}
	return t;
}

// Returns the list of alive human survivors (excluding the one with the given userid)
::Left4Bots.GetOtherAliveHumanSurvivors <- function (userid)
{
	local t = {};
	local i = -1;
	foreach (id, surv in ::Left4Bots.Survivors)
	{
		if (id != userid && surv.IsValid() && !IsPlayerABot(surv))
			t[++i] <- surv;
	}
	return t;
}

// Are there survivors (other than the one with the given userid) within 'radius' from 'origin'?
::Left4Bots.AreOtherSurvivorsNearby <- function (userid, origin, radius = 150)
{
	foreach (id, surv in ::Left4Bots.Survivors)
	{
		if (id != userid && surv.IsValid() && (surv.GetOrigin() - origin).Length() <= radius)
			return true;
	}
	return false;
}

// Is there any other survivor (other than the one with the given userid) currently holding a weapon of class 'weaponClass'?
::Left4Bots.IsSomeoneElseHolding <- function (userid, weaponClass)
{
	foreach (id, surv in ::Left4Bots.Survivors)
	{
		if (id != userid && surv.IsValid())
		{
			local holding = surv.GetActiveWeapon();
			if (holding && holding.IsValid() && holding.GetClassname() == weaponClass)
				return true;
		}
	}
	return false;
}

// Handles the give item algorithm from the given bot to the dest survivor of the item in the bot's inventory slot
// Returns true if the item has been given, false otherwise
::Left4Bots.GiveInventoryItem <- function (bot, survDest, invSlot)
{
	if (Left4Bots.GiveItemIndex1 != 0 || Left4Bots.GiveItemIndex2 != 0 || (Time() - Left4Bots.LastGiveItemTime) < 3)
		return false; // Another give is already in progress or we must wait 3 seconds between each give

	// Give molotov / pipe bombs / bile jars / pills / adrenaline to all humans
	if ((invSlot == INV_SLOT_THROW && !Left4Bots.Settings.give_bots_nades) || (invSlot == INV_SLOT_PILLS && !Left4Bots.Settings.give_bots_pills))
		return false; // Disabled via settings

	local item = Left4Utils.GetInventoryItemInSlot(bot, invSlot);
	if (!item || !item.IsValid())
		return false; // No item in that slot

	local itemClass = item.GetClassname();
	local aw = bot.GetActiveWeapon();
	if (aw && aw.IsValid() && aw.GetClassname() == itemClass)
		return false; // Don't give items that are being held by the bot to avoid giving away a mekit while the bot is trying to heal

	local lvl = Left4Users.GetOnlineUserLevel(survDest.GetPlayerUserId());
	if (invSlot == INV_SLOT_MEDKIT && (itemClass == "weapon_first_aid_kit" || itemClass == "weapon_defibrillator"))
	{
		if (!Left4Bots.Settings.give_bots_medkits || lvl < Left4Bots.Settings.userlevel_give_medkit)
			return false; // Disabled via settings or user level too low
	}
	else if (lvl < Left4Bots.Settings.userlevel_give_others)
		return false; // User level too low

	if (invSlot == INV_SLOT_MEDKIT && (itemClass == "weapon_upgradepack_explosive" || itemClass == "weapon_upgradepack_incendiary") && !Left4Bots.Settings.give_bots_upgrades)
		return false; // Disabled via settings

	if (Left4Utils.GetInventoryItemInSlot(survDest, invSlot) != null)
		return false; // Dest survivor already has an item in that slot

	// Ok, we can give the item...

	local itemSkin = NetProps.GetPropInt(item, "m_nSkin");

	Left4Bots.GiveItemIndex1 = item.GetEntityIndex();

	bot.DropItem(itemClass);

	//survDest.GiveItemWithSkin(itemClass, itemSkin);
	Left4Utils.GiveItemWithSkin(survDest, itemClass, itemSkin);

	Left4Timers.AddTimer(null, 0.1, Left4Bots.ItemGiven, { player1 = bot, player2 = survDest, item = item });

	DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, bot);

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.GiveInventoryItem - " + bot.GetPlayerName() + " -> " + item + " -> " + survDest.GetPlayerName());

	return true;
}

// Finalize the give item process
::Left4Bots.ItemGiven <- function (params)
{
	local player1 = params["player1"];
	local player2 = params["player2"];
	local item = params["item"];

	if (item && item.IsValid())
		DoEntFire("!self", "Kill", "", 0, null, item);

	Left4Bots.GiveItemIndex1 = 0;

	if (Left4Bots.Settings.play_sounds)
	{
		if (player1 && player1.IsValid())
		{
			if (!IsPlayerABot(player1))
				EmitSoundOnClient("Hint.BigReward", player1);

			foreach (id, surv in ::Left4Bots.Survivors)
			{
				if (surv.IsValid() && !IsPlayerABot(surv) && id != player1.GetPlayerUserId())
					EmitSoundOnClient("Hint.LittleReward", surv);
			}
		}
	}
}

// Finalize the swap item process
::Left4Bots.ItemSwapped <- function (params)
{
	local player1 = params["player1"];
	local player2 = params["player2"];
	local item1 = params["item1"];
	local item2 = params["item2"];

	if (item1 && item1.IsValid())
		DoEntFire("!self", "Kill", "", 0, null, item1);
	if (item2 && item2.IsValid())
		DoEntFire("!self", "Kill", "", 0, null, item2);

	Left4Bots.GiveItemIndex1 = 0;
	Left4Bots.GiveItemIndex2 = 0;

	if (Left4Bots.Settings.play_sounds)
	{
		if (player1 && player1.IsValid())
		{
			if (!IsPlayerABot(player1))
				EmitSoundOnClient("Hint.BigReward", player1);
			if (!IsPlayerABot(player2))
				EmitSoundOnClient("Hint.BigReward", player2);

			foreach (id, surv in ::Left4Bots.Survivors)
			{
				if (surv.IsValid() && !IsPlayerABot(surv) && id != player1.GetPlayerUserId() && id != player2.GetPlayerUserId())
					EmitSoundOnClient("Hint.LittleReward", surv);
			}
		}
	}
}

// Returns the first available bot with any item in the given intentory slot or null if not bot available
// It also checks whether the given user level of the is allowed to receive medkits/defibs
::Left4Bots.GetFirstAvailableBotForGive <- function (slot, userlevel)
{
	foreach (bot in ::Left4Bots.Bots)
	{
		// Add some restrictions
		if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() /*&& !bot.IsIncapacitated()*/ && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			// Does the bot have any item in that slot?
			local item = Left4Utils.GetInventoryItemInSlot(bot, slot);
			if (item && item.IsValid())
			{
				// Yes.
				local itemClass = item.GetClassname();

				// But don't give items that are being held by the bot to avoid giving away items that are about to be used by the bot
				local held = bot.GetActiveWeapon();
				if (!held || !held.IsValid() || held.GetEntityIndex() != item.GetEntityIndex())
				{
					// If we are going to give a medkit/defib, check if the user level of the receiver is high enough
					if (slot != INV_SLOT_MEDKIT || (itemClass != "weapon_first_aid_kit" && itemClass != "weapon_defibrillator") || (Left4Bots.Settings.give_bots_medkits && userlevel >= Left4Bots.Settings.userlevel_give_medkit))
						return bot;
				}
			}
		}
	}

	/*
	foreach (bot in ::Left4Bots.L4D1Survivors)
	{
		// Add some restrictions
		//if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() && !bot.IsIncapacitated() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			// Does the bot have any item in that slot?
			local item = Left4Utils.GetInventoryItemInSlot(bot, slot);
			if (item && item.IsValid())
			{
				// Yes.
				local itemClass = item.GetClassname();

				// But don't give items that are being held by the bot to avoid giving away items that are about to be used by the bot
				local held = bot.GetActiveWeapon();
				if (!held || !held.IsValid() || held.GetEntityIndex() != item.GetEntityIndex())
				{
					// If we are going to give a medkit/defib, check if the user level of the receiver is high enough
					if (slot != INV_SLOT_MEDKIT || (itemClass != "weapon_first_aid_kit" && itemClass != "weapon_defibrillator") || (Left4Bots.Settings.give_bots_medkits && userlevel >= Left4Bots.Settings.userlevel_give_medkit))
						return bot;
				}
			}
		}
	}
	*/

	return null;
}

// Returns closest (to 'player') bot with an upgrade pack in the inventory
::Left4Bots.GetFirstAvailableBotForDeploy <- function (player)
{
	local ret = null;
	local minDist = 999999;
	local orig = player.GetOrigin();
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() /*&& !bot.IsIncapacitated()*/ && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			local item = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_MEDKIT);
			if (item && item.IsValid())
			{
				local itemClass = item.GetClassname();
				if (itemClass == "weapon_upgradepack_explosive" || itemClass == "weapon_upgradepack_incendiary")
				{
					local d = (bot.GetOrigin() - orig).Length();
					if (d < minDist)
					{
						ret = bot;
						minDist = d;
					}
				}
			}
		}
	}

	/*
	foreach (bot in ::Left4Bots.L4D1Survivors)
	{
		//if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() && !bot.IsIncapacitated() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			local item = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_MEDKIT);
			if (item && item.IsValid())
			{
				local itemClass = item.GetClassname();
				if (itemClass == "weapon_upgradepack_explosive" || itemClass == "weapon_upgradepack_incendiary")
				{
					local d = (bot.GetOrigin() - orig).Length();
					if (d < minDist)
					{
						ret = bot;
						minDist = d;
					}
				}
			}
		}
	}
	*/

	return ret;
}

// Returns closest (to 'destPos') bot with an item of class 'itemClass' (if 'itemClass' is not null) or with any throwable item (if 'itemClass' is null)
::Left4Bots.GetFirstAvailableBotForThrow <- function (destPos, itemClass = null)
{
	local ret = null;
	local minDist = 999999;
	foreach (bot in ::Left4Bots.Bots)
	{
		if (Left4Bots.BotCanThrow(bot, itemClass))
		{
			local d = (bot.GetOrigin() - destPos).Length();
			if (d < minDist)
			{
				ret = bot;
				minDist = d;
			}
		}
	}

	return ret;
}

// Returns whether the given 'bot' is currently able to throw the item of class 'itemClass' (if not null) or any throwable item (if 'itemClass' is null)
::Left4Bots.BotCanThrow <- function (bot, itemClass = null)
{
	if (!bot || !bot.IsValid() || bot.IsDead() || bot.IsDying() || bot.IsIncapacitated() || Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		return false;

	local item = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_THROW);
	return (item && item.IsValid() && (!itemClass || item.GetClassname() == itemClass));
}

// Returns the bot's throw target (if any) for the throw item of class 'throwableClass'
// Returned value can be an entity (in case the target is the tank), a vector with the target position (in case it's against an horde), null if no target
::Left4Bots.GetThrowTarget <- function (bot, userid, orig, throwableClass)
{
	// Is someone else already going to throw this?
	if (Left4Bots.IsSomeoneElseHolding(userid, throwableClass))
		return null; // Yes

	// No, go on...
	if (throwableClass == "weapon_molotov")
	{
		// Can we actually throw molotovs?
		if (!Left4Bots.Settings.throw_molotov || (Time() - Left4Bots.LastMolotovTime) < Left4Bots.Settings.throw_molotov_interval)
			return null; // No

		// Yes, but can we throw them at tanks right now?
		if (RandomInt(1, 100) > Left4Bots.Settings.tank_molotov_chance)
			return null; // No

		// Yes, let's find a target tank
		local nearestTank = Left4Bots.GetNearestVisibleTankWithin(bot, orig, Left4Bots.Settings.tank_throw_range_min, Left4Bots.Settings.tank_throw_range_max);

		// Should we throw the molotov at this tank?
		if (nearestTank && !nearestTank.IsOnFire() && !nearestTank.IsIncapacitated() && nearestTank.GetHealth() >= Left4Bots.Settings.tank_throw_min_health && !Left4Bots.AreOtherSurvivorsNearby(userid, nearestTank.GetOrigin(), Left4Bots.Settings.tank_throw_survivors_mindistance))
		{
			// Yes, let's do it...
			return nearestTank;
		}
		else
			return null;
	}
	else if (throwableClass == "weapon_vomitjar")
	{
		// Can we actually throw bile jars?
		if (!Left4Bots.Settings.throw_vomitjar || (Time() - Left4Bots.LastNadeTime) < Left4Bots.Settings.throw_nade_interval)
			return null; // No

		// Yes, but can we throw them at tanks right now?
		if (RandomInt(1, 100) <= Left4Bots.Settings.tank_vomitjar_chance)
		{
			// Yes, let's find a target tank
			local nearestTank = Left4Bots.GetNearestVisibleTankWithin(bot, orig, Left4Bots.Settings.tank_throw_range_min, Left4Bots.Settings.tank_throw_range_max);

			// Should we throw the bile jar at this tank?
			if (nearestTank && !nearestTank.IsOnFire() && !nearestTank.IsIncapacitated() && nearestTank.GetHealth() >= Left4Bots.Settings.tank_throw_min_health && !Left4Bots.AreOtherSurvivorsNearby(userid, nearestTank.GetOrigin(), Left4Bots.Settings.tank_throw_survivors_mindistance))
			{
				// Yes, let's do it...
				return nearestTank;
			}
		}

		// Ok, we can throw bile jars right now but not at tanks. Let's see if we need to throw it at hordes
		if (RandomInt(1, 100) > Left4Bots.Settings.horde_nades_chance || !NetProps.GetPropInt(bot, "m_hasVisibleThreats")) // NetProps.GetPropInt(bot, "m_clientIntensity") < 40
			return null; // No

		// Is there an actual horde?
		local common = Left4Bots.CheckAngryCommonsWithin(bot, orig, Left4Bots.Settings.horde_nades_size, Left4Bots.Settings.horde_nades_radius, Left4Bots.Settings.horde_nades_maxaltdiff);
		if (common == false)
			return null; // No

		// Yes
		if (common != true)
			return common.GetOrigin(); // We have the position of the farthest common of the horde

		// We don't have the position of the farthest common of the horde, we must find a target position ourselves
		local pos = Left4Utils.BotGetFarthestPathablePos(bot, Left4Bots.Settings.throw_nade_radius);
		if (pos && (pos - orig).Length() >= Left4Bots.Settings.throw_nade_mindistance)
			return pos; // Found

		return null;
	}
	else //if (throwableClass == "weapon_pipe_bomb")
	{
		// Can we actually throw pipe bombs?
		if (!Left4Bots.Settings.throw_pipebomb || (Time() - Left4Bots.LastNadeTime) < Left4Bots.Settings.throw_nade_interval)
			return null; // No

		// Yes, but can we throw them at hordes right now?
		if (RandomInt(1, 100) > Left4Bots.Settings.horde_nades_chance || !NetProps.GetPropInt(bot, "m_hasVisibleThreats")) // NetProps.GetPropInt(bot, "m_clientIntensity") < 40
			return null; // No

		// Is there an actual horde?
		local common = Left4Bots.CheckAngryCommonsWithin(bot, orig, Left4Bots.Settings.horde_nades_size, Left4Bots.Settings.horde_nades_radius, Left4Bots.Settings.horde_nades_maxaltdiff);
		if (common == false)
			return null; // No

		// Yes
		if (common != true)
			return common.GetOrigin(); // We have the position of the farthest common of the horde

		// We don't have the position of the farthest common of the horde, we must find a target position ourselves
		local pos = Left4Utils.BotGetFarthestPathablePos(bot, Left4Bots.Settings.throw_nade_radius);
		if (pos && (pos - bot.GetOrigin()).Length() >= Left4Bots.Settings.throw_nade_mindistance)
			return pos; // Found

		return null;
	}
}

// Should the throw of type 'throwType' still be going against 'throwTarget' with the item of class 'throwClass'?
::Left4Bots.ShouldStillThrow <- function (bot, userid, orig, throwType, throwTarget, throwClass)
{
	if (!throwTarget || throwType == AI_THROW_TYPE.None)
		return false;

	// No, go on...
	if (throwType == AI_THROW_TYPE.Tank)
	{
		// Is someone else already going to throw this?
		if (Left4Bots.IsSomeoneElseHolding(userid, throwClass))
			return false;

		// Can we actually throw this item?
		if ((throwClass == "weapon_molotov" && (!Left4Bots.Settings.throw_molotov || (Time() - Left4Bots.LastMolotovTime) < Left4Bots.Settings.throw_molotov_interval)) || (throwClass == "weapon_vomitjar" && (!Left4Bots.Settings.throw_vomitjar || (Time() - Left4Bots.LastNadeTime) < Left4Bots.Settings.throw_nade_interval)))
			return false; // No

		// Is the tank still a valid target?
		// TODO: add trace check?
		if (throwTarget.IsValid() && !throwTarget.IsDead() && !throwTarget.IsDying() && !throwTarget.IsIncapacitated() && !throwTarget.IsOnFire() && throwTarget.GetHealth() >= Left4Bots.Settings.tank_throw_min_health && !Left4Bots.AreOtherSurvivorsNearby(userid, throwTarget.GetOrigin(), Left4Bots.Settings.tank_throw_survivors_mindistance))
			return true; // Yes
	}
	else if (throwType == AI_THROW_TYPE.Horde)
	{
		// Is someone else already going to throw this?
		if (Left4Bots.IsSomeoneElseHolding(userid, throwClass))
			return false;

		// Can we actually throw this item?
		if ((throwClass == "weapon_pipe_bomb" && !Left4Bots.Settings.throw_pipebomb) || (throwClass == "weapon_vomitjar" && !Left4Bots.Settings.throw_vomitjar) || (Time() - Left4Bots.LastNadeTime) < Left4Bots.Settings.throw_nade_interval)
			return false; // No

		// Is there an actual horde?
		if (NetProps.GetPropInt(bot, "m_hasVisibleThreats") && Left4Bots.HasAngryCommonsWithin(orig, Left4Bots.Settings.horde_nades_size, Left4Bots.Settings.horde_nades_radius, Left4Bots.Settings.horde_nades_maxaltdiff)) // NetProps.GetPropInt(bot, "m_clientIntensity") < 40
			return true; // Yes
	}
	else //if (throwType == AI_THROW_TYPE.Manual)
	{
		// Can we actually throw this item?
		// TODO?

		return true;
	}
	return false;
}

// Makes the bot switch to the previous weapon (if any) or another weapon from primary or secondary slot
::Left4Bots.BotSwitchToAnotherWeapon <- function (bot)
{
	local last_weapon = NetProps.GetPropEntity(bot, "m_hLastWeapon");
	if (!last_weapon)
		last_weapon = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_PRIMARY);
	if (!last_weapon)
		last_weapon = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_SECONDARY);

	if (last_weapon)
		bot.SwitchToItem(last_weapon.GetClassname());
}

// Returns the closest survivor_death_model within 'radius' and 'maxAltDiff'
::Left4Bots.GetNearestDeathModelWithin <- function (player, orig, radius = 1000, maxAltDiff = 320)
{
	local ret = null;
	local minDist = 1000000;
	local isHuman = false;
	foreach (chr, death in ::Left4Bots.Deads)
	{
		if (death.dmodel.IsValid())
		{
			local human = (death.player && death.player.IsValid() && !IsPlayerABot(death.player));
			local dist = (orig - death.dmodel.GetOrigin()).Length();
			if (dist <= radius && Left4Utils.AltitudeDiff(player, death.dmodel) <= maxAltDiff && ((human && !isHuman) || (dist < minDist && (!isHuman || human)))) // Give humans higher priority
			{
				ret = death.dmodel;
				minDist = dist;
				isHuman = human;
			}
		}
	}
	return ret;
}

// Returns the closest survivor_death_model within 'radius' and 'maxAltDiff' with an available defibrillator nearby
::Left4Bots.GetNearestDeathModelWithDefibWithin <- function (player, orig, radius = 1000, maxAltDiff = 320)
{
	local ret = null;
	local minDist = 1000000;
	local isHuman = false;
	foreach (chr, death in ::Left4Bots.Deads)
	{
		if (death.dmodel.IsValid())
		{
			local human = (death.player && death.player.IsValid() && !IsPlayerABot(death.player));
			local dist = (orig - death.dmodel.GetOrigin()).Length();
			if (dist <= radius && Left4Utils.AltitudeDiff(player, death.dmodel) <= maxAltDiff && ((human && !isHuman) || (dist < minDist && (!isHuman || human))) && Left4Bots.FindDefibPickupWithin(death.dmodel.GetOrigin()) != null)
			{
				ret = death.dmodel;
				minDist = dist;
				isHuman = human;
			}
		}
	}
	return ret;
}

// Returns the first availble defibrillator near 'origin'
::Left4Bots.FindDefibPickupWithin <- function (origin)
{
	local ent = null;
	while (ent = Entities.FindByClassnameWithin(ent, "weapon_defibrillator", origin, Left4Bots.Settings.deads_scan_defibradius))
	{
		if (IsValidPickup(ent))
			return ent;
	}
}

// 'bot' will try to dodge the 'spit'
::Left4Bots.TryDodgeSpit <- function (bot, spit = null) // TODO: Improve (maybe just move to the position of a teammate who is not in spit radius)
{
	local p2 = bot.GetOrigin();
	local p1 = p2;
	if (spit)
		p1 = spit.GetOrigin();

	local i = 0;
	while ((p1 - p2).Length() <= Left4Bots.Settings.dodge_spit_radius && ++i <= 6)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, bot.GetPlayerName() + ".TryGetPathableLocationWithin - i = " + i);
		p2 = bot.TryGetPathableLocationWithin(Left4Bots.Settings.dodge_spit_radius + 150);
	}

	if (i > 0 && i <= 6)
		Left4Bots.BotHighPriorityMove(bot, p2);
}

// Checks whether the given bot is in the direction of the charger's charge and starts the dodge if needed
::Left4Bots.CheckShouldDodgeCharger <- function (bot, charger, chargerOrig, chargerLeft, chargerForwardY)
{
	if (!bot || !charger || !bot.IsValid() || !charger.IsValid())
		return;

	local toBot = bot.GetOrigin() - chargerOrig;
	toBot.Norm();

	local a = Left4Utils.GetDiffAngle(Left4Utils.VectorAngles(toBot).y, chargerForwardY);

	// a must be between -dodge_charger_diffangle and dodge_charger_diffangle. a > 0 -> the bot should run to the charger's left. a < 0 -> the bot should run to the charger's right
	if (a >= -Left4Bots.Settings.dodge_charger_diffangle && a <= Left4Bots.Settings.dodge_charger_diffangle)
		Left4Bots.TryDodge(bot, chargerLeft, a > 0, Left4Bots.Settings.dodge_charger_mindistance, Left4Bots.Settings.dodge_charger_maxdistance);
}

// 'bot' will try to dodge left o right
// 'leftVector' is a vector facing the current carger's left
// 'goLeft' tells whether the bot should run left (true) or right (false)
// 'minDistance' and 'maxDistance' are the minimum and maximum distance to travel
// Returns whether a dodge move location was found or not
::Left4Bots.TryDodge <- function (bot, leftVector, goLeft, minDistance, maxDistance)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - bot: " + bot.GetPlayerName() + " - goLeft: " + goLeft);

	//local startArea = NavMesh.GetNavArea(bot.GetCenter(), 300);
	local startArea = bot.GetLastKnownArea();

	local dest;
	if (goLeft)
		dest = bot.GetCenter() - (leftVector * minDistance);
	else
		dest = bot.GetCenter() + (leftVector * minDistance);

	local destArea =  NavMesh.GetNavArea(dest, 300);
	if (destArea && destArea.IsValid())
	{
		local d = NavMesh.NavAreaTravelDistance(startArea, destArea, maxDistance);
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - bot: " + bot.GetPlayerName() + " - d: " + d);

		if (d >= 0)
		{
			Left4Bots.Log(LOG_LEVEL_INFO, bot.GetPlayerName() + " trying to dodge");

			Left4Bots.BotHighPriorityMove(bot, Vector(dest.x, dest.y, destArea.GetZ(dest))); // Set the Z axis to ground level
			return true;
		}
	}
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - bot: " + bot.GetPlayerName() + " - nav area not found");

	// Preferred direction failed, let's try the other one (add some distance because we probably need to traver farther in this direction)
	if (goLeft)
		dest = bot.GetCenter() + (leftVector * (minDistance + 40)); // TODO: better calc that +40
	else
		dest = bot.GetCenter() - (leftVector * (minDistance + 40));

	local destArea =  NavMesh.GetNavArea(dest, 300);
	if (destArea && destArea.IsValid())
	{
		local d = NavMesh.NavAreaTravelDistance(startArea, destArea, maxDistance);
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - bot: " + bot.GetPlayerName() + " - d: " + d);

		if (d >= 0)
		{
			Left4Bots.Log(LOG_LEVEL_INFO, bot.GetPlayerName() + " trying to dodge");

			Left4Bots.BotHighPriorityMove(bot, Vector(dest.x, dest.y, destArea.GetZ(dest))); // Set the Z axis to ground level
			return true;
		}
	}
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - bot: " + bot.GetPlayerName() + " - nav area not found");

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - failed!");

	return false;
}

// Returns the survivor aimed by 'player' within 'radius' and with at least 'threshold' accuracy. visibleOnly = true if the aimed survivor must be visible to 'player'
::Left4Bots.GetPickerSurvivor <- function (player, radius = 999999, threshold = 0.95, visibleOnly = false)
{
	if (!player || !player.IsValid())
		return null;

	local userid = player.GetPlayerUserId();
	local orig = player.GetOrigin();
	local facing = player.EyeAngles().Forward();
	local bestDot = threshold;
	local bestEnt = null;
	foreach (id, surv in ::Left4Bots.Survivors)
	{
		local toEnt = surv.GetOrigin() - orig;
		if (id != userid && toEnt.Length() <= radius)
		{
			toEnt.Norm();
			local dot = facing.Dot(toEnt);
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, surv, Left4Bots.Settings.tracemask_others)))
			{
				bestDot = dot;
				bestEnt = surv;
			}
		}
	}
	return bestEnt;
}

// Returns the bot aimed by 'player' within 'radius' and with at least 'threshold' accuracy. visibleOnly = true if the aimed bot must be visible to 'player'
::Left4Bots.GetPickerBot <- function (player, radius = 999999, threshold = 0.95, visibleOnly = false)
{
	if (!player || !player.IsValid())
		return null;

	local userid = player.GetPlayerUserId();
	local orig = player.GetOrigin();
	local facing = player.EyeAngles().Forward();
	local bestDot = threshold;
	local bestEnt = null;
	foreach (id, surv in ::Left4Bots.Bots)
	{
		local toEnt = surv.GetOrigin() - orig;
		if (id != userid && toEnt.Length() <= radius)
		{
			toEnt.Norm();
			local dot = facing.Dot(toEnt);
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, surv, Left4Bots.Settings.tracemask_others)))
			{
				bestDot = dot;
				bestEnt = surv;
			}
		}
	}
	return bestEnt;
}

// Returns the witch aimed by 'player' within 'radius' and with at least 'threshold' accuracy. visibleOnly = true if the aimed witch must be visible to 'player'
::Left4Bots.GetPickerWitch <- function (player, radius = 999999, threshold = 0.95, visibleOnly = false)
{
	if (!player || !player.IsValid())
		return null;

	local userid = player.GetPlayerUserId();
	local orig = player.GetOrigin();
	local facing = player.EyeAngles().Forward();
	local bestDot = threshold;
	local bestEnt = null;
	foreach (witch in ::Left4Bots.Witches)
	{
		local toEnt = witch.GetOrigin() - orig;
		if (toEnt.Length() <= radius)
		{
			toEnt.Norm();
			local dot = facing.Dot(toEnt);
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, witch, Left4Bots.Settings.tracemask_others)))
			{
				bestDot = dot;
				bestEnt = witch;
			}
		}
	}
	return bestEnt;
}

// Remove all the ticking pipe bombs from the map to prevent the infamous bug
::Left4Bots.ClearPipeBombs <- function ()
{
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "pipe_bomb_projectile"))
	{
		if (ent.IsValid())
		{
			Left4Bots.Log(LOG_LEVEL_DEBUG, "ClearPipeBombs - Killing pipe_bomb_projectile");
			ent.Kill();
		}
	}
}

// Are all the other alive survivors (except the one with the given userid) in a checkpoint?
::Left4Bots.OtherSurvivorsInCheckpoint <- function (userid)
{
	foreach (id, surv in ::Left4Bots.Survivors)
	{
		if (id != userid && surv.IsValid())
		{
			local area = surv.GetLastKnownArea();
			if (!area || !area.HasSpawnAttributes(NAVAREA_SPAWNATTR_CHECKPOINT))
			// if (ResponseCriteria.GetValue(surv, "incheckpoint") != "1")  // <- doesn't work with bots
			{
				Left4Bots.Log(LOG_LEVEL_DEBUG, "AllSurvivorsInCheckpoint - " + surv.GetPlayerName() + " is not in checkpoint");
				return false;
			}
		}
	}
	Left4Bots.Log(LOG_LEVEL_DEBUG, "AllSurvivorsInCheckpoint - All survivors in checkpoint");
	return true;
}

// Are there enough spare medkits around for the teammates who need them and for 'me'?
::Left4Bots.HasSpareMedkitsAround <- function (me)
{
	local requiredMedkits = 1;
	foreach (surv in Left4Bots.GetOtherAliveSurvivors(me.GetPlayerUserId()))
	{
		if (surv.GetHealth() < 75 || !Left4Utils.HasMedkit(surv))
			requiredMedkits++;
	}

	Left4Bots.Log(LOG_LEVEL_DEBUG, "HasSpareMedkitsAround - me: " + me.GetPlayerName() + " - requiredMedkits: " + requiredMedkits);

	local count = 0;
	local ent = null;
	// Note: we are counting both weapon_first_aid_kit and weapon_first_aid_kit_spawn
	while (ent = Entities.FindByClassnameWithin(ent, "weapon_first_aid_kit*", me.GetOrigin(), Left4Bots.Settings.heal_spare_medkits_radius))
	{
		if (Left4Bots.IsValidPickup(ent))
		{
			if (++count >= requiredMedkits)
				return true;
		}
	}
	return false;
}

// Makes the given bot say the given line in chat
::Left4Bots.SayLine <- function (bot, line)
{
	if (bot && bot.IsValid())
		Say(bot, line, false);
}

// Checks the healing target of the given bot. If it's not the same of the given 'heal' order, it cancels the healing and makes the bot retry after a few seconds
// It is automatically called by the 'heal' order logics
::Left4Bots.CheckHealingTarget <- function (bot, order)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "CheckHealingTarget");

	if (!bot || !order || !bot.IsValid())
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "CheckHealingTarget - bot: " + bot.GetPlayerName());

	local target = NetProps.GetPropEntity(bot, "m_useActionTarget");
	if (!IsPlayerABot(bot) || !target || !order.DestEnt || !order.DestEnt.IsValid() || target.GetPlayerUserId() != order.DestEnt.GetPlayerUserId())
	{
		// Cancel

		Left4Bots.Log(LOG_LEVEL_DEBUG, "CheckHealingTarget - Cancel healing");

		// Unforce buttons + unfreeze player
		NetProps.SetPropInt(bot, "m_afButtonForced", NetProps.GetPropInt(bot, "m_afButtonForced") & (~(BUTTON_SHOVE + BUTTON_ATTACK)));
		NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN

		// Retry, but only after the timed unforce+unfreeze of the previous button press have done, otherwise the new heal will be interrupted
		if (IsPlayerABot(bot))
			Left4Timers.AddTimer(null, Left4Bots.Settings.button_holdtime_heal - 0.5, @(params) Left4Bots.BotOrderRetry(params.bot, params.order), { bot = bot, order = order });
	}
}

// Returns the closest bot to the given origin. The bot must be able to move (not incapped, pinned or something)
::Left4Bots.GetNearestMovingBot <- function (orig)
{
	local ret = null;
	local dist = 1000000;
	foreach (bot in Left4Bots.Bots)
	{
		if (!Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			local d = (bot.GetOrigin() - orig).Length();
			if (d < dist)
			{
				ret = bot;
				dist = d;
			}
		}
	}
	return ret;
}

// Returns the bot with a medkit who is closest to the given origin
::Left4Bots.GetNearestBotWithMedkit <- function (orig)
{
	local ret = null;
	local dist = 1000000;
	foreach (bot in Left4Bots.Bots)
	{
		if (!bot.IsIncapacitated() && Left4Utils.HasMedkit(bot))
		{
			local d = (bot.GetOrigin() - orig).Length();
			if (d < dist)
			{
				ret = bot;
				dist = d;
			}
		}
	}
	return ret;
}

// Returns the bot with a medkit who is lowest on health
::Left4Bots.GetLowestHPBotWithMedkit <- function ()
{
	local ret = null;
	local hp = 1000000;
	foreach (bot in Left4Bots.Bots)
	{
		if (!bot.IsIncapacitated() && Left4Utils.HasMedkit(bot))
		{
			local h = bot.GetHealth() + bot.GetHealthBuffer();
			if (h < hp)
			{
				ret = bot;
				hp = h;
			}
		}
	}
	return ret;
}

// Checks whether the given player should deploy the carried upgrade pack (if any)
// Returns the class name of the upgrade pack to deploy or null if can't/shouldn't deploy now
// query is the OnConcept query
::Left4Bots.ShouldDeployUpgrades <- function (player, query)
{
	if (!player || !player.IsValid())
		return null;

	local item = Left4Utils.GetInventoryItemInSlot(player, INV_SLOT_MEDKIT);
	if (!item)
		return null;

	local itemClass = item.GetClassname();
	if (itemClass != "weapon_upgradepack_incendiary" && itemClass != "weapon_upgradepack_explosive")
		return null;

	if ((("incheckpoint" in query) && query.incheckpoint != 0) || (("BotIsNearCheckpoint" in query) && query.BotIsNearCheckpoint != 0) || (("incombat" in query) && query.incombat != 0) || (("InCombatMusic" in query) && query.InCombatMusic != 0))
		return null;

	if ((("incapacitated" in query) && query.incapacitated != 0) || (("hangingfromledge" in query) && query.hangingfromledge != 0) || (("onfire" in query) && query.onfire != 0) || (("beinghealed" in query) && query.beinghealed != 0))
		return null;

	if ((("hangingfromtongue" in query) && query.hangingfromtongue != 0) || (("pouncevictim" in query) && query.pouncevictim != 0) || (("beingjockeyed" in query) && query.beingjockeyed != 0))
		return null;

	if (("activeweapon" in query) && (query.activeweapon == "UpgradePack_Incendiary" || query.activeweapon == "UpgradePack_Explosive"))
		return null;

	if ((!("instartarea" in query) || query.instartarea == 0) && (!("disttoclosestsurvivor" in query) || query.disttoclosestsurvivor > 100))
		return null;

	local primary = Left4Utils.GetInventoryItemInSlot(player, INV_SLOT_PRIMARY);
	if (primary && NetProps.GetPropInt(primary, "m_nUpgradedPrimaryAmmoLoaded") > 5)
		return null;

	if (Left4Bots.SurvivorsHeldOrIncapped())
		return null;

	return itemClass;
}

// Finalize the upgrade pack deploy procedure
::Left4Bots.DoDeployUpgrade <- function (player)
{
	if (!player || !player.IsValid())
		return;

	local item = player.GetActiveWeapon();
	if (!item)
		return;

	local itemClass = item.GetClassname();

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + player.GetPlayerName() + " switched to upgrade " + itemClass);

	if (itemClass != "weapon_upgradepack_incendiary" && itemClass != "weapon_upgradepack_explosive")
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + player.GetPlayerName() + " deploying upgrade " + itemClass);

	Left4Utils.PlayerPressButton(player, BUTTON_ATTACK, 2.2, null, 0, 0, true);
}

// Think function that is attached to any spawned tank rock
// It triggers the dodging for the bots who are in its trajectory
::Left4Bots.L4B_RockThink <- function ()
{
	/*
	- m_hThrower
	- m_DmgRadius
	- m_flDamage
	*/

	// Wait until the rock left the tank's hands
	if (NetProps.GetPropInt(self, "m_hMoveParent") >= 0)
		return 0.01;

	//Left4Bots.Log(LOG_LEVEL_DEBUG, "L4B_RockThink");

	local MyPos = self.GetCenter();

	//local fwd = self.GetForwardVector();
	local fwd = self.GetAngles().Forward();
	fwd.Norm();
	local fwdY = Left4Utils.VectorAngles(fwd).y;
	local lft = self.GetAngles().Left();

	//fwd = Vector(fwd.x, fwd.y, 0);

	//DebugDrawLine_vCol(MyPos, MyPos + (fwd * 30), Vector(0, 255, 0), true, 5.0);

	foreach (id, bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid())
		{
			local distance = (bot.GetCenter() - MyPos).Length();
			if (distance <= 1500 && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting) && Left4Utils.CanTraceTo(bot, self, Left4Bots.Settings.tracemask_others))
			{
				local toBot = bot.GetCenter() - MyPos;
				toBot.Norm();

				local a = Left4Utils.GetDiffAngle(Left4Utils.VectorAngles(toBot).y, fwdY);

				/*
					- if dodge_rock is true and the bot has a dodge move location, then dodge
					- if shoot_rock is true and the bot did not (or did not yet) dodge for any reason, then shoot
				*/

				// a must be between -dodge_rock_diffangle and dodge_rock_diffangle. a > 0 -> the bot should run to the rock's left. a < 0 -> the bot should run to the rock's right
				if (!(id in DodgingBots) && Left4Bots.Settings.dodge_rock && a >= -Left4Bots.Settings.dodge_rock_diffangle && a <= Left4Bots.Settings.dodge_rock_diffangle && Left4Bots.TryDodge(bot, lft, a > 0, Left4Bots.Settings.dodge_rock_mindistance, Left4Bots.Settings.dodge_rock_maxdistance))
					DodgingBots[id] <- 1;
				else if (Left4Bots.Settings.shoot_rock && a >= -Left4Bots.Settings.shoot_rock_diffangle && a <= Left4Bots.Settings.shoot_rock_diffangle)
				{
					local aw = bot.GetActiveWeapon();
					if (aw && aw.IsValid() && Time() >= NetProps.GetPropFloat(aw, "m_flNextPrimaryAttack") && distance <= Left4Bots.GetWeaponRangeById(Left4Utils.GetWeaponId(aw)))
					{
						Left4Utils.PlayerPressButton(bot, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, self.GetCenter() + (fwd * Left4Bots.Settings.shoot_rock_ahead), 0, 0, true); // Try to shoot slightly in front of the rock

						Left4Bots.Log(LOG_LEVEL_DEBUG, bot.GetPlayerName() + " shooting at rock " + self.GetEntityIndex());
					}
				}
			}
		}
	}

	return 0.01;
}

// Loads the given survivor weapon preference file and returns an array with 5 elements (one for each inventory slot)
// Each element is a sub-array with the weapon list from the highest to the lowest priority one for that inventory slot
::Left4Bots.LoadWeaponPreferences <- function (survivor)
{
	// Main array has one sub-array for each inventory slot
	// Each sub-array contains the weapons from the highest to the lowest priority one for that inventory slot
	local ret = [[], [], [], [], []];

	if (!survivor || !survivor.IsValid())
		return ret;

	//Left4Bots.Log(LOG_LEVEL_DEBUG, "LoadWeaponPreferences - survivor: " + survivor.GetPlayerName());

	//local filename = Left4Bots.Settings.file_weapons_prefix + survivor.GetPlayerName().tolower() + ".txt";
	local filename = Left4Bots.Settings.file_weapons_prefix + GetCharacterDisplayName(survivor).tolower() + ".txt";
	local lines = Left4Utils.FileToStringList(filename);
	if (!lines)
		return ret;

	for (local i = 0; i < lines.len(); i++)
	{
		local line = Left4Utils.StripComments(lines[i]);
		if (line != "")
		{
			local weaps = split(line, ",");
			for (local x = 0; x < weaps.len(); x++)
			{
				local id = Left4Utils.GetWeaponIdByName(weaps[x]);

				//Left4Bots.Log(LOG_LEVEL_DEBUG, "LoadWeaponPreferences - i: " + i + " - w: " + weaps[x] + " - id: " + id);

				if (id > Left4Utils.WeaponId.none && id != Left4Utils.MeleeWeaponId.none && id != Left4Utils.UpgradeWeaponId.none)
					ret[i].append(id); // valid weapon
			}
		}
	}

	Left4Bots.Log(LOG_LEVEL_DEBUG, "LoadWeaponPreferences - Loaded " + ret.len() + " preferences for survivor: " + survivor.GetPlayerName() + " from file: " + filename);

	return ret;
}

// Loads the vocalizer-bot command mappings from the given file
::Left4Bots.LoadVocalizerCommandsFromFile <- function (fileName)
{
	local ret = {};

	local mappings = Left4Utils.FileToStringList(fileName);
	if (!mappings)
		return ret;

	foreach (mapping in mappings)
	{
		//Left4Bots.Log(LOG_LEVEL_DEBUG, mapping);
		mapping = Left4Utils.StringReplace(mapping, "\\t", "");
		mapping = Left4Utils.StripComments(mapping);
		if (mapping && mapping != "")
		{
			mapping = strip(mapping);
			//Left4Bots.Log(LOG_LEVEL_DEBUG, mapping);

			if (mapping && mapping != "")
			{
				local idx = mapping.find("=");
				if (idx != null)
				{
					local command = mapping.slice(0, idx);
					command = Left4Utils.StringReplace(command, "\"", "");
					command = strip(command);
					//Left4Bots.Log(LOG_LEVEL_DEBUG, command);

					local value = mapping.slice(idx + 1);
					value = Left4Utils.StringReplace(value, "\"", "");
					value = strip(value);

					//Left4Bots.Log(LOG_LEVEL_DEBUG, "MAPPING: " + command + " = " + value);

					ret[command] <- value;
					/*
					if (!(command in ret))
						ret[command] <- [];
					ret[command].append(value); // Allowing multiple commands for each vocalizer line
					*/
				}
			}
		}
	}

	return ret;
}

// Is the entity a valid pick up?
::Left4Bots.IsValidPickup <- function (ent)
{
	if (!ent || !ent.IsValid())
		return false;

	if (ent.GetClassname().find("_spawn") != null)
	{
		// It's a spawner, we just check if the item count is still > 0
		return (NetProps.GetPropInt(ent, "m_itemCount") > 0);
	}
	else
	{
		// It's the item itself, let's check if someone already picked it up
		return (ent.GetMoveParent() == null /*&& NetProps.GetPropInt(ent, "m_iState") != 1*/); // The melee has this to 1 while it's replaced by the pistol when you are incapped but "in theory" this shouldn't be needed because moveparent doesn't change
	}
}

// Is the entity a valid use item?
::Left4Bots.IsValidUseItem <- function (ent, allowedMoveParent = null)
{
	if (!ent || !ent.IsValid())
		return false;

	//Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidUseItem - allowedMoveParent: " + allowedMoveParent);

	local cls = ent.GetClassname();
	if (cls.find("weapon_") != null || cls == "prop_physics")
	{
		if (cls.find("_spawn") != null)
			return (NetProps.GetPropInt(ent, "m_itemCount") > 0); // It's a spawner, we just check if the item count is still > 0

		local mp = ent.GetMoveParent();
		return (mp == null || mp == allowedMoveParent); // It's the item itself, check if someone already picked it up
	}

	return true;
	//return (cls.find("func_button") != null || cls.find("prop_door_rotating") != null || cls == "trigger_finale" || cls == "prop_minigun" || cls == "prop_dynamic")
}

// Returns the nearest usable entity within the given radius from origin
::Left4Bots.FindNearestUsable <- function (orig, radius)
{
	local ret = null;
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindInSphere(ent, orig, radius))
	{
		if (Left4Bots.IsValidUseItem(ent))
		{
			local dist = (ent.GetCenter() - orig).Length();
			local entClass = ent.GetClassname();
			if (dist < minDist && (entClass.find("weapon_") != null || entClass.find("prop_physics") != null || entClass.find("prop_minigun") != null || entClass.find("func_button") != null || (entClass.find("trigger_finale") != null && NetProps.GetPropInt(ent, "m_bDisabled") == 0) || entClass.find("prop_door_rotating") != null) && entClass != "weapon_scavenge_item_spawn" && entClass != "weapon_gascan_spawn")
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Returns the nearest carriable item within the given radius from origin
::Left4Bots.FindNearestCarriable <- function (orig, radius)
{
	local ret = null;
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindInSphere(ent, orig, radius))
	{
		if (Left4Bots.IsValidUseItem(ent))
		{
			local dist = (ent.GetCenter() - orig).Length();
			local entClass = ent.GetClassname();
			if (dist < minDist && /*(entClass.find("weapon_") != null || entClass.find("prop_physics") != null) &&*/ entClass != "weapon_scavenge_item_spawn" && entClass != "weapon_gascan_spawn" && Left4Utils.GetWeaponSlotById(Left4Utils.GetWeaponId(ent)) == 5)
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Returns the nearest deployable item within the given radius from origin
::Left4Bots.FindNearestDeployable <- function (orig, radius)
{
	local ret = null;
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindInSphere(ent, orig, radius))
	{
		if (Left4Bots.IsValidUseItem(ent))
		{
			local dist = (ent.GetCenter() - orig).Length();
			local entClass = ent.GetClassname();
			if (dist < minDist && (entClass.find("weapon_upgradepack_explosive") != null || entClass.find("weapon_upgradepack_incendiary") != null))
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Returns the nearest scavenge item within the given radius from origin
::Left4Bots.FindNearestScavengeItem <- function (orig, radius)
{
	local ret = null;
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindInSphere(ent, orig, radius))
	{
		if (Left4Bots.IsValidUseItem(ent))
		{
			local dist = (ent.GetCenter() - orig).Length();
			local entClass = ent.GetClassname();
			local wId = Left4Utils.GetWeaponId(ent);
			if (dist < minDist && /*(entClass.find("weapon_") != null || entClass.find("prop_physics") != null) &&*/ entClass != "weapon_scavenge_item_spawn" && entClass != "weapon_gascan_spawn" && ((Left4Bots.ScavengeUseType == SCAV_TYPE_GASCAN && wId == Left4Utils.WeaponId.weapon_gascan) || (Left4Bots.ScavengeUseType == SCAV_TYPE_COLA && wId == Left4Utils.WeaponId.weapon_cola_bottles)))
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Finds the best position for the bot to stand while using the given use target
::Left4Bots.FindBestUseTargetPos <- function (useTarget, orig = null, angl = null, fwdFailsafe = true, debugShow = false, debugShowTime = 15)
{
	local ret = null;
	if (!useTarget || !useTarget.IsValid())
		return ret;

	if (!orig)
		orig = useTarget.GetCenter();
	if (!angl)
		angl = useTarget.GetAngles();
	angl = QAngle(0, angl.Yaw(), 0);
	local grounds = [];

	grounds.append(Left4Utils.FindGround(orig, angl, 315, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 0, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 45, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 90, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 135, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 180, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 225, debugShow, debugShowTime));
	grounds.append(Left4Utils.FindGround(orig, angl, 270, debugShow, debugShowTime));
	grounds.append(grounds[0]);
	grounds.append(grounds[1]);

	for (local i = 1; i < grounds.len() - 1; i++)
	{
		if (grounds[i - 1] != null && grounds[i] != null && grounds[i + 1] != null)
		{
			ret = grounds[i];
			break;
		}
	}

	if (ret == null)
	{
		for (local i = 1; i < grounds.len() - 1; i++)
		{
			if (grounds[i] != null)
			{
				ret = grounds[i];
				break;
			}
		}
	}

	if (ret == null && fwdFailsafe)
		ret = Left4Utils.FindGroundFrom(orig + (angl.Forward() * 45), FINDGROUND_MAXHEIGHT, FINDGROUND_MINFRACTION).pos;

	if (ret != null && debugShow)
		DebugDrawLine_vCol(orig, ret, Vector(0, 0, 255), true, debugShowTime);

	return ret;
}

// Returns the "range" of the weapon with the given id
::Left4Bots.GetWeaponRangeById <- function (weaponId)
{
	if (weaponId > Left4Utils.MeleeWeaponId.none || weaponId == Left4Utils.WeaponId.weapon_chainsaw)
	{
		if (Left4Bots.Settings.manual_attack_radius < 150)
			return Left4Bots.Settings.manual_attack_radius;
		else
			return 150;
	}

	if (weaponId == Left4Utils.WeaponId.weapon_pumpshotgun || weaponId == Left4Utils.WeaponId.weapon_autoshotgun || weaponId == Left4Utils.WeaponId.weapon_shotgun_chrome || weaponId == Left4Utils.WeaponId.weapon_shotgun_spas)
	{
		if (Left4Bots.Settings.manual_attack_radius < 600)
			return Left4Bots.Settings.manual_attack_radius;
		else
			return 600;
	}

	return Left4Bots.Settings.manual_attack_radius;
}

// Returns whether the given bot has visibility on the given pickup item
::Left4Bots.CanTraceToPickup <- function (bot, item)
{
	//local mask = 0x1 | 0x8 | 0x40 | 0x2000 | 0x4000  | 0x8000000; // CONTENTS_SOLID | CONTENTS_GRATE | CONTENTS_BLOCKLOS | CONTENTS_IGNORE_NODRAW_OPAQUE | CONTENTS_MOVEABLE | CONTENTS_DETAIL
	local traceTable = { start = bot.EyePosition(), end = item.GetCenter(), ignore = bot, mask = Left4Bots.Settings.tracemask_pickups };

	TraceLine(traceTable);

	//printl("fraction: " + traceTable.fraction);
	//DebugDrawCircle(traceTable.pos, Vector(0, 0, 255), 255, 10, true, 0.1);

	return (traceTable.fraction > 0.98 || !traceTable.hit || !traceTable.enthit || traceTable.enthit == item || traceTable.enthit.GetClassname() == "prop_health_cabinet");
}

// Starts the scavenge logics
::Left4Bots.ScavengeStart <- function ()
{
	if (Left4Bots.ScavengeStarted)
		return; // Already started

	if (!Left4Bots.SetScavengeUseTarget())
		return; // No use target/pos available

	Left4Bots.ScavengeStarted = true;

	// Start the scavenge manager
	Left4Timers.AddTimer("ScavengeManager", Left4Bots.Settings.scavenge_manager_interval, Left4Bots.OnScavengeManager, {}, true);

	Left4Bots.Log(LOG_LEVEL_INFO, "Scavenge started");
}

// Stops the scavenge logics
::Left4Bots.ScavengeStop <- function ()
{
	if (!Left4Bots.ScavengeStarted)
		return; // Already stopped

	Left4Bots.ScavengeStarted = false;

	// Stop the scavenge manager
	Left4Timers.RemoveTimer("ScavengeManager");

	Left4Bots.ScavengeUseTarget = null;
	Left4Bots.ScavengeUseTargetPos = null;
	Left4Bots.ScavengeUseType = 0;
	Left4Bots.ScavengeBots.clear();

	// Cancel any pending scavenge order
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot && bot.IsValid())
			bot.GetScriptScope().BotCancelOrders("scavenge");
	}

	Left4Bots.Log(LOG_LEVEL_INFO, "Scavenge stopped");
}

// Finds/Sets the scavenge use target
::Left4Bots.SetScavengeUseTarget <- function ()
{
	//Left4Bots.Log(LOG_LEVEL_DEBUG, "SetScavengeUseTarget");

	// TODO: get it from automation?
	Left4Bots.ScavengeUseTarget = Entities.FindByClassname(null, "point_prop_use_target");
	if (!Left4Bots.ScavengeUseTarget)
		return false;

	Left4Bots.ScavengeUseType = NetProps.GetPropInt(Left4Bots.ScavengeUseTarget, "m_spawnflags");

	if (Left4Bots.ScavengeUseType == SCAV_TYPE_GASCAN)
		Left4Bots.Log(LOG_LEVEL_INFO, "Scavenge use target found (type: Gascan)");
	else if (Left4Bots.ScavengeUseType == SCAV_TYPE_COLA)
		Left4Bots.Log(LOG_LEVEL_INFO, "Scavenge use target found (type: Cola)");
	else
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "Unsupported scavenge use target type: " + Left4Bots.ScavengeUseType + "; switching to type: Gascan");

		Left4Bots.ScavengeUseType = SCAV_TYPE_GASCAN;
	}

	// TODO: get it from automation
	Left4Bots.ScavengeUseTargetPos = Left4Bots.FindBestUseTargetPos(Left4Bots.ScavengeUseTarget, null, null, true, Left4Bots.Settings.scavenge_usetarget_debug);
	if (!Left4Bots.ScavengeUseTargetPos)
	{
		Left4Bots.ScavengeUseTarget = null;
		Left4Bots.ScavengeUseType = 0;
		return false;
	}

	return true;
}

// Returns the list of scavenge items of type 'type'
::Left4Bots.GetAvailableScavengeItems <- function (type)
{
	//	- Spawned gascans have class "weapon_gascan" when they have been picked up by players; after spawn too but i'm not 100% sure.
	//	  They can have different m_nSkin (default is 0).
	//	  In scavenge maps (regardless the gamemode) they are spawned by weapon_scavenge_item_spawn
	//
	//	- cola's class can be "prop_physics" after spawn but it becomes "weapon_cola_bottles" after being picked up by a player; model should be always the same.

	local model = "models/props_junk/gascan001a.mdl";
	if (type == SCAV_TYPE_COLA)
		model = "models/w_models/weapons/w_cola.mdl";

	local t = {};
	local ent = null;
	local i = -1;
	while (ent = Entities.FindByModel(ent, model))
	{
		if (ent.IsValid() && (Left4Bots.Settings.scavenge_pour || (ent.GetOrigin() - Left4Bots.ScavengeUseTarget.GetOrigin()).Length() >= Left4Bots.Settings.scavenge_drop_radius) && Left4Bots.IsValidPickup(ent) && !Left4Bots.BotsHaveOrderDestEnt(ent))
			t[++i] <- ent;
	}
	return t;
}

// Makes the given 'player' (likely a survivor bot) trigger the given 'alarm' (prop_car_alarm)
::Left4Bots.TriggerCarAlarm <- function (player, alarm)
{
	if (!player || !alarm || !player.IsValid() || !alarm.IsValid() || alarm.GetClassname() != "prop_car_alarm" || Left4Bots.IsCarAlarmTriggered(alarm))
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "TriggerCarAlarm - player: " + player.GetPlayerName());

	DoEntFire("!self", "SurvivorStandingOnCar", "", 0, alarm, alarm); // Activator is who triggers the alarm but it doesn't work with bots. This way it triggers but i need to play the vocalizer lines manually.

	local actor = Left4Utils.GetActorFromSurvivor(player);

	player.SetContext("subject", actor, 0.1);
	player.SetContext("panictype", "CarAlarm", 0.1);
	//DoEntFire("!self", "AddContext", "subject:" + actor, 0, null, player);
	//DoEntFire("!self", "AddContext", "panictype:CarAlarm", 0, null, player);
	DoEntFire("!self", "SpeakResponseConcept", "PanicEvent", 0, null, player);
	//DoEntFire("!self", "ClearContext", "", 0, null, player);

	foreach (surv in ::Left4Bots.GetOtherAliveSurvivors(player.GetPlayerUserId()))
	{
		surv.SetContext("subject", actor, 0.1);
		surv.SetContext("panictype", "CarAlarm", 0.1);
		//DoEntFire("!self", "AddContext", "subject:" + actor, 0, null, surv);
		//DoEntFire("!self", "AddContext", "panictype:CarAlarm", 0, null, surv);
		DoEntFire("!self", "SpeakResponseConcept", "PanicEvent", 0, null, surv);
		//DoEntFire("!self", "ClearContext", "", 0, null, surv);
	}
}

// Returns whether the given 'alarm' (prop_car_alarm) is already triggered
::Left4Bots.IsCarAlarmTriggered <- function (alarm)
{
	if (!alarm || !alarm.IsValid())
		return false;

	if (NetProps.GetPropInt(alarm, "m_bDisabled"))
		return true;

	local ambient_generic = null;
	while (ambient_generic = Entities.FindByClassname(ambient_generic, "ambient_generic"))
	{
		if (NetProps.GetPropString(ambient_generic, "m_sSourceEntName") == alarm.GetName() && NetProps.GetPropString(ambient_generic, "m_iszSound") == "Car.Alarm" && NetProps.GetPropInt(ambient_generic, "m_fActive"))
			return true;
	}
	return false;
}

// Creates a script_nav_blocker on the landed spitter's spit and parents it to the spit's entity so it's automatically removed once the spit is gone
// Must set params["spit_ent"] as the spit's entity
::Left4Bots.SpitterSpitBlockNav <- function (params)
{
	local spit = params["spit_ent"];
	if (!spit || !spit.IsValid())
		return;

	local kvs = { classname = "script_nav_blocker", origin = spit.GetOrigin(), extent = Vector(Left4Bots.Settings.dodge_spit_radius, Left4Bots.Settings.dodge_spit_radius, Left4Bots.Settings.dodge_spit_radius), teamToBlock = "2", affectsFlow = "0" };
	local ent = g_ModeScript.CreateSingleSimpleEntityFromTable(kvs);
	ent.ValidateScriptScope();
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Created script_nav_blocker: " + ent.GetName());

	DoEntFire("!self", "SetParent", "!activator", 0, spit, ent); // I parent the nav blocker to the spit entity so it is automatically killed when the spit is gone
	DoEntFire("!self", "BlockNav", "", 0, null, ent);
}

// Returns whether the given *_spawn entity has available items to spawn (m_itemCount > minCount or it's set to infinite items)
::Left4Bots.SpawnerHasItems <- function (spawner_ent, minCount = 0)
{
	// Note: m_itemCount has already been decreased by 1 when OnPlayerUse is triggered (but not when it's called from PickupFailsafe)

	local m_itemCount = NetProps.GetPropInt(spawner_ent, "m_itemCount");
	local m_spawnflags = NetProps.GetPropInt(spawner_ent, "m_spawnflags");

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.SpawnerHasItems - " + spawner_ent + " - m_itemCount: " + m_itemCount + " - m_spawnflags: " + m_spawnflags + " - minCount: " + minCount);

	// item count > 0 or infinite items in spawn flags
	return (m_itemCount > minCount || (m_spawnflags & 8) == 8);
}

// Is there any human within the given range from 'srcBot' who may need to pick-up ammo?
Left4Bots.HumansNeedAmmo <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying())
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist && Left4Utils.GetPrimaryAmmoPercent(surv) < 85.0)
				return true;
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up this weapon?
Left4Bots.HumansNeedWeapon <- function (srcBot, weaponId, minDist = 250.0, maxDist = 2500.0)
{
	local tier = Left4Utils.GetWeaponTierById(weaponId);

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.HumansNeedWeapon - weaponId: " + weaponId + " - tier: " + tier);

	if (tier <= 0)
		return false;

	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying())
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist)
			{
				local w = Left4Utils.GetInventoryItemInSlot(surv, INV_SLOT_PRIMARY);
				if (!w || !w.IsValid())
					return true;

				local wt = Left4Utils.GetWeaponTierByClass(w.GetClassname())

				Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.HumansNeedWeapon - w: " + w.GetClassname() + " - wt: " + wt);

				if (wt < tier)
					return true;
			}
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up a medkit?
Left4Bots.HumansNeedMedkit <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying())
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist)
			{
				// TODO?

				return true;
			}
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up pills or adrenaline?
Left4Bots.HumansNeedTempMed <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying() && Left4Utils.GetInventoryItemInSlot(surv, INV_SLOT_PILLS) == null)
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist)
				return true;
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up throwables?
Left4Bots.HumansNeedThrowable <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying() && Left4Utils.GetInventoryItemInSlot(surv, INV_SLOT_THROW) == null)
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist)
				return true;
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up explosive or incendiary ammo?
Left4Bots.HumansNeedUpgradeAmmo <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying())
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist)
			{
				// TODO?

				return true;
			}
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up the laser sight?
Left4Bots.HumansNeedLaserSight <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	local orig = srcBot.GetOrigin();
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv) && !surv.IsDead() && !surv.IsDying() && !Left4Utils.HasLaserSight(surv))
		{
			local d = (surv.GetOrigin() - orig).Length();
			if (d >= minDist && d <= maxDist)
				return true;
		}
	}
	return false;
}

// Returns the first weapon_first_aid_kit_spawn (with items to spawn) whithin 'radius' from 'srcSpawn' (weapon_first_aid_kit_spawn)
Left4Bots.GetOtherMedkitSpawn <- function (srcSpawn, radius = 100.0)
{
	local ent = null;
	while (ent = Entities.FindByClassnameWithin(ent, "weapon_first_aid_kit_spawn", srcSpawn.GetOrigin(), radius))
	{
		if (ent.IsValid() && ent.GetEntityIndex() != srcSpawn.GetEntityIndex() && Left4Bots.SpawnerHasItems(ent))
			return ent;
	}
	return null;
}

// Makes the given survivor signal the given item
// who = the player entity of the survivor (likely a bot)
// what = the entity of the item to signal
// concept = the SpeakResponseConcept concept to vocalize
// weaponname = the class name of the weapon (used as "weaponname" context for the SpeakResponseConcept)
// chatText = text to chat
::Left4Bots.DoSignal <- function (who, what, concept, weaponname = null, chatText = null)
{
	local signalType = concept;
	if (weaponname)
		signalType = signalType + ":" + weaponname;

	local t = Time();
	if (Left4Bots.LastSignalType == signalType && (t - Left4Bots.LastSignalTime) <= Left4Bots.Settings.signal_min_interval)
		return;

	Left4Bots.LastSignalType = signalType;
	Left4Bots.LastSignalTime = t;

	if (weaponname)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "DoSignal - " + who.GetPlayerName() + " -> " + what + " - " + concept + " - " + weaponname);

		who.SetContext("weaponname", weaponname, 0.1);
		//DoEntFire("!self", "AddContext", "weaponname:" + weaponname, 0, null, who);
		DoEntFire("!self", "SpeakResponseConcept", concept, 0, null, who);
		//DoEntFire("!self", "ClearContext", "", 0, null, who);
	}
	else
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.DoSignal - " + who.GetPlayerName() + " -> " + what + " - " + concept);

		DoEntFire("!self", "SpeakResponseConcept", concept, 0, null, who);
	}

	if (Left4Bots.Settings.signal_chat && chatText)
		Say(who, chatText, true);

	if (Left4Bots.L4F && Left4Bots.Settings.signal_ping)
		Left4Fun.PingEnt(who, what);
}

// Returns the number of other survivors alive (and not incapacitated) whithin the given radius
::Left4Bots.CountOtherStandingSurvivorsWithin <- function (me, radius)
{
	local ret = 0;
	foreach (surv in ::Left4Bots.GetOtherAliveSurvivors(me.GetPlayerUserId()))
	{
		if (!surv.IsIncapacitated() && (surv.GetOrigin() - me.GetOrigin()).Length() <= radius)
			ret++;
	}
	return ret;
}

// Cancels the revive and forces the bot to throw its pipe bomb/vomit jar
// 'bot' and 'subject' are the bot who is reviving and the survivor who is being revived
// 'pos' is the desired throw location
::Left4Bots.CancelReviveAndThrowNade <- function (bot, subject, pos)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "CancelReviveAndThrowNade - bot: " + bot.GetPlayerName() + " - subject: " + subject.GetPlayerName());

	NetProps.SetPropEntity(bot, "m_reviveTarget", null);
	NetProps.SetPropEntity(subject, "m_reviveOwner", null);

	Left4Utils.BotCmdReset(bot);

	//Left4Bots.BotThrow(bot, pos);
	Left4Timers.AddTimer(null, 0.01, @(params) Left4Bots.BotThrow(params.bot, params.pos), { bot = bot, pos = pos });
}

// Called when a survivor is pinned by a special infected
// attackType can be:
// - charger_carry_start (start of the carry phase of the charger's charge)
// - charger_pummel_start (start of the pummel phase of the charger's charge)
// - tongue_grab (grabbed by the smoker's tongue)
// - jockey_ride (ridden by the jockey)
// - lunge_pounce (pounced by the hunter)
::Left4Bots.SpecialGotSurvivor <- function (special, survivor, attackType)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "SpecialGotSurvivor - special: " + special.GetPlayerName() + " - survivor: " + survivor.GetPlayerName() + " - attackType: " + attackType);

	/*
	foreach (id, bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid() && id != survivor.GetPlayerUserId())
			Left4Utils.BotCmdAttack(bot, special);
	}
	*/

	if (Left4Bots.IsHandledBot(survivor))
	{
		// If survivor is an handled bot, it should immediately pause any current task
		// This should fix the problem of the bot not being pulled by the smoker's tongue if the bot was executing the 'wait' order (https://github.com/smilz0/Left4Bots/issues/2)
		local scope = survivor.GetScriptScope();
		scope.BotPause();
	}
}

// Handles the shooting of the smoker's tongue
::Left4Bots.DealWithSmoker <- function (smoker, victim, duck = true)
{
	local tongue = NetProps.GetPropEntity(smoker, "m_customAbility");
	if (!tongue || !tongue.IsValid() || NetProps.GetPropInt(tongue, "m_tongueState") != 3)
		return;

	local points = Left4Bots.GetSmokerTargetPoints(tongue, smoker, victim);

	foreach (bot in ::Left4Bots.Bots)
	{
		//if (bot && bot.IsValid() && !bot.IsDying() && NetProps.GetPropInt(bot, "m_reviveTarget") <= 0 && NetProps.GetPropInt(bot, "m_iCurrentUseAction") <= 0 && !Left4Utils.IsPlayerHeld(bot))
		if (bot && bot.IsValid() && !bot.IsDying() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			//Left4Utils.BotCmdAttack(bot, smoker);

			if (Left4Bots.ValidWeaponForSmoker(bot.GetActiveWeapon()) && !Left4Bots.CanTraceToSmoker(bot, smoker))
			{
				if ((victim.GetCenter() - bot.GetCenter()).Length() < 100)
					continue;

				if (bot.GetActiveWeapon().GetClassname().find("shotgun") != null && (victim.GetCenter() - bot.GetCenter()).Length() > 600 && (smoker.GetCenter() - bot.GetCenter()).Length() > 600)
					continue;

				for (local i = 0; i < points.len(); i++)
				{
					local p = points[i];
					if (Left4Utils.CanTraceToPos(bot, p, Left4Bots.Settings.tracemask_others))
					{
						Left4Bots.Log(LOG_LEVEL_INFO, bot.GetPlayerName() + " shooting the smoker's tongue");

						//DebugDrawCircle(p, Vector(255, 0, 0), 255, 2, true, 1.5);

						if (duck)
							Left4Utils.PlayerPressButton(bot, BUTTON_DUCK, 1.5, p, 0, 0, true);
						Left4Utils.PlayerPressButton(bot, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, p, 0, 0, true);
						Left4Timers.AddTimer(null, 0.5, @(params) Left4Utils.PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = Left4Bots.Settings.button_holdtime_tap, destination = p, deltaPitch = 0, deltaYaw = 0, lockLook = true });
						Left4Timers.AddTimer(null, 0.9, @(params) Left4Utils.PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = Left4Bots.Settings.button_holdtime_tap, destination = p, deltaPitch = 0, deltaYaw = 0, lockLook = true });
						Left4Timers.AddTimer(null, 1.4, @(params) Left4Utils.PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = Left4Bots.Settings.button_holdtime_tap, destination = p, deltaPitch = 0, deltaYaw = 0, lockLook = true });

						break;
					}
					//else
					//	DebugDrawCircle(p, Vector(0, 0, 255), 255, 2, true, 1.5);
				}
			}
		}
	}
}

// Returns a set of points (Vector) along the smoker's tongue that the bot can shoot in order to break it
::Left4Bots.GetSmokerTargetPoints <- function (tongue, smoker, victim, section = 25)
{
	local ret = {};
	local idx = 0;

	local startPos = smoker.GetAttachmentOrigin(smoker.LookupAttachment("smoker_mouth"));
	//local endPos = NetProps.GetPropVector(tongue, "m_tipPosition");
	//local endPos = victim.GetCenter();
	local endPos = victim.GetAttachmentOrigin(victim.LookupAttachment("medkit"));
	local bendCount = NetProps.GetPropInt(tongue, "m_bendPointCount");

	// Give priority to the smoker itself, if visible
	//ret[idx++] <- smoker.GetCenter();
	//ret[idx++] <- startPos;

	// Then the bend points (bend points don't move with the characters animation so they are easier target)
	local bendCount = NetProps.GetPropInt(tongue, "m_bendPointCount");
	for (local i = bendCount - 1; i >= 0; i--)
		ret[idx++] <- NetProps.GetPropVectorArray(tongue, "m_bendPositions", i);

	// Last some points along the tongue
	local p1 = endPos;
	local p2 = startPos;
	for (local i = bendCount - 1; i >= 0; i--)
	{
		p2 = NetProps.GetPropVectorArray(tongue, "m_bendPositions", i);

		local p = p1;
		local v = p2 - p1;
		local d = v.Norm();
		local n = floor(d / section);

		for (local x = 0; x < n; x++)
		{
			p = p + (v * section);
			ret[idx++] <- p;
		}

		p1 = p2;
	}
	p2 = startPos;

	local p = p1;
	local v = p2 - p1;
	local d = v.Norm();
	local n = floor(d / section);

	for (local x = 0; x < n; x++)
	{
		p = p + (v * section);
		ret[idx++] <- p;
	}

	return ret;
}

// Returns whether the given weapon is suitable for shooting the smoker's tongue (and it's not currently reloading)
::Left4Bots.ValidWeaponForSmoker <- function (weapon)
{
	if (!weapon || !weapon.IsValid())
		return false;

	if (NetProps.GetPropInt(weapon, "m_bInReload"))
		return false;

	local wclass = weapon.GetClassname();
	local allowed = [ ".*pistol.*", ".*smg.*" ".*rifle.*", ".*shotgun.*", ".*sniper.*"/*, ".*grenade_launcher.*"*/ ];
	foreach (str in allowed)
	{
		local expression = regexp(str);
		if (expression.match(wclass))
			return true;
	}
	return false;
}

// Can the 'source' bot trace to the given 'smoker'?
::Left4Bots.CanTraceToSmoker <- function (source, smoker)
{
	if (Left4Utils.CanTraceToEntPos(source, smoker, smoker.GetAttachmentOrigin(smoker.LookupAttachment("smoker_mouth")), Left4Bots.Settings.tracemask_others))
		return true;

	if (Left4Utils.CanTraceToEntPos(source, smoker, smoker.GetCenter(), Left4Bots.Settings.tracemask_others))
		return true;

	if (Left4Utils.CanTraceToEntPos(source, smoker, smoker.GetOrigin(), Left4Bots.Settings.tracemask_others))
		return true;

	return false;
}

// Disables BUTTON_ATTACK and set the primary/secondary weapons howner to null in order to prevent the bot from dropping the carry item
::Left4Bots.CarryItemStart <- function(bot)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "CarryItemStart - bot: " + bot.GetPlayerName());
	
	if (!Left4Utils.IsButtonDisabled(bot, BUTTON_ATTACK))
		Left4Utils.PlayerDisableButton(bot, BUTTON_ATTACK);
		
	local w = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_PRIMARY);
	if (w)
		NetProps.SetPropEntity(w, "m_hOwner", null); // This prevents the bot from switching to this weapon (and dropping the held item)
	w = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_SECONDARY);
	if (w)
		NetProps.SetPropEntity(w, "m_hOwner", null);
}

// Re-enables BUTTON_ATTACK and restores the primary/secondary weapons howner to the bot
::Left4Bots.CarryItemStop <- function(bot)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "CarryItemStop - bot: " + bot.GetPlayerName());
	
	if (Left4Utils.IsButtonDisabled(bot, BUTTON_ATTACK))
		Left4Utils.PlayerEnableButton(bot, BUTTON_ATTACK);

	local w = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_PRIMARY);
	if (w)
		NetProps.SetPropEntity(w, "m_hOwner", bot);
	w = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_SECONDARY);
	if (w)
		NetProps.SetPropEntity(w, "m_hOwner", bot);
}

// Makes the given bot drop the carried item
::Left4Bots.DropCarryItem <- function(bot)
{
	local aw = bot.GetActiveWeapon();
	if (aw && aw.IsValid() && Left4Utils.GetWeaponSlotById(Left4Utils.GetWeaponId(aw)) == 5) // <- Carry item
		//Left4Timers.AddTimer(null, 0.01, @(params) Left4Utils.PlayerPressButton(params.bot, params.button, params.holdtime), { bot = bot, button = BUTTON_USE, holdtime = Left4Bots.Settings.button_holdtime_tap });
		//Left4Utils.PlayerPressButton(bot, BUTTON_USE, Left4Bots.Settings.button_holdtime_tap); // Drop it
		//bot.DropItem(aw.GetClassname());
		Left4Bots.BotSwitchToAnotherWeapon(bot); // <- Best method
}

// Returns the closest carriable item to the given 'origin' with the given 'weaponId' whithin the given 'range' (range = 0 -> no limit)
// 'availCheck' = true -> the item must not be in someone's order DestEnt
// Returns null if no item found
::Left4Bots.GetClosestCarriableByWeaponIdWhithin <- function(origin, weaponId, range = 0, availCheck = true)
{
	local ret = null;
	
	local modelToSearch = Left4Utils.GetCarriableModelById(weaponId);
	if (!modelToSearch)
	{
		Left4Bots.Log(LOG_LEVEL_ERROR, "GetClosestCarriableByWeaponIdWhithin - No model for item with weaponId: " + weaponId);
		return ret;
	}
	
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindByModel(ent, modelToSearch))
	{
		local d = (ent.GetOrigin() - origin).Length();
		if ((range == 0 || d <= range) && d < minDist && Left4Utils.GetWeaponId(ent) == weaponId && ent.GetMoveParent() == null && (!availCheck || !Left4Bots.BotsHaveOrderDestEnt(ent)))
		{
			ret = ent;
			minDist = d;
		}
	}
	return ret;
}

// Debug hud text
::Left4Bots.RefreshDebugHudText <- function()
{
	local i = 0;
	foreach (bot in Left4Bots.Bots)
	{
		if (++i > 4)
			break;

		local scope = bot.GetScriptScope();
		local txt = " " + bot.GetPlayerName() + ": ";
		if (scope.Paused != 0)
			txt += "[P] ";
		else
			txt += "[->] ";
		if (scope.CurrentOrder)
		{
			txt += scope.CurrentOrder.OrderType + " (";
			if (scope.CurrentOrder.DestEnt)
				txt += scope.CurrentOrder.DestEnt;
			txt += ") (";
			if (scope.CurrentOrder.DestPos)
				txt += "DestPos";
			txt += ")";
		}
		txt += " - " + scope.Orders.len() + " (";
		for (local i = 0; i < scope.Orders.len(); i++)
		{
			if (i == 0)
				txt += scope.Orders[i].OrderType;
			else
				txt += ", " + scope.Orders[i].OrderType;
		}
		txt += ")";
		
		Left4Hud.SetHudText("l4b2debug" + i, txt);
	}
}

//

IncludeScript("left4bots_ai");
IncludeScript("left4bots_events");

try
{
	IncludeScript("left4bots_afterload");
}
catch(exception)
{
	error("[L4B][ERROR] Exception in left4bots_afterload.nut: " + exception + "\n");
}

__CollectEventCallbacks(::Left4Bots.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

Left4Bots.Initialize();
