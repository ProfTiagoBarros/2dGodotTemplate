# Godot 2D Template Manual

[Português](MANUAL.md) · **English**

A practical guide to starting a new game from the template, making the initial changes and getting the most out of what's already built. For technical details about each system, the [README](README.en.md) is the reference; this manual focuses on **how to use it**.

> 🤖 Template and manual developed with AI assistance (**Claude**, by Anthropic), reviewed and tested by the author. Details in [Credits and AI usage](README.en.md#credits-and-ai-usage).

## Contents

1. [What's included](#1-whats-included)
2. [Before you start](#2-before-you-start)
3. [Creating a new game, step by step](#3-creating-a-new-game-step-by-step)
4. [Initial changes: your game's identity](#4-initial-changes-your-games-identity)
5. [Building your game](#5-building-your-game)
6. [Everyday tools](#6-everyday-tools)
7. [Publishing: builds and releases](#7-publishing-builds-and-releases)
8. [Tips to get the most out of it](#8-tips-to-get-the-most-out-of-it)
9. [Troubleshooting](#9-troubleshooting)
10. [New game quick checklist](#10-new-game-quick-checklist)

---

## 1. What's included

| Area | What you get without writing code |
|---|---|
| **Flow** | Main menu, gameplay, pause, settings, scene changes with fade, JSON autosave |
| **Genres** | Platformer/metroidvania (jump with coyote/buffer, directional attack, pogo, dash, double jump, abilities) and top-down (8 directions, twin-stick aiming, dash, attack) |
| **Enemies** | Generic base with patrol → chase → telegraph → lunge, one example type per genre |
| **Controls** | Keyboard, mouse, gamepad and touch, with player **remapping** and button prompts that follow the device |
| **PC + mobile** | Virtual joystick, safe area (notch), pause when minimized, Android back button, desktop-only options hidden on phones |
| **Game feel** | Hitstop, damage flash, squash & stretch, dust, sparks, screen shake |
| **Debug** | F3 overlay, F1 console with commands (god, tp, level…), leveled logging |
| **Quality** | Automated smoke test and GitHub CI that tests every push and builds Windows, Linux, Web and Android on every tag |

---

## 2. Before you start

- **Godot 4.7** (the same version used by CI: `GODOT_VERSION` in `.github/workflows/ci.yml`).
- **Git** and a **GitHub** account, for the template, CI and automatic builds.
- Optional: **Claude Code**. `CLAUDE.md` already describes the architecture and conventions, so you can ask for new features and they will follow the project's patterns.

If you haven't yet: in the template repository on GitHub, go to *Settings → General* and enable **Template repository**. This only needs to be done once.

---

## 3. Creating a new game, step by step

### Step 1: create the game repository

**With GitHub (recommended):**
1. In the template repository, click **Use this template → Create a new repository**.
2. Name it after your game (e.g. `my-metroidvania`) and create it.
3. Clone the new repository:
   ```bash
   git clone https://github.com/YOUR_USER/my-metroidvania.git
   ```

**Without GitHub:** copy the template folder, delete the `.git` folder in the copy and run `git init` inside it.

### Step 2: open it and test before changing anything

1. Open Godot 4.7, click **Import** and choose the new game's `project.godot`.
2. On the first open, Godot imports every file. Wait for it to finish.
3. Press **F5**: menu → **Play** → the platformer example level.
4. Want to try the top-down genre before deciding? With the game running, press **F1** and type:
   ```
   level topdown_level_01
   ```

### Step 3: pick the genre (only once)

1. In the editor, open `tools/setup_genre.gd`.
2. Change the line `const GENRE := "platformer"` to the genre you want (`"platformer"` or `"topdown"`).
3. With the script open, use **File → Run** (Ctrl+Shift+X).
4. Use **Project → Reload Current Project**.

What the setup does:
- Points the game's first level to the chosen genre.
- Moves the **other** genre's folder to the **system trash**, where it can be recovered.
- Removes from the input map the actions only the other genre used, such as jump in top-down or aiming in the platformer.

> Tip: press **F5** again after the setup to confirm everything works. The `tools/` folder can be deleted afterwards.

### Step 4: run the tests

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

It should end with `Smoke test: PASSOU` (the test output is in Portuguese). After the setup, only the chosen genre's suites run.

### Step 5: first commit

```bash
git add -A
```

```bash
git commit -m "Initial game setup"
```

```bash
git push
```

Open the repository's **Actions** tab and check that the smoke test is green.

---

## 4. Initial changes: your game's identity

Do this right at the start, because some of these values are hard to change after the game is published.

| What | Where | Notes |
|---|---|---|
| **Project name** | *Project Settings → Application → Config → Name* | Also changes the user's saves/settings folder |
| **Menu title** | `localization/translations.csv`, key `GAME_TITLE` | One text per language (`en`, `pt_BR`) |
| **Initial version** | *Project Settings → Application → Config → Version* | Afterwards CI fills it in from tags (`v1.0.0`) |
| **Icon** | Replace `icon.svg` | For Android, also configure the adaptive icons in the preset |
| **Android app ID** | `export_presets.cfg` → `package/unique_name` | Format `com.yourstudio.yourgame`. **Don't change it after publishing** on the Play Store |
| **Android app name** | `export_presets.cfg` → `package/name` | The name shown on the phone |
| **Build file names** | `.github/workflows/ci.yml` → `GAME_SLUG` | E.g. `my-metroidvania` |
| **Game README** | `README.md` | Replace the top description with your game's. Keep `MANUAL.md` and `CLAUDE.md` as reference |
| **Badges and links** | Top of `README.md` and `README.en.md` | Replace `ProfTiagoBarros/2dGodotTemplate` with your repository (CI badge) |
| **Game license** | `LICENSE` | The template is MIT. Your game can use another license (or none, if closed source); keep the template's copyright notice in a third-party licenses file or in the credits |
| **History** | `CHANGELOG.md` | Start a new history for the game, deleting the template's entries |
| **PR reviewer** | `.github/CODEOWNERS` | Replace `@ProfTiagoBarros` with your user or team |
| **Base resolution** | *Project Settings → Display → Window* | Default 640×360 (pixel art). For HD art use 1280×720 and switch the texture filter to *Linear* |
| **Mobile orientation** | *Project Settings → Display → Window → Handheld* | Landscape by default. For portrait games, use `sensor_portrait` and adjust the base resolution |

### Removing the examples (when the time comes)

The examples are useful while you learn the template. Once the game has its own content:

- **Example level** (`game/<genre>/levels/*_level_01.tscn`): replace it with your first level and update `ScenePaths.FIRST_LEVEL` in `core/constants/scene_paths.gd`.
- **Training dummy** (`game/props/training_dummy.*`) and **spikes** (`game/hazards/`): delete them if you don't use them.
- **Tests:** if you delete something a test uses (e.g. the training dummy), adjust the suite in `game/<genre>/tests/`. The smoke test will tell you.

> Don't delete `core/`, `autoloads/`, `ui/`, `game/game.*` or `game/level.gd`. They are the foundation of everything.

---

## 5. Building your game

### 5.1 Replacing the character art

Characters use this structure:

```
Player
└─ Visual          ← turns left/right (scale.x = ±1)
   ├─ Shadow       ← (top-down) stays outside Squash
   └─ Squash       ← deforms (squash & stretch) and flashes on damage
      ├─ Body      ← replace these polygons with your art
      └─ Eye
```

1. Delete `Body` and `Eye` and add a `Sprite2D` or `AnimatedSprite2D` **inside `Squash`**.
2. Position the art with the **feet at the origin** (0, 0). That way squash keeps the feet on the ground and top-down Y-sorting works.
3. For animations, start each one in the matching state's `enter()`:

```gdscript
# platformer_player.gd
@onready var sprite: AnimatedSprite2D = $Visual/Squash/Sprite

# states/run_state.gd
func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	player.sprite.play(&"run")
```

> To import straight from **Aseprite**, the *Aseprite Wizard* addon generates `SpriteFrames` from `.aseprite` files.

### 5.2 Tuning movement without touching code

All movement numbers live in **Resources** (`.tres`). Double-click the file and edit it in the Inspector:

| File | What it controls |
|---|---|
| `game/platformer/player/default_platformer_stats.tres` | Speed, **jump height and timing**, coyote time, attack, pogo, dash, air jumps |
| `game/topdown/player/default_topdown_stats.tres` | Speed, dash, attack duration, knockback |
| `game/<genre>/enemies/*_stats.tres` | Each enemy's speeds, sight radii, telegraph and lunge timing |

The platformer jump is defined in design terms: **height in pixels** (`jump_height`) and **time to the top** (`time_to_apex`). Physics is computed from those. A `time_to_descent` smaller than `time_to_apex` gives a "heavier" fall.

> **Tip:** for variations (a faster character, a power-up), duplicate the `.tres` instead of editing the default.

### 5.3 Creating levels

1. Duplicate your genre's example level and rename it.
2. On the level's root node (script `level.gd`), check in the Inspector:
   - `level_id`: unique identifier (e.g. `&"cave_01"`).
   - `music`: the level's music, played with crossfade.
   - `touch_actions`: what touch buttons A, B and C do.
   - `hud_hint_actions`: which button prompts appear on screen. In a tutorial level, show only what has been taught so far.
3. For prototyping, use `SolidBlock` blocks (greybox). When the art arrives, replace them with `TileMapLayer`.
4. To quickly test a level: **F1** → `level level_name`.

In top-down, put characters, enemies and tall objects inside the `Entities` node, which has Y-sort. Things on the floor (rugs, spikes) go in `FloorDecals`.

### 5.4 Creating enemies

**Same behavior, different visuals and numbers:**
1. Duplicate `game/<genre>/enemies/<enemy>.tscn`.
2. Replace the art inside `Visual/Squash`.
3. Duplicate the stats `.tres`, adjust the numbers and point the new scene's `stats` property to it.
4. Adjust the `damage` of `ContactHitbox` and `AttackHitbox`, and the `max_health` of `HealthComponent`.

**New behavior** (e.g. a flying platformer enemy): create a script that `extends Enemy` and override only the movement: `patrol_direction()`, `direction_to_target()` and `move_toward_direction()`. The AI (states) keeps working on its own. Use `platformer_enemy.gd` as a model.

> To balance combat, `windup_time` is how long the player has to react and `recover_time` is the counter-attack window. Those two numbers change the "fairness" of a fight the most.

### 5.5 Abilities (metroidvania)

The platformer player has a list of abilities stored in the save. To create a new one, for example **wall jump**:

1. Add the method to the player (`platformer_player.gd`):
   ```gdscript
   func wall_jump() -> void:
   	velocity = Vector2(get_wall_normal().x * stats.max_speed, -stats.jump_velocity)
   	face(signf(velocity.x))
   	jump_buffer_timer = 0.0
   ```
2. Use it in the fall state (`states/fall_state.gd`), before the other jump checks:
   ```gdscript
   if player.has_ability(&"wall_jump") and player.is_on_wall() and player.wants_to_jump():
   	player.wall_jump()
   	return
   ```
3. Place an `AbilityPickup` (`game/props/ability_pickup.tscn`) in the level with `ability = wall_jump`.
4. Add the `ABILITY_WALL_JUMP` translation to `translations.csv`, used by the "Wall jump unlocked!" toast.
5. Test with the console: **F1** → `ability wall_jump on`.

For **doors and barriers** that require an ability, make a `StaticBody2D` that removes itself when `player.has_ability(...)` is true, or that listens to `EventBus.ability_unlocked`.

### 5.6 Saving game data

`SaveSystem` stores a dictionary (`SaveSystem.data`) as JSON. For a node to save its own state:

```gdscript
func _ready() -> void:
	add_to_group(SaveSystem.PERSIST_GROUP)
	coins = int(SaveSystem.data.get("coins", 0)) # reads what was already loaded


func save_state(data: Dictionary) -> void:
	data["coins"] = coins


func load_state(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
```

- Call `SaveSystem.save_game()` at the right moments: checkpoint, collected item, level change.
- JSON turns integers into floats, so use `int(...)` when reading. For values a player could tamper with, prefer `SaveSystem.get_int("key")`, which also handles wrong types.
- Changed the save format after release? Increase `SAVE_VERSION` and handle the conversion in `_migrate()` (`autoloads/save_system.gd`).

### 5.7 Texts and languages

1. Add a line to `localization/translations.csv`:
   ```
   NPC_HELLO,Hello traveler!,Olá, viajante!
   ```
2. Use the key as the text of any `Label` or `Button` (`NPC_HELLO`). Translation is automatic.
3. In code: `tr("NPC_HELLO")`.
4. For a new language, add a column (e.g. `es`) and add the code to `LOCALES` and the name to `LOCALE_NAMES` in `ui/settings_menu/settings_menu.gd`.

> If the text contains a comma, wrap it in quotes in the CSV.

### 5.8 New controls

1. Create the action in *Project Settings → Input Map*, with a key and a gamepad button. **Mouse buttons** need `device = 32` (`InputEvent.DEVICE_ID_MOUSE`, the real mouse); with "all devices", every tap on a phone screen also triggers the action. The easiest way is to copy an existing mouse event in `project.godot` (see `attack`) and change its `button_index`.
2. In code, always use the **action**, never the key: `Input.is_action_just_pressed(&"interact")`.
3. To let players remap it, add the action to `REMAPPABLE` in `autoloads/input_bindings.gd`, with the translation key of its name.
4. To show its prompt in the HUD, add the action to the level's `hud_hint_actions`.
5. For an on-screen touch button, add it to the level's `touch_actions` (up to 3 buttons).

### 5.9 Music and sound effects

Put the files in `assets/audio/music/` and `assets/audio/sfx/` (`.ogg` for music, `.wav` for short effects).

```gdscript
AudioManager.play_music(preload("res://assets/audio/music/theme.ogg"))       # with crossfade
AudioManager.play_sfx(preload("res://assets/audio/sfx/jump.wav"), 0.1)       # 0.1 = pitch variation
AudioManager.play_sfx_at(preload("res://assets/audio/sfx/explosion.wav"), global_position)
```

Good places to hook sounds: the player's `jump()` and `start_dash()`, `EventBus.enemy_died`, and `GameFeel.hitstop_started`, which marks the exact moment of impacts.

### 5.10 New settings

1. Add the default value to `DEFAULTS` (`autoloads/settings.gd`).
2. If the option changes something in the engine, apply it in `_apply()` in the same file.
3. Create the row on screen (`ui/settings_menu/settings_menu.tscn`) and wire it with `_bind_check` or `_bind_option` in `settings_menu.gd`.
4. Read it anywhere with `Settings.get_value("game", "my_option")`.

### 5.11 Game feel: how much to use

| Impact | Recipe |
|---|---|
| Small (regular hit) | Flash + sparks |
| Medium (strong hit, taking damage) | Above + `GameFeel.hitstop(0.05)` |
| Big (boss, explosion, death) | Above + `EventBus.camera_shake_requested.emit(0.5)` |

Overdoing everything tires the player. Players can turn hitstop and screen shake off in the settings, and it's good to keep those options.

---

## 6. Everyday tools

### Debug (editor and test builds only)

| Shortcut | Use |
|---|---|
| **F3** | Overlay: FPS, current player state, health, enemies, input device |
| **F1** or **`** | Console. Type `help` to list the commands |
| **3 fingers on screen** | Opens the console on mobile |

The most useful commands during development:

| Command | What for |
|---|---|
| `god` | Test levels without dying |
| `tp` | Teleport to the mouse (skip sections) |
| `level <name>` | Jump straight to a level |
| `ability <name> on` | Test abilities without collecting them |
| `timescale 0.25` | Slow motion to inspect animations and collisions |
| `collisions` | Show collision shapes and hitboxes |
| `heal`, `kill`, `reload` | Health, death and reloading the scene |

To add your game's own commands, see "Debug tools" in the [README](README.en.md#debug-tools).

Use `Log.info(...)`, `Log.warn(...)` and `Log.error(...)` instead of `print`. Everything shows up in the F1 console, including on phones, where you can't see the editor output.

### Automated tests

Run before every important commit:

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

To test something in your game, add checks to your genre's suite (`game/<genre>/tests/<genre>_smoke_test.gd`):

```gdscript
# inside run(t), after spawn_game:
var door := game.find_child("DoorBoss", true, false)
t.check(door != null, "Level has the boss door")
```

Helpers available on `t`:

| Helper | What it does |
|---|---|
| `t.check(cond, "description")` | Records a check |
| `t.frames(n)` | Waits n physics frames |
| `t.tap(&"action")` / `t.hold(&"action", n)` | Simulates input |
| `t.real_seconds(s)` | Waits in real time (use with hitstop) |
| `t.spawned_effects` | Particle effects that were created |

> For input-triggered events, wait a few frames instead of checking an exact frame. Otherwise the test becomes flaky in CI.

### Testing on a phone

1. Run the workflow manually (*Actions → CI → Run workflow*) or push a tag.
2. Download the `...-android-debug` artifact (or `...-android`, if you set up the release keystore) and install the `.apk` on the phone. You need to allow installs from unknown sources.
3. The test APK is a debug build: the 3-finger console works and shows errors.

---

## 7. Publishing: builds and releases

### Shipping a version

```bash
git tag v0.1.0
```

```bash
git push origin v0.1.0
```

Within a few minutes (the first time takes longer, because it downloads the export templates), GitHub publishes a **Release** with `.zip` files for Windows, Linux, Web and Android. The tag's version shows up in the corner of the main menu.

Use [semantic versioning](https://semver.org/): `v0.x` during development, `v1.0.0` at launch, `v1.0.1` for fixes.

### Android for the Play Store

1. Generate a release keystore **only once** and keep it somewhere safe, with a backup. **Losing the keystore prevents you from updating the app.**
   ```bash
   keytool -genkeypair -v -keystore release.keystore -alias mygame -keyalg RSA -keysize 2048 -validity 10000
   ```
2. On GitHub, under *Settings → Secrets and variables → Actions*, create:
   - `ANDROID_KEYSTORE_BASE64`: the output of `base64 -w0 release.keystore`
   - `ANDROID_KEYSTORE_ALIAS`: the alias (e.g. `mygame`)
   - `ANDROID_KEYSTORE_PASSWORD`: the password
3. Never put the keystore in the repository (`.gitignore` already blocks `*.keystore`).
4. The Play Store requires **AAB** instead of APK. See the corresponding item in [IMPROVEMENTS.md](IMPROVEMENTS.md) (in Portuguese).

### Web (itch.io)

The Web build runs on any static hosting. On itch.io, upload the Web `.zip` as "HTML" and leave *SharedArrayBuffer support* **off**, because the template uses the no-threads variant, the most compatible one.

---

## 8. Tips to get the most out of it

### Process

- **Build a "vertical slice" first:** one complete room, with final art, sound, an enemy, an ability and saving, before producing many levels. Problems show up early.
- **Prototype in greybox:** `SolidBlock` blocks and colored polygons. Only swap in the art once the level is fun like that.
- **Test on a phone from the start** if the game targets mobile: touch, performance and safe area tend to hide surprises.
- **Small commits and frequent tags:** each tag produces builds you can send to friends for testing.
- **Use [IMPROVEMENTS.md](IMPROVEMENTS.md) as a backlog** (in Portuguese): it already lists the natural next steps (ability-gated doors, rooms, minimap, new enemies, button icons, AAB…).

### Architecture (what keeps the project organized over time)

- **`core/` is generic:** nothing there knows your game exists. Game-specific code goes in `game/`.
- **Organize by feature:** a thing's scene, script, art and sounds live together (e.g. `game/enemies/bat/`). `assets/` is only for what's shared.
- **Call down, signal up:** parents call methods on children and children emit signals. Use `EventBus` only between systems that don't know each other, like player → HUD.
- **Composition:** before creating new inheritance, check whether the existing components solve it (`HealthComponent`, `Hitbox`/`Hurtbox`, `HitFlashComponent`, `SquashStretch`).
- **Data-driven:** design numbers live in `.tres` files, not scattered through code.
- **Always actions, never keys:** that keeps remapping, gamepad and touch working for free.
- **Outside data is untrusted:** never use `ConfigFile.load()`/`str_to_var()` on files players can edit. Use `SafeConfig` and validate types (see "Security and performance" in the [README](README.en.md#security-and-performance)).

### Using Claude Code on your game

`CLAUDE.md` explains the architecture, the test commands and the known Godot 4.7 pitfalls. Requests that work well:

- "Add a flying platformer enemy following the `PlatformerEnemy` pattern, with tests."
- "Create the wall jump ability with a pickup and a test."
- "Implement ability-gated doors as described in IMPROVEMENTS."

Always ask it to **run the smoke test** at the end. That's your guarantee nothing broke.

### Keeping the template and games up to date

Improved something generic in a game, like a new component in `core/`? Bring it back to the template so future games start with it. The reverse works too: to bring a template improvement into a game in progress:

```bash
git remote add template https://github.com/ProfTiagoBarros/2dGodotTemplate.git
```

```bash
git fetch template
```

```bash
git cherry-pick <commit-hash>
```

### Updating the Godot version

1. Open the project in the new version and let the editor reimport everything.
2. Update `GODOT_VERSION` in `.github/workflows/ci.yml`.
3. Run the smoke test locally and check CI.

---

## 9. Troubleshooting

| Problem | Solution |
|---|---|
| "Failed loading resource" errors on first open or after moving files | Use *Project → Reload Current Project*. If it persists, close Godot, delete the `.godot/` folder and open again (it's regenerated) |
| I ran the setup with the wrong genre | If the project was already committed, `git checkout -- .` undoes everything (including restoring the deleted folder). Without a commit, restore the folder from the **system trash** and undo the change in `scene_paths.gd`. Then run the setup again |
| Touch controls don't show on PC | In *Settings → Touch Controls*, choose **Always**. To simulate touch with the mouse, enable *Project Settings → Input Devices → Pointing → Emulate Touch From Mouse* |
| Tapping the phone screen triggers a mouse action | The action's mouse event needs `"device":32` (real mouse) in `project.godot`, as in `attack` |
| "Weird" settings or bindings | Delete `settings.cfg` in `%APPDATA%\Godot\app_userdata\<Project Name>\` (Windows). Saves are in `saves/`, in the same folder |
| Smoke test passes locally but sometimes fails in CI | Some test checks an exact frame. Wait a few frames instead (see `_wait_for` in the platformer suite) |
| Android job failed in CI | Check the "Exportar" step log. Without the 3 secrets the APK is built in debug mode, which is expected. With secrets, check the alias and password |
| "hides a native class" error | That `class_name` already exists in Godot (e.g. `Logger`, `VirtualJoystick`). Pick another name |
| The Settings screen doesn't fit | It already scrolls; when adding many options, keep the controls inside `Scroll` |
| I want to see errors on the phone | Use a debug build and open the console with 3 fingers |

---

## 10. New game quick checklist

- [ ] **Use this template** → clone → open in Godot 4.7 → **F5** works
- [ ] `tools/setup_genre.gd` with the genre → **File → Run** → **Reload Current Project**
- [ ] Smoke test passes locally
- [ ] Project name, `GAME_TITLE`, icon, initial version
- [ ] Android `package/unique_name` and `package/name`
- [ ] `GAME_SLUG` in CI
- [ ] README with the game's description, plus the game's own badges, `LICENSE`, `CHANGELOG.md` and `CODEOWNERS`
- [ ] First commit and push → green CI in the Actions tab
- [ ] (If publishing on Android) release keystore + 3 GitHub secrets
- [ ] First own level in `ScenePaths.FIRST_LEVEL`
- [ ] First `v0.1.0` tag → Release with the builds
