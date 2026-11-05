# raycast-scripts

A collection of [Raycast](https://raycast.com) script commands.

| Command | What it does |
|---------|--------------|
| **Rain** 🌧️ | Confetti's gloomy cousin: grey sky, clouds and steady rain over your screen for a few seconds. |
| **Thunderstorm** ⛈️ | Darker sky, heavier rain, lightning. |
| **God Rays** ☀️ | Warm sunbeams fan down from the top corner, with dust drifting in the light. |
| **Money Rain** 💸 | Bills and coins tumble down your screen instead of raindrops. |
| **Spotlight** 🔦 | Dims everything except a soft circle that follows your cursor. Run it again to turn it off. |
| **Tornado** 🌪️ | A dust funnel spins up, wanders across the screen and breaks apart. |
| **Bird Flock** 🐦 | A murmuration sweeps across a sunset-tinted screen. |
| **Matrix Rain** 💊 | Green glyph columns pour down a darkened screen. |
| **Countdown** ⏳ | Huge 3, 2, 1 numbers, then your message (or Go!). |
| **Earthquake** 🫨 \* | Your screen shakes for a few seconds. |
| **Glitch** 📺 \* | Your screen tears into RGB-shifted slices. |
| **Heatwave** 🥵 \* | Your windows shimmer like asphalt in August. |
| **Pixel Dissolve** 👾 \* | Your screen blows away as dust, left to right, and comes back. |
| **Black Hole** 🕳️ \* | A black hole opens at the cursor and swirls the screen into it. |
| **Gravity Flip** 🙃 \* | Your screen breaks into chunks that tumble off the bottom edge. |

Every command's title starts with **FX:**, so typing `fx` in Raycast lists them all.

\* These start from a screenshot, so Raycast needs Screen Recording permission. The first run asks for it; turn Raycast on in **System Settings → Privacy & Security → Screen & System Audio Recording** and run the command again.

The overlays ignore clicks, so you can keep working while it rains. All but Spotlight fade out on their own.

## Install

Needs macOS and the Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/eyal-hl/raycast-scripts.git ~/raycast-scripts
```

Then add the folder to Raycast:

1. Open Raycast, search **Search Script Commands** and press Enter.
2. Choose **Add Script Command Folder** (or press ⌘K to find it).
3. In the folder picker press ⌘⇧G, paste `~/raycast-scripts`, press Enter and click **Open**.

Every script in the folder shows up as a command. Each Swift overlay compiles on its first run, so that one takes a few seconds.

To get new commands later, `git pull` in the folder.

## From the terminal

```bash
./rain             # rain for 12 seconds
./rain storm 20    # thunderstorm for 20 seconds
./rain money       # money rain for 8 seconds
./rain rays        # god rays for 10 seconds
./spotlight        # cursor spotlight until you kill it
./fx blackhole     # also quake, glitch, heatwave, dissolve, gravity, tornado, flock, matrix
./fx quake 8       # any of them with a custom length in seconds
./fx countdown "Standup"  # 3, 2, 1, then the message
```
