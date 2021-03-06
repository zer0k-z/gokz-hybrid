#include <sourcemod>

#include <sdkhooks>
#include <sdktools>

#include <movementapi>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/core>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1

#include "gokz-mode-hybridkz/csgo_movement_unlocker.sp"

public Plugin myinfo = 
{
	name = "GOKZ Mode - HybridKZ", 
	author = "DanZay, zer0.k", 
	description = "HybridKZ mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define MODE_VERSION 4

#define PERF_MIN_SPEED_CAP 325.0
#define PERF_MAX_SPEED_CAP 650.0
#define PERF_SPEED_CAP_GAIN 32.5
#define PERF_TICKS 3

#define PS_MAX_REWARD_TURN_RATE 0.703125 // Degrees per tick (90 degrees per second)
#define PS_MAX_TURN_RATE_DECREMENT 0.015625 // Degrees per tick (2 degrees per second)
#define PS_SPEED_MAX 26.0 // Units
#define PS_SPEED_INCREMENT 0.65 // Units per tick
#define PS_GRACE_TICKS 3 // No. of ticks allowed to fail prestrafe checks when prestrafing - helps players with low fps

#define DUCK_SPEED_NORMAL 8.0
#define DUCK_SPEED_MINIMUM 6.0234375 // Equal to if you just ducked/unducked for the first time in a while

#define GROUND_SPEED_CAP_SOFT_TICK 4 // at which tick on ground to clamp speed on ground

#define STAMINA_SPEED_FACTOR 0.333333 // Falling at 300u/s vertically results in 10% speed loss
#define STAMINA_MIN_SPEED_FACTOR 0.5
#define STAMINA_JUMP_FACTOR 0.4
#define STAMINA_MIN_JUMP_VELOCITY 270.380968 // 48 units high
#define STAMINA_MIN_RECOVERY_RATE 8.841110 // Fully recover stamina lost from a noduck longjump in one doubleduck

#define DOUBLEDUCK_HEIGHT 36.0 // Has to be more or equal to 20 units.
#define DOUBLEDUCK_GRACE_FRAMES 5
#define DOUBLEDUCK_MIN_SPEED_SCALE 0.75 // Maximum speed reduction
#define STANDING_MINS view_as<float>({-16.0, -16.0,  0.0})
#define STANDING_MAXS view_as<float>({ 16.0,  16.0, 63.0})

float gF_ModeCVarValues[MODECVAR_COUNT] = 
{
	6.5,  // sv_accelerate
	0.0,  // sv_accelerate_use_weapon_speed
	100.0,  // sv_airaccelerate
	30.0,  // sv_air_max_wishspeed
	1.0,  // sv_enablebunnyhopping
	5.2,  // sv_friction
	800.0,  // sv_gravity
	301.993377,  // sv_jump_impulse
	1.0,  // sv_ladder_scale_speed
	0.0,  // sv_ledge_mantle_helper
	320.0,  // sv_maxspeed
	3500.0,  // sv_maxvelocity
	0.0,  // sv_staminajumpcost
	0.0,  // sv_staminalandcost
	0.0,  // sv_staminamax
	0.0,  // sv_staminarecoveryrate
	0.7,  // sv_standable_normal
	0.0,  // sv_timebetweenducks
	0.7,  // sv_walkable_normal
	10.0,  // sv_wateraccelerate
	0.8,  // sv_water_movespeed_multiplier
	0.0,  // sv_water_swim_mode 
	0.0,  // sv_weapon_encumbrance_per_item
	0.0 // sv_weapon_encumbrance_scale
};

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];

float gF_PSBonusSpeed[MAXPLAYERS + 1];
float gF_PSVelMod[MAXPLAYERS + 1];
float gF_PSVelModLanding[MAXPLAYERS + 1];
bool gB_PSTurningLeft[MAXPLAYERS + 1];
float gF_PSTurnRate[MAXPLAYERS + 1];
int gI_PSTicksSinceIncrement[MAXPLAYERS + 1];

int gI_OldButtons[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
float gF_OldOrigin[MAXPLAYERS + 1][3];
float gF_OldAngles[MAXPLAYERS + 1][3];
float gF_OldVelocity[MAXPLAYERS + 1][3];

float gF_PerfTakeoffSpeedCap[MAXPLAYERS + 1];

bool gB_Jumpbugged[MAXPLAYERS + 1];
bool gB_AllowDoubleDuck[MAXPLAYERS + 1];
bool gB_JustDoubleDucked[MAXPLAYERS + 1];
float gF_Stamina[MAXPLAYERS + 1];
int gI_OldFlags[MAXPLAYERS + 1];


// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	if (FloatAbs(1.0 / GetTickInterval() - 128.0) > EPSILON)
	{
		SetFailState("gokz-mode-HybridKZ only supports 128 tickrate servers.");
	}
	
	OnPluginStart_MovementUnlocker();

	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_HybridKZ, true, MODE_VERSION);
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnPluginEnd()
{
	if (gB_GOKZCore)
	{
		GOKZ_SetModeLoaded(Mode_HybridKZ, false);
	}
	OnPluginEnd_MovementUnlocker();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_HybridKZ, true, MODE_VERSION);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZCore = gB_GOKZCore && !StrEqual(name, "gokz-core");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	ResetClient(client);
	
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
	SDKHook(client, SDKHook_PostThink, SDKHook_OnClientPostThink);
	if (IsUsingMode(client))
	{
		ReplicateConVars(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	
	KZPlayer player = KZPlayer(client);
	RemoveCrouchJumpBind(player, buttons);
	ReduceDuckSlowdown(player);
	ApplyGroundSpeedCap(player, cmdnum);

	int flags = GetEntityFlags(player.ID);
	if (player.Jumped && !(flags & FL_ONGROUND) && gI_OldFlags[player.ID] & FL_ONGROUND)
	{
		ApplyJumpStamina(player);
	}
	

	ApplyGroundStamina(player, flags);
	TweakVelMod(player, angles);
	FixWaterBoost(player, buttons);
	if (gB_Jumpbugged[player.ID])
	{
		TweakJumpbug(player);
	}
	
	// Restore stamina
	gF_Stamina[player.ID] -= FloatMax(STAMINA_MIN_RECOVERY_RATE, gF_Stamina[player.ID] / 33); // You get back all stamina in 0.89s (worst scenario)
	gF_Stamina[player.ID] = FloatMax(gF_Stamina[player.ID], 0.0);

	DoDoubleDuck(player, buttons, cmdnum);
	gB_Jumpbugged[player.ID] = false;
	gI_OldButtons[player.ID] = buttons;
	gI_OldFlags[player.ID] = GetEntityFlags(player.ID);
	gB_OldOnGround[player.ID] = Movement_GetOnGround(client);	
	player.GetOrigin(gF_OldOrigin[player.ID]);
	Movement_GetEyeAngles(client, gF_OldAngles[player.ID]);
	Movement_GetVelocity(client, gF_OldVelocity[client]);
	return Plugin_Continue;
}

public void SDKHook_OnClientPreThink_Post(int client)
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return;
	}
	
	// Don't tweak convars if GOKZ isn't running
	if (gB_GOKZCore)
	{
		// need to cap speed to 250.0 if it's between 250 and 278 and prestrafe mode isn't css/1.6,
		// so that you don't get doubled prestrafe from css/1.6 pre because of the unlocked speed.
		float speed = Movement_GetSpeed(client);
		if (speed > 278.0)
		{
			MovementUnlocker_PatchBytes();
		}
		else
		{
			MovementUnlocker_UnpatchBytes();
		}
		TweakConVars();
	}
}

public void SDKHook_OnClientPostThink(int client)
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return;
	}
	
	/*
		Why are we using PostThink for slope boost fix?
		
		MovementAPI measures landing speed, calls forwards etc. during 
		PostThink_Post. We want the slope fix to apply it's speed before 
		MovementAPI does this, so that we can apply tweaks based on the 
		'fixed' landing speed.
	*/
	SlopeFix(client);
}

public void Movement_OnStartTouchGround(int client)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	KZPlayer player = KZPlayer(client);
	ApplyLandStamina(player);
	gF_PSVelModLanding[player.ID] = gF_PSVelMod[player.ID];
	gB_JustDoubleDucked[player.ID] = false;
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (jumped)
	{
		TweakJump(player);
		TweakJumpHeight(player);
	}
	else if (gB_GOKZCore)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	if (jumpbug)
	{
		gB_Jumpbugged[client] = true;
	}
}

public void Movement_OnChangeMovetype(int client, MoveType oldMovetype, MoveType newMovetype)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (gB_GOKZCore && newMovetype == MOVETYPE_WALK)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_HybridKZ)
	{
		ReplicateConVars(client);
	}
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	ResetClient(client);
}



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_HybridKZ;
}

void ResetClient(int client)
{
	KZPlayer player = KZPlayer(client);
	ResetVelMod(player);
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i] = FindConVar(gC_ModeCVars[i]);
	}
}

void TweakConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].FloatValue = gF_ModeCVarValues[i];
	}
}

void ReplicateConVars(int client)
{
	/*
		Replicate convars only when player changes mode in GOKZ
		so that lagg isn't caused by other players using other
		modes, and also as an optimisation.
	*/
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].ReplicateToClient(client, FloatToStringEx(gF_ModeCVarValues[i]));
	}
}



// =====[ VELOCITY MODIFIER ]=====

void TweakVelMod(KZPlayer player, const float angles[3])
{
	player.VelocityModifier = CalcPrestrafeVelMod(player, angles) * CalcWeaponVelMod(player);
}

void ResetVelMod(KZPlayer player)
{
	gF_PSBonusSpeed[player.ID] = 0.0;
	gF_PSVelMod[player.ID] = 1.0;
	gF_PSTurnRate[player.ID] = 0.0;
	gF_PerfTakeoffSpeedCap[player.ID] = PERF_MIN_SPEED_CAP;
}

float CalcPrestrafeVelMod(KZPlayer player, const float angles[3])
{
	gI_PSTicksSinceIncrement[player.ID]++;
	
	// Short circuit if speed is 0 (also avoids divide by 0 errors)
	if (player.Speed < EPSILON)
	{
		ResetVelMod(player);
		return gF_PSVelMod[player.ID];
	}
	
	// Current speed without bonus
	float baseSpeed = FloatMin(SPEED_NORMAL, player.Speed / gF_PSVelMod[player.ID]);
	
	float newBonusSpeed = gF_PSBonusSpeed[player.ID];
	
	// If player is on the ground and turning at the required speed, and has the correct button inputs, reward it
	if (player.OnGround)
	{
		if (player.Turning && ValidPrestrafeButtons(player))
		{
			
			// Keep track of the direction of the turn
			gB_PSTurningLeft[player.ID] = player.TurningLeft;
			
			// Step one of calculating new turn rate
			float newTurningRate = FloatAbs(CalcDeltaAngle(gF_OldAngles[player.ID][1], angles[1]));

			// If no turning for just a few ticks, then forgive and calculate reward based on that no. of ticks
			if (gI_PSTicksSinceIncrement[player.ID] <= PS_GRACE_TICKS)
			{
				// This turn occurred over multiple ticks, so scale appropriately
				// Also cap turn rate at maximum reward turn rate
				newTurningRate = FloatMin(PS_MAX_REWARD_TURN_RATE, 
					newTurningRate / gI_PSTicksSinceIncrement[player.ID]);
				
				// Limit how fast turn rate can decrease (also scaled appropriately)
				gF_PSTurnRate[player.ID] = FloatMax(newTurningRate, 
					gF_PSTurnRate[player.ID] - PS_MAX_TURN_RATE_DECREMENT * gI_PSTicksSinceIncrement[player.ID]);
				
				newBonusSpeed += CalcPreRewardSpeed(gF_PSTurnRate[player.ID], baseSpeed) * gI_PSTicksSinceIncrement[player.ID];
			}
			else
			{
				// Cap turn rate at maximum reward turn rate
				newTurningRate = FloatMin(PS_MAX_REWARD_TURN_RATE, newTurningRate);
				
				// Limit how fast turn rate can decrease
				gF_PSTurnRate[player.ID] = FloatMax(newTurningRate, 
					gF_PSTurnRate[player.ID] - PS_MAX_TURN_RATE_DECREMENT);
				
				// This is normal turning behaviour
				newBonusSpeed += CalcPreRewardSpeed(gF_PSTurnRate[player.ID], baseSpeed);
			}

			gI_PSTicksSinceIncrement[player.ID] = 0;
		}
		else if (gI_PSTicksSinceIncrement[player.ID] > PS_GRACE_TICKS)
		{
			// They definitely aren't turning, but limit how fast turn rate can decrease
			gF_PSTurnRate[player.ID] = FloatMax(0.0, 
				gF_PSTurnRate[player.ID] - PS_MAX_TURN_RATE_DECREMENT);
		}
	}
		
	
	if (newBonusSpeed < 0.0)
	{
		// Keep velocity modifier positive
		newBonusSpeed = 0.0;
	}
	else
	{
		// Scale the bonus speed based on current base speed and turn rate
		float baseSpeedScaleFactor = baseSpeed / SPEED_NORMAL; // Max 1.0
		float turnRateScaleFactor = FloatMin(1.0, gF_PSTurnRate[player.ID] / PS_MAX_REWARD_TURN_RATE);
		float scaledMaxBonusSpeed = PS_SPEED_MAX * baseSpeedScaleFactor * turnRateScaleFactor;
		newBonusSpeed = FloatMin(newBonusSpeed, scaledMaxBonusSpeed);
	}
	
	gF_PSBonusSpeed[player.ID] = newBonusSpeed;
	gF_PSVelMod[player.ID] = 1.0 + (newBonusSpeed / baseSpeed);	
	return gF_PSVelMod[player.ID];
}

bool ValidPrestrafeButtons(KZPlayer player)
{
	bool forwardOrBack = player.Buttons & (IN_FORWARD | IN_BACK) && !(player.Buttons & IN_FORWARD && player.Buttons & IN_BACK);
	bool leftOrRight = player.Buttons & (IN_MOVELEFT | IN_MOVERIGHT) && !(player.Buttons & IN_MOVELEFT && player.Buttons & IN_MOVERIGHT);
	return forwardOrBack && leftOrRight;
}

float CalcPreRewardSpeed(float yawDiff, float baseSpeed)
{
	// Formula
	float reward;
	if (yawDiff >= PS_MAX_REWARD_TURN_RATE)
	{
		reward = PS_SPEED_INCREMENT;
	}
	else
	{
		reward = PS_SPEED_INCREMENT * (yawDiff / PS_MAX_REWARD_TURN_RATE);
	}
	
	return reward * baseSpeed / SPEED_NORMAL;
}

float CalcWeaponVelMod(KZPlayer player)
{
	return SPEED_NORMAL / player.MaxSpeed;
}



// =====[ JUMPING ]=====

void TweakJumpHeight(KZPlayer player)
{
	if (!Movement_GetDucking(player.ID) && !(GetEntityFlags(player.ID) & FL_DUCKING))
	{
		// Velocity tweak
		float velocity[3];
		float playergravity = GetEntityGravity(player.ID);
		float servergravity = GetConVarFloat(FindConVar("sv_gravity"));
		player.GetVelocity(velocity);
		if (playergravity == 0.0)
		{
			velocity[2] += 0.5 * servergravity * GetGameFrameTime();
		}
		else
		{
			velocity[2] += GetEntityGravity(player.ID) * 0.5 * servergravity * GetGameFrameTime();
		}
		player.SetVelocity(velocity);

		// Origin tweak
		float mins[3], maxs[3], startPosition[3], endPosition[3], newOrigin[3];
		
		player.GetOrigin(startPosition);
		
		endPosition = startPosition;
		endPosition[2] = startPosition[2] + 0.5 * servergravity * GetGameFrameTime() * GetGameFrameTime();
		
		GetEntPropVector(player.ID, Prop_Send, "m_vecMins", mins);
		GetEntPropVector(player.ID, Prop_Send, "m_vecMaxs", maxs);
		
		Handle trace = TR_TraceHullFilterEx(
			startPosition, 
			endPosition, 
			mins, 
			maxs, 
			MASK_PLAYERSOLID, 
			TraceEntityFilterPlayers, 
			player.ID);
		
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(newOrigin, trace);
			
			// Set vertical velocity to match what happens when player hits a ceiling
			float newVelocity[3];
			player.GetVelocity(newVelocity);
			newVelocity[2] = -3.125;
			player.SetVelocity(newVelocity);
		}
		else
		{
			player.GetOrigin(newOrigin);
			newOrigin[2] = newOrigin[2] + 0.5 * servergravity * GetGameFrameTime() * GetGameFrameTime();
		}
		
		player.SetOrigin(newOrigin);
		
		delete trace;
	}	
}
void TweakJump(KZPlayer player)
{
	int cmdsSinceLanding = player.TakeoffCmdNum - player.LandingCmdNum;
	
	if (cmdsSinceLanding <= PERF_TICKS)
	{
		if (cmdsSinceLanding == 1)
		{
			NerfRealPerf(player);
		}
		if (cmdsSinceLanding > 1 || player.TakeoffSpeed > SPEED_NORMAL)
		{
			ApplyTweakedTakeoffSpeed(player);

			// Restore prestrafe lost due to briefly being on the ground
			gF_PSVelMod[player.ID] = gF_PSVelModLanding[player.ID];
			
			if (gB_GOKZCore)
			{
				player.GOKZHitPerf = true;
				player.GOKZTakeoffSpeed = player.Speed;
			}
		}
		else if (gB_GOKZCore)
		{
			player.GOKZHitPerf = true;
			player.GOKZTakeoffSpeed = player.TakeoffSpeed;
		}
	}
	else if (gB_GOKZCore)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

void ApplyTweakedTakeoffSpeed(KZPlayer player)
{
	// Note that resulting velocity has same direction as landing velocity, not current velocity
	float velocity[3], baseVelocity[3], newVelocity[3];
	player.GetVelocity(velocity);
	player.GetBaseVelocity(baseVelocity);
	player.GetLandingVelocity(newVelocity);
	
	newVelocity[2] = velocity[2];
	SetVectorHorizontalLength(newVelocity, CalcTweakedTakeoffSpeed(player));
	AddVectors(newVelocity, baseVelocity, newVelocity);
	
	player.SetVelocity(newVelocity);
}

void NerfRealPerf(KZPlayer player)
{
	// Not worth worrying about if player is already falling
	if (player.VerticalVelocity < EPSILON)
	{
		return;
	}
	
	// Work out where the ground was when they bunnyhopped
	float startPosition[3], endPosition[3], mins[3], maxs[3], groundOrigin[3];
	
	startPosition = gF_OldOrigin[player.ID];
	
	endPosition = startPosition;
	endPosition[2] = endPosition[2] - 2.0; // Should be less than 2.0 units away
	
	GetEntPropVector(player.ID, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(player.ID, Prop_Send, "m_vecMaxs", maxs);
	
	Handle trace = TR_TraceHullFilterEx(
		startPosition, 
		endPosition, 
		mins, 
		maxs, 
		MASK_PLAYERSOLID, 
		TraceEntityFilterPlayers, 
		player.ID);
	
	// This is expected to always hit
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(groundOrigin, trace);
		
		// Teleport player downwards so it's like they jumped from the ground
		float newOrigin[3];
		player.GetOrigin(newOrigin);
		newOrigin[2] -= gF_OldOrigin[player.ID][2] - groundOrigin[2];
		
		if (gB_GOKZCore)
		{
			GOKZ_SetValidJumpOrigin(player.ID, newOrigin);
		}
		else
		{
			SetEntPropVector(player.ID, Prop_Data, "m_vecAbsOrigin", newOrigin);
		}		
	}
	
	delete trace;
}

void TweakJumpbug(KZPlayer player)
{	
	ApplyJumpStamina(player);
	if (player.Speed > SPEED_NORMAL)
	{
		Movement_SetSpeed(player.ID, CalcTweakedTakeoffSpeed(player, true), true);
	}
	if (gB_GOKZCore)
	{
		player.GOKZHitPerf = true;
		player.GOKZTakeoffSpeed = player.Speed;
	}
}

// Takeoff speed assuming player has met the conditions to need tweaking
float CalcTweakedTakeoffSpeed(KZPlayer player, bool jumpbug = false)
{
	// Formula
	if (jumpbug)
	{
		if (player.Speed < PERF_MIN_SPEED_CAP)
		{
			gF_PerfTakeoffSpeedCap[player.ID] = FloatMax(PERF_MIN_SPEED_CAP, player.Speed + PERF_SPEED_CAP_GAIN);
			return player.Speed;
		}
		else if (player.Speed > gF_PerfTakeoffSpeedCap[player.ID]) // If the player goes over the cap, go slower...
		{
			float newspeed;			 
		
			newspeed = FloatMax(gF_PerfTakeoffSpeedCap[player.ID] - (player.Speed - gF_PerfTakeoffSpeedCap[player.ID]), SPEED_NORMAL * gF_PSVelMod[player.ID]);
			gF_PerfTakeoffSpeedCap[player.ID] = FloatMin(newspeed + PERF_SPEED_CAP_GAIN, PERF_MAX_SPEED_CAP); // Increase the speed cap every bhop.
		
			return newspeed;
		}
		else
		{
			gF_PerfTakeoffSpeedCap[player.ID] = FloatMax(player.Speed + PERF_SPEED_CAP_GAIN, PERF_MAX_SPEED_CAP);
			return player.Speed;
		}
	}
	else if (player.LandingSpeed > SPEED_NORMAL)
	{
		if (player.LandingSpeed < PERF_MIN_SPEED_CAP)
		{
			gF_PerfTakeoffSpeedCap[player.ID] = FloatMax(PERF_MIN_SPEED_CAP, player.LandingSpeed + PERF_SPEED_CAP_GAIN);
			return player.LandingSpeed;
		}
		else if (player.LandingSpeed > gF_PerfTakeoffSpeedCap[player.ID])
		{
			float newspeed;
	
			newspeed = FloatMax(gF_PerfTakeoffSpeedCap[player.ID] - (player.LandingSpeed - gF_PerfTakeoffSpeedCap[player.ID]), SPEED_NORMAL * gF_PSVelMod[player.ID]);
			gF_PerfTakeoffSpeedCap[player.ID] = FloatMin(newspeed + PERF_SPEED_CAP_GAIN, PERF_MAX_SPEED_CAP);
		
			return newspeed;
		}
		else
		{
			gF_PerfTakeoffSpeedCap[player.ID] = FloatMin(player.LandingSpeed + PERF_SPEED_CAP_GAIN, PERF_MAX_SPEED_CAP);
			return player.LandingSpeed;
		}
	}

	return player.LandingSpeed;
}



// =====[ SLOPEFIX ]=====

// ORIGINAL AUTHORS : Mev & Blacky
// URL : https://forums.alliedmods.net/showthread.php?p=2322788
// NOTE : Modified by DanZay for this plugin

void SlopeFix(int client)
{
	// Check if player landed on the ground
	if (Movement_GetOnGround(client) && !gB_OldOnGround[client])
	{
		// Set up and do tracehull to find out if the player landed on a slope
		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		
		float vMins[3];
		GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
		
		float vMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
		
		float vEndPos[3];
		vEndPos[0] = vPos[0];
		vEndPos[1] = vPos[1];
		vEndPos[2] = vPos[2] - gF_ModeCVarValues[ModeCVar_MaxVelocity];
		
		TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		
		if (TR_DidHit())
		{
			// Gets the normal vector of the surface under the player
			float vPlane[3], vLast[3];
			TR_GetPlaneNormal(null, vPlane);
			
			// Make sure it's not flat ground and not a surf ramp (1.0 = flat ground, < 0.7 = surf ramp)
			if (0.7 <= vPlane[2] < 1.0)
			{
				/*
					Copy the ClipVelocity function from sdk2013 
					(https://mxr.alliedmods.net/hl2sdk-sdk2013/source/game/shared/gamemovement.cpp#3145)
					With some minor changes to make it actually work
				*/
				vLast[0] = gF_OldVelocity[client][0];
				vLast[1] = gF_OldVelocity[client][1];
				vLast[2] = gF_OldVelocity[client][2];
				vLast[2] -= (gF_ModeCVarValues[ModeCVar_Gravity] * GetTickInterval() * 0.5);
				
				float fBackOff = GetVectorDotProduct(vLast, vPlane);
				
				float change, vVel[3];
				for (int i; i < 2; i++)
				{
					change = vPlane[i] * fBackOff;
					vVel[i] = vLast[i] - change;
				}
				
				float fAdjust = GetVectorDotProduct(vVel, vPlane);
				if (fAdjust < 0.0)
				{
					for (int i; i < 2; i++)
					{
						vVel[i] -= (vPlane[i] * fAdjust);
					}
				}
				
				vVel[2] = 0.0;
				vLast[2] = 0.0;
				
				// Make sure the player is going down a ramp by checking if they actually will gain speed from the boost
				if (GetVectorLength(vVel) > GetVectorLength(vLast))
				{
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
				}
			}
		}
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 < entity <= MaxClients);
}



// =====[ OTHER ]=====

void FixWaterBoost(KZPlayer player, int buttons)
{
	if (GetEntProp(player.ID, Prop_Send, "m_nWaterLevel") >= 2) // WL_Waist = 2
	{
		// If duck is being pressed and we're not already ducking or on ground
		if (GetEntityFlags(player.ID) & (FL_DUCKING | FL_ONGROUND) == 0
			 && buttons & IN_DUCK && ~gI_OldButtons[player.ID] & IN_DUCK)
		{
			float newOrigin[3];
			Movement_GetOrigin(player.ID, newOrigin);
			newOrigin[2] += 9.0;
			
			TR_TraceHullFilter(newOrigin, newOrigin, view_as<float>( { -16.0, -16.0, 0.0 } ), view_as<float>( { 16.0, 16.0, 54.0 } ), MASK_PLAYERSOLID, TraceEntityFilterPlayers);
			if (!TR_DidHit())
			{
				TeleportEntity(player.ID, newOrigin, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

void RemoveCrouchJumpBind(KZPlayer player, int &buttons)
{
	if (player.OnGround && buttons & IN_JUMP && !(gI_OldButtons[player.ID] & IN_JUMP) && !(gI_OldButtons[player.ID] & IN_DUCK))
	{
		buttons &= ~IN_DUCK;
	}
}

void ReduceDuckSlowdown(KZPlayer player)
{
	/*
		Duck speed is reduced by the game upon ducking or unducking.
		The goal here is to accept that duck speed is reduced, but
		stop it from being reduced further when spamming duck.

		This is done by enforcing a minimum duck speed equivalent to
		the value as if the player only ducked once. When not in not
		in the middle of ducking, duck speed is reset to its normal
		value in effort to reduce the number of times the minimum
		duck speed is enforced. This should reduce noticeable lagg.
	*/
	
	if (!GetEntProp(player.ID, Prop_Send, "m_bDucking")
		 && player.DuckSpeed < DUCK_SPEED_NORMAL - EPSILON)
	{
		player.DuckSpeed = DUCK_SPEED_NORMAL;
	}
	else if (player.DuckSpeed < DUCK_SPEED_MINIMUM - EPSILON)
	{
		player.DuckSpeed = DUCK_SPEED_MINIMUM;
	}
} 

static bool IsValidPlayerPos(int client, float origin[3])
{
	TR_TraceHullFilter(origin, origin,
		STANDING_MINS,
		STANDING_MAXS,
		MASK_PLAYERSOLID, TraceEntityFilterPlayers, client);
	
	return !TR_DidHit();
}

void DoDoubleDuck(KZPlayer player, int buttons, int cmdnum)
{
	int flags = GetEntityFlags(player.ID);
	if (flags & FL_ONGROUND)
	{
		if (flags & FL_DUCKING)
		{
			gB_AllowDoubleDuck[player.ID] = false;
		}
		else if (buttons & IN_DUCK)
		{
			gB_AllowDoubleDuck[player.ID] = true;
		}
		else if (GetEntProp(player.ID, Prop_Data, "m_bDucking")
			&& gB_AllowDoubleDuck[player.ID])
		{
			// Is transitioning?
			float origin[3];
			Movement_GetOrigin(player.ID, origin);
			origin[2] += DOUBLEDUCK_HEIGHT;
			if (IsValidPlayerPos(player.ID, origin))
			{
				TeleportEntity(player.ID, origin, NULL_VECTOR, NULL_VECTOR);
				
				int cmdsSinceLanding = cmdnum - player.LandingCmdNum;
				if (cmdsSinceLanding <= DOUBLEDUCK_GRACE_FRAMES)
				{
					float newVelocity[3];
					// NOTE: the speed scale here is just because the landing speed doesn't get reduced by ducking speed properly.
					// usually you go from 250 to ~243 speed when you do a single doubleduck.
					// The faster your speed is, the more speed you lose using doubleduck. There is a small loss under the bhop cap,
					// by being IN_DUCK for one tick.
					float newSpeed = player.LandingSpeed * FloatMax(FloatMin(PERF_MIN_SPEED_CAP / player.LandingSpeed, 1.0), DOUBLEDUCK_MIN_SPEED_SCALE);

					float speed = player.Speed;
					
					if (speed > 0.0)
					{
						player.GetVelocity(newVelocity);
					}
					else
					{
						player.GetLandingVelocity(newVelocity);
					}
					
					SetVectorHorizontalLength(newVelocity, newSpeed);
					player.SetVelocity(newVelocity);
				}
				gB_JustDoubleDucked[player.ID] = true;
			}
		}
	}
}

void ApplyGroundSpeedCap(KZPlayer player, int cmdnum)
{
	int flags = GetEntityFlags(player.ID);
	if (flags & FL_ONGROUND)
	{
		int cmdnumsOnGround = cmdnum - Movement_GetLandingCmdNum(player.ID);
		
		if (cmdnumsOnGround == GROUND_SPEED_CAP_SOFT_TICK)
		{
			float velocity[3];
			player.GetVelocity(velocity);
			float speed = GetVectorHorizontalLength(velocity);
			
			float maxSpeed = SPEED_NORMAL * gF_PSVelMod[player.ID];
			gF_PerfTakeoffSpeedCap[player.ID] = PERF_MIN_SPEED_CAP; // Reset bhop speed cap as well
			if (flags & FL_DUCKING) 
			{
				maxSpeed = 85.0 * gF_PSVelMod[player.ID];
			}
			
			if (speed > maxSpeed)
			{
				SetVectorHorizontalLength(velocity, maxSpeed);
				player.SetVelocity(velocity);
			}
		}
	}
}

void ApplyJumpStamina(KZPlayer player)
{
	if (gF_Stamina[player.ID] > 0.0)
	{
		float ratio = 1 - (gF_Stamina[player.ID] * STAMINA_JUMP_FACTOR) / 1000;
		float velocity[3];
		player.GetVelocity(velocity);
		velocity[2] *= ratio;
		velocity[2] = FloatMax(STAMINA_MIN_JUMP_VELOCITY, velocity[2]);
		player.SetVelocity(velocity);
	}
}
void ApplyLandStamina(KZPlayer player)
{
	int flags = GetEntityFlags(player.ID);
	
	// Always apply stamina, except for landing after doubleducks.

	if (!gB_JustDoubleDucked[player.ID] && flags & FL_ONGROUND && !(gI_OldFlags[player.ID] & FL_ONGROUND)) 
	{
		gF_Stamina[player.ID] -= gF_OldVelocity[player.ID][2];
	}
}

void ApplyGroundStamina(KZPlayer player, int flags)
{
	if (flags & FL_ONGROUND)
	{
		if (gF_Stamina[player.ID] > 0.0)
		{
			float ratio = FloatMax(1 - (gF_Stamina[player.ID] * STAMINA_SPEED_FACTOR) / 1000, STAMINA_MIN_SPEED_FACTOR); // Effectively capped at 750u/s
			float velocity[3];
			player.GetVelocity(velocity);
			velocity[0] *= ratio;
			velocity[1] *= ratio;
			player.SetVelocity(velocity);
		}
	}
}