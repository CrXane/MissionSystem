/* NOTE
   A final unreleased "NOT-WORKING" version which I couldn't finish myself.
*/

/* Zombie Plague Missions System */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
//#include <zombieplague>
//#include <zp50_gamemodes>

/* Download CromChat from GitHub 
 * https://github.com/OciXCrom/CromChat */
#include <cromchat>

// Macros
#define team(%1) get_user_team(%1)

#define MenuMacro1(%1) formatex(item_name,charsmax(item_name),%1,Menu[i][MenuLevel],Menu[i][MenuAmount],Menu[i][MenuAmount]>1?"s":"",Menu[i][MenuReward],Menu[i][MenuTypeReward] == 1 ? "\w$":"\wAP")
#define MenuMacro2(%1) formatex(item_name,charsmax(item_name),%1,Menu[i][MenuLevel],Menu[i][MenuReward],Menu[i][MenuTypeReward] == 1? "\y$":"\yAP")

#define PlayerMacro1(%1) formatex(Menu_Item_Text,charsmax(Menu_Item_Text),%1,Player_Challange[id][Player_CustomAmount],Player_Challange[id][Player_MenuAmount])
#define PlayerMacro2(%1) formatex(Menu_Item_Text,charsmax(Menu_Item_Text),%1)
//

#define VERSION "4.0"
#define MENU_MAX_ITEMS 128

new filename[256];
new menu, j;

enum _:Items{
	MenuGameName[32],
	MenuTeam,
	MenuLevel[32],
	MenuMode,
	MenuAmount,
	MenuTypeReward,
	MenuReward,
	// -----------
	temp_MenuTeam[2],
	temp_MenuMode[2],
	temp_MenuAmount[10],
	temp_MenuTypeReward[2],
	temp_MenuReward[10]
};

new Menu[MENU_MAX_ITEMS][Items];

enum _:Player_Info{
	//Player_Container[32],
	Player_MenuName[128],
	Player_Team,
	Player_MenuMode,
	Player_MenuAmount,
	Player_MenuTypeReward,
	Player_MenuReward,
	Player_CustomAmount,
	bool:challange,
	bool:complete,
	// -----------
	temp_Player_Team[2],
	temp_Player_MenuMode[2],
	temp_Player_MenuAmount[10],
	temp_Player_MenuTypeReward[2],
	temp_Player_MenuReward[10]
}

enum _:TYPE{
	CASH = 1,
	AMMO_PACKS = 2
};

enum _:PLAYER{
	ZOMBIE = 1,
	HUMAN = 2
};

new Player_Challange[33][Player_Info];
new item_name[256], send_data[32];

new filename_content[][] = {
	"; Params",
	"",
	"; 1 - GameMode Name 	( ^"My GameMode Name^" )",
	"; 2 - Team 		( 1/Zombies 2/Humans )",
	"; 3 - Level 		( EASY, MEDIUM, HARD, any... )",
	"; 4 - Mode 		( 1/2/3/... )",
	"; 5 - Amount 		( if not neccessary leave ^"0^" )",
	"; 6 - Reward Type 	( 1/cash / 2/ammo packs )",
	"; 7 - Reward Amount 	( amount in number )",
	"",
	"; Modes",
	"",
	"; HUMANS",
	"; 1 - Kill <amount>",
	"; 2 - Headshot <amount>",
	"; 3 - Survive the round <0>",
	"; 4 - Kill zombie with a secondary weapon <amount>",
	"; 5 - Kill zombie with a grenade <amount>",
	"; 6 - Kill zombie with a knife <amount>",
	"; 7 - Survive a round without jumping <0>",
	"; 8 - Don't use any greandes <0>",
	"; 9 - No taken damage <0>",
	"",
	"; ZOMBIES",
	"; 1 - Infect <amount>",
	"; 2 - Headshot <amount>",
	"; 3 - Survive the round <0>",
	"; 4 - Infect human with grenade <amount>",
	"; 5 - Survive a round without jumping <0>",
	"; 6 - Don't use any grenades <0>",
	"; 7 - Hide and seek, don't get any damage <0>"
};

public plugin_init(){
	register_plugin("Missions Menu", VERSION, "Relaxing");
	register_clcmd("say /missions", "clcmd_menu");

	register_event("DeathMsg", "event_death", "a");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	register_dictionary("missions.txt");
	
	RegisterHam(Ham_Spawn, "player", "reset_user_challange", 1);
	
	CC_SetPrefix("[!gMission System!n]");
	
	get_configsdir(filename, charsmax(filename));
	add(filename, charsmax(filename), "/missions.ini");

	if (!file_exists(filename)){
		for (new i = 0; i < sizeof(filename_content); i++){
			write_file(filename, filename_content[i]);
		}
	}
	
	ReadData();
}

ReadData(){
	new Line[128];
	new f = fopen(filename, "rt");
	if (!f){
		set_fail_state("Error opening %s file", filename);
	}

	while (!feof(f)){
		fgets(f, Line, charsmax(Line));
		trim(Line);
		
		if (Line[0] == ';' || !Line[0] || Line[0] == '^n'){
			continue;
		}
		
		remove_quotes(Line);
		parse(Line, Menu[j][MenuGameName],	charsmax(Menu[][MenuGameName]), 
			Menu[j][temp_MenuTeam], 	charsmax(Menu[][temp_MenuTeam]), 
			Menu[j][MenuLevel], 		charsmax(Menu[][MenuLevel]),
			Menu[j][temp_MenuMode],		charsmax(Menu[][temp_MenuMode]),
			Menu[j][temp_MenuAmount], 	charsmax(Menu[][temp_MenuAmount]),
			Menu[j][temp_MenuTypeReward], 	charsmax(Menu[][temp_MenuTypeReward]),
			Menu[j][temp_MenuReward], 	charsmax(Menu[][temp_MenuReward]));
			
		trim(Menu[j][MenuGameName]);
		trim(Menu[j][temp_MenuTeam]);
		trim(Menu[j][MenuLevel]);
		trim(Menu[j][temp_MenuMode]);
		trim(Menu[j][temp_MenuAmount]);
		trim(Menu[j][temp_MenuTypeReward]);
		trim(Menu[j][temp_MenuReward]);
		
		Menu[j][MenuTeam] 	= str_to_num(Menu[j][temp_MenuTeam]);
		Menu[j][MenuMode] 	= str_to_num(Menu[j][temp_MenuMode]);
		Menu[j][MenuAmount] 	= str_to_num(Menu[j][temp_MenuAmount]);
		Menu[j][MenuTypeReward] 	= str_to_num(Menu[j][temp_MenuTypeReward]);
		Menu[j][MenuReward] 	= str_to_num(Menu[j][temp_MenuReward]);

		j++;
	}
	fclose(f);
	
	if (!j){
		set_fail_state("No missions found on %s file", filename);
	}
}

public client_disconnected(id){
	reset_user_challange(id);
}

public clcmd_menu(id){
	if (!is_user_alive(id)){
		CC_SendMessage(id, "%L", id, "ALIVE_ONLY");
		return PLUGIN_HANDLED;
	}
	
	/*if (zp_has_round_started() != 2){
		CC_SendMessage(id, "%L", id, "ROUND_MUST_START");
		return PLUGIN_HANDLED;
	}*/
	
	BuildMenu_Main(id);
	return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item){
	if (item == MENU_EXIT){
		menu_destroy(menu);
	}
	
	new receive_data[32], Menu_Item_Name[128];
	new _access, item_callback;
	menu_item_getinfo(menu, item, _access, receive_data, charsmax(receive_data), Menu_Item_Name, charsmax(Menu_Item_Name), item_callback);
	
	copy(Player_Challange[id][Player_MenuName], charsmax(Player_Challange[][Player_MenuName]), Menu_Item_Name);
	//copy(Player_Challange[id][Player_Container], charsmax(Player_Challange[][Player_Container]), receive_data);
	
	parse(receive_data, Player_Challange[id][temp_Player_Team],	charsmax(Player_Challange[][temp_Player_Team]),
		Player_Challange[id][temp_Player_MenuMode], 		charsmax(Player_Challange[][temp_Player_MenuMode]),
		Player_Challange[id][temp_Player_MenuAmount], 		charsmax(Player_Challange[][temp_Player_MenuAmount]),
		Player_Challange[id][temp_Player_MenuTypeReward], 	charsmax(Player_Challange[][temp_Player_MenuTypeReward]),
		Player_Challange[id][temp_Player_MenuReward], 		charsmax(Player_Challange[][temp_Player_MenuReward]));
	
	Player_Challange[id][Player_Team]		= str_to_num(Player_Challange[id][temp_Player_Team]);
	Player_Challange[id][Player_MenuMode] 		= str_to_num(Player_Challange[id][temp_Player_MenuMode]);
	Player_Challange[id][Player_MenuTypeReward]	= str_to_num(Player_Challange[id][temp_Player_MenuTypeReward]);
	Player_Challange[id][Player_MenuReward] 		= str_to_num(Player_Challange[id][temp_Player_MenuReward]);
	
	Player_Challange[id][challange] = true;
	Player_Challange[id][complete] 	= false;
	
	CC_SendMessage(id, "%L", id, "SELECTED_SUCCESSFULLY");
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public menu_current(id, menu, item){
	if (item || !item){
		menu_destroy(menu);
	}
	return PLUGIN_HANDLED;
}

public event_death(){
	new Attacker	= read_data(1);
	new Victim	= read_data(2);
	
	if (team(Attacker) == team(Victim) || Attacker == Victim
		|| !is_user_connected(Attacker) || !is_user_connected(Victim)){
			return PLUGIN_HANDLED;
	}
	
	if (Player_Challange[Victim][challange] == true){
		CC_SendMessage(Victim, "%L", Victim, "MISSION_FAILED");
		reset_user_challange(Victim);
	}
	
	check_challange(Attacker);
	
	return PLUGIN_CONTINUE;			
}

public reset_user_challange(id){
	//Player_Challange[id][Player_Container] 	= "";
	Player_Challange[id][Player_MenuName] 		= "";
	Player_Challange[id][Player_Team] 		= 0;
	Player_Challange[id][Player_MenuMode] 		= 0;
	Player_Challange[id][Player_MenuAmount] 	= 0;
	Player_Challange[id][Player_MenuTypeReward] 	= 0;
	Player_Challange[id][Player_MenuReward] 	= 0;
	Player_Challange[id][Player_CustomAmount] 	= 0;
	Player_Challange[id][challange] 		= false;
	Player_Challange[id][complete]	 		= false;
	// -----------
	Player_Challange[id][temp_Player_Team] 		= "";
	Player_Challange[id][temp_Player_MenuMode] 	= "";
	Player_Challange[id][temp_Player_MenuAmount] 	= "";
	Player_Challange[id][temp_Player_MenuTypeReward]= "";
	Player_Challange[id][temp_Player_MenuReward] 	= "";
}

public logevent_round_end(){
	new players[32], num, pid;
	get_players(players, num);

	for (new i = 0; i < num; i++){
		pid = players[i];
		if (Player_Challange[pid][challange] == true
			&& Player_Challange[pid][complete] == false){
			CC_SendMessage(pid, "%L", pid, "MISSION_FAILED");
		}
	}
}

////////////////////////////////
//           Stocks           //
////////////////////////////////

stock check_challange(id){
	if (Player_Challange[id][challange] == true && Player_Challange[id][complete] == false){
		new amount = Player_Challange[id][Player_CustomAmount]++;
		
		switch (team(id)){
			case ZOMBIE: {
				switch (Player_Challange[id][Player_MenuMode]){
					case 1, 2, 4: {
						if (amount >= Player_Challange[id][Player_MenuAmount]){
							challange_win(id, Player_Challange[id][Player_MenuTypeReward]);
						}
					}
					
					case 3, 6, 7: {
						if (amount){
							challange_win(id, Player_Challange[id][Player_MenuTypeReward]);
						}
					}	
				}
			}
			
			case HUMAN: {
				switch (Player_Challange[id][Player_MenuMode]){
					case 1, 2, 4, 5, 6: {
						if (amount >= Player_Challange[id][Player_MenuAmount]){
							challange_win(id, Player_Challange[id][Player_MenuTypeReward]);
						}
					}
					
					case 3, 7, 8, 9: {
						if (amount){
							challange_win(id, Player_Challange[id][Player_MenuTypeReward]);
						}
					}	
				}
			}
		}
	}
}

stock challange_win(id, _Type_Reward){
	new reward;
	switch (_Type_Reward){
		case CASH:{
			reward = cs_get_user_money(id);
			cs_set_user_money(id, reward + Player_Challange[id][Player_MenuReward]);
			CC_SendMessage(id, "%L", id, "MISSION_ACCOMPLISHED_CASH", Player_Challange[id][Player_MenuReward]); 
		}
								
		case AMMO_PACKS: {
			//reward = zp_get_user_ammo_packs(id);
			//zp_set_user_ammo_packs(id, reward + Player_Challange[id][Player_MenuReward]);
			reward = cs_get_user_money(id);
			cs_set_user_money(id, reward + Player_Challange[id][Player_MenuReward]);
			CC_SendMessage(id, "%L", id, "MISSION_ACCOMPLISHED_AP", Player_Challange[id][Player_MenuReward]);
		}
	}
	
	Player_Challange[id][complete] = true;
}

stock BuildMenu_Main(id){
	new finished[32], required[16];
	if (Player_Challange[id][challange] == true){
		new Menu_Item_Text[64];
		
		switch(team(id)){
			case ZOMBIE: {
				switch (Player_Challange[id][Player_MenuMode]){
					case 1: PlayerMacro1("\wInfects\r: \w%d\y/\w%d");
					case 2: PlayerMacro1("\wHeadshot\r: \w%d\y/\w%d");
					case 3: PlayerMacro2("\wSurvive the round");
					case 4: PlayerMacro1("\wInfect human with grenade: \w%d\y/\w%d");
					case 5: PlayerMacro2("\wSurvive a round without jumping");
					case 6: PlayerMacro2("\wDon't use any grenades");
					case 7: PlayerMacro2("\wHide and seek, don't get any damage");
				}	
			}
			
			case HUMAN: {
				switch (Player_Challange[id][Player_MenuMode]){
					case 1: PlayerMacro1("\wKills\r: \w%d\y/\w%d");
					case 2: PlayerMacro1("\wHeadshot\r: \w%d\y/\w%d");
					case 3: PlayerMacro2("\wSurvive the round");
					case 4: PlayerMacro1("\wKill zombie with a secondary weapon: \w%d\y/\w%d");
					case 5: PlayerMacro1("\wKill zombie with a grenade: \w%d\y/\w%d");
					case 6: PlayerMacro1("\wKill zombie with a knife: \w%d\y/\w%d");
					case 7: PlayerMacro2("\wSurvive a round without jumping");
					case 8: PlayerMacro2("\wDon't use any greandes");
					case 9: PlayerMacro2("\wNo taken damage");
				}	
			}
		}
		
		if (Player_Challange[id][Player_MenuMode]){
			formatex(finished, charsmax(finished), "You completed this mission");
		}
		
		//CC_SendMessage(id, "%L", id, "CHANGED_NEXTMAP");
		menu = menu_create("Current Mission Selected", "menu_current");
		menu_additem(menu, Player_Challange[id][Player_MenuName]);
		//menu_additem(menu, kills);
		if (finished[0]){
			menu_additem(menu, finished);
		}
		menu_additem(menu, "Exit");
		
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(id, menu);
		
		return PLUGIN_HANDLED;
	}
		
	menu = menu_create("Missions Menu", "menu_handler");

	BuildMenu_Missions(menu, team(id));
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

stock BuildMenu_Missions(menuid, p_Team){
	new _get_current_gamemode;
	for (new i = 0; i < j; i++){
		//_get_current_gamemode = zp_gamemodes_get_id(Menu[i][MenuGameName]);
		
		//if (zp_gamemodes_get_current() == _get_current_gamemode){
		if (i == i){
			if (Menu[i][MenuTeam] == p_Team){
				switch (p_Team){
					case ZOMBIE: {
						switch (Menu[i][MenuMode]){
							case 1: MenuMacro1("\r[\y%s\r] \wInfect %d human%s\r \r(\w%d %d\r)");
							case 2: MenuMacro1("\r[\y%s\r] \wHeadshot %d human%s\r \r(\w%d %s\r)");
							case 3: MenuMacro2("\r[\y%s\r] \wSurvive the round \r(\w%d %s\r)");
							case 4: MenuMacro1("\r[\y%s\r] \wInfect %d human%s with grenade \r(\w%d %s\r)");
							case 5: MenuMacro2("\r[\y%s\r] \wSurvive a round without jumping \r(\w%d %s\r)");
							case 6: MenuMacro2("\r[\y%s\r] \wDon't use any grenades \r(\w%d %s\r)");
							case 7: MenuMacro2("\r[\y%s\r] \wHide and seek, don't get any damage \r(\w%d %s\r)");
						}                                         
					}
					
					case HUMAN: {
						switch (Menu[i][MenuMode]){
							case 1: MenuMacro1("\wKill %d zombie%s \r(\w%s %s\r)");
							case 2: MenuMacro1("\wHeadshot %d zombie%s \r(\w%s %s\r)");
							case 3: MenuMacro2("\wSurvive the round \r(\w%s %s\r)");
							case 4: MenuMacro1("\wKill %d zombie%s with a secondary weapon \r(\w%s %s\r)");
							case 5: MenuMacro1("\wKill %d zombie%s with a grenade \r(\w%s %s\r)");
							case 6: MenuMacro1("\wKill %d zombie%s with a knife \r(\w%s %s\r)");
							case 7: MenuMacro2("\wSurvive a round without jumping \r(\w%s %s\r)");
							case 8: MenuMacro2("\wDon't use any greandes \r(\w%s %s\r)");
							case 9: MenuMacro2("\wNo taken damage \r(\w%s %s\r)");
						}       
					}
				}
				formatex(send_data, charsmax(send_data), "%d %d %d %d %d", Menu[i][MenuTeam], Menu[i][MenuMode], Menu[i][MenuAmount], Menu[i][MenuTypeReward], Menu[i][MenuReward]);
				menu_additem(menuid, item_name, send_data);
			}
		}
	}
}
