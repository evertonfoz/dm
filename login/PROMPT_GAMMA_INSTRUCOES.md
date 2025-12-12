# PROMPT PARA CAMPO "INSTRUÇÕES ADICIONAIS" - GAMMA.APP

## 📋 Copie e cole este prompt no campo "Instruções adicionais"

---

## PROMPT COMPLETO:

```
DIRETRIZES DE CRIAÇÃO DE SLIDES - AUTENTICAÇÃO FLUTTER

FOCO PRINCIPAL: Conceitos visuais, diagramas e compreensão, NÃO código extenso.

═══════════════════════════════════════════════════════════

REGRAS OBRIGATÓRIAS:

1. CÓDIGO - USE COM EXTREMA MODERAÇÃO:
   ❌ NUNCA mostre blocos de código com mais de 7 linhas
   ❌ NUNCA mostre código completo de classes ou arquivos
   ✅ Use APENAS snippets específicos de 3-5 linhas que ilustrem UM conceito
   ✅ Destaque apenas a linha/trecho relevante para o ponto do slide
   ✅ Priorize pseudocódigo ou diagramas quando possível

2. ESTRUTURA DE CADA SLIDE:
   ✅ Título claro e objetivo
   ✅ 1 conceito principal por slide (máximo 2)
   ✅ 3-5 bullets concisos com palavras-chave
   ✅ 1 elemento visual (diagrama, ícone, ilustração)
   ✅ Exemplo prático quando relevante

3. ELEMENTOS VISUAIS PRIORITÁRIOS:
   ✅ Diagramas de fluxo (ex: fluxo de login, oauth, magic link)
   ✅ Comparações lado a lado (❌ errado vs ✅ correto)
   ✅ Ícones e emojis para conceitos (🔒 segurança, ⚡ performance)
   ✅ Boxes coloridos para categorizar (info, aviso, dica, erro)
   ✅ Checklists visuais
   ✅ Antes/Depois de implementações
   ✅ Esquemas de arquitetura

4. LINGUAGEM:
   ✅ Concisa e direta
   ✅ Analogias e metáforas para conceitos complexos
   ✅ Exemplos do mundo real
   ✅ Evite jargão excessivo
   ✅ Use voz ativa

5. QUANDO INCLUIR CÓDIGO (apenas nestes casos):
   ✅ Demonstrar sintaxe crítica (ex: como chamar signInWithPassword)
   ✅ Mostrar diferença entre abordagem errada e correta
   ✅ Ilustrar padrão específico (ex: estrutura de validator)
   ✅ Exemplo mínimo funcional (3-5 linhas máximo)

6. EXEMPLOS DE TRANSFORMAÇÃO:

   ❌ NÃO FAÇA ASSIM:
   "Aqui está o código completo do AuthService com todos os métodos..."
   [30 linhas de código]

   ✅ FAÇA ASSIM:
   "Método Principal: signIn()"
   [Diagrama: Email/Senha → Supabase → Token → Sessão]
   Snippet foco:
   ```dart
   await supabase.auth.signInWithPassword(
     email: email, password: password
   );
   ```

7. SLIDES ESPECIAIS:

   PARA SEÇÃO SUPABASE:
   - Mostre dashboard (screenshots)
   - Fluxogramas de OAuth
   - Diagramas de deep linking
   - MÍNIMO de código

   PARA SEÇÃO DESIGN:
   - Mockups visuais
   - Paleta de cores
   - Anatomia de telas
   - Especificações visuais

   PARA SEÇÃO DESAFIOS:
   - Tabelas de requisitos
   - Rubrica visual
   - Checklists
   - Níveis de dificuldade visual

   PARA SEÇÃO ERROS:
   - Comparação ❌ vs ✅
   - Sintomas visuais
   - Soluções em bullets
   - Código APENAS se essencial (máx 4 linhas)

8. HIERARQUIA VISUAL:
   - Títulos: Grande, bold
   - Subtítulos: Médio, destaque
   - Corpo: Bullets, conciso
   - Código: Pequeno, background diferente
   - Notas: Fonte menor, cor secundária

9. DENSIDADE DE INFORMAÇÃO:
   ✅ Máximo 30-40 palavras por slide (exceto diagramas)
   ✅ Espaço em branco generoso
   ✅ Progressão gradual de conceitos
   ✅ Um slide para introduzir, outro para detalhar

10. TRANSIÇÕES ENTRE SLIDES:
    ✅ Cada slide conecta com o anterior
    ✅ Use "Resumindo...", "Próximo passo...", "Na prática..."
    ✅ Recapitule conceito anterior antes de avançar

═══════════════════════════════════════════════════════════

LEMBRE-SE: Este material é para ENSINAR conceitos, não para ser um manual de código. O objetivo é que o aluno COMPREENDA e depois consulte o código completo na documentação escrita.

PRIORIDADE: Clareza > Completude | Conceitos > Sintaxe | Visual > Textual
```

---

## VARIAÇÃO CURTA (se o campo tiver limite de caracteres):

```
FOCO: Conceitos visuais e diagramas, NÃO código extenso.

REGRAS:
• Código: máximo 5 linhas por slide, apenas quando essencial
• Use diagramas de fluxo, comparações ❌/✅, ícones
• 1 conceito por slide, 3-5 bullets concisos
• Priorize: analogias, exemplos práticos, elementos visuais
• Para Supabase: screenshots e fluxogramas
• Para Design: mockups e paletas
• Para Erros: comparações visuais
• Densidade: 30-40 palavras/slide, espaço em branco generoso
• Objetivo: COMPREENSÃO, não manual de código

QUANDO INCLUIR CÓDIGO:
• Sintaxe crítica (ex: signInWithPassword)
• Padrão específico (ex: validator)
• Comparação errado vs correto
• Máximo 3-5 linhas, destacar linha relevante
```

---

## PROMPT ALTERNATIVO - ESTILO DIRETIVO:

```
INSTRUÇÕES CRÍTICAS PARA CRIAÇÃO DOS SLIDES:

🎯 OBJETIVO: Apresentação visual e conceitual sobre autenticação Flutter, NÃO documentação de código.

🚫 PROIBIÇÕES ABSOLUTAS:
- Blocos de código com mais de 7 linhas
- Código completo de classes ou métodos
- Texto denso sem hierarquia visual
- Múltiplos conceitos complexos no mesmo slide

✅ OBRIGAÇÕES:
- Cada slide: 1 conceito + elemento visual + bullets curtos
- Código: SOMENTE snippets de 3-5 linhas para ilustrar ponto específico
- Priorizar: diagramas, fluxogramas, comparações, ícones, checklists
- Linguagem: concisa, analogias, exemplos práticos
- Densidade: máximo 40 palavras/slide (excluindo diagramas)

📊 ELEMENTOS VISUAIS PREFERENCIAIS:
• Fluxogramas de autenticação
• Diagramas de arquitetura
• Comparações ❌ ERRADO vs ✅ CORRETO
• Screenshots de configuração
• Esquemas de componentes
• Checklists visuais
• Ícones conceituais (🔒 segurança, ⚡ performance, 🎨 design)

🎨 TRATAMENTO POR SEÇÃO:

FUNDAMENTOS (1-6): Diagramas conceituais, analogias, fluxos
IMPLEMENTAÇÃO (7-10): Arquitetura visual, padrões, fluxogramas
SUPABASE (11): Screenshots dashboard, fluxo OAuth, deep linking
DESIGN (12): Mockups, paletas, anatomia de telas, especificações
DESAFIOS (13): Tabelas requisitos, rubrica visual, níveis
ERROS (14): Comparações ❌/✅, sintomas, soluções em bullets

💡 EXEMPLO DE BOM SLIDE:
Título: "Fluxo de Login com Supabase"
[Diagrama: Usuário → Input → Supabase Auth → Token → App]
Bullets:
• Validação client-side primeiro
• Token armazenado automaticamente
• Sessão persiste entre aberturas
Snippet (opcional):
await supabase.auth.signInWithPassword(...)

❌ EXEMPLO DE MAU SLIDE:
[30 linhas de código da classe AuthService completa]

RESULTADO ESPERADO: Slides visuais, conceituais e engajadores que ensinem através de compreensão, não memorização de código.
```

---

## 🎯 QUAL USAR?

- **PROMPT COMPLETO**: Se o campo aceita texto longo (recomendado)
- **VARIAÇÃO CURTA**: Se houver limite de caracteres
- **ESTILO DIRETIVO**: Se você quiser ser mais enfático e direto

---

## 💡 DICAS DE USO NO GAMMA:

1. **Cole o prompt no campo "Instruções adicionais"**
2. **Mantenha as configurações**:
   - Quantidade de texto: "Detalhado" ou "Conciso" (teste ambos)
   - Idioma: Português (Brasil)
   - Tema visual: Escolha um clean (Iris, Zephyr, Cornfield)

3. **Após gerar os slides**:
   - Revise slide por slide
   - Remova código excessivo se aparecer
   - Adicione elementos visuais manualmente se necessário
   - Verifique se cada slide tem 1 conceito claro

4. **Ajustes manuais comuns**:
   - Substituir código longo por diagrama
   - Adicionar ícones aos bullets
   - Criar comparações lado a lado
   - Inserir screenshots do Supabase

---

## 📋 CHECKLIST PÓS-GERAÇÃO:

Para cada slide, pergunte:
- [ ] Tem mais de 7 linhas de código? → Reduza para 3-5 ou remova
- [ ] Tem elemento visual? → Se não, adicione
- [ ] Foca em 1 conceito? → Se não, divida em 2 slides
- [ ] Texto conciso (≤40 palavras)? → Se não, sintetize
- [ ] Usa analogias/exemplos? → Prefira sobre jargão
- [ ] Código é essencial? → Se não for, remova

---

## 🎨 SUGESTÕES VISUAIS ESPECÍFICAS:

**Seção 1 (Fundamentos):**
- Diagrama: Autenticação vs Autorização (porteiro vs chaves)
- Fluxo: Jornada do usuário desde login até acesso

**Seção 7 (Estado):**
- Diagrama: Estados de autenticação (círculos conectados)
- Fluxo: Como state muda durante login

**Seção 11 (Supabase):**
- Screenshot: Dashboard Supabase
- Diagrama: Fluxo OAuth (App → Google → Supabase → App)
- Diagrama: Deep linking (Email → Link → App)

**Seção 12 (Design):**
- Paleta de cores visual
- Anatomia de tela de login (wireframe anotado)
- Antes/depois de aplicar Material Design 3

**Seção 14 (Erros):**
- Grid 2x2: ❌ Errado | ✅ Correto (para cada erro principal)
- Checklist visual de validações

---

## ⚠️ AVISOS IMPORTANTES:

1. **O Gamma pode ignorar**: Mesmo com instruções, a IA pode gerar código extenso. Esteja preparado para editar manualmente.

2. **Iteração**: Gere os slides, revise, e se necessário, regenere seções específicas com instruções mais diretas.

3. **Use "Editar com IA"**: Para slides problemáticos, use a função de edição com IA do Gamma e diga: "Remova o código e substitua por um diagrama conceitual sobre [tópico]"

4. **Templates visuais**: Escolha templates que favoreçam elementos visuais sobre texto (Iris, Wireframe são bons)

---

## 🚀 EXEMPLO DE INSTRUÇÃO POR SEÇÃO:

Você pode adicionar instruções específicas ao processar cada seção:

**Para Seção 1:**
"Crie slides focados em CONCEITOS fundamentais com analogias do dia a dia. Use diagramas, NÃO código."

**Para Seção 11:**
"Crie slides com SCREENSHOTS e FLUXOGRAMAS de Supabase. Código apenas para chamadas de API (3 linhas max)."

**Para Seção 14:**
"Crie slides com COMPARAÇÕES VISUAIS (❌ vs ✅) dos erros comuns. Código mínimo, foco em solução conceitual."

---

Boa sorte com a criação dos slides! 🎉
