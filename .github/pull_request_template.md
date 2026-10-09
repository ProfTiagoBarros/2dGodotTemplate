## O que muda / What changes

<!-- Descreva a mudança e o motivo. Referencie a issue: "Closes #123". -->
<!-- Describe the change and why. Reference the issue: "Closes #123". -->

## Checklist

- [ ] Smoke test passa / Smoke test passes: `godot --headless --path . res://tests/smoke_test.tscn`
- [ ] Testes novos para gameplay novo / New tests for new gameplay
- [ ] Regra dos módulos respeitada (`core/`, `ui/`, `autoloads/` e a raiz de `game/` não referenciam os módulos de gênero) / Module rule respected
- [ ] Dados de fora validados (`SafeConfig`, checagem de tipos) / Outside data validated
- [ ] Docs atualizadas nos dois idiomas (README/MANUAL) e `CHANGELOG.md` (*Não lançado*) / Docs updated in both languages and `CHANGELOG.md` (*Unreleased*)
- [ ] Mudanças no CI validadas com o actionlint / CI changes validated with actionlint

## Uso de IA / AI usage

<!-- Usou assistente de IA? Diga qual e como revisou o resultado. -->
<!-- Used an AI assistant? Say which one and how you reviewed the output. -->
- [ ] Não / No
- [ ] Sim, revisei e testei o código gerado / Yes, I reviewed and tested the generated code
