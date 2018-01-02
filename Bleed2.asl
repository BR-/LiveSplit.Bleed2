state("Bleed2") {
}

startup {
	vars.levelScanTarget = new SigScanTarget(5, "8b 45 ec 8d 15 ?? ?? ?? ?? e8 ?? ?? ?? ?? 90 8d 65 f8 5e 5f 5d c3");	// JIT code for GameState_Playing..cctor
	vars.gamestateScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 05 02 04 00 00 00");	// method table header for Bleed_II.IJCGameStateEngine
	vars.playtimeScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 a6 02 04 00 00 00");	// method table header for Bleed_II.IJCStatsEngine
	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 48};
}

init {
	var levelPtr = IntPtr.Zero;
	var gamestatePtr = IntPtr.Zero;
	var playtimePtr = IntPtr.Zero;
	foreach (var page in memory.MemoryPages()) {
		if (levelPtr == IntPtr.Zero) {
			levelPtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.levelScanTarget);
		}
		if (gamestatePtr == IntPtr.Zero) {
			gamestatePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.gamestateScanTarget);
		}
		if (playtimePtr == IntPtr.Zero) {
			playtimePtr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.playtimeScanTarget);
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
	if (playtimePtr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find playtime sig");
	}

	// this would be neat, but there's no way to make a deeppointer as a child of another
	// var staticRefTypeArray = new DeepPointer(((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25);
	// var staticValueTypeArray = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28);

	// reference type, offset 15c
	var dp = new DeepPointer("Bleed2.exe", ((int) levelPtr) - ((int) game.MainModuleWow64Safe().BaseAddress), 0, 0x30);
	vars.levelInfo = new MemoryWatcher<int>(dp);

	// reference type, offset 494
	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25, 0, 0, 10);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);

	// value type, offset 5e4
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28, 0);
	vars.playtimeInfo = new MemoryWatcher<float>(dp);

	// value type, offset 3e4
	dp = new DeepPointer("Bleed2.exe", ((int) playtimePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x168, 28, -0x200);
	vars.gamemodeInfo = new MemoryWatcher<int>(dp);
}

update {
	vars.levelInfo.Update(game);
	vars.gamestateInfo.Update(game);
	vars.playtimeInfo.Update(game);
	vars.gamemodeInfo.Update(game);
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