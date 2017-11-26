// yesterday's TODO:
// gamestateScanTarget is super ambiguous - matches almost every getter function
// either add a check to make sure we're looking at the right mdToken (somehow?)
// or find a better signature

// today's TODO:
// find the current gamestate
// figure out what class it is
// only start the timer when we move into GameState_Playing

state("Bleed2") {
}

startup {
	vars.levelScanTarget = new SigScanTarget(5, "8b 45 ec 8d 15 ?? ?? ?? ?? e8 ?? ?? ?? ?? 90 8d 65 f8 5e 5f 5d c3");
	vars.gamestateScanTarget = new SigScanTarget(7, "33 d2 89 55 fc 90 a1 ?? ?? ?? ?? 89 45 fc 90 eb 00 8b 45 fc 8b e5 5d c3");
	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 48};
}

init {
	var levelPtr = IntPtr.Zero;
	var gamestatePtr = IntPtr.Zero;
	foreach (var page in memory.MemoryPages()) {
		if (levelPtr == IntPtr.Zero) {
			levelPtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.levelScanTarget);
		}
		if (gamestatePtr == IntPtr.Zero) {
			gamestatePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.gamestateScanTarget);
		}
	}
	if (levelPtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find level sig");
	}
	if (gamestatePtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find gamestate sig");
	}

	var dp = new DeepPointer("Bleed2.exe", ((int) levelPtr) - ((int) game.MainModuleWow64Safe().BaseAddress), 0, 0x30);
	vars.levelInfo = new MemoryWatcher<int>(dp);

	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress), 0, 0, 10);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);
}

update {
	vars.levelInfo.Update(game);
	vars.gamestateInfo.Update(game);
	print(vars.gamestateInfo.Current.ToString("x"));
}

start {
	return vars.gamestateInfo.Old != 0xA1 && vars.gamestateInfo.Current == 0xA1 && vars.levelInfo.Current == 0;
}

split {
	if (vars.levelInfo.Current == 37
			&& vars.levelInfo.Old == 49) {
		// cutscene between Warship and Showdown has an out-of-order ID
		return true;
	}
	return vars.levelInfo.Current > vars.levelInfo.Old
		&& ((int[]) vars.splits).Contains((int) vars.levelInfo.Current);
}

isLoading {
	return vars.gamestateInfo.Current != 0xA1;
}

// start -> IJCGameStateEngine.currentState.Old is not GameState_Playing && IJCGameStateEngine.currentState.Current is GameState_Playing
	// and on level 0
	// what other gamestates can interrupt? is pausing a gamestate?
// isLoading -> IJCGameStateEngine.currentState is GameState_Intermission
// gameTime -> IJCStatsEngine.playTime_total
	// i don't know how this works wrt Story vs Arcade
	// does it reset between Story runs? (probably)
	// if not, does it count intermission time? (gotta test)