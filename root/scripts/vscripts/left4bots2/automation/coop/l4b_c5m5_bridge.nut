Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c5m5_bridge automation script...\n");

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
		
			// *** TASK 2. Use the radio
			
			::Left4Bots.Automation.DoUse("bot", "radio_fake_button", Vector(-11554.702148, 6191.389648, 466.008453));
			break;

		case "c5m5Button":
			// *** TASK 3. Radio used, wait for the bridge button to be available
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 2;
			break;

		case "C5M5button2":
			// *** TASK 5. Bridge button pressed, idle until the bridge is down and the finale is started
			
			::Left4Bots.Automation.ResetTasks();
			break;

		case "FinaleTriggered":
			// *** TASK 6. Bridge is down and finale triggered, go leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "FinalVehicleArrived":
			// *** TASK 7. The flow is broken here (maybe it can be fixed with the same technique used in l4b_c3m3_shantytown.nut ?), let's 'goto' to the chopper
			
			::Left4Bots.Automation.DoGotoAndIdle(Vector(7479.217773, 3353.315430, 168.031250));
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
		
		//case 1: (wait for the radio to be used)
		
		case 2:
			// *** TASK 4. Press the bridge button to start the finale
			
			if (::Left4Bots.Automation.DoUse("bot", "finale", Vector(-11532.093750, 6121.568848, 460.031250)))
				::Left4Bots.Automation.step++;
			break;
	}
}
