# raycast-rain

Confetti's gloomy cousin. Two [Raycast](https://raycast.com) script commands that cover your screen with grey clouds and rain for a few seconds:

- **Rain** 🌧️ — grey sky, clouds, steady rain.
- **Thunderstorm** ⛈️ — darker sky, heavier rain, lightning.

The overlay ignores clicks, so you can keep working while it rains. It fades out on its own.

## Install

Needs macOS and the Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/eyal-hl/raycast-rain.git ~/raycast-rain
```

Then add the folder to Raycast:

1. Open Raycast, search **Search Script Commands** and press Enter.
2. Choose **Add Script Command Folder** (or press ⌘K to find it).
3. In the folder picker press ⌘⇧G, paste `~/raycast-rain`, press Enter and click **Open**.

Search **Rain** or **Thunderstorm**. The first run compiles the Swift overlay, so it takes a few seconds; after that it starts instantly.

## Run from the terminal

```bash
./rain             # rain for 12 seconds
./rain storm 20    # thunderstorm for 20 seconds
```
