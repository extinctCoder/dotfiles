# The living core

The creature in the middle of the desktop. It isn't a looping animation: every
motion comes from a live signal, and with no signal nothing moves. It is meant to be
*felt* (calm, busy, hot, playing music) rather than read like a gauge.

Code: `modules/LivingCore.qml` (logic), `shaders/` (drawing), placed by
`modules/Desktop.qml` in its own small window above the desktop widgets.

## Anatomy

| Part | Is | Driven by |
|---|---|---|
| **Heart** | a dense knot of particles in the center | its own heartbeat: slow at rest, faster with load and fever; on the bass with music |
| **Body** | particles in four **bands** (compute, memory, storage, network), each orbiting in its own tilted plane | each band's load (particle count, speed, size) and strain (calm → chaotic) |
| **Skin** | a line wrapped around the body | the bands' actual reach; grows fast, relaxes slowly (memory) |
| **Specks** | single particles crossing the skin | download (in), upload (out), charging (food, into the heart) |

One causal chain ties them together: **the heart beats → a wave travels through
the body (pushing and lighting particles) → the skin ripples when it arrives.**

## Behaviors

| Behavior | Signal | What happens |
|---|---|---|
| strain | per-band load | a calm band keeps a neat orbit; a strained one wobbles, crosses and flings particles out |
| roaming | per-band load | each band's plane precesses over the sphere, faster when busy; bands push each other apart |
| memory | band reach | after hard work the skin stays swollen and relaxes slowly |
| eating / exhaling | download / upload | specks pass through the skin; the line lights up exactly where they cross (pores) |
| hunger / food | battery / charging | below 30% the heart weakens; charging feeds it (green specks) |
| fever | CPU and NVMe temperature | colors shift toward the theme's alert color, the heart races, the body jitters |
| touch | a notification | the skin dents at the top right (where notifications appear), then the heart flinches |
| presence | idle 90 s / locked | away: the heart weakens and the body loosens and dims; locked: the body collapses into the heart; coming back: one strong beat |
| senses | mic or camera in use | the skin turns alert |
| music | cava bands | beats drive the heart; mids swell the skin; highs shimmer along it; album colors flow in |
| heartbeat | each beat | body and skin contract ~8%, then release |
| day / night | sunrise and sunset | 75% brightness at night, an hour of twilight each side |
| health | battery under 10% unplugged | irregular heartbeat, trembling skin |

## Signals

| Signal | Source | Feeds |
|---|---|---|
| CPU total, busiest core | `Sys` (`/proc/stat`) | compute band, heart rate |
| Intel GPU busy | `Sensors` (i915/xe RC6 residency) | compute band |
| RAM, swap | `Sys` (`/proc/meminfo`) | memory band |
| disk read / write | `Disk` (`/proc/diskstats`) | storage band (writes strain more) |
| download / upload | `Sys` (`/proc/net/dev`) | network band, specks, pores |
| CPU, NVMe temperature | `Sys`, `Sensors` (hwmon) | fever |
| battery, charging, power draw | UPower | hunger, food, heart effort |
| music, bands, beats, cover | MPRIS, `Visualizer` (cava), `Album` | heartbeat, skin, colors |
| notifications, workspaces | `Notifs`, `Hypr` | touch, small pulses |
| idle, lock | `IdleMonitor`, `Session` | presence |
| mic / camera | `Privacy` | senses |
| sunrise / sunset | `Weather` | day / night |

Network and disk rates go through a log scale (10 kB/s → 100 MB/s) so a trickle
and a big download both register.

## Music and beats

cava listens to the default output through PipeWire across **20 Hz–20 kHz**
(`.config/cava/quickshell.conf`). The bars are spaced logarithmically; `Visualizer`
computes each bar's real frequency with cava's own formula, so bands are picked by
frequency: bass 20–250 Hz, mids 250 Hz–4 kHz, highs 4–20 kHz.

Beats use **spectral flux**: how much 20–500 Hz suddenly grew since the last frame
(the 40–200 Hz kick region counts double), against an adaptive threshold (recent
mean + 0.8 standard deviations), at most one beat per 0.28 s. Tested through cava on
90–140 BPM tracks with deep and weak kicks; bass lines, hi-hats and sustained chords
alone produce no rhythm. It syncs within a couple of seconds of a song starting.

## Lyrics

`services/Lyrics.qml` finds synced lyrics on LRCLIB. First with the player's own
artist and title (cleaned of video extras like "(Official Video)" and channel
names like "…VEVO"). When that finds nothing while the song plays, it identifies
the song **by ear**: it records about 11 seconds of what the speakers play (the
output's monitor, never the microphone) and asks Shazam through SongRec, then
looks up the real artist, title and album. Only a fingerprint of the audio is
sent, to Shazam's servers only. Without a synced version, plain lyrics are shown,
marked as not synced.

The dashboard's media tab shows what was learned: the real cover, album, year,
genre and label, where the names came from (the player, or by ear), a link to
the song, and the lyrics as a window that follows the song.

Privacy: identified songs are kept **in memory only** (they survive shell
reloads, not a reboot; the last 50), album covers are downloaded to the
session's runtime folder (also gone at reboot), the log never names a track, and
the 11 s recording is deleted right after recognition. Quick settings → audio
has the **listen by ear** switch and **forget now**. LRCLIB still receives the
names of what plays (that's how lyrics are found), and Apple's iTunes Search API
the cleaned names of songs found the quick way (for the album, year, genre and
cover; one request per new song). Tracks shorter than 30 s (video ads) are not
looked up: the shell waits for the real song. Needs `songrec`
(`media/install.sh`); without it, the quick lookup still works.

## Rendering and cost

- All particles (450 slots: body, heart, specks) are placed by **one vertex shader**
  (`shaders/core.vert`) from about 30 numbers per frame; the CPU never touches
  individual particles. The skin is a fragment shader (`shaders/membrane.frag`).
- Rates: data is sampled every **2 s** (like the other desktop graphs), colors 4×/s,
  motion at **10 frames/s**. Motion is time-based, so speed doesn't depend on rate.
- The core has **its own small window**, so a frame redraws only the core.
- It **pauses** whenever the visible workspace has windows, or the screen is locked.
  (Hyprland keeps sending frames to covered surfaces, so it pauses itself.)

Measured on an i7-1165G7: about 0.5% of one core while paused, a few percent while
animating, drawn on the GPU.

## Editing the shaders

The `.qsb` files are compiled shaders and are what Quickshell loads. After editing a
`.vert` or `.frag`:

```sh
sudo pacman -S --needed qt6-shadertools   # provides qsb
~/.config/quickshell/shaders/build.sh
```

`core.vert` and `core.frag` share one uniform block; keep them identical. Arrays
aren't supported as `ShaderEffect` properties, so values are packed into `vec4`s.
The membrane shader re-computes the specks' paths with the same seeds as `core.vert`
(for the pores); change both together.
