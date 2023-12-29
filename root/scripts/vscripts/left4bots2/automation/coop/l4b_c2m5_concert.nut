Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m5_concert automation script...\n");

::Left4Bots.Automation.step <- 0;

class ::Left4Bots.Automation.HealAndGoto extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "HealAndGoto", null, null, null, -1, true, null, false, false);
		
		_ordersSent = false;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (!_ordersSent)
		{
			foreach (bot in _l4b.Bots)
			{
				// Heal if needed
				if (bot.GetHealth() <= 98 && ::Left4Utils.HasMedkit(bot))
					_l4b.BotOrderAdd(bot, "heal", null, bot, null, null, 0, false);
				
				// Go get medkits if needed
				_l4b.BotOrderAdd(bot, "goto", null, null, goto_pos);
			}
			_ordersSent = true;
			return;
		}
		
		// Make sure the bots completed their previously assigned orders (heal and goto) before continuing
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotOrdersCount(bot) > 0)
				return;
		}
		
		// Task is complete. Remove it from CurrentTasks
		_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
		_l4b.Logger.Debug("Task complete");
	}
	
	_ordersSent = false;
	
	static goto_pos = Vector(-675.433411, 2177.320313, -255.968979);
}

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c2m5Button1":
			// Start the concert
			local stage_escape_button = Entities.FindByName(null, "stage_escape_button");
			if (stage_escape_button && stage_escape_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", stage_escape_button, Vector(-1878.096558, 3376.330811, -175.968750)))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bot", "use", stage_escape_button, Vector(-1878.096558, 3376.330811, -175.968750));
			}
			break;
		
		case "FinaleTriggered":
			// Wait near the ammo stack for the entire finale
			local ammo = Entities.FindByName(null, "item_spawn_set1_ammo");
			if (!ammo)
				ammo = Entities.FindByName(null, "item_spawn_set2_ammo");
			
			// [L4D][INFO]   183 |                        weapon_ammo_spawn |                                         item_spawn_set1_ammo | -02280.9375,003256.0000,-00176.0000 | models/props/terror/ammo_stack.mdl
			// [L4D][INFO]   183 |                        weapon_ammo_spawn |                                         item_spawn_set2_ammo | -02337.6250,002427.5625,-00063.7188 | models/props/terror/ammo_stack.mdl
			
			if (ammo && ammo.IsValid() && !::Left4Bots.Automation.TaskExists("bots", "wait", null, ammo.GetOrigin()))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "wait", null, ammo.GetOrigin());
			}
			break;
		
		case "FinalVehicleSpotted":
			// Let's go meet the chopper at its landing spot
			//local stadium_exit_left_relay = Entities.FindByName(null, "stadium_exit_left_relay");
			local stadium_exit_right_relay = Entities.FindByName(null, "stadium_exit_right_relay");
			local left = NetProps.GetPropInt(stadium_exit_right_relay, "m_bDisabled");
			local waitpos = left == 1 ? Vector(-1062.592041, 2497.011475, 24.165833) : Vector(-3686.272217, 3011.679688, -8.828863);
			
			if (!::Left4Bots.Automation.TaskExists("bots", "wait", null, waitpos))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "wait", null, waitpos);
			}
			break;
		
		case "FinalVehicleArrived":
			::Left4Bots.Automation.ResetTasks();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			if (!::Left4Bots.Automation.TaskExists("bots", "HealAndGoto"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealAndGoto());
			}
			
			::Left4Bots.Automation.step++;
			break;
			
		case 1:
			// Turn on the lights
			if (curFlowPercent > 67 && prevFlowPercent <= 67)
			{
				local stage_lights_button = Entities.FindByName(null, "stage_lights_button");
				if (stage_lights_button && stage_lights_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", stage_lights_button, Vector(-2281.586914, 2082.279541, 128.031250)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", stage_lights_button, Vector(-2281.586914, 2082.279541, 128.031250));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

/* Not really needed
::Left4Bots.Automation.Events.OnGameEvent_player_death <- function (params)
{
	local victim = null;
	if ("userid" in params)
		victim = g_MapScript.GetPlayerFromUserID(params["userid"]);

	if (!victim || !victim.IsValid() || victim.GetZombieType() != Z_TANK)
		return;

	// count++;
}
*/
