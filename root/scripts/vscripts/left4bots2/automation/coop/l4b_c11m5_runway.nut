Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c11m5_runway automation script...\n");

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
		
		case "plane_radio_button1":
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 3;
			
			break;
		
		case "plane_radio_button2":
			// *** TASK 5. Fuel button pressed, go idle and let the vanilla AI handle the finale and the rescue
			
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
			// *** TASK 3. Use the radio
			
			if (curFlowPercent >= 85)
			{
				::Left4Bots.Automation.DoUse("bots", "radio_fake_button", Vector(-4997.125000, 9136.904297, -173.958755));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 2: (waiting for the radio to be used)
		
		case 3:
			// *** TASK 4. Radio used, hit the fuel button
			
			if (::Left4Bots.Automation.DoUse("bot", "radio", Vector(-4997.125000, 9136.904297, -173.958755)))
				::Left4Bots.Automation.step++;
			break;
	}
}
