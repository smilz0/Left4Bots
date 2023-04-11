//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

Msg("Including left4bots...\n");

if (!IncludeScript("left4lib_utils"))
	error("[L4B][ERROR] Failed to include 'left4lib_utils', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_timers"))
	error("[L4B][ERROR] Failed to include 'left4lib_timers', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_concepts"))
	error("[L4B][ERROR] Failed to include 'left4lib_concepts', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_hooks"))
	error("[L4B][ERROR] Failed to include 'left4lib_hooks', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");
if (!IncludeScript("left4lib_users"))
	error("[L4B][ERROR] Failed to include 'left4lib_users', please make sure the 'Left 4 Lib' addon is installed and enabled!\n");

IncludeScript("left4bots_requirements");

::Left4Bots <-
{
	Initialized = false
	ModeName = ""
	MapName = ""
	Difficulty = "" // easy, normal, hard, impossible
	Settings =
	{
		// Prevents (at least will try) the infamous bug of the pipe bomb thrown right before transitioning to the next chapter, the bots will bug out and do nothing for the entire next chapter
		anti_pipebomb_bug = 1
		
		// Interval of the main bot Think function (default is 0.1 which means 10 ticks per second)
		// Set the max i can get even though the think functions can go up to 30 ticks per second (interval 0.0333) and the CTerrorPlayer entities limit their think functions to max 15 ticks per second (0.06666)
		bot_think_interval = 0.01
		
		// How long do the bots hold down the button to defib a dead survivor
		button_holdtime_defib = 3.2
		
		// How long do the bots hold down the button to heal
		button_holdtime_heal = 5.3
		
		// How long do the bots hold down a button to do single tap button press (it has to last at least 2 ticks, so it must be greater than 0.033333 or the weapons firing can fail)
		button_holdtime_tap = 0.04
		
		// Chance that the bot will chat one of the BG lines at the end of the campaign (if dead or incapped)
		chat_bg_chance = 50
		
		// Chance that the bot will chat one of the GG lines at the end of the campaign (if alive)
		chat_gg_chance = 70
		
		// [1/0] Should the last bot entering the saferoom close the door immediately?
		close_saferoom_door = 1
		
		// When the last bot steps into the saferoom he will start the close door procedure when his distance from the door is > than this
		// This is meant to make sure that the bot is actually inside and will not lock himself out
		// NOTE: Maps with bad navmesh (CHECKPOINT nav areas outside of the actual saferoom) might still make the bots lock themselves out. I you can try increasing this in such cases
		close_saferoom_door_distance = 70
		
		// [1/0] 1 = The close door AI code runs every think tick (15 times per second by default). 0 = Run rate is 1/5 (3 times per second default)
		// Basically with 1 the bots will quickly close the door as soon as they are inside. 0 adds more variation with some chance that the bot will step inside further and then go back to the door after a couple of seconds
		close_saferoom_door_highres = 0
		
		// Dead survivors to defib must be within this radius
		deads_scan_radius = 1200
		
		// Max altitude difference between the bot and the dead survivor when scanning for dead survivors to defib
		deads_scan_maxaltdiff = 320
		
		// When survivor bots find a dead survivor to defib but they don't have a defib, they will consider picking up and use defibs within this radius from the dead survivor
		deads_scan_defibradius = 250
		
		// [1/0] Enable/Disable charger dodging
		dodge_charger = 1
		
		// Max angle difference between the charger's current facing direction and the direction to the bot when deciding whether the bot should dodge the charge or not
		dodge_charger_diffangle = 10
		
		// Maximum distance to travel when dodging chargers
		dodge_charger_maxdistance = 600
		
		// Minimum distance to travel when dodging chargers
		dodge_charger_mindistance = 80
		
		// [1/0] Enable/Disable spit dodging
		dodge_spit = 1
		
		// Approximate radius of the spitter's spit on the ground
		dodge_spit_radius = 150
		
		// When the addon tells a bot to open/close a door, the bot does it via USE button (in order to do the hand animation)
		// But if, for some reason, the open/close door fails (too far or something) the door will be forced to open/close by the addon after this delay
		door_failsafe_delay = 0.15
		
		// Name of the file containing the BG chat lines
		file_bg = "left4bots2/cfg/bg.txt"
		
		// Name of the file with the convar changes to load
		file_convars = "left4bots2/cfg/convars.txt"
		
		// Name of the file containing the GG chat lines
		file_gg = "left4bots2/cfg/gg.txt"
		
		// Name of the file containing the list of items to avoid
		//file_itemstoavoid = "left4bots2/cfg/itemstoavoid.txt" // TODO: ?
		
		// Name of the file with the vocalizer/command mapping
		file_vocalizer = "left4bots2/cfg/vocalizer.txt"
		
		// When executing a 'follow' order, the bot will start pause when within move_end_radius_follow from the followed entity, but will only resume when farther than follow_pause_radius, so this has to be > move_end_radius_follow
		follow_pause_radius = 220
		
		// [1/0] Should the bots give their medkits/defibrillators to human players? // TODO: admins?
		give_bots_medkits = 1
		
		// [1/0] Should the bots give their pills/adrenaline to human players?
		give_bots_pills = 1
		
		// [1/0] Should the bots give their throwables to human players?
		give_bots_nades = 1
		
		// [1/0] Should the bots give their upgrade packs to human players?
		give_bots_upgrades = 1
		
		// [1/0] Can the human survivors give their pills/adrenaline to other survivors (and swap with bots)?
		give_humans_meds = 1
		
		// [1/0] Can the human survivors give their molotovs/pipe bombs/bile jars to other survivors (and swap with bots)?
		give_humans_nades = 1
		
		// Maximum distance from the other survivors for giving them items
		give_max_range = 270
		
		// (1/0) Should the L4B AI handle the extra L4D1 survivors (spawned in some maps like "The Passing" or manually by some admin addon)?
		// Does not affect the L4D1 survivors spawned as the main team, they are always handled
		handle_l4d1_survivors = 0
		
		// When the bot tries to heal with a health >= this (usually they do it in the start saferoom) the addon will interrupt it, unless there is no human in the team
		// or there are enough spare medkits around for the bot and the teammates who also need it
		heal_interrupt_minhealth = 50
		
		// [1/0] 1 = The bot will be forced to heal without interrupting when healing himself (unless there are enough infected nearby). 0 = The bot can interrupt healing even without a real threat (vanilla behavior)
		heal_force = 0 // TODO: 1?
		
		// Radius for searching the spare medkits around
		heal_spare_medkits_radius = 500
		
		// [1/0] 1 = valid chat commands given to the bot will be hidden to the other players. 0 = They are visible
		hide_chat_commands = 1
		
		// Chance that the bot will throw the pipe bomb/bile jar at the horde (this check runs multiple times in a second, so this chance must be pretty low to have an actual chance of no throw)
		horde_nades_chance = 30
		
		// When scanning for an actual horde, this is the maximum altitude difference between the bot and the common infected being counted
		horde_nades_maxaltdiff = 200
		
		// When scanning for an actual horde, this is the maximum distance between the bot and the common infected being counted
		horde_nades_radius = 400
		
		// When scanning for an actual horde, this is the minimum number of common infected to count
		horde_nades_size = 10
		
		// (1/0) Enable/Disable the additional trace check on the ground when calculating the 'lead' path
		lead_check_ground = 0
		
		// >0 = each segment calculation of the 'lead' order is drawn on screen for this amount of time (only the host can see it). 0 = Disable
		lead_debug_duration = 0
		
		// Max(ish) distance of a single MOVE segment when executing the 'lead' order
		lead_max_segment = 600
		
		// Max distance from the other survivors when executing the 'lead' order. Bot will pause the leading when too far (0 = no limit)
		lead_max_separation = 1000
		
		// Min distance of a single MOVE segment when executing the 'lead' order (if the next segment's end is closer than this, it means that the goal was reached and the 'lead' is done)
		lead_min_segment = 100
		
		// Vocalizer commands from vocalizer_lead_start will be played when the bot starts a 'lead' order and resumes it after a pause. This is the minimum interval between each vocalization
		lead_vocalize_interval = 30
		
		// Minimum log level for the addon's log lines into the console
		// 0 = No log
		// 1 = Only [ERROR] messages are logged
		// 2 = [ERROR] and [WARNING]
		// 3 = [ERROR], [WARNING] and [INFO]
		// 4 = [ERROR], [WARNING], [INFO] and [DEBUG]
		loglevel = 4 // TODO: 3
		
		// [0.0 - 1.0] While executing MOVE commands, this is how straight the bot should be looking at the enemy in order to shoot it
		// 0.0 = Even the enemies behind will be shoot (CSGO spinbot style). 1.0 = The bot will probably never shoot
		manual_attack_mindot = 0.95
		
		// While executing MOVE commands, this is the max distance of the enemies that the bot will shoot
		manual_attack_radius = 600
		
		// Minimum distance from the destination position for setting the travel done
		move_end_radius = 30
		
		// Minimum distance from the destination dead teammate before starting to defib
		move_end_radius_defib = 80
		
		// Minimum distance from the destination door before open/close it
		move_end_radius_door = 100
		
		// Minimum distance from the destination teammate before starting to heal him
		move_end_radius_heal = 80
		
		// Minimum distance from the destination position for setting the 'lead' travel done
		move_end_radius_lead = 85
		
		// Minimum distance from the followed entity for setting the 'follow' travel done
		move_end_radius_follow = 100
		
		// Minimum distance from the destination witch before starting to shoot her
		move_end_radius_witch = 55
		
		// [1/0] Enable/Disable debug chat messages when the bot starts/stops the pause
		pause_debug = 0
		
		// Minimum duration of the pause. When a bot starts a pause (due to infected nearby, teammates need help etc.), the pause cannot end earlier than this, even if the conditions to stop the pause are met
		pause_min_time = 4.0
		
		// Should the AI pick up the adrenaline?
		pickup_adrenaline = 1
		
		// Should the AI pick up the defibrillators?
		pickup_defib = 1
		
		// Should the AI pick up the medkits?
		pickup_medkit = 1
		
		// Should the AI pick up the molotovs?
		pickup_molotov = 1
		
		// Should the AI pick up the pain pills?
		pickup_pills = 1
		
		// Should the AI pick up the pipe bombs?
		pickup_pipebomb = 1
		
		// Should the AI pick up the upgrade packs?
		pickup_upgrades = 1
		
		// Should the AI pick up the bile jars?
		pickup_vomitjar = 1
		
		// When the addon tells a bot to pickup an item, the bot does it via USE button (in order to do the hand animation)
		// But if, for some reason, the pickup fails (too far or something) the item is forced into the bot's inventory after this delay (to prevent stuck situations)
		pickups_failsafe_delay = 0.15
		
		// Only move for a pick-up if there is at least one human survivor within this range (0 = no limit)
		pickups_max_separation = 600
		
		// Pick up the item we are looking for when within this range
		pickups_pick_range = 99
		
		// Items to pick up must be within this radius (and be visible to the bot)
		pickups_scan_radius = 380
		
		// (1/0) Should the sounds be played on give/swap items?
		play_sounds = 1
		
		// Delta pitch (from his feet) for aiming when shoving common infected
		shove_commons_deltapitch = -6.0
		
		// While executing MOVE commands, the bot will shove common infected within this radius (set 0 to disable)
		shove_commons_radius = 35
		
		// Chance that the bots will try to deadstop a hunter/jockey attack when the attack is directed at them
		shove_deadstop_chance = 95
		
		// Delta pitch (from his feet) for aiming when deadstopping special infected
		shove_deadstop_deltapitch = -9.5
		
		// Delta pitch (from his feet) for aiming when shoving special infected within shove_specials_radius
		shove_specials_deltapitch = -6.0
		
		// Bots will shove special infected (excluding boomers) within this radius (set 0 to disable)
		shove_specials_radius = 70
		
		// Sound scripts to play when a survivor gives an item to another survivor
		// UI/BigReward.wav	(played on the giver)
		sound_give_giver = "Hint.BigReward"
		// UI/LittleReward.wav (Played on all the players except the giver)
		sound_give_others = "Hint.LittleReward"
		
		// Chance that the bot will throw the molotov at the tank (this check runs multiple times in a second while the tank is in range, so this chance must be pretty low to have an actual chance of no throw)
		tank_molotov_chance = 25
		
		// Chance that the bot will throw the bile jar at the tank (this check runs multiple times in a second while the tank is in range, so this chance must be pretty low to have an actual chance of no throw)
		tank_vomitjar_chance = 1
		
		// Tanks with health lower than this do not become molotov/bile jar targets
		tank_throw_min_health = 1500
		
		// Minimum bot's distance to a tank for throwing molotovs/bile jars at the tank
		tank_throw_range_min = 200
		
		// Maximum bot's distance to a tank for throwing molotovs/bile jars at the tank
		tank_throw_range_max = 1200

		// Minimum distance between the tank and the other survivors for throwing molotovs at the tank
		tank_throw_survivors_mindistance = 240

		// Delta pitch (from his feet) for aiming when throwing molotovs/bile jars at the tank ( <0: higher, >0: lower )
		tank_throw_deltapitch = 3
		
		// Max chainsaws in the team
		team_max_chainsaws = 0
		
		// Minimum defibrillators in the team
		team_min_defibs = 0
		
		// Minimum medkits in the team
		team_min_medkits = 4
		
		// [1/0] Enable/Disable throwing molotovs
		throw_molotov = 1
		
		// If a survivor already threw a molotov, don't throw another one before this delay
		throw_molotov_interval = 4.0
		
		// Delta pitch when throwing pipe bombs and bile jars ( <0: higher, >0: lower )
		throw_nade_deltapitch = -6
		
		// If a survivor already threw a pipe bomb or bile jar, don't throw another one before this delay
		throw_nade_interval = 10.0
		
		// Try to throw pipe bombs and bile jars AT LEAST this far or don't throw
		throw_nade_mindistance = 250
		
		// Try to throw pipe bombs and bile jars this far (must be > of throw_nade_mindistance)
		throw_nade_radius = 500
		
		// [1/0] Enable/Disable throwing pipe bombs
		throw_pipebomb = 1
		
		// [1/0] Enable/Disable throwing bile jars
		throw_vomitjar = 1
		
		// Minimum L4U level for receiving medkits/defibs from the bots (2 = Admin, 1 = Friend, 0 = Random player, -1 = Griefer)
		userlevel_give_medkit = 1
		
		// Minimum L4U level for receiving any other items from the bots (2 = Admin, 1 = Friend, 0 = Random player, -1 = Griefer)
		userlevel_give_others = 0
		
		// Minimum L4U level for sending orders to the bots (2 = Admin, 1 = Friend, 0 = Random player, -1 = Griefer)
		userlevel_orders = 1
		
		// Minimum L4U level for triggering a vocalizer response (laugh, thanks, etc.) from the bots (2 = Admin, 1 = Friend, 0 = Random player, -1 = Griefer)
		userlevel_vocalizer = 0
		
		// [1/0] Enable/Disable orders via vocalizer (does not affect orders via chat/console)
		vocalizer_commands = 1
		
		// Comma separated vocalizer commands to speak when the bot ends the 'goto' order (command to speak will be a random one from this list)
		vocalizer_goto_stop = "PlayerAnswerLostCall,PlayerLostCall"
		
		// Chance that the bots will laugh after you laugh
		vocalizer_laugh_chance = 30
		
		// Comma separated vocalizer commands to speak when the bot starts the 'lead' order (command to speak will be a random one from this list)
		vocalizer_lead_start = "PlayerFollowMe,PlayerMoveOn,PlayerEmphaticGo"
		
		// Comma separated vocalizer commands to speak when the bot ends the 'lead' order (command to speak will be a random one from this list)
		vocalizer_lead_stop = "PlayerAnswerLostCall,PlayerLostCall,PlayerStayTogether,PlayerLeadOn"
		
		// Chance that the bot will vocalize "Sorry" after doing friendly fire
		vocalizer_sorry_chance = 80
		
		// Chance that the bot you are looking at (or the last bot who killed a special infected) will vocalize "Thanks" after your "Nice shoot"
		vocalizer_thanks_chance = 90
		
		// Comma separated vocalizer commands to speak when the bot receives an order
		vocalizer_yes = "PlayerYes,SurvivorBotYesReady"
		
		// Chance that the bot you are looking at will vocalize "You welcome" after your "Thanks"
		vocalizer_youwelcome_chance = 90
	}
	OrderPriorities = // Orders and their priorities (orders with lower priority are shifted back in the queue when orders with higher priority are added)
	{
		lead = 0
		follow = 1
		use = 2
		goto = 2
		heal = 2
		witch = 3
	}
	Events = {}
	Survivors = {}	// Used for performance reasons, instead of doing (very slow) Entities search every time
	Bots = {}		// Same as above ^
	Deads = {}		// Same ^
	Specials = {}	// Idem ^
	Tanks = {}		// ^
	Witches = {}	// Guess what? ^
	ModeStarted = false
	EscapeStarted = false
	VocalizerLeadStart = []
	VocalizerLeadStop = []
	VocalizerGotoStop = []
	VocalizerYes = []
	ItemsToAvoid = {}
	BtnStatus_Shove = {}
	GiveItemIndex1 = 0
	GiveItemIndex2 = 0
	LastGiveItemTime = 0
	LastMolotovTime = 0
	LastNadeTime = 0
	LastLeadStartVocalize = 0
	NiceShootSurv = null
	NiceShootTime = 0
}

::Left4Bots.Log <- function (level, text)
{
	if (level > Left4Bots.Settings.loglevel)
		return;
	
	if (level == LOG_LEVEL_DEBUG)
		printl("[L4B][DEBUG] " + text);
	else if (level == LOG_LEVEL_INFO)
		printl("[L4B][INFO] " + text);
	else if (level == LOG_LEVEL_WARN)
		error("[L4B][WARNING] " + text + "\n");
	else if (level == LOG_LEVEL_ERROR)
		error("[L4B][ERROR] " + text + "\n");
	else
		error("[L4B][" + level + "] " + text + "\n");
}

// Left4Bots main initialization function
::Left4Bots.Initialize <- function ()
{
	if (Left4Bots.Initialized)
	{
		// For some reason, when Initialize is called, LOG_LEVEL* consts contained in left4lib are not available yet...
		printl("[L4B][DEBUG] Already initialized");
		
		return;
	}
	
	Left4Bots.ModeName = SessionState.ModeName;
	Left4Bots.MapName = SessionState.MapName;
	Left4Bots.Difficulty = Convars.GetStr("z_difficulty").tolower();
	
	printl("[L4B][INFO] Initializing for game mode: " + Left4Bots.ModeName + " - map name: " + Left4Bots.MapName + " - difficulty: " + Left4Bots.Difficulty);
	
	// TODO: settings
	
	// TODO: convars
	Convars.SetValue("sb_debug_apoproach_wait_time", 0.5);
	//Convars.SetValue("sb_unstick", 0);
	
	// Put the vocalizer lines into arrays
	if (Left4Bots.Settings.vocalizer_lead_start != "")
		Left4Bots.VocalizerLeadStart = split(Left4Bots.Settings.vocalizer_lead_start, ",");
	if (Left4Bots.Settings.vocalizer_lead_stop != "")
		Left4Bots.VocalizerLeadStop = split(Left4Bots.Settings.vocalizer_lead_stop, ",");
	if (Left4Bots.Settings.vocalizer_goto_stop != "")
		Left4Bots.VocalizerGotoStop = split(Left4Bots.Settings.vocalizer_goto_stop, ",");
	if (Left4Bots.Settings.vocalizer_yes != "")
		Left4Bots.VocalizerYes = split(Left4Bots.Settings.vocalizer_yes, ",");
	
	Left4Bots.Initialized = true;
}

::Left4Bots.AddonStop <- function ()
{
	// Stop the button listener
	Left4Timers.RemoveThinker("L4BUTTON_LISTENER");
	
	// Stop the inventory manager
	Left4Timers.RemoveTimer("InventoryManager");
	
	// Stop the cleaner
	Left4Timers.RemoveTimer("Cleaner");
	
	// Stop receiving concepts
	::ConceptsHub.RemoveHandler("Left4Bots");
	
	// Stop receiving user commands
	::HooksHub.RemoveUserConsoleCommand("Left4Bots");
	::HooksHub.RemoveInterceptChat("Left4Bots");
	
	// Remove all the bots think functions
	Left4Bots.ClearBotThink();
	
	// Clear the lists
	Left4Bots.Survivors = {};
	Left4Bots.Bots = {};
	Left4Bots.Deads = {};
	Left4Bots.Specials = {};
	Left4Bots.Tanks = {};
	Left4Bots.Witches = {};
}

// Is player a valid survivor? (if player is a bot also checks whether it should be handled by the AI)
::Left4Bots.IsValidSurvivor <- function (player)
{
	local team = NetProps.GetPropInt(player, "m_iTeamNum");
	if (team == TEAM_SURVIVORS)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidSurvivor - " + player.GetPlayerName() + " is a valid survivor");
		return true;
	}
		
	if (team == TEAM_L4D1_SURVIVORS && Left4Bots.Settings.handle_l4d1_survivors)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidSurvivor - " + player.GetPlayerName() + " is a valid survivor (L4D1)");
		return true;
	}
	
	//Left4Bots.Log(LOG_LEVEL_DEBUG, "IsValidSurvivor - " + player.GetPlayerName() + " is not a valid survivor");
	return false;
}

// Is bot an AI handled survivor bot?
::Left4Bots.IsHandledBot <- function (bot)
{
	if (!bot || !bot.IsValid())
		return false;
	
	local userid = bot.GetPlayerUserId();
	foreach (id, b in ::Left4Bots.Bots)
	{
		if (id == userid)
			return true;
	}
	
	return false;
}

::Left4Bots.PrintSurvivorsCount <- function ()
{
	local sn = ::Left4Bots.Survivors.len();
	local bn = ::Left4Bots.Bots.len();
	local hn = sn - bn;
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[Alive survivors: " + sn + " - " + bn + " bot(s) - " + hn + " human(s)]");
}

// Returns the entity (if found) of the survivor with that actor name
::Left4Bots.GetSurvivorFromActor <- function (actor)
{
	local ret = Left4Utils.GetSurvivorFromActor(actor);
	if (ret != null)
		return ret;
	
	switch (actor)
	{
		case "TeenGirl":
		{
			ret = Left4Bots.GetSurvivorByCharacter(EXTRA_S_ZOEY);
			if (ret == null)
				ret = Left4Bots.GetSurvivorByCharacter(S_ZOEY);
			break;
		}
		case "NamVet":
		{
			ret = Left4Bots.GetSurvivorByCharacter(EXTRA_S_BILL);
			if (ret == null)
				ret = Left4Bots.GetSurvivorByCharacter(S_BILL);
			break;
		}
		case "Manager":
		{
			ret = Left4Bots.GetSurvivorByCharacter(EXTRA_S_LOUIS);
			if (ret == null)
				ret = Left4Bots.GetSurvivorByCharacter(S_LOUIS);
			break;
		}
		case "Biker":
		{
			ret = Left4Bots.GetSurvivorByCharacter(EXTRA_S_FRANCIS);
			if (ret == null)
				ret = Left4Bots.GetSurvivorByCharacter(S_FRANCIS);
			break;
		}
		case "Gambler":
		{
			ret = Left4Bots.GetSurvivorByCharacter(S_NICK);
			break;
		}
		case "Producer":
		{
			ret = Left4Bots.GetSurvivorByCharacter(S_ROCHELLE);
			break;
		}
		case "Coach":
		{
			ret = Left4Bots.GetSurvivorByCharacter(S_COACH);
			break;
		}
		case "Mechanic":
		{
			ret = Left4Bots.GetSurvivorByCharacter(S_ELLIS);
			break;
		}
	}
	
	return ret;
}

// Returns the entity (if found) of the survivor with that character id
::Left4Bots.GetSurvivorByCharacter <- function (character)
{
	foreach (id, surv in ::Left4Bots.Survivors)
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
::Left4Bots.SurvivorCantMove <- function (survivor)
{
	// IsHangingFromLedge = hanging from ledge
	// IsIncapacitated = down or hanging from ledge
	// IsDominatedBySpecialInfected = dominated by special infected
	// IsStaggering = staggering
	// IsGettingUp = ?
	// IsDying = dying
	// IsImmobilized = down, hanging from ledge, dominated by special (except jockey), dying, healing, being healed, reviving, being revived, punched by tank
	
	return (survivor.IsImmobilized() || survivor.IsDominatedBySpecialInfected() || survivor.IsStaggering());
}

// Should the bot's AI start the pause and temporarily give control to the vanilla AI?
::Left4Bots.BotShouldStartPause <- function (bot, userid, orig, isHealOrder = false, maxSeparation = 0)
{
	local aw = bot.GetActiveWeapon();
	if (maxSeparation)
		return bot.IsIT() || (!isHealOrder && aw && aw.GetClassname() == "weapon_first_aid_kit") || Left4Bots.IsFarFromOtherSurvivors(userid, orig, maxSeparation) || Left4Bots.HasTanksWithin(orig, 800) || Left4Bots.BotWillUseMeds(bot) || Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) || Left4Bots.HasWitchesWithin(orig, 300, 100) || Left4Bots.SurvivorsHeldOrIncapped() || Left4Bots.HasAngryCommonsWithin(orig, 4, 160, 100);
	else
		return bot.IsIT() || (!isHealOrder && aw && aw.GetClassname() == "weapon_first_aid_kit") || Left4Bots.HasTanksWithin(orig, 800) || Left4Bots.BotWillUseMeds(bot) || Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) || Left4Bots.HasWitchesWithin(orig, 300, 100) || Left4Bots.SurvivorsHeldOrIncapped() || Left4Bots.HasAngryCommonsWithin(orig, 4, 160, 100);
}

// Should the bot's AI stop the pause?
::Left4Bots.BotShouldStopPause <- function (bot, userid, orig, isHealOrder = false, maxSeparation = 0)
{
	local aw = bot.GetActiveWeapon();
	if (maxSeparation)
		return /*!bot.IsIT() &&*/ (isHealOrder || !aw || aw.GetClassname() != "weapon_first_aid_kit") && !bot.IsInCombat() && !Left4Bots.IsFarFromOtherSurvivors(userid, orig, maxSeparation) && !Left4Bots.HasTanksWithin(orig, 800) && !Left4Bots.BotWillUseMeds(bot) && !Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) && !Left4Bots.HasWitchesWithin(orig, 300, 100) && !Left4Bots.SurvivorsHeldOrIncapped();
	else
		return /*!bot.IsIT() &&*/ (isHealOrder || !aw || aw.GetClassname() != "weapon_first_aid_kit") && !bot.IsInCombat() && !Left4Bots.HasTanksWithin(orig, 800) && !Left4Bots.BotWillUseMeds(bot) && !Left4Bots.HasVisibleSpecialInfectedWithin(bot, orig, 400) && !Left4Bots.HasWitchesWithin(orig, 300, 100) && !Left4Bots.SurvivorsHeldOrIncapped();
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
			if (dist > d && dist >= Left4Bots.Settings.throw_nade_mindistance && Left4Utils.CanTraceTo(player, ent))
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
::Left4Bots.HasVisibleSpecialInfectedWithin <- function (player, orig, radius = 1000)
{
	foreach (ent in ::Left4Bots.Specials)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= radius && !ent.IsGhost() && Left4Utils.CanTraceTo(player, ent))
			return true;
	}
	return false;
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
::Left4Bots.HasTanksWithin <- function (orig, radius = 1000)
{
	foreach (ent in ::Left4Bots.Tanks)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= radius && !ent.IsGhost())
			return true;
	}
	return false;
}

// Is there at least one witch within 'radius' and 'maxAltDiff' from 'orig'?
::Left4Bots.HasWitchesWithin <- function (orig, radius = 1000, maxAltDiff = 1000)
{
	foreach (witch in ::Left4Bots.Witches)
	{
		if (witch.IsValid() && abs(orig.z - witch.GetOrigin().z) <= maxAltDiff && (witch.GetOrigin() - orig).Length() <= radius && NetProps.GetPropInt(witch, "m_lifeState") == 0 && !NetProps.GetPropInt(witch, "m_bIsBurning"))
			return true;
	}
	return false;
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
			if (dist >= min && dist <= max && dist < minDist && Left4Utils.CanTraceTo(player, tank))
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
			if (dist <= radius && dist < minDist && botFacing.Dot(toEnt) >= minDot && !ent.IsGhost() && Left4Utils.CanTraceTo(bot, ent))
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
			if (dist < minDist && botFacing.Dot(toEnt) >= minDot && NetProps.GetPropInt(ent, "m_lifeState") == 0 && Left4Utils.CanTraceTo(bot, ent))
			{
				ret = ent;
				minDist = dist;
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
		return (NetProps.GetPropInt(ent, "m_hOwner") <= 0);
	}
}

// Called when the bot's pick-up algorithm decides to pick the item up
// Checks if the pick-up via button press worked and the item went into the bot's inventory. if it didn't it will force it via USE input on the item
// It is meant to prevent the bot getting stuck in a loop if the button press, for some reason, didn't pick the item up
::Left4Bots.PickupFailsafe <- function (bot, item)
{
	if (!bot || !bot.IsValid() || !Left4Bots.IsValidPickup(item))
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "PickupFailsafe - " + bot.GetPlayerName() + " -> " + item.GetClassname());
	
	DoEntFire("!self", "Use", "", 0, bot, item); // <- make sure i pick this up even if the real pickup (with the button) fails or i will be stuck here forever
	//TODO Left4Bots.OnPlayerUse(bot, item, 1); // ^this doesn't trigger the event so i do it myself
}

// Called when the bot opens/closes a door door
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
		Left4Bots.Log(LOG_LEVEL_DEBUG, "DoorFailsafe - " + bot.GetPlayerName() + " -> " + door.GetClassname() + " (Close)");
		DoEntFire("!self", "Close", "", 0, bot, door);
	}
	else
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "DoorFailsafe - " + bot.GetPlayerName() + " -> " + door.GetClassname() + " (Open)");
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
		return false; // Don't give items that are being held by the bot to avoid giving away a mekit while the bot is trying to heal etc.
	
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
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.GiveInventoryItem - " + bot.GetPlayerName() + " -> " + item.GetClassname() + " -> " + survDest.GetPlayerName());
	
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
				EmitSoundOnClient(Left4Bots.Settings.sound_give_giver, player1);
			
			foreach (id, surv in ::Left4Bots.Survivors)
			{
				if (surv.IsValid() && !IsPlayerABot(surv) && id != player1.GetPlayerUserId())
					EmitSoundOnClient(Left4Bots.Settings.sound_give_others, surv);
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
				EmitSoundOnClient(Left4Bots.Settings.sound_give_giver, player1);
			if (!IsPlayerABot(player2))
				EmitSoundOnClient(Left4Bots.Settings.sound_give_giver, player2);
			
			foreach (id, surv in ::Left4Bots.Survivors)
			{
				if (surv.IsValid() && !IsPlayerABot(surv) && id != player1.GetPlayerUserId() && id != player2.GetPlayerUserId())
					EmitSoundOnClient(Left4Bots.Settings.sound_give_others, surv);
			}
		}
	}
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
	
	// Is someone else already going to throw this?
	if (Left4Bots.IsSomeoneElseHolding(userid, throwClass))
		return false;

	// No, go on...
	if (throwType == AI_THROW_TYPE.Tank)
	{
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
::Left4Bots.TryDodgeSpit <- function (bot, spit = null)
{
	local p2 = bot.GetOrigin();
	local p1 = p2;
	if (spit)
		p1 = spit.GetOrigin();

	local i = 0;
	while (i < 6 && (p1 - p2).Length() <= Left4Bots.Settings.dodge_spit_radius)
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, bot.GetPlayerName() + ".TryGetPathableLocationWithin - i = " + i);
		p2 = bot.TryGetPathableLocationWithin(Left4Bots.Settings.dodge_spit_radius + 150);
		i++;
	}
	
	if (i == 0)
		return; // No need to move
	
	/* TODO?
	if (Convars.GetFloat("sb_hold_position") != 0 && !Left4Bots.Settings.keep_holding_position)
	{
		// Stop holding position if one or more bots are going to be hit by the spitter's spit
		Convars.SetValue("sb_hold_position", 0);
		Convars.SetValue("sb_enforce_proximity_range", Left4Bots.Old_sb_enforce_proximity_range);
		if (Left4Bots.Settings.wait_crouch)
			Convars.SetValue("sb_crouch", 0);
	}
	*/
	
	Left4Bots.BotHighPriorityMove(bot, p2);
}

// 'bot' will try to dodge the 'charger'
// 'leftVector' is a vector facing the current carger's left
// 'goLeft' tells whether the bot should run left (true) or right (false)
::Left4Bots.TryDodgeCharger <- function (bot, charger, leftVector, goLeft) // TODO: delay based on distance
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodgeCharger - bot: " + bot.GetPlayerName() + " - goLeft: " + goLeft);
	
	local startArea = NavMesh.GetNavArea(bot.GetCenter(), 300);
	
	local dest;
	if (goLeft)
		dest = bot.GetCenter() - (leftVector * Left4Bots.Settings.dodge_charger_mindistance);
	else
		dest = bot.GetCenter() + (leftVector * Left4Bots.Settings.dodge_charger_mindistance);
	
	local destArea =  NavMesh.GetNavArea(dest, 300);
	if (destArea && destArea.IsValid())
	{
		local d = NavMesh.NavAreaTravelDistance(startArea, destArea, Left4Bots.Settings.dodge_charger_maxdistance);
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodgeCharger - bot: " + bot.GetPlayerName() + " - d: " + d);
		
		if (d >= 0)
		{
			Left4Bots.Log(LOG_LEVEL_INFO, bot.GetPlayerName() + " trying to dodge charger");
			
			Left4Bots.BotHighPriorityMove(bot, Vector(dest.x, dest.y, destArea.GetZ(dest))); // Set the Z axis to ground level
			return;
		}
	}
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodgeCharger - bot: " + bot.GetPlayerName() + " - nav area not found");
	
	// Preferred direction failed, let's try the other one (add some distance because we probably need to traver farther in this direction)
	if (goLeft)
		dest = bot.GetCenter() + (leftVector * (Left4Bots.Settings.dodge_charger_mindistance + 40)); // TODO: better calc that +40
	else
		dest = bot.GetCenter() - (leftVector * (Left4Bots.Settings.dodge_charger_mindistance + 40));
	
	local destArea =  NavMesh.GetNavArea(dest, 300);
	if (destArea && destArea.IsValid())
	{
		local d = NavMesh.NavAreaTravelDistance(startArea, destArea, Left4Bots.Settings.dodge_charger_maxdistance);
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodgeCharger - bot: " + bot.GetPlayerName() + " - d: " + d);
		
		if (d >= 0)
		{
			Left4Bots.Log(LOG_LEVEL_INFO, bot.GetPlayerName() + " trying to dodge charger");
			
			Left4Bots.BotHighPriorityMove(bot, Vector(dest.x, dest.y, destArea.GetZ(dest))); // Set the Z axis to ground level
			return;
		}
	}
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodgeCharger - bot: " + bot.GetPlayerName() + " - nav area not found");
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodgeCharger - failed!");
}

// Returns the survivor aimed by 'player' within 'radius' and with at least 'threshold' accuracy. visibleOnly = true if the aimed survivor must be visible to 'player'
::Left4Bots.GetPickerSurvivor <- function (player, radius = 999999, threshold = 0.95, visibleOnly = false)
{
	if (!player || !player.IsValid())
		return null;
	
	/*
	local start = player.EyePosition();
	local end = start + player.EyeAngles().Forward().Scale(radius);
		
	local m_trace = { start = start, end = end, ignore = player, mask = TRACE_MASK_SOLID };
	TraceLine(m_trace);
		
	if (m_trace.hit && m_trace.enthit && m_trace.enthit.IsValid() && m_trace.enthit != player && m_trace.enthit.GetClassname() == "player" && )
		return m_trace.enthit;
	*/

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
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, surv)))
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
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, witch)))
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
		if (surv.IsValid() && id != userid)
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

// Are there enough spare medkits around for the teammates who need them and 'me'?
::Left4Bots.HasSpareMedkitsAround <- function (me)
{
	local numMedkits = Left4Utils.GetMedkitsWithin(me, 500).len();
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.CountSpareMedkitsAround - me: " + me.GetPlayerName() + " - numMedkits: " + numMedkits);
	
	local requiredMedkits = 1;
	foreach (surv in Left4Bots.GetOtherAliveSurvivors(me.GetPlayerUserId()))
	{
		if (surv.GetHealth() < 75 || !Left4Utils.HasMedkit(surv))
			requiredMedkits++;
	}
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "HasSpareMedkitsAround - me: " + me.GetPlayerName() + " - requiredMedkits: " + requiredMedkits);
	
	local count = 0;
	local ent = null;
	while (ent = Entities.FindInSphere(ent, me.GetOrigin(), Left4Bots.Settings.heal_spare_medkits_radius))
	{
		// Note: we are counting both weapon_first_aid_kit and weapon_first_aid_kit_spawn
		if (ent.IsValid() && ent.GetClassname().find("weapon_first_aid_kit") != null && NetProps.GetPropEntity(ent, "m_hOwner") == null)
		{
			if (++count >= requiredMedkits)
				return true;
		}
	}
	return false;
}

// Makes the given bot say the given line in chat
::Left4Bots.SayGG <- function (bot, line)
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

//

IncludeScript("left4bots_ai");
IncludeScript("left4bots_events");

Left4Bots.Initialize();
