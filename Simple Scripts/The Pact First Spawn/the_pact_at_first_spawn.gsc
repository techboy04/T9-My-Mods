#using scripts\core_common\flag_shared.gsc;
#using scripts\core_common\clientfield_shared.gsc;
#using scripts\core_common\callbacks_shared.gsc;
#using scripts\zm_common\zm_utility_zsurvival.gsc;
#using scripts\zm_common\zm_fasttravel.gsc;
#using scripts\core_common\struct.gsc;

#namespace instant_pact;

function autoexec main()
{
    callback::on_spawned(&player_spawned);
    level thread main_thread();
}

function private main_thread()
{
    level flag::wait_till(#"intro_scene_done");
    level thread reset_dvar();
    wait 1;
    if ( level.script != "wz_zoo" )
    {
        if(getdvarint( #"loaded_zoo") != 1)
        {
            setdvar( #"loaded_zoo", 1 );
            go_to_zoo();
        }
    }
    else
    {
        foreach(player in getPlayers())
        {
            player thread player_spawned();
        }
    }
}

function go_to_zoo()
{
    level endon( #"end_game" );
    level flag::wait_till( "start_zombie_round_logic" );
    wait 1;
    foreach ( player in getplayers() )
    {
        player clientfield::increment( "fasttravel_start_fx", 1 );
        player clientfield::set_to_player( "fasttravel_teleport_sfx", 1 );
    }
    zm_utility_zsurvival::switch_map( "wz_zoo" );
}

function player_spawned()
{
    level flag::wait_till_all( array( "all_players_spawned", "initial_blackscreen_passed" ) );
    wait 5;
    if ( level.script != "wz_zoo" )
    {
        return;
    }
    
    dest = struct::spawn( (8076.16, 7422.61, 2023), ( 0, 270, 0 ) );

    if ( isalive( self ) )
    {
        self thread zm_fasttravel::function_66d020b0( undefined, undefined, undefined, "my_travel_done", dest, undefined, "custom_travel", 1 );        
    }
}

function reset_dvar()
{
    level waittill ("end_game");
    setdvar( #"loaded_zoo", 0 );
    
}