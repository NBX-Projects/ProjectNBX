---
name: flutter-ui-ux
description: Implementa e revisa telas e componentes Flutter do ProjectNBX com foco em UI/UX, responsividade multiplataforma, acessibilidade e reutilização do design system existente.
---

# UI/UX no Flutter do ProjectNBX

Use ao criar, modificar ou revisar telas e widgets Flutter.

## Antes de implementar

- Consulte `AGENTS.md`, o tema em `lib/core/theme/` e telas/widgets semelhantes em `lib/features/`.
- Identifique componentes compartilhados, tokens de cor e tipografia, estados Riverpod e testes relevantes antes de criar código novo.
- Preserve a identidade visual documentada para os temas claro (Forest Slate) e escuro (Pastel Tech). Use cores, estilos e transições do tema; evite valores visuais avulsos ou aparência genérica.

## Interface e comportamento

- Prefira widgets e layouts que se adaptem à largura disponível, orientação e plataforma. Revise janelas estreitas e largas, overflow, rolagem, áreas seguras, redimensionamento de desktop e tamanhos de toque quando aplicável.
- Cubra estados de carregamento, vazio, erro, sucesso e interação, conforme o fluxo existente. Preserve navegação, atalhos e expectativas da plataforma.
- Inclua semântica, rótulos acessíveis, foco e operação por teclado quando aplicável; não use cor como único sinal. Mantenha contraste e alvos interativos legíveis.
- Reutilize widgets e estilos existentes. Extraia um componente apenas quando houver repetição real, responsabilidade clara ou necessidade de consistência; evite abstração de uso único sem benefício concreto.
- Preserve a arquitetura por funcionalidade e o gerenciamento de estado existente com Riverpod. Não mova responsabilidades entre camadas como parte incidental de um ajuste visual.
- Use imports `package:projectnbx/...`, `const` quando apropriado e siga o formatador e linter configurados.

## Revisão

Antes de concluir, confira a tela no contexto adjacente, interações e estados afetados; verifique adaptação de layout, tema, acessibilidade e reutilização. Descreva limitações que não puderem ser avaliadas no ambiente disponível.
