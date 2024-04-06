Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c13m2_southpinestream automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;
::Left4Bots.Automation.avoidAreas <- [461313, 461304, 504112, 461287, 461395, 461306, 461286, 424733, 424709, 424670, 424739]; // Avoid these common stuck/slow spots

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

		case "C13M2BarrelsIgnited":
			// *** TASK 5. Barrels ignited, back up!
			
			::Left4Bots.Automation.DoWait("bots", Vector(710.671082, 5763.595215, 273.049255), false); // Back up no pauses
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
	
	// Make sure the areas listed in avoidAreas are always DAMAGING so the bots will try to avoid them
	for (local i = 0; i < ::Left4Bots.Automation.avoidAreas.len(); i++)
	{
		local area = NavMesh.GetNavAreaByID(::Left4Bots.Automation.avoidAreas[i]);
		if (area && area.IsValid() && !area.IsDamaging())
			area.MarkAsDamaging(99999);
	}
	
	switch(::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Regroup here before triggering the panic event
			
			if (curFlowPercent >= 75)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(710.671082, 5763.595215, 273.049255));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 4. After regroup, all shoot the barrels
				
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoDestroy("bots", "bridge_dummy", Vector(460.935181, 5444.702148, 272.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 3: (waiting for the barrels to explode)
		
		case 4:
			// *** TASK 6. Barrels exploded, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;

			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	printl("::Left4Bots.Automation.Events.OnGameEvent_round_start");

	// Survivors can't walk through this. Force a nav flow rebuild avoiding these areas
	local l4bbetternavflow = Entities.FindByName(null, "l4bbetternavflow");
	if (!l4bbetternavflow)
		::Left4Utils.SpawnNavBlocker("l4bbetternavflow", Vector(4912.500000, 1462.500000, 368.065308), "-30 -300 -100", "30 300 10", 2);
	
	/* Lower the barrel's health so the bots can ignite them faster (kind of cheating tho)
	local bridge_dummy = Entities.FindByName(null, "bridge_dummy");
	if (bridge_dummy && bridge_dummy.IsValid())
		bridge_dummy.SetHealth(100); // Default: 500;
	*/
}

// Proceed to the next step when the barrels explode
EntityOutputs.AddOutput(Entities.FindByName(null, "bridge_murette"), "OnBreak", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 4) ::Left4Bots.Automation.step = 4", 0, -1);
