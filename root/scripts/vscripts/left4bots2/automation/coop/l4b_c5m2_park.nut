Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c5m2_park automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;
::Left4Bots.Automation.allin <- false;

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

		case "C502AlarmStopped":
			// *** TASK 5. Alarm stopped. Idle until the building's doors open
			
			CurrentTasks.clear();
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
			// *** TASK 3. Wait for all to get into the CEDA trailer, then close the entrance door and open the exit one
			
			local finale_cleanse_exit_door = Entities.FindByName(null, "finale_cleanse_exit_door");
			if (finale_cleanse_exit_door && finale_cleanse_exit_door.IsValid())
			{
				if (NetProps.GetPropInt(finale_cleanse_exit_door, "m_bLocked"))
				{
					// CEDA trailer exit door still locked, check if we the entrance door still needs to close
					if (::Left4Bots.Automation.allin)
					{
						// We are all in the trailer
						local finale_cleanse_entrance_door = Entities.FindByName(null, "finale_cleanse_entrance_door");
						if (finale_cleanse_entrance_door && finale_cleanse_entrance_door.IsValid() && NetProps.GetPropInt(finale_cleanse_entrance_door, "m_eDoorState") == 2 /* OPEN */)
						{
							// Entrance door still open, someone close it
							::Left4Bots.Automation.DoUse("bot", "finale_cleanse_entrance_door", Vector(-9654.945313, -5691.519531, -213.083099));
						}
					}
				}
				else
				{
					// CEDA trailer exit door is unlocked, this means that we are all in the trailer and the entrance door is closed. Check if the exit door needs to open
					if (NetProps.GetPropInt(finale_cleanse_exit_door, "m_eDoorState") == 0 /* CLOSED */)
					{
						// Still closed, someone open it
						::Left4Bots.Automation.DoUse("bot", "finale_cleanse_exit_door", Vector(-9575.561523, -6039.125977, -213.945755));
					}
				}
			}
			
			break;
		
		case 2:
			// *** TASK 4. CEDA trailer exit door open, all go press the stop alarm button
			
			if (::Left4Bots.Automation.DoUse("bots", "finale_alarm_stop_button", Vector(-8163.214844, -5836.873047, -32.218750)))
				::Left4Bots.Automation.step++;
			break;
		
		// case 3: (waiting for the alarm to stop and the building doors to open)
		
		case 4:
			// *** TASK 6. Building's doors are open, go back to leading up to the saferoom

			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			break;
	}
}

// Set a flag when all the survivors are inside the CEDA trailer
EntityOutputs.AddOutput(Entities.FindByName(null, "finale_decon_trigger"), "OnEntireTeamStartTouch", "worldspawn", "RunScriptCode", "::Left4Bots.Automation.allin = true", 0, -1);
EntityOutputs.AddOutput(Entities.FindByName(null, "finale_decon_trigger"), "OnEntireTeamEndTouch", "worldspawn", "RunScriptCode", "::Left4Bots.Automation.allin = false", 0, -1);

// Triggers when the CEDA trailer exit door opens
EntityOutputs.AddOutput(Entities.FindByName(null, "finale_cleanse_exit_door_relay"), "OnTrigger", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 2) ::Left4Bots.Automation.step = 2", 0, -1);

// Alarm stopped and the end doors are open
EntityOutputs.AddOutput(Entities.FindByName(null, "finale_end_doors_right"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 4) ::Left4Bots.Automation.step = 4", 0, -1);
