Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m4_barns automation script...\n");

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
	
	static goto_pos = Vector(2942.561523, 3774.956543, -187.968750);
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
		
		case "C2M4ButtonPressed":
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "c2m4GateOpen":
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "SurvivorBotReachedCheckpoint":
			CurrentTasks.clear();
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
			// Open the gates
			if (curFlowPercent > 78 && prevFlowPercent <= 78)
			{
				local minifinale_gates_button = Entities.FindByName(null, "minifinale_gates_button");
				if (minifinale_gates_button && minifinale_gates_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", minifinale_gates_button, Vector(-2382.254150, 1573.590820, -255.968750)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", minifinale_gates_button, Vector(-2382.254150, 1573.590820, -255.968750));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
