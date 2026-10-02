---
name: efficient-engineering
description: Resolve mudanças de engenharia no ProjectNBX pela menor solução correta, reduzindo etapas, perguntas, abstrações e refatorações desnecessárias.
---

# Engenharia eficiente

Use para bugs, pequenas funcionalidades, manutenção e decisões de implementação.

1. Defina o resultado observável pedido e localize a causa ou ponto de extensão antes de alterar arquivos.
2. Procure uma função, padrão, dependência ou componente já existente que resolva o caso. Prefira completar ou corrigir esse caminho a criar outro.
3. Escolha a menor mudança que atende ao requisito e preserva compatibilidade. Evite refatorar vizinhanças, antecipar requisitos, criar camadas genéricas ou adicionar dependências sem necessidade demonstrável.
4. Para um defeito simples, siga o dado ou evento até a falha, corrija a origem e confira os casos próximos. Não ofereça listas de opções quando houver uma solução direta apoiada no código.
5. Faça perguntas apenas quando uma informação não recuperável do projeto for indispensável e mudar materialmente a solução. Se houver um padrão estabelecido, aplique-o sem confirmar de novo.
6. Preserve alterações preexistentes. Examine antes o diff e não resolva conflitos fora do escopo.
7. Explique o raciocínio durante a execução só quando uma descoberta mudar o plano ou exigir decisão. Ao concluir, resuma resultado, arquivos relevantes e limitações reais sem narrar cada passo.
