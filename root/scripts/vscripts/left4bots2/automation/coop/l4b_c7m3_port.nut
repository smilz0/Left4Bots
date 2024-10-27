Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c7m3_port automation script...\n");

::Left4Bots.Automation.checkpointleft <- false;

// Handles the entire startup process of the generators, trying to make it synchronized for the CHAOS GENERATOR achievement
// How it works:
// - If there are 3 bots available and no generator has been started yet, 3 bots are selected to go and wait near each generator.
//   When all 3 bots are waiting for a few seconds, they will autonomously start the generators at the same time.
// - If there aren't 3 bots available and no generator has been started yet, the available bots will go and wait near their generators.
//   When a human begins his own generator's startup, the waiting bots will also start their generators.
// - If one or more generators have already been started, the available bots will go and start the remaining generators without waiting
class ::Left4Bots.Automation.C7M3Generators extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "C7M3Generators", null, null, null, 0.0, true, null, false, false);
		
		_generatorbutton1 = Entities.FindByName(null, genbutton1name);
		if (!_generatorbutton1)
			_l4b.Logger.Error("Automation.OnFlow - " + genbutton1name + " is null!!!");
		
		_generatorbutton2 = Entities.FindByName(null, genbutton2name);
		if (!_generatorbutton2)
			_l4b.Logger.Error("Automation.OnFlow - " + genbutton2name + " is null!!!");
		
		_generatorbutton3 = Entities.FindByName(null, genbutton3name);
		if (!_generatorbutton3)
			_l4b.Logger.Error("Automation.OnFlow - " + genbutton3name + " is null!!!");
	}
	
	function Stop()
	{
		if (!_started)
			return;
		
		_started = false;
		
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotHasAutoOrder(bot, "wait") || _l4b.BotHasAutoOrder(bot, "use"))
				bot.GetScriptScope().BotCancelAll();
		}
		
		_l4b.Logger.Debug("Task stopped " + tostring());
	}
	
	function GetFirstAvailableBotForGenerator(generatorbutton)
	{
		local bestBot = null;
		local bestDistance = 1000000;
		local bestQueue = 1000;
		local closestTo = generatorbutton.GetOrigin();
		foreach (id, bot in _l4b.Bots)
		{
			if (bot.IsValid() && bot != _generatorbot1 && bot != _generatorbot2 && bot != _generatorbot3 && !bot.IsDead() && !bot.IsDying() /*&& !bot.IsIncapacitated()*/ /*&& !_l4b.BotHasOrderOfType(bot, "wait") && !_l4b.BotHasOrderOfType(bot, "use")*/)
			{
				local scope = bot.GetScriptScope();
				if (!_l4b.SurvivorCantMove(bot, scope.Waiting))
				{
					local q = scope.Orders.len();
					if (q == 0 && !scope.CurrentOrder)
						q = -1;

					local d = 0;
					if (closestTo)
						d = (bot.GetOrigin() - closestTo).Length();

					// Get the bot with the shortest queue (and closer to closestTo if closestTo is not null)
					if (q < bestQueue || (q == bestQueue && d < bestDistance))
					{
						bestBot = bot;
						bestQueue = q;
						bestDistance = d;
					}
				}
			}
		}
		return bestBot;
	}
	
	function SwitchToUsePhase()
	{
		if (_usePhase)
			return;

		_usePhase = true;
		
		_l4b.Logger.Debug("C7M3Generators.SwitchToUsePhase");
		
		if (_generatorbot1 && _generatorbutton1 && !_l4b.BotHasAutoOrder(_generatorbot1, "use"))
		{
			_generatorbot1.GetScriptScope().BotCancelAll();
			_l4b.BotOrderAdd(_generatorbot1, "use", null, _generatorbutton1, genbutton1pos);
		}
		
		if (_generatorbot2 && _generatorbutton2 && !_l4b.BotHasAutoOrder(_generatorbot2, "use"))
		{
			_generatorbot2.GetScriptScope().BotCancelAll();
			_l4b.BotOrderAdd(_generatorbot2, "use", null, _generatorbutton2, genbutton2pos);
		}
		
		if (_generatorbot3 && _generatorbutton3 && !_l4b.BotHasAutoOrder(_generatorbot3, "use"))
		{
			_generatorbot3.GetScriptScope().BotCancelAll();
			_l4b.BotOrderAdd(_generatorbot3, "use", null, _generatorbutton3, genbutton3pos);
		}
	}
	
	function Think()
	{
		if (!_started)
		{
			_waitReadyStart = 0;
			return;
		}
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (_generatorbutton1 && !_generatorbutton1.IsValid())
			_generatorbutton1 = null; // Likely the generator has been started already
		
		if (_generatorbutton2 && !_generatorbutton2.IsValid())
			_generatorbutton2 = null; // Same ^
			
		if (_generatorbutton3 && !_generatorbutton3.IsValid())
			_generatorbutton3 = null; // Same ^
		
		if (!_generatorbutton1 && !_generatorbutton2 && !_generatorbutton3)
		{
			// All 3 generators have been started, this task is done
			Stop();
			_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
			_l4b.Logger.Debug("Task complete");
			
			return;
		}
		
		// 1 or more generators have yet to be started
		
		// If a bot (assigned to a generator) is no longer available we should be able to replace it with another one (if any)
		if (_generatorbot1 && (!_generatorbot1.IsValid() || _generatorbot1.IsDead() || _generatorbot1.IsDying()))
			_generatorbot1 = null;
			
		if (_generatorbot2 && (!_generatorbot2.IsValid() || _generatorbot2.IsDead() || _generatorbot2.IsDying()))
			_generatorbot2 = null;
			
		if (_generatorbot3 && (!_generatorbot3.IsValid() || _generatorbot3.IsDead() || _generatorbot3.IsDying()))
			_generatorbot3 = null;

		// Check the generators, assign the bots and send the 'wait' order if we're still in the 'wait' phase
		if (_generatorbutton3 && !_generatorbot3)
		{
			_l4b.Logger.Debug("C7M3Generators.Think - _generatorbutton3 has no bot assigned");
			
			_generatorbot3 = GetFirstAvailableBotForGenerator(_generatorbutton3);
			if (_generatorbot3)
				_l4b.Logger.Debug("C7M3Generators.Think - Assigned " + _generatorbot3.GetPlayerName() + " to _generatorbutton3");
		}
		
		if (_generatorbutton2 && !_generatorbot2)
		{
			_l4b.Logger.Debug("C7M3Generators.Think - _generatorbutton2 has no bot assigned");
			
			_generatorbot2 = GetFirstAvailableBotForGenerator(_generatorbutton2);
			if (_generatorbot2)
				_l4b.Logger.Debug("C7M3Generators.Think - Assigned " + _generatorbot2.GetPlayerName() + " to _generatorbutton2");
		}
		
		if (_generatorbutton1 && !_generatorbot1)
		{
			_l4b.Logger.Debug("C7M3Generators.Think - _generatorbutton1 has no bot assigned");
			
			_generatorbot1 = GetFirstAvailableBotForGenerator(_generatorbutton1);
			if (_generatorbot1)
				_l4b.Logger.Debug("C7M3Generators.Think - Assigned " + _generatorbot1.GetPlayerName() + " to _generatorbutton1");
		}
		
		if (!_generatorbot1 && !_generatorbot2 && !_generatorbot3)
		{
			_l4b.Logger.Debug("C7M3Generators.Think - No bot is available at the moment");
			
			_waitReadyStart = 0;
			
			return; // We have no available bots, no reason to proceed. Let's see if a bot becomes available later...
		}

		// If all 3 generators have yet to be started, there are enough survivors to start them all and no assigned bot has the 'use' order yet, then we are still in the 'wait' phase
		if (!_usePhase && _generatorbutton1 && _generatorbutton2 && _generatorbutton3 && _l4b.Survivors.len() >= 3 && (!_generatorbot1 || !_l4b.BotHasAutoOrder(_generatorbot1, "use")) && (!_generatorbot2 || !_l4b.BotHasAutoOrder(_generatorbot2, "use")) && (!_generatorbot3 || !_l4b.BotHasAutoOrder(_generatorbot3, "use")))
			WaitPhase();
		else
			UsePhase();
	}
	
	function WaitPhase()
	{
		// Handle the 'wait' phase
		
		local required = (_generatorbot1 != null).tointeger() + (_generatorbot2 != null).tointeger() + (_generatorbot3 != null).tointeger();
		local waiting = 0;

		if (_generatorbot1)
		{
			// If the bot has not received the 'wait' order yet, then send it
			if (!_l4b.BotHasAutoOrder(_generatorbot1, "wait"))
				_l4b.BotOrderAdd(_generatorbot1, "wait", null, null, genbutton1pos);
			
			waiting += _l4b.BotIsWaiting(_generatorbot1).tointeger();
		}
		
		if (_generatorbot2)
		{
			// If the bot has not received the 'wait' order yet, then send it
			if (!_l4b.BotHasAutoOrder(_generatorbot2, "wait"))
				_l4b.BotOrderAdd(_generatorbot2, "wait", null, null, genbutton2pos);
			
			waiting += _l4b.BotIsWaiting(_generatorbot2).tointeger();
		}
		
		if (_generatorbot3)
		{
			// If the bot has not received the 'wait' order yet, then send it
			if (!_l4b.BotHasAutoOrder(_generatorbot3, "wait"))
				_l4b.BotOrderAdd(_generatorbot3, "wait", null, null, genbutton3pos);
			
			waiting += _l4b.BotIsWaiting(_generatorbot3).tointeger();
		}
		
		_l4b.Logger.Debug("C7M3Generators.WaitPhase - required: " + required + " - waiting: " + waiting);
		
		if (waiting < required)
		{
			// Not all the bots are ready yet
			_waitReadyStart = 0;
			return;
		}

		// All the waiting bots are ready
		if (_waitReadyStart == 0)
			_waitReadyStart = Time();
		
		if (waiting < 3)
		{
			// Not enough bots to start all 3 generators but there are enough humans available, we must wait for a human to start first. Just say we are ready
			if ((Time() - _lastReady) >= readyVocalizeInterval)
			{
				_l4b.Logger.Debug("C7M3Generators.WaitPhase - Playing 'iMT_PlayerAnswerReady'...");
				
				if (_generatorbot1)
					DoEntFire("!self", "SpeakResponseConcept", "iMT_PlayerAnswerReady", 0, null, _generatorbot1);
					
				if (_generatorbot2)
					DoEntFire("!self", "SpeakResponseConcept", "iMT_PlayerAnswerReady", 1.5, null, _generatorbot2);
					
				if (_generatorbot3)
					DoEntFire("!self", "SpeakResponseConcept", "iMT_PlayerAnswerReady", 3, null, _generatorbot3);
				
				_lastReady = Time();
			}
			
			return;
		}
		
		// Enough ready bots for all 3 generators. Make sure they are being ready for a few seconds before starting the generators
		if ((Time() - _waitReadyStart) >= waitReadyTime)
			SwitchToUsePhase();
		else
			_l4b.Logger.Debug("C7M3Generators.WaitPhase - All bots are ready but ready time is not over yet");
	}
	
	function UsePhase()
	{
		// Handle the 'use' phase
		
		_l4b.Logger.Debug("C7M3Generators.UsePhase");
		
		// Just check if all the assigned bots have their own 'use' order and add it if needed
		if (_generatorbot1 && _generatorbutton1 && !_l4b.BotHasAutoOrder(_generatorbot1, "use"))
			_l4b.BotOrderAdd(_generatorbot1, "use", null, _generatorbutton1, genbutton1pos);
		
		if (_generatorbot2 && _generatorbutton2 && !_l4b.BotHasAutoOrder(_generatorbot2, "use"))
			_l4b.BotOrderAdd(_generatorbot2, "use", null, _generatorbutton2, genbutton2pos);
		
		if (_generatorbot3 && _generatorbutton3 && !_l4b.BotHasAutoOrder(_generatorbot3, "use"))
			_l4b.BotOrderAdd(_generatorbot3, "use", null, _generatorbutton3, genbutton3pos);
	}
	
	_generatorbutton1 = null;
	_generatorbutton2 = null;
	_generatorbutton3 = null;
	
	_generatorbot1 = null;
	_generatorbot2 = null;
	_generatorbot3 = null;
	
	_usePhase = false;
	_lastReady = 0;
	_waitReadyStart = 0;
	
	static genbutton1name = "finale_start_button";	// Center generator
	static genbutton2name = "finale_start_button1";	// Right (upper) generator
	static genbutton3name = "finale_start_button2";	// Left (lower) generator
	
	static genbutton1pos = Vector(-397.044769, -605.649475, 2.346591);
	static genbutton2pos = Vector(-1189.056274, 872.344177, 160.031250);
	static genbutton3pos = Vector(1810.601318, 718.421936, -95.968750);
	
	static readyVocalizeInterval = 6;
	static waitReadyTime = 3;
}

// Returns the first bot trying to leave Bill as the last option
::Left4Bots.Automation.GetBotForBridgeButton <- function()
{
	local bill = null;
	local billChar = Left4Utils.GetCharacterFromActor("NamVet", Director.GetSurvivorSet());
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid())
		{
			if (NetProps.GetPropInt(bot, "m_survivorCharacter") == billChar)
				bill = bot;
			else
				return bot;
		}
	}
	return bill;
}

// Returns the first bot trying to get Bill as the first option
::Left4Bots.Automation.GetBotForSacrificeGenerator <- function()
{
	local notbill = null;
	local billChar = Left4Utils.GetCharacterFromActor("NamVet", Director.GetSurvivorSet());
	foreach (bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid())
		{
			if (NetProps.GetPropInt(bot, "m_survivorCharacter") == billChar)
				return bot;
			else
				notbill = bot;
		}
	}
	return notbill;
}

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
		
		case "CrashFinaleGeneratorPress":
			// This will tell the waiting bots to start their generators when a human is starting the first one (in case there aren't 3 bots available)
			local task = ::Left4Bots.Automation.GetTask("bots", "C7M3Generators");
			if (task)
				task.SwitchToUsePhase();

			break;
		
		case "FinalVehicleArrived":
			// All wait here: (8.472557, -1456.906616, -5.468750) <- no need to. Vanilla AI go there too
			
			// *** TASK 5. Bridge open, someone (possibly not Bill) press the bridge button
			
			local bot = ::Left4Bots.Automation.GetBotForBridgeButton();
			if (bot)
				::Left4Bots.Automation.DoUse(bot.GetPlayerName(), "bridge_start_button", Vector(-121.661514, -1759.812622, 252.031250));
			break;
		
		case "C7M3BridgeButton":
			// *** TASK 6. Bridge button pressed, someone (Bill) go restart the sacrifice generator
			
			local bot = ::Left4Bots.Automation.GetBotForSacrificeGenerator();
			if (bot)
			{
				// Make sure to set CanPause to false or the bot won't make it to the generator
				::Left4Bots.Automation.DoWait(bot.GetPlayerName(), Vector(-405.201050, -609.159302, 2.399614), false);
				::Left4Bots.Automation.step++;
			}
			break;
		
		case "CrashFinaleGenerator2On":
			// *** TASK 8. Sacrifice generator re-started, go idle (not really needed since the round is ending but...)
			
			::Left4Bots.Automation.ResetTasks();
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
			// *** TASK 3. Start the generators
			
			if (curFlowPercent >= 45)
			{
				if (!::Left4Bots.Automation.TaskExists("bots", "C7M3Generators"))
				{
					::Left4Bots.Automation.ResetTasks();
					::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.C7M3Generators());
				}
				::Left4Bots.Automation.step++;
			}
			break;
		
		/* No need for a 'wait' command since the vanilla AI already sits near the ammo stack
		case 2:
			// *** TASK 4. Stay here and fight until the bridge opens
			
			if (!::Left4Bots.Automation.TaskExists("bots", "C7M3Generators"))
			{
				::Left4Bots.Automation.DoWait("bots", Vector(-440.626617, -444.601715, 5.284966));
				::Left4Bots.Automation.step++;
			}
			break;
		*/
		
		case 3:
			// *** TASK 7. Wait until the sacrifice generator button is available, then press it
			
			local bot = ::Left4Bots.Automation.GetBotForSacrificeGenerator();
			if (bot)
			{
				// Make sure to set CanPause to false or the bot won't make it
				if (::Left4Bots.Automation.DoUse(bot.GetPlayerName(), "generator_button", Vector(-405.201050, -609.159302, 2.399614), false))
					::Left4Bots.Automation.step++;
			}
			break;
	}
}
