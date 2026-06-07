# nimbus — System Weather Engine

```
   ╔══════════════════════════════════════╗
   ║          SYSTEM WEATHER MAP          ║
   ╚══════════════════════════════════════╝
```

**Nimbus** maps your computer's internal state onto a living weather system. CPU becomes temperature, memory becomes humidity, processes become wind — and your machine develops its own climate.

## Concept

Every computer has an internal climate. High CPU load generates heat (Heatwave). Memory pressure creates fog. Disk thrashing produces storms. Nimbus reads these metrics and renders them as a real-time weather visualization with dynamic particle effects and a changing sky gradient.

| System State | Weather Pattern |
|---|---|
| Idle, long uptime | Clear / Aurora |
| Moderate load | Partly Cloudy / Overcast |
| High memory, high CPU | Rain / Storm |
| Sustained max load | Heatwave |
| High CPU spikes with low memory | Fog |

## Usage

```powershell
.\nimbus.ps1
```

Runs for ~45 seconds of live weather. Press Ctrl+C to exit early.

## Output

- **Weather icon** and conditions (temperature, wind)
- **Barometric pressure**, **humidity**, **wind speed** (derived from system metrics)
- **Living landscape** with particle effects (raindrops, fog, aurora)
- **Climate dashboard** — CPU, Memory, Disk bars
- **Forecast** — text prediction of system trends

Every system at every moment produces unique weather. Run it during different workloads and watch the climate change.
