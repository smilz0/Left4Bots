Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c3m4_plantation automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.tanksKilled <- 0;

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
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
		
		case "C3M4Button1":
			// *** TASK 4. Radio used (1st time)
			
			::Left4Bots.Automation.step = 3;
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "FinaleTriggered":
			// *** TASK 6. Radio used (2nd time) and finale started, wait near the ammo stack for the entire finale
			
			::Left4Bots.Automation.ResetTasks();
			if (!::Left4Bots.Automation.TaskExists("bots", "wait"))
			{
				local holdPos = null;
				local weapon_ammo_spawn = null;
				while (weapon_ammo_spawn = Entities.FindByClassname(weapon_ammo_spawn, "weapon_ammo_spawn"))
				{
					if (weapon_ammo_spawn.GetName().find("mansion_resources") != null)
					{
						holdPos = weapon_ammo_spawn.GetOrigin();
						break;
					}
				}
				
				if (holdPos)
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bots", "wait", null, holdPos);
				}
			}
			break;
		
		case "c3m4GateExplosion":
			// *** TASK 8. Gate open, escape fast to the boat
			
			::Left4Bots.Automation.ResetTasks();
			::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.GotoAndIdle(Vector(1665.984375, 4428.196289, -18.973595)));
			
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
			
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
		
		case 1:
			// *** TASK 3. Use the radio
			
			if (curFlowPercent >= 90)
			{
				local escape_gate_button = Entities.FindByName(null, "escape_gate_button");
				if (escape_gate_button && escape_gate_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", escape_gate_button, Vector(1519.158936, 1978.451660, 126.953949)))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddTask("bot", "use", escape_gate_button, Vector(1519.158936, 1978.451660, 126.953949));
					
					::Left4Bots.Automation.step++;
				}
			}
			break;
		
		case 3:
			// *** TASK 5. Use the radio again
			
			local escape_gate_triggerfinale = Entities.FindByName(null, "escape_gate_triggerfinale");
			if (escape_gate_triggerfinale && escape_gate_triggerfinale.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", escape_gate_triggerfinale, Vector(1519.158936, 1978.451660, 126.953949)))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bot", "use", escape_gate_triggerfinale, Vector(1519.158936, 1978.451660, 126.953949));
				
				::Left4Bots.Automation.step++;
			}
			break;
		
		// case 4: (killing the tanks)
	}
}

::Left4Bots.Automation.Events.OnGameEvent_player_death <- function (params)
{
	if (::Left4Bots.Automation.step != 4)
		return;
	
	if (!("userid" in params))
		return;
	
	local victim = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!victim || !victim.IsValid() || NetProps.GetPropInt(victim, "m_iTeamNum") != TEAM_INFECTED || victim.GetZombieType() != Z_TANK)
		return;
	
	::Left4Bots.Automation.tanksKilled++;
	printl("tanksKilled: " + ::Left4Bots.Automation.tanksKilled); // TODO: remove
		
	if (::Left4Bots.Automation.tanksKilled < 2)
		return;

	// *** TASK 7. Enough tanks killed, let's go wait near the gate to be closer to the escape

	::Left4Bots.Automation.ResetTasks();
	::Left4Bots.Automation.AddTask("bots", "wait", null, Vector(1657.824097, 1906.584595, 119.602448));
	::Left4Bots.Automation.step++;
}
