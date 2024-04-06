Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c4m2_sugarmill_a automation script...\n");

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

		case "c4m2_elevator_top_button":
			// *** TASK 4. Elevator called, idle until the elevator arrives
			
			::Left4Bots.Automation.ResetTasks();
			break;

		case "c4m2_elevator_arrived":
			// *** TASK 5. Elevator arrived, all get in the elevator and press the button
			
			EntFire("elevator_wait_navblocker", "UnblockNav");
			::Left4Bots.Automation.DoUse("bots", "button_inelevator", Vector(-1476.037231, -9574.574219, 621.031250));
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 8. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Call the elevator
			
			if (curFlowPercent >= 70)
			{
				::Left4Bots.Automation.DoUse("bot", "button_callelevator", Vector(-1407.527954, -9445.394531, 608.385925));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the elevator button to be pressed)
		
		case 3:
			// *** TASK 6. Elevator button pressed, idle until the elevator is down
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step++;

			break;
		
		//case 4: (waiting for the elevator to reach the bottom)
		
		case 5:
			// *** TASK 7. Elevator is down, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			break;
	}
}

// Apparently there is no concept triggered when the elevator button is pressed, so let's do it this way
EntityOutputs.AddOutput(Entities.FindByName(null, "button_inelevator"), "OnPressed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);

// Not even a concept when the elevator is down
EntityOutputs.AddOutput(Entities.FindByName(null, "elevator"), "OnReachedBottom", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 5) ::Left4Bots.Automation.step = 5", 0, -1);

// Apparently the vanilla AI likes to teleport down the elevators while the elevator is still coming. Block the path to the elevator until it arrives
local name = "elevator_wait_navblocker";
if (Entities.FindByName(null, name) == null)
	::Left4Utils.SpawnNavBlocker(name, Vector(-1475.000000, -9482.500000, 624.262512), "-5 -5 -5", "5 5 5", 2, 0);
