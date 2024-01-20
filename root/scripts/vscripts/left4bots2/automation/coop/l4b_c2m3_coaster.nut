Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m3_coaster automation script...\n");

::Left4Bots.Automation.step <- 0;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			if (::Left4Bots.Automation.step > 1)
				return; // !!! This also triggers when a survivor is defibbed later in the game !!!
		
			// *** TASK 2. Wait for the first survivor to leave the start saferoom, then start leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c2m3CoasterStart":
			// *** TASK 6. Coaster started, wait for the gate to open
			
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "C2M3CoasterRun":
			// *** TASK 7. Coaster gate is open, go back to leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c2m3CoasterEnd":
			// *** TASK 9. Coaster stopped, regroup on the bridge before proceeding to the saferoom. Can't use 'lead' here cause of bad flow, they will be able to lead again from the bridge
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.RegroupAt(Vector(-4124.318359, 2319.524170, 272.031250)));
				
				::Left4Bots.Automation.step = 6;
			}
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 11. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
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
		
		case 1:
			// *** TASK 3. Regroup near the pain pills cabinet before proceeding, so everyone can get the pills if needed
			
			if (curFlowPercent >= 42 && prevFlowPercent < 42)
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.RegroupAt(Vector(-1403.558472, 1134.177246, 4.031250)));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 4. Wait until everyone regrouped, then go back to leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 3:
			// *** TASK 5. Start the coaster
			
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
		
		case 4:
			// *** TASK 8. Stop the coaster
			
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
		
		case 6:
			// *** TASK 10. Wait until everyone is on the bridge, then back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
