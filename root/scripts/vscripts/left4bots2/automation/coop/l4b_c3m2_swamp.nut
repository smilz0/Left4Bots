Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c3m2_swamp automation script...\n");

::Left4Bots.Automation.step <- 0;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
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

		case "C3M2OpenDoor":
			// *** TASK 4. Door open, back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 5. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
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
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Open the plane door
			
			if (curFlowPercent >= 38 && prevFlowPercent < 38)
			{
				local cabin_door_button = Entities.FindByName(null, "cabin_door_button");
				if (cabin_door_button && cabin_door_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", cabin_door_button, Vector(-1784.953491, 3047.793945, 49.652466)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", cabin_door_button, Vector(-1784.953491, 3047.793945, 49.652466));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
