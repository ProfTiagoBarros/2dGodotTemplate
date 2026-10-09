# Contribuindo

**Português** · [English](#english)

Obrigado pelo interesse! Este template busca ser uma base enxuta, testada e bem documentada para jogos 2D em Godot.

## Fluxo

1. **Abra uma issue** antes de mudanças grandes, usando os modelos de bug ou de sugestão, para alinharmos a ideia.
2. Crie uma branch a partir da `main` (ex.: `feat/inimigo-voador`, `fix/pulo-duplo`).
3. Faça a mudança seguindo as convenções abaixo.
4. Rode o smoke test e garanta que passa:
   ```bash
   godot --headless --path . res://tests/smoke_test.tscn
   ```
5. Abra o Pull Request e preencha o checklist do modelo.

## Convenções

- Siga o [guia de estilo oficial do GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), com **tipagem estática** em tudo.
- Respeite a **regra dos módulos**: `core/`, `ui/`, `autoloads/` e a raiz de `game/` nunca referenciam `game/platformer/` nem `game/topdown/`.
- Código novo de gameplay vem com **teste** na suíte do gênero (`game/<gênero>/tests/`) ou no runner geral (`tests/smoke_test.gd`).
- Textos de interface são **chaves de tradução** em `localization/translations.csv`, em inglês e português.
- Dados vindos de fora (`user://`, arquivos do jogador) são **não confiáveis**: use `SafeConfig` e valide os tipos. Nunca use `ConfigFile.load()` nem `str_to_var()` neles.
- Atualize a documentação afetada (`README`/`MANUAL` nos **dois idiomas**, `CLAUDE.md`, `IMPROVEMENTS.md`) e registre a mudança em `CHANGELOG.md`, na seção *Não lançado*.
- Mensagens de commit no imperativo e descritivas (ex.: "Adiciona inimigo voador ao platformer").
- Mudanças no CI: valide com o [actionlint](https://github.com/rhysd/actionlint) antes do PR.

## Contribuições com IA

Contribuições feitas com ajuda de IA são bem-vindas, nas mesmas condições de qualquer outra: você é responsável por entender, revisar e testar o código. Indique o uso no PR, e no commit quando fizer sentido (ex.: trailer `Co-Authored-By`). O arquivo `CLAUDE.md` orienta assistentes de código sobre a arquitetura do projeto.

## Segurança

**Não abra issue pública para vulnerabilidades.** Veja o [SECURITY.md](SECURITY.md).

---

## English

Thanks for your interest! This template aims to be a lean, tested and well-documented base for 2D Godot games.

1. **Open an issue** before large changes, using the bug or feature templates.
2. Branch from `main` (e.g. `feat/flying-enemy`, `fix/double-jump`).
3. Follow the conventions above. In short: static typing, the module rule, tests for new gameplay, translation keys for UI text, untrusted outside data (use `SafeConfig`), and docs updated in **both languages** plus the `CHANGELOG.md` *Unreleased* section.
4. Make sure the smoke test passes: `godot --headless --path . res://tests/smoke_test.tscn`.
5. Open a Pull Request and fill in the template checklist.

AI-assisted contributions are welcome under the same terms: you are responsible for understanding, reviewing and testing the code, and should mention the AI use in the PR. For vulnerabilities, see [SECURITY.md](SECURITY.md); don't open public issues.
