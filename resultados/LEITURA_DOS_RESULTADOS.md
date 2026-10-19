# Leitura inicial dos resultados

Esta nota é gerada pelo script. Não substitui o relatório final do trabalho.

- Amostra: 4.739 estudantes e 14 variáveis.
- Células ausentes: 0; linhas totalmente repetidas: 0.
- Nenhuma observação foi excluída ou imputada. Não há ponderação amostral nesta análise.
- Escolaridade média: 13,81 anos; mediana: 13 anos.
- Distância média: 1,80 dezenas de milhas (18,03 milhas).
- Distâncias iguais a zero: 94. O logaritmo da distância não está definido nessas observações.
- Escolaridade média por renda: 13,56 anos na categoria low e 14,42 anos na categoria high; diferença bruta: 0,87 ano.
- Correlação de Pearson entre distância e escolaridade: -0,093 (4739 casos completos).
- Correlação de Pearson entre nota inicial e escolaridade: 0,465.

## Como interpretar

As comparações são descritivas, sem controles ou testes de significância. Não demonstram causalidade.
A correlação simples não mede a relação parcial após controlar renda, desempenho e contexto familiar.
A amostra é histórica e de estudantes do ensino médio; não representa automaticamente todos os jovens, o Brasil ou a população atual.
income é uma categoria; wage é salário industrial estadual; urban se refere à escola.
Valores extremos foram mantidos. A sinalização pelo intervalo interquartil não é prova de erro.

## Próxima etapa

Revisar as distribuições e definir os modelos de regressão e seus controles. A V1 encerra na descrição.

Fonte: [documentação CollegeDistance/AER](https://cran.r-universe.dev/AER/doc/manual.html#CollegeDistance).
Versão do AER: 1.2.17.
