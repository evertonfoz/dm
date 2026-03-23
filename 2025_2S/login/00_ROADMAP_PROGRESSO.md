# Roadmap do Material Didático - Autenticação Flutter/Supabase

## Status Atual do Projeto

**Data de atualização:** Sessão atual concluída
**Seções completadas:** 10 de 14
**Progresso:** 71%

---

## Seções Completadas ✅

### 1. Fundamentos Teóricos de Autenticação Mobile ✅
**Arquivo:** `01_fundamentos_teoricos_autenticacao.md`
**Conteúdo coberto:**
- Autenticação vs. Autorização
- Desafios específicos de autenticação mobile
- Fluxos comuns (tradicional, OAuth, passwordless, biométrico)
- Conceitos de tokens e sessões
- Princípios fundamentais de segurança

### 2. Arquitetura e Organização do Código ✅
**Arquivo:** `02_arquitetura_organizacao_codigo.md`
**Conteúdo coberto:**
- Estrutura de pastas por features
- Separação em camadas (presentation, domain, data)
- Fluxo de dados entre camadas
- Gerenciamento de estado (introdução ao Riverpod)
- Nomenclatura e convenções

### 3. As Telas do Fluxo de Autenticação ✅
**Arquivo:** `03_telas_fluxo_autenticacao.md`
**Conteúdo coberto:**
- Jornada completa do usuário
- Tela de Login (elementos visuais, configuração de campos)
- Tela de Cadastro (campos essenciais, indicadores de força de senha)
- Tela de Recuperação de Senha
- Tela de Redefinição de Senha
- Tela Inicial (Auth Wrapper e Splash Screen)
- Transições e navegação entre telas
- Mensagens de erro e feedback

### 4. Boas Práticas de UX e Acessibilidade ✅
**Arquivo:** `04_boas_praticas_ux_acessibilidade.md`
**Conteúdo coberto:**
- Feedback visual durante operações assíncronas
- Tratamento de erros de forma amigável
- Campos de senha e controle de visibilidade
- Validação em tempo real vs. validação ao enviar
- Acessibilidade (labels semânticos, contraste, tamanhos de toque)
- Indicadores visuais não apenas por cor
- Microinterações e polimento visual

### 5. Segurança e Armazenamento de Credenciais ✅
**Arquivo:** `05_seguranca_armazenamento_credenciais.md`
**Conteúdo coberto:**
- Por que nunca armazenar senhas
- Compreendendo JSON Web Tokens (JWT)
- Armazenamento seguro com Flutter Secure Storage
- Gestão de tokens (access e refresh)
- HTTPS obrigatório
- Validação no backend
- Rate limiting e proteção contra ataques
- Princípio do menor privilégio

### 6. Validação de Formulários ✅
**Arquivo:** `06_validacao_formularios.md`
**Conteúdo coberto:**
- Validação de email pragmática
- Validação de senha (requisitos balanceados)
- Validação de confirmação de senha
- Validação de campos obrigatórios
- Implementação com Form e GlobalKey
- Validação assíncrona com debouncing
- Composição de validators

---

## Seções Pendentes (Para Próxima Sessão)

### 7. Gerenciamento de Estado para Autenticação ✅
**Arquivo:** `07_gerenciamento_estado_autenticacao.md`
**Conteúdo coberto:**
- Conceitos de estado de autenticação
- Modelagem de estados com hierarquia de classes
- AuthNotifier com Riverpod (StateNotifier)
- Métodos de login, logout, registro
- Consumindo estado nas telas (watch, read, listen)
- Auth Wrapper para navegação baseada em estado
- Listeners e observers globais

### 8. Integração com APIs (Backend) ✅
**Arquivo:** `08_integracao_apis_backend.md`
**Conteúdo coberto:**
- Configuração do Dio
- Estruturando AuthService completo
- Tratamento abrangente de erros HTTP
- Interceptors (logging e autenticação)
- Renovação automática de tokens
- Parsing de JSON e models
- Requisições autenticadas

### 9. Navegação e Proteção de Rotas ✅
**Arquivo:** `09_navegacao_protecao_rotas.md`
**Conteúdo coberto:**
- Auth Wrapper detalhado
- Navegação manual entre telas
- Transições customizadas
- Deep linking (configuração Android/iOS)
- Processamento de deep links no Flutter
- Proteção de rotas baseada em roles

### 10. Métodos Alternativos de Autenticação ✅
**Arquivo:** `10_metodos_alternativos_autenticacao.md`
**Conteúdo coberto:**
- Autenticação passwordless com Magic Links
- Login social com OAuth 2.0
- Implementação de login com Google
- Implementação de login com GitHub
- Autenticação biométrica com local_auth
- Quick login com biometria

### 11. Autenticação com Supabase - Guia Completo 📋
**Arquivo planejado:** `11_supabase_guia_completo.md`
**Conteúdo a cobrir:**

**ESTA É A SEÇÃO MAIS IMPORTANTE E EXTENSA**

#### Parte 1: Introdução e Setup
- O que o Supabase oferece
- Criar projeto no Supabase
- Instalar e configurar no Flutter
- Inicialização no main.dart

#### Parte 2: Implementações Práticas
- Cadastro de usuário (signUp)
- Login tradicional (signInWithPassword)
- Recuperação de senha (resetPasswordForEmail)
- Redefinição de senha (updateUser)
- Logout (signOut)

#### Parte 3: Login Social
- Configurar Google OAuth
- Configurar GitHub OAuth
- Implementar signInWithOAuth
- Tratar callbacks e redirecionamentos

#### Parte 4: Magic Links
- Implementar signInWithOtp
- Fluxo completo de magic link
- Configuração de emails

#### Parte 5: Estado e Listeners
- onAuthStateChange stream
- Integração com AuthNotifier
- Renovação automática de tokens
- Tratamento de eventos (signedIn, signedOut, tokenRefreshed)

#### Parte 6: Deep Linking
- Configuração AndroidManifest.xml
- Configuração Info.plist
- authCallbackUrlHostname
- Testar deep links

#### Parte 7: Customizações
- Templates de email
- SMTP customizado
- Metadados de usuário
- RLS (Row Level Security) básico

**Pontos-chave para não esquecer:**
- Código passo-a-passo comentado para CADA operação
- Screenshots/descrições de configuração no dashboard Supabase
- Troubleshooting comum
- Exemplos completos end-to-end

### 12. Protótipos Visuais e Material Design 3 📋
**Arquivo planejado:** `12_prototipos_visuais_material_design.md`
**Conteúdo a cobrir:**
- Princípios de design para autenticação
- Especificações detalhadas de cada tela
- Prompts para geração de protótipos (IA)
- Sistema de cores Material Design 3
- Componentes reutilizáveis
- Espaçamentos e tipografia

**Pontos-chave para não esquecer:**
- Prompts completos e detalhados para cada tela
- Especificações de cores, fontes, tamanhos
- Exemplos de CustomTextField, AuthButton, etc
- ThemeData configuração completa

### 13. Desafios Práticos e Critérios de Avaliação 📋
**Arquivo planejado:** `13_desafios_praticos_avaliacao.md`
**Conteúdo a cobrir:**

#### Desafio Nível Básico
- Requisitos: login, cadastro, logout
- Critérios de avaliação
- Dicas para alunos

#### Desafio Nível Intermediário
- Requisitos: + recuperação senha, login social, persistência
- Critérios de avaliação
- Dicas para alunos

#### Desafio Nível Avançado
- Requisitos: + magic link, biometria, múltiplos OAuth, testes
- Requisitos de UX adicionais
- Critérios de avaliação
- Dicas para alunos

#### Extensões Opcionais
- Perfil de usuário
- Upload de foto
- 2FA
- Lista de dispositivos
- Histórico de login
- Modo offline

#### Entrega e Apresentação
- Formato de entrega
- Estrutura da apresentação

**Pontos-chave para não esquecer:**
- Critérios mensuráveis e objetivos
- Pontuação clara para cada aspecto
- Exemplos de excelência

### 14. Erros Comuns e Como Evitá-los 📋
**Arquivo planejado:** `14_erros_comuns_troubleshooting.md`
**Conteúdo a cobrir:**

**10 erros principais com soluções:**

1. Não validar antes de enviar
2. Não tratar erros de rede
3. Armazenar dados sensíveis de forma insegura
4. Não dar feedback visual durante operações assíncronas
5. Problemas com foco de teclado
6. Deep linking não funciona
7. Não limpar controllers
8. Expor informações sensíveis em logs
9. Não lidar com sessões expiradas
10. URLs incorretas ou configurações erradas

Para cada erro:
- Sintoma
- Causa
- Código errado (exemplo)
- Código correto (exemplo)
- Explicação

**Pontos-chave para não esquecer:**
- Exemplos de código reais e práticos
- Diferença clara entre abordagem errada e correta
- Dicas de debugging

---

## Estrutura de Cada Arquivo

Todos os arquivos seguem este padrão para consistência:

```markdown
# [Título da Seção]

## Desenvolvimento de Aplicativos Móveis - Flutter

---

## Introdução
[Contextualização e importância do tópico]

---

## [Subtópico 1]
[Conteúdo com código comentado quando aplicável]

### [Subseção se necessário]
[Detalhamento]

---

## [Subtópico 2]
...

---

## Conclusão da Seção
[Resumo dos pontos-chave e transição para próxima seção]

---

**Fim da Seção X: [Título]**
```

---

## Diretrizes de Estilo Mantidas

- **Tom:** Didático, claro, direto, sem infantilizar
- **Idioma:** Português do Brasil
- **Público:** Alunos de graduação em Computação
- **Tecnologias:** Flutter (versão estável), Dart, Material Design 3, Supabase
- **Código:** Sempre comentado, com explicações inline
- **Exemplos:** Situações reais, práticas
- **Estrutura:** Contexto → Conceito → Exemplo → Armadilhas comuns

---

## Checklist para Retomar Trabalho

Quando retomar em nova sessão, verificar:

- [ ] Revisar últimas 2 seções criadas para relembrar contexto
- [ ] Identificar próxima seção pendente neste roadmap
- [ ] Seguir estrutura de arquivo padrão
- [ ] Manter tom e estilo consistentes
- [ ] Incluir código comentado e exemplos práticos
- [ ] Conectar conteúdo com seções anteriores quando relevante
- [ ] Atualizar este roadmap ao completar cada seção

---

## Notas Importantes

### Sobre Supabase (Seção 11)
Esta é a seção mais crítica e extensa. Requer:
- Código passo-a-passo para CADA funcionalidade
- Explicações de configuração no dashboard
- Troubleshooting específico do Supabase
- Integração completa com AuthNotifier do Riverpod

Estimar: Esta seção sozinha pode precisar de 2-3 arquivos separados se ficar muito extensa.

### Sobre Prompts de Protótipos (Seção 12)
Os prompts devem ser extremamente detalhados e específicos para que alunos possam usar com ferramentas de IA para gerar interfaces. Incluir:
- Especificações visuais completas
- Cores exatas (hex codes)
- Tamanhos e espaçamentos em pixels
- Descrição de cada elemento

### Sobre Desafios (Seção 13)
Os critérios de avaliação precisam ser:
- Mensuráveis objetivamente
- Com pontuação clara
- Diferenciados por nível de dificuldade
- Acompanhados de rubrica de avaliação

---

## Arquivos Gerados Até Agora

1. ✅ `01_fundamentos_teoricos_autenticacao.md`
2. ✅ `02_arquitetura_organizacao_codigo.md`
3. ✅ `03_telas_fluxo_autenticacao.md`
4. ✅ `04_boas_praticas_ux_acessibilidade.md`
5. ✅ `05_seguranca_armazenamento_credenciais.md`
6. ✅ `06_validacao_formularios.md`
7. ✅ `07_gerenciamento_estado_autenticacao.md`
8. ✅ `08_integracao_apis_backend.md`
9. ✅ `09_navegacao_protecao_rotas.md`
10. ✅ `10_metodos_alternativos_autenticacao.md`
11. 📋 `11_supabase_guia_completo.md` - **PRÓXIMO (PRIORIDADE)**
12. 📋 `12_prototipos_visuais_material_design.md`
13. 📋 `13_desafios_praticos_avaliacao.md`
14. 📋 `14_erros_comuns_troubleshooting.md`

---

## Como Usar Este Roadmap

**Para o Professor:**
- Acompanhe o progresso das seções
- Revise cada arquivo antes de importar no Gamma.app
- Adapte conteúdo conforme necessidade da turma
- Use este documento para planejar aulas

**Para Continuar o Desenvolvimento:**
- Identifique próxima seção pendente (marcada com 📋)
- Leia "Conteúdo a cobrir" e "Pontos-chave"
- Siga estrutura padrão de arquivo
- Mantenha consistência de tom e estilo
- Atualize status ao completar

---

**Última atualização:** Sessão atual concluída - 10 seções completas (71%)
**Próxima ação:** Criar seção 11 (Supabase - Guia Completo) - **SEÇÃO MAIS IMPORTANTE**

## Resumo da Sessão Atual

Nesta sessão, foram criadas 4 seções completas:

1. **Seção 7 - Gerenciamento de Estado** (Riverpod completo)
2. **Seção 8 - Integração com APIs** (Dio, interceptors, error handling)
3. **Seção 9 - Navegação e Proteção de Rotas** (Auth Wrapper, deep linking)
4. **Seção 10 - Métodos Alternativos** (Magic links, OAuth, biometria)

**Total: 10 de 14 seções completas**

## Para Próxima Sessão

**PRIORIDADE MÁXIMA:** Seção 11 - Supabase (a mais extensa e importante)

Esta seção deve cobrir:
- Setup completo do Supabase
- Cada método de autenticação com código passo-a-passo
- Integração com AuthNotifier do Riverpod
- Deep linking para confirmação de email
- OAuth social (Google, GitHub)
- Magic links
- Troubleshooting específico do Supabase

Após Seção 11, restam apenas 3 seções menores (protótipos, desafios, troubleshooting).

