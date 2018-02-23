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

	vars.IJCGameStateEngine__currentState = 0x500;

	vars.IJCStatsEngine__playTime_total = 0x6A4;

	vars.GameState_Playing__GameMode = 0x474;

	vars.IJCGameStateEngine__currentTransition = 0x508;

	vars.IJCGameStateEngine__newState = 0x504;

	vars.Transition_LevelIntro__levelNumber = 0x4BC;

	vars.IJCGameState__currentMiniState = 0x4;

	vars.IJCEndlessModeEngine__currentEnvironmentNumber = 0x704;

	vars.GameState_Playing__mdToken = 0xB8;
	vars.Transition_LevelIntro__mdToken = 0x162;
	vars.GameState_EndlessGeneration__mdToken = 0x2F9;
	vars.MiniGameState_LevelClear__mdToken = 0x2D2;
	vars.GameState_ArcadeClear__mdToken = 0xB;
	vars.GameState_ReplayResult__mdToken = 0x359;
	vars.GameState_EndlessClear__mdToken = 0x2F7;

	vars.splits = new int[] {8, 15, 22, 30, 37, 41};
	vars.highestLevel = 41;
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
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.gamestateMethodOffset, vars.gamestateAsmOffset, (vars.IJCGameStateEngine__currentState - vars.gamestateHeapOffset), 0, 10);
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

	// IJCGameStateEngine.currentState: reference type
	//  -> IJCGameState.currentMiniState
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.gamestateMethodOffset, vars.gamestateAsmOffset, (vars.IJCGameStateEngine__currentState - vars.gamestateHeapOffset), vars.IJCGameState__currentMiniState, 0, 10);
	vars.currentMiniState = new MemoryWatcher<short>(dp);
	vars.currentMiniState.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.playtimeMethodOffset, vars.playtimeAsmOffset, (vars.IJCEndlessModeEngine__currentEnvironmentNumber - vars.playtimeHeapOffset));
	vars.currentEnvironmentNumber = new MemoryWatcher<short>(dp);
	vars.currentEnvironmentNumber.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
}

update {
	vars.levelInfo.Update(game);
	vars.gamestateInfo.Update(game);
	vars.playtimeInfo.Update(game);
	vars.gamemodeInfo.Update(game);
	vars.transitionType.Update(game);
	vars.transitionNewState.Update(game);
	vars.transitionLevel.Update(game);
	vars.currentMiniState.Update(game);
	vars.currentEnvironmentNumber.Update(game);
}

reset {
	if (vars.gamemodeInfo.Current == 1 || vars.gamemodeInfo.Current == 2) {
		// arcade resets when you enter the first room
		return vars.levelInfo.Current == 0 && vars.levelInfo.Old != 0;
	} else if (vars.gamemodeInfo.Current == 4) {
		// endless resets when it's generating the first level
		return vars.gamestateInfo.Current == vars.GameState_EndlessGeneration__mdToken && vars.currentEnvironmentNumber.Current == 0;
	}
}

start {
	if (vars.gamestateInfo.Old == vars.GameState_EndlessGeneration__mdToken && vars.gamestateInfo.Current == vars.GameState_Playing__mdToken) {
		// endless mode starts after EndlessGeneration finishes
		return true;
	} else if (vars.gamemodeInfo.Current == 0) {
		// story mode starts when the difficulty is clicked
		return vars.transitionType.Current == vars.Transition_LevelIntro__mdToken && vars.transitionNewState.Current == vars.GameState_Playing__mdToken && vars.transitionLevel.Current == 0;
	} else if (vars.gamemodeInfo.Current == 1 || vars.gamemodeInfo.Current == 2) {
		// arcade modes start when the game starts
		return vars.gamestateInfo.Current == vars.GameState_Playing__mdToken && vars.levelInfo.Current == 0;
	}
}

split {
	if (vars.gamemodeInfo.Current == 4) {
		return vars.gamestateInfo.Old != vars.GameState_EndlessGeneration__mdToken && vars.gamestateInfo.Current == vars.GameState_EndlessGeneration__mdToken
		    || vars.gamestateInfo.Current == vars.GameState_EndlessClear__mdToken;
	}
	if (vars.levelInfo.Current > vars.highestLevel) {
		if (vars.gamemodeInfo.Current == 0) {
			// arcade ends timing on "Game Clear" text
			return vars.currentMiniState.Current == vars.MiniGameState_LevelClear__mdToken;
		} else {
			// other modes end timing when the gamestate changes
			return vars.gamestateInfo.Current == vars.GameState_ArcadeClear__mdToken
			    || vars.gamestateInfo.Current == vars.GameState_ReplayResult__mdToken;
		}
	}
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