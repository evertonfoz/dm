# Prompt — Consolidação por Links (Apresentador + Nota do Avaliador + Nota do Observador)

## Objetivo
A partir de **dois links** (formulário do Avaliador e formulário do Observador), produzir:
1) **Devolutiva direta ao apresentador** + **nota final (0–100)**.
2) **Nota do Avaliador (0–100)** pela **qualidade da avaliação** (metaavaliação do avaliador).
3) **Nota do Observador (0–100)** pela **qualidade da observação** (metaavaliação do observador).
4) Registro claro do **porquê** não foi 100 (quando aplicável) e **EOA** (Específico, Observável e Acionável em 1 dia).

> O tom ao apresentador deve ser **respeitoso, claro e direto**, endereçando-o **pelo nome**.  
> O tom na mensagem ao **Observador** deve ser **informal**, começando pelo **primeiro nome**.

---

## Entradas
Cole apenas os **links** (HTTP/HTTPS). O assistente deve **buscar o conteúdo bruto** (raw) dos arquivos e processar:

- **Link do Formulário do Avaliador (.md):**  
  `URL_AVALIADOR = <cole aqui o link público>`

- **Link do Formulário do Observador (.md):**  
  `URL_OBSERVADOR = <cole aqui o link público>`

> Os arquivos seguem os modelos `form-avaliador-*.md` e `form-observador-*.md`.

**Comportamento quando faltar link:**
- Se **só houver Observador**: calcule a **nota do Observador (checklist) para o apresentador** e a **metaavaliação da qualidade da observação**; marque a parte do Avaliador como **pendente**, **sem punir** o apresentador.
- Se **só houver Avaliador**: calcule a **nota do Avaliador (rubrica) para o apresentador** e a **metaavaliação da qualidade da avaliação**; marque a parte do Observador como **pendente**, **sem punir** o apresentador.

---

## Tarefas de Coleta (obrigatórias)
1) Baixe o conteúdo de `URL_AVALIADOR` e `URL_OBSERVADOR`.  
2) Extraia (quando existir em cada arquivo):
   - **Apresentador/Avaliado** (nome e repositório) e **Tema do app**.
   - **Rubrica do Avaliador** (5 critérios, cada um 0,1,2) e **justificativas/evidências**.
   - **Checklist do Observador** (Sim/Parcial/Não por subitem) e **“onde vi”**.
   - Campos **EOA** (útil porque / melhoraria se / onde verificar / critério de aceite).

> Se algum campo não existir, trate como **vazio** (valor 0) e registre no relatório.

---

## Cálculo da **Nota do Apresentador** (0–100)

### 1) Componente do Avaliador (0–10 → 0–100)
- Some os 5 critérios (0..2) = **máx 10**.  
- Converta: `nota_avaliador_100 = soma * 10`.  
- Se não houver rubrica do Avaliador, deixe como **pendente** e **não aplique penalidade**.

### 2) Componente do Observador (0–10 → 0–100)
- Mapeie **Sim=2, Parcial=1, Não=0** para cada **subitem** da checklist.  
- Para cada **um dos 5 critérios espelhados**, faça a **média** dos subitens (0..2).  
- Some os 5 critérios (máx 10) → `nota_observador_100 = soma * 10`.  
- Se não houver checklist do Observador, deixe como **pendente** e **não aplique penalidade**.

### 3) Nota Final do Apresentador
- **Peso**: Avaliador **60%**, Observador **40%**  
  `nota_final = 0.6 * nota_avaliador_100 + 0.4 * nota_observador_100`
- Se um dos dois estiver **pendente**, **informe a nota parcial** e que a final será recalculada quando o insumo chegar.

### 4) Penalidades automáticas (aplicar no fim, apenas se ambos os insumos permitirem a verificação)
- **–5** se **não** houver **qualquer** evidência mínima (prints/GIFs **ou** commits/PR **ou** README).
- **–2 por critério** (máx –6) se houver **inconsistência** Avaliador×Observador (diferença **≥ 2 pontos** em 0..2) **no mesmo critério**.  
- **Floor/cap**: limite entre **0 e 100**.

> **Importante:** Não aplique **inconsistência A×O** se um dos lados estiver **pendente**.

---

## Metaavaliações (não entram na nota do apresentador)

### A) **Nota do Avaliador (qualidade da avaliação)** — 0–100
Avalie **como** o avaliador avaliou, com pesos:
1) **Completude estrutural** (preencheu todos os campos e justificou cada critério) — **25%**  
   - (0) faltam campos/sem justificativas | (50) parcial | (100) completo e coerente
2) **Qualidade das evidências** (prints/links/commits localizáveis) — **25%**  
   - (0) sem/irrelevantes | (50) genéricas | (100) específicas e verificáveis
3) **Calibração com Observação** (diferença média ≤0.5 em 0..2) — **25%**  
   - (0) ≥1.5 | (50) 0.5–1.49 | (100) <0.5
4) **EOA do avaliador** (2 itens EOA claros) — **25%**  
   - (0) ausente/vago | (50) parcial | (100) dois EOAs completos

**Penalidade**: –10 se **não** indicou “onde verificar” (arquivo/rota/commit) em **3+ itens**.  
**Cálculo**: média ponderada – penalidade, cap 0..100.

> Se não houver avaliador, marque **pendente**.

### B) **Nota do Observador (qualidade da observação)** — 0–100
Avalie **como** o observador observou, com pesos:
1) **Cobertura da checklist** (marcou e descreveu “onde vi”) — **30%**  
   - (0) lacunas graves | (50) parcial | (100) completa
2) **Especificidade/Localização** (rotas/telas/commits apontados) — **30%**  
   - (0) genérico | (50) moderado | (100) preciso
3) **Consistência com a avaliação** (alinhamento com a rubrica) — **20%**  
   - (0) divergente | (50) parcialmente | (100) bem alinhado
4) **EOA do observador** (2 itens EOA válidos) — **20%**  
   - (0) ausente/vago | (50) parcial | (100) completo

**Penalidade**: –10 se **não houver quaisquer** exemplos de evidência concreta (“onde vi”).  
**Cálculo**: média ponderada – penalidade, cap 0..100.

> **Distinção fundamental:**  
> • **Nota do Observador (checklist → 0..100)** entra nos **40% da nota do apresentador**.  
> • **Nota da Qualidade da Observação (0..100)** é **metaavaliação** do observador (não compõe a nota do apresentador).

---

## Regras de Justificativa (<100 do apresentador)
Crie a seção "**Por que não foi 100**" listando **critérios com desconto**, do maior para o menor, citando **onde verificar** (arquivo/rota/print/commit). Aponte se houve **penalidade** (evidências/inconsistência).

---

## EOA — Feedback (obrigatório, 2 itens)
- **Útil porque…** (valor)  
- **Melhoraria se…** (ação em 1 dia; o que/onde/como)  
- **Onde verificar** (arquivo/rota/widget; commit/PR)  
- **Critério de aceite** (teste objetivo)

> Se EOA vier vazio nos formulários, **proponha** 2 itens EOA a partir dos gaps.

---

## Formato de Saída (obrigatório)

### 1) Mensagem ao **Apresentador** (use o nome completo extraído)
**[Saudação], [Nome do Apresentador].**

**Nota final do seu protótipo:** X/100  
- Avaliador: Y/100 (**60%**)  
- Observador (checklist): Z/100 (**40%**)  
- Penalidades: [listar se houve]  
- Itens pendentes: [“Avaliador” ou “Observador”], se aplicável

#### Por que não foi 100
- [Critério] — [Resumo do gap] — **Onde verificar:** [arquivo/rota/print/commit]  
- (repita conforme necessário)

#### Devolutiva formativa (EOA — 1 dia)
1) **Útil porque…** [...]  
   **Melhoraria se…** [...]  
   **Onde verificar:** [...]  
   **Critério de aceite:** [...]

2) **Útil porque…** [...]  
   **Melhoraria se…** [...]  
   **Onde verificar:** [...]  
   **Critério de aceite:** [...]

#### Evidências consideradas
- [links de commits/PRs, prints, README]

---

### 2) Mensagem ao **Observador** (tom **informal**, começar pelo **primeiro nome**)

**Modelo** (preencha com a metaavaliação calculada):
> **[PrimeiroNome]**, **[NotaQualidadeObservacao]/100** na **qualidade da observação**. Você cobriu [resumo da cobertura], mas [apontar brevemente os pontos a melhorar: especificidade de “onde vi”, precisão de rotas/telas/commits e **dois EOAs completos** com o que/onde/como/critério de aceite].  
> Pra próxima: marque exatamente “onde vi” (ex.: `lib/...`, rota `...`, commit `abc123`) e escreva **2 EOAs verificáveis**; isso deixa o feedback cirúrgico e fecha os gaps de forma objetiva.  
> Se achar que algum ponto foi lido pela metade ou quiser **questionar a avaliação**, mande **links/prints/commits** e diga o que você mesmo entende que **precisa** ou **deve** melhorar na sua observação. Com esses insumos, eu reviso e **atualizo a nota** se fizer sentido.

---

### 3) Notas de metaavaliação (resumo numérico)
- **Qualidade do Avaliador:** A/100 (com breve justificativa por eixo 25/25/25/25 e eventual penalidade).  
- **Qualidade da Observação:** B/100 (com breve justificativa por eixo 30/30/20/20 e eventual penalidade).

**Próximos passos:**  
- **Apresentador:** implementar os EOAs e registrar no `README.md` + `docs/reviews/YYYY-MM-DD/evidences/`.  
- **Avaliador e Observador:** maximizar **especificidade**, **evidência** e **EOA** nas próximas submissões.

---

## Regras de Nome
- Extraia o **Nome do Apresentador** dos arquivos (dar preferência a “Nome + e-mail” do bloco de identificação).  
- Para o **Observador**, use o **primeiro nome** (se não for possível extrair com segurança, use o nome completo).  
- Se não encontrar o nome do apresentador: use “**Apresentador**” como fallback e registre a ausência.

---
