Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m5_concert automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
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
		
		case "c2m5Button1":
			// *** TASK 4. Lights ON, start the concert
			
			::Left4Bots.Automation.DoUse("bot", "stage_escape_button", Vector(-1878.096558, 3376.330811, -175.968750));
			break;
		
		case "FinaleTriggered":
			// *** TASK 5. Concert started, wait near the ammo stack for the entire finale
			
			local ammo = Entities.FindByName(null, "item_spawn_set1_ammo");
			if (!ammo)
				ammo = Entities.FindByName(null, "item_spawn_set2_ammo");
			
			if (ammo && ammo.IsValid())
				::Left4Bots.Automation.DoWait("bots", ammo.GetOrigin());
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 6. Chopper coming, go meet it at its landing spot for a quicker escape
			
			//local stadium_exit_left_relay = Entities.FindByName(null, "stadium_exit_left_relay");
			local stadium_exit_right_relay = Entities.FindByName(null, "stadium_exit_right_relay");
			local left = NetProps.GetPropInt(stadium_exit_right_relay, "m_bDisabled");
			local waitpos = left == 1 ? Vector(-1062.592041, 2497.011475, 24.165833) : Vector(-3686.272217, 3011.679688, -8.828863);
			
			::Left4Bots.Automation.DoWait("bots", waitpos);
			break;
		
		case "FinalVehicleArrived":
			// *** TASK 7. Chopper landed, go idle and let the vanilla AI go inside
			
			::Left4Bots.Automation.ResetTasks();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom (and make sure they go grab the medkits behind the wall)
			
			::Left4Bots.Automation.DoHealAndGoto([ Vector(-675.433411, 2177.320313, -255.968979) ]);
			::Left4Bots.Automation.step++;
			break;
			
		case 1:
			// *** TASK 3. Turn on the lights
			
			if (curFlowPercent >= 67)
			{
				::Left4Bots.Automation.DoUse("bot", "stage_lights_button", Vector(-2281.586914, 2082.279541, 128.031250));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
