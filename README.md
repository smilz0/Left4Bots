# Left 4 Bots 2 (Alpha)
This is a complete rework of [Left 4 Bots (v1)](https://github.com/smilz0/Left4Bots/tree/V1). It has pretty much the same functionalities of the V1 but they have been improved, plus some new functionalities have been added.

***Please note: this is an alpha version which is still in development. A few of new functionalities and some of the old ones are not implemented yet and it likely has bugs.***

If you are uncomfortable with development versions or you simply don't like this new version, you can stick with the [Left 4 Bots (v1)](https://steamcommunity.com/sharedfiles/filedetails/?id=2279814689).

***Also please note: the goal of Left 4 Bots has always been to make the survivor bots more human-like, not to turn them into super zombie killing machines.***

The addon gives them some functions that the vanilla AI was missing, like defib dead players, scavenge gascans, deadstop special intefected etc, so their combat capabilities are also improved but they can also fail and fu** things up, sometimes. But isn't this part of the human behavior? :stuck_out_tongue:

Despite the use of the term **AI** there is no real AI/machine learning algorithm, it's just a bunch of `if then else`, so do not expect them to start learning and eventually become self-conscious and do things on their own acting perfectly in every situation.


### What changed?
Almost everything. The bots are more active while executing the orders, they can attack and shove infected and scavenge items. The **lead** order has been completely reworked and it will work on most maps, including finales. Now you can order each bot to follow another survivor or to go and hold a certain position. Bots have weapon preferences you can change. And more.

For more details, please check the videos i made about L4B2 on my [Youtube Channel](https://www.youtube.com/channel/UCS5k0e5UJr_GklgCd1j89Yg).


### Addon settings
The list of L4B2 settings can be found [HERE](https://github.com/smilz0/Left4Bots/blob/main/root/scripts/vscripts/left4bots_settings.nut).

You can change the settings by editing the file `ems/left4bots2/cfg/settings.txt` or directly ingame with the following commands:
- Via chat: `!l4b settings [setting] [value]`
- Via console: `scripted_user_func l4b,settings,[setting],[value]`


### Addon commands
The list of L4B2 commands can be found [HERE](https://github.com/smilz0/Left4Bots/blob/main/COMMANDS.md).


### Want to customize the addon even further
and you know a bit about VScript?

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

and you can alter the [Left 4 Lib](https://github.com/smilz0/Left4Lib) functions as well, if you need to.

`left4bots_afterinit.nut` is called after the addon loaded the settings and finished its initialization. Here, for example, you can force your values to the addon settings:

```nut
Left4Bots.Settings.handle_l4d1_survivors = 1;
// ... or do whatever you want to do after the addon initialization
```

You aren't forced to add both the .nut files, only the one you use.

Now, if you want, you can pack your .nut files and upload your addon to the workshop adding both **Left 4 Bots 2** and **Left 4 Lib** as required addons.

This is better than duplicating the L4B2 files into your addon because this way you aren't creating conflicting addons, the end user will be able to switch between normal L4B2 and your version simply by enabling/disabling your addon in the addon list and (potentially) you won't need to update your addon every time i update mine.
