#using scripts\core_common\flag_shared.gsc;
#using scripts\core_common\values_shared.gsc;
#using scripts\core_common\callbacks_shared.gsc;
#using scripts\core_common\clientfield_shared.gsc;
#using scripts\core_common\hud_shared.gsc;
#using scripts\core_common\gameobjects_shared.gsc;
#using scripts\zm_common\zm_utility.gsc;
#using scripts\core_common\array_shared.gsc;
#using scripts\core_common\math_shared.gsc;
#using scripts\core_common\item_drop.gsc;
#using scripts\core_common\trigger_shared.gsc;
#using scripts\core_common\struct.gsc;
#using scripts\core_common\content_manager.gsc;
#using scripts\zm_common\zm_audio.gsc;
#using scripts\zm_common\zm_blockers.gsc;
#using scripts\zm_common\zm_unitrigger.gsc;
#using scripts\zm_common\zm_magicbox.gsc;
#using scripts\zm_common\zm_zonemgr.gsc;
#using scripts\zm_common\zm_sq.gsc;
#using scripts\zm_common\zm_round_logic.gsc;
#using scripts\zm_common\zm_power.gsc;
#using scripts\zm_common\zm_perks.gsc;
#using scripts\zm_common\zm_powerups.gsc;
#using scripts\zm_common\zm_weapons.gsc;
#using scripts\zm_common\zm_fasttravel.gsc;
#using scripts\core_common\util_shared.gsc;
#using script_6fc2be37feeb317b;
#using script_25be5471a9c31833;
#using script_7a5293d92c61c788;
#using script_4ccfb58a9443a60b;

#namespace starting_room;

/*[[[SETTINGS]]]
CHECKBOX enable_random_perk "Enable Random Perk Powerup" default=true help="Adds the Random Perk powerup to powerups set."
CHECKBOX enable_fire_sale "Enable Fire Sale Powerup" default=true help="Adds the Fire Sale powerup to powerups set."

CHECKBOX enable_wunderfizz "Enable Wunderfizz" default=true help="Toggle a placed Wunderfizz" category="Stations"
CHECKBOX enable_pap "Enable Pack a Punch" default=true help="Toggle a placed Pack a Punch" category="Stations"
CHECKBOX enable_arsenal "Enable Arsenal" default=true help="Toggle a placed Arsenal" category="Stations"

SLIDER rounds_till_wunderfizz   "Rounds Till Wunderfizz"   min=0 max=100 default=0 help="What round to spawn the Wunderfizz in. If set to 0, it will spawn at the start." category="Stations"

CHECKBOX enable_dark_aether "Enable Dark Aether" default=true help="Enables the maps Dark Aether." category = "Map Specific" subcategory = "Die Maschine"
SLIDER rounds_till_dark_aether   "Rounds to switch Dark Aether"   min=0 max=100 default=7 help="How many rounds to swap in and out of the Dark Aether. When set to 0, will permanently be in the Dark Aether (Exfil will still be available)" category = "Map Specific" subcategory = "Die Maschine"

CHECKBOX zm_classic_quick_revive_fix "ZM Classic Quick Revive Fix" default=true help="Returns the Quick Revive machine and increases the perk limit. Perfect workaround to ZM Classic's bug with Quick Revive not being given. Also will ignore the Perk Limit setting." category = "Map Specific" subcategory = "Firebase Z"

[[[/SETTINGS]]]*/

/*[[[PRESETS]]]
PRESET "Default" default help="The way the mod is meant to be played."
    enable_random_perk = true
    enable_wunderfizz = true
    enable_fire_sale = true
    enable_pap = true
    enable_arsenal = true
    rounds_till_wunderfizz = 0
    enable_dark_aether = true
    rounds_till_dark_aether = 7
    zm_classic_quick_revive_fix = false

PRESET "Bo6 Rules" help="Rules based off of Bo6s LTM mode."
    enable_random_perk = true
    enable_wunderfizz = false
    enable_fire_sale = true
    enable_pap = false
    enable_arsenal = false
    rounds_till_wunderfizz = 25
    enable_dark_aether = true
    rounds_till_dark_aether = 7
    zm_classic_quick_revive_fix = false
    
PRESET "Bo6 Rules (Casual Friendly)" help="Rules based off of Bo6s LTM mode with some tweaks to make it Casual friendly."
    enable_random_perk = true
    enable_wunderfizz = true
    enable_fire_sale = true
    enable_pap = true
    enable_arsenal = true
    rounds_till_wunderfizz = 15
    enable_dark_aether = true
    rounds_till_dark_aether = 7
    zm_classic_quick_revive_fix = tre

[[[/PRESETS]]]*/

function autoexec main()
{
    level thread main_thread();
    callback::on_spawned(&on_spawned);
}

function private main_thread()
{
    level flag::wait_till(#"intro_scene_done");

    foreach(player in level.players)
    {
        player.firsttime = 1;
    }
    level thread remove_all_door_buy();
    level thread remove_all_perk_machines();
    level thread setup_locations();
    level thread force_starting_room_box();
    level thread remove_objectives();
    level thread wait_on_exfil();
    level thread add_free_perk();
}

function on_spawned()
{
    if(isdefined(self.firsttime))
    {
        self.firsttime = 0;
    }
    if(self.firsttime == 0)
    {
        self.firsttime = 1;
    }
}

function setup_locations()
{
    level.wunderfizz_loc = [];
    level.arsenal_loc = [];
    level.bench_loc = [];
    level.pap_loc = [];
    level.exfil_loc = [];

    if(level.script == "zm_silver")
    {
        level.wunderfizz_loc[level.wunderfizz_loc.size] = (246.141, -634.047, -0.288);
        level.wunderfizz_loc[level.wunderfizz_loc.size] = 11.7;
    
        level.arsenal_loc[level.arsenal_loc.size] = (1002.95, 582.359, 27.6765);
        level.arsenal_loc[level.arsenal_loc.size] = -94;
    
        level.bench_loc = undefined;
    
        level.pap_loc[level.pap_loc.size] = (1012.85, -1072.96, 21.90);
        level.pap_loc[level.pap_loc.size] = 135.538;
        
        level.starter_box_location = (903.204, 108.417, 56.126);
        
        level.exfil_loc = undefined;
    }
    else if(level.script == "zm_gold")
    {
        level.wunderfizz_loc = undefined;
        level.arsenal_loc = undefined;
        level.bench_loc = undefined;
        level.pap_loc = undefined;
        
        level.starter_box_location = (-48806, -20536, 629);
        
        level.exfil_loc[level.exfil_loc.size] = (-48482.8, -20076.2, 680.006);
        level.exfil_loc[level.exfil_loc.size] = -90;
    }
    else if(level.script == "zm_platinum")
    {
        level.wunderfizz_loc[level.wunderfizz_loc.size] = (-1593.06, 10079.1, 688.125);
        level.wunderfizz_loc[level.wunderfizz_loc.size] = -51.6467;
  
        level.arsenal_loc[level.arsenal_loc.size] = (-1158.76, 10068.1, 688.125);
        level.arsenal_loc[level.arsenal_loc.size] = -51;

        level.bench_loc = undefined;
        level.pap_loc[level.pap_loc.size] = (-1065.95, 9039.84, 952.125);
        level.pap_loc[level.pap_loc.size] = 90;
                        
        level.starter_box_location = (-873.174, 9945.13, 857.236);
        
        level.exfil_loc[level.exfil_loc.size] = (-1340.52, 9757.71, 713.201);
        level.exfil_loc[level.exfil_loc.size] = 132;
    }
    else if(level.script == "zm_tungsten")
    {
        level.wunderfizz_loc[level.wunderfizz_loc.size] = (-2358.7,-916.073, 0.125);
        level.wunderfizz_loc[level.wunderfizz_loc.size] = -130;
    
        level.arsenal_loc = undefined;
    
        level.bench_loc = undefined;
    
        level.pap_loc[level.pap_loc.size] = (-3271.85, -656.641, 53.5154);
        level.pap_loc[level.pap_loc.size] = -90;
        
        level.exfil_loc[level.exfil_loc.size] = (-2901.58, -2707.87, 87.9542);
        level.exfil_loc[level.exfil_loc.size] = 43;
        
        level.starter_box_location = (-4131.36, -1570.66, 0.125);
    }
    else
    {
        level.wunderfizz_loc = undefined;
        level.arsenal_loc = undefined;
        level.bench_loc = undefined;
        level.pap_loc = undefined;
        level.exfil_loc = undefined;
    }
    
    place_stations();
}

function remove_all_door_buy()
{
    zombie_doors = getentarray( "zombie_door", "targetname" );
    
    for (i = 0; i < zombie_doors.size; i++) {
        zombie_doors[ i ] triggerenable(false);
        
        waitframe( 1 );
    }
    
    zombie_debris = getentarray( "zombie_debris", "targetname" );
    
    for (i = 0; i < zombie_doors.size; i++) {
        zombie_debris[ i ] triggerenable(false);
        
        waitframe( 1 );
    }
}

function open_everything()
{
    power_trigs = getentarray( "use_elec_switch", "targetname" );
    foreach ( trig in power_trigs )
    {
        if ( isdefined( trig.script_int ) )
        {
            level flag::set( "power_on" + trig.script_int );
            level clientfield::set( "zombie_power_on", trig.script_int + 1 );
        }
    }
    
    players = getplayers();
    zombie_doors = getentarray( "zombie_door", "targetname" );
    
    for (i = 0; i < zombie_doors.size; i++) {
        if ( !is_true( zombie_doors[ i ].has_been_opened ) )
        {
            zombie_doors[ i ] zm_blockers::force_open_door( players[ 0 ] );
        }
        
        if ( is_true( zombie_doors[ i ].power_door_ignore_flag_wait ) )
        {
            zombie_doors[ i ] notify( #"power_on" );
        }
        
        waitframe( 1 );
    }
    
    zombie_airlock_doors = getentarray( "zombie_airlock_buy", "targetname" );
    
    for (i = 0; i < zombie_airlock_doors.size; i++) {
        zombie_airlock_doors[ i ] zm_blockers::force_open_door( players[ 0 ] );
        waitframe( 1 );
    }
    
    zombie_debris = getentarray( "zombie_debris", "targetname" );
    
    for (i = 0; i < zombie_debris.size; i++) {
        if ( isdefined( zombie_debris[ i ] ) )
        {
            zombie_debris[ i ] zm_blockers::force_open_door( players[ 0 ] );
        }
        
        waitframe( 1 );
    }
}

function remove_all_perk_machines()
{  
    if(level.script == "zm_gold" && is_true([[[zm_classic_quick_revive_fix]]]))
    {
        level.perk_purchase_limit = 16;
        return;
    }
    
    foreach ( stub in level.var_976841f )
    {
        zm_unitrigger::unregister_unitrigger( stub );

        if ( isdefined( stub.bump ) )
        {
            stub.bump delete();
        }
        if ( isdefined( stub.clip ) )
        {
            stub.clip delete();
        }

        if ( isdefined( stub.machine ) )
        {
            if ( isdefined( stub.machine.n_obj_id ) )
                zm_utility::function_bc5a54a8( stub.machine.n_obj_id );   // map/ping marker

            stub.machine delete();
        }
    }
    level.var_976841f = [];
    level.perk_machines = [];
    foreach ( trigger in getentarray( "audio_bump_trigger", "targetname" ) )
        trigger delete();
}

function make_spot( org, ang )
{
    s = spawnstruct();
    s.origin = org;
    s.angles = (0, ang, 0);
    s.parent = spawnstruct();
    return s;
}

function place_stations()
{
    if(isDefined(level.pap_loc) && is_true([[[enable_pap]]]))
    {
        pap   = make_spot( level.pap_loc[0], level.pap_loc[1] );
        namespace_4b9fccd8::function_e0069640( pap );
        spawncollision( "collision_clip_64x64x256", "collider", level.pap_loc[0] + ( 0, 0, 96 ), ( 0, level.pap_loc[1], 0 ) );
    }
    if(isDefined(level.bench_loc))
    {
        bench = make_spot( level.bench_loc[0], level.bench_loc[1] );
        namespace_1cc7b406::function_db05041b( bench, #"hash_1e1b751abcb0c5b6", &namespace_1cc7b406::function_e3ad9f54 );
    }
    if(isDefined(level.arsenal_loc) && is_true([[[enable_arsenal]]]))
    {
        armor = make_spot( level.arsenal_loc[0], level.arsenal_loc[1] );
        namespace_dd7e54e3::function_93a99046( armor );
        spawncollision( "collision_clip_64x64x256", "collider", level.arsenal_loc[0] + ( 0, 0, 96 ), ( 0, level.arsenal_loc[1], 0 ) );
    }
    if(isDefined(level.wunderfizz_loc) && is_true([[[enable_wunderfizz]]]))
    {
        level thread spawn_wunderfizz();
    }

    move_exfil_radio();
}

function force_starting_room_box()
{
    level endon( #"end_game" );
    level flag::wait_till( #"start_zombie_round_logic" );

    while ( !isdefined( level.chests ) || level.chests.size == 0 )
    {
        wait 0.5;
    }

    wait 3;
    level flag::clear( #"disable_weapon_machine" );
    chosen_chest = undefined;
    best_dist = 9999;
    foreach(chest in level.chests)
    {
        dist = distance( chest.origin, level.starter_box_location );

        if ( dist < best_dist )
        {
            best = chest;
            best_dist = dist;
        }
    }

    
    foreach (chest in level.chests)
    {
        if(best == chest)
        {
            chosen_chest = chest;
            if(chest.hidden)
            {
                chest thread zm_magicbox::show_chest();   
            }
        }
        else
        {
            chest zm_magicbox::hide_chest();
            if(isDefined(chest.zbarrier))
            {
                chest.zbarrier delete();
            }
        }
    }
    
    chosen_chest.zombie_cost = 950;
    chosen_chest.old_cost = 950;
    chosen_chest.no_fly_away = 1;

    level.chests = [];
    level.chests[ 0 ] = chosen_chest;
    level.chest_index = 0;
    level flag::clear( "moving_chest_enabled" );
}

function remove_objectives()
{

    level thread clear_intro_markers();
    if(level.script == "zm_silver")
    {
        zm_sq::objective_complete( #"hash_502a7a67764fd94e", struct::get( "zm_atuo_door", "targetname" ) );
        zm_sq::objective_complete( #"hash_1c145a15f9ddd06d", struct::get_array( "pap_extra_objective_marker", "targetname" ) );
        zm_sq::objective_complete( #"hash_502a7967764fd79b", getent( "elec_switch", "script_noteworthy" ) );
        zm_sq::objective_complete( #"hash_51a6aa8cdd8606d6", getent( "zm_tm_blue", "targetname" ) );
        zm_sq::objective_complete( #"hash_51a6aa8cdd8606d6", getent( "zm_tm_red", "targetname" ) );
        zm_sq::objective_complete( #"hash_52a7a8068eacfe", level.var_f2484ed9 );
        zm_sq::objective_complete( #"hash_75e465cf3c494bdd", struct::get( level.var_f070b39a.objective_string, "script_string" ) );
        zm_sq::objective_complete( #"hash_48b81559139c7c6f", level.var_f070b39a );
        zm_sq::objective_complete( #"hash_30b3a017b4e8ca1a" );
        zm_sq::objective_complete( #"hash_502a7e67764fe01a", level.var_241be029 );
        level thread dark_aether_segment();
    }
    else if(level.script == "zm_gold")
    {
        level flag::set( #"disable_fast_travel" );
        
        players = getplayers();
        zombie_doors = getentarray( "zombie_door", "targetname" );
    
        for (i = 0; i < zombie_doors.size; i++) {
            if ( !is_true( zombie_doors[ i ].has_been_opened ) )
            {
                zombie_doors[ i ] zm_blockers::force_open_door( players[ 0 ] );
            }
        
            if ( is_true( zombie_doors[ i ].power_door_ignore_flag_wait ) )
            {
                zombie_doors[ i ] notify( #"power_on" );
            }
        
            waitframe( 1 );
        }
        
        power_trigs = getentarray( "use_elec_switch", "targetname" );
        foreach ( trig in power_trigs )
        {
            if ( isdefined( trig.script_int ) )
            {
                level flag::set( "power_on" + trig.script_int );
                level clientfield::set( "zombie_power_on", trig.script_int + 1 );
            }
        }
        
        zm_power::turn_power_on_and_open_doors( 1 );
        zm_power::turn_power_on_and_open_doors( 2 );
        zm_power::turn_power_on_and_open_doors( 3 );
        
        zm_sq::objective_complete( #"hash_42ebe8f41ed5edc8" );
        zm_sq::objective_complete( #"hash_968256af57af0db" );
        zm_sq::objective_complete( #"hash_69cca9825b7edc33" );
        zm_sq::objective_complete( #"hash_2b663a5dd7beb565" );
        level flag::set( #"pap_quest_completed" );
    }
    else if(level.script == "zm_platinum")
    {
        level flag::set( #"hash_7b5643f5ecc16c8f" );
        level flag::set( "flag_pap_quest_start_adds" );
        level flag::set( #"hash_1040acad653a881f" );
        level flag::set( #"hash_20afa38b1f1c339e" );
        
        zm_sq::objective_complete( #"hash_1c556f45aa40ebef" );
    }
    else if(level.script == "zm_tungsten")
    {
        level flag::set( #"disable_fast_travel" );
        
        while ( !isdefined( level.var_150884c ) || !isdefined( level.var_150884c.s_unitrigger ) )
        {
            wait 0.5;
        }

        zm_unitrigger::unregister_unitrigger( level.var_150884c.s_unitrigger );
        zm_sq::objective_complete( #"hash_6b0d99dea8e99af5" );

        level.round_wait_func = &zm_round_logic::round_wait;
        level.func_get_delay_between_rounds = &zm_round_logic::get_delay_between_rounds;
        level.func_get_zombie_spawn_delay = &zm_round_logic::get_zombie_spawn_delay;
        level flag::set( #"hash_3b763d6426336ce0" );
        
        level.var_69244388 = undefined;
        level.var_9b33b774 = undefined;
    }
}

function move_exfil_radio()
{
    level endon( #"end_game" );

    if(!isDefined(level.exfil_loc))
    {
        return;
    }
    
    level flag::wait_till( #"start_zombie_round_logic" );
    wait 5;

    radio = struct::get( "exfil_radio" );
    if ( !isdefined( radio ) )
    {
        return;
    }

    old_origin = radio.origin;
    radio.origin = level.exfil_loc[0];
    radio.angles = (0, level.exfil_loc[1] + 90, 0);

    moved = 0;

    foreach ( m in getentarray( "script_model", "classname" ) )
    {
        if ( !isdefined( m ) || !isdefined( m.model ) )
        {
            continue;
        }

        if ( m.model == #"hash_615f17c2d8b69f96" && distance( m.origin, old_origin ) < 32 )
        {
            m.origin = level.exfil_loc[0];
            m.angles = (0, level.exfil_loc[1], 0);
            moved += 1;
        }
    }
}

function wait_on_exfil()
{
    level endon ("end_game");
    level flag::wait_till(#"rbz_exfil_started");
    level thread open_everything();
    level flag::clear( #"disable_fast_travel" );
}

function clear_intro_markers()
{
    level endon( #"game_ended" );
    level flag::wait_till( "start_zombie_round_logic" );

    doors  = [ struct::get( "zipline_to_destroyed_apartments" ), struct::get( "zipline_to_east_berlin_hotel" ) ];
    hashes  = [ #"hash_6540714f9d2b59fb", #"hash_6540724f9d2b5bae" ];

    while ( !level flag::get( "power_on" ) )
    {
        for ( i = 0; i < 2; i++ )
            level zm_sq::objective_complete( hashes[ i ], doors[ i ] );

        level zm_sq::objective_complete( #"hash_6540734f9d2b5d61", struct::get( "garment_warehouse_door" ) );
        level zm_sq::objective_complete( #"hash_6540744f9d2b5f14", struct::get( "ghost_station_door" ) );
        level zm_sq::objective_complete( #"hash_6540754f9d2b60c7", struct::get( "ghost_station2_door" ) );
        level zm_sq::objective_complete( #"hash_50971d60dd167421", getent( "elec_switch", "script_noteworthy" ) );

        wait 1;
    }
}

function spawn_wunderfizz()
{
    rounds = [[[rounds_till_wunderfizz]]];
    
    if(rounds > 0)
    {
        for(;;)
        {
            level waittill( #"between_round_over" );
            rounds -= 1;
            if(rounds == 0)
            {
                break;
            }
        }
    }
    
    fizz  = make_spot( level.wunderfizz_loc[0], level.wunderfizz_loc[1] );
    namespace_82b4c2d1::function_744f2a2( fizz, #"perk_machine_choice", #"hash_6e47d6576612543c", #"hash_4af85251966549b8", #"hash_3eac5ec7a888ddfb", 0, &namespace_82b4c2d1::function_472f16d8, undefined );
    spawncollision( "collision_clip_64x64x256", "collider", level.wunderfizz_loc[0] + ( 0, 0, 96 ), ( 0, level.wunderfizz_loc[1], 0 ) );
}

function add_free_perk()
{
    level flag::wait_till( #"start_zombie_round_logic" );

    if(is_true([[[enable_random_perk]]]))
    {
        level.zombie_powerups[ "free_perk" ].func_should_drop_with_regular_powerups = &zm_powerups::func_should_always_drop;        
    }
    if(is_true([[[enable_fire_sale]]]))
    {
        level.zombie_powerups[ "fire_sale" ].func_should_drop_with_regular_powerups = &zm_powerups::func_should_always_drop;  
    }
}

function dark_aether_segment()
{
    level endon ("end_game");
    if(is_false([[[enable_dark_aether]]]))
    {
        return;
    }
    if([[[rounds_till_dark_aether]]] == 0)
    {
        level thread dark_aether_on();
        return;
    }
    round_to_teleport = [[[rounds_till_dark_aether]]];
    for(;;)
    {
        level waittill ("between_round_over");
        
        if(level.round_number == round_to_teleport)
        {
            round_to_teleport += [[[rounds_till_dark_aether]]];
            if(level flag::get("in_dark_side"))
            {
                level thread dark_aether_off();
            }
            else
            {
                level thread dark_aether_on();
            }
        }
    }
}

function dark_aether_on()
{
    level flag::set( "in_dark_side" );
    if(level.usingrampage != 1)
    {
        level clientfield::increment( "" + #"hash_5cf186464ce9cdd6" );   
        wait 7;
    }

    foreach ( player in getplayers() )
    {
        if ( isalive( player ) )
        {
            player thread zm_fasttravel::function_66d020b0( undefined, undefined, undefined, undefined, struct::spawn( player.origin, player.angles ), undefined, "dark_aether_fasttravel", 1, 0, 0 );   
        }
    }

    level waittill( #"hash_62c65dd69ca5fbf5" );
    waitframe( 1 );

    level clientfield::set( "" + #"hash_51ed1d1064cfb0e", 1 );
    foreach ( player in getplayers() )
    {
        player clientfield::set_to_player( "" + #"music_underscore", 2 );
    }

    level clientfield::set( "newtonian_negation", 1 );
    level clientfield::set( "" + #"hash_266f6fe481bab1bc", 1 );
    level util::set_lighting_state( 1 );
    hidemiscmodels( "zm_silver_normal_computers" );
    level flag::set( #"dark_aether_active" );
}

function dark_aether_off()
{
    if(level.usingrampage != 1)
    {
        level clientfield::increment( "" + #"hash_5cf186464ce9cdd6" );
        wait 7;
    }
    level flag::clear( "in_dark_side" );

    foreach ( player in getplayers() )
    {
        if ( isalive( player ) )
        {
            player thread zm_fasttravel::function_66d020b0( undefined, undefined, undefined, undefined, struct::spawn( player.origin, player.angles ), undefined, "dark_aether_fasttravel", 1, 0, 0 ); 
        }
    }

    level waittill( #"hash_62c65dd69ca5fbf5" );
    waitframe( 1 );

    level clientfield::set( "" + #"hash_51ed1d1064cfb0e", 0 );
    level clientfield::set( "" + #"hash_266f6fe481bab1bc", 0 );
    foreach ( player in getplayers() )
    {
        player clientfield::set_to_player( "" + #"music_underscore", 3 );
    }

    level clientfield::set( "newtonian_negation", 0 );
    level util::set_lighting_state( 0 );
    showmiscmodels( "zm_silver_normal_computers" );
    level flag::clear( #"dark_aether_active" );
}
