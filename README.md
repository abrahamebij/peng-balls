# Peng-Balls (Godot 4 Mobile Edition)

Peng-Balls is a 3D marble-maze speedrunner built in Godot 4 for Android and desktop platforms. Players navigate intricate 3D mazes, collect coins, avoid wandering patrol enemies, and race for the best completion time.

---

## Overview and Core Mechanics

- **Native Mobile Physics**: High-precision marble physics powered by Godot 4 (`CharacterBody3D`, `move_and_slide`).
- **Touch-First Controls**: On-screen dynamic virtual joystick for marble movement, accompanied by screen swipe gestures for 360-degree camera rotation. Keyboard controls (WASD / Arrow keys) are supported for PC testing.
- **Procedural 3D Mazes**: Grid-based procedural maze generation carving rooms and hallways with configurable openness and loop factors.
- **Patrol AI**: Hazards wander the maze and actively chase the player with 3D line-of-sight raycasting.
- **Speedrun Timer**: Precise time tracking formatted down to centiseconds (`mm:ss.cc`).

---

## User Flow

1. **Launch & Menu**: Start a game directly from the main menu.
2. **Speedrun Maze**: Collect all coins while dodging patrol hazards.
3. **Completion**: Upon victory or defeat, review your final completion time and retry or return to the menu.

---

## Repository Structure

```
peng-balls-v4/
├── environments/            # Skyboxes, lighting, and tileset configurations
├── resources/               # Fonts and title screen textures
├── scenes/
│   ├── game/
│   │   ├── CameraPivot.gd   # 3D third-person spring arm camera
│   │   ├── Coin.gd / .tscn  # Collectible coin item with collision triggers
│   │   ├── Enemy.gd / .tscn # Patrol AI with raycast line-of-sight detection
│   │   ├── Game.gd / .tscn  # Main gameplay scene, HUD, and timer loop
│   │   ├── GridMap.gd       # Procedural 3D maze generation
│   │   ├── Player.gd / .tscn# CharacterBody3D marble controller
│   │   └── TouchControl.gd  # Dual-input virtual joystick and camera drag
│   └── menu/
│       └── Menu.gd / .tscn  # Main menu
├── export_presets.cfg       # Android export preset (arm64-v8a, armeabi-v7a)
└── project.godot            # Godot 4 engine configuration
```

---

## Building and Exporting

### Prerequisites
- **Godot Engine**: v4.x Stable
- **Android SDK**: Build Tools 30.0.3+ / Target SDK 34
- **Java Development Kit**: JDK 17 (Eclipse Adoptium / OpenJDK)
- **Export Templates**: Godot 4 Android templates installed

### Exporting via Godot CLI

```bash
# Debug export
godot --headless --path . --export-debug "Android" "build/PengBalls.apk"

# Release export
godot --headless --path . --export-release "Android" "build/PengBalls.apk"
```

### Installing on Device

```bash
adb install -r build/PengBalls.apk
```

---

## License

This project is licensed under the MIT License.
