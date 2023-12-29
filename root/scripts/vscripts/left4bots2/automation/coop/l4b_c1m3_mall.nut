Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c1m3_mall automation script...\n");

::Left4Bots.Automation.step <- 0;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "SurvivorLeavingInitialCheckpoint":
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "C1M3AlarmDoor":
		case "C1M3BrokeWindow":
			::Left4Bots.Automation.step = 3;
		
			// For some reason the button has no name but it's the only func_button on the map
			local stop_alarm_button = Entities.FindByClassname(null, "func_button");
			if (stop_alarm_button && stop_alarm_button.IsValid())
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "use", stop_alarm_button))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "use", stop_alarm_button, Vector(940.319031, -5178.390137, 536.031250));
				}
			}
			else
				::Left4Bots.Logger.Error("Automation.OnConcept - stop_alarm_button not found!!!");
			break;
			
		case "C1M3AlarmOff":
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
			
		case "SurvivorBotReachedCheckpoint":
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			if (curFlowPercent > 42)
				::Left4Bots.Automation.step++;
			break;
			
		case 2:
			local door_hallway = Entities.FindByName(null, "door_hallway");
			if (!door_hallway && door_hallway.IsValid())
			{
				Left4Bots.Logger.Error("Automation.Events.OnFlow - door_hallway not found!");
				::Left4Bots.Automation.step = 3;
				return;
			}
			
			local closed = NetProps.GetPropInt(door_hallway, "m_eDoorState") == 0;
			if (closed && curFlowPercent >= 55.8 && prevFlowPercent < 55.8)
			{
				// We are at the alarm door
				Left4Bots.Logger.Debug("Automation.Events.OnFlow - stairwell minifinale");
				
				local door_hallway_lower4a = Entities.FindByName(null, "door_hallway_lower4a");
				if (door_hallway_lower4a && door_hallway_lower4a.IsValid())
				{
					if (!::Left4Bots.Automation.TaskExists("bot", "use", door_hallway_lower4a))
					{
						::Left4Bots.Automation.ResetTasks();
						::Left4Bots.Automation.AddTask("bot", "use", door_hallway_lower4a, Vector(967.269592, -2962.729248, 0.031250));
					}
				}
				else
					Left4Bots.Logger.Error("Automation.Events.OnFlow - door_hallway_lower4a not found!");
				
				::Left4Bots.Automation.step++;
			}
			else if (curFlowPercent >= 54 && prevFlowPercent < 54)
			{
				// We are at the breakable glass
				Left4Bots.Logger.Debug("Automation.Events.OnFlow - hallway minifinale");
				
				local breakble_glass_minifinale = Entities.FindByName(null, "breakble_glass_minifinale");
				if (breakble_glass_minifinale && breakble_glass_minifinale.IsValid())
				{
					if (!::Left4Bots.Automation.TaskExists("bot", "destroy", breakble_glass_minifinale))
					{
						::Left4Bots.Automation.ResetTasks();
						::Left4Bots.Automation.AddTask("bot", "destroy", breakble_glass_minifinale, Vector(1188.252319, -2411.302002, 280.031250));
					}
				}
				else
					Left4Bots.Logger.Error("Automation.Events.OnFlow - breakble_glass_minifinale not found!");
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 3:
			if (curFlowPercent > 86 && prevFlowPercent <= 86)
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "goto"))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "goto", null, Vector(-1960.306763, -3884.179932, 536.031250));
				}
				
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 4:
			if (curFlowPercent > 93.5 && prevFlowPercent <= 93.5)
			{
				if (::Left4Bots.Automation.HasTasks())
					::Left4Bots.Automation.ResetTasks();
				
				::Left4Bots.Automation.step++;
			}
			break;
	}
}


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
