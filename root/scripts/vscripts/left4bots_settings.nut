::Left4Bots.Settings <-
{
	// [1/0] 1 = Prevents (at least will try) the infamous bug of the pipe bomb thrown right before transitioning to the next chapter that makes the bots bug out and do nothing for the entire next chapter. 0 = Disabled
	anti_pipebomb_bug = 1
	
	// Chance that the bot will chat one of the BG lines at the end of the campaign (if dead or incapped)
	bg_chance = 50
	
	// Last bot entering the saferoom will close the door after this delay (if close_saferoom_door is 1). You can increase/decrease this value for maps with CHECKPOINT nav areas not perfectly aligned to the door
	close_saferoom_delay = 0.9
	
	// [1/0] Enable/Disable closing the door right after entering the saferoom
	close_saferoom_door = 1
	
	// [1/0] 1 = Bots will automatically deploy upgrade packs when near other teammates
	deploy_upgrades = 1
	
	// [1/0] 1 = Admins can make the bots die with the "die" command at any time. 0 = Only if there are no human survivors alive
	die_humans_alive = 1
	
	// [1/0] Should the bots dodge the charger?
	dodge_charger = 1
	
	// If the bot's falling (vertical) velocity is > than this, he will be safely teleported to a random teammate. 10000 or higher to prevent the teleport
	// Can be set to the value of one of the game's cvars "fall_speed_fatal" (default val. 720), "fall_speed_safe" (560) to avoid insta-death or any damage at all respectively
	fall_velocity_warp = 10000
	
	// Name of the file containing the admins
	file_admins = "admins.txt"
	
	// Name of the file containing the BG chat lines
	file_bg = "bg.txt"
	
	// Name of the file containing the CVAR changes to apply
	file_convars = "convars.txt"
	
	// Name of the file containing the GG chat lines
	file_gg = "gg.txt"
	
	// Name of the file containing the items that the vanilla AI should not pickup
	file_itemstoavoid = "itemstoavoid.txt"
	
	// Name of the file with the vocalizer/command mapping
	file_vocalizer = "vocalizer.txt"
	
	// [1/0] 1 = The bot will be forced to heal without interrupting when healing himself (unless there are enough infected nearby). 0 = The bot can interrupt healing if not feeling safe enough (vanilla behavior)
	force_heal = 1
	
	// Chance that the bot will chat one of the GG lines at the end of the campaign (if alive)
	gg_chance = 70
	
	// [1/0] Should the L4B AI handle the extra L4D1 survivors (spawned in some maps like "The Passing" or manually by some admin addon)?
	// NOTE: This does only apply when the main team is the L4D2 one, it has no effect when the L4D1 survivors are spawned as the main team
	handle_l4d1_survivors = 1
	
	// [1/0] 1 = When your order a bot to pick up an item with the "use" command and the item is a carry item (gascan, oxygen tank, fireworks etc.), the bot will hold the item until you cancel the order (or the bot is incapped/pinned)
	hold_items = 1
	
	// Chance that the bot will throw the pipe bomb/bile jar at the horde (this check runs multiple times in a second, so this chance must be pretty low to have an actual chance of no throw)
	horde_nades_chance = 5
	
	// When scanning for an actual horde, this is the maximum altitude difference between the bot and the common infected being counted
	horde_nades_maxaltdiff = 150
	
	// When scanning for an actual horde, this is the maximum distance between the bot and the common infected being counted
	horde_nades_radius = 350
	
	// When scanning for an actual horde, this is the minimum number of common infected to count
	horde_nades_size = 10
	
	// When the survivor being ridden by a jockey gets hit by a survivor bot, the jockey gets this amount of damage
	// NOTE: Due to some limitations, the damage is always the same regardless the weapon
	jockey_redirect_damage = 40
	
	// [1/0] 0 = When the bots are holding their position (order "wait"), they automatically stop holding when a survivor gets pinned by SI / is incapacitated / dies / they are in the spitter's spit / they spot a tank or the last human survivor in the team leaves or changes team. 1 = They only stop if the last human survivor leaves or changes team
	keep_holding_position = 0
	
	// [1/0] 1 = Whenever an empty chainsaw is dropped it is immediately removed from the map
	// This is useful when you allow the bots to pickup the chainsaw ("max_chainsaws" setting), so they don't get stuck dropping and picking the empty chainsaw for ever
	kill_empty_chainsaw = 0
	
	// Chance that the bots will laugh when you laugh
	laugh_chance = 25
	
	// [1/0] 1 = Load the CVAR changes from the file_convars file. 0 = Don't (useful if you are going to use another CVAR based AI improvement addon like Improved Bots, Competitive-Bots etc.)
	load_convars = 1
	
	// Minimum log level for the addon's log lines into the console
	// 0 = No log
	// 1 = Only [ERROR] messages are logged
	// 2 = [ERROR] and [WARNING]
	// 3 = [ERROR], [WARNING] and [INFO]
	// 4 = [ERROR], [WARNING], [INFO] and [DEBUG]
	loglevel = 3
	
	// Max chainsaws in the team
	max_chainsaws = 0
	
	// [1/0] Should the bots give their medkits to admins?
	medkits_bots_give = 1

	// [1/0] Can the human survivors give their pills/adrenaline to other survivors (and swap with bots)?
	meds_give = 1
	
	// When the bot tries to heal with health >= this (usually they do it in the start saferoom) the addon will interrupt it, unless there is no human in the team
	// or there are enough spare medkits around for the bot and the teammates who also need it
	min_start_health = 50
	
	// [1/0] Should the bots give their throwables to human players?
	nades_bots_give = 1
	
	// [1/0] Can the human survivors give their molotovs/pipe bombs/bile jars to other survivors (and swap with bots)?
	nades_give = 1
	
	// [1/0] 1 = Disable the bots scavenge for the current map
	no_scavenge = 0
	
	// [1/0] Should the bot do the pickup animation when picking items (also forces them to go closer to the items before picking them up)?
	pickup_animation = 1
	
	// If the distance between the bot and the nearest human is greater than this, the bot will not move to go pickup throwable items (so they don't waste time when you are rushing)
	pickup_max_separation = 450
	
	// [1/0] Should the bots immediately pick up medkits? 0 = vanilla behavior
	pickup_medkit = 1
	
	// [1/0] Should the bots pick up molotovs?
	pickup_molotov = 1
	
	// [1/0] Should the bots immediately pick up pills/adrenaline? 0 = vanilla behavior
	pickup_pills_adrenaline = 1
	
	// [1/0] Should the bots pick up pipe bombs?
	pickup_pipe_bomb = 1
	
	// [1/0] Should the bots pick up vomit jars?
	pickup_vomitjar = 1
	
	// [1/0] Should the bots give their pills/adrenaline to human players?
	pills_bots_give = 1
	
	// [1/0] Enable/Disable the UI sounds when giving a throwable item to another survivor
	play_sounds = 1
	
	// When the tank's rock comes this close, the bots will try to shoot it (they aren't 100% accurate tho). 0 = feature disabled
	rock_shoot_range = 700
	
	// [1/0] 1 = The bots will start scavenging gascans automatically (without the need to use the "bots lead" command) in campaign and versus game modes, even if there are humans in the team
	// NOTE: In scavenge mode they always start automatically
	scavenge_campaign_autostart = 1
	
	// Max number of bots that will be scavenging gascans/cola bottles
	scavenge_max_bots = 2
	
	// [1/0] 1 = Scavenge bots will automatically pour the gascans/cola. 0 = they will just drop them near the pour target and a human will need to complete the pouring
	scavenge_pour = 1
	
	// [1/0] Enable/Disable bots trying to shoot (the bot will crouch and shoot) the smoker's tongue when a survivor is being strangled and the smoker isn't visible
	// NOTE: This isn't perfect and may slow down the rescue even more, depending on the situation
	shoot_smokers_tongue = 1
	
	// Value for the cm_ShouldHurry director option (not sure what it does exactly)
	should_hurry = 1
	
	// Bots will shove special infected (excluding boomers) within this radius (set 0 to disable)
	shove_si_within = 70
	
	// [1/0] 0 = valid chat commands given to the bot will be hidden to the other players
	show_commands = 1
	
	// [1/0] 1 = The bots will also signal the presence of available items to pick up via chat (if signal_max_distance is non 0). 0 No signal via chat but they will still do it via vocalizer
	signal_chat = 1
	
	// Maximum distance from the human teammate (who might need that item) in order to signal the item. 0 = Entire signal feature will be disabled
	signal_max_distance = 2500
	
	// Minimum distance from the human teammate (who might need that item) in order to signal the item
	signal_min_distance = 150
	
	// Minimum wait time (in seconds) for repeating signals (2 or more signals for the same item type, regardless the source bot)
	signal_min_interval = 5.0
	
	// [1/0] If 1 (and the "Left 4 Fun" addon is installed and enabled) they will also mimic the L4F's "scripted_user_func ping" command on that item
	signal_ping = 0
	
	// Chance that the bot will vocalize "Sorry" after doing friendly fire
	sorry_chance = 80
	
	// Chance that the bots will try to deadstop a hunter/jockey attack when the attack is directed at them
	special_shove_chance = 95
	
	// [1/0] 1 = The bot's navigation is automatically blocked in the spitted acid area while the acid is active. This helps avoid the bots stepping into the acid after they dodge it
	// NOTE: This is not 100% effective, can make the bots lag behind more and may increase the chance of getting the bots stuck into the acid
	spit_block_nav = 1
	
	// The damage taken from the spitter's acid is multiplied by this factor (bots only)
	// The game reduces this damage for the bots by default. If you want them to take the same amount of damage of the humans you can set this to 2
	spit_damage_multiplier = 1
	
	// [1/0] Enable/Disable replenish ammo for T3 weapon by bots
	t3_ammo_bots = 1
	
	// [1/0] Enable/Disable replenish ammo for T3 weapon by humans
	t3_ammo_human = 0
	
	// Chance that the bot will throw the molotov at the tank (this check runs multiple times in a second while the tank is in range, so this chance must be pretty low to have an actual chance of no throw)
	tank_molotov_chance = 30
	
	// Chance that the bot will throw the bile jar at the tank (this check runs multiple times in a second while the tank is in range, so this chance must be pretty low to have an actual chance of no throw)
	tank_vomitjar_chance = 3
	
	// Minimum number of defibs (in the entire team) the bots will look for when choosing what to pick up. The bots will first try to have the minimum number of medkits and then look for the required defibs
	// For example: if you set team_min_medkits = 3 and team_min_defibs = 1, the bots will look for at least 3 medkits first, then 1 of them will replace his medkit with a defib once he finds it
	// If their inventory slot is empty they will always pick up anything
	// NOTE: Unfortunately the base AI will still give priority to the medkit, so it will try to pick the medkit and then the defib over and over again. Just carry them far away to make them stop
	team_min_defibs = 0
	
	// Minimum number of medkits (in the entire team) the bots will look for when choosing what to pick up. The bots will first try to have the minimum number of medkits and then look for the required defibs
	// For example: if you set team_min_medkits = 3 and team_min_defibs = 1, the bots will look for at least 3 medkits first, then 1 of them will replace his medkit with a defib once he finds it
	// If their inventory slot is empty they will always pick up anything
	// NOTE: Unfortunately the base AI will still give priority to the medkit, so it will try to pick the medkit and then the defib over and over again. Just carry them far away to make them stop
	team_min_medkits = 4
	
	// Chance that the bot you are looking at (or the last bot who killed a special infected) will vocalize "Thanks" after your "Nice shoot"
	thanks_chance = 90
	
	// [1/0] Are the bots allowed to throw molotovs?
	throw_molotov = 1
	
	// [1/0] Are the bots allowed to throw pipe bombs?
	throw_pipe_bomb = 1
	
	// [1/0] Are the bots allowed to throw vomit jars?
	throw_vomitjar = 1
	
	// [1/0] 1 = Survivor bots will set off car alarms just like the humans
	trigger_caralarm = 0
	
	// [1/0] 1 = Survivor bots will startle the witch when they accidentally shoot her (just like the humans)
	trigger_witch = 0
	
	// [1/0] Should the bots give their upgrade packs to human players?
	upgrades_bots_give = 1
	
	// [1/0] 1 = Non admin players can give orders to the bots (if vocalizer_commands is 1). 0 = Only the admins can
	user_can_command_bots = 0
	
	// [1/0] Enable/Disable the vocalizer orders to the bots (orders via chat are always possible)
	vocalizer_commands = 1
	
	// [1/0] While executing the 'wait' order the bot will wait crouch (1) or standing (0)
	wait_crouch = 0
	
	// Chance that the bot you are looking at will vocalize "You welcome" after your "Thanks"
	youwelcome_chance = 90
}
