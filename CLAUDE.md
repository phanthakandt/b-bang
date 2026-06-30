# B-Bang — Project Reference for Claude

## Game Overview
2D top-down roguelike shooter in **Godot 4.6** (GDScript).
- Camera: oblique top-down (Hades-style)
- Controls: WASD move + mouse aim/shoot
- Core loop: 10 runs × 5 stages, card draft on level-up, permanent perk tree
- Weapons: mag system + cooldown-before-reload, 10 weapon types

## Engine & Project Settings
- Godot version: **4.6**
- Renderer: `GL Compatibility` (2D performance)
- Viewport: 1280 × 720, stretch mode `canvas_items`
- GDScript: **static typing required** — always declare types on variables and return values
- No Godot 3 patterns: use `super()`, `@export`, `%NodeName`, `FileAccess`, `JSON.parse_string()`

## Folder Structure
```
res://
├── autoload/          # Singletons registered in project.godot
├── scenes/
│   ├── player/
│   ├── weapons/
│   ├── enemies/
│   ├── rooms/
│   └── ui/
├── resources/         # Resource .gd class definitions + .tres/.res instances
│   ├── weapons/
│   ├── cards/
│   └── perks/
├── systems/           # Pure-logic scripts (no Node dependency)
└── assets/
    ├── sprites/
    └── sounds/
```

## Autoloads (global singletons)
All three are registered in `project.godot` with the `*` prefix (Node singleton).

### `EventBus` — `autoload/event_bus.gd`
Signal-only. No logic. Every system emits and listens here — no direct Node-to-Node signal connections.

| Signal | Args |
|---|---|
| `player_died` | — |
| `player_leveled_up` | `new_level: int` |
| `room_cleared` | — |
| `run_started` | `run_index: int` |
| `run_ended` | `won: bool` |
| `card_selected` | `card_id: String` |
| `weapon_mag_empty` | — |
| `weapon_reload_complete` | — |
| `enemy_died` | `enemy: Node` |
| `gold_changed` | `amount: int` |
| `hp_changed` | `current: int, maximum: int` |

**Rule:** never add logic to EventBus. Keep it signals-only.

### `GameManager` — `autoload/game_manager.gd`
In-run state. Resets on `start_run()`. Not persisted.

| Member | Type | Notes |
|---|---|---|
| `MAX_RUNS` | `const int` | 10 |
| `STAGES_PER_RUN` | `const int` | 5 |
| `current_run` | `int` | increments in `start_run()` |
| `current_stage` | `int` | increments in `next_stage()` |
| `gold` | `int` | resets each run |
| `is_paused` | `bool` | reset to false on `run_ended` |

`get_difficulty_multiplier()` → `1.0 + current_run * 0.15` (range 1.0–2.35 across runs 1–9)

`end_run()` writes to `SaveManager` and emits `EventBus.run_ended`.

### `SaveManager` — `autoload/save_manager.gd`
Persistent meta-progression. Saves to `user://save_data.json`.

```gdscript
data = {
    "unlocked_perks": [],   # Array[String] of perk_ids
    "total_runs": 0,
    "best_run": 0,
    "settings": {}
}
```

`load()` merges file into defaults — new keys added in future versions won't break old saves.

## Resource Classes

### `WeaponData` — `resources/weapon_data.gd`
```
weapon_name, weapon_type (auto/burst/semi/shotgun/special)
damage, fire_rate (shots/sec), mag_size, reload_time, cooldown_time
accuracy (0–1, spread = (1-accuracy)*15°), bullet_speed, bullet_count
is_auto (hold vs click)
skill_name, skill_description, skill_cooldown
synergy_path (aggro/precision/control/dot)
```

### `CardData` — `resources/card_data.gd`
```
card_id, card_name, description
rarity (common/rare/epic/legendary/curse), is_curse
effect_type (stat_modifier/weapon_mod/passive/active)
effect_params: Dictionary   # interpreted by effect system
synergy_tags: Array[String]
```

### `PerkData` — `resources/perk_data.gd`
```
perk_id, perk_name, description
perk_tree (combat/survival/fortune), cost: int
prerequisites: Array[String]   # perk_ids required first
effect_type, effect_params: Dictionary
```

## Coding Conventions
- **Signals via EventBus only** — no `node.signal.connect(other_node.method)` across unrelated systems
- **Resource instances** as `.tres` files under `resources/weapons/`, `resources/cards/`, `resources/perks/`
- `class_name` on every Resource subclass
- `@export_group` to organise inspector sections on Resources
- Comments only when the WHY is non-obvious — no "this function does X" comments
- No gameplay logic in autoloads — GameManager orchestrates state, systems implement behaviour
- `push_error()` / `push_warning()` for non-crash issues (visible in editor Output, not crashes)

## Input Actions (must exist in Project Settings → Input Map)
| Action | Key |
|---|---|
| `move_up` | W |
| `move_down` | S |
| `move_left` | A |
| `move_right` | D |
| `dash` | Left Shift |
| `reload` | R |
| `shoot` | Mouse Button Left |
| `aim` | Mouse Button Right |
| `interact` | E |
| `use_skill` | Q |

## Key design decisions

### Player
- **Dash timers**: float countdowns in `_tick_timers(delta)` — no Timer nodes needed
- **Aim**: `gun_pivot.rotation = aim_dir.angle()` every physics frame; FacingLine point[1] updated in local space
- **Player group**: `"player"` added in `_ready()` — bullet filter uses this to skip self-hit

### Weapon system
- **WeaponHolder state machine**: IDLE → COOLDOWN (mag empty penalty) → RELOADING → IDLE
- **COOLDOWN vs RELOADING**: intentionally separate — COOLDOWN is a punishment for emptying mag; pressing R during COOLDOWN skips it (skill expression)
- **Semi-auto**: uses `Input.is_action_just_pressed` outside the match block (not inside IDLE case)
- **Auto-fire**: uses `Input.is_action_pressed` inside the IDLE match case
- **Bullets** added to `get_tree().current_scene` — not parented to player, so they don't move with player
- **Bullet group** `"bullet"` — CRITICAL: shotgun pellets all spawn at the same MuzzlePoint position; without this group check, `area_entered` causes pellets to instantly destroy each other
- **Bullet collision**: `body_entered` → walls/CharacterBody2D; `area_entered` → enemy HurtBoxes (future). Both skip groups `"player"` and `"bullet"`

### Player UI
- **Reload bar**: Node2D child of Player at (0, -28) — world space, follows player automatically. Two ColorRect children: BG (fixed 32px) + Fill (width driven by `size.x = 32 * progress`)
- **Bar colors**: orange = COOLDOWN phase, yellow = RELOADING phase, hidden = IDLE
- **Untyped `_wh`**: `@onready var _wh = $GunPivot` (no type annotation) — needed because weapon_holder has no `class_name`; typed `Marker2D` would block duck-typed method calls like `is_busy()`

### weapon_holder helpers (for external access without enum exposure)
| Method | Returns | Purpose |
|---|---|---|
| `is_busy()` | `bool` | show/hide reload bar |
| `is_in_cooldown()` | `bool` | bar color selection |
| `get_reload_progress()` | `float 0–1` | bar fill width |
| `get_state_string()` | `String` | HUD state label |

### Other
- **Difficulty multiplier**: `1.0 + current_run * 0.15`, range 1.0 (run 0) → 2.35 (run 9)

### Enemy system
- **EnemyBase state machine**: IDLE/PATROL → CHASE → ATTACK, with STUNNED/DEAD as interrupts. `_physics_process` dispatches via `match state` then calls `move_and_slide()` once centrally — state functions only set `velocity`, never call `move_and_slide()` themselves (Gunner overrides `_state_chase` and relies on this)
- **Collision layers**: enemy body (CharacterBody2D) sits on `collision_layer = 4`, NOT the default layer 1 that bullets monitor. Only the HurtBox `Area2D` (layer 1) takes bullet hits via `area_entered`. Without this split, a bullet overlapping both the body and the HurtBox at once would call `take_damage()` twice
- **Per-instance shape duplication**: `body_size`/`detection_radius` are `@export` so Runner/Gunner can override them, but the underlying `RectangleShape2D`/`CircleShape2D` sub-resources are shared across all instances of `enemy_base.tscn` unless duplicated — `_ready()` calls `.duplicate()` before resizing
- **`player_ref` typed `Player`** (not `Node2D`) — `Player` has a `class_name`, so static calls like `player_ref.take_damage()` work without the duck-typing workaround `weapon_holder` needs
- **Gunner** overrides `_state_chase` to hold `preferred_distance` instead of closing to melee range; **Runner** just charges and melees
- **Gunner kiting wall guard**: Gunner backs away when `dist < preferred_distance` while always facing the player (intentional — fire-and-retreat). If a wall is directly behind it, retreating gets physically blocked but `dist` never grows past `preferred_distance`, so it would push into the wall forever. The retreat branch is gated on `get_slide_collision_count() == 0` (reflects last frame's `move_and_slide()`) — once blocked, it falls through to `ATTACK` (stand and shoot) instead of stalling against the wall
- **PATROL wall handling**: a raw random `patrol_target` (`global_position + ±100px`) can land outside the room (behind a wall), making the enemy beeline into the wall and stall. Tried `nav_agent` routing and `NavigationServer2D.map_get_closest_point` snapping first — both unreliable (nav map sync timing). Landed on two layers: (1) `RoomBase.spawn_wave()` passes each enemy a `patrol_bounds: Rect2` (`RoomBase.FLOOR_BOUNDS`, matching the floor's `NavigationPolygon` rect) that `_pick_patrol_target()`/`_clamp_to_patrol_bounds()` clamps every new target into, inset by half `body_size`; (2) `get_slide_collision_count() > 0` at the top of `_state_patrol` is the actual wall-hit detector — on hit, `_reverse_patrol_direction()` backs off using `get_slide_collision(0).get_normal()` (the actual wall surface normal Godot computed) rather than reversing the intended heading, which wasn't reliable near corners/glancing angles and kept re-triggering. Zero `Rect2` (default `patrol_bounds`) means unbounded, for enemies not spawned via `spawn_wave`

### Room system
- **RoomBase** (`scenes/rooms/room_base.gd`): walls are hand-authored `StaticBody2D` segments in `room_base.tscn` (split per side to leave a 96px door gap), not built at runtime — the old `test_room.gd._build_room()` runtime approach was replaced
- **NavigationRegion2D**: `room_base.tscn` ships a pre-baked `NavigationPolygon` (vertices+polygons for the floor quad) instead of baking at runtime, since there's no editor pass available to trigger a bake
- **Door gap sizing**: `door.tscn` ships a generic 32×64 placeholder shape; `Door.configure(gap_size)` resizes/duplicates it at runtime to fit whichever wall opening `room_base.gd` cut (N/S doors get a 96×32 gap, E/W get 32×96)
- **RoomLoader autoload** (`systems/room_loader.gd`) tracks `current_room` + `rooms_completed`; boss room loads after 4 procedurally-loaded rooms (so 5 combat rooms total counting the hand-placed one in `test_room.tscn`, matching `GameManager.STAGES_PER_RUN`). `default_enemy_scenes`/`default_wave_count`/`default_enemies_per_wave` must be set by whoever owns the run (currently `test_room.gd`) since procedurally instanced `room_base.tscn` copies don't carry the enemy_scenes override the hand-placed instance has
- **Door → next room**: `Door._on_transition_trigger_body_entered` calls `RoomLoader.load_next_room()` directly rather than re-emitting `EventBus.room_cleared` — reusing that signal would also fire when waves finish (since `RoomBase.clear_room()` already emits it), double-triggering room loads

## Weapon instances (`resources/weapons/`)
| File | Type | Mag | fire_rate | bullet_count | Notes |
|---|---|---|---|---|---|
| `ak_iron.tres` | auto | 30 | 8/s | 1 | medium spread (accuracy 0.6) |
| `breach_12.tres` | shotgun | 2 | 1.2/s | 8 | wide spread (accuracy 0.25), reload_time 1.0s, cooldown 0.3s |
| `echo_smg.tres` | auto | 25 | 14/s | 1 | fastest fire rate, accuracy 0.5 |

## Step Progress
| Step | Status | Summary |
|---|---|---|
| 1 | Done | Folder structure, autoloads, Resource classes, main scene |
| 2 | Done | Player: WASD + dash + HP + aim; player.tscn |
| 3 | Done | WeaponHolder state machine, Bullet scene, 3 weapon .tres, test_room |
| Hotfix | Done | Bullet group `"bullet"` — shotgun pellet mutual destruction bug |
| Addon | Done | Reload progress bar above player head (world space, 2-phase color) |
| 4 | Done | EnemyBase state machine (IDLE/PATROL/CHASE/ATTACK/STUNNED/DEAD), Runner + Gunner subclasses, enemy_bullet.gd |
| 5 | Done | RoomBase (waves, doors, NavigationRegion2D floor), Door, RoomLoader autoload, boss_room placeholder; test_room rebuilt on RoomBase |
| 6–N | Pending | — |
