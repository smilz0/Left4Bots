// Interval of the main bot's Think function (default is 0.1 which means 10 fps)
const BOT_THINK_INTERVAL = 0.01; // Set the max i can get even though the think functions can go up to 30 fps (interval 0.0333) and the CTerrorPlayer entities limit their think functions to max 15 fps (0.06666)

// Interval of the logic that coordinates the scavenge process
const SCAVENGE_MANAGER_INTERVAL = 1;

// Approximate radius of a spitter's spit on the ground
const SPIT_RADIUS = 150;

// Min survivor bot's distance to a tank for throwing molotovs
const TANK_MOLOTOV_MIN = 200;

// Max survivor bot's distance to a tank for throwing molotovs
const TANK_MOLOTOV_MAX = 1000;

// Minimum distance between the tank and the other survivors before throwing a molotov to a tank
const MOLOTOV_SURVIVORS_MINDISTANCE = 200;

// Delta pitch when throwing molotovs at tanks ( <0: higher, >0: lower )
const TANK_MOLOTOV_DELTAPITCH = 2;

// A survivor bot who is running to the rescue vehicle has this chance of throwing a pipe bomb or a bile jar
const THROW_NADE_CHANCE = 25;

// Try to throw pipe bombs and bile jars this far (must be > of THROW_NADE_MIN_DISTANCE)
const THROW_NADE_RADIUS = 500;

// Try to throw pipe bombs and bile jars AT LEAST this far or don't throw
const THROW_NADE_MIN_DISTANCE = 250;

// Delta pitch when throwing pipe bombs and bile jars ( <0: higher, >0: lower )
const THROW_NADE_DELTAPITCH = -6;

// If a survivor already threw a pipe bomb or bile jar, don't throw another one before this time
const THROW_NADE_MININTERVAL = 10;

// Survivor bots won't throw a pipe bomb or bile jar before reviving an incapped friend if there are at least this number of other non-incapped alive survivors
// within THROW_NADE_ONREVIVE_COVER_RADIUS units from the bot who is doing the revive
const THROW_NADE_ONREVIVE_COVER_COUNT = 2;

// Survivor bots won't throw a pipe bomb or bile jar before reviving an incapped friend if there are at least THROW_NADE_ONREVIVE_COVER_COUNT other non-incapped alive survivors
// within this distance from the bot who is doing the revive
const THROW_NADE_ONREVIVE_COVER_RADIUS = 300;

// When a survivor is being overwhelmed, survivor bots within this radius will try to help by throwing their pipe bomb / bile jar
const THROW_NADE_HELP_RADIUS = 400;

// If a survivor already threw a molotov, don't throw another one before this time
const THROW_MOLOTOV_MININTERVAL = 4;

// Survivor bot's max scan range for items to pickup
const BOT_GOTOPICKUP_RANGE = 300;

// Survivor bots will automatically pickup items within this range
const BOT_PICKUP_RANGE = 120; // when Settings.pickup_animation = 0
const BOT_PICKUP_RANGE2 = 120; // when Settings.pickup_animation = 1

// Survivor bot's max scan range for dead survivors to defib
const BOT_GOTODEFIB_RANGE = 1000;

// Max altitude difference between the bot and the dead survivor when scanning for dead survivors to defib
const BOT_GOTODEFIB_MAX_ALTDIFF = 320;

// When survivor bots find a dead survivor to defib but they don't have a defib, they will consider picking up and use defibs within this radius from the dead survivor
const NEARBY_DEFIB_RADIUS = 250;

// Survivor bot who is traveling to a destination entity will set their travel complete when within this radius from the destination entity's origin
const BOT_GOTO_END_RADIUS = 80;

// Survivor bot who is traveling to a scavenge pouring target (cars etc..) will set their travel complete when within this radius from the target entity's origin
const BOT_GOTO_POUR_RADIUS = 80;

// How long do the bots hold down a button to do single tap button press
const BUTTON_HOLDTIME_TAP = 0.1;

// How long do the bots hold down the button to heal
const BUTTON_HOLDTIME_HEAL = 5.3;

// How long do the bots hold down the button to defib a dead survivor
const BUTTON_HOLDTIME_DEFIB = 3.2;

// How long do the bots hold down the button to pour gascans / cola bottles
const BUTTON_HOLDTIME_POUR = 2.2;

// How long do the bots hold down the button to start generators
const BUTTON_HOLDTIME_GENERATOR = 5.3;

// If "scavenge_pour" setting is "0", scavenging survivor bots will drop gascans and cola bottles within this radius from the pour target
const SCAVENGE_DROP_RADIUS = 200;

// When giving manual orders to the survivor bots, this is the max time to set the order's target after you called the bot
const MANUAL_ORDER_MAXTIME = 3;

// When going for witch crown, shoot only when within this distance from her
const WITCH_CROWN_RADIUS = 50;

// When shoving common infected during scavenge, this is the delta pitch from the common's origin (feet)
const SHOVE_COMMON_DELTAPITCH = -6;

// When ordering the bots to hold position the cvar sb_enforce_proximity_range is temporarily set to this number to avoid that the bots teleport to you
const PROXIMITY_RANGE_MAX = 20000;

// Survivor bots will retreat from the tank if their distance from the tank is below this
const RETREAT_FROM_TANK_DINSTANCE = 150;

// Don't send the ATTACK command to the bot to attack an SI who is pinning a teammate if the distance to the SI is less than this
const ATTACK_SI_MIN_DISTANCE = 40;

// Don't send the ATTACK command to the bot to attack an SI who is pinning a teammate if the distance to the SI is greater than this
const ATTACK_SI_MAX_DISTANCE = 1000;

// Sound scripts to play when a survivor gives an item to another survivor
const SOUND_BIGREWARD = "Hint.BigReward"; // UI/BigReward.wav	(played on the giver)
const SOUND_LITTLEREWARD = "Hint.LittleReward"; // UI/LittleReward.wav (Played on all the players except the giver)

printl("[L4B] const.nut included");
