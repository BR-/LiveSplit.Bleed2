state("Bleed2") {
}

startup {
	vars.levelScanTarget = new SigScanTarget(5, "8b 45 ec 8d 15 ?? ?? ?? ?? e8 ?? ?? ?? ?? 90 8d 65 f8 5e 5f 5d c3");
	vars.gamestateScanTarget = new SigScanTarget(0, "00 02 00 00 0c 00 00 00 88 05 05 02 04 00 00 00");
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

	dp = new DeepPointer("Bleed2.exe", ((int) gamestatePtr) - ((int) game.MainModuleWow64Safe().BaseAddress) - 0x5C + 8, 25, 0, 0, 10);
	vars.gamestateInfo = new MemoryWatcher<short>(dp);
}

update {
	vars.levelInfo.Update(game);
	vars.gamestateInfo.Update(game);
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
	// A1 = GameState_Playing
	// 27F = GameState_GameOver
	return vars.gamestateInfo.Current != 0xA1 && vars.gamestateInfo.Current != 0x27F;
}

// gameTime -> IJCStatsEngine.playTime_total
	// i don't know how this works wrt Story vs Arcade
	// does it reset between Story runs? (probably)
	// if not, does it count intermission time? (gotta test)