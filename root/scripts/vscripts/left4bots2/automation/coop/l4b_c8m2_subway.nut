Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c8m2_subway automation script...\n");

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
			if (curFlowPercent >= 62)
			{
				// *** TASK 3. Someone go press the button

				// For some reason the button has no name but it's the only func_button on the map
				::Left4Bots.Automation.DoUseNoName("bot", "func_button", Vector(7319.290039, 3291.947266, 16.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the button to be pressed)
		
		case 3:
			// *** TASK 4. Button pressed, go wait here until the door is open
			
			::Left4Bots.Automation.DoWait("bots", Vector(7817.504395, 4036.855713, 36.920250));
			::Left4Bots.Automation.step++;

			break;
		
		//case 4: (waiting for the door to open)
		
		case 5:
			// *** TASK 5. Door open, back to leading up to the saferoom

			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			break;
	}
}

// Proceed to the next step when the button is pressed
EntityOutputs.AddOutput(Entities.FindByName(null, "filter_generator"), "OnPass", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);

// Proceed to the next step when the door is open
EntityOutputs.AddOutput(Entities.FindByName(null, "door_sliding"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 5) ::Left4Bots.Automation.step = 5", 0, -1);
