Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c3m3_shantytown automation script...\n");

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

		case "C3M3BridgeButton":
			// *** TASK 4. Button pressed, idle until the bridge is down
			
			::Left4Bots.Automation.ResetTasks();
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 6. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Lower the bridge
			
			if (curFlowPercent >= 62)
			{
				::Left4Bots.Automation.DoUse("bot", "bridge_button", Vector(-292.148132, -4237.525391, 3.659943));
				::Left4Bots.Automation.step++;
			}
			break;
		
		// case 2 (waiting for the bridge button to be pressed)
		
		case 3:
			// *** TASK 5. Bridge is down, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	::Left4Bots.Logger.Debug("::Left4Bots.Automation.Events.OnGameEvent_round_start");
	
	// bridge_minifinale.OnFullyClosed = bridge is down
	EntityOutputs.AddOutput(Entities.FindByName(null, "bridge_minifinale"), "OnFullyClosed", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 3) ::Left4Bots.Automation.step = 3", 0, -1);

	// Better flow
	// NOTE:  Would be better to unblock these areas after the flow re-computation, but if we do, the flow computation will be triggered again. Idk if there is a way to do it
	// NOTE2: Would also be better to do this with nav blockers but they are hard to align and they trigger the flow re-computation anyway
	local areastoblock = [9179, 372754, 168797, 113051, 12757, 186681, 6465, 168792, 141529, 9277, 243784, 372757, 149433, 7541, 9105, 11994, 11995, 372709, 6573, 186680, 12239, 380310, 8930, 8957, 6817, 9002, 679939, 9369, 90095, 372711, 372702, 372743, 168856, 372689, 4997, 149427, 5761, 6516, 9296, 11705, 243785, 372758, 168660, 8848, 243783, 11707, 11711, 5178, 372775, 372772, 90099, 8958, 7540, 149434, 157428, 6131, 45120, 243786, 372767, 11709, 8920, 11710, 12739, 6467, 9003, 29835, 45242];
	for (local i = 0; i < areastoblock.len(); i++)
	{
		local area = NavMesh.GetNavAreaByID(areastoblock[i]);
		if (area && area.IsValid())
		{
			area.SetAttributes(134217728 /* NAV_MESH_FLOW_BLOCKED */);
			area.MarkAsBlocked(-1);
		}
	}

	local areastoblock = [46722, 46211, 113157, 46408, 113097, 113162, 113163, 113101, 46351, 46352, 113169, 113170, 46548, 15063, 46552, 46553, 113114, 46363, 46236, 37405, 628706, 113113, 113175, 113194, 46315, 46188, 113177, 46190, 113178, 113179, 113180, 113168, 113161, 113140, 46261, 113142, 113144, 113141, 46266, 46251, 13244, 46216, 46362, 46591, 104749, 13728];
	for (local i = 0; i < areastoblock.len(); i++)
	{
		local area = NavMesh.GetNavAreaByID(areastoblock[i]);
		if (area && area.IsValid())
		{
			area.SetAttributes(134217728 /* NAV_MESH_FLOW_BLOCKED */);
			area.MarkAsBlocked(-1);
		}
	}
	
	// This nav_blocker blocks the area behind the open saferoom door so the bots don't get stuck there and, at the same time,
	// triggers a nav flow recomputation taking into account the nav areas blocked earlier ^
	local area = NavMesh.GetNavAreaByID(45);
	if (area && area.IsValid())
	{
		local name = "saferoom_door_navblocker_" + area.GetID();
		if (Entities.FindByName(null, name) == null)
			::Left4Utils.SpawnNavBlocker(name, area.GetCenter(), "-5 -5 -5", "5 5 5");
	}
	
	/*
	// Bots always get stuck at the breakable walls, so let's break them before the bots get there
	local ent = null;
	//while (ent = Entities. FindByClassnameWithin(ent, "prop_wall_breakable", Vector(395.948303, 4404.918945, -343.968750), 300))
	while (ent = Entities. FindByClassname(ent, "prop_wall_breakable"))
		ent.TakeDamage(100, 64, null);
	*/
}
