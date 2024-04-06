Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c13m1_alpinecreek automation script...\n");

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
			if (curFlowPercent >= 82)
			{
				// *** TASK 2. Open the bunker
				
				::Left4Bots.Automation.DoUse("bot", "bunker_button", Vector(1056.769043, 224.648315, 720.031250), true, 6); // <- No need to open it entirely
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 3. When the door is open enough, go back to leading up to the saferoom

			local move_door = Entities.FindByName(null, "move_door");
			if (move_door && move_door.IsValid() && move_door.GetOrigin().y < -200)
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
