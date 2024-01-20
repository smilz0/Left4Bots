Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m2_fairgrounds automation script...\n");

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
		
		case "c2m2CarouselStart":
			// *** TASK 4. Carousel started, go back to leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c2m2CarouselEnd":
			// *** TASK 6. Carousel stopped, back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
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
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Start the carousel
			
			if (curFlowPercent > 77 && prevFlowPercent <= 77)
			{
				local carousel_gate_button = Entities.FindByName(null, "carousel_gate_button");
				if (carousel_gate_button && carousel_gate_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", carousel_gate_button, Vector(-2829.860352, -5404.784180, -127.968750)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", carousel_gate_button, Vector(-2829.860352, -5404.784180, -127.968750));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 5. Stop the carousel started
			
			if (curFlowPercent > 89 && prevFlowPercent <= 89)
			{
				local carousel_button = Entities.FindByName(null, "carousel_button");
				if (carousel_button && carousel_button.IsValid() && !::Left4Bots.Automation.TaskExists("bots", "use", carousel_button, Vector(-2153.808594, -5956.031250, -63.968750)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "use", carousel_button, Vector(-2153.808594, -5956.031250, -63.968750));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
