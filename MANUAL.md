# Manual do Godot 2D Template

**Português** · [English](MANUAL.en.md)

Guia prático para começar um jogo novo a partir do template, fazer as modificações iniciais e aproveitar bem o que já vem pronto. Para detalhes técnicos de cada sistema, o [README](README.md) é a referência; este manual foca no **como usar**.

> 🤖 Template e manual desenvolvidos com assistência de IA (**Claude**, da Anthropic), com revisão e testes do autor. Detalhes em [Créditos e uso de IA](README.md#créditos-e-uso-de-ia).

## Índice

1. [O que vem pronto](#1-o-que-vem-pronto)
2. [Antes de começar](#2-antes-de-começar)
3. [Criando um jogo novo, passo a passo](#3-criando-um-jogo-novo-passo-a-passo)
4. [Modificações iniciais: a identidade do jogo](#4-modificações-iniciais-a-identidade-do-jogo)
5. [Construindo o seu jogo](#5-construindo-o-seu-jogo)
6. [Ferramentas do dia a dia](#6-ferramentas-do-dia-a-dia)
7. [Publicando: builds e releases](#7-publicando-builds-e-releases)
8. [Sugestões para aproveitar melhor](#8-sugestões-para-aproveitar-melhor)
9. [Solução de problemas](#9-solução-de-problemas)
10. [Checklist rápido de jogo novo](#10-checklist-rápido-de-jogo-novo)

---

## 1. O que vem pronto

| Área | O que você ganha sem escrever código |
|---|---|
| **Fluxo** | Menu principal, jogo, pausa, configurações, troca de cena com fade, save automático em JSON |
| **Gêneros** | Platformer/metroidvania (pulo com coyote/buffer, ataque direcional, pogo, dash, pulo duplo, habilidades) e top-down (8 direções, mira twin-stick, dash, ataque) |
| **Inimigos** | Base genérica com patrulha → persegue → aviso → bote, um tipo de exemplo por gênero |
| **Controles** | Teclado, mouse, gamepad e toque, com **remapeamento** pelo jogador e dicas de botão que mudam com o dispositivo |
| **PC + celular** | Joystick virtual, safe area (notch), pausa ao minimizar, botão voltar do Android, opções só de desktop escondidas no celular |
| **Game feel** | Hitstop, flash de dano, squash & stretch, poeira, faíscas, tremor de tela |
| **Debug** | Overlay F3, console F1 com comandos (god, tp, level…), log com níveis |
| **Qualidade** | Smoke test automático e CI no GitHub que testa a cada push e gera builds para Windows, Linux, Web e Android a cada tag |

---

## 2. Antes de começar

- **Godot 4.7** (a mesma versão usada no CI: `GODOT_VERSION` em `.github/workflows/ci.yml`).
- **Git** e uma conta no **GitHub**, para o template, o CI e os builds automáticos.
- Opcional: **Claude Code**. O arquivo `CLAUDE.md` já descreve a arquitetura e as convenções, então você pode pedir features novas e elas seguem o padrão do projeto.

Se ainda não fez isso: no repositório do template no GitHub, vá em *Settings → General* e marque **Template repository**. Só precisa ser feito uma vez.

---

## 3. Criando um jogo novo, passo a passo

### Passo 1: criar o repositório do jogo

**Com GitHub (recomendado):**
1. No repositório do template, clique em **Use this template → Create a new repository**.
2. Dê o nome do jogo (ex.: `meu-metroidvania`) e crie.
3. Clone o repositório novo:
   ```bash
   git clone https://github.com/SEU_USUARIO/meu-metroidvania.git
   ```

**Sem GitHub:** copie a pasta do template, apague a pasta `.git` da cópia e rode `git init` dentro dela.

### Passo 2: abrir e testar antes de mudar qualquer coisa

1. Abra o Godot 4.7, clique em **Import** e escolha o `project.godot` do jogo novo.
2. Na primeira abertura o Godot importa todos os arquivos. Espere terminar.
3. Pressione **F5**: menu → **Jogar** → fase de exemplo do platformer.
4. Quer experimentar o top-down antes de decidir? Com o jogo rodando, aperte **F1** e digite:
   ```
   level topdown_level_01
   ```

### Passo 3: escolher o gênero (uma única vez)

1. No editor, abra `tools/setup_genre.gd`.
2. Mude a linha `const GENRE := "platformer"` para o gênero desejado (`"platformer"` ou `"topdown"`).
3. Com o script aberto, use **File → Run** (Ctrl+Shift+X).
4. Use **Project → Reload Current Project**.

O que o setup faz:
- Aponta a primeira fase do jogo para o gênero escolhido.
- Move a pasta do **outro** gênero para a **lixeira do sistema**, de onde dá para recuperar.
- Remove do mapa de controles as ações que só o outro gênero usava, como o pulo no top-down ou a mira no platformer.

> Dica: rode **F5** de novo depois do setup para confirmar que está tudo certo. A pasta `tools/` pode ser apagada depois.

### Passo 4: rodar os testes

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

Deve terminar com `Smoke test: PASSOU`. Depois do setup, só as suítes do gênero escolhido rodam.

### Passo 5: primeiro commit

```bash
git add -A
```

```bash
git commit -m "Setup inicial do jogo"
```

```bash
git push
```

Abra a aba **Actions** do repositório e confira o smoke test verde.

### Passo 6: configurar o repositório no GitHub (uma vez por repositório)

> A interface do GitHub muda com o tempo. Os nomes abaixo são os da documentação oficial em outubro de 2026. Se algo não bater, procure o nome equivalente ou consulte o link da documentação de cada item.

Todas as configurações começam igual: na página do repositório, clique na aba **Settings** (engrenagem, no topo, à direita de *Insights*; se não aparecer, abra o menu **…**). A **barra lateral esquerda** é dividida em grupos.

**a) Segurança: reporte privado de vulnerabilidades e Dependabot**
1. Na barra lateral, no grupo **Security and quality**, clique em **Advanced Security**. Antes essa página se chamava *Code security and analysis*.
2. Na linha **Private vulnerability reporting**, clique em **Enable**. Isso só existe em repositórios **públicos**.
3. Na mesma página, ative também **Dependabot alerts** (e **Dependabot security updates**, se aparecer).

Documentação: [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/configuring-private-vulnerability-reporting-for-a-repository) · [Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/configuring-dependabot-alerts)

**b) Proteger a branch `main`**
1. Na barra lateral, no grupo **Code, planning, and automation**, clique em **Rules** → **Rulesets**.
2. Clique em **New ruleset** → **New branch ruleset**.
3. **Ruleset name:** `Proteger main`.
4. **Enforcement status:** troque de *Disabled* para **Active**. O padrão é desligado, e sem essa troca a regra não vale.
5. **Target branches:** clique em **Add target** → **Include default branch**.
6. Em **Branch rules**, deixe marcados **Restrict deletions** e **Block force pushes**. Isso já impede apagar a `main` ou reescrever o histórico.
7. Clique em **Create**.

Quando outras pessoas forem mandar PRs, volte nessa regra e marque também **Require status checks to pass**. Adicione o check **Smoke test**, que só aparece na lista depois de rodar ao menos uma vez. Em **Bypass list**, adicione **Repository admin**: assim você continua podendo dar `git push` direto na `main`. Sem isso, um push direto seria recusado, porque o commit ainda não tem o check aprovado.

Documentação: [rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)

**c) Descrição e tópicos (para outras pessoas acharem o projeto)**
1. Na **página inicial** do repositório (fora de Settings), coluna da direita, no quadro **About**, clique na **engrenagem ⚙**.
2. **Description:** uma frase curta.
3. **Topics:** digite cada tópico e aperte **Enter** (ex.: `godot`, `godot4`, `gdscript`, `gamedev`, `2d`).
4. Clique em **Save changes**.

**d) Template repository (só no repositório do template)**
- *Settings* → grupo **General** (a primeira página) → logo abaixo do nome do repositório, marque **Template repository**. Nos repositórios dos jogos, deixe desmarcado.

---

## 4. Modificações iniciais: a identidade do jogo

Faça isto logo no começo, porque alguns desses valores são difíceis de mudar depois que o jogo é publicado.

| O quê | Onde | Observação |
|---|---|---|
| **Nome do projeto** | *Project Settings → Application → Config → Name* | Também muda a pasta de saves/configurações do usuário |
| **Título no menu** | `localization/translations.csv`, chave `GAME_TITLE` | Um texto por idioma (`en`, `pt_BR`) |
| **Versão inicial** | *Project Settings → Application → Config → Version* | Depois o CI preenche a partir das tags (`v1.0.0`) |
| **Ícone** | Substitua `icon.svg` | Para Android, configure também os ícones adaptativos no preset |
| **ID do app Android** | `export_presets.cfg` → `package/unique_name` | Formato `com.seuestudio.seujogo`. **Não mude depois de publicar** na Play Store |
| **Nome do app Android** | `export_presets.cfg` → `package/name` | Nome que aparece no celular |
| **Nome dos arquivos de build** | `.github/workflows/ci.yml` → `GAME_SLUG` | Ex.: `meu-metroidvania` |
| **README do jogo** | `README.md` | Troque a descrição do topo pela do seu jogo. Mantenha `MANUAL.md` e `CLAUDE.md` como referência |
| **Badges e links** | Topo de `README.md` e `README.en.md` | Troque `ProfTiagoBarros/2dGodotTemplate` pelo seu repositório (badge do CI) |
| **Licença do jogo** | `LICENSE` | O template é MIT. Seu jogo pode ter outra licença (ou nenhuma, se for fechado); mantenha o aviso de copyright do template num arquivo de licenças de terceiros ou nos créditos |
| **Histórico** | `CHANGELOG.md` | Comece um histórico novo para o jogo, apagando as entradas do template |
| **Revisor de PRs** | `.github/CODEOWNERS` | Troque `@ProfTiagoBarros` pelo seu usuário ou equipe |
| **Resolução base** | *Project Settings → Display → Window* | Padrão 640×360 (pixel art). Para arte HD use 1280×720 e mude o filtro de textura para *Linear* |
| **Orientação no celular** | *Project Settings → Display → Window → Handheld* | Padrão paisagem. Para jogos em pé, use `sensor_portrait` e ajuste a resolução base |

### Removendo os exemplos (quando for a hora)

Os exemplos são úteis enquanto você aprende o template. Quando o jogo tiver conteúdo próprio:

- **Fase de exemplo** (`game/<gênero>/levels/*_level_01.tscn`): substitua pela sua primeira fase e atualize `ScenePaths.FIRST_LEVEL` em `core/constants/scene_paths.gd`.
- **Alvo de treino** (`game/props/training_dummy.*`) e **espinhos** (`game/hazards/`): pode apagar se não usar.
- **Testes:** se apagar algo que um teste usa (ex.: o alvo de treino), ajuste a suíte em `game/<gênero>/tests/`. O smoke test vai acusar.

> Não apague `core/`, `autoloads/`, `ui/`, `game/game.*` nem `game/level.gd`. São a base de tudo.

---

## 5. Construindo o seu jogo

### 5.1 Trocar a arte do personagem

Os personagens usam esta estrutura:

```
Player
└─ Visual          ← vira para os lados (scale.x = ±1)
   ├─ Shadow       ← (top-down) fica fora do Squash
   └─ Squash       ← deforma (squash & stretch) e pisca ao levar dano
      ├─ Body      ← troque estes polígonos pela sua arte
      └─ Eye
```

1. Apague `Body` e `Eye` e coloque um `Sprite2D` ou `AnimatedSprite2D` **dentro de `Squash`**.
2. Posicione a arte com os **pés na origem** (0, 0). Assim o squash mantém os pés no chão e o Y-sort do top-down funciona.
3. Para animações, ligue cada uma no `enter()` do estado correspondente:

```gdscript
# platformer_player.gd
@onready var sprite: AnimatedSprite2D = $Visual/Squash/Sprite

# states/run_state.gd
func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	player.sprite.play(&"run")
```

> Para importar direto do **Aseprite**, o addon *Aseprite Wizard* gera as `SpriteFrames` a partir do `.aseprite`.

### 5.2 Ajustar o movimento sem tocar em código

Todos os números de movimento ficam em **Resources** (`.tres`). Dê dois cliques no arquivo e edite no Inspector:

| Arquivo | O que controla |
|---|---|
| `game/platformer/player/default_platformer_stats.tres` | Velocidade, **altura e tempo do pulo**, coyote time, ataque, pogo, dash, pulos no ar |
| `game/topdown/player/default_topdown_stats.tres` | Velocidade, dash, duração do ataque, knockback |
| `game/<gênero>/enemies/*_stats.tres` | Velocidades, raios de visão, tempo de aviso e bote de cada inimigo |

O pulo do platformer é definido em termos de design: **altura em pixels** (`jump_height`) e **tempo até o topo** (`time_to_apex`). A física é calculada a partir disso. Um `time_to_descent` menor que `time_to_apex` dá uma queda mais "pesada".

> **Dica:** para variações (um personagem mais rápido, um power-up), duplique o `.tres` em vez de editar o padrão.

### 5.3 Criar fases

1. Duplique a fase de exemplo do seu gênero e renomeie.
2. No nó raiz da fase (script `level.gd`), confira no Inspector:
   - `level_id`: identificador único (ex.: `&"caverna_01"`).
   - `music`: a música da fase, que toca com crossfade.
   - `touch_actions`: o que os botões de toque A, B e C fazem.
   - `hud_hint_actions`: quais dicas de botão aparecem na tela. Numa fase de tutorial, mostre só o que já foi ensinado.
3. Para prototipar, use os blocos `SolidBlock` (greybox). Quando a arte chegar, troque por `TileMapLayer`.
4. Para testar uma fase rapidamente: **F1** → `level nome_da_fase`.

No top-down, coloque personagens, inimigos e objetos altos dentro do nó `Entities`, que tem Y-sort. Coisas no chão (tapetes, espinhos) ficam em `FloorDecals`.

### 5.4 Criar inimigos

**Mesmo comportamento, visual e números diferentes:**
1. Duplique `game/<gênero>/enemies/<inimigo>.tscn`.
2. Troque a arte dentro de `Visual/Squash`.
3. Duplique o `.tres` de stats, ajuste os números e aponte a propriedade `stats` da cena nova para ele.
4. Ajuste o `damage` de `ContactHitbox` e `AttackHitbox`, e o `max_health` do `HealthComponent`.

**Comportamento novo** (ex.: um inimigo voador no platformer): crie um script que `extends Enemy` e sobrescreva só o movimento: `patrol_direction()`, `direction_to_target()` e `move_toward_direction()`. A IA (estados) continua funcionando sozinha. Veja `platformer_enemy.gd` como modelo.

> Para equilibrar o combate, `windup_time` é o tempo que o jogador tem para reagir e `recover_time` é a janela de contra-ataque. São os dois números que mais mudam a "justiça" da luta.

### 5.5 Habilidades (metroidvania)

O player do platformer tem uma lista de habilidades salva no save. Para criar uma nova, por exemplo **wall jump**:

1. Adicione o método no player (`platformer_player.gd`):
   ```gdscript
   func wall_jump() -> void:
   	velocity = Vector2(get_wall_normal().x * stats.max_speed, -stats.jump_velocity)
   	face(signf(velocity.x))
   	jump_buffer_timer = 0.0
   ```
2. Use no estado de queda (`states/fall_state.gd`), antes das outras checagens de pulo:
   ```gdscript
   if player.has_ability(&"wall_jump") and player.is_on_wall() and player.wants_to_jump():
   	player.wall_jump()
   	return
   ```
3. Coloque um `AbilityPickup` (`game/props/ability_pickup.tscn`) na fase com `ability = wall_jump`.
4. Adicione a tradução `ABILITY_WALL_JUMP` em `translations.csv`, usada no aviso "Wall jump desbloqueado!".
5. Teste com o console: **F1** → `ability wall_jump on`.

Para **portas e barreiras** que exigem habilidade, faça um `StaticBody2D` que se remove quando `player.has_ability(...)` for verdadeiro, ou que escuta `EventBus.ability_unlocked`.

### 5.6 Salvar dados do jogo

O `SaveSystem` guarda um dicionário (`SaveSystem.data`) em JSON. Para um nó salvar o próprio estado:

```gdscript
func _ready() -> void:
	add_to_group(SaveSystem.PERSIST_GROUP)
	coins = int(SaveSystem.data.get("coins", 0)) # lê o que já foi carregado


func save_state(data: Dictionary) -> void:
	data["coins"] = coins


func load_state(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
```

- Chame `SaveSystem.save_game()` nos momentos certos: checkpoint, item coletado, troca de fase.
- O JSON converte números inteiros em decimais, então use `int(...)` ao ler. Para valores que o jogador poderia adulterar, prefira `SaveSystem.get_int("chave")`, que também trata tipos errados.
- Mudou o formato do save depois de lançar? Aumente `SAVE_VERSION` e trate a conversão em `_migrate()` (`autoloads/save_system.gd`).

### 5.7 Textos e idiomas

1. Adicione uma linha em `localization/translations.csv`:
   ```
   NPC_HELLO,Hello traveler!,Olá, viajante!
   ```
2. Use a chave como texto de qualquer `Label` ou `Button` (`NPC_HELLO`). A tradução é automática.
3. Em código: `tr("NPC_HELLO")`.
4. Para um idioma novo, adicione uma coluna (ex.: `es`) e inclua o código em `LOCALES` e o nome em `LOCALE_NAMES` em `ui/settings_menu/settings_menu.gd`.

> Se o texto tiver vírgula, coloque entre aspas no CSV.

### 5.8 Novos controles

1. Crie a ação em *Project Settings → Input Map*, com tecla e botão de gamepad. **Botões do mouse** precisam ter `device = 32` (`InputEvent.DEVICE_ID_MOUSE`, o mouse real); com "todos os dispositivos", cada toque na tela do celular também dispara a ação. O jeito mais simples é copiar no `project.godot` um evento de mouse já existente (veja `attack`) e trocar o `button_index`.
2. No código, use sempre a **ação**, nunca a tecla: `Input.is_action_just_pressed(&"interact")`.
3. Para o jogador poder remapear, adicione a ação em `REMAPPABLE` em `autoloads/input_bindings.gd`, com a chave de tradução do nome.
4. Para mostrar a dica na HUD, inclua a ação em `hud_hint_actions` da fase.
5. Para um botão na tela de toque, inclua em `touch_actions` da fase (até 3 botões).

### 5.9 Música e efeitos sonoros

Coloque os arquivos em `assets/audio/music/` e `assets/audio/sfx/` (`.ogg` para música, `.wav` para efeitos curtos).

```gdscript
AudioManager.play_music(preload("res://assets/audio/music/tema.ogg"))       # com crossfade
AudioManager.play_sfx(preload("res://assets/audio/sfx/pulo.wav"), 0.1)      # 0.1 = variação de tom
AudioManager.play_sfx_at(preload("res://assets/audio/sfx/explosao.wav"), global_position)
```

Bons lugares para ligar sons: `jump()` e `start_dash()` do player, `EventBus.enemy_died`, e `GameFeel.hitstop_started`, que marca o momento exato dos impactos.

### 5.10 Opções de configuração novas

1. Adicione o valor padrão em `DEFAULTS` (`autoloads/settings.gd`).
2. Se a opção mudar algo do engine, aplique em `_apply()` no mesmo arquivo.
3. Crie a linha na tela (`ui/settings_menu/settings_menu.tscn`) e ligue com `_bind_check` ou `_bind_option` em `settings_menu.gd`.
4. Leia em qualquer lugar com `Settings.get_value("game", "minha_opcao")`.

### 5.11 Game feel: quanto usar

| Impacto | Receita |
|---|---|
| Pequeno (golpe comum) | Flash + faíscas |
| Médio (golpe forte, levar dano) | Acima + `GameFeel.hitstop(0.05)` |
| Grande (chefe, explosão, morte) | Acima + `EventBus.camera_shake_requested.emit(0.5)` |

Exagerar em tudo cansa o jogador. O jogador pode desligar o hitstop e o tremor de tela nas configurações, e é bom manter essas opções.

---

## 6. Ferramentas do dia a dia

### Debug (só no editor e em builds de teste)

| Atalho | Uso |
|---|---|
| **F3** | Overlay: FPS, estado atual do player, vida, inimigos, dispositivo de input |
| **F1** ou **`** | Console. Digite `help` para ver os comandos |
| **3 dedos na tela** | Abre o console no celular |

Comandos mais úteis no desenvolvimento:

| Comando | Para quê |
|---|---|
| `god` | Testar fases sem morrer |
| `tp` | Teleportar até o mouse (pular trechos) |
| `level <nome>` | Ir direto para uma fase |
| `ability <nome> on` | Testar habilidades sem coletar |
| `timescale 0.25` | Câmera lenta para analisar animações e colisões |
| `collisions` | Ver as formas de colisão e hitboxes |
| `heal`, `kill`, `reload` | Vida, morte e recarregar a cena |

Para adicionar comandos do seu jogo, veja "Ferramentas de debug" no [README](README.md#ferramentas-de-debug).

Use `Log.info(...)`, `Log.warn(...)` e `Log.error(...)` no lugar de `print`. Tudo aparece no console F1, inclusive no celular, onde não dá para ver a saída do editor.

### Testes automáticos

Rode antes de cada commit importante:

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

Para testar algo do seu jogo, acrescente checagens na suíte do seu gênero (`game/<gênero>/tests/<gênero>_smoke_test.gd`):

```gdscript
# dentro de run(t), depois de spawn_game:
var door := game.find_child("DoorBoss", true, false)
t.check(door != null, "Fase tem a porta do chefe")
```

Helpers disponíveis em `t`:

| Helper | O que faz |
|---|---|
| `t.check(cond, "descrição")` | Registra uma verificação |
| `t.frames(n)` | Espera n frames de física |
| `t.tap(&"acao")` / `t.hold(&"acao", n)` | Simula input |
| `t.real_seconds(s)` | Espera em tempo real (use com hitstop) |
| `t.spawned_effects` | Efeitos de partícula criados |

> Para eventos disparados por input, espere alguns frames em vez de checar num frame exato. Senão o teste fica instável no CI.

### Testando no celular

1. Rode o workflow manualmente (*Actions → CI → Run workflow*) ou crie uma tag.
2. Baixe o artifact `...-android-debug` (ou `...-android`, se você configurou a keystore de release) e instale o `.apk` no celular. É preciso permitir a instalação de fontes desconhecidas.
3. O APK de teste é um build de debug: o console de 3 dedos funciona e mostra os erros.

---

## 7. Publicando: builds e releases

### Gerar uma versão

```bash
git tag v0.1.0
```

```bash
git push origin v0.1.0
```

Em poucos minutos (a primeira vez demora mais, por baixar os export templates), o GitHub publica um **Release** com `.zip` para Windows, Linux, Web e Android. A versão da tag aparece no canto do menu principal.

Use [versionamento semântico](https://semver.org/lang/pt-BR/): `v0.x` durante o desenvolvimento, `v1.0.0` no lançamento, `v1.0.1` para correções.

### Android para a Play Store

1. Gere uma keystore de release **uma única vez** e guarde-a em local seguro, com backup. **Perder a keystore impede atualizar o app.**
   ```bash
   keytool -genkeypair -v -keystore release.keystore -alias meujogo -keyalg RSA -keysize 2048 -validity 10000
   ```
2. No GitHub, em *Settings → Secrets and variables → Actions*, crie:
   - `ANDROID_KEYSTORE_BASE64`: a saída de `base64 -w0 release.keystore`
   - `ANDROID_KEYSTORE_ALIAS`: o alias (ex.: `meujogo`)
   - `ANDROID_KEYSTORE_PASSWORD`: a senha
3. Nunca coloque a keystore no repositório (o `.gitignore` já bloqueia `*.keystore`).
4. A Play Store exige **AAB** em vez de APK. Veja o item correspondente no [IMPROVEMENTS.md](IMPROVEMENTS.md).

### Web (itch.io)

O build Web roda em qualquer hospedagem estática. No itch.io, envie o `.zip` do Web como "HTML" e marque *SharedArrayBuffer support* como **desligado**, porque o template usa a variante sem threads, a mais compatível.

---

## 8. Sugestões para aproveitar melhor

### Processo

- **Faça uma "fatia vertical" primeiro:** uma sala completa, com arte final, som, inimigo, habilidade e save, antes de produzir muitas fases. Os problemas aparecem cedo.
- **Prototipe em greybox:** blocos `SolidBlock` e polígonos coloridos. Só troque pela arte depois que a fase for divertida assim.
- **Teste no celular desde o início** se o jogo vai para mobile: toque, desempenho e safe area costumam esconder surpresas.
- **Commits pequenos e tags frequentes:** cada tag gera builds que você pode mandar para amigos testarem.
- **Use o [IMPROVEMENTS.md](IMPROVEMENTS.md) como backlog:** ele já lista os próximos passos naturais (portas por habilidade, salas, minimapa, novos inimigos, ícones de botão, AAB…).

### Arquitetura (o que mantém o projeto organizado com o tempo)

- **`core/` é genérico:** nada ali sabe que seu jogo existe. Código específico do jogo vai em `game/`.
- **Organize por feature:** cena, script, arte e sons de uma coisa ficam juntos (ex.: `game/enemies/morcego/`). `assets/` é só para o que é compartilhado.
- **Call down, signal up:** o pai chama métodos dos filhos e os filhos emitem sinais. Use o `EventBus` só entre sistemas que não se conhecem, como player → HUD.
- **Composição:** antes de criar herança nova, veja se dá para resolver com os componentes que já existem (`HealthComponent`, `Hitbox`/`Hurtbox`, `HitFlashComponent`, `SquashStretch`).
- **Data-driven:** números de design ficam em `.tres`, não espalhados no código.
- **Sempre ações, nunca teclas:** isso mantém o remapeamento, o gamepad e o toque funcionando de graça.
- **Dados de fora não são confiáveis:** nunca use `ConfigFile.load()`/`str_to_var()` em arquivos que o jogador pode editar. Use `SafeConfig` e valide os tipos (veja "Segurança e performance" no [README](README.md#segurança-e-performance)).

### Usando o Claude Code no seu jogo

O `CLAUDE.md` explica a arquitetura, os comandos de teste e as armadilhas conhecidas da Godot 4.7. Pedidos que funcionam bem:

- "Adicione um inimigo voador para o platformer seguindo o padrão de `PlatformerEnemy`, com testes."
- "Crie a habilidade wall jump com pickup e teste."
- "Implemente portas que exigem habilidade, como descrito no IMPROVEMENTS."

Peça sempre para **rodar o smoke test** no fim. É a garantia de que nada quebrou.

### Mantendo o template e os jogos atualizados

Melhorou algo genérico num jogo, como um componente novo em `core/`? Leve para o template, para os próximos jogos já nascerem com isso. O caminho inverso também funciona: para trazer uma melhoria do template para um jogo em andamento:

```bash
git remote add template https://github.com/ProfTiagoBarros/2dGodotTemplate.git
```

```bash
git fetch template
```

```bash
git cherry-pick <hash-do-commit>
```

### Atualizando a versão do Godot

1. Abra o projeto na versão nova e deixe o editor reimportar tudo.
2. Atualize `GODOT_VERSION` em `.github/workflows/ci.yml`.
3. Rode o smoke test localmente e confira o CI.

---

## 9. Solução de problemas

| Problema | Solução |
|---|---|
| Erros de "Failed loading resource" ao abrir pela primeira vez ou depois de mover arquivos | Use *Project → Reload Current Project*. Se persistir, feche o Godot, apague a pasta `.godot/` e abra de novo (ela é regenerada) |
| Rodei o setup com o gênero errado | Se o projeto já estava commitado, `git checkout -- .` desfaz tudo (inclusive restaura a pasta apagada). Sem commit, restaure a pasta da **lixeira do sistema** e desfaça a mudança em `scene_paths.gd`. Depois, rode o setup de novo |
| Controles de toque não aparecem no PC | Em *Configurações → Controles de Toque*, escolha **Sempre**. Para simular toque com o mouse, ative *Project Settings → Input Devices → Pointing → Emulate Touch From Mouse* |
| Tocar na tela do celular dispara uma ação de mouse | O evento de mouse da ação precisa ter `"device":32` (mouse real) no `project.godot`, como em `attack` |
| Configurações ou atalhos "estranhos" | Apague `settings.cfg` em `%APPDATA%\Godot\app_userdata\<Nome do Projeto>\` (Windows). Os saves ficam em `saves/`, na mesma pasta |
| O smoke test passa localmente mas falha no CI de vez em quando | Algum teste checa um frame exato. Troque por espera de alguns frames (veja `_wait_for` na suíte do platformer) |
| Job do Android falhou no CI | Veja o log do passo "Exportar". Sem os 3 secrets o APK sai em modo debug, o que é normal. Com secrets, confira alias e senha |
| Erro "hides a native class" | O nome de `class_name` já existe no Godot (ex.: `Logger`, `VirtualJoystick`). Escolha outro nome |
| A tela de Configurações não cabe | Já tem rolagem; ao adicionar muitas opções, mantenha os controles dentro do `Scroll` |
| Quero ver os erros no celular | Use um build de debug e abra o console com 3 dedos |

---

## 10. Checklist rápido de jogo novo

- [ ] **Use this template** → clonar → abrir no Godot 4.7 → **F5** funciona
- [ ] `tools/setup_genre.gd` com o gênero → **File → Run** → **Reload Current Project**
- [ ] Smoke test passa localmente
- [ ] Nome do projeto, `GAME_TITLE`, ícone, versão inicial
- [ ] `package/unique_name` e `package/name` do Android
- [ ] `GAME_SLUG` no CI
- [ ] README com a descrição do jogo, badges, `LICENSE`, `CHANGELOG.md` e `CODEOWNERS` do jogo
- [ ] Primeiro commit e push → CI verde na aba Actions
- [ ] GitHub configurado: Advanced Security (vulnerabilidades + Dependabot), ruleset da `main`, descrição e tópicos ([Passo 6](#passo-6-configurar-o-repositório-no-github-uma-vez-por-repositório))
- [ ] (Se for publicar no Android) keystore de release + 3 secrets no GitHub
- [ ] Primeira fase própria em `ScenePaths.FIRST_LEVEL`
- [ ] Primeira tag `v0.1.0` → Release com os builds
