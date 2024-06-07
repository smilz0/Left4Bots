IncludeScript("left4bots");

//if (!("ShouldAvoidItem" in DirectorScript.GetDirectorOptions()))
{
	DirectorScript.GetDirectorOptions().ShouldAvoidItem <- function (classname)
	{
		foreach (item in Left4Bots.ItemsToAvoid)
		{
			if (classname.find(item) != null)
				return !Left4Bots.Settings.items_not_to_avoid;
		}
		
		return Left4Bots.Settings.items_not_to_avoid;
	}
}

if (Left4Bots.Settings.should_hurry)
	DirectorScript.GetDirectorOptions().cm_ShouldHurry <- 1;
