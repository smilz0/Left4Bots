Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c14m1_junkyard automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;

// Handles the generators restart process.
// Sends one bot to restart the generators one after the other and orders the other bots to follow him
class ::Left4Bots.Automation.C14M1Generators extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "C14M1Generators", null, null, null, 0.0, true, null, false, false);
		
		// List of generator buttons (key = button name - value = use position)
		_gen_buttons = {
			gen1_button = Vector(-3350.262451, 519.295654, -50.968750),
			gen2_button = Vector(-2243.642578, 3278.659424, -38.653404),
			gen3_button = Vector(-1590.950806, 485.119843, -50.968750),
			gen4_button = Vector(-1169.414429, 1948.946167, -55.932152)
		};
	}
	
	function Stop()
	{
		if (!_started)
			return;
		
		_started = false;
		
		foreach (bot in _l4b.Bots)
			bot.GetScriptScope().BotCancelAutoOrders();
		
		_l4b.Logger.Debug("Task stopped " + tostring());
	}
	
	// Returns the button entity of the next (closest to 'origin') generator to activate or null of all generators have been activated
	function GetNextGenerator(origin)
	{
		local minDist = 999999;
		local bestBtn = null;
		foreach (btn, pos in _gen_buttons)
		{
			local ent = Entities.FindByName(null, btn);
			if (ent && ent.IsValid() && (ent.GetOrigin() - origin).Length() < minDist)
			{
				minDist = (ent.GetOrigin() - origin).Length();
				bestBtn = ent;
			}
		}
		return bestBtn;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		// Set the bot who will activate the generators, if not set already
		if (!_activator_bot || !_activator_bot.IsValid() || _activator_bot.IsDead() || _activator_bot.IsDying())
		{
			_activator_bot = _l4b.GetFirstAvailableBotForOrder("use");
			
			if (_activator_bot)
				_l4b.Logger.Debug("C14M1Generators.Think - New activator bot: " + _activator_bot.GetPlayerName());
			
			foreach (bot in _l4b.Bots)
				bot.GetScriptScope().BotCancelAutoOrders();
		}
		
		if (!_activator_bot)
		{
			_l4b.Logger.Warning("No bot available to activate the generators");
			
			/* TODO: should we?
			// Task is complete. Remove it from CurrentTasks
			Stop();
			_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
			_l4b.Logger.Debug("Task complete");
			*/
			
			return;
		}
		
		// Set the next generator button to activate, if not set already
		if (!_current_btn || !_current_btn.IsValid())
		{
			_current_btn = GetNextGenerator(_activator_bot.GetOrigin());
			_l4b.Logger.Debug("C14M1Generators.Think - New current button: " + _current_btn);
		}
		
		if (!_current_btn)
		{
			_l4b.Logger.Info("No more generators to activate");
			
			// Task is complete. Remove it from CurrentTasks
			Stop();
			_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
			_l4b.Logger.Debug("Task complete");
			
			return;
		}
		
		// Make sure that the 'use' order to activate the current button exists
		if (!_l4b.BotHasAutoOrder(_activator_bot, "use", _current_btn))
			_l4b.BotOrderAdd(_activator_bot, "use", null, _current_btn, _gen_buttons[_current_btn.GetName()]);
		
		// Also make sure that the 'follow' order to follow the activator bot exists
		foreach (bot in _l4b.Bots)
		{
			if (bot != _activator_bot && !_l4b.BotHasAutoOrder(bot, "follow", _activator_bot))
				_l4b.BotOrderAdd(bot, "follow", null, _activator_bot);
		}
	}
	
	_gen_buttons = null;
	_activator_bot = null;
	_current_btn = null;
}

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
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then step a bit behind so everyone can pick up their weapons and medkits
			
			::Left4Bots.Automation.step = 1;
			::Left4Bots.Automation.DoGotoAndIdle(Vector(-4171.684082, -10712.492188, -298.306244));
			break;

		case "C14M1PanicStart":
			// *** TASK 5. Fuel button pressed, all go wait here until the power out
			
			::Left4Bots.Automation.DoWait("bots", Vector(-2573.106689, 1489.458740, 1.031250));
			break;

		case "C14M1PowerOut":
			// *** TASK 6. Power out, activate the generators
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.C14M1Generators());
			::Left4Bots.Automation.step = 5;
			
			break;

		case "C14M1CraneReady":
			// *** TASK 8. Crane is ready, press the button
			
			// Unblock the new crane nav area first or the bots cannot get there
			EntFire("newcranearea", "UnblockNav");
			
			::Left4Bots.Automation.DoUse("bots", "drop_button", Vector(-3509.496338, 1658.323853, -10.547668));
			break;

		case "C14M1CraneDrop":
			// *** TASK 9. Button pressed, idle until the path is clear
			
			::Left4Bots.Automation.ResetTasks();

			break;

		case "C14M1PathClear":
			// *** TASK 10. Path is clear, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 11. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	//::Left4Bots.Logger.Debug("Automation.OnFlow(" + prevFlowPercent + " -> " + curFlowPercent + ")");
	
	switch(::Left4Bots.Automation.step)
	{
		case 1:
			// *** TASK 2. Start leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "GotoAndIdle"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 3. Regroup here
			
			if (curFlowPercent >= 51)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(-2573.106689, 1489.458740, 1.031250));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 3:
			// *** TASK 4. After regroup, someone go press the fuel button
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoUse("bot", "fuel_button", Vector(-3815.731201, 1408.230713, -55.283020));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 4: (waiting for the C14M1Generators task to start)
		
		case 5:
			// *** TASK 7. When all the generators have been activated, wait near the crane
			
			if (!::Left4Bots.Automation.TaskExists("bots", "C14M1Generators"))
			{
				::Left4Bots.Automation.DoWait("bots", Vector(-3408.798584, 1349.959961, -50.968750));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	::Left4Bots.Logger.Debug("::Left4Bots.Automation.Events.OnGameEvent_round_start");

	// This new nav area on the crane is needed to allow the bots go press the button, but it must start as blocked and be unblocked only when the crane is ready
	local newcranearea = Entities.FindByName(null, "newcranearea");
	if (!newcranearea)
		::Left4Utils.SpawnNavBlocker("newcranearea", Vector(-3514.050781, 1638.757446, -8.924236), "-5 -5 -5", "5 5 5", 2, 0);
}
