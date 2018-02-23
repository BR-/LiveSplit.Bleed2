state("Bleed2") {
}

startup {
	vars.gamestateScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 76 00 04 00 00 00");	// method table header for Bleed_II.IJCGameStateEngine
	vars.playtimeScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 1b 02 04 00 00 00");	// method table header for Bleed_II.IJCStatsEngine
	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 48};
	vars.weirdStart = false;
	//vars.printupdate = false;
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

	// here's how we're getting our offsets:
	// scanPtr points to head of methodtable
	// scanPtr - 0x5C+8 points to the getter function call
	// 0x19 points to the [mov] argument (something in static heap)
	// the heap we got is at 0xA0, the heap we want is 0x394, so (0x394-0xA0) is the offset we need
	// now we have a pointer to the object in CurrentLevel
	// 0x30 is levelInfo

	// GameState_Playing.CurrentLevel: reference type, offset 394
	//  -> Level.levelInfo, offset 30
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 0x19, (0x394 - 0xa0), 0x30);
	vars.levelInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentState: reference type, offset a0
	//  -> IJCGameState.mdToken, offset a
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 0x19, (0xa0 - 0xa0), 0, 0xa);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);

	// IJCStatsEngine.playTime_total: value type, offset 4f0
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 0x1C, (0x4f0 - 0x4f0));
	vars.playtimeInfo = new MemoryWatcher<float>(dp);

	// GameState_Playing.GameMode: value type, offset 4b4
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 0x1C, (0x4b4 - 0x4f0));
	vars.gamemodeInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentTransition: reference type, offset a8
	//  -> IJCTransition.mdToken, offset a
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 0x19, (0xa8 - 0xa0), 0, 0xa);
	vars.transitionType = new MemoryWatcher<short>(dp);
	vars.transitionType.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// IJCGameStateEngine.newState: reference type, offset a4
	//  -> IJCGameState.mdToken, offset a
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 0x19, (0xa4 - 0xa0), 0, 0xa);
	vars.transitionNewState = new MemoryWatcher<short>(dp);
	vars.transitionNewState.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// Transition_LevelIntro.levelNumber: value type, offset 50c
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 0x1C, (0x50c - 0xa0));
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
	if (vars.printupdate) {
		print("next update tick!");
		vars.printupdate = false;
	}
	if (vars.gamemodeInfo.Old != vars.gamemodeInfo.Current) {
		print("Gamemode: " + vars.gamemodeInfo.Old.ToString() + "->" + vars.gamemodeInfo.Current.ToString());
		vars.printupdate = true;
	}
	if (vars.gamestateInfo.Old != vars.gamestateInfo.Current) {
		print("GameState: " + vars.gamestateInfo.Old.ToString() + "->" + vars.gamestateInfo.Current.ToString());
		vars.printupdate = true;
	}
	if (vars.levelInfo.Old != vars.levelInfo.Current) {
		print("Level: " + vars.levelInfo.Old.ToString() + "->" + vars.levelInfo.Current.ToString());
		vars.printupdate = true;
	}

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
		if (vars.gamestateInfo.Old != 0x1B3 && vars.gamestateInfo.Current == 0x1B3 && vars.levelInfo.Current == 0) {
			vars.weirdStart = true;
		}
		// story mode starts when the difficulty is clicked
		// Transition_LevelIntro = 0x21E
		// GameState_Playing = 0x1B3
		// Only start timer on first mission = 0
		var retval = vars.transitionType.Current == 0x21E && vars.transitionNewState.Current == 0x1B3 && vars.transitionLevel.Current == 0;
		if (retval) {
			vars.weirdStart = false;
		}
		return retval;
	} else {
		if (vars.weirdStart && vars.gamemodeInfo.Old == 0 && vars.gamestateInfo.Current == 0x1B3 && vars.levelInfo.Current == 0) {
			vars.weirdStart = false;
			return true;
		}
		vars.weirdStart = false;
		// other modes start when the game starts
		// GameState_Playing = 0x1B3
		// Only start timer on first level = 0
		return vars.gamestateInfo.Old != 0x1B3 && vars.gamestateInfo.Current == 0x1B3 && vars.levelInfo.Current == 0;
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