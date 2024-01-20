Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c1m4_atrium automation script...\n");

::Left4Bots.Automation.step <- 0;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			if (::Left4Bots.Automation.step > 1)
				return; // !!! This also triggers when a survivor is defibbed later in the game !!!
		
			// *** TASK 2. Wait for the first survivor to leave the start saferoom, then all go press the elevator button
			
			local button_elev_3rdfloor = Entities.FindByName(null, "button_elev_3rdfloor");
			if (button_elev_3rdfloor && button_elev_3rdfloor.IsValid())
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "use", button_elev_3rdfloor))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "use", button_elev_3rdfloor, Vector(-3996.047363, -3471.647461, 536.031250));
				}
			}
			else
				::Left4Bots.Logger.Error("Automation.OnConcept - button_elev_3rdfloor not found!!!");
			break;
		
		case "c1m4startelevator":
			// *** TASK 3. Elevator started, go idle until it reaches the bottom floor
			
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "FinaleTriggered":
			// *** TASK 4. Elevator down and finale was triggered, start the gasgan scavenge
			
			// This is optional, it's just to set a better ScavengeUseTargetPos than the autocalculated one
			::Left4Bots.ScavengeUseTarget = Entities.FindByClassname(null, "point_prop_use_target");
			::Left4Bots.ScavengeUseType = NetProps.GetPropInt(::Left4Bots.ScavengeUseTarget, "m_spawnflags");
			::Left4Bots.ScavengeUseTargetPos = Vector(-4799.723633, -3601.501709, 24.792393);

			if (!::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				::Left4Bots.Automation.ResetTasks();
				local task = ::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.Scavenge());
				if (::Left4Bots.Settings.scavenge_campaign_autostart)
					task.Start();
			}
			break;
			
		case "PlayerPourFinished":
			// *** TASK 5. Scavenge finished, just go idle and let the vanilla AI go to the rescue vehicle
			
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
			}
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
	}
}
