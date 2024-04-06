Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c10m4_mainstreet automation script...\n");

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
			if (curFlowPercent >= 50)
			{
				// *** TASK 3. Regroup before proceeding with the panic event
				
				::Left4Bots.Automation.DoRegroupAt(Vector(2107.620361, -3952.787842, -59.105595));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 4. After regroup, all press the forklift button
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoUse("bots", "button", Vector(1104.391357, -4143.024414, -63.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 3: (waiting for the forklift button to be pressed)
		
		case 4:
			// *** TASK 5. Forklift button pressed, idle until the path is clear
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step++;
			
			break;
		
		case 5:
			// *** TASK 6. Wait until the path is clear, then go back to leading up to the saferoom
			
			local player_block_ramp = Entities.FindByName(null, "player_block_ramp");
			if (!player_block_ramp || !player_block_ramp.IsValid())
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

// Proceed to the next step when the forklift button is pressed
EntityOutputs.AddOutput(Entities.FindByName(null, "button"), "OnPressed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 4) ::Left4Bots.Automation.step = 4", 0, -1);
