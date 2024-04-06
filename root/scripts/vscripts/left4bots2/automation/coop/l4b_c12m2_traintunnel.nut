Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c12m2_traintunnel automation script...\n");

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
			// *** TASK 5. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Open the alarm door
			
			if (curFlowPercent >= 30)
			{
				::Left4Bots.Automation.DoUse("bots", "emergency_door", Vector(-8597.893555, -7501.024414, -63.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the alarm door to open)
		
		case 3:
			// *** TASK 4. Alarm door open, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;

			break;
	}
}

// Proceed to the next step when the alarm door is open
EntityOutputs.AddOutput(Entities.FindByName(null, "emergency_door_relay"), "OnTrigger", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);
