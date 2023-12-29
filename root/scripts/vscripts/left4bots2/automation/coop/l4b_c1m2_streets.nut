Msg("Including " + ::Left4Bots.BaseModeName + "/l4b_c1m2_streets automation script...\n");

::Left4Bots.Automation.step <- 0;

class ::Left4Bots.Automation.HealAndGoto extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "HealAndGoto", null, null, null, -1, true, null, false, false);
		
		_ordersSent = false;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (!_ordersSent)
		{
			foreach (bot in _l4b.Bots)
			{
				// Heal if needed
				if (bot.GetHealth() <= 98 && ::Left4Utils.HasMedkit(bot))
					_l4b.BotOrderAdd(bot, "heal", null, bot, null, null, 0, false);
				
				// Go get medkits if needed
				_l4b.BotOrderAdd(bot, "goto", null, null, goto_pos1);
				_l4b.BotOrderAdd(bot, "goto", null, null, goto_pos2);
			}
			_ordersSent = true;
			return;
		}
		
		// Make sure the bots completed their previously assigned orders (heal and goto) before continuing
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotOrdersCount(bot) > 0)
				return;
		}
		
		// Task is complete. Remove it from CurrentTasks
		_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
		_l4b.Logger.Debug("Task complete");
	}
	
	_ordersSent = false;
	
	static goto_pos1 = Vector(-5347.480957, -1716.984863, 456.031250);
	static goto_pos2 = Vector(-5365.701660, -1905.519653, 456.031250);
}

class ::Left4Bots.Automation.ColaDelivery extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "ColaDelivery", null, null, null, -1, true, null, false, false);
		
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
				
				_l4b.Logger.Debug("ColaDelivery.Think - store_doors closed, open order sent");
			}
			else
			{
				// Must send the order to open
				_scavenge_bot = _l4b.GetNearestMovingBot(_store_doors.GetCenter());
				
				_l4b.Logger.Debug("ColaDelivery.Think - scavenge bot is: " + _scavenge_bot.GetPlayerName());
				
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
				_l4b.Logger.Debug("ColaDelivery.Think - cola not spwaned yet");
				return;
			}

			if (!_l4b.ScavengeUseTarget)
			{
				_l4b.ScavengeUseTarget = Entities.FindByName(null, "cola_delivered");
				if (!_l4b.ScavengeUseTarget)
				{
					_l4b.Logger.Error("ColaDelivery.Think - point_prop_use_target not found!!!");
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
					_l4b.Logger.Debug("ColaDelivery.Think - scavenge bot changed: " + _scavenge_bot.GetPlayerName());
					
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
				
				_l4b.Logger.Debug("ColaDelivery.Think - scavenge in progress; _cola_outside: " + _cola_outside);
				
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
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "C1M2InsideGunShop":
			local gunshop_door_button = Entities.FindByName(null, "gunshop_door_button");
			if (gunshop_door_button && gunshop_door_button.IsValid() && !::Left4Bots.Automation.TaskExists("bot", "use", gunshop_door_button, Vector(-4879.598145, -2066.573975, 456.031250)))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bot", "use", gunshop_door_button, Vector(-4879.598145, -2066.573975, 456.031250));
			}
			break;
			
		case "C1M2GunRoomDoor":
			if (!::Left4Bots.Automation.TaskExists("bots", "HealAndGoto"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealAndGoto());
			}
			break;
		
		case "C1M2FirstOutside":
			if (!::Left4Bots.Automation.TaskExists("bots", "ColaDelivery"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.ColaDelivery());
			}
			break;
		
		case "C1M2ColaInDoor":
			::Left4Bots.Automation.ResetTasks();
			break;
		
		case "c1m2goodluckgettingtothemall":
		//case "C1M2TankerAttack":
			if (!::Left4Bots.Automation.TaskExists("bots", "lead"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddTask("bots", "lead");
			}
			break;
		
		case "SurvivorBotReachedCheckpoint":
			CurrentTasks.clear();
			break;
	}
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	switch (::Left4Bots.Automation.step)
	{
		case 0:
			if (!::Left4Bots.Automation.TaskExists("bots", "HealInSaferoom"))
			{
				::Left4Bots.Automation.ResetTasks();
				::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.HealInSaferoom());
			}
			
			::Left4Bots.Automation.step++;
			break;
	}
	
	/*
	// Wait until the nav area in front of the door is unblocked
	if (NavMesh.GetNavAreaByID(206685).IsBlocked(2, false))
		return;
	*/
}
