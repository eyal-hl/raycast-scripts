# raycast-scripts

A collection of [Raycast](https://raycast.com) script commands.

| Command | What it does |
|---------|--------------|
| **Rain** 🌧️ | Confetti's gloomy cousin: grey sky, clouds and steady rain over your screen for a few seconds. |
| **Thunderstorm** ⛈️ | Darker sky, heavier rain, lightning. |

The weather overlays ignore clicks, so you can keep working while it rains. They fade out on their own.

## Install

Needs macOS and the Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/eyal-hl/raycast-scripts.git ~/raycast-scripts
```

Then add the folder to Raycast:

1. Open Raycast, search **Search Script Commands** and press Enter.
2. Choose **Add Script Command Folder** (or press ⌘K to find it).
3. In the folder picker press ⌘⇧G, paste `~/raycast-scripts`, press Enter and click **Open**.

Every script in the folder shows up as a command. Rain and Thunderstorm compile their Swift overlay on the first run, so that one takes a few seconds.

To get new commands later, `git pull` in the folder.

## Weather from the terminal

```bash
./rain             # rain for 12 seconds
./rain storm 20    # thunderstorm for 20 seconds
```
