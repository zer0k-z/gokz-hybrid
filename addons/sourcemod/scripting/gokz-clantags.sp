#include <sourcemod>

#include <cstrike>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN


#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Clan Tags", 
	author = "DanZay", 
	description = "Sets the clan tags of players", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};





// =====[ PLUGIN EVENTS ]=====

public void OnAllPluginsLoaded()
{

}

public void OnLibraryAdded(const char[] name)
{

}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	UpdateClanTag(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	Option coreOption;
	if (!GOKZ_IsCoreOption(option, coreOption))
	{
		return;
	}
	
	if (coreOption == Option_Mode)
	{
		UpdateClanTag(client);
	}
}

void UpdateClanTag(int client)
{
	if (!IsFakeClient(client))
	{
		CS_SetClientClanTag(client, gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
	}
}
