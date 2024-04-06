Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c9m1_alleys automation script...\n");

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

		case "HowitzerFired":
			// *** TASK 4. Howitzer fired, wait here until the path is clear
			
			::Left4Bots.Automation.DoHoldAt(Vector(-2137.692627, -6080.912598, 32.031250), Vector(-1390.707397, -6072.333496, 7.580958));
			break;

		case "HowitzerBurnEnd":
			// *** TASK 5. Path is clear, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 6. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			if (curFlowPercent >= 66)
			{
				// *** TASK 2. There are weapons here
				
				::Left4Bots.Automation.DoRegroupAt(Vector(915.705750, -6252.528809, -143.968750));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 3. After regroup, all go fire the howitzer

			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				if (::Left4Bots.Automation.DoUse("bots", "fire_howitzer", Vector(-1319.745239, -6487.446289, -3.662347)))
					::Left4Bots.Automation.step++;
			}

			break;
	}
}
