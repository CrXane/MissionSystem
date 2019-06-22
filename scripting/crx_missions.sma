/* Zombie Plague Missions System */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <zombieplague>

/* Download CromChat from GitHub 
 * https://github.com/OciXCrom/CromChat */
#include <cromchat>

#define team(%1) get_user_team(%1)

#define VERSION "3.2"
#define MENU_MAX_ITEMS 64

new filename[256];
new menu, j;

enum _:Items{
	MenuLevel[20],
	MenuType[2],
	MenuAmount[10],
	MenuTypeReward[2],
	MenuReward[10],
};

new Menu[MENU_MAX_ITEMS][Items];

enum _:Player_Info{
	//Player_Container[32],
	Player_MenuName[128],
	Player_MenuType[2],
	Player_MenuAmount[10],
	Player_MenuTypeReward[2],
	Player_MenuReward[10],
	Player_Infects,
	Player_Kills,
	Player_iMenuAmount,
	Player_iMenuReward,
	bool:challange,
	bool:complete
}

enum _:TYPE{
	CASH = 0,
	AMMO_PACKS
};

enum _:PLAYER{
	ZOMBIE = 1,
	HUMAN = 2
};

new Player_Challange[33][Player_Info];
new item_name[128], send_data[32];

new filename_content[][] = {
	"; Params",
	"; 1 - Mode [EASY, MEDIUM, HARD, any...]",
	"; 2 - Type [(k)ills, (i)nfectors]",
	"; 3 - Amount of required kills/infections",
	"; 4 - Reward Type [(c)ash, (a)mmo packs]",
	"; 5 - Amount",
	"",
	"; e.g:",
	"; ^"MEDIUM^" ^"K^" ^"5^" ^"C^" ^"5000^""
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
	new Line[64];
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
		parse(Line, Menu[j][MenuLevel], charsmax(Menu[][MenuLevel]), 
			Menu[j][MenuType], 	charsmax(Menu[][MenuType]), 
			Menu[j][MenuAmount], 	charsmax(Menu[][MenuAmount]),
			Menu[j][MenuTypeReward],charsmax(Menu[][MenuTypeReward]),
			Menu[j][MenuReward], 	charsmax(Menu[][MenuReward]));
			
		trim(Menu[j][MenuLevel]);
		trim(Menu[j][MenuType]);
		trim(Menu[j][MenuAmount]);
		trim(Menu[j][MenuTypeReward]);
		trim(Menu[j][MenuReward]);

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
	
	if (Player_Challange[id][challange] == true){
		new kills[32], finished[32], amount;
		
		switch (team(id)){
			case HUMAN: {
				amount = Player_Challange[id][Player_Kills];
				formatex(kills, charsmax(kills), "\wInfects\r: \w%d\y/\w%d", 
					amount, Player_Challange[id][Player_iMenuAmount]);
			}
			
			case ZOMBIE: {
				amount = Player_Challange[id][Player_Infects];
				formatex(kills, charsmax(kills), "\wKills\r: \w%d\y/\w%d", 
					amount, Player_Challange[id][Player_iMenuAmount]);
			}
		}
		
		if (amount >= Player_Challange[id][Player_iMenuAmount]){
			formatex(finished, charsmax(finished), "You completed this mission");
		}
		
		//CC_SendMessage(id, "%L", id, "CHANGED_NEXTMAP");
		menu = menu_create("Current Mission Selected", "menu_current");
		menu_additem(menu, Player_Challange[id][Player_MenuName]);
		menu_additem(menu, kills);
		if (finished[0]){
			menu_additem(menu, finished);
		}
		menu_additem(menu, "Exit");
		
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(id, menu);
		
		return PLUGIN_HANDLED;
	}
		
	menu = menu_create("Missions Menu", "menu_handler");

	switch (team(id)){
		case HUMAN: MenuAddT(menu);
		case ZOMBIE: MenuAddCT(menu);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item){
	if (item == MENU_EXIT){
		menu_destroy(menu);
	}
	
	new receive_data[32], Menu_Item_Name[64];
	new _access, item_callback;
	menu_item_getinfo(menu, item, _access, receive_data, charsmax(receive_data), Menu_Item_Name, charsmax(Menu_Item_Name), item_callback);
	
	copy(Player_Challange[id][Player_MenuName], charsmax(Player_Challange[][Player_MenuName]), Menu_Item_Name);
	//copy(Player_Challange[id][Player_Container], charsmax(Player_Challange[][Player_Container]), receive_data);
	
	parse(receive_data, Player_Challange[id][Player_MenuType],	charsmax(Player_Challange[][Player_MenuType]),
		Player_Challange[id][Player_MenuAmount], 		charsmax(Player_Challange[][Player_MenuAmount]),
		Player_Challange[id][Player_MenuTypeReward], 		charsmax(Player_Challange[][Player_MenuTypeReward]),
		Player_Challange[id][Player_MenuReward], 		charsmax(Player_Challange[][Player_MenuReward]));
	
	Player_Challange[id][Player_iMenuAmount] = str_to_num(Player_Challange[id][Player_MenuAmount]);
	Player_Challange[id][Player_iMenuReward] = str_to_num(Player_Challange[id][Player_MenuReward]);
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
	
	user_challange_complete(Attacker);
	
	return PLUGIN_CONTINUE;			
}

public reset_user_challange(id){
	//Player_Challange[id][Player_Container] 	= "";
	Player_Challange[id][Player_MenuName] 		= "";
	Player_Challange[id][Player_MenuType] 		= "";
	Player_Challange[id][Player_MenuAmount] 	= "";
	Player_Challange[id][Player_MenuTypeReward] 	= "";
	Player_Challange[id][Player_MenuReward] 	= "";
	Player_Challange[id][Player_Infects] 		= 0;
	Player_Challange[id][Player_Kills] 		= 0;
	Player_Challange[id][Player_iMenuAmount] 	= 0;
	Player_Challange[id][Player_iMenuReward] 	= 0;
	Player_Challange[id][challange] 		= false;
	Player_Challange[id][complete]	 		= false;
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

stock challange_completed(id, type){
	new reward;
	
	switch (type){
		case CASH: {
			reward = cs_get_user_money(id);
			cs_set_user_money(id, reward + Player_Challange[id][Player_iMenuReward]);
			CC_SendMessage(id, "%L", id, "MISSION_ACCOMPLISHED_CASH", Player_Challange[id][Player_iMenuReward]); 
		}
		
		case AMMO_PACKS: {
			reward = zp_get_user_ammo_packs(id);
			zp_set_user_ammo_packs(id, reward + Player_Challange[id][Player_iMenuReward]);
			CC_SendMessage(id, "%L", id, "MISSION_ACCOMPLISHED_AP", Player_Challange[id][Player_iMenuReward]);
		}
	}
	Player_Challange[id][complete] = true;
}

stock user_challange_complete(id){
	if (Player_Challange[id][challange] == true && Player_Challange[id][complete] == false){
		new amount;
		switch (team(id)){
			case HUMAN: {
				Player_Challange[id][Player_Kills]++
				amount = Player_Challange[id][Player_Kills];
			}
			
			case ZOMBIE: {
				Player_Challange[id][Player_Infects]++;
				amount = Player_Challange[id][Player_Infects];
			}
		}
		
		if (amount >= Player_Challange[id][Player_iMenuAmount]){
			if (equali(Player_Challange[id][Player_MenuTypeReward], "c")){
				challange_completed(id, CASH);
			}
					
			else if (equali(Player_Challange[id][Player_MenuTypeReward], "a")){
				challange_completed(id, AMMO_PACKS);
			}
		}
	}
}

stock MenuAddCT(menuid){
	for (new i = 0; i < j; i++){
		if (equali(Menu[i][MenuType], "k")){
			if (equali(Menu[i][MenuTypeReward], "a")){
				formatex(item_name, charsmax(item_name), "\r[\y%s\r] \wKill %s zombies \r(\y%s \wAP\r)",
					Menu[i][MenuLevel], Menu[i][MenuAmount], Menu[i][MenuReward]);
				formatex(send_data, charsmax(send_data), "%s %s %s %s", Menu[i][MenuType],
					Menu[i][MenuAmount], Menu[i][MenuTypeReward], Menu[i][MenuReward]);
			}
			
			else if (equali(Menu[i][MenuTypeReward], "c")){
				formatex(item_name, charsmax(item_name), "\r[\y%s\r] \wKill %s zombies \r(\w$\y%s\r)",
					Menu[i][MenuLevel], Menu[i][MenuAmount], Menu[i][MenuReward]);
				formatex(send_data, charsmax(send_data), "%s %s %s %s", Menu[i][MenuType],
					Menu[i][MenuAmount], Menu[i][MenuTypeReward], Menu[i][MenuReward]);
			}
			menu_additem(menuid, item_name, send_data);
		}
	}
}

stock MenuAddT(menuid){
	for (new i = 0; i < j; i++){
		if (equali(Menu[i][MenuType], "i")){
			if (equali(Menu[i][MenuTypeReward], "a")){
				formatex(item_name, charsmax(item_name), "\r[\y%s\r] \wInfect %s humans \r(\y%s \wAP\r)",
					Menu[i][MenuLevel], Menu[i][MenuAmount], Menu[i][MenuReward]);
				formatex(send_data, charsmax(send_data), "%s %s %s %s", Menu[i][MenuType],
					Menu[i][MenuAmount], Menu[i][MenuTypeReward], Menu[i][MenuReward]);
			}

			else if (equali(Menu[i][MenuTypeReward], "c")){
				formatex(item_name, charsmax(item_name), "\r[\y%s\r] \wInfect %s humans \r(\w$\y%s\r)",
					Menu[i][MenuLevel], Menu[i][MenuAmount], Menu[i][MenuReward]);
				formatex(send_data, charsmax(send_data), "%s %s %s %s", Menu[i][MenuType],
					Menu[i][MenuAmount], Menu[i][MenuTypeReward], Menu[i][MenuReward]);
			}
			menu_additem(menuid, item_name, send_data);
		}
	}
}
