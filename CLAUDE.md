# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot **4.7** 2D game template (GDScript only, no 3D) targeting PC and mobile. It ships two **genre modules**, `game/platformer/` (side-scrolling) and `game/topdown/`, on top of a shared base. A one-time setup script keeps one module and trashes the other. User-facing docs, comments and UI translation values are in **Brazilian Portuguese**; identifiers are English. `README.md` explains the architecture, and `IMPROVEMENTS.md` is the backlog of features that are deliberately not implemented yet. Update it when you implement or add one of those items.

## Commands

Godot is installed at `C:\Godot\Godot.exe`. The `_console.exe` wrapper there is broken because it looks for a differently named main exe. Godot is a GUI-subsystem app, so pass `--log-file <path>` to capture output.

```bash
# Re-import assets (needed after adding/moving files, editing the CSV, or deleting scripts still in the .godot cache)
/c/Godot/Godot.exe --headless --path . --import --log-file import.log

# Smoke test: shared checks + every genre suite present (exits non-zero on failure)
/c/Godot/Godot.exe --headless --path . res://tests/smoke_test.tscn --log-file smoke.log

# Genre setup (destructive: moves the other module to the OS trash). Test it on a COPY of the project.
/c/Godot/Godot.exe --headless --path <copy> -s res://tools/setup_genre_cli.gd --log-file setup.log -- topdown

# Render real frames to PNG for visual checks (opens a window briefly)
/c/Godot/Godot.exe --path . res://game/game.tscn --write-movie out/f.png --quit-after 60
```

CI lives in `.github/workflows/ci.yml`; it uses the composite action `.github/actions/setup-godot`, which downloads and caches the Godot binary and export templates. On every push or PR it imports the project and runs the smoke test. On `v*` tags it exports the 4 presets in `export_presets.cfg` (Windows Desktop, Linux, Web, Android) and publishes a GitHub Release.
- Keep `GODOT_VERSION` in the workflow equal to the editor version.
- Android signing comes only from env vars (`GODOT_ANDROID_KEYSTORE_*`). The CI generates a debug keystore and uses a release keystore only when repo secrets exist.
- Editor settings in 4.7 live in `editor_settings-4.7.tres` (named by `major.minor`).
- Before committing workflow changes, lint them with **actionlint**. It's not installed globally. Get it from the rhysd/actionlint releases (verify the checksum) and run `actionlint -no-color -oneline` at the repo root. It also parses the local composite action. Quote any YAML value that contains `: `: an unquoted `description: ... (ex.: 4.7.2)` broke the first CI run.
- Locally there are no export templates or Java, so presets can only be validated: `--export-release "<preset>"` fails with "template not found" for valid presets and with "Invalid export preset name" for invalid ones.

Tests must run as a **scene**, not with `-s script.gd`. In `-s` mode autoload identifiers (`EventBus`, `Settings`…) aren't available at compile time, so any script touching them fails to compile. The setup CLI works with `-s` only because `tools/genre_setup.gd` has no autoload or game dependencies. Keep it that way.

Test timing:
- `await get_tree().physics_frame` resumes **before** nodes run `_physics_process` for that frame. After simulating input, wait an extra frame before asserting on state changes.
- Events from `Input.parse_input_event` reach `_input` on the next **process** frame. Several physics frames can run before that, so await `process_frame` when testing event-driven code.

The smoke test remaps bindings, so it snapshots and restores the player's real bindings (`InputBindings.get_snapshot/apply_snapshot`) to avoid leaving overrides in `user://settings.cfg`. Keep that pattern in any test that touches `InputBindings` or `Settings`.

## Architecture

- **Module boundary**: `core/`, `ui/`, `autoloads/` and the root of `game/` (`game.gd`, `level.gd`, `hazards/`, `props/`, `world/`) must never reference `game/platformer/` or `game/topdown/`. Modules connect only via `ScenePaths.FIRST_LEVEL` (rewritten by the setup) and `Level` exports (`touch_primary_action`/`touch_secondary_action`, which `game.gd` passes to `TouchControls.configure`). Module `class_name`s are genre-prefixed (`PlatformerPlayer`, `TopDownState`…) because both modules coexist before setup. Each module owns its test suite at `game/<genre>/tests/<genre>_smoke_test.gd` (a `RefCounted` with `run(t: SmokeTest)`), discovered via `GENRE_SUITES` in `tests/smoke_test.gd`. A new module must also be registered in `GENRES` in `tools/genre_setup.gd`, along with the input actions only it uses.
- **Autoloads** (`autoloads/`, order matters): `EventBus` (global signals only), `Settings` (ConfigFile; `DEFAULTS` merged then applied in `_apply`), `SaveSystem` (versioned JSON, atomic tmp→rename with `.bak` fallback; nodes in group `persist` implement `save_state(data)`/`load_state(data)`), `AudioManager` (buses Master/Music/SFX/UI from `default_bus_layout.tres`), `InputManager` (active device detection; `using_mouse` becomes true only after real mouse motion or clicks and resets on gamepad or touch), `InputBindings` (remapping; must load after `Settings` and `InputManager`), `SceneLoader` (threaded load + fade; always change scenes through it).
- **Communication rule**: call down, signal up. Use `EventBus` only between systems that don't know each other. For example, the players emit `player_health_changed` and the HUD listens; the HUD never references a player.
- **`core/`**:
  - Node-based FSM: states are identified by **node name**, and `StateMachine` awaits `owner.ready` before entering the initial state.
  - Damage components: `HitboxComponent` (layer 4) is detected by `HurtboxComponent` (layer 5, mask 4), which passes damage to `HealthComponent`. The hurtbox polls each physics frame so i-frames work, and it **skips hitboxes with the same `owner`**. `HealthComponent` also offers `grant_invulnerability()` and `revive()`.
  - `GameCamera`: trauma² noise shake triggered via `EventBus.camera_shake_requested`.
  - Static helpers: `MathUtils`, `PlatformUtils`, `ScenePaths`, `PhysicsLayers`.
- **Players**: both expose movement primitives, and their states decide the transitions.
  - Platformer: `apply_gravity`/`apply_horizontal`/`jump`, with coyote/buffer timers in `_physics_process`, which runs before the child StateMachine. Jump physics derive from height/time in `PlatformerStats`.
  - Top-down: `motion_mode` is floating, the origin is at the feet with a small foot collider, and the level sorts entities by Y-sort under `Entities`. It provides `apply_movement`/`face`/`set_attack_active`. Twin-stick aim is resolved in `_update_aim()` each physics frame, with priority right stick (`aim_*` actions), then mouse (if `InputManager.using_mouse`), then `facing`. The attack hitbox lives under `AttackPivot`, which is rotated to `aim_direction` and locked while attacking.
- **Input** is action-only (`move_*`, `jump`, `attack`, `dash`, `aim_*`, `interact`, `pause`).
  - Mouse bindings must use `device = InputEvent.DEVICE_ID_MOUSE` (32). In 4.7, keyboard is 16 and touch-emulated mouse is `DEVICE_ID_EMULATION` (-1). A mouse binding with device -1 (all devices) would fire on every touch on mobile.
  - `InputBindings` treats the first event of each kind (keyboard/mouse vs gamepad) as an action's "primary" binding; that's the one the Controls screen remaps. Overrides are stored as plain dicts in `settings.cfg [input]`, and only the actions that differ from the defaults are saved.
  - Remappable actions are listed in `InputBindings.REMAPPABLE`. Actions missing from the InputMap (removed by the genre setup) are skipped automatically. Touch uses Godot 4.7's **native `VirtualJoystick`** plus the custom `TouchButton`, which emits `InputEventAction` via `Input.parse_input_event`. Don't declare a `class_name VirtualJoystick`: it collides with the native class.
- **UI**: text properties hold translation keys from `localization/translations.csv`. The generated `.translation` files are committed. `SettingsMenu` and `ControlsMenu` are self-freeing overlays that emit `closed`. A parent overlay hides its own panel while a child overlay is open, so gamepad focus doesn't leak behind it. `ActionPromptLabel` shows "<action> [binding]" for the current device. `SafeAreaMargin` handles notches. Pause/menu scenes handle `NOTIFICATION_WM_GO_BACK_REQUEST` because `quit_on_go_back=false`.

## Conventions

- Static typing everywhere (`untyped_declaration` warns); type loop variables (`for x: Node in ...`).
- Reference nodes in the same scene with `%UniqueName`. Exported node refs in `.tscn` need `node_paths=PackedStringArray(...)` on the node header.
- When moving scripts on disk, move their `.gd.uid` files too.
- Physics interpolation is on. Cameras use `process_callback = 0` (physics).
- Renderer is GL Compatibility with a 640×360 base, `canvas_items` + `expand` stretch, and nearest filtering.
