/* TODO:

- "use_nopause" etc.
- Force ammo replenish while in saferoom
- Invece di GetScriptScope... DoEntFire("!self", "RunScriptCode", "AutomaticShot()", 0.01, null, bot);  oppure  DoEntFire("!self", "CallScriptFunction", "AutomaticShot", 0.01, null, bot);
- Weapon/Item spotted -> check dist/... and add as pickup
- Reset should reset pause?

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
if (!IncludeScript("left4lib_timers2"))
	error("[L4B][ERROR] Failed to include 'left4lib_timers2', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_concepts"))
	error("[L4B][ERROR] Failed to include 'left4lib_concepts', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_simplehud"))
	error("[L4F][ERROR] Failed to include 'left4lib_simplehud', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_logger"))
	error("[L4F][ERROR] Failed to include 'left4lib_logger', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");

IncludeScript("left4bots_requirements");

::Left4Bots <-
{
	Logger = Left4Logger("L4B")
	Initialized = false
	ModeName = ""
	BaseModeName = ""
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
		tempheal = 2
		heal = 2
		use = 2
		destroy = 2
		witch = 3
	}

	Events = {}
	Survivors = {}		// Used for performance reasons, instead of doing (very slow) Entities search every time
	Bots = {}			// Same as above ^
	Deads = {}			// Same ^
	Specials = {}		// Idem ^
	Tanks = {}			// ^
	Witches = {}		// Guess what? ^
	L4D1Survivors = {}	// Used to store the extra L4D1 bots when handle_l4d1_survivors = 1
	SurvivorFlow = {}
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
	FinalVehicleArrived = false
	GiveItemIndex1 = 0
	GiveItemIndex2 = 0
	LastGiveItemTime = 0
	LastMolotovTime = 0
	LastNadeTime = 0
	LastLeadStartVocalize = 0
	NiceShootSurv = null
	NiceShootTime = 0
	//IncapBlockNavs = {}
	ItemsToAvoid = []
	TeamShotguns = 0
	TeamMolotovs = 0
	TeamPipeBombs = 0
	TeamVomitJars = 0
	TeamMedkits = 0
	TeamDefibs = 0
	TeamChainsaws = 0
	TeamMelee = 0
	ScavengeUseTarget = null
	ScavengeUseTargetPos = null
	ScavengeUseType = 0
	ScavengeBots = {}
	IncapNavBlockerAreas = {}
	L4F = false
	LastSignalType = ""
	LastSignalTime = 0
	AntiPipebombBugSetup = false
	OnTankSettings = {}
	OnTankSettingsBak = {}
	OnTankCvars = {}
	OnTankCvarsBak = {}
	AIFuncs = {}
	
	//lxc check infected's status, is there a better way?
	InfectedCalmAct =
	[
		"", //empty when spawn
		
		//Basically includes all calm actions
		"ACT_TERROR_IDLE_NEUTRAL",
		"ACT_TERROR_FACE_RIGHT_NEUTRAL",
		"ACT_TERROR_FACE_LEFT_NEUTRAL",
		"ACT_TERROR_ABOUT_FACE_NEUTRAL",
		"ACT_TERROR_CROUCH_IDLE_NEUTRAL",
		"ACT_TERROR_ALERT_TO_NEUTRAL",
		"ACT_TERROR_WALK_NEUTRAL",
		"ACT_TERROR_SHAMBLE",
		"ACT_TERROR_JUMP_LANDING_NEUTRAL",
		"ACT_TERROR_JUMP_LANDING_HARD_NEUTRAL",
		"ACT_TERROR_SIT_FROM_STAND",
		"ACT_TERROR_SIT_IDLE",
		"ACT_TERROR_SIT_TO_STAND",
		"ACT_TERROR_SIT_IN_CHAIR_FROM_STAND",
		"ACT_TERROR_SIT_IN_CHAIR_IDLE",
		"ACT_TERROR_SIT_IN_CHAIR_TO_STAND",
		"ACT_TERROR_LIE_FROM_STAND",
		"ACT_TERROR_LIE_IDLE",
		"ACT_TERROR_LIE_TO_STAND",
		"ACT_TERROR_LIE_TO_SIT",
		"ACT_TERROR_SIT_TO_LIE",
		"ACT_TERROR_LEAN_RIGHTWARD_IDLE",
		"ACT_TERROR_LEAN_BACKWARD_IDLE",
		"ACT_TERROR_LEAN_LEFTWARD_IDLE",
		"ACT_TERROR_LEAN_FORWARD_IDLE",
		
		//"ACT_TERROR_IDLE_ACQUIRE", //Indicates that the infected has set a target. If you shoot it from a distance, this actions may be played. Otherwise, the following actions will be played.
		
		//Here's where the infected find the threat, but have no clear target
		"ACT_TERROR_IDLE_ALERT",
		"ACT_TERROR_IDLE_ALERT_BEHIND",
		"ACT_TERROR_IDLE_ALERT_LEFT",
		"ACT_TERROR_IDLE_ALERT_RIGHT",
		"ACT_TERROR_IDLE_ALERT_AHEAD",
		"ACT_TERROR_IDLE_ALERT_INJURED_BEHIND",
		"ACT_TERROR_IDLE_ALERT_INJURED_LEFT",
		"ACT_TERROR_IDLE_ALERT_INJURED_RIGHT",
		"ACT_TERROR_IDLE_ALERT_INJURED_AHEAD"
	]
}

IncludeScript("left4bots_settings");

// Left4Bots main initialization function
::Left4Bots.Initialize <- function ()
{
	if (Initialized)
	{
		Logger.Debug("Left4Bots already initialized");
		return;
	}

	Logger.Info("Initializing for game mode: " + ModeName + " (" + BaseModeName + ") - map name: " + MapName + " - difficulty: " + Difficulty);

	Logger.Info("Loading settings...");
	Left4Utils.LoadSettingsFromFileNew("left4bots2/cfg/settings.txt", "Left4Bots.Settings.", Logger);
	
	Logger.LogLevel(Settings.loglevel);
	
	Left4Utils.SaveSettingsToFileNew("left4bots2/cfg/settings.txt", Settings, Logger);

	// Create the missing config files with their default values
	DefaultConfigFiles();

	LoadSettingsOverride();

	Logger.LogLevel(Settings.loglevel);

	Left4Utils.PrintSettingsNew(Settings, Logger, "[Settings] ");

	if (Settings.load_convars && Settings.file_convars != "")
	{
		Logger.Info("Loading convars from file: " + Settings.file_convars);
		local c = Left4Utils.LoadCvarsFromFileNew(Settings.file_convars, Logger);
		Logger.Info("Loaded " + c + " convars");
	}
	else
		Logger.Info("Convars file was not loaded due to settings.load_convars and settings.file_convars");

	if (Settings.move_wait_time >= 0)
		Convars.SetValue("sb_debug_apoproach_wait_time", Settings.move_wait_time);

	if (Settings.file_itemstoavoid != "")
	{
		Logger.Info("Loading items to avoid from file: " + Settings.file_itemstoavoid);
		ItemsToAvoid = LoadItemsToAvoidFromFile(Settings.file_itemstoavoid);
		Logger.Info("Loaded " + ItemsToAvoid.len() + " items");
	}
	else
		Logger.Info("Itemstoavoid file was not loaded (settings.file_itemstoavoid is empty)");

	if (Settings.file_vocalizer != "")
	{
		Logger.Info("Loading vocalizer command mapping from file: " + Settings.file_vocalizer);
		VocalizerCommands = LoadVocalizerCommandsFromFile(Settings.file_vocalizer);
		Logger.Info("Loaded " + VocalizerCommands.len() + " mappings");
		
		//Left4Utils.PrintTable(VocalizerCommands); // TODO: remove
	}
	else
		Logger.Info("Vocalizer file was not loaded (settings.file_vocalizer is empty)");

	if (Left4Utils.FileExists("left4bots2/cfg/ontank_settings.txt"))
	{
		Logger.Info("Loading OnTank settings...");
		Left4Utils.LoadSettingsFromFileNew("left4bots2/cfg/ontank_settings.txt", "Left4Bots.OnTankSettings.", Logger, true);
	}
	Left4Utils.PrintSettingsNew(OnTankSettings, Logger, "[OnTank Settings] ");

	if (Left4Utils.FileExists("left4bots2/cfg/ontank_convars.txt"))
	{
		Logger.Info("Loading OnTank convars...");
		local c = LoadOnTankCvarsFromFile("left4bots2/cfg/ontank_convars.txt");
		Logger.Info("Loaded " + c + " OnTank convars");
	}

	// Put the vocalizer lines into arrays
	if (Settings.vocalizer_lead_start != "")
		VocalizerLeadStart = split(Settings.vocalizer_lead_start, ",");
	if (Settings.vocalizer_lead_stop != "")
		VocalizerLeadStop = split(Settings.vocalizer_lead_stop, ",");
	if (Settings.vocalizer_goto_stop != "")
		VocalizerGotoStop = split(Settings.vocalizer_goto_stop, ",");
	if (Settings.vocalizer_yes != "")
		VocalizerYes = split(Settings.vocalizer_yes, ",");

	// And the BG/GG chat lines too
	if (Settings.chat_bg_lines != "")
		ChatBGLines = split(Settings.chat_bg_lines, ",");
	if (Settings.chat_gg_lines != "")
		ChatGGLines = split(Settings.chat_gg_lines, ",");

	if (Settings.chat_hello_replies != "")
		ChatHelloReplies = split(Settings.chat_hello_replies, ",");

	local name = "l4b2automation";
	Left4Hud.HideHud(name);
	Left4Hud.RemoveHud(name);
	if (Settings.automation_debug)
	{
		Left4Hud.AddHud(name, g_ModeScript["HUD_TICKER"], g_ModeScript.HUD_FLAG_NOTVISIBLE | g_ModeScript.HUD_FLAG_ALIGN_LEFT);
		Left4Hud.PlaceHud(name, 0.01, 0.15, 0.8, 0.05);
		Left4Hud.ShowHud(name);
	}

	for (local i = 1; i <= 4; i++)
	{
		local name = "l4b2orders" + i;
		Left4Hud.HideHud(name);
		Left4Hud.RemoveHud(name);
		if (Settings.orders_debug)
		{
			Left4Hud.AddHud(name, g_ModeScript["HUD_SCORE_" + i], g_ModeScript.HUD_FLAG_NOTVISIBLE | g_ModeScript.HUD_FLAG_ALIGN_LEFT);
			Left4Hud.PlaceHud(name, 0.01, 0.15 + (0.05 * (i - 1)), 0.8, 0.05);
			Left4Hud.ShowHud(name);
		}
	}

	Initialized = true;

	try
	{
		IncludeScript("left4bots_afterinit");
	}
	catch(exception)
	{
		error("[L4B][ERROR] Exception in left4bots_afterinit.nut: " + exception + "\n");
	}
}

::Left4Bots.LoadSettingsOverride <- function ()
{
	// 1. settings_[map]_[difficulty]_[mode].txt
	local fileName = "left4bots2/cfg/settings_" + MapName + "_" + Difficulty + "_" + ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
		return;
	}

	// 2. settings_[difficulty]_[mode].txt
	fileName = "left4bots2/cfg/settings_" + Difficulty + "_" + ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
		return;
	}

	// 3. settings_[map]_[mode].txt
	fileName = "left4bots2/cfg/settings_" + MapName + "_" + ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
		return;
	}

	// 4. settings_[mode].txt
	fileName = "left4bots2/cfg/settings_" + ModeName + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
		return;
	}

	// 5. settings_[map]_[difficulty].txt
	fileName = "left4bots2/cfg/settings_" + MapName + "_" + Difficulty + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
		return;
	}

	// 6. settings_[difficulty].txt
	fileName = "left4bots2/cfg/settings_" + Difficulty + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
		return;
	}

	// 7. settings_[map].txt
	fileName = "left4bots2/cfg/settings_" + MapName + ".txt"
	if (Left4Utils.LoadSettingsFromFileNew(fileName, "Left4Bots.Settings.", Logger))
	{
		Logger.Info("Loaded settings overrides from: " + fileName);
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
	OnTankCvars.clear();

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

					Logger.Debug("CVAR: " + command + " " + value);

					OnTankCvars[command] <- value;

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
	foreach (bot in Bots)
	{
		if (bot.IsValid())
			CarryItemStop(bot);
	}

	// Stop the thinker
	Left4Timers.RemoveThinker("L4BThinker");

	// Stop the inventory manager
	Left4Timers.RemoveTimer("InventoryManager");

	// Stop the automation task manager
	Left4Timers.RemoveTimer("TaskManager");

	// Stop the cleaner
	Left4Timers.RemoveTimer("Cleaner");

	// Stop receiving concepts
	::ConceptsHub.RemoveHandler("Left4Bots");

	// Stop receiving user commands
	::HooksHub.RemoveChatCommandHandler("l4b");
	::HooksHub.RemoveConsoleCommandHandler("l4b");
	::HooksHub.RemoveAllowTakeDamage("L4B");

	// Stop any pending automation task
	Automation.ResetTasks();

	// Clear the lists
	Survivors.clear();

	// Remove all the bots think functions
	ClearBotThink();
	Bots.clear();

	Deads.clear();
	Specials.clear();
	Tanks.clear();
	Witches.clear();
	SurvivorFlow.clear();

	// Remove all the L4D1 bots think functions
	foreach (id, bot in L4D1Survivors)
	{
		if (bot.IsValid())
			AddThinkToEnt(bot, null);
	}
	L4D1Survivors.clear();
}

// Is player a valid survivor? (if player is a bot also checks whether it should be handled by the AI)
::Left4Bots.IsValidSurvivor <- function (player)
{
	if (player.GetZombieType() != 9)
		return false; // Not a survivor

	local team = NetProps.GetPropInt(player, "m_iTeamNum"); // Certain mutations for some reason can spawn special infected with TEAM_SURVIVORS
	if (team == TEAM_SURVIVORS)
	{
		Logger.Debug("IsValidSurvivor - " + player.GetPlayerName() + " is a valid survivor");
		return true;
	}

	if (team == TEAM_L4D1_SURVIVORS && Settings.handle_l4d1_survivors == 2)
	{
		Logger.Debug("IsValidSurvivor - " + player.GetPlayerName() + " is a valid survivor (L4D1)");
		return true;
	}

	//Logger.Debug("IsValidSurvivor - " + player.GetPlayerName() + " is not a valid survivor");
	return false;
}

// Is survivor an handled survivor? (basically is survivor in Survivors?)
::Left4Bots.IsHandledSurvivor <- function (survivor)
{
	return survivor && survivor.IsValid() && survivor.GetPlayerUserId() in Survivors;
}

// Is bot an AI handled survivor bot? (basically is bot in Bots?)
::Left4Bots.IsHandledBot <- function (bot)
{
	return bot && bot.IsValid() && bot.GetPlayerUserId() in Bots;
}

// Is bot an AI handled extra L4D1 survivor bot? (basically is bot in L4D1Survivors?)
::Left4Bots.IsHandledL4D1Bot <- function (bot)
{
	return bot && bot.IsValid() && bot.GetPlayerUserId() in L4D1Survivors;
}

::Left4Bots.PrintSurvivorsCount <- function ()
{
	local sn = Survivors.len();
	local bn = Bots.len();
	local hn = sn - bn;
	Logger.Debug("[Alive survivors: " + sn + " - " + bn + " bot(s) - " + hn + " human(s)]");
}

::Left4Bots.PrintL4D1SurvivorsCount <- function ()
{
	Logger.Debug("[L4D1 bots: " + L4D1Survivors.len() + "]");
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

	r = Left4Utils.GetCharacterFromActor(actor, SurvivorSet);
	if (r == null)
		return null;

	return GetSurvivorByCharacter(r);
}

// Returns the entity (if found) of the survivor with that character id
::Left4Bots.GetSurvivorByCharacter <- function (character)
{
	foreach (surv in Survivors)
	{
		if (surv.IsValid() && NetProps.GetPropInt(surv, "m_survivorCharacter") == character)
			return surv;
	}
	foreach (surv in L4D1Survivors)
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
	foreach (bot in Bots)
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
::Left4Bots.BotShouldStartPause <- function (bot, userid, orig, isstuck, isHealOrder = false, isLeadOrder = false, maxSeparation = 0)
{
	if (isstuck || bot.IsIT() || (isLeadOrder && Settings.lead_pause_behind_dist && !IsBotAheadOfHumans(userid, Settings.lead_pause_behind_dist)) || CheckSeparation_Orders(userid, maxSeparation) || BotWillUseMeds(bot) || SurvivorsHeldOrIncapped())
		return true;

	local tmp;
	if (!isHealOrder)
	{
		tmp = bot.GetActiveWeapon();
		if (tmp && tmp.GetClassname() == "weapon_first_aid_kit")
			return true;
	}

	tmp = HasVisibleSpecialInfectedWithin(bot, orig, 400);
	if (tmp)
		return tmp;

	tmp = HasTanksWithin(orig, 800);
	if (tmp)
		return tmp;

	tmp = HasWitchesWithin(orig, 300, 100);
	if (tmp)
		return tmp;

	if (HasAngryCommonsWithin(orig, 4, 160, 100))
		return 1;

	return false;
}

// Should the bot's AI stop the pause?
::Left4Bots.BotShouldStopPause <- function (bot, userid, orig, isstuck, isHealOrder = false, isLeadOrder = false, maxSeparation = 0)
{
	local aw = bot.GetActiveWeapon();
	if (maxSeparation)
		return !isstuck && !bot.IsIT() && (!isLeadOrder || Settings.lead_pause_behind_dist == 0 || IsBotAheadOfHumans(userid, Settings.lead_pause_behind_dist)) && (isHealOrder || !aw || aw.GetClassname() != "weapon_first_aid_kit") && !bot.IsInCombat() && !CheckSeparation_Orders(userid, maxSeparation) && !HasTanksWithin(orig, 800) && !BotWillUseMeds(bot) && !HasVisibleSpecialInfectedWithin(bot, orig, 400) && !HasWitchesWithin(orig, 300, 100) && !SurvivorsHeldOrIncapped();
	else
		return !isstuck && !bot.IsIT() && (!isLeadOrder || Settings.lead_pause_behind_dist == 0 || IsBotAheadOfHumans(userid, Settings.lead_pause_behind_dist)) && (isHealOrder || !aw || aw.GetClassname() != "weapon_first_aid_kit") && !bot.IsInCombat() && !HasTanksWithin(orig, 800) && !BotWillUseMeds(bot) && !HasVisibleSpecialInfectedWithin(bot, orig, 400) && !HasWitchesWithin(orig, 300, 100) && !SurvivorsHeldOrIncapped();
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
		if (ent.IsValid() && NetProps.GetPropInt(ent, "m_lifeState") == 0 && (NetProps.GetPropInt(ent, "m_mobRush") || NetProps.GetPropInt(ent, "m_clientLookatTarget")) /* still alive and angry */ && abs(a - ent.GetOrigin().z) <= maxAltDiff)
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
	local throw_nade_mindistance = Settings.throw_nade_mindistance;
	local tracemask_others = Settings.tracemask_others;
	while (ent = Entities.FindByClassnameWithin(ent, "infected", orig, radius))
	{
		if (ent.IsValid() && NetProps.GetPropInt(ent, "m_lifeState") == 0) // <- still alive
		{
			local dist = (ent.GetOrigin() - orig).Length();
			if (dist > d && dist >= throw_nade_mindistance && Left4Utils.CanTraceTo(player, ent, tracemask_others))
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
	local tracemask_others = Settings.tracemask_others;
	foreach (ent in Specials)
	{
		if (ent.IsValid() && !ent.IsGhost() && (ent.GetOrigin() - orig).Length() <= radius && Left4Utils.CanTraceTo(player, ent, tracemask_others))
			return ent;
	}
	return null;
}

// Does 'player' have at least one special infected within 'radius'?
::Left4Bots.HasSpecialInfectedWithin <- function (orig, radius = 1000)
{
	foreach (ent in Specials)
	{
		if (ent.IsValid() && !ent.IsGhost() && (ent.GetOrigin() - orig).Length() <= radius)
			return true;
	}
	return false;
}

// Is there at least one tank within 'radius' from 'orig'?
// Returns the ent of the first tank found or null if none
::Left4Bots.HasTanksWithin <- function (orig, radius = 1000)
{
	foreach (ent in Tanks)
	{
		if (ent.IsValid() && !ent.IsGhost() && (ent.GetOrigin() - orig).Length() <= radius)
			return ent;
	}
	return null;
}

// Is there at least one witch within 'radius' and 'maxAltDiff' from 'orig'?
// Returns the ent of the first witch found or null if none
::Left4Bots.HasWitchesWithin <- function (orig, radius = 1000, maxAltDiff = 1000)
{
	foreach (witch in Witches)
	{
		if (witch.IsValid() && NetProps.GetPropInt(witch, "m_lifeState") == 0 && !NetProps.GetPropInt(witch, "m_bIsBurning") && abs(orig.z - witch.GetOrigin().z) <= maxAltDiff && (witch.GetOrigin() - orig).Length() <= radius)
			return witch;
	}
	return null;
}

// Is there at least one survivor to defib within 'radius' from 'orig'?
::Left4Bots.HasDeathModelWithin <- function (orig, radius = 1000)
{
	foreach (chr, death in Deads)
	{
		if (death.dmodel.IsValid() && (orig - death.dmodel.GetOrigin()).Length() <= radius)
			return true;
	}
	return false;
}

// Returns the first tongue victim teammate to shove
::Left4Bots.GetTongueVictimToShove <- function (player, orig) // TODO: add trace check?
{
	local shove_tonguevictim_radius = Settings.shove_tonguevictim_radius;
	foreach (surv in GetOtherAliveSurvivors(player.GetPlayerUserId()))
	{
		if (NetProps.GetPropInt(surv, "m_tongueOwner") > 0 && (surv.GetOrigin() - orig).Length() <= shove_tonguevictim_radius)
			return surv;
	}
	return null;
}

// Returns the first special infected to shove (only smokers, hunters, spitters or jockeys)
::Left4Bots.GetSpecialInfectedToShove <- function (player, orig) // TODO: add trace check?
{
	local shove_specials_radius = Settings.shove_specials_radius;
	foreach (ent in Specials)
	{
		if (ent.IsValid() && !ent.IsGhost() && (ent.GetOrigin() - orig).Length() <= shove_specials_radius)
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
	local tracemask_others = Settings.tracemask_others;
	foreach (tank in Tanks)
	{
		if (tank.IsValid())
		{
			local dist = (orig - tank.GetOrigin()).Length();
			if (dist >= min && dist <= max && dist < minDist && Left4Utils.CanTraceTo(player, tank, tracemask_others))
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
	foreach (surv in Survivors)
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

// Force the given bot to fire a single bullet with the active weapon at the position of the entity's center
::Left4Bots.BotShootAtEntity <- function (bot, entity, lockLook = false, unlockLookDelay = 0)
{
	if (!bot || !bot.IsValid())
		return;

	if (!entity || !entity.IsValid())
	{
		if (lockLook) // Make sure to unfreeze the bot anyway
			NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN

		return;
	}

	Logger.Debug("BotShootAtEntity - bot: " + bot.GetPlayerName() + " - entity: " + entity);

	PlayerPressButton(bot, BUTTON_ATTACK, 0.0, entity.GetCenter(), 0, 0, lockLook, unlockLookDelay);
}

// Force the given bot to fire a single bullet with the active weapon at the position of the entity's attachment with the given id
::Left4Bots.BotShootAtEntityAttachment <- function (bot, entity, attachmentid, lockLook = false, unlockLookDelay = 0)
{
	if (!bot || !bot.IsValid())
		return;

	if (!entity || !entity.IsValid())
	{
		if (lockLook) // Make sure to unfreeze the bot anyway
			NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN

		return;
	}

	Logger.Debug("BotShootAtEntityAttachment - bot: " + bot.GetPlayerName() + " - entity: " + entity + " - attachmentid: " + attachmentid);

	PlayerPressButton(bot, BUTTON_ATTACK, 0.0, entity.GetAttachmentOrigin(attachmentid), 0, 0, lockLook, unlockLookDelay);
}

// Returns the closest valid enemy for the given bot within the given radius and minimum dot
// Valid enemies are common and special infected (including tank), witch excluded
::Left4Bots.FindBotNearestEnemy <- function (bot, orig, radius, minDot = 0.96)
{
	local ret_array = [];
	
	local botFacing = bot.EyeAngles().Forward();
	local tracemask_others = Settings.tracemask_others;
	
	// [NEW] Perhaps we could add `foreach (ent in Dominators)` here so SurvivorBots can prioritize killing special infected that are grabbing survivors if they are within radius.
	
	foreach (ent in Specials)
	{
		if (ent.IsValid() && !ent.IsGhost())
		{
			local toEnt = ent.GetOrigin() - orig;
			local dist = toEnt.Norm();
			
			if (dist < radius && botFacing.Dot(toEnt) >= minDot)
			{
				ret_array.append([dist, ent]);
			}
		}
	}
	
	// [NEW] Sort the array from closest to farthest special infected so the `CanTraceTo` function doesn't have to perform as many traces.
	
	ret_array.sort(function (a, b) {return a[0] - b[0]});
	
	foreach (ret_data in ret_array)
	{
		local ret = ret_data[1];
		
		if (ret && Left4Utils.CanTraceTo(bot, ret, tracemask_others))
		{
			return { ent = ret, head = ret_data[0] <= Settings.manual_attack_special_head_radius };
		}
	}
	
	ret_array.clear();
	
	//lxc kill raged Witch if no Specials nearby
	foreach (witch in Witches)
	{
		// fix for https://github.com/smilz0/Left4Bots/issues/84
		if (witch.IsValid() && NetProps.GetPropFloat(witch, "m_rage") >= 1.0)
		{
			local dist = (witch.GetOrigin() - orig).Length();
			if (dist < radius)
			{
				ret_array.append([dist, witch]);
			}
		}
	}
	
	// [NEW] Sort the array from closest to farthest Witch so the `CanTraceTo` function doesn't have to perform as many traces.
	
	ret_array.sort(function (a, b) {return a[0] - b[0]});
	
	foreach (ret_data in ret_array)
	{
		local ret = ret_data[1];
		
		if (ret && Left4Utils.CanTraceTo(bot, ret, tracemask_others))
		{
			return { ent = ret, head = true };
		}
	}
	
	ret_array.clear();
	
	// [NEW] Added Tanks to the list of targets for SurvivorBots to shoot so they don't take too long to react to its presence.
	
	foreach (tank in Tanks)
	{
		if (tank.IsValid() && !tank.IsIncapacitated() && NetProps.GetPropInt(tank, "m_lookatPlayer") >= 0) //Aggroed
		{
			local dist = (tank.GetOrigin() - orig).Length();
			if (dist < radius)
			{
				ret_array.append([dist, tank]);
			}
		}
	}
	
	local tank = null;
	local newRadius = radius;
	
	// [NEW] Sort the array from closest to farthest Tank so the `CanTraceTo` function doesn't have to perform as many traces.
	
	ret_array.sort(function (a, b) {return a[0] - b[0]});
	
	foreach (ret_data in ret_array)
	{
		local ret = ret_data[1];
		
		if (ret && Left4Utils.CanTraceTo(bot, ret, tracemask_others))
		{
			tank = ret;
			//newRadius = radius < 120 ? radius : 120;
			newRadius = ret_data[0];
			break;
		}
	}
	
	ret_array.clear();
	
	local ent = null;
	while (ent = Entities.FindByClassnameWithin(ent, "infected", orig, newRadius)) // If only we had a infected_spawned event for the commons...
	{
		if (ent.IsValid() && NetProps.GetPropInt(ent, "m_lifeState") == 0)
		{
			local toEnt = ent.GetOrigin() - orig;
			local dist = toEnt.Norm();
			
			if (botFacing.Dot(toEnt) >= minDot)
			{
				ret_array.append([dist, ent]);
			}
		}
	}
	
	// [NEW] Sort the array from closest to farthest common infected so the `CanTraceTo` function doesn't have to perform as many traces.
	
	ret_array.sort(function (a, b) {return a[0] - b[0]});
	
	foreach (ret_data in ret_array)
	{
		local ret = ret_data[1];
		
		if (ret && (Settings.manual_attack_wandering || IsInfectedAngry(ret)) && !IsRiotPolice(ret, orig) && Left4Utils.CanTraceTo(bot, ret, tracemask_others))
		{
			return { ent = ret, head = ret_data[0] <= Settings.manual_attack_common_head_radius };
		}
	}
	
	return tank ? { ent = tank, head = true } : tank;
}

// Called when the bot's pick-up algorithm decides to pick the item up
// Checks if the pick-up via button press worked and the item went into the bot's inventory. if it didn't it will force it via USE input on the item
// It is meant to prevent the bot getting stuck in a loop if the button press, for some reason, didn't pick the item up
::Left4Bots.PickupFailsafeVerbatimCode <- @"
local isWorthPickingUp = !self.GetMoveParent();
if (self.GetClassname().find(""_spawn""))
	isWorthPickingUp = NetProps.GetPropInt(self, ""m_itemCount"") > 0;
if (activator && isWorthPickingUp)
{
	local weaponid = Left4Utils.GetWeaponId(self);
	if (Left4Utils.HasWeaponId(activator, weaponid, Left4Utils.GetAmmoPercent(self)))
		return;

	Left4Bots.Logger.Debug(""PickupFailsafe - "" + activator.GetPlayerName() + "" -> "" + self + "" ("" + weaponid + "")"");

	DoEntFire(""!self"", ""Use"", """", -1, activator, self);
	Left4Bots.OnPlayerUse(activator, self, 1);
}";

::Left4Bots.PickupFailsafe <- function (bot, item)
{
	//lxc if use this method, will set context to ent, so other bots will ignore it until context deleted
	item.SetContext("skip_use", "true", -1);
	DoEntFire("!self", "RemoveContext", "skip_use", 0.2, null, item);
	
	item.ValidateScriptScope(); //lxc avoid [the index 'activator' does not exist]
	
	//"weapon_smg, weapon_smg_silenced, weapon_shotgun_chrome, weapon_pumpshotgun, weapon_rifle, weapon_rifle_desert, weapon_rifle_ak47, weapon_rifle_sg552, weapon_shotgun_spas, weapon_autoshotgun, weapon_hunting_rifle, weapon_sniper_military, weapon_smg_mp5, weapon_sniper_scout, weapon_sniper_awp, weapon_grenade_launcher, weapon_rifle_m60, weapon_pistol, weapon_pistol_magnum"
	//By Inputs "Use" to pickup weapon, weapons in the list above never fire "item_pickup" or "player_use" event, the remaining weapons and all spawn ent only fire "item_pickup" event.
	
	//lxc if "PlayerPressButton" succeed, "item_pickup" or "player_use" event will always fire before 'DoEntFire()', so use -1 delay is safe.
	DoEntFire("!self", "RunScriptCode", PickupFailsafeVerbatimCode, -1, bot, item);
	
	/*
	if (!bot || !bot.IsValid() || !IsValidPickup(item))
		return;

	//Left4Utils.HasWeaponEnt <- function (player, weaponEnt)
	local weaponid = Left4Utils.GetWeaponId(item);
	if (Left4Utils.HasWeaponId(bot, weaponid, Left4Utils.GetAmmoPercent(item)))
		return;

	Logger.Debug("PickupFailsafe - " + bot.GetPlayerName() + " -> " + item + " (" + weaponid + ")");

	DoEntFire("!self", "Use", "", 0, bot, item); // <- make sure i pick this up even if the real pickup (with the button) fails or i will be stuck here forever
	OnPlayerUse(bot, item, 1); // ^this doesn't trigger the event so i do it myself
	*/
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
		Logger.Debug("DoorFailsafe - " + bot.GetPlayerName() + " -> " + door + " (Close)");
		DoEntFire("!self", "Close", "", 0, bot, door);
	}
	else
	{
		Logger.Debug("DoorFailsafe - " + bot.GetPlayerName() + " -> " + door + " (Open)");
		DoEntFire("!self", "Open", "", 0, bot, door);
	}
	//DoEntFire("!self", "Use", "", 0, bot, door);

	// Let's pretend we are closing it the normal way
	Left4Utils.BotLookAt(bot, door, 0, 0);
}

// Returns the flow distance between the survivors with the given user ids
::Left4Bots.FlowDistance <- function (userid1, userid2)
{
	if (!(userid1 in SurvivorFlow) || !(userid2 in SurvivorFlow))
		return -1;
	
	return abs(SurvivorFlow[userid1].flow - SurvivorFlow[userid2].flow);
}

// Returns whether the bot with the given userid has a separation > maxSeparation (true) or not (false)
// If any human is in the team the separation is measured from the last human, if no human it is measured from the other bots
::Left4Bots.CheckSeparation_Orders <- function (userid, maxSeparation)
{
	if (maxSeparation <= 0 || SurvivorFlow.len() < 2 || !(userid in SurvivorFlow))
		return false;
	
	local hasHumans = Survivors.len() > Bots.len();
	local myFlow = SurvivorFlow[userid].flow;
	
	foreach (id, f in SurvivorFlow)
	{
		if (id != userid && (!hasHumans || !f.isBot) && abs(myFlow - f.flow) <= maxSeparation)
			return false;
	}
	return true;
}

// Returns whether the bot with the given userid has a separation > pickups_max_separation (true) or not (false)
// The separation only counts when the bot is behind and, if any human is in the team then it is measured from the last human, if no human then it is measured from the other bots
::Left4Bots.CheckSeparation_Pickup <- function (userid)
{
	if (Settings.pickups_max_separation <= 0 || SurvivorFlow.len() < 2 || !(userid in SurvivorFlow))
		return false;
	
	local hasHumans = Survivors.len() > Bots.len();
	local myFlow = SurvivorFlow[userid].flow;
	
	foreach (id, f in SurvivorFlow)
	{
		if (id != userid && (!hasHumans || !f.isBot) && f.flow < (myFlow + Settings.pickups_max_separation))
			return false;
	}
	return true;
}

// Returns the list of survivors alive (excluding the one with the given userid)
::Left4Bots.GetOtherAliveSurvivors <- function (userid)
{
	foreach (id, surv in Survivors)
	{
		if (id != userid && surv.IsValid())
			yield surv;
	}
}

// Returns the list of alive human survivors (excluding the one with the given userid)
::Left4Bots.GetOtherAliveHumanSurvivors <- function (userid)
{
	foreach (id, surv in Survivors)
	{
		if (id != userid && surv.IsValid() && !IsPlayerABot(surv))
			yield surv;
	}
}

// Are there survivors (other than the one with the given userid) within 'radius' from 'origin'?
::Left4Bots.AreOtherSurvivorsNearby <- function (userid, origin, radius = 150)
{
	// TODO: use SurvivorFlow ?
	foreach (id, surv in Survivors)
	{
		if (id != userid && surv.IsValid() && (surv.GetOrigin() - origin).Length() <= radius)
			return true;
	}
	return false;
}

// Is there any other survivor (other than the one with the given userid) currently holding a weapon of class 'weaponClass'?
::Left4Bots.IsSomeoneElseHolding <- function (userid, weaponClass)
{
	foreach (id, surv in Survivors)
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
	if (GiveItemIndex1 != 0 || GiveItemIndex2 != 0 || (Time() - LastGiveItemTime) < 3)
		return false; // Another give is already in progress or we must wait 3 seconds between each give

	// Give molotov / pipe bombs / bile jars / pills / adrenaline to all humans
	if ((invSlot == INV_SLOT_THROW && !Settings.give_bots_nades) || (invSlot == INV_SLOT_PILLS && !Settings.give_bots_pills))
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
		if (!Settings.give_bots_medkits || lvl < Settings.userlevel_give_medkit)
			return false; // Disabled via settings or user level too low
	}
	else if (invSlot == INV_SLOT_PRIMARY || invSlot == INV_SLOT_SECONDARY)
	{
		if (!Settings.give_bots_weapons || lvl < Settings.userlevel_give_weapons)
			return false; // Disabled via settings or user level too low
	}
	else if (lvl < Settings.userlevel_give_others)
		return false; // User level too low

	if (invSlot == INV_SLOT_MEDKIT && (itemClass == "weapon_upgradepack_explosive" || itemClass == "weapon_upgradepack_incendiary") && !Settings.give_bots_upgrades)
		return false; // Disabled via settings

	if (Left4Utils.GetInventoryItemInSlot(survDest, invSlot) != null)
		return false; // Dest survivor already has an item in that slot

	// Ok, we can give the item...

	//local itemSkin = NetProps.GetPropInt(item, "m_nSkin");

	GiveItemIndex1 = item.GetEntityIndex();

	bot.DropItem(itemClass);

	//Left4Utils.GiveItemWithSkin(survDest, itemClass, itemSkin);

	Left4Timers.AddTimer(null, 0.3, ::Left4Bots.ItemGiven.bindenv(::Left4Bots), { player1 = bot, item = item, player2 = survDest });

	DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, bot);

	Logger.Debug("GiveInventoryItem - " + bot.GetPlayerName() + " -> " + item + " -> " + survDest.GetPlayerName());

	return true;
}

// Finalize the give item process
::Left4Bots.ItemGiven <- function (params)
{
	local item = params["item"];
	local player2 = params["player2"];

	//if (item && item.IsValid())
	//	DoEntFire("!self", "Kill", "", 0, null, item);

	if (item && player2 && item.IsValid() && player2.IsValid())
		DoEntFire("!self", "Use", "", 0, player2, item);

	GiveItemIndex1 = 0;

	if (Settings.play_sounds)
	{
		local player1 = params["player1"];
		if (player1 && player1.IsValid())
		{
			if (!IsPlayerABot(player1))
				EmitSoundOnClient("Hint.BigReward", player1);

			local player1UserId = player1.GetPlayerUserId();
			foreach (id, surv in Survivors)
			{
				if (id != player1UserId && surv.IsValid() && !IsPlayerABot(surv))
					EmitSoundOnClient("Hint.LittleReward", surv);
			}
		}
	}
}

// Finalize the swap item process
::Left4Bots.ItemSwapped <- function (params)
{
	local item1 = params["item1"];
	local player1 = params["player1"];

	//if (item1 && item1.IsValid())
	//	DoEntFire("!self", "Kill", "", 0, null, item1);

	if (item1 && player1 && item1.IsValid() && player1.IsValid())
		DoEntFire("!self", "Use", "", 0, player1, item1);

	GiveItemIndex1 = 0;

	local item2 = params["item2"];
	local player2 = params["player2"];

	//if (item2 && item2.IsValid())
	//	DoEntFire("!self", "Kill", "", 0, null, item2);

	if (item2 && player2 && item2.IsValid() && player2.IsValid())
		DoEntFire("!self", "Use", "", 0, player2, item2);

	GiveItemIndex2 = 0;

	if (Settings.play_sounds)
	{
		if (player1 && player1.IsValid())
		{
			if (!IsPlayerABot(player1))
				EmitSoundOnClient("Hint.BigReward", player1);
			if (!IsPlayerABot(player2))
				EmitSoundOnClient("Hint.BigReward", player2);

			local player1UserId = player1.GetPlayerUserId();
			local player2UserId = player2.GetPlayerUserId();
			foreach (id, surv in Survivors)
			{
				if (id != player1UserId && id != player2UserId && surv.IsValid() && !IsPlayerABot(surv))
					EmitSoundOnClient("Hint.LittleReward", surv);
			}
		}
	}
}

// Returns whether the given bot is available for a new order of type 'orderType'
::Left4Bots.IsBotAvailableForOrder <- function (bot, botScope, orderType)
{
	// If orderType = "lead" or "follow", then the bots can't have another order of that type in the queue
	switch (orderType)
	{
		//case "lead": // bot can't have another order of the same type in the queue
		//	return !BotHasOrderOfType(bot, orderType);

		case "follow":
			return (!BotHasOrderOfType(bot, orderType) && !(bot.GetPlayerUserId() in ScavengeBots));
		
		case "witch": // bot must be holding a shotgun
			return (botScope.ActiveWeapon && botScope.ActiveWeapon.GetClassname().find("shotgun") != null);
		
		case "scavenge": // bot can't be an automatic scavenge bot
			return !(bot.GetPlayerUserId() in ScavengeBots);
		
		case "destroy":
			return (botScope.ActiveWeapon && IsRangedWeapon(botScope.ActiveWeaponId, botScope.ActiveWeaponSlot) && Left4Utils.GetAmmoPercent(botScope.ActiveWeapon) >= 2);
		
		default: // bot can't have another order of the same type in the queue
			return !BotHasOrderOfType(bot, orderType);
	}
	
	return true;
}

// Returns the first available bot to add an order of type 'orderType' to his queue (null = no bot available)
// if 'ignoreUserid' is not null, the bot with that userid will be ignored
::Left4Bots.GetFirstAvailableBotForOrder <- function (orderType, ignoreUserid = null, closestTo = null)
{
	local bestBot = null;
	local bestDistance = 1000000;
	local bestQueue = 1000;
	foreach (id, bot in Bots)
	{
		if (bot.IsValid() && (!ignoreUserid || id != ignoreUserid) && !bot.IsDead() && !bot.IsDying() /*&& !bot.IsIncapacitated()*/)
		{
			local scope = bot.GetScriptScope();
			if (!SurvivorCantMove(bot, scope.Waiting) && IsBotAvailableForOrder(bot, scope, orderType))
			{
				local q = scope.Orders.len();
				if (q == 0 && !scope.CurrentOrder)
					q = -1;

				local d = 0;
				if (closestTo)
					d = (bot.GetOrigin() - closestTo).Length();

				// Get the bot with the shortest queue (and closer to closestTo if closestTo is not null)
				if (q < bestQueue || (q == bestQueue && d < bestDistance))
				{
					bestBot = bot;
					bestQueue = q;
					bestDistance = d;
				}
			}
		}
	}
	return bestBot;
}

// Returns the first available bot with any item in the given intentory slot or null if not bot available
// It also checks whether the given user level of the is allowed to receive medkits/defibs
::Left4Bots.GetFirstAvailableBotForGive <- function (slot, userlevel)
{
	foreach (bot in Bots)
	{
		// Add some restrictions
		if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() /*&& !bot.IsIncapacitated()*/ && !SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
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
					if (slot != INV_SLOT_MEDKIT && slot != INV_SLOT_PRIMARY && slot != INV_SLOT_SECONDARY)
						return bot;
					
					if (slot == INV_SLOT_MEDKIT && ((itemClass != "weapon_first_aid_kit" && itemClass != "weapon_defibrillator") || (Settings.give_bots_medkits && userlevel >= Settings.userlevel_give_medkit)))
						return bot;
					
					if ((slot == INV_SLOT_PRIMARY || slot == INV_SLOT_SECONDARY) && Settings.give_bots_weapons && userlevel >= Settings.userlevel_give_weapons)
						return bot;
				}
			}
		}
	}

	return null;
}

// Returns closest (to 'player') bot with an upgrade pack in the inventory
::Left4Bots.GetFirstAvailableBotForDeploy <- function (player)
{
	local ret = null;
	local minDist = 999999;
	local orig = player.GetOrigin();
	foreach (bot in Bots)
	{
		if (bot.IsValid() && !bot.IsDead() && !bot.IsDying() /*&& !bot.IsIncapacitated()*/ && !SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
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

	return ret;
}

// Returns closest (to 'destPos') bot with an item of class 'itemClass' (if 'itemClass' is not null) or with any throwable item (if 'itemClass' is null)
::Left4Bots.GetFirstAvailableBotForThrow <- function (destPos, itemClass = null)
{
	local ret = null;
	local minDist = 999999;
	foreach (bot in Bots)
	{
		if (BotCanThrow(bot, itemClass))
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
	if (!bot || !bot.IsValid() || bot.IsDead() || bot.IsDying() || bot.IsIncapacitated() || SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		return false;

	local item = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_THROW);
	return (item && item.IsValid() && (!itemClass || item.GetClassname() == itemClass));
}

// Returns the bot's throw target (if any) for the throw item of class 'throwableClass'
// Returned value can be an entity (in case the target is the tank), a vector with the target position (in case it's against an horde), null if no target
::Left4Bots.GetThrowTarget <- function (bot, userid, orig, throwableClass)
{
	// Is someone else already going to throw this?
	if (IsSomeoneElseHolding(userid, throwableClass))
		return null; // Yes

	// No, go on...
	
	if (throwableClass == "weapon_molotov")
	{
		// Can we actually throw molotovs?
		if (!Settings.throw_molotov || (Time() - LastMolotovTime) < Settings.throw_molotov_interval)
			return null; // No

		// Yes, but can we throw them at tanks right now?
		if (RandomInt(1, 100) > Settings.tank_molotov_chance)
			return null; // No

		// Yes, let's find a target tank
		local nearestTank = GetNearestVisibleTankWithin(bot, orig, Settings.tank_throw_range_min, Settings.tank_throw_range_max);

		// Should we throw the molotov at this tank?
		if (nearestTank && !nearestTank.IsOnFire() && !nearestTank.IsIncapacitated() && nearestTank.GetHealth() >= Settings.tank_throw_min_health && /*!::Left4Utils.IsPlayerInWater(nearestTank)*/ NetProps.GetPropInt(nearestTank, "m_nWaterLevel") <= 0 && !AreOtherSurvivorsNearby(userid, nearestTank.GetOrigin(), Settings.tank_throw_survivors_mindistance))
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
		if (!Settings.throw_vomitjar || (Time() - LastNadeTime) < Settings.throw_nade_interval)
			return null; // No

		// Yes, but can we throw them at tanks right now?
		if (RandomInt(1, 100) <= Settings.tank_vomitjar_chance)
		{
			// Yes, let's find a target tank
			local nearestTank = GetNearestVisibleTankWithin(bot, orig, Settings.tank_throw_range_min, Settings.tank_throw_range_max);

			// Should we throw the bile jar at this tank?
			if (nearestTank && !nearestTank.IsOnFire() && !nearestTank.IsIncapacitated() && nearestTank.GetHealth() >= Settings.tank_throw_min_health && /*!::Left4Utils.IsPlayerInWater(nearestTank)*/ NetProps.GetPropInt(nearestTank, "m_nWaterLevel") <= 0 && !AreOtherSurvivorsNearby(userid, nearestTank.GetOrigin(), Settings.tank_throw_survivors_mindistance))
			{
				// Yes, let's do it...
				return nearestTank;
			}
		}

		// Ok, we can throw bile jars right now but not at tanks. Let's see if we need to throw it at hordes
		if (RandomInt(1, 100) > Settings.horde_nades_chance || !NetProps.GetPropInt(bot, "m_hasVisibleThreats")) // NetProps.GetPropInt(bot, "m_clientIntensity") < 40
			return null; // No

		// Is there an actual horde?
		local common = CheckAngryCommonsWithin(bot, orig, Settings.horde_nades_size, Settings.horde_nades_radius, Settings.horde_nades_maxaltdiff);
		if (common == false)
			return null; // No

		// Yes
		if (common != true)
			return common.GetOrigin(); // We have the position of the farthest common of the horde

		// We don't have the position of the farthest common of the horde, we must find a target position ourselves
		local pos = Left4Utils.BotGetFarthestPathablePos(bot, Settings.throw_nade_radius);
		if (pos && (pos - orig).Length() >= Settings.throw_nade_mindistance)
			return pos; // Found

		return null;
	}
	else //if (throwableClass == "weapon_pipe_bomb")
	{
		// Can we actually throw pipe bombs?
		if (!Settings.throw_pipebomb || (Time() - LastNadeTime) < Settings.throw_nade_interval)
			return null; // No

		// Yes, but can we throw them at hordes right now?
		if (RandomInt(1, 100) > Settings.horde_nades_chance || !NetProps.GetPropInt(bot, "m_hasVisibleThreats")) // NetProps.GetPropInt(bot, "m_clientIntensity") < 40
			return null; // No

		// Is there an actual horde?
		local common = CheckAngryCommonsWithin(bot, orig, Settings.horde_nades_size, Settings.horde_nades_radius, Settings.horde_nades_maxaltdiff);
		if (common == false)
			return null; // No

		// Yes
		if (common != true)
			return common.GetOrigin(); // We have the position of the farthest common of the horde

		// We don't have the position of the farthest common of the horde, we must find a target position ourselves
		local pos = Left4Utils.BotGetFarthestPathablePos(bot, Settings.throw_nade_radius);
		if (pos && (pos - bot.GetOrigin()).Length() >= Settings.throw_nade_mindistance)
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
		if (IsSomeoneElseHolding(userid, throwClass))
			return false;

		// Can we actually throw this item?
		if ((throwClass == "weapon_molotov" && (!Settings.throw_molotov || (Time() - LastMolotovTime) < Settings.throw_molotov_interval)) || (throwClass == "weapon_vomitjar" && (!Settings.throw_vomitjar || (Time() - LastNadeTime) < Settings.throw_nade_interval)))
			return false; // No

		// Is the tank still a valid target?
		// TODO: add trace check?
		if (throwTarget.IsValid() && !throwTarget.IsDead() && !throwTarget.IsDying() && !throwTarget.IsIncapacitated() && !throwTarget.IsOnFire() && throwTarget.GetHealth() >= Settings.tank_throw_min_health && /*!::Left4Utils.IsPlayerInWater(throwTarget)*/ NetProps.GetPropInt(throwTarget, "m_nWaterLevel") <= 0 && !AreOtherSurvivorsNearby(userid, throwTarget.GetOrigin(), Settings.tank_throw_survivors_mindistance))
			return true; // Yes
	}
	else if (throwType == AI_THROW_TYPE.Horde)
	{
		// Is someone else already going to throw this?
		if (IsSomeoneElseHolding(userid, throwClass))
			return false;

		// Can we actually throw this item?
		if ((throwClass == "weapon_pipe_bomb" && !Settings.throw_pipebomb) || (throwClass == "weapon_vomitjar" && !Settings.throw_vomitjar) || (Time() - LastNadeTime) < Settings.throw_nade_interval)
			return false; // No

		// Is there an actual horde?
		if (NetProps.GetPropInt(bot, "m_hasVisibleThreats") && HasAngryCommonsWithin(orig, Settings.horde_nades_size, Settings.horde_nades_radius, Settings.horde_nades_maxaltdiff)) // NetProps.GetPropInt(bot, "m_clientIntensity") < 40
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
	foreach (chr, death in Deads)
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
	foreach (chr, death in Deads)
	{
		if (death.dmodel.IsValid())
		{
			local human = (death.player && death.player.IsValid() && !IsPlayerABot(death.player));
			local dist = (orig - death.dmodel.GetOrigin()).Length();
			if (dist <= radius && Left4Utils.AltitudeDiff(player, death.dmodel) <= maxAltDiff && ((human && !isHuman) || (dist < minDist && (!isHuman || human))) && FindDefibPickupWithin(death.dmodel.GetOrigin()) != null)
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
	local deads_scan_defibradius = Settings.deads_scan_defibradius;
	while (ent = Entities.FindByClassnameWithin(ent, "weapon_defibrillator", origin, deads_scan_defibradius))
	{
		if (IsValidPickup(ent))
			return ent;
	}
}

// 'bot' will try to dodge the 'spit'
::Left4Bots.TryDodgeSpit <- function (bot, spit = null) // TODO: Improve (maybe just move to the position of a teammate who is not in spit radius)
{
	local dodge_spit_radius = Settings.dodge_spit_radius;
	local p2 = bot.GetOrigin();
	local p1 = p2;
	if (spit)
		p1 = spit.GetOrigin();

	local i = 0;
	while ((p1 - p2).Length() <= dodge_spit_radius && ++i <= 6)
	{
		Logger.Debug(bot.GetPlayerName() + ".TryGetPathableLocationWithin - i = " + i);
		p2 = bot.TryGetPathableLocationWithin(dodge_spit_radius + 150);
	}

	if (i > 0 && i <= 6)
		BotHighPriorityMove(bot, p2);
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
	if (a >= -Settings.dodge_charger_diffangle && a <= Settings.dodge_charger_diffangle)
		TryDodge(bot, chargerLeft, a > 0, Settings.dodge_charger_mindistance, Settings.dodge_charger_maxdistance);
}

// 'bot' will try to dodge left o right
// 'leftVector' is a vector facing the current carger's left
// 'goLeft' tells whether the bot should run left (true) or right (false)
// 'minDistance' and 'maxDistance' are the minimum and maximum distance to travel
// Returns whether a dodge move location was found or not
::Left4Bots.TryDodge <- function (bot, leftVector, goLeft, minDistance, maxDistance)
{
	Logger.Debug("TryDodge - bot: " + bot.GetPlayerName() + " - goLeft: " + goLeft);

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
		Logger.Debug("TryDodge - bot: " + bot.GetPlayerName() + " - d: " + d);

		if (d >= 0)
		{
			Logger.Info(bot.GetPlayerName() + " trying to dodge");

			BotHighPriorityMove(bot, Vector(dest.x, dest.y, destArea.GetZ(dest))); // Set the Z axis to ground level
			return true;
		}
	}
	else
		Logger.Debug("TryDodge - bot: " + bot.GetPlayerName() + " - nav area not found");

	// Preferred direction failed, let's try the other one (add some distance because we probably need to traver farther in this direction)
	if (goLeft)
		dest = bot.GetCenter() + (leftVector * (minDistance + 40)); // TODO: better calc that +40
	else
		dest = bot.GetCenter() - (leftVector * (minDistance + 40));

	local destArea =  NavMesh.GetNavArea(dest, 300);
	if (destArea && destArea.IsValid())
	{
		local d = NavMesh.NavAreaTravelDistance(startArea, destArea, maxDistance);
		Logger.Debug("TryDodge - bot: " + bot.GetPlayerName() + " - d: " + d);

		if (d >= 0)
		{
			Logger.Info(bot.GetPlayerName() + " trying to dodge");

			BotHighPriorityMove(bot, Vector(dest.x, dest.y, destArea.GetZ(dest))); // Set the Z axis to ground level
			return true;
		}
	}
	else
		Logger.Debug("TryDodge - bot: " + bot.GetPlayerName() + " - nav area not found");

	Logger.Debug("TryDodge - failed!");

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
	local tracemask_others = Settings.tracemask_others;
	foreach (id, surv in Survivors)
	{
		local toEnt = surv.GetOrigin() - orig;
		if (id != userid && toEnt.Length() <= radius)
		{
			toEnt.Norm();
			local dot = facing.Dot(toEnt);
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, surv, tracemask_others)))
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
	local tracemask_others = Settings.tracemask_others;
	foreach (id, surv in Bots)
	{
		local toEnt = surv.GetOrigin() - orig;
		if (id != userid && toEnt.Length() <= radius)
		{
			toEnt.Norm();
			local dot = facing.Dot(toEnt);
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, surv, tracemask_others)))
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
	local tracemask_others = Settings.tracemask_others;
	foreach (witch in Witches)
	{
		local toEnt = witch.GetOrigin() - orig;
		if (toEnt.Length() <= radius)
		{
			toEnt.Norm();
			local dot = facing.Dot(toEnt);
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, witch, tracemask_others)))
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
			Logger.Debug("ClearPipeBombs - Killing pipe_bomb_projectile");
			ent.Kill();
		}
	}
}

// Are all the other alive survivors (except the one with the given userid) in a checkpoint?
::Left4Bots.OtherSurvivorsInCheckpoint <- function (userid)
{
	/*
	foreach (id, surv in Survivors)
	{
		if (id != userid && surv.IsValid())
		{
			local area = surv.GetLastKnownArea();
			if (!area || !area.HasSpawnAttributes(NAVAREA_SPAWNATTR_CHECKPOINT))
			// if (ResponseCriteria.GetValue(surv, "incheckpoint") != "1")  // <- doesn't work with bots
			{
				Logger.Debug("AllSurvivorsInCheckpoint - " + surv.GetPlayerName() + " is not in checkpoint");
				return false;
			}
		}
	}
	*/
	
	foreach (id, f in SurvivorFlow)
	{
		if (id != userid && !f.inCheckpoint)
		{
			Logger.Debug("AllSurvivorsInCheckpoint - " + id + " is not in checkpoint");
			return false;
		}
	}
	Logger.Debug("AllSurvivorsInCheckpoint - All survivors in checkpoint");
	return true;
}

// Is the given survivor in a checkpoint?
::Left4Bots.IsSurvivorInCheckpoint <- function (survivor)
{
	local area = survivor.GetLastKnownArea();
	return (area && area.IsValid() && area.HasSpawnAttributes(NAVAREA_SPAWNATTR_CHECKPOINT));
}

// Are there enough spare medkits around for the teammates who need them and for 'me'?
::Left4Bots.HasSpareMedkitsAround <- function (me)
{
	local requiredMedkits = 1;
	local haveLowestHP = true;
	foreach (surv in GetOtherAliveSurvivors(me.GetPlayerUserId()))
	{
		if (surv.GetHealth() < 75 || !::Left4Utils.HasMedkit(surv))
			requiredMedkits++;
		
		if (surv.GetHealth() < me.GetHealth())
			haveLowestHP = false;
	}

	Logger.Debug("HasSpareMedkitsAround - me: " + me.GetPlayerName() + " - requiredMedkits: " + requiredMedkits + " - haveLowestHP: " + haveLowestHP);

	local count = 0;
	local ent = null;
	// Note: we are counting both weapon_first_aid_kit and weapon_first_aid_kit_spawn
	while (ent = Entities.FindByClassnameWithin(ent, "weapon_first_aid_kit*", me.GetOrigin(), Settings.heal_spare_medkits_radius))
	{
		if (IsValidPickup(ent))
		{
			if (++count >= requiredMedkits)
				return true;
		}
	}
	
	return (haveLowestHP && count > 0);
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
	Logger.Debug("CheckHealingTarget");

	if (!bot || !order || !bot.IsValid())
		return;

	Logger.Debug("CheckHealingTarget - bot: " + bot.GetPlayerName());

	local target = NetProps.GetPropEntity(bot, "m_useActionTarget");
	if (!IsPlayerABot(bot) || !target || !order.DestEnt || !order.DestEnt.IsValid() || target.GetPlayerUserId() != order.DestEnt.GetPlayerUserId())
	{
		// Cancel

		Logger.Debug("CheckHealingTarget - Cancel healing");

		// Unforce buttons + unfreeze player
		NetProps.SetPropInt(bot, "m_afButtonForced", NetProps.GetPropInt(bot, "m_afButtonForced") & (~(BUTTON_SHOVE + BUTTON_ATTACK)));
		NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN

		// Retry, but only after the timed unforce+unfreeze of the previous button press have done, otherwise the new heal will be interrupted
		if (IsPlayerABot(bot))
			Left4Timers.AddTimer(null, 0.5, @(params) ::Left4Bots.BotOrderRetry.bindenv(::Left4Bots)(params.bot, params.order), { bot = bot, order = order });
	}
}

// Returns the closest bot to the given origin. The bot must be able to move (not incapped, pinned or something)
::Left4Bots.GetNearestMovingBot <- function (orig)
{
	local ret = null;
	local dist = 1000000;
	foreach (bot in Bots)
	{
		if (!SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
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
	foreach (bot in Bots)
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
	foreach (bot in Bots)
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

	if (SurvivorsHeldOrIncapped())
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

	Logger.Debug("Bot " + player.GetPlayerName() + " switched to upgrade " + itemClass);

	if (itemClass != "weapon_upgradepack_incendiary" && itemClass != "weapon_upgradepack_explosive")
		return;

	Logger.Debug("Bot " + player.GetPlayerName() + " deploying upgrade " + itemClass);

	//lxc apply changes
	//PlayerPressButton(player, BUTTON_ATTACK, 2.2, null, 0, 0, true);
	PlayerPressButton(player, BUTTON_ATTACK, 0.0, null, 0, 0, true);
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

	//Logger.Debug("L4B_RockThink");

	local MyPos = self.GetCenter();

	//local fwd = self.GetForwardVector();
	local fwd = self.GetAngles().Forward();
	fwd.Norm();
	local fwdY = Left4Utils.VectorAngles(fwd).y;
	local lft = self.GetAngles().Left();

	//fwd = Vector(fwd.x, fwd.y, 0);

	//DebugDrawLine_vCol(MyPos, MyPos + (fwd * 30), Vector(0, 255, 0), true, 5.0);

	local l4b = ::Left4Bots;

	foreach (id, bot in l4b.Bots)
	{
		if (bot.IsValid())
		{
			local distance = (bot.GetCenter() - MyPos).Length();
			if (distance <= 1500 && !l4b.SurvivorCantMove(bot, bot.GetScriptScope().Waiting) && Left4Utils.CanTraceTo(bot, self, l4b.Settings.tracemask_others))
			{
				local toBot = bot.GetCenter() - MyPos;
				toBot.Norm();

				local a = Left4Utils.GetDiffAngle(Left4Utils.VectorAngles(toBot).y, fwdY);

				/*
					- if dodge_rock is true and the bot has a dodge move location, then dodge
					- if shoot_rock is true and the bot did not (or did not yet) dodge for any reason, then shoot
				*/

				// a must be between -dodge_rock_diffangle and dodge_rock_diffangle. a > 0 -> the bot should run to the rock's left. a < 0 -> the bot should run to the rock's right
				if (!(id in DodgingBots) && l4b.Settings.dodge_rock && a >= -l4b.Settings.dodge_rock_diffangle && a <= l4b.Settings.dodge_rock_diffangle && l4b.TryDodge(bot, lft, a > 0, l4b.Settings.dodge_rock_mindistance, l4b.Settings.dodge_rock_maxdistance))
					DodgingBots[id] <- 1;
				//lxc now we can move and shoot in same time, rock can be destroyed if health > 0, don't waste bullets
				if (l4b.Settings.shoot_rock && self.GetHealth() > 0 && a >= -l4b.Settings.shoot_rock_diffangle && a <= l4b.Settings.shoot_rock_diffangle)
				{
					local aw = bot.GetActiveWeapon();
					if (aw && aw.IsValid() && (bot.IsFiringWeapon() || Time() >= NetProps.GetPropFloat(aw, "m_flNextPrimaryAttack")) && distance <= l4b.GetWeaponRangeById(Left4Utils.GetWeaponId(aw)))
					{
						//l4b.PlayerPressButton(bot, BUTTON_ATTACK, 0.0, self.GetCenter() + (fwd * l4b.Settings.shoot_rock_ahead), 0, 0, true); // Try to shoot slightly in front of the rock
						
						//lxc no need freeze bot anymore
						local scope = bot.GetScriptScope();
						if (scope.AimType <= AI_AIM_TYPE.Rock)
						{
							scope.BotSetAim(AI_AIM_TYPE.Rock, self, 0.5); //need refresh target, if can't see rock, will pasue aim and shoot after this delay
							Left4Utils.PlayerForceButton(bot, BUTTON_ATTACK);
							
							l4b.Logger.Debug(bot.GetPlayerName() + " shooting at rock " + self.GetEntityIndex());
						}
					}
				}
			}
		}
	}

	return -1;
}

// Loads the given survivor weapon preference file and returns an array with 5 elements (one for each inventory slot)
// Each element is a sub-array with the weapon list from the highest to the lowest priority one for that inventory slot
/*
Support vanilla weapon preference.
		use '*' and '/' split weapon list into each group(Tier)，each group has a priority.
		flag for single group:
			*: no priority, bot will just pick up any one of them.
			/: have priority.
	
	Without any flag or only at the beginning of each line, it is still l4b2 style (all weapons are at the same group, and have priority (determined by *))
	https://github.com/smilz0/Left4Bots/issues/104
*/
::Left4Bots.LoadWeaponPreferences <- function (survivor, scope)
{
	// WeapPref array has one sub-array for each inventory slot
	// Each sub-array contains the weapons from the highest to the lowest priority one for that inventory slot
	scope.WeapPref <- [[], [], [], [], []]; 
	//new format like this: [[[],[]...], [], [], [], []];
	
	if (!survivor || !survivor.IsValid() || !scope)
		return;

	//Logger.Debug("LoadWeaponPreferences - survivor: " + survivor.GetPlayerName());

	// TODO: do this with the character id instead
	local filename = GetCharacterDisplayName(survivor);
	if (filename == null || filename == "")
		filename = survivor.GetPlayerName(); // Apparently the L4D1 survivors in The Passing 3 don't have a CharacterDisplayName
	filename = Settings.file_weapons_prefix + filename.tolower() + ".txt";
	local lines = Left4Utils.FileToStringList(filename);
	if (!lines)
		return;

	local c = 0;
	for (local i = 0; i < lines.len(); i++)
	{
		local line = Left4Utils.StripComments(lines[i]);
		if (line != "")
		{
			local Tier = -1;
			local weaps = split(line, ",");
			for (local x = 0; x < weaps.len(); x++)
			{
				//delete space characters which cause bug
				local wp = strip(weaps[x]);
				
				// Start a new line when find a flag
				if (wp == "*" || wp == "/" || x == 0)
				{
					Tier++;
					local arr = [(wp == "*")] // set NoPref flag into first
					scope.WeapPref[i].append(arr);
				}
				
				local id = Left4Utils.GetWeaponIdByName(wp);

				//Logger.Debug("LoadWeaponPreferences - i: " + i + " - w: " + wp + " - id: " + id);

				if (id > Left4Utils.WeaponId.none && id != Left4Utils.MeleeWeaponId.none && id != Left4Utils.UpgradeWeaponId.none)
				{
					scope.WeapPref[i][Tier].append(id); // valid weapon
					c++;
				}
			}
		}
	}
	
	/*
	printl(filename);
	foreach(slot, list in scope.WeapPref)
	{
		printl("slot" + slot)
		__DumpScope(4, list);
	}
	*/
	
	Logger.Debug("LoadWeaponPreferences - Loaded " + c + " preferences for survivor: " + survivor.GetPlayerName() + " from file: " + filename);
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
		//Logger.Debug(mapping);
		mapping = Left4Utils.StringReplace(mapping, "\\t", "");
		mapping = Left4Utils.StripComments(mapping);
		if (mapping && mapping != "")
		{
			mapping = strip(mapping);
			//Logger.Debug(mapping);

			if (mapping && mapping != "")
			{
				local idx = mapping.find("=");
				if (idx != null)
				{
					local command = mapping.slice(0, idx);
					command = Left4Utils.StringReplace(command, "\"", "");
					command = strip(command);
					//Logger.Debug(command);

					local value1 = mapping.slice(idx + 1);
					local value2 = "";

					value1 = Left4Utils.StringReplace(value1, "\"", "");
					value1 = strip(value1);

					//Logger.Debug("MAPPING: " + command + " = " + value1);

					local values = split(value1, ",");
					value1 = values[0];
					if (values.len() > 1)
						value2 = values[1];
					else
					{
						value2 = Left4Utils.StringReplace(value1, "bot ", "botname ");
						value2 = Left4Utils.StringReplace(value2, "bots ", "botname ");
					}

					ret[command] <- { all = value1, one = value2 };

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
	if (!ent || !ent.IsValid() || ent.GetContext("skip_use")) //lxc filter if someone about pick
		return false;

	if (ent.GetClassname().find("_spawn") != null)
	{
		// It's a spawner, we just check if the item count is still > 0
		return (NetProps.GetPropInt(ent, "m_itemCount") > 0);
	}

	// It's the item itself, let's check if someone already picked it up
	return (ent.GetMoveParent() == null /*&& NetProps.GetPropInt(ent, "m_iState") != 1*/); // The melee has this to 1 while it's replaced by the pistol when you are incapped but "in theory" this shouldn't be needed because moveparent doesn't change
}

// Is the entity a valid use item?
::Left4Bots.IsValidUseItem <- function (ent, allowedMoveParent = null)
{
	if (!ent || !ent.IsValid())
		return false;

	//Logger.Debug("IsValidUseItem - allowedMoveParent: " + allowedMoveParent);

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
		if (IsValidUseItem(ent))
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
		if (IsValidUseItem(ent))
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
		if (IsValidUseItem(ent))
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
		if (IsValidUseItem(ent))
		{
			local dist = (ent.GetCenter() - orig).Length();
			local entClass = ent.GetClassname();
			local wId = Left4Utils.GetWeaponId(ent);
			if (dist < minDist && /*(entClass.find("weapon_") != null || entClass.find("prop_physics") != null) &&*/ entClass != "weapon_scavenge_item_spawn" && entClass != "weapon_gascan_spawn" && ((ScavengeUseType == SCAV_TYPE_GASCAN && wId == Left4Utils.WeaponId.weapon_gascan) || (ScavengeUseType == SCAV_TYPE_COLA && wId == Left4Utils.WeaponId.weapon_cola_bottles)))
			{
				ret = ent;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Returns the nearest barricade gascans within the given radius from origin
::Left4Bots.FindNearestBarricadeGascans <- function (orig, radius)
{
	local ret = null;
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindByModel(ent, "models/props_unique/wooden_barricade_gascans.mdl"))
	{
		local dist = (ent.GetCenter() - orig).Length();
		//local entClass = ent.GetClassname();
		if (dist < minDist && dist < radius /*&& entClass.find("prop_physics") != null */)
		{
			ret = ent;
			minDist = dist;
		}
	}
	return ret;
}

// Finds the best position for the bot to stand while using the given use target (or while shooting the given barricade gascans)
::Left4Bots.FindBestUseTargetPos <- function (useTarget, orig = null, angl = null, fwdFailsafe = true, debugShow = false, debugShowTime = 15, posDist = 35, ignoreEnt = null)
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

	grounds.append(Left4Utils.FindGround(orig, angl, 315, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 0, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 45, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 90, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 135, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 180, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 225, debugShow, debugShowTime, posDist, ignoreEnt));
	grounds.append(Left4Utils.FindGround(orig, angl, 270, debugShow, debugShowTime, posDist, ignoreEnt));
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
		//lxc use "melee_range", otherwise the bots might just swing melee and hit nothing.
		local melee_range = Convars.GetFloat("melee_range");
		return Settings.manual_attack_radius < melee_range ? Settings.manual_attack_radius : melee_range; // TODO: maybe we should make it a setting
	}
	
	if (weaponId == Left4Utils.WeaponId.weapon_pumpshotgun || weaponId == Left4Utils.WeaponId.weapon_autoshotgun || weaponId == Left4Utils.WeaponId.weapon_shotgun_chrome || weaponId == Left4Utils.WeaponId.weapon_shotgun_spas)
		return Settings.manual_attack_radius < 600 ? Settings.manual_attack_radius : 600;

	return Settings.manual_attack_radius;
}

// Returns whether the given bot has visibility on the given pickup item
::Left4Bots.CanTraceToPickup <- function (bot, item)
{
	//local mask = 0x1 | 0x8 | 0x40 | 0x2000 | 0x4000  | 0x8000000; // CONTENTS_SOLID | CONTENTS_GRATE | CONTENTS_BLOCKLOS | CONTENTS_IGNORE_NODRAW_OPAQUE | CONTENTS_MOVEABLE | CONTENTS_DETAIL
	local traceTable = { start = bot.EyePosition(), end = item.GetCenter(), ignore = bot, mask = Settings.tracemask_pickups };

	TraceLine(traceTable);

	//printl("fraction: " + traceTable.fraction);
	//DebugDrawCircle(traceTable.pos, Vector(0, 0, 255), 255, 10, true, 0.1);

	return (traceTable.fraction > 0.98 || !traceTable.hit || !traceTable.enthit || traceTable.enthit == item || traceTable.enthit.GetClassname() == "prop_health_cabinet");
}

// Finds/Sets the scavenge use target
::Left4Bots.SetScavengeUseTarget <- function ()
{
	//Logger.Debug("SetScavengeUseTarget");

	ScavengeUseTarget = Entities.FindByClassname(null, "point_prop_use_target");
	if (!ScavengeUseTarget)
		return false;

	ScavengeUseType = NetProps.GetPropInt(ScavengeUseTarget, "m_spawnflags");

	if (ScavengeUseType == SCAV_TYPE_GASCAN)
		Logger.Info("Scavenge use target found (type: Gascan)");
	else if (ScavengeUseType == SCAV_TYPE_COLA)
		Logger.Info("Scavenge use target found (type: Cola)");
	else
	{
		Logger.Warning("Unsupported scavenge use target type: " + ScavengeUseType + "; switching to type: Gascan");

		ScavengeUseType = SCAV_TYPE_GASCAN;
	}

	ScavengeUseTargetPos = FindBestUseTargetPos(ScavengeUseTarget, null, null, true, Settings.scavenge_usetarget_debug);
	if (!ScavengeUseTargetPos)
	{
		ScavengeUseTarget = null;
		ScavengeUseType = 0;
		return false;
	}

	return true;
}

// Returns the list of scavenge items of type 'Left4Bots.ScavengeUseType'
::Left4Bots.GetAvailableScavengeItems <- function ()
{
	local t = {};
	if (!ScavengeUseTarget || !ScavengeUseTarget.IsValid())
		return t;
	
	//	- Spawned gascans have class "weapon_gascan" when they have been picked up by players; after spawn too but i'm not 100% sure.
	//	  They can have different m_nSkin (default is 0).
	//	  In scavenge maps (regardless the gamemode) they are spawned by weapon_scavenge_item_spawn
	//
	//	- cola's class can be "prop_physics" after spawn but it becomes "weapon_cola_bottles" after being picked up by a player; model should be always the same.

	local model = ScavengeUseType == SCAV_TYPE_COLA ? "models/w_models/weapons/w_cola.mdl" : "models/props_junk/gascan001a.mdl";
	local ent = null;
	local i = -1;
	while (ent = Entities.FindByModel(ent, model))
	{
		if (ent.IsValid() && (Settings.scavenge_pour || (ent.GetOrigin() - ScavengeUseTarget.GetOrigin()).Length() >= Settings.scavenge_drop_radius) && IsValidPickup(ent) && !BotsHaveOrderDestEnt(ent))
			t[++i] <- { ent = ent, flow = GetFlowDistanceForPosition(ent.GetOrigin()) };
	}
	return t;
}

::Left4Bots.ScavengeStart <- function ()
{
	// TODO: Create and start a Scavenge task
}

::Left4Bots.ScavengeStop <- function ()
{
	// TODO: 
}

// Makes the given 'player' (likely a survivor bot) trigger the given 'alarm' (prop_car_alarm)
::Left4Bots.TriggerCarAlarm <- function (player, alarm)
{
	if (!player || !alarm || !player.IsValid() || !alarm.IsValid() || alarm.GetClassname() != "prop_car_alarm" || IsCarAlarmTriggered(alarm))
		return;

	Logger.Debug("TriggerCarAlarm - player: " + player.GetPlayerName());

	DoEntFire("!self", "SurvivorStandingOnCar", "", 0, alarm, alarm); // Activator is who triggers the alarm but it doesn't work with bots. This way it triggers but i need to play the vocalizer lines manually.

	local actor = Left4Utils.GetActorFromSurvivor(player);

	player.SetContext("subject", actor, 0.1);
	player.SetContext("panictype", "CarAlarm", 0.1);
	//DoEntFire("!self", "AddContext", "subject:" + actor, 0, null, player);
	//DoEntFire("!self", "AddContext", "panictype:CarAlarm", 0, null, player);
	DoEntFire("!self", "SpeakResponseConcept", "PanicEvent", 0, null, player);
	//DoEntFire("!self", "ClearContext", "", 0, null, player);

	foreach (surv in GetOtherAliveSurvivors(player.GetPlayerUserId()))
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

	local kvs = { classname = "script_nav_blocker", origin = spit.GetOrigin(), extent = Vector(Settings.dodge_spit_radius, Settings.dodge_spit_radius, Settings.dodge_spit_radius), teamToBlock = "2", affectsFlow = "0" };
	local ent = g_ModeScript.CreateSingleSimpleEntityFromTable(kvs);
	ent.ValidateScriptScope();
	Logger.Debug("Created script_nav_blocker (spit): " + ent.GetName());

	DoEntFire("!self", "SetParent", "!activator", 0, spit, ent); // I parent the nav blocker to the spit entity so it is automatically killed when the spit is gone
	DoEntFire("!self", "BlockNav", "", 0, null, ent);
}

// Returns whether the given *_spawn entity has available items to spawn (m_itemCount > minCount or it's set to infinite items)
::Left4Bots.SpawnerHasItems <- function (spawner_ent, minCount = 0)
{
	// Note: m_itemCount has already been decreased by 1 when OnPlayerUse is triggered (but not when it's called from PickupFailsafe)

	local m_itemCount = NetProps.GetPropInt(spawner_ent, "m_itemCount");
	local m_spawnflags = NetProps.GetPropInt(spawner_ent, "m_spawnflags");

	Logger.Debug("SpawnerHasItems - " + spawner_ent + " - m_itemCount: " + m_itemCount + " - m_spawnflags: " + m_spawnflags + " - minCount: " + minCount);

	// item count > 0 or infinite items in spawn flags
	return (m_itemCount > minCount || (m_spawnflags & 8) == 8);
}

// Is there any human within the given range from 'srcBot' who may need to pick-up ammo?
::Left4Bots.HumansNeedAmmo <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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
::Left4Bots.HumansNeedWeapon <- function (srcBot, weaponId, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local tier = Left4Utils.GetWeaponTierById(weaponId);

	Logger.Debug("HumansNeedWeapon - weaponId: " + weaponId + " - tier: " + tier);

	if (tier <= 0)
		return false;

	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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

				Logger.Debug("HumansNeedWeapon - w: " + w.GetClassname() + " - wt: " + wt);

				if (wt < tier)
					return true;
			}
		}
	}
	return false;
}

// Is there any human within the given range from 'srcBot' who may need to pick-up a medkit?
::Left4Bots.HumansNeedMedkit <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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
::Left4Bots.HumansNeedTempMed <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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
::Left4Bots.HumansNeedThrowable <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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
::Left4Bots.HumansNeedUpgradeAmmo <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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
::Left4Bots.HumansNeedLaserSight <- function (srcBot, minDist = 250.0, maxDist = 2500.0)
{
	// TODO: use SurvivorFlow ?
	local orig = srcBot.GetOrigin();
	foreach (surv in Survivors)
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
::Left4Bots.GetOtherMedkitSpawn <- function (srcSpawn, radius = 100.0)
{
	local ent = null;
	local srcSpawnIndex = srcSpawn.GetEntityIndex();
	while (ent = Entities.FindByClassnameWithin(ent, "weapon_first_aid_kit_spawn", srcSpawn.GetOrigin(), radius))
	{
		if (ent.IsValid() && ent.GetEntityIndex() != srcSpawnIndex && SpawnerHasItems(ent))
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
	if (LastSignalType == signalType && (t - LastSignalTime) <= Settings.signal_min_interval)
		return;

	LastSignalType = signalType;
	LastSignalTime = t;

	if (weaponname)
	{
		Logger.Debug("DoSignal - " + who.GetPlayerName() + " -> " + what + " - " + concept + " - " + weaponname);

		who.SetContext("weaponname", weaponname, 0.1);
		//DoEntFire("!self", "AddContext", "weaponname:" + weaponname, 0, null, who);
		DoEntFire("!self", "SpeakResponseConcept", concept, 0, null, who);
		//DoEntFire("!self", "ClearContext", "", 0, null, who);
	}
	else
	{
		Logger.Debug("DoSignal - " + who.GetPlayerName() + " -> " + what + " - " + concept);

		DoEntFire("!self", "SpeakResponseConcept", concept, 0, null, who);
	}

	if (Settings.signal_chat && chatText)
		Say(who, chatText, true);

	if (L4F && Settings.signal_ping)
		Left4Fun.PingEnt(who, what);
}

// Returns the number of other survivors alive (and not incapacitated) whithin the given radius
::Left4Bots.CountOtherStandingSurvivorsWithin <- function (me, radius)
{
	// TODO: use SurvivorFlow ?
	local ret = 0;
	foreach (surv in GetOtherAliveSurvivors(me.GetPlayerUserId()))
		ret += (!surv.IsIncapacitated() && (surv.GetOrigin() - me.GetOrigin()).Length() <= radius).tointeger();
	return ret;
}

// Cancels the revive and forces the bot to throw its pipe bomb/vomit jar
// 'bot' and 'subject' are the bot who is reviving and the survivor who is being revived
// 'pos' is the desired throw location
::Left4Bots.CancelReviveAndThrowNade <- function (bot, subject, pos)
{
	Logger.Debug("CancelReviveAndThrowNade - bot: " + bot.GetPlayerName() + " - subject: " + subject.GetPlayerName());

	NetProps.SetPropEntity(bot, "m_reviveTarget", null);
	NetProps.SetPropEntity(subject, "m_reviveOwner", null);

	//lxc clear progress bar and revive animation for survivor, if 'subject' is human, it's necessary
	NetProps.SetPropFloat(bot, "m_flProgressBarDuration", 0);
	NetProps.SetPropFloat(subject, "m_flProgressBarDuration", 0);
	
	Left4Utils.BotCmdReset(bot);

	//BotThrow(bot, pos);
	Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Bots.BotThrow.bindenv(::Left4Bots)(params.bot, params.pos), { bot = bot, pos = pos });
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
	Logger.Debug("SpecialGotSurvivor - special: " + special.GetPlayerName() + " - survivor: " + survivor.GetPlayerName() + " - attackType: " + attackType);

	/*
	foreach (id, bot in Bots)
	{
		if (bot.IsValid() && id != survivor.GetPlayerUserId())
			Left4Utils.BotCmdAttack(bot, special);
	}
	*/

	if (IsHandledBot(survivor))
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

	local points = GetSmokerTargetPoints(tongue, smoker, victim);

	foreach (bot in Bots)
	{
		//if (bot && bot.IsValid() && !bot.IsDying() && NetProps.GetPropInt(bot, "m_reviveTarget") <= 0 && NetProps.GetPropInt(bot, "m_iCurrentUseAction") <= 0 && !Left4Utils.IsPlayerHeld(bot))
		if (bot && bot.IsValid() && !bot.IsDying() && !SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			//lxc check first
			local scope = bot.GetScriptScope();
			if (scope.AimType > AI_AIM_TYPE.Shoot)
				continue;
			
			//Left4Utils.BotCmdAttack(bot, smoker);

			//lxc ValidWeaponForSmoker() can not match "weapon_autoshotgun"
			if (ValidWeaponForSmoker(bot.GetActiveWeapon()) && !CanTraceToSmoker(bot, smoker))
			{
				if ((victim.GetCenter() - bot.GetCenter()).Length() < 100)
					continue;

				if (bot.GetActiveWeapon().GetClassname().find("shotgun") != null && (victim.GetCenter() - bot.GetCenter()).Length() > 600 && (smoker.GetCenter() - bot.GetCenter()).Length() > 600)
					continue;

				for (local i = 0; i < points.len(); i++)
				{
					local p = points[i];
					if (Left4Utils.CanTraceToPos(bot, p, Settings.tracemask_others))
					{
						//lxc no need freeze bot anymore
						scope.BotSetAim(AI_AIM_TYPE.Shoot, p, 0.6);
						Left4Utils.PlayerForceButton(bot, BUTTON_ATTACK);
					
						Logger.Info(bot.GetPlayerName() + " shooting the smoker's tongue");

						//DebugDrawCircle(p, Vector(255, 0, 0), 255, 2, true, 1.5);
						if (duck)
							PlayerPressButton(bot, BUTTON_DUCK, 1.5);
						
						/*PlayerPressButton(bot, BUTTON_ATTACK, 0, p, 0, 0, true);
						Left4Timers.AddTimer(null, 0.5, @(params) PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = 0, destination = p, deltaPitch = 0, deltaYaw = 0, lockLook = true });
						Left4Timers.AddTimer(null, 0.9, @(params) PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = 0, destination = p, deltaPitch = 0, deltaYaw = 0, lockLook = true });
						Left4Timers.AddTimer(null, 1.4, @(params) PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = 0, destination = p, deltaPitch = 0, deltaYaw = 0, lockLook = true });*/
						
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

	// TODO: replace with IsRangedWeapon
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
	if (Left4Utils.CanTraceToEntPos(source, smoker, smoker.GetAttachmentOrigin(smoker.LookupAttachment("smoker_mouth")), Settings.tracemask_others))
		return true;

	if (Left4Utils.CanTraceToEntPos(source, smoker, smoker.GetCenter(), Settings.tracemask_others))
		return true;

	if (Left4Utils.CanTraceToEntPos(source, smoker, smoker.GetOrigin(), Settings.tracemask_others))
		return true;

	return false;
}

// Returns whether the weapon with the given id and inventory slot is a ranged weapon (basically any non melee/chainsaw weapon that belongs to the 1st or 2nd inventory slot)
::Left4Bots.IsRangedWeapon <- function (weaponId, weaponSlot)
{
	return ((weaponId > Left4Utils.WeaponId.none && weaponId < Left4Utils.MeleeWeaponId.none && weaponId != Left4Utils.WeaponId.weapon_chainsaw) && (weaponSlot == 0 || weaponSlot == 1));
}

// Disables BUTTON_ATTACK and set the primary/secondary weapons howner to null in order to prevent the bot from dropping the carry item
::Left4Bots.CarryItemStart <- function(bot)
{
	Logger.Debug("CarryItemStart - bot: " + bot.GetPlayerName());
	
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
	Logger.Debug("CarryItemStop - bot: " + bot.GetPlayerName());
	
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
		BotSwitchToAnotherWeapon(bot); // <- Best method
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
		Logger.Error("GetClosestCarriableByWeaponIdWhithin - No model for item with weaponId: " + weaponId);
		return ret;
	}
	
	local minDist = 1000000;
	local ent = null;
	while (ent = Entities.FindByModel(ent, modelToSearch))
	{
		local d = (ent.GetOrigin() - origin).Length();
		if ((range == 0 || d <= range) && d < minDist && Left4Utils.GetWeaponId(ent) == weaponId && ent.GetMoveParent() == null && (!availCheck || !BotsHaveOrderDestEnt(ent)))
		{
			ret = ent;
			minDist = d;
		}
	}
	return ret;
}

// Automation debug hud text
::Left4Bots.RefreshAutomationDebugHudText <- function()
{
	local str = "";
	foreach (task in Automation.CurrentTasks)
	{
		if (str != "")
			str += ", ";
		str += "[" + task._target + " " + task._order + " (" + task.IsStarted() + ")]";
	}
	if (str == "")
		str = "[]";
	
	Left4Hud.SetHudText("l4b2automation", "Flow: " + Automation.PrevFlow + " - Tasks: " + str);
}

// Orders debug hud text
::Left4Bots.RefreshOrdersDebugHudText <- function()
{
	local i = 0;
	foreach (bot in Bots)
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
		
		Left4Hud.SetHudText("l4b2orders" + i, txt);
	}
}

// Check whether the given bot needs that item (pills/adrenaline) and forces switch to another weapon if not needed
::Left4Bots.CheckBotPickup <- function (bot, item)
{
	if (!bot || !bot.IsValid() || (bot.GetHealth() + bot.GetHealthBuffer()) < 50)
		return;
		
	local activeWeapon = bot.GetActiveWeapon();
	if (activeWeapon && activeWeapon.GetClassname() == item)
		BotSwitchToAnotherWeapon(bot);
}

// Resets all the movement/flags
::Left4Bots.PlayerResetAll <- function (player)
{
	Logger.Debug("PlayerResetAll - " + player.GetPlayerName());

	if (NetProps.GetPropInt(player, "movetype") == 0)
		NetProps.SetPropInt(player, "movetype", 2);
	
	CarryItemStop(player);

	NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN
	NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") & (~BUTTON_ATTACK)); // enable FIRE button
	NetProps.SetPropInt(player, "m_afButtonForced", 0); // clear forced buttons
	//NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~BUTTON_DUCK));
}

//lxc check if we need holding button, otherwise release. by this, we don't need get "m_nUseTime", and quickly unfreeze if bot release button for other reason.
::Left4Bots.CheckReleaseButton <- function (bot, button, lockLook)
{
	//m_iCurrentUseAction 0 = none, 1 = first aid, func_button_timed, 4 = defibrillator, 5 = revive from defibrillator
															//lxc if "m_useActionOwner" is me, means I pressed the button						//help friend
	if ((NetProps.GetPropInt(bot, "m_iCurrentUseAction") > 0 && NetProps.GetPropEntity(bot, "m_useActionOwner") == bot) || NetProps.GetPropEntity(bot, "m_reviveTarget"))
	{
		//lxc keep frozen if needed
		if (lockLook)
			NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") | (1 << 5));
		
		//repeat every 0.1s
		DoEntFire("!self", "RunScriptCode", format("Left4Bots.CheckReleaseButton(self, %d, %d);", button, lockLook), 0.099, null, bot);
	}
	else
	{
		if (button == BUTTON_ATTACK)
		{
			local scope = bot.GetScriptScope();
			scope.AttackButtonForced = false;
		}
		Left4Utils.PlayerUnForceButton(bot, button);
		if (lockLook)
			Left4Utils.UnfreezePlayer(bot);
	}
}

//lxc if timeout, release button
::Left4Bots.ReleaseButton <- function (bot, button, endtime, lockLook)
{
	if (Time() < endtime)
	{
		//lxc keep frozen if needed
		if (lockLook)
			NetProps.SetPropInt(bot, "m_fFlags", NetProps.GetPropInt(bot, "m_fFlags") | (1 << 5));
		
		//repeat every 0.1s
		DoEntFire("!self", "RunScriptCode", format("Left4Bots.ReleaseButton(self, %d, %f, %d);", button, endtime, lockLook), 0.099, null, bot);
	}
	else
	{
		if (button == BUTTON_ATTACK)
		{
			local scope = bot.GetScriptScope();
			scope.AttackButtonForced = false;
		}
		Left4Utils.PlayerUnForceButton(bot, button);
		if (lockLook)
			Left4Utils.UnfreezePlayer(bot);
	}
}

// get head, otherwise return center pos
::Left4Bots.GetHitPos <- function (victim, head = true)
{
	if ("GetLastKnownArea" in victim)
	{
		if (head == true) // head
		{
			//survivor, common infected, smoker, boomer, hunter, witch
			local BoneId = victim.LookupBone("ValveBiped.Bip01_Head1");
								//spitter, jockey, charger						//tank
			if (BoneId != -1 || (BoneId = victim.LookupBone("bip_head")) != -1 || (BoneId = victim.LookupBone("ValveBiped.Bip01_Head")) != -1)
				return victim.GetBoneOrigin(BoneId);
		}
		else if (head == false) // chest
		{
			//survivor, common infected, smoker, boomer, hunter, witch, tank
			local BoneId = victim.LookupBone("ValveBiped.Bip01_Spine1");
								//spitter, jockey, charger
			if (BoneId != -1 || (BoneId = victim.LookupBone("bip_spine_1")) != -1)
				return victim.GetBoneOrigin(BoneId);
		}
		else if (head == null) // foot, use for weapons like grenade launcher
			return victim.GetOrigin();
		
		// Fast Headcrab (Jockey) https://steamcommunity.com/sharedfiles/filedetails/?id=3121830019
		// this model use custom named bone, and cannot hit Center pos
		return victim.GetBoneOrigin(0);
	}
	
	//lxc center should be better
	//return victim.GetOrigin();
	return victim.GetCenter();
}

// Moved here because Left4Utils.PlayerPressButton can be used by other addons
::Left4Bots.PlayerPressButton <- function (player, button, holdTime = 0.0, destination = null, deltaPitch = 0, deltaYaw = 0, lockLook = false, unlockLookDelay = 0)
{
	if (!player || !player.IsValid())
		return;
	
	if (lockLook)
	{
		// make bot look at target
		local scope = player.GetScriptScope();
		scope.BotUnSetAim();
		
		local aimtype = AI_AIM_TYPE.Order;
		// Make the bot keep looking at the target At least 0.5s even after the order is completed, making them looks like the vanilla AI
		local aimtime = 0.5;
		
		// don't freeze if throw grenade
		if (unlockLookDelay == 0)
			NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") | (1 << 5)); // set FL_FROZEN
		//Left4Timers.AddTimer(null, holdTime + unlockLookDelay, @(params) ::Left4Utils.UnfreezePlayer(params.player), { player = player });
		else
		{
			//deal with throw grenade
			lockLook = false;
			aimtype = AI_AIM_TYPE.Throw;
			aimtime = unlockLookDelay;
		}
		
		// fix bots rotating when pick up item
		local aimtarget = (typeof(destination) == "instance" && !("GetLastKnownArea" in destination)) ? destination.GetOrigin() : destination;
		
		scope.BotSetAim(aimtype, aimtarget, aimtime, deltaPitch, deltaYaw);
	}
	
	if (destination != null || deltaPitch != 0 || deltaYaw != 0)
		Left4Utils.BotLookAt(player, destination, deltaPitch, deltaYaw);
	
	// prevent release the button in wrong way
	if (button == BUTTON_ATTACK)
	{
		local scope = player.GetScriptScope();
		scope.AttackButtonForced = true;
	}
	
	Left4Utils.PlayerForceButton(player, button);
	
	if (holdTime == 0.0)
	{
		DoEntFire("!self", "RunScriptCode", format("Left4Bots.CheckReleaseButton(self, %d, %d);", button, lockLook.tointeger()), 0.099, null, player);
	}
	else //if user set custom use time
	{
		DoEntFire("!self", "RunScriptCode", format("Left4Bots.ReleaseButton(self, %d, %f, %d);", button, Time() + holdTime, lockLook.tointeger()), -1, null, player);
	}
	//Left4Timers.AddTimer(null, holdTime, @(params) ::Left4Utils.PlayerUnForceButton(params.player, params.button), { player = player, button = button });
}

// Returns the survivors highest flow percent
::Left4Bots.GetFlowPercent <- function ()
{
	local ret = 0;
	foreach (surv in Survivors)
	{
		if (surv && surv.IsValid())
		{
			local flow = GetCurrentFlowPercentForPlayer(surv);
			if (flow > ret)
				ret = flow;
		}
	}
	return ret;
}

// Returns whether the there is at least one aggroed tank whithin 'min' and 'max' units from 'origin'
::Left4Bots.HasAggroedTankWithin <- function (origin, min = 80, max = 1000)
{
	foreach (tank in Tanks)
	{
		if (tank && tank.IsValid() && NetProps.GetPropInt(tank, "m_lifeState") == 0 /* is alive? */ && !tank.IsIncapacitated() && NetProps.GetPropInt(tank, "m_lookatPlayer") >= 0)
		{
			local dist = (origin - tank.GetOrigin()).Length();
			if (dist >= min && dist <= max)
			{
				return true;
			}
		}
	}
	return false;
}

// Returns the nearest aggroed tank whithin 'min' and 'max' units from 'origin'
::Left4Bots.GetNearestAggroedTankWithin <- function (origin, min = 80, max = 1000)
{
	local ret = null;
	local minDist = max;
	foreach (tank in Tanks)
	{
		if (tank && tank.IsValid() && NetProps.GetPropInt(tank, "m_lifeState") == 0 /* is alive? */ && !tank.IsIncapacitated() && NetProps.GetPropInt(tank, "m_lookatPlayer") >= 0)
		{
			local dist = (origin - tank.GetOrigin()).Length();
			if (dist >= min && dist < minDist)
			{
				ret = tank;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Returns the nearest aggroed visible tank whithin 'min' and 'max' units from 'origin'
::Left4Bots.GetNearestAggroedVisibleTankWithin <- function (player, origin, min = 80, max = 1000)
{
	local ret = null;
	local minDist = max;
	local tracemask_others = Settings.tracemask_others;
	foreach (tank in Tanks)
	{
		if (tank && tank.IsValid() && NetProps.GetPropInt(tank, "m_lifeState") == 0 /* is alive? */ && !tank.IsIncapacitated() && NetProps.GetPropInt(tank, "m_lookatPlayer") >= 0 && Left4Utils.CanTraceTo(player, tank, tracemask_others))
		{
			local dist = (origin - tank.GetOrigin()).Length();
			if (dist >= min && dist < minDist)
			{
				ret = tank;
				minDist = dist;
			}
		}
	}
	return ret;
}

// Handles the dodging of the spitter's acid dropped upon spitter's death
::Left4Bots.FindSpitterDeathPool <- function (spitterpos)
{
	local spit = null;
	
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "insect_swarm", spitterpos, 300); )
	{
		//lxc compare pos to find the dead spitter's acid
		if ((ent.GetOrigin() - spitterpos).Length2D() == 0)
		{
			spit = ent;
			break;
		}
	}
	
	if (!spit)
		return;
	
	Logger.Debug("Find Spitter Death Pool - acid pool: " + spit);
	
	if (!Settings.dodge_spit)
		return;
	
	foreach (bot in Bots)
	{
		if (bot.IsValid() && !SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
			TryDodgeSpit(bot, spit);
	}
	
	//lxc if script_nav_blocker already created and bots in it's radius, 'TryGetPathableLocationWithin()' can not find pos.
	//Is it possible to use "wait" command instead?
	if (Settings.spit_block_nav)
		Left4Timers.AddTimer(null, 3.8, ::Left4Bots.SpitterSpitBlockNav.bindenv(::Left4Bots), { spit_ent = spit });
}

// Is the given infected angry?
::Left4Bots.IsInfectedAngry <- function (Infected)
{
	return InfectedCalmAct.find(Infected.GetSequenceActivityName(Infected.GetSequence())) == null;
}

// Is the bot with the given userid ahead (on the flow) of human survivors?
::Left4Bots.IsBotAheadOfHumans <- function (userid, threshold = 120)
{
	if (!(userid in SurvivorFlow))
		return true;
	
	local myFlow = SurvivorFlow[userid].flow + threshold;
	foreach (id, f in SurvivorFlow)
	{
		if (id != userid && !f.isBot && f.flow >= myFlow)
			return false;
	}
	return true;
}

// Returns whether the bots should close the saferoom door after the survivor with the given userid entered
::Left4Bots.ShouldCloseSaferoomDoor <- function (userid, range = 0)
{
	Logger.Debug("ShouldCloseSaferoomDoor - userid: " + userid);
	
	if (range == 0)
		return OtherSurvivorsInCheckpoint(userid);
	
	if (!(userid in SurvivorFlow))
	{
		Logger.Debug("ShouldCloseSaferoomDoor - userid: " + userid + " - FALSE");
		return false;
	}
	
	local myFlow = SurvivorFlow[userid].flow;
	foreach (id, f in SurvivorFlow)
	{
		if (id != userid && !f.inCheckpoint && f.flow < myFlow && f.flow >= (myFlow - range))
		{
			Logger.Debug("ShouldCloseSaferoomDoor - userid: " + userid + " - myFlow: " + myFlow + " - f.flow: " + f.flow);
			return false;
		}
	}
	
	Logger.Debug("ShouldCloseSaferoomDoor - userid: " + userid + " - TRUE");
	return true;
}

// https://github.com/smilz0/Left4Bots/issues/86
::Left4Bots.DropItem <- function (player, weapon, weaponClass)
{
	local ammoType = NetProps.GetPropInt(weapon, "m_iPrimaryAmmoType");
	local extraAmmo = NetProps.GetPropIntArray(player, "m_iAmmo", ammoType);
	//printl(extraAmmo);
	
	player.DropItem(weaponClass);
	
	//'DropItem()' not set these steps
	NetProps.SetPropInt(weapon, "m_iExtraPrimaryAmmo", extraAmmo); //set weapon's backup ammo
	NetProps.SetPropIntArray(player, "m_iAmmo", 0, ammoType); //without this, if the player picks up the weapon again, will get more backup ammo
	if (weaponClass == "weapon_defibrillator")
	{
		//set the correct index //https://forums.alliedmods.net/showthread.php?p=1621340#post1621340
		NetProps.SetPropInt(weapon, "m_iWorldModelIndex", GetModelIndex(weapon.GetModelName()));
	}
}

// Removes any active pipe bomb from the map, if needed
::Left4Bots.HandleAntiPipebombBug <- function ()
{
	Logger.Debug("HandleAntiPipebombBug");
	
	if (!::Left4Bots.Settings.anti_pipebomb_bug || !::Left4Bots.OtherSurvivorsInCheckpoint(-1)) // -1 is like: is everyone in checkpoint?
		return;

	::Left4Bots.ClearPipeBombs();

	// If someone is holding a pipe bomb we'll also force them to switch to another weapon to make sure they don't throw the bomb while the door is closing
	foreach (surv in ::Left4Bots.Survivors)
	{
		local activeWeapon = surv.GetActiveWeapon();
		if (activeWeapon && activeWeapon.GetClassname() == "weapon_pipe_bomb")
			::Left4Bots.BotSwitchToAnotherWeapon(surv);
	}
}

// Handles the logics for sending survivor bots to close the door
// player is the survivor that triggered it (the one who is entering the saferoom or speaking the close the door vocalizer line)
::Left4Bots.HandleCloseDoor <- function (player, door = null, area = null)
{
	if (!Left4Bots.IsHandledSurvivor(player) || !Left4Bots.Settings.close_saferoom_door)
		return;

	if (!door)
		door = Entities.FindByClassnameNearest("prop_door_rotating_checkpoint", player.GetOrigin(), 1000);
	if (!door || !door.IsValid())
	{
		Logger.Debug("HandleCloseDoor - No door!");
		return;
	}
	
	if (!area)
		area = NavMesh.GetNearestNavArea(door.GetOrigin(), 200, false, false);

	local allBots = RandomInt(1, 100) <= Left4Bots.Settings.close_saferoom_door_all_chance;
	if ((!allBots && !Left4Bots.IsHandledBot(player)) || !::Left4Bots.ShouldCloseSaferoomDoor(player.GetPlayerUserId(), ::Left4Bots.Settings.close_saferoom_door_behind_range))
		return;

	local state = NetProps.GetPropInt(door, "m_eDoorState"); // 0 = closed - 1 = opening - 2 = open - 3 = closing
	if (state == 0 || state == 3)
		return;

	local doorZ = player.GetOrigin().z;
	if (area)
	{
		doorZ = area.GetCenter().z;
			
		Left4Bots.Logger.Debug("OnGameEvent_player_entered_checkpoint - area: " + area.GetID() + " - DoorZ: " + doorZ);
	}
	else
		Left4Bots.Logger.Debug("OnGameEvent_player_entered_checkpoint - area is null! - DoorZ: " + doorZ);

	if (Left4Bots.IsHandledBot(player))
	{
		local scope = player.GetScriptScope();
		scope.DoorAct = AI_DOOR_ACTION.Saferoom;
		scope.DoorEnt = door; // This tells the bot to close the door. From now on, the bot will start looking for the best moment to close the door without locking himself out (will try at least)
		scope.DoorZ = doorZ;
	}

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
		{
			if (bot != player && ::Left4Bots.IsSurvivorInCheckpoint(bot))
			{
				local scope = bot.GetScriptScope();
				scope.DoorAct = AI_DOOR_ACTION.Saferoom;
				scope.DoorEnt = door; // This tells the bot to close the door. From now on, the bot will start looking for the best moment to close the door without locking himself out (will try at least)
				scope.DoorZ = doorZ;
			}
		}
	}
}

// Only shoot the riot police if i can see his back.
::Left4Bots.IsRiotPolice <- function (ent, start)
{
	//(NetProps.GetPropInt(ent, "m_Gender") == 15)
	local model = ent.GetModelName();
	if (model == "models/infected/common_male_riot.mdl" || model == "models/infected/common_male_riot_l4d1.mdl")
	{
		local chest = ent.LookupAttachment("chest");
		if (chest != 0) // if custom model not has this attachment, don't shoot
		{
			local toEnt = ent.GetOrigin() - start;
			toEnt.Norm();
			local forward = QAngle(0, ent.GetAttachmentAngles(chest).y, 0).Forward();
			local dot = toEnt.Dot(forward);
			//printl("dot: " + dot + ", back: " + (dot > 0));
			return dot <= 0;
		}
		return true;
	}
	return false;
}

// Enables/Disables bots switching to secondary weapon by setting/unsetting its m_hOwner property
::Left4Bots.AllowSecondaryWeaponSwitch <- function(bot, allow)
{
	local w = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_SECONDARY);
	if (w)
		NetProps.SetPropEntity(w, "m_hOwner", (allow ? bot : null));
}

// Handles the logics for allowing/not allowing to switch to secondary
::Left4Bots.EnforcePrimaryWeapon <- function(bot, ActiveWeapon)
{
	local canSwitch = true;
	if ((Settings.enforce_shotgun || Settings.enforce_sniper_rifle) && ActiveWeapon && !bot.IsIncapacitated())
	{
		local wp = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_PRIMARY);
		local wp2nd = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_SECONDARY);
		if (wp && wp2nd && Left4Utils.GetAmmoPercent(wp) > 0)
		{
			local type = Left4Utils.GetWeaponTypeById(Left4Utils.GetWeaponId(wp));
			if (type == "shotgun" || type == "sniper_rifle")
			{
				local type2nd = Left4Utils.GetWeaponTypeById(Left4Utils.GetWeaponId(wp2nd));
				local flag = type2nd == "pistol" ? (wp2nd.GetClassname() == "weapon_pistol_magnum" ? 2 : 1) : 
							 type2nd == "melee" ? 4 : 
							 type2nd == "chainsaw" ? 8 : 
							 0;
				
				if (flag)
				{
					if ((Settings["enforce_" + type] & flag) == flag)
						canSwitch = false;
					
					if (!canSwitch && ActiveWeapon == wp2nd)
					{
						NetProps.SetPropEntity(wp2nd, "m_hOwner", bot);
						bot.SwitchToItem(wp.GetClassname());
						
						//if can not switch to primary weapon, at least we still have one, also fixed chainsaw smoking when pickup and switch at the same time
						return;
					}
				}
			}
		}
	}
	
	AllowSecondaryWeaponSwitch(bot, canSwitch);
}

// Helps update the COMMANDS.md file on the github repo
::Left4Bots.PrintCommandsMarkdown <- function ()
{
	local function CommandToMarkdown(cmdHelpText)
	{
		local field1 = "";
		local field2 = "";
		
		local txt = "";
		for (local i = 0; i < cmdHelpText.len(); i++)
		{
			if (cmdHelpText[i] > 5)
				txt += cmdHelpText[i].tochar();
		}
		
		txt = Left4Utils.StringReplace(txt, "<", "\\<");
		txt = Left4Utils.StringReplace(txt, ">", "\\>");
		txt = split(txt, "\n");
		for (local j = 0; j < txt.len(); j++)
		{
			if (j == 0)
			{
				local cmd = split(txt[0], " ");
				field1 = Left4Utils.StringReplace(cmd[0], "botsource", "_botsource_") + " **" + cmd[1] + "**";
				for (local k = 2; k < cmd.len(); k++)
					field1 += " " + Left4Utils.StringReplace(Left4Utils.StringReplace(cmd[k], "\\[", "[_"), "\\]", "_]");
			}
			else if (j == 1)
				field2 = txt[1];
			else
				field2 += "<br />" + txt[j];
		}
		
		return "| " + field1 + " | " + field2 + " |";
	}
	
	printl("--- ADMIN COMMANDS -------------------------");
	for (local i = 0; i < AdminCommands.len(); i++)
		printl(CommandToMarkdown(Left4Bots["CmdHelp_" + AdminCommands[i]]()));
	
	printl("--- USER COMMANDS --------------------------");
	for (local i = 0; i < UserCommands.len(); i++)
		printl(CommandToMarkdown(Left4Bots["CmdHelp_" + UserCommands[i]]()));
	
	printl("--------------------------------------------");
}

//

::Left4Bots.ModeName = Director.GetGameMode();
::Left4Bots.BaseModeName = Director.GetGameModeBase();
::Left4Bots.MapName = Director.GetMapName();
::Left4Bots.Difficulty = Convars.GetStr("z_difficulty").tolower();
::Left4Bots.SurvivorSet = Director.GetSurvivorSet();

IncludeScript("left4bots_defaults");
IncludeScript("left4bots_ai");
IncludeScript("left4bots_events");
IncludeScript("left4bots_commands");
IncludeScript("left4bots_automation");

try
{
	IncludeScript("left4bots_afterload");
}
catch(exception)
{
	error("[L4B][ERROR] Exception in left4bots_afterload.nut: " + exception + "\n");
}

__CollectEventCallbacks(::Left4Bots.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
__CollectEventCallbacks(::Left4Bots.Automation.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

::Left4Bots.Initialize();
