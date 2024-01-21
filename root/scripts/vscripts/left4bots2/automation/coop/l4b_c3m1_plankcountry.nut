Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c3m1_plankcountry automation script...\n");

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

		case "C3M1CallFerry":
			// *** TASK 5. Ferry button pressed, wait the ferry on the upper floor of the nearest building
			
			::Left4Bots.Automation.DoWait("bots", Vector(-6337.396973, 6361.096680, 176.031250));
			break;

		case "C3M1FerryLanded":
			// *** TASK 6. Ferry arrived, all go start it
			
			::Left4Bots.Automation.DoUse("bots", "ferry_tram_button", Vector(-5248.111328, 5993.679199, 3.531250));
			break;

		case "C3M1FerryLaunched":
			// *** TASK 7. Ferry started, go idle until it finished crossing
			
			::Left4Bots.Automation.ResetTasks();
			break;

		case "C3M1FerryEnd":
			// *** TASK 8. Ferry landed, go back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 9. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	//::Left4Bots.Logger.Debug("Automation.OnFlow(" + prevFlowPercent + " -> " + curFlowPercent + ")");
	
	switch(::Left4Bots.Automation.step)
	{
		case 1:
			if (curFlowPercent >= 11 && prevFlowPercent < 11)
			{
				// *** TASK 2. Go grab some stuff in the garage
				
				::Left4Bots.Automation.DoGotoAndIdle(Vector(-10764.463867, 10476.730469, 160.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 3. Wait for the GotoAndIdle to finish and then go back to leading
			
			if (curFlowPercent >= 16 || !::Left4Bots.Automation.TaskExists("bots", "GotoAndIdle"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}
			break;
			
		case 3:
			// *** TASK 4. Press the ferry button
			
			if (curFlowPercent >= 42.5)
			{
				::Left4Bots.Automation.DoUse("bot", "ferry_button", Vector(-5475.400879, 6021.643555, 28.160290));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

// Workaround for the double ladders (one for both teams and one for infected only) in this house
// The surivor bots nav picks the wrong one and can't path to the upper floow
local ent = null;
while (ent = Entities. FindByClassnameWithin(ent, "func_simpleladder", Vector(-7925.019531, 8964.340820, 64.031250), 100))
	NetProps.SetPropInt(ent, "m_iTeamNum", 0);
