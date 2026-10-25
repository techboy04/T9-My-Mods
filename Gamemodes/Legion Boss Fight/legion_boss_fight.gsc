#using scripts\core_common\flag_shared.gsc;
#using scripts\core_common\clientfield_shared.gsc;
#using scripts\core_common\callbacks_shared.gsc;
#using scripts\zm_common\zm_utility_zsurvival.gsc;
#using scripts\zm_common\zm_fasttravel.gsc;
#using scripts\zm_common\zm_score.gsc;
#using scripts\zm_common\zm_utility.gsc;
#using scripts\zm_common\zm_weapons.gsc;
#using scripts\core_common\struct.gsc;
#using script_66b094f566d08b1c;
#using script_32b18d9fb454babf;
#using script_437ce686d29bb81b;
#using script_6fc2be37feeb317b;
#using script_25be5471a9c31833;
#using script_7a5293d92c61c788;
#using script_4ccfb58a9443a60b;
#using script_18077945bb84ede7;

#namespace legion;

function autoexec main()
{
    level thread main_thread();
}

function private main_thread()
{
    level flag::wait_till(#"intro_scene_done");
    namespace_cf6efd05::function_c484a9be( #"hash_62df6469a6590d1c", 1 );
    level flag::set( #"hash_24ee328d248f88de" );
    namespace_18bbc38e::function_8e64a2b1( "wz_forest", #"ee", #"reveal" );
    level flag::wait_till_all( array("all_players_connected", "all_players_spawned", "initial_blackscreen_passed", "start_zombie_round_logic"));
    level flag::clear( "spawn_zombies" );
    if ( level.script == "wz_forest" && level.var_b48509f9 != 1)
    {
        level thread skip_quest();
        level thread report_main_quest();
        level thread place_stations();
        level thread give_players_unlimited_money();
        
        wait 0.5;
        foreach(player in level.players)
        {
            if(distance(player.origin, (13104.5, 161.856, -1360.09)) > 250)
            {
                dest = struct::spawn( (13104.5, 161.856, -1360.09), ( 0, 172.996, 0 ) );
                if ( isalive( player ) )
                {
                    player thread zm_fasttravel::function_66d020b0( undefined, undefined, undefined, "my_travel_done", dest, undefined, "custom_travel", 1 );        
                }   
            }
        }
        wait 5;
        level thread damage_if_players_stray();
        if(level flag::get("spawn_zombies"))
        {
            level flag::clear("spawn_zombies");
        }
        a_enemies = getaiteamarray( level.zombie_team );
        foreach(enemy in a_enemies)
        {
            enemy dodamage(enemy.health, enemy.origin);
        }
    }
    else
    {
        level.var_b48509f9 = 3;

        zm_utility_zsurvival::function_7c97e961( 3 );
        
        zm_utility_zsurvival::switch_map( "wz_forest" );
    }
}

function skip_to_boss()
{
    level endon( #"end_game" );
    s_instance = level.contentmanager.activeobjective;
    if ( !isdefined( s_instance ) || !isdefined( s_instance.contentgroups[ #"beast" ] ) )
    {
        return;
    }
    level thread namespace_1b312da5::function_861f39db( s_instance, 1 );
    wait 1;
    s_instance flag::set( #"keys_collected" );
    s_instance flag::set( #"keys_inserted" );
}

function get_main_quest_instance()
{
    foreach ( location in level.contentmanager.locations )
    {
        inst = location.instances[ #"reveal" ];

        if ( isdefined( inst ) )
        {
            return inst;
        }
    }

    return undefined;
}

function remove_enter_facility()
{
    level endon( #"end_game" );

    inst = get_main_quest_instance();
    btn  = inst.contentgroups[ #"elevator_button" ][ 0 ];

    if ( !isdefined( btn ) )
    {
        return;
    }

    while ( true )
    {
        foreach ( t in getentarray( "trigger_radius_use", "classname" ) )
        {
            if ( distance( t.origin, btn.origin ) < 160 )
            {
                t delete();
            }
        }

        zm_utility::function_bc5a54a8( inst.var_e55c8b4e );
        wait 1;
    }
}

function skip_quest()
{
    setdvar( #"hash_4c7a7b0813c6765d", "reveal" );
    
    inst = get_main_quest_instance();
    
    if ( !isdefined( inst ) )
    {
        return;
    }

    if ( isdefined( inst.var_4272a188 ) )
    {
        inst.var_4272a188 triggerenable( 0 );
        inst.var_4272a188 delete();
    }

    if ( isdefined( inst.var_e55c8b4e ) )
    {
        zm_utility::function_bc5a54a8( inst.var_e55c8b4e );   // the game's own marker cleanup
    }

    if ( isdefined( inst ) && isdefined( inst.contentgroups[ #"beast" ] ) )
    {
        beast = inst.contentgroups[ #"beast" ][ 0 ];
    }
}

function report_main_quest()
{
    level flag::wait_till( "start_zombie_round_logic" );
    wait 3;
    found = false;
    foreach ( location in level.contentmanager.locations )
    {
        if ( isdefined( location.instances[ #"reveal" ] ) )
        {
            found = true;
        }
    }
}

function start_boss_now()
{
    level endon( #"end_game" );
    inst = get_main_quest_instance();
    if ( !isdefined( inst ) || !isdefined( inst.contentgroups[ #"beast" ] ) )
    {
        return;
    }
    level thread remove_enter_facility();
    wait 3;
    if ( !isdefined( level.var_a05ab6 ) )
    {
        namespace_1b312da5::function_7c583c30( inst );
    }
    level.contentmanager.activeobjective = inst;
    level thread namespace_1b312da5::function_861f39db( inst, 1 );
    level thread keep_zombies_disabled();
}

function place_stations()
{
    level thread spawn_weapons();
    wait 0.5;    
    pap = struct::spawn( (12594.49, 196.649, -1371.77), ( 0, 16.4575, 0 ) );
    namespace_4b9fccd8::function_e0069640( pap );
    spawncollision( "collision_clip_64x64x256", "collider", pap.origin + ( 0, 0, 96 ), ( 0, pap.angles[1], 0 ) );
    wait 0.5;
    bench = struct::spawn( (12617.9, 390.804, -1400.1), ( 0, 3.7, 0 ) );
    namespace_1cc7b406::function_db05041b( bench, #"hash_1e1b751abcb0c5b6", &namespace_1cc7b406::function_e3ad9f54 );
    spawncollision( "collision_clip_64x64x256", "collider", bench.origin + ( 0, 0, 96 ), ( 0, bench.angles[1], 0 ) );
    wait 0.5;
    armor = struct::spawn( (12643.9, -1.30771, -1345.77), ( 0, 40.5341, 0 ) );
    namespace_dd7e54e3::function_93a99046( armor );
    spawncollision( "collision_clip_64x64x256", "collider", armor.origin + ( 0, 0, 96 ), ( 0, armor.angles[1], 0 ) );
    wait 0.5;
    fizz = struct::spawn( (12664.2, 562.83, -1437.64), ( 0, -35.2551, 0 ) );
    namespace_82b4c2d1::function_744f2a2( fizz, #"perk_machine_choice", #"hash_6e47d6576612543c", #"hash_4af85251966549b8", #"hash_3eac5ec7a888ddfb", 0, &namespace_82b4c2d1::function_472f16d8, undefined );
    spawncollision( "collision_clip_64x64x256", "collider", fizz.origin + ( 0, 0, 96 ), ( 0, fizz.angles[1], 0 ) );
    wait 0.5;
    boss_start_struct = struct::spawn( (12797.6, -16.9184, -1285.54), ( 0, 50, 0 ) );
    level thread boss_start(boss_start_struct);
    wait 0.5;
    enemies_toggle = struct::spawn( (12989.2, -11.0051, -1319.97) + (0, 0, 40), ( 0, 89.3134, 0 ) );
    level thread enemies_trigger(enemies_toggle);
}

function spawn_powerup_fx( origin, type )
{
    fx = spawn( "script_model", origin );
    fx setmodel( #"tag_origin" );
    if(!isDefined(type))
    {
        type = 1;
    }
    fx clientfield::set( "powerup_fx", type );
    return fx;
}

function boss_start(struct)
{
    trig = spawn( "trigger_radius_use", struct.origin, 0, 64, 128, 1 );
    trig triggerignoreteam();
    trig setcursorhint( "HINT_NOICON" );
    trig usetriggerrequirelookat();
    trig sethintstring( "Press [{+activate}] to ready up" );
    trig callback::on_trigger( &on_used );
    trig.powerup = spawn_powerup_fx(struct.origin);
    level.readyplayers = [];
    return trig;
}

function enemies_trigger(struct)
{
    trig = spawn( "trigger_radius_use", struct.origin, 0, 64, 128, 1 );
    trig triggerignoreteam();
    trig setcursorhint( "HINT_NOICON" );
    trig usetriggerrequirelookat();
    trig sethintstring( "Press [{+activate}] to turn off enemies" );
    trig callback::on_trigger( &toggle_on_used );
    trig.powerup = spawn_powerup_fx(struct.origin, 2);
    level.wants_to_toggle = [];
    level.disable_enemies = 0;
    return trig;
}

function on_used( eventstruct )
{
    player = eventstruct.activator;
    if(player.isready != 1)
    {
        player.isready = 1;
        level.readyplayers[level.readyplayers.size] = player;
        iprintlnbold(player.name + " is ready!" + " - " + level.readyplayers.size + "/" + level.players.size);
    }
    foreach(i in level.players)
    {
        if ( isbot( i ) )
        {
            i.isready = 1;
            level.readyplayers[level.readyplayers.size] = i;
        }
    }
    if(level.readyplayers.size == level.players.size)
    {
        level notify ("disable_stray");
        wait 1;
        foreach(player in level.players)
        {
            dest = struct::spawn( (-5341.11, -6159.9, -487.875), ( 0, 68, 0 ) );

            if ( isalive( player ) )
            {
                player thread zm_fasttravel::function_66d020b0( undefined, undefined, undefined, "my_travel_done", dest, undefined, "custom_travel", 1 );        
            }
        }
        level thread start_boss_now();
    }
}

function toggle_on_used( eventstruct )
{
    player = eventstruct.activator;
    if(level.disable_enemies == 1)
    {
        toggle_str = "enable";
    }
    else
    {
        toggle_str = "disable";
    }
    if(player.toggled != 1)
    {
        player.toggled = 1;
        level.wants_to_toggle[level.wants_to_toggle.size] = player;
        iprintlnbold(player.name + " wants to " + toggle_str + " enemies!" + level.wants_to_toggle.size + "/" + level.players.size);
    }
    foreach(i in level.players)
    {
        if ( isbot( i ) )
        {
            i.toggled = 1;
            level.wants_to_toggle[level.wants_to_toggle.size] = i;
        }
    }
    if(level.wants_to_toggle.size == level.players.size)
    {
        wait 1;
        if(level.disable_enemies == 0)
        {
            level.disable_enemies = 1;
            iprintlnbold("Enemies have been toggled off!");
            self sethintstring( "Press [{+activate}] to turn on enemies" );
        }
        else
        {
            level.disable_enemies = 0;
            iprintlnbold("Enemies have been toggled on!");
            self sethintstring( "Press [{+activate}] to turn off enemies" );
        }
        level.wants_to_toggle = [];
        foreach(player in level.players)
        {
            player.toggled = 0;
        }
    }
}

function give_players_unlimited_money()
{
    for(;;)
    {
        foreach(player in level.players)
        {
            player zm_score::function_c1f146ff( 500000 );
            if(player namespace_2a9f256a::function_6f3fd157() < 1750)
            {
                player namespace_2a9f256a::function_afab250a( 1750 );              
            }
            if(player namespace_2a9f256a::function_efd1d093() < 1750)
            {
                player namespace_2a9f256a::function_a6d4221f( 1750 );
            }
        }
        wait 1;
    }
}

function keep_zombies_disabled()
{
    if(!level.disable_enemies)
    {
        return;
    }
    
    for(;;)
    {
        if(level flag::get("spawn_zombies"))
        {
            level flag::clear("spawn_zombies");
        }
        a_enemies = getaiteamarray( level.zombie_team );
        foreach(enemy in a_enemies)
        {
            enemy dodamage(enemy.health, enemy.origin);
        }
        wait 1;
    }
}

function damage_if_players_stray()
{
    level endon ("disable_stray");
    for(;;)
    {
        foreach(player in level.players)
        {
            if(distance(player.origin, (13104.5, 161.856, -1360.09)) > 2000)
            {
                player dodamage(25, player.origin);   
            }
        }
        wait 1;
    }
}

function spawn_weapons()
{
    level thread build_weapon_wall((13060, 667.251, -1423.48) + (0,0,40), -10);
}

function get_weapon_list()
{
    list = [];
    seen = [];

    if ( isdefined( level.var_ec04a8a4 ) )
    {
        foreach ( name, variants in level.var_ec04a8a4 )
        {
            if ( isdefined( seen[ name ] ) )
            {
                continue;
            }

            weapon = getweapon( name );
            
            if(weapon.rootweapon.weapclass == #"melee")
            {
                continue;
            }

            if ( isdefined( weapon ) && isdefined( weapon.worldmodel ) )
            {
                seen[ name ] = 1;
                list[ list.size ] = weapon;
            }
        }
    }
    
    wonder = array(#"ray_gun", #"ww_ray_rifle_t9", #"ww_ieu_shockwave_t9");
    foreach(weap in wonder)
    {
        weapon = getWeapon(weap);
        if ( isdefined( weapon ) && isdefined( weapon.worldmodel ) )
        {
            seen[ name ] = 1;
            list[ list.size ] = weapon;
        }
    }
    return list;
}

function weapon_wall_positions( origin, yaw, count, rows, spacing_h, spacing_v )
{
    cols = int( ( count + rows - 1 ) / rows );
    dx = cos( yaw );
    dy = sin( yaw );
    start_h = 0 - ( ( cols - 1 ) * spacing_h ) / 2;
    positions = [];
    for ( i = 0; i < count; i++ )
    {
        col = int( i / rows );
        row = i - ( col * rows );

        h = start_h + ( col * spacing_h );
        v = row * spacing_v;

        positions[ i ] = origin + ( dx * h, dy * h, v );
    }
    return positions;
}

function build_weapon_wall( origin, yaw )
{
    list = get_weapon_list();
    spots = weapon_wall_positions( origin, yaw, list.size, 3, 64, 36 );
    for ( i = 0; i < list.size; i++ )
    {
        model = zm_utility::spawn_weapon_model( list[ i ], undefined, spots[ i ], ( 0, yaw, 0 ) );
        
        trig = spawn( "trigger_radius_use", spots[ i ], 0, 48, 48, 1 );
        trig triggerignoreteam();
        trig setcursorhint( "HINT_NOICON" );
        trig usetriggerrequirelookat();
        trig.weapon = list[ i ];
        trig callback::on_trigger( &on_wall_use );
    }
}

function on_wall_use( eventstruct )
{
    eventstruct.activator zm_weapons::weapon_give( self.weapon );
}