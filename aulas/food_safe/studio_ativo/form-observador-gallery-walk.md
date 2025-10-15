# Formulário do Observador — Gallery Walk (Observação rápida)

> **Objetivo**: registrar **evidências observáveis** do fluxo apresentado e produzir feedback **EOA** (Específico, Observável e Acionável) que possa ser **implementado em 1 dia**, facilitando o **cruzamento** com o Formulário do Avaliador.

## Identificação
- **Expositor (nome/repo):** __________________________________________
- **Tema do aplicativo observado:** ___________________________________
- **Observador:** ______________________________________________________
- **Rodada:** 1 ☐ 2 ☐   **Data:** ____/____/________   **Horário:** ______:____

---

## Como observar (roteiro de 90 segundos)
> **Siga o fluxo** demonstrado: **Splash → Onboarding → Políticas (viewer) → Consentimento → Home**  
> Marque a checklist e anote **onde** você viu cada evidência (tela/rota/print/commit).

---

## Mini-Checklist (Sim / Parcial / Não) + Evidência
> **Como preencher:** Marque **Sim/Parcial/Não** e descreva **onde** verificou (ex.: “tela X”, “rota onboarding→consent”, “print Y”, “commit abc123”).

### 1) Fluxo Claro (dots / pular / splash)
- **Dots** sincronizados e **ocultos na última tela**.  **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **“Pular”** leva ao **Consentimento** (não salta para a Home). **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Splash** decide a rota pela **versão aceita** das políticas. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________

### 2) Legal & Consentimento (viewer / aceite / versão / revogação)
- **Viewer** de políticas com **progresso** visível. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **“Marcar como lido”** só **habilita ao final** do texto. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Aceite após 2 leituras** + **versão** registrada. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Revogar/Desfazer** consentimento está claro na UI. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________

### 3) Acessibilidade (48dp / contraste / foco / botões)
- Alvos táteis ≥ **48dp** (toque confortável). **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Contraste** suficiente (texto/ícones). **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Foco visível** (teclado/leitor de tela). **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- Botões **desabilitados** são perceptíveis/acessíveis. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________

### 4) Evidências & Registro (prints / README.md / commit)
- Há **prints/GIFs** anexados ou referenciados. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **README.md/docs** descrevem **fluxo e decisões**. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Commits/PRs** evidenciam a entrega. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi (IDs/links):** ______________________________________________

### 5) Identidade Visual (ColorScheme sem “cores mágicas”)
- Uso consistente de **ColorScheme/tema** (Material 3). **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________
- **Sem** “cores mágicas” hard-coded. **Sim ☐  Parcial ☐  Não ☐**  
  **Onde vi:** __________________________________________________________

---

## EOA — Feedback principal (executável em 1 dia)
> **O que é EOA?**  
> **E**specífico: diga **exatamente** o que mudar (componente/rota/arquivo).  
> **O**bservável: algo que possa ser **verificado** (print, vídeo, teste, código).  
> **A**cionável (em 1 dia): que caiba em **uma iteração curta**.

- **Útil porque…** _(valor para usuário/negócio/UX)_  
  → ______________________________________________________________________

- **Melhoraria se…** _(ação concreta em 1 dia; indique onde e como)_  
  → ______________________________________________________________________

**Onde verificar (evidência esperada):**  
- Arquivo/rota/widget: _________________________________________________  
- Commit/PR esperado: _________________________________________________  
- Critério de aceite (como saberei que ficou pronto?): ___________________

---

## Post-its para o Gallery Walk
- **Verde — “Útil porque…”** ____________________________________________  
- **Amarelo — “Melhoraria se (1 dia)…”** _________________________________

> Dica: mantenha as frases **curtas e claras**; objetivo é facilitar a ação imediata.

---

## Como registrar os pontos (padrão do repositório)
> **Padronize** para facilitar o cruzamento com o **Formulário do Avaliador**:
1. **Crie a pasta**: `docs/reviews/YYYY-MM-DD/`  
2. **Salve este arquivo** como: `docs/reviews/YYYY-MM-DD/form-observador-<expositor>.md`  
3. **Anexe evidências** (prints/GIFs curtos) em `docs/reviews/YYYY-MM-DD/evidences/` e **referencie** neste arquivo.  
4. **Aponte commits/PRs** (IDs/links) quando citá-los nas respostas.  
5. (Opcional) **Comente na issue “Warm-up”** do repositório com um resumo EOA + link deste formulário.

---

### Legenda de marcação (para referência rápida)
- **Sim**: requisito claramente observado.  
- **Parcial**: observado com lacunas/ambiguidade.  
- **Não**: não observado ou contraditório.

