# Leitura dos diagnósticos econométricos

Esta nota é gerada por `03_diagnosticos.R`. Nenhuma especificação foi alterada e nenhuma observação foi excluída.

## Síntese

No Modelo 3, os testes apontam possível inadequação da especificação (RESET, p robusto < 0,001) e heterocedasticidade (Breusch-Pagan studentizado, p < 0,001). A multicolinearidade é baixa, e nenhuma observação isolada se destaca como muito influente. A associação estimada para `distance` continua pequena, e sua significância a 5% é a parte mais frágil: bastaria um erro padrão 26% maior que o HC3 para o intervalo incluir zero. Esses procedimentos não comprovam exogeneidade, ausência de variáveis omitidas ou independência entre estudantes.

## Como os diagnósticos foram feitos

- **RESET:** regressão auxiliar `education ~ regressores do modelo + ŷ² + ŷ³`, com H0 de que os dois coeficientes adicionais são nulos. A versão clássica usa `lmtest::resettest(power = 2:3, type = "fitted")`. Como ela supõe homocedasticidade, também é reportado um F de Wald com matriz HC3 na mesma auxiliar.
- **Breusch-Pagan:** versão studentizada de Koenker, `lmtest::bptest(studentize = TRUE)`, com os regressores do próprio modelo. A estatística é n × R² da regressão de e² nesses regressores.
- **VIF e GVIF:** `car::vif`. Ver a explicação de escalas abaixo.
- **Triagem de influência:** alavancagem acima de 2k/n; resíduo studentizado externo acima de 3 em valor absoluto; distância de Cook acima de 4/n. São instrumentos de triagem, não regras de exclusão.
- Os modelos carregados correspondem à base preservada: mesmos identificadores, mesmos valores e coeficientes reproduzidos (tabela 01).

## Evidência encontrada

### Resíduos e forma funcional

| Modelo | RESET F clássico | p | RESET F HC3 | p | BP LM (gl) | p |
|---|---:|---:|---:|---:|---:|---:|
| Modelo 1 | 10,66 | < 0,001 | 13,39 | < 0,001 | 5,13 (1) | 0,023 |
| Modelo 2 | 0,61 | 0,544 | 0,59 | 0,553 | 5,04 (4) | 0,283 |
| Modelo 3 | 6,42 | 0,002 | 8,85 | < 0,001 | 128,66 (10) | < 0,001 |

- O RESET rejeita a 5% nos Modelos 1 e 3 e não rejeita no Modelo 2. No Modelo 1, ŷ é função linear de `distance`, então o teste equivale a perguntar se potências de `distance` acrescentam poder explicativo.
- No Modelo 3, 35 valores ajustados ficam abaixo de 12 anos, o mínimo possível da escala (`score` médio de 33,6 nesse grupo, contra 50,9 na amostra). A forma linear não respeita esse piso em toda a amostra.
- Por decis de valores ajustados, a média dos resíduos do Modelo 3 varia de -0,134 a 0,134 ano e alterna sinais, sem curva única. O desvio mais visível está no início da faixa: no primeiro decil, a média é 0,111 ano, com IC aproximado acima de zero (tabela 03).
- Contra `score`, a curva LOESS é quase plana e sobe abaixo de cerca de 36 pontos, justamente onde ficam os valores ajustados abaixo de 12. No primeiro decil de `score`, a média é de 0,082 ano, com IC aproximado de [-0,018; 0,181]. A faixa densa e descendente nesse gráfico reúne estudantes com 12 anos, o piso da escala.
- Nas distâncias acima de 100 milhas, a média dos resíduos é de 0,255 ano, com apenas 61 estudantes e IC aproximado de [-0,061; 0,572], que inclui zero. A curva LOESS é quase plana até cerca de 100 milhas e depois sobe, mas se apoia em poucas observações.
- O gráfico contra valores ajustados mostra faixas diagonais paralelas. Elas são mecânicas: cada faixa reúne estudantes com o mesmo valor de `education`, que é discreta. Não devem ser lidas como padrão econômico.
- Gráficos: [valores ajustados](graficos/01_residuos_ajustados_modelos.png), [distância](graficos/02_residuos_distancia_modelo_3.png) e [desempenho inicial](graficos/03_residuos_score_modelo_3.png).

### Heterocedasticidade

- O Breusch-Pagan rejeita homocedasticidade nos Modelos 1 (p = 0,023) e 3 (p < 0,001). No Modelo 2, não rejeita (p = 0,283). Isso não prova homocedasticidade nesse modelo: o teste procura variância linear nos regressores e pode não detectar outros formatos.
- No Modelo 3, a média de e² por decil de valores ajustados vai de 1,07 no primeiro decil a 3,07 nos decis centrais e 1,99 no último. Variância menor nas pontas é compatível com uma variável limitada entre 12 e 18, embora o teste não identifique essa causa.
- Rejeitar homocedasticidade não significa que todo erro HC3 seja maior. No Modelo 3, a razão HC3/convencional vai de 0,908 a 1,032. O teste indica que há heterocedasticidade, mas não mede quanto ela altera cada erro padrão. Para `distance`, o HC3 é menor nos três modelos:

| Modelo | EP conv. de `distance` | EP HC3 | Razão | p conv. | p HC3 |
|---|---:|---:|---:|---:|---:|
| Modelo 1 | 0,0113 | 0,0110 | 0,977 | < 0,001 | < 0,001 |
| Modelo 2 | 0,0108 | 0,0104 | 0,968 | < 0,001 | < 0,001 |
| Modelo 3 | 0,0103 | 0,0096 | 0,936 | 0,021 | 0,013 |

### Multicolinearidade

As escalas diferem. Para termo com 1 grau de liberdade, GVIF = VIF, e GVIF^(1/(2gl)) é a raiz do VIF: o fator que multiplica o erro padrão. Para `ethnicity`, com 2 graus de liberdade, o GVIF é conjunto e não é comparável diretamente a um VIF. A comparação deve usar a coluna ajustada, ou seu quadrado, que volta à escala do VIF.

| Termo (Modelo 3) | gl | GVIF | GVIF^(1/(2gl)) | Ajustado ao quadrado |
|---|---:|---:|---:|---:|
| `distance` | 1 | 1,131 | 1,063 | 1,131 |
| `income` | 1 | 1,187 | 1,090 | 1,187 |
| `fcollege` | 1 | 1,382 | 1,175 | 1,382 |
| `mcollege` | 1 | 1,257 | 1,121 | 1,257 |
| `score` | 1 | 1,233 | 1,110 | 1,233 |
| `gender` | 1 | 1,011 | 1,005 | 1,011 |
| `ethnicity` | 2 | 1,310 | 1,070 | 1,145 |
| `urban` | 1 | 1,151 | 1,073 | 1,151 |
| `region` | 1 | 1,065 | 1,032 | 1,065 |

O maior valor na escala do VIF é o de `fcollege` (1,382), o que corresponde a um erro padrão cerca de 18% maior do que sem correlação com os demais regressores. O VIF de `distance` sobe de 1,015 no Modelo 2 para 1,131 no Modelo 3. Nada aqui recomenda excluir controles: controles entram por motivo econômico, não por limiar.

### Observações influentes

- No Modelo 3, 285 de 4.739 observações são sinalizadas por algum critério (tabela 08): 114 por alavancagem, 10 por resíduo e 193 por Cook; uma observação pode atender a mais de um. Nenhuma foi excluída. A tabela traz o identificador original do AER, que não coincide necessariamente com a posição na base (o caso de maior Cook tem identificador 5441 e está na linha 4340).
- A distância de Cook máxima é 0,0045, muito abaixo de 1 (0,0269 no Modelo 1 e 0,0060 no Modelo 2). O limiar 4/n fica muito baixo em amostra grande (0,00084) e sinaliza 4,1% da amostra: serve para ordenar casos, não para indicar problema.
- O maior resíduo studentizado é 3,38 e todos os acima de 3 são positivos: estudantes com escolaridade bem acima da prevista. Com correção de Bonferroni, o maior deles não se destaca (p = 1).
- 55 das 114 observações de alta alavancagem têm distância acima de 100 milhas. A maior alavancagem é 0,0181, no valor máximo de distância (200 milhas).
- [Gráfico de influência](graficos/05_influencia_modelo_3.png). Valores extremos não são prova de erro; a tabela serve para conferir os registros.

### Distribuição dos resíduos

- O [gráfico Q-Q](graficos/04_qq_modelo_3.png) se afasta da reta. A assimetria é 0,35 e a curtose excedente, -0,40. O desvio principal está na cauda esquerda, mais curta que a da normal (percentil 1 de -1,88, contra -2,33). A cauda direita fica próxima da reta (percentil 99 de 2,40).
- Esse afastamento é esperado: `education` é discreta, limitada entre 12 e 18 e concentrada em 12 anos (38,7% da amostra). A cauda esquerda curta é compatível com o piso de 12 anos. Resíduos de uma variável assim não podem ser exatamente normais. Com n = 4.739, um teste formal tenderia a rejeitar mesmo desvios pequenos, então a leitura se apoia no gráfico e nos números.

## Consequência prática

- **Não viés:** a normalidade dos resíduos não é condição para o MQO ser não viesado. O não viés depende de linearidade nos parâmetros, amostragem aleatória, ausência de colinearidade perfeita e média condicional do erro igual a zero. A normalidade só daria distribuição exata a t e F em amostra finita. Aqui a inferência se apoia em aproximação de amostra grande, que também pressupõe dependência limitada entre observações.
- **Erro padrão:** a rejeição no Modelo 3 sustenta manter HC3 como referência nesse modelo, sem descartar a convencional. Para `distance`, as duas levam à mesma conclusão a 5%.
- **`distance`:** o intervalo HC3 do Modelo 3 termina perto de zero. O erro padrão precisaria ser 1,26 vez o HC3 (ou 1,18 vez o convencional) para o IC de 95% incluir zero. A conclusão de significância deve ser apresentada com essa cautela. Esse número é uma conta de sensibilidade, não uma estimativa da correlação dentro de escolas.
- **Forma funcional:** o coeficiente de `distance` deve ser lido como a inclinação de uma aproximação linear, não como uma mudança igual em qualquer distância. As rejeições do RESET justificam comparar formas funcionais na próxima etapa.
- **RESET:** o teste pode apontar inadequação da especificação, mas não identifica sozinho a causa nem a transformação correta. A rejeição pode refletir não linearidade, variável omitida ou os limites de `education`.
- **Multicolinearidade:** não é o que limita a precisão de `distance`, e não há motivo para retirar controles por esse diagnóstico.
- **Influência:** os dados não indicam que poucas observações dominem os resultados pelas medidas examinadas. Não houve reestimação sem elas, portanto esta etapa não mede quanto os coeficientes mudariam.
- **Escolha de modelo:** os diagnósticos não elegem um modelo, e significância ou R² também não bastam para isso. A não rejeição do RESET e do Breusch-Pagan no Modelo 2 não o torna preferível: ele responde a outra comparação, sem desempenho inicial e sem controles demográficos e locais.

## Limitações que esses diagnósticos não resolvem

- **Exogeneidade e variáveis omitidas:** nenhum destes procedimentos comprova exogeneidade ou ausência de variáveis omitidas. Resíduos do MQO são ortogonais aos regressores por construção, então gráficos de resíduos não podem revelar correlação entre o erro verdadeiro e `distance`. A escolha do local de moradia, a motivação e a qualidade da escola seguem como possíveis fontes de endogeneidade.
- **Independência entre estudantes:** estes procedimentos também não comprovam independência. HC3 não corrige correlação dos erros dentro de escolas ou localidades. A pesquisa cobriu cerca de 1.100 escolas, e a base não identifica a escola. Há 747 combinações distintas de variáveis locais na base (`distance`, `unemp`, `wage`, `tuition`, `urban`, `region`), com média de 6,3 estudantes por combinação. Isso sugere agrupamento, mas essas combinações não são identificadores de escola.
- **Causalidade:** passar ou não em um teste não transforma associação em efeito causal.
- **Poder e formato dos testes:** o RESET usa só potências de ŷ, e o Breusch-Pagan, só uma relação linear com os regressores. Não rejeitar não confirma a especificação.
- **Múltiplos testes:** os testes foram feitos em três modelos, sem ajuste para comparações múltiplas. Os modelos também são aninhados, portanto os resultados não são independentes.
- **Medida da variável dependente:** nenhuma correção foi feita para a escala construída de `education`. Pesos amostrais continuam ausentes.

## O que estes achados motivam na comparação de formas funcionais

A comparação ainda não foi feita. Os diagnósticos apenas indicam o que vale examinar:

- **Quadrática em `distance`:** o RESET rejeita no Modelo 1, em que ŷ é função só de `distance`. No Modelo 3, a evidência é mais fraca: a curva de resíduos é quase plana até cerca de 100 milhas, e a média acima disso é positiva, mas imprecisa.
- **Quadrática em `score`:** é a motivação mais direta no Modelo 3. Os valores ajustados abaixo do piso estão todos no primeiro decil de `score`, e a curva de resíduos sobe nessa faixa. É uma hipótese a testar: o desvio se concentra em uma ponta e pode refletir o piso, não uma parábola.
- **Logaritmo de `distance` (log-log):** a concentração em distâncias curtas e a cauda longa motivam a comparação. As 94 distâncias iguais a zero exigem decisão explícita, sem exclusão silenciosa, para que os modelos comparados usem as mesmas observações.
- **Logaritmo de `education` (log-linear):** o enunciado pede essa forma, mas a evidência a favor é fraca. A faixa de 12 a 18 anos é estreita, então a transformação muda pouco a forma da variável e não elimina a discretização nem o piso. R² com variáveis dependentes diferentes não é comparável diretamente.
- Nenhuma dessas formas resolve endogeneidade ou correlação dentro de escolas. A escolha final deve considerar interpretação, justificativa econômica e os diagnósticos, não apenas significância ou R².

Fonte: tabelas e gráficos em `resultados/diagnosticos/`; modelos em `resultados/modelos/`; documentação de AER::CollegeDistance.
