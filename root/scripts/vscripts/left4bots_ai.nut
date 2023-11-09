//--------------------------------------------------------------------------------------------------
//     GitHub:		https://github.com/smilz0/Left4Bots
//     Workshop:	https://steamcommunity.com/sharedfiles/filedetails/?id=3022416274
//--------------------------------------------------------------------------------------------------

Msg("Including left4bots_ai...\n");

// AI Move types from the lowest to the highest priority one
// HighPriority is used in spit/charger dodging and other high priority MOVEs
enum AI_MOVE_TYPE {
	None,
	Order,
	Pickup,
	Defib,
	Door, // This is used for saferoom doors only (other doors are handled as orders and so with Order priority)
	HighPriority
}

// AI Throw types
enum AI_THROW_TYPE {
	None,
	Tank,  // Throwing molotov/bile at a tank (ThrowTarget is the tank)
	Horde, // Throwing pipe/bile at hordes (ThrowTarget is our target position)
	Manual // Throwing anything at a given position
}

// AI Door actions
enum AI_DOOR_ACTION {
	None,
	Open,		// Open the door
	Close,		// Close the door
	Saferoom	// Check if we're fully in the saferoom, then Close
}

// Add the main AI think function to the given bot and initialize it
::Left4Bots.AddBotThink <- function (bot)
{
	Logger.Debug("AddBotThink -> " + bot.GetPlayerName());

	AddThinkToEnt(bot, null);

	bot.ValidateScriptScope();
	local scope = bot.GetScriptScope();

	scope.L4B <- ::Left4Bots; // TODO: also Settings and Left4Utils?
	scope.CharId <- NetProps.GetPropInt(bot, "m_survivorCharacter");
	//scope.FuncI <- 0; //scope.CharId % 5; // <- this makes the bots start the sub-think functions in different order so they don't "Use" pickups or do things at the exact same time
	scope.FuncI <- (scope.CharId - 1) % 5; // <- this makes the bots start the sub-think functions in different order so they don't "Use" pickups or do things at the exact same time
	// CharIds are supposed to be from 1 to 8 so FuncI shouldn't be <0. But you never know...
	if (scope.FuncI < 0)
		scope.FuncI = 0; // Btw, we start from 0 now because the FuncI++ has been moved to the beginning of the think function
	scope.UserId <- bot.GetPlayerUserId();
	scope.Origin <- bot.GetOrigin(); // This will be updated each tick by the BotThink_Main think function. It is meant to replace all the self.GetOrigin() used by the various funcs
	scope.CurTime <- Time(); // Same ^
	scope.ActiveWeapon <- null; // ^
	scope.ActiveWeaponId <- null; // ^
	scope.ActiveWeaponSlot <- null; // ^
	scope.MoveEnt <- null;
	scope.MovePos <- null;
	scope.MovePosReal <- null;
	scope.MoveType <- AI_MOVE_TYPE.None;
	scope.MoveTime <- 0;
	scope.MoveTimeout <- 0;
	scope.NeedMove <- 0;
	scope.CanReset <- true;
	scope.DelayedReset <- false;
	scope.Paused <- 0; // Paused = 0 = not in pause. Paused > 0 (Time() of when the pause started) = in pause
	scope.WeaponsToSearch <- {};
	scope.UpgradesToSearch <- {};
	scope.TimePickup <- 0;
	scope.LastPickup <- 0;
	scope.CurrentOrder <- null;
	scope.Orders <- [];
	scope.ThrowType <- AI_THROW_TYPE.None;
	scope.ThrowTarget <- null;
	scope.ThrowStartedOn <- 0;
	scope.DoorEnt <- null; // Used for AI_MOVE_TYPE.Door
	scope.DoorZ <- 0; // Used for AI_MOVE_TYPE.Door
	scope.DoorAct <- AI_DOOR_ACTION.None; // Used for AI_MOVE_TYPE.Door
	scope.Waiting <- false;
	scope.SM_IsStuck <- false;
	scope.SM_StuckPos <- Vector(0, 0, 0);
	scope.SM_StuckTime <- 0;
	scope.SM_MoveTime <- 0;
	scope.WeapPref <- LoadWeaponPreferences(bot);
	scope.CarryItem <- null;
	scope.CarryItemWeaponId <- 0;
	scope.HurryUntil <- 0;
	scope.UseWeapons <- {};

	scope["BotThink_Main"] <- AIFuncs.BotThink_Main;
	scope["BotThink_Pickup"] <- AIFuncs.BotThink_Pickup;
	scope["BotThink_Defib"] <- AIFuncs.BotThink_Defib;
	scope["BotThink_Throw"] <- AIFuncs.BotThink_Throw;
	scope["BotThink_Orders"] <- AIFuncs.BotThink_Orders;
	scope["BotThink_Door"] <- AIFuncs.BotThink_Door;
	scope["BotThink_Misc"] <- AIFuncs.BotThink_Misc;
	scope["BotManualAttack"] <- AIFuncs.BotManualAttack;
	scope["BotStuckMonitor"] <- AIFuncs.BotStuckMonitor;
	scope["BotMoveTo"] <- AIFuncs.BotMoveTo;
	scope["BotMoveToNav"] <- AIFuncs.BotMoveToNav;
	scope["BotMoveReset"] <- AIFuncs.BotMoveReset;
	scope["BotReset"] <- AIFuncs.BotReset;
	scope["BotUpdatePickupToSearch"] <- AIFuncs.BotUpdatePickupToSearch;
	scope["BotGetNearestPickupWithin"] <- AIFuncs.BotGetNearestPickupWithin;
	scope["BotInitializeCurrentOrder"] <- AIFuncs.BotInitializeCurrentOrder;
	scope["BotFinalizeCurrentOrder"] <- AIFuncs.BotFinalizeCurrentOrder;
	scope["BotGetOrders"] <- AIFuncs.BotGetOrders;
	scope["BotCancelCurrentOrder"] <- AIFuncs.BotCancelCurrentOrder;
	scope["BotCancelOrder"] <- AIFuncs.BotCancelOrder;
	scope["BotCancelOrders"] <- AIFuncs.BotCancelOrders;
	scope["BotCancelOrdersDestEnt"] <- AIFuncs.BotCancelOrdersDestEnt;
	scope["BotCancelDefib"] <- AIFuncs.BotCancelDefib;
	scope["BotCancelAll"] <- AIFuncs.BotCancelAll;
	scope["BotIsInPause"] <- AIFuncs.BotIsInPause;
	scope["BotPause"] <- AIFuncs.BotPause;
	scope["BotUnPause"] <- AIFuncs.BotUnPause;
	scope["BotOnPause"] <- AIFuncs.BotOnPause;
	scope["BotOnResume"] <- AIFuncs.BotOnResume;

	AddThinkToEnt(bot, "BotThink_Main");
}

// Add the main AI think function to the given extra L4D1 bot and initialize it
::Left4Bots.AddL4D1BotThink <- function (bot)
{
	Logger.Debug("AddL4D1BotThink -> " + bot.GetPlayerName());

	AddThinkToEnt(bot, null);

	bot.ValidateScriptScope();
	local scope = bot.GetScriptScope();

	scope.L4B <- ::Left4Bots; // TODO: also Settings and Left4Utils?
	scope.CharId <- NetProps.GetPropInt(bot, "m_survivorCharacter");
	scope.FuncI <- (scope.CharId - 1) % 5; // <- this makes the bots start the sub-think functions in different order so they don't "Use" pickups or do things at the exact same time
	// CharIds are supposed to be from 1 to 8 so FuncI shouldn't be <0. But you never know...
	if (scope.FuncI < 0)
		scope.FuncI = 0; // Btw, we start from 0 now because the FuncI++ has been moved to the beginning of the think function
	scope.UserId <- bot.GetPlayerUserId();
	scope.Origin <- bot.GetOrigin(); // This will be updated each tick by the BotThink_Main think function. It is meant to replace all the self.GetOrigin() used by the various funcs
	scope.CurTime <- Time(); // Same ^
	scope.ActiveWeapon <- null; // ^
	scope.ActiveWeaponId <- null; // ^
	scope.ActiveWeaponSlot <- null; // ^
	scope.MoveEnt <- null;
	scope.MovePos <- null;
	scope.MovePosReal <- null;
	scope.MoveType <- AI_MOVE_TYPE.None;
	scope.MoveTime <- 0;
	scope.MoveTimeout <- 0;
	scope.NeedMove <- 0;
	scope.CanReset <- true;
	scope.DelayedReset <- false;
	scope.Paused <- 0; // Paused = 0 = not in pause. Paused > 0 (Time() of when the pause started) = in pause
	scope.WeaponsToSearch <- {};
	scope.UpgradesToSearch <- {};
	scope.TimePickup <- 0;
	scope.LastPickup <- 0;
	scope.ThrowType <- AI_THROW_TYPE.None;
	scope.ThrowTarget <- null;
	scope.ThrowStartedOn <- 0;
	scope.Waiting <- false;
	scope.WeapPref <- LoadWeaponPreferences(bot);
	scope.HurryUntil <- 0;
	scope.UseWeapons <- {};

	scope["BotThink_Main"] <- AIFuncs.BotThink_Main_L4D1;
	scope["BotThink_Pickup"] <- AIFuncs.BotThink_Pickup;
	scope["BotThink_Throw"] <- AIFuncs.BotThink_Throw;
	scope["BotManualAttack"] <- AIFuncs.BotManualAttack;
	scope["BotMoveTo"] <- AIFuncs.BotMoveTo;
	scope["BotMoveToNav"] <- AIFuncs.BotMoveToNav;
	scope["BotMoveReset"] <- AIFuncs.BotMoveReset;
	scope["BotReset"] <- AIFuncs.BotReset;
	scope["BotUpdatePickupToSearch"] <- AIFuncs.BotUpdatePickupToSearch;
	scope["BotGetNearestPickupWithin"] <- AIFuncs.BotGetNearestPickupWithin;

	AddThinkToEnt(bot, "BotThink_Main");
}

::Left4Bots.RemoveBotThink <- function (bot)
{
	AddThinkToEnt(bot, null);
}

::Left4Bots.ClearBotThink <- function ()
{
	foreach (id, bot in Bots)
	{
		if (bot.IsValid())
			AddThinkToEnt(bot, null);
	}
}

// Returns the table representing the order with the given parameters, or null if the given bot is invalid or orderType is unknown
::Left4Bots.BotOrderPrepare <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true, param1 = null)
{
	if (!IsHandledBot(bot))
		return null;

	if (!(orderType in OrderPriorities))
		return null;

	local order = { OrderType = orderType, Priority = OrderPriorities[orderType], From = from, DestEnt = destEnt, DestPos = destPos, DestLookAtPos = destLookAtPos, HoldTime = holdTime, CanPause = canPause, Param1 = param1 };
	switch (orderType)
	{
		case "lead":
		{
			order.DestRadius <- Settings.move_end_radius_lead;
			order.MaxSeparation <- Settings.lead_max_separation;
			break;
		}
		case "witch":
		{
			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.DestRadius <- Settings.move_end_radius_witch;
			order.MaxSeparation <- 0;
			break;
		}
		case "heal":
		{
			//SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.DestRadius <- Settings.move_end_radius_heal;
			order.MaxSeparation <- 0;
			break;
		}
		case "use":
		{
			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			local entClass = destEnt.GetClassname();
			if (entClass.find("weapon_") != null || entClass.find("prop_physics") != null)
				order.DestRadius <- Settings.pickups_pick_range;
			//else if (entClass.find("func_button") != null || entClass.find("trigger_finale") != null || entClass.find("prop_door_rotating") != null)
			//	order.DestRadius <- 50;
			else// if (entClass == "prop_minigun")
				order.DestRadius <- Settings.move_end_radius;

			order.MaxSeparation <- 0;
			break;
		}
		case "scavenge":
		{
			local wId = Left4Utils.GetWeaponId(destEnt);
			if (Left4Utils.GetWeaponSlotById(wId) != 5)
				return null; // Not a carriable item

			order.Param1 <- wId;
			order.DestRadius <- Settings.move_end_radius_scavenge;
			order.MaxSeparation <- 0;
			break;
		}
		case "carry":
		{
			local wId = Left4Utils.GetWeaponId(destEnt);
			if (Left4Utils.GetWeaponSlotById(wId) != 5)
				return null; // Not a carriable item

			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.Param1 <- wId;
			order.DestRadius <- Settings.pickups_pick_range;
			order.MaxSeparation <- 0;
			break;
		}
		case "deploy":
		{
			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.DestRadius <- Settings.pickups_pick_range;
			order.MaxSeparation <- 0;
			break;
		}
		case "follow":
		{
			order.DestRadius <- Settings.move_end_radius_follow;
			order.MaxSeparation <- 0;
			break;
		}
		case "wait":
		{
			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.DestRadius <- Settings.move_end_radius_wait;
			order.MaxSeparation <- 0;
			break;
		}
		case "destroy":
		{
			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.DestRadius <- Settings.move_end_radius;
			order.MaxSeparation <- 0;
			break;
		}
		default:
		{
			SpeakRandomVocalize(bot, VocalizerYes, RandomFloat(0.5, 1.0));

			order.DestRadius <- Settings.move_end_radius;
			order.MaxSeparation <- 0;
		}
	}
	return order;
}

// Append an order to the given bot's queue. No check on priorities
// Returns the order's position in the bot's queue (where 1 = first position), or -1 if bad bot/orderType
::Left4Bots.BotOrderAppend <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true, param1 = null)
{
	local order = BotOrderPrepare(bot, orderType, from, destEnt, destPos, destLookAtPos, holdTime, canPause, param1);
	if (!order)
		return -1;

	local scope = bot.GetScriptScope();
	scope.Orders.append(order);
	local queuePos = scope.Orders.len();

	Logger.Debug("[AI]" + bot.GetPlayerName() + " - Appended order (queue pos. " + queuePos + "): " + BotOrderToString(order));

	return queuePos;
}

// Insert an order to the first position of the bot's queue and replaces CurrentOrder if needed. No check on priorities
// Returns the bot's queue len after the operation, or -1 if bad bot/orderType
::Left4Bots.BotOrderInsert <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true, param1 = null)
{
	local order = BotOrderPrepare(bot, orderType, from, destEnt, destPos, destLookAtPos, holdTime, canPause, param1);
	if (!order)
		return -1;

	local scope = bot.GetScriptScope();
	if (scope.CurrentOrder)
	{
		scope.Orders.insert(0, scope.CurrentOrder);
		scope.CurrentOrder = order;

		if (scope.MoveType == AI_MOVE_TYPE.Order)
		{
			scope.MovePos = null; // Force a MOVE to the new destination
			scope.MovePosReal = null;
		}
	}
	else
		scope.Orders.insert(0, order);

	local queueLen = scope.Orders.len();
	Logger.Debug("[AI]" + bot.GetPlayerName() + " - Inserted order (queue len " + queueLen + "): " + BotOrderToString(order));

	scope.BotUnPause();

	return queueLen;
}

// Add an order to the bot's queue placing it in the right position according to the priorities and replacing CurrentOrder if needed
// Returns the order's position in the bot's queue (where 0 = set/replaced CurrentOrder, 1 = first position in the queue), or -1 if bad bot/orderType
::Left4Bots.BotOrderAdd <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true, param1 = null)
{
	local order = BotOrderPrepare(bot, orderType, from, destEnt, destPos, destLookAtPos, holdTime, canPause, param1);
	if (!order)
		return -1;

	local scope = bot.GetScriptScope();
	local idx;

	if (Settings.orders_no_queue && from != null)
	{
		scope.BotCancelOrders();
		idx = 0;
	}
	else
	{
		for (idx = 0; idx < scope.Orders.len(); idx++)
		{
			if (scope.Orders[idx].Priority < order.Priority)
				break;
		}
	}
	// idx now contains the queue index the new order should be inserted to

	if (idx == 0)
	{
		// If idx is 0 we must also check CurrentOrder and its priority
		if (!scope.CurrentOrder || scope.CurrentOrder.Priority < order.Priority)
		{
			// Either CurrentOrder was null or its priority was lower and must be replaced
			if (scope.CurrentOrder)
			{
				scope.Orders.insert(0, scope.CurrentOrder); // Shift CurrentOrder to the first pos of the queue
				scope.CurrentOrder = order; // Replace CurrentOrder

				if (scope.MoveType == AI_MOVE_TYPE.Order)
				{
					scope.MovePos = null; // Force a MOVE to the new destination
					scope.MovePosReal = null;
				}

				Logger.Debug("[AI]" + bot.GetPlayerName() + " - New order replaced CurrentOrder: " + BotOrderToString(order));
			}
			else
			{
				scope.CurrentOrder = order; // Set CurrentOrder

				Logger.Debug("[AI]" + bot.GetPlayerName() + " - New order set to CurrentOrder: " + BotOrderToString(order));
			}

			scope.BotUnPause();

			return 0;
		}

		// CurrentOrder must stay, just insert the new order to the first pos in the queue
		scope.Orders.insert(0, order);

		Logger.Debug("[AI]" + bot.GetPlayerName() + " - New order (queue pos. 0): " + BotOrderToString(order));

		return 1;
	}

	// If idx is >0 then CurrentOrder is not null and its priority is likely higher, so no need to check it
	scope.Orders.insert(idx, order); // Insert the new order to its pos in the queue

	Logger.Debug("[AI]" + bot.GetPlayerName() + " - New order (queue pos. " + idx + "): " + BotOrderToString(order));

	return (idx+1);
}

// Re-adds the given order to the bot's queue for a retry
::Left4Bots.BotOrderRetry <- function(bot, order)
{
	Logger.Debug("BotOrderRetry");

	if (!bot || !order || !bot.IsValid() || !IsPlayerABot(bot))
		return;

	Logger.Debug("BotOrderRetry - bot: " + bot.GetPlayerName() + " - order: " + order.OrderType);

	BotOrderAdd(bot, order.OrderType, order.From, order.DestEnt, order.DestPos, order.DestLookAtPos, order.HoldTime, order.CanPause); // Retry
}

// Returns the number of order of type 'orderType' in the bot's queue (including CurrentOrder), or -1 if invalid bot supplied
::Left4Bots.BotOrdersCount <- function (bot, orderType)
{
	if (!IsHandledBot(bot))
		return -1;

	local count = 0;
	local scope = bot.GetScriptScope();

	if (scope.CurrentOrder && scope.CurrentOrder.OrderType == orderType)
		count++;

	for (local i = 0; i < scope.Orders.len(); i++)
	{
		if (scope.Orders[i].OrderType == orderType)
			count++;
	}

	Logger.Debug("[AI]" + bot.GetPlayerName() + " - Has " + count + " orders of type: " + orderType);

	return count;
}

// Returns a string representing the given order
::Left4Bots.BotOrderToString <- function (order)
{
	if (!order)
		return "[null]";

	local ret = "OrderType: " + order.OrderType + " - Priority: " + order.Priority + " - From: ";
	if (order.From)
	{
		if (order.From.IsValid())
			ret += order.From.GetPlayerName();
		else
			ret += "[Invalid Player]";
	}
	else
		ret += "[null]";
	if (order.DestEnt)
		ret += " - DestEnt: " + order.DestEnt;
	if (order.DestPos)
		ret += " - DestPos: " + order.DestPos;
	if (order.DestLookAtPos)
		ret += " - DestLookAtPos: " + order.DestLookAtPos;
	ret += " - DestRadius: " + order.DestRadius;
	ret += " - MaxSeparation: " + order.MaxSeparation;
	ret += " - HoldTime: " + order.HoldTime;
	ret += " - CanPause: " + order.CanPause;

	return ret;
}

// Returns a string representing the current state of the L4B2 AI
::Left4Bots.BotAIToString <- function (bot)
{
	local isBot = IsHandledBot(bot);
	local isL4D1Bot = IsHandledL4D1Bot(bot);
	
	if (!isBot && !isL4D1Bot)
		return "[null]";

	local ret = "--------------------------------------------------------------------- L4B2 AI DUMP ---------------------------------------------------------------------\n";
	if (isL4D1Bot)
		ret += "- L4D1 Bot: " + bot.GetPlayerName() + "\n";
	else
		ret += "- Bot: " + bot.GetPlayerName() + "\n";
	
	local scope = bot.GetScriptScope();
	if (isL4D1Bot)
	{
		ret += "- UserId: " + scope.UserId + "\n";
		ret += "- CharId: " + scope.CharId + "\n";
		ret += "- FuncI: " + scope.FuncI + "\n";
		ret += "- Origin: " + scope.Origin + "\n";
		ret += "- CurTime: " + scope.CurTime + "\n";
		ret += "- ActiveWeapon: " + scope.ActiveWeapon + "\n";
		ret += "- ActiveWeaponId: " + scope.ActiveWeaponId + "\n";
		ret += "- ActiveWeaponSlot: " + scope.ActiveWeaponSlot + "\n";
		ret += "- MoveEnt: " + scope.MoveEnt + "\n";
		ret += "- MovePos: " + scope.MovePos + "\n";
		ret += "- MovePosReal: " + scope.MovePosReal + "\n";
		ret += "- MoveType: AI_MOVE_TYPE." + Left4Utils.TableKeyFromValue(getconsttable()["AI_MOVE_TYPE"], scope.MoveType) + "\n";
		ret += "- MoveTime: " + scope.MoveTime + "\n";
		ret += "- MoveTimeout: " + scope.MoveTimeout + "\n";
		ret += "- NeedMove: " + scope.NeedMove + "\n";
		ret += "- CanReset: " + scope.CanReset + "\n";
		ret += "- DelayedReset: " + scope.DelayedReset + "\n";
		ret += "- TimePickup: " + scope.TimePickup + "\n";
		ret += "- LastPickup: " + scope.LastPickup + "\n";
		ret += "- ThrowType: AI_THROW_TYPE." + Left4Utils.TableKeyFromValue(getconsttable()["AI_THROW_TYPE"], scope.ThrowType) + "\n";
		ret += "- ThrowTarget: " + scope.ThrowTarget + "\n";
		ret += "- ThrowStartedOn: " + scope.ThrowStartedOn + "\n";
		ret += "- HurryUntil: " + scope.HurryUntil + "\n";
		ret += "- Paused: " + scope.Paused + "\n";
		ret += "\n- Num. WeapPref (" + scope.WeapPref.len() + "): ";
		for (local i = 0; i < scope.WeapPref.len(); i++)
		{
			if (i == 0)
				ret += "[" + i + "]: " + scope.WeapPref[i].len();
			else
				ret += ", [" + i + "]: " + scope.WeapPref[i].len();
		}
		ret += "\n- Num. WeaponsToSearch: " + scope.WeaponsToSearch.len() + "\n";
		ret += "- Num. UpgradesToSearch: " + scope.UpgradesToSearch.len() + "\n";
	}
	else
	{
		ret += "- UserId: " + scope.UserId + "\n";
		ret += "- CharId: " + scope.CharId + "\n";
		ret += "- FuncI: " + scope.FuncI + "\n";
		ret += "- Origin: " + scope.Origin + "\n";
		ret += "- CurTime: " + scope.CurTime + "\n";
		ret += "- ActiveWeapon: " + scope.ActiveWeapon + "\n";
		ret += "- ActiveWeaponId: " + scope.ActiveWeaponId + "\n";
		ret += "- ActiveWeaponSlot: " + scope.ActiveWeaponSlot + "\n";
		ret += "- MoveEnt: " + scope.MoveEnt + "\n";
		ret += "- MovePos: " + scope.MovePos + "\n";
		ret += "- MovePosReal: " + scope.MovePosReal + "\n";
		ret += "- MoveType: AI_MOVE_TYPE." + Left4Utils.TableKeyFromValue(getconsttable()["AI_MOVE_TYPE"], scope.MoveType) + "\n";
		ret += "- MoveTime: " + scope.MoveTime + "\n";
		ret += "- MoveTimeout: " + scope.MoveTimeout + "\n";
		ret += "- NeedMove: " + scope.NeedMove + "\n";
		ret += "- CanReset: " + scope.CanReset + "\n";
		ret += "- DelayedReset: " + scope.DelayedReset + "\n";
		ret += "- TimePickup: " + scope.TimePickup + "\n";
		ret += "- LastPickup: " + scope.LastPickup + "\n";
		ret += "- ThrowType: AI_THROW_TYPE." + Left4Utils.TableKeyFromValue(getconsttable()["AI_THROW_TYPE"], scope.ThrowType) + "\n";
		ret += "- ThrowTarget: " + scope.ThrowTarget + "\n";
		ret += "- ThrowStartedOn: " + scope.ThrowStartedOn + "\n";
		ret += "- DoorEnt: " + scope.DoorEnt + "\n";
		ret += "- DoorZ: " + scope.DoorZ + "\n";
		ret += "- DoorAct: AI_DOOR_ACTION." + Left4Utils.TableKeyFromValue(getconsttable()["AI_DOOR_ACTION"], scope.DoorAct) + "\n";
		ret += "- Waiting: " + scope.Waiting + "\n";
		ret += "- SM_IsStuck: " + scope.SM_IsStuck + "\n";
		ret += "- SM_StuckPos: " + scope.SM_StuckPos + "\n";
		ret += "- SM_StuckTime: " + scope.SM_StuckTime + "\n";
		ret += "- SM_MoveTime: " + scope.SM_MoveTime + "\n";
		ret += "- CarryItem: " + scope.CarryItem + "\n";
		ret += "- CarryItemWeaponId: " + scope.CarryItemWeaponId + "\n";
		ret += "- HurryUntil: " + scope.HurryUntil + "\n";
		ret += "- Paused: " + scope.Paused + "\n";
		ret += "- CurrentOrder: " + BotOrderToString(scope.CurrentOrder) + "\n";
		ret += "- Queued Orders (" + scope.Orders.len() + "): ";
		for (local i = 0; i < scope.Orders.len(); i++)
		{
			if (i == 0)
				ret += scope.Orders[i].OrderType;
			else
				ret += ", " + scope.Orders[i].OrderType;
		}
		ret += "\n- Num. WeapPref (" + scope.WeapPref.len() + "): ";
		for (local i = 0; i < scope.WeapPref.len(); i++)
		{
			if (i == 0)
				ret += "[" + i + "]: " + scope.WeapPref[i].len();
			else
				ret += ", [" + i + "]: " + scope.WeapPref[i].len();
		}
		ret += "\n- Num. WeaponsToSearch: " + scope.WeaponsToSearch.len() + "\n";
		ret += "- Num. UpgradesToSearch: " + scope.UpgradesToSearch.len() + "\n";
		
		// TODO: print buttons disabled/forced, movetype etc.
	}
	
	ret += "--------------------------------------------------------------------------------------------------------------------------------------------------------";
	return ret;
}

// Does 'bot' have an order of type 'orderType'?
// true = yes, false = no, null = invalid bot
::Left4Bots.BotHasOrderOfType <- function (bot, orderType)
{
	if (!IsHandledBot(bot))
		return null;

	local scope = bot.GetScriptScope();
	if (scope.CurrentOrder && scope.CurrentOrder.OrderType == orderType)
		return true;

	for (local i = 0; i < scope.Orders.len(); i++)
	{
		if (scope.Orders[i].OrderType == orderType)
			return true;
	}

	return false;
}

// Does 'bot' have an order with a DestEnt of class 'destEntClass'?
// true = yes, false = no, null = invalid bot
::Left4Bots.BotHasOrderDestEnt <- function (bot, destEntClass)
{
	if (!IsHandledBot(bot))
		return null;

	local scope = bot.GetScriptScope();
	if (scope.CurrentOrder && scope.CurrentOrder.DestEnt && scope.CurrentOrder.DestEnt.GetClassname() == destEntClass)
		return true;

	for (local i = 0; i < scope.Orders.len(); i++)
	{
		if (scope.Orders[i].DestEnt && scope.Orders[i].DestEnt.GetClassname() == destEntClass)
			return true;
	}

	return false;
}

// Does any bot have any order with 'destEnt' as DestEnt?
::Left4Bots.BotsHaveOrderDestEnt <- function (destEnt)
{
	if (!destEnt || !destEnt.IsValid())
		return false;

	foreach (bot in Bots)
	{
		local scope = bot.GetScriptScope();
		if (scope.CurrentOrder && scope.CurrentOrder.DestEnt && scope.CurrentOrder.DestEnt.IsValid() && scope.CurrentOrder.DestEnt.GetEntityIndex() == destEnt.GetEntityIndex())
			return true;

		for (local i = 0; i < scope.Orders.len(); i++)
		{
			if (scope.Orders[i].DestEnt && scope.Orders[i].DestEnt.IsValid() && scope.Orders[i].DestEnt.GetEntityIndex() == destEnt.GetEntityIndex())
				return true;
		}
	}

	return false;
}

// Starts an high priority MOVE command (mainly used for spit/charger dodging and such)
::Left4Bots.BotHighPriorityMove <- function (bot, destPos)
{
	if (!destPos || !IsHandledBot(bot))
	{
		Logger.Error("[AI]Can't execute High Priority MOVE; invalid bot/destination (bot: " + bot + " - destPos: " + destPos + ")");
		return false;
	}

	local scope = bot.GetScriptScope();

	if (SurvivorCantMove(bot, scope.Waiting))
	{
		Logger.Debug("[AI]" + bot.GetPlayerName() + " can't execute High Priority MOVE now; bot can't move");
		return false;
	}

	scope.MoveType = AI_MOVE_TYPE.HighPriority;
	scope.MoveTime = Time();
	scope.MoveTimeout = Settings.move_hipri_timeout;
	scope.BotMoveTo(destPos, true);

	Logger.Debug("[AI]" + bot.GetPlayerName() + " - High Priority MOVE -> " + destPos);

	return true;
}

// Tells the bot to throw his throwable item at destPos
::Left4Bots.BotThrow <- function (bot, destPos)
{
	if (!destPos || !IsHandledBot(bot))
	{
		Logger.Error("[AI]Can't throw; invalid bot/destination (bot: " + bot + " - destPos: " + destPos + ")");
		return false;
	}

	local throwItem = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_THROW);
	if (!throwItem || !throwItem.IsValid())
	{
		Logger.Debug("[AI]" + bot.GetPlayerName() + " can't throw; no throw item in inventory");
		return false;
	}

	local scope = bot.GetScriptScope();

	if (SurvivorCantMove(bot, scope.Waiting))
	{
		Logger.Debug("[AI]" + bot.GetPlayerName() + " can't throw now; bot can't move");
		return false;
	}

	scope.ThrowType = AI_THROW_TYPE.Manual;
	scope.ThrowTarget = destPos;
	scope.ThrowStartedOn = Time();

	// Need to disable the fire button until we are ready to throw (or throw is interrupted) otherwise the bot's vanilla AI can trigger the fire before our PressButton and the throw pos will be totally random
	NetProps.SetPropInt(bot, "m_afButtonDisabled", NetProps.GetPropInt(bot, "m_afButtonDisabled") | BUTTON_ATTACK);

	bot.SwitchToItem(throwItem.GetClassname());

	Logger.Debug("[AI]" + bot.GetPlayerName() + " - Throw (" + throwItem + ") -> " + destPos);

	return true;
}

//...


// ------ AI FUNCTIONS (the following functions will run int the scope of the bots entities)

// Main bot think function (splits the work of the entire think process in different frames so the think function isn't overloaded)
::Left4Bots.AIFuncs.BotThink_Main <- function ()
{
	// https://github.com/smilz0/Left4Bots/issues/2
	if (++FuncI > 5)
		FuncI = 1;

	Origin = self.GetOrigin();
	CurTime = Time();
	ActiveWeapon = self.GetActiveWeapon();
	ActiveWeaponId = 0;
	ActiveWeaponSlot = -1;
	if (ActiveWeapon)
	{
		ActiveWeaponId = Left4Utils.GetWeaponId(ActiveWeapon);
		ActiveWeaponSlot = Left4Utils.GetWeaponSlotById(ActiveWeaponId);
	}

	// Basically, all this CarryItem stuff is because some carriable items despawn as prop_physics and respawn as weapon_* and viceversa when picking/dropping them
	// and also because the game's "dropped" event does not trigger every time
	if (CarryItem)
	{
		if (CarryItem != ActiveWeapon || !CarryItem.IsValid())
		{
			if (ActiveWeaponSlot == 5)
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Carry item changed: " + CarryItem + " -> " + ActiveWeapon);
				
				if (L4B.Settings.carry_debug)
					Say(self, "Carry item changed: " + CarryItem + " -> " + ActiveWeapon, false);
				
				local isCarryOrder = false;
				local ordersToUpdate = BotGetOrders(null, null, ActiveWeaponId);
				foreach (orderToUpdate in ordersToUpdate)
				{
					if (orderToUpdate.DestEnt.IsValid())
					{
						if (orderToUpdate.DestEnt == ActiveWeapon)
						{
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt has not changed: " + L4B.BotOrderToString(orderToUpdate));
							isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
						}
						else
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Unrelated order: " + L4B.BotOrderToString(orderToUpdate));
					}
					else
					{
						orderToUpdate.DestEnt = ActiveWeapon;
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt has been updated: " + L4B.BotOrderToString(orderToUpdate));
						isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
					}
				}
				
				if (isCarryOrder)
					L4B.CarryItemStart(self);
				
				CarryItem = ActiveWeapon;
				CarryItemWeaponId = ActiveWeaponId;
			}
			else
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Carry item dropped: " + CarryItem);
				
				if (L4B.Settings.carry_debug)
					Say(self, "Carry item dropped: " + CarryItem, false);
				
				L4B.CarryItemStop(self);
				
				local ordersToUpdate = BotGetOrders(null, CarryItem, CarryItemWeaponId);
				foreach (orderToUpdate in ordersToUpdate)
				{
					if (orderToUpdate.OrderType == "scavenge" && orderToUpdate.DestPos)
					{
						orderToUpdate.DestPos = null;
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestPos has been reset: " + L4B.BotOrderToString(orderToUpdate));
					}
					
					if (CarryItem.IsValid())
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " dropped DestEnt is still valid: " + L4B.BotOrderToString(orderToUpdate));
					else
					{
						// Item dropped and no longer valid
						local newDestEnt = L4B.GetClosestCarriableByWeaponIdWhithin(Origin, CarryItemWeaponId, 350);
						if (newDestEnt)
						{
							orderToUpdate.DestEnt = newDestEnt;
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt has been updated: " + L4B.BotOrderToString(orderToUpdate));
						}
						else
						{
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt was lost. Cancelling the order: " + L4B.BotOrderToString(orderToUpdate));
							if (L4B.Settings.carry_debug)
								Say(self, orderToUpdate.OrderType + " item was lost", false);

							BotCancelOrder(orderToUpdate);
						}
					}
				}
				
				CarryItem = null;
				CarryItemWeaponId = 0;
			}
		}
	}
	else
	{
		if (ActiveWeaponSlot == 5)
		{
			CarryItem = ActiveWeapon;
			CarryItemWeaponId = ActiveWeaponId;
			
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Carry item picked up: " + CarryItem);
			
			if (L4B.Settings.carry_debug)
				Say(self, "Carry item picked up: " + CarryItem, false);
			
			local isCarryOrder = false;
			local ordersToUpdate = BotGetOrders(null, null, CarryItemWeaponId);
			foreach (orderToUpdate in ordersToUpdate)
			{
				if (orderToUpdate.DestEnt.IsValid())
				{
					if (orderToUpdate.DestEnt == CarryItem)
					{
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " item DestEnt has not changed: " + L4B.BotOrderToString(orderToUpdate));
						isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
					}
					else
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Unrelated order: " + L4B.BotOrderToString(orderToUpdate));
				}
				else
				{
					orderToUpdate.DestEnt = CarryItem;
					L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " item DestEnt has been updated: " + L4B.BotOrderToString(orderToUpdate));
					isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
				}
			}
			
			if (isCarryOrder)
				L4B.CarryItemStart(self);
		}
	}

	// Can't do anything at the moment
	if (L4B.SurvivorCantMove(self, Waiting))
	{
		if (!CanReset)
		{
			CanReset = true; // Now we can safely send RESET commands again

			L4B.Logger.Debug("Bot " + self.GetPlayerName() + " CanReset = true");

			// Delayed resets are executed as soon as we can reset again
			if (DelayedReset)
				BotReset(true);
		}
		return L4B.Settings.bot_think_interval;
	}

	// Don't do anything if the bot is on a ladder or the mode hasn't started yet
	if (NetProps.GetPropInt(self, "movetype") == 9 /* MOVETYPE_LADDER */ || !L4B.ModeStarted)
		return L4B.Settings.bot_think_interval;

	// Don't do anything while frozen
	if ((NetProps.GetPropInt(self, "m_fFlags") & (1 << 5)))
	{
		// If the bot has FL_FROZEN flag set, CommandABot will fail even though it still returns true
		// Make sure to send at least one extra move command to the bot after the FL_FROZEN flag is unset
		if (MovePos)
			NeedMove = 2;

		return L4B.Settings.bot_think_interval;
	}

	if (L4B.Settings.fall_velocity_warp != 0 && self.GetVelocity().z <= (-L4B.Settings.fall_velocity_warp))
	{
		local others = L4B.GetOtherAliveSurvivors(UserId);
		if (others.len() > 0)
		{
			local to = others[RandomInt(0, others.len() - 1)];
			if (to && to.IsValid())
			{
				self.SetVelocity(Vector(0,0,0));
				self.SetOrigin(to.GetOrigin());

				L4B.Logger.Info(self.GetPlayerName() + " has been teleported to " + to.GetPlayerName() + " while falling");

				return L4B.Settings.bot_think_interval;
			}
		}
	}

	if (L4B.Settings.stuck_detection)
		BotStuckMonitor();

	// HighPriority MOVEs are spit/charger dodging and such
	if (MovePos && MoveType == AI_MOVE_TYPE.HighPriority)
	{
		// Lets see if we reached our high priority destination...
		if ((Origin - MovePos).Length() <= L4B.Settings.move_end_radius)
		{
			// Yes, we did

			// No longer needed if we set sb_debug_apoproach_wait_time to something like 0.5 or even 0
			// BotReset();

			BotMoveReset();
			//MovePos = null;
			//MovePosReal = null;
			//MoveType = AI_MOVE_TYPE.None;
		}
		else if ((CurTime - MoveTime) >= MoveTimeout)
		{
			// No but the move timed out

			//BotReset();

			BotMoveReset();
			//MovePos = null;
			//MovePosReal = null;
			//MoveType = AI_MOVE_TYPE.None;
		}
		else
			BotMoveTo(MovePos); // No, keep moving
	}

	if (CurTime < HurryUntil) // TODO: Maybe we should also stop high priority moves
	{
		// "hurry" command was used
		BotThink_Misc(); // Still need to trigger car alarms
		return L4B.Settings.bot_think_interval;
	}

	if (L4B.Settings.close_saferoom_door_highres)
		BotThink_Door();

	switch (FuncI)
	{
		case 1:
		{
			BotThink_Pickup();
			break;
		}
		case 2:
		{
			BotThink_Defib();
			break;
		}
		case 3:
		{
			BotThink_Throw();
			break;
		}
		case 4:
		{
			BotThink_Orders();
			break;
		}
		case 5:
		{
			if (!L4B.Settings.close_saferoom_door_highres)
				BotThink_Door();

			BotThink_Misc();
			break;
		}
	}

	BotManualAttack();

	return L4B.Settings.bot_think_interval;
}

// Main bot think function for the extra L4D1 bots
::Left4Bots.AIFuncs.BotThink_Main_L4D1 <- function ()
{
	// https://github.com/smilz0/Left4Bots/issues/2
	if (++FuncI > 5)
		FuncI = 1;

	Origin = self.GetOrigin();
	CurTime = Time();
	ActiveWeapon = self.GetActiveWeapon();
	ActiveWeaponId = 0;
	ActiveWeaponSlot = -1;
	if (ActiveWeapon)
	{
		ActiveWeaponId = Left4Utils.GetWeaponId(ActiveWeapon);
		ActiveWeaponSlot = Left4Utils.GetWeaponSlotById(ActiveWeaponId);
	}

	// Can't do anything at the moment
	if (L4B.SurvivorCantMove(self, Waiting))
	{
		if (!CanReset)
		{
			CanReset = true; // Now we can safely send RESET commands again

			L4B.Logger.Debug("L4D1 Bot " + self.GetPlayerName() + " CanReset = true");

			// Delayed resets are executed as soon as we can reset again
			if (DelayedReset)
				BotReset(true);
		}
		return L4B.Settings.bot_think_interval;
	}

	// Don't do anything if the bot is on a ladder or the mode hasn't started yet
	if (NetProps.GetPropInt(self, "movetype") == 9 /* MOVETYPE_LADDER */ || !L4B.ModeStarted)
		return L4B.Settings.bot_think_interval;

	// Don't do anything while frozen
	if ((NetProps.GetPropInt(self, "m_fFlags") & (1 << 5)))
	{
		// If the bot has FL_FROZEN flag set, CommandABot will fail even though it still returns true
		// Make sure to send at least one extra move command to the bot after the FL_FROZEN flag is unset
		if (MovePos)
			NeedMove = 2;

		return L4B.Settings.bot_think_interval;
	}

	//if (L4B.Settings.stuck_detection)
	//	BotStuckMonitor();

	switch (FuncI)
	{
		case 1:
		{
			BotThink_Pickup();
			break;
		}
		case 3:
		{
			BotThink_Throw();
			break;
		}
	}

	BotManualAttack(false);

	return L4B.Settings.bot_think_interval;
}

// Handles the bot's items pick-up logic
::Left4Bots.AIFuncs.BotThink_Pickup <- function ()	// TODO fix: The sacrifice finale, Francis near the fence started moving for the medkit, while walking around the fence the pickup went too far and stopped, then started again and again.
{
	if ((CurTime - TimePickup) < L4B.Settings.pickups_min_interval)
		return;

	// Don't do this here. Let the bot pick up items that can be picked up directly (without a MOVE command) even if we are moving for something else
	//if (MoveType > AI_MOVE_TYPE.Pickup)
	//	return; // Do nothing if there is an ongoing MOVE with higher priority

	local pickup = BotGetNearestPickupWithin(L4B.Settings.pickups_scan_radius);
	if (!pickup && MoveType == AI_MOVE_TYPE.Pickup && L4B.IsValidPickup(MoveEnt))
		pickup = MoveEnt; // We have no visible pickup nearby at the moment but, if we already got a MoveEnt we are moving to and it's still valid, we'll stick to it even if we can't see it

	if (!pickup)
	{
		// No item to pick up

		if (MoveType == AI_MOVE_TYPE.Pickup)
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - No item to pick up; resetting previous pick-up MOVE");

			// We were moving for a pick-up tho, so we must reset
			BotMoveReset();
		}
		return;
	}

	// Is the item close enough?
	if ((self.GetCenter() - pickup.GetCenter()).Length() <= L4B.Settings.pickups_pick_range) // There is a cvar (player_use_radius 96) but idk how the distance is calculated, seems not to be from the player's origin or center
	{
		// Yes, pick it up
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Picking up: " + pickup);

		// After this item, wait till WeaponsToSearch gets updated before picking up anything else
		WeaponsToSearch.clear();

		TimePickup = CurTime;

		Left4Timers.AddTimer(null, L4B.Settings.pickups_failsafe_delay, @(params) ::Left4Bots.PickupFailsafe.bindenv(::Left4Bots)(params.bot, params.item), { bot = self, item = pickup });
		Left4Utils.PlayerPressButton(self, BUTTON_USE, L4B.Settings.button_holdtime_tap, pickup, 0, 0, true);

		if (MoveType == AI_MOVE_TYPE.Pickup)
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Item picked up: resetting MOVE");

			// Reset if we were moving for this item
			BotMoveReset();
		}
		// else means that we picked up an item while moving for something else

		// We are done with this item
		return;
	}

	// So, we have an item to pickup but it's not close enough yet. Should we move for it?

	// Do it here
	if (MoveType > AI_MOVE_TYPE.Pickup)
		return; // Do not move for the item if there is an ongoing MOVE with higher priority

	// Don't move for the item if finale escape started, there are teammates who need help or we are too far from the human survivors
	// if (BotIsInPause()) // TODO: Should we?
	if (L4B.EscapeStarted || L4B.SurvivorsHeldOrIncapped() || (L4B.Settings.pickups_max_separation > 0 && L4B.IsFarFromHumanSurvivors(UserId, Origin, L4B.Settings.pickups_max_separation))) // TODO: max separation only if lagging behind?
	{
		if (MoveType == AI_MOVE_TYPE.Pickup)
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Teammates need help or too far: resetting MOVE");

			// Reset if we were moving for this item
			BotMoveReset();
		}
		return;
	}

	if (!MovePos || MoveType != AI_MOVE_TYPE.Pickup || !L4B.IsValidPickup(MoveEnt) || /*MoveEnt.GetEntityIndex() != pickup.GetEntityIndex()*/ MoveEnt != pickup)
	{
		// We start a MOVE if at least one of these conditions is met:
		// 1. There is no previous MOVE
		// 2. The previous MOVE has a lower priority
		// 3. Our destination item (MoveEnt) wasn't set or is no longer valid
		// 4. Our destination item (MoveEnt) changed

		MoveType = AI_MOVE_TYPE.Pickup;
		MoveEnt = pickup;
		
		if (L4B.Settings.moveto_nav)
			BotMoveToNav(MoveEnt.GetOrigin(), true);
		else
			BotMoveTo(MoveEnt.GetOrigin(), true);

		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Started moving for: " + MoveEnt);
	}
	else
	{
		// Already moving for the item (MoveEnt), keep moving
		if (L4B.Settings.moveto_nav)
			BotMoveToNav(MoveEnt.GetOrigin());
		else
			BotMoveTo(MoveEnt.GetOrigin());
	}
}

// Handles the bot's defib logic
::Left4Bots.AIFuncs.BotThink_Defib <- function ()
{
	if (MoveType > AI_MOVE_TYPE.Defib)
		return; // Do nothing if there is an ongoing MOVE with higher priority

	if (L4B.IsSomeoneElseHolding(UserId, "weapon_defibrillator"))
	{
		// Someone else is holding a defibrillator, likely they are already about to defib the dead one

		if (MoveType == AI_MOVE_TYPE.Defib)
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Someone else is about to defib; resetting");

			BotMoveReset();
		}
		return;
	}

	if (MoveType != AI_MOVE_TYPE.Defib)
	{
		// We aren't executing any defib atm

		// Is there any survivor_death_model we can actually defib?
		local death = null;
		if (Left4Utils.HasDefib(self))
			death = L4B.GetNearestDeathModelWithin(self, Origin, L4B.Settings.deads_scan_radius, L4B.Settings.deads_scan_maxaltdiff); // If we have a defibrillator we'll search the nearest death model within a certain radius
		else
			death = L4B.GetNearestDeathModelWithDefibWithin(self, Origin, L4B.Settings.deads_scan_radius, L4B.Settings.deads_scan_maxaltdiff); // Otherwise we'll search the nearest death model within a certain radius with a defibrillator nearby

		if (!death || !death.IsValid())
			return; // No one to defib

		// TODO?
		//if (L4B.HasAngryCommonsWithin(orig, 3, 100) != false || Left4Utils.HasSpecialInfectedWithin(self, 400) || L4B.SurvivorsHeldOrIncapped())
		if (BotIsInPause()) // TODO: maxSeparation
			return;

		MoveType = AI_MOVE_TYPE.Defib;
		MoveEnt = death;
		
		if (L4B.Settings.moveto_nav)
			BotMoveToNav(MoveEnt.GetOrigin(), true);
		else
			BotMoveTo(MoveEnt.GetOrigin(), true);

		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Started moving for: " + MoveEnt);

		return;
	}

	// We are already moving for a survivor_death_model

	// TODO?
	//if (L4B.HasAngryCommonsWithin(orig, 3, 100) != false || Left4Utils.HasSpecialInfectedWithin(self, 400) || L4B.SurvivorsHeldOrIncapped())
	if (BotIsInPause()) // TODO: maxSeparation
		return;

	// Reset if our destination survivor_death_model is no longer valid
	if (!MovePos || !MoveEnt || !MoveEnt.IsValid())
	{
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Dest death model no longer valid; resetting");

		BotMoveReset();

		return;
	}

	// Destination survivor_death_model is still there and no one is defibbing it, let's see if we reached it
	if ((Origin - MovePos).Length() <= L4B.Settings.move_end_radius_defib)
	{
		// We reached the dead survivor, but do we have a defibrillator?
		if (!Left4Utils.HasDefib(self))
		{
			// Nope, but we are supposed to find it here
			local defib = L4B.FindDefibPickupWithin(MoveEnt.GetOrigin());
			if (!defib)
			{
				// We don't have a defib and we came for a death model with defib nearby that is no longer available, so let's reset

				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Dest death had a defib nearby but it's no longer available; resetting");

				BotMoveReset();

				return;
			}

			DoEntFire("!self", "Use", "", 0, self, defib);

			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Picked up a defib near the death model");

			// Do nothing until the defib is fully in our inventory
		}
		else
		{
			// We either came here with a defibrillator or we picked it up here, but are we holding it?
			if (ActiveWeapon && ActiveWeapon.GetClassname() == "weapon_defibrillator")
			{
				// Yes, but can we use it right now?
				if (CurTime > NetProps.GetPropFloat(ActiveWeapon, "m_flNextPrimaryAttack") + 0.1) // <- Add a little delay or the animation will be bugged
					Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_defib, MoveEnt, 0, 0, true); // Yes
			}
			else if (ActiveWeapon && ActiveWeapon.GetClassname() != "weapon_pain_pills" && ActiveWeapon.GetClassname() != "weapon_adrenaline") // We'll run into an infinite switch loop if the vanilla AI wants to use pills/adrenaline
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - About to start defib");

				self.SwitchToItem("weapon_defibrillator");
			}
		}
	}
	else
	{
		if (L4B.Settings.moveto_nav)
			BotMoveToNav(MoveEnt.GetOrigin()); // Not there yet, keep moving
		else
			BotMoveTo(MoveEnt.GetOrigin()); // Not there yet, keep moving
	}
}

// Handles the bot's items give and nades throw logics
::Left4Bots.AIFuncs.BotThink_Throw <- function ()
{
	/* I'm not sure this is even needed, the bots already retreat on their own and this has no effect when there is a downed survivor anyway
	local nearestTank = L4B.GetNearestActiveTankWithin(self, 0, RETREAT_FROM_TANK_DINSTANCE);
	if (nearestTank && !nearestTank.IsDead() && !nearestTank.IsDying() && !nearestTank.IsIncapacitated())
	{
		Left4Utils.BotCmdRetreat(self, nearestTank);

		L4B.Logger.Debug(self.GetPlayerName() + " RETREAT");
	}
	*/

	// Handle give items
	local lookAtHuman = NetProps.GetPropEntity(self, "m_lookatPlayer");
	if (lookAtHuman && lookAtHuman.IsValid() && !IsPlayerABot(lookAtHuman) && NetProps.GetPropInt(lookAtHuman, "m_iTeamNum") == TEAM_SURVIVORS && !L4B.SurvivorCantMove(lookAtHuman, Waiting) && (Origin - lookAtHuman.GetOrigin()).Length() <= L4B.Settings.give_max_range)
	{
		// Then try with pills and adrenaline
		if (L4B.GiveInventoryItem(self, lookAtHuman, INV_SLOT_PILLS))
			return; // Don't do anything else if the give succedes

		// Try give a throwable
		if (L4B.GiveInventoryItem(self, lookAtHuman, INV_SLOT_THROW))
			return; // Don't do anything else if the give succedes

		// Last try with medkits / defib / upgrade packs
		if (L4B.GiveInventoryItem(self, lookAtHuman, INV_SLOT_MEDKIT))
			return; // Don't do anything else if the give succedes
	}

	// Handle throw nades
	if ((ThrowStartedOn && (CurTime - ThrowStartedOn) > 5.0) || L4B.SurvivorCantMove(self, Waiting))
	{
		// Reset last attempted throw if takes too long (likely we got interrupted while switching) or bot can't move (probably got pinned)
		ThrowType = AI_THROW_TYPE.None;
		ThrowTarget = null;
		ThrowStartedOn = 0;

		// Don't forget to re-enable the fire button
		NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK));

		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Throw expired");
	}

	local heldClass = null;
	if (ActiveWeapon && ActiveWeapon.IsValid())
		heldClass = ActiveWeapon.GetClassname();

	if (heldClass && (heldClass == "weapon_molotov" || heldClass == "weapon_pipe_bomb" || heldClass == "weapon_vomitjar"))
	{
		// Probably we're about to throw this. Let's see if we can...
		if (CurTime > NetProps.GetPropFloat(ActiveWeapon, "m_flNextPrimaryAttack"))
		{
			if (ThrowTarget && L4B.ShouldStillThrow(self, UserId, Origin, ThrowType, ThrowTarget, heldClass))
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Throw finalization - ThrowType: " + ThrowType + " - ThrowTarget: " + ThrowTarget);

				// Don't forget to re-enable the fire button
				NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK));

				switch (ThrowType)
				{
					case AI_THROW_TYPE.Tank:
					{
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_tap, ThrowTarget, L4B.Settings.tank_throw_deltapitch, 0, true, 1);
						break;
					}
					case AI_THROW_TYPE.Horde:
					{
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_tap, ThrowTarget, L4B.Settings.throw_nade_deltapitch, 0, true, 1);
						break;
					}
					case AI_THROW_TYPE.Manual:
					{
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_tap, ThrowTarget, L4B.Settings.throw_nade_deltapitch, 0, true, 1);
						break;
					}
					default: // None
					{
						// Not supposed to happen, but..
						L4B.BotSwitchToAnotherWeapon(self);
					}
				}

				ThrowType = AI_THROW_TYPE.None;
				ThrowTarget = null;
				ThrowStartedOn = 0;
			}
			else
			{
				// We no longer have a valid throw target
				ThrowType = AI_THROW_TYPE.None;
				ThrowTarget = null;
				ThrowStartedOn = 0;

				// Don't forget to re-enable the fire button
				NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK));

				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Throw no longer valid");

				L4B.BotSwitchToAnotherWeapon(self);
			}
		}
	}
	else if (ThrowType == AI_THROW_TYPE.None && !ThrowTarget) // Only if there is no ongoing throw
	{
		local throwItem = Left4Utils.GetInventoryItemInSlot(self, INV_SLOT_THROW);
		if (throwItem && throwItem.IsValid())
		{
			local itemClass = throwItem.GetClassname();

			// Do we have a throw target?
			ThrowTarget = L4B.GetThrowTarget(self, UserId, Origin, itemClass);
			if (ThrowTarget)
			{
				if ((typeof ThrowTarget) == "instance")
					ThrowType = AI_THROW_TYPE.Tank;
				else
					ThrowType = AI_THROW_TYPE.Horde;
				ThrowStartedOn = CurTime;

				// Need to disable the fire button until we are ready to throw (or throw is interrupted) otherwise the bot's vanilla AI can trigger the fire before our PressButton and the throw pos will be totally random
				NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") | BUTTON_ATTACK);

				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Throw (" + itemClass + ") -> " + ThrowTarget);

				self.SwitchToItem(itemClass); // Yes, switch to the throw item
			}
		}
	}
}

// Handles the bot's orders execution logic
::Left4Bots.AIFuncs.BotThink_Orders <- function ()
{
	if (MoveType > AI_MOVE_TYPE.Order)
		return; // Do nothing if there is an ongoing MOVE with higher priority
	
	if (!CurrentOrder && Orders.len() > 0)
	{
		CurrentOrder = Orders.remove(0); // Get the next order to execute and remove it from the FIFO queue
		
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - New CurrentOrder: " + L4B.BotOrderToString(CurrentOrder));
	}
	
	if (!CurrentOrder)
		return; // Nothing to do
	
	if (CurrentOrder.OrderType == "carry" && CarryItem == CurrentOrder.DestEnt)
	{
		// We're holding our carry item. Do nothing but handle the pauses
		BotIsInPause(CurrentOrder.CanPause, false, CurrentOrder.MaxSeparation);
		return;
	}
	
	if (CurrentOrder.DestEnt && !L4B.IsValidUseItem(CurrentOrder.DestEnt, (CurrentOrder.OrderType == "scavenge" || CurrentOrder.OrderType == "carry") ? self : null))
	{
		// Order's DestEnt is no longer valid or it was picked up by someone. Cancel this order
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - CurrentOrder's DestEnt is no longer valid: " + L4B.BotOrderToString(CurrentOrder));
		
		BotCancelCurrentOrder();

		return;
	}
	
	// Execute CurrentOrder
	
	if (CurrentOrder.OrderType == "follow")
	{
		if (BotIsInPause(CurrentOrder.CanPause, false, CurrentOrder.MaxSeparation, CurrentOrder.DestEnt, L4B.Settings.follow_pause_radius))
			return;
	}
	else
	{
		if (BotIsInPause(CurrentOrder.CanPause, CurrentOrder.OrderType == "heal", CurrentOrder.MaxSeparation))
			return;
	}
	
	// BotIsInPause can call BotFinalizeCurrentOrder, so CurrentOrder can also be null here. Let's check it again...
	if (!CurrentOrder)
		return;
	
	if (!MovePos || MoveType != AI_MOVE_TYPE.Order)
	{
		// We also get here when we were already executing the order but an higher priority MOVE took over and now it's finished
		BotInitializeCurrentOrder();
	}
	else
	{
		// Already moving for the current order
		
		// Lets see if we reached the order's destination...
		local destPos = CurrentOrder.DestPos;
		if (!destPos && CurrentOrder.DestEnt)
			destPos = CurrentOrder.DestEnt.GetOrigin();
		if (!destPos)
			destPos = MovePos;

		if ((Origin - destPos).Length() <= CurrentOrder.DestRadius)
		{
			// Yes, we did
			// BotReset(); // No longer needed if we set sb_debug_apoproach_wait_time to something like 0.5 or even 0
			
			BotFinalizeCurrentOrder();
		}
		else
		{
			// Not yet. Keep moving...
			if (destPos)
			{
				if (L4B.Settings.moveto_nav && (CurrentOrder.OrderType == "scavenge" || CurrentOrder.OrderType == "carry"))
					BotMoveToNav(destPos);
				else
					BotMoveTo(destPos);
			}
			else
				BotFinalizeCurrentOrder();
		}
	}
}

// Handles the bot's open/close door logics
::Left4Bots.AIFuncs.BotThink_Door <- function ()
{
	if (MoveType > AI_MOVE_TYPE.Door)
		return; // Do nothing if there is an ongoing MOVE with higher priority

	if (!DoorEnt)
		return; // Nothing to do

	// Is our door still valid?
	if (!DoorEnt.IsValid())
	{
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - DoorEnt is no longer valid");

		// Nope, reset
		DoorEnt = null;
		DoorZ = 0;
		DoorAct = AI_DOOR_ACTION.None;

		if (MoveType == AI_MOVE_TYPE.Door)
			BotMoveReset();

		return;
	}

	// We do have a door to open/close
	local doorPos = Vector(DoorEnt.GetCenter().x, DoorEnt.GetCenter().y, DoorZ);

	if (DoorAct == AI_DOOR_ACTION.Saferoom)
	{
		// This means that we need to close a saferoom door and we must do it without locking ourselves out

		local area = self.GetLastKnownArea(); // Get the area currently occupied by the bot
		if (area)
		{
			if (area.HasSpawnAttributes(NAVAREA_SPAWNATTR_CHECKPOINT))
			{
				// When the SaferoomDoor gets set, the bot is likely on a nav area with both CHECKPOINT and DOOR spawn attrs
				// Closing the door now can result in the bot locking himself out, so we wait for the bot to step on the first CHECKPOINT nav area without the DOOR attr
				//if (!area.HasSpawnAttributes(NAVAREA_SPAWNATTR_DOOR))
				// Nope, different method: we wait till the bot's distance from the door is > close_saferoom_door_distance
				if ((Origin - doorPos).Length() > L4B.Settings.close_saferoom_door_distance)
				{
					// Now we can finally close it
					DoorAct = AI_DOOR_ACTION.Close;
				}
			}
			else
			{
				// Did the bot step outside the saferoom?
				DoorEnt = null;
				DoorZ = 0;
				DoorAct = AI_DOOR_ACTION.None;

				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - DoorEnt reset; bot stepped outside the saferoom");
			}
		}
	}

	if (DoorAct != AI_DOOR_ACTION.Open && DoorAct != AI_DOOR_ACTION.Close)
		return; // Likely it's still AI_DOOR_ACTION.Saferoom, we must wait until we can actually close it

	// Are we close enough to the door, yet?
	if ((Origin - doorPos).Length() <= L4B.Settings.move_end_radius_door)
	{
		// Yes, open/close it

		if (DoorAct == AI_DOOR_ACTION.Open)
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Opening the door: " + DoorEnt.GetName());
		else
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Closing the door: " + DoorEnt.GetName());

		Left4Utils.PlayerPressButton(self, BUTTON_USE, L4B.Settings.button_holdtime_tap, DoorEnt, 0, 0, true);
		Left4Timers.AddTimer(null, L4B.Settings.door_failsafe_delay, @(params) ::Left4Bots.DoorFailsafe.bindenv(::Left4Bots)(params.bot, params.door, params.action), { bot = self, door = DoorEnt, action = DoorAct });

		// Reset
		DoorEnt = null;
		DoorZ = 0;
		DoorAct = AI_DOOR_ACTION.None;

		if (MoveType == AI_MOVE_TYPE.Door)
			BotMoveReset();
	}
	else
	{
		// Not yet. Do we need to start or keep moving?
		if (!MovePos || MoveType != AI_MOVE_TYPE.Door)
		{
			MoveType = AI_MOVE_TYPE.Door;
			BotMoveTo(doorPos, true); // Start move
		}
		else
			BotMoveTo(doorPos); // Keep move
	}
}

// Handles other bot's logics
::Left4Bots.AIFuncs.BotThink_Misc <- function ()
{
	// Handling car alarms
	if (L4B.Settings.trigger_caralarm)
	{
		local groundEnt = NetProps.GetPropEntity(self, "m_hGroundEntity");
		if (groundEnt && groundEnt.IsValid() && groundEnt.GetClassname() == "prop_car_alarm")
			L4B.TriggerCarAlarm(self, groundEnt);
	}
}

// Handles the bot's enemy melee/shove/shoot logics
// Also prevents the bots for reloading their weapons for no reason while they are executing a MOVE command
::Left4Bots.AIFuncs.BotManualAttack <- function (shootWhileMove = true)
{
	local canMelee = ActiveWeapon && ActiveWeapon.GetClassname() == "weapon_melee" && CurTime >= NetProps.GetPropFloat(ActiveWeapon, "m_flNextPrimaryAttack");
	local canShove = !self.IsFiringWeapon() && CurTime >= NetProps.GetPropFloat(self, "m_flNextShoveTime"); // TODO: add shove penalty?
	local target = null;
	local dot = 0;
	if (canMelee || canShove)
	{
		// Search for a close target that is in range for both melee and shove
		if (L4B.Settings.shove_tonguevictim_radius > 0)
			target = L4B.GetTongueVictimToShove(self, Origin); // Is there any tongue victim teammate to shove?

		if (!target && L4B.Settings.shove_specials_radius > 0)
			target = L4B.GetSpecialInfectedToShove(self, Origin); // No. Any special infected?

		if (!target && L4B.Settings.shove_commons_radius > 0)
			target = Left4Utils.GetFirstShovableCommonInfectedWithin(self, L4B.Settings.shove_commons_radius); // No. Any common?

		if (target)
		{
			local toTarget = target.GetOrigin() - Origin;
			toTarget.Norm();
			dot = self.EyeAngles().Forward().Dot(toTarget);
		}
	}

	// If we have a close target that we can either melee or shove then melee/shove it
	if (target && canMelee && dot >= 0.6)
		Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_tap, target.GetCenter(), 0, 0, false);
	else if (target && canShove) // TODO: add dot?
		Left4Utils.PlayerPressButton(self, BUTTON_SHOVE, L4B.Settings.button_holdtime_tap, target.GetCenter(), 0, 0, false);
	else if (shootWhileMove && MovePos && Paused == 0 && NetProps.GetPropInt(self, "m_hasVisibleThreats")) // m_hasVisibleThreats indicates that a threat is in the bot's current field of view. An infected behind the bot won't set this
	{
		// If no close target or we cannot melee or shove it at the moment, then handle manual shooting to targets in our field of view, but only if we are executing a MOVE command
		if (ActiveWeapon && !NetProps.GetPropInt(ActiveWeapon, "m_bInReload"))
		{
			if (ActiveWeaponSlot == 0 || ActiveWeaponSlot == 1)
			{
				local tgt = L4B.FindBotNearestEnemy(self, Origin, L4B.GetWeaponRangeById(ActiveWeaponId), L4B.Settings.manual_attack_mindot);
				if (tgt)
					Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_tap, tgt.GetCenter(), 0, 0, false);

				// Bots always reload for no reason while executing a MOVE command. Don't let them if there are visible threats and still rounds in the magazine
				if (ActiveWeapon.Clip1() >= 5)
				{
					Left4Utils.PlayerDisableButton(self, BUTTON_RELOAD);
					return;
				}
			}
		}
	}

	Left4Utils.PlayerEnableButton(self, BUTTON_RELOAD);
}

// Based on the Valve's C++ ILocomotion::StuckMonitor()
// It tries to detect the stuck status of the bot before the C++ does. The bot's AI will use this to try to reset the MOVE and start a Pause before the bot gets teleported
::Left4Bots.AIFuncs.BotStuckMonitor <- function ()
{
	if ((NetProps.GetPropInt(self, "m_nButtons") & (BUTTON_FORWARD + BUTTON_BACK + BUTTON_MOVELEFT + BUTTON_MOVERIGHT)) != 0)
	{
		// Bot is trying to move
		if (SM_MoveTime == 0)
			SM_MoveTime = CurTime; // Start of the move
	}
	else
		SM_MoveTime = 0; // No longer trying to move

	if (SM_MoveTime == 0 || (CurTime - SM_MoveTime) < 0.25)
	{
		if (L4B.Settings.stuck_nomove_unstuck && SM_IsStuck)
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " [UN-STUCK]");
			if (L4B.Settings.stuck_debug)
				Say(self, "[UN-STUCK]", false);

			SM_IsStuck = false;
		}

		SM_StuckPos = Origin;
		SM_StuckTime = CurTime;

		return false;
	}

	if (SM_IsStuck)
	{
		if ((Origin - SM_StuckPos).Length() > L4B.Settings.stuck_range)
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " [UN-STUCK]");
			if (L4B.Settings.stuck_debug)
				Say(self, "[UN-STUCK]", false);

			SM_IsStuck = false;
			SM_StuckPos = Origin;
			SM_StuckTime = CurTime;
		}
	}
	else
	{
		//if ( /*IsClimbingOrJumping() || */GetBot()->IsRangeGreaterThan( m_stuckPos, STUCK_RADIUS ) )
		if ((Origin - SM_StuckPos).Length() > L4B.Settings.stuck_range)
		{
			SM_StuckPos = Origin;
			SM_StuckTime = CurTime;
		}
		else
		{
			local m_StuckLast = NetProps.GetPropInt(self, "m_StuckLast");
			if (m_StuckLast != 0)
				printl(self.GetPlayerName() + " m_StuckLast: " + m_StuckLast);

			//local minMoveSpeed = 0.1 * GetDesiredSpeed() + 0.1;
			//local escapeTime = L4B.Settings.stuck_range / minMoveSpeed;
			//if ((CurTime - SM_StuckTime) > escapeTime)
			if ((CurTime - SM_StuckTime) >= L4B.Settings.stuck_time)
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " [STUCK]");
				if (L4B.Settings.stuck_debug)
					Say(self, "[STUCK]", false);

				SM_IsStuck = true;

				//if (MovePos)
				//	BotReset();
				//  BotCancelAll();
			}
		}
	}

	return SM_IsStuck;
}

// Send the MOVE command to reach the given position, but only when really needed
// force = true to start moving or to force a MOVE command. force = false to keep moving and only send another MOVE command if needed
::Left4Bots.AIFuncs.BotMoveTo <- function (dest, force = false)
{
	if (!dest)
		return;

	if (force || !MovePos)
		NeedMove = 2;	// For some reason, sometimes, the first MOVE does nothing so let's send at least 2

	if (NeedMove <= 0 && (dest - MovePos).Length() <= 5) // <- This checks if the destination entity moved after the bot started moving towards it and forces a move command to the new entity position if the entity moved
		return;

	if (NetProps.GetPropInt(self, "m_fFlags") & (1 << 5))
		return;

	// Reset movetype if needed
	Waiting = false;
	if (NetProps.GetPropInt(self, "movetype") == 0)
		NetProps.SetPropInt(self, "movetype", 2);
	NetProps.SetPropInt(self, "m_afButtonForced", NetProps.GetPropInt(self, "m_afButtonForced") & (~BUTTON_DUCK));

	MovePos = dest;
	MovePosReal = MovePos;

	if (L4B.Settings.moveto_debug_duration > 0)
		DebugDrawCircle(MovePosReal, Vector(255, 0, 0), 255, 6, true, L4B.Settings.moveto_debug_duration);

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - MOVE -> " + MovePos + " (real: " + MovePosReal + ")");

	Left4Utils.BotCmdMove(self, MovePosReal);
	DelayedReset = false; // Reset no longer needed as the MOVE replaced the previous one

	NeedMove--;
}

// Send the MOVE command to reach the given position, but only when really needed
// force = true to start moving or to force a MOVE command. force = false to keep moving and only send another MOVE command if needed
// If the dest pos is not in a nav area, it is moved into the nearest nav area
::Left4Bots.AIFuncs.BotMoveToNav <- function (dest, force = false)
{
	if (!dest)
		return;

	if (force || !MovePos)
		NeedMove = 2;	// For some reason, sometimes, the first MOVE does nothing so let's send at least 2

	if (NeedMove <= 0 && (dest - MovePos).Length() <= 5) // <- This checks if the destination entity moved after the bot started moving towards it and forces a move command to the new entity position if the entity moved
		return;

	if (NetProps.GetPropInt(self, "m_fFlags") & (1 << 5))
		return;

	// Reset movetype if needed
	Waiting = false;
	if (NetProps.GetPropInt(self, "movetype") == 0)
		NetProps.SetPropInt(self, "movetype", 2);
	NetProps.SetPropInt(self, "m_afButtonForced", NetProps.GetPropInt(self, "m_afButtonForced") & (~BUTTON_DUCK));

	MovePos = dest;

	// checkLOS = true -> ignores blocked areas which is bad for c1m2_streets when to press the gunshop button because it gets the previous area that is too far from the button so the bot fails to press the button
	local area = NavMesh.GetNearestNavArea(MovePos, 120, true, false);
	// checkLOS = false -> good for c1m2_streets but bad for all the rest because it doesn't check the LOS and gets the area behind the wall if it's closer to the item. RIP c1m2_streets button i guess...
	//local area = NavMesh.GetNearestNavArea(MovePos, 120, false, false); // checkLOS = false -> ignores blocked areas
	if (area)
	{
		local center = area.GetCenter();
		local halfX = area.GetSizeX() / 2;
		local halfY = area.GetSizeY() / 2;

		if (MovePos.x >= center.x - halfX && MovePos.x <= center.x + halfX && MovePos.y >= center.y - halfY && MovePos.y <= center.y + halfY)
		{
			// Dest pos is inside the area's 2D bounds
			MovePosReal = Vector(MovePos.x, MovePos.y, area.GetCenter().z);
		}
		else
		{
			// It's outside, need to find the closest point inside the area
			MovePosReal = Vector(Left4Utils.Max(center.x - halfX, Left4Utils.Min(MovePos.x, center.x + halfX)), Left4Utils.Max(center.y - halfY, Left4Utils.Min(MovePos.y, center.y + halfY)), center.z);
		}
		MovePosReal = Vector(MovePosReal.x, MovePosReal.y, area.GetZ(MovePosReal)); // Adjust the height at the specified point

		if (L4B.Settings.moveto_debug_duration > 0)
			area.DebugDrawFilled(0, 0, 255, 255, L4B.Settings.moveto_debug_duration, true);
	}
	else
	{
		L4B.Logger.Warning("[AI]" + self.GetPlayerName() + " - BotMoveToNav -> " + MovePos + " - No NavArea found nearby; using the dest pos");
		MovePosReal = MovePos;
	}

	if (L4B.Settings.moveto_debug_duration > 0)
		DebugDrawCircle(MovePosReal, Vector(255, 0, 0), 255, 6, true, L4B.Settings.moveto_debug_duration);

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - MOVE -> " + MovePos + " (real: " + MovePosReal + ")");

	Left4Utils.BotCmdMove(self, MovePosReal);
	DelayedReset = false; // Reset no longer needed as the MOVE replaced the previous one

	NeedMove--;
}

// Reset the MOVE parameters and, if needed, the MOVE itself and the movetype
::Left4Bots.AIFuncs.BotMoveReset <- function ()
{
	// Reset the MOVE if needed
	if (MovePos)
		BotReset();

	// Reset movetype if needed
	Waiting = false;
	if (NetProps.GetPropInt(self, "movetype") == 0)
		NetProps.SetPropInt(self, "movetype", 2);
	NetProps.SetPropInt(self, "m_afButtonForced", NetProps.GetPropInt(self, "m_afButtonForced") & (~BUTTON_DUCK));

	// Reset MOVE parameters
	MoveEnt = null;
	MovePos = null;
	MovePosReal = null;
	MoveType = AI_MOVE_TYPE.None;
	NeedMove = 0;
}

// Send a RESET command to the bot (if CanReset is true)
::Left4Bots.AIFuncs.BotReset <- function (isDelayed = false)
{
	if (CanReset)
	{
		if (isDelayed)
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - DELAYED RESET");
		else
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - RESET");

		// TODO: Should we send delayed resets or not? It seems that they can get the bots stuck sometimes. Need to verify
		//if (!isDelayed)
			Left4Utils.BotCmdReset(self);

		DelayedReset = false;
	}
	else
	{
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - RESET has been delayed");

		DelayedReset = true;
	}
}

// Updates the bot's pickups search lists (WeaponsToSearch and UpgradesToSearch)
::Left4Bots.AIFuncs.BotUpdatePickupToSearch <- function ()
{
	WeaponsToSearch.clear();
	UpgradesToSearch.clear();

	local currWeps = [Left4Utils.WeaponId.none, Left4Utils.WeaponId.none, Left4Utils.WeaponId.none, Left4Utils.WeaponId.none, Left4Utils.WeaponId.none]; // Will be filled with the weapon ids of the bot's current weapons
	local hasT1Shotgun = false;
	local hasT2Shotgun = false;
	local priAmmoPercent = 100;
	local hasAmmoUpgrade = true;
	local hasLaserSight = true;
	local hasChainsaw = false;
	local hasPistol = false;
	local hasDualPistol = false;
	local hasMelee = false;
	local hasMolotov = false;
	local hasPipeBomb = false;
	local hasVomitJar = false;
	local hasMedkit = false;
	local hasDefib = false;
	local hasUpgdInc = false;
	local hasUpgdExp = false;
	local wantsMolotov = false;
	local wantsPipeBomb = false;
	local wantsVomitJar = false;
	local wantsMedkit = false;
	local wantsDefib = false;
	local wantsUpgdInc = false;
	local wantsUpgdExp = false;
	local inv = {};

	GetInvTable(self, inv);

	// For each slot...
	for (local i = 0; i < 5; i++)
	{
		local slot = "slot" + i;

		// Get the current weapon id for this slot (if any)
		if (slot in inv)
		{
			currWeps[i] = Left4Utils.GetWeaponId(inv[slot]);

			if (i == 0)
			{
				hasT1Shotgun = (currWeps[i] == Left4Utils.WeaponId.weapon_shotgun_chrome) || (currWeps[i] == Left4Utils.WeaponId.weapon_pumpshotgun);
				hasT2Shotgun = (currWeps[i] == Left4Utils.WeaponId.weapon_autoshotgun) || (currWeps[i] == Left4Utils.WeaponId.weapon_shotgun_spas);
				priAmmoPercent = Left4Utils.GetAmmoPercent(inv[slot]);
				hasAmmoUpgrade = NetProps.GetPropInt(inv[slot], "m_nUpgradedPrimaryAmmoLoaded") >= L4B.Settings.pickups_wep_upgraded_ammo;
				hasLaserSight = (NetProps.GetPropInt(inv[slot], "m_upgradeBitVec") & 4) != 0;
			}
			else if (i == 1)
			{
				hasChainsaw = currWeps[i] == Left4Utils.WeaponId.weapon_chainsaw;
				hasPistol = currWeps[i] == Left4Utils.WeaponId.weapon_pistol;
				if (hasPistol)
					//hasDualPistol = NetProps.GetPropInt(inv[slot], "m_hasDualWeapons") > 0; // ???? This doesn't work sometimes
					hasDualPistol = NetProps.GetPropInt(inv[slot], "m_isDualWielding") > 0;
				hasMelee = currWeps[i] > Left4Utils.MeleeWeaponId.none;
			}
			else if (i == 2)
			{
				hasMolotov = currWeps[i] == Left4Utils.WeaponId.weapon_molotov;
				hasPipeBomb = currWeps[i] == Left4Utils.WeaponId.weapon_pipe_bomb;
				hasVomitJar = currWeps[i] == Left4Utils.WeaponId.weapon_vomitjar;
			}
			else if (i == 3)
			{
				hasMedkit = currWeps[i] == Left4Utils.WeaponId.weapon_first_aid_kit;
				hasDefib = currWeps[i] == Left4Utils.WeaponId.weapon_defibrillator;
				hasUpgdInc = currWeps[i] == Left4Utils.WeaponId.weapon_upgradepack_incendiary;
				hasUpgdExp = currWeps[i] == Left4Utils.WeaponId.weapon_upgradepack_explosive;
			}
		}
	}

	local slotIdx = 0;
	local useWeapon = (slotIdx in UseWeapons) ? UseWeapons[slotIdx] : 0;
	if (L4B.Settings.pickups_wep_always || (MovePos && MoveType == AI_MOVE_TYPE.Order && Paused == 0))
	{
		// PRIMARY
		if (useWeapon != 0 && useWeapon == currWeps[slotIdx])
		{
			// They ordered to pickup a weapon with the "use" order and we already picked that weapon up. No need to look for other weapons
		}
		else
		{
			if (useWeapon != 0)
				WeaponsToSearch[useWeapon] <- 0; // Always add the "use" weapon, if any
			
			if (L4B.TeamShotguns <= L4B.Settings.team_min_shotguns && (hasT1Shotgun || hasT2Shotgun))
			{
				// We have a shotgun but TeamShotguns <= team_min_shotguns so we need to make sure to keep it. Just upgrade it if needed

				if (!hasT2Shotgun)
				{
					WeaponsToSearch[Left4Utils.WeaponId.weapon_autoshotgun] <- 0;
					WeaponsToSearch[Left4Utils.WeaponId.weapon_shotgun_spas] <- 0;
				}
			}
			else
			{
				// We either don't have a shotgun or TeamShotguns > team_min_shotguns so we can follow our preference and try to get an higher priority weapon

				for (local x = 0; x < WeapPref[slotIdx].len(); x++)
				{
					// Add all the preference weapons that have higher priority than the one we have in the inventory
					// Or add them all if ammo percent of our primary weapon is < pickups_wep_replace_ammo
					local prefId = WeapPref[slotIdx][x];
					if (prefId != currWeps[slotIdx] || priAmmoPercent < L4B.Settings.pickups_wep_replace_ammo)
						WeaponsToSearch[prefId] <- 0;
					else
						break;
				}

				// But if TeamShotguns < team_min_shotguns we must also make sure to try to get a shotgun as we currently don't have one
				if (L4B.TeamShotguns < L4B.Settings.team_min_shotguns)
				{
					WeaponsToSearch[Left4Utils.WeaponId.weapon_autoshotgun] <- 0;
					WeaponsToSearch[Left4Utils.WeaponId.weapon_shotgun_spas] <- 0;
					WeaponsToSearch[Left4Utils.WeaponId.weapon_pumpshotgun] <- 0;
					WeaponsToSearch[Left4Utils.WeaponId.weapon_shotgun_chrome] <- 0;
				}

				// If ammo percent < 95 and no laser/ammo upgrade, add the current weapon too so we can get one with full ammo
				// ???
				//if (currWeps[slotIdx] > Left4Utils.WeaponId.none && priAmmoPercent < 95 && !hasLaserSight && !hasAmmoUpgrade)
				//	WeaponsToSearch[currWeps[slotIdx]] <- 0;
			}
		}

		// If ammo percent < 95 and no laser/ammo upgrade, add the current weapon too so we can get one with full ammo
		if (currWeps[slotIdx] > Left4Utils.WeaponId.none && priAmmoPercent < 95 && !hasLaserSight && !hasAmmoUpgrade)
			WeaponsToSearch[currWeps[slotIdx]] <- 0;

		// SECONDARY
		slotIdx = 1;
		useWeapon = (slotIdx in UseWeapons) ? UseWeapons[slotIdx] : 0;
		if (useWeapon != 0 && useWeapon == currWeps[slotIdx])
		{
			// They ordered to pickup a weapon with the "use" order and we already picked that weapon up. No need to look for other weapons
		}
		else
		{
			if (useWeapon != 0)
				WeaponsToSearch[useWeapon] <- 0; // Always add the "use" weapon, if any
			
			for (local x = 0; x < WeapPref[slotIdx].len(); x++)
			{
				local prefId = WeapPref[slotIdx][x];
				if (hasChainsaw && L4B.TeamChainsaws > L4B.Settings.team_max_chainsaws)
				{
					// Try to get rid of chainsaw by replacing with anything else
					if (prefId != Left4Utils.WeaponId.weapon_chainsaw)
					{
						if (prefId > Left4Utils.MeleeWeaponId.none && L4B.TeamMelee >= L4B.Settings.team_max_melee)
						{
							// But always take care of the team_max_chainsaws / team_max_melee limits
						}
						else
							WeaponsToSearch[prefId] <- 0;
					}
				}
				else if (hasMelee && L4B.TeamMelee > L4B.Settings.team_max_melee)
				{
					// Try to get rid of melee by replacing with any non melee secondary
					if (prefId < Left4Utils.MeleeWeaponId.none)
					{
						if (prefId == Left4Utils.WeaponId.weapon_chainsaw && L4B.TeamChainsaws >= L4B.Settings.team_max_chainsaws)
						{
							// But always take care of the team_max_chainsaws / team_max_melee limits
						}
						else
							WeaponsToSearch[prefId] <- 0;
					}
				}
				else
				{
					// Add all the preference weapons that have higher priority than the one we have in the inventory
					if (prefId != currWeps[slotIdx])
					{
						if ((prefId == Left4Utils.WeaponId.weapon_chainsaw && L4B.TeamChainsaws >= L4B.Settings.team_max_chainsaws) || (prefId > Left4Utils.MeleeWeaponId.none && L4B.TeamMelee >= L4B.Settings.team_max_melee && !hasMelee))
						{
							// Take care of the team_max_chainsaws / team_max_melee limits
						}
						else if (currWeps[0] == Left4Utils.WeaponId.none && prefId > Left4Utils.MeleeWeaponId.none && !L4B.Settings.pickups_melee_noprimary)
						{
							// Don't pickup melee weapons if we don't have a primary weapon and pickups_melee_noprimary is 0
						}
						else
							WeaponsToSearch[prefId] <- 0;
					}
					else
						break;
				}
			}
		}

		// Handle Dual Pistols
		if (hasPistol && !hasDualPistol)
		{
			// We have a pistol, it's not dual, we likely aren't searching another one due to how priorities work... so add it again to get a dual
			WeaponsToSearch[Left4Utils.WeaponId.weapon_pistol] <- 0;
		}
	}

	// THROWABLES
	slotIdx = 2;
	useWeapon = (slotIdx in UseWeapons) ? UseWeapons[slotIdx] : 0;
	if (useWeapon != 0 && useWeapon == currWeps[slotIdx])
	{
		// They ordered to pickup a weapon with the "use" order and we already picked that weapon up. No need to look for other weapons
	}
	else
	{
		if (useWeapon != 0)
			WeaponsToSearch[useWeapon] <- 0; // Always add the "use" weapon, if any
		
		for (local x = 0; x < WeapPref[slotIdx].len(); x++)
		{
			// Just take note of the requested higher priority items, we'll build the search list later
			local prefId = WeapPref[slotIdx][x];
			if (prefId != currWeps[slotIdx])
			{
				if (prefId == Left4Utils.WeaponId.weapon_molotov)
					wantsMolotov = true;
				else if (prefId == Left4Utils.WeaponId.weapon_pipe_bomb)
					wantsPipeBomb = true;
				else if (prefId == Left4Utils.WeaponId.weapon_vomitjar)
					wantsVomitJar = true;
			}
			else
				break;
		}
		
		// TODO: This IF nesting is ugly af. I'm sure there is a better way to write this
		if (!hasMolotov && !hasPipeBomb && !hasVomitJar)
		{
			// If the slot is empty we'll pick up anything that is in our assigned priority list
			if (wantsMolotov)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_molotov] <- 0;

			if (wantsPipeBomb)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_pipe_bomb] <- 0;

			if (wantsVomitJar)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_vomitjar] <- 0;
		}
		else
		{
			// Otherwise...
			if (L4B.TeamMolotovs < L4B.Settings.team_min_molotovs)
			{
				// If there are not enough team molotovs, we'll go for the molotov
				if (!hasMolotov)
					WeaponsToSearch[Left4Utils.WeaponId.weapon_molotov] <- 0;
			}
			else
			{
				// Otherwise...
				if (L4B.TeamMolotovs == L4B.Settings.team_min_molotovs && hasMolotov)
				{
					// Do nothing or TeamMolotovs will drop below team_min_molotovs
				}
				else
				{
					if (L4B.TeamPipeBombs < L4B.Settings.team_min_pipebombs)
					{
						// If there are not enough team pipe bombs, we'll go for the pipe bomb
						if (!hasPipeBomb)
							WeaponsToSearch[Left4Utils.WeaponId.weapon_pipe_bomb] <- 0;
					}
					else
					{
						// Otherwise...
						if (L4B.TeamPipeBombs == L4B.Settings.team_min_pipebombs && hasPipeBomb)
						{
							// Do nothing or TeamPipeBombs will drop below team_min_pipebombs
						}
						else
						{
							if (L4B.TeamVomitJars < L4B.Settings.team_min_vomitjars)
							{
								// If there are not enough team vomit jars, we'll go for the vomit jar
								if (!hasVomitJar)
									WeaponsToSearch[Left4Utils.WeaponId.weapon_vomitjar] <- 0;
							}
							else
							{
								if (L4B.TeamVomitJars == L4B.Settings.team_min_vomitjars && hasVomitJar)
								{
									// Do nothing or TeamVomitJars will drop below team_min_vomitjars
								}
								else
								{
									// Otherwise we'll just follow our assigned priority list
									if (wantsMolotov && !hasMolotov)
										WeaponsToSearch[Left4Utils.WeaponId.weapon_molotov] <- 0;

									if (wantsPipeBomb && !hasPipeBomb)
										WeaponsToSearch[Left4Utils.WeaponId.weapon_pipe_bomb] <- 0;

									if (wantsVomitJar && !hasVomitJar)
										WeaponsToSearch[Left4Utils.WeaponId.weapon_vomitjar] <- 0;
								}
							}
						}
					}
				}
			}
		}
	}

	// MEDKIT
	slotIdx = 3;
	useWeapon = (slotIdx in UseWeapons) ? UseWeapons[slotIdx] : 0;
	if (useWeapon != 0 && useWeapon == currWeps[slotIdx])
	{
		// They ordered to pickup a weapon with the "use" order and we already picked that weapon up. No need to look for other weapons
	}
	else
	{
		if (useWeapon != 0)
			WeaponsToSearch[useWeapon] <- 0; // Always add the "use" weapon, if any
		
		for (local x = 0; x < WeapPref[slotIdx].len(); x++)
		{
			// Just take note of the requested higher priority items, we'll build the search list later
			local prefId = WeapPref[slotIdx][x];
			if (prefId != currWeps[slotIdx])
			{
				if (prefId == Left4Utils.WeaponId.weapon_first_aid_kit)
					wantsMedkit = true;
				else if (prefId == Left4Utils.WeaponId.weapon_defibrillator)
					wantsDefib = true;
				else if (prefId == Left4Utils.WeaponId.weapon_upgradepack_incendiary)
					wantsUpgdInc = true;
				else if (prefId == Left4Utils.WeaponId.weapon_upgradepack_explosive)
					wantsUpgdExp = true;
			}
			else
				break;
		}
		
		if (!hasMedkit && !hasDefib && !hasUpgdInc && !hasUpgdExp)
		{
			// If the slot is empty we'll pick up anything that is in our assigned priority list
			if (wantsMedkit)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_first_aid_kit] <- 0;

			if (wantsDefib)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_defibrillator] <- 0;

			if (wantsUpgdInc)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_upgradepack_incendiary] <- 0;

			if (wantsUpgdExp)
				WeaponsToSearch[Left4Utils.WeaponId.weapon_upgradepack_explosive] <- 0;
		}
		else
		{
			// Otherwise...
			if (L4B.HasDeathModelWithin(Origin, L4B.Settings.deads_scan_radius))
			{
				// If there is a dead survivor to defib, our top priority is the defibrillator
				if (!hasDefib)
					WeaponsToSearch[Left4Utils.WeaponId.weapon_defibrillator] <- 0; // Search one if we don't have it
			}
			else
			{
				// Otherwise...
				if (L4B.TeamMedkits < L4B.Settings.team_min_medkits || (self.GetHealth() + self.GetHealthBuffer()) < 30)
				{
					// If we need to heal or there are not enough team medkits, we'll go for the medkit
					if (!hasMedkit)
						WeaponsToSearch[Left4Utils.WeaponId.weapon_first_aid_kit] <- 0;
				}
				else
				{
					// Otherwise...
					if (L4B.TeamMedkits == L4B.Settings.team_min_medkits && hasMedkit)
					{
						// Do nothing or TeamMedkits will drop below team_min_medkits
					}
					else
					{
						if (L4B.TeamDefibs < L4B.Settings.team_min_defibs)
						{
							// If there are not enough team defibrillators, we'll go for the defibrillator
							if (!hasDefib)
								WeaponsToSearch[Left4Utils.WeaponId.weapon_defibrillator] <- 0;
						}
						else
						{
							if (L4B.TeamDefibs == L4B.Settings.team_min_defibs && hasDefib)
							{
								// Do nothing or TeamDefibs will drop below team_min_defibs
							}
							else
							{
								// Otherwise we'll just follow our assigned priority list
								if (wantsMedkit && !hasMedkit)
									WeaponsToSearch[Left4Utils.WeaponId.weapon_first_aid_kit] <- 0;

								if (wantsDefib && !hasDefib)
									WeaponsToSearch[Left4Utils.WeaponId.weapon_defibrillator] <- 0;

								if (wantsUpgdInc && !hasUpgdInc)
									WeaponsToSearch[Left4Utils.WeaponId.weapon_upgradepack_incendiary] <- 0;

								if (wantsUpgdExp && !hasUpgdExp)
									WeaponsToSearch[Left4Utils.WeaponId.weapon_upgradepack_explosive] <- 0;
							}
						}
					}
				}
			}
		}
	}

	// PILLS
	slotIdx = 4;
	useWeapon = (slotIdx in UseWeapons) ? UseWeapons[slotIdx] : 0;
	if (useWeapon != 0 && useWeapon == currWeps[slotIdx])
	{
		// They ordered to pickup a weapon with the "use" order and we already picked that weapon up. No need to look for other weapons
	}
	else
	{
		if (useWeapon != 0)
			WeaponsToSearch[useWeapon] <- 0; // Always add the "use" weapon, if any
		
		for (local x = 0; x < WeapPref[slotIdx].len(); x++)
		{
			// Add all the preference weapons that have higher priority than the one we have in the inventory
			local prefId = WeapPref[slotIdx][x];
			if (prefId != currWeps[slotIdx])
				WeaponsToSearch[prefId] <- 0;
			else
				break;
		}
	}

	// Handle Ammo
	if (priAmmoPercent < L4B.Settings.pickups_wep_ammo_replenish)
		WeaponsToSearch[Left4Utils.WeaponId.weapon_ammo] <- 0;

	// Handle Upgrades
	if (!hasAmmoUpgrade)
	{
		UpgradesToSearch[Left4Utils.UpgradeWeaponId.upgrade_ammo_explosive] <- 0;
		UpgradesToSearch[Left4Utils.UpgradeWeaponId.upgrade_ammo_incendiary] <- 0;
	}
	if (!hasLaserSight)
		UpgradesToSearch[Left4Utils.UpgradeWeaponId.upgrade_laser_sight] <- 0;

	//L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - WeaponsToSearch: " + WeaponsToSearch.len() + " - UpgradesToSearch: " + UpgradesToSearch.len());
}

// Returns the bot's closest item to pick up within the given radius
::Left4Bots.AIFuncs.BotGetNearestPickupWithin <- function (radius = 200)
{
	local ret = null;
	local ent = null;
	local orig = self.GetCenter();
	local minDist = 1000000;
	local priWeaponId = Left4Utils.WeaponId.none;
	local priAmmoPercent = 100;
	local pri = Left4Utils.GetInventoryItemInSlot(self, INV_SLOT_PRIMARY);
	if (pri)
	{
		priWeaponId = Left4Utils.GetWeaponId(pri);
		priAmmoPercent = Left4Utils.GetAmmoPercent(pri);
	}

	if (WeaponsToSearch.len() > 0)
	{
		while (ent = Entities.FindByClassnameWithin(ent, "weapon_*", orig, radius)) // TODO: SLOW! We should find another way to do this
		{
			local entIndex = ent.GetEntityIndex();
			local weaponId = Left4Utils.GetWeaponId(ent);
			if ((weaponId in WeaponsToSearch) && entIndex != L4B.GiveItemIndex1 && entIndex != L4B.GiveItemIndex2 && L4B.IsValidPickup(ent))
			{
				// If we are moving to defib a dead survivor and we have a defibrillator in our inventory, ignore the medkit or we'll loop replacing our defibrillator with the medkit over and over again
				if (MoveType != AI_MOVE_TYPE.Defib || weaponId != Left4Utils.WeaponId.weapon_first_aid_kit || !Left4Utils.HasDefib(self))
				{
					local dist = (orig - ent.GetCenter()).Length();
					if (dist < minDist && L4B.CanTraceToPickup(self, ent))
					{
						if (Left4Utils.GetWeaponSlotById(weaponId) == 0)
						{
							// Primary

							// If we are going to pick-up the same weapon, make sure it has more ammo than the current one
							local ammoPercent = Left4Utils.GetAmmoPercent(ent);
							if ((weaponId != priWeaponId && ammoPercent >= L4B.Settings.pickups_wep_min_ammo) || (weaponId == priWeaponId && ammoPercent > priAmmoPercent))
							{
								// Any other
								ret = ent;
								minDist = dist;
							}
						}
						else
						{
							// Any other

							ret = ent;
							minDist = dist;
						}
					}
				}
			}
		}
	}

	if (UpgradesToSearch.len() > 0)
	{
		ent = null;
		while (ent = Entities.FindByClassnameWithin(ent, "upgrade_*", orig, radius)) // TODO: SLOW! We should find another way to do this
		{
			local weaponId = Left4Utils.GetWeaponId(ent);
			if ((weaponId in UpgradesToSearch) && (NetProps.GetPropInt(ent, "m_iUsedBySurvivorsMask") & (1 << CharId)) == 0)
			{
				local dist = (orig - ent.GetCenter()).Length();
				if (dist < minDist && L4B.CanTraceToPickup(self, ent))
				{
					ret = ent;
					minDist = dist;
				}
			}
		}
	}

	return ret;
}

// Called to initialize the current order when the order starts or its MOVE resumes after an higher priority MOVE
::Left4Bots.AIFuncs.BotInitializeCurrentOrder <- function ()
{
	// Whatever the previous MovePos was, our order has higher priority, so let's start moving...
	MoveType = AI_MOVE_TYPE.Order;

	if (CurrentOrder.OrderType == "lead")
	{
		// If we are coming back to leading after an higher priority move we need to check if we already moved ahead on the flow, so let's force the BotFinalizeCurrentOrder
		BotFinalizeCurrentOrder();
	}
	else if (CurrentOrder.OrderType == "heal")
	{
		// But do we have a medkit?
		if (!Left4Utils.HasMedkit(self))
		{
			// Nope, nothing to do then
			//L4B.Logger.Warning("[AI]" + self.GetPlayerName() + " can't execute 'heal' order; no medkit in inventory");

			BotFinalizeCurrentOrder();
			return;
		}

		self.SwitchToItem("weapon_first_aid_kit");

		if (CurrentOrder.DestEnt.GetPlayerUserId() == self.GetPlayerUserId())
		{
			// We have to heal ourselves, we don't really need to move
			MovePos = Origin; // Set this or BotThink_Orders will call BotInitializeCurrentOrder again

			BotFinalizeCurrentOrder();
		}
		else
			BotMoveTo(CurrentOrder.DestEnt.GetOrigin(), true);
	}
	else
	{
		// If the order has a DestPos, we'll move there, otherwise we'll move to DestEnt's origin
		// If both DestPos and DestEnt are null we call the current order finalization
		if (CurrentOrder.DestPos)
		{
			if (L4B.Settings.moveto_nav && (CurrentOrder.OrderType == "scavenge" || CurrentOrder.OrderType == "carry"))
				BotMoveToNav(CurrentOrder.DestPos, true);
			else
				BotMoveTo(CurrentOrder.DestPos, true);
		}
		else if (CurrentOrder.DestEnt)
		{
			if (L4B.Settings.moveto_nav && (CurrentOrder.OrderType == "scavenge" || CurrentOrder.OrderType == "carry"))
				BotMoveToNav(CurrentOrder.DestEnt.GetOrigin(), true);
			else
				BotMoveTo(CurrentOrder.DestEnt.GetOrigin(), true);
		}
		else
			BotFinalizeCurrentOrder();
	}
}

// Called to finalize the current order after the order's destination has been reached (or there was no destination at all)
// Makes the bot (self) do whatever he has to do in order to complete the current order
::Left4Bots.AIFuncs.BotFinalizeCurrentOrder <- function ()
{
	if (!CurrentOrder)
	{
		L4B.Logger.Error("[AI]" + self.GetPlayerName() + " - Finalizing current order without a current order!");

		NeedMove = 0;
		MovePos = null;
		MovePosReal = null;
		MoveType = AI_MOVE_TYPE.None;
		return;
	}

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Finalizing order: " + L4B.BotOrderToString(CurrentOrder));

	local orderComplete = true;
	switch (CurrentOrder.OrderType)
	{
		case "lead":
		{
			local nextPos = Left4Utils.GetFarthestPathableFlowPos(self, L4B.Settings.lead_max_segment, L4B.Settings.lead_dontstop_ondamaging, L4B.Settings.lead_detour_maxdist, L4B.Settings.lead_check_ground, L4B.Settings.lead_debug_duration);
			if (nextPos)
			{
				if ((nextPos - Origin).Length() >= L4B.Settings.lead_min_segment)
				{
					if (!CurrentOrder.DestPos)
					{
						// This was a Start lead order from a player (CurrentOrder.From contains the entity of the player)
						if (CurrentOrder.From && CurrentOrder.From.IsValid())
							L4B.Logger.Info("[AI]" + self.GetPlayerName() + " started leading; order from: " + CurrentOrder.From.GetPlayerName());
						else
							L4B.Logger.Warning("[AI]" + self.GetPlayerName() + " started leading; order from: ?");

						if ((CurTime - L4B.LastLeadStartVocalize) >= L4B.Settings.lead_vocalize_interval)
						{
							L4B.SpeakRandomVocalize(self, L4B.VocalizerLeadStart, RandomFloat(0.4, 0.9));
							L4B.LastLeadStartVocalize = CurTime;
						}
					}

					// Self add another "lead" order but with the next position as DestPos so we can start/continue travel
					///L4B.BotOrderAppend(self, "lead", null, null, nextPos);
					/// Avoid the ^slow GetScriptScope(), if possible
					//local order = { OrderType = "lead", From = null, DestEnt = null, DestPos = nextPos, DestLookAtPos = null, CanPause = true, DestRadius = L4B.Settings.move_end_radius_lead, MaxSeparation = L4B.Settings.lead_max_separation };
					//Orders.append(order);
					//L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Appended order (queue pos. " + Orders.len() + "): " + L4B.BotOrderToString(order));
					orderComplete = false; // This way is better

					// Update CurrentOrder.DestPos with the next segment's end
					CurrentOrder.DestPos = nextPos;
					L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - CurrentOrder.DestPos updated: " + CurrentOrder.DestPos);

					// Is this the lead's first or a resume MOVE?
					if (!MovePos)
						BotMoveTo(CurrentOrder.DestPos, true); // Yes. We need to start the move here or BotThink_Orders will call BotFinalizeCurrentOrder resulting in an infinite loop
				}
				else
				{
					// Travel is done
					if (!CurrentOrder.DestPos)
					{
						// This was a Start lead order from a player, so the travel didn't even start
						L4B.Logger.Warning("[AI]" + self.GetPlayerName() + " can't start leading; goal already reached");

						L4B.SpeakRandomVocalize(self, L4B.VocalizerLeadStop, RandomFloat(0.5, 1.0));
					}
					else
					{
						// It was a continuation of the travel, so it's a legit end of the travel
						L4B.Logger.Info("[AI]" + self.GetPlayerName() + " stopped leading; goal reached");

						L4B.SpeakRandomVocalize(self, L4B.VocalizerLeadStop, RandomFloat(0, 0.5));
					}
				}
			}
			else
			{
				// Not supposed to happen but we'll just end the travel here
				if (!CurrentOrder.DestPos)
				{
					// This was a Start lead order from a player, so the travel didn't even start
					L4B.Logger.Error("[AI]" + self.GetPlayerName() + " can't start leading; nextPos is null!");

					DoEntFire("!self", "SpeakResponseConcept", "PlayerNo", RandomFloat(0.5, 1.0), null, self);
				}
				else
				{
					// It was a continuation of the travel, so it's an "abnormal" end of the travel
					L4B.Logger.Error("[AI]" + self.GetPlayerName() + " stopped leading; nextPos is null!");

					L4B.SpeakRandomVocalize(self, L4B.VocalizerLeadStop, RandomFloat(0, 0.5));
				}
			}
			break;
		}
		case "witch":
		{
			if (CurrentOrder.DestEnt && CurrentOrder.DestEnt.IsValid() && ("LookupAttachment" in CurrentOrder.DestEnt))
			{
				local attachId = CurrentOrder.DestEnt.LookupAttachment("forward");

				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Found witch 'forward' attachment id: " + attachId);

				// Shoot 3 bullets to her head as quick as possible (if using slow weapons like pump shotguns the bullets will be 2 but usually 1 is enough)
				NetProps.SetPropInt(self, "m_fFlags", NetProps.GetPropInt(self, "m_fFlags") | (1 << 5)); // set FL_FROZEN for the entire duration of the 3 shoots
				Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Bots.BotShootAtEntityAttachment.bindenv(::Left4Bots)(params.bot, params.entity, params.attachmentid ), { bot = self, entity = CurrentOrder.DestEnt, attachmentid = attachId });
				Left4Timers.AddTimer(null, 0.5, @(params) ::Left4Bots.BotShootAtEntityAttachment.bindenv(::Left4Bots)(params.bot, params.entity, params.attachmentid ), { bot = self, entity = CurrentOrder.DestEnt, attachmentid = attachId });
				Left4Timers.AddTimer(null, 0.9, @(params) ::Left4Bots.BotShootAtEntityAttachment.bindenv(::Left4Bots)(params.bot, params.entity, params.attachmentid, true ), { bot = self, entity = CurrentOrder.DestEnt, attachmentid = attachId }); // this will unset FL_FROZEN at the end
			}
			else
				L4B.Logger.Error("[AI]" + self.GetPlayerName() + " - Witch has no LookupAttachment!");

			break;
		}
		case "use":
		{
			L4B.Logger.Info("[AI]" + self.GetPlayerName() + " is using " + CurrentOrder.DestEnt);

			Left4Utils.PlayerPressButton(self, BUTTON_USE,  CurrentOrder.HoldTime, CurrentOrder.DestEnt.GetCenter(), 0, 0, true);

			break;
		}
		case "carry":
		{
			L4B.Logger.Info("[AI]" + self.GetPlayerName() + " is carrying " + CurrentOrder.DestEnt);

			Left4Timers.AddTimer(null, L4B.Settings.pickups_failsafe_delay, @(params) ::Left4Bots.PickupFailsafe.bindenv(::Left4Bots)(params.bot, params.item), { bot = self, item = CurrentOrder.DestEnt });
			Left4Utils.PlayerPressButton(self, BUTTON_USE,  CurrentOrder.HoldTime, CurrentOrder.DestEnt.GetCenter(), 0, 0, true);

			// Do not complete the order if we need to carry this item
			orderComplete = !CurrentOrder.Param1 || Left4Utils.GetWeaponSlotById(CurrentOrder.Param1) != 5;

			break;
		}
		case "scavenge":
		{
			if (CurrentOrder.DestPos)
			{
				if (L4B.Settings.scavenge_pour)
				{
					// Pour
					if (NetProps.GetPropInt(L4B.ScavengeUseTarget, "m_useActionOwner") > 0)
					{
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " can't pour; pour target is busy. Pausing...");
						BotPause();
					}
					else
					{
						L4B.CarryItemStop(self);
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " is pouring");
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, L4B.Settings.button_holdtime_pour, L4B.ScavengeUseTarget, 0, 0, true);
					}
				}
				else
				{
					// Drop it
					L4B.CarryItemStop(self);
					L4B.DropCarryItem(self);
				}
			}
			else
			{
				L4B.Logger.Info("[AI]" + self.GetPlayerName() + " is carrying " + CurrentOrder.DestEnt);

				Left4Timers.AddTimer(null, L4B.Settings.pickups_failsafe_delay, @(params) ::Left4Bots.PickupFailsafe.bindenv(::Left4Bots)(params.bot, params.item), { bot = self, item = CurrentOrder.DestEnt });
				Left4Utils.PlayerPressButton(self, BUTTON_USE,  CurrentOrder.HoldTime, CurrentOrder.DestEnt.GetCenter(), 0, 0, true);

				CurrentOrder.DestPos = L4B.ScavengeUseTargetPos;
				if (L4B.Settings.scavenge_pour)
					CurrentOrder.DestRadius <- L4B.Settings.move_end_radius_pour;
				else
					CurrentOrder.DestRadius <- L4B.Settings.scavenge_drop_radius - 20;

				BotMoveTo(CurrentOrder.DestPos, true);

				// Do not complete the order, we need to carry this item to the pour target
				orderComplete = false;
			}			

			break;
		}
		case "deploy":
		{
			L4B.Logger.Info("[AI]" + self.GetPlayerName() + " is deploying " + CurrentOrder.DestEnt);

			// Disable the AI stuff for a while so the bot doesn't switch back to medkit before finishing the deploy
			HurryUntil = Left4Utils.Max(HurryUntil, CurTime + 5);

			Left4Utils.PlayerPressButton(self, BUTTON_USE,  CurrentOrder.HoldTime, CurrentOrder.DestEnt.GetCenter(), 0, 0, true);

			Left4Timers.AddTimer(null, 1, @(params) params.bot.SwitchToItem(params.cls), { bot = self, cls = Left4Utils.StringReplace(CurrentOrder.DestEnt.GetClassname(), "_spawn", "") });

			Left4Timers.AddTimer(null, 2, @(params) ::Left4Bots.DoDeployUpgrade.bindenv(::Left4Bots)(params.bot), { bot = self });

			break;
		}
		case "heal":
		{
			if (Left4Utils.HasMedkit(self))
			{
				if (ActiveWeapon && ActiveWeapon.GetClassname() == "weapon_first_aid_kit")
				{
					// Are we ready to use the medkit?
					if (CurTime > NetProps.GetPropFloat(ActiveWeapon, "m_flNextPrimaryAttack") + 0.1) // <- Add a little delay or the animation will be bugged
					{
						// Yes
						L4B.Logger.Info("[AI]" + self.GetPlayerName() + " is healing " + CurrentOrder.DestEnt.GetPlayerName());

						if (CurrentOrder.DestEnt.GetPlayerUserId() == self.GetPlayerUserId())
							Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, CurrentOrder.HoldTime, null, 0, 0, true); // <- NOTE: Vanilla AI will likely interrupt the healing if lockLook is false
						else
						{
							Left4Utils.PlayerPressButton(self, BUTTON_SHOVE,  CurrentOrder.HoldTime, CurrentOrder.DestEnt.GetCenter(), 0, 0, true);

							// This will check if the healing started and the healing target is the right target. If not, it will abort the healing and the current order and will re-add the order to try again
							Left4Timers.AddTimer(null, 0.8, @(params) ::Left4Bots.CheckHealingTarget.bindenv(::Left4Bots)(params.bot, params.order), { bot = self, order = CurrentOrder });
						}
					}
					else
						orderComplete = false; // must wait
				}
				else
				{
					orderComplete = false; // must wait
					self.SwitchToItem("weapon_first_aid_kit");
				}
			}
			else
				L4B.Logger.Warning("[AI]" + self.GetPlayerName() + " can't execute 'heal' order; no medkit in inventory");

			break;
		}
		case "goto":
		{
			L4B.SpeakRandomVocalize(self, L4B.VocalizerGotoStop, RandomFloat(0.1, 0.6));

			break;
		}
		case "follow":
		{
			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Followed ent is in range");

			// Start the Pause if needed
			BotPause();
			orderComplete = false;

			break;
		}
		case "wait":
		{
			// https://github.com/smilz0/Left4Bots/issues/2
			/* Thre is a better way to do this with m_hGroundEntity
			local area = self.GetLastKnownArea(); // Get the area currently occupied by the bot
			if (area && area.GetElevator())
			*/
			local gEnt = NetProps.GetPropEntity(self, "m_hGroundEntity");
			if (gEnt && gEnt.IsValid() && gEnt.GetClassname() == "func_elevator")
			{
				// Cancel the current wait order if its wait location is in an elevator
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling wait order with wait position in elevator");

				BotCancelCurrentOrder(); // This is actually needed. orderComplete = true does not reset the MOVE
			}
			else
			{
				if (MovePos && !Waiting)
				{
					L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Wait position is in range");

					// Give control back to the vanilla AI
					BotReset();

					// But don't let it move
					NetProps.SetPropInt(self, "movetype", 0);

					self.SetVelocity(Vector(0, 0, 0)); // This will reset the bot's animation from running to idle

					if (L4B.Settings.wait_crouch)
						NetProps.SetPropInt(self, "m_afButtonForced", NetProps.GetPropInt(self, "m_afButtonForced") | BUTTON_DUCK);

					Waiting = true;
				}

				orderComplete = false;
			}

			break;
		}
		case "destroy":
		{
			if (CurrentOrder.DestEnt && CurrentOrder.DestEnt.IsValid())
			{
				if (ActiveWeapon && L4B.IsRangedWeapon(ActiveWeaponId, ActiveWeaponSlot) && ActiveWeapon.Clip1() > 0 && !NetProps.GetPropInt(ActiveWeapon, "m_bInReload"))
				{
					// Shoot 3 bullets to the gascans as quick as possible (if using slow weapons like pump shotguns the bullets will be 2 but usually 1 is enough)
					NetProps.SetPropInt(self, "m_fFlags", NetProps.GetPropInt(self, "m_fFlags") | (1 << 5)); // set FL_FROZEN for the entire duration of the 3 shoots
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Bots.BotShootAtEntity.bindenv(::Left4Bots)(params.bot, params.entity ), { bot = self, entity = CurrentOrder.DestEnt });
					Left4Timers.AddTimer(null, 0.5, @(params) ::Left4Bots.BotShootAtEntity.bindenv(::Left4Bots)(params.bot, params.entity ), { bot = self, entity = CurrentOrder.DestEnt });
					Left4Timers.AddTimer(null, 0.9, @(params) ::Left4Bots.BotShootAtEntity.bindenv(::Left4Bots)(params.bot, params.entity, true ), { bot = self, entity = CurrentOrder.DestEnt }); // this will unset FL_FROZEN at the end
				}
			}
			else
				L4B.Logger.Error("[AI]" + self.GetPlayerName() + " - DestEnt no longer valid!");

			orderComplete = false; // Assume we failed to ignite the gascans and we need to retry. Actual ignite success will be handled by the "PropExplosion" concept (or CurrentOrder.DestEnt no longer valid)

			break;
		}
		default:
		{
			// Do nothing
		}
	}

	if (orderComplete)
	{
		NeedMove = 0;
		MovePos = null;
		MovePosReal = null;
		MoveType = AI_MOVE_TYPE.None;
		CurrentOrder = null; // Order is done

		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - CurrentOrder done. " + Orders.len() + " order(s) in queue.");
	}
	else
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - CurrentOrder not done yet");
}

// Returns all the orders (current and queued) matching the given parameters
::Left4Bots.AIFuncs.BotGetOrders <- function (orderType = null, destEnt = null, param1 = null)
{
	local ret = {};
	local idx = 0;

	if (CurrentOrder && (!orderType || CurrentOrder.OrderType == orderType) && (!destEnt || CurrentOrder.DestEnt == destEnt) && (!param1 || CurrentOrder.Param1 == param1))
		ret[idx++] <- CurrentOrder;

	for (local i = 0; i < Orders.len(); i++)
	{
		if ((!orderType || Orders[i].OrderType == orderType) && (!destEnt || Orders[i].DestEnt == destEnt) && (!param1 || Orders[i].Param1 == param1))
			ret[idx++] <- Orders[i];
	}
	
	return ret;
}

// Cancel the current order (does not affect the orders in the queue)
::Left4Bots.AIFuncs.BotCancelCurrentOrder <- function ()
{
	if (!CurrentOrder)
		return;

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling order: " + L4B.BotOrderToString(CurrentOrder));

	if (MoveType == AI_MOVE_TYPE.Order)
		BotMoveReset();

	
	if (CurrentOrder.OrderType == "scavenge" || CurrentOrder.OrderType == "carry")
	{
		L4B.CarryItemStop(self);
		L4B.DropCarryItem(self);
	}

	CurrentOrder = null;
}

// Cancel the given order (it can be either the current or a queued one)
::Left4Bots.AIFuncs.BotCancelOrder <- function (order)
{
	if (!order)
		return;
	
	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling the order: " + L4B.BotOrderToString(order));

	for (local i = Orders.len() - 1; i >= 0; i--)
	{
		if (Orders[i] == order)
			Orders.remove(i);
	}
	if (CurrentOrder == order)
		BotCancelCurrentOrder();

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Orders still in queue: " + Orders.len());
}

// Cancel all the orders (current and queued) of type 'orderType'. if 'orderType' is null, all the bot's orders will be cancelled
::Left4Bots.AIFuncs.BotCancelOrders <- function (orderType = null)
{
	if (orderType)
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling all the orders of type: " + orderType);
	else
		L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling all the orders");

	if (orderType)
	{
		for (local i = Orders.len() - 1; i >= 0; i--)
		{
			if (Orders[i].OrderType == orderType)
				Orders.remove(i);
		}
		if (CurrentOrder && CurrentOrder.OrderType == orderType)
			BotCancelCurrentOrder();
	}
	else
	{
		Orders.clear();
		BotCancelCurrentOrder();
	}

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Orders still in queue: " + Orders.len());
}

// Cancel all the orders (current and queued) with a DestEnt of class 'destEntClass'
::Left4Bots.AIFuncs.BotCancelOrdersDestEnt <- function (destEntClass)
{
	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling all the orders with DestEnt of class: " + destEntClass);

	for (local i = Orders.len() - 1; i >= 0; i--)
	{
		if (Orders[i].DestEnt && Orders[i].DestEnt.GetClassname() == destEntClass)
			Orders.remove(i);
	}
	if (CurrentOrder && CurrentOrder.DestEnt && CurrentOrder.DestEnt.GetClassname() == destEntClass)
		BotCancelCurrentOrder();

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Orders still in queue: " + Orders.len());
}

// Cancel the current defib action
::Left4Bots.AIFuncs.BotCancelDefib <- function ()
{
	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling defib");

	// MOVE stuff
	if (MoveType == AI_MOVE_TYPE.Defib)
		BotMoveReset();
}

// Cancel everything (current/queued orders, current pickup, anything)
::Left4Bots.AIFuncs.BotCancelAll <- function ()
{
	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Cancelling everything");

	// Orders stuff
	BotCancelOrders();

	// MOVE stuff
	//if (MoveType != AI_MOVE_TYPE.None)
		BotMoveReset();

	// Door stuff
	DoorEnt = null;
	DoorZ = 0;
	DoorAct = AI_DOOR_ACTION.None;

	// Just in case...
	NetProps.SetPropInt(self, "m_fFlags", NetProps.GetPropInt(self, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN
	NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK)); // enable FIRE button
	NetProps.SetPropInt(self, "m_afButtonForced", 0); // clear forced buttons

	/*
	L4B.CarryItemStop(self);
	CarryItem = null;
	CarryItemWeaponId = 0;
	*/
}

// Check if the bot should pause what he is doing. Handles the Paused flag and the RESET command
// canStartPause tells whether the bot can start a pause or not. It has no effect on ending a previously started pause
// maxSeparation is the max distance from the other survivors (0 = no check)
// followEnt if not null it's the entity we need to follow
// if followEnt is not null, followRange is the maximum distance from followEnt before we need to move to follow again (we'll stay in Pause if within this range from followEnt)
// followEnt and followRange have no effect on the logics to start the pause, only for the stop. The pause will be started in BotThink_Orders when we're within DestRadius from our followEnt
// Returns true if the bot is in pause, false if not
::Left4Bots.AIFuncs.BotIsInPause <- function (canStartPause = true, isHealOrder = false, maxSeparation = 0, followEnt = null, followRange = 150)
{
	if (Paused == 0)
	{
		// Should we start the pause?
		if (canStartPause)
		{
			local r = L4B.BotShouldStartPause(self, UserId, Origin, SM_IsStuck, isHealOrder, maxSeparation);
			if (r)
				BotPause(r); // Yes, let's give control back to the vanilla AI
		}
	}
	else if (followEnt || (CurTime - Paused) >= L4B.Settings.pause_min_time) // Only stop the pause if at least pause_min_time seconds passed, or we are following someone
	{
		// Should we stop the pause?
		if ((!followEnt || (followEnt.GetOrigin() - Origin).Length() > followRange) && L4B.BotShouldStopPause(self, UserId, Origin, SM_IsStuck, isHealOrder, maxSeparation))
			BotUnPause(); // Yes, unpause and refresh the last MOVE if needed
	}

	return (Paused != 0);
}

// Starts a pause with the given 'reason'
::Left4Bots.AIFuncs.BotPause <- function (reason = true)
{
	if (Paused != 0)
		return;

	Paused = CurTime;
	BotOnPause(reason);
}

// Stops the current pause
::Left4Bots.AIFuncs.BotUnPause <- function ()
{
	if (Paused == 0)
		return;

	Paused = 0;
	BotOnResume();
}

// Called when the bot starts the pause
::Left4Bots.AIFuncs.BotOnPause <- function (reason = true)
{
	if (MovePos)
		BotReset();

	// Reset movetype if needed
	Waiting = false;
	if (NetProps.GetPropInt(self, "movetype") == 0)
		NetProps.SetPropInt(self, "movetype", 2);
	NetProps.SetPropInt(self, "m_afButtonForced", NetProps.GetPropInt(self, "m_afButtonForced") & (~BUTTON_DUCK));

	// reason is actually the return value of L4B.BotShouldStartPause (but cannot be false here)
	// - ent (entity of the special infected / tank / witch that is the reason to start the pause)
	// - 1 (common infected horde)
	// - true (any other reason)
	if (reason == true)
		reason = "other";
	else if (reason == 1)
	{
		reason = "horde";
		if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_horde_chance)
			DoEntFire("!self", "SpeakResponseConcept", "PlayerIncoming", RandomFloat(0, 0.8), null, self);
	}
	else
	{
		if (reason.GetClassname() == "witch")
		{
			if (L4B.Settings.witch_autocrown)
			{
				if (ActiveWeapon && ActiveWeapon.GetClassname().find("shotgun") != null)
					L4B.BotOrderAdd(self, "witch", null, reason, null, null, 0, false);
			}

			reason = "witch";
			if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_witch_chance)
				DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnWitch", RandomFloat(0, 0.8), null, self);
		}
		else
		{
			// player
			switch (reason.GetZombieType())
			{
				case Z_SMOKER:
				{
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Utils.BotCmdAttack(params.bot, params.target), { bot = self, target = reason });

					reason = "smoker";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_special_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnSmoker", RandomFloat(0, 0.8), null, self);

					break;
				}
				case Z_BOOMER:
				{
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Utils.BotCmdAttack(params.bot, params.target), { bot = self, target = reason });

					reason = "boomer";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_special_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnBoomer", RandomFloat(0, 0.8), null, self);

					break;
				}
				case Z_HUNTER:
				{
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Utils.BotCmdAttack(params.bot, params.target), { bot = self, target = reason });

					reason = "hunter";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_special_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnHunter", RandomFloat(0, 0.8), null, self);

					break;
				}
				case Z_SPITTER:
				{
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Utils.BotCmdAttack(params.bot, params.target), { bot = self, target = reason });

					reason = "spitter";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_special_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnSpitter", RandomFloat(0, 0.8), null, self);

					break;
				}
				case Z_JOCKEY:
				{
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Utils.BotCmdAttack(params.bot, params.target), { bot = self, target = reason });

					reason = "jockey";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_special_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnJockey", RandomFloat(0, 0.8), null, self);

					break;
				}
				case Z_CHARGER:
				{
					Left4Timers.AddTimer(null, 0.01, @(params) ::Left4Utils.BotCmdAttack(params.bot, params.target), { bot = self, target = reason });

					reason = "charger";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_special_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnCharger", RandomFloat(0, 0.8), null, self);

					break;
				}
				case Z_TANK:
				{
					reason = "tank";
					if (RandomInt(1, 100) <= L4B.Settings.vocalizer_onpause_tank_chance)
						DoEntFire("!self", "SpeakResponseConcept", "PlayerWarnTank", RandomFloat(0, 0.8), null, self);

					break;
				}
				default:
				{
					reason = "unknown";
				}
			}
		}
	}

	L4B.CarryItemStop(self);
	L4B.DropCarryItem(self);

	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " [P] (" + reason + ")");
	if (L4B.Settings.pause_debug)
		Say(self, "[P] (" + reason + ")", false);
}

// Called when the bot stops the pause
::Left4Bots.AIFuncs.BotOnResume <- function ()
{
	L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " [->]");
	if (L4B.Settings.pause_debug)
		Say(self, "[->]", false);

	if (MoveType == AI_MOVE_TYPE.Order && CurrentOrder.OrderType == "lead")
	{
		if (CurrentOrder.DestPos)
		{
			// If we are executing a "lead" order and, during the pause, we moved ahead of the next position, the last MOVE will take us backwards. Better finalize the order to re-calc the next position from here
			BotFinalizeCurrentOrder();
		}
		else if (MovePos)
			NeedMove = 2; // Refresh previous MOVE

		if ((CurTime - L4B.LastLeadStartVocalize) >= L4B.Settings.lead_vocalize_interval)
		{
			L4B.SpeakRandomVocalize(self, L4B.VocalizerLeadStart, RandomFloat(0.4, 0.9));
			L4B.LastLeadStartVocalize = CurTime;
		}
	}
	else if (MovePos)
		NeedMove = 2; // Refresh previous MOVE
}

//...
