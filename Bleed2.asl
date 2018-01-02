state("Bleed2") {
}

startup {
	vars.gamestateScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 05 02 04 00 00 00");	// method table header for Bleed_II.IJCGameStateEngine
	vars.playtimeScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 a6 02 04 00 00 00");	// method table header for Bleed_II.IJCStatsEngine
	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 48};
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
}

update {
	vars.levelInfo.Update(game);
	vars.gamestateInfo.Update(game);
	vars.playtimeInfo.Update(game);
	vars.gamemodeInfo.Update(game);

	/*
	print("Level: " + vars.levelInfo.Current + "\n"
	    + "State: " + vars.gamestateInfo.Current + "\n"
	    + "Time:  " + vars.playtimeInfo.Current + "\n"
	    + "Mode:  " + vars.gamemodeInfo.Current);
	*/
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