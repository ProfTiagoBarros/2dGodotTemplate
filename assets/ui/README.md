# Skin da interface (assets/ui)

**Português** · [English](#english)

Todas as telas do jogo (menu, pausa, configurações, controles e HUD) usam o tema global `ui/theme/main_theme.tres`, que monta botões, painéis e barras **a partir destes PNGs**. Para trocar o visual do jogo inteiro, **substitua os arquivos mantendo o mesmo nome**. Não precisa mexer em cena nem em código.

O visual padrão é o **Template Chronicles** (cyberpunk com toque de fantasia), em pixel art para a resolução base de 640×360.

| Arquivo | Tamanho | Bordas fixas (9-slice) | Onde aparece |
|---|---|---|---|
| `menu_background.png` | 640×360 | — | Fundo do menu principal (cobre a tela, mantendo a proporção) |
| `emblem.png` | livre (~64 px de altura) | — | Emblema acima do título do menu |
| `panel.png` | 32×32 | 8 px | Painéis (configurações, controles, pausa), dropdowns e tooltips |
| `button.png` | 32×16 | 6 px | Botão normal (o desabilitado é este, escurecido) |
| `button_hover.png` | 32×16 | 6 px | Botão com o mouse em cima |
| `button_pressed.png` | 32×16 | 6 px | Botão pressionado |
| `button_focus.png` | 32×16 | 6 px | Moldura de foco (gamepad/teclado), desenhada **por cima** do texto: deixe o centro transparente |
| `bar_frame.png` | 16×8 | 3 px | Fundo da barra de vida |
| `bar_fill.png` | 8×8 | 3 px | Preenchimento da barra de vida. Os 2 px transparentes em volta são o recuo dentro da moldura |
| `slider_track.png` | 16×8 | 3 px | Trilho dos sliders de volume |
| `slider_fill.png` | 8×8 | 3 px | Parte preenchida dos sliders (mesmo recuo da `bar_fill`) |
| `slider_grabber.png` | 8×12 | — | Pegador dos sliders |
| `toggle_on.png` / `toggle_off.png` | 24×12 | — | Chave liga/desliga das opções |

## Como trocar

1. Desenhe a peça no seu editor (Aseprite, Krita, Canva…) **com o mesmo tamanho** da tabela, ou maior mantendo as bordas.
2. Salve por cima do arquivo, com o mesmo nome. O Godot reimporta sozinho.
3. Se a peça nova tiver bordas de outro tamanho, ajuste as margens (`texture_margin_*`) do StyleBox correspondente em `ui/theme/main_theme.tres` (no editor: abra o tema e clique no estilo).

**Bordas fixas (9-slice):** os cantos da imagem, até a margem indicada, nunca esticam; só o meio estica. É isso que deixa um painel pequeno virar uma janela grande sem deformar. Mantenha detalhes importantes (cantos chanfrados, brilhos) dentro das bordas.

**Pixel art nítida:** o projeto usa filtro *nearest*. Desenhe no tamanho final, sem suavização, ou com o tamanho em múltiplos inteiros.

**Cores do texto, fonte e títulos** ficam no próprio tema: `Label`, `Button` e as variações `TitleLabel` (título do menu) e `HeaderLabel` (títulos dos painéis). Para usar uma fonte própria (ex.: pixel font), defina `default_font` no tema.

## Origem das peças padrão

- **Fundo e emblema:** gerados no Canva com IA, a partir dos layouts de referência "Template Chronicles - UI Kit" (menu, HUD e configurações com camadas editáveis).
- **Painéis, botões, barras, slider e chaves:** desenhados em código por `tools/generate_ui_skin.gd`, para saírem com pixels e bordas exatas. Para recriá-los (se a pasta `tools/` ainda existir no seu projeto):
  ```bash
  godot --headless --path . -s res://tools/generate_ui_skin.gd
  ```

---

## English

All game screens (menu, pause, settings, controls and HUD) use the global theme `ui/theme/main_theme.tres`, which builds buttons, panels and bars **from these PNGs**. To reskin the whole game, **replace the files keeping the same names**; no scene or code changes needed. The table above lists each file, its size, the fixed 9-slice border (corners up to that margin never stretch) and where it appears. If a new piece has different borders, adjust the matching StyleBox `texture_margin_*` in `ui/theme/main_theme.tres`. `button_focus.png` is drawn on top of the text, so keep its center transparent. Text colors, the font and title styles (`TitleLabel`, `HeaderLabel`) live in the theme. The default background and emblem were AI-generated in Canva; the other pieces are drawn by `tools/generate_ui_skin.gd` (run it to regenerate them).
