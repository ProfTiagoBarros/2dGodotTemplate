# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot **4.7** 2D game template (GDScript only, no 3D) targeting PC and mobile. It ships two **genre modules**, `game/platformer/` (side-scrolling) and `game/topdown/`, on top of a shared base. A one-time setup script keeps one module and trashes the other. User-facing docs, comments and UI translation values are in **Brazilian Portuguese**; identifiers are English. `README.md` explains the architecture, and `IMPROVEMENTS.md` is the backlog of features that are deliberately not implemented yet. Update it when you implement or add one of those items.

Docs are bilingual: `README.md`/`MANUAL.md` (Portuguese, primary) and `README.en.md`/`MANUAL.en.md` (English). Any doc change must be made in both languages and keep the language switchers and cross-file anchors valid. Record user-visible changes under *Não lançado* in `CHANGELOG.md` (Keep a Changelog, SemVer). The project is MIT-licensed. The README states that the template was developed with AI assistance (Claude, by Anthropic); keep that disclosure and the `Co-Authored-By` trailers. Community files: `CONTRIBUTING.md`, `SECURITY.md` (private vulnerability reporting), `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`, `.github/CODEOWNERS`, `.github/release.yml`.

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
- `process_frame` likewise fires **before** `_process`, so anything drained in `_process` (such as console output) needs about 3 `process_frame` awaits before you assert.
- Events from `Input.parse_input_event` reach `_input` on the next **process** frame. Several physics frames can run before that, so await `process_frame` when testing event-driven code.

`SmokeTest` provides `spawned_effects` (names of the `OneShotEffect` scenes added since the last `clear()`), `hitstop_count` and `real_seconds()` for asserting game feel. Game-feel timing must be measured in real time, because hitstop changes `time_scale`.

All copies of the project share one `user://` directory, because it is keyed by project name. Visual probes run on scratch copies therefore write to the real user data, so always call `SaveSystem.new_game(<test slot>)` in probes.

The smoke test uses save slot 98 (`SmokeTest.TEST_SLOT`) and deletes it at the end, so autosaves during tests never touch the player's real save. The runner fails, rather than hangs, when a genre suite doesn't compile (`can_instantiate()`). GDScript gotcha: `a == [..] as Array[T]` parses as `(a == [..]) as ...`, so use a typed local variable instead.

The smoke test remaps bindings, so it snapshots and restores the player's real bindings (`InputBindings.get_snapshot/apply_snapshot`) to avoid leaving overrides in `user://settings.cfg`. Keep that pattern in any test that touches `InputBindings` or `Settings`.

## Architecture

- **Module boundary**: `core/`, `ui/`, `autoloads/` and the root of `game/` (`game.gd`, `level.gd`, `hazards/`, `props/`, `world/`) must never reference `game/platformer/` or `game/topdown/`. Modules connect only via `ScenePaths.FIRST_LEVEL` (rewritten by the setup) and `Level` exports (`touch_actions` for touch buttons A/B/C and `hud_hint_actions` for HUD prompts; `game.gd` passes them to `TouchControls.configure` and `GameHUD.set_hint_actions`). Module `class_name`s are genre-prefixed (`PlatformerPlayer`, `TopDownState`…) because both modules coexist before setup. Each module owns its test suite at `game/<genre>/tests/<genre>_smoke_test.gd` (a `RefCounted` with `run(t: SmokeTest)`), discovered via `GENRE_SUITES` in `tests/smoke_test.gd`. A new module must also be registered in `GENRES` in `tools/genre_setup.gd`, along with the input actions only it uses.
- **Autoloads** (`autoloads/`, order matters): `Log` (first; leveled logging — use `Log.debug/info/warn/error` instead of `print`/`push_*`), `EventBus` (global signals only), `Settings` (ConfigFile; `DEFAULTS` merged then applied in `_apply`), `SaveSystem` (versioned JSON, atomic tmp→rename with `.bak` fallback; nodes in group `persist` implement `save_state(data)`/`load_state(data)`), `AudioManager` (buses Master/Music/SFX/UI from `default_bus_layout.tres`), `GameFeel` (hitstop + one-shot effects), `InputManager` (active device detection; `using_mouse` becomes true only after real mouse motion or clicks and resets on gamepad or touch), `InputBindings` (remapping; must load after `Settings` and `InputManager`), `SceneLoader` (threaded load + fade; always change scenes through it), `DebugTools` (last; see below).
- **Game feel** (`autoloads/game_feel.gd` + `core/feel/`):
  - `GameFeel.hitstop(duration)` scales `Engine.time_scale` and restores it using **real time** (`Time.get_ticks_msec`). It respects `Settings game/hitstop` and emits `hitstop_started`.
  - `GameFeel.spawn_effect(GameFeel.DUST | HIT_SPARKS, pos)` instances a self-freeing `OneShotEffect` (CPUParticles2D) into `current_scene`.
  - `HitFlashComponent` puts a ShaderMaterial on `target` and sets `use_parent_material` on its descendants.
  - Character visuals are `Visual` (flip via `scale.x`) → `Squash` (`SquashStretch` + flash target) → drawables. Shadows stay outside `Squash`. Don't tween `Visual.modulate` for damage; the flash handles it.
- **Enemies** (`game/enemies/`, shared; concrete types live in each module's `enemies/`):
  - `Enemy` (base `CharacterBody2D`, group `enemy`) handles perception, windup/lunge, knockback and death; the generic `EnemyState`s (Patrol/Chase/Windup/Attack/Recover/Hurt) use only its public API.
  - Perception happens in `update_target()`, which runs in `Enemy._physics_process` before the StateMachine. It checks `detection_radius` plus a line-of-sight ray against `PhysicsLayers.WORLD`, with hysteresis via `lose_target_radius`.
  - Genre subclasses override only movement: `patrol_direction`, `direction_to_target`, `move_toward_direction` (which must call `move_and_slide`), `lunge_step`, `apply_knockback` and optionally `can_attack_target`. `PlatformerEnemy` uses `LedgeRay` with `force_raycast_update()` for ledge checks.
  - Numbers come from `EnemyStats` .tres files. `end_windup()` must kill the windup tween, because a hit can interrupt the windup.
  - Genre test suites free the level's enemies at the start and spawn their own, which keeps the movement tests deterministic.
- **Debug tools** exist only when `OS.is_debug_build()`; in release, `DebugTools` returns early and loads nothing.
  - F3 toggles the overlay, F1/` the console (which pauses the tree and restores the previous pause state on close), and a 3-finger tap opens the console on mobile.
  - `ConsoleLogger` (`core/debug/`, a native `Logger` subclass registered with `OS.add_logger`) captures all engine output thread-safely, and `DebugTools._process` drains it into the console.
  - Commands are `Callable(args: PackedStringArray) -> String` registered with `DebugTools.register_command`; overlay values come from `DebugTools.watch(label, getter)`. Generic commands live in `debug_tools.gd`. Gameplay ones live in `game/game_debug_commands.gd`, a provider auto-loaded from `DebugTools.COMMAND_PROVIDERS`. It is genre-agnostic: it finds the player via group `player` and duck-typed `health`/`state_machine`/`velocity`.
  - The `level <name>` command sets the static `Game.level_override`.
  - Native-name collisions to avoid: `Logger` and `VirtualJoystick` are engine classes. Enums in autoloads must not share names with global `class_name`s; `Log.Level` clashed with `class_name Level`, hence `Log.LogLevel`.
- **Communication rule**: call down, signal up. Use `EventBus` only between systems that don't know each other. For example, the players emit `player_health_changed` and the HUD listens; the HUD never references a player.
- **`core/`**:
  - Node-based FSM: states are identified by **node name**, and `StateMachine` awaits `owner.ready` before entering the initial state.
  - Damage components: `HitboxComponent` (layer 4) is detected by `HurtboxComponent` (layer 5, mask 4), which passes damage to `HealthComponent`. The hurtbox polls each physics frame so i-frames work. It **skips hitboxes with the same `owner` or the same non-empty `team`** (`player`/`enemy`); an empty team is neutral and hits everyone, e.g. spikes. `HealthComponent` also offers `grant_invulnerability()`, `revive()`, `kill()` and `god_mode`.
  - `GameCamera`: trauma² noise shake triggered via `EventBus.camera_shake_requested`.
  - Static helpers: `MathUtils`, `PlatformUtils`, `ScenePaths`, `PhysicsLayers`.
- **Players**: both expose movement primitives, and their states decide the transitions.
  - Platformer (metroidvania-ready): `apply_gravity`/`apply_horizontal`/`jump`, with coyote/buffer timers in `_physics_process`, which runs before the child StateMachine. Jump physics derive from height/time in `PlatformerStats`.
    - States: Idle/Run/Jump/Fall/Attack/Dash. `PlatformerState.try_actions()` handles attack and dash from free states, and `transition_to_free_state()` picks Idle, Run or Fall.
    - Attack direction comes from input: ↑ attacks up, and ↓ in the air attacks down. A down hit pogos the player and refills air jumps and dashes.
    - Dash is horizontal and gravity-free, limited by `air_dashes` per airtime.
    - **Abilities**: `abilities: Array[StringName]` (`attack`, `dash`, `double_jump`…), gated with `has_ability()` and unlocked with `unlock_ability()`, which emits `EventBus.ability_unlocked`; the HUD shows a toast using key `ABILITY_<NAME>`. Abilities are persisted under `SaveSystem.data["platformer_abilities"]` through the `persist` group and read back in `_ready`.
    - `game/props/ability_pickup` is genre-agnostic (duck-typed) and autosaves on pickup.
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

## Security and performance rules

- **Never call `ConfigFile.load/parse`, `str_to_var` or `bytes_to_var` on untrusted data** (anything in `user://`, downloaded or player-shared). They construct objects and load scripts from text, so a tampered `settings.cfg` executed code; this was proven with an exploit test. Use `SafeConfig.load_file/parse` (`core/utils/safe_config.gd`), which rejects `Object(`, `Resource(`, `ExtResource(` and `SubResource(`, then validate types with `Settings.is_valid_value`. Saves are JSON, which is safe from code execution but still untrusted: type-check values, e.g. with `SaveSystem.get_int()`.
- Don't put `${{ inputs.* }}` or other expressions directly in `run:` scripts; pass them via `env:`. Keep `permissions: contents: read` at the workflow level. Pin third-party actions by commit SHA (Dependabot keeps them updated). Godot downloads are verified against the release's `SHA512-SUMS.txt`.
- `HurtboxComponent` sleeps until `area_entered` and goes back to sleep when nothing overlaps. Don't add per-frame logic that assumes it always processes.
- Enemy perception runs every `perception_interval` (0.1 s, random phase per enemy). Tests that expect detection must wait at least that long: use `_wait_for` and avoid checks pinned to an exact frame.
