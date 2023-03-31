//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

Msg("Including left4bots_events...\n");

::Left4Bots.Events.OnGameEvent_round_start <- function (params)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_round_start - MapName: " + Left4Bots.MapName + " - MapNumber: " + Director.GetMapNumber());

	// Apparently, when scriptedmode is enabled and this director option isn't set, there is a big stutter (for the host)
	// when a witch is chasing a survivor and that survivor enters the saferoom. Simply having a value for this key, removes the stutter
	if (!("AllowWitchesInCheckpoints" in DirectorScript.GetDirectorOptions()))
		DirectorScript.GetDirectorOptions().AllowWitchesInCheckpoints <- false;

	// Start receiving concepts
	::ConceptsHub.SetHandler("Left4Bots", Left4Bots.OnConcept);
	
	// Start receiving user commands
	::HooksHub.SetUserConsoleCommand("Left4Bots", ::Left4Bots.UserConsoleCommand);
	::HooksHub.SetInterceptChat("Left4Bots", ::Left4Bots.InterceptChat);
	
	// Start the cleaner
	Left4Timers.AddTimer("Cleaner", 0.5, Left4Bots.OnCleaner, {}, true);
	
	// Start the inventory manager
	Left4Timers.AddTimer("InventoryManager", 0.7, Left4Bots.OnInventoryManager, {}, true);
}

::Left4Bots.Events.OnGameEvent_round_end <- function (params)
{
	local winner = params["winner"];
	local reason = params["reason"];
	local message = params["message"];
	local time = params["time"];
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_round_end - winner: " + winner + " - reason: " + reason + " - message: " + message + " - time: " + time);
		
	Left4Bots.AddonStop();
}

::Left4Bots.Events.OnGameEvent_map_transition <- function (params)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_map_transition");
		
	Left4Bots.AddonStop();
}

::Left4Bots.Events.OnGameEvent_player_spawn <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	if (!player || !player.IsValid())
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_spawn - player: " + player.GetPlayerName());
		
	if (Left4Bots.IsValidSurvivor(player))
	{
		::Left4Bots.Survivors[player.GetPlayerUserId()] <- player;
			
		if (IsPlayerABot(player))
		{
			::Left4Bots.Bots[player.GetPlayerUserId()] <- player;
		
			Left4Bots.AddBotThink(player);
		}
		else if (Left4Bots.Settings.play_sounds)
		{
			// Precache sounds for human players
			player.PrecacheScriptSound(Left4Bots.Settings.sound_give_giver);
			player.PrecacheScriptSound(Left4Bots.Settings.sound_give_others);
		}
		
		Left4Bots.PrintSurvivorsCount();
	}
	else if (player.GetZombieType() == Z_TANK)
	{
		::Left4Bots.Tanks[player.GetPlayerUserId()] <- player;
		
		if (Left4Bots.Tanks.len() == 1) // At least 1 tank has spawned
			Left4Bots.OnTankActive();
		
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Active tanks: " + ::Left4Bots.Tanks.len());
	}
	else
	{
		::Left4Bots.Specials[player.GetPlayerUserId()] <- player;
		
		Left4Bots.Log(LOG_LEVEL_DEBUG, "Active specials: " + ::Left4Bots.Specials.len());
	}
}

::Left4Bots.Events.OnGameEvent_witch_spawn <- function (params)
{
	local witch = null;
	if ("witchid" in params)
		witch = EntIndexToHScript(params["witchid"]);
	
	if (!witch || !witch.IsValid())
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_witch_spawn - witch spawned");
	
	::Left4Bots.Witches[witch.GetEntityIndex()] <- witch;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Active witches: " + ::Left4Bots.Witches.len());
}

::Left4Bots.Events.OnGameEvent_player_death <- function (params)
{
	local victim = null;
	local victimIsPlayer = false;
	local victimUserId = null;
	
	if ("userid" in params)
		victim = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	if (victim && victim.IsValid())
	{
		victimIsPlayer = true;
		victimUserId = victim.GetPlayerUserId();
	}
	else if ("entityid" in params)
		victim = EntIndexToHScript(params["entityid"]);
	
	if (!victim || !victim.IsValid())
		return;
	
	local attacker = null;
	local attackerIsPlayer = false;
	
	if ("attacker" in params)
		attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
	
	if (attacker && attacker.IsValid())
		attackerIsPlayer = true;
	else if ("attackerentid" in params)
		attacker = EntIndexToHScript(params["attackerentid"]);
	
	local weapon = null;
	local abort = null;
	local type = null;
		
	if ("weapon" in params)
		weapon = params["weapon"];

	if ("abort" in params)
		abort = params["abort"];
			
	if ("type" in params)
		type = params["type"];
	
	local victimName = "?";
	if (victim)
	{
		if (victimIsPlayer)
			victimName = victim.GetPlayerName();
		else
			victimName = victim.GetClassname(); // It's called victimName but it's the class name in case it's not a player
	}
	
	local attackerName = "?";
	if (attacker)
	{
		if (attackerIsPlayer)
			attackerName = attacker.GetPlayerName();
		else
			attackerName = attacker.GetClassname(); // It's called attackerName but it's the class name in case it's not a player
	}
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_death - victim: " + victimName + " - attacker: " + attackerName + " - weapon: " + weapon + " - abort: " + abort + " - type: " + type);
	
	local victimTeam = NetProps.GetPropInt(victim, "m_iTeamNum");
	if (victimTeam == TEAM_INFECTED)
	{
		if (victimIsPlayer)
		{
			if  (victim.GetZombieType() == Z_TANK)
			{
				if (victimUserId in ::Left4Bots.Tanks)
				{
					delete ::Left4Bots.Tanks[victimUserId];
			
					if (Left4Bots.Tanks.len() == 0) // All the tanks are dead
						Left4Bots.OnTankGone();
			
					Left4Bots.Log(LOG_LEVEL_DEBUG, "Active tanks: " + ::Left4Bots.Tanks.len());
				}
				else
					Left4Bots.Log(LOG_LEVEL_ERROR, "Dead tank was not in Left4Bots.Tanks");
			}
			else
			{
				if (victimUserId in ::Left4Bots.Specials)
				{
					delete ::Left4Bots.Specials[victimUserId];
			
					Left4Bots.Log(LOG_LEVEL_DEBUG, "Active specials: " + ::Left4Bots.Specials.len());
				}
				else
					Left4Bots.Log(LOG_LEVEL_ERROR, "Dead special was not in Left4Bots.Specials");
			}
		}
		else
		{
			if (victimName == "infected")
			{
				// Common infected
			}
			else if (victimName == "witch")
			{
				// Witch
				if (victim.GetEntityIndex() in ::Left4Bots.Witches)
				{
					delete ::Left4Bots.Witches[victim.GetEntityIndex()];
	
					Left4Bots.Log(LOG_LEVEL_DEBUG, "Active witches: " + ::Left4Bots.Witches.len());
				}
				else
					Left4Bots.Log(LOG_LEVEL_ERROR, "Dead witch was not in Left4Bots.Witches");
			}
		}
	}
	else if (victimTeam == TEAM_SURVIVORS && victimIsPlayer)
	{
		if (victimUserId in ::Left4Bots.Survivors)
			delete ::Left4Bots.Survivors[victimUserId];
		
		if (IsPlayerABot(victim))
		{
			if (victimUserId in ::Left4Bots.Bots)
				delete ::Left4Bots.Bots[victimUserId];
		
			Left4Bots.RemoveBotThink(victim);
		}
		
		Left4Bots.PrintSurvivorsCount();
		
		//
		
		local chr = NetProps.GetPropInt(victim, "m_survivorCharacter");
		local sdm = Left4Utils.GetSurvivorDeathModelByChar(chr);
		if (sdm)
		{
			if (attacker && !attackerIsPlayer && attackerName == "trigger_hurt" && (Left4Utils.DamageContains(type, DMG_DROWN) || Left4Utils.DamageContains(type, DMG_CRUSH)))
				Left4Bots.Log(LOG_LEVEL_INFO, "Ignored possible unreachable survivor_death_model for dead survivor: " + victim.GetPlayerName());
			else
				Left4Bots.Deads[chr] <- { dmodel = sdm, player = victim };
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "Couldn't find a survivor_death_model for the dead survivor: " + victim.GetPlayerName() + "!!!");
	}
}

::Left4Bots.Events.OnGameEvent_player_disconnect <- function (params)
{
	if ("userid" in params)
	{
		local userid = params["userid"].tointeger();
		local player = g_MapScript.GetPlayerFromUserID(userid);
	
		if (player && player.IsValid() && IsPlayerABot(player))
			return;

		//Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_disconnect - player: " + player.GetPlayerName());
		
		if (userid in ::Left4Bots.Survivors)
			delete ::Left4Bots.Survivors[userid];
	}
}

::Left4Bots.Events.OnGameEvent_player_bot_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_bot_replace - bot: " + bot.GetPlayerName() + " replaced player: " + player.GetPlayerName());
		
	if (player.GetPlayerUserId() in ::Left4Bots.Survivors)
		delete ::Left4Bots.Survivors[player.GetPlayerUserId()];
	
	if (Left4Bots.IsValidSurvivor(bot))
	{
		::Left4Bots.Survivors[bot.GetPlayerUserId()] <- bot;
		::Left4Bots.Bots[bot.GetPlayerUserId()] <- bot;
	
		Left4Bots.AddBotThink(bot);
	}
	
	Left4Bots.PrintSurvivorsCount();
}

::Left4Bots.Events.OnGameEvent_bot_player_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_bot_player_replace - player: " + player.GetPlayerName() + " replaced bot: " + bot.GetPlayerName());

	if (bot.GetPlayerUserId() in ::Left4Bots.Survivors)
		delete ::Left4Bots.Survivors[bot.GetPlayerUserId()];
	
	if (bot.GetPlayerUserId() in ::Left4Bots.Bots)
		delete ::Left4Bots.Bots[bot.GetPlayerUserId()];
	
	Left4Bots.RemoveBotThink(bot);

	//

	if (Left4Bots.IsValidSurvivor(player))
		::Left4Bots.Survivors[player.GetPlayerUserId()] <- player;
	
	Left4Bots.PrintSurvivorsCount();
}

::Left4Bots.Events.OnGameEvent_item_pickup <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local item = params["item"];
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_item_pickup - player: " + player.GetPlayerName() + " picked up: " + item);
	
	// Update the inventory items
	Left4Bots.OnInventoryManager(params);
}

::Left4Bots.Events.OnGameEvent_weapon_fire <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local weapon = params["weapon"];
	
	//Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnWeaponFired - player: " + player.GetPlayerName() + " - weapon: " + weapon);
		
	if (weapon == "pipe_bomb" || weapon == "vomitjar")
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, player.GetPlayerName() + " threw " + weapon);
		
		Left4Bots.LastNadeTime = Time();
	}
	else if (weapon == "molotov")
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, player.GetPlayerName() + " threw " + weapon);
		
		Left4Bots.LastMolotovTime = Time();
	}
}

::Left4Bots.Events.OnGameEvent_spit_burst <- function (params)
{
	local spitter = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local spit = EntIndexToHScript(params["subject"]);

	if (!spitter || !spit || !spitter.IsValid() || !spit.IsValid())
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnGameEvent_spit_burst - spitter: " + spitter.GetPlayerName());

	if (!Left4Bots.Settings.dodge_spit)
		return;

	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid())
			Left4Bots.TryDodgeSpit(bot, spit);
	}
		
	// TODO?
	//if (Left4Bots.Settings.spit_block_nav)
	//	Left4Timers.AddTimer(null, 3.8, Left4Bots.SpitterSpitBlockNav, { spit_ent = spit });
}

::Left4Bots.Events.OnGameEvent_charger_charge_start <- function (params)
{
	local charger = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!charger || !charger.IsValid())
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnChargerChargeStart - charger: " + charger.GetPlayerName());
	
	if (!Left4Bots.Settings.dodge_charger)
		return;
	
	local chargerOrig = charger.GetOrigin();
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid() && (chargerOrig - bot.GetOrigin()).Length() <= 1200 /*&& Left4Utils.CanTraceTo(bot, charger)*/)
		{
			local facing = charger.EyeAngles().Forward();
			local toBot = bot.GetOrigin() - chargerOrig;
			
			facing.Norm();
			toBot.Norm();
			
			local d = Left4Utils.GetDiffAngle(Left4Utils.VectorAngles(toBot).y, Left4Utils.VectorAngles(facing).y);
			
			// d must be between -dodge_charger_diffangle and dodge_charger_diffangle. d > 0 -> the bot should run to the charger's left. d < 0 -> the bot should run to the charger's right
			if (d >= -Left4Bots.Settings.dodge_charger_diffangle && d <= Left4Bots.Settings.dodge_charger_diffangle)
				Left4Bots.TryDodgeCharger(bot, charger, charger.EyeAngles().Left(), d > 0);
		}
	}
}

::Left4Bots.Events.OnGameEvent_player_jump <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	if (!player || !player.IsValid())
		return;
	
	//Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnPlayerJump - player: " + player.GetPlayerName());
	
	if (RandomInt(1, 100) > Left4Bots.Settings.shove_deadstop_chance)
		return;
	
	local z = NetProps.GetPropInt(player, "m_zombieClass");
	if (z != Z_HUNTER && z != Z_JOCKEY)
		return;
	
	// Victim is supposed to be the infected's lookat survivor but if another survivor gets in the way, he will be the victim without trying to deadstop the special
	local victim = NetProps.GetPropEntity(player, "m_lookatPlayer");
	if (!victim || !victim.IsValid() || !victim.IsPlayer() || !("IsSurvivor" in victim) || !victim.IsSurvivor() || !IsPlayerABot(victim) || Time() < NetProps.GetPropFloat(victim, "m_flNextShoveTime"))
		return;
	
	local d = (victim.GetOrigin() - player.GetOrigin()).Length();

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnPlayerJump - " + player.GetPlayerName() + " -> " + victim.GetPlayerName() + " - " + d);
	
	if (d > 700) // Too far to be a threat
		return;
	
	if (d <= 150)
		Left4Utils.PlayerPressButton(victim, BUTTON_SHOVE, Left4Bots.Settings.button_holdtime_tap, player, Left4Bots.Settings.shove_deadstop_deltapitch, 0, false);
	else
		Left4Timers.AddTimer(null, 0.001 * d, @(params) Left4Utils.PlayerPressButton(params.player, BUTTON_SHOVE, Left4Bots.Settings.button_holdtime_tap, params.destination, Left4Bots.Settings.shove_deadstop_deltapitch, 0, false), { player = victim, destination = player });
}

::Left4Bots.Events.OnGameEvent_finale_escape_start <- function (params)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_finale_escape_start");
	
	Left4Bots.EscapeStarted = true;
}

::Left4Bots.Events.OnGameEvent_finale_vehicle_ready <- function (params)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_finale_vehicle_ready");
	
	Left4Bots.EscapeStarted = true;
}

//

::Left4Bots.OnConcept <- function (concept, query)
{
	if (!Left4Bots.ModeStarted && "gamemode" in query)
	{
		Left4Bots.ModeStarted = true;
		Left4Bots.OnModeStart();
	}
		
	if (concept == "PlayerExertionMinor" || concept.find("VSLib") != null)
		return;
		
	local who = null;
	if ("who" in query)
		who = query.who;
	else if ("Who" in query)
		who = query.Who;
	
	local subject = null;
	if ("subject" in query)
		subject = query.subject;
	else if ("Subject" in query)
		subject = query.Subject;
	
	if (who)
		who = Left4Bots.GetSurvivorFromActor(who);

	if (who && who.IsValid())
	{
		if (IsPlayerABot(who))
		{
			// WHO is a bot
			
			if (concept == "SurvivorBotEscapingFlames")
			{
				local scope = who.GetScriptScope();
				if (scope.CanReset)
				{
					scope.CanReset = false; // Do not send RESET commands to the bot if the bot is trying to escape from the fire or the spitter's spit or it will get stuck there
				
					Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + who.GetPlayerName() + " CanReset = false");
				}
			}
			else if (concept == "SurvivorBotHasEscapedSpit" || concept == "SurvivorBotHasEscapedFlames")
			{
				local scope = who.GetScriptScope();
				if (!scope.CanReset)
				{
					scope.CanReset = true; // Now we can safely send RESET commands again
				
					Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + who.GetPlayerName() + " CanReset = true");
				
					// Delayed resets are executed as soon as we can reset again
					if (scope.DelayedReset)
						Left4Timers.AddTimer(null, 0.01, @(params) params.scope.BotReset(true), { scope = scope });
						//scope.BotReset(true); // Apparently, sending a RESET command to the bot from this OnScope, makes the game crash
				}
				
				// Bot's vanilla escape flames/spit algorithm interfered with any previous MOVE so the MOVE must be refreshed
				if (scope.MovePos && scope.NeedMove <= 0)
					scope.NeedMove = 2;
			}
			else if (concept == "SurvivorBotRegroupWithTeam")
			{
				local scope = who.GetScriptScope();
				if (!scope.CanReset)
				{
					scope.CanReset = true; // Now we can safely send RESET commands again
				
					Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + who.GetPlayerName() + " CanReset = true");
				
					// Delayed resets are executed as soon as we can reset again
					if (scope.DelayedReset)
						Left4Timers.AddTimer(null, 0.01, @(params) params.scope.BotReset(true), { scope = scope });
						//scope.BotReset(true); // Apparently, sending a RESET command to the bot from this OnScope, makes the game crash
				}
				
				// Receiving this concept from a bot who is executing a move command means that the bot got nav stuck and teleported somewhere.
				// After the teleport the move command is lost and needs to be refreshed.
				if (scope.MovePos && scope.NeedMove <= 0)
					scope.NeedMove = 2;
			}
			
			// ...
		}
		else
		{
			// WHO is a human
			
			local canCommand = who.GetPlayerName() == "smilzo";
			
			if (concept == "OfferItem")
			{
				if (subject)
					subject = Left4Bots.GetSurvivorFromActor(subject);
				
				if (subject && subject.IsValid() && IsPlayerABot(subject))
					Left4Bots.LastGiveItemTime = Time();
				
				return;
			}
			
			if (canCommand)
			{
				if (concept == "PlayerStayTogether")
					Left4Bots.OnUserCommand(who, "bots", "cancel", null);
				else if (concept == "PlayerLeadOn")
					Left4Bots.OnUserCommand(who, "bots", "lead", null);
				else if (concept == "PlayerWarnWitch")
				{
					local bestBot = null;
					local bestBotQueue = 10000;
					foreach (bot in Left4Bots.Bots)
					{
						local aw = bot.GetActiveWeapon();
						if (aw && aw.IsValid() && aw.GetClassname().find("shotgun") != null)
						{
							local queued = Left4Bots.BotOrdersCount(bot, "witch");
							if (queued < bestBotQueue)
							{
								bestBot = bot;
								bestBotQueue = queued;
							}
						}
					}
					if (bestBot)
						Left4Bots.OnUserCommand(who, bestBot.GetPlayerName().tolower(), "witch", null);
				}
			}
			
			// TODO
			
			
		}
	}
}

// Removes invalid entities from the Survivors, Bots, Tanks and Deads lists
::Left4Bots.OnCleaner <- function (params)
{
	// Survivors
	foreach (id, surv in ::Left4Bots.Survivors)
	{
		if (!surv || !surv.IsValid())
		{
			delete ::Left4Bots.Survivors[id];
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Removed an invalid survivor from ::Left4Bots.Survivors");
		}
	}
	
	// Bots
	foreach (id, bot in ::Left4Bots.Bots)
	{
		if (!bot || !bot.IsValid())
		{
			delete ::Left4Bots.Bots[id];
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Removed an invalid bot from ::Left4Bots.Bots");
		}
	}
	
	// Deads
	foreach (chr, dead in ::Left4Bots.Deads)
	{
		if (!dead.dmodel || !dead.dmodel.IsValid())
		{
			delete ::Left4Bots.Deads[chr];
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Removed an invalid death model from ::Left4Bots.Deads");
		}
	}

	// Specials
	foreach (id, special in ::Left4Bots.Specials)
	{
		if (!special || !special.IsValid())
		{
			delete ::Left4Bots.Specials[id];
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Removed an invalid special from ::Left4Bots.Specials");
		}
	}
	
	// Tanks
	foreach (id, tank in ::Left4Bots.Tanks)
	{
		if (!tank || !tank.IsValid())
		{
			delete ::Left4Bots.Tanks[id];
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Removed an invalid tank from ::Left4Bots.Tanks");
			
			if (Left4Bots.Tanks.len() == 0)
				Left4Bots.OnTankGone();
		}
	}
	
	// Witches
	foreach (id, witch in ::Left4Bots.Witches)
	{
		if (!witch || !witch.IsValid())
		{
			delete ::Left4Bots.Witches[id];
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Removed an invalid witch from ::Left4Bots.Witches");
		}
	}
}

// Tells the bots which items to pick up based on the current team situation
::Left4Bots.OnInventoryManager <- function (params)
{
	// First count how many medkits, defibs and chainsaws we already have in the team
	local teamMedkits = 0;
	local teamDefibs = 0;
	local teamChainsaws = 0;
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid())
		{
			local inv = {};
			GetInvTable(surv, inv);
			
			if (INV_SLOT_MEDKIT in inv)
			{
				if (inv[INV_SLOT_MEDKIT].GetClassname() == "weapon_first_aid_kit")
					teamMedkits++;
				else if (inv[INV_SLOT_MEDKIT].GetClassname() == "weapon_defibrillator")
					teamDefibs++;
			}
			
			if ((INV_SLOT_SECONDARY in inv) && inv[INV_SLOT_SECONDARY].GetClassname() == "weapon_chainsaw")
				teamChainsaws++;
		}
	}
	
	// Then decide what we need
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid())
		{
			local scope = bot.GetScriptScope();
			scope.PickupsToSearch = {};
			
			local inv = {};
			GetInvTable(bot, inv);
			
			// TODO: Priorities
			if (!(INV_SLOT_THROW in inv))
			{
				// If we don't have a throwable we'll just pick up anything
				
				if (Left4Bots.Settings.pickup_molotov && !("weapon_molotov" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_molotov"] <- 0;
					scope.PickupsToSearch["weapon_molotov_spawn"] <- 0;
				}
				if (Left4Bots.Settings.pickup_pipebomb && !("weapon_pipe_bomb" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_pipe_bomb"] <- 0;
					scope.PickupsToSearch["weapon_pipe_bomb_spawn"] <- 0;
				}
				if (Left4Bots.Settings.pickup_vomitjar && !("weapon_vomitjar" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_vomitjar"] <- 0;
					scope.PickupsToSearch["weapon_vomitjar_spawn"] <- 0;
				}
			}
			
			if (!(INV_SLOT_MEDKIT in inv))
			{
				// If we have nothing in the medkit slot we'll just pick up anything
				
				if (Left4Bots.Settings.pickup_defib && !("weapon_defibrillator" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_defibrillator"] <- 0;
					scope.PickupsToSearch["weapon_defibrillator_spawn"] <- 0;
				}
				if (Left4Bots.Settings.pickup_medkit && !("weapon_first_aid_kit" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_first_aid_kit"] <- 0;
					scope.PickupsToSearch["weapon_first_aid_kit_spawn"] <- 0;
				}
				if (Left4Bots.Settings.pickup_upgrades && !("weapon_upgradepack_explosive" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_upgradepack_explosive"] <- 0;
					scope.PickupsToSearch["weapon_upgradepack_explosive_spawn"] <- 0;
				}
				if (Left4Bots.Settings.pickup_upgrades && !("weapon_upgradepack_incendiary" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_upgradepack_incendiary"] <- 0;
					scope.PickupsToSearch["weapon_upgradepack_incendiary_spawn"] <- 0;
				}
			}
			else
			{
				// Otherwise the priority will be like this:
				// 1. If there is a dead survivor to defib nearby, top priority will be the defib
				// 2. If not enough team medkits or the bot needs to heal, priority -> medkit
				// 3. If not enough team defibs, -> defib
				
				local itemClass = inv[INV_SLOT_MEDKIT].GetClassname();
				local goMedkit = false;
				local goDefib = Left4Bots.HasDeathModelWithin(bot, Left4Bots.Settings.deads_scan_radius);
				if (!goDefib)
				{
					local c = Left4Bots.Survivors.len();
					if ((teamMedkits < Left4Bots.Settings.team_min_medkits && teamMedkits < c) || Left4Bots.BotWillUseMeds(bot))
						goMedkit = true;
					else if (teamDefibs < Left4Bots.Settings.team_min_defibs && teamDefibs < (c - Left4Bots.Settings.team_min_medkits))
						goDefib = true;
				}
				
				if (itemClass != "weapon_defibrillator" && itemClass != "weapon_first_aid_kit")
				{
					if (goDefib && Left4Bots.Settings.pickup_defib && !("weapon_defibrillator" in Left4Bots.ItemsToAvoid))
					{
						scope.PickupsToSearch["weapon_defibrillator"] <- 0;
						scope.PickupsToSearch["weapon_defibrillator_spawn"] <- 0;
					}
					if (Left4Bots.Settings.pickup_medkit && !("weapon_first_aid_kit" in Left4Bots.ItemsToAvoid))
					{
						scope.PickupsToSearch["weapon_first_aid_kit"] <- 0;
						scope.PickupsToSearch["weapon_first_aid_kit_spawn"] <- 0;
					}
				}
				else if (itemClass != "weapon_defibrillator" && goDefib && Left4Bots.Settings.pickup_defib && !("weapon_defibrillator" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_defibrillator"] <- 0;
					scope.PickupsToSearch["weapon_defibrillator_spawn"] <- 0;
				}
				else if (itemClass != "weapon_first_aid_kit" && goMedkit && Left4Bots.Settings.pickup_medkit && !("weapon_first_aid_kit" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_first_aid_kit"] <- 0;
					scope.PickupsToSearch["weapon_first_aid_kit_spawn"] <- 0;
				}
			}
			
			// TODO: Priorities
			if (!(INV_SLOT_PILLS in inv))
			{
				// If we have nothing in the pills slot we'll just pick up anything
				
				if (Left4Bots.Settings.pickup_pills && !("weapon_pain_pills" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_pain_pills"] <- 0;
					scope.PickupsToSearch["weapon_pain_pills_spawn"] <- 0;
				}
				if (Left4Bots.Settings.pickup_adrenaline && !("weapon_adrenaline" in Left4Bots.ItemsToAvoid))
				{
					scope.PickupsToSearch["weapon_adrenaline"] <- 0;
					scope.PickupsToSearch["weapon_adrenaline_spawn"] <- 0;
				}
			}
			
			if (!(INV_SLOT_SECONDARY in inv) || inv[INV_SLOT_SECONDARY] == null || inv[INV_SLOT_SECONDARY].GetClassname() != "weapon_chainsaw")
			{
				// Bot doesn't have a chainsaw
				
				if (teamChainsaws < Left4Bots.Settings.team_max_chainsaws)
				{
					// Not enough team chainsaws
					
					scope.PickupsToSearch["weapon_chainsaw"] <- 0;
					scope.PickupsToSearch["weapon_chainsaw_spawn"] <- 0;
				}
			}
		}
	}
}

// There is at least 1 tank alive
::Left4Bots.OnTankActive <- function ()
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnTankActive");
	
	// TODO
}

// Last tank alive is dead
::Left4Bots.OnTankGone <- function ()
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnTankGone");
	
	// TODO
}

/* Handle user commands

Available commands:
	[botname] lead				: The order is added to the given bot's orders queue. The bot will start leading the way following the map's flow
	bots lead					: Same as above but the first available bot will be automatically selected
	[botname] witch				: The order is added to the given bot's orders queue. The bot will try to kill the witch you are looking at
	bots witch					: Same as above but the first available bot will be automatically selected
	[botname] cancel current	: The given bot will abort it's current order and will proceed with the next one in the queue (if any)
	bots cancel current			: Same as above but for all the bots
	[botname] cancel [ordertype]: The given bot will abort all it's orders (current and queued ones) of type [type] (example: coach cancel lead)
	bots cancel [ordertype]		: Same as above but for all the bots
	[botname] cancel orders		: The given bot will abort all it's orders (current and queued ones) of any type
	bots cancel	orders			: Same as above but for all the bots
	[botname] cancel all		: (or just: [botname] cancel) The given bot will abort everything (orders, current pick-up, ...)
	bots cancel	all				: Same as above but for all the bots

*/
::Left4Bots.OnUserCommand <- function (player, target, command, param)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnUserCommand - player: " + player.GetPlayerName() + " - target: " + target + " - command: " + command + " - param: " + param);
	
	// allBots = true -> "bots" keyword was used, tgtBot is ignored (will be null)
	// allBots = false -> "botname" was used, tgtBot is the target bot (or null if "botname" is invalid)
	local allBots = false;
	local tgtBot = null;

	if (target == "bots")
		allBots = true;
	else
		tgtBot = Left4Bots.GetBotByName(target);
	
	if (!allBots && !tgtBot)
		return false; // Invalid target
	
	switch (command)
	{
		case "lead":
		{
			if (allBots)
				tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command);
			
			if (tgtBot)
				Left4Bots.BotOrderAppend(tgtBot, command, player);
			else
				Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			
			return true;
		}
		case "follow":
		{
			if (allBots)
				tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command);
			
			if (tgtBot)
			{
				local followEnt = null;
				if (param)
					followEnt = param.tolower();
				
				if (!followEnt || followEnt == "me")
					followEnt = player;
				else
					followEnt = Left4Bots.GetBotByName(followEnt);
				
				if (followEnt && followEnt.GetPlayerUserId() != tgtBot.GetPlayerUserId())
					Left4Bots.BotOrderAppend(tgtBot, command, player, followEnt);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "Invalid follow target: " + param);
			}
			else
				Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			
			return true;
		}
		case "witch":
		{
			local witch = Left4Bots.GetPickerWitch(player);
			if (witch)
			{
				if (allBots)
					tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command);
				
				if (tgtBot)
					//Left4Bots.BotOrderInsert(tgtBot, command, player, witch, null, null, 0, false); // This order should have an higher priority so let's use BotOrderInsert instead of BotOrderAppend
					Left4Bots.BotOrderInsertAfter("witch", tgtBot, command, player, witch, null, null, 0, false); // ^ but lower than any previous "witch" order, so BotOrderInsertAfter is better
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}
			else
				Left4Bots.Log(LOG_LEVEL_WARN, "No target witch found for order of type: " + command);
			
			return true;
		}
		case "cancel":
		{
			// param can be:
			// - "current" to cancel the current order only
			// - "orders" to cancel all the orders (including the current one)
			// - "ordertype" to cancel all the orders of given type
			// - "all" (or null) to cancel everything (orders, current pick-up, ...)
			if (param)
				param = param.tolower();
			
			if (!param || param == "all")
			{
				if (allBots)
				{
					foreach (bot in ::Left4Bots.Bots)
						bot.GetScriptScope().BotCancelAll();
				}
				else
					tgtBot.GetScriptScope().BotCancelAll();
			}
			else if (param == "current")
			{
				if (allBots)
				{
					foreach (bot in ::Left4Bots.Bots)
						bot.GetScriptScope().BotCancelCurrentOrder();
				}
				else
					tgtBot.GetScriptScope().BotCancelCurrentOrder();
			}
			else if (param == "orders")
			{
				if (allBots)
				{
					foreach (bot in ::Left4Bots.Bots)
						bot.GetScriptScope().BotCancelOrders();
				}
				else
					tgtBot.GetScriptScope().BotCancelOrders();
			}
			else
			{
				if (allBots)
				{
					foreach (bot in ::Left4Bots.Bots)
						bot.GetScriptScope().BotCancelCurrentOrder(param);
				}
				else
					tgtBot.GetScriptScope().BotCancelCurrentOrder(param);
			}
			
			return true;
		}
	}
	
	return false;
}

//

::Left4Bots.InterceptChat <- function (msg, speaker)
{
	// Removing the ending \r\n
	if (msg.find("\n", msg.len() - 1) != null || msg.find("\r", msg.len() - 1) != null)
		msg = msg.slice(0, msg.len() - 1);
	if (msg.find("\n", msg.len() - 1) != null || msg.find("\r", msg.len() - 1) != null)
		msg = msg.slice(0, msg.len() - 1);
	
	if (!speaker || !speaker.IsValid())
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "Got InterceptChat with invalid speaker: " + msg);
		return true;
	}
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "InterceptChat - speaker: " + speaker.GetPlayerName() + " - msg: " + msg);
	
	local name = speaker.GetPlayerName() + ": ";
	local text = strip(msg.slice(msg.find(name) + name.len())); // Remove the speaker's name part from the message
	local args = {};
	if (text != null && text != "")
		args = split(text, " ");
	
	if (args.len() < 2)
		return true; // L4B commands have at least 2 arguments
	
	name = args[0] + " " + args[1];
	text = strip(text.slice(text.find(name) + name.len())); // Remove the first 2 arguments from the message and take the remaining text as 3rd argument (if any)
	if (text == "")
		text = null;
	
	local isCommand = Left4Bots.OnUserCommand(speaker, args[0].tolower(), args[1].tolower(), text);
	if (isCommand && Left4Bots.Settings.hide_chat_commands)
		return false;
	else
		return true;
}

::Left4Bots.UserConsoleCommand <- function (playerScript, arg)
{
	local args = {};
	if (arg != null && arg != "")
		args = split(arg, ",");
	
	if (args.len() < 3) // L4B commands have at least 2 arguments but commands via console must also start with "l4b," so there is an additional argument
		return;
	
	if (args[0].tolower() != "l4b")
		return; // Not a L4B command
	
	local arg1 = strip(args[1].tolower());
	local arg2 = strip(args[2].tolower());
	local arg3 = null;
	if (args.len() > 3)
		arg3 = strip(args[3]);
	
	Left4Bots.OnUserCommand(playerScript, arg1, arg2, arg3);
}

__CollectEventCallbacks(::Left4Bots.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
