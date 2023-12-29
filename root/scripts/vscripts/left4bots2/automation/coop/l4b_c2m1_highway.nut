Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m1_highway automation script...\n");

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
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
