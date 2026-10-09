# Changelog

Todas as mudanças relevantes deste template são registradas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), versionamento [SemVer](https://semver.org/lang/pt-BR/).

*All notable changes are recorded here (in Portuguese). Format: Keep a Changelog; versioning: SemVer.*

## [Não lançado]

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
