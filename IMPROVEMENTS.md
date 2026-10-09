# IMPROVEMENTS

Itens que ficaram fora da base do template, por dependerem de decisões do jogo, de contas/SDKs externos ou de assets. Ordenados por prioridade dentro de cada seção.

## 1. Build, exportação e CI

- [x] ~~Export presets Windows/Linux/Web/Android~~, ~~GitHub Actions (teste + export + Release)~~ e ~~versionamento pela tag~~: implementados (veja "CI, builds e releases" no README).
- [x] ~~Primeira execução real do CI~~: validada no GitHub (smoke test + export das 4 plataformas OK em ~2 min).
- [ ] **macOS e iOS**: exigem runner macOS, assinatura e notarização da Apple (conta paga de desenvolvedor).
- [ ] **Deploy automático**: itch.io via `butler` (secret `BUTLER_API_KEY`, canais `windows`/`linux`/`web`/`android`) e Play Store via `r0adkll/upload-google-play` (AAB + conta de serviço).
- [ ] **Android para a loja**: build **AAB** (exige `gradle_build/use_gradle_build=true` e o template Android instalado no projeto), ícones adaptativos (`launcher_icons/*`), splash e revisão do `target SDK`.
- [ ] **Ícone e metadados do .exe** no Windows: `application/modify_resources=true` exige `rcedit` (no CI Linux, via Wine).
- [ ] **Web com threads**: só se o jogo precisar. Exige headers `Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` no servidor.

## 2. Testes e qualidade

- [ ] Adicionar **GUT** ou **gdUnit4** (addons) para testes unitários de `HealthComponent`, `StateMachine`, `SaveSystem._migrate`, `MathUtils`.
- [ ] **gdtoolkit** (`gdlint` + `gdformat`) com hook de pre-commit.
- [ ] Promover os warnings `untyped_declaration`/`unsafe_*` a **erro** quando o time estiver confortável com tipagem estática.

## 3. Input

- [x] ~~Remapeamento de controles~~: implementado (`InputBindings` + *Configurações → Controles*).
- [ ] **Ícones gráficos de botões** no lugar do texto em `InputBindings.get_event_label` / `ActionPromptLabel`, usando um pacote como **Kenney Input Prompts** (CC0), com um mapa `evento → textura` por família (teclado, Xbox, PlayStation, Switch). Pode ser exibido em `RichTextLabel` com `[img]`.
- [ ] **Nomes de teclas traduzidos**: `OS.get_keycode_string` devolve em inglês ("Space", "Escape"). Mapear as teclas comuns para chaves de tradução.
- [ ] **Segundo slot de atalho** por dispositivo (coluna "Alternativo") na tela de Controles, e remapeamento dos eixos de mira.
- [ ] **Família do controle pelo último gamepad usado** (hoje usa o primeiro conectado) e opção manual de estilo de ícones.
- [ ] **Mira**: cursor de mira próprio (`Input.set_custom_mouse_cursor` ou sprite seguindo o mouse), aim assist leve no analógico e opção de sensibilidade/deadzone do analógico direito.
- [ ] **Vibração**: `Input.vibrate_handheld()` (mobile) e `Input.start_joy_vibration()` (gamepad), com opção para desligar.
- [ ] Pausar automaticamente quando o gamepad desconectar durante o jogo.
- [ ] Layout dos controles de toque editável pelo jogador (posição, tamanho, opacidade).

## 4. Gameplay e arquitetura

- [x] ~~Inimigo de exemplo (patrulha → persegue → windup → bote → recupera, Hurt) e times de dano~~: implementados (`game/enemies/`, `team` nos componentes).
- [ ] **Mais inimigos**: atirador (projéteis com pooling), voador (ignora gravidade, persegue em 2D no platformer), tanque com escudo frontal, spawners e um chefe com fases (FSM de alto nível trocando "padrões" de ataque).
- [ ] **IA**: evitar espinhos/buracos ao perseguir, desvio de obstáculos no top-down (`NavigationAgent2D` + `NavigationRegion2D`), aggro em grupo (um inimigo alerta os próximos).
- [ ] **Behavior Trees** para IA complexa (addons **LimboAI** ou **Beehave**). A FSM atual atende casos simples.
- [ ] **Object pooling** para projéteis e partículas frequentes.
- [ ] **Interação** (`InteractableComponent` + ação `interact`, já mapeada) e sistema de **diálogo** (addon **Dialogue Manager**, de Nathan Hoad).
- [ ] **Checkpoints** e respawn sem recarregar a cena inteira.
- [x] ~~Variante top-down do player~~: implementada como módulo `game/topdown/` + setup de gênero.
- [ ] **Top-down**: ataque com combo (encadear Attack → Attack2 com janela de input), mira por mouse/analógico direito (twin-stick) e snap opcional do `facing` para 4/8 direções conforme as animações.
- [x] ~~Platformer: ataque direcional + pogo, dash, pulo duplo e sistema de habilidades desbloqueáveis~~ (base metroidvania).
- [ ] **Platformer/metroidvania — próximas habilidades**: wall slide/wall jump, plataformas one-way (`one_way_collision`, com "descer" segurando ↓ + pulo), escadas, gancho/grapple.
- [ ] **Metroidvania — mundo**: portas/barreiras que exigem habilidade (`has_ability`), mapa por salas com transições (`Area2D` nas bordas → `SceneLoader` + ponto de entrada), minimapa revelado por sala visitada, save points/bancos e câmera com limites por sala + look-ahead horizontal.
- [ ] Animações reais: `AnimatedSprite2D`/`AnimationPlayer` acionados no `enter()` de cada estado e `AnimationTree` se a blend ficar complexa.

## 5. Arte e mundo

- [ ] **TileMapLayer** + TileSet com terrains (autotile) e física por tile, substituindo os `SolidBlock` de greybox.
- [ ] **Pipeline Aseprite**: addon **Aseprite Wizard** para importar `.aseprite` direto como `SpriteFrames`/animações.
- [ ] **Pixel-perfect opcional**: `display/window/stretch/scale_mode="integer"` ou render em `SubViewport` de baixa resolução com upscale, avaliando o efeito em telas de celular com proporções incomuns.
- [ ] **Parallax** de fundo com o nó `Parallax2D` (platformer).
- [ ] **Top-down**: TileMapLayer com Y-sort por tile (paredes/objetos altos) e `TileMapLayer` separado para o chão.
- [ ] Limites de câmera por fase (`limit_*`) definidos pelo `Level`.

## 6. Game feel ("juice")

- [x] ~~Hitstop, hit flash (shader), squash & stretch e partículas (poeira/faíscas)~~: implementados (`GameFeel`, `core/feel/`).
- [ ] **Mais juice**: partículas de morte/explosão, rastro (ghost trail) no dash, knockback nos inimigos, "freeze + zoom" em golpes finais, vibração do controle (`Input.start_joy_vibration`) sincronizada com `GameFeel.hitstop_started`, e sons de impacto.
- [ ] **Pooling de efeitos** se o jogo spawnar muitas partículas por frame (hoje cada efeito é instanciado e liberado).
- [ ] **Transições de cena com shader** (dissolve/wipe) no `SceneLoader` e **tela de loading** com barra usando `SceneLoader.load_progress`.

## 7. UI e acessibilidade

- [ ] **Theme completo**: fonte própria (pixel font com `Fixed Size` e antialiasing desligado), StyleBoxes, 9-patch e sons de UI via `AudioManager.play_ui`.
- [ ] **Acessibilidade**: escala de fonte, modo daltônico, "reduzir movimento" (o screen shake já tem opção), legendas e contraste alto.
- [ ] **Menu de seleção de slots** de save (continuar / novo jogo / apagar).
- [ ] Tela de **créditos** e de **splash** (logo do estúdio e logo do Godot).

## 8. Persistência

- [ ] **Criptografia** opcional dos saves (`FileAccess.open_encrypted_with_pass`) para jogos com economia/ranking.
- [ ] **Cloud save**: Steam Cloud, Google Play Saved Games, iCloud.
- [ ] **Autosave** em checkpoints e em `NOTIFICATION_APPLICATION_PAUSED` (mobile pode matar o app em segundo plano).
- [ ] Metadados do slot (tempo de jogo, fase, screenshot miniatura).

## 9. Plataformas e serviços

- [ ] **Steam** via **GodotSteam** (conquistas, Cloud, Steam Input, Steam Deck verificado).
- [ ] **Google Play Games / Game Center** (conquistas e leaderboards).
- [ ] **Compras in-app e anúncios** (plugins oficiais de billing do Android / StoreKit), se o modelo de negócio exigir.
- [ ] **Analytics e crash reporting** respeitando LGPD/GDPR (tela de consentimento).

## 10. Performance e ferramentas

- [x] ~~Overlay de debug, console de comandos e Log com níveis~~: implementados (`DebugTools`, `Log`, `ui/debug/`).
- [ ] **Console/overlay**: comando `screenshot`, gráfico de frame time no overlay, console "flutuante" redimensionável e salvar o conteúdo do console num arquivo para anexar em bug reports.
- [ ] **Crash/bug report remoto** em builds de teste: enviar `DebugTools.get_console_text()` + versão + dispositivo para um endpoint (ex.: Sentry, que tem SDK para Godot) com consentimento do jogador.
- [ ] Opção de **limite de FPS** (30/60/ilimitado) para economizar bateria no mobile, e `low_processor_mode` nos menus.
- [ ] Profiling em aparelhos Android de entrada (draw calls, overdraw de partículas, tamanho de texturas).
- [ ] Após o primeiro import, trocar os caminhos `res://` de `ScenePaths` por `uid://`, que sobrevivem a renomeações.

## 11. Localização

- [ ] Migrar de CSV para **gettext (.po)** se precisar de plurais ou contexto, gerando o POT pelo editor.
- [ ] Mais idiomas (es, fr, de, ja) e fontes com fallback para CJK.
