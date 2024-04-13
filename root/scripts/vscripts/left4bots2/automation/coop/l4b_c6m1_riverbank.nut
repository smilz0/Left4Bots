Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c6m1_riverbank automation script...\n");

::Left4Bots.Automation.step <- 1;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 4. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 2. Go grab the T1 weapons
			
			if (curFlowPercent >= 12)
			{
				local tier1_weapons_2 = Entities.FindByName(null, "tier1_weapons_2");
				local weaponsPos = tier1_weapons_2 != null ? Vector(3199.533447, 2420.133057, 56.031250) : Vector(3532.326172, 2501.537598, 56.031250);
				
				::Left4Bots.Automation.DoGotoAndIdle(weaponsPos);
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 3. Wait for the GotoAndIdle to finish and then go back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "GotoAndIdle"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
