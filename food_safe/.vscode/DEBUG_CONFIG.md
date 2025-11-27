# Configuração de Debug - Supabase Flutter

## Problema Resolvido

Este projeto tinha pausas não demonstradas no IDE durante a inicialização do Supabase, causadas por exceções internas do pacote `supabase_flutter` v2.10.3.

### Causa Raiz
- **TimeoutException** do Hive durante migração automática de sessões (Issue #794)
- O `Hive.openBox()` tinha timeout de 1 segundo que falhava silenciosamente
- O debugger pausava na exceção antes do `catch` silencioso

## Soluções Implementadas

### 1. CustomLocalStorage (✅ IMPLEMENTADO)

Criamos uma implementação customizada de `LocalStorage` que:
- **Evita completamente o Hive** e suas exceções de timeout
- Usa apenas `SharedPreferences` diretamente
- Elimina a necessidade de migração de sessões antigas
- Previne pausas no debugger

```dart
class CustomLocalStorage extends LocalStorage {
  // Implementação sem Hive que evita TimeoutException
}
```

### 2. Configuração do VS Code (✅ IMPLEMENTADO)

Adicionamos configurações em `launch.json` para:
- Desabilitar debug de bibliotecas externas (`debugExternalPackageLibraries: false`)
- Desabilitar debug do SDK (`debugSdkLibraries: false`)
- Não parar em exceções (`stopOnException: none`)

### 3. Inicialização Customizada do Supabase (✅ IMPLEMENTADO)

Modificamos `main.dart` para usar o `CustomLocalStorage`:

```dart
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  authOptions: FlutterAuthClientOptions(
    localStorage: CustomLocalStorage(
      persistSessionKey: "sb-${Uri.parse(supabaseUrl).host.split(".").first}-auth-token",
    ),
  ),
);
```

## Como Usar

### Modo Normal (com proteções)
```bash
# No VS Code, selecione a configuração "food_safe" ou "food_safe (no pause)"
# Pressione F5 ou clique em "Run and Debug"
```

### Modo Profile (para testes de performance)
```bash
# Selecione "food_safe (profile mode)"
```

### Modo Release (produção)
```bash
# Selecione "food_safe (release mode)"
```

## Benefícios

✅ **Sem pausas inesperadas** no debugger  
✅ **Sem dependência do Hive** para armazenamento de sessão  
✅ **Inicialização mais rápida** do Supabase  
✅ **Menos overhead** de debug em packages externos  
✅ **Melhor experiência de desenvolvimento**  

## Notas Importantes

1. **Sessões antigas do Hive NÃO serão migradas automaticamente**
   - Usuários existentes precisarão fazer login novamente
   - Este é um trade-off aceitável para eliminar os problemas de timeout

2. **A versão 2.11.0+ do supabase_flutter ainda não está disponível**
   - Quando disponível, considere atualizar
   - As mudanças aqui ainda serão benéficas

3. **Para Android Studio/IntelliJ**
   - Configure manualmente: `Run` → `View Breakpoints` (Ctrl+Shift+F8)
   - Desative Exception Breakpoints para `TimeoutException`

## Referências

- Issue #794: https://github.com/supabase/supabase-flutter/issues/794
- Issue #799: https://github.com/supabase/supabase-flutter/issues/799
- Documentação oficial: https://github.com/supabase/supabase-flutter

## Histórico de Mudanças

**27/11/2025**
- ✅ Implementado `CustomLocalStorage` sem Hive
- ✅ Configurado `launch.json` para não pausar em exceções
- ✅ Modificado inicialização do Supabase
- ✅ Documentação criada
