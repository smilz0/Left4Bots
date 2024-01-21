Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m2_fairgrounds automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 2. Wait for the first survivor to leave the start saferoom, then start leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "c2m2CarouselStart":
			// *** TASK 4. Carousel started, go back to leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "c2m2CarouselEnd":
			// *** TASK 6. Carousel stopped, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 7. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Start the carousel
			
			if (curFlowPercent >= 77)
			{
				::Left4Bots.Automation.DoUse("bot", "carousel_gate_button", Vector(-2829.860352, -5404.784180, -127.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 5. Stop the carousel started
			
			if (curFlowPercent >= 89)
			{
				::Left4Bots.Automation.DoUse("bots", "carousel_button", Vector(-2153.808594, -5956.031250, -63.968750));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}


