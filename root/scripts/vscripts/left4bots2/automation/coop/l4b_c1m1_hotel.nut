Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c1m1_hotel automation script...\n");

::Left4Bots.Automation.step <- 1;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
			if (::Left4Bots.Automation.step > 1)
				return; // !!! This also triggers when a survivor is defibbed later in the game !!!
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c1m1_elevator_start":
			// *** TASK 3. Go idle after the elevator button was pressed

			::Left4Bots.Automation.ResetTasks();
			break;
			
		case "c1m1_elevator_ready":
			// *** TASK 4. When the elevator reaches the bottom floor, order one bot to open the doors
			
			local elevator_door_button1 = Entities.FindByName(null, "elevator_door_button1");
			if (elevator_door_button1 && elevator_door_button1.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", elevator_door_button1, Vector(2164.798340, 5753.712402, 1188.031250)))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bot", "use", elevator_door_button1, Vector(2164.798340, 5753.712402, 1188.031250));
			}
			break;
		
		case "c1m1_elevator_door_open":
			// *** TASK 5. When the elevator doors open, order the bots to hold in front of it for 10 seconds
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HoldAt"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HoldAt(Vector(2184.934570, 5546.779297, 1184.031250), 10));
				
				::Left4Bots.Automation.step = 3;
			}
			break;
			
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 7. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			//::Left4Bots.Automation.ResetTasks(); // <- Apparently this makes the game crash when they enter the saferoom. Likely because of the RESET...
			// ...Better remove the task and let the lead order complete
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	//::Left4Bots.Logger.Debug("Automation.OnFlow(" + prevFlowPercent + " -> " + curFlowPercent + ")");
	
	switch(::Left4Bots.Automation.step)
	{
		case 1:
			if (curFlowPercent >= 52 && prevFlowPercent < 52)
			{
				// *** TASK 2. At the end of the corridor that leads to the elevator, order all the bots to press the elevator button

				local elevator_button = Entities.FindByName(null, "elevator_button");
				if (elevator_button && elevator_button.IsValid() && !::Left4Bots.Automation.TaskExists("bots", "use", elevator_button, Vector(2237.244141, 5769.408203, 2464.031250)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "use", elevator_button, Vector(2237.244141, 5769.408203, 2464.031250));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 3:
			// *** TASK 6. After holding for 10 seconds, start leading again up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HoldAt"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

/*
::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	Left4Bots.Logger.Debug("Automation.Events.OnGameEvent_round_start");
}
*/
