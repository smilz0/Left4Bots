Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c1m3_mall automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;
::Left4Bots.Automation.minifinale <- 0;
::Left4Bots.Automation.avoidAreas <- [1095, 118545, 118546, 4018, 314746]; // Avoid these common stuck spots

::Left4Bots.Automation.SetElevatorPath <- function(num)
{
	printl("SetElevatorPath(" + num + ")");
	
	// Navblockers that are meant to be unblocked for each path
	local paths = {};
	paths[1] <- ["escalator_lower_01-navblocker", "escalator_lower_03-navblocker", "escalator_upper_01-navblocker", "escalator_upper_03-navblocker"];
	paths[2] <- ["escalator_lower_01-navblocker", "escalator_lower_04-navblocker", "escalator_upper_02-navblocker", "escalator_upper_04-navblocker"];
	paths[3] <- ["escalator_lower_01-navblocker", "escalator_lower_03-navblocker", "escalator_upper_02-navblocker", "escalator_upper_04-navblocker"];
	paths[4] <- ["escalator_lower_01-navblocker", "escalator_lower_04-navblocker", "escalator_upper_02-navblocker", "escalator_upper_03-navblocker"];
	paths[5] <- ["escalator_lower_02-navblocker", "escalator_lower_04-navblocker", "escalator_upper_01-navblocker", "escalator_upper_03-navblocker"];
	paths[6] <- ["escalator_lower_02-navblocker", "escalator_lower_03-navblocker", "escalator_upper_01-navblocker", "escalator_upper_04-navblocker"];
	paths[7] <- ["escalator_lower_02-navblocker", "escalator_lower_03-navblocker", "escalator_upper_01-navblocker", "escalator_upper_03-navblocker"];
	paths[8] <- ["escalator_lower_02-navblocker", "escalator_lower_04-navblocker", "escalator_upper_01-navblocker", "escalator_upper_04-navblocker"];
	
	if (!(num in paths))
	{
		printl("Error: " + num + " is not a valid path number");
		return;
	}
	
	// Blocking all the 'escalator' navblockers except the ones that are meant to be unblocked for this path
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "func_nav_blocker"))
	{
		local name = ent.GetName();
		if (name.find("escalator") != null)
		{
			if (paths[num].find(name) == null)
			{
				DoEntFire("!self", "BlockNav", "", 1, ent, ent);
				printl(name + " blocked");
			}
		}
	}
}

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
		
		case "C1M3AlarmDoor":
		case "C1M3BrokeWindow":
			// *** TASK 5. Alarm set, go press the stop alarm button on the upper floor
			
			// For some reason the button has no name but it's the only func_button on the map
			local stop_alarm_button = Entities.FindByClassname(null, "func_button");
			if (stop_alarm_button && stop_alarm_button.IsValid() && !::Left4Bots.Automation.TaskExists("bots", "use", stop_alarm_button))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "use", stop_alarm_button, Vector(940.319031, -5178.390137, 536.031250));
			}
			
			::Left4Bots.Automation.step = 3;
			break;
			
		case "C1M3AlarmOff":
			// *** TASK 6. Alarm is off, go back to leading up to the saferoom
			
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
	// Make sure the areas listed in avoidAreas are always DAMAGING so the bots will try to avoid them
	for (local i = 0; i < ::Left4Bots.Automation.avoidAreas.len(); i++)
	{
		local area = NavMesh.GetNavAreaByID(::Left4Bots.Automation.avoidAreas[i]);
		if (area && area.IsValid() && !area.IsDamaging())
			area.MarkAsDamaging(99999);
	}
	
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Wait for the minifinale (one of the 2 dynamic paths) to be set
			
			if (::Left4Bots.Automation.minifinale == 1)
			{
				Left4Bots.Logger.Debug("Automation.Events.OnFlow - Stairwell minifinale");
				NavMesh.GetNavAreaByID(53672).UnblockArea(); // Unblock the area in front of the alarm door so the bots can open the door
				::Left4Bots.Automation.step++;
			}
			else if (::Left4Bots.Automation.minifinale == 2)
			{
				Left4Bots.Logger.Debug("Automation.Events.OnFlow - Hallway minifinale");
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 4. Depending on the choosen minifinale, when near the breakable glass/alarm door, break/open it
			
			if (::Left4Bots.Automation.minifinale == 1 && curFlowPercent >= 55.8)
			{
				::Left4Bots.Automation.DoUse("bot", "door_hallway_lower4a", Vector(967.269592, -2962.729248, 0.031250));
				::Left4Bots.Automation.step++;
			}
			else if (::Left4Bots.Automation.minifinale == 2 && curFlowPercent >= 54)
			{
				::Left4Bots.Automation.DoDestroy("bot", "breakble_glass_minifinale", Vector(1188.252319, -2411.302002, 280.031250));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	printl("::Left4Bots.Automation.Events.OnGameEvent_round_start");

	local ent = null;
	while (ent = Entities.FindByClassname(ent, "func_nav_blocker"))
	{
		if (ent.GetName().find("escalator") != null)
		{
			NetProps.SetPropInt(ent, "m_bAffectsFlow", 1);
			DoEntFire("!self", "UnblockNav", "", 1, ent, ent); // Idk why UnblockNav needs this delay but it fails without it
		}
	}
}

// relay_hallway_close triggers the Stairwell (Alarm door) minifinale
EntityOutputs.AddOutput(Entities.FindByName(null, "relay_hallway_close"), "OnTrigger", "worldspawn", "RunScriptCode", "::Left4Bots.Automation.minifinale = 1", 0, -1);
// relay_stairwell_close triggers the Hallway (Breakable glass) minifinale
EntityOutputs.AddOutput(Entities.FindByName(null, "relay_stairwell_close"), "OnTrigger", "worldspawn", "RunScriptCode", "::Left4Bots.Automation.minifinale = 2", 0, -1);

for (local i = 1; i <= 8; i++)
	EntityOutputs.AddOutput(Entities.FindByName(null, "relay_elevator_path_0" + i), "OnTrigger", "worldspawn", "RunScriptCode", "::Left4Bots.Automation.SetElevatorPath(" + i + ")", 0, -1);

/*
local compare_minifinale = Entities.FindByName(null, "compare_minifinale");
//local m_flInValue = NetProps.GetPropFloat(compare_minifinale, "m_flInValue"); // 6
//printl("m_flInValue: " + m_flInValue);

// Do no call this, it is automatically triggered when the survivors pass the one way barricade at the beginning of the corridor that leads to the 2 dynamic paths
//DoEntFire("!self", "SetCompareValue", "6", 0, compare_minifinale, compare_minifinale);
// SetCompareValue <  6 -> relay_hallway_close
// SetCompareValue >= 6 -> relay_stairwell_close

// Set m_flInValue instead
//NetProps.SetPropFloat(compare_minifinale, "m_flInValue", 1); // Force stairwell minifinale
NetProps.SetPropFloat(compare_minifinale, "m_flInValue", 16); // Force hallway minifinale
*/


