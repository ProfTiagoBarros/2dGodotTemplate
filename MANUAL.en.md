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
11. [Full recipe: a game from start to first build](#11-full-recipe-a-game-from-start-to-first-build)

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
| **Interface** | "Template Chronicles" skin (cyberpunk with a touch of fantasy) on every screen: replace the PNGs in `assets/ui/` and the whole game changes look |
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

### Step 3: set up the game with the wizard (only once)

The template ships a **wizard that asks about your game** and shapes the project accordingly, removing what won't be used. Less code to maintain, and less context for Claude Code to read in every session.

1. In the editor: **Project → Tools → Configurar novo jogo…** (the wizard's UI is in Portuguese).
2. Answer the questions:

   | Question | What changes |
   |---|---|
   | **Game name** | Project name (and the save folder), menu title (`GAME_TITLE`) and build file names in CI (`GAME_SLUG`) |
   | **Game type** | *Platformer* or *top-down* keep only that module. *Base only* (puzzle, cards, narrative…) removes both and creates an empty level at `game/levels/level_01.tscn`, keeping menus, saves, controls, debug and CI |
   | **Platforms** | PC, Web and/or Android. Platforms left out are removed from `export_presets.cfg` and CI |
   | **Documentation** | Turns the template docs into game docs: a new `README.md`, the template README becomes `TEMPLATE.md`, a fresh `CHANGELOG.md` and a slimmer `CLAUDE.md` (without the template maintenance rules or the removed genre's sections). Optionally keeps the English docs and the community files (CONTRIBUTING, issue/PR templates) |
   | **At the end** | Removes the setup tools (`tools/` and the wizard itself), which have no further use |

3. The window shows **what will happen** before you confirm. When you click **Configurar**, the editor restarts on its own.
4. Press **F5** to check.

Everything removed goes to the **system trash**. Since the repository was just created (Step 1), you can undo everything with:

```bash
git checkout -- . && git clean -fd
```

**From the command line** (automation, or if you prefer the terminal), the same questions become parameters. Use `--dry-run` to only see the plan:

```bash
godot --headless --path . -s res://tools/setup_project_cli.gd -- --name="Cat Adventure" --genre=platformer --platforms=pc,mobile --dry-run
```

> The wizard asks through a window because on Windows Godot is a GUI app and doesn't show prompts in the terminal. The genre-only setup (`tools/setup_genre.gd`, **File → Run**) still exists, but the wizard does that and more.

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

### Step 6: configure the repository on GitHub (once per repository)

> GitHub's interface changes over time. The names below follow the official documentation as of October 2026. If something doesn't match, look for the equivalent name or check each item's documentation link.

Every setting starts the same way: on the repository page, click the **Settings** tab (gear, at the top, right of *Insights*; if it's not visible, open the **…** menu). The **left sidebar** is split into groups.

**a) Security: private vulnerability reporting and Dependabot**
1. In the sidebar, under the **Security and quality** group, click **Advanced Security**. This page used to be called *Code security and analysis*.
2. On the **Private vulnerability reporting** row, click **Enable**. It only exists for **public** repositories.
3. On the same page, also enable **Dependabot alerts** (and **Dependabot security updates**, if shown).

Docs: [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/configuring-private-vulnerability-reporting-for-a-repository) · [Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/configuring-dependabot-alerts)

**b) Protect the `main` branch**
1. In the sidebar, under the **Code, planning, and automation** group, click **Rules** → **Rulesets**.
2. Click **New ruleset** → **New branch ruleset**.
3. **Ruleset name:** `Protect main`.
4. **Enforcement status:** change it from *Disabled* to **Active**. It's off by default, and the rule doesn't apply until you change it.
5. **Target branches:** click **Add target** → **Include default branch**.
6. Under **Branch rules**, keep **Restrict deletions** and **Block force pushes** checked. That already prevents deleting `main` or rewriting its history.
7. Click **Create**.

When other people start sending PRs, come back to this rule and also check **Require status checks to pass**. Add the **Smoke test** check, which only shows up in the list after it has run at least once. Under **Bypass list**, add **Repository admin**: that way you can still `git push` straight to `main`. Without it, a direct push would be rejected, because the commit doesn't have a passing check yet.

Docs: [rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)

**c) Description and topics (so people can find the project)**
1. On the repository's **home page** (outside Settings), right column, in the **About** box, click the **gear ⚙**.
2. **Description:** one short sentence.
3. **Topics:** type each topic and press **Enter** (e.g. `godot`, `godot4`, `gdscript`, `gamedev`, `2d`).
4. Click **Save changes**.

**d) Template repository (only on the template repository)**
- *Settings* → **General** group (the first page) → right below the repository name, check **Template repository**. Leave it unchecked on game repositories.

---

## 4. Initial changes: your game's identity

Do this right at the start, because some of these values are hard to change after the game is published. The wizard from [Step 3](#step-3-set-up-the-game-with-the-wizard-only-once) already handles the items marked with ✔.

| What | Where | Notes |
|---|---|---|
| ✔ **Project name** | *Project Settings → Application → Config → Name* | Also changes the user's saves/settings folder |
| ✔ **Menu title** | `localization/translations.csv`, key `GAME_TITLE` | One text per language (`en`, `pt_BR`) |
| **Initial version** | *Project Settings → Application → Config → Version* | Afterwards CI fills it in from tags (`v1.0.0`) |
| **Icon** | Replace `icon.svg` | For Android, also configure the adaptive icons in the preset |
| **Android app ID** | `export_presets.cfg` → `package/unique_name` | Format `com.yourstudio.yourgame`. **Don't change it after publishing** on the Play Store |
| **Android app name** | `export_presets.cfg` → `package/name` | The name shown on the phone |
| ✔ **Build file names** | `.github/workflows/ci.yml` → `GAME_SLUG` | E.g. `my-metroidvania` |
| ✔ **Game README** | `README.md` | The wizard creates a game README and keeps the template's as `TEMPLATE.md`. Fill it in with your game's description, images and badges |
| **Badges and links** | Top of `README.md` and `README.en.md` | Replace `ProfTiagoBarros/2dGodotTemplate` with your repository (CI badge) |
| **Game license** | `LICENSE` | The template is MIT. Your game can use another license (or none, if closed source); keep the template's copyright notice in a third-party licenses file or in the credits |
| ✔ **History** | `CHANGELOG.md` | The wizard starts a new history for the game |
| **PR reviewer** | `.github/CODEOWNERS` | Replace `@ProfTiagoBarros` with your user or team (the wizard removes the file if you don't keep the community files) |
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

The template's characters (the hero, the android and the slime) were generated with **PixelLab** (pixellab.ai) in the *Template Chronicles* theme. The player is **32×48** px in the platformer and **32×32** in top-down. They all follow this structure:

```
Player
└─ Visual          ← flips sideways (scale.x = ±1)
   ├─ Shadow       ← (top-down) stays outside Squash
   └─ Squash       ← deforms (squash & stretch) and flashes when hurt
      └─ Sprite    ← AnimatedSprite2D with the animations
```

**Animation follows the state on its own.** The `Character` class plays on `Sprite` the animation named after the state in lowercase: the `Idle` state plays `idle`, `Run` plays `run`, `Attack` plays `attack`. You don't need to write code in the states. The special cases:

| Character | Expected animations |
|---|---|
| Platformer | `idle`, `run`, `jump`, `fall`, `attack`, `attack_up`, `attack_down`, `dash` |
| Top-down | the same per direction: `idle_south`, `walk_east`, `attack_north_east`… (south, south-east, east, north-east and north; the west side is the east one mirrored) |
| Enemies | `walk` (patrol and chase), `idle` (windup and recovery), `attack`, `hurt` |

A missing animation is simply skipped: the slime only has `idle` and works that way.

**To use your own character:**

1. Generate or draw the animations. In PixelLab, create the character at game size and animate only the east direction for the platformer (or 5 directions for top-down); download each animation's frames into its own folder (`idle/0.png`, `idle/1.png`…). From Aseprite, export each tag as separate frames.
2. Import everything at once:
   ```bash
   godot --headless --path . -s res://tools/import_frames.gd -- C:/my_animations res://game/platformer/player/art hero
   ```
   The script builds one PNG strip per animation and `hero_frames.tres` (a `SpriteFrames`). Attacks, jump and dash are imported without looping.
3. Tune each animation's speed by opening the `.tres` in the editor (SpriteFrames panel).
4. On `Sprite`, set `offset` so **the feet are at the origin** (0, 0): squash keeps the feet on the ground and top-down Y-sort works. PixelLab frames come centered, so a single `offset` works for every animation.
5. Adjust the collision, hurtbox and attack hitbox to the new art's size.

> To import straight from **Aseprite**, the *Aseprite Wizard* addon also builds `SpriteFrames` from the `.aseprite` file.

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

The example levels use **PixelLab tilesets** with automatic corner-based autotiling: a cyberpunk rooftop in the platformer and a wet street with metal sidewalks in top-down.

**How to paint the scenery:** each level has two tile layers.

| Layer | What it is |
|---|---|
| `Terrain` (platformer) / `Ground` (top-down) | **Logic** layer: you paint here. It holds the collision (in the platformer) and shows semi-transparent in the editor |
| `TerrainArt` / `GroundArt` | **Visual** layer (`DualGridTerrain`): picks each edge and corner tile on its own from what you painted |

1. Select the logic layer and, in the **TileMap** panel, paint with the cyan tile ("upper" terrain: block in the platformer, sidewalk in top-down). In top-down, paint the street with the dark blue tile.
2. The visual layer updates itself in the editor.

**To swap the tileset:** generate a new one in PixelLab (*sidescroller tileset* for the platformer, *top-down tileset* for top-down) and replace the PNG in `game/<genre>/levels/tiles/`. The order of the 16 tiles in PixelLab sheets is always the same. In PixelLab sidescroller tilesets the block is the "lower" terrain, which is why the platformer's visual layer uses `painted_is_lower = true`.

**Level settings** (root node, `level.gd` script):
- `level_id`: unique identifier (e.g. `&"cave_01"`).
- `music`: the level's music, played with a crossfade.
- `touch_actions`: what touch buttons A, B and C do.
- `hud_hint_actions`: which button prompts show on screen. In a tutorial level, show only what was already taught.
- `camera_limits`: the area the camera may show, so it never leaves the scenery.

**More details:**
- **Background:** the platformer uses a `Parallax2D` with `assets/ui/menu_background.png`, which scrolls slowly.
- **Decoration:** lamps, crates, terminals and vending machines live in `game/world/decor/`.
- **Test markers:** the `TestMarkers` node holds positions used by the automated tests (open ground, platform top…). When you redesign the level, move the markers with it and the smoke test keeps working.
- **Greybox:** for prototyping without art, the `SolidBlock` blocks are still available.
- **Testing a level quickly:** **F1** → `level level_name`.

In top-down, put characters, enemies and tall objects inside the `Entities` node, which has Y-sort. Things on the floor (rugs, spikes) go in `FloorDecals`.

### 5.4 Creating enemies

**Same behavior, different visuals and numbers:**
1. Duplicate `game/<genre>/enemies/<enemy>.tscn`.
2. Replace the art inside `Visual/Squash`.
3. Duplicate the stats `.tres`, adjust the numbers and point the new scene's `stats` property to it.
4. Adjust the `damage` of `ContactHitbox` and `AttackHitbox`, and the `max_health` of `HealthComponent`.

**New behavior** (e.g. a flying platformer enemy): create a script that `extends Enemy` and implement only the movement: `patrol_direction()`, `direction_to_target()` and `move_toward_direction()`. They are `@abstract` methods: if one is missing, Godot reports it when you save the script. Damage, knockback, effects and death already come from `Character`, and the AI (states) keeps working on its own. Use `platformer_enemy.gd` as a model.

> To balance combat, `windup_time` is how long the player has to react and `recover_time` is the counter-attack window. Those two numbers change the "fairness" of a fight the most.

### 5.5 Abilities (metroidvania)

Every player (`PlayerCharacter`) has a list of abilities stored in the save. To create a new one in the platformer, for example **wall jump**:

1. Add the constant and the method to the player (`platformer_player.gd`):
   ```gdscript
   const ABILITY_WALL_JUMP := &"wall_jump"

   func wall_jump() -> void:
   	velocity = Vector2(get_wall_normal().x * stats.max_speed, -stats.jump_velocity)
   	face(signf(velocity.x))
   	jump_buffer_timer = 0.0
   ```
2. Use it in the fall state (`states/fall_state.gd`), before the other jump checks:
   ```gdscript
   if player.has_ability(PlatformerPlayer.ABILITY_WALL_JUMP) and player.is_on_wall() and player.wants_to_jump():
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
	add_to_group(Groups.PERSIST)
	coins = int(SaveSystem.data.get("coins", 0)) # reads what was already loaded


func save_state(data: Dictionary) -> void:
	data["coins"] = coins


func load_state(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
```

- Call `SaveSystem.save_game()` at the right moments: checkpoint, collected item, level change.
- JSON turns integers into floats, so use `int(...)` when reading. For values a player could tamper with, prefer `SaveSystem.get_int("key")`, which also handles wrong types.
- Changed the save format after release? Increase `SAVE_VERSION` and handle the conversion in `_migrate()` (`autoloads/save_system.gd`). The v1 → v2 migration, which renames the abilities key, is a working example.

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
2. Declare the action in `core/constants/actions.gd` (constant + the `ALL` list; the smoke test flags it if you forget) and, in code, always use the **action constant**, never the key or a loose string: `Input.is_action_just_pressed(Actions.INTERACT)`.
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

1. Create the key constant in `autoloads/settings.gd` (e.g. `const MY_OPTION := "my_option"`) and add the default value to `DEFAULTS`.
2. If the option changes something in the engine, apply it in `_apply()` in the same file.
3. Create the row on screen (`ui/settings_menu/settings_menu.tscn`) and wire it with `_bind_check` or `_bind_option` in `settings_menu.gd`.
4. Read it anywhere with `Settings.get_value(Settings.GAME, Settings.MY_OPTION)`. Never write a section or key as a loose string.

### 5.11 Game feel: how much to use

| Impact | Recipe |
|---|---|
| Small (regular hit) | Flash + sparks |
| Medium (strong hit, taking damage) | Above + `GameFeel.hitstop(0.05)` |
| Big (boss, explosion, death) | Above + `EventBus.camera_shake_requested.emit(0.5)` |

Overdoing everything tires the player. Players can turn hitstop and screen shake off in the settings, and it's good to keep those options.

---

### 5.12 Changing the UI look (skin)

Menu, pause, settings, controls and HUD use a single theme (`ui/theme/main_theme.tres`), which builds buttons, panels, bars, sliders and toggles **from the PNGs in `assets/ui/`**. The default look is **Template Chronicles**.

To give the game your own look:

1. Open `assets/ui/README.md`: it lists each piece, its size and its fixed (9-slice) borders.
2. Draw the new piece **at the same size** and save over the old one, **with the same name**. Godot reimports it and every screen changes together.
3. Text colors, the font and title styles (`TitleLabel` on the menu, `HeaderLabel` on panels) are set in the theme itself: open `main_theme.tres` in the editor.

Tips:

- **Start with the background and the emblem** (`menu_background.png`, `emblem.png`). They change the identity the most and have no borders to respect.
- **Fixed borders:** panel and button corners never stretch, only the middle does. Keep bevels and glows inside those margins.
- **Canva:** you can generate the background and emblem with AI. For a transparent background, use *remove background* and export a PNG at the final size (e.g. 640×360 for the background).
- **Don't use `theme_override_styles` in scenes:** a local style ignores the skin. If a screen needs a different look, add a *type variation* to the theme, like `TitleLabel`.
- The smoke test fails if a skin piece is deleted or renamed.

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
| `t.tap(Actions.X)` / `t.hold(Actions.X, n)` | Simulates input |
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
- **Pausing:** use `PauseController.request(&"reason")`/`release(&"reason")`, never `get_tree().paused` directly (cutscenes, dialogs and inventory are pause "reasons" too).
- **Runtime validation:** don't use `assert` for errors that can happen in an exported build, because asserts are stripped from release. Validate, report with `Log.error` and fall back to safe behavior.

### Using Claude Code on your game

`CLAUDE.md` explains the architecture, the test commands and the known Godot 4.7 pitfalls. Requests that work well:

- "Add a flying platformer enemy following the `PlatformerEnemy` pattern, with tests."
- "Create the wall jump ability with a pickup and a test."
- "Implement ability-gated doors as described in IMPROVEMENTS."

Always ask it to **run the smoke test** at the end. That's your guarantee nothing broke.

To spend **fewer tokens and less time**:

- **Run the Step 3 wizard before anything else.** Every module, doc or rule left in the project is context the AI may read for nothing.
- **Make `CLAUDE.md` about your game:** add what is specific (characters, custom systems, decisions already made) and remove what no longer applies. It's read at the start of every session.
- **Ask for small, specific tasks that point to a recipe:** "add wall jump following section 5.5 of the MANUAL" costs far less than "improve the game".
- **One task per session** when tasks are unrelated. A long conversation accumulates context that makes every answer more expensive.
- **Delete examples you won't use** (enemies, levels, training dummy), adjusting the tests that depended on them.

### Template or start from scratch?

Using the template saves time and tokens **when the game needs what it provides**. The expensive part of a game isn't the character walking; it's the infrastructure: safe versioned saves, settings, control remapping, menus, pause, mobile touch, CI with builds and debug tools. It's already done, tested and has had several real defects fixed. On top of that, `CLAUDE.md` and the tests make the AI get things right more often and redo less.

The template also has costs: rules and docs you won't use (the wizard removes most of them), a smoke test that takes about 1 minute, and an architecture designed for action games, which becomes dead weight in other genres.

| Kind of game | Best path |
|---|---|
| Platformer, metroidvania, top-down action | **Use the template** with the matching genre. It's what it was made for |
| Another 2D genre that needs menus, saves and controls (puzzle, cards, narrative) | Use the template with the **base only** option |
| Throwaway game jam prototype (a few hours) | Starting from scratch may be faster |
| Small game with no saves, no menus and no configurable controls | From scratch |

### What about 3D games?

This template is **2D**, but much of it doesn't depend on dimension: the autoloads (Log, Settings, SaveSystem, AudioManager, SceneLoader, InputManager/InputBindings, DebugTools), `PauseController`, `SafeConfig`, menus and UI, localization, the `StateMachine`, the tests, the CI and the rules in `CLAUDE.md` and [REVIEW_GUIDE.en.md](REVIEW_GUIDE.en.md). Rebuilding that for every 3D game would be waste.

A **complete** 3D template built before the game, however, tends to pay off poorly:

- **What changes in 3D is exactly what's hardest to generalize:** camera (third person with collision, first person, isometric), `CharacterBody3D` movement, animation (AnimationTree, blend spaces, root motion), lighting, LOD and mobile performance.
- **3D genres differ far more** from each other (FPS, third-person action, racing, puzzle) than platformer and top-down do.
- **The 3D bottleneck is usually art and assets**, not code, and no template solves that.
- **AI is weaker in 3D:** it can't "see" the scene, so tuning camera and collision takes more rounds of you testing. 3D scenes are also bigger files that cost more tokens to read.

**Recommendation:**

1. To make both 2D **and** 3D games, split the shared part of this template into a "base template" (item in [IMPROVEMENTS.md](IMPROVEMENTS.md)).
2. For the first 3D game, start from that base and use ready-made addons for the hard parts (e.g. **Phantom Camera** for cameras). Also look at community templates such as **COGITO** (first person) and the official Godot demos.
3. Only after 1 or 2 3D games of the same kind, extract a 3D genre module, as was done here with platformer and top-down. Good templates come from real games, not the other way around.

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
| I ran the wizard (or the setup) with the wrong option | If the project was already committed, `git checkout -- . && git clean -fd` undoes everything: it restores what was deleted and removes the created files (careful: `clean` also deletes your own files that were never committed). Without a commit, restore the files from the **system trash**. Then run it again |
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
- [ ] **Project → Tools → Configurar novo jogo…** (name, genre, platforms, docs) → **F5** works
- [ ] Smoke test passes locally
- [ ] Icon and initial version (the wizard already set the name and `GAME_TITLE`)
- [ ] Android `package/unique_name` and `package/name`
- [ ] README with the game's description, plus the game's own badges and `LICENSE`
- [ ] First commit and push → green CI in the Actions tab
- [ ] GitHub configured: Advanced Security (vulnerabilities + Dependabot), `main` ruleset, description and topics ([Step 6](#step-6-configure-the-repository-on-github-once-per-repository))
- [ ] (If publishing on Android) release keystore + 3 GitHub secrets
- [ ] First own level in `ScenePaths.FIRST_LEVEL`
- [ ] First `v0.1.0` tag → Release with the builds

---

## 11. Full recipe: a game from start to first build

An example of the most efficient way to use the template, from an empty repository to the first build. The example game is **"Cat Adventure"**, a small metroidvania for PC and mobile, made with the help of Claude Code.

### Stage 1: create and configure (about 15 min)

1. On GitHub, in the template repository: **Use this template → Create a new repository** → `cat-adventure`.
2. Clone it and open it in Godot 4.7 (**Import**). Wait for the import and press **F5** to see that everything works.
3. **Project → Tools → Configurar novo jogo…** and answer:
   - Name: `Cat Adventure`
   - Type: *side-scrolling / metroidvania*
   - Platforms: **PC** and **Mobile** (no Web)
   - Documentation: **game**, no English docs, no community files
   - At the end: remove the setup tools
4. The editor restarts. Press **F5** again and run the tests:
   ```bash
   godot --headless --path . res://tests/smoke_test.tscn
   ```
5. Commit and push, then check the green CI in the **Actions** tab:
   ```bash
   git add -A && git commit -m "Set up the game from the template" && git push
   ```

### Stage 2: give Claude Code your game's context (about 10 min)

Open `CLAUDE.md` and add a short section about **your** game, right after *Project*. Example:

```markdown
## The game

- Short metroidvania (~1 h), 1 map with 12 rooms. Character: a cat that unlocks abilities.
- Planned abilities, in order: dash (starting), double jump, wall jump, heavy scratch.
- Out of scope: multiplayer, shop, branching dialogue.
```

It's only a few lines, but it keeps the AI from inventing out-of-scope features or asking about things already decided.

### Stage 3: vertical slice, one task at a time

Build **one complete room** before producing content in volume. Ask Claude Code for one thing at a time, always pointing to the manual's recipe and asking for a test. Examples of requests that work well:

1. "Replace the player's visuals with the sprite in `assets/sprites/cat/`, following section 5.1 of the MANUAL."
2. "Create the wall jump ability following section 5.5 of the MANUAL, with a pickup in the level and a test in the platformer suite. Run the smoke test at the end."
3. "Create a bat enemy that flies toward the player, extending `Enemy` (section 5.4 of the MANUAL), with its own `EnemyStats` and a test."
4. "Create the `room_01` level with a door that only opens with wall jump, as suggested in IMPROVEMENTS."

After each task: play a bit (**F5**), tune the numbers in the Inspector (in the `.tres` files, without asking the AI) and make a small commit.

### Stage 4: first build

1. Replace the icon (`icon.svg`) and, for Android, set `package/unique_name` ([section 4](#4-initial-changes-your-games-identity)).
2. Create the tag:
   ```bash
   git tag v0.1.0 && git push --tags
   ```
3. CI builds for PC and Android and publishes a **Release** on GitHub. Send it to friends to test.

### Why this order saves time and tokens

- **The wizard comes first:** the project starts with only what the game uses, so every Claude Code session reads less.
- **The game's context lives in `CLAUDE.md`,** instead of being repeated in every conversation.
- **Requests that point to a MANUAL section** give a ready-made path: the AI doesn't need to explore the project to figure out how.
- **A test with every request:** errors show up right away, not three features later, when they cost much more to find.
- **Fine-tune in the Inspector, not by prompt:** changing `jump_height` in the `.tres` costs zero tokens.
