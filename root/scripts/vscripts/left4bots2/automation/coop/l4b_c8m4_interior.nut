Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c8m4_interior automation script...\n");

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
			if (curFlowPercent >= 35)
			{
				// *** TASK 3. Call the elevator

				// This button has no name
				::Left4Bots.Automation.DoUseNoName("bots", "func_button", Vector(13488.784180, 15074.621094, 424.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the elevator button to be pressed)
		
		case 3:
			// *** TASK 4. Elevator called, idle until it comes
			
			// Don't stay idle here or the vanilla AI will teleport and fall to death right before the elevator reaches the bottom
			::Left4Bots.Automation.DoWait("bots", Vector(12009.153320, 14681.099609, 424.031250)); // Safest room
			//::Left4Bots.Automation.DoWait("bots", Vector(13454.908203, 14650.862305, 424.031250)); // Near the ammo
			::Left4Bots.Automation.step++;
			
			break;
		
		//case 4: (waiting for the elevator to come)
		
		case 5:
			// *** TASK 5. Elevator is here, all go press the up button
			
			::Left4Bots.Automation.DoUse("bots", "elevator_button", Vector(13496.271484, 15173.877930, 425.031250));
			::Left4Bots.Automation.step++;
			
			break;
		
		//case 6: (waiting for the up elevator button to be pressed)
		
		case 7:
			// *** TASK 6. Elevator up button pressed, idle until the elevator reaches the top
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step++;
			
			break;
		
		//case 8: (waiting for the elevator to reach the top)
		
		case 9:
			// *** TASK 7. Elevator reached the top, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			break;
	}
}

// Proceed to the next step when the elevator button is pressed
local button = Entities.FindByClassnameWithin(null, "func_button", Vector(13488.784180, 15074.621094, 424.031250), 200);
if (button)
	EntityOutputs.AddOutput(button, "OnPressed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);
else
	::Left4Bots.Logger.Error("Automation - button not found!!!");

// Proceed to the next step when the elevator reaches the bottom
EntityOutputs.AddOutput(Entities.FindByName(null, "door_elevouterlow"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 5) ::Left4Bots.Automation.step = 5", 0, -1);

// Proceed to the next step when the up elevator button is pressed
EntityOutputs.AddOutput(Entities.FindByName(null, "elevator_button"), "OnPressed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 7) ::Left4Bots.Automation.step = 7", 0, -1);

// Proceed to the next step when the elevator reaches the top
EntityOutputs.AddOutput(Entities.FindByName(null, "door_elevouterhigh"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 9) ::Left4Bots.Automation.step = 9", 0, -1);
