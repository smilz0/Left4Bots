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
	
	// Start the button listener
	Left4Timers.AddThinker("L4BUTTON_LISTENER", 0.01, Left4Bots.OnButtonListener, {});
	
	DirectorScript.GetDirectorOptions().cm_ShouldHurry <- 1; // TODO: settings
}

::Left4Bots.Events.OnGameEvent_round_end <- function (params)
{
	local winner = params["winner"];
	local reason = params["reason"];
	local message = params["message"];
	local time = params["time"];
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_round_end - winner: " + winner + " - reason: " + reason + " - message: " + message + " - time: " + time);
	
	if (Left4Bots.Settings.anti_pipebomb_bug)
		Left4Bots.ClearPipeBombs();
	
	Left4Bots.AddonStop();
}

::Left4Bots.Events.OnGameEvent_map_transition <- function (params)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_map_transition");
	
	if (Left4Bots.Settings.anti_pipebomb_bug)
		Left4Bots.ClearPipeBombs();
	
	Left4Bots.AddonStop();
}

::Left4Bots.Events.OnGameEvent_server_pre_shutdown <- function (params)
{
	//local reason = params["reason"];
	
	if (Left4Bots.Settings.anti_pipebomb_bug)
		Left4Bots.ClearPipeBombs();
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
			
			if (attacker && attackerIsPlayer && Left4Bots.IsHandledBot(attacker))
			{
				Left4Bots.NiceShootSurv = attacker;
				Left4Bots.NiceShootTime = Time();
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

				if (attacker && attackerIsPlayer && Left4Bots.IsHandledBot(attacker))
				{
					Left4Bots.NiceShootSurv = attacker;
					Left4Bots.NiceShootTime = Time();
				}
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

::Left4Bots.Events.OnGameEvent_player_entered_checkpoint <- function (params)
{
	if (!Left4Bots.ModeStarted)
		return;
	
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	if (!player || !player.IsValid() || !Left4Bots.IsValidSurvivor(player))
		return;

	local door = null;
	if ("door" in params)
		door = EntIndexToHScript(params["door"]);
	
	//local doorname = null;
	//if ("doorname" in params)
	//	doorname = params["doorname"];
	
	if (Left4Bots.Settings.close_saferoom_door && door && door.IsValid() && Left4Bots.IsHandledBot(player) && Left4Bots.OtherSurvivorsInCheckpoint(player.GetPlayerUserId()))
	{
		local state = NetProps.GetPropInt(door, "m_eDoorState"); // 0 = closed - 1 = opening - 2 = open - 3 = closing
		if (state != 0 && state != 3)
		{
			local area = null;
			if ("area" in params)
				area = NavMesh.GetNavAreaByID(params["area"]);
			else
				area = NavMesh.GetNearestNavArea(door.GetOrigin(), 200, false, false);
			
			local scope = player.GetScriptScope();
			scope.DoorAct = AI_DOOR_ACTION.Saferoom;
			scope.DoorEnt = door; // This tells the bot to close the door. From now on, the bot will start looking for the best moment to close the door without locking himself out (will try at least)
			if (area)
			{
				scope.DoorZ = area.GetCenter().z;
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_entered_checkpoint - area: " + area.GetID() + " - DoorZ: " + scope.DoorZ);
			}
			else
			{
				scope.DoorZ = player.GetOrigin().z;
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_entered_checkpoint - area is null! - DoorZ: " + scope.DoorZ);
			}
		}
	}
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

::Left4Bots.Events.OnGameEvent_door_close <- function (params)
{
	local checkpoint = params["checkpoint"];
	// TODO: is there any other way to know if we are in the exit checkoint? Director.IsAnySurvivorInExitCheckpoint() doesn't even work. It returns true for the starting checkpoint too
	if (checkpoint && Left4Bots.Settings.anti_pipebomb_bug /*&& Director.IsAnySurvivorInExitCheckpoint()*/ && Left4Bots.OtherSurvivorsInCheckpoint(-1)) // -1 is like: is everyone in checkpoint?
	{
		Left4Bots.ClearPipeBombs();
		
		// If someone is holding a pipe bomb we'll also force them to switch to another weapon to make sure they don't throw the bomb while the door is closing
		foreach (surv in ::Left4Bots.Survivors)
		{
			local activeWeapon = surv.GetActiveWeapon();
			if (activeWeapon && activeWeapon.GetClassname() == "weapon_pipe_bomb")
				Left4Bots.BotSwitchToAnotherWeapon(surv);
		}
	}
}

::Left4Bots.Events.OnGameEvent_friendly_fire <- function (params)
{
	local attacker = null;
	local victim = null;
	local guilty = null;
	//local dmgType = null;
	
	if ("attacker" in params)
		attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
	if ("victim" in params)
		victim = g_MapScript.GetPlayerFromUserID(params["victim"]);
	if ("guilty" in params)
		guilty = g_MapScript.GetPlayerFromUserID(params["guilty"]);
	//if ("type" in params)
	//	dmgType = params["type"];
	
	local attackerName = "";
	local victimName = "";
	local guiltyName = "";
	
	if (attacker)
		attackerName = attacker.GetPlayerName();
	if (victim)
		victimName = victim.GetPlayerName();
	if (guilty)
		guiltyName = guilty.GetPlayerName();
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_friendly_fire - attacker: " + attackerName + " - victim: " + victimName + " - guilty: " + guiltyName);
	
	if (victim && guilty && victim.GetPlayerUserId() != guilty.GetPlayerUserId() && IsPlayerABot(guilty) /*&& !IsPlayerABot(victim)*/ && RandomInt(1, 100) <= Left4Bots.Settings.vocalizer_sorry_chance)
		DoEntFire("!self", "SpeakResponseConcept", "PlayerSorry", RandomFloat(0.6, 2), null, guilty);
}

::Left4Bots.Events.OnGameEvent_heal_begin <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	if(!player || !subject || !player.IsValid() || !subject.IsValid())
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_heal_begin - player: " + player.GetPlayerName() + " - subject: " + subject.GetPlayerName());
	
	if (Left4Bots.IsHandledBot(player) && player.GetPlayerUserId() == subject.GetPlayerUserId()) // Bot healing himself
	{
		// Don't let survivor bots heal themselves if their health is >= Left4Bots.Settings.min_start_health (usually they do it in the start saferoom) and there are not enough spare medkits around
		// ... and there are humans in the team (otherwise they won't leave the saferoom)
		if (player.GetHealth() >= Left4Bots.Settings.heal_interrupt_minhealth && Left4Bots.Bots.len() < Left4Bots.Survivors.len() && (!player.GetScriptScope().CurrentOrder || player.GetScriptScope().CurrentOrder.OrderType != "heal") && !Left4Bots.HasSpareMedkitsAround(player))
			player.GetScriptScope().BotReset(); // TODO: Maybe handle this from the Think func?
		else if (Left4Bots.Settings.heal_force && !Left4Bots.HasAngryCommonsWithin(player.GetOrigin(), 3, 100) && !Left4Utils.HasSpecialInfectedWithin(player.GetOrigin(), 400))
		{
			// Force healing without interrupting or they won't heal when not "feeling safe" resulting sometimes in not healing until they die
			
			Left4Bots.Log(LOG_LEVEL_DEBUG, player.GetPlayerName() + " FORCE HEAL");
			
			Left4Utils.PlayerPressButton(player, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_heal, null, 0, 0, true); // <- Without lockLook the vanilla AI will be able to interrupt the healing
		}
	}
}

::Left4Bots.Events.OnGameEvent_finale_win <- function (params)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_finale_win");
	
	local ggLines = Left4Utils.FileToStringList(Left4Bots.Settings.file_gg);
	local bgLines = Left4Utils.FileToStringList(Left4Bots.Settings.file_bg);
	
	foreach (id, bot in ::Left4Utils.GetAllSurvivors())
	{
		if (bot && bot.IsValid() && IsPlayerABot(bot))
		{
			local line = null;
			if (!bot.IsIncapacitated() && !bot.IsDead() && !bot.IsDying())
			{
				if (ggLines && ggLines.len() > 0 && RandomInt(1, 100) <= Left4Bots.Settings.chat_gg_chance)
					line = ggLines[RandomInt(0, ggLines.len() - 1)];
			}
			else
			{
				if (bgLines && bgLines.len() > 0 && RandomInt(1, 100) <= Left4Bots.Settings.chat_bg_chance)
					line = bgLines[RandomInt(0, bgLines.len() - 1)];
			}
			
			if (line)
				Left4Timers.AddTimer(null, RandomFloat(2.0, 5.0), @(params) Left4Bots.SayGG(params.bot, params.line), { bot = bot, line = line });
		}
	}
}

::Left4Bots.Events.OnGameEvent_player_hurt <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
	if (!attacker && ("attackerentid" in params))
		attacker = EntIndexToHScript(params["attackerentid"]);
	
	/*
	local weapon = "";
	if ("weapon" in params)
		weapon = params["weapon"];
	local type = -1;
	if ("type" in params)
		type = params["type"]; // commons do DMG_CLUB
		
	if (attacker)
		Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_hurt - player: " + player.GetPlayerName() + " - attacker: " + attacker.GetClassname() + " - weapon: " + weapon + " - type: " + type);
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_player_hurt - player: " + player.GetPlayerName() + " - weapon: " + weapon + " - type: " + type);
	*/
	
	if (Left4Bots.IsHandledBot(player))
	{
		local weapon = "";
		if ("weapon" in params)
			weapon = params["weapon"];
		
		if (weapon == "insect_swarm" || weapon == "inferno")
		{
			// Pause the 'wait' order if the bot is being damaged by the spitter's spit or the fire
			local scope = player.GetScriptScope();
			if (scope.Waiting && !scope.Paused)
			{
				scope.Paused = Time();
				scope.BotOnPause();
			}
		}
	}
}

::Left4Bots.Events.OnGameEvent_ammo_pile_weapon_cant_use_ammo <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if (!player || !player.IsValid())
		return;

	local pWeapon = Left4Utils.GetInventoryItemInSlot(player, INV_SLOT_PRIMARY);
	if (!pWeapon || !pWeapon.IsValid())
		return;
		
	local cWeapon = pWeapon.GetClassname();
		
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnGameEvent_ammo_pile_weapon_cant_use_ammo - player: " + player.GetPlayerName() + " - weapon: " + cWeapon);
		
	if (cWeapon == "weapon_grenade_launcher" || cWeapon == "weapon_rifle_m60")
	{
		if ((IsPlayerABot(player) && Left4Bots.Settings.t3_ammo_bots) || (!IsPlayerABot(player) && Left4Bots.Settings.t3_ammo_human))
		{
			local ammoType = NetProps.GetPropInt(pWeapon, "m_iPrimaryAmmoType");
			local maxAmmo = Left4Utils.GetMaxAmmo(ammoType);
			NetProps.SetPropIntArray(player, "m_iAmmo", maxAmmo + (pWeapon.GetMaxClip1() - pWeapon.Clip1()), ammoType);
			
			Left4Bots.Log(LOG_LEVEL_INFO, "Player: " + player.GetPlayerName() + " replenished ammo for T3 weapon " + cWeapon);
		}
	}
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
		if (Left4Bots.IsHandledBot(who))
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
						//scope.BotReset(true); // Apparently, sending a RESET command to the bot from this OnConcept, makes the game crash
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
						//scope.BotReset(true); // Apparently, sending a RESET command to the bot from this OnConcept, makes the game crash
				}
				
				// Receiving this concept from a bot who is executing a move command means that the bot got nav stuck and teleported somewhere.
				// After the teleport the move command is lost and needs to be refreshed.
				if (scope.MovePos && scope.NeedMove <= 0 && !scope.Paused)
					scope.NeedMove = 2;
			}
			else if (concept == "TLK_IDLE" || concept == "SurvivorBotNoteHumanAttention" || concept == "SurvivorBotHasRegroupedWithTeam")
			{
				if (Left4Bots.Settings.deploy_upgrades)
				{
					local itemClass = Left4Bots.ShouldDeployUpgrades(who, query);
					if (itemClass)
					{
						Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + who.GetPlayerName() + " switching to upgrade " + itemClass);
						
						who.SwitchToItem(itemClass);
						
						Left4Timers.AddTimer(null, 1, @(params) Left4Bots.DoDeployUpgrade(params.player), { player = who });
					}
				}
			}
			
			// ...
		}
		else
		{
			// WHO is a human
			
			if (concept == "OfferItem")
			{
				if (subject)
					subject = Left4Bots.GetSurvivorFromActor(subject);
				
				if (subject && subject.IsValid() && IsPlayerABot(subject))
					Left4Bots.LastGiveItemTime = Time();
				
				return;
			}
			
			local lvl = Left4Users.GetOnlineUserLevel(who.GetPlayerUserId());
			
			if (Left4Bots.Settings.vocalizer_commands && lvl >= Left4Bots.Settings.userlevel_orders)
			{
				if (concept == "PlayerStayTogether")
					Left4Bots.OnUserCommand(who, "bots", "cancel", null);
				else if (concept == "PlayerMoveOn")
					Left4Bots.OnUserCommand(who, "bots", "cancel", "current");
				else if (concept == "PlayerLeadOn")
					Left4Bots.OnUserCommand(who, "bots", "lead", null);
				else if (concept == "PlayerWarnWitch")
					Left4Bots.OnUserCommand(who, "bot", "witch", null);
				else if (concept == "PlayerFollowMe")
					Left4Bots.OnUserCommand(who, "bot", "follow", "me");
				else if (concept == "AskForHealth2")
					Left4Bots.OnUserCommand(who, "bot", "heal", "me");
				else if (concept == "PlayerWaitHere")
					Left4Bots.OnUserCommand(who, "bots", "wait", null);
				else if (concept == "iMT_PlayerSuggestHealth")
				{
					if (subject)
						subject = Left4Bots.GetSurvivorFromActor(subject);

					if (Left4Bots.IsHandledBot(subject))
						Left4Bots.OnUserCommand(who, subject.GetPlayerName().tolower(), "heal", null);
					else
						Left4Bots.OnUserCommand(who, "bots", "heal", null);
				}
			}
			
			if (lvl < Left4Bots.Settings.userlevel_vocalizer)
				return;

			if (concept == "PlayerLaugh")
			{
				foreach (bot in ::Left4Bots.Bots)
				{
					if (bot.IsValid() && RandomInt(1, 100) <= Left4Bots.Settings.vocalizer_laugh_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerLaugh", RandomFloat(0.5, 2), null, bot);
				}
			}
			else if (concept == "PlayerThanks")
			{
				if (subject)
					subject = Left4Bots.GetSurvivorFromActor(subject);
				
				if (subject && IsPlayerABot(subject) && RandomInt(1, 100) <= Left4Bots.Settings.vocalizer_youwelcome_chance)
					DoEntFire("!self", "SpeakResponseConcept", "PlayerYouAreWelcome", RandomFloat(1.2, 2.3), null, subject);
			}
			else if (concept == "iMT_PlayerNiceShot")
			{
				if (RandomInt(1, 100) <= Left4Bots.Settings.vocalizer_thanks_chance)
				{
					if (subject)
						subject = Left4Bots.GetSurvivorFromActor(subject);

					if (subject && IsPlayerABot(subject))
						DoEntFire("!self", "SpeakResponseConcept", "PlayerThanks", RandomFloat(1.2, 2.3), null, subject);
					else if (Left4Bots.NiceShootSurv && Left4Bots.NiceShootSurv.IsValid() && (Time() - Left4Bots.NiceShootTime) <= 10.0)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerThanks", RandomFloat(0.5, 2), null, Left4Bots.NiceShootSurv);
				}
			}
			/// ...
		}
	}
}

::Left4Bots.OnModeStart <- function ()
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnModeStart");
	
	if (Left4Bots.MapName == "c7m3_port")
	{
		// This stuff allows a full bot team to play The Sacrifice finale by disabling the error message for not enough human survivors
		local bridge_checker = Entities.FindByName(null, "bridge_checker");
		if (bridge_checker)
		{
			DoEntFire("!self", "Kill", "", 0, null, bridge_checker);
			
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Killed bridge_checker");
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "bridge_checker was not found in c7m3_port map!");
		
		local generator_start_model = Entities.FindByName(null, "generator_start_model");
		if (generator_start_model)
		{
			DoEntFire("!self", "SacrificeEscapeSucceeded", "", 0, null, generator_start_model);
			
			Left4Bots.Log(LOG_LEVEL_DEBUG, "Triggered generator_start_model's SacrificeEscapeSucceeded");
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "generator_start_model was not found in c7m3_port map!");
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
				// 1. If there is a dead survivor to defib nearby, top priority -> defib
				// 2. If not enough team medkits or the bot needs to heal, priority -> medkit
				// 3. If not enough team defibs, -> defib
				
				local itemClass = inv[INV_SLOT_MEDKIT].GetClassname();
				local goMedkit = false;
				local goDefib = Left4Bots.HasDeathModelWithin(bot.GetOrigin(), Left4Bots.Settings.deads_scan_radius);
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

// Listen for BUTTON_SHOVE press
Left4Bots.OnButtonListener <- function (params)
{
	foreach (surv in ::Left4Bots.Survivors)
	{
		if (surv.IsValid() && !IsPlayerABot(surv))
		{
			if ((surv.GetButtonMask() & BUTTON_SHOVE) != 0 || (NetProps.GetPropInt(surv, "m_afButtonPressed") & BUTTON_SHOVE) != 0) // <- With med items (pills and adrenaline) the shove button is disabled when looking at teammates and GetButtonMask never sees the button down but m_afButtonPressed still does
			{
				local userid = surv.GetPlayerUserId();
				if (!(userid in Left4Bots.BtnStatus_Shove) || !Left4Bots.BtnStatus_Shove[userid])
				{
					Left4Bots.Log(LOG_LEVEL_DEBUG, surv.GetPlayerName() + " BUTTON_SHOVE");
					
					Left4Bots.BtnStatus_Shove[userid] <- true;

					if (Left4Bots.Settings.give_humans_nades || Left4Bots.Settings.give_humans_meds)
						Left4Timers.AddTimer(null, 0.0, Left4Bots.OnShovePressed, { player = surv });
				}
			}
			else
				Left4Bots.BtnStatus_Shove[surv.GetPlayerUserId()] <- false;
		}
	}
}

// params["player"] pressed the SHOVE button. Handle the items give/swap from the humans
::Left4Bots.OnShovePressed <- function (params)
{
	local attacker = params["player"];
	if (!attacker || !attacker.IsValid())
		return;
	
	local attackerItem = attacker.GetActiveWeapon();
	if (!attackerItem || !attackerItem.IsValid())
		return;
	
	local slot = Left4Utils.FindSlotForItemClass(attacker, attackerItem.GetClassname());
	if (!(slot == INV_SLOT_THROW && Left4Bots.Settings.give_humans_nades) && !(slot == INV_SLOT_PILLS && Left4Bots.Settings.give_humans_meds))
		return;
	
	local attackerItemClass = attackerItem.GetClassname();
	local attackerItemSkin = NetProps.GetPropInt(attackerItem, "m_nSkin");
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnShovePressed - " + attacker.GetPlayerName() + " - " + attackerItemClass + " - " + attackerItemSkin);
	
	local t = Time();
	if (((attackerItemClass == "weapon_pipe_bomb" || attackerItemClass == "weapon_vomitjar") && (t - Left4Bots.LastNadeTime) < 1.5) || (attackerItemClass == "weapon_molotov" && (t - Left4Bots.LastMolotovTime) < 1.5))
		return; // Preventing an exploit that allows you to give the item you just threw away. Throw the nade and press RMB immediately, the item is still seen in the players inventory (Drop event comes after a second), so the item was duplicated.
	
	local victim = Left4Utils.GetPickerEntity(attacker, 270, 0.95);
	if (!victim || !victim.IsValid() || victim.GetClassname() != "player" || !victim.IsSurvivor())
		return;

	Left4Bots.Log(LOG_LEVEL_DEBUG, "Left4Bots.OnShovePressed - attacker: " + attacker.GetPlayerName() + " - victim: " + victim.GetPlayerName() + " - weapon: " + attackerItemClass + " - skin: " + attackerItemSkin);
	
	local victimItem = Left4Utils.GetInventoryItemInSlot(victim, slot);
	if (!victimItem && slot == INV_SLOT_THROW)
	{
		DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, attacker);
		
		Left4Bots.GiveItemIndex1 = attackerItem.GetEntityIndex();
		
		attacker.DropItem(attackerItemClass);

		//victim.GiveItemWithSkin(attackerItemClass, attackerItemSkin);
		Left4Utils.GiveItemWithSkin(victim, attackerItemClass, attackerItemSkin);
		
		Left4Timers.AddTimer(null, 0.1, Left4Bots.ItemGiven, { player1 = attacker, player2 = victim, item = attackerItem });
		
		if (IsPlayerABot(victim))
			Left4Bots.LastGiveItemTime = Time();
	}
	else if (victimItem && IsPlayerABot(victim))
	{
		// Swap
		local victimItemClass = victimItem.GetClassname();
		local victimItemSkin = NetProps.GetPropInt(victimItem, "m_nSkin");
		
		if (victimItemClass != attackerItemClass || victimItemSkin != attackerItemSkin)
		{
			DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, attacker);
			DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, victim);
			
			Left4Bots.GiveItemIndex1 = attackerItem.GetEntityIndex();
			Left4Bots.GiveItemIndex2 = victimItem.GetEntityIndex();
			
			attacker.DropItem(attackerItemClass);
			victim.DropItem(victimItemClass);
			
			//attacker.GiveItemWithSkin(victimItemClass, victimItemSkin);
			Left4Utils.GiveItemWithSkin(attacker, victimItemClass, victimItemSkin);
			//victim.GiveItemWithSkin(attackerItemClass, attackerItemSkin);
			Left4Utils.GiveItemWithSkin(victim, attackerItemClass, attackerItemSkin);
			
			Left4Timers.AddTimer(null, 0.1, Left4Bots.ItemSwapped, { player1 = attacker, item1 = victimItem, player2 = victim, item2 = attackerItem });
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

botsource command [target]

"botsource" can be: "bot" (bot is automatically selected), "bots" (all the bots), "botname" (name of the bot)

Available commands:
	botsource lead				: The order is added to the given bot(s) orders queue. The bot(s) will start leading the way following the map's flow
	botsource follow			: The order is added to the given bot(s) orders queue. The bot(s) will start following you
	botsource follow target		: The order is added to the given bot(s) orders queue. The bot(s) will follow the given target survivor (you can also use the keyword "me" to follow you)
	botsource witch				: The order is added to the given bot(s) orders queue. The bot(s) will try to kill the witch you are looking at
	botsource heal				: The order is added to the given bot(s) orders queue. The bot(s) will heal himself/themselves
	botsource heal target		: The order is added to the given bot(s) orders queue. The bot(s) will heal the target survivor (target can also be the bot himself or the keyword "me" to heal you)
	botsource goto				: The order is added to the given bot(s) orders queue. The bot(s) will go to the location you are looking at
	botsource goto target		: The order is added to the given bot(s) orders queue. The bot(s) will go to the current target's position (target can be another survivor or the keyword "me" to come to you)
	botsource wait				: The order is added to the given bot(s) orders queue. The bot(s) will hold his/their current position
	botsource wait here			: The order is added to the given bot(s) orders queue. The bot(s) will hold position at your current position
	botsource wait there		: The order is added to the given bot(s) orders queue. The bot(s) will hold position at the location you are looking at


botsource cancel [switch]

"botsource" can be: "bots" (all the bots) or "botname" (name of the bot); Keyword "bot" is not allowed here

Switches:
	current		: The given bot(s) will abort his/their current order and will proceed with the next one in the queue (if any)
	ordertype	: The given bot(s) will abort all his/their orders (current and queued ones) of type 'ordertype' (example: coach cancel lead)
	orders		: The given bot(s) will abort all his/their orders (current and queued ones) of any type
	all			: (or empty) The given bot(s) will abort everything (orders, current pick-up, anything)

*/
::Left4Bots.OnUserCommand <- function (player, target, command, param)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "OnUserCommand - player: " + player.GetPlayerName() + " - target: " + target + " - command: " + command + " - param: " + param);
	
	local allBots = false;	// true = "bots" keyword was used, tgtBot is ignored (will be null)
	local tgtBot = null;	// (allBots = false) null = "bot" keyword was used, tgtBot will be automatically selected - not null = "[botname]" was used, tgtBot is the selected bot

	if (target == "bots")
		allBots = true;
	else if (target != "bot")
	{
		tgtBot = Left4Bots.GetBotByName(target);
		if (!tgtBot)
			return false; // Invalid target
	}
	
	switch (command)
	{
		case "lead":
		{
			if (allBots)
			{
				foreach (bot in Left4Bots.Bots)
					Left4Bots.BotOrderAdd(bot, command, player);
			}
			else
			{
				if (!tgtBot)
					tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command);
				
				if (tgtBot)
					Left4Bots.BotOrderAdd(tgtBot, command, player);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}
			
			return true;
		}
		case "follow":
		{
			local followEnt = null;
			if (param)
			{
				if (param.tolower() == "me")
					followEnt = player;
				else
					followEnt = Left4Bots.GetBotByName(param);
			}
			else
				followEnt = player;
			
			if (!followEnt)
			{
				Left4Bots.Log(LOG_LEVEL_WARN, "Invalid follow target: " + param);
				return true;
			}
			
			if (allBots)
			{
				foreach (id, bot in Left4Bots.Bots)
				{
					if (id != followEnt.GetPlayerUserId())
						Left4Bots.BotOrderAdd(bot, command, player, followEnt);
				}
			}
			else
			{
				if (!tgtBot)
					tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command, followEnt.GetPlayerUserId(), followEnt.GetOrigin());

				if (tgtBot && tgtBot.GetPlayerUserId() != followEnt.GetPlayerUserId())
					Left4Bots.BotOrderAdd(tgtBot, command, player, followEnt);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}
			
			return true;
		}
		case "witch":
		{
			local witch = Left4Bots.GetPickerWitch(player); // TODO: Shouldn't just pick the one with the best dot, distance should also be taken into account
			if (!witch)
			{
				Left4Bots.Log(LOG_LEVEL_WARN, "No target witch found for order of type: " + command);
				return true;
			}
			
			if (allBots)
			{
				foreach (bot in Left4Bots.Bots)
					Left4Bots.BotOrderAdd(bot, command, player, witch, null, null, 0, false);
			}
			else
			{
				if (!tgtBot)
					tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command, null, witch.GetOrigin());
				
				if (tgtBot)
					Left4Bots.BotOrderAdd(tgtBot, command, player, witch, null, null, 0, false);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}
			
			return true;
		}
		case "heal":
		{
			local healTgt = null;
			if (param)
			{
				if (param.tolower() == "me")
					healTgt = player;
				else
					healTgt = Left4Bots.GetBotByName(param);
				
				if (!healTgt)
				{
					Left4Bots.Log(LOG_LEVEL_WARN, "Invalid heal target: " + param);
					return true;
				}
			}

			if (allBots)
			{
				foreach (bot in Left4Bots.Bots)
					Left4Bots.BotOrderAdd(bot, command, player, healTgt != null ? healTgt : bot, null, null, Left4Bots.Settings.button_holdtime_heal, false);
			}
			else
			{
				if (!tgtBot)
				{
					if (healTgt)
						tgtBot = Left4Bots.GetNearestBotWithMedkit(healTgt.GetOrigin());
					else
						tgtBot = Left4Bots.GetLowestHPBotWithMedkit()
				}

				if (tgtBot)
					Left4Bots.BotOrderAdd(tgtBot, command, player, healTgt != null ? healTgt : tgtBot, null, null, Left4Bots.Settings.button_holdtime_heal, false);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}

			return true;
		}
		case "goto":
		{
			local gotoPos = null;
			if (param)
			{
				if (param.tolower() == "me")
					gotoPos = player;
				else
					gotoPos = Left4Bots.GetBotByName(param);
				if (!gotoPos)
				{
					Left4Bots.Log(LOG_LEVEL_WARN, "Invalid goto target: " + param);
					return true;
				}
				gotoPos = gotoPos.GetOrigin();
			}
			else
			{
				gotoPos = Left4Utils.GetLookingPosition(player);
				if (!gotoPos)
				{
					Left4Bots.Log(LOG_LEVEL_WARN, "Invalid goto position");
					return true;
				}
			}
			
			if (allBots)
			{
				foreach (bot in Left4Bots.Bots)
					Left4Bots.BotOrderAdd(bot, command, player, null, gotoPos);
			}
			else
			{
				if (!tgtBot)
					tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command);
				
				if (tgtBot)
					Left4Bots.BotOrderAdd(tgtBot, command, player, null, gotoPos);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}
			
			return true;
		}
		case "wait":
		{
			local waitPos = null;
			if (param)
			{
				if (param.tolower() == "here")
					waitPos = player.GetOrigin();
				else if (param.tolower() == "there")
					waitPos = Left4Utils.GetLookingPosition(player);

				if (!waitPos)
				{
					Left4Bots.Log(LOG_LEVEL_WARN, "Invalid wait position: " + param);
					return true;
				}
			}
			
			if (allBots)
			{
				foreach (bot in Left4Bots.Bots)
					Left4Bots.BotOrderAdd(bot, command, player, null, waitPos != null ? waitPos : bot.GetOrigin(), null, 0, !Left4Bots.Settings.wait_nopause);
			}
			else
			{
				if (!tgtBot)
					tgtBot = Left4Bots.GetFirstAvailableBotForOrder(command);
				
				if (tgtBot)
					Left4Bots.BotOrderAdd(tgtBot, command, player, null, waitPos != null ? waitPos : tgtBot.GetOrigin(), null, 0, !Left4Bots.Settings.wait_nopause);
				else
					Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: " + command);
			}
			
			return true;
		}
		case "cancel":
		{
			if (!allBots && !tgtBot)
			{
				Left4Bots.Log(LOG_LEVEL_WARN, "Can't use the 'bot' keyword with the 'cancel' command");
				return true;
			}
			
			// param can be:
			// - "current" to cancel the current order only
			// - "orders" to cancel all the orders (including the current one)
			// - "ordertype" to cancel all the orders of given type
			// - "all" (or null) to cancel everything (orders, current pick-up, anything)
			if (param)
				param = param.tolower();
			
			if (allBots)
			{
				foreach (bot in ::Left4Bots.Bots)
				{
					if (!param || param == "all")
						bot.GetScriptScope().BotCancelAll();
					else if (param == "current")
						bot.GetScriptScope().BotCancelCurrentOrder();
					else if (param == "orders")
						bot.GetScriptScope().BotCancelOrders();
					else
						bot.GetScriptScope().BotCancelCurrentOrder(param);
				}
			}
			else
			{
				if (!param || param == "all")
					tgtBot.GetScriptScope().BotCancelAll();
				else if (param == "current")
					tgtBot.GetScriptScope().BotCancelCurrentOrder();
				else if (param == "orders")
					tgtBot.GetScriptScope().BotCancelOrders();
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
	
	if (Left4Users.GetOnlineUserLevel(speaker.GetPlayerUserId()) < Left4Bots.Settings.userlevel_orders)
		return true;
	
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
	if (Left4Users.GetOnlineUserLevel(playerScript.GetPlayerUserId()) < Left4Bots.Settings.userlevel_orders)
		return true;
	
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

// Moved to left4bots.nut
//__CollectEventCallbacks(::Left4Bots.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
