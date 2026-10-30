# Changelog

Todas as mudanças relevantes deste template são registradas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), versionamento [SemVer](https://semver.org/lang/pt-BR/).

*All notable changes are recorded here (in Portuguese). Format: Keep a Changelog; versioning: SemVer.*

## [Não lançado]

### Adicionado

- Arte de jogo gerada com o PixelLab no tema Template Chronicles: herói animado (platformer 32×48 e top-down 32×32 em 8 direções), androide e slime animados, tilesets de telhado cyberpunk e de rua, objetos (alvo de treino, orbe de habilidade, espinhos, colunas) e decoração.
- Fases novas para os dois gêneros: telhados com plataformas, plataforma alta para o pulo duplo, escadaria e fundo em parallax; rua com calçadas e praça no top-down.
- `DualGridTerrain`: desenha tilesets de cantos (formato do PixelLab) a partir de uma camada lógica pintada à mão, com colisão alinhada à arte.
- Animação por estado na `Character`: cada estado toca a animação de mesmo nome; o top-down escolhe a direção pela mira e espelha o lado oeste.
- `tools/import_frames.gd`: importa pastas de quadros (PixelLab, Aseprite…) como tiras PNG e `SpriteFrames`.
- `Level.camera_limits`: a câmera não sai do cenário.
- Testes de gênero leem posições de marcadores (`TestMarkers`) da fase em vez de coordenadas fixas.
- Skin de interface **Template Chronicles** (cyberpunk com toque de fantasia): o tema global monta botões, painéis, barras, sliders e chaves a partir dos PNGs de `assets/ui/`, então trocar os arquivos muda o visual de todas as telas. Inclui fundo do menu e emblema gerados no Canva, título com contorno neon, painel no menu de pausa e o gerador `tools/generate_ui_skin.gd`. O título do menu passa a ser "Template Chronicles".
- Assistente de novo jogo: **Project → Tools → Configurar novo jogo…** pergunta nome, tipo de jogo (platformer, top-down ou só a base), plataformas e como tratar as docs, e configura o projeto (módulos, presets de exportação, CI, título, README/CHANGELOG do jogo e `CLAUDE.md` enxuto). Também disponível por linha de comando (`tools/setup_project_cli.gd`, com `--dry-run`).
- Opção **só a base** no setup de gênero: remove os módulos e cria uma fase vazia, para jogos de outros gêneros.
- MANUAL: quando vale usar o template ou começar do zero, o caso dos jogos 3D, dicas para gastar menos tokens com o Claude Code e uma receita completa de exemplo (do repositório vazio ao primeiro build).
- `REVIEW_GUIDE.md` (PT/EN): guia de revisão de código e arquitetura, com princípios, boas práticas do Godot, padrões de projeto para jogos e checklist de PR.
- `PauseController` (`core/utils/`): pausa coordenada por motivos (menu, console…). O jogo só despausa quando nenhum sistema pede pausa.

### Alterado

- Player do platformer passa a 32×48 e o do top-down a 32×32. Movimento, pulo, dash, hitboxes, câmera e números dos inimigos foram escalados junto.
- Código duplicado entre players e inimigos extraído para as classes abstratas `Character` e `PlayerCharacter` (`game/characters/`). `PlatformerPlayer`, `TopDownPlayer` e `Enemy` agora só implementam movimento e os ganchos `@abstract` (`apply_knockback`, `get_facing_vector`, `_play_death`); esquecer um deles é erro de compilação. Tremor e hitstop de combate viraram propriedades exportadas (`hurt_shake`, `hit_hitstop`…).
- Nomes de ações e grupos agora são constantes (`Actions.JUMP`, `Groups.PLAYER`…, em `core/constants/`). O smoke test falha se o InputMap tiver ação fora de `Actions.ALL`.
- `SaveSystem.PERSIST_GROUP` foi removido; use `Groups.PERSIST`.
- O sistema de habilidades saiu do `PlatformerPlayer` para o `PlayerCharacter` e vale para qualquer gênero. A chave do save passou a ser `abilities` (save v2); saves v1 são migrados automaticamente. `AbilityPickup` e os comandos de debug agora usam tipos (`PlayerCharacter`/`Enemy`) em vez de duck typing.
- Seções e chaves de configuração viraram constantes (`Settings.GAME`, `Settings.HITSTOP`…), assim como nomes de estado, uniforms de shader e buses de áudio. `Enemy` ganhou `eye_height` e `death_shake` exportados no lugar de números fixos.
- `Enemy` passou a ser `@abstract`: `patrol_direction`, `direction_to_target` e `move_toward_direction` são obrigatórios nas subclasses.

### Corrigido

- A HUD mostrava a barra de vida mesmo sem player na fase; agora ela aparece quando um player anuncia a vida.
- `HurtboxComponent` gerava erro do engine ("Can't find overlapping areas when monitoring is off") no frame em que um inimigo morria.

Encontrados na revisão de arquitetura; todos reproduzidos antes da correção e cobertos por teste:

- Fechar o console de debug despausava o jogo com o menu de pausa aberto.
- Crossfade de música em sequência rápida (A → B → A) deixava o jogo mudo.
- Botão de toque removido com o dedo na tela deixava a ação pressionada para sempre.
- Fase inválida derrubava o jogo em builds de release (dependia de `assert`); agora registra o erro e volta ao menu.
- `StateMachine` quebrava com transição antes de inicializar e embaralhava transições pedidas dentro de `enter()`/`exit()`.
- `HitFlashComponent` descartava o shader próprio dos filhos (contorno, paleta…).
- Save com `version` adulterada gerava erro na migração; save de versão mais nova agora gera aviso.
- Barra de vida com animações sobrepostas em danos seguidos; fase inicial da percepção dos inimigos ignorava `perception_interval`.

### Segurança

- O CI não publica mais builds de debug (console e cheats) no Release; eles continuam como artifacts de teste.

## [0.1.0] - 2026-10-09

Primeira versão do template, desenvolvida com assistência de IA (Claude, da Anthropic). Veja [Créditos e uso de IA](README.md#créditos-e-uso-de-ia).

### Adicionado

- **Base:** projeto Godot 4.7 (renderer Compatibility, 640×360, physics interpolation) com organização por feature e tipagem estática.
- **Autoloads:** `Log`, `EventBus`, `Settings`, `SaveSystem` (JSON versionado, escrita atômica, `.bak`), `AudioManager`, `GameFeel`, `InputManager`, `InputBindings`, `SceneLoader` e `DebugTools`.
- **Core reutilizável:** máquina de estados baseada em nós, componentes de vida e dano com times, câmera com screen shake por trauma, utilitários.
- **Módulos de gênero:**
  - Platformer/metroidvania: pulo por altura e tempo, coyote time, jump buffer, ataque direcional com pogo, dash, pulo duplo, habilidades desbloqueáveis e salvas.
  - Top-down: 8 direções, mira twin-stick (mouse e analógico direito), dash, ataque, Y-sort.
- **Setup de gênero** (`tools/`) que mantém um módulo e remove o outro.
- **Inimigos:** base genérica com patrulha, perseguição com linha de visão, aviso, bote, recuperação e atordoamento; um tipo por gênero.
- **UI:** menus principal, de pausa, de configurações e de controles; HUD com dicas de botão; controles de toque (joystick nativo e 3 botões); safe area.
- **Remapeamento de controles** para teclado/mouse e gamepad, com nomes por layout e por família de controle.
- **Game feel:** hitstop, flash de dano por shader, squash & stretch, poeira e faíscas.
- **Ferramentas de debug:** overlay F3, console F1 com comandos, captura de toda a saída do engine.
- **Localização:** inglês e português (pt-BR).
- **Qualidade:** smoke test headless (126 verificações) e CI no GitHub Actions com builds para Windows, Linux, Web e Android e Release automático por tag.
- **Documentação:** README e MANUAL em português e inglês, `CLAUDE.md`, `IMPROVEMENTS.md`, guias de contribuição e de segurança, templates de issue e PR.

### Segurança

- `settings.cfg` lido com `SafeConfig`: o `ConfigFile` padrão permitia executar código a partir de um arquivo adulterado.
- Validação de tipos em configurações, saves e atalhos remapeados.
- CI com permissões mínimas, downloads verificados por SHA-512, action de terceiros fixada por commit, tags validadas e Dependabot.

[Não lançado]: https://github.com/ProfTiagoBarros/2dGodotTemplate/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ProfTiagoBarros/2dGodotTemplate/releases/tag/v0.1.0
