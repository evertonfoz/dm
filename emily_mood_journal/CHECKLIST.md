# Checklist - Arquitetura Entity ≠ DTO + Mapper

**Projeto:** MoodJournal  
**Aluna:** Emily Pessutti  
**Repositório:** https://github.com/emillypessutti/MoodJournal  
**Branch:** main  
**Data:** 06/11/2025

---

## 📋 Resumo da Implementação

Implementei **4 entidades do domínio** seguindo rigorosamente a arquitetura **Entity ≠ DTO + Mapper**, conforme solicitado pelo professor. Cada entidade possui:

- ✅ **Entity** com tipos fortes e invariantes de domínio
- ✅ **DTO** espelhando fielmente o schema do backend/API
- ✅ **Mapper** com conversões bidirecionais (toEntity/toDto)
- ✅ **Testes** demonstrando conversões funcionando

---

## 🎯 Entidades Implementadas

### 1️⃣ MoodEntry (Registro de Humor)

#### ✅ Entity
- **Arquivo:** `lib/domain/entities/mood_entry_entity.dart`
- **Invariantes:**
  - ID não pode ser vazio
  - Nota limitada a 500 caracteres
  - Timestamp não pode ser no futuro (`isValid`)
  - Enum `MoodLevel` com valores semânticos (1-5)
- **Tipos Fortes:**
  - `MoodLevel` enum com métodos `fromValue()` e `fromString()`
  - `DateTime` para timestamp
  - `List<String>` para tags (nunca null)
- **Métodos de Domínio:**
  - `hasNote` - verifica se tem anotações
  - `intensity` - retorna valor numérico do humor

#### ✅ DTO
- **Arquivo:** `lib/data/dtos/mood_entry_dto.dart`
- **Espelhamento do Backend:**
  - `moodLevel: int` (backend usa 1-5)
  - `timestamp: int` (Unix timestamp em milissegundos)
  - `notes: String?` (backend usa "notes" plural)
  - `tagsList: List<String>?` (backend pode retornar null)
- **Métodos:** `fromJson()` e `toJson()`

#### ✅ Mapper
- **Arquivo:** `lib/data/mappers/mood_entry_mapper.dart`
- **Conversões:**
  - `toEntity()` - DTO → Entity
  - `toDto()` - Entity → DTO
  - `toEntityList()` / `toDtoList()` - conversões em lote
- **Normalizações:**
  - Remove espaços extras de notas (trim)
  - Converte null tags para lista vazia
  - Converte lista vazia de tags para null (para backend)
  - Converte timestamp Unix para DateTime

#### ✅ Teste
- **Arquivo:** `test/data/mappers/mood_entry_mapper_test.dart`
- **Casos de Teste:**
  - ✅ toEntity converte DTO corretamente
  - ✅ Normaliza tags null para lista vazia
  - ✅ toDto converte Entity corretamente
  - ✅ Converte lista vazia de tags para null
  - ✅ Conversão bidirecional mantém dados
  - ✅ toEntityList converte listas

---

### 2️⃣ UserProfile (Perfil do Usuário)

#### ✅ Entity
- **Arquivo:** `lib/domain/entities/user_profile_entity.dart`
- **Invariantes:**
  - ID não pode ser vazio
  - Nome: mínimo 2, máximo 100 caracteres
  - Email validado com regex (Value Object `Email`)
- **Tipos Fortes:**
  - `Email` - Value Object com validação
  - `DateTime` para createdAt e lastUpdated
- **Métodos de Domínio:**
  - `hasValidName` - valida nome
  - `hasPhoto` - verifica foto
  - `initials` - extrai iniciais (até 2 letras)
  - `isComplete` - verifica se perfil está completo

#### ✅ DTO
- **Arquivo:** `lib/data/dtos/user_profile_dto.dart`
- **Espelhamento do Backend:**
  - `userId: String` (backend usa "user_id")
  - `userName: String` (backend usa "user_name")
  - `userEmail: String` (backend usa "user_email")
  - `photoBase64: String?` (backend armazena foto em base64)
  - `createdTimestamp: int` (Unix timestamp)
  - `updatedTimestamp: int?` (pode ser null)

#### ✅ Mapper
- **Arquivo:** `lib/data/mappers/user_profile_mapper.dart`
- **Normalizações:**
  - Nome: remove espaços extras (trim)
  - Email: converte para lowercase
  - Photo vazia → null
  - Timestamps Unix ↔ DateTime

#### ✅ Teste
- **Arquivo:** `test/data/mappers/user_profile_mapper_test.dart`
- **Casos de Teste:**
  - ✅ toEntity normaliza nome e email
  - ✅ Trata photo vazia como null
  - ✅ toDto converte corretamente
  - ✅ Valida email inválido (lança AssertionError)
  - ✅ Conversão bidirecional mantém dados
  - ✅ Calcula iniciais corretamente
  - ✅ toEntityList converte listas

---

### 3️⃣ DailyGoal (Meta Diária)

#### ✅ Entity
- **Arquivo:** `lib/domain/entities/daily_goal_entity.dart`
- **Invariantes:**
  - ID e userId não vazios
  - targetValue > 0 (positivo)
  - currentValue >= 0 (não negativo)
  - Progresso limitado a 100% (clamp)
- **Tipos Fortes:**
  - `GoalType` enum (moodEntries, positiveEntries, reflection, gratitude)
  - `DateTime` para date
- **Métodos de Domínio:**
  - `progress` - calcula 0.0 a 1.0
  - `progressPercentage` - 0 a 100%
  - `isAchieved` - verifica se atingiu meta
  - `remaining` - quanto falta
  - `isToday` - verifica se é de hoje

#### ✅ DTO
- **Arquivo:** `lib/data/dtos/daily_goal_dto.dart`
- **Espelhamento do Backend:**
  - `goalId: String` (backend usa "goal_id")
  - `uid: String` (backend usa "uid" para user ID)
  - `goalType: String` (backend armazena como string)
  - `target: int` / `current: int`
  - `dateIso: String` (formato ISO 8601: "YYYY-MM-DD")
  - `completed: bool`

#### ✅ Mapper
- **Arquivo:** `lib/data/mappers/daily_goal_mapper.dart`
- **Normalizações:**
  - Converte string ISO 8601 ↔ DateTime
  - Formata data com padding de zeros
  - GoalType string ↔ enum

#### ✅ Teste
- **Arquivo:** `test/data/mappers/daily_goal_mapper_test.dart`
- **Casos de Teste:**
  - ✅ toEntity converte e calcula progresso
  - ✅ Valida meta atingida (isAchieved)
  - ✅ toDto formata data ISO 8601
  - ✅ Formata com padding (2023-01-05)
  - ✅ Conversão bidirecional mantém dados
  - ✅ Valida invariantes (targetValue > 0)
  - ✅ toEntityList converte listas

---

### 4️⃣ MoodStatistics (Estatísticas de Humor)

#### ✅ Entity
- **Arquivo:** `lib/domain/entities/mood_statistics_entity.dart`
- **Invariantes:**
  - userId não vazio
  - averageMood entre 1.0 e 5.0
  - totalEntries >= 0
  - startDate <= endDate
- **Tipos Fortes:**
  - `Period` enum (week, month, quarter, year)
  - `Map<String, int>` para distribuição
  - `DateTime` para datas
- **Métodos de Domínio:**
  - `dominantMood` - humor predominante
  - `hasEnoughData` - mínimo 3 registros
  - `trend` - positive/negative/stable
  - `periodInDays` - duração em dias
  - `averageEntriesPerDay` - média diária

#### ✅ DTO
- **Arquivo:** `lib/data/dtos/mood_statistics_dto.dart`
- **Espelhamento do Backend:**
  - `uid: String` (backend usa "uid")
  - `periodType: String` (week/month/quarter/year)
  - `avg: double` (abreviado)
  - `count: int` (total de registros)
  - `distribution: Map<String, dynamic>` (backend retorna dynamic)
  - `startTs: int` / `endTs: int` (timestamps Unix)

#### ✅ Mapper
- **Arquivo:** `lib/data/mappers/mood_statistics_mapper.dart`
- **Normalizações:**
  - `Map<String, dynamic>` ↔ `Map<String, int>`
  - Converte valores dinâmicos para int
  - Timestamps Unix ↔ DateTime
  - Period string ↔ enum

#### ✅ Teste
- **Arquivo:** `test/data/mappers/mood_statistics_mapper_test.dart`
- **Casos de Teste:**
  - ✅ toEntity converte e normaliza distribuição
  - ✅ Normaliza numbers (int/double) para int
  - ✅ toDto converte corretamente
  - ✅ Calcula humor predominante
  - ✅ Calcula métricas (periodInDays, averageEntriesPerDay)
  - ✅ Conversão bidirecional mantém dados
  - ✅ Valida invariante de média (1.0-5.0)
  - ✅ toEntityList converte listas com trend

---

## 📊 Estrutura de Arquivos

```
lib/
├── domain/
│   └── entities/
│       ├── mood_entry_entity.dart
│       ├── user_profile_entity.dart
│       ├── daily_goal_entity.dart
│       └── mood_statistics_entity.dart
├── data/
│   ├── dtos/
│   │   ├── mood_entry_dto.dart
│   │   ├── user_profile_dto.dart
│   │   ├── daily_goal_dto.dart
│   │   └── mood_statistics_dto.dart
│   └── mappers/
│       ├── mood_entry_mapper.dart
│       ├── user_profile_mapper_mapper.dart
│       ├── daily_goal_mapper.dart
│       └── mood_statistics_mapper.dart
test/
└── data/
    └── mappers/
        ├── mood_entry_mapper_test.dart
        ├── user_profile_mapper_test.dart
        ├── daily_goal_mapper_test.dart
        └── mood_statistics_mapper_test.dart
```

---

## ✅ Princípios Arquiteturais Aplicados

### 🎯 Entity (Domínio)
- ✅ Tipos fortes (enums, value objects)
- ✅ Invariantes de domínio (assertions)
- ✅ Métodos de negócio calculados
- ✅ Imutabilidade (copyWith)
- ✅ SEM dependência de infraestrutura

### 📦 DTO (Data Transfer Object)
- ✅ Espelha fielmente o schema do backend
- ✅ Usa tipos primitivos compatíveis com JSON
- ✅ Nomeclatura seguindo convenção da API
- ✅ fromJson() / toJson() para serialização
- ✅ SEM lógica de negócio

### 🔄 Mapper
- ✅ Responsabilidade única: conversão
- ✅ Métodos bidirecionais (toEntity/toDto)
- ✅ Normalizações centralizadas (trim, lowercase, null handling)
- ✅ Conversões de tipo (timestamps, enums, strings)
- ✅ SEM regras de negócio

### 🧪 Testes
- ✅ Testes unitários para cada Mapper
- ✅ Casos de conversão Entity → DTO
- ✅ Casos de conversão DTO → Entity
- ✅ Conversões bidirecionais (mantém dados)
- ✅ Validação de normalizações
- ✅ Validação de invariantes (assertions)
- ✅ Conversões de listas

---

## 🚀 Como Executar os Testes

```bash
# Executar todos os testes
flutter test

# Executar testes de um Mapper específico
flutter test test/data/mappers/mood_entry_mapper_test.dart
flutter test test/data/mappers/user_profile_mapper_test.dart
flutter test test/data/mappers/daily_goal_mapper_test.dart
flutter test test/data/mappers/mood_statistics_mapper_test.dart
```

---

## 📝 Observações Técnicas

### Separação de Responsabilidades
- **Entity:** Regras de negócio, validações de domínio, cálculos
- **DTO:** Estrutura de dados do backend, serialização JSON
- **Mapper:** APENAS conversões e normalizações (sem negócio)

### Normalizações Implementadas
- Trim em strings (remove espaços extras)
- Lowercase em emails
- Null handling (null ↔ valores padrão)
- Timestamp Unix ↔ DateTime
- String ↔ Enum
- ISO 8601 formatting
- Map<String, dynamic> ↔ Map<String, int>

### Invariantes de Domínio
- Validações com `assert()` nos construtores
- Lançam `AssertionError` em casos inválidos
- Garantem consistência do modelo de domínio
- Testados nos testes unitários

---

## 🎓 Entregáveis Completos

| Entidade | Entity | DTO | Mapper | Teste |
|----------|--------|-----|--------|-------|
| **MoodEntry** | ✅ | ✅ | ✅ | ✅ |
| **UserProfile** | ✅ | ✅ | ✅ | ✅ |
| **DailyGoal** | ✅ | ✅ | ✅ | ✅ |
| **MoodStatistics** | ✅ | ✅ | ✅ | ✅ |

**Total:** 4 entidades × 4 componentes = **16 arquivos implementados** ✅

---

## 📱 Repositório

**GitHub:** https://github.com/emillypessutti/MoodJournal  
**Branch:** main  
**Commits:** Conventional Commits em português

---

**Implementado por:** Emily Pessutti  
**Email:** emillypessutti@gmail.com  
**Data:** 06 de novembro de 2025
