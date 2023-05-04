/* TODO:

- Force ammo replenish while in saferoom
- Invece di GetScriptScope... DoEntFire("!self", "RunScriptCode", "AutomaticShot()", 0.01, null, bot);  oppure  DoEntFire("!self", "CallScriptFunction", "AutomaticShot", 0.01, null, bot);
- Weapon/Item spotted -> check dist/... and add as pickup
- Remove cmdattack su special (bugga i bot)
- Heal da solo e rescue pure
- sb_unstick 0 e gestire l'unstick (magari teleportarlo dietro, davanti solo se sta da solo o è indietro?)
- auto crown witch
- manual attack headshot
- Reset should reset pause?
- Cancel heal near saferoom

----- IMPROV:

- All close saferoom door
- Weapon preferences
- Lead detour
- l4u
- close saferoom door
- 'wait'
- Spit/Flames not stuck
- 'follow' (new)
- dodge rock

*/

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
		
		// How long do the bots hold down a button to do single tap button press (it needs to last at least 2 ticks, so it must be greater than 0.033333 or the weapons firing can fail)
		button_holdtime_tap = 0.04
		
		// Chance that the bot will chat one of the BG lines at the end of the campaign (if dead or incapped)
		chat_bg_chance = 50
		
		// Chance that the bot will chat one of the GG lines at the end of the campaign (if alive)
		chat_gg_chance = 70
		
		// [1/0] Should the last bot entering the saferoom close the door immediately?
		close_saferoom_door = 1
		
		// Chance that all the survivor bots will quickly go close the saferoom door once the last survivor (including humans) entered the saferoom
		// NOTE: This will likely make the bots lock the last surivor out in maps with very bad CHECKPOINT nav areas
		close_saferoom_door_all_chance = 50
		
		// When the last bot steps into the saferoom he will start the close door procedure when his distance from the door is > than this
		// This is meant to make sure that the bot is actually inside and will not lock himself out
		// NOTE: Maps with bad navmesh (CHECKPOINT nav areas outside of the actual saferoom) might still make the bots lock themselves out. You can try increasing this in such cases
		close_saferoom_door_distance = 70
		
		// [1/0] 1 = The close door AI code runs every think tick (15 times per second with default interval). 0 = Run rate is 1/5 (3 times per second)
		// Basically with 1 the bots will quickly close the door as soon as they are inside. 0 adds more variation with some chance that the bot will step inside further and then go back to the door after a moment
		close_saferoom_door_highres = 0
		
		// Dead survivors to defib must be within this radius
		deads_scan_radius = 1200
		
		// Max altitude difference between the bot and the dead survivor when scanning for dead survivors to defib
		deads_scan_maxaltdiff = 320
		
		// When survivor bots find a dead survivor to defib but they don't have a defib, they will consider picking up and use defibs within this radius from the dead survivor
		deads_scan_defibradius = 250
		
		// [1/0] 1 = Bots will automatically deploy upgrade packs when near other teammates
		deploy_upgrades = 1
		
		// [1/0] Enable/Disable charger dodging
		dodge_charger = 1
		
		// Max angle difference between the charger's current facing direction and the direction to the bot when deciding whether the bot should dodge the charge or not
		dodge_charger_diffangle = 10
		
		// Delay of the dodge is the result of the distance between the charger and the bot multiplied by this
		dodge_charger_distdelay_factor = 0.0006
		
		// Maximum distance to travel when dodging chargers
		dodge_charger_maxdistance = 600
		
		// Minimum distance to travel when dodging chargers
		dodge_charger_mindistance = 80
		
		// [1/0] Enable/Disable tank rocks dodging
		dodge_rock = 1
		
		// Max angle difference between the tank's rock current direction and the direction to the bot when deciding whether the bot should dodge the rock or not
		dodge_rock_diffangle = 8
		
		// Maximum distance to travel when dodging tank rocks
		dodge_rock_maxdistance = 600
		
		// Minimum distance to travel when dodging tank rocks
		dodge_rock_mindistance = 140
		
		// [1/0] Enable/Disable spit dodging
		dodge_spit = 1
		
		// Approximate radius of the spitter's spit on the ground
		dodge_spit_radius = 150
		
		// When the addon tells a bot to open/close a door, the bot does it via USE button (in order to do the hand animation)
		// But if, for some reason, the open/close door fails (too far or something) the door will be forced to open/close by the addon after this delay
		door_failsafe_delay = 0.15
		
		// If the bot's falling (vertical) velocity is > than this, he will be safely teleported to a random teammate. 0 = disabled
		// Can be set to the value of one of the game's cvars "fall_speed_fatal" (default val. 720), "fall_speed_safe" (560) to avoid insta-death or any damage at all respectively
		fall_velocity_warp = 0
		
		// Name of the file containing the BG chat lines
		file_bg = "left4bots2/cfg/bg.txt"
		
		// Name of the file with the convar changes to load
		file_convars = "left4bots2/cfg/convars.txt"
		
		// Name of the file containing the GG chat lines
		file_gg = "left4bots2/cfg/gg.txt"
		
		// Name of the file containing the items that the vanilla AI should not pickup
		file_itemstoavoid = "left4bots2/cfg/itemstoavoid.txt"
		
		// Name of the file with the vocalizer/command mapping
		file_vocalizer = "left4bots2/cfg/vocalizer.txt"
		
		// Prefix of the name of the files with the weapon preferences (file name will be "file_weapons_prefix" + "bot name lowercase" + ".txt")
		file_weapons_prefix = "left4bots2/cfg/weapons/"
		
		// When executing a 'follow' order, the bot will start pause when within move_end_radius_follow from the followed entity,
		// but will only resume when farther than follow_pause_radius, so this has to be > than move_end_radius_follow
		follow_pause_radius = 220
		
		// [1/0] Should the bots give their medkits/defibrillators to human players?
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
		// This does only apply when the main team is the L4D2 one, it has no effect when the L4D1 survivors are spawned as the main team
		handle_l4d1_survivors = 0
		
		// When the bot tries to heal with health >= this (usually they do it in the start saferoom) the addon will interrupt it, unless there is no human in the team
		// or there are enough spare medkits around for the bot and the teammates who also need it
		heal_interrupt_minhealth = 50
		
		// [1/0] 1 = The bot will be forced to heal without interrupting when healing himself (unless there are enough infected nearby). 0 = The bot can interrupt healing if not feeling safe enough (vanilla behavior)
		heal_force = 1
		
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
		
		// [1/0] 1 = Reverse itemstoavoid logics (tells the vanilla AI to avoid all the items except the ones in the itemstoavoid.txt file). 0 = Normal logics (vanilla AI should avoid only the items in the file)
		items_not_to_avoid = 1
		
		// (1/0) Enable/Disable the additional trace check on the ground when calculating the 'lead' path
		lead_check_ground = 0
		
		// >0 = each segment calculation of the 'lead' order is drawn on screen for this amount of time (only the host can see it). 0 = Disable
		lead_debug_duration = 0
		
		// If during the 'lead' order, a blocked nav area is found, the algorithm will try to find an alternate route to get past the blocked area. This is the max distance of the alternate route
		// Set 0 to disable the alternate route calculation and just stop at the blocked area
		lead_detour_maxdist = 5000
		
		// [1/0] If 1, lead segments will avoid to end on nav areas with DAMAGING attribute (such as areas with fire and spitter's spit),
		// so the vanilla nav system of the bot can try to avoid such areas and take an alternate route (if possible)
		lead_dontstop_ondamaging = 1
		
		// Max(ish) distance of a single MOVE segment when executing the 'lead' order
		lead_max_segment = 800
		
		// Max distance from human survivors when executing the 'lead' order. Bot will pause the leading when too far (0 = no limit)
		lead_max_separation = 1200
		
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
		
		// Maximum distance from a generic destination position for setting the travel done
		move_end_radius = 30
		
		// Maximum distance from the destination dead teammate before starting to defib
		move_end_radius_defib = 80
		
		// Maximum distance from the destination door before open/close it
		move_end_radius_door = 100
		
		// Maximum distance from the destination teammate before starting to heal him
		move_end_radius_heal = 80
		
		// Maximum distance from the destination position for setting the 'lead' travel done
		move_end_radius_lead = 110
		
		// Maximum distance from the followed entity for setting the 'follow' travel done
		move_end_radius_follow = 100
		
		// Maximum distance from the 'wait' position before stopping
		move_end_radius_wait = 150
		
		// Maximum distance from the destination witch before starting to shoot her
		move_end_radius_witch = 55
		
		// High priority MOVEs will be automatically terminated after this time, regardless the destination position was reached or not (likely unreachable position)
		move_hipri_timeout = 5.0
		
		// [1/0] Enable/Disable debug chat messages when the bot starts/stops the pause
		pause_debug = 0
		
		// Minimum duration of the pause. When a bot starts a pause (due to infected nearby, teammates need help etc.), the pause cannot end earlier than this, even if the conditions to stop the pause are met
		pause_min_time = 3.0 // TODO: 4?
		
		// When the addon tells a bot to pickup an item, the bot does it via USE button (in order to do the hand animation)
		// But if, for some reason, the pickup fails (too far or something) the item is forced into the bot's inventory after this delay (to prevent stuck situations)
		pickups_failsafe_delay = 0.15
		
		// Only move for a pick-up if there is at least one human survivor within this range (0 = no limit)
		pickups_max_separation = 600
		
		// Pick up the item we are looking for when within this range
		pickups_pick_range = 99
		
		// Items to pick up must be within this radius (and be visible to the bot)
		pickups_scan_radius = 400
		
		// [1/0] 1 = L4B AI will always handle the pickup logics for every item (including weapons) in the preference files
		//       0 = L4B AI will handle pri/sec weapons in preference files only while executing orders but will ignore them while at rest (order paused or no order). Will still handle the other items, though
		pickups_wep_always = 1
		
		// The bot will look for ammo stacks when the percent of ammo in his primary weapon drops below this
		pickups_wep_ammo_replenish = 80.0
		
		// Minimum percent of ammo in a weapon on the ground in order for the bot to consider picking it up
		pickups_wep_min_ammo = 10.0
		
		// If the ammo percent of the bot's current primary weapon drops below this value, the bot will consider replacing the weapon with any other weapon
		pickups_wep_replace_ammo = 1.0
		
		// Minumum number of upgraded (incendiary/explosive) ammo loaded for ignoring deployed upgrades
		// Basically the bot will consider using another deployed ammo upgrade pack only when the number of upgraded ammo in his weapon is below this number
		pickups_wep_upgraded_ammo = 1
		
		// [1/0] Should the sounds be played on give/swap items?
		play_sounds = 1
		
		// Value for the cm_ShouldHurry director option. Not sure what it does exactly
		should_hurry = 0 // TODO: 1
		
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
		
		// Delta pitch (from his feet) for aiming when shoving tongue victim teammates within shove_specials_radius
		shove_tonguevictim_deltapitch = -6.0
		
		// Bots will shove tongue victim teammates within this radius (set 0 to disable)
		shove_tonguevictim_radius = 90
		
		// Sound scripts to play when a survivor gives an item to another survivor
		// UI/BigReward.wav	(played on the giver)
		sound_give_giver = "Hint.BigReward"
		// UI/LittleReward.wav (Played on all the players except the giver)
		sound_give_others = "Hint.LittleReward"
		
		// [1/0] Enable/Disable debug chat messages of the stuck detection algorithm
		stuck_debug = 0
		
		// [1/0] Enable/Disable the stuck detection algorithm
		stuck_detection = 1
		
		// [1/0] 1 = Unstuck is also triggered as soon the bot stops moving. 0 = Only when his movement is > stuck_range
		stuck_nomove_unstuck = 1
		
		// Range used by the stuck detection algorithm
		stuck_range = 100.0
		
		// Min time to be considered stuck
		stuck_time = 2.9
		
		// [1/0] Enable/Disable replenish ammo for T3 weapon by bots
		t3_ammo_bots = 1
		
		// [1/0] Enable/Disable replenish ammo for T3 weapon by humans
		t3_ammo_human = 1 // TODO: 0
		
		// Chance that the bot will throw the molotov at the tank (this check runs multiple times in a second while the tank is in range, so this chance must be pretty low to have an actual chance of no throw)
		tank_molotov_chance = 25
		
		// Chance that the bot will throw the bile jar at the tank (this check runs multiple times in a second while the tank is in range, so this chance must be pretty low to have an actual chance of no throw)
		tank_vomitjar_chance = 1
		
		// Tanks with health lower than this will not become molotov/bile jar targets
		tank_throw_min_health = 1500
		
		// Minimum bot's distance to a tank for throwing molotovs/bile jars at the tank
		tank_throw_range_min = 200
		
		// Maximum bot's distance to a tank for throwing molotovs/bile jars at the tank
		tank_throw_range_max = 1300

		// Minimum distance between the tank and the other survivors for throwing molotovs at the tank
		tank_throw_survivors_mindistance = 240

		// Delta pitch (from his feet) for aiming when throwing molotovs/bile jars at the tank ( <0: higher, >0: lower )
		tank_throw_deltapitch = 3
		
		// Max chainsaws in the team
		team_max_chainsaws = 1 // TODO: 0
		
		// Max melee weapons in the team
		team_max_melee = 2

		// Minimum defibrillators in the team
		team_min_defibs = 0
		
		// Minimum medkits in the team
		team_min_medkits = 2
		
		// Minimum molotovs in the team
		team_min_molotovs = 1
		
		// Minimum pipe bombs in the team
		team_min_pipebombs = 1
		
		// Minimum vomit jars in the team
		team_min_vomitjars = 1
		
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
		
		// Bot selected with 'Look' will stay selected for this amount of time. The selection will be reset after this time
		vocalize_botselect_timeout = 4.0
		
		// [1/0] Enable/Disable orders via vocalizer (does not affect orders via chat/console)
		vocalizer_commands = 1
		
		// Comma separated vocalizer commands to speak when the bot ends the 'goto' order (command to speak will be a random one from this list)
		vocalizer_goto_stop = "PlayerAnswerLostCall,PlayerLostCall"
		
		// Chance that the bots will laugh when you laugh
		vocalizer_laugh_chance = 30
		
		// Comma separated vocalizer commands to speak when the bot starts the 'lead' order (command to speak will be a random one from this list)
		vocalizer_lead_start = "PlayerFollowMe,PlayerMoveOn,PlayerEmphaticGo"
		
		// Comma separated vocalizer commands to speak when the bot ends the 'lead' order (command to speak will be a random one from this list)
		vocalizer_lead_stop = "PlayerAnswerLostCall,PlayerLostCall,PlayerStayTogether,PlayerLeadOn"
		
		// Chance that the bot will vocalize the horde incoming warning when starting the pause for that reason
		vocalizer_onpause_horde_chance = 30
		
		// Chance that the bot will vocalize the special infected warning when starting the pause for that reason
		vocalizer_onpause_special_chance = 80
		
		// Chance that the bot will vocalize the tank warning when starting the pause for that reason
		vocalizer_onpause_tank_chance = 100
		
		// Chance that the bot will vocalize the witch warning when starting the pause for that reason
		vocalizer_onpause_witch_chance = 90
		
		// Chance that the bot will vocalize "Sorry" after doing friendly fire
		vocalizer_sorry_chance = 80
		
		// Chance that the bot you are looking at (or the last bot who killed a special infected) will vocalize "Thanks" after your "Nice shoot"
		vocalizer_thanks_chance = 90
		
		// Comma separated vocalizer commands to speak when the bot receives an order
		vocalizer_yes = "PlayerYes,SurvivorBotYesReady"
		
		// Chance that the bot you are looking at will vocalize "You welcome" after your "Thanks"
		vocalizer_youwelcome_chance = 90
		
		// [1/0] While executing the 'wait' order the bot will wait crouch (1) or standing (0)
		wait_crouch = 0
		
		// [1/0] If 1, the bots will not pause the 'wait' order
		// This means that they will keep holding their positions even if there are special infected around, teammates who need help etc. But they will still move to do higher priority tasks (like charger/spit dodging, defib, etc.)
		wait_nopause = 0
	}
	OrderPriorities = // Orders and their priorities (orders with lower priority are shifted back in the queue when orders with higher priority are added)
	{
		lead = 0
		follow = 0
		goto = 1
		wait = 1
		use = 2
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
	TeamMolotovs = 0
	TeamPipeBombs = 0
	TeamVomitJars = 0
	TeamMedkits = 0
	TeamDefibs = 0
	TeamChainsaws = 0
	TeamMelee = 0
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
		// LOG_LEVEL* consts contained in left4lib are not available yet...
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
	Convars.SetValue("sb_enforce_proximity_range", 20000);
	// Convars.SetValue("sb_unstick", 0);  // TODO: Posso farlo unstickare io
	
	// Put the vocalizer lines into arrays
	if (Left4Bots.Settings.vocalizer_lead_start != "")
		Left4Bots.VocalizerLeadStart = split(Left4Bots.Settings.vocalizer_lead_start, ",");
	if (Left4Bots.Settings.vocalizer_lead_stop != "")
		Left4Bots.VocalizerLeadStop = split(Left4Bots.Settings.vocalizer_lead_stop, ",");
	if (Left4Bots.Settings.vocalizer_goto_stop != "")
		Left4Bots.VocalizerGotoStop = split(Left4Bots.Settings.vocalizer_goto_stop, ",");
	if (Left4Bots.Settings.vocalizer_yes != "")
		Left4Bots.VocalizerYes = split(Left4Bots.Settings.vocalizer_yes, ",");
	
	printl("[L4B][INFO] Loading items to avoid from file: " + Left4Bots.Settings.file_itemstoavoid);
	Left4Bots.ItemsToAvoid = Left4Bots.LoadItemsToAvoidFromFile(Left4Bots.Settings.file_itemstoavoid);
	printl("[L4B][INFO] Loaded " + Left4Bots.ItemsToAvoid.len() + " items");
	
	// Default vocalizer.txt file
	if (!Left4Utils.FileExists("left4bots2/cfg/vocalizer.txt"))
	{
		// using array instead of table to maintain the order
		local defaultMappingValues =
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
			"PlayerEmphaticGo = bots goto",
			//"PlayerHurryUp = canceldefib",
			"AskForHealth2 = bot heal me"
			//"PlayerAnswerLostCall = give",
			//"PlayerYellRun = goto",
			//"PlayerImWithYou = next thing to do" // TODO:
		];

		Left4Utils.StringListToFile("left4bots2/cfg/vocalizer.txt", defaultMappingValues, false);
				
		printl("[L4B][INFO] Vocalizer orders mapping file was not found and has been recreated");
	}
		
	printl("[L4B][INFO] Loading vocalizer command mapping from file: " + Left4Bots.Settings.file_vocalizer);
	::Left4Bots.VocalizerCommands = Left4Bots.LoadVocalizerCommandsFromFile(Left4Bots.Settings.file_vocalizer);
	printl("[L4B][INFO] Loaded " + Left4Bots.VocalizerCommands.len() + " orders");
	
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

::Left4Bots.AddonStop <- function ()
{
	// Stop the thinker
	Left4Timers.RemoveThinker("L4BThinker");
	
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
// Returns the ent of the first special infected found or null if none
::Left4Bots.HasVisibleSpecialInfectedWithin <- function (player, orig, radius = 1000)
{
	foreach (ent in ::Left4Bots.Specials)
	{
		if (ent.IsValid() && (ent.GetOrigin() - orig).Length() <= radius && !ent.IsGhost() && Left4Utils.CanTraceTo(player, ent))
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
	
	local weaponid = Left4Utils.GetWeaponId(item);
	if (Left4Utils.HasWeaponId(bot, weaponid))
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "PickupFailsafe - " + bot.GetPlayerName() + " -> " + item.GetClassname() + " (" + weaponid + ")");
	
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
			return;
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
			return;
		}
	}
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - bot: " + bot.GetPlayerName() + " - nav area not found");
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.TryDodge - failed!");
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
			if (dot > bestDot && (!visibleOnly || Left4Utils.CanTraceTo(player, surv)))
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
		if (ent.IsValid() && NetProps.GetPropEntity(ent, "m_hOwner") == null)
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
// It triggers the dodging for the bots who are in it's trajectory
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
	local fwdY = self.GetAngles().Forward();
	fwdY.Norm();
	fwdY = Left4Utils.VectorAngles(fwdY).y;
	local lft = self.GetAngles().Left();
	
	//fwd = Vector(fwd.x, fwd.y, 0);
	
	//DebugDrawLine_vCol(MyPos, MyPos + (fwd * 30), Vector(0, 255, 0), true, 5.0);
	
	foreach (id, bot in ::Left4Bots.Bots)
	{
		/*
		//if (bot.IsValid() && Left4Utils.CanTraceTo(bot, rock, TRACE_MASK_ALL))
		//if (bot.IsValid() && (self.GetCenter() - bot.EyePosition()).Length() <= Left4Bots.Settings.rock_shoot_range)
		if (bot.IsValid() && (self.GetCenter() - bot.EyePosition()).Length() <= Left4Bots.Settings.rock_shoot_range && NetProps.GetPropInt(bot, "m_reviveTarget") <= 0 && NetProps.GetPropInt(bot, "m_iCurrentUseAction") <= 0)
		{
			Left4Bots.BotPressButton(bot, BUTTON_ATTACK, BUTTON_HOLDTIME_TAP, self.GetCenter(), 0, 0, true);
		
			Left4Bots.Log(LOG_LEVEL_DEBUG, bot.GetPlayerName() + " shooting at rock " + self.GetEntityIndex());
			
			//Delay = 0.4;
		}
		*/
		
		if (bot.IsValid() && !(id in WarnedBots) && !Left4Bots.SurvivorCantMove(bot) && (bot.GetCenter() - MyPos).Length() <= 1500 && Left4Utils.CanTraceTo(bot, self))
		{
			local toBot = bot.GetCenter() - MyPos;
			toBot.Norm();
			
			local a = Left4Utils.GetDiffAngle(Left4Utils.VectorAngles(toBot).y, fwdY);
			
			// a must be between -dodge_rock_diffangle and dodge_rock_diffangle. a > 0 -> the bot should run to the rock's left. a < 0 -> the bot should run to the rock's right
			if (a >= -Left4Bots.Settings.dodge_rock_diffangle && a <= Left4Bots.Settings.dodge_rock_diffangle)
			{
				Left4Bots.TryDodge(bot, lft, a > 0, Left4Bots.Settings.dodge_rock_mindistance, Left4Bots.Settings.dodge_rock_maxdistance);
				WarnedBots[id] <- 1;
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
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "LoadWeaponPreferences - survivor: " + survivor.GetPlayerName());
	
	local lines = Left4Utils.FileToStringList(Left4Bots.Settings.file_weapons_prefix + survivor.GetPlayerName().tolower() + ".txt");
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
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "LoadWeaponPreferences - i: " + i + " - w: " + weaps[x] + " - id: " + id);
				
				if (id > Left4Utils.WeaponId.none && id != Left4Utils.MeleeWeaponId.none && id != Left4Utils.UpgradeWeaponId.none)
					ret[i].append(id); // valid weapon
			}
		}
	}
	
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

// Returns the nearest usable entity within the given radius from origin
::Left4Bots.FindNearestUsable <- function (orig, radius)
{
	local ret = null;
	local minDist = 1000000;		
	local ent = null;
	while (ent = Entities.FindInSphere(ent, orig, radius))
	{
		if (NetProps.GetPropInt(ent, "m_hOwner") <= 0)
		{
			local dist = (ent.GetCenter() - orig).Length();
			local entClass = ent.GetClassname();
			if (dist < minDist && (entClass.find("weapon_") != null || entClass.find("prop_physics") != null || entClass.find("prop_minigun") != null || entClass.find("func_button") != null || (entClass.find("trigger_finale") != null && NetProps.GetPropInt(ent, "m_bDisabled") == 0) || entClass.find("prop_door_rotating") != null))
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
