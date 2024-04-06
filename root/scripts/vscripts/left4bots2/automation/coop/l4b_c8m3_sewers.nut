Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c8m3_sewers automation script...\n");

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
			// *** TASK 7. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			if (curFlowPercent >= 15)
			{
				// *** TASK 3. Start the lift

				::Left4Bots.Automation.DoUse("bots", "washer_lift_button2", Vector(12658.458008, 7317.577637, 61.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the lift to start)
		
		case 3:
			// *** TASK 4. Lift started, idle until the lift is up
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step++;
			
			break;
		
		//case 4: (waiting for the lift to reach the top)
		
		case 5:
			// *** TASK 5. Lift is up, go regroup in the building
			
			//::Left4Bots.Automation.DoRegroupAt(Vector(10818.195313, 6949.717285, 296.031250)); // Upper floor
			::Left4Bots.Automation.DoRegroupAt(Vector(10810.408203, 7015.356934, 160.031250)); // Lower floor (with ammo and pills)
			::Left4Bots.Automation.step++;

			break;
		
		case 6:
			// *** TASK 6. Wait for the regroup, then go back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

// Proceed to the next step when the lift is started
EntityOutputs.AddOutput(Entities.FindByName(null, "washer_lift_up_relay"), "OnTrigger", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);

// Proceed to the next step when the lift is up
EntityOutputs.AddOutput(Entities.FindByName(null, "washer_lift"), "OnReachedTop", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 5) ::Left4Bots.Automation.step = 5", 0, -1);
