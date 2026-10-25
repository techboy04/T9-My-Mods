#using scripts\core_common\flag_shared.gsc;

#namespace firebase_z_mimic_step_skip;

/*[[[SETTINGS]]]
CHECKBOX skip_mimic_step "Skip Mimic Step" default=true help="Skips the mimic step completely."
CHECKBOX skip_dart_board "Skip Dart Board" default=true help="Auto sets the dart board codes only requiring you to shoot the bullseye."
[[[/SETTINGS]]]*/

function autoexec main()
{
    level thread main_thread();
}

function private main_thread()
{
    level flag::wait_till(#"intro_scene_done");

    if([[[skip_mimic_step]]])
    {
        level thread skip_mimic_hunt();
    }

    if([[[skip_dart_board]]])
    {
        level thread skip_dartboard_codes();   
    }
}

function skip_mimic_hunt()
{
    level flag::wait_till( #"hash_2aa7dafe13615e92" );
    wait 1;
    level flag::set( #"hash_18e72757cd139ecf" );
    level flag::set( #"hash_d5792142b22f671" );
    level flag::set( #"hash_18e72857cd13a082" );
}

function skip_dartboard_codes()
{
    level endon( #"end_game" );
    level endon( #"hash_76c7837322a67981" );

    while ( !isdefined( level.var_685ca72f ) || !isdefined( level.var_1221f4ab ) || !isdefined( level.var_82f3ced5 ) )
    {
        wait 1;
    }

    while ( true )
    {
        for ( i = 0; i < level.var_685ca72f.size; i++ )
        {
            level flag::set( #"hash_23851dbffef298e1" );
            waitframe( 2 );
        }

        if ( isdefined( level.var_82f3ced5 ) )
        {
            level.var_82f3ced5 waittill( #"damage" );   
        }
        else
        {
            wait 1;
        }

        waitframe( 3 );
    }
}