Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m1_highway automation script...\n");

::Left4Bots.Automation.step <- 1;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
			if (::Left4Bots.Automation.step > 1)
				return; // !!! This also triggers when a survivor is defibbed later in the game !!!
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			::Left4Bots.Automation.step++;
			
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 2. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
	}
}
