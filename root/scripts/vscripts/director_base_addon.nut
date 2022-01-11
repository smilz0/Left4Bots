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
