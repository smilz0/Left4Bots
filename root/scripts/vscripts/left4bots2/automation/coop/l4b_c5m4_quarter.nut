Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c5m4_quarter automation script...\n");

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

		case "c5m4floatstart":
			// *** TASK 5. Tractor started, go wait on this roof
			
			::Left4Bots.Automation.DoWait("bots", Vector(-1284.699097, 727.339233, 294.857422));
			break;

		case "c5m4floatend":
			// *** TASK 6. Tractor stopped, we can cross but the flow isn't usable so let's regroup after crossing
			
			::Left4Bots.Automation.DoRegroupAt(Vector(-2220.762695, 365.447998, 240.031250));
			::Left4Bots.Automation.step = 4;
			
			break;

		case "SurvivorBotReachedCheckpoint":
			// *** TASK 8. Saferoom reached. Remove all the task and let the given orders (lead) complete
			
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
			// *** TASK 3. Regroup in this room before proceeding
			
			if (curFlowPercent >= 47)
			{
				::Left4Bots.Automation.DoRegroupAt(Vector(-426.391785, 800.659180, 416.031250));
				::Left4Bots.Automation.step++;
			}
			break;
		
		case 2:
			// *** TASK 4. Wait for the regroup to finish, then all go start the tractor
			
			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				if (::Left4Bots.Automation.DoUse("bots", "tractor_button", Vector(-1502.344604, 151.633255, 64.832397)))
					::Left4Bots.Automation.step++;
			}
			break;
		
		// case 3: (Waiting to cross over the tractor)
		
		case 4:
			// *** TASK 7. Wait for the regroup then go back to leading up to the saferoom

			if (!::Left4Bots.Automation.TaskExists("bots", "RegroupAt"))
			{
				::Left4Bots.Automation.DoLead("bots");
				::Left4Bots.Automation.step++;
			}

			break;
	}
}

/* Would be cool to solve this stuck area but i don't know how
local area = NavMesh.GetNavAreaByID(22055);
if (area && area.IsValid())
	area.SetAttributes(2); // JUMP (too bad it doesn't work)
*/
