# Prompt — Consolidação por Links (Apresentador + Nota do Avaliador + Nota do Observador)

## Objetivo
A partir de **dois links** (formulário do Avaliador e formulário do Observador), produzir:
1) **Devolutiva direta ao apresentador** + **nota final (0–100)**.
2) **Nota do Avaliador (0–100)** pela **qualidade da avaliação**.
3) **Nota do Observador (0–100)** pela **qualidade da observação**.
4) Registro claro do **porquê** não foi 100 (quando aplicável) e **EOA** (Específico, Observável e Acionável em 1 dia).

> O tom deve ser **respeitoso, claro e direto**, endereçando o **apresentador pelo nome**.

---

## Entradas
Cole apenas os **links** (HTTP/HTTPS). O assistente deve **buscar o conteúdo bruto** (raw) dos arquivos e processar:

- **Link do Formulário do Avaliador (.md):**  
  `URL_AVALIADOR = <cole aqui o link público>`

- **Link do Formulário do Observador (.md):**  
  `URL_OBSERVADOR = <cole aqui o link público>`

> Os arquivos seguem os modelos `form-avaliador-*.md` e `form-observador-*.md`.

---

## Tarefas de Coleta (obrigatórias)
1) Baixe o conteúdo de `URL_AVALIADOR` e `URL_OBSERVADOR`.  
2) Extraia:
   - **Apresentador/Avaliado (nome/repo)** e **Tema do app**.
   - **Rubrica do Avaliador** (5 critérios, cada um 0,1,2) e **justificativas/evidências**.
   - **Checklist do Observador** (Sim/Parcial/Não por subitem) e **onde viu**.
   - Campos **EOA** (útil porque / melhoraria se / onde verificar / critério de aceite).

> Se algum campo não existir, trate como **vazio** (valor 0) e registre no relatório.

---

## Cálculo da Nota do Apresentador (0–100)

### 1) Nota do Avaliador (0–10 → 0–100)
- Some os 5 critérios (0..2) = **máx 10**.
- Converta: `nota_avaliador_100 = soma * 10`.

### 2) Nota do Observador (0–10 → 0–100)
- Mapeie **Sim=2, Parcial=1, Não=0** por subitem, agregue em 5 critérios espelhados.
- Para cada critério, faça a **média** dos subitens (0..2).
- Some critérios (máx 10) → `nota_observador_100 = soma * 10`.

### 3) Nota Final do Apresentador
- **Peso**: Avaliador **60%**, Observador **40%**  
  `nota_final = 0.6 * nota_avaliador_100 + 0.4 * nota_observador_100`

### 4) Penalidades automáticas (aplicar no fim)
- **–5** se **não** houver evidências mínimas (prints/GIFs **ou** commits/PR **ou** README).
- **–2 por critério** (máx –6) se houver **inconsistência** A×O (diferença ≥2 pontos em 0..2).
- **Floor/cap**: limite entre **0 e 100**.

---

## Nota do Avaliador (qualidade da avaliação) — 0–100
Avalie **como** o avaliador avaliou (não o app), com pesos:

1) **Completude estrutural** (preencheu todos os campos e justificou cada critério) — **25%**  
   - (0) faltam campos/sem justificativas  
   - (50) parcialmente preenchido  
   - (100) completo e coerente

2) **Qualidade das evidências** (prints/links/commits localizáveis e pertinentes) — **25%**  
   - (0) sem evidências ou irrelevantes  
   - (50) evidências genéricas  
   - (100) evidências específicas e verificáveis

3) **Calibração com Observação** (diferença média ≤0.5 em 0..2) — **25%**  
   - (0) dif. média ≥1.5  
   - (50) 0.5–1.49  
   - (100) <0.5

4) **EOA do avaliador** (seus itens são Específicos, Observáveis e Acionáveis em 1 dia) — **25%**  
   - (0) ausente/vago  
   - (50) parcialmente EOA  
   - (100) 2 itens EOA claros (o que/onde/como/aceite)

**Penalidade**: –10 se o avaliador **não** indicou **onde verificar** (arquivo/rota/commit) em 3+ itens.  
**Cálculo**: média ponderada (25/25/25/25) – penalidade, cap 0..100.

---

## Nota do Observador (qualidade da observação) — 0–100
Avalie **como** o observador observou, com pesos:

1) **Cobertura da checklist** (marcou e descreveu “onde vi” nos subitens) — **30%**  
   - (0) lacunas graves  
   - (50) parcial  
   - (100) completa

2) **Especificidade/Localização** (telas/rotas/commits apontados com precisão) — **30%**  
   - (0) genérico  
   - (50) moderado  
   - (100) altamente preciso

3) **Consistência com a avaliação** (alinhamento com a rubrica do avaliador) — **20%**  
   - (0) divergente  
   - (50) parcialmente alinhado  
   - (100) bem alinhado

4) **EOA do observador** (2 itens EOA válidos) — **20%**  
   - (0) ausente/vago  
   - (50) parcialmente EOA  
   - (100) EOA completo (o que/onde/como/aceite)

**Penalidade**: –10 se não houver **quaisquer** exemplos de evidência concreta (“onde vi”).  
**Cálculo**: média ponderada (30/30/20/20) – penalidade, cap 0..100.

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
> Enderece **diretamente ao apresentador** (use o nome extraído dos arquivos).

**[Saudação], [Nome do Apresentador].**

**Nota final do seu protótipo:** X/100  
- Avaliador: Y/100 (60%)  
- Observador: Z/100 (40%)  
- Penalidades: [listar se houve]

### Por que não foi 100
- [Critério] — [Resumo do gap] — **Onde verificar:** [arquivo/rota/print/commit]  
- (repita conforme necessário)

### Devolutiva formativa (EOA — 1 dia)
1) **Útil porque…** [...]  
   **Melhoraria se…** [...]  
   **Onde verificar:** [...]  
   **Critério de aceite:** [...]

2) **Útil porque…** [...]  
   **Melhoraria se…** [...]  
   **Onde verificar:** [...]  
   **Critério de aceite:** [...]

### Evidências consideradas
- [links de commits/PRs, prints, README]

---

## Notas de metaavaliação
- **Qualidade do Avaliador:** A/100 (com breve justificativa por eixo 25/25/25/25 e eventual penalidade).  
- **Qualidade do Observador:** B/100 (com breve justificativa por eixo 30/30/20/20 e eventual penalidade).

**Próximos passos:**  
- Apresentador: implementar EOA e registrar no `README.md` + `docs/reviews/YYYY-MM-DD/evidences/`.  
- Avaliador e Observador: ajustar futuras submissões para **maximizar especificidade, evidência e EOA**.
