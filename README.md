# Piezo

*Battery-aware refresh rate switching for Plasma 6.*

Drop your laptop screen to 60 Hz when you unplug, and bring it back up when you plug in again. For KDE Plasma on Wayland.

If you've got a 120/144/165/240 Hz panel, running it at 60 Hz on battery can buy you a noticeable amount of extra runtime. Plasma doesn't do this on its own yet (there are open wishlist requests: [Bug 461695](https://bugs.kde.org/show_bug.cgi?id=461695) and [Bug 514146](https://bugs.kde.org/show_bug.cgi?id=514146)), but it *does* let you run a script when the power state changes. This repo is just that script.

## What's in here

| File | What it does |
|---|---|
| `refresh-rate.sh` | The actual logic. Takes `battery` or `ac`. |
| `refresh-rate-battery.sh` | Tiny wrapper: runs the above with `battery`. |
| `refresh-rate-ac.sh` | Tiny wrapper: runs the above with `ac`. |

The two wrappers exist because Plasma's power settings want you to pick a *file*, and there's no box to type arguments into. One file per power state keeps that simple.

## What it does

- Finds your internal display (`eDP`, `LVDS` or `DSI`) on its own, so you don't have to hunt for the output name or mode number.
- Keeps your current resolution and only changes the refresh rate.
- On battery it picks the mode closest to 60 Hz. On AC it picks the highest refresh rate available.
- If the screen is already on the right mode, it does nothing.

It uses `kscreen-doctor`, which ships with Plasma and works on Wayland.

## Requirements

- KDE Plasma 6 (Wayland)
- `kscreen-doctor` (comes with Plasma)
- bash, awk, grep, sed

## Install

```bash
git clone https://github.com/MurderFromMars-Backup/Piezo ~/.local/share/piezo
cd ~/.local/share/piezo
chmod +x refresh-rate.sh refresh-rate-battery.sh refresh-rate-ac.sh
```

Or just copy the three scripts into any folder you like. Keep them together, since the wrappers look for `refresh-rate.sh` next to themselves.

### Try it by hand first

Before wiring anything into Plasma, make sure it actually works on your machine:

```bash
./refresh-rate-battery.sh   # screen should drop to 60 Hz
./refresh-rate-ac.sh        # and back up to the max
```

If you want to see what it's looking at:

```bash
kscreen-doctor -o
```

The active mode is the one marked with `*`.

### Hook it into Plasma

1. Open **System Settings → Power Management** (some versions call it Energy Saving).
2. Go to the **On Battery** tab, find **Run command or script**, set the trigger to when the profile is loaded (the wording varies a bit between versions), and choose `refresh-rate-battery.sh` with the file picker.
3. Go to the **On AC Power** tab and do the same with `refresh-rate-ac.sh`.
4. Hit **Apply**, then unplug and replug the charger to check it.

## Configuration

Everything has a sensible default, but if you need to change something, open the wrapper and uncomment the relevant line:

| Variable | Default | Meaning |
|---|---|---|
| `OUTPUT` | first `eDP`/`LVDS`/`DSI` panel | Which display to control, e.g. `eDP-1` |
| `BATTERY_HZ` | `60` | Target refresh rate on battery (closest available mode is used) |
| `AC_HZ` | highest available | Target refresh rate on AC |

## Troubleshooting

**"No internal display found"**
Your panel has an unusual name. Run `kscreen-doctor -o`, find its name, and set `OUTPUT` in the wrappers.

**"Could not determine current mode"**
The script reads `kscreen-doctor -o` and the output format can differ between Plasma versions. Open an issue and paste the output of `kscreen-doctor -o` and your Plasma version (`plasmashell --version`).

**Nothing happens when I plug/unplug**
Make sure the scripts are executable, that you picked them in the right tab, and that you clicked Apply. You can also run them by hand from a terminal to see any error messages.

**It switches to the wrong rate**
Some panels expose odd refresh rates at certain resolutions. Check the list in `kscreen-doctor -o` and set `BATTERY_HZ` or `AC_HZ` to a rate that's actually in there.

## How it works

`kscreen-doctor -o` lists every output with its modes, each shown as `id:WIDTHxHEIGHT@RATE`. The script strips the colour codes, grabs the block for your internal panel, finds the current resolution (the mode marked `*`), filters to modes at that resolution, picks the one closest to the target, and applies it with `kscreen-doctor output.<name>.mode.<id>`.

## Limitations

- It only handles the internal panel. External monitors are left alone unless you point `OUTPUT` at one.
- It's a one-shot switch on power events, not a smart power manager. It won't react to things like battery percentage.

## Contributing

Bug reports and fixes are welcome, especially if you've got a different laptop or Plasma version and something didn't parse right. Please include the output of `kscreen-doctor -o` when you open an issue.
