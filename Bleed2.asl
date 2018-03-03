state("Bleed2") {
}

startup {
	// BEGIN AUTOGENERATED VALUES
	vars.referenceScanTarget = new SigScanTarget(0, "00 02 00 00 0C 00 00 00 88 05 49 02 04 00 00 00");	// method table header for Bleed_II.IJCGameStateEngine
	vars.referenceMethodOffset = - 0x5C + 8;	// method desc entry for get_CurrentState
	vars.referenceAsmOffset = 0x19;	// 00000018 a1 f8 39 XX XX                 mov eax, [0xXXX39f8]
	vars.referenceHeapOffset = 0x500;	// currentState
	vars.valueScanTarget = new SigScanTarget(0, "00 02 00 00 0C 00 00 00 88 25 50 00 04 00 00 00");	// method table header for Bleed_II.IJCSteamHelper
	vars.valueMethodOffset = - 0x1754 + 8;	// method desc entry for Initialize
	vars.valueAsmOffset = 0x20;	// 0000001f a2 4c 66 XX XX                 mov [0xXX664c], al
	vars.valueHeapOffset = 0x428;	// isSteamInitialized
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
	// END AUTOGENERATED VALUES

	vars.firstLevel = 0;
	vars.secondLevel = 1;
	vars.firstEnvironment = 0;
	vars.highestLevel = 41;
	vars.unknownLevel = 54;

	vars.gamemodeStory = 0;
	vars.gamemodeArcadeNewGame = 1;
	vars.gamemodeArcadeFreeStyle = 2;
	vars.gamemodeChallenge = 3;
	vars.gamemodeEndless = 4;
}

init {
	var referencePtr = IntPtr.Zero;
	var valuePtr = IntPtr.Zero;
	foreach (var page in memory.MemoryPages()) {
		if (referencePtr == IntPtr.Zero) {
			referencePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.referenceScanTarget);
		}
		if (valuePtr == IntPtr.Zero) {
			valuePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.valueScanTarget);
		}
	}
	if (referencePtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find reference sig");
	}
	if (valuePtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find value sig");
	}

	DeepPointer dp;

	// GameState_Playing.CurrentLevel: reference type
	//  -> Level.levelInfo
	dp = new DeepPointer("Bleed2.exe", ((int) referencePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.referenceMethodOffset, vars.referenceAsmOffset, (vars.GameState_Playing__CurrentLevel - vars.referenceHeapOffset), vars.Level__levelInfo);
	vars.levelInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentState: reference type
	//  -> IJCGameState.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) referencePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.referenceMethodOffset, vars.referenceAsmOffset, (vars.IJCGameStateEngine__currentState - vars.referenceHeapOffset), 0, 10);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);

	// IJCStatsEngine.playTime_total: value type
	dp = new DeepPointer("Bleed2.exe", ((int) valuePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.valueMethodOffset, vars.valueAsmOffset, (vars.IJCStatsEngine__playTime_total - vars.valueHeapOffset));
	vars.playtimeInfo = new MemoryWatcher<float>(dp);

	// GameState_Playing.GameMode: value type
	dp = new DeepPointer("Bleed2.exe", ((int) valuePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.valueMethodOffset, vars.valueAsmOffset, (vars.GameState_Playing__GameMode - vars.valueHeapOffset));
	vars.gamemodeInfo = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentTransition: reference type
	//  -> IJCTransition.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) referencePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.referenceMethodOffset, vars.referenceAsmOffset, (vars.IJCGameStateEngine__currentTransition - vars.referenceHeapOffset), 0, 10);
	vars.transitionType = new MemoryWatcher<short>(dp);
	vars.transitionType.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// IJCGameStateEngine.newState: reference type
	//  -> IJCGameState.mdToken
	dp = new DeepPointer("Bleed2.exe", ((int) referencePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.referenceMethodOffset, vars.referenceAsmOffset, (vars.IJCGameStateEngine__newState - vars.referenceHeapOffset), 0, 10);
	vars.transitionNewState = new MemoryWatcher<short>(dp);
	vars.transitionNewState.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// Transition_LevelIntro.levelNumber: value type
	dp = new DeepPointer("Bleed2.exe", ((int) valuePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.valueMethodOffset, vars.valueAsmOffset, (vars.Transition_LevelIntro__levelNumber - vars.valueHeapOffset));
	vars.transitionLevel = new MemoryWatcher<int>(dp);

	// IJCGameStateEngine.currentState: reference type
	//  -> IJCGameState.currentMiniState
	dp = new DeepPointer("Bleed2.exe", ((int) referencePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.referenceMethodOffset, vars.referenceAsmOffset, (vars.IJCGameStateEngine__currentState - vars.referenceHeapOffset), vars.IJCGameState__currentMiniState, 0, 10);
	vars.currentMiniState = new MemoryWatcher<short>(dp);
	vars.currentMiniState.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	dp = new DeepPointer("Bleed2.exe", ((int) valuePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) + vars.valueMethodOffset, vars.valueAsmOffset, (vars.IJCEndlessModeEngine__currentEnvironmentNumber - vars.valueHeapOffset));
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
	if (vars.gamemodeInfo.Current == vars.gamemodeArcadeNewGame || vars.gamemodeInfo.Current == vars.gamemodeArcadeFreeStyle) {
		// arcade resets when you enter the first room
		return vars.levelInfo.Current == vars.firstLevel && vars.levelInfo.Old != vars.firstLevel;
	} else if (vars.gamemodeInfo.Current == vars.gamemodeEndless) {
		// endless resets when it's generating the first level
		return vars.gamestateInfo.Current == vars.GameState_EndlessGeneration__mdToken && vars.currentEnvironmentNumber.Current == vars.firstEnvironment;
	}
}

start {
	if (vars.gamestateInfo.Old == vars.GameState_EndlessGeneration__mdToken && vars.gamestateInfo.Current == vars.GameState_Playing__mdToken) {
		// endless mode starts after EndlessGeneration finishes
		return true;
	} else if (vars.gamemodeInfo.Current == vars.gamemodeStory) {
		// story mode starts when the difficulty is clicked
		return vars.transitionType.Current == vars.Transition_LevelIntro__mdToken && vars.transitionNewState.Current == vars.GameState_Playing__mdToken && vars.transitionLevel.Current == vars.firstLevel;
	} else if (vars.gamemodeInfo.Current == vars.gamemodeArcadeNewGame || vars.gamemodeInfo.Current == vars.gamemodeArcadeFreeStyle) {
		// arcade modes start when the game starts
		return vars.gamestateInfo.Current == vars.GameState_Playing__mdToken && vars.levelInfo.Current <= vars.secondLevel;
	}
}

split {
	if (vars.gamemodeInfo.Current == vars.gamemodeEndless) {
		return vars.gamestateInfo.Old != vars.GameState_EndlessGeneration__mdToken && vars.gamestateInfo.Current == vars.GameState_EndlessGeneration__mdToken
		    || vars.gamestateInfo.Current == vars.GameState_EndlessClear__mdToken;
	} else if (vars.levelInfo.Current != vars.unknownLevel && vars.levelInfo.Current > vars.highestLevel) {
		if (vars.gamemodeInfo.Current == vars.gamemodeStory) {
			// story ends timing on "Game Clear" text
			return vars.currentMiniState.Current == vars.MiniGameState_LevelClear__mdToken;
		} else {
			// other modes end timing when the gamestate changes
			return vars.gamestateInfo.Current == vars.GameState_ArcadeClear__mdToken
			    || vars.gamestateInfo.Current == vars.GameState_ReplayResult__mdToken;
		}
	} else {
		// split on "Level Clear" text
		return vars.MiniGameState_LevelClear__mdToken == vars.currentMiniState.Current
		    && vars.MiniGameState_LevelClear__mdToken != vars.currentMiniState.Old;
	}
}

isLoading {
	if (vars.gamemodeInfo.Current == vars.gamemodeStory) {
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