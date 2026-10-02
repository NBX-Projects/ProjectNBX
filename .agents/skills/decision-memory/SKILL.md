---
name: decision-memory
description: Registra e recupera decisões duradouras, restrições e convenções confirmadas do ProjectNBX para evitar redescobrir ou perguntar novamente o mesmo contexto.
---

# Memória de decisões

Use quando uma tarefa revelar uma decisão reutilizável, uma convenção confirmada ou uma correção que deva orientar trabalho futuro.

## Consultar

- Leia `docs/agent/DECISIONS.md` quando a decisão puder afetar a tarefa atual.
- Verifique no código e nas instruções pertinentes se a entrada continua válida. Trate o arquivo como índice conciso, não como autoridade acima do código atual ou de uma instrução mais específica.
- Reuse a decisão aplicável sem pedir ao usuário que repita o que já foi estabelecido.

## Registrar

- Registre uma decisão somente após estar confirmada pelo usuário, pelas instruções existentes ou por uma implementação explícita e estável. Não transforme inferência ou escolha transitória em regra do projeto.
- Acrescente uma entrada curta ao `docs/agent/DECISIONS.md` com data, contexto, decisão, consequência e evidência/caminho relevante. Use `A confirmar` se o usuário ainda precisa decidir; não a trate como decisão aprovada.
- Atualize ou marque uma entrada como superada quando houver mudança de direção; preserve o histórico mínimo necessário para entender a mudança.
- Não copie documentação extensa nem repita todas as decisões em `AGENTS.md`. Referencie o arquivo nos pontos em que o contexto persistente é útil.
