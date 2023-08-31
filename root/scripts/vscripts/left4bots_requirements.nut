//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

if (!("L4ReqChecker" in getroottable()))
{
	::L4ReqChecker <- {};
	
	L4ReqChecker.CheckRequirement <- function (checkcount)
	{
		if (!("Left4Utils" in ::getroottable()))
		{
			if (checkcount++ >= 10)
			{
				printl("[L4ReqChecker][DEBUG] Requirement check failed!");
				return;
			}
			
			ClientPrint(null, 3, "\x04WARNING:\x01 Required addon \x03 Left 4 Lib\x01 is missing!");
			ClientPrint(null, 3, "\x03Left 4 Bots\x01,\x03 Left 4 Grief\x01 and\x03 Left 4 Fun\x01 addons require the\x03 Left 4 Lib\x01 addon to be installed and enabled in order to work properly.");
			ClientPrint(null, 3, "\x01Please, check the\x03 REQUIRED ITEMS\x01 section on the addons workshop pages.");
		}
		else if (checkcount++ >= 2)
		{
			printl("[L4ReqChecker][DEBUG] Requirement checked successfully!");
			return;
		}
		DoEntFire("worldspawn", "RunScriptCode", "g_ModeScript.L4ReqChecker.CheckRequirement(" + checkcount + ")", 10.0, null, null);
	}
	
	// Recursive function, GO!
	DoEntFire("worldspawn", "RunScriptCode", "g_ModeScript.L4ReqChecker.CheckRequirement(" + 0 + ")", 0.0, null, null);
}
