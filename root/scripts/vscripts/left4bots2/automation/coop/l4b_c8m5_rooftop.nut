Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c8m5_rooftop automation script...\n");

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
		
		case "hospital_radio_button1":
			::Left4Bots.Automation.step = 3;
			
			break;
		
		//case "FinaleTriggered":
		case "concepthospitalpilotontheway":
			// *** TASK 5. Radio used again and finale triggered, all go wait here for the entire finale
			
			::Left4Bots.Automation.DoHoldAt(Vector(5782.562988, 8444.085938, 6080.031250), Vector(6164.964355, 8445.219727, 5920.031250));
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 6. Chopper coming, let's go
			
			::Left4Bots.Automation.ResetTasks();
			//::Left4Bots.Automation.DoGotoAndIdle(Vector(7477.717773, 8685.762695, 6056.031250));
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
			if (curFlowPercent >= 90)
			{
				// *** TASK 3. Use the radio

				::Left4Bots.Automation.DoUse("bot", "radio_button", Vector(5813.912109, 8373.925781, 5920.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the 1st radio use)
		
		case 3:
			// *** TASK 4. Radio used, use it again
			
			::Left4Bots.Automation.DoUse("bot", "radio", Vector(5813.912109, 8373.925781, 5920.031250));
			::Left4Bots.Automation.step++;
			
			break;
	}
}
