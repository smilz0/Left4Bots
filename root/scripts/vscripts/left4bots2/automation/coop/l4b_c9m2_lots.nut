Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c9m2_lots automation script...\n");

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
		
		case "CrashFinaleGeneratorOn":
			// *** TASK 5. Generator ON, idle and fight until the generator breaks
			
			::Left4Bots.Automation.ResetTasks();
			
			break;
		
		case "CrashFinaleGeneratorBreak":
			::Left4Bots.Automation.step = 5;
			
			break;
			
		case "CrashFinaleGenerator2On":
			// *** TASK 7. Generator back ON, idle and let the vanilla AI finish the map
			
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
			// *** TASK 2. Regroup here before moving to the finale area
			
			if (curFlowPercent >= 78)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(5333.345703, 6580.538086, 52.489586));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 3. After 1st regroup, regroup near the finale ammo stack
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(7248.553711, 6495.471680, 45.589081));
				::Left4Bots.Automation.step++;
			}

			break;
			
		case 3:
			// *** TASK 4. After 2nd regroup, someone go start the generator

			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				if (::Left4Bots.Automation.DoUse("bot", "finaleswitch_initial", Vector(6860.150879, 5937.352539, 42.814075)))
					::Left4Bots.Automation.step++;
			}
			break;
		
		//case 4: (waiting for the finale generator to break)
		
		case 5:
			// *** TASK 6. Generator stopped, start it again
			
			if (::Left4Bots.Automation.DoUse("bot", "generator_switch", Vector(6860.150879, 5937.352539, 42.814075)))
				::Left4Bots.Automation.step++;
			break;
	}
}
