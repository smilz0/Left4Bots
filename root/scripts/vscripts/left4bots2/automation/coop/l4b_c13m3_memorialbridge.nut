Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c13m3_memorialbridge automation script...\n");

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

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 5. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Regroup here and trigger the explosion
			
			if (curFlowPercent >= 43)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(635.104248, -4091.494873, 1328.031250));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 4. After regroup, go back to leading up to the saferoom
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	printl("::Left4Bots.Automation.Events.OnGameEvent_round_start");
	
	// This nav_blocker blocks the area behind the open saferoom door so the bots don't get stuck there and, at the same time,
	// triggers a nav flow recomputation taking into account the nav areas blocked earlier ^
	local area = NavMesh.GetNavAreaByID(9155);
	if (area && area.IsValid())
	{
		local name = "saferoom_door_navblocker_" + area.GetID();
		if (Entities.FindByName(null, name) == null)
			::Left4Utils.SpawnNavBlocker(name, area.GetCenter(), "-5 -5 -5", "5 5 5");
	}
}
