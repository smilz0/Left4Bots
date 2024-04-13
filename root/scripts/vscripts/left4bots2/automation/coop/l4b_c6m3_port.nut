Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c6m3_port automation script...\n");

class ::Left4Bots.Automation.c6m3_Scavenge extends ::Left4Bots.Automation.Scavenge
{
	constructor(useTargetPos = null, onTankPos = null, onTankCanPause = true)
	{
		base.constructor(useTargetPos, onTankPos, onTankCanPause);
		
		_bak["ScavengeUseTargetPos"] <- _l4b.ScavengeUseTargetPos;
		_bak["scavenge_pour"] <- _l4b.Settings.scavenge_pour;
		_bak["scavenge_items_farthest_first"] <- _l4b.Settings.scavenge_items_farthest_first;
		_bak["scavenge_items_from_pourtarget"] <- _l4b.Settings.scavenge_items_from_pourtarget;
		
		_dangerItems = true;
		_l4b.ScavengeUseTargetPos = Vector(153.229553, 1052.890381, 159.901718);
		_l4b.Settings.scavenge_pour = 0;
		_l4b.Settings.scavenge_items_farthest_first = 1;
		_l4b.Settings.scavenge_items_from_pourtarget = 1;
	}
	
	function Stop()
	{
		base.Stop();
		
		_dangerItems = false;
		_l4b.ScavengeUseTargetPos = _bak["ScavengeUseTargetPos"];
		_l4b.Settings.scavenge_pour = _bak["scavenge_pour"];
		_l4b.Settings.scavenge_items_farthest_first = _bak["scavenge_items_farthest_first"];
		_l4b.Settings.scavenge_items_from_pourtarget = _bak["scavenge_items_from_pourtarget"];
	}
	
	function GetScavengeItems()
	{
		local p1 = Vector(-2543.997070, 514.369080, 0);
		local p2 = Vector(-268.958588, 2255.994629, 0);
		
		local items = base.GetScavengeItems();
		local dangerItems = {};
		foreach (idx, item in items)
		{
			local p = item.ent.GetOrigin();
			if (p.x >= p1.x && p.x <= p2.x && p.y >= p1.y && p.y <= p2.y)
			{
				// Item in the rectangle area
				dangerItems[idx] <- item;
			}
		}
		
		if (dangerItems.len() > 0)
		{
			// There are still items in the danger area
			if (!_dangerItems)
			{
				// Setup for danger items scavenge
				_dangerItems = true;
				_l4b.ScavengeUseTargetPos = Vector(153.229553, 1052.890381, 159.901718);
				_l4b.Settings.scavenge_pour = 0;
				_l4b.Settings.scavenge_items_farthest_first = 1;
				_l4b.Settings.scavenge_items_from_pourtarget = 1;
				
				_l4b.Logger.Debug("c6m3_Scavenge.GetScavengeItems - *** Danger Items Scavenge ***");
			}
			return dangerItems;
		}

		// No more items in the danger area

		if (_dangerItems)
		{
			// Rollback to normal scavenge
			_dangerItems = false;
			_l4b.ScavengeUseTargetPos = _bak["ScavengeUseTargetPos"];
			_l4b.Settings.scavenge_pour = _bak["scavenge_pour"];
			_l4b.Settings.scavenge_items_farthest_first = _bak["scavenge_items_farthest_first"];
			_l4b.Settings.scavenge_items_from_pourtarget = _bak["scavenge_items_from_pourtarget"];
			
			_l4b.Logger.Debug("c6m3_Scavenge.GetScavengeItems - *** Normal Scavenge ***");
		}
		return items;
	}
	
	_dangerItems = false;
	_bak = {};
}

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 2. Wait for the first survivor to leave the start saferoom, then all go press the elevator button
			
			::Left4Bots.Automation.DoUse("bots", "generator_elevator_button", Vector(-742.242920, -552.537354, 320.031250));
			break;

		case "c6m3_elevator":
			// *** TASK 3. Elevator button pressed, idle while the elevator moves
			
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "FinaleTriggered":
			// *** TASK 4. Elevator down and finale triggered, start scavenge
			
			if (!::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				::Left4Bots.Automation.ResetTasks();
				local task = ::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.c6m3_Scavenge(Vector(-382.833466, -562.657227, 2.490599), Vector(-146.069611, -275.451355, 0.031250), true));
				if (::Left4Bots.Settings.scavenge_campaign_autostart)
					task.Start();
			}
			break;
		
		case "PlayerPourFinished":
			// *** TASK 5. Scavenge finished, go wait near the bridge until the bridge is down
			
			local score = null;
			local towin = null;

			if ("Score" in query)
				score = query.Score.tointeger();
			if ("towin" in query)
				towin = query.towin.tointeger();

			if (score != null && towin != null)
				::Left4Bots.Logger.Info("Poured: " + score + " - Left: " + towin);

			if (towin == 0 && ::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				::Left4Bots.Logger.Info("Scavenge complete");
				::Left4Bots.Automation.ResetTasks();
				
				::Left4Bots.Automation.DoWait("bots", Vector(4.344630, -977.386353, -7.968752));
			}
			break;
		
		case "FinalVehicleArrived":
			// *** TASK 6. Bridge is down and the rescue vehicle is waiting, go idle and let the vanilla AI get to the car
			
			::Left4Bots.Automation.ResetTasks();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	//::Left4Bots.Logger.Debug("Automation.OnFlow(" + prevFlowPercent + " -> " + curFlowPercent + ")");
	
	switch(::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
	}
}
