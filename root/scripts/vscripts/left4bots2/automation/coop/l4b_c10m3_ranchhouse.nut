Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c10m3_ranchhouse automation script...\n");

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
			
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.DoLead("bots");
				
				// Bots get stuck at this window because of the breakable stuff, so let's break it before the bots get there
				local ent = null;
				while (ent = Entities. FindByClassnameWithin(ent, "func_breakable", Vector(-7440.849121, -2111.499023, -15.327688), 300))
					ent.TakeDamage(100, 64 /* DMG_BLAST */, null);
			}
			break;

		case "churchguy_button":
			// *** TASK 4. Knocked the door, idle and let the vanilla AI handle the panic event and enter the saferoom
			
			CurrentTasks.clear();
			
			// Apparently the vanilla AI likes to teleport into the saferoom while the door is still locked. Block the path until the door is unlocked
			local name = "saferoom_wait_navblocker";
			if (Entities.FindByName(null, name) == null)
				::Left4Utils.SpawnNavBlocker(name, Vector(-2557.500000, 61.469147, 160.031250), "-5 -5 -5", "5 5 5", 2, 0);
			
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
			if (curFlowPercent >= 93)
			{
				// *** TASK 3. Knock the door
				
				::Left4Bots.Automation.DoUse("bot", "button_safedoor_PANIC", Vector(-2569.371826, 75.537933, 160.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			local checkpoint_entrance = Entities.FindByName(null, "checkpoint_entrance");
			if (checkpoint_entrance && checkpoint_entrance.IsValid() && NetProps.GetPropInt(checkpoint_entrance, "m_bLocked") == 0)
			{
				// *** TASK 5. Saferoom door unlocked. Unblock the path to let the bots in
				
				EntFire("saferoom_wait_navblocker", "UnblockNav");
				::Left4Bots.Automation.step++;
			}
	}
}

//churchguy_door_unlocked
// Apparently there is no concept triggered when the elevator button is pressed, so let's do it this way
//EntityOutputs.AddOutput(, "OnUnblockedOpening", "worldspawn", "RunScriptCode", "EntFire('saferoom_wait_navblocker', 'UnblockNav')", 0, -1);
