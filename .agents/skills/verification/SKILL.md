---
name: verification
description: Escolhe e executa verificações proporcionais a alterações no ProjectNBX e informa resultados reais sem alegar testes que não foram executados.
---

# Verificação após mudanças

Use após mudanças de código, configuração, testes ou documentação que exijam validação.

1. Confira o diff para confirmar escopo, arquivos pretendidos e preservação das alterações anteriores do usuário.
2. Escolha a checagem mais direta para o risco e os arquivos afetados. Use as ferramentas e instruções existentes; não instale dependências nem inicie serviços sem necessidade.
3. Flutter/Dart: priorize `dart format` para arquivos Dart alterados e `flutter analyze`; execute testes Flutter direcionados quando o comportamento mudar e o ambiente permitir.
4. Go: use `gofmt` nos arquivos Go alterados; execute `go test` nos pacotes afetados. Amplie para `go test ./...`, race detector ou outras análises somente quando o escopo ou risco justificar.
5. Configuração/documentação: confira nomes, links, sintaxe e consistência com as instruções e o projeto. Não rode toda a bateria de testes por padrão para alterações que não mudam código.
6. Se uma verificação falhar, determine se a falha foi introduzida pela alteração. Corrija problemas dentro do escopo e rode de novo a verificação pertinente; relate falhas preexistentes ou bloqueios com clareza.
7. Informe o comando/checagem executada e seu resultado. Diferencie explicitamente o que foi inspecionado do que foi executado; não declare sucesso de teste não rodado.
