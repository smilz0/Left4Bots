//--------------------------------------------------------------------------------------------------
//     GitHub:		https://github.com/smilz0/Left4Bots
//     Workshop:	https://steamcommunity.com/sharedfiles/filedetails/?id=3022416274
//--------------------------------------------------------------------------------------------------

Msg("Including left4bots_commands...\n");

::Left4Bots.AdminCommands <- [
	"die",
	"dump",
	"pause"
];

::Left4Bots.UserCommands <- [
	"cancel",
	"carry",
	"come",
	"deploy",
	"follow",
	"give",
	"goto",
	"heal",
	"hurry",
	"lead",
	"move",
	"scavenge",
	"swap",
	"tempheal",
	"throw",
	"use",
	"usereset",
	"wait",
	"warp",
	"witch"
];

// -- Admin commands --------------------------

::Left4Bots.Cmd_die <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_die - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (!Left4Bots.Settings.die_humans_alive && Left4Bots.Survivors.len() > Left4Bots.Bots.len())
		return; // Can't use this command with human survivors alive if "die_humans_alive" setting is 0

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Utils.KillPlayer(bot);
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

		if (tgtBot)
			Left4Utils.KillPlayer(tgtBot);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: die");
	}
}

::Left4Bots.CmdHelp_die <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "die" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will die.\n"
		 + PRINTCOLOR_NORMAL + "If '" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' botsource is used, the selected bot will be the bot you are looking at.\n"
		 + PRINTCOLOR_ORANGE + "NOTE:" + PRINTCOLOR_NORMAL + " only the admins can use this command.";
}

::Left4Bots.Cmd_dump <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_dump - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			printl(Left4Bots.BotAIToString(bot));
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

		if (tgtBot)
			printl(Left4Bots.BotAIToString(tgtBot));
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: dump");
	}
}

::Left4Bots.CmdHelp_dump <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "dump" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will print all their L4B2 AI data to the console (for debugging purposes).\n"
		 + PRINTCOLOR_NORMAL + "If '" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' botsource is used, the selected bot will be the bot you are looking at.\n"
		 + PRINTCOLOR_ORANGE + "NOTE:" + PRINTCOLOR_NORMAL + " only the admins can use this command.";
}

::Left4Bots.Cmd_pause <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_pause - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			bot.GetScriptScope().BotPause();
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

		if (tgtBot)
			tgtBot.GetScriptScope().BotPause();
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: pause");
	}
}

::Left4Bots.CmdHelp_pause <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "pause" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will be forced to start a pause (for debugging purposes).\n"
		 + PRINTCOLOR_NORMAL + "If '" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' botsource is used, the selected bot will be the bot you are looking at.\n"
		 + PRINTCOLOR_ORANGE + "NOTE:" + PRINTCOLOR_NORMAL + " only the admins can use this command.";
}

// -- User commands --------------------------

::Left4Bots.Cmd_cancel <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_cancel - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (!allBots && !tgtBot)
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "Can't use the 'bot' keyword with the 'cancel' command");
		return;
	}

	// param can be:
	// - "current" to cancel the current order only
	// - "orders" to cancel all the orders (including the current one)
	// - "ordertype" to cancel all the orders of given type
	// - "defib" to cancel any pending defib task
	// - "all" (or null) to cancel everything (orders, current pick-up, anything)
	if (param)
		param = param.tolower();

	if (allBots)
	{
		// With 'bots cancel defib' we also "abandon" any dead survivor
		if (param == "defib")
			Left4Bots.Deads = {}; // Clear the deads list

		foreach (bot in ::Left4Bots.Bots)
		{
			if (!param || param == "all")
				bot.GetScriptScope().BotCancelAll();
			else if (param == "current")
				bot.GetScriptScope().BotCancelCurrentOrder();
			else if (param == "orders")
				bot.GetScriptScope().BotCancelOrders();
			else if (param == "defib")
				bot.GetScriptScope().BotCancelDefib();
			else
				bot.GetScriptScope().BotCancelOrders(param);
		}

		// With 'bots cancel all' we also stop the scavenge
		if (!param || param == "all")
			Left4Bots.ScavengeStop();
	}
	else
	{
		if (!param || param == "all")
			tgtBot.GetScriptScope().BotCancelAll();
		else if (param == "current")
			tgtBot.GetScriptScope().BotCancelCurrentOrder();
		else if (param == "orders")
			tgtBot.GetScriptScope().BotCancelOrders();
		else if (param == "defib")
			tgtBot.GetScriptScope().BotCancelDefib();
		else
			tgtBot.GetScriptScope().BotCancelOrders(param);
	}
}

::Left4Bots.CmdHelp_cancel <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "cancel" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "switch" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "If 'current' [switch] is used, the bot(s) will abort his/their current order and will proceed with the next one in the queue (if any).\n"
		 + PRINTCOLOR_NORMAL + "If 'ordertype' [switch] is used, the bot(s) will abort all his/their orders (current and queued ones) of type 'ordertype' (example: " + PRINTCOLOR_GREEN + "coach cancel lead" + PRINTCOLOR_NORMAL + ").\n"
		 + PRINTCOLOR_NORMAL + "If 'orders' [switch] is used, the bot(s) will abort all his/their orders (current and queued ones) of any type.\n"
		 + PRINTCOLOR_NORMAL + "If 'defib' [switch] is used, the bot(s) will abort any pending defib task. '" + PRINTCOLOR_GREEN + "botname cancel defib" + PRINTCOLOR_NORMAL + "' is temporary (the bot will retry). '" + PRINTCOLOR_GREEN + "bots cancel defib" + PRINTCOLOR_NORMAL + "' is permanent (currently dead survivors will be abandoned).\n"
		 + PRINTCOLOR_NORMAL + "If [switch] is not specified or 'all' [switch] is used, the bot(s) will abort everything (orders, defib, current pick-up, anything).\n"
		 + PRINTCOLOR_ORANGE + "NOTE: '" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_ORANGE + "' botsource is not allowed here, only '" + PRINTCOLOR_CYAN + "bots" + PRINTCOLOR_ORANGE + "' and '" + PRINTCOLOR_CYAN + "botname" + PRINTCOLOR_ORANGE + "' can be used.";
}

::Left4Bots.Cmd_carry <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_carry - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local tTable = Left4Utils.GetLookingTargetEx(player, TRACE_MASK_NPC_SOLID);
	if (!tTable)
		return;

	local target = null;

	if (tTable["ent"])
	{
		//local tClass = tTable["ent"].GetClassname();
		//if (tClass.find("weapon_") != null || tClass.find("prop_physics") != null && Left4Utils.GetWeaponSlotById(Left4Utils.GetWeaponId(tTable["ent"])))
		if (Left4Utils.GetWeaponSlotById(Left4Utils.GetWeaponId(tTable["ent"])))
			target = tTable["ent"];
		else
			target = Left4Bots.FindNearestCarriable(tTable["pos"], 130);
	}
	else
		target = Left4Bots.FindNearestCarriable(tTable["pos"], 130);

	if (!target)
		return;

	if (!tgtBot || allBots)
		tgtBot = Left4Bots.GetFirstAvailableBotForOrder("carry", null, target.GetCenter());

	if (tgtBot)
		Left4Bots.BotOrderAdd(tgtBot, "carry", player, target, null, null, Left4Bots.Settings.button_holdtime_tap);
	else
		Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: carry");
}

::Left4Bots.CmdHelp_carry <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "carry" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will pick and hold the carriable item (gnome, gascan, cola, etc.) you are looking at.";
}

::Left4Bots.Cmd_come <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_come - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Bots.BotOrderAdd(bot, "goto", player, null, player.GetOrigin());
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("goto");

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "goto", player, null, player.GetOrigin());
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: come");
	}
}

::Left4Bots.CmdHelp_come <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "come" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will come to your current location (alias of " + PRINTCOLOR_GREEN + "'<botsource> goto me" + PRINTCOLOR_NORMAL + "').";
}

::Left4Bots.Cmd_deploy <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_deploy - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local tTable = Left4Utils.GetLookingTargetEx(player, TRACE_MASK_NPC_SOLID);
	if (!tTable)
		return;

	local target = null;

	if (tTable["ent"])
	{
		local tClass = tTable["ent"].GetClassname();
		if (tClass.find("weapon_upgradepack_explosive") != null || tClass.find("weapon_upgradepack_incendiary") != null)
			target = tTable["ent"];
		else
			target = Left4Bots.FindNearestDeployable(tTable["pos"], 130);
	}
	else
		target = Left4Bots.FindNearestDeployable(tTable["pos"], 130);

	if (target)
	{
		// Must go pick up the aimed upgradepack and deploy it
		if (!tgtBot || allBots)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("deploy", null, target.GetCenter());

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "deploy", player, target, null, null, Left4Bots.Settings.button_holdtime_tap);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: deploy");
	}
	else
	{
		// Must deploy the upgradepacks in their inventory
		if (allBots)
		{
			foreach (bot in Left4Bots.Bots)
			{
				local item = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_MEDKIT);
				if (item && item.IsValid())
				{
					local itemClass = item.GetClassname();
					if (itemClass.find("weapon_upgradepack_explosive") != null || itemClass.find("weapon_upgradepack_incendiary") != null)
					{
						Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + bot.GetPlayerName() + " switching to upgrade " + itemClass);

						bot.SwitchToItem(itemClass);

						Left4Timers.AddTimer(null, 1, @(params) Left4Bots.DoDeployUpgrade(params.player), { player = bot });
					}
				}
			}
		}
		else
		{
			if (!tgtBot)
				tgtBot = Left4Bots.GetFirstAvailableBotForDeploy(player);

			if (tgtBot)
			{
				local itemClass = Left4Utils.GetInventoryItemInSlot(tgtBot, INV_SLOT_MEDKIT).GetClassname();

				Left4Bots.Log(LOG_LEVEL_DEBUG, "Bot " + tgtBot.GetPlayerName() + " switching to upgrade " + itemClass);

				tgtBot.SwitchToItem(itemClass);

				Left4Timers.AddTimer(null, 1, @(params) Left4Bots.DoDeployUpgrade(params.player), { player = tgtBot });
			}
			else
				Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: deploy");
		}
	}
}

::Left4Bots.CmdHelp_deploy <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "deploy" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue or executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will go pick the deployable item (ammo upgrade packs) you are looking at and deploy it immediately.\n"
		 + PRINTCOLOR_NORMAL + "If you aren't looking at any item and the bot already has a deployable item in his inventory, he will deploy that item immediately.";
}

::Left4Bots.Cmd_follow <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_follow - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
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
		return;
	}

	if (allBots)
	{
		foreach (id, bot in Left4Bots.Bots)
		{
			if (id != followEnt.GetPlayerUserId())
				Left4Bots.BotOrderAdd(bot, "follow", player, followEnt);
		}
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("follow", followEnt.GetPlayerUserId(), followEnt.GetOrigin());

		if (tgtBot && tgtBot.GetPlayerUserId() != followEnt.GetPlayerUserId())
			Left4Bots.BotOrderAdd(tgtBot, "follow", player, followEnt);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: follow");
	}
}

::Left4Bots.CmdHelp_follow <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "follow" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "target" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will start following you (if [target] isn't specified) or the given target survivor.\n"
		 + PRINTCOLOR_NORMAL + "You can also use the keyword 'me' as the 'target' to make the bot(s) follow you.";
}

::Left4Bots.Cmd_give <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_give - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local lvl = Left4Users.GetOnlineUserLevel(player.GetPlayerUserId());
	if (lvl < Left4Bots.Settings.userlevel_give_others)
		return; // Player's user level is too low for any item, no point continuing

	local searchSlots = [INV_SLOT_PILLS, INV_SLOT_THROW, INV_SLOT_MEDKIT];
	for (local i = 0; i < searchSlots.len(); i++)
	{
		local slot = searchSlots[i];
		local bot = null;
		local item = Left4Utils.GetInventoryItemInSlot(player, slot);
		if (!item)
		{
			if (allBots || !tgtBot)
			{
				// "bot give" and "bots give" will work the same way. The first bot with any item in that inventory slot is automatically selected
				bot = Left4Bots.GetFirstAvailableBotForGive(slot, lvl);
			}
			else
			{
				local botItem = Left4Utils.GetInventoryItemInSlot(tgtBot, slot);
				if (botItem && botItem.IsValid())
					bot = tgtBot;
			}

			if (bot)
			{
				Left4Bots.GiveInventoryItem(bot, player, slot);
				return;
			}
		}
	}

	Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: give");
}

::Left4Bots.CmdHelp_give <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "give" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot will give you one item from their pills/throwable/medkit inventory slot if your slot is emtpy.\n"
		 + PRINTCOLOR_NORMAL + "'" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' and '" + PRINTCOLOR_CYAN + "bots" + PRINTCOLOR_NORMAL + "' botsources are the same here, the first available bot is selected.";
}

::Left4Bots.Cmd_goto <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_goto - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
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
			return;
		}
		gotoPos = gotoPos.GetOrigin();
	}
	else
	{
		gotoPos = Left4Utils.GetLookingPosition(player, Left4Bots.Settings.tracemask_others);
		if (!gotoPos)
		{
			Left4Bots.Log(LOG_LEVEL_WARN, "Invalid goto position");
			return;
		}
	}

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Bots.BotOrderAdd(bot, "goto", player, null, gotoPos);
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("goto");

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "goto", player, null, gotoPos);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: goto");
	}
}

::Left4Bots.CmdHelp_goto <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "goto" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "target" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will go to the location you are looking at (if [target] isn't specified) or to the current target's position.\n"
		 + PRINTCOLOR_NORMAL + "'target' can be another survivor or the keyword 'me' to come to you.";
}

::Left4Bots.Cmd_heal <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_heal - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
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
			return;
		}
	}

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Bots.BotOrderAdd(bot, "heal", player, healTgt != null ? healTgt : bot, null, null, Left4Bots.Settings.button_holdtime_heal, false);
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
			Left4Bots.BotOrderAdd(tgtBot, "heal", player, healTgt != null ? healTgt : tgtBot, null, null, Left4Bots.Settings.button_holdtime_heal, false);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: heal");
	}
}

::Left4Bots.CmdHelp_heal <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "heal" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "target" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will heal himself/themselves (if [target] isn't specified) or the target survivor.\n"
		 + PRINTCOLOR_NORMAL + "'target' can also be the bot himself or the keyword 'me' to heal you.";
}

::Left4Bots.Cmd_hurry <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_hurry - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		local hurryUntil = Time() + Left4Bots.Settings.hurry_time;
		foreach (bot in Left4Bots.Bots)
		{
			local scope = bot.GetScriptScope();
			scope.BotCancelAll();
			scope.HurryUntil = hurryUntil;

			Left4Bots.SpeakRandomVocalize(bot, Left4Bots.VocalizerYes, RandomFloat(0.5, 1.0));
		}
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetNearestMovingBot(player.GetOrigin());

		if (tgtBot)
		{
			local scope = tgtBot.GetScriptScope();
			scope.BotCancelAll();
			scope.HurryUntil = Time() + Left4Bots.Settings.hurry_time;

			Left4Bots.SpeakRandomVocalize(tgtBot, Left4Bots.VocalizerYes, RandomFloat(0.5, 1.0));
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: hurry");
	}
}

::Left4Bots.CmdHelp_hurry <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "hurry" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) L4B2 AI will stop doing anything for '" + PRINTCOLOR_GREEN + "hurry_time" + PRINTCOLOR_NORMAL + "' seconds.\n"
		 + PRINTCOLOR_NORMAL + "Basically they will cancel any pending action/order and ignore pickups, defibs, throws etc. for that amount of time.";
}

::Left4Bots.Cmd_lead <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_lead - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Bots.BotOrderAdd(bot, "lead", player);
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("lead");

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "lead", player);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: lead");
	}
}

::Left4Bots.CmdHelp_lead <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "lead" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will start leading the way following the map's flow.";
}

::Left4Bots.Cmd_move <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_move - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	// Alias of "cancel all"
	if (!allBots && !tgtBot)
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "Can't use the 'bot' keyword with the 'move' command");
		return;
	}

	if (allBots)
	{
		foreach (bot in ::Left4Bots.Bots)
			bot.GetScriptScope().BotCancelAll();

		// With 'bots cancel all' we also stop the scavenge
		Left4Bots.ScavengeStop();
	}
	else
		tgtBot.GetScriptScope().BotCancelAll();
}

::Left4Bots.CmdHelp_move <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "move" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "Alias of '" + PRINTCOLOR_ORANGE + "<botsource> cancel all" + PRINTCOLOR_NORMAL + "'.";
}

::Left4Bots.Cmd_scavenge <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_scavenge - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (param)
	{
		if (param.tolower() == "start")
			Left4Bots.ScavengeStart();
		else if (param.tolower() == "stop")
			Left4Bots.ScavengeStop();
		
		return;
	}
	
	local tTable = Left4Utils.GetLookingTargetEx(player, TRACE_MASK_NPC_SOLID);
	if (!tTable)
		return;

	local target = null;

	if (tTable["ent"])
	{
		local tClass = tTable["ent"].GetClassname();
		local wId = Left4Utils.GetWeaponId(tTable["ent"]);
		if (tClass != "weapon_scavenge_item_spawn" && tClass != "weapon_gascan_spawn" && ((Left4Bots.ScavengeUseType == SCAV_TYPE_GASCAN && wId == Left4Utils.WeaponId.weapon_gascan) || (Left4Bots.ScavengeUseType == SCAV_TYPE_COLA && wId == Left4Utils.WeaponId.weapon_cola_bottles)))
			target = tTable["ent"];
		else
			target = Left4Bots.FindNearestScavengeItem(tTable["pos"], 130);
	}
	else
		target = Left4Bots.FindNearestScavengeItem(tTable["pos"], 130);

	//if (target && !Left4Bots.BotsHaveOrderDestEnt(target))
	if (target)
	{
		//if (!Left4Bots.BotHasOrderOfType(bot, "scavenge"))
		if (!tgtBot || allBots)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("scavenge", null, target.GetCenter());

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "scavenge", player, target, null, null, Left4Bots.Settings.button_holdtime_tap);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: scavenge");
	}
}

::Left4Bots.CmdHelp_scavenge <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "scavenge" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "switch" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue (if [switch] is not specified) or it's executed immediately (if 'start/stop' switch is used).\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will scavenge the item you are looking at (gascan, cola bottles) if a pour target is active and [switch] isn't specified.\n"
		 + PRINTCOLOR_NORMAL + "You can give this order to any bot, including the ones who aren't already scavenging automatically.\n"
		 + PRINTCOLOR_NORMAL + "If 'start/stop' switch is used, the command will start/stop the scavenge process.\n"
		 + PRINTCOLOR_NORMAL + "In this case the botsource parameter is ignored, the scavenge bot(s) are always selected automatically.";
}

::Left4Bots.Cmd_swap <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_swap - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local lvl = Left4Users.GetOnlineUserLevel(player.GetPlayerUserId());
	if (lvl < Left4Bots.Settings.userlevel_give_others)
		return; // Player's user level is too low for any item, no point continuing

	if (allBots || !tgtBot)
		tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

	if (!tgtBot)
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: swap");
		return;
	}
	
	local held = player.GetActiveWeapon();
	if (!held || !held.IsValid())
		return;
	
	local heldClass = held.GetClassname();
//	local heldSkin = NetProps.GetPropInt(held, "m_nSkin");
	local slot = Left4Utils.FindSlotForItemClass(player, heldClass);
//	if (slot != INV_SLOT_PILLS && slot != INV_SLOT_THROW && slot != INV_SLOT_MEDKIT)
//		return;

	local botItem = Left4Utils.GetInventoryItemInSlot(tgtBot, slot);
	if (!botItem || !botItem.IsValid())
		return;

	local botItemClass = botItem.GetClassname();
//	local botItemSkin = NetProps.GetPropInt(botItem, "m_nSkin");
//	if (botItemClass == heldClass && heldSkin == botItemSkin)
//		return;

	// tgtBot has a valid swappable item
	if (slot == INV_SLOT_MEDKIT && (botItemClass == "weapon_first_aid_kit" || botItemClass == "weapon_defibrillator") && (!Left4Bots.Settings.give_bots_medkits || lvl < Left4Bots.Settings.userlevel_give_medkit))
		return;
					
	if ((slot == INV_SLOT_PRIMARY || slot == INV_SLOT_SECONDARY) && (!Left4Bots.Settings.give_bots_weapons || lvl < Left4Bots.Settings.userlevel_give_weapons))
		return;

	// Player is allowed to receive that item

	// Swap
	DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, player);
	DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertGiveItem", 0, null, tgtBot);

	Left4Bots.GiveItemIndex1 = held.GetEntityIndex();
	Left4Bots.GiveItemIndex2 = botItem.GetEntityIndex();

	player.DropItem(heldClass);
	tgtBot.DropItem(botItemClass);

	//Left4Utils.GiveItemWithSkin(player, botItemClass, botItemSkin);
	//Left4Utils.GiveItemWithSkin(tgtBot, heldClass, heldSkin);

	Left4Timers.AddTimer(null, 0.3, Left4Bots.ItemSwapped, { player1 = player, item1 = botItem, player2 = tgtBot, item2 = held });
}

::Left4Bots.CmdHelp_swap <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "swap" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "You will swap the item you are holding (only for items from the pills/throwable/medkit inventory slots) with the selected bot.\n"
		 + PRINTCOLOR_NORMAL + "'" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' and '" + PRINTCOLOR_CYAN + "bots" + PRINTCOLOR_NORMAL + "' botsources will both select the bot you are looking at.";
}

::Left4Bots.Cmd_tempheal <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_tempheal - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
		{
			local item = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_PILLS);
			if (item && item.IsValid())
			{
				bot.SwitchToItem(item.GetClassname());
				Left4Timers.AddTimer(null, 1.2, @(params) Left4Utils.PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = bot, button = BUTTON_ATTACK, holdTime = 1, destination = null, deltaPitch = 0, deltaYaw = 0, lockLook = true });
			}
		}
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

		if (tgtBot)
		{
			local item = Left4Utils.GetInventoryItemInSlot(tgtBot, INV_SLOT_PILLS);
			if (item && item.IsValid())
			{
				tgtBot.SwitchToItem(item.GetClassname());
				Left4Timers.AddTimer(null, 1.2, @(params) Left4Utils.PlayerPressButton(params.bot, params.button, params.holdTime, params.destination, params.deltaPitch, params.deltaYaw, params.lockLook), { bot = tgtBot, button = BUTTON_ATTACK, holdTime = 1, destination = null, deltaPitch = 0, deltaYaw = 0, lockLook = true });
			}
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: tempheal");
	}
}

::Left4Bots.CmdHelp_tempheal <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "tempheal" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will use their pain pils/adrenaline.\n"
		 + PRINTCOLOR_NORMAL + "If '" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' botsource is used, the selected bot will be the bot you are looking at.";
}

::Left4Bots.Cmd_throw <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_throw - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local destination = Left4Utils.GetLookingTarget(player, Left4Bots.Settings.tracemask_others);
	if (!destination)
		return; // Invalid destination

	local destPos = destination;
	if ((typeof destPos) == "instance")
		destPos = destPos.GetOrigin();

	local item = null;
	if (param)
	{
		item = param.tolower();
		if (item.find("molotov") != null)
			item = "weapon_molotov";
		else if (item.find("pipe") != null)
			item = "weapon_pipe_bomb";
		else if (item.find("bile") != null)
			item = "weapon_vomitjar";
		else
			return; // bad item name
	}

	if (allBots)
	{
		// bots throw [item]
		foreach (bot in Left4Bots.Bots)
		{
			if (Left4Bots.BotCanThrow(bot, item))
				Left4Bots.BotThrow(bot, destPos);
		}
	}
	else
	{
		// bot/botname throw [item]
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForThrow(destPos, item);

		if (!tgtBot || !Left4Bots.BotCanThrow(tgtBot, item))
		{
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: throw");
			return;
		}

		Left4Bots.BotThrow(tgtBot, destPos);
	}
}

::Left4Bots.CmdHelp_throw <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "throw" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "item" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will throw their throwable item to the location you are looking at.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) must have the given [item] type (if [item] is specified).";
}

::Left4Bots.Cmd_use <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_use - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local tTable = Left4Utils.GetLookingTargetEx(player, TRACE_MASK_NPC_SOLID);
	if (!tTable)
		return;

	local holdTime = Left4Bots.Settings.button_holdtime_tap;
	local target = null;

	if (tTable["ent"])
	{
		local tClass = tTable["ent"].GetClassname();
		if (tClass.find("weapon_") != null || tClass.find("prop_physics") != null || tClass.find("prop_minigun") != null || tClass.find("func_button") != null || tClass.find("trigger_finale") != null || tClass.find("prop_door_rotating") != null)
			target = tTable["ent"];
		else
			target = Left4Bots.FindNearestUsable(tTable["pos"], 130);
	}
	else
		target = Left4Bots.FindNearestUsable(tTable["pos"], 130);

	if (!target)
		return;

	local targetClass = target.GetClassname();
	local wId = Left4Utils.GetWeaponId(target);
	local wSlot = Left4Utils.GetWeaponSlotById(wId);
	if (Left4Bots.Settings.smart_use_scavenge && Left4Bots.ScavengeUseTarget && ((Left4Bots.ScavengeUseType == SCAV_TYPE_GASCAN && wId == Left4Utils.WeaponId.weapon_gascan) || (Left4Bots.ScavengeUseType == SCAV_TYPE_COLA && wId == Left4Utils.WeaponId.weapon_cola_bottles)))
	{
		// scavenge
		Left4Bots.Log(LOG_LEVEL_DEBUG, "'use' -> 'scavenge': " + targetClass);

		if (!tgtBot || allBots)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("scavenge", null, target.GetCenter());

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "scavenge", player, target, null, null, Left4Bots.Settings.button_holdtime_tap);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: scavenge");

		return;
	}
	else if (Left4Bots.Settings.smart_use_carry && wSlot == 5)
	{
		// carry
		Left4Bots.Log(LOG_LEVEL_DEBUG, "'use' -> 'carry': " + targetClass);

		if (!tgtBot || allBots)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("carry", null, target.GetCenter());

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "carry", player, target, null, null, Left4Bots.Settings.button_holdtime_tap);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: carry");

		return;
	}
	else if (Left4Bots.Settings.smart_use_deploy && (wId == Left4Utils.WeaponId.weapon_upgradepack_incendiary || wId == Left4Utils.WeaponId.weapon_upgradepack_explosive))
	{
		// deploy
		Left4Bots.Log(LOG_LEVEL_DEBUG, "'use' -> 'deploy': " + targetClass);

		if (!tgtBot || allBots)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("deploy", null, target.GetCenter());

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "deploy", player, target, null, null, Left4Bots.Settings.button_holdtime_tap);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: deploy");

		return;
	}

	local targetPos = null;

	if (targetClass.find("weapon_") != null || targetClass.find("prop_physics") != null)
	{
		//targetPos = null;
	}
	else if (targetClass.find("prop_minigun") != null)
		targetPos = target.GetOrigin() - (target.GetAngles().Forward() * 50);
	else if (targetClass.find("func_button") != null || targetClass.find("trigger_finale") != null || targetClass.find("prop_door_rotating") != null)
	{
		if (targetClass == "func_button_timed")
			holdTime = NetProps.GetPropInt(target, "m_nUseTime") + 0.1;

		local p = tTable["pos"];
		local a = Left4Utils.VectorAngles(player.GetCenter() - tTable["pos"]);

		if (targetClass.find("trigger_finale") != null)
			targetPos = Left4Bots.FindBestUseTargetPos(target, p, a, true, Left4Bots.Settings.scavenge_usetarget_debug);
		else
			targetPos = Left4Bots.FindBestUseTargetPos(target, p, a, false, Left4Bots.Settings.scavenge_usetarget_debug);
		if (!targetPos)
			targetPos = target.GetCenter();

		if (targetClass.find("func_button") != null)
		{
			local glowEntName = NetProps.GetPropString(target, "m_sGlowEntity");
			if (glowEntName && glowEntName != "")
			{
				local glowEnt = Entities.FindByName(null, glowEntName);
				if (glowEnt)
					target = glowEnt;
			}
		}
	}
	else
		target = null;

	if (!target)
		return;

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
		{
			Left4Bots.BotOrderAdd(bot, "use", player, target, targetPos, null, holdTime);
			
			if (wSlot >= 0 && wSlot <= 4)
				bot.GetScriptScope().UseWeapons[wSlot] <- wId;
		}
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("use", null, target.GetCenter());

		if (tgtBot)
		{
			Left4Bots.BotOrderAdd(tgtBot, "use", player, target, targetPos, null, holdTime);
			
			if (wSlot >= 0 && wSlot <= 4)
				tgtBot.GetScriptScope().UseWeapons[wSlot] <- wId;
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: use");
	}
}

::Left4Bots.CmdHelp_use <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "use" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will use the entity (pickup item / press button etc.) you are looking at.";
}

::Left4Bots.Cmd_usereset <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_usereset - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			bot.GetScriptScope().UseWeapons.clear();
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

		if (tgtBot)
			tgtBot.GetScriptScope().UseWeapons.clear();
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: usereset");
	}
}

::Left4Bots.CmdHelp_usereset <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "usereset" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will stop using the weapons picked up via '" + PRINTCOLOR_GREEN + "use" + PRINTCOLOR_NORMAL + "' order and will go back to its weapon preferences / team weapon rules.";
}

::Left4Bots.Cmd_wait <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_wait - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local waitPos = null;
	if (param)
	{
		if (param.tolower() == "here")
			waitPos = player.GetOrigin();
		else if (param.tolower() == "there")
			waitPos = Left4Utils.GetLookingPosition(player, Left4Bots.Settings.tracemask_others);

		if (!waitPos)
		{
			Left4Bots.Log(LOG_LEVEL_WARN, "Invalid wait position: " + param);
			return;
		}
	}

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Bots.BotOrderAdd(bot, "wait", player, null, waitPos != null ? waitPos : bot.GetOrigin(), null, 0, !Left4Bots.Settings.wait_nopause);
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("wait");

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "wait", player, null, waitPos != null ? waitPos : tgtBot.GetOrigin(), null, 0, !Left4Bots.Settings.wait_nopause);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: wait");
	}
}

::Left4Bots.CmdHelp_wait <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "wait" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "location" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "If [location] is not specified, the bot(s) will hold his/their current position.\n"
		 + PRINTCOLOR_NORMAL + "If 'here' [location] is used, the bot(s) will hold position at your current location.\n"
		 + PRINTCOLOR_NORMAL + "If 'there' [location] is used, the bot(s) will hold position at the location you are looking at.";
}

::Left4Bots.Cmd_warp <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_warp - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local warpPos = null;
	if (param)
	{
		if (param.tolower() == "here")
			warpPos = player.GetOrigin();
		else if (param.tolower() == "there")
			warpPos = Left4Utils.GetLookingPosition(player, Left4Bots.Settings.tracemask_others);
		else if (param.tolower() == "move")
			warpPos = "move";

		if (!warpPos)
		{
			Left4Bots.Log(LOG_LEVEL_WARN, "Invalid wait position: " + param);
			return;
		}
	}
	else
		warpPos = player.GetOrigin();

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
		{
			if (warpPos == "move")
			{
				local movepos = bot.GetScriptScope().MovePos;
				if (movepos)
					bot.SetOrigin(movepos);
			}
			else
				bot.SetOrigin(warpPos);
		}
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetPickerBot(player); // player, radius = 999999, threshold = 0.95, visibleOnly = false

		if (tgtBot)
		{
			if (warpPos == "move")
			{
				local movepos = tgtBot.GetScriptScope().MovePos;
				if (movepos)
					tgtBot.SetOrigin(movepos);
			}
			else
				tgtBot.SetOrigin(warpPos);
		}
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: warp");
	}
}

::Left4Bots.CmdHelp_warp <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "warp" + PRINTCOLOR_NORMAL + " [" + PRINTCOLOR_ORANGE + "location" + PRINTCOLOR_NORMAL + "]\n"
		 + PRINTCOLOR_NORMAL + "The order is executed immediately.\n"
		 + PRINTCOLOR_NORMAL + "If [location] is not specified or 'here' [location] is used, the bot(s) will teleport to your current location.\n"
		 + PRINTCOLOR_NORMAL + "If 'there' [location] is used, the bot(s) will teleport to the location you are looking at.\n"
		 + PRINTCOLOR_NORMAL + "If 'move' [location] is used, the bot(s) will teleport to their current MOVE location (if any).\n"
		 + PRINTCOLOR_NORMAL + "If '" + PRINTCOLOR_CYAN + "bot" + PRINTCOLOR_NORMAL + "' botsource is used, the selected bot will be the bot you are looking at.";
}

::Left4Bots.Cmd_witch <- function (player, allBots = false, tgtBot = null, param = null)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "Cmd_witch - player: " + player.GetPlayerName() + " - allBots: " + allBots + " - tgtBot: " + tgtBot + " - param: " + param);
	
	local witch = Left4Bots.GetPickerWitch(player); // TODO: Shouldn't just pick the one with the best dot, distance should also be taken into account
	if (!witch)
	{
		Left4Bots.Log(LOG_LEVEL_WARN, "No target witch found for order of type: witch");
		return;
	}

	if (allBots)
	{
		foreach (bot in Left4Bots.Bots)
			Left4Bots.BotOrderAdd(bot, "witch", player, witch, null, null, 0, false);
	}
	else
	{
		if (!tgtBot)
			tgtBot = Left4Bots.GetFirstAvailableBotForOrder("witch", null, witch.GetOrigin());

		if (tgtBot)
			Left4Bots.BotOrderAdd(tgtBot, "witch", player, witch, null, null, 0, false);
		else
			Left4Bots.Log(LOG_LEVEL_WARN, "No available bot for order of type: witch");
	}
}

::Left4Bots.CmdHelp_witch <- function ()
{
	return PRINTCOLOR_NORMAL + "<" + PRINTCOLOR_CYAN + "botsource" + PRINTCOLOR_NORMAL + "> " + PRINTCOLOR_GREEN + "witch" + PRINTCOLOR_NORMAL + "\n"
		 + PRINTCOLOR_NORMAL + "The order is added to the given bot(s) orders queue.\n"
		 + PRINTCOLOR_NORMAL + "The bot(s) will try to kill the witch you are looking at.";
}

//
