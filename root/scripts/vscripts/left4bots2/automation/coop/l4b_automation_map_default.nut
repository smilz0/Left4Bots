Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_automation_map_default automation script...\n");

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	switch (concept)
	{
		case "FinaleTriggered":
			if (!::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
			{
				::Left4Bots.Automation.ResetTasks();
				if (::Left4Bots.SetScavengeUseTarget())
				{
					local task = ::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.Scavenge());
					if (::Left4Bots.Settings.scavenge_campaign_autostart)
						task.Start();
				}
			}
			break;
			
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
