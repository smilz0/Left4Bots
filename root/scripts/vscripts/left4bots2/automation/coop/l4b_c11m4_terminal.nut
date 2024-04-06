Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c11m4_terminal automation script...\n");

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

		case "Airport04VanStarted":
			// *** TASK 4. Van started, idle until the path is clear

			::Left4Bots.Automation.ResetTasks();
			break;

		case "Airport04VanPathClear":
			// *** TASK 5. Path is clear, back to leading
			
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
			// *** TASK 3. Start the van
			
			if (curFlowPercent >= 30)
			{
				::Left4Bots.Automation.DoUse("bots", "van_button", Vector(-430.705811, 4307.923340, 16.031250));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 6. Regroup before triggering the alarm
			
			if (curFlowPercent >= 62)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(755.647827, 1234.508911, 16.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 3:
			// *** TASK 7. After regroup, go back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
