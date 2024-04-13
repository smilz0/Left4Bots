Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c14m2_lighthouse automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;
::Left4Bots.Automation.tanksKilled <- 0;

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
		
		case "FinaleTriggered":
			// *** TASK 4. Pump activated, go wait near the ammo until the scavenge starts

			local holdPos = null;
			local weapon_ammo_spawn = null;
			while (weapon_ammo_spawn = Entities.FindByClassname(weapon_ammo_spawn, "weapon_ammo_spawn"))
			{
				if (weapon_ammo_spawn.GetName().find("item_spawn_set") != null)
				{
					holdPos = weapon_ammo_spawn.GetOrigin();
					break;
				}
			}
			
			if (holdPos)
				::Left4Bots.Automation.DoHoldAt(holdPos, Vector(-3640.457520, 3349.825928, 804.539063));
			break;
		
		case "C14M2PowerOutAgain":
			// *** TASK 5. Power out, start the gascan scavenge
			
			::Left4Bots.Automation.DoScavenge(Vector(-3855.748535, 4038.760742, 704.031250));
			break;
		
		case "PlayerPourFinished":
			// *** TASK 6. Scavenge finished, go back to the ammo
			
			local score = null;
			local towin = null;

			if ("Score" in query)
				score = query.Score.tointeger();
			if ("towin" in query)
				towin = query.towin.tointeger();

			if (score != null && towin != null)
				::Left4Bots.Logger.Info("Poured: " + score + " - Left: " + towin);

			if (towin == 0 && ::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				::Left4Bots.Logger.Info("Scavenge complete");
				::Left4Bots.Automation.ResetTasks();

				local holdPos = null;
				local weapon_ammo_spawn = null;
				while (weapon_ammo_spawn = Entities.FindByClassname(weapon_ammo_spawn, "weapon_ammo_spawn"))
				{
					if (weapon_ammo_spawn.GetName().find("item_spawn_set") != null)
					{
						holdPos = weapon_ammo_spawn.GetOrigin();
						break;
					}
				}
				
				if (holdPos)
					::Left4Bots.Automation.DoHoldAt(holdPos, Vector(-2104.374023, 4004.541504, 351.084991));
				
				::Left4Bots.Automation.step = 5; // Start count the killed tanks now
			}
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 8. Boat coming, go idle and let the vanilla AI handle the escape
			
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
			// *** TASK 3. Regroup here
			
			if (curFlowPercent >= 43)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(-632.052429, 1340.705200, 143.861420));
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 2:
			// *** TASK 4. After regroup, go back to leading
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 3:
			// *** TASK 4. All go activate the pump
			
			if (curFlowPercent >= 90)
			{
				::Left4Bots.Automation.DoUse("bots", "radio", Vector(-3865.083984, 3945.311523, 704.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		//case 4:
		//case 5:
	}
}

::Left4Bots.Automation.Events.OnGameEvent_player_death <- function (params)
{
	if (::Left4Bots.Automation.step != 5)
		return;
	
	if (!("userid" in params))
		return;
	
	local victim = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!victim || !victim.IsValid() || NetProps.GetPropInt(victim, "m_iTeamNum") != TEAM_INFECTED || victim.GetZombieType() != Z_TANK)
		return;
	
	if (++::Left4Bots.Automation.tanksKilled < 2)
		return;

	// *** TASK 7. Enough tanks killed, let's go wait near the boat's landing point

	::Left4Bots.Automation.DoWait("bots", Vector(-3983.620850, 4843.479492, -38.816288));
	::Left4Bots.Automation.step++;
}
