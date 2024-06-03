Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_automation_map_default automation script...\n");

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	//::Left4Bots.Logger.Debug("Automation.OnConcept - " + concept + " - who: " + who + " - subject: " + subject);
	
	switch (concept)
	{
		case "PlayerPourFinished":
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
			}
			break;
	}
}

::Left4Bots.Automation.Events.OnGameEvent_scavenge_round_start <- function (params)
{
	::Left4Bots.Logger.Debug("::Left4Bots.Automation.Events.OnGameEvent_scavenge_round_start");
	
	if (!::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
	{
		::Left4Bots.Automation.ResetTasks();
		::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.Scavenge()).Start();
	}
}
