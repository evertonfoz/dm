# Formulário do Avaliador — Gallery Walk (Peer-review rápido)

> **Objetivo**: avaliar de forma **Específica, Observável e Acionável (EOA)**, gerando feedback formativo que possa ser **implementado em 1 dia**.

## Identificação
- **Avaliado (nome/repo):** __________________________________________
- **Tema do aplicativo avaliado:** ___________________________________
- **Avaliador:** ______________________________________________________
- **Turma/Trio:** ____________________  **Data:** ____/____/________

---

## Rubrica (0, 1, 2) — marque e justifique brevemente
> **Como preencher:** para cada critério, atribua **0, 1 ou 2** e **diga onde você viu** (ex.: tela/rota, print, commit/PR, arquivo). Use os exemplos em “Como evidenciar” abaixo de cada item.

### 1) Fluxo Claro (dots / pular / splash)  __/2  
**O que observar:**  
- Dots do onboarding certos (sincronizados e **sem dots na última tela**).  
- **Pular** leva ao **Consentimento** (não “saltar para a Home”).  
- **Splash** decide a rota com base na **versão aceita** das políticas.  

**Como evidenciar (exemplos):**  
- _Print_ do onboarding (última tela sem dots).  
- Rota/navegação: `onboarding → consent` ao tocar “Pular”.  
- Vídeo/print do **primeiro lançamento** mostrando a decisão do Splash.  
- _Commit/PR_ com a lógica de rota.

**Justificativa curta:** ___________________________________________________

---

### 2) Legal & Consentimento (viewer / aceite / versão / revogação)  __/2  
**O que observar:**  
- **Viewer** de políticas com **barra de progresso**.  
- **“Marcar como lido” só habilita ao final** (após percorrer o texto).  
- **Aceite somente após 2 leituras** + **versão** registrada.  
- **Como revogar/desfazer** o consentimento está claro na UI.  

**Como evidenciar (exemplos):**  
- Print do botão “Marcar como lido” **desabilitado** → **habilitado** no final.  
- Demonstração das **2 leituras** e do **aceite**.  
- _Commit/PR_ com o registro da **versão** (ex.: chave/enum/Prefs/DB).  
- Print/vídeo da **tela de revogação** ou caminho para desfazer.

**Justificativa curta:** ___________________________________________________

---

### 3) Acessibilidade (48dp / contraste / foco / botões)  __/2  
**O que observar:**  
- Alvos táteis ≥ **48dp**.  
- **Contraste** adequado (texto e ícones).  
- **Foco visível** (navegação por teclado/leitor de tela).  
- Botões **desabilitados** com **estado perceptível** e descrição acessível.  

**Como evidenciar (exemplos):**  
- Print com _rulers_ mostrando 48dp.  
- Captura com **foco** destacado.  
- _Commit/PR_ com estilo/tema de contraste ou labels de acessibilidade.

**Justificativa curta:** ___________________________________________________

---

### 4) Evidências & Registro (prints / README.md / commit)  __/2  
**O que observar:**  
- Evidências (prints/GIFs curtos) **anexadas**.  
- **README.md** (ou docs) atualizado com o fluxo e decisões.  
- **Commits/PRs** relacionados à entrega (mensagens claras).  

**Como evidenciar (exemplos):**  
- Links para `/docs/` (prints/GIFs).  
- Link do **README.md** com seção “Fluxo inicial e consentimento”.  
- IDs de **commits/PRs** que implementam onboarding/policies/splash.

**Justificativa curta:** ___________________________________________________

---

### 5) Identidade Visual (ColorScheme sem “cores mágicas”)  __/2  
**O que observar:**  
- Uso consistente do **ColorScheme/tema** (Material 3).  
- Sem “**cores mágicas**” hard-coded; cores vêm do tema.  

**Como evidenciar (exemplos):**  
- _Commit/PR_ mostrando uso de `Theme.of(context).colorScheme`.  
- Print de telas coerentes entre si (variações de estado no tema).

**Justificativa curta:** ___________________________________________________

---

## Total:  __/10  
> **Interpretação rápida**:  
> - **9–10**: pronto para mostrar, foque refinamentos finos.  
> - **8**: apto ao Gallery Walk; priorize os ajustes descritos no EOA.  
> - **≤7**: antes do Gallery Walk, implemente primeiro as correções EOA.

---

## EOA — Feedback principal (executável em 1 dia)
> **O que é EOA?**  
> **E**specífico: diz **exatamente** o que mudar (componente/rota/arquivo).  
> **O**bservável: pode ser **verificado** (print, vídeo, teste, trecho de código).  
> **A**cionável (em 1 dia): cabe em **uma iteração curta**, sem dependências grandes.

- **Útil porque…** _(valor percebido pelo usuário/negócio/UX)_  
  → ______________________________________________________________________

- **Melhoraria se…** _(ação concreta em 1 dia, indicando onde e como)_  
  → ______________________________________________________________________

**Onde verificar (evidência esperada):**  
- Arquivo/rota/widget: _________________________________________________  
- Commit/PR esperado: _________________________________________________  
- Critério de aceite (como saberei que ficou pronto?): ___________________

---

## Como registrar os pontos (padrão do repositório)
> **Siga este padrão para facilitar o cruzamento com a observação:**
1. **Crie a pasta**: `docs/reviews/YYYY-MM-DD/`  
2. **Salve este arquivo** como: `docs/reviews/YYYY-MM-DD/form-avaliador-<avaliado>.md`  
3. **Anexe evidências** (prints/GIFs curtos) em `docs/reviews/YYYY-MM-DD/evidences/` e **referencie** no texto.  
4. **Relacione commits/PRs** (IDs/links) na justificativa de cada critério.  
5. **Abra uma issue “Warm-up” (opcional)** com o resumo EOA e links deste formulário + observação.

---

### Guia rápido de pontuação (auto-checagem do avaliador)
- **0**: requisito não atendido ou confuso; faltam evidências.  
- **1**: parcialmente atendido; há evidências, mas com lacunas.  
- **2**: claramente atendido; evidências objetivas e localizáveis.
