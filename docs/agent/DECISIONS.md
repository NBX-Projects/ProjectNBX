# Memória de decisões do ProjectNBX

Registre aqui apenas decisões confirmadas que devam continuar orientando tarefas futuras. Consulte o código e `AGENTS.md` para verificar se ainda se aplicam. Não use este arquivo para hipóteses ou escolhas específicas de uma tarefa.

## Decisões

| Data | Contexto | Decisão | Consequência | Evidência |
| 2026-10-01 | Customização de perfil do usuário e persistência de status de presença | Persistir status (`online`, `idle`, `dnd`), foto de perfil (`avatar_url`), capa (`banner_url`), bio e `custom_status` com suporte total a GIFs tanto no PostgreSQL quanto localmente no cliente (SharedPreferences + Riverpod) com sincronização em tempo real via WebSocket (`USER_PRESENCE`). | Ao alterar status ou customizações, utilizar o `authControllerProvider` (que atualiza estado local de forma otimista, salva em SharedPreferences, envia presença no WebSocket e sincroniza na API REST). O hub WebSocket não deve mais sobrescrever cegamente o status para 'online' ao registrar conexão. Suportar GIFs animados nas tags de avatar e banner com renderização nativa de frames. | `backend/migrations/000008_...`, `user_model.dart`, `auth_controller.dart`, `hub.go`, `user_status_chip.dart`, `settings_screen.dart` |

## Modelo de entrada

```text
### AAAA-MM-DD — Título curto
- Contexto: problema ou necessidade duradoura.
- Decisão: escolha confirmada e seu escopo.
- Consequência: como tarefas futuras devem agir.
- Evidência: arquivo, instrução ou confirmação que fundamenta a decisão.
```
