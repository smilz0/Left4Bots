Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c12m3_bridge automation script...\n");

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

		case "TrainUnhooked":
			// *** TASK 5. Train unhooked, idle until the bridge is down
			
			::Left4Bots.Automation.ResetTasks();

			break;

		case "BridgeReadyToCross":
			// *** TASK 6. Bridge down, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 7. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. There are useful items in the house, regroup there before starting the panic event
			
			if (curFlowPercent >= 75)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(6677.284180, -12867.667969, -43.968750));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 4. After regroup, go unhook the train
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoUse("bots", "train_engine_button", Vector(8062.569336, -13569.922852, 12.031250));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
