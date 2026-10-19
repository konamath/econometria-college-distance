# CollegeDistance | Primeira versão

Projeto do trabalho de Econometria Básica, 2026/2. Base aprovada pelo professor.

**Pergunta de trabalho:** como a distância até a faculdade e as condições familiares se relacionam com os anos de escolaridade dos jovens?

## Colaboração no GitHub

Repositório: [konamath/econometria-college-distance](https://github.com/konamath/econometria-college-distance).

Para trabalhar com o grupo, clone o repositório no GitHub Desktop ou no VS Code. Leia [CONTRIBUIR.md](CONTRIBUIR.md) para atualizar sua cópia, criar uma branch e propor uma alteração. A branch `main` guarda a versão revisada pelo grupo; use um pull request para propor mudanças.

O repositório público permite consultar os arquivos. Para publicar alterações diretamente, é preciso ser convidado como colaborador; também é possível contribuir por fork e pull request.

Esta versão contém preparação da base e análise descritiva. As regressões, os testes de hipóteses, os intervalos de confiança e a comparação de formas funcionais serão feitos na próxima etapa. Não são apresentadas conclusões causais.

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

## Em outro computador

Instale o R e execute `00_preparar_ambiente.R` uma vez. Ele instala AER, ggplot2 e languageserver na biblioteca pessoal. A configuração do editor usa os executáveis `R` e `Rscript`; eles precisam estar acessíveis no sistema. A análise em si funciona sem VS Code.

Não é necessário instalar todos os pacotes citados no enunciado: eles servem a outras bases. O pacote AER instala também dependências úteis às próximas etapas, como lmtest, sandwich e car.

## Arquivos entregues

| Caminho | Conteúdo |
|---|---|
| `00_preparar_ambiente.R` | Instalação das dependências em outro computador |
| `01_descritiva.R` | Análise completa e comentada desta versão |
| `dados/CollegeDistance_original.rds` | Cópia com tipos e categorias originais do R |
| `dados/CollegeDistance_original.csv` | Cópia tabular para consulta |
| `dados/PROVENIENCIA.txt` | Fonte, versão e tratamento dos dados |
| `resultados/tabelas/` | Dicionário, qualidade, descritivas, frequências, correlações e grupos |
| `resultados/graficos/` | Quatro figuras PNG geradas pelo script |
| `resultados/LEITURA_DOS_RESULTADOS.md` | Números iniciais e limites de interpretação |
| `resultados/sessionInfo.txt` | Versões do R e dos pacotes usados |

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

1. Entender o dicionário e a diferença entre variáveis individuais, familiares e locais.
2. Ler as distribuições, em especial a concentração de escolaridade e a cauda da distância.
3. Comparar escolaridade por renda e educação dos pais, sem atribuir causalidade.
4. Definir os controles das futuras regressões com justificativa econômica.
5. Tratar explicitamente as distâncias zero antes de qualquer transformação logarítmica.

## Fontes

- Enunciado: `trabalho_econometria.html`, seções 1.1 a 1.4 e 3.1.4, fornecido pelo grupo. Apresentação prevista no enunciado para 11/11/2026.
- [Documentação oficial do AER: CollegeDistance](https://cran.r-universe.dev/AER/doc/manual.html#CollegeDistance).
- Base: AER::CollegeDistance, pesquisa High School and Beyond de 1980 com acompanhamento em 1986; fonte indicada pelo AER: complementos de Stock e Watson (2007).
