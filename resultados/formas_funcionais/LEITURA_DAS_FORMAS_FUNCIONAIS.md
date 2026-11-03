# Comparação exploratória de formas funcionais

Esta nota é gerada por `04_formas_funcionais.R`. É uma comparação exploratória, motivada por diagnósticos já observados nos mesmos dados: os valores-p não têm o significado de hipóteses fixadas antes de olhar os resultados. Nenhuma transformação demonstra causalidade ou corrige automaticamente a dependência dos erros entre estudantes.

## Síntese

**Recomendação provisória: manter A (Modelo 3, linear) como especificação principal, sem apresentá-la sozinha: C (com distance²) e P2 (log de distance, sem os zeros) devem aparecer ao lado.** A evidência não distingue claramente as alternativas: a diferença de R² ajustado é inferior a 0,001 em cada comparação, e o RESET e o Breusch-Pagan continuam rejeitando em todas.

O que muda a leitura é a magnitude em distâncias típicas. O coeficiente de A (-0,024 ano por 10 milhas) é um resumo muito influenciado por distâncias longas: os 290 estudantes acima de 50 milhas (6,1% da amostra) têm 64% do peso nele. Na distância mediana (10 milhas), C e P2 indicam inclinações mais fortes, de -0,060 e -0,054, mas com intervalos largos. O sinal negativo em distâncias típicas se mantém; a magnitude depende da forma.

## O que motivou cada alternativa

- **B (score²):** a etapa de diagnósticos encontrou valores ajustados abaixo de 12 anos nas notas baixas e resíduos positivos nessa faixa.
- **C (distance²):** o RESET rejeitou no Modelo 1, em que ŷ é função só de `distance`, e os resíduos do Modelo 3 sobem na cauda de distância.
- **D:** reúne B e C, para avaliar os dois termos em conjunto.
- **E (log de education):** é forma exigida pelo enunciado. A motivação empírica já era fraca, porque a faixa de 12 a 18 anos é estreita.
- **P1 a P4 (log de distance):** a concentração em distâncias curtas e a cauda longa sugerem que 10 milhas podem pesar mais perto da faculdade. Só podem ser comparados com distâncias positivas.

Centralização: B, C e D usam `distance_c = distance - 1,80287` e `score_c = score - 50,8890` (médias da amostra completa; tabela 01). Os ajustes são iguais aos do polinômio sem centralizar. O coeficiente linear passa a ser a associação marginal na média da variável, e só ali.

## Convenção de inferência

Erros padrão HC3. Testes bilaterais com t de Student e gl = n - k; IC de 95% = coeficiente ± t(0,975; n - k) × EP. Testes conjuntos: Wald F(q, n - k) com a matriz HC3. Associações marginais: EP = √(g'Vg), com a matriz V completa. Pontos de inversão: método delta. É a mesma convenção das etapas anteriores.

## O que mudou nos resultados e diagnósticos

### Amostra completa (4.739 estudantes, incluindo as 94 distâncias zero)

| Modelo | Especificação | Coef. linear de distance | IC 95% HC3 | R² ajust. | RESET robusto F (p) | BP LM (p) |
|---|---|---:|---:|---:|---:|---:|
| A | Modelo 3 original | -0,0238 | [-0,0427; -0,0049] | 0,2677 | 8,85 (< 0,001) | 128,7 (< 0,001) |
| B | A + score² | -0,0240 | [-0,0429; -0,0051] | 0,2677 | 7,18 (< 0,001) | 172,0 (< 0,001) |
| C | A + distance² | -0,0535 | [-0,0855; -0,0214] | 0,2683 | 9,58 (< 0,001) | 130,1 (< 0,001) |
| D | A + score² + distance² | -0,0541 | [-0,0861; -0,0221] | 0,2684 | 7,70 (< 0,001) | 173,5 (< 0,001) |
| E | log(education), explicativas de A | -0,0017 | [-0,0030; -0,0003] | 0,2692 | 9,32 (< 0,001) | 118,4 (< 0,001) |

Em C e D, o coeficiente linear vale só na média de distância (cerca de 18 milhas); não é comparável diretamente ao de A. Em E, está em log-pontos. O R² ajustado de E não pode ser comparado com o dos demais, porque a dependente é outra; a tabela o mostra apenas para registro.

- **`score²`:** sem evidência de curvatura em B (b = 0,00028, p = 0,284) nem em D (p = 0,250). A inversão calculada fica fora da faixa observada (-108 pontos em B, contra mínimo de 29,0), então a curva é monótona no suporte e a estimativa da inversão não tem leitura útil. Os casos previstos abaixo de 12 caem de 35 para 24, sem desaparecer. A motivação indicada na etapa de diagnósticos como a mais direta não se confirmou.
- **`distance²`:** positivo em C (b = 0,0040, IC [0,0010; 0,0071], p = 0,010). O teste conjunto dos dois quadrados em D dá F = 3,97 (p = 0,019).
- **Diagnósticos:** o RESET robusto rejeita em todas as especificações, e nenhuma alternativa o reduz de forma decisiva (F de 7,18 a 9,58; em C sobe de 8,85 para 9,58). O Breusch-Pagan também rejeita em todas. As estatísticas não servem de nota entre especificações: os regressores auxiliares mudam, e nos modelos em log a escala também.
- **R²:** entre A e D, com mesma dependente e mesma amostra, o R² ajustado passa de 0,2677 para 0,2684. A diferença é pequena demais para decidir.
- **Alavancagem:** o quadrado de distância eleva a alavancagem máxima de 0,018 para 0,067, um sinal do peso da cauda.
- **Resíduos:** C reduz o desvio positivo dos resíduos na cauda de distância, sem eliminá-lo. B e D reduzem pouco o desvio nas notas muito baixas, e E praticamente repete A contra distância.
- [Curvas por distância](graficos/01_curvas_distancia.png), [curvas por score](graficos/03_curvas_score.png) e [resíduos](graficos/05_residuos_loess.png).

### Previsões fora da faixa observada

| Modelo | Versão | < 12 | > 18 | Mín. | Máx. | Média prevista | Média observada | REQM (anos) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| A | Previsão direta em anos | 35 | 0 | 11,46 | 16,72 | 13,808 | 13,808 | 1,529 |
| B | Previsão direta em anos | 24 | 0 | 11,55 | 16,79 | 13,808 | 13,808 | 1,529 |
| C | Previsão direta em anos | 36 | 0 | 11,41 | 16,73 | 13,808 | 13,808 | 1,528 |
| D | Previsão direta em anos | 26 | 0 | 11,50 | 16,81 | 13,808 | 13,808 | 1,528 |
| E | exp(previsão em log) | 28 | 0 | 11,59 | 16,86 | 13,725 | 13,808 | 1,532 |
| E | Média com smearing de Duan | 15 | 0 | 11,66 | 16,96 | 13,807 | 13,808 | 1,530 |

Exponenciar a previsão em log e estimar a média condicional em anos são operações diferentes. `exp(previsão)` aproxima a mediana se os erros forem simétricos e aqui subestima a média (13,725 contra 13,808). A média usa o fator de smearing de Duan (1,0060), que supõe erro sem relação com os regressores; como o Breusch-Pagan rejeita, é só uma aproximação. O log impede previsões negativas, não previsões abaixo de 12. O REQM é descritivo, dentro da amostra.

### Subamostra de distância positiva

Foram retiradas 94 observações, apenas desta análise complementar: os estudantes com distância zero, para os quais log(distance) não existe (identificadores na tabela 03). Isso não é limpeza de dados nem solução neutra. Esses estudantes diferem dos demais: em média têm 14,02 anos de escolaridade (contra 13,80), 33% com pai graduado (contra 21%) e 27% na categoria afam (contra 16%) (tabela 04). As conclusões de P1 a P4 valem só para estudantes com distância registrada acima de zero.

**Mudança de amostra:** com a mesma especificação, o coeficiente de `distance` passa de -0,0238 (completa) para -0,0244 (positiva), variação de 2,4% (tabela 11). A retirada dos zeros, portanto, muda pouco esse coeficiente, e as diferenças entre P1 e P2 refletem a forma funcional.

| Modelo | Especificação | Coef. da distância | IC 95% HC3 | p | R² | R² ajust. | RESET robusto F (p) |
|---|---|---:|---:|---:|---:|---:|---:|
| P1 | education ~ distance | -0,0244 | [-0,0435; -0,0053] | 0,012 | 0,2664 | 0,2648 | 7,63 (< 0,001) |
| P2 | education ~ log(distance) | -0,0537 | [-0,0934; -0,0139] | 0,008 | 0,2666 | 0,2651 | 7,86 (< 0,001) |
| P3 | log(education) ~ distance | -0,0017 | [-0,0031; -0,0003] | 0,014 | 0,2679 | 0,2663 | 7,98 (< 0,001) |
| P4 | log(education) ~ log(distance) | -0,0039 | [-0,0067; -0,0010] | 0,008 | 0,2681 | 0,2666 | 8,19 (< 0,001) |

R² só pode ser comparado entre P1 e P2 (education) e entre P3 e P4 (log(education)). O log de distância ajusta um pouco melhor em cada par (R² ajustado de 0,2648 para 0,2651 e de 0,2663 para 0,2666), diferença pequena demais para decidir. [Curvas](graficos/04_curvas_subamostra_positiva.png).

## Como interpretar a associação de distância

### Quadráticos: não há associação constante

A associação marginal é b_linear + 2 × b_quadrado × (distance - média). Abaixo, em anos por 10 milhas, com IC de 95% HC3 obtido com a matriz completa. Em E, o valor é o equivalente aproximado em anos.

| Ponto | Milhas | n até 5 milhas | A | C | E (aprox.) |
|---|---:|---:|---:|---:|---:|
| Mínimo | 0 | 1722 | -0,024 [-0,043; -0,005] | -0,068 [-0,110; -0,026] | -0,023 |
| p25 | 4 | 2231 | -0,024 [-0,043; -0,005] | -0,065 [-0,104; -0,025] | -0,023 |
| p50 | 10 | 1872 | -0,024 [-0,043; -0,005] | -0,060 [-0,096; -0,024] | -0,023 |
| p75 | 25 | 622 | -0,024 [-0,043; -0,005] | -0,048 [-0,076; -0,019] | -0,023 |
| p90 | 45 | 377 | -0,024 [-0,043; -0,005] | -0,032 [-0,052; -0,011] | -0,023 |
| p95 | 60 | 107 | -0,024 [-0,043; -0,005] | -0,020 [-0,038; -0,002] | -0,023 |
| p99 | 120 | 10 | -0,024 [-0,043; -0,005] | 0,029 [-0,011; 0,069] | -0,023 |
| Máximo | 200 | 4 | -0,024 [-0,043; -0,005] | 0,094 [0,006; 0,181] | -0,023 |

- **Faixa bem sustentada:** do mínimo a p95 (60 milhas), o IC de C exclui zero, e a associação enfraquece de -0,068 para -0,020 ano por 10 milhas.
- **Inversão:** a curva de C tem mínimo em 84 milhas (IC delta de 56 a 113). O ponto está no suporte, mas só 93 estudantes (2,0%) estão acima dele e 63 estão a até 10 milhas dele.
- **Cauda:** C dá sinal positivo no máximo (200 milhas), onde só 4 estudantes estão a até 5 milhas desse valor. Isso não basta para afirmar que maior distância se associe a mais escolaridade: o trecho crescente pode ser consequência de impor uma parábola à cauda.
- **Peso da cauda:** os 61 estudantes acima de 100 milhas têm 53% do peso na identificação do termo quadrático de C, 41% no coeficiente de A e 6% no de log(distance) em P2 (tabela 10). O peso é calculado com o regressor residualizado (Frisch-Waugh), sem excluir nem reestimar. Portanto, a dependência da cauda não é um problema só de C: a inclinação de A também vem em grande parte dela. P2 é a forma menos dependente da cauda.
- **Convergência só perto da mediana:** C e P2 têm dependências muito diferentes da cauda e ainda assim dão inclinações parecidas em 10 milhas. Em 25 milhas já se separam (-0,048 em C, -0,021 em P2), e P2 fica próxima de zero nas distâncias longas. Isso sugere que A subestima a magnitude perto da mediana, mas não o demonstra: o IC de P2 nesse ponto inclui o coeficiente de A, e ambas as formas impõem concavidade.
- [Gráfico da associação marginal](graficos/02_associacao_marginal_distancia.png).

### Logaritmos: cada transformação tem sua leitura

- **E e P3 (log-nível):** 10 milhas a mais se associam a uma escolaridade 0,17% menor em E e 0,17% menor em P3, usando 100 × (exp(b) - 1). Em E, isso equivale a cerca de -0,023 ano, quase o mesmo que A.
- **P2 (nível-log):** 1% a mais de distância se associa a -0,00054 ano. Dobrar a distância se associa a b × ln 2 = -0,037 ano, em qualquer ponto. Por 10 milhas, a inclinação é b/distance: -0,134 em 4 milhas, -0,054 em 10 e -0,012 em 45. Isso é a inclinação local expressa por 10 milhas, não o resultado de um salto real de 10 milhas, sobretudo em distâncias muito curtas. A forma impõe associação sempre negativa e decrescente em módulo, sem inversão.
- **P4 (log-log):** o coeficiente é uma elasticidade: 1% a mais de distância se associa a uma escolaridade 0,0039% menor; dobrar a distância, a cerca de 0,27% menor.
- A unidade de `distance` não altera o coeficiente de log(distance), só o intercepto. Nenhuma dessas formas diz algo sobre quem está a distância zero.

## Recomendação provisória

**Principal: A, lida como resumo linear e não como inclinação típica. Ao lado: C, lida só até p95 (60 milhas), e P2, deixando claro que exclui as distâncias zero.** E, B e D não acrescentam o suficiente para ficar na apresentação principal.

- **Interpretação econômica:** rendimentos decrescentes da distância são plausíveis, e C e P2 os expressam. C também produz um trecho crescente na cauda, sem sustentação; P2 não comporta os zeros. A é a mais simples, mas seu número único esconde essa possível diferença entre distâncias curtas e longas.
- **Parcimônia:** A e P2 têm o mesmo número de parâmetros, e C tem um a mais. `score²` não se justifica, e E, em anos, é quase igual a A, com leitura menos direta.
- **Suporte dos dados:** A usa todos os estudantes, mas 64% do peso de sua inclinação vem de 6,1% da amostra. C usa todos, com 53% do peso do termo quadrático em 1,3%. P2 depende menos da cauda, mas perde as 94 distâncias zero, que diferem das demais.
- **Diagnósticos:** nenhuma alternativa elimina as rejeições, então eles não apontam vencedor.
- **Por que não trocar A por C ou P2 agora:** A foi definida antes desta exploração. O termo quadrático tem p = 0,010, mas veio de uma busca motivada pelos mesmos dados e deixaria de ser significativo a 5% com um erro padrão 31% maior, algo possível sob correlação dentro de escolas. O ganho de ajuste é mínimo. Mudar a especificação principal com base nisso seria escolher por valor-p.
- **Risco desta escolha:** A pode subestimar a magnitude em distâncias típicas. Por isso, o relatório deve dar uma faixa na mediana, de -0,024 (A) a -0,060 (C), com -0,054 em P2, e não um único número. Se o grupo priorizar a distância típica acima da simplicidade, C lida até p95 é uma alternativa defensável.
- A associação é negativa e pequena em distâncias curtas e típicas em todas as formas. A evidência não distingue a magnitude com clareza, e o relatório deve dizer isso.

## Limitações que permanecem

- **Exploração:** as alternativas foram escolhidas depois de ver diagnósticos nos mesmos dados, e vários testes foram feitos sem ajuste. Não há amostra separada para confirmação.
- **Causalidade:** nenhuma forma funcional resolve endogeneidade. Escolha do local de moradia, motivação e qualidade da escola seguem como possíveis fontes de viés.
- **Dependência dos erros:** HC3 não corrige correlação dentro de escolas ou localidades, e a base não identifica a escola. Os ICs podem estar estreitos demais em todas as especificações, inclusive nos testes dos quadrados.
- **Natureza de `education`:** nenhuma das formas respeita o piso de 12 anos nem trata a variável como discreta. Isso pode explicar parte das rejeições persistentes do RESET, mas esta etapa não demonstra essa causa. Modelos para variável discreta e limitada estão fora do escopo do enunciado.
- **Distâncias zero:** não há tratamento neutro. Somar 1 ou trocar o zero por outro valor mudaria a leitura e não foi feito; retirá-los muda a população comparada.
- **Curvas:** fixam os demais regressores nas médias, ou em cada estudante nos modelos em log, e descrevem o ajuste, não o que aconteceria se um estudante fosse deslocado. A retransformação por smearing é aproximada.

Fonte: tabelas, gráficos e modelos em `resultados/formas_funcionais/`; documentação de AER::CollegeDistance.
