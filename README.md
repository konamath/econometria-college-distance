# CollegeDistance | Trabalho de Econometria Básica

Projeto do trabalho de Econometria Básica, 2026/2. Base aprovada pelo professor.

**Pergunta de trabalho:** como a distância até a faculdade e as condições familiares se relacionam com os anos de escolaridade dos jovens?

## Relatório e ordem de execução

O trabalho consolidado está em [RELATORIO_TRABALHO.md](RELATORIO_TRABALHO.md), que reúne a conclusão atual. As versões de entrega, em Word e PDF, ficam em `entrega/`. As notas intermediárias em `resultados/` registram o estágio de cada etapa e não foram reescritas depois; se uma delas divergir do relatório, vale o relatório. As análises exploratórias adicionais não fazem parte da exposição principal.

Para reproduzir tudo, execute dentro da pasta do projeto, nesta ordem:

```sh
Rscript --vanilla 00_preparar_ambiente.R   # só uma vez em cada computador
Rscript --vanilla 01_descritiva.R
Rscript --vanilla 02_regressoes.R
Rscript --vanilla 03_diagnosticos.R
Rscript --vanilla 04_formas_funcionais.R
```

O relatório é um texto editável, não é gerado pelos scripts. Se algum resultado mudar, atualize os números dele à mão.

## Colaboração no GitHub

Repositório: [konamath/econometria-college-distance](https://github.com/konamath/econometria-college-distance).

Para trabalhar com o grupo, clone o repositório no GitHub Desktop ou no VS Code. Leia [CONTRIBUIR.md](CONTRIBUIR.md) para atualizar sua cópia, criar uma branch e propor uma alteração. A branch `main` guarda a versão revisada pelo grupo; use um pull request para propor mudanças.

O repositório público permite consultar os arquivos. Para publicar alterações diretamente, é preciso ser convidado como colaborador; também é possível contribuir por fork e pull request.

O projeto contém a preparação da base, a análise descritiva, três modelos progressivos por MQO, com erros padrão convencionais e HC3, os diagnósticos desses modelos, uma comparação exploratória de formas funcionais e o relatório consolidado. O Modelo 3 linear é a especificação principal. Não são apresentadas conclusões causais.

## Abrir e executar no VS Code

1. Abra a **pasta CollegeDistance_v1 inteira** no VS Code, pelo menu File > Open Folder.
2. Abra `01_descritiva.R` para acompanhar o código comentado.
3. Use **Terminal > Run Build Task**. A tarefa se chama **CollegeDistance: executar análise descritiva** e inicia uma sessão limpa do R.
4. Examine `resultados/LEITURA_DOS_RESULTADOS.md`, as tabelas e os quatro gráficos.

Alternativa no terminal, dentro da pasta do projeto:

```sh
Rscript --vanilla 01_descritiva.R
```

No console do R ou no RStudio, com a pasta do projeto como diretório de trabalho:

```r
source("01_descritiva.R", encoding = "UTF-8")
```

Para explorar por partes no VS Code, use **R: Create R terminal**, abra o script e envie trechos com **R: Run Selection/Line**. Comece sempre pela seção 1. O arquivo completo é a referência para reproduzir a entrega.

## Executar as regressões

Na pasta do projeto, em uma sessão limpa:

```sh
Rscript --vanilla 02_regressoes.R
```

No console do R ou no RStudio, use `source("02_regressoes.R", encoding = "UTF-8")`. O script lê `dados/CollegeDistance_original.rds` e `resultados/tabelas/01_dicionario.csv`, não baixa a base, não altera os resultados descritivos e não precisa que `01_descritiva.R` seja executado de novo. Ele para com erro se alguma verificação falhar.

## Executar os diagnósticos

Depois das regressões, na pasta do projeto e em uma sessão limpa:

```sh
Rscript --vanilla 03_diagnosticos.R
```

No console do R ou no RStudio, use `source("03_diagnosticos.R", encoding = "UTF-8")`. O script lê a base preservada, os modelos salvos e a tabela 11, sem alterá-los, e escreve apenas em `resultados/diagnosticos/`. A nota `resultados/LEITURA_DAS_REGRESSOES.md` descreve a etapa anterior; a avaliação dos diagnósticos está em `resultados/diagnosticos/LEITURA_DOS_DIAGNOSTICOS.md`.

## Executar a comparação de formas funcionais

Depois das etapas anteriores, na pasta do projeto e em uma sessão limpa:

```sh
Rscript --vanilla 04_formas_funcionais.R
```

No console do R ou no RStudio, use `source("04_formas_funcionais.R", encoding = "UTF-8")`. O script usa a base preservada, confere os resultados anteriores sem alterá-los e escreve apenas em `resultados/formas_funcionais/`. Os logs de distância usam só distâncias positivas, em uma análise complementar; as 94 distâncias zero permanecem na comparação principal.

## Em outro computador

Instale o R e execute `00_preparar_ambiente.R` uma vez. Ele instala AER, ggplot2 e languageserver na biblioteca pessoal. A configuração do editor usa os executáveis `R` e `Rscript`; eles precisam estar acessíveis no sistema. A análise em si funciona sem VS Code.

Não é necessário instalar todos os pacotes citados no enunciado: eles servem a outras bases. O pacote AER instala também dependências úteis às próximas etapas, como lmtest, sandwich e car.

## Arquivos entregues

| Caminho | Conteúdo |
|---|---|
| `RELATORIO_TRABALHO.md` | Relatório consolidado para o grupo e o professor |
| `entrega/Trabalho_Econometria.docx` | Versão editável do relatório |
| `entrega/Trabalho_Econometria.pdf` | Versão em PDF do relatório |
| `00_preparar_ambiente.R` | Instalação das dependências em outro computador |
| `01_descritiva.R` | Análise descritiva completa e comentada |
| `02_regressoes.R` | Três modelos por MQO, inferência e verificações |
| `03_diagnosticos.R` | RESET, Breusch-Pagan, VIF/GVIF, influência e resíduos |
| `04_formas_funcionais.R` | Comparação exploratória de formas quadráticas e logarítmicas |
| `dados/CollegeDistance_original.rds` | Cópia com tipos e categorias originais do R |
| `dados/CollegeDistance_original.csv` | Cópia tabular para consulta |
| `dados/PROVENIENCIA.txt` | Fonte, versão e tratamento dos dados |
| `resultados/tabelas/` | Dicionário, qualidade, descritivas, frequências, correlações e grupos |
| `resultados/graficos/` | Quatro figuras PNG geradas pelo script |
| `resultados/LEITURA_DOS_RESULTADOS.md` | Números iniciais e limites de interpretação |
| `resultados/sessionInfo.txt` | Versões do R e dos pacotes usados na análise descritiva |
| `resultados/tabelas/09_regressao_variaveis.csv` | Tipos, categorias, referências, ausentes e não finitos |
| `resultados/tabelas/10_regressao_amostra.csv` | Observações iniciais, exclusões e amostra final |
| `resultados/tabelas/11_regressao_coeficientes.csv` | Coeficientes e inferência convencional e HC3, por modelo |
| `resultados/tabelas/12_regressao_ajuste.csv` | Observações, R² e R² ajustado |
| `resultados/tabelas/13_regressao_distance.csv` | Comparação do coeficiente de `distance` nos três modelos |
| `resultados/tabelas/14_regressao_validacao.csv` | Verificações aprovadas na execução |
| `resultados/modelos/` | Objetos `lm` em `.rds` e versões usadas nas regressões |
| `resultados/LEITURA_DAS_REGRESSOES.md` | Interpretação dos modelos e limites |
| `resultados/diagnosticos/tabelas/` | Correspondência, testes, erros padrão, VIF/GVIF e observações sinalizadas |
| `resultados/diagnosticos/graficos/` | Resíduos, Q-Q e influência |
| `resultados/diagnosticos/LEITURA_DOS_DIAGNOSTICOS.md` | Evidência, consequências, limitações e formas funcionais a comparar |
| `resultados/formas_funcionais/modelos/` | Modelos A a E (amostra completa) e P1 a P4 (distância positiva) |
| `resultados/formas_funcionais/tabelas/` | Amostras, coeficientes HC3, testes, associações marginais, suporte e previsões |
| `resultados/formas_funcionais/graficos/` | Curvas ajustadas, associação marginal e resíduos |
| `resultados/formas_funcionais/LEITURA_DAS_FORMAS_FUNCIONAIS.md` | Comparação, interpretação, limitações e recomendação provisória |

As tabelas CSV usam vírgula como separador, ponto decimal e UTF-8. Na importação em uma planilha, selecione essas opções. Não há valores arredondados nas tabelas; apenas a apresentação dos gráficos e da nota é arredondada.

Reexecutar o script atualiza os resultados desta versão e a cópia dos dados a partir do AER instalado. Antes de atualizar o pacote AER, preserve esta pasta para manter o registro da versão utilizada. Não edite manualmente tabelas e figuras geradas.

## Convenções da análise

- A amostra inclui ambas as regiões do AER, sem exclusões e sem pesos amostrais.
- Cada linha representa um estudante. Não há painel sendo estimado.
- Médias e proporções descrevem a amostra, não estimativas representativas da população.
- Variância e desvio padrão são amostrais. Correlações de Pearson usam casos completos nas variáveis numéricas; o tamanho dessa amostra é exportado.
- A renda é categórica. Distância é medida em dezenas de milhas. O salário é estadual, não individual.
- A sinalização de extremos pelo intervalo interquartil serve à inspeção; nenhuma linha é removida por esse critério.
- A tabela por grupos e o gráfico de renda mostram diferenças brutas, sem controles. Não são efeitos causais.

## O que revisar em grupo

As regressões, os diagnósticos e a comparação de formas funcionais estão concluídos. Faltam:

1. **Identificação:** preencher os campos "A preencher" da capa (integrantes, professor(a), instituição e turma) em `entrega/Trabalho_Econometria.docx`.
2. **Leitura final:** o grupo deve ler o relatório inteiro antes da entrega. Depois de editar o Word, exporte o PDF novamente a partir dele.
3. **Apresentação:** preparar os slides e dividir as partes entre os integrantes. A apresentação está prevista no enunciado para 11/11/2026.

## Fontes

- Enunciado: `trabalho_econometria.html`, seções 1.1 a 1.4 e 3.1.4, fornecido pelo grupo. Apresentação prevista no enunciado para 11/11/2026.
- [Documentação oficial do AER: CollegeDistance](https://cran.r-universe.dev/AER/doc/manual.html#CollegeDistance).
- Base: AER::CollegeDistance, pesquisa High School and Beyond de 1980 com acompanhamento em 1986; fonte indicada pelo AER: complementos de Stock e Watson (2007).
