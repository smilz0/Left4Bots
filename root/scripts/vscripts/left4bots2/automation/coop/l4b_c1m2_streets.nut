Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c1m2_streets automation script...\n");

::Left4Bots.Automation.step <- 0;
::Left4Bots.Automation.checkpointleft <- false;
::Left4Bots.Automation.avoidAreas <- [222122, 233809, 233810];

// Handles the entire cola delivery process.
// Picks one bot for the cola scavenge and orders the others to wait outside of the shop until the cola carrier runs outside, then tell them to follow him for the delivery
class ::Left4Bots.Automation.C1M2ColaDelivery extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "C1M2ColaDelivery", null, null, null, 0.0, true, null, false, false);
		
		_store_doors = Entities.FindByName(null, "store_doors");
		if (!_store_doors)
			_l4b.Logger.Error("Automation.OnFlow - store_doors is null!!!");
	}
	
	function Stop()
	{
		if (!_started)
			return;
		
		_started = false;
		
		foreach (bot in _l4b.Bots)
			bot.GetScriptScope().BotCancelAll();
		
		_l4b.Logger.Debug("Task stopped " + tostring());
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		local state = NetProps.GetPropInt(_store_doors, "m_eDoorState");
		if (state == 0) // 0 = closed - 2 = open
		{
			// Store doors are still closed
			if (_l4b.BotsHaveOrderDestEnt(_store_doors))
			{
				// Order to open has already been sent
				// Do nothing
				
				_l4b.Logger.Debug("C1M2ColaDelivery.Think - store_doors closed, open order sent");
			}
			else
			{
				// Must send the order to open
				_scavenge_bot = _l4b.GetNearestMovingBot(_store_doors.GetCenter());
				
				_l4b.Logger.Debug("C1M2ColaDelivery.Think - scavenge bot is: " + _scavenge_bot.GetPlayerName());
				
				_scavenge_bot.GetScriptScope().BotCancelAll();
				_l4b.BotOrderAdd(_scavenge_bot, "use", null, _store_doors, open_doors_pos);
				
				// Tell the remaining bots to wait outside
				foreach (id, bot in _l4b.Bots)
				{
					if (id != _scavenge_bot.GetPlayerUserId())
					{
						if (!Left4Bots.BotHasOrderOfType(bot, "wait"))
							_l4b.BotOrderAdd(bot, "wait", null, null, wait_pos);
					}
				}
			}
		}
		else 
		{
			// Store doors are open (or opening)
			local cola = Entities.FindByModel(null, "models/w_models/weapons/w_cola.mdl");
			if (!cola)
				cola = Entities.FindByClassname(null, "weapon_cola_bottles");
			if (!cola || !cola.IsValid())
			{
				_l4b.Logger.Debug("C1M2ColaDelivery.Think - cola not spwaned yet");
				return;
			}

			if (!_l4b.ScavengeUseTarget)
			{
				_l4b.ScavengeUseTarget = Entities.FindByName(null, "cola_delivered");
				if (!_l4b.ScavengeUseTarget)
				{
					_l4b.Logger.Error("C1M2ColaDelivery.Think - point_prop_use_target not found!!!");
					return;
				}
				
				_l4b.ScavengeUseType = NetProps.GetPropInt(_l4b.ScavengeUseTarget, "m_spawnflags");
				_l4b.ScavengeUseTargetPos = pour_pos;
			}
			
			if (!_l4b.BotsHaveOrder("scavenge"))
			{
				if (!_scavenge_bot || !_scavenge_bot.IsValid() || _scavenge_bot.IsDead() || _scavenge_bot.IsDying())
				{
					_scavenge_bot = _l4b.GetNearestMovingBot(cola.GetOrigin());
					_l4b.Logger.Debug("C1M2ColaDelivery.Think - scavenge bot changed: " + _scavenge_bot.GetPlayerName());
					
					if (_cola_outside)
					{
						// Remaining bots must follow the new scavenge bot
						foreach (id, bot in _l4b.Bots)
						{
							if (id != _scavenge_bot.GetPlayerUserId())
							{
								bot.GetScriptScope().BotCancelAll();
								_l4b.BotOrderAdd(bot, "follow", null, _scavenge_bot);
							}
						}
					}
				}
				
				// Check if the cola is already in the bot's hands, otherwise we might interrupt the pouring (scavenge order is already gone while pouring)
				if (cola.GetMoveParent() == null)
				{
					_scavenge_bot.GetScriptScope().BotCancelAll();
					_l4b.BotOrderAdd(_scavenge_bot, "scavenge", null, cola);
				}
			}
			else
			{
				if (!_cola_outside)
					_cola_outside = GetFlowPercentForPosition(cola.GetOrigin(), false) > 78;
				
				_l4b.Logger.Debug("C1M2ColaDelivery.Think - scavenge in progress; _cola_outside: " + _cola_outside);
				
				if (_cola_outside && !_l4b.BotsHaveOrder("follow", _scavenge_bot))
				{
					// Remaining bots must follow the new scavenge bot
					foreach (id, bot in _l4b.Bots)
					{
						if (id != _scavenge_bot.GetPlayerUserId())
						{
							bot.GetScriptScope().BotCancelAll();
							_l4b.BotOrderAdd(bot, "follow", null, _scavenge_bot);
						}
					}
				}
			}
		}
	}
	
	_store_doors = null;
	_scavenge_bot = null;
	_cola_outside = false;
	
	static open_doors_pos = Vector(-6598.032715, -2493.884766, 392.031250);
	static wait_pos = Vector(-6275.781250, -2380.112305, 396.723877);
	static pour_pos = Vector(-5368.641602, -1992.017212, 616.031250);
}

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
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
		
		case "C1M2InsideGunShop":
			// *** TASK 3. As soon as entering the gunshop, order one bot to press the button to talk to Whitaker
			
			::Left4Bots.Automation.DoUse("bot", "gunshop_door_button", Vector(-4879.598145, -2066.573975, 456.031250));
			break;
			
		case "C1M2GunRoomDoor":
			// *** TASK 4. After talking to Whitaker, heal (if needed) and go grab the other medkits in the gunshop
			
			::Left4Bots.Automation.DoHealAndGoto([ Vector(-5347.480957, -1716.984863, 456.031250), Vector(-5365.701660, -1905.519653, 456.031250) ]);
			break;
		
		case "C1M2FirstOutside":
			// *** TASK 5. After leaving the gunshop, start the cola delivery process
			
			if (!::Left4Bots.Automation.TaskExists("bots", "C1M2ColaDelivery"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.C1M2ColaDelivery());
			}
			break;
		
		case "C1M2ColaInDoor":
			// *** TASK 6. Go idle after the cola has been successfully delivered
			
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "c1m2goodluckgettingtothemall":
		//case "C1M2TankerAttack":
			// *** TASK 7. Wait for the "Good luck getting to the mall" line from Whitaker, then go back to leading up to the end saferoom
			
			::Left4Bots.Automation.DoLead("bots");
			break;
		
		case "SurvivorBotReachedCheckpoint":
			// *** TASK 8. Saferoom reached. Remove all the task and let the given orders (lead) complete
		
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	// Make sure the areas listed in avoidAreas are always DAMAGING so the bots will try to avoid them
	for (local i = 0; i < ::Left4Bots.Automation.avoidAreas.len(); i++)
	{
		local area = NavMesh.GetNavAreaByID(::Left4Bots.Automation.avoidAreas[i])
		if (area && area.IsValid() && !area.IsDamaging())
			area.MarkAsDamaging(99999);
			//area.MarkAsBlocked(2);
	}
	
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			// *** TASK 1. Heal while in the start saferoom
			
			::Left4Bots.Automation.DoHealInSaferoom();
			::Left4Bots.Automation.step++;
			break;
	}
	
	/* not needed
	// Wait until the nav area in front of the door is unblocked
	if (NavMesh.GetNavAreaByID(206685).IsBlocked(2, false))
		return;
	*/
}

