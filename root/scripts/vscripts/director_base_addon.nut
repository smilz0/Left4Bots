if (!("ShouldAvoidItem" in DirectorScript.GetDirectorOptions()))
{
	DirectorScript.GetDirectorOptions().ShouldAvoidItem <- function (classname)
	{
		//if (classname.find("_spawn") != null)
		//	Left4Bots.Log(LOG_LEVEL_DEBUG, "ShouldAvoidItem - " + classname);
		
		if (Left4Bots.ItemsToAvoid.find(classname) != null)
		{
			//Left4Bots.Log(LOG_LEVEL_DEBUG, "ShouldAvoidItem - " + classname);
			
			return true;
		}
		else
			return false;
	}
}

if (Left4Bots.Settings.should_hurry)
{
	DirectorScript.GetDirectorOptions().cm_ShouldHurry <- 1;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "cm_ShouldHurry = 1");
}
