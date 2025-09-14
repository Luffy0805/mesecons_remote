# Minetest Mod: Mesecons Remote

By Luffy0805
Version: 1.0.0
License: MIT

---

## Installation

1. Place the mod folder in the `mods/` directory
2. Enable the mod in the desired world
3. The `mesecons` mod is required

---

## Description

This mod allows players to **control receivers remotely** using a remote (`remote`).
Each receiver has a **unique ID** and can be activated or deactivated in **button** (momentary) or **lever** (toggle) mode.

The remote's channel configuration is **stored in its inventory** and can be changed via a configuration form.
Receivers display their current state (`ON` or `OFF`) directly in their infotext.

---

## Features

* Remote `ON/OFF` receivers for Mesecons
* Configuration form accessible by pressing `Aux1 + left click` with the remote
* Remote configurable with **4 channels**:

  * Left Click
  * Right Click
  * Shift+Left Click
  * Shift+Right Click
* Modes: **button** (3 seconds) or **lever** (toggle)
* Dynamic display of receiver states
* Automatic storage of receivers in the world file
* Chat command `/receiver <ID>` to locate a receiver by ID

---

## Commands

```bash
/receiver <ID>
```

* Displays the position and state (`ON/OFF`) of the receiver with the provided ID.
* Example: `/receiver R0001` → `Receiver R0001 : (x, y, z), ON`

---

## Remote Control

* **Left Click** → Activates the left channel
* **Right Click** → Activates the right channel
* **Shift+Left Click** → Activates the 3rd channel
* **Shift+Right Click** → Activates the 4th channel
* **Ctrl/Shift+Click** → Opens the configuration form
* Channels and modes configurable via form

---

## Storage & Persistence

* Receivers are automatically saved in `mesecons_remote_receivers.data` in the world directory
* Receiver IDs are **standardized** (e.g., R0001)
* Destroyed receivers are automatically removed from the database

---

## Recommended Structure

```
mods/
└── mesecons_remote/
    ├── mod.conf
    ├── init.lua
    ├── README-fr.txt
    ├── README.md
    ├── textures/
    │   ├── receiver_off.png
    │   ├── receiver_on.png
    │   └── remote.png
```

---

## Notes

* All sounds and textures must be compatible with Minetest
* The mod works only with Mesecons enabled
* IDs are unique and automatically generated
* Sound volume and Mesecons settings can be modified in the code

---

## License

Code: MIT
Textures: MIT
