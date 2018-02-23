state("Bleed2") {
}

startup {
	vars.gamestateScanTarget = new SigScanTarget(0, "00 02 00 00 0C 00 00 00 88 05 49 02 04 00 00 00");	// method table header for Bleed_II.IJCGameStateEngine
	vars.gamestateMethodOffset = - 0x5C + 8;
	vars.gamestateAsmOffset = 0x19;
	vars.gamestateHeapOffset = 0x500;

	vars.playtimeScanTarget = new SigScanTarget(0, "00 02 00 00 0C 00 00 00 88 05 05 03 04 00 00 00");	// method table header for Bleed_II.IJCStatsEngine
	vars.playtimeMethodOffset = - 0x170 + 8;
	vars.playtimeAsmOffset = 0x1C;
	vars.playtimeHeapOffset = 0x6A4;

	vars.GameState_Playing__CurrentLevel = 0x18C;
	vars.Level__levelInfo = 0x30;

	vars.IJCGameStateEngine_currentState = 0x500;

	vars.IJCStatsEngine__playTime_total = 0x6A4;

	vars.GameState_Playing__GameMode = 0x474;

	vars.IJCGameStateEngine__currentTransition = 0x508;

	vars.IJCGameStateEngine__newState = 0x504;

	vars.Transition_LevelIntro__levelNumber = 0x4BC;

	vars.GameState_Playing__mdToken = 0xB8;
	vars.Transition_LevelIntro__mdToken = 0x162;

	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 53};
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

	DeepPointer dp;

	// GameState_Playing.CurrentLevel: reference type
	//  -> Level.levelInfo
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.gamestateMethodOffset, vars.gamestateAsmOffset, (vars.GameState_Playing__CurrentLevel - vars.gamestateHeapOffset), vars.Level__levelInfo);
	vars.levelInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentState: reference type
	//  -> IJCGameState.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.gamestateMethodOffset, vars.gamestateAsmOffset, (vars.IJCGameStateEngine_currentState - vars.gamestateHeapOffset), 0, 10);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);

	// IJCStatsEngine.playTime_total: value type
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.playtimeMethodOffset, vars.playtimeAsmOffset, (vars.IJCStatsEngine__playTime_total - vars.playtimeHeapOffset));
	vars.playtimeInfo = new MemoryWatcher<float>(dp);

	// GameState_Playing.GameMode: value type
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.playtimeMethodOffset, vars.playtimeAsmOffset, (vars.GameState_Playing__GameMode - vars.playtimeHeapOffset));
	vars.gamemodeInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentTransition: reference type
	//  -> IJCTransition.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.gamestateMethodOffset, vars.gamestateAsmOffset, (vars.IJCGameStateEngine__currentTransition - vars.gamestateHeapOffset), 0, 10);
	vars.transitionType = new MemoryWatcher<short>(dp);
	vars.transitionType.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// IJCGameStateEngine.newState: reference type
	//  -> IJCGameState.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.gamestateMethodOffset, vars.gamestateAsmOffset, (vars.IJCGameStateEngine__newState - vars.gamestateHeapOffset), 0, 10);
	vars.transitionNewState = new MemoryWatcher<short>(dp);
	vars.transitionNewState.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// Transition_LevelIntro.levelNumber: value type
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.playtimeMethodOffset, vars.playtimeAsmOffset, (vars.Transition_LevelIntro__levelNumber - vars.playtimeHeapOffset));
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
		if (vars.gamestateInfo.Old != vars.GameState_Playing__mdToken && vars.gamestateInfo.Current == vars.GameState_Playing__mdToken && vars.levelInfo.Current == 0) {
			vars.weirdStart = true;
		}
		// story mode starts when the difficulty is clicked
		var retval = vars.transitionType.Current == vars.Transition_LevelIntro__mdToken && vars.transitionNewState.Current == vars.GameState_Playing__mdToken && vars.transitionLevel.Current == 0;
		if (retval) {
			vars.weirdStart = false;
		}
		return retval;
	} else {
		if (vars.weirdStart && vars.gamemodeInfo.Old == 0 && vars.gamestateInfo.Current == vars.GameState_Playing__mdToken && vars.levelInfo.Current == 0) {
			vars.weirdStart = false;
			return true;
		}
		vars.weirdStart = false;
		// other modes start when the game starts
		return vars.gamestateInfo.Old != vars.GameState_Playing__mdToken && vars.gamestateInfo.Current == vars.GameState_Playing__mdToken && vars.levelInfo.Current == 0;
	}
}

split {
	if (vars.levelInfo.Current == 37
			&& vars.levelInfo.Old == 54) {
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