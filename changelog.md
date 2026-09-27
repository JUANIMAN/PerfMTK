# Changelog

## v16.5

- Fully dynamic, universal hardware probing and profile generation: eliminated all device-specific hardcodes, dynamically detecting OPP frequencies, cluster topologies, and CPU governor policies across any MediaTek platform.
- Main UI thread RenderBooster integration: pins and elevates the application's main thread alongside render threads to Big/Prime cores for stutter-free frame generation.
- Dynamic panel refresh rate probing: automatically detects max display refresh rate and clamps target frame rates appropriately for 60Hz, 90Hz, 120Hz, and 144Hz panels.
- Standardized balanced profile generation: optimized baseline frequencies and EAS energy-efficiency sweet spots.
- Dynamic game frame rate adaptation: eliminated fixed phase offset overrides in favor of adaptive SurfaceFlinger sync.
