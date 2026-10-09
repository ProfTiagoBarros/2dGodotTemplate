# Godot 2D Template

[Português](README.md) · **English**

[![CI](https://github.com/ProfTiagoBarros/2dGodotTemplate/actions/workflows/ci.yml/badge.svg)](https://github.com/ProfTiagoBarros/2dGodotTemplate/actions/workflows/ci.yml)
[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Built with Claude](https://img.shields.io/badge/built%20with-Claude%20(Anthropic)-D97757)](#credits-and-ai-usage)

Starter template for **2D** games in **Godot 4.7+**, built for **PC and mobile** at the same time, with a modular architecture and the patterns recommended by the official documentation and the indie community. It ships two **genre modules**, **side-scrolling (platformer)** and **top-down**, on top of the same base.

> 📘 **First time using the template?** Start with the **[MANUAL.en.md](MANUAL.en.md)**: a step-by-step guide to creating a new game, making the initial changes, building levels, enemies and abilities, publishing builds, and getting the most out of everything.
>
> Features that are not implemented yet are listed in [IMPROVEMENTS.md](IMPROVEMENTS.md) (in Portuguese). Version history lives in [CHANGELOG.md](CHANGELOG.md).
>
> 🤖 This template was developed **with AI assistance (Claude, by Anthropic)**. See [Credits and AI usage](#credits-and-ai-usage).

## Starting a new game

1. Create the project from the template (GitHub: **Use this template**, or copy the folder).
2. Open it in Godot 4.7+ (Project Manager → Import).
3. **Pick the genre** (only once):
   - **In the editor:** open `tools/setup_genre.gd`, set `const GENRE := "platformer"` or `"topdown"` and run it with **File → Run** (Ctrl+Shift+X). Then use *Project → Reload Current Project*.
   - **From the command line:**
     ```bash
     godot --headless --path . -s res://tools/setup_genre_cli.gd -- topdown
     ```

   The setup points `ScenePaths.FIRST_LEVEL` to the genre's level, moves the other genre's module to the **trash** (recoverable) and removes from the InputMap the actions only the other genre used.
4. **Game identity:**
   - Name: *Project Settings → Application → Config → Name*.
   - Android: `package/unique_name` (e.g. `com.yourstudio.yourgame`) and `package/name` in `export_presets.cfg` (or *Project → Export → Android*).
   - CI: `GAME_SLUG` in `.github/workflows/ci.yml`, used to name the generated files.
5. Press **F5**. From then on, every push runs the smoke test on GitHub and every `v*` tag produces builds (see [CI, builds and releases](#ci-builds-and-releases)).

> Before the setup, both modules coexist. To try the other genre, change `FIRST_LEVEL` in `core/constants/scene_paths.gd`.

### Controls

| Action | Keyboard / Mouse | Gamepad | Touch |
|---|---|---|---|
| Move | A/D/W/S or arrows | Left stick / D-pad | Virtual joystick |
| Aim (top-down) | Mouse (cursor) | Right stick | Movement direction |
| Jump (platformer) | Space / K | A | Button A |
| Attack | J / Left click | X | Button B (platformer) / A (top-down) |
| Dash | Shift / L / Right click | B | Button C (platformer) / B (top-down) |
| Interact | E | Y | — |
| Pause | Esc / P | Start | Button II |

Everything can be **remapped by the player** in *Settings → Controls* (see [Control remapping](#control-remapping)).

### Smoke test

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

Runs the shared tests plus the suite of every genre module present in the project.

## CI, builds and releases

The workflow [.github/workflows/ci.yml](.github/workflows/ci.yml) runs on GitHub Actions:

| Trigger | What happens |
|---|---|
| Push to `main` / Pull Request | Imports the project and runs the smoke test |
| `v*` tag (e.g. `v1.2.0`) | Smoke test → exports **Windows, Linux, Web and Android** → publishes a **Release** with the `.zip` files |
| Manual (*Actions → CI → Run workflow*) | Smoke test + export, no Release (builds are kept as *artifacts*) |

**To ship a version:**

```bash
git tag v1.2.0
```

```bash
git push origin v1.2.0
```

The tag's version (`1.2.0`) is written to `config/version`, shown in the corner of the main menu. It also becomes Android's `version/name`. Android's `version/code` uses the workflow run number, so it always increases.

**Details:**
- Godot and the export templates (~1.3 GB) are downloaded once and **cached**. The version is set by `GODOT_VERSION` in the workflow; keep it equal to the editor's.
- `tests/`, `tools/` and `game/*/tests/` are **excluded** from builds by the presets.
- **Web** uses the **no-threads** variant, compatible with itch.io and any static hosting, without COOP/COEP headers.
- **Android with no setup:** the APK is signed with a **debug** keystore generated in CI. You can install and test it, but not publish it on the Play Store.
- **Release Android builds:** add 3 repository *secrets* (*Settings → Secrets and variables → Actions*). With them, CI exports in release mode automatically.
  - `ANDROID_KEYSTORE_BASE64`: the keystore in base64 (`base64 -w0 release.keystore`).
  - `ANDROID_KEYSTORE_ALIAS`: the key alias.
  - `ANDROID_KEYSTORE_PASSWORD`: the password.

  To generate the release keystore (keep it safe: losing it prevents you from updating the app on the Play Store):
  ```bash
  keytool -genkeypair -v -keystore release.keystore -alias mygame -keyalg RSA -keysize 2048 -validity 10000
  ```
- Passwords and keystores **never** go into the repository: `*.keystore`/`*.jks` are in `.gitignore`. In the editor, Godot stores credentials in `.godot/export_credentials.cfg`, which is also ignored.

**Exporting locally:** install the export templates (*Editor → Manage Export Templates*) and use *Project → Export*, or:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/game.exe
```

### Using it as a GitHub template

1. Create a GitHub repository and push this project to it.
2. In *Settings → General*, enable **Template repository**.
3. For every new game: **Use this template → Create a new repository**, clone the new repository and follow [Starting a new game](#starting-a-new-game).

## Structure

```
autoloads/     Global services (singletons): few, each with a single responsibility
core/          Reusable, game- and genre-agnostic code
  components/    HealthComponent, HitboxComponent, HurtboxComponent
  state_machine/ StateMachine + State (node-based FSM)
  camera/        GameCamera (trauma-based screen shake)
  utils/         MathUtils, PlatformUtils, SafeConfig
  constants/     ScenePaths, PhysicsLayers
  debug/         ConsoleLogger (captures engine output for the console)
  feel/          HitFlashComponent, SquashStretch, flash shader, particle effects
game/          Game content, organized BY FEATURE
  game.tscn      Gameplay scene (any genre): level + HUD + touch + pause
  level.gd       Level: the contract (base class) every level follows
  game_debug_commands.gd  Console commands and gameplay watches
  hazards/       DamageZone (spikes)
  props/         TrainingDummy, AbilityPickup
  enemies/       Enemy (generic base), EnemyStats and shared AI states
  world/         SolidBlock (greybox)
  platformer/    Side-scrolling MODULE: player, states, stats, enemy, level, tests
  topdown/       Top-down MODULE: player, states, stats, enemy, pillar, level, tests
ui/            main_menu/ pause_menu/ settings_menu/ controls_menu/ hud/ touch_controls/
  components/    SafeAreaMargin (notch), ActionPromptLabel (button prompt)
  debug/         DebugOverlay (F3) and DebugConsole (F1)
localization/  translations.csv (en, pt_BR)
assets/        Shared assets (sprites, audio, fonts, shaders)
tests/         Smoke test runner
tools/         Genre setup (run once, then you can delete it)
```

**Why by feature?** The Godot documentation recommends keeping assets close to the scenes that use them. Each feature (and each genre) becomes a self-contained folder that is easy to move, delete or reuse.

**Module rule:** `core/`, `ui/` and the root of `game/` **never** reference `game/platformer/` or `game/topdown/`. That's what allows deleting a module without breaking anything. The only links are `ScenePaths.FIRST_LEVEL` and the `Level` properties.

## Architecture

### Autoloads (order matters)

| Autoload | Responsibility |
|---|---|
| `Log` | Leveled logging (DEBUG/INFO/WARN/ERROR); only WARN+ in release builds |
| `EventBus` | Global signals for cross-cutting events (Player → HUD, anything → camera) |
| `Settings` | User options in `user://settings.cfg` (audio, video, language, touch) |
| `SaveSystem` | Versioned JSON saves, atomic writes + `.bak`, per-version migration |
| `AudioManager` | Music with crossfade, SFX pool, positional SFX |
| `GameFeel` | Hitstop and one-shot particle effects (dust, sparks) |
| `InputManager` | Detects the active device (keyboard/mouse, gamepad, touch) and whether the mouse is in use |
| `InputBindings` | Control remapping, persisted bindings and button names/prompts |
| `SceneLoader` | Scene changes with fade and threaded loading |
| `DebugTools` | F3 overlay, F1 console and command/watch registry. **Debug builds only** |

### Game feel kit ("juice")

Generic pieces in `core/feel/` and the `GameFeel` autoload, used by both genres:

| Piece | How to use | Where it's already wired |
|---|---|---|
| **Hitstop** | `GameFeel.hitstop(0.05)`. Freezes for **real** time and restores the previous `time_scale`; overlapping calls extend the end | Landed hit (0.05 s), player taking damage (0.08 s) |
| **Hit flash** | `HitFlashComponent` node with `target` (the visual) and `health`. Flashes white through a shader on damage | Players and training dummy |
| **Squash & stretch** | `SquashStretch` node between the flip node and the drawables: `stretch_vertical(1.3)` / `stretch_horizontal(1.3)`. **Preserves area** (sx·sy = 1) and springs back | Jump, landing (proportional to the fall), dash |
| **Particles** | `GameFeel.spawn_effect(GameFeel.DUST, position)`. One-shot `CPUParticles2D` that free themselves | Dust (jump, landing, dash) and sparks (landed hit) |
| **Screen shake** | `EventBus.camera_shake_requested.emit(0.4)` | Damage and hits |

Character visuals follow `Visual` (flips with `scale.x = ±1`) → `Squash` (deforms and flashes) → drawables. The shadow stays outside `Squash`, so it neither deforms nor flashes.

**Dosage:** small impacts get flash and sparks; medium ones also a short hitstop; big ones also screen shake. Overdoing everything on every hit becomes tiring. Players can turn hitstop off in *Settings → Hit Stop* and shake in *Screen Shake*.

`GameFeel.hitstop_started(duration)` is emitted on every hitstop, to sync sound and controller vibration.

### Debug tools

Available in the editor and in **debug exports**, such as the CI test APK. In release builds `DebugTools` loads nothing.

| Shortcut | What it does |
|---|---|
| **F3** | Overlay: FPS, frame time, draw calls, nodes, memory, scene, input device and the game's *watches* (position, FSM state, health…) |
| **F1** or **`** | Command console. **Pauses the game** while open. Tab completes, ↑/↓ browse history, Esc closes |
| **3 fingers** on screen | Opens the console on mobile |

The console also shows **all game output**: `print`, `Log`, engine warnings and errors with the script file and line. You can see errors on a phone with no cable or editor.

**Built-in commands:**
- Generic: `help`, `clear`, `overlay`, `fps <n>`, `timescale <x>`, `collisions` (shows collision shapes), `log <level>`, `lang <locale>`, `quit`.
- Gameplay: `god`, `heal [n]`, `kill`, `tp <x> <y>` (no arguments: to the mouse), `level [name]` (lists or loads a level from any `levels/` folder), `reload`, `save [slot]`, `load [slot]`, `ability [name] [on|off]`.

**To add commands and watches**, each system registers its own:

```gdscript
func _ready() -> void:
	DebugTools.register_command("gold", _cmd_gold, "gold <n> - sets the gold")
	DebugTools.watch("Enemies", func() -> String: return str(get_tree().get_node_count_in_group("enemy")))


func _cmd_gold(args: PackedStringArray) -> String:
	gold = args[0].to_int() if not args.is_empty() else gold
	return "Gold: %d" % gold
```

Gameplay commands live in `game/game_debug_commands.gd`. `core/` only has the generic ones, so it still knows nothing about the game.

**Log:** use `Log.debug/info/warn/error("message")` instead of `print`/`push_warning`. Each line includes time and level. Release builds only show WARN and ERROR, and the level can be changed at runtime with `log <level>`.

### Patterns

- **Call down, signal up**: parents call methods on children and children emit signals. `EventBus` is only used when systems don't know each other (e.g. the HUD never references the Player).
- **Composition with components**: health and damage are reusable nodes, the same in both genres. Hitboxes and hurtboxes have a **`team`** (`player`, `enemy` or empty = neutral): a hurtbox ignores hits from its own team and its own entity (`owner`). Enemies don't hurt each other, the player doesn't hurt itself, and (neutral) spikes hurt everyone.
- **Node-based state machine**: each state is a child node with `enter/exit/update/physics_update/handle_input`. The player exposes movement primitives and the states decide the transitions.
- **Data-driven Resources**: `PlatformerStats` and `TopDownStats` are `Resource`s. Create different `.tres` files per character or power-up.
- **Abstract input**: gameplay only reads InputMap **actions**. Keyboard, gamepad and touch produce the same actions. Each level defines what touch buttons A/B/C do (`Level.touch_actions`) and which button prompts the HUD shows (`Level.hud_hint_actions`).

### Platformer (side-scrolling / metroidvania)

States: **Idle, Run, Jump, Fall, Attack, Dash**. The jump is defined by **height** and **time to apex**:

- `v₀ = 2h / t_apex`
- `g_up = 2h / t_apex²`
- `g_down = 2h / t_descent²` (heavier fall = jump with more "weight")

Releasing the button early applies the fall gravity, giving a **variable-height jump**. **Coyote time** and **jump buffering** are included.

- **Directional attack:** sideways, **up** (holding ↑) or **down in the air** (holding ↓). The player keeps moving during the swing and doesn't turn around mid-swing. Jumping on the ground cancels the attack.
- **Pogo:** hitting something with the down attack bounces the player (`pogo_velocity`) and refills the double jump and air dash, as in Hollow Knight.
- **Horizontal dash:** fixed speed with **no gravity**, i-frames (`dash_invulnerable`) and cooldown. In the air it's **1 per jump** (`air_dashes`). It ends early when hitting a wall.
- **Double jump:** `air_jumps` extra jumps in the air.

All numbers live in `PlatformerStats`, in the *Attack*, *Dash* and *Jump* groups.

#### Abilities (metroidvania progression)

The player has an `abilities` list. By default it has `attack` and `dash`; `double_jump` starts locked.

- `has_ability()` gates what can be used; states check it before acting.
- `unlock_ability()` / `lock_ability()` change the list. Unlocking emits `EventBus.ability_unlocked`, and the HUD shows "<ability> unlocked!".
- Progress is **saved through SaveSystem**: the player is in the `persist` group, and pickups autosave when collected.
- **`AbilityPickup`** (`game/props/`) is the collectible that unlocks an ability. It removes itself if the player already has it. The example level has a double jump pickup and a high ledge designed to be reachable only with it.
- **New ability:** pick a name (e.g. `wall_jump`), check `player.has_ability(&"wall_jump")` in the state that uses it, place an `AbilityPickup` with `ability = &"wall_jump"` and add the `ABILITY_WALL_JUMP` key to `translations.csv`.
- To test, use the debug command `ability [name] [on|off]`.

### Top-down

States: **Idle → Walk → Dash → Attack**.

- 8-direction movement with `Input.get_vector`: normalized diagonals, analog input preserved and `motion_mode = Floating` (no concept of floor).
- **Origin at the feet and collision only at the base**: the player walks "behind" pillars and objects, and the level uses **Y-sort** on the `Entities` node. Things on the floor (spikes) live in `FloorDecals`, with a lower `z_index`.
- **Twin-stick aiming**, with priority **right stick → mouse → movement direction**. The mouse only takes over aiming after the player actually moves or clicks it (`InputManager.using_mouse`), so keyboard-only players keep aiming where they walk. Using the gamepad gives aiming back to the stick. A yellow indicator shows the direction when aiming comes from the mouse or the stick.
- **Dash** at fixed speed, with i-frames (`HealthComponent.grant_invulnerability`) and cooldown. It follows the movement direction, or the aim direction when standing still.
- **Melee attack** in the aim direction. The hitbox stays locked at the starting angle during `attack_duration`.

### Enemies

A generic base (`game/enemies/`) serves both genres. The AI is a shared state machine:

```
Patrol ──sees player──▶ Chase ──close──▶ Windup ──▶ Attack (lunge) ──▶ Recover ──▶ Chase/Patrol
                              (any state) ──takes damage──▶ Hurt ──▶ Chase/Patrol
```

- **Perception:** the enemy notices the player within `detection_radius` **with line of sight** (a raycast against the world). It only gives up beyond `lose_target_radius`, which is larger; this **hysteresis** prevents flip-flopping between patrol and chase.
- **Windup (telegraph):** before the lunge the enemy stops, crouches and turns red for `windup_time`. That's what makes the hit **fair**: the player sees it coming and reacts. **Recover** after the lunge is the counter-attack window.
- **Damage:** on **contact** (`ContactHitbox`) and from the **lunge** (`AttackHitbox`), both on team `enemy`. When hit, the enemy gets knocked back and stunned (`Hurt`), which cancels its attack. On death it emits `EventBus.enemy_died`, spawns sparks and dust, and disappears.
- **`EnemyStats` (.tres per type):** speeds, perception radii, windup/lunge/recover times, knockback.
- **Per genre, only movement changes:**
  - **`PlatformerEnemy`** (walker): gravity, turns at **walls and ledges**, doesn't fall off while chasing, only attacks on the same "floor".
  - **`TopDownEnemy`** (slime): wanders near its origin with pauses, chases and attacks in 2D.

Each example level has 2 enemies. In the F3 overlay, the "Enemies" watch shows how many exist and how many are chasing.

### Control remapping

*Settings → Controls* lists the actions in two columns, **Keyboard/Mouse** and **Gamepad**. Click (or confirm on the gamepad) a binding and press the new one. **Esc** cancels.

- **Primary binding:** each action has one primary binding per device kind (the first in the InputMap list), and that's what the screen changes. Alternates such as arrows and D-pad keep working.
- **Conflicts:** if the new binding belonged to another action, the two **swap** bindings, so no action is left without a key.
- **Persistence:** changes are stored in `user://settings.cfg`, section `[input]`. Defaults stay the Project Settings ones, and "Reset Defaults" goes back to them.
- **Genre-aware list:** the screen only shows actions that exist in the project, so after the setup it's already right for the genre.
- **Per-device names:** keys follow the player's keyboard layout (ABNT2, AZERTY…), and gamepad buttons follow the detected family (Xbox: A/B/X/Y, PlayStation: Cross/Circle…, Nintendo: B/A/Y/X).
- **Mouse and touch:** mouse bindings only apply to the **real mouse** (`InputEvent.DEVICE_ID_MOUSE`). The click phones emulate from touch is ignored; otherwise every tap on the screen would trigger the action.
- **On-screen prompts:** `InputBindings.get_prompt(&"attack")` returns the binding for the current device. The `ActionPromptLabel` component (used in the HUD) shows "Attack [J]" or "Attack [X]" and updates itself.
- **New remappable action:** create the action in the InputMap and add it to `InputBindings.REMAPPABLE` with the translation key of its name.

### Physics layers

| Layer | Name | Use |
|---|---|---|
| 1 | world | Solid level geometry |
| 2 | player | Player body |
| 3 | enemies | Enemy / dummy bodies (the top-down player collides; mask 1+3) |
| 4 | hitboxes | Areas that deal damage |
| 5 | hurtboxes | Areas that receive damage (mask: 4) |
| 6 | interactables | Interactive objects |

Use `PhysicsLayers.HITBOXES` etc. in code instead of magic numbers.

## Security and performance

### Outside data is untrusted

Files in `user://` (settings, saves) can be edited by the player or shared between people, in mods or downloaded "packs". Template rules:

- **Never use `ConfigFile.load()`, `str_to_var()` or `bytes_to_var()` with objects on outside data.** Godot's parser builds objects and **loads scripts** from text (`Object(...)`, `Resource("...")`), which means it executes code. `settings.cfg` is read through **`SafeConfig`** (`core/utils/`), which rejects those constructors before parsing. Values still go through `Settings.is_valid_value` (only known keys with the right type, and volume clamped to 0–1).
- **JSON saves:** the JSON parser only produces primitive types. Still validate types when reading: `SaveSystem` rejects `data` that isn't a dictionary, and `SaveSystem.get_int("key")` returns the default when the value was tampered with.
- **Debug builds are not for distribution:** they include the console and cheats. CI names the APK built without a release keystore `...-android-debug`.

### CI

- **Least privilege:** the token can only read the repository; only the Release job asks for write access.
- **Godot and export templates verified with SHA-512** against the release's official `SHA512-SUMS.txt`.
- **Third-party action pinned by commit.** **Dependabot** (`.github/dependabot.yml`) opens monthly PRs with updates.
- **Validated tags:** only `vX.Y.Z` (semver) is accepted before becoming a version.
- **Protected secrets:** only used by tag and manual jobs. PRs from forks have no access to them.

### Performance

- **Hurtboxes sleep** (`set_physics_process(false)`) and only wake up when something enters the area.
- **Enemy perception at ~10 Hz** (`perception_interval`), with a random phase per enemy: line-of-sight raycasts are spread across frames instead of all running every frame.
- **CPU particles** (`CPUParticles2D`) and the Compatibility renderer, the lightest option for mobile and web.
- **Debug tools** and log capture are not loaded in release builds.

## PC + Mobile

- **640×360 base resolution** (16:9, integer scaling to 720p/1080p/1440p/4K), `canvas_items` stretch + `expand` aspect: 19.5:9 phones show more of the world instead of black bars.
- **Compatibility renderer** (OpenGL ES 3 / WebGL 2): the most compatible option for older phones and the web.
- **Nearest filter** by default (pixel art). For HD art, change *Rendering > Textures > Default Texture Filter*.
- **Physics interpolation** enabled: smooth movement on 90/120/144 Hz screens with physics fixed at 60 Hz.
- **Orientation** `sensor_landscape`, **ETC2/ASTC** enabled for mobile exports.
- **Safe area** (notch) handled by `SafeAreaMargin` in the HUD and touch controls.
- **Automatic pause** when losing focus or going to the background. **Android back button**: pauses in game and quits from the menu (`quit_on_go_back=false`).
- Fullscreen and VSync options only show on desktop. The "Quit" button is hidden on iOS and the web.
- To test touch on PC, enable *Input Devices > Pointing > Emulate Touch From Mouse* and set "Touch Controls" to "Always".

## Conventions (official GDScript style guide)

- Files and folders in `snake_case`. Nodes and `class_name` in `PascalCase`.
- Module `class_name`s carry the genre prefix (`PlatformerPlayer`, `TopDownState`), because both modules coexist until the setup and identical names would clash.
- **Static typing** everywhere. The project warns about untyped declarations.
- Script order: `class_name`/`extends` → docstring → signals → enums → constants → `@export` → variables → `@onready` → built-in methods → public → private (`_`).
- Reference nodes from the same scene with `%UniqueName`, not long paths.
- UI texts are **translation keys** (`UI_PLAY`) defined in `localization/translations.csv`.

## Quick recipes

- **New level**: duplicate your module's level (the root uses `level.gd`) and point `ScenePaths.FIRST_LEVEL` to it, or load it through `game.level_path`.
- **New player state**: create a script that `extends PlatformerState` (or `TopDownState`), add a child node under `Player/StateMachine` and call `transition_to(&"NodeName")`.
- **New enemy type**: duplicate `platformer_enemy.tscn` (or `topdown_enemy.tscn`), swap the visuals and create an `EnemyStats` (.tres) with its numbers. For different movement, extend `Enemy` and override `patrol_direction`/`direction_to_target`/`move_toward_direction`.
- **New setting**: add the default to `Settings.DEFAULTS`, handle it in `Settings._apply` and create the control in `settings_menu`.
- **New text**: add a line to `translations.csv` and use the key as the Control's `text`.
- **New genre module** (e.g. twin-stick, puzzle): create `game/<genre>/` with a level, player and `tests/<genre>_smoke_test.gd`, and register it in `tools/genre_setup.gd` (`GENRES`) and `tests/smoke_test.gd` (`GENRE_SUITES`).

## Contributing

Suggestions and fixes are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow (issue → branch → PR with a passing smoke test). To report a vulnerability, **don't open a public issue**: follow [SECURITY.md](SECURITY.md).

## Credits and AI usage

This template was conceived and directed by **Tiago de Souza Barros** and developed **with artificial intelligence assistance**: **Claude** (Claude Opus 5.5 model), by **[Anthropic](https://www.anthropic.com)**, used through **[Claude Code](https://claude.com/claude-code)**.

- **What the AI did:** architecture, GDScript code, scenes, automated tests, CI and documentation were produced in collaboration with Claude, based on the author's requirements, decisions and reviews.
- **How it was verified:** every change was validated with the automated smoke test (126 checks), with real builds on GitHub Actions for Windows, Linux, Web and Android, and with a security and performance review that reproduced the vulnerability it found before fixing it.
- **Traceability:** commits made with the AI carry the `Co-Authored-By: Claude` trailer.
- **Responsibility:** final decisions and maintenance belong to the author. As with any third-party code, review and test before using it in production.
- [CLAUDE.md](CLAUDE.md) contains the architecture instructions used by Claude Code and lets you keep developing with AI while following the project's patterns.

## License

Distributed under the **MIT license**: see [LICENSE](LICENSE). You can use, modify and sell games made with the template. The only requirement is keeping the template's copyright notice in copies of its code, for example in a third-party licenses file or in the game's credits.
