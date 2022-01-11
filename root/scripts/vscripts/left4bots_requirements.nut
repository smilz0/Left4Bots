//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

if (!("L4ReqChecker" in getroottable()))
{
	::L4ReqChecker <-
	{
		DummyEnt = null
		Count = 0
	}

	::L4ReqChecker.ThinkFunc <- function()
	{
		if (!("Left4Utils" in ::getroottable()))
		{
			if (L4ReqChecker.Count++ >= 10)
			{
				L4ReqChecker.DummyEnt.Kill();
				delete ::L4ReqChecker;
				
				printl("[L4ReqChecker][DEBUG] Dummy entity killed");
			}
			else
			{
				ClientPrint(null, 3, "\x04WARNING:\x01 Required addon \x03 Left 4 Lib\x01 is missing!");
				ClientPrint(null, 3, "\x03Left 4 Bots\x01,\x03 Left 4 Grief\x01 and\x03 Left 4 Fun\x01 addons require the\x03 Left 4 Lib\x01 addon to be installed and enabled in order to work properly.");
				ClientPrint(null, 3, "\x01Please, check the\x03 REQUIRED ITEMS\x01 section on the addons workshop pages.");
			}
		}
		else if (L4ReqChecker.Count++ >= 2)
		{
			L4ReqChecker.DummyEnt.Kill();
			delete ::L4ReqChecker;
			
			printl("[L4ReqChecker][DEBUG] Dummy entity killed");
		}
		
		return 10.0;
	}
}

if (!::L4ReqChecker.DummyEnt || !::L4ReqChecker.DummyEnt.IsValid())
{
	::L4ReqChecker.DummyEnt = SpawnEntityFromTable("info_target", { targetname = "l4reqchecker" });
	if (::L4ReqChecker.DummyEnt)
	{
		::L4ReqChecker.DummyEnt.ValidateScriptScope();
		local scope = ::L4ReqChecker.DummyEnt.GetScriptScope();
		scope["L4ReqCheckerThinkFunc"] <- ::L4ReqChecker.ThinkFunc;
		AddThinkToEnt(::L4ReqChecker.DummyEnt, "L4ReqCheckerThinkFunc");
			
		printl("[L4ReqChecker][DEBUG] Spawned dummy entity");
	}
	else
		error("[L4ReqChecker][ERROR] Failed to spawn dummy entity!\n");
}
else
	printl("[L4ReqChecker][DEBUG] Dummy entity already spawned");
