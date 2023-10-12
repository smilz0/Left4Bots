# L4B2 commands
The L4B commands can be sent via chat or via console.

If via console, the command must be prefixed with the `l4b` trigger.

Example:
```
scripted_user_func l4b,bots,lead
```

If via chat, the prefix is `!l4b`, but you can also omit the prefix entirely.

Example:
```
!l4b nick heal
nick heal
```

### Order commands

[L4B2 commands on YouTube](https://www.youtube.com/playlist?list=PLFEEMMIutAbsDQHsp6sMLiAo2l5682lqi).

The following commands are in this format: <_botsource_> <**command**> [_parameter_]

<_botsource_> can be:
- _bot_ (the bot is automatically selected)
- _bots_ (all the bots)
- _botname_ (name of the bot)

[_parameter_] is optional and depends on the command.

| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description |
| :-- | :-- |
| <_botsource_> **lead** | The order is added to the given bot(s) orders queue.<br />The bot(s) will start leading the way following the map's flow |
| <_botsource_> **follow** | The order is added to the given bot(s) orders queue.<br />The bot(s) will start following you |
| <_botsource_> **follow** <_target_> | The order is added to the given bot(s) orders queue.<br />The bot(s) will follow the given target survivor (you can also use the keyword "me" to follow you) |
| <_botsource_> **witch** | The order is added to the given bot(s) orders queue.<br />The bot(s) will try to kill the witch you are looking at |
| <_botsource_> **heal** | The order is added to the given bot(s) orders queue.<br />The bot(s) will heal himself/themselves |
| <_botsource_> **heal** <_target_> | The order is added to the given bot(s) orders queue.<br />The bot(s) will heal the target survivor (target can also be the bot himself or the keyword "me" to heal you) |
| <_botsource_> **goto** | The order is added to the given bot(s) orders queue.<br />The bot(s) will go to the location you are looking at |
| <_botsource_> **goto** <_target_> | The order is added to the given bot(s) orders queue.<br />The bot(s) will go to the current target's position (target can be another survivor or the keyword "me" to come to you) |
| <_botsource_> **come** | The order is added to the given bot(s) orders queue.<br />The bot(s) will come to your current location (alias of "<botsource> goto me") |
| <_botsource_> **wait** | The order is added to the given bot(s) orders queue.<br />The bot(s) will hold his/their current position |
| <_botsource_> **wait** _here_ | The order is added to the given bot(s) orders queue.<br />The bot(s) will hold position at your current position |
| <_botsource_> **wait** _there_ | The order is added to the given bot(s) orders queue.<br />The bot(s) will hold position at the location you are looking at |
| <_botsource_> **use** | The order is added to the given bot(s) orders queue.<br />The bot(s) will use the entity (pickup item / press button etc.) you are looking at |
| <_botsource_> **carry** | The order is added to the given bot(s) orders queue.<br />The bot(s) will pick and hold the carriable item (gnome, gascan, cola, etc.) you are looking at |
| <_botsource_> **deploy** | The order is added to the given bot(s) orders queue or executed immediately.<br />The bot(s) will go pick the deployable item (ammo upgrade packs) you are looking at and deploy it immediately.<br />If you aren't looking at any item and the bot already has a deployable item in his inventory, he will deploy that item immediately |
| <_botsource_> **usereset** | The order is executed immediately.<br />The bot(s) will stop using the weapons picked up via "use" order and will go back to its weapon preferences / team weapon rules |
| <_botsource_> **warp** | The order is executed immediately.<br />The bot(s) will teleport to your position |
| <_botsource_> **warp** _here_ | The order is executed immediately.<br />The bot(s) will teleport to your position |
| <_botsource_> **warp** _there_ | The order is executed immediately.<br />The bot(s) will teleport to the location you are looking at |
| <_botsource_> **warp** _move_ | The order is executed immediately.<br />The bot(s) will teleport to the current MOVE location (if any) |
| <_botsource_> **give** | The order is executed immediately.<br />The bot will give you one item from their pills/throwable/medkit inventory slot if your slot is emtpy.<br />"bot" and "bots" botsources are the same here, the first available bot is selected |
| <_botsource_> **swap** | The order is executed immediately.<br />You will swap the item you are holding (only for items from the pills/throwable/medkit inventory slots) with the selected bot.<br />"bot" and "bots" botsources will both select the bot you are looking at |
| <_botsource_> **tempheal** | The order is executed immediately.<br />The bot(s) will use their pain pils/adrenaline.<br />If "bot" botsource is used, the selected bot will be the bot you are looking at |
| <_botsource_> **throw** | The order is executed immediately.<br />The bot(s) will throw their throwable item to the location you are looking at |
| <_botsource_> **throw** <_itemtype_> | The order is executed immediately.<br />The bot(s) will throw their throwable item of type <_itemtype_> to the location you are looking at.<br />Example: "bot throw pipe", "bots throw molotov" |
| <_botsource_> **scavenge** | The order is added to the given bot(s) orders queue.<br />The bot(s) will scavenge the item you are looking at (gascan, cola bottles) if a pour target is active.<br />You can give this order to any bot, including the ones that aren't already scavenging automatically |
| <_botsource_> **scavenge** _start_ | Starts the scavenge process.<br />The botsource parameter is ignored, the scavenge bot(s) are always selected automatically |
| <_botsource_> **scavenge** _stop_ | Stops the scavenge process.<br />The botsource parameter is ignored, the scavenge bot(s) are always selected automatically |
| <_botsource_> **hurry** | The order is executed immediately.<br />The bot(s) L4B2 AI will stop doing anything for _'hurry_time'_ seconds.<br />Basically they will cancel any pending action/order and ignore pickups, defibs, throws etc. for that amount of time |
| <_botsource_> **die** | The order is executed immediately.<br />The bot(s) will die.<br />If "bot" botsource is used, the selected bot will be the bot you are looking at.<br />NOTE: only the admins can use this command |
| <_botsource_> **pause** | The order is executed immediately.<br />The bot(s) will be forced to start a pause.<br />If "bot" botsource is used, the selected bot will be the bot you are looking at.<br />NOTE: only the admins can use this command |
| <_botsource_> **dump** | The order is executed immediately.<br />The bot(s) will print all their L4B2 AI data to the console.<br />If "bot" botsource is used, the selected bot will be the bot you are looking at.<br />NOTE: only the admins can use this command |
| <_botsource_> **move** | Alias of "<botsource> cancel all" (see below) |


### Cancelling orders
To cancel all or some of the order use: <_botsource_> **cancel** [_switch_]

<_botsource_> can be:
- bots (all the bots)
- botname (name of the bot)

***"bot" botsource is not allowed here.***

[_switch_] is optional and can be:
| Switch | Description |
| :-- | :-- |
| _current_ | The given bot(s) will abort his/their current order and will proceed with the next one in the queue (if any) |
| _ordertype_ | The given bot(s) will abort all his/their orders (current and queued ones) of type _ordertype_<br />Example: `coach cancel lead` |
| _orders_ | The given bot(s) will abort all his/their orders (current and queued ones) of any type |
| _defib_ | The given bot(s) will abort any pending defib task.<br />"botname cancel defib" is temporary (the bot will retry).<br />"bots cancel defib" is permanent (currently dead survivors will be abandoned) |
| _all_ (or empty) | The given bot(s) will abort everything (orders, current pick-up, anything) |


### Orders queue
The orders that are added to the bot's queue are automatically executed according to their priorities:
| Order | Priority |
| :-- | :-- |
carry | 0 |
follow | 0 |
lead | 0 |
scavenge | 0 |
goto | 1 |
wait | 1 |
deploy | 2 |
heal | 2 |
use | 2 |
witch | 3 |

Orders with higher priority are executed first.

Orders with the same priority are executed with the same order as they have been received.

The next order in the queue is not executed until the current order is not finished or cancelled (Example: `coach cancel current`).


### Bot selection (for commands via vocalizer)
To select the bot for the command via vocalizer you can look at the bot and use the **"Look"** vocalizer line (like in L4B1). However that vocalizer line is very inconsistent, sometimes your character fails to call the bot and will say **"Weapons here"** or something else, depending on what is in your field of view.

So i added a command to simplify this process: **botselect** [_botname_]

_botname_ is the name of the bot you want to select. If you omit it, the addon will automatically select the bot closest to your crosshair.

The `!l4b` trigger is mandatory if you use this command via chat but you may want to use the console version instead and bind it to some key on the keyboard:
```
bind "KEY" "scripted_user_func l4b,botselect"
```


### Default vocalizer bindings
| Vocalizer line | Vocalizer command | L4B2 command |
| :-- | :-- | :-- |
Lead | PlayerLeadOn | bots lead |
Wait | PlayerWaitHere | bots wait |
GO | PlayerEmphaticGo | bots goto |
Witch | PlayerWarnWitch | bot witch |
Move | PlayerMoveOn | bot use |
Stay Together | PlayerStayTogether | bots cancel |
Follow me | PlayerFollowMe | bot follow me |
Suggest Heal | iMT_PlayerSuggestHealth | bots heal |
Ask health | AskForHealth2 | bot heal me |
I'm with you | PlayerImWithYou | bots scavenge start |
Hurry | PlayerHurryUp | bots hurry |
I'm here! | PlayerAnswerLostCall | bot give |
Hello | iMT_PlayerHello | bot swap |

You can change these bindings by editing the file `ems/left4bots2/cfg/vocalizer.txt`.

Each line in the file is in the format: <_vocalizer command_> = <_l4b2 command_>

<_l4b2 command_> must be the complete command as you type it chat (without the `!l4b` trigger) and for <_botsource_> you must choose between **bot** and **bots** (the **botname** version is automatically used by selecting the bot first).
