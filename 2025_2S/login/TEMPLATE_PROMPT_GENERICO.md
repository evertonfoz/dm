# 📝 TEMPLATE DE PROMPT PARA MATERIAL DIDÁTICO - FLUTTER
## Prompt Genérico e Reutilizável para Qualquer Feature

---

## 🎯 COMO USAR ESTE TEMPLATE

1. **Copie o prompt base** (seção abaixo)
2. **Substitua as variáveis** entre `[COLCHETES]` pela sua feature específica
3. **Ajuste os exemplos** conforme necessário
4. **Cole no chat** e deixe a IA gerar o roadmap
5. **Revise, valide e aprove** antes da criação completa

---

## 📋 PROMPT BASE - COPIE E ADAPTE

```
Vou ensinar aos alunos RESPONSIVIDADE E DESIGN ADAPTATIVO em Flutter. Em uma aplicação mobile normal, é essencial que a interface se adapte adequadamente a diferentes tamanhos de tela (smartphones, tablets, foldables) e orientações (portrait/landscape), garantindo uma experiência de usuário consistente e profissional. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo e bem estruturado
2. Diagramas visuais mostrando breakpoints e adaptações de layout
3. Boas práticas de implementação responsiva
4. Prompts para que os alunos possam usar para criar interfaces adaptativas profissionais

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: INTERMEDIÁRIO
- Já conhecem: Dart básico, Widgets fundamentais do Flutter (Container, Row, Column, Stack), Conceitos de layout básico
- Foco: Aplicação prática e profissional para diferentes dispositivos

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de responsividade e design adaptativo
2. Arquitetura e organização do código responsivo
3. Interface de usuário e UX para múltiplos dispositivos
4. Implementação prática passo a passo
5. Integração com MediaQuery, LayoutBuilder e breakpoints
6. Widgets especializados (Expanded, Flexible, FractionallySizedBox, AspectRatio)
7. Boas práticas e padrões (Mobile-first, Design System)
8. Erros comuns e troubleshooting
9. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Comparações "errado vs correto"
- Material preparado para Gamma.app (slides) - FOCO EM CONCEITOS VISUAIS
- Evitar código extenso nos slides, priorizar diagramas e exemplos concisos

ESTRATÉGIA DE GERAÇÃO:
Para evitar estouro de cota, vou solicitar o material em ETAPAS:
- Etapa 1: Estrutura e tópicos (para validação)
- Etapa 2: Conteúdo teórico (slides 1-5)
- Etapa 3: Implementação prática (slides 6-10)
- Etapa 4: Boas práticas e exercícios (slides finais)

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

---

## ⚡️ PROMPT RÁPIDO (ECONOMIA DE TOKENS)

Use esta versão quando quiser validar a estrutura primeiro e evitar respostas longas logo de cara:

```
Preciso planejar material sobre [NOME_DA_FEATURE] em Flutter. Público: alunos de graduação, nível [BÁSICO/INTERMEDIÁRIO/AVANÇADO], já sabem [PRÉ-REQUISITOS].

Objetivo: receber APENAS uma lista de tópicos e formatos sugeridos (sem detalhar conteúdo nem escrever texto didático ainda).

Peça confirmação antes de expandir: "Posso detalhar?".

Checklist mínimo:
- Teoria essencial
- Arquitetura e UI/UX
- Passo a passo prático
- Integração com [SERVIÇOS/APIs]
- Boas práticas, erros comuns, desafios avaliativos
- Materiais visuais: [TIPO_DE_VISUAL_NECESSÁRIO]
- Prompts finais para gerar [ARTEFATOS]
```

Depois de validar a lista curta, você pode pedir: "Agora detalhe cada tópico em bullets breves" e só então solicitar versões completas. Assim você controla o tamanho das respostas.

---

## 🔧 VARIÁVEIS PARA PERSONALIZAR

### `[NOME_DA_FEATURE]`
**Exemplos:**
- "a tela de autenticação"
- "o sistema de pagamentos in-app"
- "notificações push"
- "sincronização offline"
- "chat em tempo real"
- "upload de imagens e vídeos"
- "geolocalização e mapas"
- "animações e transições"

### `[DESCRIÇÃO_CONTEXTO_FEATURE]`
**Formato:** Descreva o comportamento típico da feature em apps reais

**Exemplos:**
- **Autenticação:** "o usuário pode informar suas credenciais, se registrar e recuperar senha"
- **Pagamentos:** "o usuário pode adicionar métodos de pagamento, processar compras e visualizar histórico de transações"
- **Notificações:** "o app pode receber e exibir notificações push, permitir configurações de preferências e gerenciar permissões"
- **Chat:** "usuários podem trocar mensagens em tempo real, enviar mídias e ver status de leitura"
- **Maps:** "o app pode exibir mapas interativos, marcar localização do usuário e traçar rotas"

### `[TIPO_DE_VISUAL_NECESSÁRIO]`
**Exemplos:**
- "Imagens de protótipos para essas telas"
- "Diagramas de fluxo e arquitetura"
- "Mockups de interface e componentes"
- "Wireframes e especificações de design"
- "Gráficos de performance e otimização"
- "Esquemas de integração com APIs"

### `[ARTEFATOS_FINAIS]`
**Exemplos:**
- "criar as páginas"
- "implementar o sistema completo"
- "desenvolver os componentes"
- "integrar com serviços externos"
- "otimizar a performance"

### `[NÍVEL]`
- **Básico:** Iniciantes em Flutter, conhecem Dart básico
- **Intermediário:** Já criaram apps simples, conhecem widgets e state
- **Avançado:** Dominam Flutter, querem patterns profissionais

### `[PRÉ-REQUISITOS]`
**Exemplos:**
- "Dart básico, widgets Flutter, navegação"
- "State management (Provider ou Riverpod)"
- "Consumo de APIs REST"
- "Arquitetura MVC/MVVM básica"

### `[TÓPICOS_ESPECÍFICOS_DA_FEATURE]`
**Depende da feature. Exemplos:**

**Para Pagamentos:**
- "Integração com Stripe/PayPal"
- "PCI compliance e segurança"
- "Gestão de assinaturas recorrentes"

**Para Notificações:**
- "Firebase Cloud Messaging"
- "Configuração iOS/Android"
- "Deep linking a partir de notificações"

**Para Chat:**
- "WebSockets vs Firebase Realtime"
- "Sincronização de mensagens"
- "Criptografia end-to-end (opcional)"

---

## 📚 EXEMPLOS COMPLETOS PRONTOS

### Exemplo 1: Sistema de Pagamentos

```
Vou ensinar aos alunos o sistema de pagamentos in-app em Flutter. Em uma aplicação mobile normal, o usuário pode adicionar métodos de pagamento (cartão, PIX, boleto), processar compras, visualizar histórico de transações e gerenciar assinaturas recorrentes. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo e bem estruturado
2. Mockups de telas de checkout, confirmação de pagamento e histórico
3. Boas práticas de implementação
4. Prompts para que os alunos possam usar para criar as telas de pagamento

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: Intermediário
- Já conhecem: Dart, widgets Flutter, state management básico, APIs REST
- Foco: Aplicação prática e profissional com segurança

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de pagamentos mobile
2. Arquitetura e organização do código
3. Interface de usuário e UX para pagamentos
4. Implementação prática passo a passo
5. Integração com Stripe e/ou Mercado Pago
6. PCI compliance e segurança de dados financeiros
7. Gestão de assinaturas e pagamentos recorrentes
8. Webhooks e confirmação de pagamentos
9. Boas práticas e padrões
10. Erros comuns e troubleshooting
11. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Comparações "errado vs correto"
- Material preparado para Gamma.app (slides)
- Foco em conceitos visuais, não código extenso
- Ênfase em segurança e compliance

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

### Exemplo 2: Notificações Push

```
Vou ensinar aos alunos notificações push em Flutter. Em uma aplicação mobile normal, o app pode receber e exibir notificações push do servidor, permitir que usuários configurem preferências de notificações, gerenciar permissões do sistema e processar deep links quando o usuário toca em uma notificação. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo e bem estruturado
2. Diagramas de fluxo de notificações e screenshots de configuração
3. Boas práticas de implementação
4. Prompts para que os alunos possam usar para criar o sistema de notificações

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: Intermediário
- Já conhecem: Flutter básico, state management, navegação, APIs
- Foco: Aplicação prática e profissional

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de notificações mobile
2. Arquitetura e organização do código
3. Interface de configurações de notificação
4. Implementação prática passo a passo
5. Integração com Firebase Cloud Messaging (FCM)
6. Configuração específica iOS (APNs) e Android
7. Deep linking a partir de notificações
8. Notificações locais vs remotas
9. Gerenciamento de permissões
10. Boas práticas e padrões
11. Erros comuns e troubleshooting
12. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Comparações "errado vs correto"
- Material preparado para Gamma.app (slides)
- Foco em conceitos visuais, não código extenso

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

### Exemplo 3: Chat em Tempo Real

```
Vou ensinar aos alunos sistema de chat em tempo real em Flutter. Em uma aplicação mobile normal, usuários podem trocar mensagens instantâneas, enviar imagens e arquivos, ver indicadores de digitação, status de entrega/leitura, e receber notificações de novas mensagens. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo e bem estruturado
2. Mockups de interface de chat e protótipos de interação
3. Boas práticas de implementação
4. Prompts para que os alunos possam usar para criar a interface de chat

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: Avançado
- Já conhecem: Flutter, state management avançado, APIs, WebSockets
- Foco: Aplicação prática e profissional em tempo real

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de comunicação em tempo real
2. Arquitetura e organização do código
3. Interface de usuário e UX de chat
4. Implementação prática passo a passo
5. Integração com Firebase Realtime Database ou Stream Chat
6. WebSockets vs Server-Sent Events vs Firebase
7. Sincronização de mensagens e estado offline
8. Upload de mídias (imagens, vídeos, áudio)
9. Indicadores em tempo real (digitando, online/offline)
10. Otimização de performance e scroll infinito
11. Boas práticas e padrões
12. Erros comuns e troubleshooting
13. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Comparações "errado vs correto"
- Material preparado para Gamma.app (slides)
- Foco em conceitos visuais, não código extenso
- Ênfase em performance e tempo real

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

### Exemplo 4: Geolocalização e Mapas

```
Vou ensinar aos alunos integração de geolocalização e mapas em Flutter. Em uma aplicação mobile normal, o app pode exibir mapas interativos, marcar a localização atual do usuário, buscar endereços, traçar rotas, calcular distâncias e trabalhar com geofencing. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo e bem estruturado
2. Screenshots de mapas e mockups de interface de busca de localização
3. Boas práticas de implementação
4. Prompts para que os alunos possam usar para criar funcionalidades de mapa

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: Intermediário
- Já conhecem: Flutter, APIs, permissões de sistema
- Foco: Aplicação prática e profissional

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de geolocalização mobile
2. Arquitetura e organização do código
3. Interface de mapas e controles de usuário
4. Implementação prática passo a passo
5. Integração com Google Maps / Apple Maps
6. Geolocalização (GPS, network, passive)
7. Geocoding e reverse geocoding
8. Cálculo de rotas e distâncias
9. Geofencing e location tracking
10. Gerenciamento de permissões de localização
11. Otimização de bateria
12. Boas práticas e padrões
13. Erros comuns e troubleshooting
14. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Comparações "errado vs correto"
- Material preparado para Gamma.app (slides)
- Foco em conceitos visuais, não código extenso
- Atenção a privacidade e permissões

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

---

## 🎨 TEMPLATE PARA FEATURES VISUAIS (UI/UX)

Use este quando a feature for focada em interface:

```
Vou ensinar aos alunos [COMPONENTE_UI] em Flutter. Em uma aplicação mobile profissional, [DESCRIÇÃO_USO_COMUM]. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo sobre design e UX
2. Protótipos visuais e especificações de design
3. Boas práticas de implementação e acessibilidade
4. Prompts para que os alunos possam usar para criar [COMPONENTE]

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: [NÍVEL]
- Já conhecem: Flutter básico, widgets, layouts
- Foco: UI/UX profissional e Material Design 3

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de [COMPONENTE_UI]
2. Princípios de design e UX
3. Especificações visuais (cores, tipografia, espaçamentos)
4. Implementação prática passo a passo
5. Animações e microinterações
6. Estados visuais (default, hover, pressed, disabled)
7. Responsividade e adaptação
8. Acessibilidade (a11y)
9. Temas e customização
10. Boas práticas e padrões
11. Erros comuns e troubleshooting
12. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos visuais (antes/depois, variações)
- Prompts detalhados para geração de protótipos com IA
- Material preparado para Gamma.app (slides)
- Foco em princípios de design, não apenas código
- Ênfase em acessibilidade e usabilidade

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

**Exemplos de uso:**
- `[COMPONENTE_UI]`: "bottom sheets e modais"
- `[DESCRIÇÃO_USO_COMUM]`: "o app usa bottom sheets para ações contextuais, filtros e forms sem sair da tela atual"

---

## 🔧 TEMPLATE PARA FEATURES TÉCNICAS (Backend/Infra)

Use este quando a feature for mais técnica:

```
Vou ensinar aos alunos [TECNOLOGIA_TÉCNICA] em Flutter. Em uma aplicação mobile profissional, [DESCRIÇÃO_NECESSIDADE]. O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo sobre arquitetura e padrões
2. Diagramas de arquitetura e fluxos de dados
3. Boas práticas de implementação e segurança
4. Prompts para que os alunos possam usar para implementar [FUNCIONALIDADE]

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: Avançado
- Já conhecem: Flutter, Dart, arquitetura de apps, APIs
- Foco: Padrões profissionais e escalabilidade

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de [TECNOLOGIA]
2. Arquitetura e design patterns
3. Organização e estrutura de código
4. Implementação prática passo a passo
5. Integração com [SERVIÇOS_EXTERNOS]
6. Gerenciamento de estado e cache
7. Tratamento de erros e retry logic
8. Testes (unit, integration, e2e)
9. Performance e otimização
10. Segurança e best practices
11. Monitoring e debugging
12. Erros comuns e troubleshooting
13. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Diagramas de arquitetura
- Material preparado para Gamma.app (slides)
- Foco em conceitos e padrões, não apenas código
- Ênfase em qualidade e manutenibilidade

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```

**Exemplos de uso:**
- `[TECNOLOGIA_TÉCNICA]`: "sincronização offline com cache"
- `[DESCRIÇÃO_NECESSIDADE]`: "o app precisa funcionar sem internet e sincronizar dados quando reconectar"

---

## 📊 CHECKLIST DE VALIDAÇÃO DO PROMPT

Antes de enviar seu prompt, verifique:

- [ ] **Feature bem definida?** Nome claro e contexto completo
- [ ] **Público especificado?** Nível, pré-requisitos, foco
- [ ] **Estrutura desejada?** 8-14 tópicos listados
- [ ] **Visuais especificados?** Tipo de material visual necessário
- [ ] **Qualidade definida?** Requisitos claros (comentários, slides, etc)
- [ ] **Finaliza com validação?** "Traga os pontos para eu validar"

---

## 💡 DICAS DE PERSONALIZAÇÃO

### Para Features Complexas
Adicione: "Divida em módulos progressivos (básico → intermediário → avançado)"

### Para Features com Múltiplas Plataformas
Adicione: "Inclua diferenças específicas iOS vs Android quando relevante"

### Para Features com Segurança Crítica
Adicione: "Ênfase especial em segurança, compliance e boas práticas da indústria"

### Para Features com Muitas Bibliotecas
Adicione: "Compare as principais bibliotecas disponíveis (prós, contras, quando usar)"

### Para Features Visuais
Adicione: "Inclua prompts detalhados para geração de protótipos com ferramentas de IA"

---

## 🎯 RESULTADO ESPERADO

Ao usar este template, você deve obter:

1. ✅ **Roadmap detalhado** com 10-14 seções planejadas
2. ✅ **Validação prévia** antes da criação completa
3. ✅ **Material estruturado** seguindo as melhores práticas
4. ✅ **Código comentado** em português
5. ✅ **Slides prontos** para Gamma.app
6. ✅ **Desafios práticos** com rubrica de avaliação
7. ✅ **Troubleshooting** com erros comuns

---

## 🚀 WORKFLOW COMPLETO RECOMENDADO

1. **Escolha a feature** que vai ensinar
2. **Personalize o template** com as variáveis
3. **Envie o prompt** e aguarde o roadmap
4. **Revise e valide** o roadmap proposto
5. **Aprove** e deixe a IA criar o material completo
6. **Revise seção por seção** conforme for criado
7. **Adapte para Gamma.app** usando o prompt de instruções
8. **Teste com alunos** e itere conforme feedback

---

## ⚙️ VARIAÇÕES OPCIONAIS

### Versão Minimalista (para features simples)

```
Ensinarei [FEATURE] em Flutter. Contexto: [DESCRIÇÃO_BREVE].

Preciso de:
- Material teórico
- [VISUAL_TIPO]
- Código comentado
- Boas práticas

Público: [NÍVEL], conhecem [PRÉ-REQ]

Estrutura sugerida: fundamentos → implementação → desafios

Traga os pontos para eu validar?
```

### Versão Expandida (para features muito complexas)

Adicione seções extras:
- Histórico e evolução da tecnologia
- Comparação com alternativas
- Casos de uso reais (apps famosos)
- Roadmap futuro da tecnologia
- Recursos para aprendizado contínuo
- Comunidade e suporte

---

## 📝 TEMPLATE EM BRANCO - COPIE E COMPLETE

```
Vou ensinar aos alunos _________________________ em Flutter. 

Em uma aplicação mobile normal, ________________________________________
_________________________________________________________________.

O que mais julga importante nesse processo?

Eu preciso de:
1. Material teórico completo e bem estruturado
2. _________________________________________________
3. Boas práticas de implementação
4. Prompts para que os alunos possam usar para criar _________________

CONTEXTO DO PÚBLICO:
- Alunos de graduação em Computação
- Nível: _______________
- Já conhecem: _________________________________________
- Foco: _______________________________________________

ESTRUTURA DESEJADA:
1. Fundamentos teóricos de ____________________
2. Arquitetura e organização do código
3. _____________________________________________
4. Implementação prática passo a passo
5. Integração com ______________________________
6. _____________________________________________
7. _____________________________________________
8. Boas práticas e padrões
9. Erros comuns e troubleshooting
10. Desafios práticos com critérios de avaliação

REQUISITOS DE QUALIDADE:
- Código totalmente comentado em português
- Exemplos práticos e reais
- Comparações "errado vs correto"
- Material preparado para Gamma.app (slides)
- Foco em conceitos visuais, não código extenso
- _____________________________________________

Você consegue antes me trazer os pontos que pretende abordar, por favor, para eu analisar, comentar e validar?
```
