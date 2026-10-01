---
name: project-context-explorer
description: Reconstrói o contexto do ProjectNBX e pesquisa implementação, convenções, histórico e testes existentes antes de planejar mudanças ou fazer perguntas.
---

# Contexto e exploração do repositório

Use ao começar uma tarefa neste repositório, ao retomar uma área existente ou quando faltar contexto.

1. Leia `AGENTS.md` e as instruções aplicáveis no caminho do arquivo. Consulte `README.md` ou `GETTING_STARTED.md` somente quando ajudarem na questão atual.
2. Inspecione o estado do repositório e os arquivos diretamente relacionados antes de editar. Procure usos, componentes, controladores, serviços, testes e documentação próximos; siga o fluxo real em vez de inferir arquitetura pelo nome.
3. Para Flutter, reconheça a organização `lib/core` + `lib/features`, Riverpod e imports `package:projectnbx/...`. Para o serviço Go, consulte `backend/README.md`, `backend/go.mod` e os pacotes existentes relevantes.
4. Consulte `docs/agent/DECISIONS.md` para decisões registradas. Confirme se continuam válidas no código atual; o código e as instruções mais específicas do diretório resolvem divergências.
5. Verifique o histórico local apenas quando ele puder esclarecer uma decisão ou regressão concreta. Não faça uma varredura ampla sem motivo.
6. Não pergunte o que pode ser respondido por busca, documentação ou código existente. Se ainda faltar uma decisão do usuário que realmente bloqueie a tarefa, pergunte somente essa decisão e continue o trabalho independente.
7. Mantenha o contexto interno conciso. Na resposta, resuma apenas a descoberta que afeta a solução; não recite arquitetura já conhecida.

## Proteção do trabalho em andamento

- Antes de editar, identifique mudanças preexistentes nos arquivos que pretende tocar, incluindo estado staged e conflitos.
- Não sobrescreva alterações alheias, arquivos em conflito nem arquivos gerados que o usuário modificou. Se um arquivo necessário estiver em conflito, evite-o e adapte a solução; peça orientação somente se não houver alternativa segura.
- Faça a menor mudança que conclui o pedido e mantenha a formatação e os padrões locais.
