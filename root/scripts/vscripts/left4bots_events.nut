//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

Msg("Including left4bots_events...\n");

const ALLOW_BASH_ALL = 0;
const ALLOW_BASH_PUSHONLY = 1;
const ALLOW_BASH_NONE = 2;

::Left4Bots.Events.OnGameEvent_round_start <- function (params)
{
	Left4Bots.OnRoundStart(params);
}

::Left4Bots.Events.OnGameEvent_scavenge_round_start <- function (params)
{
	local round = params["round"];
	local firsthalf = params["firsthalf"];
	
	Left4Bots.OnScavengeRoundStart(round, firsthalf, params);
}

::Left4Bots.Events.OnGameEvent_versus_round_start <- function (params)
{
	Left4Bots.OnVersusRoundStart(params);
}

::Left4Bots.Events.OnGameEvent_round_end <- function (params)
{
	local winner = params["winner"];
	local reason = params["reason"];
	local message = params["message"];
	local time = params["time"];
	
	Left4Bots.OnRoundEnd(winner, reason, message, time, params);
}

::Left4Bots.Events.OnGameEvent_map_transition <- function (params)
{
	Left4Bots.OnMapTransition(params);
}

::Left4Bots.Events.OnGameEvent_heal_begin <- function (params)
{
	local healer = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local healee = g_MapScript.GetPlayerFromUserID(params["subject"]);

	Left4Bots.OnHealStart(healer, healee, params);
}

::Left4Bots.Events.OnGameEvent_revive_begin <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	Left4Bots.OnReviveBegin(player, subject, params);
}

::Left4Bots.Events.OnGameEvent_defibrillator_begin <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	Left4Bots.OnDefibrillatorBegin(player, subject, params);
}

::Left4Bots.Events.OnGameEvent_defibrillator_used <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	Left4Bots.OnDefibrillatorUsed(player, subject, params);
}

::Left4Bots.Events.OnGameEvent_defibrillator_used_fail <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	Left4Bots.OnDefibrillatorUsedFail(player, subject, params);
}

::Left4Bots.Events.OnGameEvent_defibrillator_interrupted <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = g_MapScript.GetPlayerFromUserID(params["subject"]);

	Left4Bots.OnDefibrillatorInterrupted(player, subject, params);
}

::Left4Bots.Events.OnGameEvent_player_connect_full <- function (params)
{
	if ("userid" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
		Left4Bots.OnPlayerConnected(player, params);
	}
}

::Left4Bots.Events.OnGameEvent_player_disconnect <- function (params)
{
	if ("userid" in params)
	{
		local userid = params["userid"].tointeger();
		local player = g_MapScript.GetPlayerFromUserID(userid);
	
		Left4Bots.OnPlayerDisconnected(userid, player, params);
	}
}

::Left4Bots.Events.OnGameEvent_player_spawn <- function (params)
{
	if ("userid" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
		Left4Bots.OnPlayerSpawn(player, params);
	}
}

::Left4Bots.Events.OnGameEvent_player_incapacitated <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);

	Left4Bots.OnPlayerIncapacitated(player, params);
}

::Left4Bots.Events.OnGameEvent_player_ledge_grab <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local causer = null;
	if ("causer" in params)
		causer = g_MapScript.GetPlayerFromUserID(params["causer"]);
	
	Left4Bots.OnPlayerLedgeGrab(player, causer, params);
}

::Left4Bots.Events.OnGameEvent_player_death <- function (params)
{
	if ("userid" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
		local attacker = null;
		local attackerentid = null;
		local weapon = null;
		local abort = null;
		local type = null;
		
		if ("attacker" in params)
			attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
			
		if ("attackerentid" in params)
			attackerentid = EntIndexToHScript(params["attackerentid"]);
			
		if ("weapon" in params)
			weapon = params["weapon"];

		if ("abort" in params)
			abort = params["abort"];
			
		if ("type" in params)
			type = params["type"];
			
		Left4Bots.OnPlayerDeath(player, attacker, attackerentid, weapon, abort, type, params);
	}
}

/*
Note: Registers all playable classes (Hunter, Smoker, Boomer, Tank, Survivors). See infected_hurt for Witch and Common Infected
Name:	player_hurt
Structure:	
1	local	Not networked
short	userid	user ID who was hurt
short	attacker	user id who attacked
long	attackerentid	entity id who attacked, if attacker not a player, and userid therefore invalid
short	health	remaining health points
byte	armor	remaining armor points
string	weapon	weapon name attacker used, if not the world
short	dmg_health	damage done to health
byte	dmg_armor	damage done to armor
byte	hitgroup	hitgroup that was damaged
long	type	damage type
*/
::Left4Bots.Events.OnGameEvent_player_hurt <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
	if (!attacker && ("attackerentid" in params))
		attacker = EntIndexToHScript(params["attackerentid"]);
	
	Left4Bots.OnPlayerHurt(player, attacker, params);
}

::Left4Bots.Events.OnGameEvent_player_bot_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);
	
	Left4Bots.OnBotReplacedPlayer(player, bot, params);
}

::Left4Bots.Events.OnGameEvent_bot_player_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);
	
	Left4Bots.OnPlayerReplacedBot(player, bot, params);
}

::Left4Bots.Events.OnGameEvent_charger_charge_start <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	Left4Bots.OnChargerChargeStart(player, params);
}

::Left4Bots.Events.OnGameEvent_charger_carry_start <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);
	
	Left4Bots.OnChargerCarryStart(player, victim, params);
}

::Left4Bots.Events.OnGameEvent_tongue_grab <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);
	
	Left4Bots.OnSmokerTongueGrab(player, victim, params);
}

::Left4Bots.Events.OnGameEvent_jockey_ride <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);
	
	Left4Bots.OnJockeyRide(player, victim, params);
}

::Left4Bots.Events.OnGameEvent_lunge_pounce <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local victim = g_MapScript.GetPlayerFromUserID(params["victim"]);
	
	Left4Bots.OnHunterPounce(player, victim, params);
}

::Left4Bots.Events.OnGameEvent_spit_burst <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local subject = EntIndexToHScript(params["subject"]);

	Left4Bots.OnSpitBurst(player, subject, params);
}

::Left4Bots.Events.OnGameEvent_weapon_fire <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local weapon = params["weapon"];
	
	Left4Bots.OnWeaponFired(player, weapon, params);
}

::Left4Bots.Events.OnGameEvent_item_pickup <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	local item = params["item"];
	
	Left4Bots.OnItemPickup(player, item, params);
}

::Left4Bots.Events.OnGameEvent_player_entered_checkpoint <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!player && ("entityid" in params))
		player = EntIndexToHScript(params["entityid"]);
	local door = null;
	if ("door" in params)
		door = EntIndexToHScript(params["door"]);
	local doorname = null;
	if ("doorname" in params)
		doorname = params["doorname"];
	local area = null;
	if ("area" in params)
		area = params["area"];
	
	Left4Bots.OnPlayerEnteredCheckpoint(player, door, doorname, area, params);
}

::Left4Bots.Events.OnGameEvent_player_left_checkpoint <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!player && ("entityid" in params))
		player = EntIndexToHScript(params["entityid"]);
	local area = null;
	if ("area" in params)
		area = params["area"];		
	
	Left4Bots.OnPlayerLeftCheckpoint(player, area, params);
}

::Left4Bots.Events.OnGameEvent_friendly_fire <- function (params)
{
	local attacker = null;
	local victim = null;
	local guilty = null;
	local dmgType = null;
	
	if ("attacker" in params)
		attacker = g_MapScript.GetPlayerFromUserID(params["attacker"]);
	if ("victim" in params)
		victim = g_MapScript.GetPlayerFromUserID(params["victim"]);
	if ("guilty" in params)
		guilty = g_MapScript.GetPlayerFromUserID(params["guilty"]);
	if ("type" in params)
		dmgType = params["type"];
	
	Left4Bots.OnFriendlyFire(attacker, victim, guilty, dmgType, params);
}

::Left4Bots.Events.OnGameEvent_ability_use <- function (params)
{
	local player = 0;
	if ("userid" in params)
		player = params["userid"];
	if (player != 0)
		player = g_MapScript.GetPlayerFromUserID(player);
	else
		player = null;
	
	local ability = params["ability"];
	local context = params["context"];
	
	Left4Bots.OnAbilityUse(player, ability, context, params);
}

::Left4Bots.Events.OnGameEvent_door_close <- function (params)
{
	local player = 0;
	if ("userid" in params)
		player = params["userid"];
	if (player != 0)
		player = g_MapScript.GetPlayerFromUserID(player);
	else
		player = null;
	
	local checkpoint = params["checkpoint"];
	
	Left4Bots.OnDoorClose(player, checkpoint, params);
}

//::Left4Bots.Events.OnGameEvent_ammo_pickup <- function (params)
::Left4Bots.Events.OnGameEvent_ammo_pile_weapon_cant_use_ammo <- function (params)
{
	if ("userid" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);

		//Left4Bots.OnAmmoPickup(player, params);
		Left4Bots.OnWeaponCantUseAmmo(player, params);
	}
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
	
	Left4Bots.OnInfectedHurt(attacker, infected, damage, dmgType);
}

::Left4Bots.Events.OnGameEvent_weapon_drop <- function (params)
{
	local player = null;
	local weapon = null;
	
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
		
	if ("propid" in params)
		weapon = EntIndexToHScript(params["propid"]);
	
	Left4Bots.OnWeaponDrop(player, weapon);
}

::Left4Bots.Events.OnGameEvent_server_pre_shutdown <- function (params)
{
	local reason = params["reason"];
	
	Left4Bots.OnServerPreShutdown(reason);
}

::Left4Bots.InterceptChat <- function (msg, speaker)
{
	// Removing the ending \r\n
	if (msg.find("\n", msg.len() - 1) != null || msg.find("\r", msg.len() - 1) != null)
		msg = msg.slice(0, msg.len() - 1);
	if (msg.find("\n", msg.len() - 1) != null || msg.find("\r", msg.len() - 1) != null)
		msg = msg.slice(0, msg.len() - 1);
	
	if (!speaker)
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "Got InterceptChat with null speaker: " + msg);
		return true;
	}
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "InterceptChat - speaker: " + speaker.GetPlayerName() + " - msg: " + msg);
	
	local name = speaker.GetPlayerName() + ": ";
	local text = strip(msg.slice(msg.find(name) + name.len()));
	local args = {};
	if (text != null && text != "")
		args = split(text, " ");
	
	local isCommand = Left4Bots.OnPlayerSay(speaker, text, args, null);
	if (isCommand && !Left4Bots.Settings.show_commands)
		return false;
	else
		return true;
}

HooksHub.SetInterceptChat("L4B", ::Left4Bots.InterceptChat);

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
	
	//if (Left4Bots.Settings.trigger_caralarm && victim.GetClassname() == "prop_car_alarm" && (victim.GetOrigin() - attacker.GetOrigin()).Length() <= 730 && damageTable.DamageType != DMG_BURN && damageTable.DamageType != (DMG_BURN + DMG_PREVENT_PHYSICS_FORCE))
	if (Left4Bots.Settings.trigger_caralarm && victim.GetClassname() == "prop_car_alarm" && (victim.GetOrigin() - attacker.GetOrigin()).Length() <= 730 && (!("Inflictor" in damageTable) || !damageTable.Inflictor || damageTable.Inflictor.GetClassname() != "inferno"))
	{
		Left4Bots.TriggerCarAlarm(attacker, victim);
		return null;
	}
	
	if (!victim.IsPlayer() || attacker.GetPlayerUserId() == victim.GetPlayerUserId() || NetProps.GetPropInt(victim, "m_iTeamNum") != TEAM_SURVIVORS)
		return null;
	
	// TODO filter the weapon (damageTable.Weapon) ?
	
	local jockey = NetProps.GetPropEntity(victim, "m_jockeyAttacker");
	if (!jockey || !jockey.IsValid())
		return null;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "AllowTakeDamage - attacker: " + attacker.GetPlayerName() + " - victim: " + victim.GetPlayerName() + " - damage: " + damageTable.DamageDone + " - type: " + damageTable.DamageType + " - weapon: " + damageTable.Weapon);
	
	jockey.TakeDamage(Left4Bots.Settings.jockey_redirect_damage, damageTable.DamageType, attacker);
	
	return false;
}

HooksHub.SetAllowTakeDamage("L4B", ::Left4Bots.AllowTakeDamage);

/*
::Left4Bots.AllowBash <- function (basher, bashee)
{
	local ret = Left4Bots.OnBash(basher, bashee);
	
	if (ret == ALLOW_BASH_NONE)
		return ALLOW_BASH_NONE;
	else if (ret == ALLOW_BASH_PUSHONLY)
		return ALLOW_BASH_PUSHONLY;
	else
		return ALLOW_BASH_ALL;
}

HooksHub.SetAllowBash("L4B", ::Left4Bots.AllowBash);
*/

__CollectEventCallbacks(::Left4Bots.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
