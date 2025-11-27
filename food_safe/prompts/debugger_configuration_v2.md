```markdown
# Debugger Configuration (VS Code / IntelliJ) - v2

Objetivo
--------
Evitar que o depurador pause em exceções que seu código já captura (caught exceptions), facilitando testes de fluxo como sync/pull que tratam erros internamente.

VS Code (Dart/Flutter)
- Abra `Run and Debug` (Cmd+Shift+D).
- No painel `Breakpoints` localize `Dart Exceptions` ou `Exception Breakpoints`.
- Desmarque `All Exceptions` e deixe `Uncaught Exceptions` marcado.
- Se a execução estiver pausada, pressione `Continue` (F5).

IntelliJ / Android Studio
- Run → View Breakpoints... → Selecione `Dart Exception Breakpoints`.
- Desmarque `Caught exceptions` / `Any Exception` (ou apenas deixe `Uncaught` habilitado).

Inspecionar exceção pausada
- Quando o depurador pausar, abra `Call Stack` e `Variables` para ver o erro e `stackTrace`.
- A `Debug Console` pode conter a exceção formatada; copie-a se precisar de ajuda para interpretar.

Observação
- Desativar pausa em exceptions capturadas não altera o tratamento do seu código — apenas evita interrupções no fluxo enquanto você testa fluxos que já fazem try/catch.

Debugger pausando sem exceção visível
-------------------------------------
Se o depurador pausa mas nenhuma exceção aparece nos logs:
1. Verifique a aba `Call Stack` na IDE — o frame superior mostra onde pausou.
2. Procure por `return` statements em código assíncrono — se `mounted = false`,
   o código pode retornar cedo e o depurador pode pausar nesse ponto.
3. Use logs de rastreamento (`[tag] checkpoint`) para identificar a última linha
   executada antes da pausa.

Operações assíncronas e widget lifecycle
----------------------------------------
- Em Flutter, widgets podem ser desmontados (`mounted = false`) durante operações
  assíncronas (ex.: sync de dados, chamadas de API).
- Sempre verifique `if (!mounted) return;` após `await` para evitar chamadas
  `setState` em widgets desmontados.
- Padrão recomendado: aplicar dados do cache à UI **antes** de iniciar operações
  lentas, para que a UI responda instantaneamente.

Exemplo de padrão UI-first
---------------------------
```dart
// Carregar e mostrar cache imediatamente
final cached = await dao.listAll();
if (!mounted) return;
setState(() {
  items = cached;
  loading = false;
});

// Sync em segundo plano
try {
  if (!mounted) return;
  setState(() { syncing = true; });
  
  await syncFromServer();
  
  if (!mounted) return;
  setState(() { 
    items = await dao.listAll(); // atualizar com dados sincronizados
    syncing = false;
  });
} catch (e) {
  if (mounted) setState(() { syncing = false; });
}
```
```
