//--------------------------------------------------------------------------------------------------
//     GitHub:		https://github.com/smilz0/Left4Bots
//     Workshop:	https://steamcommunity.com/sharedfiles/filedetails/?id=3022416274
//--------------------------------------------------------------------------------------------------

Msg("Including left4bots_automation...\n");

::Left4Bots.Automation <-
{
	AutoStart = false
	CurrentTasks = {}
	Events = {}
	PrevFlow = 0
	step = 0
}

// Base Task. Assigns a single 'order' to the 'target' bot(s)
class ::Left4Bots.Automation.Task
{
	constructor(target, order, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.0, canPause = true, param1 = null, cancelAllOnBegin = false, cancelAllOnEnd = true)
	{
		_target = target;
		_order = order;
		_destEnt = destEnt;
		_destPos = destPos;
		_destLookAtPos = destLookAtPos;
		_holdTime = holdTime;
		_canPause = canPause;
		_param1 = param1;
		_cancelAllOnBegin = cancelAllOnBegin;
		_cancelAllOnEnd = cancelAllOnEnd;
		_l4b = ::Left4Bots;
		_allBots = _target == "bots";
		if (!_allBots)
		{
			if (target == "bot")
			{
				_targetBot = "*";
				_targetBots = [];
			}
			else
			{
				_targetBots = split(target, ",");
				if (_targetBots.len() < 2)
				{
					_targetBot = _targetBots[0];
					_targetBots.clear();
				}
			}
		}
		
		/*
			_target = "bots"				-> _allBots = true,  _targetBot = "*", 			_targetBots = [] 						-> All bots
			_target = "bot"					-> _allBots = false, _targetBot = "*", 			_targetBots = [] 						-> Any bot
			_target = "botname"				-> _allBots = false, _targetBot = "botname", 	_targetBots = [] 						-> That one bot
			_target = "botname1,botname2,*"	-> _allBots = false, _targetBot = "*", 			_targetBots = [botname1, botname2, *]	-> One available bot in that order (* = any)
		*/
	}
	
	function _typeof()
	{
		return "Left4Bots.Automation.Task";
	}
	
	function _tostring()
	{
		return "Left4Bots.Automation.Task { target: " + _target + ", order: " + _order + ", destEnt: " + _destEnt + ", destPos: " + _destPos + ", destLookAtPos: " + _destLookAtPos + ", holdTime: " + _holdTime + ", canPause: " + _canPause + ", param1: " + _param1 + ", cancelAllOnBegin: " + _cancelAllOnBegin + ", cancelAllOnEnd: " + _cancelAllOnEnd + " }";
	}
	
	function _cmp(other)
	{
		if (!other || (typeof other) != "Left4Bots.Automation.Task" || !("_target" in other) || !("_order" in other) || !("_destEnt" in other) || !("_destPos" in other) || !("_destLookAtPos" in other))
			return -1;
		
		if (other._target != _target || other._order != _order || other._destEnt != _destEnt || other._destPos != _destPos || other._destLookAtPos != _destLookAtPos)
			return 1;
		
		return 0;
	}
	
	function Start()
	{
		if (_started)
			return;
		
		_started = true;
		
		_l4b.Logger.Debug("Task started " + tostring());
	}
	
	function Stop()
	{
		if (!_started)
			return;
		
		_started = false;
		
		if (_cancelAllOnEnd)
		{
			foreach (bot in _l4b.Bots)
			{
				if (_l4b.BotHasOrder(bot, _order, _destEnt, _destPos))
					bot.GetScriptScope().BotCancelAll();
			}
		}
		
		_l4b.Logger.Debug("Task stopped " + tostring());
	}
	
	function IsStarted()
	{
		return _started;
	}
	
	function CheckStartBot(bot)
	{
		if (_l4b.BotHasOrder(bot, _order, _destEnt, _destPos))
			return;

		if (_cancelAllOnBegin)
			bot.GetScriptScope().BotCancelAll();
		
		_l4b.BotOrderAdd(bot, _order, null, _destEnt, _destPos, _destLookAtPos, _holdTime, _canPause, _param1);
	}
	
	function Think()
	{
		if (!_started || !_order || (_destEnt && !_destEnt.IsValid()))
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (_allBots)
		{
			/*
			_target = "bots"					-> _allBots = true,  _targetBot = "*", 			_targetBots = [] 						-> All bots
			*/
			
			foreach (bot in _l4b.Bots)
				CheckStartBot(bot);
			
			return;
		}

		/*
		_target = "bot"					-> _allBots = false, _targetBot = "*", 			_targetBots = [] 						-> Any bot
		_target = "botname"				-> _allBots = false, _targetBot = "botname", 	_targetBots = [] 						-> That one bot
		_target = "botname1,botname2,*"	-> _allBots = false, _targetBot = "*", 			_targetBots = [botname1, botname2, *]	-> One available bot in that order (* = any)
		*/
			
		if (_l4b.BotsHaveOrder(_order, _destEnt, _destPos, _destLookAtPos))
			return; // Someone is already doing this task
		
		local bot = null;
		if (_targetBot != "*")
			bot = _l4b.GetBotByName(_targetBot); // That one bot
		else if (_targetBots.len() == 0)
		{
			// Search the nearest available bot to either destPos, destEnt or 0,0,0 <- this just to select a random bot
			local p = Vector(0,0,0);
			if (_destPos)
				p = _destPos
			else if (_destEnt)
				p = _destEnt.GetOrigin();
			bot = _l4b.GetNearestMovingBot(p);
		}
		else
		{
			// Find the first available bot from the ordered list
			for (local i = 0; i < _targetBots.len(); i++)
			{
				bot = _l4b.GetBotByName(_targetBots[i]);
				if (bot && !SurvivorCantMove(bot, bot.GetScriptScope().Waiting))
					break;
			}
		}
		
		if (!bot)
		{
			_l4b.Logger.Debug("No available bot for task: " + tostring());
			return;
		}
		
		if (_cancelAllOnBegin)
			bot.GetScriptScope().BotCancelAll();
		
		_l4b.BotOrderAdd(bot, _order, null, _destEnt, _destPos, _destLookAtPos, _holdTime, _canPause, _param1);
	}
	
	_target = "bot";
	_order = null;
	_destEnt = null;
	_destPos = null;
	_destLookAtPos = null;
	_holdTime = 0.0;
	_canPause = true;
	_param1 = null;
	_cancelAllOnBegin = false;
	_cancelAllOnEnd = true;
	_l4b = null;
	_started = false;
	_allBots = false;
	_targetBot = "*";
	_targetBots = [];
}

// Gives a 'heal' order to the bots with health <= 98 and a medkit in the inventory, then automatically remove its task from CurrentTasks
class ::Left4Bots.Automation.HealInSaferoom extends ::Left4Bots.Automation.Task
{
	constructor()
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "HealInSaferoom", null, null, null, 0.0, true, null, false, false);
		
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
				if (bot.GetHealth() < 98 /* _l4b.Settings.heal_interrupt_minhealth */ && ::Left4Utils.HasMedkit(bot) && _l4b.HasSpareMedkitsAround(bot))
					_l4b.BotOrderAdd(bot, "heal", null, bot, null, null, 0, false);
			}
			_ordersSent = true;
			return;
		}
		
		// Make sure the bots completed their previously assigned orders (heal and goto) before continuing
		/*
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotOrdersCount(bot) > 0)
				return;
		}
		*/
		
		// Task is complete. Remove it from CurrentTasks
		_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
		_l4b.Logger.Debug("Task complete");
	}
	
	_ordersSent = false;
}

// General gascan scavenge task. Handles the autofollow bots
class ::Left4Bots.Automation.Scavenge extends ::Left4Bots.Automation.Task
{
	constructor(useTargetPos = null, onTankPos = null, onTankCanPause = true)
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "Scavenge", null, useTargetPos, onTankPos, 0.0, onTankCanPause, null, false, false);
		// constructor(target, order, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.0, canPause = true, param1 = null, cancelAllOnBegin = false, cancelAllOnEnd = true)
		
		if (useTargetPos)
		{
			// This is optional, it's just to set a better ScavengeUseTargetPos than the autocalculated one
			_l4b.ScavengeUseTarget = Entities.FindByClassname(null, "point_prop_use_target");
			_l4b.ScavengeUseType = NetProps.GetPropInt(_l4b.ScavengeUseTarget, "m_spawnflags");
			_l4b.ScavengeUseTargetPos = useTargetPos;
		}
		else
		{
			// Use the autocalculated ScavengeUseTargetPos
			_l4b.ScavengeUseTarget = null;
			_l4b.ScavengeUseType = 0;
			_l4b.ScavengeUseTargetPos = null;
		}
	}
	
	function Stop()
	{
		if (!_started)
			return;
		
		_started = false;
		
		_l4b.ScavengeUseTarget = null;
		_l4b.ScavengeUseTargetPos = null;
		_l4b.ScavengeUseType = 0;
		_l4b.ScavengeBots.clear();

		// Cancel any pending scavenge order
		foreach (bot in _l4b.Bots)
		{
			if (bot && bot.IsValid())
			{
				//bot.GetScriptScope().BotCancelOrders("wait");
				//bot.GetScriptScope().BotCancelOrders("scavenge");
				//bot.GetScriptScope().BotCancelAutoOrders("follow");
				bot.GetScriptScope().BotCancelAll();
			}
		}

		_l4b.Logger.Debug("Task stopped " + tostring());
	}
	
	function CountAutofollowBots()
	{
		local c = 0;
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotHasAutoOrder(bot, "follow"))
				c++;
		}
		return c;
	}
	
	function CountFollowers(target)
	{
		local c = 0;
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotHasOrder(bot, "follow", target))
				c++;
		}
		return c;
	}
	
	function GetAutofollowTarget()
	{
		local ret = null;
		local minFollowers = 100000;
		foreach (bot in _l4b.ScavengeBots)
		{
			local numFollowers = CountFollowers(bot);
			if (numFollowers < minFollowers)
			{
				ret = bot;
				minFollowers = numFollowers;
			}
		}
		return ret;
	}
	
	function SetScavengeUseTarget()
	{
		if (_l4b.ScavengeUseTarget && _l4b.ScavengeUseTarget.IsValid())
			return true;

		return _l4b.SetScavengeUseTarget();
	}
	
	function UpdateScavengeBots(num)
	{
		local update_autofollow = false;

		// Remove invalid/dead bots
		foreach (id, bot in _l4b.ScavengeBots)
		{
			if (!bot || !bot.IsValid() || bot.IsDead() || bot.IsDying())
			{
				delete _l4b.ScavengeBots[id];
				
				if (bot && bot.IsValid())
				{
					// Stop autofollowing this bot
					foreach (followbot in _l4b.Bots)
						followbot.GetScriptScope().BotCancelAutoOrders("follow", bot);
				}
			}
		}

		// Add the required bots
		while (_l4b.ScavengeBots.len() < num && _l4b.ScavengeBots.len() < _l4b.Bots.len())
		{
			local bot = _l4b.GetFirstAvailableBotForOrder("scavenge");
			if (!bot)
				break;

			_l4b.ScavengeBots[bot.GetPlayerUserId()] <- bot;

			_l4b.Logger.Info("Added scavenge order slot for bot " + bot.GetPlayerName());

			_l4b.SpeakRandomVocalize(bot, _l4b.VocalizerYes, RandomFloat(0.2, 1.0));
			
			update_autofollow = true;
		}

		// Remove the excess
		foreach (id, bot in _l4b.ScavengeBots)
		{
			if (_l4b.ScavengeBots.len() <= _l4b.Settings.scavenge_max_bots)
				break;

			delete _l4b.ScavengeBots[id];

			_l4b.Logger.Info("Removed scavenge order slot for bot " + bot.GetPlayerName());
			
			// Stop autofollowing this bot
			foreach (followbot in _l4b.Bots)
				followbot.GetScriptScope().BotCancelAutoOrders("follow", bot);
			
			update_autofollow = true;
		}

		return _l4b.ScavengeBots.len();
	}
	
	function UpdateScavengeAutofollowBots()
	{
		_l4b.Logger.Debug("Scavenge.UpdateScavengeAutofollowBots - Updating autofollowers...");
		local afbCount = CountAutofollowBots();
		while (afbCount < _l4b.Settings.scavenge_max_autofollow)
		{
			local target = GetAutofollowTarget();
			if (!target)
			{
				_l4b.Logger.Debug("Scavenge.UpdateScavengeAutofollowBots - Noone to autofollow");
				break;
			}
			
			local follower = _l4b.GetFirstAvailableBotForOrder("follow", null, target.GetOrigin());
			if (!follower)
			{
				_l4b.Logger.Debug("Scavenge.UpdateScavengeAutofollowBots - No more followers available");
				break;
			}
			
			_l4b.Logger.Debug("Scavenge.UpdateScavengeAutofollowBots - Sending " + follower.GetPlayerName() + " to follow " + target.GetPlayerName());
			if (_l4b.BotOrderAdd(follower, "follow", null, target) >= 0)
				afbCount++;
		}
	}
	
	function GetScavengeItems()
	{
		return _l4b.GetAvailableScavengeItems();
	}
	
	function GetNextItemIdx(player, entList, linear = false)
	{
		local ret = null;
		local orig;
		if (linear)
			orig = _l4b.Settings.scavenge_items_from_pourtarget != 0 ? _l4b.ScavengeUseTargetPos : player.GetOrigin();
		else
			orig = _l4b.Settings.scavenge_items_from_pourtarget != 0 ? GetFlowDistanceForPosition(_l4b.ScavengeUseTargetPos) : GetFlowDistanceForPosition(player.GetOrigin());
		if (_l4b.Settings.scavenge_items_farthest_first)
		{
			local curDist = 0;
			foreach (idx, item in entList)
			{
				local dist = linear ? (item.ent.GetOrigin() - orig).Length() : abs(item.flow - orig);
				if (dist > curDist)
				{
					ret = idx;
					curDist = dist;
				}
			}
		}
		else
		{
			local curDist = 9999999;
			foreach (idx, item in entList)
			{
				local dist = linear ? (item.ent.GetOrigin() - orig).Length() : abs(item.flow - orig);
				if (dist < curDist)
				{
					ret = idx;
					curDist = dist;
				}
			}
		}
		return ret;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (_destLookAtPos != null && _l4b.Tanks.len() > 0)
		{
			// There are tank alive and the onTankPos position was given. Cancel any previous order and go wait at onTankPos
			foreach (id, bot in _l4b.Bots)
			{
				if (!_l4b.BotHasOrder(bot, "wait", null, _destLookAtPos))
				{
					//bot.GetScriptScope().BotCancelAll();
					_l4b.BotOrderAdd(bot, "wait", null, null, _destLookAtPos, null, 0.0, _canPause);
				}
			}
			return;
		}
		else if (_destLookAtPos != null)
		{
			// No tank but the onTankPos position was given. Likely we are resuming from an OnTank wait, make sure to cancel it
			foreach (id, bot in _l4b.Bots)
			{
				if (_l4b.BotHasOrder(bot, "wait", null, _destLookAtPos))
					bot.GetScriptScope().BotCancelOrders("wait");
					//bot.GetScriptScope().BotCancelAll();
			}
		}

		// No tanks or no onTankPos given. Do scavenge
		
		// Set the scavenge use target (if not set)
		SetScavengeUseTarget();
		
		// Retrieve the list of scavenge items
		local scavengeItems = GetScavengeItems();
		
		// Assign the scavenge bot slots
		UpdateScavengeBots(::Left4Utils.Min(_l4b.Settings.scavenge_max_bots, scavengeItems.len()));
		
		// Assign the auto follow bots to the available scavenge bots
		UpdateScavengeAutofollowBots();

		// Handle the scavenge orders
		local linearDistance = !_l4b.Settings.scavenge_items_flow_distance;
		foreach (id, bot in _l4b.ScavengeBots)
		{
			if (!_l4b.BotHasOrderOfType(bot, "scavenge"))
			{
				// Assign the order
				while (scavengeItems.len() > 0)
				{
					local idx = GetNextItemIdx(bot, scavengeItems, linearDistance);
					local item = scavengeItems[idx].ent;

					delete scavengeItems[idx];

					if (!_l4b.BotsHaveOrderDestEnt(item))
					{
						_l4b.BotOrderAdd(bot, "scavenge", null, item);

						_l4b.Logger.Info("Assigned a scavenge order to bot " + bot.GetPlayerName());

						break;
					}
				}
			}
		}
	}
}

// Orders the bots to heal (if they have a medkit and their health is <= 98) and then goto (likely to check for pickups) at the given location(s)
// Waits until all the orders complete before completing and removing its task from CurrentTasks
class ::Left4Bots.Automation.HealAndGoto extends ::Left4Bots.Automation.Task
{
	constructor(pos = [])
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "HealAndGoto", null, null, null, 0.0, true, null, false, false);
		
		_ordersSent = false;
		
		for (local i = 0; i < pos.len(); i++)
			_goto_pos.append(pos[i]);
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
				
				// Goto the given locations
				for (local i = 0; i < _goto_pos.len(); i++)
					_l4b.BotOrderAdd(bot, "goto", null, null, _goto_pos[i]);
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
	_goto_pos = [];
}

// Gives all the bots a 'wait' order at the specified location and automatically cancels it (and removes its task from CurrentTasks) when all the bots are in their 'Waiting' status
class ::Left4Bots.Automation.RegroupAt extends ::Left4Bots.Automation.Task
{
	constructor(pos)
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "RegroupAt", null, null, null, 0.0, true, null, false, false);
		
		_ordersSent = false;
		_gotoPos = pos;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (!_ordersSent)
		{
			foreach (bot in _l4b.Bots)
				_l4b.BotOrderAdd(bot, "wait", null, null, _gotoPos);
			
			_ordersSent = true;
			return;
		}
		
		// Make sure that all the bots are in the 'Waiting' status before continuing
		foreach (bot in _l4b.Bots)
		{
			if (!bot.GetScriptScope().Waiting)
				return;
		}
		
		// Task is complete. Cancel the 'wait' order and remove the task from CurrentTasks
		foreach (bot in _l4b.Bots)
			bot.GetScriptScope().BotCancelOrders("wait");
		
		_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
		_l4b.Logger.Debug("Task complete");
	}
	
	_ordersSent = false;
	_gotoPos = null;
}

// Gives all the bots a 'wait' order at the specified location and automatically cancels it (and removes its task from CurrentTasks) after the given amount of 'time' elapsed
class ::Left4Bots.Automation.HoldAt extends ::Left4Bots.Automation.Task
{
	constructor(holdPos, onTankPos = null, holdTime = 0.0, canPause = true)
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "HoldAt", null, holdPos, onTankPos, holdTime, canPause);
		// constructor(target, order, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.0, canPause = true, param1 = null, cancelAllOnBegin = false, cancelAllOnEnd = true)
		
		_holdStart = null;
	}
	
	function Stop()
	{
		if (!_started)
			return;
		
		_started = false;
		_holdStart = null;
		
		foreach (bot in _l4b.Bots)
		{
			if (_l4b.BotHasOrder(bot, "wait", null, _destPos) || (_destLookAtPos != null && _l4b.BotHasOrder(bot, "wait", null, _destLookAtPos)))
				bot.GetScriptScope().BotCancelOrders("wait");
		}
		
		_l4b.Logger.Debug("Task stopped " + tostring());
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (_holdStart == null)
			_holdStart = Time();
		else if (_holdTime > 0 && (Time() - _holdStart) > _holdTime)
		{
			// Task is complete. Cancel the 'wait' order and remove the task from CurrentTasks
			foreach (bot in _l4b.Bots)
				bot.GetScriptScope().BotCancelOrders("wait");
			
			_l4b.Automation.DeleteTasks(_target, _order, _destEnt, _destPos, _destLookAtPos);
			_l4b.Logger.Debug("Task complete");
			
			return;
		}
		
		local pos = _l4b.Tanks.len() > 0 ? _destLookAtPos : _destPos;
		foreach (bot in _l4b.Bots)
		{
			if (!_l4b.BotHasOrder(bot, "wait", null, pos))
			{
				bot.GetScriptScope().BotCancelOrders("wait");
				_l4b.BotOrderAdd(bot, "wait", null, null, pos, null, 0.0, _canPause);
			}
		}
	}
	
	_holdStart = null;
}

// Gives all the bots a 'goto' order to the specified location and waits for the completion of the order for all the bots before removing its task from CurrentTasks
class ::Left4Bots.Automation.GotoAndIdle extends ::Left4Bots.Automation.Task
{
	constructor(pos)
	{
		// 'target' and 'order' are only used for the task identification (GetTaskId), not for the actual orders
		base.constructor("bots", "GotoAndIdle", null, null, null, 0.0, true, null, false, false);
		
		_ordersSent = false;
		_gotoPos = pos;
	}
	
	function Think()
	{
		if (!_started)
			return;
		
		_l4b.Logger.Debug("Task thinking " + tostring());
		
		if (!_ordersSent)
		{
			foreach (bot in _l4b.Bots)
				_l4b.BotOrderAdd(bot, "goto", null, null, _gotoPos);
			
			_ordersSent = true;
			return;
		}
		
		// Make sure the bots completed their previously assigned orders (goto) before continuing
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
	_gotoPos = null;
}

::Left4Bots.Automation.AddTask <- function (target, order, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.0, canPause = true, param1 = null, cancelAllOnBegin = false, cancelAllOnEnd = true)
{
	local task = Task(target, order, destEnt, destPos, destLookAtPos, holdTime, canPause, param1, cancelAllOnBegin, cancelAllOnEnd);
	CurrentTasks[CurrentTasks.len()] <- task;
	return task;
}

::Left4Bots.Automation.AddCustomTask <- function (task)
{
	CurrentTasks[CurrentTasks.len()] <- task;
	return task;
}

::Left4Bots.Automation.StartTasks <- function (autoStart = false)
{
	AutoStart = autoStart;
	foreach (task in CurrentTasks)
		task.Start();
}

::Left4Bots.Automation.StopTasks <- function ()
{
	AutoStart = false;
	foreach (task in CurrentTasks)
		task.Stop();
}

::Left4Bots.Automation.ResetTasks <- function ()
{
	foreach (task in CurrentTasks)
		task.Stop();

	CurrentTasks.clear();
}

::Left4Bots.Automation.HasTasks <- function ()
{
	return CurrentTasks.len() > 0;
}

::Left4Bots.Automation.GetTaskId <- function (target, order, destEnt = null, destPos = null, destLookAtPos = null)
{
	foreach (id, task in CurrentTasks)
	{
		if (task._target == target && task._order == order && (!destEnt || task._destEnt == destEnt) && (!destPos || (task._destPos - destPos).Length() < 2) && (!destLookAtPos || (task._destLookAtPos - destLookAtPos).Length() < 2))
			return id;
	}
	return -1;
}

::Left4Bots.Automation.GetTask <- function (target, order, destEnt = null, destPos = null, destLookAtPos = null)
{
	local id = GetTaskId(target, order, destEnt, destPos, destLookAtPos);
	if (id < 0)
		return null;
	
	return CurrentTasks[id];
}

::Left4Bots.Automation.TaskExists <- function (target, order, destEnt = null, destPos = null, destLookAtPos = null)
{
	return (GetTaskId(target, order, destEnt, destPos, destLookAtPos) > -1);
}

::Left4Bots.Automation.DeleteTasks <- function (target, order, destEnt = null, destPos = null, destLookAtPos = null)
{
	local id = GetTaskId(target, order, destEnt, destPos, destLookAtPos);
	while (id > -1)
	{
		delete CurrentTasks[id];
		id = GetTaskId(target, order, destEnt, destPos, destLookAtPos);
	}
}

::Left4Bots.Automation.DoLead <- function (target)
{
	if (TaskExists(target, "lead"))
		return false;
	
	ResetTasks();
	AddTask(target, "lead");
	
	return true;
}

::Left4Bots.Automation.DoUse <- function (target, entName, usePos, canPause = true, holdTime = 0.0)
{
	local ent = Entities.FindByName(null, entName);
	if (!ent || !ent.IsValid() || TaskExists(target, "use", ent))
		return false;

	ResetTasks();
	AddTask(target, "use", ent, usePos, null, holdTime, canPause);
	
	return true;
}

::Left4Bots.Automation.DoUseNoName <- function (target, entClass, usePos, canPause = true)
{
	local ent = Entities.FindByClassnameNearest(entClass, usePos, 500);
	if (!ent || !ent.IsValid())
	{
		::Left4Bots.Logger.Error("Automation.DoUseNoName - " + entClass + " not found near " + usePos);
		return false;
	}
	
	if (TaskExists(target, "use", ent))
		return false;
	
	ResetTasks();
	AddTask(target, "use", ent, usePos, null, 0.0, canPause);
	
	return true;
}

::Left4Bots.Automation.DoDestroy <- function (target, entName, destroyPos, canPause = true)
{
	local ent = Entities.FindByName(null, entName);
	if (!ent || !ent.IsValid() || TaskExists(target, "destroy", ent))
		return false;

	ResetTasks();
	AddTask(target, "destroy", ent, destroyPos, null, 0.0, canPause);
	
	return true;
}

::Left4Bots.Automation.DoWait <- function (target, waitPos, canPause = true)
{
	if (TaskExists(target, "wait", null, waitPos))
		return false;

	ResetTasks();
	AddTask(target, "wait", null, waitPos, null, 0.0, canPause);
		
	return true;
}

::Left4Bots.Automation.DoHoldAt <- function (holdPos, onTankPos = null, holdTime = 0.0, canPause = true)
{
	if (TaskExists("bots", "HoldAt"))
		return false;
	
	ResetTasks();
	AddCustomTask(HoldAt(holdPos, onTankPos, holdTime, canPause));
		
	return true;
}

::Left4Bots.Automation.DoRegroupAt <- function (pos)
{
	if (TaskExists("bots", "RegroupAt"))
		return false;
	
	ResetTasks();
	AddCustomTask(RegroupAt(pos));
		
	return true;
}

::Left4Bots.Automation.DoGotoAndIdle <- function (pos)
{
	if (TaskExists("bots", "GotoAndIdle"))
		return false;
	
	ResetTasks();
	AddCustomTask(GotoAndIdle(pos));
		
	return true;
}

::Left4Bots.Automation.DoHealInSaferoom <- function ()
{
	if (TaskExists("bots", "HealInSaferoom"))
		return false;
	
	ResetTasks();
	AddCustomTask(HealInSaferoom());
		
	return true;
}

::Left4Bots.Automation.DoHealAndGoto <- function (posList)
{
	if (TaskExists("bots", "HealAndGoto"))
		return false;
	
	ResetTasks();
	AddCustomTask(HealAndGoto(posList));
		
	return true;
}

::Left4Bots.Automation.DoScavenge <- function (useTargetPos = null, onTankPos = null, onTankCanPause = true)
{
	if (::Left4Bots.Automation.TaskExists("bots", "Scavenge"))
		return false;
	
	::Left4Bots.Automation.ResetTasks();
	local task = ::Left4Bots.Automation.AddCustomTask(::Left4Bots.Automation.Scavenge(useTargetPos, onTankPos, onTankCanPause));
	if (::Left4Bots.Settings.scavenge_campaign_autostart)
		task.Start();
	
	return true;
}

::Left4Bots.Automation.OnTaskManager <- function (params)
{
	if (!Settings.automation)
		return;
	
	local newFlow = GetFlowPercent();
	Automation.OnFlow(Automation.PrevFlow, newFlow);
	Automation.PrevFlow = newFlow;
	
	// Automatically start the current tasks if AutoStart is true or there is no human survivor in the team
	if (Automation.AutoStart || Bots.len() == Survivors.len())
	{
		foreach (task in Automation.CurrentTasks)
		{
			if (!task.IsStarted())
				task.Start();
		}
	}
	
	foreach (task in Automation.CurrentTasks)
		task.Think();
}

::Left4Bots.Automation.OnConcept <- function(who, subject, concept, query)
{
	// Override in "left4bots2/automation/mapname.nut"
}

::Left4Bots.Automation.OnFlow <- function(prevFlowPercent, curFlowPercent)
{
	// Override in "left4bots2/automation/mapname.nut"
}

/*
if (::Left4Bots.BaseModeName == "coop" || ::Left4Bots.BaseModeName == "versus" || ::Left4Bots.BaseModeName == "realism") // TODO: are there other campaign based modes?
{
	if (!IncludeScript("left4bots2/automation/" + ::Left4Bots.MapName))
	{
		if (!IncludeScript("left4bots2/automation/l4b_" + ::Left4Bots.MapName))
		{
			if (!IncludeScript("left4bots2/automation/automation_default"))
				IncludeScript("left4bots2/automation/l4b_automation_default");
		}
	}
}
else
{
	if (!IncludeScript("left4bots2/automation/automation_" + ::Left4Bots.BaseModeName))
	{
		if (!IncludeScript("left4bots2/automation/l4b_automation_" + ::Left4Bots.BaseModeName))
		{
			if (!IncludeScript("left4bots2/automation/automation_default"))
				IncludeScript("left4bots2/automation/l4b_automation_default");
		}
	}
}
*/

/*
Search path order:
1. left4bots2/automation/[base mode name]/[map name].nut
2. left4bots2/automation/[base mode name]/l4b_[map name].nut
3. left4bots2/automation/[base mode name]/automation_map_default.nut
4. left4bots2/automation/[base mode name]/l4b_automation_map_default.nut
*/
local path = "left4bots2/automation/" + ::Left4Bots.BaseModeName + "/";
if (!IncludeScript(path + ::Left4Bots.MapName))
{
	if (!IncludeScript(path + "l4b_" + ::Left4Bots.MapName))
	{
		if (!IncludeScript(path + "automation_map_default"))
			IncludeScript(path + "l4b_automation_map_default");
	}
}

::Left4Bots.Automation.Events.OnGameEvent_player_entered_checkpoint <- function (params)
{
	local player = null;
	if ("userid" in params)
		player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	if (!player || !player.IsValid() || GetCurrentFlowPercentForPlayer(player) < 80)
		return;
	
	if (::Left4Bots.Automation.step == 999999)
		return; // Already did it
	
	::Left4Bots.Logger.Debug("::Left4Bots.Automation.Events.OnGameEvent_player_entered_checkpoint");
	
	::Left4Bots.Automation.step = 999999;
	::Left4Bots.Automation.CurrentTasks.clear();
	if (!::Left4Bots.Settings.automation_stay_in_end_saferoom)
		return;
	
	local mapAreas = {};
	::Left4Utils.FindMapAreas(mapAreas);
	if (mapAreas["checkpointB_in"])
	{
		::Left4Bots.Settings.move_end_radius_wait = 30;
		::Left4Bots.Automation.DoWait("bots", mapAreas["checkpointB_in"].GetCenter());
	}
}
