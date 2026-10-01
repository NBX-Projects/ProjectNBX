---
trigger: always_on
---

# Regras do ProjectNBX

- Antes de alterar código, consulte `AGENTS.md` e as convenções do diretório afetado. Use `README.md` e `GETTING_STARTED.md` quando o objetivo exigir contexto de produto ou execução.
- Trate o repositório e seu histórico como contexto persistente: pesquise decisões, implementações, componentes e testes existentes antes de perguntar algo que possa ser descoberto localmente. Não peça nem repita contexto já documentado; explique apenas o necessário para a tarefa atual.
- Faça mudanças focadas e compatíveis com a arquitetura real: Flutter/Dart com organização por funcionalidade e Riverpod; backend Go em `backend/`. Não introduza dependências, abstrações ou refatorações sem necessidade demonstrável.
- Preserve alterações preexistentes do usuário, inclusive arquivos staged, não staged e conflitos de merge. Não reverta, sobrescreva ou resolva trabalho que não pertence à tarefa.
- Ao criar ou mudar uma convenção/decisão duradoura, registre-a em `docs/agent/DECISIONS.md`; não registre preferências temporárias nem fatos ainda não confirmados.
- Ative as skills de contexto/exploração, engenharia eficiente, UI Flutter, verificação ou memória de decisões quando forem relevantes. Ao terminar, relate brevemente o que mudou e quais verificações foram realmente executadas.
