//--------------------------------------------------------------------------------------------------
//     GitHub:		https://github.com/smilz0/Left4Bots
//     Workshop:	https://steamcommunity.com/sharedfiles/filedetails/?id=3022416274
//--------------------------------------------------------------------------------------------------

Msg("Including left4bots_events...\n");

::Left4Bots.Events.OnGameEvent_round_start <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_round_start - MapName: " + Left4Bots.MapName + " - MapNumber: " + Director.GetMapNumber());

	// Apparently, when scriptedmode is enabled and this director option isn't set, there is a big stutter (for the host)
	// when a witch is chasing a survivor and that survivor enters the saferoom. Simply having a value for this key, removes the stutter
	if (!("AllowWitchesInCheckpoints" in DirectorScript.GetDirectorOptions()))
		DirectorScript.GetDirectorOptions().AllowWitchesInCheckpoints <- false;

	Left4Bots.L4F = ("Left4Fun" in getroottable() && "PingEnt" in ::Left4Fun);
	Left4Bots.Logger.Debug("L4F = " + Left4Bots.L4F.tostring());

	// Start receiving concepts
	::ConceptsHub.SetHandler("Left4Bots", ::Left4Bots.OnConcept.bindenv(::Left4Bots));

	// Start receiving user commands
	::HooksHub.SetChatCommandHandler("l4b", ::Left4Bots.HandleCommand.bindenv(::Left4Bots));
	::HooksHub.SetConsoleCommandHandler("l4b", ::Left4Bots.HandleCommand.bindenv(::Left4Bots));
	::HooksHub.SetAllowTakeDamage("L4B", ::Left4Bots.AllowTakeDamage.bindenv(::Left4Bots));

	// Start the cleaner
	Left4Timers.AddTimer("Cleaner", 0.5, ::Left4Bots.OnCleaner.bindenv(::Left4Bots), {}, true);

	// Start the inventory manager
	Left4Timers.AddTimer("InventoryManager", 0.5, ::Left4Bots.OnInventoryManager.bindenv(::Left4Bots), {}, true);

	// Start the automation task manager
	Left4Timers.AddTimer("TaskManager", 1, ::Left4Bots.Automation.OnTaskManager.bindenv(::Left4Bots), {}, true);

	// Start the thinker
	Left4Timers.AddThinker("L4BThinker", Left4Bots.Settings.thinkers_think_interval, ::Left4Bots.OnThinker.bindenv(::Left4Bots), {});

	DirectorScript.GetDirectorOptions().cm_ShouldHurry <- Left4Bots.Settings.should_hurry;
	
	if (::Left4Bots.Settings.automation && ::Left4Bots.Settings.automation_autostart)
		::Left4Bots.Automation.StartTasks(true);
}

::Left4Bots.Events.OnGameEvent_round_end <- function (params)
{
	local winner = params["winner"];
	local reason = params["reason"];
	local message = params["message"];
	local time = params["time"];

	Left4Bots.Logger.Debug("OnGameEvent_round_end - winner: " + winner + " - reason: " + reason + " - message: " + message + " - time: " + time);

	if (Left4Bots.Settings.anti_pipebomb_bug)
		Left4Bots.ClearPipeBombs();

	Left4Bots.AddonStop();
}

::Left4Bots.Events.OnGameEvent_map_transition <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_map_transition");

	if (Left4Bots.Settings.anti_pipebomb_bug)
		Left4Bots.ClearPipeBombs();

	Left4Bots.AddonStop();
}

::Left4Bots.Events.OnGameEvent_server_pre_shutdown <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_server_pre_shutdown");
	
	Convars.SetValue("sb_all_bot_game", 0);
	
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

	Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Bots.OnPostPlayerSpawn.bindenv(::Left4Bots)(params.player, params.userid), { player = player, userid = params["userid"].tointeger() });
}

::Left4Bots.Events.OnGameEvent_witch_spawn <- function (params)
{
	local witch = null;
	if ("witchid" in params)
		witch = EntIndexToHScript(params["witchid"]);

	if (!witch || !witch.IsValid())
		return;

	Left4Bots.Logger.Debug("OnGameEvent_witch_spawn - witch spawned");

	::Left4Bots.Witches[params["witchid"].tointeger()] <- witch;

	Left4Bots.Logger.Debug("Active witches: " + ::Left4Bots.Witches.len());
}

::Left4Bots.PlayerDeathDebug <- function (victimName, attackerName, params)
{
	local weapon = null;
	if ("weapon" in params)
		weapon = params["weapon"];

	local abort = null;
	if ("abort" in params)
		abort = params["abort"];

	local type = null;
	if ("type" in params)
		type = params["type"];
	
	Left4Bots.Logger.Debug("OnGameEvent_player_death - victim: " + victimName + " - attacker: " + attackerName + " - weapon: " + weapon + " - abort: " + abort + " - type: " + type);
}

::Left4Bots.Events.OnGameEvent_player_death <- function (params)
{
	local victimUserId = null;
	local victim = null;
	local victimIsPlayer = false;

	if ("userid" in params)
	{
		victimUserId = params["userid"].tointeger();
		victim = g_MapScript.GetPlayerFromUserID(params["userid"]);
		victimIsPlayer = victim && victim.IsValid();
	}
	else if ("entityid" in params)
		victim = EntIndexToHScript(params["entityid"]);

	if (!victim || !victim.IsValid())
		return;

	local victimName = "?";
	if (victimIsPlayer)
		victimName = victim.GetPlayerName();
	else
		victimName = victim.GetClassname(); // It's called victimName but it's the class name in case it's not a player

	local attacker = null;
	local attackerIsPlayer = false;

	if ("attacker" in params)
	{
		attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
		attackerIsPlayer = attacker && attacker.IsValid();
	}
	else if ("attackerentid" in params)
		attacker = EntIndexToHScript(params["attackerentid"]);

	local attackerName = "?";
	if (attacker)
	{
		if (attackerIsPlayer)
			attackerName = attacker.GetPlayerName();
		else
			attackerName = attacker.GetClassname(); // It's called attackerName but it's the class name in case it's not a player
	}

	if (Left4Bots.Logger._logLevel >= LOG_LEVEL_DEBUG)
		::Left4Bots.PlayerDeathDebug(victimName, attackerName, params);

	local victimTeam = NetProps.GetPropInt(victim, "m_iTeamNum");
	if (victimIsPlayer)
	{
		if (victimTeam == TEAM_INFECTED)
		{
			if (victimUserId in ::Left4Bots.Specials)
			{
				delete ::Left4Bots.Specials[victimUserId];

				Left4Bots.Logger.Debug("Active specials: " + ::Left4Bots.Specials.len());
			}
			else if (victim.GetZombieType() != Z_TANK)
				Left4Bots.Logger.Warning("Dead special was not in Left4Bots.Specials");

			if (attackerIsPlayer && Left4Bots.IsHandledBot(attacker)) // Validity check is handled there.
			{
				Left4Bots.NiceShootSurv = attacker;
				Left4Bots.NiceShootTime = Time();
			}
		}
		else if (victimTeam == TEAM_SURVIVORS)
		{
			if (victimUserId in ::Left4Bots.Survivors)
				delete ::Left4Bots.Survivors[victimUserId];

			if (victimUserId in ::Left4Bots.SurvivorFlow)
				delete ::Left4Bots.SurvivorFlow[victimUserId];

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
				if (attacker && !attackerIsPlayer && attackerName == "trigger_hurt" /*&& (Left4Utils.DamageContains(type, DMG_DROWN) || Left4Utils.DamageContains(type, DMG_CRUSH))*/)
					Left4Bots.Logger.Info("Ignored possible unreachable survivor_death_model for dead survivor: " + victim.GetPlayerName());
				else
					Left4Bots.Deads[chr] <- { dmodel = sdm, player = victim };
			}
			else
				Left4Bots.Logger.Warning("Couldn't find a survivor_death_model for the dead survivor: " + victim.GetPlayerName() + "!!!");
		}
		else if (victimTeam == TEAM_L4D1_SURVIVORS)
		{
			if (victimUserId in ::Left4Bots.L4D1Survivors)
				delete ::Left4Bots.L4D1Survivors[victimUserId];

			if (victimUserId in ::Left4Bots.SurvivorFlow)
				delete ::Left4Bots.SurvivorFlow[victimUserId];

			Left4Bots.RemoveBotThink(victim);
		}
	}
	/*else if (victimTeam == TEAM_INFECTED)
	{
		if (victimName == "infected")
		{
			// Common infected
		}
	}*/
}

::Left4Bots.Events.OnGameEvent_witch_killed <- function (params)
{
	if (!("witchid" in params))
		return;

	local witchid = params["witchid"].tointeger();

	// Witch
	if (witchid in ::Left4Bots.Witches)
	{
		delete ::Left4Bots.Witches[witchid];

		Left4Bots.Logger.Debug("Active witches: " + ::Left4Bots.Witches.len());
	}
	else
		Left4Bots.Logger.Error("Dead witch was not in Left4Bots.Witches");

	if (!("userid" in params))
		return;

	local attacker = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (Left4Bots.IsHandledBot(attacker))
	{
		Left4Bots.NiceShootSurv = attacker;
		Left4Bots.NiceShootTime = Time();
	}
}

::Left4Bots.Events.OnGameEvent_tank_killed <- function (params)
{
	if (!("userid" in params))
		return;

	local tankId = params["userid"].tointeger();

	if (tankId in ::Left4Bots.Tanks)
	{
		delete ::Left4Bots.Tanks[tankId];

		if (Left4Bots.Tanks.len() == 0) // All the tanks are dead
			::Left4Bots.OnTankGone.bindenv(::Left4Bots)();

		Left4Bots.Logger.Debug("Active tanks: " + ::Left4Bots.Tanks.len());
	}
	else
		Left4Bots.Logger.Warning("Dead tank was not in Left4Bots.Tanks");
}

::Left4Bots.Events.OnGameEvent_player_disconnect <- function (params)
{
	if ("userid" in params)
	{
		local userid = params["userid"].tointeger();
		local player = g_MapScript.GetPlayerFromUserID(userid);

		if (!player || !player.IsValid())
			return;

		//Left4Bots.Logger.Debug("OnGameEvent_player_disconnect - player: " + player.GetPlayerName());

		if (player.GetZombieType() != 9) // Account for Special Infected that get kicked/deleted for whatever reason.
		{
			if (userid in ::Left4Bots.Specials)
				delete ::Left4Bots.Specials[userid];

			if (userid in ::Left4Bots.Tanks)
			{
				delete ::Left4Bots.Tanks[userid];

				if (Left4Bots.Tanks.len() == 0) // All the tanks are gone
					::Left4Bots.OnTankGone.bindenv(::Left4Bots)();
			}
		}
		else if (NetProps.GetPropInt(player, "m_iTeamNum") == TEAM_L4D1_SURVIVORS) // Also account for L4D1 survivors that *also* get kicked/deleted. Perhaps the admin(s) hate them?
		{
			if (userid in ::Left4Bots.L4D1Survivors)
				delete ::Left4Bots.L4D1Survivors[userid];

			if (userid in ::Left4Bots.SurvivorFlow)
				delete ::Left4Bots.SurvivorFlow[userid];
		}
		else if (!IsPlayerABot(player))
		{
			if (userid in ::Left4Bots.Survivors)
				delete ::Left4Bots.Survivors[userid];

			if (userid in ::Left4Bots.SurvivorFlow)
				delete ::Left4Bots.SurvivorFlow[userid];
		}
	}
}

::Left4Bots.Events.OnGameEvent_player_bot_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);

	if (!player || !bot || !player.IsValid() || !bot.IsValid())
	{
		Left4Bots.Logger.Error("OnGameEvent_player_bot_replace - player: " + player + " - bot: " + bot);
		return;
	}

	if (!::Left4Bots.IsValidSurvivor(bot))
		return;

	Left4Bots.Logger.Debug("OnGameEvent_player_bot_replace - bot: " + bot.GetPlayerName() + " replaced player: " + player.GetPlayerName());

	local userid = params["player"].tointeger();
	if (userid in ::Left4Bots.Survivors)
		delete ::Left4Bots.Survivors[userid];

	if (userid in ::Left4Bots.SurvivorFlow)
		delete ::Left4Bots.SurvivorFlow[userid];

	if (Left4Bots.IsValidSurvivor(bot))
	{
		local botUserID = params["bot"].tointeger();
		::Left4Bots.Survivors[botUserID] <- bot;
		::Left4Bots.Bots[botUserID] <- bot;
		::Left4Bots.SurvivorFlow[botUserID] <- { isBot = true, inCheckpoint = ::Left4Bots.IsSurvivorInCheckpoint(bot), flow = GetCurrentFlowDistanceForPlayer(bot) };

		Left4Bots.AddBotThink(bot);
	}

	Left4Bots.PrintSurvivorsCount();
}

::Left4Bots.Events.OnGameEvent_bot_player_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);

	if (!player || !bot || !player.IsValid() || !bot.IsValid())
	{
		Left4Bots.Logger.Error("OnGameEvent_bot_player_replace - player: " + player + " - bot: " + bot);
		return;
	}

	if (!::Left4Bots.IsValidSurvivor(player))
		return;

	Left4Bots.Logger.Debug("OnGameEvent_bot_player_replace - player: " + player.GetPlayerName() + " replaced bot: " + bot.GetPlayerName());

	local botUserID = params["bot"].tointeger();
	if (botUserID in ::Left4Bots.Survivors)
		delete ::Left4Bots.Survivors[botUserID];

	if (botUserID in ::Left4Bots.Bots)
		delete ::Left4Bots.Bots[botUserID];

	if (botUserID in ::Left4Bots.SurvivorFlow)
		delete ::Left4Bots.SurvivorFlow[botUserID];

	Left4Bots.RemoveBotThink(bot);

	// This should fix https://github.com/smilz0/Left4Bots/issues/47
	Left4Bots.PlayerResetAll(player);
	Left4Bots.PlayerResetAll(bot);

	if (Left4Bots.IsValidSurvivor(player))
	{
		local userid = params["player"].tointeger();
		::Left4Bots.Survivors[userid] <- player;
		::Left4Bots.SurvivorFlow[userid] <- { isBot = false,  inCheckpoint = ::Left4Bots.IsSurvivorInCheckpoint(player), flow = GetCurrentFlowDistanceForPlayer(player) };
	}

	Left4Bots.PrintSurvivorsCount();
}

::Left4Bots.Events.OnGameEvent_item_pickup <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if (!Left4Bots.IsHandledSurvivor(player))
		return;

	local item = params["item"];

	Left4Bots.Logger.Debug("OnGameEvent_item_pickup - player: " + player.GetPlayerName() + " picked up: " + item);

	// This is meant to prevent the bot from accidentally using the pills/adrenaline you give them while they are shooting the infected
	if ((item == "pain_pills" || item == "adrenaline") && Left4Bots.IsHandledBot(player)) // Added IsHandledBot to fix https://github.com/smilz0/Left4Bots/issues/83
		Left4Timers.AddTimer(null, 1, @(params) ::Left4Bots.CheckBotPickup.bindenv(::Left4Bots)(params.bot, params.item), { bot = player, item = "weapon_" + item });

	// Update the inventory items
	::Left4Bots.OnInventoryManager.bindenv(::Left4Bots)(params);
	//Left4Timers.AddTimer(null, 0.1, ::Left4Bots.OnInventoryManager.bindenv(::Left4Bots), { });
}

::Left4Bots.Events.OnGameEvent_player_use <- function (params)
{
	local player = null;
	local entity = null;

	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if ("targetid" in params)
		entity = EntIndexToHScript(params["targetid"]);

	if (player == null || !player.IsValid() || entity == null || !entity.IsValid())
		return;

	Left4Bots.Logger.Debug("Left4Bots.OnGameEvent_player_use - " + player.GetPlayerName() + " -> " + entity);

	::Left4Bots.OnPlayerUse.bindenv(::Left4Bots)(player, entity);
}

//lxc molotov has his own event
::Left4Bots.Events.OnGameEvent_molotov_thrown <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	Left4Bots.Logger.Debug(player.GetPlayerName() + " threw molotov");
	
	Left4Bots.LastMolotovTime = Time();
}

::Left4Bots.Events.OnGameEvent_weapon_fire <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local weapon = params["weapon"];

	//Left4Bots.Logger.Debug("Left4Bots.OnWeaponFired - player: " + player.GetPlayerName() + " - weapon: " + weapon);

	if (weapon == "pipe_bomb" || weapon == "vomitjar")
	{
		Left4Bots.Logger.Debug(player.GetPlayerName() + " threw " + weapon);

		Left4Bots.LastNadeTime = Time();
		
		//lxc freeze bot 0.2s
		if (params["userid"] in ::Left4Bots.Bots)
		{
			player.SetVelocity(player.GetVelocity() * 0.3); //lxc reduce speed
			NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") | (1 << 5)); // set FL_FROZEN
			DoEntFire("!self", "RunScriptCode", "Left4Utils.UnfreezePlayer(self);", 0.2, null, player);
		}
	}
	else if (weapon == "molotov")
	{
		//lxc missed fixes: set time in "molotov_thrown" events
		//Left4Bots.Logger.Debug(player.GetPlayerName() + " threw " + weapon);
		//Left4Bots.LastMolotovTime = Time();
		
		//lxc freeze bot 0.2s
		if (params["userid"] in ::Left4Bots.Bots)
		{
			player.SetVelocity(player.GetVelocity() * 0.3); //lxc reduce speed
			NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") | (1 << 5)); // set FL_FROZEN
			DoEntFire("!self", "RunScriptCode", "Left4Utils.UnfreezePlayer(self);", 0.2, null, player);
		}
	}
	//lxc in "weapon_fire" event, we can make bots look at target, this work together with 'BotAim()' in BotThink_Main.
	else if (params["userid"] in ::Left4Bots.Bots)
	{
		local scope = player.GetScriptScope();
		//lxc if not gun or melee, skip
		if (scope.ActiveWeaponSlot == 0 || scope.ActiveWeaponSlot == 1)
		{
			//lxc
			scope.LastFireTime = Time();
			if (scope.BotAim())
				//lxc Full Automatic Weapon, so we don't need release attack button
				NetProps.SetPropInt(player.GetActiveWeapon(), "m_isHoldingFireButton", 0);
		}
	}
}

::Left4Bots.Events.OnGameEvent_spit_burst <- function (params)
{
	local spitter = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local spit = EntIndexToHScript(params["subject"]);

	if (!spitter || !spit || !spitter.IsValid() || !spit.IsValid())
		return;

	Left4Bots.Logger.Debug("Left4Bots.OnGameEvent_spit_burst - spitter: " + spitter.GetPlayerName());

	if (!Left4Bots.Settings.dodge_spit)
		return;

	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
			Left4Bots.TryDodgeSpit(bot, spit);
	}

	if (Left4Bots.Settings.spit_block_nav)
		Left4Timers.AddTimer(null, 3.8, ::Left4Bots.SpitterSpitBlockNav.bindenv(::Left4Bots), { spit_ent = spit });
}

// when "player_death" and "spitter_killed" events fire, can not find acid pool, but in "zombie_death" could
// https://github.com/smilz0/Left4Bots/issues/68
::Left4Bots.Events.OnGameEvent_zombie_death <- function (params)
{
	switch (params["infected_id"]) //common = 0, Smoker = 1, Boomer = 2, Hunter = 3, Spitter = 4, Jockey = 5, Charger = 6, Witch = 7, Tank = 8
	{
		/*case 0: //common
		{
			if (params["victim"] in ::Left4Bots.CommonInfected)
				delete ::Left4Bots.CommonInfected[params["victim"]];
		
			//printl(Left4Bots.CommonInfected.len());
			break;
		}*/
		case 4: //spitter "spitter_killed"
		{
			Left4Bots.FindSpitterDeathPool(EntIndexToHScript(params["victim"]).GetOrigin());
			break;
		}
		//case 1: //Smoker
		//case 2: //Boomer 	"boomer_exploded"
		//case 3: //Hunter
		//case 5: //Jockey 	"jockey_killed"
		//case 6: //Charger "charger_killed"
		//case 7: //Witch 	"witch_killed"
		//case 8: //Tank 	"player_incapacitated", "tank_killed"
	}
}

::Left4Bots.Events.OnGameEvent_charger_charge_start <- function (params)
{
	local charger = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!charger || !charger.IsValid())
		return;

	Left4Bots.Logger.Debug("Left4Bots.OnChargerChargeStart - charger: " + charger.GetPlayerName());

	if (!Left4Bots.Settings.dodge_charger)
		return;

	local chargerOrig = charger.GetOrigin();
	local chargerLeft = charger.EyeAngles().Left();
	local chargerForwardY = charger.EyeAngles().Forward();
	chargerForwardY.Norm();
	chargerForwardY = Left4Utils.VectorAngles(chargerForwardY).y;

	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid() && !Left4Bots.SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
		{
			local d = (chargerOrig - bot.GetOrigin()).Length();
			if (d <= 1200 /*&& Left4Utils.CanTraceTo(bot, charger, Left4Bots.Settings.tracemask_others)*/)
			{
				if (d <= 500)
				{
					Left4Bots.CheckShouldDodgeCharger(bot, charger, chargerOrig, chargerLeft, chargerForwardY);
					continue;
				}
				Left4Timers.AddTimer(null, Left4Bots.Settings.dodge_charger_distdelay_factor * d, @(params) ::Left4Bots.CheckShouldDodgeCharger.bindenv(::Left4Bots)(params.bot, params.charger, params.chargerOrig, params.chargerLeft, params.chargerForwardY), { bot = bot, charger = charger, chargerOrig = chargerOrig, chargerLeft = chargerLeft, chargerForwardY = chargerForwardY });
			}
		}
	}
}

::Left4Bots.Events.OnGameEvent_player_jump <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if (!player || !player.IsValid())
		return;

	//Left4Bots.Logger.Debug("Left4Bots.OnPlayerJump - player: " + player.GetPlayerName());

	if (RandomInt(1, 100) > Left4Bots.Settings.shove_deadstop_chance)
		return;

	local z = NetProps.GetPropInt(player, "m_zombieClass");
	if (z != Z_HUNTER && z != Z_JOCKEY)
		return;

	// Victim is supposed to be the infected's lookat survivor but if another survivor gets in the way, he will be the victim without trying to deadstop the special
	local victim = NetProps.GetPropEntity(player, "m_lookatPlayer");
	//if (!victim || !victim.IsValid() || !victim.IsPlayer() || !("IsSurvivor" in victim) || !victim.IsSurvivor() || !IsPlayerABot(victim) || Time() < NetProps.GetPropFloat(victim, "m_flNextShoveTime"))
	//lxc only check handle bots
	if (!victim || !victim.IsValid() || !("BotSetAim" in victim.GetScriptScope()) || Time() < NetProps.GetPropFloat(victim, "m_flNextShoveTime"))
		return;

	local d = (victim.GetOrigin() - player.GetOrigin()).Length();

	Left4Bots.Logger.Debug("Left4Bots.OnPlayerJump - " + player.GetPlayerName() + " -> " + victim.GetPlayerName() + " - " + d);

	if (d > 700) // Too far to be a threat
		return;

	if (d <= 150)
	{
		victim.GetScriptScope().BotSetAim(AI_AIM_TYPE.Shove, player, 0.233);
		::Left4Bots.PlayerPressButton(victim, BUTTON_SHOVE);
	}
	else
	{
		DoEntFire("!self", "RunScriptCode", @"
			if (activator && !activator.IsDead() && !activator.IsDying() && !activator.IsStaggering())
			{
				local nextshove = NetProps.GetPropFloat(self, ""m_flNextShoveTime"");
				if (Time() >= nextshove)
				{
					BotSetAim(AI_AIM_TYPE.Shove, activator, 0.233);
					L4B.PlayerPressButton(self, BUTTON_SHOVE);
				}
				else //lxc can still stop hunter and jockey in left time, the success rate is proportional to the left time
				{
					BotSetAim(AI_AIM_TYPE.Shove, Left4Bots.GetHitPos(activator), nextshove - Time());
				}
			}
		", 0.001 * d, player, victim);
		//Left4Timers.AddTimer(null, 0.001 * d, @(params) ::Left4Bots.PlayerPressButton(params.player, BUTTON_SHOVE, 0, params.destination, Left4Bots.Settings.shove_deadstop_deltapitch, 0, false), { player = victim, destination = player });
	}
}

::Left4Bots.Events.OnGameEvent_player_entered_checkpoint <- function (params)
{
	if (!Left4Bots.ModeStarted)
		return;

	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if (!Left4Bots.IsHandledSurvivor(player))
		return;

	local door = null;
	if ("door" in params)
		door = EntIndexToHScript(params["door"]);

	local allBots = RandomInt(1, 100) <= Left4Bots.Settings.close_saferoom_door_all_chance;

	if (Left4Bots.Settings.close_saferoom_door && door && door.IsValid() && (allBots || Left4Bots.IsHandledBot(player)) && ::Left4Bots.ShouldCloseSaferoomDoor(player.GetPlayerUserId(), ::Left4Bots.Settings.close_saferoom_door_behind_range))
	{
		local state = NetProps.GetPropInt(door, "m_eDoorState"); // 0 = closed - 1 = opening - 2 = open - 3 = closing
		if (state != 0 && state != 3)
		{
			local area = null;
			if ("area" in params)
				area = NavMesh.GetNavAreaByID(params["area"]);
			else
				area = NavMesh.GetNearestNavArea(door.GetOrigin(), 200, false, false);

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
	}
}

::Left4Bots.Events.OnGameEvent_revive_begin <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_revive_begin");

	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!Left4Bots.IsHandledBot(player))
		return;

	local item = Left4Utils.GetInventoryItemInSlot(player, INV_SLOT_THROW);
	if (!item || !item.IsValid())
		return;

	local itemClass = item.GetClassname();
	if (((Left4Bots.Settings.throw_pipebomb && itemClass == "weapon_pipe_bomb") || (Left4Bots.Settings.throw_vomitjar && itemClass == "weapon_vomitjar")) &&
		//NetProps.GetPropInt(player, "m_hasVisibleThreats") &&
		(Time() - Left4Bots.LastNadeTime) >= Left4Bots.Settings.throw_nade_interval &&
		Left4Bots.CountOtherStandingSurvivorsWithin(player, 300) < 2 &&
		Left4Bots.HasAngryCommonsWithin(player.GetOrigin(), 3, 500, 150))
	{
		local pos = Left4Utils.BotGetFarthestPathablePos(player, Left4Bots.Settings.throw_nade_radius);
		if (pos && (pos - player.GetOrigin()).Length() >= Left4Bots.Settings.throw_nade_mindistance)
			Left4Timers.AddTimer(null, 0.1, @(params) ::Left4Bots.CancelReviveAndThrowNade.bindenv(::Left4Bots)(params.bot, params.subject, params.pos), { bot = player, subject = g_MapScript.GetPlayerFromUserID(params["subject"]), pos = pos });
	}
}

::Left4Bots.Events.OnGameEvent_finale_escape_start <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_finale_escape_start");

	Left4Bots.EscapeStarted = true;
}

::Left4Bots.Events.OnGameEvent_finale_vehicle_ready <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_finale_vehicle_ready");

	Left4Bots.EscapeStarted = true;
}

::Left4Bots.Events.OnGameEvent_door_close <- function (params)
{
	local checkpoint = params["checkpoint"];
	// TODO: is there any other way to know if we are in the exit checkpoint? Director.IsAnySurvivorInExitCheckpoint() doesn't even work. It returns true for the starting checkpoint too
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

::Left4Bots.FriendlyFireDebug <- function (attacker, victim, guilty)
{
	local attackerName = "";
	if (attacker)
		attackerName = attacker.GetPlayerName();

	local victimName = "";
	if (victim)
		victimName = victim.GetPlayerName();

	local guiltyName = "";
	if (guilty)
		guiltyName = guilty.GetPlayerName();

	Logger.Debug("OnGameEvent_friendly_fire - attacker: " + attackerName + " - victim: " + victimName + " - guilty: " + guiltyName);
}

::Left4Bots.Events.OnGameEvent_friendly_fire <- function (params)
{
	local victim = null;
	if ("victim" in params)
		victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	local guilty = null;
	if ("guilty" in params)
		guilty = g_MapScript.GetPlayerFromUserID(params["guilty"]);

	if (Left4Bots.Logger._logLevel >= LOG_LEVEL_DEBUG)
	{
		local attacker = null;
		if ("attacker" in params)
			attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);

		//local dmgType = null;
		//if ("type" in params)
		//	dmgType = params["type"];

		::Left4Bots.FriendlyFireDebug(attacker, victim, guilty);
	}

	if (victim && guilty && victim.GetPlayerUserId() != guilty.GetPlayerUserId() && IsPlayerABot(guilty) /*&& !IsPlayerABot(victim)*/ && RandomInt(1, 100) <= Left4Bots.Settings.vocalizer_sorry_chance)
		DoEntFire("!self", "SpeakResponseConcept", "PlayerSorry", RandomFloat(0.6, 2), null, guilty);
}

::Left4Bots.Events.OnGameEvent_heal_begin <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	if(!player || !player.IsValid() || !subject || !subject.IsValid())
		return;

	Left4Bots.Logger.Debug("OnGameEvent_heal_begin - player: " + player.GetPlayerName() + " - subject: " + subject.GetPlayerName());

	if (Left4Bots.IsHandledBot(player) && player.GetPlayerUserId() == subject.GetPlayerUserId()) // Bot healing himself
	{
		// Don't let survivor bots heal themselves if their health is >= Left4Bots.Settings.min_start_health (usually they do it in the start saferoom) and there are not enough spare medkits around
		// ... and there are humans in the team (otherwise they won't leave the saferoom)
		// ... and it's not a "heal" order
		if (player.GetHealth() >= Left4Bots.Settings.heal_interrupt_minhealth && Left4Bots.Bots.len() < Left4Bots.Survivors.len() && (NetProps.GetPropInt(player, "m_afButtonForced") & BUTTON_ATTACK) == 0 && !Left4Bots.HasSpareMedkitsAround(player))
			player.GetScriptScope().BotReset(); // TODO: Maybe handle this from the Think func?
		else if (Left4Bots.Settings.heal_force && !Left4Bots.HasAngryCommonsWithin(player.GetOrigin(), 3, 100) && !Left4Bots.HasSpecialInfectedWithin(player.GetOrigin(), 400))
		{
			// Force healing without interrupting or they won't heal when not "feeling safe" resulting sometimes in not healing until they die

			Left4Bots.Logger.Debug(player.GetPlayerName() + " FORCE HEAL");

			::Left4Bots.PlayerPressButton(player, BUTTON_ATTACK, 0, null, 0, 0, true); // <- Without lockLook the vanilla AI will be able to interrupt the healing
		}
	}
}

::Left4Bots.Events.OnGameEvent_finale_win <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_finale_win");

	foreach (id, bot in ::Left4Utils.GetAllSurvivors())
	{
		if (bot && bot.IsValid() && IsPlayerABot(bot) && RandomInt(1, 100) <= Left4Bots.Settings.chat_gg_chance)
		{
			local linesToPickFrom = Left4Bots.ChatBGLines;
			if (NetProps.GetPropInt(bot, "m_lifeState") == 0 /* is alive? */ && !bot.IsIncapacitated())
				linesToPickFrom = Left4Bots.ChatGGLines;

			if (linesToPickFrom.len() > 0)
				Left4Timers.AddTimer(null, RandomFloat(1.0, 7.0), @(params) ::Left4Bots.SayLine.bindenv(::Left4Bots)(params.bot, params.line), { bot = bot, line = linesToPickFrom[RandomInt(0, linesToPickFrom.len() - 1)] });
		}
	}
}

::Left4Bots.Events.OnGameEvent_player_hurt <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	/*
	local attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
	if (!attacker && ("attackerentid" in params))
		attacker = EntIndexToHScript(params["attackerentid"]);

	local weapon = "";
	if ("weapon" in params)
		weapon = params["weapon"];
	local type = -1;
	if ("type" in params)
		type = params["type"]; // commons do DMG_CLUB

	if (attacker)
		Left4Bots.Logger.Debug("OnGameEvent_player_hurt - player: " + player.GetPlayerName() + " - attacker: " + attacker + " - weapon: " + weapon + " - type: " + type);
	else
		Left4Bots.Logger.Debug("OnGameEvent_player_hurt - player: " + player.GetPlayerName() + " - weapon: " + weapon + " - type: " + type);
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
				scope.BotPause();
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

	Left4Bots.Logger.Debug("OnGameEvent_ammo_pile_weapon_cant_use_ammo - player: " + player.GetPlayerName() + " - weapon: " + cWeapon);

	local isPlayerABot = IsPlayerABot(player);
	if ((cWeapon == "weapon_grenade_launcher" || cWeapon == "weapon_rifle_m60") && (isPlayerABot ? Left4Bots.Settings.t3_ammo_bots : Left4Bots.Settings.t3_ammo_human))
	{
		local ammoType = NetProps.GetPropInt(pWeapon, "m_iPrimaryAmmoType");
		local maxAmmo = Left4Utils.GetMaxAmmo(ammoType);

		local upAmmo = 0;
		if (NetProps.GetPropInt(pWeapon, "m_upgradeBitVec") & (1 | 2)) //INCENDIARY_AMMO = 1; EXPLOSIVE_AMMO = 2;
			upAmmo = NetProps.GetPropInt(pWeapon, "m_nUpgradedPrimaryAmmoLoaded");

		NetProps.SetPropIntArray(player, "m_iAmmo", maxAmmo + (pWeapon.GetMaxClip1() - (pWeapon.Clip1() - upAmmo)), ammoType);

		if (!isPlayerABot)
			EmitSoundOnClient("BaseCombatCharacter.AmmoPickup", player);

		Left4Bots.Logger.Info("Player: " + player.GetPlayerName() + " replenished ammo for T3 weapon " + cWeapon);
	}
}

::Left4Bots.Events.OnGameEvent_survivor_call_for_help <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if (!player || !player.IsValid())
		return;

	// info_survivor_rescue
	local subject = null;
	if ("subject" in params)
		subject = EntIndexToHScript(params["subject"]);

	if (!subject || !subject.IsValid())
		return;

	//Left4Bots.Logger.Debug("OnGameEvent_survivor_call_for_help - player: " + player.GetPlayerName() + " - pos: " + subject.GetOrigin());
	Left4Bots.Logger.Debug("OnGameEvent_survivor_call_for_help - player: " + player.GetPlayerName() + " - " + player.GetOrigin() + " - " + subject + ": " + subject.GetOrigin());

	foreach (bot in Left4Bots.Bots)
	{
		if (!Left4Bots.BotHasOrderDestEnt(bot, "info_survivor_rescue"))
			Left4Bots.BotOrderAdd(bot, "goto", null, subject);
	}
}

::Left4Bots.Events.OnGameEvent_survivor_rescued <- function (params)
{
	//local rescuer = null;
	//if ("rescuer" in params)
	//	rescuer = g_MapScript.GetPlayerFromUserID(params["rescuer"]);

	local victim = null;
	if ("victim" in params)
		victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	if (!victim || !victim.IsValid())
		return;

	//local door = null;
	//if ("dooridx" in params)
	//	door = EntIndexToHScript(params["dooridx"]);

	Left4Bots.Logger.Debug("OnGameEvent_survivor_rescued - victim: " + victim.GetPlayerName());

	foreach (bot in Left4Bots.Bots)
		bot.GetScriptScope().BotCancelOrdersDestEnt("info_survivor_rescue");
}

::Left4Bots.Events.OnGameEvent_survivor_rescue_abandoned <- function (params)
{
	Left4Bots.Logger.Debug("OnGameEvent_survivor_rescue_abandoned");

	foreach (bot in Left4Bots.Bots)
		bot.GetScriptScope().BotCancelOrdersDestEnt("info_survivor_rescue");
}

::Left4Bots.Events.OnGameEvent_player_say <- function (params)
{
	local player = 0;
	if ("userid" in params)
		player = params["userid"];
	if (player != 0)
		player = g_MapScript.GetPlayerFromUserID(player);
	else
		player = null;
	local text = params["text"];

	if (!player || !text || !player.IsValid() || IsPlayerABot(player))
		return;

	// Handle 'hello' replies
	local playerid = player.GetPlayerUserId();
	if (Left4Bots.ChatHelloReplies.len() > 0 && Left4Bots.Bots.len() > 0 && Left4Users.IsJustJoined(playerid) && !(playerid in Left4Bots.ChatHelloAlreadyReplied))
	{
		local helloTriggers = "," + Left4Bots.Settings.chat_hello_triggers + ",";
		if (helloTriggers.find("," + text.tolower() + ",") != null)
		{
			Left4Bots.Logger.Debug("OnGameEvent_player_say - Hello triggered");
			foreach (bot in Left4Bots.Bots)
			{
				if (RandomInt(1, 100) <= Left4Bots.Settings.chat_hello_chance)
					Left4Timers.AddTimer(null, RandomFloat(2.5, 6.5), @(params) ::Left4Bots.SayLine.bindenv(::Left4Bots)(params.bot, params.line), { bot = bot, line = Left4Bots.ChatHelloReplies[RandomInt(0, Left4Bots.ChatHelloReplies.len() - 1)] });
			}
			Left4Bots.ChatHelloAlreadyReplied[playerid] <- 1;
		}
	}

	// Also handle chat bot commands given without chat trigger
	if (Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < Left4Bots.Settings.userlevel_orders)
		return;

	local args = split(text, " ");
	if (args.len() < 2)
		return;

	local arg1 = strip(args[0].tolower());
	if (arg1 != "bot" && arg1 != "bots" && Left4Bots.GetBotByName(arg1) == null)
		return;

	local arg2 = strip(args[1].tolower());
	if (::Left4Bots.UserCommands.find(arg2) == null && ::Left4Bots.AdminCommands.find(arg2) == null)
		return;

	local arg3 = null;
	if (args.len() > 2)
		arg3 = strip(args[2]);

	Left4Bots.OnUserCommand(player, arg1, arg2, arg3);
}

::Left4Bots.Events.OnGameEvent_infected_hurt <- function (params)
{
	local attacker = null;
	local infected = null;
	local damage = 0;
	local dmgType = 0;

	if ("attacker" in params)
		attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);

	if ("entityid" in params)
		infected = EntIndexToHScript(params["entityid"]);

	if ("amount" in params)
		damage = params["amount"].tointeger();

	if ("type" in params)
		dmgType = params["type"].tointeger();

	//Left4Bots.Logger.Debug("OnGameEvent_infected_hurt");

	if (!attacker || !infected || !attacker.IsValid() || !infected.IsValid() || attacker.GetClassname() != "player" || infected.GetClassname() != "witch" || !IsPlayerABot(attacker))
		return;

	local attackerTeam = NetProps.GetPropInt(attacker, "m_iTeamNum");
	if (attackerTeam != TEAM_SURVIVORS && attackerTeam != TEAM_L4D1_SURVIVORS)
		return;

	//Left4Bots.Logger.Debug("OnGameEvent_infected_hurt - attacker: " + attacker.GetPlayerName() + " - damage: " + damage + " - dmgType: " + dmgType);

	if (Left4Bots.Settings.trigger_witch && NetProps.GetPropFloat(infected, "m_rage") < 1.0 && !NetProps.GetPropInt(infected, "m_mobRush") && (dmgType & DMG_BURN) == 0)
	{
		Left4Bots.Logger.Debug("OnGameEvent_infected_hurt - Bot " + attacker.GetPlayerName() + " startled witch (damage: " + damage + " - dmgType: " + dmgType + ")");

		/* Fire method
		if (!NetProps.GetPropInt(infected, "m_bIsBurning"))
			Left4Timers.AddTimer(null, 0.01, ::Left4Bots.ExtinguishWitch.bindenv(::Left4Bots), { witch = infected }, false);

		infected.TakeDamage(0.001, DMG_BURN, attacker); // Startle the witch
		*/

		// Easier method
		NetProps.SetPropFloat(infected, "m_rage", 1.0);
		NetProps.SetPropFloat(infected, "m_wanderrage", 1.0);
		Left4Utils.BotCmdAttack(infected, attacker);
	}
}

::Left4Bots.Events.OnGameEvent_charger_carry_start <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	Left4Bots.SpecialGotSurvivor(player, victim, "charger_carry_start");
}

::Left4Bots.Events.OnGameEvent_charger_pummel_start <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	Left4Bots.SpecialGotSurvivor(player, victim, "charger_pummel_start");
}

::Left4Bots.Events.OnGameEvent_tongue_grab <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	Left4Bots.SpecialGotSurvivor(player, victim, "tongue_grab");
}

::Left4Bots.Events.OnGameEvent_jockey_ride <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	Left4Bots.SpecialGotSurvivor(player, victim, "jockey_ride");
}

::Left4Bots.Events.OnGameEvent_lunge_pounce <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);

	Left4Bots.SpecialGotSurvivor(player, victim, "lunge_pounce");
}

// -----

::Left4Bots.OnPostPlayerSpawn <- function (player, userid)
{
	if (!player || !player.IsValid())
		return;

	Logger.Debug("OnPostPlayerSpawn - player: " + player.GetPlayerName());

	player.SetContext("userid", userid.tostring(), -1);

	if (IsValidSurvivor(player))
	{
		Survivors[userid] <- player;
		SurvivorFlow[userid] <- { isBot = false, inCheckpoint = IsSurvivorInCheckpoint(player), flow = GetCurrentFlowDistanceForPlayer(player) };

		if (IsPlayerABot(player))
		{
			Bots[userid] <- player;
			SurvivorFlow[userid].isBot = true;

			AddBotThink(player);
		}
		else if (Settings.play_sounds)
		{
			// Precache sounds for human players
			player.PrecacheScriptSound("Hint.BigReward");
			player.PrecacheScriptSound("Hint.LittleReward");
			player.PrecacheScriptSound("BaseCombatCharacter.AmmoPickup");
		}

		PrintSurvivorsCount();
		return;
	}
	
	local team = NetProps.GetPropInt(player, "m_iTeamNum");
	if (team == TEAM_INFECTED)
	{
		if (player.GetZombieType() == Z_TANK)
		{
			Tanks[userid] <- player;

			if (Tanks.len() == 1) // At least 1 tank has spawned
				OnTankActive();

			Logger.Debug("Active tanks: " + Tanks.len());
			return;
		}
		Specials[userid] <- player;
		Logger.Debug("Active specials: " + Specials.len());
	}
	else if (team == TEAM_L4D1_SURVIVORS && Settings.handle_l4d1_survivors == 1)
	{
		L4D1Survivors[userid] <- player;
		AddL4D1BotThink(player);

		PrintL4D1SurvivorsCount();
	}
}

::Left4Bots.OnModeStart <- function ()
{
	Logger.Debug("OnModeStart");

	if (MapName == "c7m3_port")
	{
		// This stuff allows a full bot team to play The Sacrifice finale by disabling the error message for not enough human survivors
		local bridge_checker = Entities.FindByName(null, "bridge_checker");
		if (bridge_checker)
		{
			DoEntFire("!self", "Kill", "", 0, null, bridge_checker);

			Logger.Debug("Killed bridge_checker");
		}
		else
			Logger.Warning("bridge_checker was not found in c7m3_port map!");

		local generator_start_model = Entities.FindByName(null, "generator_start_model");
		if (generator_start_model)
		{
			DoEntFire("!self", "SacrificeEscapeSucceeded", "", 0, null, generator_start_model);

			Logger.Debug("Triggered generator_start_model's SacrificeEscapeSucceeded");
		}
		else
			Logger.Warning("generator_start_model was not found in c7m3_port map!");
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
	if (!(slot == INV_SLOT_THROW && Settings.give_humans_nades) && !(slot == INV_SLOT_PILLS && Settings.give_humans_meds))
		return;

	local attackerItemClass = attackerItem.GetClassname();
	local attackerItemSkin = NetProps.GetPropInt(attackerItem, "m_nSkin");

	Logger.Debug("OnShovePressed - " + attacker.GetPlayerName() + " - " + attackerItemClass + " - " + attackerItemSkin);

	local t = Time();
	if (((attackerItemClass == "weapon_pipe_bomb" || attackerItemClass == "weapon_vomitjar") && (t - LastNadeTime) < 1.5) || (attackerItemClass == "weapon_molotov" && (t - LastMolotovTime) < 1.5))
		return; // Preventing an exploit that allows you to give the item you just threw away. Throw the nade and press RMB immediately, the item is still seen in the players inventory (Drop event comes after a second), so the item was duplicated.

	local victim = Left4Utils.GetPickerEntity(attacker, 270, 0.95, true, null, Settings.tracemask_others);
	if (!victim || !victim.IsValid() || victim.GetClassname() != "player" || !victim.IsSurvivor())
		return;

	Logger.Debug("OnShovePressed - attacker: " + attacker.GetPlayerName() + " - victim: " + victim.GetPlayerName() + " - weapon: " + attackerItemClass + " - skin: " + attackerItemSkin);

	local victimItem = Left4Utils.GetInventoryItemInSlot(victim, slot);
	if (!victimItem && slot == INV_SLOT_THROW)
	{
		DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, attacker);

		GiveItemIndex1 = attackerItem.GetEntityIndex();

		attacker.DropItem(attackerItemClass);

		//Left4Utils.GiveItemWithSkin(victim, attackerItemClass, attackerItemSkin);

		Left4Timers.AddTimer(null, 0.3, ::Left4Bots.ItemGiven.bindenv(::Left4Bots), { player1 = attacker, item = attackerItem, player2 = victim });

		if (IsPlayerABot(victim))
			LastGiveItemTime = Time();
	}
	else if (victimItem && IsPlayerABot(victim))
	{
		// Swap

		local lvl = Left4Users.GetOnlineUserLevel(attacker.GetPlayerUserId());
		if (lvl >= Settings.userlevel_give_others)
		{
			local victimItemClass = victimItem.GetClassname();
			local victimItemSkin = NetProps.GetPropInt(victimItem, "m_nSkin");

			if (victimItemClass != attackerItemClass || victimItemSkin != attackerItemSkin)
			{
				DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, attacker);
				DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, victim);

				GiveItemIndex1 = attackerItem.GetEntityIndex();
				GiveItemIndex2 = victimItem.GetEntityIndex();

				attacker.DropItem(attackerItemClass);
				victim.DropItem(victimItemClass);

				//Left4Utils.GiveItemWithSkin(attacker, victimItemClass, victimItemSkin);
				//Left4Utils.GiveItemWithSkin(victim, attackerItemClass, attackerItemSkin);

				Left4Timers.AddTimer(null, 0.3, ::Left4Bots.ItemSwapped.bindenv(::Left4Bots), { item1 = victimItem, player1 = attacker, item2 = attackerItem, player2 = victim, });
			}
		}
	}
}

::Left4Bots.OnPlayerUse <- function (player, entity, minCount = 0)
{
	if (Settings.signal_max_distance <= 0 || !IsPlayerABot(player))
		return;

	switch (entity.GetClassname())
	{
		case "weapon_ammo_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedAmmo(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "Ammo", "Ammo here!");

			break;
		}

		/* better handled in default:
		case "weapon_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedWeapon(player, NetProps.GetPropInt(entity, "m_weaponID"), Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotOtherWeapon", null, "Weapons here!");

			break;
		}
		*/

		case "weapon_first_aid_kit_spawn":
		{
			local other = GetOtherMedkitSpawn(entity, 100.0);
			if (other && HumansNeedMedkit(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, other, "PlayerSpotWeapon", "FirstAidKit", "Medkits here!");

			break;
		}

		case "weapon_pain_pills_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedTempMed(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "PainPills", "Pills here!");

			break;
		}

		case "weapon_adrenaline_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedTempMed(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "Adrenaline", "Adrenaline here!");

			break;
		}

		case "weapon_molotov_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedThrowable(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "Molotov", "Molotovs here!");

			break;
		}

		case "weapon_pipe_bomb_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedThrowable(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "PipeBomb", "Pipe bombs here!");

			break;
		}

		case "weapon_vomitjar_spawn":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedThrowable(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "VomitJar", "Bile jars here!");

			break;
		}

		case "upgrade_ammo_incendiary":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedUpgradeAmmo(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "UpgradePack_Incendiary", "Incendiary ammo here!");

			break;
		}

		case "upgrade_ammo_explosive":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedUpgradeAmmo(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "UpgradePack_Explosive", "Explosive ammo here!");

			break;
		}

		case "upgrade_laser_sight":
		{
			if (SpawnerHasItems(entity, minCount) && HumansNeedLaserSight(player, Settings.signal_min_distance, Settings.signal_max_distance))
				DoSignal(player, entity, "PlayerSpotWeapon", "LaserSights", "Laser sights here!");

			break;
		}

		default:
		{
			if (entity.GetClassname().find("weapon_") != null && entity.GetClassname().find("_spawn") != null)
			{
				if (SpawnerHasItems(entity, minCount) && HumansNeedWeapon(player, NetProps.GetPropInt(entity, "m_weaponID"), Settings.signal_min_distance, Settings.signal_max_distance))
					DoSignal(player, entity, "PlayerSpotOtherWeapon", null, "Weapons here!");
			}
		}
	}
}

// There is at least 1 tank alive
::Left4Bots.OnTankActive <- function ()
{
	Logger.Debug("OnTankActive");

	// Settings
	foreach (key, val in OnTankSettings)
	{
		OnTankSettingsBak[key] <- Settings[key];
		Settings[key] <- val;

		Logger.Debug("Changing setting " + key + " to " + val);
	}

	// Convars
	foreach (key, val in OnTankCvars)
	{
		OnTankCvarsBak[key] <- Convars.GetStr(key);
		Convars.SetValue(key, val);

		Logger.Debug("Changing convar " + key + " to " + val);
	}
}

// Last tank alive is dead
::Left4Bots.OnTankGone <- function ()
{
	Logger.Debug("OnTankGone");

	// Settings
	foreach (key, val in OnTankSettingsBak)
	{
		Settings[key] <- val;

		Logger.Debug("Changing setting " + key + " back to " + val);
	}
	OnTankSettingsBak.clear();

	// Convars
	foreach (key, val in OnTankCvarsBak)
	{
		Convars.SetValue(key, val);

		Logger.Debug("Changing convar " + key + " back to " + val);
	}
	OnTankCvarsBak.clear();
}

// Removes invalid entities from the Survivors, Bots, Tanks and Deads lists
::Left4Bots.OnCleaner <- function (params)
{
	// Survivors
	foreach (id, survivor in Survivors)
	{
		if (!survivor || !survivor.IsValid())
		{
			delete Survivors[id];
			Logger.Debug("Removed an invalid survivor from Survivors");
		}
	}

	// Bots
	foreach (id, bot in Bots)
	{
		if (!bot || !bot.IsValid())
		{
			delete Bots[id];
			Logger.Debug("Removed an invalid bot from Bots");
		}
	}

	// Deads
	foreach (chr, dead in Deads)
	{
		if (!dead.dmodel || !dead.dmodel.IsValid())
		{
			delete Deads[chr];
			Logger.Debug("Removed an invalid death model from Deads");
		}
	}

	// Specials
	foreach (id, special in Specials)
	{
		if (!special || !special.IsValid())
		{
			delete Specials[id];
			Logger.Debug("Removed an invalid special from Specials");
		}
	}

	// Tanks
	foreach (id, tank in Tanks)
	{
		if (!tank || !tank.IsValid())
		{
			delete Tanks[id];
			Logger.Debug("Removed an invalid tank from Tanks");

			if (Tanks.len() == 0)
				OnTankGone();
		}
	}

	// Witches
	foreach (id, witch in Witches)
	{
		if (!witch || !witch.IsValid())
		{
			delete Witches[id];
			Logger.Debug("Removed an invalid witch from Witches");
		}
	}

	// Extra L4D2 Survivors
	foreach (id, surv in L4D1Survivors)
	{
		if (!surv || !surv.IsValid())
		{
			delete L4D1Survivors[id];
			Logger.Debug("Removed an invalid L4D1 survivor from L4D1Survivors");
		}
	}

	// Survivor flow
	foreach (id, v in SurvivorFlow)
	{
		if (!(id in Survivors) && !(id in L4D1Survivors))
		{
			delete SurvivorFlow[id];
			Logger.Debug("Removed an invalid survivor from SurvivorFlow");
		}
	}

	// Vocalizer bot selections
	foreach (id, sel in VocalizerBotSelection)
	{
		if ((Time() - sel.time) > Settings.vocalize_botselect_timeout || !sel.bot || !sel.bot.IsValid())
		{
			delete VocalizerBotSelection[id];
			Logger.Debug("Removed an invalid vocalizer bot selection from VocalizerBotSelection");
		}
	}
}

// Tells the bots which items to pick up based on the current team situation
::Left4Bots.OnInventoryManager <- function (params)
{
	// First count how many medkits, defibs, chainsaws and throwables we already have in the team
	TeamShotguns = 0;
	TeamChainsaws = 0;
	TeamMelee = 0;
	TeamMolotovs = 0;
	TeamPipeBombs = 0;
	TeamVomitJars = 0;
	TeamMedkits = 0;
	TeamDefibs = 0;

	foreach (surv in Survivors)
	{
		if (surv.IsValid())
		{
			local inv = {};
			GetInvTable(surv, inv);

			// Strings are a char array -- start the classname search at index 5, which is after "weapon", and the search should go by quicker.
			TeamShotguns += (INV_SLOT_PRIMARY in inv && inv[INV_SLOT_PRIMARY].GetClassname().find("shotgun", 5) != null).tointeger();

			if (INV_SLOT_SECONDARY in inv)
			{
				local cls = inv[INV_SLOT_SECONDARY].GetClassname();

				TeamChainsaws += (cls == "weapon_chainsaw").tointeger();
				TeamMelee += (cls == "weapon_melee").tointeger();
			}

			if (INV_SLOT_THROW in inv)
			{
				local cls = inv[INV_SLOT_THROW].GetClassname();

				TeamMolotovs += (cls == "weapon_molotov").tointeger();
				TeamPipeBombs += (cls == "weapon_pipe_bomb").tointeger();
				TeamVomitJars += (cls == "weapon_vomitjar").tointeger();
			}

			if (INV_SLOT_MEDKIT in inv)
			{
				local cls = inv[INV_SLOT_MEDKIT].GetClassname();

				TeamMedkits += (cls == "weapon_first_aid_kit").tointeger();
				TeamDefibs += (cls == "weapon_defibrillator").tointeger();
			}
		}
	}

	//Logger.Debug("OnInventoryManager - TeamShotguns: " + TeamShotguns + " - TeamChainsaws: " + TeamChainsaws + " - TeamMelee: " + TeamMelee);
	//Logger.Debug("OnInventoryManager - TeamMolotovs: " + TeamMolotovs + " - TeamPipeBombs: " + TeamPipeBombs + " - TeamVomitJars: " + TeamVomitJars);
	//Logger.Debug("OnInventoryManager - TeamMedkits: " + TeamMedkits + " - TeamDefibs: " + TeamDefibs);

	// Then decide what we need
	foreach (bot in Bots)
	{
		if (bot.IsValid())
			bot.GetScriptScope().BotUpdatePickupToSearch();
	}

	foreach (bot in L4D1Survivors)
	{
		if (bot.IsValid())
			bot.GetScriptScope().BotUpdatePickupToSearch();
	}
}

// Does various stuff
::Left4Bots.OnThinker <- function (params)
{
	// Listen for human survivors BUTTON_SHOVE press
	foreach (surv in Survivors)
	{
		if (surv.IsValid())
		{
			local userid = surv.GetPlayerUserId();
			
			SurvivorFlow[userid].inCheckpoint = IsSurvivorInCheckpoint(surv);
			SurvivorFlow[userid].flow = GetCurrentFlowDistanceForPlayer(surv);
			
			if (SurvivorFlow[userid].isBot)
				continue;
			
			if ((surv.GetButtonMask() & BUTTON_SHOVE) != 0 || (NetProps.GetPropInt(surv, "m_afButtonPressed") & BUTTON_SHOVE) != 0) // <- With med items (pills and adrenaline) the shove button is disabled when looking at teammates and GetButtonMask never sees the button down but m_afButtonPressed still does
			{
				if (!(userid in BtnStatus_Shove) || !BtnStatus_Shove[userid])
				{
					Logger.Debug(surv.GetPlayerName() + " BUTTON_SHOVE");

					BtnStatus_Shove[userid] <- true;

					if (Settings.give_humans_nades || Settings.give_humans_meds)
						Left4Timers.AddTimer(null, 0.0, ::Left4Bots.OnShovePressed.bindenv(::Left4Bots), { player = surv });
				}
				continue;
			}
			BtnStatus_Shove[userid] <- false;
		}
	}

	// Attach our think function to newly spawned tank rocks
	if (Settings.dodge_rock || Settings.shoot_rock)
	{
		local ent = null;
		while (ent = Entities.FindByClassname(ent, "tank_rock"))
		{
			if (ent.IsValid())
			{
				ent.ValidateScriptScope();
				local scope = ent.GetScriptScope();
				if (!("L4B_RockThink" in scope))
				{
					scope.DodgingBots <- {};
					scope["L4B_RockThink"] <- L4B_RockThink;
					AddThinkToEnt(ent, "L4B_RockThink");

					Logger.Debug("New tank rock: " + ent.GetEntityIndex());
				}
			}
		}
	}

	if (Settings.automation_debug)
		RefreshAutomationDebugHudText();
	
	if (Settings.orders_debug)
		RefreshOrdersDebugHudText();
}

// -----

::Left4Bots.HandleCommand <- function (player, cmd, args, text)
{
	if (!player || !player.IsValid() || IsPlayerABot(player) || Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < Settings.userlevel_orders)
		return;

	if (cmd != "botselect" && cmd != "settings" && cmd != "findsettings" && cmd != "help" && cmd != "reloadweapons" && args.len() < 3) // Normal bot commands have at least 2 arguments (excluding 'l4b')
		return;

	local arg2 = null;
	if (args.len() > 2)
		arg2 = strip(args[2].tolower());

	local arg3 = null;
	if (args.len() > 3)
		arg3 = strip(args[3]);

	OnUserCommand(player, cmd, arg2, arg3);
}

/* Handle user commands

<botsource> command [parameter]

<botsource> can be:
- bot (the bot is automatically selected)
- bots (all the bots)
- botname (name of the bot)

Available commands:
	<botsource> lead			: The order is added to the given bot(s) orders queue. The bot(s) will start leading the way following the map's flow
	<botsource> follow			: The order is added to the given bot(s) orders queue. The bot(s) will start following you
	<botsource> follow <target>	: The order is added to the given bot(s) orders queue. The bot(s) will follow the given target survivor (you can also use the keyword "me" to follow you)
	<botsource> witch			: The order is added to the given bot(s) orders queue. The bot(s) will try to kill the witch you are looking at
	<botsource> heal			: The order is added to the given bot(s) orders queue. The bot(s) will heal himself/themselves
	<botsource> heal <target>	: The order is added to the given bot(s) orders queue. The bot(s) will heal the target survivor (target can also be the bot himself or the keyword "me" to heal you)
	<botsource> goto			: The order is added to the given bot(s) orders queue. The bot(s) will go to the location you are looking at
	<botsource> goto <target>	: The order is added to the given bot(s) orders queue. The bot(s) will go to the current target's position (target can be another survivor or the keyword "me" to come to you)
	<botsource> come			: The order is added to the given bot(s) orders queue. The bot(s) will come to your current location (alias of "<botsource> goto me")
	<botsource> wait			: The order is added to the given bot(s) orders queue. The bot(s) will hold his/their current position
	<botsource> wait here		: The order is added to the given bot(s) orders queue. The bot(s) will hold position at your current position
	<botsource> wait there		: The order is added to the given bot(s) orders queue. The bot(s) will hold position at the location you are looking at
	<botsource> use				: The order is added to the given bot(s) orders queue. The bot(s) will use the entity (pickup item / press button etc.) you are looking at
	<botsource> carry			: The order is added to the given bot(s) orders queue. The bot(s) will pick and hold the carriable item (gnome, gascan, cola, etc.) you are looking at
	<botsource> deploy			: The order is added to the given bot(s) orders queue or executed immediately. The bot(s) will go pick the deployable item (ammo upgrade packs) you are looking at and deploy it immediately. If you aren't looking at any item and the bot already has a deployable item in his inventory, he will deploy that item immediately
	<botsource> usereset		: The order is executed immediately. The bot(s) will stop using the weapons picked up via "use" order and will go back to its weapon preferences / team weapon rules
	<botsource> warp			: The order is executed immediately. The bot(s) will teleport to your position. If "bot" botsource is used, the selected bot will be the bot you are looking at
	<botsource> warp here		: The order is executed immediately. The bot(s) will teleport to your position. If "bot" botsource is used, the selected bot will be the bot you are looking at
	<botsource> warp there		: The order is executed immediately. The bot(s) will teleport to the location you are looking at. If "bot" botsource is used, the selected bot will be the bot you are looking at
	<botsource> warp move		: The order is executed immediately. The bot(s) will teleport to the current MOVE location (if any). If "bot" botsource is used, the selected bot will be the bot you are looking at
	<botsource> give			: The order is executed immediately. The bot will give you one item from their pills/throwable/medkit inventory slot if your slot is emtpy. "bot" and "bots" botsources are the same here, the first available bot is selected
	<botsource> swap			: The order is executed immediately. You will swap the item you are holding (only for items from the pills/throwable/medkit inventory slots) with the selected bot. "bot" and "bots" botsources will both select the bot you are looking at
	<botsource> tempheal		: The order is executed immediately. The bot(s) will use their pain pils/adrenaline. If "bot" botsource is used, the selected bot will be the bot you are looking at
	<botsource> throw [item]	: The order is executed immediately. The bot(s) will throw their throwable item to the location you are looking at. The bot(s) must have the given [item] type (or any throwable item if [item] is not supplied)
	<botsource> scavenge		: The order is added to the given bot(s) orders queue. The bot(s) will scavenge the item you are looking at (gascan, cola bottles) if a pour target is active. You can give this order to any bot, including the ones that aren't already scavenging automatically
	<botsource> scavenge start	: Starts the scavenge process. The botsource parameter is ignored, the scavenge bot(s) are always selected automatically
	<botsource> scavenge stop	: Stops the scavenge process. The botsource parameter is ignored, the scavenge bot(s) are always selected automatically
	<botsource> hurry			: The order is executed immediately. The bot(s) L4B2 AI will stop doing anything for 'hurry_time' seconds. Basically they will cancel any pending action/order and ignore pickups, defibs, throws etc. for that amount of time
	<botsource> die				: The order is executed immediately. The bot(s) will die. If "bot" botsource is used, the selected bot will be the bot you are looking at. NOTE: only the admins can use this command
	<botsource> pause			: The order is executed immediately. The bot(s) will be forced to start a pause. If "bot" botsource is used, the selected bot will be the bot you are looking at. NOTE: only the admins can use this command
	<botsource> dump			: The order is executed immediately. The bot(s) will print all their L4B2 AI data to the console. If "bot" botsource is used, the selected bot will be the bot you are looking at. NOTE: only the admins can use this command
	<botsource> move			: Alias of "<botsource> cancel all" (see below)


<botsource> cancel [switch]

<botsource> can be:
- bots (all the bots)
- botname (name of the bot)
("bot" botsource is not allowed here)

Available switches:
	current		: The given bot(s) will abort his/their current order and will proceed with the next one in the queue (if any)
	ordertype	: The given bot(s) will abort all his/their orders (current and queued ones) of type 'ordertype' (example: coach cancel lead)
	orders		: The given bot(s) will abort all his/their orders (current and queued ones) of any type
	defib		: The given bot(s) will abort any pending defib task. "botname cancel defib" is temporary (the bot will retry). "bots cancel defib" is permanent (currently dead survivors will be abandoned)
	all			: (or empty) The given bot(s) will abort everything (orders, defib, current pick-up, anything)


botselect [botname]

Selects the given bot as the destination of the next vocalizer command. If "botname" is omitted, the closest bot to your crosshair will be selected


settings

// TODO

*/
::Left4Bots.OnUserCommand <- function (player, arg1, arg2, arg3)
{
	local function GetFormattedCommandList(cmdArray)
	{
		local ret = "";
		for (local i = 0; i < cmdArray.len(); i++)
		{
			if (i == 0)
				ret += PRINTCOLOR_CYAN + cmdArray[i] + PRINTCOLOR_NORMAL;
			else
				ret += ", " + PRINTCOLOR_CYAN + cmdArray[i] + PRINTCOLOR_NORMAL;
		}
		return ret;
	}
	
	Logger.Debug("OnUserCommand - player: " + player.GetPlayerName() + " - arg1: " + arg1 + " - arg2: " + arg2 + " - arg3: " + arg3);

	switch (arg1)
	{
		case "botselect":
			local tgtBot = null;
			if (arg2)
				tgtBot = GetBotByName(arg2);
			else
				tgtBot = GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

			if (!tgtBot)
				return false; // Invalid target

			player.SetContext("subject", Left4Utils.GetActorFromSurvivor(tgtBot), 0.1);
			player.SetContext("subjectid", tgtBot.GetPlayerUserId().tostring(), 0.1);
			player.SetContext("smartlooktype", "manual", 0.1);
			//DoEntFire("!self", "AddContext", "subject:" + Left4Utils.GetActorFromSurvivor(tgtBot), 0, null, player);
			DoEntFire("!self", "SpeakResponseConcept", "PlayerLook", 0, null, player);
			//DoEntFire("!self", "ClearContext", "", 0, null, player);
			
			break;
		
		case "settings":
			if (Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < L4U_LEVEL.Admin)
				return false; // Only admins can change the settings

			if (arg2 in Settings)
			{
				if (!arg3)
					ClientPrint(player, 3, PRINTCOLOR_NORMAL + "Current value for " + arg2 + ": " + Settings[arg2]);
				else
				{
					try
					{
						//Settings[arg2] <- arg3;  // <- this converts any value to string
						local compiledscript = compilestring("::Left4Bots.Settings." + arg2 + " <- " + arg3);
						compiledscript();

						if (arg2 in OnTankSettingsBak)
							OnTankSettingsBak[arg2] <- Settings[arg2];

						// Probably not the best way to do this but at least we aren't saving the settings override to the settings.txt file and we don't need to worry about the OnTankSettings
						SettingsTmp <- {};
						Left4Utils.LoadSettingsFromFileNew("left4bots2/cfg/settings.txt", "::Left4Bots.SettingsTmp.", Logger, true);
						SettingsTmp[arg2] <- Settings[arg2];
						Left4Utils.SaveSettingsToFileNew("left4bots2/cfg/settings.txt", SettingsTmp, Logger);

						// Maybe we can just keep this in memory and avoid to reload it every time?
						delete SettingsTmp;

						if (arg2 == "loglevel")
							Logger.LogLevel(Settings.loglevel);
						else if (arg2 == "should_hurry")
							DirectorScript.GetDirectorOptions().cm_ShouldHurry <- Settings.should_hurry;
						else if (arg2 == "automation_debug")
						{
							local name = "l4b2automation";
							Left4Hud.HideHud(name);
							Left4Hud.RemoveHud(name);
							if (Settings.automation_debug)
							{
								Left4Hud.AddHud(name, g_ModeScript["HUD_TICKER"], g_ModeScript.HUD_FLAG_NOTVISIBLE | g_ModeScript.HUD_FLAG_ALIGN_LEFT);
								Left4Hud.PlaceHud(name, 0.01, 0.15, 0.8, 0.05);
								Left4Hud.ShowHud(name);
							}
						}
						else if (arg2 == "orders_debug")
						{
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
						}

						ClientPrint(player, 3, PRINTCOLOR_GREEN + "Value of setting " + arg2 + " changed to: " + Settings[arg2]);
					}
					catch(exception)
					{
						Logger.Error("Error changing value of setting: " + arg2 + " - new value: " + arg3 + " - error: " + exception);
						ClientPrint(player, 3, PRINTCOLOR_ORANGE + "Error changing value of setting " + arg2);
					}
				}
			}
			else
				ClientPrint(player, 3, PRINTCOLOR_ORANGE + "Invalid setting: " + arg2);
			
			break;
		
		case "findsettings":
			if (Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < L4U_LEVEL.Admin)
				return false; // Only admins can change the settings

			if (!arg2 || arg2 == "")
				ClientPrint(player, 3, PRINTCOLOR_ORANGE + "Invalid search term");
			else
			{
				local found = "";
				foreach (k, v in Settings)
				{
					if (k.find(arg2) != null)
					{
						if (found == "")
							found = k;
						else
							found += ", " + k;
					}
				}
				
				if (found == "")
					ClientPrint(player, 3, PRINTCOLOR_ORANGE + "No settings found");
				else
					ClientPrint(player, 3, PRINTCOLOR_GREEN + "Settings: " + found); // TODO: should split the text if too long
			}
			
			break;
		
		case "help":
			if (arg2)
			{
				local adminCommand = AdminCommands.find(arg2) != null;
				if (adminCommand || UserCommands.find(arg2) != null)
				{
					if (adminCommand && Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < L4U_LEVEL.Admin)
					{
						ClientPrint(player, 3, PRINTCOLOR_ORANGE + "You don't have access to that command");
						return false; // Not an admin
					}
					
					local helpTxt = Left4Bots["CmdHelp_" + arg2]();
					local helpLines = split(helpTxt, "\n");
					for (local i = 0; i < helpLines.len(); i++)
						ClientPrint(player, 3, helpLines[i]);
				}
				else
					ClientPrint(player, 3, PRINTCOLOR_ORANGE + "Command not found: " + arg2);
			}
			else
			{
				if (Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) >= L4U_LEVEL.Admin)
					ClientPrint(player, 3, PRINTCOLOR_GREEN + "Admin Commands" + PRINTCOLOR_NORMAL + ": " + GetFormattedCommandList(AdminCommands));
				ClientPrint(player, 3, PRINTCOLOR_GREEN + "User Commands" + PRINTCOLOR_NORMAL + ": " + GetFormattedCommandList(UserCommands));
				ClientPrint(player, 3, PRINTCOLOR_NORMAL + "Type: '" + PRINTCOLOR_GREEN + "!l4b help " + PRINTCOLOR_CYAN + "command" + PRINTCOLOR_NORMAL + "' for more info on a specific command");
			}
			
			break;
		
		case "reloadweapons":
			if (Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < L4U_LEVEL.Admin)
				return false; // Only admins can use this command

			local sw = (arg2 && arg2 != "") ? arg2.tolower() : "all";
			local c = 0;
			foreach (bot in Bots)
			{
				if (sw == "all" || bot.GetPlayerName().tolower() == sw)
				{
					LoadWeaponPreferences(bot, bot.GetScriptScope());
					c++;
				}
			}
			foreach (bot in L4D1Survivors)
			{
				if (sw == "all" || bot.GetPlayerName().tolower() == sw)
				{
					LoadWeaponPreferences(bot, bot.GetScriptScope());
					c++;
				}
			}
			ClientPrint(player, 3, PRINTCOLOR_GREEN + "Weapons reloaded for " + c + " bot(s)");
		
			break;
		
		default:
			// normal bot commands

			local allBots = false;	// true = "bots" keyword was used, tgtBot is ignored (will be null)
			local tgtBot = null;	// (allBots = false) null = "bot" keyword was used, tgtBot will be automatically selected - not null = "[botname]" was used, tgtBot is the selected bot

			if (arg1 == "bots")
				allBots = true;
			else if (arg1 != "bot")
			{
				tgtBot = GetBotByName(arg1);
				if (!tgtBot)
					return false; // Invalid target
			}

			local adminCommand = AdminCommands.find(arg2) != null;
			if (!adminCommand && UserCommands.find(arg2) == null)
				return false; // Not a bot command
				
			if (adminCommand && Left4Users.GetOnlineUserLevel(player.GetPlayerUserId()) < L4U_LEVEL.Admin)
				return false; // Not an admin
				
			// Call the cmd function (Cmd_command)
			Left4Bots["Cmd_" + arg2](player, allBots, tgtBot, arg3);
			
			break;
	}

	return true;
}

// -----

::Left4Bots.OnConcept <- function (concept, query)
{
	if (!ModeStarted && "gamemode" in query)
	{
		ModeStarted = true;
		OnModeStart();
	}

	if (concept == "PlayerExertionMinor" || concept.find("VSLib") != null)
		return;

	local who = null;
	if ("userid" in query)
		who = g_MapScript.GetPlayerFromUserID(query.userid.tointeger());
	else if ("who" in query)
		who = GetSurvivorFromActor(query.who);
	else if ("Who" in query)
		who = GetSurvivorFromActor(query.Who);

	local subjectid = null;
	if ("subjectid" in query)
		subjectid = query.subjectid.tointeger();
	
	local subject = null;
	if ("subject" in query)
		subject = query.subject;
	else if ("Subject" in query)
		subject = query.Subject;

	if (Settings.automation_debug)
	{
		if (who && who.IsValid() && "GetPlayerName" in who)
			::Left4Users.AdminNotice("[" + concept + "] " + who.GetPlayerName() + " -> " + subject);
		else
			::Left4Users.AdminNotice("[" + concept + "] " + who + " -> " + subject);
	}

	Automation.OnConcept(who, subject, concept, query);

	if (!who || !who.IsValid())
	{
		Logger.Debug("OnConcept(" + concept + ") - who: none (" + who + ")");
		return;
	}
	
	//Logger.Debug("OnConcept(" + concept + ") - who: " + who.GetPlayerName() + " - subjectid: " + subjectid + " - subject: " + subject);

	local isHandledBot = IsHandledBot(who);
	if (isHandledBot || IsHandledL4D1Bot(who)) // Both Main and L4D1 bots
	{
		// WHO is a bot

		switch (concept)
		{
			case "TLK_IDLE":
			case "SurvivorBotNoteHumanAttention":
			case "SurvivorBotHasRegroupedWithTeam":
				if (isHandledBot && Settings.deploy_upgrades) // Only Main bots
				{
					local itemClass = ShouldDeployUpgrades(who, query);
					if (itemClass)
					{
						Logger.Debug("Bot " + who.GetPlayerName() + " switching to upgrade " + itemClass);
						
						who.SwitchToItem(itemClass);
						
						Left4Timers.AddTimer(null, 1, @(params) ::Left4Bots.DoDeployUpgrade.bindenv(::Left4Bots)(params.player), { player = who });
					}
				}
				
				break;
			
			case "SurvivorBotEscapingFlames":
				local scope = who.GetScriptScope();
				if (scope.CanReset)
				{
					scope.CanReset = false; // Do not send RESET commands to the bot if the bot is trying to escape from the fire or the spitter's spit or it will get stuck there

					Logger.Debug("Bot " + who.GetPlayerName() + " CanReset = false");
				}
				
				break;
			
			case "SurvivorBotHasEscapedSpit":
			case "SurvivorBotHasEscapedFlames":
				local scope = who.GetScriptScope();
				if (!scope.CanReset)
				{
					scope.CanReset = true; // Now we can safely send RESET commands again

					Logger.Debug("Bot " + who.GetPlayerName() + " CanReset = true");

					// Delayed resets are executed as soon as we can reset again
					if (scope.DelayedReset)
						Left4Timers.AddTimer(null, 0.01, @(params) params.scope.BotReset(true), { scope = scope });
						//scope.BotReset(true); // Apparently, sending a RESET command to the bot from this OnConcept, makes the game crash
				}

				// Bot's vanilla escape flames/spit algorithm interfered with any previous MOVE so the MOVE must be refreshed
				if (scope.MovePos && scope.NeedMove <= 0)
					scope.NeedMove = 2;
				
				break;
			
			case "SurvivorBotRegroupWithTeam":
				local scope = who.GetScriptScope();
				if (!scope.CanReset)
				{
					scope.CanReset = true; // Now we can safely send RESET commands again

					Logger.Debug("Bot " + who.GetPlayerName() + " CanReset = true");

					// Delayed resets are executed as soon as we can reset again
					if (scope.DelayedReset)
						Left4Timers.AddTimer(null, 0.01, @(params) params.scope.BotReset(true), { scope = scope });
						//scope.BotReset(true); // Apparently, sending a RESET command to the bot from this OnConcept, makes the game crash
				}

				// Receiving this concept from a bot who is executing a move command means that the bot got nav stuck and teleported somewhere.
				// After the teleport the move command is lost and needs to be refreshed.
				if (scope.MovePos && scope.NeedMove <= 0 && !scope.Paused)
					scope.NeedMove = 2;
				
				break;
			
			case "PlayerGetToRescueVehicle":
				/* TODO?
				if (!who.IsIncapacitated() && (Time() - LastNadeTime) >= THROW_NADE_MININTERVAL && RandomInt(1, 100) <= THROW_NADE_CHANCE)
				{
					local item = Left4Utils.GetInventoryItemInSlot(who, INV_SLOT_THROW);
					if (item && ((Settings.throw_pipe_bomb && item.GetClassname() == "weapon_pipe_bomb") || (Settings.throw_vomitjar && item.GetClassname() == "weapon_vomitjar")))
					{
						local pos = Left4Utils.BotGetFarthestPathablePos(who, THROW_NADE_RADIUS);
						if (pos && (pos - who.GetOrigin()).Length() >= THROW_NADE_MIN_DISTANCE)
							BotThrowNade(who, item.GetClassname(), pos, THROW_NADE_DELTAPITCH);
					}
				}
				*/
				
				// TODO: hurry
				
				break;
			
			// ...
		}
	}
	else
	{
		// WHO is a human

		if (concept == "OfferItem")
		{
			if (subjectid != null)
				subject = g_MapScript.GetPlayerFromUserID(subjectid);
			else if (subject)
				subject = GetSurvivorFromActor(subject);

			if (subject && subject.IsValid() && IsPlayerABot(subject))
				LastGiveItemTime = Time();

			return;
		}

		local lvl = Left4Users.GetOnlineUserLevel(who.GetPlayerUserId());

		if (Settings.vocalizer_commands && lvl >= Settings.userlevel_orders)
		{
			if (concept == "PlayerLook" || concept == "PlayerLookHere")
			{	
				//lxc filter automatically triggered "Look" vocalizer
				// "smartlooktype = auto|manual"
				if ("smartlooktype" in query && query.smartlooktype == "manual")
				{
					//printl("smartlooktype" + " = " + query.smartlooktype);
					
					// Bot selection
					if (subjectid != null)
						subject = g_MapScript.GetPlayerFromUserID(subjectid);
					else if (subject)
					{
						//lxc
						// "m_vocalizationSubject" will updated at the same time as the vocalizer fires if someone in my vision.
						// "subject" and "m_vocalizationSubject" are not always the same, but "m_vocalizationSubject" is definitely what we are looking at within 400 radius.
						if ((NetProps.GetPropFloat(who, "m_vocalizationSubjectTimer.m_timestamp") - NetProps.GetPropFloat(who, "m_vocalizationSubjectTimer.m_duration")) == Time())
						{
							subject = NetProps.GetPropEntity(who, "m_vocalizationSubject");
							//printl(subject.GetPlayerName());
						}
						else
							subject = GetSurvivorFromActor(subject);
					}

					if (IsHandledBot(subject))
					{
						VocalizerBotSelection[who.GetPlayerUserId()] <- { bot = subject, time = Time() };

						Logger.Debug(who.GetPlayerName() + " selected bot " + subject.GetPlayerName());
					}
				}
			}
			else if (concept in VocalizerCommands)
			{
				local cmd = VocalizerCommands[concept].all;
				local userid = who.GetPlayerUserId();
				if ((userid in VocalizerBotSelection) && (Time() - VocalizerBotSelection[userid].time) <= Settings.vocalize_botselect_timeout && VocalizerBotSelection[userid].bot && VocalizerBotSelection[userid].bot.IsValid())
				{
					local botname = VocalizerBotSelection[userid].bot.GetPlayerName().tolower();
					cmd = Left4Utils.StringReplace(VocalizerCommands[concept].one, "botname ", botname + " ");
					
					//lxc should be deleted here, otherwise, vocalizer command cannot be used on other bots until it times out or use "PlayerLook" again.
					delete VocalizerBotSelection[userid];
				}
				cmd = "!l4b " + cmd;
				local args = split(cmd, " ");
				HandleCommand(who, args[1], args, cmd);
			}
		}

		if (lvl >= Settings.userlevel_vocalizer)
		{
			switch (concept)
			{
				case "PlayerLaugh":
					foreach (bot in Bots)
					{
						if (bot.IsValid() && RandomInt(1, 100) <= Settings.vocalizer_laugh_chance)
							DoEntFire("!self", "SpeakResponseConcept", "PlayerLaugh", RandomFloat(0.5, 2), null, bot);
					}
					
					break;
				
				case "PlayerThanks":
					if (subjectid != null)
						subject = g_MapScript.GetPlayerFromUserID(subjectid);
					else if (subject)
						subject = GetSurvivorFromActor(subject);

					if (subject && IsPlayerABot(subject) && RandomInt(1, 100) <= Settings.vocalizer_youwelcome_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerYouAreWelcome", RandomFloat(1.2, 2.3), null, subject);
					
					break;
				
				case "iMT_PlayerNiceShot":
					if (RandomInt(1, 100) <= Settings.vocalizer_thanks_chance)
					{
						if (subjectid != null)
							subject = g_MapScript.GetPlayerFromUserID(subjectid);
						else if (subject)
							subject = GetSurvivorFromActor(subject);

						if (subject && IsPlayerABot(subject))
							DoEntFire("!self", "SpeakResponseConcept", "PlayerThanks", RandomFloat(1.2, 2.3), null, subject);
						else if (NiceShootSurv && NiceShootSurv.IsValid() && (Time() - NiceShootTime) <= 10.0)
							DoEntFire("!self", "SpeakResponseConcept", "PlayerThanks", RandomFloat(0.5, 2), null, NiceShootSurv);
					}
					
					break;
				
				/// ...
			}
		}
	}

	// Any who
	switch (concept)
	{
		case "PlayerChoke":
		//case "PlayerTonguePullStart": //lxc not always fire if victim is human
		case "PlayerGrabbedByTongue":
			if (Settings.smoker_shoot_tongue)
			{
				local smoker = NetProps.GetPropEntity(who, "m_tongueOwner");
				if (smoker && smoker.IsValid())
					DealWithSmoker(smoker, who, Settings.smoker_shoot_tongue_duck);
			}
			
			break;
		
		/* TODO: reimplement this?
		case "SurvivorBotHelpOverwhelmed":
			break;
		*/
		
		/* TODO
		case "PlayerPourFinished":
			local score = null;
			local towin = null;

			if ("Score" in query)
				score = query.Score.tointeger();
			if ("towin" in query)
				towin = query.towin.tointeger();

			if (score != null && towin != null)
				Logger.Info("Poured: " + score + " - Left: " + towin);

			if (ScavengeStarted && towin == 0)
			{
				Logger.Info("Scavenge complete");

				ScavengeStop();
			}
			
			break;
		*/
		
		case "PropExplosion":
			// Barricade gascans are successfully ignited, cancel any pending "destroy" order
			foreach (bot in Bots)
			{
				if (bot.IsValid())
					bot.GetScriptScope().BotCancelOrders("destroy");
			}
			
			break;
		
		case "FinalVehicleArrived": // FinalVehicleSpotted
			if (!FinalVehicleArrived)
			{
				FinalVehicleArrived = true;
				
				Logger.Debug("FinalVehicleArrived");
			}
			
			break;
		
		/// ...
	}
}

// -----

::Left4Bots.AllowTakeDamage <- function (damageTable)
{
	local victim = damageTable.Victim;
	local attacker = damageTable.Attacker;

	if (victim == null || attacker == null)
		return null;

	local attackerTeam = NetProps.GetPropInt(attacker, "m_iTeamNum");
	if (attackerTeam != TEAM_SURVIVORS && attackerTeam != TEAM_L4D1_SURVIVORS)
	{
		if (victim.IsPlayer() && NetProps.GetPropInt(victim, "m_iTeamNum") == TEAM_SURVIVORS && IsPlayerABot(victim) && "Inflictor" in damageTable && damageTable.Inflictor && damageTable.Inflictor.GetClassname() == "insect_swarm")
		{
			damageTable.DamageDone = damageTable.DamageDone * Left4Bots.Settings.spit_damage_multiplier;
			return (damageTable.DamageDone > 0);
		}
		return null;
	}

	if (!attacker.IsPlayer() || !IsPlayerABot(attacker))
		return null;

	
	local victimClass = victim.GetClassname();
	if (Left4Bots.Settings.trigger_caralarm && victimClass == "prop_car_alarm" && (victim.GetOrigin() - attacker.GetOrigin()).Length() <= 730 && (!("Inflictor" in damageTable) || !damageTable.Inflictor || damageTable.Inflictor.GetClassname() != "inferno"))
	{
		Left4Bots.TriggerCarAlarm(attacker, victim);
		return null;
	}
	
	if (victimClass == "prop_physics" || victimClass.find("weapon_") != null)
	{
		local isBarricadeGascans = victim.GetModelName() == "models/props_unique/wooden_barricade_gascans.mdl";
		if ((Left4Bots.Settings.damage_barricade && isBarricadeGascans) || (Left4Bots.Settings.damage_other && !isBarricadeGascans))
		{
			victim.TakeDamageEx(attacker, attacker.GetActiveWeapon(), damageTable.Weapon, Vector(0,0,0), damageTable.Location, damageTable.DamageDone, damageTable.DamageType);
			return false;
		}
	}

	if (!victim.IsPlayer() || attacker.GetPlayerUserId() == victim.GetPlayerUserId() || NetProps.GetPropInt(victim, "m_iTeamNum") != TEAM_SURVIVORS)
		return null;

	if (Left4Bots.Settings.jockey_redirect_damage == 0)
		return null;

	// TODO filter the weapon (damageTable.Weapon) ?

	local jockey = NetProps.GetPropEntity(victim, "m_jockeyAttacker");
	if (!jockey || !jockey.IsValid())
		return null;

	//Left4Bots.Logger.Debug("AllowTakeDamage - attacker: " + attacker.GetPlayerName() + " - victim: " + victim.GetPlayerName() + " - damage: " + damageTable.DamageDone + " - type: " + damageTable.DamageType + " - weapon: " + damageTable.Weapon);

	jockey.TakeDamage(Left4Bots.Settings.jockey_redirect_damage, damageTable.DamageType, attacker);

	return false;
}
