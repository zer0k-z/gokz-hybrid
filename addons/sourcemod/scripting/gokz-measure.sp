#include <sourcemod>

#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN


#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Measure", 
	author = "DanZay", 
	description = "Provides tools for measuring things", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};



int gI_BeamModel;

#include "gokz-measure/commands.sp"
#include "gokz-measure/measure_menu.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-measure");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-measure.phrases");
	
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{

}

public void OnLibraryAdded(const char[] name)
{

}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	gI_BeamModel = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
} 