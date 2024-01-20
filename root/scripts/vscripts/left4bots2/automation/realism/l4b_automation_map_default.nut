/*
If the 'realism' scripts are not defined, use the 'coop' ones.
Search path order:
1. left4bots2/automation/coop/[map name].nut
2. left4bots2/automation/coop/l4b_[map name].nut
3. left4bots2/automation/coop/automation_map_default.nut
4. left4bots2/automation/coop/l4b_automation_map_default.nut
*/
local path = "left4bots2/automation/coop/";
if (!IncludeScript(path + ::Left4Bots.MapName))
{
	if (!IncludeScript(path + "l4b_" + ::Left4Bots.MapName))
	{
		if (!IncludeScript(path + "automation_map_default"))
			IncludeScript(path + "l4b_automation_map_default");
	}
}
