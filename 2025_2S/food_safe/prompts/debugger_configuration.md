```markdown
# Debugger Configuration (VS Code / IntelliJ)

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
