::Left4Bots.Settings <-
{
	// [1/0] 1 = Prevents (at least will try) the infamous bug of the pipe bomb thrown right before transitioning to the next chapter, the bots will bug out and do nothing for the entire next chapter
	anti_pipebomb_bug = 1

	// Interval of the main bot Think function (default is 0.1 which means 10 ticks per second)
	// Set the max i can get even though the think functions can go up to 30 ticks per second (interval 0.0333) and the CTerrorPlayer entities limit their think functions to max 15 ticks per second (0.06666)
	bot_think_interval = 0.01

	// How long do the bots hold down the button to defib a dead survivor
	button_holdtime_defib = 3.2

	// How long do the bots hold down the button to heal
	button_holdtime_heal = 5.3

	// How long do the bots hold down the button to pour gascans/cola
	button_holdtime_pour = 2.2

	// How long do the bots hold down a button to do single tap button press (it needs to last at least 2 ticks, so it must be greater than 0.033333 or the weapons firing can fail)
	button_holdtime_tap = 0.04

	// [1/0] Enable/Disable debug chat messages when the bot picks-up/drops the assigned carry item
	carry_debug = 0

	// Chance that the bot will chat one of the BG lines at the end of the campaign (if dead or incapped)
	chat_bg_chance = 50

	// Bot will chat one of these BG lines at the end of the campaign (if dead or incapped)
	chat_bg_lines = "bg,:(,:'("

	// Chance that the bot will chat one of the GG lines at the end of the campaign (if alive)
	chat_gg_chance = 70

	// Bot will chat one of these GG lines at the end of the campaign (if alive)
	chat_gg_lines = "gg,GG,gg,GGG,gg,ggs,gg,GG,gg"

	// Chance that the bot will reply to a 'hello' trigger from a player who just joined
	chat_hello_chance = 85

	// The bot will reply to the 'hello' triggers with one of these
	chat_hello_replies = "hi,hello,hey,hi dude,wassup,hi,hello,hi,ciao"

	// List of 'hello' lines that can trigger the reply
	chat_hello_triggers = "hi,hello,hey,hi guys,hi all,hey guys,yo,ciao"

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

	// [1/0] 1 = Admins can make the bots die with the "die" command at any time. 0 = Only if there are no human survivors alive
	die_humans_alive = 1

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

	// [1/0] Enable/Disable tank rocks dodging. If shoot_rock is also 1, the bot might do both but will prioritize the dodge
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
	//		file_bg = "left4bots2/cfg/bg.txt" // TODO: remove

	// Name of the file with the convar changes to load (empty = don't load the convar changes)
	file_convars = "left4bots2/cfg/convars.txt"

	// Name of the file containing the GG chat lines
	//		file_gg = "left4bots2/cfg/gg.txt" // TODO: remove

	// Name of the file containing the items that the vanilla AI should/should not pickup (empty = don't load the items)
	file_itemstoavoid = "left4bots2/cfg/itemstoavoid.txt"

	// Name of the file with the vocalizer/command mapping (empty = don't load the mapping)
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

	// [0/1/2] Should the L4B AI handle the extra L4D1 survivors (spawned in some maps like "The Passing" or manually by some admin addon)?
	// 0 = No
	// 1 = Yes but for the items pickup/throw only (can be useful considering that the itemstoavoid logics also affect the L4D1 bots and will likely make them not pickup any weapon with vanilla AI)
	// 2 = Yes (full AI like the main bots)
	// NOTE: This does only apply when the main team is the L4D2 one, it has no effect when the L4D1 survivors are spawned as the main team
	handle_l4d1_survivors = 1

	// When the bot tries to heal with health >= this (usually they do it in the start saferoom) the addon will interrupt it, unless there is no human in the team
	// or there are enough spare medkits around for the bot and the teammates who also need it
	heal_interrupt_minhealth = 50

	// [1/0] 1 = The bot will be forced to heal without interrupting when healing himself (unless there are enough infected nearby). 0 = The bot can interrupt healing if not feeling safe enough (vanilla behavior)
	heal_force = 0

	// Radius for searching the spare medkits around
	heal_spare_medkits_radius = 500

	// Chance that the bot will throw the pipe bomb/bile jar at the horde (this check runs multiple times in a second, so this chance must be pretty low to have an actual chance of no throw)
	horde_nades_chance = 30

	// When scanning for an actual horde, this is the maximum altitude difference between the bot and the common infected being counted
	horde_nades_maxaltdiff = 120

	// When scanning for an actual horde, this is the maximum distance between the bot and the common infected being counted
	horde_nades_radius = 450

	// When scanning for an actual horde, this is the minimum number of common infected to count
	horde_nades_size = 10

	// When you use the "hurry" command, the bot(s) improved AI will be disabled (they will not pick-up items/execute orders/defib teammates/throw items/scavenge) for this amount of seconds
	hurry_time = 15

	// [1/0] 1 = Reverse itemstoavoid logics (tells the vanilla AI to avoid all the items except the ones in the itemstoavoid.txt file). 0 = Normal logics (vanilla AI should avoid only the items in the file)
	items_not_to_avoid = 1

	// If >0, when a survivor bot shoots a teammate who is being ridden by a jockey, the damage to the teammate is removed and the jockey receives this amount of damage instead. 0 = disabled
	jockey_redirect_damage = 40

	// [1/0] Enable/Disable the additional trace check on the ground when calculating the 'lead' path
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
	lead_vocalize_interval = 40

	// [1/0] Enable/Disable loading the configured 'convars.txt' file
	load_convars = 1

	// Minimum log level for the addon's log lines into the console
	// 0 = No log
	// 1 = Only [ERROR] messages are logged
	// 2 = [ERROR] and [WARNING]
	// 3 = [ERROR], [WARNING] and [INFO]
	// 4 = [ERROR], [WARNING], [INFO] and [DEBUG]
	loglevel = 3

	// [0.0 - 1.0] While executing MOVE commands, this is how straight the bot should be looking at the enemy in order to shoot it
	// 0.0 = Even the enemies behind will be shoot (CSGO spinbot style). 1.0 = The bot will probably never shoot
	manual_attack_mindot = 0.94

	// While executing MOVE commands, this is the max distance of the enemies that the bot will shoot
	manual_attack_radius = 950

	// Maximum distance from a generic destination position for setting the travel done
	move_end_radius = 30

	// Maximum distance from the destination dead teammate before starting to defib
	move_end_radius_defib = 80

	// Maximum distance from the destination door before open/close it
	move_end_radius_door = 100

	// Maximum distance from the followed entity for setting the 'follow' travel done
	move_end_radius_follow = 100

	// Maximum distance from the destination teammate before starting to heal him
	move_end_radius_heal = 80

	// Maximum distance from the destination position for setting the 'lead' travel done
	move_end_radius_lead = 110

	// Maximum distance from the destination pour position before starting to pour
	move_end_radius_pour = 16

	// Maximum distance from the destination scavenge item before picking it up
	move_end_radius_scavenge = 80

	// Maximum distance from the 'wait' position before stopping
	move_end_radius_wait = 150

	// Maximum distance from the destination witch before starting to shoot her
	move_end_radius_witch = 55

	// High priority MOVEs will be automatically terminated after this time, regardless the destination position was reached or not (likely unreachable position)
	move_hipri_timeout = 5.0

	// >0 = BotMoveTo area and move pos are drawn on screen for this amount of time (only the host can see it). 0 = Disable
	moveto_debug_duration = 0

	// [1/0] Enable/Disable orders debug text overlays (only visible to the host)
	orders_debug = 0

	// [1/0] 1 = No orders queue. Any order given to a bot will automatically cancel any previous order for that bot (auto orders like the auto crown witch will still use the queue system)
	//       0 = Orders are queued according to their priorities. You can always cancel the previous orders with the 'cancel' command
	orders_no_queue = 0

	// [1/0] Enable/Disable debug chat messages when the bot starts/stops the pause
	pause_debug = 0

	// Minimum duration of the pause. When a bot starts a pause (due to infected nearby, teammates need help etc.), the pause cannot end earlier than this, even if the conditions to stop the pause are met
	pause_min_time = 3.0

	// Minimum interval between each pick-up
	pickups_min_interval = 0.8

	// When the addon tells a bot to pickup an item, the bot does it via USE button (in order to do the hand animation)
	// But if, for some reason, the pickup fails (too far or something) the item is forced into the bot's inventory after this delay (to prevent stuck situations)
	pickups_failsafe_delay = 0.15

	// Only move for a pick-up if there is at least one human survivor within this range (0 = no limit)
	pickups_max_separation = 800

	// [1/0] 0 = Bots will not pickup melee weapons if they don't have a primary weapon. 1 = Always
	pickups_melee_noprimary = 1

	// Pick up the item we are looking for when within this range
	pickups_pick_range = 90

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

	// If 'scavenge_pour' is '0' the bots will drop gascans and cola bottles within this radius from the pour target
	scavenge_drop_radius = 200

	// Interval of the logic that coordinates the scavenge process
	scavenge_manager_interval = 1

	// Max number of bots that will go scavenge gascans/cola bottles
	scavenge_max_bots = 2

	// [1/0] 1 = Bots will pour the scavenge items they collect. 0 = Bots will drop the collected scavenge items near the use target
	scavenge_pour = 1

	// [1/0] Enable/Disable debug visualization of the found scavenge use target
	scavenge_usetarget_debug = 0

	// [1/0] Enable/Disable tank rocks shooting. If dodge_rock is also 1, the bot might do both but will prioritize the dodge
	shoot_rock = 1

	// Max angle difference between the tank's rock current direction and the direction to the bot when deciding whether the bot should shoot the rock or not
	shoot_rock_diffangle = 8

	// This is how far ahead of the rock's current direction the bot will shoot in order to compensate for its speed
	shoot_rock_ahead = 4

	// Value for the cm_ShouldHurry director option. Not sure what it does exactly
	should_hurry = 1

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

	// [1/0] 1 = When the bots pick up an item, they will chat about that item ("Weapons here", "Ammo here" etc.) if there is at least one human survivor who may need that item. 0 = they only vocalize about it
	// NOTE: signal_max_distance must be > 0 for the entire signal system to work
	signal_chat = 0

	// Maximum distance from the human survivor who may need the item in order to signal the item. 0 = The entire signal system is disabled
	signal_max_distance = 2500

	// Minimum distance from the human survivor who may need the item in order to signal the item
	signal_min_distance = 150

	// Minimum interval between 2 or more signals of the same type (ex. Ammo, Weapon, Throwable, etc.)
	signal_min_interval = 5.0

	// [1/0] If 1, and the "Left 4 Fun" addon is installed and enabled, the bot will also use the L4F PING command on the item to signal. 0 = They don't
	// NOTE: signal_max_distance must be > 0 for the entire signal system to work
	signal_ping = 0

	// [1/0] Enable/Disable the smart use command for carriable items. "use" order on a carriable item (gascans, gnome, cola, etc.) will automatically convert to the "carry" order
	smart_use_carry = 1

	// [1/0] Enable/Disable the smart use command for deployable items. "use" order on a deployable item (upgrade ammo packs) will automatically convert to the "deploy" order
	smart_use_deploy = 1

	// [1/0] Enable/Disable the smart use command for scavenge items. "use" order on a scavenge item (gascans, cola while a pouring target is active) will automatically convert to the "scavenge" order
	smart_use_scavenge = 1

	// [1/0] Enable/Disable shooting the smoker's tongue that is strangling a teammate
	// NOTE: This isn't perfect and in some situations might slow down the rescue even more
	smoker_shoot_tongue = 1

	// [1/0] Enable/Disable crouching while shooting the smoker's tongue
	smoker_shoot_tongue_duck = 1

	// [1/0] 1 = When the spitter's acid lands, it will block the nav areas under it as long as the acid is there. This means that the bots nav system will not make them step into the acid. 0 = normal behavior
	// NOTE: The bots can still step into the acid if they were close to where it landed and they were already running to that direction
	// NOTE2: Blocked nav areas might cause issues and can get the bots stuck into the acid in rare cases
	spit_block_nav = 0

	// The damage received by the bots from the spitter's acid is multiplied by this factor. If you want them to receive the same amount of damage as you, you can set 2
	spit_damage_multiplier = 1

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
	t3_ammo_human = 0

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
	team_max_chainsaws = 0

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

	// Minimum shotguns in the team
	// NOTE: This will override the weapon preferences and it also means that this amount of bots will prefer keeping their tier1 shotguns instead of taking tier2 guns if no tier2 shotgun is found
	team_min_shotguns = 1

	// Minimum vomit jars in the team
	team_min_vomitjars = 0

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

	// TraceLine mask used to look for pick-up items
	tracemask_pickups = 134242379 // 0x1 | 0x2 | 0x8 | 0x40 | 0x2000 | 0x4000 | 0x8000000 (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE | CONTENTS_BLOCKLOS | CONTENTS_IGNORE_NODRAW_OPAQUE | CONTENTS_MOVEABLE | CONTENTS_DETAIL)
	
	// TraceLine mask used for other traces
	tracemask_others = 1174421507 // TRACE_MASK_DEFAULT from left4lib_consts.nut

	// [1/0] 1 = The bots will trigger the car alarms when they accidentally shoot or jump on the car (like human players). 0 = normal behavior
	trigger_caralarm = 0

	// [1/0] 1 = The bots will trigger the witch when they accidentally shoot her (like human players). 0 = normal behavior
	trigger_witch = 0

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

	// [1/0] 1 = If the bot pauses an order due to a nearby witch and the bot is holding a shotgun, he will automatically get ordered to crown that witch
	witch_autocrown = 1
}
