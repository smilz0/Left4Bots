Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c7m1_docks automation script...\n");

::Left4Bots.Automation.step <- 1;
::Left4Bots.Automation.checkpointleft <- false;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "introend":
		case "SurvivorLeavingInitialCheckpoint":
		case "SurvivorLeavingCheckpoint":
			// !!! This also triggers when a survivor is defibbed later in the game !!!
			if (::Left4Bots.Automation.checkpointleft)
				return;
			::Left4Bots.Automation.checkpointleft = true;
		
			// *** TASK 1. Wait for the intro to finish (or a survivor leaving the safe area) and then start leading
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		/*
		case "C7M1OpenTankDoor":
			// 1st train door is opening (not open yet)
			break;
		*/

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 7. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	//::Left4Bots.Logger.Debug("Automation.OnFlow(" + prevFlowPercent + " -> " + curFlowPercent + ")");
	
	switch (::Left4Bots.Automation.step)
	{
		case 1:
			// *** TASK 2. Regroup here so the bots have a chance to clear the area before freeing the tank
			
			if (curFlowPercent >= 43)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(7781.461914, 216.571304, 0.062359));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 3. Now open the 1st train door
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoUse("bot", "tankdoorin_button", Vector(7057.688965, 600.554993, 141.083344));
				::Left4Bots.Automation.step++;
			}
			break;
		
		// case 3: (waiting for the tank to be killed and the 2nd train door to open)
		
		case 4:
			// *** TASK 6. 2nd train door open, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			::Left4Bots.Automation.step++;
			
			EntFire("nav_blocker_barrel", "UnblockNav"); // What is this nav_blocker for?

			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_player_spawn <- function (params)
{
	if (::Left4Bots.Automation.step != 3)
		return;
	
	if (!("userid" in params))
		return;
	
	local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!player || !player.IsValid() || NetProps.GetPropInt(player, "m_iTeamNum") != TEAM_INFECTED || player.GetZombieType() != Z_TANK)
		return;
	
	// *** TASK 4. Tank Spawned, go idle and kill the tank
	
	::Left4Bots.Automation.ResetTasks();
}

::Left4Bots.Automation.Events.OnGameEvent_player_death <- function (params)
{
	if (::Left4Bots.Automation.step != 3)
		return;
	
	if (!("userid" in params))
		return;
	
	local victim = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!victim || !victim.IsValid() || NetProps.GetPropInt(victim, "m_iTeamNum") != TEAM_INFECTED || victim.GetZombieType() != Z_TANK)
		return;
	
	// *** TASK 5. Tank killed, open the 2nd train door

	::Left4Bots.Automation.DoUse("bot", "tankdoorout_button", Vector(6939.248047, 680.642822, 167.189667));
}

// Go to the next step when the 2nd train door opens
EntityOutputs.AddOutput(Entities.FindByName(null, "tankdoorout"), "OnFullyOpen", "worldspawn", "RunScriptCode", "if (::Left4Bots.Automation.step < 4) ::Left4Bots.Automation.step = 4", 0, -1);
