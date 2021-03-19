HybridKZ is a modified version of SimpleKZ and GameChaos's game mode.
 
## Features

**Prestrafe**
- Much faster prestrafing compared to SimpleKZ, the time to prestrafe to 276 is the same as the time to nopre run straight to 250 (eg. vanilla). 
- However, you can't prestrafe with just one or 3 movement keys. 
- Prestrafe bonus is not reset upon changing prestrafe direction (WA to WD for example)
- Prestrafe increases the minimum bhop speed from 250 up to 276.
- Prestrafe gain is preserved in air (as opposed to 0.175u loss every tick in SimpleKZ). 

**Doubleduck**
- Quickly ducking and unducking on the ground raises the player by 36 units (or 27 if you land while standing).
- In contrast to GC's doubleduck, you can do this under a 99 height roof instead of a minimum of 108.
- Doubleduck speed loss now depends on the landing speed. The faster you go, the more slowed down you get with double duck (up to 25% reduction).
- The tick window for doubleduck to preserve speed is 5. 

**Stamina**
- Added landing stamina, which slows player upon landing. Landing stamina depends on vertical velocity upon landing. Landing stamina is not applied upon doubleducking.
- Stamina slows running speed up to 50% and jump height to a minimum of 48 units. The maximum speed penalty is reached at 750u/s, while the maximum jump penalty is reached at ~266u/s (lowjump landing speed). 
- When you land you still have the prestrafe speed modifier but slightly slowed down by stamina.
- Current version of stamina does not affect acceleration (airstrafe included), unlike vanilla CSGO.

**Bunnyhop**
- Bhop prespeed formula is similar to GameChaos's bhop cap, but it is now dynamic. The bhop cap is your previous takeoff speed + 32.5 with a minimum cap of 325 and a maximum cap is 650. You can reach this in 10 perfect bhops. 
- Perf window is 3 ticks, the soft ground speed cap applies after 4 ticks, and there's a 5 tick window for doubleduck. 
- Every jump has the same height as a crouch jump, with the exception of jumpbug, which varies from 55.8 to 57.8 units. 
- Perfs are now nerfed for consistent bhop height.

**Misc**
- Jump height is now consistently 57.0/66.0 units high.
- Players will slide for 4 ticks after landing.

## Notes
- **Jumpstats display is broken** due to jump height fix. Use !jsalways to display distances.
- Doubleducks are used to get better edge and speed for the next bhop, or to fully restores stamina from a flat ground jump. High fall requires multiple doubleducks in order to fully mitigate stamina's effect.
- Good double/multi doubleducks can help you reach 325u/s.
- Stamina's effect on running speed is small on flat ground, but noticeable from a big fall.
- Bhop is almost always better than LJ, except for height, but you can't gain bhop prespeed by jumping and turning 360 degrees.
- Speed control is very important on the first few bhops as you can easily lose speed by overstrafing, after reaching 450u/s it becomes easier to keep your bhop prespeed, but you need to handle the high speed instead. You will hover around 600-650u/s at maximum bhop momentum.
- Many maps seems to be much easier to complete but much harder to fully optimize. Some other maps are impossible to complete because of stamina/high bhop jumps.
- Replay bots are not well adjusted to HybridKZ yet.
- Ledgegrabbing is possible on almost every height if you use the correct technique (Double duck for anything under 36 units, flat ground bhop for blocks under 48/57 height, and normal jump for 57/66 blocks). Ledgegrabbing effectively nullifies stamina's effect, allowing you to have a full 57.0 height jump immediately afterwards.

A list of tested maps can be found [here](https://docs.google.com/spreadsheets/d/1dBCF3g1XcN-L9a1k54UXUgAwA9vr5hERYtD1qoUDMNs/edit?usp=sharing).