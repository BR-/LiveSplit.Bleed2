state("Bleed2") {
}

startup {
	vars.scanTarget = new SigScanTarget(5, "8b 45 ec 8d 15 ?? ?? ?? ?? e8 ?? ?? ?? ?? 90 8d 65 f8 5e 5f 5d c3");
	vars.splits = new int[] {8, 15, 22, 30, 37, 41};
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

split {
	return vars.levelInfo.Current > vars.levelInfo.Old && ((int[]) vars.splits).Any(split => split == vars.levelInfo.Current);
}
