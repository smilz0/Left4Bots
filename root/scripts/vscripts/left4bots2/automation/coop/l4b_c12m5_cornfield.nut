Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c12m5_cornfield automation script...\n");

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
		
		case "farm_radio_button1":
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.step = 5;
			
			break;
		
		case "farm_radio_button2":
			// *** TASK 7. Radio used again, idle and let the vanilla AI handle the finale and the rescue
			
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
			// *** TASK 3. Regroup here before triggering the panic event
			
			if (curFlowPercent >= 47)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(8987.512695, 3842.188477, 404.604614));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 4. After regroup go back to leading
			
			if (curFlowPercent >= 65 || !::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 3:
			// *** TASK 5. Use the radio
			
			if (curFlowPercent >= 95)
			{
				::Left4Bots.Automation.DoUse("bots", "radio_button", Vector(6802.366211, 1310.517944, 238.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 4: (waiting for the radio to be used)
		
		case 5:
			// *** TASK 6. Radio used, use it again
			
			if (::Left4Bots.Automation.DoUse("bot", "radio", Vector(6802.366211, 1310.517944, 238.031250)))
				::Left4Bots.Automation.step++;
			break;
	}
}
