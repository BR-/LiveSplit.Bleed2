state("Bleed2") {
}

startup {
	vars.gamestateScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 05 02 04 00 00 00");	// method table header for Bleed_II.IJCGameStateEngine
	vars.playtimeScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 a6 02 04 00 00 00");	// method table header for Bleed_II.IJCStatsEngine
	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 48};
	vars.weirdStart = false;
}

init {
	var gamestatePtr = IntPtr.Zero;
	var playtimePtr = IntPtr.Zero;
	foreach (var page in memory.MemoryPages()) {
		if (gamestatePtr == IntPtr.Zero) {
			gamestatePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.gamestateScanTarget);
		}
		if (playtimePtr == IntPtr.Zero) {
			playtimePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.playtimeScanTarget);
		}
	}
	if (gamestatePtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find gamestate sig");
	}
	if (playtimePtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find playtime sig");
	}

	// this would be neat, but there's no way to make a deeppointer as a child of another
	// var staticRefTypeArray = new DeepPointer(((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25);
	// var staticValueTypeArray = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28);
	DeepPointer dp;

	// GameState_Playing.instance: reference type, offset 15c
	//  -> Level.levelInfo
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25, (0x15C - 0x494), 0x30);
	vars.levelInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentState: reference type, offset 494
	//  -> IJCGameState.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25, 0, 0, 10);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);

	// IJCStatsEngine.playTime_total: value type, offset 5e4
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28, 0);
	vars.playtimeInfo = new MemoryWatcher<float>(dp);

	// GameState_Playing.GameMode: value type, offset 3e4
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28, -0x200);
	vars.gamemodeInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentTransition: reference type, offset 49c
	//  -> IJCTransition.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25, (0x49C - 0x494), 0, 10);
	vars.transitionType = new MemoryWatcher<short>(dp);
	vars.transitionType.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// IJCGameStateEngine.newState: reference type, offset 498
	//  -> IJCGameState.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25, (0x498 - 0x494), 0, 10);
	vars.transitionNewState = new MemoryWatcher<short>(dp);
	vars.transitionNewState.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// Transition_LevelIntro.levelNumber: value type, offset 42c
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28, (0x42C - 0x5E4));
	vars.transitionLevel = new MemoryWatcher<int>(dp);
}

update {
	vars.levelInfo.Update(game);
	vars.gamestateInfo.Update(game);
	vars.playtimeInfo.Update(game);
	vars.gamemodeInfo.Update(game);
	vars.transitionType.Update(game);
	vars.transitionNewState.Update(game);
	vars.transitionLevel.Update(game);

	/*
	print("Level: " + vars.levelInfo.Current + "\n"
	    + "State: " + vars.gamestateInfo.Current + "\n"
	    + "Time:  " + vars.playtimeInfo.Current + "\n"
	    + "Mode:  " + vars.gamemodeInfo.Current);
	print("Transition Type: " + vars.transitionType.Current.ToString("X") + "\n"
	    + "New Game State:  " + vars.transitionNewState.Current.ToString("X") + "\n"
	    + "Next Level:      " + vars.transitionLevel.Current);
	*/
}

start {
	if (vars.gamemodeInfo.Current == 0) {
		// the first time we start playing Arcade, the transition of GameState_Playing.GameMode from Story to Arcade is late by one cycle
		// this adds an extra grace period
		if (vars.gamestateInfo.Old != 0xA1 && vars.gamestateInfo.Current == 0xA1 && vars.levelInfo.Current == 0) {
			vars.weirdStart = true;
		}
		// story mode starts when the difficulty is clicked
		// Transition_LevelIntro = 0x135
		// GameState_Playing = 0xA1
		// Only start timer on first mission = 0
		var retval = vars.transitionType.Current == 0x135 && vars.transitionNewState.Current == 0xA1 && vars.transitionLevel.Current == 0;
		if (retval) {
			vars.weirdStart = false;
		}
		return retval;
	} else {
		if (vars.weirdStart && vars.gamemodeInfo.Old == 0 && vars.gamestateInfo.Current == 0xA1 && vars.levelInfo.Current == 0) {
			vars.weirdStart = false;
			return true;
		}
		vars.weirdStart = false;
		// other modes start when the game starts
		// GameState_Playing = 0xA1
		// Only start timer on first level = 0
		return vars.gamestateInfo.Old != 0xA1 && vars.gamestateInfo.Current == 0xA1 && vars.levelInfo.Current == 0;
	}
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
	// Story, ArcadeNewGame, ArcadeFreeStyle, Challenge, Endless

	if (vars.gamemodeInfo.Current == 0) {
		// story uses RTA and doesn't use any load removals
		return false;
	} else {
		// other modes use IGT
		return true;
	}
}

gameTime {
	return TimeSpan.FromMilliseconds(vars.playtimeInfo.Current);
}