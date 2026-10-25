#using scripts\core_common\flag_shared.gsc;
#using scripts\core_common\values_shared.gsc;
#using scripts\core_common\callbacks_shared.gsc;
#using scripts\core_common\hud_shared.gsc;
#using scripts\zm_common\zm_utility.gsc;
#using scripts\core_common\array_shared.gsc;
#using scripts\core_common\math_shared.gsc;
#using scripts\core_common\item_drop.gsc;
#using scripts\core_common\trigger_shared.gsc;
#using scripts\zm_common\zm_audio.gsc;

#namespace zombie_snacks;

/*[[[SETTINGS]]]
CHECKBOX per_player_food "Food for All" default=false help="Food that is dropped can be picked up by everyone, instead of only one."
CHECKBOX hunger_replaces_health "Hunger Replaces Health" default=false help="Use a Hunger stat instead of using your Health. Numbers will still be the same but this will be less annoying on the visuals."
CHOICE   drop_look  "Drop Type" options="Normal,Realistic" default="Normal" help="Determine how the food will drop. Normal will be high in the air for visibility while Realistic keeps it close to the floor."
CHECKBOX no_critical "No Critical" default=false help="If Enabled, the player will go down instead of staying at Critical health."

CHECKBOX enable_flowstate "Enable Flowstate" default=true help="Toggle the Flowstate mechanic. When players reach a certain amount of kills they get insta kill active. When they get hit, they lose Flowstate." category="Flowstate"
SLIDER flowstate_kills   "Kills to Activate"   min=1 max=100 default=10 help="Amount of kills in a row needed to activate Flowstate." category="Flowstate"
CHECKBOX hit_always_resets "Hit Always Resets Killstreak" default=true help="If taking damage by a zombie always resets your killstreak count. If disabled, streak persist untill you lose Flowstate." category="Flowstate"
CHECKBOX flowstate_pauses_hunger "Flowstate Stops Hunger" default=false help="While Flowstate is active, the player will not lose health/hunger." category="Flowstate"

SLIDER drop_chance   "Food Drop Chance"   min=1 max=100 default=60 help="Chance that food drops." category="Specifics"
SLIDER second_per_hunger   "Seconds per Loss"   min=0.1 max=180.0 default=2.0 help="How long, in seconds, that health (or hunger if Hunger Replace Health is enabled) per second." category="Specifics"
SLIDER hunger_per_second   "Loss per X seconds"   min=1 max=100 default=1 help="How much damage (or hunger if Hunger Replace Health is enabled) to lose." category="Specifics"

[[[/SETTINGS]]]*/

/*[[[PRESETS]]]
PRESET "Default" default help="The way the mod is meant to be played."
    per_player_food = false
    hunger_replaces_health = false
    drop_look = "Normal"
    no_critical = false
    
    enable_flowstate = true
    flowstate_kills = 10
    hit_always_resets = true
    flowstate_pauses_hunger = false
    
    drop_chance = 60
    second_per_hunger = 2.0
    hunger_per_second = 1

PRESET "Casual" help="For a casual experience."
    per_player_food = false
    hunger_replaces_health = false
    drop_look = "Normal"
    no_critical = false
    
    enable_flowstate = true
    flowstate_kills = 10
    hit_always_resets = false
    flowstate_pauses_hunger = true
    
    drop_chance = 80
    second_per_hunger = 2.0
    hunger_per_second = 1

PRESET "Chaotic" help="For a crazy experience."
    per_player_food = false
    hunger_replaces_health = false
    drop_look = "Normal"
    no_critical = false
    
    enable_flowstate = true
    flowstate_kills = 3
    hit_always_resets = false
    flowstate_pauses_hunger = true
    
    drop_chance = 80
    second_per_hunger = 0.5
    hunger_per_second = 1

PRESET "Realism" help="For the realists"
    per_player_food = false
    hunger_replaces_health = false
    drop_look = "Realistic"
    no_critical = true
    
    enable_flowstate = false
    flowstate_kills = 10
    hit_always_resets = false
    flowstate_pauses_hunger = true
    
    drop_chance = 60
    second_per_hunger = 1.0
    hunger_per_second = 1
[[[/PRESETS]]]*/
  
function autoexec main()
{
    level.food_items = [#"p9_zm_food_variety_chips_bag",#"p9_zm_food_variety_poutine",#"p9_zm_food_variety_can",#"p9_zm_food_variety_cookie",#"p9_zm_food_variety_pizza_pepperoni_full",#"p9_zm_food_variety_cheese_wedge",#"p9_zm_food_variety_hamburger",#"p9_zm_food_variety_pizza_slice",#"p9_zm_food_variety_cauliflower",#"p9_zm_food_variety_bowl_soup",#"p9_zm_food_variety_banana_group",#"p9_zm_food_variety_pastry"];
    level thread main_thread();
    level flag::wait_till(#"start_zombie_round_logic");
    callback::on_ai_killed(&drop_food);
}

function private main_thread()
{
    level flag::wait_till(#"intro_scene_done");
    ArrayRemoveValue(level.zombie_powerup_array,"insta_kill");
    level.check_for_instakill_override = &check_player_flowstate;
    level.hunger_loss = [[[hunger_per_second]]];
    level.seconds_per_hunger = [[[second_per_hunger]]];
    foreach ( player in getplayers() )
    {
        player thread player_things();
    }
    callback::on_connect( &player_things );
}

function player_things()
{
    if(!is_true([[[hunger_replaces_health]]]))
    {
        self.var_4d9b2bc3 = 0;
    }
    self.hunger = self.var_66cb03ad;
    self.dont_lose_hunger = false;
    self thread slowly_damage_player();
    if([[[enable_flowstate]]])
    {
        self thread player_zombie_kill_counter();
        self thread player_lose_flowstate();
    }
}

function slowly_damage_player()
{
    self endon ("disconnect");
    level endon ("end_game");
    for(;;)
    {
        wait level.seconds_per_hunger;
        if(!self.dont_lose_hunger)
        {
            if([[[hunger_replaces_health]]])
            {
                self.hunger -= 1;
                self iprintln("^3Hunger: ^7" + self.hunger);
                self starve_player();
            }
            else
            {
                if(self.health > level.hunger_loss)
                {
                    self.health -= level.hunger_loss;
                }
                else
                {
                    if(is_true([[[no_critical]]]))
                    {
                        self dodamage( level.hunger_loss, self.origin);
                    }
                    else
                    {
                        self.health = 1;
                    }
                }
            }
        }
    }
}

function drop_food(s_params)
{
    if(!isdefined(self)) 
    {
        return;
    }
    if(!self.completed_emerging_into_playable_area)
    {
        return;
    }
    
    if(self.zm_ai_category === #"special")
    {
        chance = [[[drop_chance]]];
        heal_amount = 100;
    }
    else if(self.zm_ai_category === #"elite")
    {
        chance = [[[drop_chance]]];
        heal_amount = 200;
    }
    else
    {
        chance = randomintrange(0,100);
        heal_amount = randomintrange(25,50);
    }
    
    if(chance > [[[drop_chance]]])
    {
        return;
    }

//    org = self.origin + (0, 0, 8);
    if([[[drop_look]]] == "Realistic")
    {
        org = self.origin + (0, 0, 24);
    }
    else
    {
        org = self.origin + (0, 0, 36);   
    }
    ang = self.angles;

    model = spawn( "script_model", org );
    model setmodel( array::random(level.food_items) );
    model.angles = ang;
    trigger = spawn("trigger_radius", org, 0, 8, 8);
    trigger.angles = ang;
    model thread food_think(trigger, heal_amount);
    model thread food_expire(trigger);
    if([[[drop_look]]] == "Normal")
    {
        model thread food_wobble();
    }
}

function food_wobble()
{
    while ( isdefined( self ) )
    {
        waittime = randomfloatrange( 2.5, 5 );
        yaw = randomint( 360 );
        
        if ( yaw > 300 )
        {
            yaw = 300;
        }
        else if ( yaw < 60 )
        {
            yaw = 60;
        }
        
        yaw = self.angles[ 1 ] + yaw;
        new_angles = ( -60 + randomint( 120 ), yaw, -45 + randomint( 90 ) );
        self rotateto( new_angles, waittime, waittime * 0.5, waittime * 0.5 );
        
        if ( isdefined( self.worldgundw ) )
        {
            self.worldgundw rotateto( new_angles, waittime, waittime * 0.5, waittime * 0.5 );
        }
        
        wait randomfloat( waittime - 0.1 );
    }
}

//waitresult = entity waittill ("trigger") method wasnt working so doing plan B
function food_think(trigger, heal_amount)
{
   self endon ("death");
   self.interacted_players = [];
   for(;;)
   {
       foreach(player in getplayers())
       {
           if(player isTouching(trigger))
           {
               
               if([[[per_player_food]]])
               {
                   if(!isinarray(player, self.interacted_players))
                   {
                       self.interacted_players[self.interacted_players.size] = player;
                       self hidefromplayer(player);
                       player heal_player(heal_amount);
                       player zm_audio::playerexert( "burp" );
                       if(level.players.size == self.interacted_players.size)
                       {
                           trigger delete();
                           self delete();
                       }
                   }
               }
               else
               {
                   player heal_player(heal_amount);
                   player zm_audio::playerexert( "burp" );
                   trigger delete();
                   self delete();
               }
           }
       }
       wait 0.1;
   } 
}

function heal_player(amount)
{
    if([[[hunger_replaces_health]]])
    {
        if(self.hunger <= self.var_66cb03ad - amount)
        {
            self.hunger += amount;
        }
        else
        {
            self.hunger = self.var_66cb03ad;
        }
        self iprintln("^3Hunger: ^7" + self.hunger);
    }
    else
    {
        if(self.health <= self.var_66cb03ad - amount)
        {
            self.health += amount;
        }
        else
        {
            self.health = self.var_66cb03ad;
        }
    }
}

function starve_player()
{
    self.var_4d9b2bc3 = 0;
    while(self.hunger == 0)
    {
        self dodamage( level.hunger_loss, self.origin);
        wait 5;
    }
    self.var_4d9b2bc3 = 1;
}

function food_expire(trigger)
{
    wait 20;
    trigger delete();
    self delete();
}

function player_zombie_kill_counter()
{
    self.zombie_kill_streak = 0;
    self.is_in_flowstate = false;
    while(true)
    {
        result = self waittill ("zom_kill");
        zomb = result.zombie;
        self.zombie_kill_streak += 1;
        if(self.is_in_flowstate != true)
        {
            if(self.zombie_kill_streak >= 15)
            {
                self change_flowstate(true);
            }            
        }
    }
}

function change_flowstate(active)
{
    if(is_true(active))
    {
        //insert rampage start sound, I cant fucking find it
        self iprintlnbold("FLOWSTATE ACTIVE!");
        self.is_in_flowstate = true;
        if([[[flowstate_pauses_hunger]]])
        {
            self.dont_lose_hunger = true;
        }
    }
    else
    {
        //insert rampage end sound, I still cant fucking find it
        self iprintlnbold("FLOWSTATE LOST!");
        self.is_in_flowstate = false;
        self.zombie_kill_streak = 0;
        self.dont_lose_hunger = false;
    }
}

function player_lose_flowstate()
{
    while ( true )
    {
        waitresult = self waittill( #"damage" );
        attacker = waitresult.attacker;
        if ( isdefined( attacker.archetype ) && attacker.archetype == #"zombie" )
        {
            if([[[hit_always_resets]]])
            {
                self.zombie_kill_streak = 0;   
            }
            if(is_true(self.is_in_flowstate))
            {
                self change_flowstate(false);
            }
        }
    }
}

function check_player_flowstate(player)
{
	if(player.is_in_flowstate || level.zombie_vars[player.team]["zombie_insta_kill"] == 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}