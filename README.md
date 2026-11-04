# raycast-scripts

A collection of [Raycast](https://raycast.com) script commands.

| Command | What it does |
|---------|--------------|
| **Rain** 🌧️ | Confetti's gloomy cousin: grey sky, clouds and steady rain over your screen for a few seconds. |
| **Thunderstorm** ⛈️ | Darker sky, heavier rain, lightning. |
| **God Rays** ☀️ | Warm sunbeams fan down from the top corner, with dust drifting in the light. |
| **Money Rain** 💸 | Bills and coins tumble down your screen instead of raindrops. |
| **Spotlight** 🔦 | Dims everything except a soft circle that follows your cursor. Run it again to turn it off. |

The overlays ignore clicks, so you can keep working while it rains. The weather ones fade out on their own.

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

## Weather from the terminal

```bash
./rain             # rain for 12 seconds
./rain storm 20    # thunderstorm for 20 seconds
./rain money       # money rain for 8 seconds
./rain rays        # god rays for 10 seconds
./spotlight        # cursor spotlight until you kill it
```
