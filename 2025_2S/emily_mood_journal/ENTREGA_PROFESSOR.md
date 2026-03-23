# Entrega - Arquitetura Entity ≠ DTO + Mapper

**Para:** Professor  
**De:** Emily Pessutti (emillypessutti@gmail.com)  
**Data:** 06/11/2025

---

## 🔗 Link do Repositório

**GitHub:** https://github.com/emillypessutti/MoodJournal  
**Branch:** main  
**Commits:** 5 conventional commits em português

---

## ✅ Checklist de Entregáveis

### 1️⃣ MoodEntry (Registro de Humor)
- ✅ **Entity:** `lib/domain/entities/mood_entry_entity.dart`
- ✅ **DTO:** `lib/data/dtos/mood_entry_dto.dart`
- ✅ **Mapper:** `lib/data/mappers/mood_entry_mapper.dart`
- ✅ **Teste:** `test/data/mappers/mood_entry_mapper_test.dart` (7 casos)

### 2️⃣ UserProfile (Perfil do Usuário)
- ✅ **Entity:** `lib/domain/entities/user_profile_entity.dart`
- ✅ **DTO:** `lib/data/dtos/user_profile_dto.dart`
- ✅ **Mapper:** `lib/data/mappers/user_profile_mapper.dart`
- ✅ **Teste:** `test/data/mappers/user_profile_mapper_test.dart` (8 casos)

### 3️⃣ DailyGoal (Meta Diária)
- ✅ **Entity:** `lib/domain/entities/daily_goal_entity.dart`
- ✅ **DTO:** `lib/data/dtos/daily_goal_dto.dart`
- ✅ **Mapper:** `lib/data/mappers/daily_goal_mapper.dart`
- ✅ **Teste:** `test/data/mappers/daily_goal_mapper_test.dart` (7 casos)

### 4️⃣ MoodStatistics (Estatísticas de Humor)
- ✅ **Entity:** `lib/domain/entities/mood_statistics_entity.dart`
- ✅ **DTO:** `lib/data/dtos/mood_statistics_dto.dart`
- ✅ **Mapper:** `lib/data/mappers/mood_statistics_mapper.dart`
- ✅ **Teste:** `test/data/mappers/mood_statistics_mapper_test.dart` (6 casos)

---

## 📊 Resultado dos Testes

```bash
flutter test test/data/mappers/
```

**Resultado:** ✅ **28 testes passando com sucesso!**

```
00:01 +28: All tests passed!
```

---

## 🎯 Destaques da Implementação

### Entities (Domínio)
- ✅ Tipos fortes: Enums (`MoodLevel`, `GoalType`, `Period`), Value Objects (`Email`)
- ✅ Invariantes validados: assertions nos construtores
- ✅ Métodos de negócio: `progress`, `isAchieved`, `dominantMood`, `trend`
- ✅ Imutabilidade: apenas `copyWith()` para modificações

### DTOs (Infraestrutura)
- ✅ Espelham schema do backend: `mood_level`, `user_id`, `start_ts`, etc
- ✅ Tipos compatíveis com JSON: `int`, `String`, `Map<String, dynamic>`
- ✅ Serialização: `fromJson()` e `toJson()`

### Mappers (Conversão)
- ✅ Bidirecionais: `toEntity()` e `toDto()`
- ✅ Normalizações: trim, lowercase, null handling, timestamps
- ✅ SEM regras de negócio: apenas conversões

### Testes
- ✅ Conversões Entity → DTO
- ✅ Conversões DTO → Entity
- ✅ Conversões bidirecionais (ida e volta)
- ✅ Validação de invariantes
- ✅ Normalização de dados

---

## 📚 Documentação Completa

Ver arquivo: **CHECKLIST.md** no repositório

Contém:
- Descrição detalhada de cada entidade
- Invariantes e tipos fortes
- Estrutura de arquivos
- Instruções de execução
- Princípios arquiteturais aplicados

---

**Implementado com sucesso!** 🚀
