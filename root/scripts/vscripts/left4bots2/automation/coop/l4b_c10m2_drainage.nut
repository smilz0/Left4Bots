Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c10m2_drainage automation script...\n");

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

		case "BridgeReadyToCross":
			// *** TASK 5. Gate open, back to leading up to the saferoom
			
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
			if (curFlowPercent >= 37)
			{
				// *** TASK 3. Press the minifinale button
				
				::Left4Bots.Automation.DoUse("bot", "button_minifinale", Vector(-8695.597656, -7829.208008, -395.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the minifinale button to be pressed)
		
		case 3:
			// *** TASK 4. Minifinale button pressed, idle until the gate opens
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step++;
			
			break;
	}
}

// Proceed to the next step when the minifinale button is pressed
EntityOutputs.AddOutput(Entities.FindByName(null, "button_minifinale"), "OnPressed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);
