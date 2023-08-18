# Left 4 Bots 2 (Beta)
This is a complete rework of [Left 4 Bots (v1)](https://github.com/smilz0/Left4Bots/tree/V1). It has pretty much the same functionalities of the V1 but they have been improved, plus some new functionalities have been added.

***Please note: this is a beta version and it's unfinished. Some functionalies are still missing, likely it has bugs and needs some polishing.***

If you are uncomfortable with beta versions or you simply don't like this new version, you can stick with the [Left 4 Bots (v1)](https://steamcommunity.com/sharedfiles/filedetails/?id=2279814689).

***Also please note: the goal of Left 4 Bots has always been to make the survivor bots more human-like, not to turn them into super zombie killing machines.***

The addon gives them some functions that the vanilla AI was missing, like defib dead players, scavenge gascans, deadstop special intefected etc, so their combat capabilities are also improved but they can also fail and fu** things up, sometimes. But isn't this part of the human behavior? :stuck_out_tongue:


### What changed?
Almost everything. The bots are more active while executing the orders, they can attack and shove infected and scavenge items. The **lead** order has been completely reworked and it will work on most maps, including finales. Now you can order each bot to follow another survivor or to go and hold a certain position. And more.

For more details, please check the videos i made about L4B2 on my [Youtube Channel](https://www.youtube.com/channel/UCS5k0e5UJr_GklgCd1j89Yg).


### You want to make changes to the addon
and reupload it without my permission?

Consider this alternative instead:

Create a file named `left4bots_afterload.nut` and one named `left4bots_afterinit.nut` into the `script/vscript` directory and put only the L4B2 code you want to change in there.

`left4bots_afterload.nut` is automatically called by **L4B2** right after its .nut files are loaded and before the L4B2 settings are loaded and the addon fully initialized.

Here you can put the L4B2 functions you want to modify so your modified version will overwrite the base one.

For example if you want to change the logic to decide whether the bot is about to use meds, you simply add this function to the file with your own changes:

```nut
::Left4Bots.BotWillUseMeds <- function (bot)
{
	local totalHealth = bot.GetHealth() + bot.GetHealthBuffer();
	if (totalHealth >= 55) // <- look, i changed 45 to 55 because for me it's better
		return false;
	
	(...)
}
```

`left4bots_afterload.nut` is also called before the VScript `__CollectEventCallbacks`, so you can even alter the events here, like:

```nut
::Left4Bots.Events.OnGameEvent_round_start <- function (params)
```

and you can alter the **Left 4 Lib** functions as well, if you need to.

`left4bots_afterinit.nut` is called after the addon loaded the settings and finished its initialization. Here, for example, you can force your values to the addon settings (if you really need to):

```nut
Left4Bots.Settings.handle_l4d1_survivors = 1;
// ... and whatever you want to change
```

You don't need to add both the .nut files, only the one you use.

After you have done you can pack your addon and upload it to the workshop adding both **Left 4 Bots 2** and **Left 4 Lib** as required addons.

You are done.

The good of this is that you aren't creating conflicting addons, the final user will be able to switch between normal L4B2 and your version simply by enabling/disabling your addon in the addon list and (potentially) you won't need to update your addon every time i update mine.
