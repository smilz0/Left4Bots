Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c2m3_coaster automation script...\n");

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
		
		case "c2m3CoasterStart":
			// *** TASK 4. Coaster started, wait for the gate to open
			
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "C2M3CoasterRun":
			// *** TASK 5. Coaster gate is open, go back to leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "c2m3CoasterEnd":
			// *** TASK 7. Coaster stopped, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 8. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Start the coaster
			
			if (curFlowPercent >= 51)
			{
				::Left4Bots.Automation.DoUse("bot", "minifinale_button", Vector(-2959.888916, 1697.165527, 0.649078));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 6. Stop the coaster
			
			if (curFlowPercent >= 89)
			{
				::Left4Bots.Automation.DoUse("bots", "finale_alarm_stop_button", Vector(-3576.294922, 1472.324341, 160.031250));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}


::Left4Bots.Automation.Events.OnGameEvent_round_start <- function (params)
{
	::Left4Bots.Logger.Debug("::Left4Bots.Automation.Events.OnGameEvent_round_start");
	
	// *** NAV FLOW OPTIMIZATIONS ***
	
	// Disconnect the big nav areas located between the container and the truck so the next flow computation will reroute through the warehouse with the pills cabinet instead (will be reconnected later)
	if (::Left4Utils.DisconnectNavAreas(47614, 47594))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas disconnected: 47614, 47594");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not disconnected: 47614, 47594");

	// Disconnect the nav areas at the end of the coaster track leading to the right blocked by the fence so the flow will reroute through the bridge (will be reconnected later)
	if (::Left4Utils.DisconnectNavAreas(334579, 292404))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas disconnected: 334579, 292404");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not disconnected: 334579, 292404");

	// Disconnect these 2 nav areas on the bridge so the flow doesn't incorrectly jump off the bridge (will be reconnected later)
	if (::Left4Utils.DisconnectNavAreas(1341, 552639))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas disconnected: 1341, 552639");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not disconnected: 1341, 552639");

	// Connect these 2 nav areas on the bridge (for some reason they aren't connected)
	if (::Left4Utils.ConnectNavAreas(11860, 11859))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas connected: 11860, 11859");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not connected: 11860, 11859");

	// Spawn a navblocker on this area in order to force a flow recomputation (this area isn't reachable by the survivors anyway)
	// NOTE: Maybe this isn't even needed
	if (::Left4Utils.SpawnNavBlockerOnNavArea(454878, 2))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: nav blocker spawned on area: 454878");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: nav blocker not spawned on area: 454878");
	
	// Reconnected the disconnected nav areas (hopefully) after the flow recomputation
	::Left4Timers.AddTimer(null, 10, ::Left4Bots.Automation.ReconnectDisconnectedNavAreas, { }, false);
	
	// ******************************
}

::Left4Bots.Automation.ReconnectDisconnectedNavAreas <- function (params)
{
	if (::Left4Utils.ConnectNavAreas(47614, 47594))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas re-connected: 47614, 47594");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not re-connected: 47614, 47594");

	if (::Left4Utils.ConnectNavAreas(334579, 292404))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas re-connected: 334579, 292404");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not re-connected: 334579, 292404");

	if (::Left4Utils.ConnectNavAreas(1341, 552639))
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas re-connected: 1341, 552639");
	else
		::Left4Bots.Logger.Debug("Nav Flow Optimization: areas not re-connected: 1341, 552639");
}
