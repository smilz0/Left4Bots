Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m1_highway automation script...\n");

::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 2. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
	}
}
