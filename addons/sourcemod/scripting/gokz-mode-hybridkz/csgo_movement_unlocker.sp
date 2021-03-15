
#if 0
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "CS:GO Movement Unlocker",
	author = "Peace-Maker",
	description = "Removes max speed limitation from players on the ground. Feels like CS:S.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}
#endif

Address g_iPatchAddress;
int g_iPatchRestore[100];
int g_iPatchRestoreBytes;

void OnPluginStart_MovementUnlocker()
{
	// Load the gamedata file.
	Handle hGameConf = LoadGameConfigFile("csgo_movement_unlocker.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Can't find csgo_movement_unlocker.games.txt gamedata.");
	
	// Get the address near our patch area inside CGameMovement::WalkMove
	Address iAddr = GameConfGetAddress(hGameConf, "WalkMoveMaxSpeed");
	if(iAddr == Address_Null)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find WalkMoveMaxSpeed address.");
	}
	
	// Get the offset from the start of the signature to the start of our patch area.
	int iCapOffset = GameConfGetOffset(hGameConf, "CappingOffset");
	if(iCapOffset == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find CappingOffset in gamedata.");
	}
	
	// Move right in front of the instructions we want to NOP.
	iAddr += view_as<Address>(iCapOffset);
	g_iPatchAddress = iAddr;
	
	// Get how many bytes we want to NOP.
	g_iPatchRestoreBytes = GameConfGetOffset(hGameConf, "PatchBytes");
	if(g_iPatchRestoreBytes == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find PatchBytes in gamedata.");
	}
	CloseHandle(hGameConf);
	
	//PrintToServer("CGameMovement::WalkMove VectorScale(wishvel, mv->m_flMaxSpeed/wishspeed, wishvel); ... at address %x", g_iPatchAddress);
	
	for (int i = 0; i < g_iPatchRestoreBytes; i++)
	{
		// Save the current instructions, so we can restore them on unload.
		int iData = LoadFromAddress(iAddr, NumberType_Int8);
		g_iPatchRestore[i] = iData;
		iAddr++;
	}
}

void OnPluginEnd_MovementUnlocker()
{
	MovementUnlocker_UnpatchBytes();
}

void MovementUnlocker_PatchBytes()
{
	if (g_iPatchAddress != Address_Null)
	{
		Address iAddr = g_iPatchAddress;
		for (int i = 0; i < g_iPatchRestoreBytes; i++)
		{
			// NOP
			StoreToAddress(iAddr, 0x90, NumberType_Int8);
			iAddr++;
		}
	}
}

void MovementUnlocker_UnpatchBytes()
{
	// Restore the original instructions, if we patched them.
	if (g_iPatchAddress != Address_Null)
	{
		for (int i = 0; i < g_iPatchRestoreBytes; i++)
		{
			StoreToAddress(g_iPatchAddress + view_as<Address>(i), g_iPatchRestore[i], NumberType_Int8);
		}
	}
}
