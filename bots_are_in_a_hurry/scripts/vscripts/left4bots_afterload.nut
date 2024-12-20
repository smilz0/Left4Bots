::Left4Bots.BotShouldStartPause <- function (bot, userid, orig, isstuck, isHealOrder = false, isLeadOrder = false, maxSeparation = 0)
{
	//return false;
	return (bot.IsValid() && (bot.IsIncapacitated() || bot.IsDominatedBySpecialInfected()))
}

::Left4Bots.BotShouldStopPause <- function (bot, userid, orig, isstuck, isHealOrder = false, isLeadOrder = false, maxSeparation = 0)
{
	//return true;
	return !(bot.IsValid() && (bot.IsIncapacitated() || bot.IsDominatedBySpecialInfected()))
}

::Left4Bots.AIFuncs.BotThink_Misc <- function ()
{
	if (!L4B.FinalVehicleArrived && L4B.Settings.tank_retreat_radius > 0)
	{
		local r = (MovePos && Paused == 0) ? 150 : L4B.Settings.tank_retreat_radius;
		local nearestTank = L4B.GetNearestAggroedVisibleTankWithin(self, Origin, 0, r);
		if (nearestTank)
			Left4Utils.BotCmdRetreat(self, nearestTank);
	}
	
	// Handling car alarms
	if (L4B.Settings.trigger_caralarm)
	{
		local groundEnt = NetProps.GetPropEntity(self, "m_hGroundEntity");
		if (groundEnt && groundEnt.IsValid() && groundEnt.GetClassname() == "prop_car_alarm")
			L4B.TriggerCarAlarm(self, groundEnt);
	}
	
	if (MovePos && Paused == 0 && L4B.BotWillUseMeds(self))
	{
		local item = ::Left4Utils.GetInventoryItemInSlot(self, INV_SLOT_PILLS);
		if (item && item.IsValid())
		{
			if (!L4B.BotHasAutoOrder(self, "tempheal", null))
				L4B.BotOrderAdd(self, "tempheal", null, null, null, null, 0, false);
		}
		else if (::Left4Utils.HasMedkit(self))
		{
			if (!L4B.BotHasAutoOrder(self, "heal", self))
				L4B.BotOrderAdd(self, "heal", null, self, null, null, 0, false);
		}
	}
	
	//lxc Move from BotThink_Main to here, almost no difference about kill infected, and it can also save performance
	BotManualAttack();
	
	//lxc lock func
	BotLockShoot();
}
