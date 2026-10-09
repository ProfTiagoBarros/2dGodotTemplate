# Política de segurança / Security policy

**Português** · [English](#english)

## Versões suportadas

Correções de segurança são feitas na versão mais recente (`main` e última tag `v*`).

## Como reportar uma vulnerabilidade

**Não abra issue pública.** Use o reporte privado do GitHub: aba **Security → Report a vulnerability** neste repositório.

Inclua, se possível:
- descrição do problema e impacto (ex.: execução de código, corrupção de save, vazamento de secrets no CI);
- passos para reproduzir ou um arquivo de exemplo;
- versão do Godot e plataforma.

Você deve receber uma resposta em até 7 dias. Depois de corrigido, o problema é registrado no `CHANGELOG.md` com crédito a quem reportou, se desejar.

## Escopo

- Código do template (`autoloads/`, `core/`, `game/`, `ui/`, `tools/`).
- Workflows e actions do CI (`.github/`).
- Fora do escopo: vulnerabilidades do próprio Godot. Reporte essas em <https://github.com/godotengine/godot/security>.

## Boas práticas já adotadas

Veja a seção [Segurança e performance](README.md#segurança-e-performance) do README.

---

## English

**Supported versions:** security fixes target the latest version (`main` and the latest `v*` tag).

**Reporting:** **do not open a public issue.** Use GitHub's private reporting: **Security → Report a vulnerability** in this repository. Please include the impact, steps to reproduce (or a sample file), and the Godot version and platform. Expect a reply within 7 days. Fixes are recorded in `CHANGELOG.md`, crediting the reporter if they wish.

**Scope:** template code (`autoloads/`, `core/`, `game/`, `ui/`, `tools/`) and CI (`.github/`). Godot engine vulnerabilities should be reported to <https://github.com/godotengine/godot/security>.

**Practices already in place:** see [Security and performance](README.en.md#security-and-performance).
