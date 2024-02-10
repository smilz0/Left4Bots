Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_automation_map_default automation script...\n");

::Left4Bots.Automation.step <- Director.GetMapNumber() == 0 ? 1 : 0;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 2. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading
			
			// In most custom campaigns they will likely get stuck at some door or something, so it's better to proceed via vanilla AI
			//::Left4Bots.Automation.DoLead("bots");
			break;
			
		case "PlayerPourFinished":
			// *** TASK 4. Stop the scavenge when it's done
			
			local score = null;
			local towin = null;

			if ("Score" in query)
				score = query.Score.tointeger();
			if ("towin" in query)
				towin = query.towin.tointeger();

			if (score != null && towin != null)
				::Left4Bots.Logger.Info("Poured: " + score + " - Left: " + towin);

			if (towin == 0 && ::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				::Left4Bots.Logger.Info("Scavenge complete");
				::Left4Bots.Automation.ResetTasks();
			}
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 5a. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
		
		case "FinalVehicleArrived":
			// *** TASK 5b. If this was the last map of the campaign and the rescue vehicle arrived, just go idle and let the vanilla AI do the rest
			
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
			// *** TASK 1. Heal while in the start saferoom (if this was not the first map of the campaign)
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Check if there is an active scavenge and start the task if needed
			
			if (!::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				local ent = Entities.FindByClassname(null, "game_scavenge_progress_display");
				if (ent && ent.IsValid() && NetProps.GetPropInt(ent, "m_bActive"))
				{
					::Left4Bots.Automation.DoScavenge();
					::Left4Bots.Automation.step++;
				}
			}
			
			break;
	}
}
