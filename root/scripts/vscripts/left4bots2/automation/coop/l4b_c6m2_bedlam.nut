Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c6m2_bedlam automation script...\n");

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
			
			// Bots get stuck at these 2 breakable windows, so let's break them before the bots get there
			local ent = null;
			while (ent = Entities. FindByClassnameWithin(ent, "prop_wall_breakable", Vector(395.948303, 4404.918945, -343.968750), 300))
				ent.TakeDamage(100, 64 /* DMG_BLAST */, null);
			
			break;

		case "C6M2_OpenGate1":
			// *** TASK 9. First gate open, back to leading
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step = 7;
			break;
		
		case "C6M2_OpenGate2":
			// *** TASK 11. Second gate open, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 12. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Little workaround for broken flow
			
			if (curFlowPercent >= 13)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(252.141937, 1925.389038, -151.968750));
				::Left4Bots.Automation.step++;
			}
			break;

		case 2:
			// *** TASK 4. After workaround, go back to leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}

		case 3:
			// *** TASK 5. Go check for medkits
			
			if (curFlowPercent >= 64.5)
			{
				::Left4Bots.Automation.DoGotoAndIdle(Vector(1685.917725, 5798.720703, -1063.968750));
				::Left4Bots.Automation.step++;
			}
			break;

		case 4:
			// *** TASK 6. Go check for medkits
			if (!::Left4Bots.Automation.TaskExists("bots", "GotoAndIdle"))
			{
				::Left4Bots.Automation.DoGotoAndIdle(Vector(1688.762329, 4762.308105, -1063.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 5:
			// *** TASK 7. Go check for medkits
			if (!::Left4Bots.Automation.TaskExists("bots", "GotoAndIdle"))
			{
				::Left4Bots.Automation.DoGotoAndIdle(Vector(2425.863770, 4953.188477, -1063.968750));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 6:
			// *** TASK 8. Open the first gate
			
			::Left4Bots.Automation.DoUse("bots", "button_minifinale", Vector(2508.848145, 5640.040527, -1063.968750));
			::Left4Bots.Automation.step++;
			
			break;
			
		case 7:
			// *** TASK 10. Open the second gate
			
			if (curFlowPercent >= 78)
			{
				::Left4Bots.Automation.DoUse("bots", "button_bridge", Vector(5156.328125, 5404.054688, -1063.968750));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
