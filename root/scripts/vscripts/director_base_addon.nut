//if (!("ShouldAvoidItem" in DirectorScript.GetDirectorOptions()))
{
	DirectorScript.GetDirectorOptions().ShouldAvoidItem <- function (classname)
	{
		foreach (item in Left4Bots.ItemsToAvoid)
		{
			if (classname.find(item) != null)
			{
				if (Left4Bots.Settings.items_not_to_avoid)
					return false;
				else
					return true;
			}
		}
		
		if (Left4Bots.Settings.items_not_to_avoid)
			return true;
		else
			return false;
	}
}

if (Left4Bots.Settings.should_hurry)
{
	DirectorScript.GetDirectorOptions().cm_ShouldHurry <- 1;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "cm_ShouldHurry = 1");
}
