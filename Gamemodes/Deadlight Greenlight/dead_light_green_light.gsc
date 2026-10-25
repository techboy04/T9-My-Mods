#using scripts\core_common\flag_shared.gsc;
#using scripts\core_common\values_shared.gsc;
#using scripts\core_common\callbacks_shared.gsc;
#using scripts\core_common\hud_shared.gsc;
#using scripts\core_common\ai\zombie_utility.gsc;
#using scripts\zm_common\zm_utility.gsc;
#using scripts\core_common\array_shared.gsc;
#using scripts\core_common\struct.gsc;
#using scripts\core_common\healthoverlay.gsc;
#using scripts\core_common\perks.gsc;
#using scripts\core_common\content_manager.gsc;
#using scripts\zm_common\zm_perks.gsc;
#using scripts\zm_common\zm_laststand.gsc;
#using scripts\zm_common\zm_armor.gsc;
#using scripts\zm_common\zm_fasttravel.gsc;
#using scripts\zm_common\zm_zonemgr.gsc;
#using scripts\zm_common\zm_player.gsc;
#using scripts\zm_common\gametypes\zm_gametype.gsc;
#using scripts\core_common\util_shared.gsc;
#using scripts\core_common\scene_shared.gsc;
#using script_3751b21462a54a7d.gsc;


#namespace deadlight_greenlight;

/*[[[SETTINGS]]]
SLIDER grace_period   "Grace Period before game starts."   min=0 max=60 default=5 help="How long it takes for the mode to actually start."
SLIDER initial_green_light_length "Initial Green Light Length (in seconds)" min=10 max=450 default=90 help="How long the first Green Light will last."
CHECKBOX allow_point_loss_on_move "Do Point Drain" default=true help="Whether to make the player lose points when they move on redlight. This triggers before the player loses health."
SLIDER points_amount "Points Drain Amount" min=1 max=10000 default=100 help="How much points that the player will lose per second."
CHECKBOX allow_damage_on_move "Do Health Drain" default=true help="Whether to damage the player when they move on a redlight. This will only occur if Point Loss is disabled or the players points reached zero."
CHECKBOX remove_round_delay "Remove Round Delay" default=false help="Remove the delay in between rounds."
SLIDER damage_amount "Damage Drain Amount" min=1 max=250 default=15 help="How much damage that the player will take per second."
CHECKBOX enable_child_laugh "Enable the Child laugh sound" default=true help="Toggle the Child laugh sound when the player is caught moving."

CHECKBOX punishment_critical "Critical Health" default=true help="Players health will be forced to low health." category="Punishments"
CHECKBOX punishment_strip_ammo "Strip Ammo" default=true help="The ammo of the players current weapon will be stripped." category="Punishments"
CHECKBOX punishment_deplete_armor "Deplete Armor" default=true help="Armor will be destroyed instantly." category="Punishments"
CHECKBOX punishment_slowness "Slow Movement" default=true help="Slow down player movement." category="Punishments"
CHECKBOX punishment_blur "Blurry Vision" default=true help="Your vision is pretty blurry." category="Punishments"
CHECKBOX punishment_rtp "Random Teleport" default=true help="You randomly get teleported." category="Punishments"
CHECKBOX punishment_lose_random_perk "Lose Random Perk" default=true help="You randomly lose a perk." category="Punishments"
[[[/SETTINGS]]]*/


/*[[[PRESETS]]]
PRESET "Default" default help="The way the mod is meant to be played."
    grace_period = 5
    initial_green_light_length = 90
    allow_point_loss_on_move = true
    allow_damage_on_move = true
    points_amount = 100
    damage_amount = 15
    remove_round_delay = false

    punishment_critical = true
    punishment_strip_ammo = true
    punishment_deplete_armor = true
    punishment_slowness = true
    punishment_blur = true
    punishment_rtp = true
    punishment_lose_random_perk = true

PRESET "Bo6 Rules" help="Settings based off the official Bo6 LTM"
    grace_period = 5
    initial_green_light_length = 90
    allow_point_loss_on_move = true
    allow_damage_on_move = true
    points_amount = 100
    damage_amount = 15
    remove_round_delay = true

    punishment_critical = false
    punishment_strip_ammo = false
    punishment_deplete_armor = false
    punishment_slowness = false
    punishment_blur = false
    punishment_rtp = false
    punishment_lose_random_perk = false

PRESET "Challenging" help="Settings made to be difficult."
    grace_period = 5
    initial_green_light_length = 20
    allow_point_loss_on_move = true
    allow_damage_on_move = true
    points_amount = 1000
    damage_amount = 50
    remove_round_delay = true

    punishment_critical = true
    punishment_strip_ammo = true
    punishment_deplete_armor = true
    punishment_slowness = true
    punishment_blur = true
    punishment_rtp = true
    punishment_lose_random_perk = true
[[[/PRESETS]]]*/

function autoexec main()
{
    level thread main_thread();
    level.lightid = 0;
    ArrayRemoveValue(level.zombie_powerup_array,"double_points");
    level.var_9c55db3 = &on_zombie_spawned;
    if(is_true([[[remove_round_delay]]]))
    {
        level.func_get_delay_between_rounds = &round_time_removal;   
    }
    level.grace_period = [[[grace_period]]];
    level.initial_greenlight_length = [[[initial_green_light_length]]];

    level.punishment_list = [];
        
    if([[[punishment_critical]]])
    {
        level.punishment_list[level.punishment_list.size] = "critical_health";
    }
    if([[[punishment_strip_ammo]]])
    {
        level.punishment_list[level.punishment_list.size] = "strip_ammo";
    }
    if([[[punishment_deplete_armor]]])
    {
        level.punishment_list[level.punishment_list.size] = "shield_deplete";
    }
    if([[[punishment_slowness]]])
    {
        level.punishment_list[level.punishment_list.size] = "slowness";
    }
    if([[[punishment_blur]]])
    {
        level.punishment_list[level.punishment_list.size] = "blur";    
    }
    if([[[punishment_lose_random_perk]]])
    {
        level.punishment_list[level.punishment_list.size] = "lose_random_perk";    
    }
    if([[[punishment_rtp]]])
    {
        if ( util::get_game_type() != #"zonslaught" )
        {
            level.punishment_list[level.punishment_list.size] = "random_teleport";   
        }
    }
}

function round_time_removal()
{
    return 0.1;
}

function on_zombie_spawned()
{
    self endon ("death");
	while(!isdefined(self.completed_emerging_into_playable_area ))
	{
		wait 0.1;
	}
	while(!self.completed_emerging_into_playable_area)
	{
		wait 0.1;
	}
    for(;;)
    {
        if(level.lightid == 2)
        {
            self zombie_utility::set_zombie_run_cycle_override_value( "super_sprint" );
        }
        else
        {
            self zombie_utility::set_zombie_run_cycle_restore_from_override();
        }
        level waittill ("light_change");
        wait 1;
    }
}

function private main_thread()
{
    // Prints before the intro scene finishes are never seen.
    level flag::wait_till(#"intro_scene_done");
    level flag::wait_till( "start_zombie_round_logic" );
    foreach ( player in getplayers() )
    {
        player thread player_things();
    }
    level.enable_point_loss_on_move = [[[allow_point_loss_on_move]]];
    level.enable_damage_on_move = [[[allow_damage_on_move]]];
    callback::on_connect( &player_things );
    wait level.grace_period;
    self.beingpunished = 0;
    level thread light_segment();
    level thread force_green_light_on_exfil();
}

function player_things()
{
    self thread movement_check();
    self thread watch_for_movement();
    self thread play_creepy_laugh();
}

function movement_check()
{
    level endon ("end_game");
    self endon ("disconnect");
    self.isinmotion = 0;
    old_location = self.origin;
    new_location = self.origin;
    for(;;)
    {
        if(distance( old_location, self.origin ) > 2)
		{
			self.isinmotion = 1;
		}
		else
		{
			self.isinmotion = 0;
		}
		old_location = new_location;
		wait 0.1;
		new_location = self.origin;
    }
}

function watch_for_movement()
{
    level endon ("end_game");
    self endon ("disconnect");
    old_motion = 0;
    for(;;)
    {
        if(self.isinmotion != old_motion)
        {
            old_motion = self.isinmotion;
        }
        wait 0.1;
    }
}

function light_segment()
{
    level endon ("end_game");
    level endon ("stop_segment");
    level.deadlightchance = 0;
    change_light(0);
    wait level.initial_greenlight_length;
    for(;;)
    {
        chance = randomintrange(5,8);
        if(chance <= level.deadlightchance)
        {
            change_light(2);
            level.deadlightchance = randomintrange(-5,0);
            wait randomintrange(20,40);
        }
        else
        {
            level.deadlightchance += 1;
            change_light(1);
            wait randomintrange(20, 40);
        }   
        change_light(0);
        wait randomintrange(20,60);
    }
}

function change_light(id)
{
    level notify ("light_change");
    level.lightid = id;
    foreach(player in GetPlayers())
    {
        player playlocalsound(#"hash_52de50e5184d1c7"); 
        if(id == 0)
        {
	       player setblur( 0, 0.1 );
        }   
    }
    
    if(id == 1)
    {
        IPrintLnBold("^1RED LIGHT");
        zombie_utility::set_zombie_var_team( #"zombie_point_scalar", getPlayers()[0].team, 0 );
        foreach(player in GetPlayers())
        {
            player thread player_caught_moving();
        }
    }
    else if(id == 0)
    {
        IPrintLnBold("^2GREEN LIGHT");
        zombie_utility::set_zombie_var_team( #"zombie_point_scalar", getPlayers()[0].team, 2 );
    }
    else if(id == 2)
    {
        IPrintLnBold("^4DEAD LIGHT");
        zombie_utility::set_zombie_var_team( #"zombie_point_scalar", getPlayers()[0].team, 1 );
        a_ai_enemies = getaiteamarray( level.zombie_team );
        foreach(ai in a_ai_enemies)
        {
            ai zombie_utility::set_zombie_run_cycle_override_value( "super_super_sprint" );
        }
    }
}

function player_caught_moving()
{
    level endon ("end_game");
    self endon ("disconnect");
    level endon ("light_change");
    self.beingpunished = 0;
    wait 2;
    for(;;)
    {
        while(self scene::is_igc_active())
        {
            wait 0.1;
        }
       
       if(self.ignore_redlight != true && self.isinmotion == 1 && !isdefined(self.revivetrigger))
       {
           if(level.enable_point_loss_on_move == 1)
           {
               self.score -= [[[points_amount]]];
           }
           if(level.enable_point_loss_on_move == 1)
           {
               if(self.score == 0 && level.enable_damage_on_move == 1)
               {
                   self dodamage( [[[damage_amount]]], self.origin); 
               }
           }
           else
           {
               if(level.enable_damage_on_move == 1)
               {
                   self dodamage( [[[damage_amount]]], self.origin);
               }
           }
           self notify ("do_laugh");
           if(isDefined(self.beingpunished) && self.beingpunished != 1)
           {
               self thread do_punishment();
               self.beingpunished = 1;
           }
       }
       wait 1;
    }
}

function play_creepy_laugh()
{
    level endon ("end_game");
    self endon ("disconnect");
    for(;;)
    {
        self waittill("do_laugh");
        if ([[[enable_child_laugh]]])
        {
            self playlocalsound(#"hash_7d764f09cd3dea92");   
        }
        wait 10;
    }
}

function do_punishment()
{
    if(level.punishment_list[level.punishment_list.size] == 0)
    {
        return;
    }
    
    if(self scene::is_igc_active())
    {
        return;
    }
    
    chosen_punishment = array::random(level.punishment_list);
    if(chosen_punishment == "critical_health")
    {
        self thread critical_health();
        punishment_str = "Critical Health";
    }
    else if(chosen_punishment == "strip_ammo")
    {
       weapon = self getcurrentweapon();
	   self setweaponammostock( weapon, 0 );
	   self setweaponammoclip( weapon, 0 );
	   punishment_str = "Stripped Ammo";
    }
    else if(chosen_punishment == "shield_deplete")
    {
        self.armor = 0;
        zm_armor::damage( 100, undefined, self );
        punishment_str = "Armor Depleted";
    }
    else if(chosen_punishment == "slowness")
    {
        self thread slowness();
        punishment_str = "Slow Movement";
    }
    else if(chosen_punishment == "blur")
    {
        self thread blur();
        punishment_str = "Blurry Vision";
    }
    else if(chosen_punishment == "random_teleport")
    {
        self thread random_teleport();
        punishment_str = "Random Teleport";
    }
    else if(chosen_punishment == "lose_random_perk")
    {
        self thread take_random_perk_player();
        punishment_str = "Lose Random Perk";
    }
    if(isDefined(punishment_str))
    {
        self iprintlnbold( "^1You were caught moving! ^5" + punishment_str );
        level waittill ("light_change");
        self healthoverlay::restart_player_health_regen();
    }
}
function critical_health()
{
    level endon ("light_change");
    for(;;)
    {
        self.var_4d9b2bc3 = 0;
        self notify( #"end_healthregen" );
        if(self.health > 10)
        {
            self.health = 10;
        }
        wait 0.1;
    }
}

function slowness()
{
    self setmovespeedscale(0.3);
    level waittill ("light_change");
    self setmovespeedscale(1);
}

function blur()
{
    level endon ("light_change");
    for(;;)
    {
        self setblur( 4, 0.1 );
        wait 0.1;
    }
}

function take_random_perk_player()
{
    if(self zm_laststand::player_is_in_laststand() || self.sessionstate == "spectator")
    {
        return;
    }

    if(!isdefined(self.var_7341f980) || self.var_7341f980.size <= 0)
    {
        return;
    }

    perk = self.var_7341f980[RandomInt(self.var_7341f980.size)];

    if(!isdefined(perk))
    {
        return;
    }

    self namespace_791d0451::function_4c1d0e25(perk);
}

function random_teleport()
{
    if ( zm_utility::is_survival() )
    {
        point = get_outbreak_spawn();
    }
    else
    {
        point = get_random_respawn_point(self);
    }
    dest = struct::spawn( point.origin, ( 0, self.angles[1], 0 ) );
    self.ignore_redlight = true;
    if ( isalive( self ) )
    {
        self thread zm_fasttravel::function_66d020b0( undefined, undefined, undefined, "", dest, undefined, "custom_travel", 1 );   
    }
    wait 5;
    self.ignore_redlight = undefined;
}

function get_random_respawn_point( player )
{
    zone_name = zm_zonemgr::get_zone_from_position( player.origin + ( 0, 0, 32 ), 0 );
    if ( !isdefined( zone_name ) )
    {
        zone_name = player.zone_name;
    }
    current_zone = undefined;
    if ( isdefined( zone_name ) )
    {
        current_zone = level.zones[ zone_name ];
    }
    rooms  = get_teleport_rooms();
    valid  = [];
    foreach ( anchor in struct::get_array( "player_respawn_point", "targetname" ) )
    {
        if ( is_true( anchor.locked ) || !isdefined( anchor.target ) )
        {
            continue;
        }
        
        if ( !is_safe_point( anchor.origin ) )
        {
            continue;
        }

        if ( zm_utility::is_point_inside_enabled_zone( anchor.origin, current_zone ) )
        {
            valid[ valid.size ] = anchor;
        }
    }
    if ( valid.size == 0 )
    {
        return undefined;
    }
    anchor   = valid[ randomint( valid.size ) ];
    children = struct::get_array( anchor.target, "targetname" );
    pick     = undefined;
    foreach ( c in children )
    {
        if ( isdefined( c.plyr ) && c.plyr == player getentitynumber() )
        {
            pick = c;
        }
    }
    if ( !isdefined( pick ) )
    {
        foreach ( c in array::randomize( children ) )
        {
            if ( !isdefined( c.plyr ) && !positionwouldtelefrag( c.origin ) && !is_near_teleport_room( c.origin, rooms ) )
            {
                pick = c;
                break;
            }
        }
    }
    return pick;
}

function get_teleport_rooms()
{
    rooms = [];
    for ( i = 1; i <= 12; i++ )
    {
        s = struct::get( "s_teleport_room_" + i, "targetname" );

        if ( isdefined( s ) )
        {
            rooms[ rooms.size ] = s;
        }
    }
    return rooms;
}

function get_outbreak_spawn()
{
    dest = level.contentmanager.currentdestination;
    if ( !isdefined( dest ) )
    {
        return undefined;
    }
    spots = dest.spawns;
    if ( !isdefined( spots ) || spots.size == 0 )
    {
        spots = content_manager::get_children( dest );
    }
    rooms = get_teleport_rooms();
    valid = [];
    foreach ( s in spots )
    {
        if ( is_near_teleport_room( s.origin, rooms ) )
        {
            continue;
        }
        if ( positionwouldtelefrag( s.origin ) )
        {
            continue;
        }
        if ( !is_safe_point( s.origin ) )
        {
            continue;
        }
        valid[ valid.size ] = s;
    }
    if ( valid.size == 0 )
    {
        return undefined;
    }
    return valid[ randomint( valid.size ) ];
}

function is_near_teleport_room( origin, rooms )
{
    foreach ( room in rooms )
    {
        if ( distance( origin, room.origin ) < 1500 )
        {
            return true;
        }
    }

    return false;
}

function is_safe_point( origin )
{
    if ( !zm_utility::check_point_in_playable_area( origin ) )
    {
        return false;
    }
    nav = getclosestpointonnavmesh( origin, 64 );
    if ( !isdefined( nav ) )
    {
        return false;
    }
    if ( distance2d( nav, origin ) > 48 )
    {
        return false;
    }
    return true;
}

function force_green_light_on_exfil()
{
    level flag::wait_till(#"rbz_exfil_started");
    level notify ("light_change");
    level notify ("stop_segment");
    change_light(0);
}
