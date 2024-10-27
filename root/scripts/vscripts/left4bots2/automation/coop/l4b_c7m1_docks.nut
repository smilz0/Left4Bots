Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c7m1_docks automation script...\n");


class ::Left4Bots.Automation.WaitDoorUnlock extends ::Left4Bots.Automation.Task
{
	constructor(entname, pos)
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "WaitDoorUnlock", null, null, null, 0.0, true, null, false, false);
		
		_ordersSent = false;
		_gotoPos = pos;
		_entName = entname
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		/*
		if (!_ordersSent)
		{
			foreach (bot in _l4b.Bots)
				_l4b.BotOrderAdd(bot, "wait", null, null, _gotoPos);
			
			_ordersSent = true;
			return;
		}
		
		// Make sure that all the bots are in the 'Waiting' status before continuing
		foreach (bot in _l4b.Bots)
		{
			if (!bot.GetScriptScope().Waiting)
				return;
		}
		*/
		local ent = Entities.FindByName(null, _entName);
		if (ent && ent.IsValid() && NetProps.GetPropInt(ent, "m_bLocked"))
			return; // Still locked
		
		// Task is complete. Cancel the 'wait' order and remove the task from CurrentTasks
		/*
		foreach (bot in _l4b.Bots)
			bot.GetScriptScope().BotCancelOrders("wait");
		*/
		
		_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
		_l4b.Logger.Debug("Task complete");
	}
	
	_ordersSent = false;
	_gotoPos = null;
	_entName = null;
}

::Left4Bots.Automation.DoWaitDoorUnlock <- function (entname, pos)
{
	if (TaskExists("bots", "WaitDoorUnlock"))
		return false;
	
	ResetTasks();
	AddCustomTask(WaitDoorUnlock(entname, pos));
		
	return true;
}


::Left4Bots.Automation.step <- 1;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
		case "SurvivorLeavingCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	//::Left4Bots.Logger.Debug("Automation.OnFlow(" + prevFlowPercent + " -> " + curFlowPercent + ")");
	
	switch (::Left4Bots.Automation.step)
	{
		case 1:
			// *** TASK 2. Regroup here so the bots have a chance to clear the area before freeing the tank
			
			if (curFlowPercent >= 43)
			{
				::Left4Bots.Automation.DoWaitDoorUnlock("tankdoorin_button", Vector(7781.461914, 216.571304, 0.062359));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 3. Now open the 1st train door
			
			if (!::Left4Bots.Automation.TaskExists("bots", "WaitDoorUnlock"))
			{
				::Left4Bots.Automation.DoUse("bots", "tankdoorin_button", Vector(7057.688965, 600.554993, 141.083344));
				::Left4Bots.Automation.step++;
			}
			break;
		
		// case 3: (waiting for the 1st train door to open)
		
		case 4:
			// *** TASK 4. 1st train door open, let's open the 2nd one
			::Left4Bots.Automation.DoWaitDoorUnlock("tankdoorout_button", Vector(7781.461914, 216.571304, 0.062359));
			::Left4Bots.Automation.step++;
			break;
			
		case 5:
			// *** TASK 5. Now open the 2nd train door
			
			if (!::Left4Bots.Automation.TaskExists("bots", "WaitDoorUnlock"))
			{
				::Left4Bots.Automation.DoUse("bots", "tankdoorout_button", Vector(6939.248047, 680.642822, 167.189667));
				::Left4Bots.Automation.step++;
			}
			break;

		// case 6: (waiting for the 2nd train door to open)
		
		case 7:
			// *** TASK 6. 2nd train door open, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			EntFire("nav_blocker_barrel", "UnblockNav"); // What is this nav_blocker for?

			break;
	}
}

// Go to the next step when the 1st train door opens
EntityOutputs.AddOutput(Entities.FindByName(null, "tankdoorin"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 4) ::Left4Bots.Automation.step = 4", 0, -1);

// Go to the next step when the 2nd train door opens
EntityOutputs.AddOutput(Entities.FindByName(null, "tankdoorout"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 7) ::Left4Bots.Automation.step = 7", 0, -1);
