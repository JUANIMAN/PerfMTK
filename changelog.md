# Changelog

## v17.1

- Devfreq Memory Subsystem: `userspace` governor integration preventing DRAM clock lock.
- Display Driver Stabilization: eliminated buffer tearing glitches and 144Hz panel lock.
- Native SurfaceFlinger Phase Synchronization respecting OEM dynamic durations.

### Notes

Please run `su -c perfmtk -d` and `su -c perfmtk -g` for regenerate profiles.
