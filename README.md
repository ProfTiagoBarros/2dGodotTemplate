# Godot 2D Template

Template base para jogos **2D** em **Godot 4.7+**, pensado para **PC e celular** ao mesmo tempo, com arquitetura modular e padrões recomendados pela documentação oficial e pela comunidade indie. Traz dois **módulos de gênero**, **side-scrolling (platformer)** e **top-down**, sobre a mesma base.

> 📘 **Primeira vez usando o template?** Comece pelo **[MANUAL.md](MANUAL.md)**: passo a passo para criar um jogo novo, fazer as modificações iniciais, construir fases, inimigos e habilidades, publicar builds, e dicas para aproveitar tudo.
>
> O que ainda não foi implementado está descrito em [IMPROVEMENTS.md](IMPROVEMENTS.md).

## Começando um jogo novo

1. Crie o projeto a partir do template (GitHub: **Use this template**, ou copie a pasta).
2. Abra no Godot 4.7+ (Project Manager → Import).
3. **Escolha o gênero** (uma única vez):
   - **No editor:** abra `tools/setup_genre.gd`, ajuste `const GENRE := "platformer"` ou `"topdown"` e rode com **File → Run** (Ctrl+Shift+X). Depois use *Project → Reload Current Project*.
   - **Pela linha de comando:**
     ```bash
     godot --headless --path . -s res://tools/setup_genre_cli.gd -- topdown
     ```

   O setup aponta `ScenePaths.FIRST_LEVEL` para a fase do gênero, move o módulo do outro gênero para a **lixeira** (dá para recuperar) e remove do InputMap as ações que só o outro gênero usava.
4. **Identidade do jogo:**
   - Nome: *Project Settings → Application → Config → Name*.
   - Android: `package/unique_name` (ex.: `com.seuestudio.seujogo`) e `package/name` em `export_presets.cfg` (ou *Project → Export → Android*).
   - CI: `GAME_SLUG` em `.github/workflows/ci.yml`, usado no nome dos arquivos gerados.
5. Pressione **F5**. A partir daí, cada push roda o smoke test no GitHub e cada tag `v*` gera os builds (veja [CI, builds e releases](#ci-builds-e-releases)).

> Antes do setup os dois módulos convivem. Para testar o outro gênero, troque `FIRST_LEVEL` em `core/constants/scene_paths.gd`.

### Controles

| Ação | Teclado / Mouse | Gamepad | Toque |
|---|---|---|---|
| Mover | A/D/W/S ou setas | Analógico esq. / D-pad | Joystick virtual |
| Mirar (top-down) | Mouse (cursor) | Analógico direito | Direção do movimento |
| Pular (platformer) | Espaço / K | A | Botão A |
| Atacar | J / Clique esquerdo | X | Botão B (platformer) / A (top-down) |
| Dash | Shift / L / Clique direito | B | Botão C (platformer) / B (top-down) |
| Interagir | E | Y | — |
| Pausar | Esc / P | Start | Botão II |

Tudo isso pode ser **remapeado pelo jogador** em *Configurações → Controles* (veja [Remapeamento de controles](#remapeamento-de-controles)).

### Smoke test

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

Roda os testes gerais e a suíte de cada módulo de gênero presente no projeto.

## CI, builds e releases

O workflow [.github/workflows/ci.yml](.github/workflows/ci.yml) roda no GitHub Actions:

| Gatilho | O que acontece |
|---|---|
| Push na `main` / Pull Request | Importa o projeto e roda o smoke test |
| Tag `v*` (ex.: `v1.2.0`) | Smoke test → exporta **Windows, Linux, Web e Android** → publica um **Release** com os `.zip` |
| Manual (*Actions → CI → Run workflow*) | Smoke test + exportação, sem Release (builds ficam como *artifacts*) |

**Para lançar uma versão:**

```bash
git tag v1.2.0
```

```bash
git push origin v1.2.0
```

A versão da tag (`1.2.0`) é gravada em `config/version`, que aparece no canto do menu principal. Também vira o `version/name` do Android. O `version/code` do Android usa o número da execução do workflow, então sempre cresce.

**Detalhes:**
- O Godot e os export templates (~1,3 GB) são baixados uma vez e ficam em **cache**. A versão é definida por `GODOT_VERSION` no workflow; mantenha igual à do editor.
- `tests/`, `tools/` e `game/*/tests/` são **excluídos** dos builds pelos presets.
- **Web** usa a variante **sem threads**, compatível com itch.io e com qualquer hospedagem estática, sem headers COOP/COEP.
- **Android sem configurar nada:** o APK sai assinado com uma keystore de **debug** gerada no CI. Dá para instalar e testar, mas não para publicar na Play Store.
- **Android de release:** adicione 3 *secrets* no repositório (*Settings → Secrets and variables → Actions*). Com eles, o CI exporta em modo release automaticamente.
  - `ANDROID_KEYSTORE_BASE64`: a keystore em base64 (`base64 -w0 release.keystore`).
  - `ANDROID_KEYSTORE_ALIAS`: o alias da chave.
  - `ANDROID_KEYSTORE_PASSWORD`: a senha.

  Para gerar a keystore de release (guarde-a com cuidado: perder a keystore impede atualizar o app na Play Store):
  ```bash
  keytool -genkeypair -v -keystore release.keystore -alias meujogo -keyalg RSA -keysize 2048 -validity 10000
  ```
- Senhas e keystores **nunca** vão para o repositório: `*.keystore`/`*.jks` estão no `.gitignore`. No editor, o Godot guarda credenciais em `.godot/export_credentials.cfg`, que também é ignorado.

**Exportar localmente:** instale os export templates (*Editor → Manage Export Templates*) e use *Project → Export*, ou:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/game.exe
```

### Usando como template no GitHub

1. Crie um repositório no GitHub e envie este projeto para ele (veja os comandos abaixo).
2. Em *Settings → General*, marque **Template repository**.
3. Para cada jogo novo: **Use this template → Create a new repository**, clone o repositório novo e siga [Começando um jogo novo](#começando-um-jogo-novo).

## Estrutura

```
autoloads/     Serviços globais (singletons): poucos e com responsabilidade única
core/          Código reutilizável e agnóstico de jogo/gênero
  components/    HealthComponent, HitboxComponent, HurtboxComponent
  state_machine/ StateMachine + State (FSM baseada em nós)
  camera/        GameCamera (screen shake por trauma)
  utils/         MathUtils, PlatformUtils
  constants/     ScenePaths, PhysicsLayers
  debug/         ConsoleLogger (captura a saída do engine para o console)
  feel/          HitFlashComponent, SquashStretch, shader de flash, efeitos de partícula
game/          Conteúdo do jogo, organizado POR FEATURE
  game.tscn      Cena de gameplay (qualquer gênero): fase + HUD + toque + pausa
  level.gd       Level: contrato (classe base) de toda fase
  game_debug_commands.gd  Comandos de console e watches de gameplay
  hazards/       DamageZone (espinhos)
  props/         TrainingDummy (alvo de treino), AbilityPickup (item de habilidade)
  enemies/       Enemy (base genérica), EnemyStats e estados de IA compartilhados
  world/         SolidBlock (greybox)
  platformer/    MÓDULO side-scrolling: player, estados, stats, fase, testes
  topdown/       MÓDULO top-down: player, estados, stats, pilar, fase, testes
ui/            main_menu/ pause_menu/ settings_menu/ controls_menu/ hud/ touch_controls/
  components/    SafeAreaMargin (notch), ActionPromptLabel (dica de botão)
  debug/         DebugOverlay (F3) e DebugConsole (F1)
localization/  translations.csv (en, pt_BR)
assets/        Assets compartilhados (sprites, audio, fonts, shaders)
tests/         Runner do smoke test
tools/         Setup de gênero (rode uma vez e pode apagar)
```

**Por que por feature?** A documentação do Godot recomenda manter os assets perto das cenas que os usam. Assim cada feature (e cada gênero) é uma pasta autocontida, fácil de mover, apagar ou reaproveitar.

**Regra dos módulos:** `core/`, `ui/` e o que está na raiz de `game/` **nunca** referenciam `game/platformer/` ou `game/topdown/`. É isso que permite apagar um módulo sem quebrar nada. A ligação acontece só por `ScenePaths.FIRST_LEVEL` e pelas propriedades da `Level`.

## Arquitetura

### Autoloads (ordem importa)

| Autoload | Responsabilidade |
|---|---|
| `Log` | Log com níveis (DEBUG/INFO/WARN/ERROR); em release só WARN+ |
| `EventBus` | Sinais globais para eventos transversais (Player → HUD, qualquer coisa → câmera) |
| `Settings` | Opções do usuário em `user://settings.cfg` (áudio, vídeo, idioma, toque) |
| `SaveSystem` | Save JSON versionado, escrita atômica + `.bak`, migração por versão |
| `AudioManager` | Música com crossfade, pool de SFX, SFX posicional |
| `GameFeel` | Hitstop e efeitos de partícula pontuais (poeira, faíscas) |
| `InputManager` | Detecta o dispositivo ativo (teclado/mouse, gamepad, toque) e se o mouse está em uso |
| `InputBindings` | Remapeamento de controles, persistência dos atalhos e nomes/dicas de botões |
| `SceneLoader` | Troca de cena com fade e carregamento em thread |
| `DebugTools` | Overlay F3, console F1 e registro de comandos/watches. **Só em debug builds** |

### Kit de game feel ("juice")

Peças genéricas em `core/feel/` e no autoload `GameFeel`, usadas pelos dois gêneros:

| Peça | Como usar | Onde já está ligada |
|---|---|---|
| **Hitstop** | `GameFeel.hitstop(0.05)`. Congela por tempo **real** e restaura o `time_scale` anterior; chamadas sobrepostas estendem o fim | Golpe que acerta (0,05 s), player levando dano (0,08 s) |
| **Hit flash** | Nó `HitFlashComponent` com `target` (o visual) e `health`. Pisca branco via shader quando há dano | Players e alvo de treino |
| **Squash & stretch** | Nó `SquashStretch` entre o nó do flip e o desenho: `stretch_vertical(1.3)` / `stretch_horizontal(1.3)`. **Conserva a área** (sx·sy = 1) e volta com uma "mola" | Pulo, aterrissagem (proporcional à queda), dash |
| **Partículas** | `GameFeel.spawn_effect(GameFeel.DUST, posição)`. `CPUParticles2D` de disparo único que se liberam sozinhas | Poeira (pulo, aterrissagem, dash) e faíscas (golpe que acerta) |
| **Screen shake** | `EventBus.camera_shake_requested.emit(0.4)` (já existia) | Dano e golpes |

A estrutura do visual dos personagens é `Visual` (faz o flip com `scale.x = ±1`) → `Squash` (deforma e pisca) → desenhos. A sombra fica fora do `Squash`, então não deforma nem pisca.

**Dosagem:** impactos pequenos levam flash e faísca; médios, também hitstop curto; grandes, também shake. Exagerar tudo em todo golpe cansa. O jogador pode desligar o hitstop em *Configurações → Pausa de Impacto* e o tremor em *Tremor de Tela*.

`GameFeel.hitstop_started(duration)` é emitido a cada hitstop, para sincronizar som e vibração do controle.

### Ferramentas de debug

Disponíveis no editor e em **exports debug**, como o APK de teste do CI. Em builds de release o `DebugTools` não carrega nada.

| Atalho | O que faz |
|---|---|
| **F3** | Overlay: FPS, tempo de frame, draw calls, nós, memória, cena, dispositivo de input e os *watches* do jogo (posição, estado da FSM, vida…) |
| **F1** ou **`** | Console de comandos. **Pausa o jogo** enquanto aberto. Tab completa, ↑/↓ navega no histórico, Esc fecha |
| **3 dedos** na tela | Abre o console no celular |

O console também mostra **toda a saída do jogo**: `print`, `Log`, avisos e erros do engine com arquivo e linha do script. Assim dá para ver erros no celular sem cabo nem editor.

**Comandos inclusos:**
- Genéricos: `help`, `clear`, `overlay`, `fps <n>`, `timescale <x>`, `collisions` (mostra as formas de colisão), `log <nível>`, `lang <locale>`, `quit`.
- De gameplay: `god`, `heal [n]`, `kill`, `tp <x> <y>` (sem argumentos, vai até o mouse), `level [nome]` (lista ou carrega uma fase de qualquer pasta `levels/`), `reload`, `save [slot]`, `load [slot]`, `ability [nome] [on|off]`.

**Para adicionar comandos e watches**, cada sistema registra os próprios:

```gdscript
func _ready() -> void:
	DebugTools.register_command("gold", _cmd_gold, "gold <n> - define o ouro")
	DebugTools.watch("Inimigos", func() -> String: return str(get_tree().get_node_count_in_group("enemy")))


func _cmd_gold(args: PackedStringArray) -> String:
	gold = args[0].to_int() if not args.is_empty() else gold
	return "Ouro: %d" % gold
```

Os comandos de gameplay ficam em `game/game_debug_commands.gd`. O `core/` só tem os genéricos, então continua sem saber nada do jogo.

**Log:** use `Log.debug/info/warn/error("mensagem")` no lugar de `print`/`push_warning`. Cada linha sai com horário e nível. Em release só WARN e ERROR aparecem, e o nível muda em tempo de execução com `log <nível>`.

### Padrões usados

- **Call down, signal up**: o pai chama métodos dos filhos e os filhos emitem sinais. O `EventBus` só entra quando os sistemas não se conhecem (ex.: a HUD nunca referencia o Player).
- **Composição com componentes**: vida e dano são nós reutilizáveis, iguais nos dois gêneros. Hitboxes e hurtboxes têm um **`team`** (`player`, `enemy` ou vazio = neutro): uma hurtbox ignora golpes do próprio time e da própria entidade (`owner`). Inimigos não se ferem entre si, o player não se fere, e espinhos (neutros) ferem todos.
- **State Machine baseada em nós**: cada estado é um nó filho com `enter/exit/update/physics_update/handle_input`. O player expõe primitivas de movimento e os estados decidem as transições.
- **Data-driven com Resources**: `PlatformerStats` e `TopDownStats` são `Resource`s. Crie `.tres` diferentes por personagem ou power-up.
- **Input abstrato**: o gameplay só lê **ações** do InputMap. Teclado, gamepad e toque geram as mesmas ações. A fase define o que os botões de toque A/B/C fazem (`Level.touch_actions`) e quais dicas de botão a HUD mostra (`Level.hud_hint_actions`).

### Platformer (side-scrolling / metroidvania)

Estados: **Idle, Run, Jump, Fall, Attack, Dash**. O pulo é definido por **altura** e **tempo até o ápice**:

- `v₀ = 2h / t_apex`
- `g_subida = 2h / t_apex²`
- `g_queda = 2h / t_descida²` (queda mais pesada = pulo com mais "peso")

Soltar o botão cedo aplica a gravidade de queda, o que dá **pulo de altura variável**. Também tem **coyote time** e **jump buffer**.

- **Ataque direcional:** para o lado, **para cima** (segurando ↑) ou **para baixo no ar** (segurando ↓). O player continua se movendo durante o golpe e não vira de lado no meio dele. Pular no chão cancela o ataque.
- **Pogo:** acertar algo com o ataque para baixo quica o player (`pogo_velocity`) e recarrega o pulo duplo e o dash no ar, como no Hollow Knight.
- **Dash horizontal:** velocidade fixa **sem gravidade**, com i-frames (`dash_invulnerable`) e cooldown. No ar vale **1 por pulo** (`air_dashes`). Termina antes se bater numa parede.
- **Pulo duplo:** `air_jumps` pulos extras no ar.

Todos os números ficam em `PlatformerStats`, nos grupos *Attack*, *Dash* e *Jump*.

#### Habilidades (progressão metroidvania)

O player tem uma lista `abilities`. Por padrão ela traz `attack` e `dash`; o `double_jump` começa bloqueado.

- `has_ability()` controla o que pode ser usado; os estados consultam antes de agir.
- `unlock_ability()` / `lock_ability()` alteram a lista. Destravar emite `EventBus.ability_unlocked`, e a HUD mostra "<habilidade> desbloqueado!".
- O progresso é **salvo no SaveSystem**: o player está no grupo `persist`, e o item faz autosave ao ser coletado.
- **`AbilityPickup`** (`game/props/`) é o item coletável que destrava uma habilidade. Ele some sozinho se o player já a tiver. A fase de exemplo tem um item de pulo duplo e uma plataforma alta projetada para só ser alcançada com ele.
- **Nova habilidade:** escolha um nome (ex.: `wall_jump`), cheque `player.has_ability(&"wall_jump")` no estado que a usa, coloque um `AbilityPickup` com `ability = &"wall_jump"` e adicione a chave `ABILITY_WALL_JUMP` em `translations.csv`.
- Para testar, use o comando de debug `ability [nome] [on|off]`.

### Top-down

Estados: **Idle → Walk → Dash → Attack**.

- Movimento em 8 direções com `Input.get_vector`: diagonal normalizada, analógico preservado e `motion_mode = Floating` (sem conceito de chão).
- **Origem nos pés e colisão só na base**: o player passa "atrás" de pilares e objetos, e a fase usa **Y-sort** no nó `Entities`. Coisas no chão (espinhos) ficam em `FloorDecals`, com `z_index` menor.
- **Mira twin-stick**, com prioridade **analógico direito → mouse → direção do movimento**. O mouse só assume a mira depois que o jogador o mexe ou clica de verdade (`InputManager.using_mouse`), então quem joga só no teclado continua mirando para onde anda. Ao usar o gamepad, a mira volta ao analógico. Um indicador amarelo mostra a direção quando a mira vem do mouse ou do analógico.
- **Dash** com velocidade fixa, i-frames (`HealthComponent.grant_invulnerability`) e cooldown. Vai na direção do movimento, ou na da mira se o player estiver parado.
- **Ataque** corpo a corpo na direção da mira. A hitbox fica travada no ângulo inicial durante `attack_duration`.

### Inimigos

Uma base genérica (`game/enemies/`) serve aos dois gêneros. A IA é uma máquina de estados compartilhada:

```
Patrol ──vê o player──▶ Chase ──perto──▶ Windup ──▶ Attack (bote) ──▶ Recover ──▶ Chase/Patrol
                                (qualquer estado) ──levou dano──▶ Hurt ──▶ Chase/Patrol
```

- **Percepção:** o inimigo nota o player dentro de `detection_radius` **com linha de visão** (raycast contra o cenário). Ele só desiste fora de `lose_target_radius`, que é maior; essa **histerese** evita ficar alternando entre patrulhar e perseguir.
- **Windup (aviso):** antes do bote o inimigo para, agacha e avermelha por `windup_time`. É o que torna o golpe **justo**: o jogador vê e reage. O **Recover** depois do bote é a janela de contra-ataque.
- **Dano:** por **contato** (`ContactHitbox`) e pelo **bote** (`AttackHitbox`), os dois no time `enemy`. Ao apanhar, o inimigo sofre knockback e fica atordoado (`Hurt`), o que cancela o ataque. Na morte, emite `EventBus.enemy_died`, solta faíscas e poeira e some.
- **`EnemyStats` (.tres por tipo):** velocidades, raios de percepção, tempos de windup, bote e recuperação, knockback.
- **Por gênero, só o movimento muda:**
  - **`PlatformerEnemy`** (walker): gravidade, vira em **paredes e beiradas**, não despenca ao perseguir, só ataca no mesmo "andar".
  - **`TopDownEnemy`** (slime): vagueia perto da origem com pausas e persegue e ataca em 2D.

As fases de exemplo têm 2 inimigos cada. No overlay F3, o watch "Inimigos" mostra quantos existem e quantos estão perseguindo.

### Remapeamento de controles

*Configurações → Controles* lista as ações com duas colunas, **Teclado/Mouse** e **Controle**. Clique (ou confirme no gamepad) num atalho e pressione o novo. **Esc** cancela.

- **Atalho principal:** cada ação tem um atalho principal por tipo de dispositivo (o primeiro da lista no InputMap), e é ele que a tela troca. Os alternativos, como setas e D-pad, continuam funcionando.
- **Conflitos:** se o novo atalho já pertencia a outra ação, as duas **trocam** de atalho, então nenhuma ação fica sem tecla.
- **Persistência:** as mudanças ficam em `user://settings.cfg`, na seção `[input]`. Os padrões continuam sendo os do Project Settings, e "Restaurar Padrões" volta a eles.
- **Lista adaptada ao gênero:** a tela mostra só as ações que existem no projeto, então depois do setup ela já está certa para o gênero.
- **Nomes por dispositivo:** teclas aparecem no layout do jogador (ABNT2, AZERTY…), e botões do controle aparecem pela família detectada (Xbox: A/B/X/Y, PlayStation: Cross/Circle…, Nintendo: B/A/Y/X).
- **Mouse e toque:** atalhos de mouse valem só para o **mouse real** (`InputEvent.DEVICE_ID_MOUSE`). O clique que o celular simula a partir do toque é ignorado, senão cada toque na tela dispararia a ação.
- **Dicas na tela:** `InputBindings.get_prompt(&"attack")` devolve o atalho no dispositivo atual. O componente `ActionPromptLabel` (usado na HUD) mostra "Atacar [J]" ou "Atacar [X]" e se atualiza sozinho.
- **Nova ação remapeável:** crie a ação no InputMap e adicione-a em `InputBindings.REMAPPABLE` com a chave de tradução do nome.

### Camadas de física

| Layer | Nome | Uso |
|---|---|---|
| 1 | world | Cenário sólido |
| 2 | player | Corpo do player |
| 3 | enemies | Corpo dos inimigos / dummies (o player top-down colide; máscara 1+3) |
| 4 | hitboxes | Áreas que causam dano |
| 5 | hurtboxes | Áreas que recebem dano (máscara: 4) |
| 6 | interactables | Objetos interativos |

Use `PhysicsLayers.HITBOXES` etc. no código em vez de números mágicos.

## Segurança e performance

### Dados de fora são não confiáveis

Arquivos em `user://` (configurações, saves) podem ser editados pelo jogador ou trocados entre pessoas, em mods ou "packs" baixados. Regras do template:

- **Nunca use `ConfigFile.load()`, `str_to_var()` ou `bytes_to_var()` com objetos em dados de fora.** O parser do Godot constrói objetos e **carrega scripts** a partir do texto (`Object(...)`, `Resource("...")`), ou seja, executa código. O `settings.cfg` é lido por **`SafeConfig`** (`core/utils/`), que recusa esses construtores antes do parse. Os valores ainda passam por `Settings.is_valid_value` (só chaves conhecidas, com o tipo certo, e volume limitado a 0–1).
- **Saves em JSON:** o parser de JSON só produz tipos primitivos. Mesmo assim, valide os tipos ao ler: `SaveSystem` recusa `data` que não seja dicionário, e `SaveSystem.get_int("chave")` devolve o padrão se o valor foi adulterado.
- **Builds de debug não são para distribuir:** eles têm console e cheats. O CI marca o APK sem keystore de release como `...-android-debug`.

### CI

- **Permissões mínimas:** o token só lê o repositório, e apenas o job de Release pede escrita.
- **Godot e export templates verificados por SHA-512** contra o `SHA512-SUMS.txt` oficial do release.
- **Action de terceiros fixada por commit.** O **Dependabot** (`.github/dependabot.yml`) abre PRs mensais com as atualizações.
- **Tags validadas:** só `vX.Y.Z` (semver) é aceita antes de virar versão.
- **Secrets protegidos:** só são usados nos jobs de tag e manuais. PRs de forks não têm acesso a eles.

### Performance

- **Hurtboxes dormem** (`set_physics_process(false)`) e só acordam quando algo entra na área.
- **Percepção dos inimigos a ~10 Hz** (`perception_interval`), com fase aleatória por inimigo: os raycasts de linha de visão se espalham entre frames em vez de rodarem todos a cada frame.
- **Partículas em CPU** (`CPUParticles2D`) e renderer Compatibility, que é o mais leve para celular e web.
- **Ferramentas de debug** e captura de log não carregam em builds de release.

## PC + Mobile

- **Resolução base 640×360** (16:9, escala inteira para 720p/1080p/1440p/4K), stretch `canvas_items` + aspect `expand`: celulares 19.5:9 mostram mais mundo em vez de barras pretas.
- **Renderer Compatibility** (OpenGL ES 3 / WebGL 2): é o mais compatível para celulares antigos e web.
- **Filtro Nearest** por padrão (pixel art). Para arte HD, troque em *Rendering > Textures > Default Texture Filter*.
- **Physics interpolation** ligada: movimento suave em telas de 90/120/144 Hz com física fixa em 60 Hz.
- **Orientação** `sensor_landscape`, **ETC2/ASTC** habilitado para exportar para mobile.
- **Safe area** (notch) via `SafeAreaMargin` na HUD e nos controles de toque.
- **Pausa automática** ao perder foco ou ir para segundo plano. **Botão voltar do Android**: pausa no jogo e fecha o app no menu (`quit_on_go_back=false`).
- Opções de tela cheia e VSync aparecem só no desktop. O botão "Sair" fica oculto no iOS e na web.
- Para testar o toque no PC, ative *Input Devices > Pointing > Emulate Touch From Mouse* e coloque "Controles de Toque" em "Sempre".

## Convenções (guia de estilo oficial do GDScript)

- Arquivos e pastas em `snake_case`. Nós e `class_name` em `PascalCase`.
- `class_name` dos módulos levam o prefixo do gênero (`PlatformerPlayer`, `TopDownState`), porque os dois módulos convivem até o setup e nomes iguais conflitariam.
- **Tipagem estática** em tudo. O projeto avisa sobre declarações não tipadas.
- Ordem no script: `class_name`/`extends` → docstring → sinais → enums → constantes → `@export` → variáveis → `@onready` → métodos built-in → públicos → privados (`_`).
- Referências a nós da própria cena com `%UniqueName`, e não com caminhos longos.
- Textos de UI são **chaves de tradução** (`UI_PLAY`) definidas em `localization/translations.csv`.

## Receitas rápidas

- **Nova fase**: duplique a fase do seu módulo (a raiz usa `level.gd`) e aponte `ScenePaths.FIRST_LEVEL`, ou carregue-a via `game.level_path`.
- **Novo estado do player**: crie um script `extends PlatformerState` (ou `TopDownState`), adicione um nó filho em `Player/StateMachine` e chame `transition_to(&"NomeDoNo")`.
- **Novo tipo de inimigo**: duplique `platformer_enemy.tscn` (ou `topdown_enemy.tscn`), troque o visual e crie um `EnemyStats` (.tres) com os números dele. Para outro comportamento de movimento, estenda `Enemy` e sobrescreva `patrol_direction`/`direction_to_target`/`move_toward_direction`.
- **Nova opção de configuração**: adicione o padrão em `Settings.DEFAULTS`, trate em `Settings._apply` e crie o controle em `settings_menu`.
- **Novo texto**: adicione uma linha em `translations.csv` e use a chave no `text` do Control.
- **Novo módulo de gênero** (ex.: twin-stick, puzzle): crie `game/<genero>/` com fase, player e `tests/<genero>_smoke_test.gd`, e registre em `tools/genre_setup.gd` (`GENRES`) e em `tests/smoke_test.gd` (`GENRE_SUITES`).
