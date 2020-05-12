#include "..\script_macros.hpp"

player setVariable [QGVAR(Dead), true, true]; //Tells the framework the player is dead

player hideObjectGlobal true;
player setCaptive true;
player allowDamage false;

cutText ["\n","BLACK IN", 5];
[QGVAR(death), 0, false] call ace_common_fnc_setHearingCapability;
0 fadeSound 1;

player call FUNC(RemoveAllGear);
player addWeapon "itemMap";

player setPos [0, 0, 0];
[player] join grpNull;

if !(player getVariable [QGVAR(Spectating), false]) then {

    player setVariable [QGVAR(Spectating), true, true];

    [true] call acre_api_fnc_setSpectator;
    //If babel is enabled, allowed spectator to hear all languages present in mission.
    if (!isNil QGVAR(enable_babel) && {GVAR(enable_babel)}) then {
        private _missionLanguages = [];
        {
            {
                if (!(_x in _missionLanguages)) then {
                    _missionLanguages pushback _x;
                };
            } foreach _x;
        } forEach GVAR(languages_babel);
        _missionLanguages call acre_api_fnc_babelSetSpokenLanguages;
    };

    //we set default pos in case all methods fail and we end up with 0,0,0
    private _pos = [2000, 2000, 100];
    private _dir = 0;
    
    if (getMarkerColor eg_spectator_marker == "") then {
        if (!isNull killcam_body) then {
            //set camera pos on player body
            _pos = [(getpos killcam_body) select 0, (getpos killcam_body) select 1, ((getposATL killcam_body) select 2)+1.2];
            _dir = getDir killcam_body;
        };
    } else {
        _pos = getmarkerpos eg_spectator_marker;
    };
    
    if (abs(_pos select 0) < 2 && abs(_pos select 1) < 2) then {
        _pos = [2000, 2000, 100];
    };

    ["Initialize", 
        [
        player,
        eg_Whitelisted_Sides,
        eg_Ai_Viewed_By_Spectator,
        eg_Free_Camera_Mode_Available,
        eg_Third_Person_Perspective_Camera_mode_Available,
        eg_Show_Focus_Info_Widget,
        eg_Show_Camera_Buttons_Widget,
        eg_Show_Controls_Helper_Widget,
        eg_Show_Header_Widget,
        eg_Show_Entities_And_Locations_Lists
        ]
    ] call BIS_fnc_EGSpectator;
    
    private _cam = missionNamespace getVariable ["BIS_EGSpectatorCamera_camera", objNull];
    
    if (_cam != objNull) then {
        
        [{!isNull (findDisplay 60492)}, {
                eg_keyHandle = (findDisplay 60492) displayAddEventHandler ["keyDown", {call eg_keyHandler;}];
                eg_keyHandle = (findDisplay 46) displayAddEventHandler ["keyDown", {call eg_keyHandler2}];
        }, []] call CBA_fnc_waitUntilAndExecute;
        
        
        if (!killcam_active) then {
            //we move 2 meters back so player's body is visible
            _pos = ([_pos, -2, _dir] call BIS_fnc_relPos);
            _cam setposATL _pos;
            _cam setDir _dir;
        }
        else {
            missionNamespace setVariable ["killcam_toggle", false];
            
            //this cool piece of code adds key handler to spectator display
            //it takes some time for display to create, so we have to delay it.
            [{!isNull (findDisplay 60492)}, {
                killcam_keyHandle = (findDisplay 60492) displayAddEventHandler ["keyDown", {call killcam_toggleFnc;}];
            }, []] call CBA_fnc_waitUntilAndExecute;
            
            if (!isNull killcam_killer) then {
                killcam_distance = killcam_killer distance killcam_body;
                _pos = ([_pos, -1.8, ([killcam_body, killcam_killer] call BIS_fnc_dirTo)] call BIS_fnc_relPos);
                _cam setposATL _pos;
                
                //vector magic
                private _temp1 = ([getposASL _cam, getposASL killcam_killer] call BIS_fnc_vectorFromXToY);
                private _temp = (_temp1 call CBA_fnc_vect2Polar);
                
                //we check if camera is not pointing up, just in case
                if (abs(_temp select 2) > 89) then {_temp set [2, 0]};
                [_cam, [_temp select 1, _temp select 2]] call BIS_fnc_setObjectRotation;
            }
            else {
                _cam setposATL _pos;
                _cam setDir _dir;
            };
            
            killcam_texture = "a3\ui_f\data\gui\cfg\debriefing\enddeath_ca.paa";
            
            killcam_drawHandle = addMissionEventHandler ["Draw3D", {
                //we don't draw hud unless we toggle it by keypress
                if (missionNamespace getVariable ["killcam_toggle", false]) then {
                
                    if ((killcam_killer_pos select 0) != 0) then {
                        
                        private _u = killcam_unit_pos;
                        private _k = killcam_killer_pos;
                        if ((_u distance _k) < 2000) then {
                            //TODO do it better
                            drawLine3D [[(_u select 0)+0.01, (_u select 1)+0.01, (_u select 2)+0.01], [(_k select 0)+0.01, (_k select 1)+0.01, (_k select 2)+0.01], [1,0,0,1]];
                            drawLine3D [[(_u select 0)-0.01, (_u select 1)-0.01, (_u select 2)-0.01], [(_k select 0)-0.01, (_k select 1)-0.01, (_k select 2)-0.01], [1,0,0,1]];
                            drawLine3D [[(_u select 0)-0.01, (_u select 1)+0.01, (_u select 2)-0.01], [(_k select 0)-0.01, (_k select 1)+0.01, (_k select 2)-0.01], [1,0,0,1]];
                            drawLine3D [[(_u select 0)+0.01, (_u select 1)-0.01, (_u select 2)+0.01], [(_k select 0)+0.01, (_k select 1)-0.01, (_k select 2)+0.01], [1,0,0,1]];
                        };
                        if (!isNull killcam_killer) then {
                            private _killerName = name killcam_killer;
                            drawIcon3D [killcam_texture, [1,0,0,1], [eyePos killcam_killer select 0, eyePos killcam_killer select 1, (ASLtoAGL eyePos killcam_killer select 2) + 0.4], 0.7, 0.7, 0, _killerName + ", " + (str round killcam_distance) + "m", 1, 0.04, "PuristaMedium"];
                        };
                    }
                    else {
                        cutText ["killer info unavailable", "PLAIN DOWN"];
                        missionNamespace setVariable ["killcam_toggle", false];
                    };
                };
            }];//draw EH
        };//killcam (not) active
    };//checking camera
    
    private _killcam_msg = "";
    if (killcam_active) then {
        _killcam_msg = "Press <t color='#FFA500'>K</t> to toggle indicator showing location where you were killed from.<br/>";
    };
    private _text = format ["<t size='0.5' color='#ffffff'>%1
    Close spectator HUD by pressing <t color='#FFA500'>CTRL+H</t>.<br/>
    Press <t color='#FFA500'>SHIFT</t>, <t color='#FFA500'>ALT</t> or <t color='#FFA500'>SHIFT+ALT</t> to modify camera speed. Open map by pressing <t color='#FFA500'>M</t> and click anywhere to move camera to that postion.<br/> 
    Spectator controls can be customized in game <t color='#FFA500'>options->controls->'Camera'</t> tab.</t>", _killcam_msg];
    
    [_text, 0.55, 0.8, 20, 1] spawn BIS_fnc_dynamicText;

    [] spawn {
        while {(player getVariable [QGVAR(Spectating), false])} do {
            player setOxygenRemaining 1;
            sleep 0.25;
        };
    };
} else {
    [] call BIS_fnc_VRFadeIn;
};