# Leitura das regressões por MQO

Esta nota é gerada por `02_regressoes.R`. Não substitui o relatório final do trabalho.

## Síntese

Na amostra, 10 milhas a mais até a faculdade de quatro anos se associam a 0,073 ano a menos de escolaridade sem controles e a 0,024 ano a menos (cerca de 0,3 mês) com todos os controles. O sinal se mantém e o intervalo de 95% exclui zero nos três modelos, mas a magnitude cai 67% e fica pequena. O resultado descreve uma associação, não um efeito causal.

## Amostra e convenção de inferência

- Amostra comum: 4.739 observações iniciais e 4.739 finais; 0 exclusões. Os três modelos usam as mesmas linhas.
- As 94 observações com distância zero e os valores extremos foram mantidos. Distância entra em nível.
- Referências: `income` = low; `fcollege` = no; `mcollege` = no; `gender` = male; `ethnicity` = other; `urban` = no; `region` = other.
- Inferência: teste bilateral com t de Student e gl = n - k, nos erros convencionais e HC3. O IC de 95% é coeficiente ± t(0,975; n - k) × erro padrão. A nota destaca HC3 porque esse erro padrão não supõe homocedasticidade; nenhum teste de heterocedasticidade foi feito nesta etapa. As duas inferências estão na tabela abaixo.
- Valor-p igual a 0 nas tabelas indica valor menor que o menor número representável pelo computador, não probabilidade exatamente nula.

## O que cada modelo procura medir

As justificativas abaixo são hipóteses econômicas para incluir cada bloco. Não são resultados das regressões.

- **Modelo 1: `distance`.** Associação bruta: compara a escolaridade média de estudantes a distâncias diferentes, sem ajuste. Distância pode refletir o custo de frequentar a faculdade (deslocamento ou moradia).
- **Modelo 2: acrescenta `income`, `fcollege` e `mcollege`.** Compara estudantes com a mesma faixa de renda familiar (até ou acima de US$ 25 mil por ano) e a mesma condição de graduação do pai e da mãe. Renda pode refletir restrição de financiamento. A graduação dos pais pode refletir informação, preferências e recursos familiares. Esses fatores também podem estar ligados ao local onde a família mora.
- **Modelo 3: acrescenta `score`, `gender`, `ethnicity`, `urban` e `region`.** Compara também estudantes com a mesma nota no teste do último ano do ensino médio, do mesmo sexo e grupo étnico, com escola na mesma condição urbana e na mesma região (West ou outra). A nota aproxima o preparo acadêmico prévio; as variáveis demográficas e locais captam diferenças de trajetória e de contexto.

## Magnitude e incerteza da associação

Uma unidade de `distance` corresponde a 10 milhas. Os coeficientes estão em anos de escolaridade por 10 milhas.

| Modelo | Coeficiente | Meses | EP HC3 | IC 95% HC3 | p HC3 | EP conv. | IC 95% conv. | p conv. | R² | R² ajust. |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Modelo 1 | -0,0726 | -0,87 | 0,0110 | [-0,0942; -0,0510] | < 0,001 | 0,0113 | [-0,0947; -0,0505] | < 0,001 | 0,009 | 0,008 |
| Modelo 2 | -0,0425 | -0,51 | 0,0104 | [-0,0629; -0,0221] | < 0,001 | 0,0108 | [-0,0636; -0,0214] | < 0,001 | 0,110 | 0,109 |
| Modelo 3 | -0,0238 | -0,29 | 0,0096 | [-0,0427; -0,0049] | 0,013 | 0,0103 | [-0,0440; -0,0036] | 0,021 | 0,269 | 0,268 |

No Modelo 3, o IC HC3 vai de 0,06 a 0,51 mês a menos por 10 milhas. Os dois tipos de erro padrão levam à mesma conclusão sobre `distance` a 5%; as diferenças entre eles são pequenas.

## Como a associação muda entre os modelos

- Do Modelo 1 para o Modelo 2, o coeficiente passa de -0,0726 para -0,0425 (magnitude 41% menor).
- Do Modelo 1 para o Modelo 3, chega a -0,0238 (magnitude 67% menor).
- O R² sobe de 0,009 para 0,110 e 0,269. Sozinha, a distância explica menos de 1% da variação da escolaridade na amostra.
- A amostra é a mesma, logo a mudança não vem da composição das observações. Pela álgebra do MQO, ela reflete a correlação de `distance` com os controles adicionados e a relação desses controles com `education`.
- Os modelos não mostram qual mecanismo está por trás dessa queda nem separam a contribuição individual de cada controle. A diferença entre coeficientes também não foi testada formalmente: as comparações são descritivas.
- Nenhuma variável foi escolhida por valor-p. `urban` e `region` permanecem no Modelo 3 embora seus ICs HC3 incluam zero (p = 0,444 e 0,086). Isso não demonstra que seus coeficientes sejam nulos.

## Controles e causalidade

Controlar por desempenho inicial e características familiares muda a comparação realizada: o Modelo 3 compara estudantes parecidos nas variáveis observadas. Isso não demonstra causalidade nem elimina automaticamente a endogeneidade.

- Fatores não observados, como motivação, qualidade da escola e características da comunidade, podem estar ligados à distância e à escolaridade. Famílias também podem escolher onde morar, o que tornaria a distância endógena.
- Um controle pode não ser neutro. Se a distância ou fatores ligados a ela influenciarem a nota antes do teste, controlar por `score` retira parte da associação total. A queda do coeficiente não indica, por si só, que o modelo com mais controles esteja mais perto de um efeito causal.
- O enunciado cita o uso da distância como variável instrumental em equações de salário. Isso supõe condições que estas regressões não testam; os resultados aqui não validam esse uso.

## Significância estatística e relevância econômica

São coisas diferentes. No Modelo 3, a associação é estatisticamente distinta de zero a 5% (p HC3 = 0,013), mas a estimativa é pequena: entre o primeiro e o terceiro quartis da distância (4 e 25 milhas), a diferença prevista é de 0,050 ano, ou 0,6 mês. Isso equivale a 0,028 desvio padrão da escolaridade (1,79 anos). O desvio padrão da distância é de 23 milhas.

A amostra grande ajuda a detectar associações pequenas. A base não traz custos e benefícios monetários, então estes números não bastam para concluir se a distância importa para uma política educacional.

## Limitações

- `education` é uma escala construída: 12 anos para todos os alunos do último ano do ensino médio, mais anos adicionais e valores atribuídos por diploma (13 para formação vocacional, 14 para AA, 16 para BA, 17 para pós-graduação incompleta e 18 para pós-graduação completa). O mínimo é 12, portanto o coeficiente não informa sobre abandono antes dessa etapa.
- A pesquisa cobriu cerca de 1.100 escolas, mas a base não identifica a escola. Estudantes do mesmo local podem ter resíduos correlacionados. Nem o erro convencional nem o HC3 tratam isso, e a incerteza pode estar subestimada.
- Não há pesos amostrais. A amostra é de estudantes americanos do ensino médio de 1980, com acompanhamento em 1986; os resultados não se estendem automaticamente a outras populações ou épocas.
- `income` é uma faixa binária, e `fcollege` e `mcollege` indicam apenas graduação. Dentro de cada categoria ainda há diferenças que os modelos não capturam.
- Forma funcional e hipóteses do MQO ainda não foram avaliadas. A linearidade em nível é uma escolha desta etapa, não uma conclusão. O intercepto do Modelo 3 corresponde a `score` = 0, fora da faixa observada, e não tem leitura substantiva.

Fonte: documentação de AER::CollegeDistance; tabelas 09 a 14 em `resultados/tabelas/`; modelos em `resultados/modelos/`.
