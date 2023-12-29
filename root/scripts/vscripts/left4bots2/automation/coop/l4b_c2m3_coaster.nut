Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m3_coaster automation script...\n");

::Left4Bots.Automation.step <- 0;

// TODO: Maybe better replace with Regroup (wait?)
class ::Left4Bots.Automation.GotoSingle extends ::Left4Bots.Automation.Task
{
	constructor(pos)
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "GotoSingle", null, null, null, -1, true, null, false, false);
		
		_ordersSent = false;
		_gotoPos = pos;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (!_ordersSent)
		{
			foreach (bot in _l4b.Bots)
				_l4b.BotOrderAdd(bot, "goto", null, null, _gotoPos);
			
			_ordersSent = true;
			return;
		}
		
		// Make sure the bots completed their previously assigned orders (goto) before continuing
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
	_gotoPos = null;
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
		
		case "c2m3CoasterStart":
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "C2M3CoasterRun":
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c2m3CoasterEnd":
			// Don't use 'lead', the map's flow is broken here. Let them go on the bridge instead, they will be able to path to the saferoom from there
			if (!::Left4Bots.Automation.TaskExists("bots", "GotoSingle"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.GotoSingle(Vector(-4015.306885, 2316.522705, 272.031250)));
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
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// Go check the pills cabinet for pickups
			if (curFlowPercent >= 42 && prevFlowPercent < 42)
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "GotoSingle"))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.GotoSingle(Vector(-1403.558472, 1134.177246, 4.031250)));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// Start the coaster
			if (curFlowPercent > 52 && prevFlowPercent <= 52)
			{
				local minifinale_button = Entities.FindByName(null, "minifinale_button");
				if (minifinale_button && minifinale_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", minifinale_button, Vector(-2959.888916, 1697.165527, 0.649078)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", minifinale_button, Vector(-2959.888916, 1697.165527, 0.649078));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 3:
			// Stop the coaster
			if (curFlowPercent > 92 && prevFlowPercent <= 92)
			{
				local finale_alarm_stop_button = Entities.FindByName(null, "finale_alarm_stop_button");
				if (finale_alarm_stop_button && finale_alarm_stop_button.IsValid() && !::Left4Bots.Automation.TaskExists("bots", "use", finale_alarm_stop_button, Vector(-3576.294922, 1472.324341, 160.031250)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "use", finale_alarm_stop_button, Vector(-3576.294922, 1472.324341, 160.031250));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
