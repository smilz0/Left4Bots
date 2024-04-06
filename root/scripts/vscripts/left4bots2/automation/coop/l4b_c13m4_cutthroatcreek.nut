Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c13m4_cutthroatcreek automation script...\n");

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
		
			// *** TASK 2. Wait for the first survivor to leave the start saferoom, then all go use the radio
			
			::Left4Bots.Automation.DoUse("bots", "startbldg_door_button", Vector(-4127.968750, -7873.937500, 371.031250));
			break;
		
		case "C13M4Button1":
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 2;
			
			break;
		
		case "FinaleTriggered":
			// *** TASK 4. Door button used, go idle until the door is fully open
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 3;
			
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 10. Make sure to free the bots after they trigger the infinite panic event, even if they did it before the last regroup finished
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 9;

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
		
		//case 1: (waiting for the radio to be used)
		
		case 2:
			// *** TASK 3. Radio used, someone press the door button
			
			if (::Left4Bots.Automation.DoUse("bot", "finale", Vector(-4109.222168, -7804.876465, 371.031250)))
				::Left4Bots.Automation.step++;
			break;
		
		//case 3: (waiting for the door to open)
		
		case 4:
			// *** TASK 5. Door open, regroup just before the 1st drop
			
			::Left4Bots.Automation.DoRegroupAt(Vector(-3807.154053, -5786.145020, 322.953735));
			::Left4Bots.Automation.step++;
			
			break;
			
		case 5:
			// *** TASK 6. After regroup, go leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 6:
			// *** TASK 7. 2nd regroup before the 2nd drop
			
			if (curFlowPercent >= 36)
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
					::Left4Bots.Automation.DoRegroupAt(Vector(-2356.734131, -1685.954468, 44.206959));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 7:
			// *** TASK 8. After regroup, go leading again
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 8:
			// *** TASK 9. Last regroup before the infinite panic event
			
			if (curFlowPercent >= 68)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(-1208.356689, 3622.707520, -117.968750));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

// Proceed to the next step when the finale door opens
EntityOutputs.AddOutput(Entities.FindByName(null, "startbldg_door"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 4) ::Left4Bots.Automation.step = 4", 0, -1);
