# Peng-Balls (Godot 4 Mobile Edition)

Peng-Balls is a competitive 3D marble-maze speedrunner built natively in Godot 4 for Android and the Solana Mobile ecosystem (Seeker). Players navigate intricate 3D mazes, collect coins, avoid wandering patrol enemies, and compete for weekly prize pools funded in $SKR and DevCoin.

---

## Overview and Core Mechanics

- **Native Mobile Physics**: High-precision 60 FPS marble physics powered by Godot 4 (`CharacterBody3D`, `move_and_slide`).
- **Touch-First Controls**: On-screen dynamic virtual joystick for marble movement, accompanied by screen swipe gestures for 360-degree camera rotation.
- **Weekly Prize Pools**: Players enter competitive time-trial rounds by staking entry fees in $SKR or DevCoin into an on-chain smart contract escrow.
- **The 90/10 Pot Distribution**: 90% of the entire accumulated weekly prize pot is awarded to the player holding the single fastest winning maze run time. The remaining 10% is allocated for protocol maintenance and round rollover.
- **Live Leaderboard**: Real-time ranking showing rank, player address, completion times (down to centisecond precision), and personal bests.

---

## Solana Mobile Architecture

### On-Chain Program (Anchor)
- **Network**: Solana Devnet
- **Program ID**: `Mh2yn8cR99LYd88UcihsCnbXatss89VKxYZU9W6WQEj`
- **Accounts**:
  - `PoolRound`: Manages round metadata, entry fees, accumulated pot, active ticket balances, and 7-day expiration timestamps.
  - `Leaderboard`: Stores verified top 10 winning run times sorted lowest-first.
  - `PlayerStats`: Tracks persistent player records (wins, losses, personal best time, and active run tickets).
  - `Vault`: Program Derived Address (PDA) acting as autonomous non-custodial escrow for pooled funds.

### Mobile Wallet Adapter (MWA)
The game connects directly to mobile wallets (Phantom, Solflare, Seed Vault) using the Solana Mobile Wallet Adapter specification:
- 1-tap authorization without seed phrase entry.
- Direct JSON-RPC communication with Solana Devnet (`https://api.devnet.solana.com`).
- Live on-chain balance lookups via `getBalance`.

---

## User Flow

1. **Launch & Menu**: View the current weekly prize pot and 1st-place target time directly on the main menu top bar.
2. **Connect Wallet**: Tap the Mobile Wallet Adapter button to authorize via Phantom, Solflare, or Seed Vault.
3. **Select Pool**: Open the Leaderboard to toggle between $SKR and DevCoin pools.
4. **Enter & Play**: Deposit the entry fee to unlock the speedrun.
5. **Speedrun Maze**: Collect all coins while dodging patrol hazards. The HUD tracks your elapsed time alongside the current 1st-place record.
6. **Settlement**: Upon victory, completion time is logged to the leaderboard. If the time holds until round close, 90% of the pool is distributed to the winner.

---

## Repository Structure

```
peng-balls-v4/
├── assets/                  # 3D models and environmental meshes
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
│       ├── LeaderboardModal.gd / .tscn # Live ranking, currency tabs, and pool UI
│       └── Menu.gd / .tscn             # Main menu and MWA status bar
├── solana/
│   └── SolanaPoolManager.gd # Autoload singleton for Solana RPC, MWA, and state
├── export_presets.cfg       # Android export preset (arm64-v8a, armeabi-v7a)
├── project.godot            # Godot 4.7 engine configuration
└── docs/                    # Technical reference and presentation materials
```

---

## Building and Exporting

### Prerequisites
- **Godot Engine**: v4.7.x Stable
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

## Configuration Settings

Key configuration variables located in `solana/SolanaPoolManager.gd`:

| Constant / Variable | Value | Description |
|:---|:---|:---|
| `PROGRAM_ID` | `Mh2yn8cR99LYd88UcihsCnbXatss89VKxYZU9W6WQEj` | Anchor Program ID on Devnet |
| `DEVNET_RPC` | `https://api.devnet.solana.com` | Primary Solana RPC Endpoint |
| `entry_fee_skr` | `250.0` | Entry fee per run in $SKR |
| `entry_fee_devcoin` | `100.0` | Entry fee per run in DevCoin |
| `round_id` | `1` | Active competitive tournament round |

---

## License

This project is licensed under the MIT License.
