Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c4m3_sugarmill_b automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
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
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
	
		case 1:
			// *** TASK 3. All get in the elevator and press the button
			
			if (curFlowPercent >= 19)
			{
				::Left4Bots.Automation.DoUse("bots", "button_inelevator", Vector(-1483.924683, -9572.943359, 141.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the elevator button to be pressed)
		
		case 3:
			// *** TASK 4. Elevator button pressed, idle until the elevator is up
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step++;
			
			break;
		
		//case 4: (waiting for the elevator to reach the top)
		
		case 5:
			// *** TASK 5. Elevator is up, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			break;
	}
}

// Apparently there is no concept triggered when the elevator button is pressed, so let's do it this way
EntityOutputs.AddOutput(Entities.FindByName(null, "button_inelevator"), "OnPressed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);

// Not even a concept when the elevator is down
EntityOutputs.AddOutput(Entities.FindByName(null, "elevator"), "OnReachedTop", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 5) ::Left4Bots.Automation.step = 5", 0, -1);
