Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m5_concert automation script...\n");

::Left4Bots.Automation.step <- 0;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			if (::Left4Bots.Automation.step > 1)
				return; // !!! This also triggers when a survivor is defibbed later in the game !!!
		
			// *** TASK 2. Wait for the first survivor to leave the start saferoom, then start leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "c2m5Button1":
			// *** TASK 4. Lights ON, start the concert
			
			local stage_escape_button = Entities.FindByName(null, "stage_escape_button");
			if (stage_escape_button && stage_escape_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", stage_escape_button, Vector(-1878.096558, 3376.330811, -175.968750)))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bot", "use", stage_escape_button, Vector(-1878.096558, 3376.330811, -175.968750));
			}
			break;
		
		case "FinaleTriggered":
			// *** TASK 5. Concert started, wait near the ammo stack for the entire finale
			
			local ammo = Entities.FindByName(null, "item_spawn_set1_ammo");
			if (!ammo)
				ammo = Entities.FindByName(null, "item_spawn_set2_ammo");
			
			// [L4D][INFO]   183 |                        weapon_ammo_spawn |                                         item_spawn_set1_ammo | -02280.9375,003256.0000,-00176.0000 | models/props/terror/ammo_stack.mdl
			// [L4D][INFO]   183 |                        weapon_ammo_spawn |                                         item_spawn_set2_ammo | -02337.6250,002427.5625,-00063.7188 | models/props/terror/ammo_stack.mdl
			
			if (ammo && ammo.IsValid() && !::Left4Bots.Automation.TaskExists("bots", "wait", null, ammo.GetOrigin()))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "wait", null, ammo.GetOrigin());
			}
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 6. Chopper coming, go meet it at its landing spot for a quicker escape
			
			//local stadium_exit_left_relay = Entities.FindByName(null, "stadium_exit_left_relay");
			local stadium_exit_right_relay = Entities.FindByName(null, "stadium_exit_right_relay");
			local left = NetProps.GetPropInt(stadium_exit_right_relay, "m_bDisabled");
			local waitpos = left == 1 ? Vector(-1062.592041, 2497.011475, 24.165833) : Vector(-3686.272217, 3011.679688, -8.828863);
			
			if (!::Left4Bots.Automation.TaskExists("bots", "wait", null, waitpos))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "wait", null, waitpos);
			}
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
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HealAndGoto"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealAndGoto([ Vector(-675.433411, 2177.320313, -255.968979) ]));
			}
			
			::Left4Bots.Automation.step++;
			break;
			
		case 1:
			// *** TASK 3. Turn on the lights
			
			if (curFlowPercent > 67 && prevFlowPercent <= 67)
			{
				local stage_lights_button = Entities.FindByName(null, "stage_lights_button");
				if (stage_lights_button && stage_lights_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", stage_lights_button, Vector(-2281.586914, 2082.279541, 128.031250)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", stage_lights_button, Vector(-2281.586914, 2082.279541, 128.031250));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
