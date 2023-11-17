# Changelog

## [v0.4.0-alpha](https://github.com/smilz0/Left4Bots/tree/v0.4.0-alpha) (2023-11-12)

[Full Changelog](https://github.com/smilz0/Left4Bots/compare/v0.3.0-alpha...v0.4.0-alpha)

**Implemented enhancements:**

- Aiming and other improvements + new setting: "manual\_attack\_always" [\#55](https://github.com/smilz0/Left4Bots/issues/55)
- New admin command: '!l4b findsettings \<string\>' [\#54](https://github.com/smilz0/Left4Bots/issues/54)
- New setting: 'thinkers\_think\_interval' and 'bot\_think\_interval' default = -1 [\#53](https://github.com/smilz0/Left4Bots/issues/53)
- New setting: 'moveto\_nav' [\#52](https://github.com/smilz0/Left4Bots/issues/52)
- New settings 'damage\_barricade' and 'damage\_other' [\#51](https://github.com/smilz0/Left4Bots/issues/51)
- New command: 'destroy' \(with smart use setting 'smart\_use\_destroy'\) [\#50](https://github.com/smilz0/Left4Bots/issues/50)
- Allow 2 different l4b commands for the same vocalizer line [\#48](https://github.com/smilz0/Left4Bots/issues/48)
- New command: !l4b help \[command\] [\#46](https://github.com/smilz0/Left4Bots/issues/46)
- give/swap weapons \(new settings: 'give\_bots\_weapons', 'userlevel\_give\_weapons'\) [\#45](https://github.com/smilz0/Left4Bots/issues/45)

**Fixed bugs:**

- Player replacing a 'wait' bot can't move [\#47](https://github.com/smilz0/Left4Bots/issues/47)

## [v0.3.0-alpha](https://github.com/smilz0/Left4Bots/tree/v0.3.0-alpha) (2023-10-09)

[Full Changelog](https://github.com/smilz0/Left4Bots/compare/v0.2.0-alpha...v0.3.0-alpha)

**Implemented enhancements:**

- Smart 'use' command \('smart\_use\_carry', 'smart\_use\_deploy', 'smart\_use\_scavenge' settings\) [\#44](https://github.com/smilz0/Left4Bots/issues/44)
- New setting: 'hurry\_time' [\#43](https://github.com/smilz0/Left4Bots/issues/43)
- Debug commands: 'pause' and 'dump' [\#42](https://github.com/smilz0/Left4Bots/issues/42)
- New command: 'hurry' [\#41](https://github.com/smilz0/Left4Bots/issues/41)
- New command: 'usereset' [\#40](https://github.com/smilz0/Left4Bots/issues/40)
- New command \('carry'\) to make the bots carry a carriable item [\#39](https://github.com/smilz0/Left4Bots/issues/39)
- 'deploy' order to pick up and deploy upgrade packs [\#38](https://github.com/smilz0/Left4Bots/issues/38)
- Manual scavenge via 'scavenge' command [\#37](https://github.com/smilz0/Left4Bots/issues/37)
- Configurable TraceLine mask \('tracemask\_pickups' and 'tracemask\_others' settings\) [\#35](https://github.com/smilz0/Left4Bots/issues/35)
- Old L4B1 setting: 'load\_convars' [\#33](https://github.com/smilz0/Left4Bots/issues/33)
- Old L4B1 feature: 'shoot\_rock' setting [\#32](https://github.com/smilz0/Left4Bots/issues/32)
- Improvements to the pickup and move algorithms [\#31](https://github.com/smilz0/Left4Bots/issues/31)
- SHOVE improvements [\#30](https://github.com/smilz0/Left4Bots/issues/30)
- Old L4B1 feature: 'smoker\_shoot\_tongue' and 'smoker\_shoot\_tongue\_duck' settings [\#28](https://github.com/smilz0/Left4Bots/issues/28)
- Workaround for vocalizer issue with 8+ survivor bots [\#27](https://github.com/smilz0/Left4Bots/issues/27)
- Add default settings override files for 'Advanced' and 'Expert difficulties' [\#25](https://github.com/smilz0/Left4Bots/issues/25)
- Old L4B1 feature: 'ontank\_settings.txt' and 'ontank\_convars.txt' files [\#23](https://github.com/smilz0/Left4Bots/issues/23)
- Add the game mode to the settings overrides file name [\#22](https://github.com/smilz0/Left4Bots/issues/22)
- Old L4B1 feature: 'throw' command [\#21](https://github.com/smilz0/Left4Bots/issues/21)
- New command: \<botsource\> move \(alias of \<botsource\> cancel all\) [\#17](https://github.com/smilz0/Left4Bots/issues/17)
- Add 'defib' switch to the 'cancel' command \(same as the old L4B1 'canceldefib' command\) [\#16](https://github.com/smilz0/Left4Bots/issues/16)
- Old L4B1 feature: 'die' command and 'die\_humans\_alive' setting [\#15](https://github.com/smilz0/Left4Bots/issues/15)
- Old L4B1 feature: 'deploy' command [\#14](https://github.com/smilz0/Left4Bots/issues/14)
- Old L4B1 feature: 'tempheal' command [\#13](https://github.com/smilz0/Left4Bots/issues/13)
- Old L4B1 feature: 'swap' command [\#12](https://github.com/smilz0/Left4Bots/issues/12)
- Old L4B1 feature: 'give' command [\#11](https://github.com/smilz0/Left4Bots/issues/11)

**Fixed bugs:**

- Bots don't keep the weapon they pickup via "use" order [\#36](https://github.com/smilz0/Left4Bots/issues/36)
- Settings overrides are saved to the settings.txt file after changing one setting via command [\#24](https://github.com/smilz0/Left4Bots/issues/24)
- Bots float when executing 'wait' order on elevators [\#2](https://github.com/smilz0/Left4Bots/issues/2)

**Merged pull requests:**

- Quickly updated Left4Bots.Log to use a switch statement. [\#26](https://github.com/smilz0/Left4Bots/pull/26) ([LeGurdah](https://github.com/LeGurdah))
- Attempted optimization on Left4Bots.InventoryManager, and \*slightly\* lowered tick interval of "L4BThinker" to 0.0666. [\#20](https://github.com/smilz0/Left4Bots/pull/20) ([LeGurdah](https://github.com/LeGurdah))
- Tiny optimization for a debug log early on in the OnGameEvent\_round\_start hook. [\#19](https://github.com/smilz0/Left4Bots/pull/19) ([LeGurdah](https://github.com/LeGurdah))
- Overhauled requirement check script, and simplified boolean return in ShouldAvoidItem [\#18](https://github.com/smilz0/Left4Bots/pull/18) ([LeGurdah](https://github.com/LeGurdah))

## [v0.2.0-alpha](https://github.com/smilz0/Left4Bots/tree/v0.2.0-alpha) (2023-08-27)

[Full Changelog](https://github.com/smilz0/Left4Bots/compare/v0.1-alpha...v0.2.0-alpha)

**Implemented enhancements:**

- Old L4B1 feature: signal system \(signal\_\*\) settings [\#10](https://github.com/smilz0/Left4Bots/issues/10)
- New setting 'orders\_no\_queue' [\#9](https://github.com/smilz0/Left4Bots/issues/9)
- Old L4B1 feature: 'trigger\_witch' setting [\#7](https://github.com/smilz0/Left4Bots/issues/7)
- Old L4B1 feature: 'trigger\_caralarm' setting [\#6](https://github.com/smilz0/Left4Bots/issues/6)
- Old L4B1 feature: 'spit\_damage\_multiplier' setting [\#5](https://github.com/smilz0/Left4Bots/issues/5)
- Old L4B1 feature: 'spit\_block\_nav' setting [\#4](https://github.com/smilz0/Left4Bots/issues/4)
- Old L4B1 feature: 'jockey\_redirect\_damage' setting [\#3](https://github.com/smilz0/Left4Bots/issues/3)

**Fixed bugs:**

- Settings not saved to file when changing them in-game [\#8](https://github.com/smilz0/Left4Bots/issues/8)

## [v0.1-alpha](https://github.com/smilz0/Left4Bots/tree/v0.1-alpha) (2023-08-21)

[Full Changelog](https://github.com/smilz0/Left4Bots/compare/4f29dd1c2a1d2a90c8d999a80ea50b041a6c1fd8...v0.1-alpha)

**Merged pull requests:**

- Update README.md [\#1](https://github.com/smilz0/Left4Bots/pull/1) ([smilz0](https://github.com/smilz0))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
