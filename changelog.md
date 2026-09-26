# Changelog

## v16.4

- Apps assigned to `powersave` or `powersave+` profiles now receive a 2000 ms grace period in balanced mode with active UCLAMP top-app boost during startup.
- Direct `package:PID` atomic socket delivery from `system_server` to the native daemon.
- Tuned SurfaceFlinger phase offsets and touch timers via `system.prop` to eliminate frame pacing jitter.
- Cleaned up legacy installer routines in `customize.sh`, delegating full control to the native C engine.
