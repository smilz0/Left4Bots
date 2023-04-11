//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

// TODO: Reset should reset pause?
// TODO: Cancel heal near saferoom

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
	bot.ValidateScriptScope();
	local scope = bot.GetScriptScope();
	
	scope.FuncI <- NetProps.GetPropInt(bot, "m_survivorCharacter") % 5; // <- this makes the bots start the sub-think functions in different order so they don't "Use" pickups or do things at the exact same time
	scope.UserId <- bot.GetPlayerUserId();
	scope.Origin <- bot.GetOrigin(); // This will be updated each tick by the BotThink_Main think function. It is meant to replace all the self.GetOrigin() used by the various funcs
	scope.MoveEnt <- null;
	scope.MovePos <- null;
	scope.MoveType <- AI_MOVE_TYPE.None;
	scope.NeedMove <- 0;
	scope.CanReset <- true;
	scope.DelayedReset <- false;
	scope.Paused <- 0; // Paused = 0 = not in pause. Paused > 0 (Time() of when the pause started) = in pause
	scope.PickupsToSearch <- {};
	scope.CurrentOrder <- null;
	scope.Orders <- [];
	scope.ThrowType <- AI_THROW_TYPE.None;
	scope.ThrowTarget <- null;
	scope.ThrowStartedOn <- 0;
	scope.DoorEnt <- null; // Used for AI_MOVE_TYPE.Door
	scope.DoorZ <- 0; // Used for AI_MOVE_TYPE.Door
	scope.DoorAct <- AI_DOOR_ACTION.None; // Used for AI_MOVE_TYPE.Door
	
	/*
	scope.HoldItem <- null;
	scope.LastUseTS <- 0;
	*/
	
	scope["BotThink_Main"] <- ::Left4Bots.BotThink_Main;
	scope["BotThink_Pickup"] <- ::Left4Bots.BotThink_Pickup;
	scope["BotThink_Defib"] <- ::Left4Bots.BotThink_Defib;
	scope["BotThink_Throw"] <- ::Left4Bots.BotThink_Throw;
	scope["BotThink_Orders"] <- ::Left4Bots.BotThink_Orders;
	scope["BotThink_Door"] <- ::Left4Bots.BotThink_Door;
	scope["BotThink_Misc"] <- ::Left4Bots.BotThink_Misc;
	scope["BotManualAttack"] <- ::Left4Bots.BotManualAttack;
	scope["BotMoveTo"] <- ::Left4Bots.BotMoveTo;
	scope["BotReset"] <- ::Left4Bots.BotReset;
	scope["BotGetNearestPickupWithin"] <- ::Left4Bots.BotGetNearestPickupWithin;
	scope["BotInitializeCurrentOrder"] <- ::Left4Bots.BotInitializeCurrentOrder;
	scope["BotFinalizeCurrentOrder"] <- ::Left4Bots.BotFinalizeCurrentOrder;
	scope["BotCancelCurrentOrder"] <- ::Left4Bots.BotCancelCurrentOrder;
	scope["BotCancelOrders"] <- ::Left4Bots.BotCancelOrders;
	scope["BotCancelAll"] <- ::Left4Bots.BotCancelAll;
	scope["BotIsInPause"] <- ::Left4Bots.BotIsInPause;
	scope["BotOnPause"] <- ::Left4Bots.BotOnPause;
	scope["BotOnResume"] <- ::Left4Bots.BotOnResume;
	
	AddThinkToEnt(bot, "BotThink_Main");
}

::Left4Bots.RemoveBotThink <- function (bot)
{
	AddThinkToEnt(bot, null);
}

::Left4Bots.ClearBotThink <- function ()
{
	foreach (id, bot in ::Left4Bots.Bots)
	{
		if (bot.IsValid())
			AddThinkToEnt(bot, null);
	}
}

// Main bot think function (splits the work of the entire think process in different frames so the think function isn't overloaded)
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Main <- function ()
{
	Origin = self.GetOrigin();
	
	// Can't do anything at the moment
	if (Left4Bots.SurvivorCantMove(self))
		return Left4Bots.Settings.bot_think_interval;
	
	// Don't do anything if the bot is on a ladder or the mode hasn't started yet
	if (NetProps.GetPropInt(self, "movetype") == 9 /* MOVETYPE_LADDER */ || !Left4Bots.ModeStarted)
		return Left4Bots.Settings.bot_think_interval;

	// Don't do anything while frozen
	if ((NetProps.GetPropInt(self, "m_fFlags") & (1 << 5)))
	{
		// If the bot has FL_FROZEN flag set, CommandABot will fail even though it still returns true
		// Make sure to send at least one extra move command to the bot after the FL_FROZEN flag is unset
		if (MovePos)
			NeedMove = 2;

		return Left4Bots.Settings.bot_think_interval;
	}
	
	// HighPriority MOVEs are spit/charger dodging and such
	if (MovePos && MoveType == AI_MOVE_TYPE.HighPriority)
	{
		// Lets see if we reached our high priority destination...
		if ((Origin - MovePos).Length() <= Left4Bots.Settings.move_end_radius)  // TODO: apparently TryGetPathableLocationWithin can return a position under cars and other big obstacles. This will make the MOVE try to get there indefinitely. Maybe add a timeout to reset it?
		{
			// Yes, we did
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			
			// No longer needed if we set sb_debug_apoproach_wait_time to something like 0.5 or even 0
			// BotReset();
		}
		else
			BotMoveTo(MovePos); // No, keep moving
	}
	
	if (Left4Bots.Settings.close_saferoom_door_highres)
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
			if (!Left4Bots.Settings.close_saferoom_door_highres)
				BotThink_Door();
			
			BotThink_Misc();
			break;
		}
	}
	
	if (MovePos && Paused == 0)
	{
		if (!BotManualAttack())
			Left4Utils.PlayerDisableButton(self, BUTTON_RELOAD); // For some reason, while executing MOVE commands, the vanilla AI keeps reloading after each bullet. Let's prevent this
		else
			Left4Utils.PlayerEnableButton(self, BUTTON_RELOAD);
	}
	else
	{
		if (Left4Bots.Settings.shove_specials_radius > 0 && Time() >= NetProps.GetPropFloat(self, "m_flNextShoveTime"))
		{
			local target = Left4Bots.GetSpecialInfectedToShove(self, Origin);
			if (target)
				Left4Utils.PlayerPressButton(self, BUTTON_SHOVE, Left4Bots.Settings.button_holdtime_tap, target, Left4Bots.Settings.shove_specials_deltapitch, 0, false);
		}
		
		Left4Utils.PlayerEnableButton(self, BUTTON_RELOAD);
	}
	
	if (++FuncI > 5)
		FuncI = 1;
	
	return Left4Bots.Settings.bot_think_interval;
}

// Handles the bot's items pick-up logic
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Pickup <- function ()	// TODO fix: The sacrifice finale, Francis near the fence started moving for the medkit, while walking around the fence the pickup went too far and stopped, then started again and again.
{
	// Don't do this here. Let the bot pick up items that can be picked up directly (without a MOVE command) even if we are moving for something else
	//if (MoveType > AI_MOVE_TYPE.Pickup)
	//	return; // Do nothing if there is an ongoing MOVE with higher priority
	
	local pickup = BotGetNearestPickupWithin(Left4Bots.Settings.pickups_scan_radius);
	if (!pickup && MoveType == AI_MOVE_TYPE.Pickup && Left4Bots.IsValidPickup(MoveEnt))
		pickup = MoveEnt; // We have no visible pickup nearby at the moment but, if we already got a MoveEnt we are moving to and it's still valid, we'll stick to it even if we can't see it
	
	if (!pickup)
	{
		// Not item to pick up

		if (MoveType == AI_MOVE_TYPE.Pickup)
		{
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - No item to pick up; resetting previous pick-up MOVE");
			
			// We were moving for a pick-up tho, so we must reset
			if (MovePos)
				BotReset();
			
			MoveEnt = null;
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			NeedMove = 0;
		}
		return;
	}
	
	// Is the item close enough?
	if ((self.GetCenter() - pickup.GetCenter()).Length() <= Left4Bots.Settings.pickups_pick_range) // There is a cvar (player_use_radius 96) but idk how the distance is calculated, seems not to be from the player's origin or center
	{
		// Yes, pick it up
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Picking up: " + pickup.GetClassname());
		
		Left4Utils.PlayerPressButton(self, BUTTON_USE, Left4Bots.Settings.button_holdtime_tap, pickup, 0, 0, true);
		Left4Timers.AddTimer(null, Left4Bots.Settings.pickups_failsafe_delay, @(params) Left4Bots.PickupFailsafe(params.bot, params.item), { bot = self, item = pickup });

		if (MoveType == AI_MOVE_TYPE.Pickup)
		{
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Item picked up: resetting MOVE");
			
			// Reset if we were moving for this item
			if (MovePos)
				BotReset();

			MoveEnt = null;
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			NeedMove = 0;
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
	if (Left4Bots.EscapeStarted || Left4Bots.SurvivorsHeldOrIncapped() || (Left4Bots.Settings.pickups_max_separation > 0 && Left4Bots.IsFarFromHumanSurvivors(UserId, Origin, Left4Bots.Settings.pickups_max_separation))) // TODO: max separation only if lagging behind?
	{
		if (MoveType == AI_MOVE_TYPE.Pickup)
		{
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Teammates need help or too far: resetting MOVE");
			
			// Reset if we were moving for this item
			if (MovePos)
				BotReset();

			MoveEnt = null;
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			NeedMove = 0;
		}
		return;
	}

	if (!MovePos || MoveType != AI_MOVE_TYPE.Pickup || !Left4Bots.IsValidPickup(MoveEnt) || MoveEnt.GetEntityIndex() != pickup.GetEntityIndex())
	{
		// We start a MOVE if at least one of these conditions is met:
		// 1. There is no previous MOVE
		// 2. The previous MOVE has a lower priority
		// 3. Our destination item (MoveEnt) wasn't set or is no longer valid
		// 4. Our destination item (MoveEnt) changed
		
		MoveType = AI_MOVE_TYPE.Pickup;
		MoveEnt = pickup;
		BotMoveTo(MoveEnt.GetOrigin(), true);
		
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Started moving for: " + MoveEnt.GetClassname());
	}
	else
	{
		// Already moving for the item (MoveEnt), keep moving
		BotMoveTo(MoveEnt.GetOrigin());
	}
}

// Handles the bot's defib logic
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Defib <- function ()
{
	if (MoveType > AI_MOVE_TYPE.Defib)
		return; // Do nothing if there is an ongoing MOVE with higher priority
	
	if (Left4Bots.IsSomeoneElseHolding(UserId, "weapon_defibrillator"))
	{
		// Someone else is holding a defibrillator, likely they are already about to defib the dead one
		
		if (MoveType == AI_MOVE_TYPE.Defib)
		{
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Someone else is about to defib; resetting");
			
			if (MovePos)
				BotReset();

			MoveEnt = null;
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			NeedMove = 0;
		}
		return;
	}
	
	if (MoveType != AI_MOVE_TYPE.Defib)
	{
		// We aren't executing any defib atm
		
		// Is there any survivor_death_model we can actually defib?
		local death = null;
		if (Left4Utils.HasDefib(self))
			death = Left4Bots.GetNearestDeathModelWithin(self, Origin, Left4Bots.Settings.deads_scan_radius, Left4Bots.Settings.deads_scan_maxaltdiff); // If we have a defibrillator we'll search the nearest death model within a certain radius
		else
			death = Left4Bots.GetNearestDeathModelWithDefibWithin(self, Origin, Left4Bots.Settings.deads_scan_radius, Left4Bots.Settings.deads_scan_maxaltdiff); // Otherwise we'll search the nearest death model within a certain radius with a defibrillator nearby
		
		if (!death || !death.IsValid())
			return; // No one to defib
		
		// TODO?
		//if (Left4Bots.HasAngryCommonsWithin(orig, 3, 100) != false || Left4Utils.HasSpecialInfectedWithin(self, 400) || Left4Bots.SurvivorsHeldOrIncapped())
		if (BotIsInPause()) // TODO: maxSeparation
			return;
		
		MoveType = AI_MOVE_TYPE.Defib;
		MoveEnt = death;
		BotMoveTo(MoveEnt.GetOrigin(), true);
			
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Started moving for: " + MoveEnt.GetClassname());
		
		return;
	}
	
	// We are already moving for a survivor_death_model
	
	// TODO?
	//if (Left4Bots.HasAngryCommonsWithin(orig, 3, 100) != false || Left4Utils.HasSpecialInfectedWithin(self, 400) || Left4Bots.SurvivorsHeldOrIncapped())
	if (BotIsInPause()) // TODO: maxSeparation
		return;

	// Reset if our destination survivor_death_model is no longer valid
	if (!MovePos || !MoveEnt || !MoveEnt.IsValid())
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Dest death model no longer valid; resetting");
		
		if (MovePos)
			BotReset();

		MoveEnt = null;
		MovePos = null;
		MoveType = AI_MOVE_TYPE.None;
		NeedMove = 0;
		
		return;
	}
	
	// Destination survivor_death_model is still there and no one is defibbing it, let's see if we reached it
	if ((Origin - MovePos).Length() <= Left4Bots.Settings.move_end_radius_defib)
	{
		// We reached the dead survivor, but do we have a defibrillator?
		if (!Left4Utils.HasDefib(self))
		{
			// Nope, but we are supposed to find it here
			local defib = Left4Bots.FindDefibPickupWithin(MoveEnt.GetOrigin());
			if (!defib)
			{
				// We don't have a defib and we came for a death model with defib nearby that is no longer available, so let's reset
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Dest death had a defib nearby but it's no longer available; resetting");
				
				if (MovePos)
					BotReset();

				MoveEnt = null;
				MovePos = null;
				MoveType = AI_MOVE_TYPE.None;
				NeedMove = 0;
				
				return;
			}
			
			DoEntFire("!self", "Use", "", 0, self, defib);
			
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Picked up a defib near the death model");
			
			// Do nothing until the defib is fully in our inventory
		}
		else
		{
			// We either came here with a defibrillator or we picked it up here, but are we holding it?
			local holdingItem = self.GetActiveWeapon();
			if (holdingItem && holdingItem.GetClassname() == "weapon_defibrillator")
			{
				// Yes, but can we use it right now?
				if (Time() >= NetProps.GetPropFloat(holdingItem, "m_flNextPrimaryAttack"))
					Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_defib, MoveEnt, 0, 0, true); // Yes
			}
			else if (holdingItem && holdingItem.GetClassname() != "weapon_pain_pills" && holdingItem.GetClassname() != "weapon_adrenaline") // We'll run into an infinite switch loop if the vanilla AI wants to use pills/adrenaline
			{
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - About to start defib");
			
				self.SwitchToItem("weapon_defibrillator");
			}
		}
	}
	else
		BotMoveTo(MoveEnt.GetOrigin()); // Not there yet, keep moving
}

// Handles the bot's items give and nades throw logics
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Throw <- function ()
{
	/* I'm not sure this is even needed, the bots already retreat on their own and this has no effect when there is a downed survivor anyway
	local nearestTank = Left4Bots.GetNearestActiveTankWithin(self, 0, RETREAT_FROM_TANK_DINSTANCE);
	if (nearestTank && !nearestTank.IsDead() && !nearestTank.IsDying() && !nearestTank.IsIncapacitated())
	{
		Left4Utils.BotCmdRetreat(self, nearestTank);
		
		Left4Bots.Log(LOG_LEVEL_DEBUG, self.GetPlayerName() + " RETREAT");
	}
	*/
	
	// Handle give items
	local lookAtHuman = NetProps.GetPropEntity(self, "m_lookatPlayer");
	if (lookAtHuman && lookAtHuman.IsValid() && !IsPlayerABot(lookAtHuman) && NetProps.GetPropInt(lookAtHuman, "m_iTeamNum") == TEAM_SURVIVORS && !Left4Bots.SurvivorCantMove(lookAtHuman) && (Origin - lookAtHuman.GetOrigin()).Length() <= Left4Bots.Settings.give_max_range)
	{
		// Try give a throwable
		if (Left4Bots.GiveInventoryItem(self, lookAtHuman, INV_SLOT_THROW))
			return; // Don't do anything else if the give succedes
		
		// Then try with pills and adrenaline
		if (Left4Bots.GiveInventoryItem(self, lookAtHuman, INV_SLOT_PILLS))
			return; // Don't do anything else if the give succedes
		
		// Last try with medkits / defib / upgrade packs
		if (Left4Bots.GiveInventoryItem(self, lookAtHuman, INV_SLOT_MEDKIT))
			return; // Don't do anything else if the give succedes
	}
	
	// Handle throw nades
	if ((ThrowStartedOn && (Time() - ThrowStartedOn) > 5.0) || Left4Bots.SurvivorCantMove(self))
	{
		// Reset last attempted throw if takes too long (likely we got interrupted while switching) or bot can't move (probably got pinned)
		ThrowType = AI_THROW_TYPE.None;
		ThrowTarget = null;
		ThrowStartedOn = 0;
		
		// Don't forget to re-enable the fire button
		NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK));
		
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Throw expired");
	}
	
	local heldClass = null;
	local held = self.GetActiveWeapon();
	if (held && held.IsValid())
		heldClass = held.GetClassname();
	
	if (heldClass && (heldClass == "weapon_molotov" || heldClass == "weapon_pipe_bomb" || heldClass == "weapon_vomitjar"))
	{
		// Probably we're about to throw this. Let's see if we can...
		if (Time() >= NetProps.GetPropFloat(held, "m_flNextPrimaryAttack"))
		{
			if (ThrowTarget && Left4Bots.ShouldStillThrow(self, UserId, Origin, ThrowType, ThrowTarget, heldClass))
			{
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Throw finalization - ThrowType: " + ThrowType + " - ThrowTarget: " + ThrowTarget);
				
				// Don't forget to re-enable the fire button
				NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK));
				
				switch (ThrowType)
				{
					case AI_THROW_TYPE.Tank:
					{
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, ThrowTarget, Left4Bots.Settings.tank_throw_deltapitch, 0, true, 1);
						break;
					}
					case AI_THROW_TYPE.Horde:
					{
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, ThrowTarget, Left4Bots.Settings.throw_nade_deltapitch, 0, true, 1);
						break;
					}
					case AI_THROW_TYPE.Manual:
					{
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, ThrowTarget, Left4Bots.Settings.throw_nade_deltapitch, 0, true, 1);
						break;
					}
					default: // None
					{
						// Not supposed to happen, but..
						Left4Bots.BotSwitchToAnotherWeapon(self);
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
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Throw no longer valid");
				
				Left4Bots.BotSwitchToAnotherWeapon(self);
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
			ThrowTarget = Left4Bots.GetThrowTarget(self, UserId, Origin, itemClass);
			if (ThrowTarget)
			{
				if ((typeof ThrowTarget) == "instance")
					ThrowType = AI_THROW_TYPE.Tank;
				else
					ThrowType = AI_THROW_TYPE.Horde;
				ThrowStartedOn = Time();
				
				// Need to disable the fire button until we are ready to throw (or throw is interrupted) otherwise the bot's vanilla AI can trigger the fire before our PressButton and the throw pos will be totally random
				NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") | BUTTON_ATTACK);
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Throw (" + itemClass + ") -> " + ThrowTarget);
				
				self.SwitchToItem(itemClass); // Yes, switch to the throw item
			}
		}
	}
}

// Handles the bot's orders execution logic
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Orders <- function ()
{
	if (MoveType > AI_MOVE_TYPE.Order)
		return; // Do nothing if there is an ongoing MOVE with higher priority
	
	if (!CurrentOrder && Orders.len() > 0)
	{
		CurrentOrder = Orders.remove(0); // Get the next order to execute and remove it from the FIFO queue
		
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - New CurrentOrder: " + Left4Bots.BotOrderToString(CurrentOrder));
	}
	
	if (!CurrentOrder)
		return; // Nothing to do
	
	if (CurrentOrder.DestEnt && (!CurrentOrder.DestEnt.IsValid() || NetProps.GetPropInt(CurrentOrder.DestEnt, "m_hOwner") > 0)) // TODO: ValidPickup?
	{
		// Order's DestEnt is no longer valid or it was picked up by someone. Cancel this order
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - CurrentOrder's DestEnt is no longer valid: " + Left4Bots.BotOrderToString(CurrentOrder));
		
		BotCancelCurrentOrder();

		return;
	}
	
	// Execute CurrentOrder
	
	if (CurrentOrder.OrderType == "follow")
	{
		if (CurrentOrder.CanPause && BotIsInPause(false, CurrentOrder.MaxSeparation, CurrentOrder.DestEnt, Left4Bots.Settings.follow_pause_radius))
			return;
	}
	else
	{
		if (CurrentOrder.CanPause && BotIsInPause(CurrentOrder.OrderType == "heal", CurrentOrder.MaxSeparation))
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
				BotMoveTo(destPos);
			else
				BotFinalizeCurrentOrder();
		}
	}
}

// Handles the bot's open/close door logics
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Door <- function ()
{
	if (MoveType > AI_MOVE_TYPE.Door)
		return; // Do nothing if there is an ongoing MOVE with higher priority
	
	if (!DoorEnt)
		return; // Nothing to do
	
	// Is our door still valid?
	if (!DoorEnt.IsValid())
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - DoorEnt is no longer valid");
		
		// Nope, reset
		DoorEnt = null;
		DoorZ = 0;
		DoorAct = AI_DOOR_ACTION.None;
		
		if (MoveType == AI_MOVE_TYPE.Door)
		{
			if (MovePos)
				BotReset();

			MoveEnt = null;
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			NeedMove = 0;
		}
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
				if ((Origin - doorPos).Length() > Left4Bots.Settings.close_saferoom_door_distance)
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
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - DoorEnt reset; bot stepped outside the saferoom");
			}
		}
	}
	
	if (DoorAct != AI_DOOR_ACTION.Open && DoorAct != AI_DOOR_ACTION.Close)
		return; // Likely it's still AI_DOOR_ACTION.Saferoom, we must wait until we can actually close it
	
	// Are we close enough to the door, yet?
	if ((Origin - doorPos).Length() <= Left4Bots.Settings.move_end_radius_door)
	{
		// Yes, open/close it

		if (DoorAct == AI_DOOR_ACTION.Open)
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Opening the door: " + DoorEnt.GetName());
		else
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Closing the door: " + DoorEnt.GetName());

		Left4Utils.PlayerPressButton(self, BUTTON_USE, Left4Bots.Settings.button_holdtime_tap, DoorEnt, 0, 0, true);
		Left4Timers.AddTimer(null, Left4Bots.Settings.door_failsafe_delay, @(params) Left4Bots.DoorFailsafe(params.bot, params.door, params.action), { bot = self, door = DoorEnt, action = DoorAct });
		
		// Reset
		DoorEnt = null;
		DoorZ = 0;
		DoorAct = AI_DOOR_ACTION.None;
		
		if (MoveType == AI_MOVE_TYPE.Door)
		{
			if (MovePos)
				BotReset();

			MoveEnt = null;
			MovePos = null;
			MoveType = AI_MOVE_TYPE.None;
			NeedMove = 0;
		}
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
// Runs in the scope of the bot entity
::Left4Bots.BotThink_Misc <- function ()
{
	// TODO?
}

// Handles the bot's enemy shoot/shove logics while the bot is executing a MOVE command
// Returns whether the bot is allowed to reload his current weapon or not
// Runs in the scope of the bot entity
::Left4Bots.BotManualAttack <- function () // TODO: Shove teammates hanging from tongue
{
	local target = null;
	local targetDeltaPitch = Left4Bots.Settings.shove_commons_deltapitch;
	if (Time() >= NetProps.GetPropFloat(self, "m_flNextShoveTime"))
	{
		// Can shove
		
		// Is there a special infected to shove?
		if (Left4Bots.Settings.shove_specials_radius > 0)
			target = Left4Bots.GetSpecialInfectedToShove(self, Origin);
		
		if (target)
			targetDeltaPitch = Left4Bots.Settings.shove_specials_deltapitch;
		else
		{
			// No. Any common?
			if (Left4Bots.Settings.shove_commons_radius > 0)
				target = Left4Utils.GetFirstVisibleCommonInfectedWithin(self, Left4Bots.Settings.shove_commons_radius);
		}
	}
	
	// Shove or shoot
	if (target)
		Left4Utils.PlayerPressButton(self, BUTTON_SHOVE, Left4Bots.Settings.button_holdtime_tap, target, targetDeltaPitch, 0, false);
	else if (NetProps.GetPropInt(self, "m_hasVisibleThreats")) // m_hasVisibleThreats indicates that a threat is in the bot's current field of view. An infected behind the bot won't set this
	{
		local aw = self.GetActiveWeapon();
		if (aw && aw.IsValid() && !NetProps.GetPropInt(aw, "m_bInReload"))
		{
			local slot = Left4Utils.FindSlotForItemClass(self, aw.GetClassname());
			if (slot == INV_SLOT_PRIMARY || slot == INV_SLOT_SECONDARY)
			{
				/*
				local start = self.EyePosition();
				local end = start + self.EyeAngles().Forward().Scale(6000); // <- TODO: maxDistance by weapon
				
				local m_trace = { start = start, end = end, ignore = self, mask = TRACE_MASK_SHOT };
				TraceLine(m_trace);
				
				if (m_trace.hit && m_trace.enthit && m_trace.enthit.IsValid() && m_trace.enthit != self)
				{
					local entClass = m_trace.enthit.GetClassname();
					if ((entClass == "infected" && NetProps.GetPropInt(m_trace.enthit, "m_lifeState") == 0) || (entClass == "player" && NetProps.GetPropInt(m_trace.enthit, "m_iTeamNum") == TEAM_INFECTED && !m_trace.enthit.IsDead() && !m_trace.enthit.IsDying()))
						Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, null, 0, 0, false);
				}
				*/
				
				local tgt = Left4Bots.FindBotNearestEnemy(self, Origin, Left4Bots.Settings.manual_attack_radius, Left4Bots.Settings.manual_attack_mindot);
				if (tgt)
				{
					local v = tgt.GetCenter() - self.EyePosition();
					v.Norm();
					self.SnapEyeAngles(Left4Utils.VectorAngles(v));
					Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, Left4Bots.Settings.button_holdtime_tap, null, 0, 0, false);
				}
				
				// Bots always reload for no reason while executing a MOVE command. Don't let them if there are visible threats and still rounds in the magazine
				if (aw.Clip1() >= 5)
					return false;
			}
		}
	}
	return true;
}

// Send the MOVE command to reach the given position, but only when really needed
// force = true to start moving or to force a MOVE command. force = false to keep moving and only send another MOVE command if needed
// Runs in the scope of the bot entity
::Left4Bots.BotMoveTo <- function (dest, force = false)
{
	if (!dest)
		return;
	
	if (force || !MovePos)
		NeedMove = 2;	// For some reason, sometimes, the first MOVE does nothing so let's send at least 2
	
	if (NeedMove <= 0 && (dest - MovePos).Length() <= 5) // <- This checks if the destination entity moved after the bot started moving towards it and forces a move command to the new entity position if the entity moved
		return;
	
	if (!(NetProps.GetPropInt(self, "m_fFlags") & (1 << 5)))
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - MOVE -> " + dest);
		
		MovePos = dest;
		Left4Utils.BotCmdMove(self, MovePos);
		DelayedReset = false; // Reset no longer needed as the MOVE replaced the previous one
	
		NeedMove--;
	}
}

// Send a RESET command to the bot (if CanReset is true)
// Runs in the scope of the bot entity
::Left4Bots.BotReset <- function (isDelayed = false)
{
	if (CanReset)
	{
		if (isDelayed)
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - DELAYED RESET");
		else
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - RESET");
		
		// TODO: Should we send delayed resets or not? It seems that they can get the bots stuck sometimes. Need to verify
		if (!isDelayed)
			Left4Utils.BotCmdReset(self);
		
		DelayedReset = false;
	}
	else
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - RESET has been delayed");
		
		DelayedReset = true;
	}
}

// Returns the bot's closest item to pick up within the given radius
// Runs in the scope of the bot entity
::Left4Bots.BotGetNearestPickupWithin <- function (radius = 200)
{
	if (PickupsToSearch.len() <= 0)
		return null;
	
	local ret = null;
	local ent = null;
	local orig = self.GetCenter();
	local minDist = 1000000;
	while (ent = Entities.FindInSphere(ent, orig, radius)) // TODO: VERY SLOW! We should find another way to do this
	{
		local entClass = ent.GetClassname();
		if ((entClass in PickupsToSearch) && Left4Bots.IsValidPickup(ent) && ent.GetEntityIndex() != Left4Bots.GiveItemIndex1 && ent.GetEntityIndex() != Left4Bots.GiveItemIndex2)
		{
			// If we are moving to defib a dead survivor and we have a defibrillator in our inventory, ignore the medkit or we'll loop replacing our defibrillator with the medkit over and over again
			if (MoveType != AI_MOVE_TYPE.Defib || entClass.find("first_aid_kit") == null || !Left4Utils.HasDefib(self))
			{
				local dist = (orig - ent.GetCenter()).Length();
				if (dist < minDist && Left4Utils.CanTraceTo(self, ent))
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
// Runs in the scope of the bot entity
::Left4Bots.BotInitializeCurrentOrder <- function ()
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
			//Left4Bots.Log(LOG_LEVEL_WARN, "[AI]" + self.GetPlayerName() + " can't execute 'heal' order; no medkit in inventory");
			
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
			BotMoveTo(CurrentOrder.DestPos, true);
		else if (CurrentOrder.DestEnt)
			BotMoveTo(CurrentOrder.DestEnt.GetOrigin(), true);
		else
			BotFinalizeCurrentOrder();
	}
}

// Called to finalize the current order after the order's destination has been reached (or there was no destination at all)
// Makes the bot (self) do whatever he has to do in order to complete the current order
// Runs in the scope of the bot entity
::Left4Bots.BotFinalizeCurrentOrder <- function ()
{
	if (!CurrentOrder)
	{
		Left4Bots.Log(LOG_LEVEL_ERROR, "[AI]" + self.GetPlayerName() + " - Finalizing current order without a current order!");
		
		NeedMove = 0;
		MovePos = null;
		MoveType = AI_MOVE_TYPE.None;
		return;
	}
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Finalizing order: " + Left4Bots.BotOrderToString(CurrentOrder));
	
	local orderComplete = true;
	switch (CurrentOrder.OrderType)
	{
		case "use":
		{
			// TODO
			
			break;
		}
		case "lead":
		{
			local nextPos = Left4Utils.GetFarthestPathableFlowPos(self, Left4Bots.Settings.lead_max_segment, Left4Bots.Settings.lead_check_ground, Left4Bots.Settings.lead_debug_duration);
			if (nextPos)
			{
				//if ((nextPos - Origin).Length() >= Left4Bots.Settings.lead_min_segment)
				if (abs(GetFlowDistanceForPosition(nextPos) - GetFlowDistanceForPosition(Origin)) >= Left4Bots.Settings.lead_min_segment)
				{
					if (!CurrentOrder.DestPos)
					{
						// This was a Start lead order from a player (CurrentOrder.From contains the entity of the player)
						if (CurrentOrder.From && CurrentOrder.From.IsValid())
							Left4Bots.Log(LOG_LEVEL_INFO, "[AI]" + self.GetPlayerName() + " started leading; order from: " + CurrentOrder.From.GetPlayerName());
						else
							Left4Bots.Log(LOG_LEVEL_WARN, "[AI]" + self.GetPlayerName() + " started leading; order from: ?");
						
						local t = Time();
						if ((t - Left4Bots.LastLeadStartVocalize) >= Left4Bots.Settings.lead_vocalize_interval)
						{
							Left4Bots.SpeakRandomVocalize(self, Left4Bots.VocalizerLeadStart, RandomFloat(0.4, 0.9));
							Left4Bots.LastLeadStartVocalize = t;
						}
					}
					
					// Self add another "lead" order but with the next position as DestPos so we can start/continue travel
					///Left4Bots.BotOrderAppend(self, "lead", null, null, nextPos);
					/// Avoid the ^slow GetScriptScope(), if possible
					//local order = { OrderType = "lead", From = null, DestEnt = null, DestPos = nextPos, DestLookAtPos = null, CanPause = true, DestRadius = Left4Bots.Settings.move_end_radius_lead, MaxSeparation = Left4Bots.Settings.lead_max_separation };
					//Orders.append(order);
					//Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Appended order (queue pos. " + Orders.len() + "): " + Left4Bots.BotOrderToString(order));
					orderComplete = false; // This way is better
					
					// Update CurrentOrder.DestPos with the next segment's end
					CurrentOrder.DestPos = nextPos;
					Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - CurrentOrder.DestPos updated: " + CurrentOrder.DestPos);
					
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
						Left4Bots.Log(LOG_LEVEL_WARN, "[AI]" + self.GetPlayerName() + " can't start leading; goal already reached");
						
						Left4Bots.SpeakRandomVocalize(self, Left4Bots.VocalizerLeadStop, RandomFloat(0.5, 1.0));
					}
					else
					{
						// It was a continuation of the travel, so it's a legit end of the travel
						Left4Bots.Log(LOG_LEVEL_INFO, "[AI]" + self.GetPlayerName() + " stopped leading; goal reached");
						
						Left4Bots.SpeakRandomVocalize(self, Left4Bots.VocalizerLeadStop, RandomFloat(0, 0.5));
					}
				}
			}
			else
			{
				// Not supposed to happen but we'll just end the travel here
				if (!CurrentOrder.DestPos)
				{
					// This was a Start lead order from a player, so the travel didn't even start
					Left4Bots.Log(LOG_LEVEL_ERROR, "[AI]" + self.GetPlayerName() + " can't start leading; nextPos is null!");
					
					DoEntFire("!self", "SpeakResponseConcept", "PlayerNo", RandomFloat(0.5, 1.0), null, self);
				}
				else
				{
					// It was a continuation of the travel, so it's an "abnormal" end of the travel
					Left4Bots.Log(LOG_LEVEL_ERROR, "[AI]" + self.GetPlayerName() + " stopped leading; nextPos is null!");
					
					Left4Bots.SpeakRandomVocalize(self, Left4Bots.VocalizerLeadStop, RandomFloat(0, 0.5));
				}
			}
			break;
		}
		case "follow":
		{
			Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Followed ent is in range");

			// Start the Pause if needed
			if (Paused == 0)
			{
				Paused = Time();
				BotOnPause();
			}
			orderComplete = false;

			break;
		}
		case "witch":
		{
			if (CurrentOrder.DestEnt && CurrentOrder.DestEnt.IsValid() && ("LookupAttachment" in CurrentOrder.DestEnt))
			{
				local attachId = CurrentOrder.DestEnt.LookupAttachment("forward");
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Found witch 'forward' attachment id: " + attachId);
				
				// Shoot 3 bullets to her head as quick as possible (if using slow weapons like pump shotguns the bullets will be 2 but usually 1 is enough)
				NetProps.SetPropInt(self, "m_fFlags", NetProps.GetPropInt(self, "m_fFlags") | (1 << 5)); // set FL_FROZEN for the entire duration of the 3 shoots
				Left4Timers.AddTimer(null, 0.01, @(params) Left4Bots.BotShootAtEntityAttachment(params.bot, params.witch, params.attachmentid ), { bot = self, witch = CurrentOrder.DestEnt, attachmentid = attachId });
				Left4Timers.AddTimer(null, 0.5, @(params) Left4Bots.BotShootAtEntityAttachment(params.bot, params.witch, params.attachmentid ), { bot = self, witch = CurrentOrder.DestEnt, attachmentid = attachId });
				Left4Timers.AddTimer(null, 0.9, @(params) Left4Bots.BotShootAtEntityAttachment(params.bot, params.witch, params.attachmentid, true ), { bot = self, witch = CurrentOrder.DestEnt, attachmentid = attachId }); // this will unset FL_FROZEN at the end
			}
			else
				Left4Bots.Log(LOG_LEVEL_ERROR, "[AI]" + self.GetPlayerName() + " - Witch has no LookupAttachment!");
			
			break;
		}
		case "heal":
		{
			if (Left4Utils.HasMedkit(self))
			{
				local aw = self.GetActiveWeapon();
				if (aw && aw.GetClassname() == "weapon_first_aid_kit")
				{
					// Are we ready to use the medkit?
					if (Time() > NetProps.GetPropFloat(aw, "m_flNextPrimaryAttack"))
					{
						// Yes
						Left4Bots.Log(LOG_LEVEL_INFO, "[AI]" + self.GetPlayerName() + " is healing " + CurrentOrder.DestEnt.GetPlayerName());
						
						if (CurrentOrder.DestEnt.GetPlayerUserId() == self.GetPlayerUserId())
							Left4Utils.PlayerPressButton(self, BUTTON_ATTACK, CurrentOrder.HoldTime, null, 0, 0, true);
						else
						{
							Left4Utils.PlayerPressButton(self, BUTTON_SHOVE,  CurrentOrder.HoldTime, CurrentOrder.DestEnt.GetCenter(), 0, 0, true);
							
							// This will check if the healing started and the healing target is the right target. If not, it will abort the healing and the current order and will re-add the order to try again
							Left4Timers.AddTimer(null, 0.8, @(params) Left4Bots.CheckHealingTarget(params.bot, params.order), { bot = self, order = CurrentOrder });
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
				Left4Bots.Log(LOG_LEVEL_WARN, "[AI]" + self.GetPlayerName() + " can't execute 'heal' order; no medkit in inventory");
			
			break;
		}
		case "goto":
		{
			Left4Bots.SpeakRandomVocalize(self, Left4Bots.VocalizerGotoStop, RandomFloat(0.1, 0.6));
			
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
		MoveType = AI_MOVE_TYPE.None;
		CurrentOrder = null; // Order is done
	
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - CurrentOrder done. " + Orders.len() + " order(s) in queue.");
	}
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - CurrentOrder not done yet");
}

// Cancel the current order (does not affect the orders in the queue)
// Runs in the scope of the bot entity
::Left4Bots.BotCancelCurrentOrder <- function ()
{
	if (!CurrentOrder)
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Cancelling order: " + Left4Bots.BotOrderToString(CurrentOrder));

	if (MoveType == AI_MOVE_TYPE.Order)
	{
		if (MovePos)
			BotReset();

		MovePos = null;
		MoveType = AI_MOVE_TYPE.None;
		NeedMove = 0;
	}

	CurrentOrder = null;
}

// Cancel all the orders (current and queued) of type 'orderType'. if 'orderType' is null, all the bot's orders will be cancelled
::Left4Bots.BotCancelOrders <- function (orderType = null)
{
	if (orderType)
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Cancelling all the orders of type: " + orderType);
	else
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Cancelling all the orders");
	
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
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Orders still in queue: " + Orders.len());
}

// Cancel everything (current/queued orders, current pickup, anything)
::Left4Bots.BotCancelAll <- function ()
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Cancelling everything");
	
	// Orders stuff
	BotCancelOrders();
	
	// MOVE stuff
	if (MoveType != AI_MOVE_TYPE.None)
	{
		if (MovePos)
			BotReset();

		MovePos = null;
		MoveEnt = null;
		MoveType = AI_MOVE_TYPE.None;
		NeedMove = 0;
	}
	
	// Door stuff
	DoorEnt = null;
	DoorZ = 0;
	DoorAct = AI_DOOR_ACTION.None;
	
	// Just in case...
	NetProps.SetPropInt(self, "m_fFlags", NetProps.GetPropInt(self, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN
	NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") & (~BUTTON_ATTACK)); // enable FIRE button
	NetProps.SetPropInt(self, "m_afButtonForced", 0); // clear forced buttons
}

// Check if the bot should pause what he is doing. Handles the Paused flag and the RESET command
// maxSeparation is the max distance from the other survivors (0 = no check)
// followEnt if not null it's the entity we need to follow
// if followEnt is not null, followRange is the maximum distance from followEnt before we need to move to follow again (we'll stay in Pause if within this range from followEnt)
// followEnt and followRange have no effect on the logics to start the pause, only for the stop. The pause will be started in BotThink_Orders when we're within DestRadius from our followEnt
// Returns true if the bot is in pause, false if not
// Runs in the scope of the bot entity
::Left4Bots.BotIsInPause <- function (isHealOrder = false, maxSeparation = 0, followEnt = null, followRange = 150)
{
	if (Paused == 0)
	{
		// Should we start the pause?
		if (Left4Bots.BotShouldStartPause(self, UserId, Origin, isHealOrder, maxSeparation))
		{
			// Yes, let's give control back to the vanilla AI
			Paused = Time();
			BotOnPause();
		}
	}
	else if (followEnt || (Time() - Paused) >= Left4Bots.Settings.pause_min_time) // Only stop the pause if at least pause_min_time seconds passed, or we are following someone
	{
		// Should we stop the pause?
		if ((!followEnt || (followEnt.GetOrigin() - Origin).Length() > followRange) && Left4Bots.BotShouldStopPause(self, UserId, Origin, isHealOrder, maxSeparation))
		{
			// Yes, unpause and refresh the last MOVE if needed
			Paused = 0;
			BotOnResume();
		}
	}
	
	return (Paused != 0);
}

// Called when the bot starts the pause
// Runs in the scope of the bot entity
::Left4Bots.BotOnPause <- function ()
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Pause start");
	
	if (MovePos)
		BotReset();
	
	if (Left4Bots.Settings.pause_debug)
		Say(self, "[P]", false);
}

// Called when the bot stops the pause
// Runs in the scope of the bot entity
::Left4Bots.BotOnResume <- function ()
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + self.GetPlayerName() + " - Pause stop");
	
	if (Left4Bots.Settings.pause_debug)
		Say(self, "[->]", false);
			
	if (MoveType == AI_MOVE_TYPE.Order && CurrentOrder.OrderType == "lead")
	{
		if (CurrentOrder.DestPos /*&& GetFlowDistanceForPosition(Origin) > GetFlowDistanceForPosition(CurrentOrder.DestPos) */)
		{
			// If we are executing a "lead" order and, during the pause, we moved ahead of the next position, the last MOVE will take us backwards. Better finalize the order to re-calc the next position from here
			BotFinalizeCurrentOrder();
		}
		else if (MovePos)
			NeedMove = 2; // Refresh previous MOVE
		
		local t = Time();
		if ((t - Left4Bots.LastLeadStartVocalize) >= Left4Bots.Settings.lead_vocalize_interval)
		{
			Left4Bots.SpeakRandomVocalize(self, Left4Bots.VocalizerLeadStart, RandomFloat(0.4, 0.9));
			Left4Bots.LastLeadStartVocalize = t;
		}
	}
	else if (MovePos)
		NeedMove = 2; // Refresh previous MOVE
}

// Returns the table representing the order with the given parameters, or null if the given bot is invalid or orderType is unknown
::Left4Bots.BotOrderPrepare <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true)
{
	if (!Left4Bots.IsHandledBot(bot))
		return null;

	if (!(orderType in ::Left4Bots.OrderPriorities))
		return null;

	local order = { OrderType = orderType, Priority = Left4Bots.OrderPriorities[orderType], From = from, DestEnt = destEnt, DestPos = destPos, DestLookAtPos = destLookAtPos, HoldTime = holdTime, CanPause = canPause };
	switch (orderType)
	{
		case "lead":
		{
			order.DestRadius <- Left4Bots.Settings.move_end_radius_lead;
			order.MaxSeparation <- Left4Bots.Settings.lead_max_separation;
			break;
		}
		case "follow":
		{
			order.DestRadius <- Left4Bots.Settings.move_end_radius_follow;
			order.MaxSeparation <- 0;
			break;
		}
		case "witch":
		{
			Left4Bots.SpeakRandomVocalize(bot, Left4Bots.VocalizerYes, RandomFloat(0.5, 1.0));
			
			order.DestRadius <- Left4Bots.Settings.move_end_radius_witch;
			order.MaxSeparation <- 0;
			break;
		}
		case "heal":
		{
			//Left4Bots.SpeakRandomVocalize(bot, Left4Bots.VocalizerYes, RandomFloat(0.5, 1.0));
			
			order.DestRadius <- Left4Bots.Settings.move_end_radius_heal;
			order.MaxSeparation <- 0;
			break;
		}
		default:
		{
			Left4Bots.SpeakRandomVocalize(bot, Left4Bots.VocalizerYes, RandomFloat(0.5, 1.0));
			
			order.DestRadius <- Left4Bots.Settings.move_end_radius;
			order.MaxSeparation <- 0;
		}
	}
	return order;
}

// Append an order to the given bot's queue. No check on priorities
// Returns the order's position in the bot's queue (where 1 = first position), or -1 if bad bot/orderType
::Left4Bots.BotOrderAppend <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true)
{
	local order = Left4Bots.BotOrderPrepare(bot, orderType, from, destEnt, destPos, destLookAtPos, holdTime, canPause);
	if (!order)
		return -1;
	
	local scope = bot.GetScriptScope();
	scope.Orders.append(order);
	local queuePos = scope.Orders.len();
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - Appended order (queue pos. " + queuePos + "): " + Left4Bots.BotOrderToString(order));
	
	return queuePos;
}

// Insert an order to the first position of the bot's queue and replaces CurrentOrder if needed. No check on priorities
// Returns the bot's queue len after the operation, or -1 if bad bot/orderType
::Left4Bots.BotOrderInsert <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true)
{
	local order = Left4Bots.BotOrderPrepare(bot, orderType, from, destEnt, destPos, destLookAtPos, holdTime, canPause);
	if (!order)
		return -1;
	
	local scope = bot.GetScriptScope();
	if (scope.CurrentOrder)
	{
		scope.Orders.insert(0, scope.CurrentOrder);
		scope.CurrentOrder = order;
		
		if (scope.MoveType == AI_MOVE_TYPE.Order)
			scope.MovePos = null; // Force a MOVE to the new destination
	}
	else
		scope.Orders.insert(0, order);
	
	local queueLen = scope.Orders.len();
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - Inserted order (queue len " + queueLen + "): " + Left4Bots.BotOrderToString(order));
	
	return queueLen;
}

// Add an order to the bot's queue placing it in the right position according to the priorities and replacing CurrentOrder if needed
// Returns the order's position in the bot's queue (where 0 = set/replaced CurrentOrder, 1 = first position in the queue), or -1 if bad bot/orderType
::Left4Bots.BotOrderAdd <- function (bot, orderType, from = null, destEnt = null, destPos = null, destLookAtPos = null, holdTime = 0.05, canPause = true)
{
	local order = Left4Bots.BotOrderPrepare(bot, orderType, from, destEnt, destPos, destLookAtPos, holdTime, canPause);
	if (!order)
		return -1;
	
	local scope = bot.GetScriptScope();
	local idx;
	for (idx = 0; idx < scope.Orders.len(); idx++)
	{
		if (scope.Orders[idx].Priority < order.Priority)
			break;
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
					scope.MovePos = null; // Force a MOVE to the new destination
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - New order replaced CurrentOrder: " + Left4Bots.BotOrderToString(order));
			}
			else
			{
				scope.CurrentOrder = order; // Set CurrentOrder
				
				Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - New order set to CurrentOrder: " + Left4Bots.BotOrderToString(order));
			}
			
			return 0;
		}
		
		// CurrentOrder must stay, just insert the new order to the first pos in the queue
		scope.Orders.insert(0, order);
			
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - New order (queue pos. 0): " + Left4Bots.BotOrderToString(order));
			
		return 1;
	}
	
	// If idx is >0 then CurrentOrder is not null and its priority is likely higher, so no need to check it
	scope.Orders.insert(idx, order); // Insert the new order to its pos in the queue
		
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - New order (queue pos. " + idx + "): " + Left4Bots.BotOrderToString(order));
		
	return (idx+1);
}

// Re-adds the given order to the bot's queue for a retry
::Left4Bots.BotOrderRetry <- function(bot, order)
{
	Left4Bots.Log(LOG_LEVEL_DEBUG, "BotOrderRetry");
	
	if (!bot || !order || !bot.IsValid() || !IsPlayerABot(bot))
		return;
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "BotOrderRetry - bot: " + bot.GetPlayerName() + " - order: " + order.OrderType);
	
	Left4Bots.BotOrderAdd(bot, order.OrderType, order.From, order.DestEnt, order.DestPos, order.DestLookAtPos, order.HoldTime, order.CanPause); // Retry
}

// Returns the number of order of type 'orderType' in the bot's queue (including CurrentOrder), or -1 if invalid bot supplied
::Left4Bots.BotOrdersCount <- function (bot, orderType)
{
	if (!Left4Bots.IsHandledBot(bot))
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
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - Has " + count + " orders of type: " + orderType);
	
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
	{
		if (order.DestEnt.IsValid())
			ret += " - DestEnt: " + order.DestEnt.GetClassname() + " (" + order.DestEnt.GetName() + ")";
		else
			ret += "[Invalid Entity]";
	}
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

// Does 'bot' have an order of type 'orderType'?
// true = yes, false = no, null = invalid bot
::Left4Bots.BotHasOrderOfType <- function (bot, orderType)
{
	if (!Left4Bots.IsHandledBot(bot))
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

// Returns the first available bot to add an order of type 'orderType' to his queue (null = no bot available)
// if 'ignoreUserid' is not null, the bot with that userid will be ignored
::Left4Bots.GetFirstAvailableBotForOrder <- function (orderType, ignoreUserid = null, closestTo = null)
{
	local bestBot = null;
	local bestDistance = 1000000;
	local bestQueue = 1000;
	foreach (id, bot in ::Left4Bots.Bots)
	{
		// If orderType = "witch", then the bot must also be holding a shotgun
		// If orderType = "lead" or "follow", then the bots can't have another order of that type in the queue
		if (bot.IsValid() && (!ignoreUserid || id != ignoreUserid) && (orderType != "witch" || (bot.GetActiveWeapon() && bot.GetActiveWeapon().GetClassname().find("shotgun") != null)) && ((orderType != "lead" && orderType != "follow") || !Left4Bots.BotHasOrderOfType(bot, orderType)))
		{
			local scope = bot.GetScriptScope();
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
	return bestBot;
}

// Starts an high priority MOVE command (mainly used for spit/charger dodging and such)
::Left4Bots.BotHighPriorityMove <- function (bot, destPos)
{
	if (!destPos || !Left4Bots.IsHandledBot(bot))
	{
		Left4Bots.Log(LOG_LEVEL_ERROR, "[AI]Can't execute High Priority MOVE; invalid bot/destination (bot: " + bot + " - destPos: " + destPos + ")");
		return false;
	}
	
	if (Left4Bots.SurvivorCantMove(bot))
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " can't execute High Priority MOVE now; bot can't move");
		return false;
	}
	
	local scope = bot.GetScriptScope();
	scope.MoveType = AI_MOVE_TYPE.HighPriority;
	scope.BotMoveTo(destPos, true);
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - High Priority MOVE -> " + destPos);
	
	return true;
}

// Tells the bot to throw his throwable item at destPos
::Left4Bots.BotThrow <- function (bot, destPos)
{
	if (!destPos || !Left4Bots.IsHandledBot(bot))
	{
		Left4Bots.Log(LOG_LEVEL_ERROR, "[AI]Can't throw; invalid bot/destination (bot: " + bot + " - destPos: " + destPos + ")");
		return false;
	}
	
	if (Left4Bots.SurvivorCantMove(bot))
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " can't throw now; bot can't move");
		return false;
	}
	
	local throwItem = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_THROW);
	if (!throwItem || !throwItem.IsValid())
	{
		Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " can't throw; no throw item in inventory");
		return false;
	}
	
	local scope = bot.GetScriptScope();
	scope.ThrowType = AI_THROW_TYPE.Manual;
	scope.ThrowTarget = destPos;
	scope.ThrowStartedOn = Time();
	
	// Need to disable the fire button until we are ready to throw (or throw is interrupted) otherwise the bot's vanilla AI can trigger the fire before our PressButton and the throw pos will be totally random
	NetProps.SetPropInt(self, "m_afButtonDisabled", NetProps.GetPropInt(self, "m_afButtonDisabled") | BUTTON_ATTACK);
	
	bot.SwitchToItem(throwItem.GetClassname());
	
	Left4Bots.Log(LOG_LEVEL_DEBUG, "[AI]" + bot.GetPlayerName() + " - Throw (" + throwItem.GetClassname() + ") -> " + destPos);
	
	return true;
}

//...
