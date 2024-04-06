Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c4m5_milltown_escape automation script...\n");

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

		case "FinaleTriggered":
			// *** TASK 4. Finale triggered, wait here for the entire finale
			
			// 1/3 chance to hold inside, near the ammo stack. 2/3 chance to hold on the roof
			local waitPos = RandomInt(1, 3) == 3 ? Vector(-6001.879883, 7488.630859, 104.031250) /* Inside */ : Vector(-5779.268555, 7330.576172, 292.031250) /* Roof */;
			::Left4Bots.Automation.DoWait("bots", waitPos); // TODO: HoldAt?
			break;
		
		case "FinalVehicleSpotted":
			// *** TASK 5. Boat coming, let's go
			
			::Left4Bots.Automation.DoGotoAndIdle(Vector(-7103.986328, 7704.025879, 114.324547));
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
			// *** TASK 3. Press the rescue button
			
			if (curFlowPercent >= 90)
			{
				::Left4Bots.Automation.DoUse("bot", "radio", Vector(-5825.094727, 7453.081055, 292.031250));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}
