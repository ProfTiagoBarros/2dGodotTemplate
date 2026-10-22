# Guia de revisão de código e arquitetura

**Português** · [English](REVIEW_GUIDE.en.md)

Este guia orienta quem **escreve** e quem **revisa** código neste template ou em jogos criados a partir dele. Ele reúne as boas práticas da documentação oficial do Godot, os padrões de projeto mais usados em jogos e as regras que este projeto aprendeu na prática (muitas vieram de defeitos reais, todos cobertos por teste).

Use junto com o [CONTRIBUTING.md](CONTRIBUTING.md) (fluxo de PR) e o [README.md](README.md#arquitetura) (visão da arquitetura).

## Sumário

1. [Como revisar](#1-como-revisar)
2. [Princípios gerais](#2-princípios-gerais)
3. [Arquitetura deste template](#3-arquitetura-deste-template)
4. [Boas práticas no Godot](#4-boas-práticas-no-godot)
5. [Padrões de projeto para jogos](#5-padrões-de-projeto-para-jogos)
6. [Constantes, literais e números mágicos](#6-constantes-literais-e-números-mágicos)
7. [Performance (PC e celular)](#7-performance-pc-e-celular)
8. [Segurança](#8-segurança)
9. [Robustez e ciclo de vida](#9-robustez-e-ciclo-de-vida)
10. [Testes](#10-testes)
11. [Documentação e Git](#11-documentação-e-git)
12. [Checklist rápido](#12-checklist-rápido)
13. [Referências](#13-referências)

---

## 1. Como revisar

**Ordem de leitura:** primeiro o *porquê* (descrição do PR, issue), depois a **arquitetura** (onde o código mora e quem depende de quem), e só então os detalhes linha a linha. Um bug de estrutura custa mais caro que um nome ruim.

**Classifique cada comentário**, para o autor saber o que é obrigatório:

| Nível | Significado | Exemplos |
|---|---|---|
| 🔴 **Bloqueante** | Não pode entrar assim | Quebra a regra dos módulos, dado de `user://` sem validação, teste falhando, vazamento de pausa/input |
| 🟡 **Importante** | Deve ser corrigido, ou justificado no PR | Código duplicado, literal no lugar de constante, falta de teste para o caso novo |
| 🟢 **Sugestão** | Melhoria opcional | Nome mais claro, simplificação, comentário |

**Boas práticas de revisão:**

- Revise PRs pequenos (até ~400 linhas). Peça para dividir os maiores.
- Comente o código, não a pessoa. Explique o motivo e, se possível, sugira a alternativa.
- Rode o projeto quando a mudança for de gameplay ou game feel: o teste prova que funciona, mas só jogando dá para saber se ficou *bom*.
- Todo bug corrigido precisa de um **teste de regressão** que falhava antes da correção.
- Código gerado por IA passa pela mesma revisão. Quem abre o PR responde por ele.

## 2. Princípios gerais

| Princípio | O que observar na revisão |
|---|---|
| **Alta coesão** | Cada script tem **uma** responsabilidade clara. Se a descrição precisa de "e", talvez sejam duas classes ou um componente novo. |
| **Baixo acoplamento** | Um sistema conhece o mínimo dos outros. Prefira sinais e interfaces pequenas a acessar campos internos (`_algo`) de outro nó. |
| **Composição antes de herança** | Capacidades (vida, hitbox, flash) são **componentes**. Herança só para um *ciclo de vida* comum e numa hierarquia **rasa** (no máximo 2–3 níveis). |
| **DRY com bom senso** | Duplicou a mesma lógica pela **segunda** vez em lugares que devem evoluir juntos? Extraia. Semelhança acidental (que vai divergir) pode ficar duplicada. |
| **KISS / YAGNI** | Não crie abstração, opção ou sistema "para o futuro". Ideia boa sem uso agora vai para o `IMPROVEMENTS.md`. |
| **Lei de Deméter** | Evite cadeias como `get_parent().get_parent().player.health.current`. Peça ao objeto o que você precisa ou ouça um sinal. |
| **Falhar cedo e alto** | Erro de digitação deve virar **erro de compilação** (constantes, tipos, `@abstract`), não um bug silencioso em produção. |
| **Princípio aberto/fechado** | Para adicionar um gênero, inimigo ou estado, você **cria** arquivos; não precisa editar o núcleo. |

## 3. Arquitetura deste template

São regras do projeto. Quebrar qualquer uma delas é 🔴 bloqueante, a menos que o PR mude a regra (e a documentação) de propósito.

- **Fronteira dos módulos:** `core/`, `ui/`, `autoloads/` e a raiz de `game/` **nunca** referenciam `game/platformer/` nem `game/topdown/`. Os módulos se conectam só por `ScenePaths.FIRST_LEVEL` e pelos exports de `Level`.
- **`core/` é agnóstico de jogo:** nada de player, inimigo ou fase ali dentro. Se precisou, o código pertence a `game/`.
- **Call down, signal up:** o pai chama métodos dos filhos; os filhos emitem sinais. O `EventBus` serve só para sistemas que **não se conhecem** (ex.: HUD ↔ player). Ele não substitui uma referência direta legítima.
- **Autoloads são poucos e de responsabilidade única.** Antes de criar um, pergunte: "isto precisa existir em todas as cenas, o tempo todo?". Se não, é um nó na cena ou uma classe estática. A ordem em `project.godot` importa.
- **Personagens:** `Character` → `PlayerCharacter` / `Enemy` concentram o ciclo de combate (Template Method). Personagens concretos implementam só os ganchos `@abstract` e o movimento. Lógica de dano, morte ou habilidades duplicada num personagem concreto é 🟡.
- **Estados decidem transições; o personagem expõe primitivas** (`jump()`, `apply_movement()`…). Estado que mexe em detalhes internos do personagem, ou personagem que decide qual é o próximo estado, é cheiro de acoplamento.
- **Dados em `Resource`s** (`PlatformerStats`, `EnemyStats`): números de balanceamento ficam em `.tres`, não no código.
- **Pausa só pelo `PauseController`**, troca de cena só pelo `SceneLoader`, logs só pelo `Log`.
- **Novo gênero/módulo:** registre em `GENRES` (`tools/genre_setup.gd`) e em `GENRE_SUITES` (`tests/smoke_test.gd`), com prefixo de gênero nos `class_name`.

## 4. Boas práticas no Godot

### GDScript

- **Tipagem estática em tudo**, inclusive variáveis de laço (`for enemy: Enemy in ...`) e retornos. O aviso `untyped_declaration` está ligado.
- Siga o [guia de estilo oficial](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): ordem `signal` → `enum` → `const` → `@export` → `var` → `@onready` → métodos; `snake_case` para funções e variáveis, `PascalCase` para classes, `CONSTANT_CASE` para constantes.
- Membros privados começam com `_`. Não acesse `_membro` de outro script; crie uma API pública.
- Use `@abstract` em classes e métodos que **precisam** ser implementados: o editor recusa a subclasse incompleta.
- Prefira `StringName` (`&"x"`) para nomes usados como identificador, e sempre por meio de constante (veja a [seção 6](#6-constantes-literais-e-números-mágicos)).
- Duck typing (`has_method`, `call(&"x")`, `get(&"x")`) só quando não existe tipo comum possível. Se existe uma base (`PlayerCharacter`, `Enemy`), use `as Tipo` e acesse diretamente.
- Comentários explicam o **porquê**; o código mostra o *como*. Comentário que só repete o código é ruído.

### Cenas e nós

- **Cenas autocontidas:** uma cena deve funcionar sozinha (F6) ou depender só do que declara em `@export`. Evite `get_parent()` e caminhos absolutos (`/root/...`).
- Referências na mesma cena com `%NomeUnico` ou `@onready var x := $Caminho`. Referências a outras cenas via `@export` (com `node_paths` no `.tscn`).
- **Escolha certa de base:** `Node` para lógica sem posição, `Node2D` para coisas no mundo, `Control` para UI, `Resource` para dados, `RefCounted`/classe estática para utilitários sem árvore.
- Grupos para "todos os X" (inimigos, `persist`), sempre com `Groups.*`.
- Ao mover scripts, mova junto os `.gd.uid`.

### Processamento e física

- Movimento e física em `_physics_process`; visual e UI em `_process`. Sempre multiplique por `delta`.
- Desligue o que não precisa rodar: `set_process(false)` / `set_physics_process(false)` (ex.: `HurtboxComponent` dorme até alguém encostar).
- Com **physics interpolation** ligada, mova corpos só no passo de física e use `reset_physics_interpolation()` em teleportes.
- Consultas caras (raycasts, buscas em grupo) com cadência, não todo frame (ex.: percepção dos inimigos a 10 Hz com fase aleatória).
- Camadas de colisão pelas constantes de `PhysicsLayers`, nunca por número.

### Sinais, `await` e tweens

- Conecte sinais em código com `Callable` tipado (`health.died.connect(_on_died)`), não por nome em texto.
- Depois de um `await`, o nó pode ter sido liberado: cheque `is_instance_valid(self)`/`is_inside_tree()` quando a espera for longa.
- Tween que anima uma propriedade compartilhada é **guardado e morto** antes de criar outro (`_music_tween`, `_health_tween`).
- Timers e tweens que dependem de tempo real (hitstop) usam `Time.get_ticks_msec()`, porque `Engine.time_scale` muda.

### Input e UI

- Gameplay lê só **ações** (`Actions.*`), nunca teclas. Texto de UI é chave de tradução.
- Botões do mouse com `device = InputEvent.DEVICE_ID_MOUSE`, senão cada toque no celular dispara a ação.
- Use `_unhandled_input` para gameplay, para a UI consumir o evento antes.
- Toda tela precisa funcionar **com gamepad** (foco inicial, sem foco vazando para trás de overlays) e **com toque** (área de toque generosa, `SafeAreaMargin`).

## 5. Padrões de projeto para jogos

Baseado em *Game Programming Patterns* (Robert Nystrom) e em como o Godot já implementa vários deles. Na revisão, pergunte se o padrão **resolve um problema real** do PR. Padrão sem problema é complexidade gratuita.

| Padrão | Problema que resolve | No Godot / neste template | Cuidados |
|---|---|---|---|
| **State (FSM)** | Muitos `if` de "está pulando? atacando?" | `StateMachine` com um nó por estado; nomes em constantes (`PlatformerState.IDLE`) | Se os estados explodirem, considere hierarquia (HFSM) ou Behavior Tree (LimboAI/Beehave) |
| **Component** | Herança profunda e classes "deus" | `HealthComponent`, `Hitbox/Hurtbox`, `HitFlashComponent` | Componente não conhece o dono concreto; comunica por sinal |
| **Observer** | Sistemas que reagem sem se conhecer | Sinais do Godot; `EventBus` para o que é global | Não transforme o `EventBus` em lixeira; sinal local quando os dois lados se conhecem |
| **Template Method** | Mesmo fluxo, detalhes diferentes por tipo | `Character._on_damaged` → `apply_knockback()` → `_on_hurt()` | Hierarquia rasa; ganchos `@abstract` para o obrigatório |
| **Type Object / Flyweight** | Variações de inimigo/arma sem nova classe | `Resource`s (`EnemyStats`, `PlatformerStats`) compartilhados entre instâncias | Para alterar em tempo de execução, `duplicate()` ou `resource_local_to_scene` |
| **Command** | Remapeamento, replays, desfazer, IA usando o mesmo input | Ações do InputMap + `InputBindings`; `TouchButton` emite `InputEventAction` | Para replay/undo, transforme ações em objetos com `execute()`/`undo()` |
| **Object Pool** | Picos de alocação (balas, partículas) | Pool de `AudioStreamPlayer` no `AudioManager` | Só com medição no profiler; resete o estado ao reusar |
| **Service Locator / Singleton** | Acesso global a serviços | Autoloads (`SaveSystem`, `AudioManager`) | Poucos; sem estado de gameplay escondido; testáveis por API pública |
| **Strategy** | Trocar comportamento (movimento, mira, IA) | Subclasses de `Enemy` trocam só o movimento; fontes de mira do top-down | Se a troca for em tempo de execução, prefira um nó/recurso plugável a `match` crescente |
| **Event Queue** | Desacoplar no *tempo* (tocar som no próximo frame, efeitos em lote) | `call_deferred`, `ConsoleLogger` drenado em `_process` | Cuidado com ordem e com objetos liberados antes de processar |
| **Update Method / Game Loop** | Cada objeto se atualiza a cada frame | `_process` / `_physics_process` | Ordem pai antes de filho; desligue quando ocioso |
| **Dirty Flag** | Recalcular só quando algo mudou | Ex.: HUD só atualiza no sinal de vida, não por frame | Garanta que todo caminho de mudança marque o "sujo" |
| **Data Locality** | Muitos objetos idênticos (milhares) | `MultiMeshInstance2D`, `PhysicsServer2D` direto | Só depois de medir; complica o código |

## 6. Constantes, literais e números mágicos

Texto ou número que **identifica** algo, ou que precisa ser igual em dois lugares, vira constante. Assim, um erro de digitação vira erro de compilação, e renomear é seguro.

| O quê | Onde fica a constante | Exemplo |
|---|---|---|
| Ações do InputMap | `Actions` (`core/constants/actions.gd`) | `Input.is_action_pressed(Actions.JUMP)` |
| Grupos | `Groups` (`core/constants/groups.gd`) | `get_first_node_in_group(Groups.PLAYER)` |
| Caminhos de cena | `ScenePaths` | `SceneLoader.change_scene(ScenePaths.MAIN_MENU)` |
| Camadas de física | `PhysicsLayers` | `PhysicsLayers.WORLD` |
| Nomes de estado | Classe base dos estados | `transition_to(EnemyState.HURT)` |
| Seções/chaves de configuração | `Settings` | `Settings.get_value(Settings.GAME, Settings.HITSTOP)` |
| Chaves de save | Na classe dona do dado | `PlayerCharacter.ABILITIES_SAVE_KEY` |
| Habilidades | No player do gênero | `PlatformerPlayer.ABILITY_DASH` |
| Uniforms de shader | No script que usa o shader | `HitFlashComponent.FLASH_AMOUNT` |
| Buses de áudio | `AudioManager` | `AudioManager.MUSIC_BUS` |

**Números:**

- **Balanceamento** (velocidade, dano, tempos, alcance) fica em `Resource` (`*Stats.tres`) ou `@export`, nunca no meio do código.
- **Game feel** ajustável (tremor, hitstop, alturas) fica em `@export`, com `@export_range` e um comentário de unidade (s, px, px/s).
- Pode ficar literal: valores **óbvios** (`0.0`, `1.0`, `0.5` para metade, `Vector2.ZERO`) e ajustes visuais usados **uma vez**, perto de um comentário. Quando o mesmo valor aparecer em dois lugares, ou alguém precisar ajustá-lo no editor, promova.

**Exceções aceitas:**

- `tools/genre_setup.gd` usa texto puro porque precisa rodar sem dependências do jogo (modo `-s`).
- Chaves de tradução (`"UI_PLAY"`) vivem no CSV, que já é a fonte da verdade.
- Caminhos de propriedade em tweens (`"modulate:a"`) são API do Godot.

## 7. Performance (PC e celular)

- **Meça antes de otimizar:** use o *Profiler*, os *Monitors* e o overlay de debug (F3). Otimização sem medição é 🟢 no máximo.
- **Nada de alocação por frame** em código quente: não crie `Array`/`Dictionary`/`String` formatada dentro de `_physics_process` sem necessidade.
- Não chame `get_tree().get_nodes_in_group()` nem `find_child()` a cada frame; guarde a referência ou use sinal.
- Pooling para objetos frequentes (projéteis, efeitos). `queue_free()` em massa no mesmo frame causa picos.
- Renderer **Compatibility** (celular): prefira `CPUParticles2D`, poucos shaders, texturas em atlas, e evite transparência sobreposta em tela cheia.
- Desligue `_process` de quem está parado; use `VisibleOnScreenEnabler2D` para inimigos fora da tela.
- Logs: `Log.debug` com `%` formata a string mesmo quando o nível está desligado; em código quente, cheque o nível antes.
- Teste em **celular de entrada** e meça tempo de carregamento (o `SceneLoader` carrega em thread).

## 8. Segurança

- Tudo que vem de `user://`, de download ou do jogador é **não confiável**.
  - **Nunca** use `ConfigFile.load/parse`, `str_to_var` ou `bytes_to_var` nesses dados: eles constroem objetos e podem executar código. Use `SafeConfig`.
  - Saves são JSON (sem execução de código), mas valide **tipos e intervalos** (`SaveSystem.get_int()`, `is Array`).
- Mudou o formato do save? Aumente `SAVE_VERSION` e escreva a migração em `_migrate()` com teste.
- Ferramentas de debug só existem em `OS.is_debug_build()`. Cheats e console nunca vão para o Release.
- Sem segredos no repositório: keystore e senhas só por variável de ambiente/secrets do CI.
- CI: `permissions: contents: read`, actions de terceiros fixadas por SHA, nada de `${{ inputs.* }}` dentro de `run:`.
- Multiplayer (quando houver): o servidor nunca confia no cliente; valide toda RPC.

## 9. Robustez e ciclo de vida

- **Nada de `assert` para validação em tempo de execução:** ele some no build de release. Valide, registre com `Log.error` e use um fallback.
- Quem "segura" algo (pausa, ação de input, música) **libera em `_exit_tree`** ou `NOTIFICATION_EXIT_TREE`.
- Subclasses chamam `super._ready()` (o Godot 4 não chama o `_ready` do pai sozinho quando você o sobrescreve).
- Liberar nós com `queue_free()`, não `free()`, durante física ou sinais.
- Desligue colisões com `set_deferred` dentro de callbacks de física.
- Interrompeu uma ação no meio (ex.: windup cortado por dano)? Garanta que tweens e flags dela sejam desfeitos.

## 10. Testes

- **Todo gameplay novo tem teste** na suíte do gênero (`game/<gênero>/tests/`) ou em `tests/smoke_test.gd`. Todo bug corrigido tem teste de regressão.
- Testes rodam como **cena**, não com `-s`.
- Sem verificação presa a um frame exato: use espera com condição (`_wait_for`) e lembre que `physics_frame` dispara **antes** do `_physics_process` dos nós.
- Timing de game feel em **tempo real** (`real_seconds()`), porque o hitstop altera `time_scale`.
- Testes não sujam dados do jogador: slot de save de teste e snapshot/restauração dos atalhos.
- Teste também os dois setups de gênero numa **cópia** do projeto quando mexer em algo compartilhado.

## 11. Documentação e Git

- Docs nos **dois idiomas** (README/MANUAL/este guia), com os links de idioma funcionando.
- Mudança visível ao usuário vai para o `CHANGELOG.md` (*Não lançado*). Item do backlog implementado é marcado no `IMPROVEMENTS.md`.
- Commits pequenos, no imperativo, explicando o porquê. Uso de IA indicado no trailer `Co-Authored-By`.
- Nunca faça `git add -A` às cegas: confira o `git status` e não suba arquivos pessoais ou gerados (`.godot/`, builds, `.aseprite` de rascunho).

## 12. Checklist rápido

Copie para o PR, se quiser:

```markdown
### Arquitetura
- [ ] Regra dos módulos respeitada (core/ui/autoloads/raiz de game não referenciam gêneros)
- [ ] Responsabilidade única; sem lógica duplicada que deveria estar em Character/componente
- [ ] Call down, signal up; EventBus só entre sistemas que não se conhecem
- [ ] Sem autoload novo sem necessidade real

### Código
- [ ] Tipagem estática completa; sem acesso a membros `_privados` de outros scripts
- [ ] Sem literais de identificador (ações, grupos, estados, configurações, chaves de save)
- [ ] Números de balanceamento em Resource/@export
- [ ] Sem duck typing quando existe uma base comum

### Robustez e segurança
- [ ] Dados de fora validados (SafeConfig, tipos); sem assert para validação
- [ ] Pausa/input/tweens liberados ao sair da árvore
- [ ] Nada de debug/cheat em release

### Performance
- [ ] Sem alocação ou busca em grupo por frame em código quente
- [ ] Processamento desligado quando ocioso

### Testes e docs
- [ ] Teste novo (ou de regressão) e smoke test passando
- [ ] Docs PT/EN, CHANGELOG e IMPROVEMENTS atualizados
```

## 13. Referências

- Documentação do Godot: [Boas práticas](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html) (organização de cenas, autoloads vs. nós, quando usar cenas ou scripts, preferências de lógica), [Guia de estilo do GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), [Tipagem estática](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html), [Otimização](https://docs.godotengine.org/en/stable/tutorials/performance/index.html) e [Physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/index.html).
- Robert Nystrom, *Game Programming Patterns* ([gameprogrammingpatterns.com](https://gameprogrammingpatterns.com), leitura gratuita).
- Google, [*Code Review Developer Guide*](https://google.github.io/eng-practices/review/): como revisar e como receber revisão.
- GDQuest, guias e tutoriais de arquitetura em Godot ([gdquest.com](https://www.gdquest.com)).
