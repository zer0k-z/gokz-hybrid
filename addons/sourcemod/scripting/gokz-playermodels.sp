#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>

#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN


#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Player Models", 
	author = "DanZay", 
	description = "Sets player's model upon spawning", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};


#define PLAYER_MODEL_T "models/player/tm_leet_varianta.mdl"
#define PLAYER_MODEL_CT "models/player/ctm_idf_variantc.mdl"

ConVar gCV_gokz_player_models_alpha;
ConVar gCV_sv_disable_immunity_alpha;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-playermodels");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
	HookEvents();
}

public void OnAllPluginsLoaded()
{

}

public void OnLibraryAdded(const char[] name)
{

}



// =====[ CLIENT EVENTS ]=====

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		UpdatePlayerModel(client);
	}
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	PrecachePlayerModels();
}



// =====[ GENERAL ]=====

void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-playermodels", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_gokz_player_models_alpha = AutoExecConfig_CreateConVar("gokz_player_models_alpha", "65", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	gCV_gokz_player_models_alpha.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	gCV_sv_disable_immunity_alpha = FindConVar("sv_disable_immunity_alpha");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_player_models_alpha)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				UpdatePlayerModelAlpha(client);
			}
		}
	}
}



// =====[ PLAYER MODELS ]=====

void UpdatePlayerModel(int client)
{
	// Do this after a delay so that gloves apply correctly after spawning
	CreateTimer(0.1, Timer_UpdatePlayerModel, GetClientUserId(client));
}

public Action Timer_UpdatePlayerModel(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	switch (GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			SetEntityModel(client, PLAYER_MODEL_T);
		}
		case CS_TEAM_CT:
		{
			SetEntityModel(client, PLAYER_MODEL_CT);
		}
	}
	
	UpdatePlayerModelAlpha(client);
}

void UpdatePlayerModelAlpha(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, _, _, _, gCV_gokz_player_models_alpha.IntValue);
}

void PrecachePlayerModels()
{
	gCV_sv_disable_immunity_alpha.IntValue = 1; // Ensures player transparency works	
	
	PrecacheModel(PLAYER_MODEL_T, true);
	PrecacheModel(PLAYER_MODEL_CT, true);
} 