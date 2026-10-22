# Code and architecture review guide

[Português](REVIEW_GUIDE.md) · **English**

This guide is for anyone who **writes** or **reviews** code in this template or in games built from it. It gathers best practices from the official Godot docs, the design patterns most used in games, and the rules this project learned the hard way (many came from real defects, all covered by tests).

Use it together with [CONTRIBUTING.md](CONTRIBUTING.md) (PR workflow) and [README.en.md](README.en.md#architecture) (architecture overview).

## Contents

1. [How to review](#1-how-to-review)
2. [General principles](#2-general-principles)
3. [This template's architecture](#3-this-templates-architecture)
4. [Godot best practices](#4-godot-best-practices)
5. [Design patterns for games](#5-design-patterns-for-games)
6. [Constants, literals and magic numbers](#6-constants-literals-and-magic-numbers)
7. [Performance (PC and mobile)](#7-performance-pc-and-mobile)
8. [Security](#8-security)
9. [Robustness and lifecycle](#9-robustness-and-lifecycle)
10. [Tests](#10-tests)
11. [Documentation and Git](#11-documentation-and-git)
12. [Quick checklist](#12-quick-checklist)
13. [References](#13-references)

---

## 1. How to review

**Reading order:** first the *why* (PR description, issue), then the **architecture** (where the code lives and what depends on what), and only then the line-by-line details. A structural bug costs more than a bad name.

**Label every comment**, so the author knows what is required:

| Level | Meaning | Examples |
|---|---|---|
| 🔴 **Blocking** | Can't be merged like this | Breaks the module rule, `user://` data without validation, failing test, leaked pause/input |
| 🟡 **Important** | Should be fixed, or justified in the PR | Duplicated code, literal instead of a constant, missing test for the new case |
| 🟢 **Suggestion** | Optional improvement | Clearer name, simplification, comment |

**Good review habits:**

- Review small PRs (up to ~400 lines). Ask for larger ones to be split.
- Comment on the code, not the person. Explain the reason and, when possible, suggest the alternative.
- Run the project for gameplay or game feel changes: tests prove it works, but only playing tells you whether it feels *good*.
- Every fixed bug needs a **regression test** that failed before the fix.
- AI-generated code goes through the same review. Whoever opens the PR is accountable for it.

## 2. General principles

| Principle | What to look for in review |
|---|---|
| **High cohesion** | Each script has **one** clear responsibility. If its description needs an "and", it may be two classes or a new component. |
| **Low coupling** | A system knows as little as possible about the others. Prefer signals and small interfaces over reaching into another node's internal (`_something`) fields. |
| **Composition over inheritance** | Capabilities (health, hitbox, flash) are **components**. Inheritance only for a shared *lifecycle*, in a **shallow** hierarchy (2–3 levels at most). |
| **DRY with judgment** | Duplicated the same logic a **second** time in places that must evolve together? Extract it. Accidental similarity (that will diverge) can stay duplicated. |
| **KISS / YAGNI** | Don't build abstractions, options or systems "for the future". A good idea with no use yet goes into `IMPROVEMENTS.md`. |
| **Law of Demeter** | Avoid chains like `get_parent().get_parent().player.health.current`. Ask the object for what you need or listen to a signal. |
| **Fail early and loudly** | A typo should be a **compile error** (constants, types, `@abstract`), not a silent bug in production. |
| **Open/closed principle** | To add a genre, enemy or state you **create** files; you don't need to edit the core. |

## 3. This template's architecture

These are project rules. Breaking any of them is 🔴 blocking, unless the PR changes the rule (and the docs) on purpose.

- **Module boundary:** `core/`, `ui/`, `autoloads/` and the root of `game/` **never** reference `game/platformer/` or `game/topdown/`. Modules connect only through `ScenePaths.FIRST_LEVEL` and the `Level` exports.
- **`core/` is game-agnostic:** no player, enemy or level in there. If you needed one, the code belongs in `game/`.
- **Call down, signal up:** parents call methods on children; children emit signals. `EventBus` is only for systems that **don't know each other** (e.g. HUD ↔ player). It doesn't replace a legitimate direct reference.
- **Autoloads are few and single-purpose.** Before adding one, ask: "does this need to exist in every scene, all the time?". If not, it's a node in the scene or a static class. Their order in `project.godot` matters.
- **Characters:** `Character` → `PlayerCharacter` / `Enemy` hold the combat lifecycle (Template Method). Concrete characters implement only the `@abstract` hooks and movement. Damage, death or ability logic duplicated in a concrete character is 🟡.
- **States decide transitions; the character exposes primitives** (`jump()`, `apply_movement()`…). A state that touches the character's internals, or a character that picks the next state, is a coupling smell.
- **Data in `Resource`s** (`PlatformerStats`, `EnemyStats`): balancing numbers live in `.tres` files, not in code.
- **Pause only through `PauseController`**, scene changes only through `SceneLoader`, logging only through `Log`.
- **New genre/module:** register it in `GENRES` (`tools/genre_setup.gd`) and `GENRE_SUITES` (`tests/smoke_test.gd`), with genre-prefixed `class_name`s.

## 4. Godot best practices

### GDScript

- **Static typing everywhere**, including loop variables (`for enemy: Enemy in ...`) and return types. The `untyped_declaration` warning is on.
- Follow the [official style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): order `signal` → `enum` → `const` → `@export` → `var` → `@onready` → methods; `snake_case` for functions and variables, `PascalCase` for classes, `CONSTANT_CASE` for constants.
- Private members start with `_`. Don't access another script's `_member`; add a public API.
- Use `@abstract` on classes and methods that **must** be implemented: the editor rejects an incomplete subclass.
- Prefer `StringName` (`&"x"`) for names used as identifiers, always through a constant (see [section 6](#6-constants-literals-and-magic-numbers)).
- Duck typing (`has_method`, `call(&"x")`, `get(&"x")`) only when no common type is possible. If there is a base (`PlayerCharacter`, `Enemy`), use `as Type` and access it directly.
- Comments explain the **why**; code shows the *how*. A comment that only restates the code is noise.

### Scenes and nodes

- **Self-contained scenes:** a scene should work on its own (F6) or depend only on what it declares in `@export`. Avoid `get_parent()` and absolute paths (`/root/...`).
- References within the same scene with `%UniqueName` or `@onready var x := $Path`. References to other scenes through `@export` (with `node_paths` in the `.tscn`).
- **Pick the right base:** `Node` for position-less logic, `Node2D` for things in the world, `Control` for UI, `Resource` for data, `RefCounted`/static class for tree-less utilities.
- Groups for "all the X" (enemies, `persist`), always via `Groups.*`.
- When moving scripts, move their `.gd.uid` files too.

### Processing and physics

- Movement and physics in `_physics_process`; visuals and UI in `_process`. Always multiply by `delta`.
- Turn off what doesn't need to run: `set_process(false)` / `set_physics_process(false)` (e.g. `HurtboxComponent` sleeps until something touches it).
- With **physics interpolation** on, move bodies only in the physics step and call `reset_physics_interpolation()` on teleports.
- Run expensive queries (raycasts, group lookups) on a cadence, not every frame (e.g. enemy perception at 10 Hz with a random phase).
- Collision layers through the `PhysicsLayers` constants, never by number.

### Signals, `await` and tweens

- Connect signals in code with typed `Callable`s (`health.died.connect(_on_died)`), not by name as a string.
- After an `await`, the node may have been freed: check `is_instance_valid(self)`/`is_inside_tree()` when the wait is long.
- A tween animating a shared property is **stored and killed** before creating another (`_music_tween`, `_health_tween`).
- Timers and tweens that depend on real time (hitstop) use `Time.get_ticks_msec()`, because `Engine.time_scale` changes.

### Input and UI

- Gameplay reads only **actions** (`Actions.*`), never keys. UI text is a translation key.
- Mouse buttons need `device = InputEvent.DEVICE_ID_MOUSE`, otherwise every tap on a phone fires the action.
- Use `_unhandled_input` for gameplay, so the UI consumes the event first.
- Every screen must work **with a gamepad** (initial focus, no focus leaking behind overlays) and **with touch** (generous touch areas, `SafeAreaMargin`).

## 5. Design patterns for games

Based on *Game Programming Patterns* (Robert Nystrom) and how Godot already implements many of them. In review, ask whether the pattern **solves a real problem** in the PR. A pattern without a problem is free complexity.

| Pattern | Problem it solves | In Godot / this template | Watch out |
|---|---|---|---|
| **State (FSM)** | Lots of "is jumping? attacking?" `if`s | `StateMachine` with one node per state; names as constants (`PlatformerState.IDLE`) | If states explode, consider a hierarchy (HFSM) or a Behavior Tree (LimboAI/Beehave) |
| **Component** | Deep inheritance and "god" classes | `HealthComponent`, `Hitbox/Hurtbox`, `HitFlashComponent` | A component doesn't know its concrete owner; it talks through signals |
| **Observer** | Systems reacting without knowing each other | Godot signals; `EventBus` for what is global | Don't turn `EventBus` into a dumping ground; use a local signal when both sides know each other |
| **Template Method** | Same flow, different details per type | `Character._on_damaged` → `apply_knockback()` → `_on_hurt()` | Shallow hierarchy; `@abstract` hooks for what is mandatory |
| **Type Object / Flyweight** | Enemy/weapon variations without a new class | `Resource`s (`EnemyStats`, `PlatformerStats`) shared between instances | To change them at runtime, `duplicate()` or `resource_local_to_scene` |
| **Command** | Remapping, replays, undo, AI using the same input | InputMap actions + `InputBindings`; `TouchButton` emits `InputEventAction` | For replay/undo, turn actions into objects with `execute()`/`undo()` |
| **Object Pool** | Allocation spikes (bullets, particles) | `AudioStreamPlayer` pool in `AudioManager` | Only after profiling; reset state on reuse |
| **Service Locator / Singleton** | Global access to services | Autoloads (`SaveSystem`, `AudioManager`) | Few of them; no hidden gameplay state; testable through a public API |
| **Strategy** | Swapping behavior (movement, aim, AI) | `Enemy` subclasses swap only movement; top-down aim sources | If swapped at runtime, prefer a pluggable node/resource over a growing `match` |
| **Event Queue** | Decoupling in *time* (play a sound next frame, batch effects) | `call_deferred`, `ConsoleLogger` drained in `_process` | Mind ordering and objects freed before processing |
| **Update Method / Game Loop** | Each object updates every frame | `_process` / `_physics_process` | Parent before child; turn off when idle |
| **Dirty Flag** | Recompute only when something changed | E.g. the HUD updates on the health signal, not every frame | Make sure every change path sets the "dirty" mark |
| **Data Locality** | Many identical objects (thousands) | `MultiMeshInstance2D`, `PhysicsServer2D` directly | Only after measuring; it complicates the code |

## 6. Constants, literals and magic numbers

Text or numbers that **identify** something, or that must match in two places, become constants. A typo then becomes a compile error, and renaming is safe.

| What | Where the constant lives | Example |
|---|---|---|
| InputMap actions | `Actions` (`core/constants/actions.gd`) | `Input.is_action_pressed(Actions.JUMP)` |
| Groups | `Groups` (`core/constants/groups.gd`) | `get_first_node_in_group(Groups.PLAYER)` |
| Scene paths | `ScenePaths` | `SceneLoader.change_scene(ScenePaths.MAIN_MENU)` |
| Physics layers | `PhysicsLayers` | `PhysicsLayers.WORLD` |
| State names | The states' base class | `transition_to(EnemyState.HURT)` |
| Settings sections/keys | `Settings` | `Settings.get_value(Settings.GAME, Settings.HITSTOP)` |
| Save keys | In the class that owns the data | `PlayerCharacter.ABILITIES_SAVE_KEY` |
| Abilities | In the genre's player | `PlatformerPlayer.ABILITY_DASH` |
| Shader uniforms | In the script that uses the shader | `HitFlashComponent.FLASH_AMOUNT` |
| Audio buses | `AudioManager` | `AudioManager.MUSIC_BUS` |

**Numbers:**

- **Balancing** (speed, damage, timings, range) lives in a `Resource` (`*Stats.tres`) or an `@export`, never in the middle of code.
- Tunable **game feel** (shake, hitstop, heights) lives in an `@export`, with `@export_range` and a unit comment (s, px, px/s).
- May stay literal: **obvious** values (`0.0`, `1.0`, `0.5` for half, `Vector2.ZERO`) and visual tweaks used **once**, next to a comment. When the same value shows up in two places, or someone needs to tune it in the editor, promote it.

**Accepted exceptions:**

- `tools/genre_setup.gd` uses plain strings because it must run without game dependencies (`-s` mode).
- Translation keys (`"UI_PLAY"`) live in the CSV, which is already the source of truth.
- Property paths in tweens (`"modulate:a"`) are Godot API.

## 7. Performance (PC and mobile)

- **Measure before optimizing:** use the *Profiler*, the *Monitors* and the debug overlay (F3). Optimization without measurement is 🟢 at most.
- **No per-frame allocations** in hot code: don't create `Array`/`Dictionary`/formatted `String`s inside `_physics_process` without need.
- Don't call `get_tree().get_nodes_in_group()` or `find_child()` every frame; cache the reference or use a signal.
- Pool frequent objects (projectiles, effects). Mass `queue_free()` in a single frame causes spikes.
- **Compatibility** renderer (mobile): prefer `CPUParticles2D`, few shaders, atlased textures, and avoid full-screen overlapping transparency.
- Turn off `_process` on idle objects; use `VisibleOnScreenEnabler2D` for off-screen enemies.
- Logs: `Log.debug` with `%` formats the string even when the level is off; in hot code, check the level first.
- Test on a **low-end phone** and measure loading time (`SceneLoader` loads on a thread).

## 8. Security

- Everything coming from `user://`, a download or the player is **untrusted**.
  - **Never** use `ConfigFile.load/parse`, `str_to_var` or `bytes_to_var` on that data: they construct objects and can execute code. Use `SafeConfig`.
  - Saves are JSON (no code execution), but validate **types and ranges** (`SaveSystem.get_int()`, `is Array`).
- Changed the save format? Bump `SAVE_VERSION` and write the migration in `_migrate()`, with a test.
- Debug tools only exist in `OS.is_debug_build()`. Cheats and the console never ship in a Release.
- No secrets in the repository: keystores and passwords only through environment variables/CI secrets.
- CI: `permissions: contents: read`, third-party actions pinned by SHA, no `${{ inputs.* }}` inside `run:`.
- Multiplayer (when added): the server never trusts the client; validate every RPC.

## 9. Robustness and lifecycle

- **No `assert` for runtime validation:** it's stripped from release builds. Validate, log with `Log.error` and fall back.
- Whoever "holds" something (pause, an input action, music) **releases it in `_exit_tree`** or on `NOTIFICATION_EXIT_TREE`.
- Subclasses call `super._ready()` (Godot 4 doesn't call the parent's `_ready` when you override it).
- Free nodes with `queue_free()`, not `free()`, during physics or signals.
- Turn off collisions with `set_deferred` inside physics callbacks.
- Interrupted an action midway (e.g. a windup cut short by damage)? Make sure its tweens and flags are undone.

## 10. Tests

- **Every new gameplay feature has a test** in the genre suite (`game/<genre>/tests/`) or in `tests/smoke_test.gd`. Every fixed bug has a regression test.
- Tests run as a **scene**, not with `-s`.
- No checks pinned to an exact frame: wait on a condition (`_wait_for`) and remember that `physics_frame` fires **before** the nodes' `_physics_process`.
- Game feel timing in **real time** (`real_seconds()`), because hitstop changes `time_scale`.
- Tests don't touch the player's data: a test save slot and a snapshot/restore of bindings.
- When changing something shared, also test both genre setups on a **copy** of the project.

## 11. Documentation and Git

- Docs in **both languages** (README/MANUAL/this guide), with working language links.
- User-visible changes go into `CHANGELOG.md` (*Unreleased*). Implemented backlog items are checked off in `IMPROVEMENTS.md`.
- Small commits, in the imperative, explaining the why. AI usage noted with a `Co-Authored-By` trailer.
- Never `git add -A` blindly: check `git status` and don't commit personal or generated files (`.godot/`, builds, draft `.aseprite` files).

## 12. Quick checklist

Copy it into the PR if you like:

```markdown
### Architecture
- [ ] Module rule respected (core/ui/autoloads/game root don't reference genres)
- [ ] Single responsibility; no duplicated logic that belongs in Character/a component
- [ ] Call down, signal up; EventBus only between systems that don't know each other
- [ ] No new autoload without a real need

### Code
- [ ] Full static typing; no access to other scripts' `_private` members
- [ ] No identifier literals (actions, groups, states, settings, save keys)
- [ ] Balancing numbers in Resource/@export
- [ ] No duck typing when a common base exists

### Robustness and security
- [ ] Outside data validated (SafeConfig, types); no assert for validation
- [ ] Pause/input/tweens released when leaving the tree
- [ ] No debug/cheats in release

### Performance
- [ ] No per-frame allocation or group lookup in hot code
- [ ] Processing turned off when idle

### Tests and docs
- [ ] New (or regression) test and a passing smoke test
- [ ] PT/EN docs, CHANGELOG and IMPROVEMENTS updated
```

## 13. References

- Godot docs: [Best practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html) (scene organization, autoloads vs. regular nodes, when to use scenes vs. scripts, logic preferences), [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), [Static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html), [Optimization](https://docs.godotengine.org/en/stable/tutorials/performance/index.html) and [Physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/index.html).
- Robert Nystrom, *Game Programming Patterns* ([gameprogrammingpatterns.com](https://gameprogrammingpatterns.com), free to read online).
- Google, [*Code Review Developer Guide*](https://google.github.io/eng-practices/review/): how to review and how to receive reviews.
- GDQuest, Godot architecture guides and tutorials ([gdquest.com](https://www.gdquest.com)).
