Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c3m2_swamp automation script...\n");

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

		case "C3M2OpenDoor":
			// *** TASK 4. Door open, back to leading up to the saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 5. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Open the plane door
			
			if (curFlowPercent >= 38)
			{
				::Left4Bots.Automation.DoUse("bot", "cabin_door_button", Vector(-1784.953491, 3047.793945, 49.652466));
				::Left4Bots.Automation.step++;
			}
			break;
	}
}

// This area on top of the table is bugged, it is not connected to any other area. If a bot gets here, even the vanilla AI will get stuck here
local area = NavMesh.GetNavAreaByID(75220);
if (area && area.IsValid())
{
	local area2 = NavMesh.GetNavAreaByID(75326);
	area.ConnectTo(area2, -1);
	area2.ConnectTo(area, -1);
	
	local area3 = NavMesh.GetNavAreaByID(75219);
	area.ConnectTo(area3, -1);
	area3.ConnectTo(area, -1);
}
