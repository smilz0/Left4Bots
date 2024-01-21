Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m4_barns automation script...\n");

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
		
		case "C2M4ButtonPressed":
			// *** TASK 4. Gates button pressed, go idle until the gates open
			
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "c2m4GateOpen":
			// *** TASK 5. Gates open, go leading up to the saferoom
			
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
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealAndGoto([ Vector(2942.561523, 3774.956543, -187.968750) ]);
			::Left4Bots.Automation.step++;
			break;
			
		case 1:
			// *** TASK 3. Open the gates to the saferoom
			
			if (curFlowPercent >= 78)
			{
				::Left4Bots.Automation.DoUse("bot", "minifinale_gates_button", Vector(-2382.254150, 1573.590820, -255.968750));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
