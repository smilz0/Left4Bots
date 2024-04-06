Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c10m5_houseboat automation script...\n");

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
		
		case "boat_radio_button1":
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 4;
			
			break;
		
		case "boat_radio_button2":
			// *** TASK 6. Radio button pressed again, wait near the ammo for the entire finale
			
			::Left4Bots.Automation.DoHoldAt(Vector(3643.842773, -4549.963379, -151.968750), Vector(3489.666260, -3579.736084, -180.804489));
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 7. Boat coming, go idle and let the vanilla AI handle the escape
			
			::Left4Bots.Automation.ResetTasks();

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
			// *** TASK 3. There is useful stuff here
			
			if (curFlowPercent >= 75)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(3360.168945, -2811.396973, -84.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 4. After regroup, all go use the finale radio
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoUse("bots", "radio_button", Vector(3895.501465, -4133.611328, -151.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 3: (waiting for the radio button to be pressed)
		
		case 4:
			// *** TASK 5. Radio button pressed, press it again to start the finale
			
			if (::Left4Bots.Automation.DoUse("bot", "radio", Vector(3895.501465, -4133.611328, -151.968750)))
				::Left4Bots.Automation.step++;
			break;
	}
}
