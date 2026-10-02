# Antigravity no ProjectNBX

Este repositório usa o mecanismo nativo de personalização do Antigravity:

- `rules/projectnbx.md`: regra curta carregada em todas as tarefas deste projeto.
- `skills/*/SKILL.md`: procedimentos especializados carregados quando relevantes.
- `../AGENTS.md`: fonte principal das convenções e da arquitetura do projeto.
- `../docs/agent/DECISIONS.md`: registro conciso de decisões confirmadas e duradouras.

As skills cobrem contexto e exploração, engenharia eficiente, UI/UX Flutter e reutilização, verificação e memória de decisões. O agente deve consultar o código atual e preservar as instruções já existentes; este pacote complementa `AGENTS.md`, não o substitui.

Antigravity descobre as regras do projeto em `.agents/rules/` e as skills em `.agents/skills/`. Se a interface já estava aberta quando estes arquivos foram adicionados, reabra ou atualize o projeto para recarregar as personalizações e confira a seção de skills nas customizações do workspace.
