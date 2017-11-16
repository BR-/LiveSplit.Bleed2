state("Bleed2") {
}

startup {
	vars.scanTarget = new SigScanTarget(5, "8b 45 ec 8d 15 ?? ?? ?? ?? e8 ?? ?? ?? ?? 90 8d 65 f8 5e 5f 5d c3");
	vars.splits = new int[] {8, 15, 22, 30, 37, 41, 48};
}

init {
	var ptr = IntPtr.Zero;
	foreach (var page in memory.MemoryPages()) {
		ptr = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize).Scan(vars.scanTarget);
		if (ptr != IntPtr.Zero) {
			break;
		}
	}
	if (ptr == IntPtr.Zero) {
		Thread.Sleep(1000);
		throw new Exception("init - could not find sig");
	}

	var dp = new DeepPointer("Bleed2.exe", ((int) ptr) - ((int) game.MainModuleWow64Safe().BaseAddress), 0, 0x30);
	vars.levelInfo = new MemoryWatcher<int>(dp);
}

update {
	vars.levelInfo.Update(game);
}

// this does not work if the person has already loaded into level 0, then quits to menu and resets the timer, then loads back into level 0
start {
	return vars.levelInfo.Current == 0;
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

// start -> IJCGameStateEngine.currentState.Old is not GameState_Playing && IJCGameStateEngine.currentState.Current is GameState_Playing
	// and on level 0
	// what other gamestates can interrupt? is pausing a gamestate?
// isLoading -> IJCGameStateEngine.currentState is GameState_Intermission
// gameTime -> IJCStatsEngine.playTime_total
	// i don't know how this works wrt Story vs Arcade
	// does it reset between Story runs? (probably)
	// if not, does it count intermission time? (gotta test)