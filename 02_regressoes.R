# COLLEGEDISTANCE | Etapa 2: três modelos progressivos por MQO
# Pergunta: como a associação entre distância e escolaridade muda com os controles?
# Esta etapa não compara formas funcionais, não roda a bateria de diagnósticos
# e não identifica efeitos causais.
# Execução no terminal: Rscript --vanilla 02_regressoes.R
# Execução no console R ou RStudio: source("02_regressoes.R", encoding = "UTF-8")

# 1. Localizar o projeto e verificar dependências -------------------------------
argumento <- grep("^--file=", commandArgs(), value = TRUE)
arquivo_source <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
if (length(argumento)) {
  # O Rscript troca espaços do caminho por "~+~"; desfazemos antes de localizar.
  caminho <- gsub("~+~", " ", sub("^--file=", "", argumento[1]), fixed = TRUE)
  pasta <- dirname(normalizePath(caminho))
} else if (!is.null(arquivo_source)) {
  pasta <- dirname(normalizePath(arquivo_source))
} else {
  pasta <- getwd()
}
if (!file.exists(file.path(pasta, "02_regressoes.R"))) {
  stop("Abra a pasta CollegeDistance_v1 e execute o script completo.")
}
for (p in c("sandwich", "lmtest")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Falta o pacote ", p, ". Execute 00_preparar_ambiente.R primeiro.")
  }
}
# Fatores não ordenados precisam de contrastes de tratamento: cada coeficiente
# compara uma categoria com a categoria de referência.
if (getOption("contrasts")[["unordered"]] != "contr.treatment") {
  stop("Use contrastes de tratamento: options(contrasts = c('contr.treatment', 'contr.poly')).")
}

arquivo_base <- file.path(pasta, "dados/CollegeDistance_original.rds")
arquivo_dicionario <- file.path(pasta, "resultados/tabelas/01_dicionario.csv")
for (a in c(arquivo_base, arquivo_dicionario)) {
  if (!file.exists(a)) stop("Arquivo não encontrado: ", a)
}
tabelas <- file.path(pasta, "resultados/tabelas")
modelos_dir <- file.path(pasta, "resultados/modelos")
dir.create(modelos_dir, recursive = TRUE, showWarnings = FALSE)
exportar <- function(x, nome) {
  write.csv(x, file.path(tabelas, paste0(nome, ".csv")), row.names = FALSE,
            fileEncoding = "UTF-8", na = "")
}
fmt <- function(x, digitos = 2) {
  formatC(x, format = "f", digits = digitos, decimal.mark = ",", big.mark = ".")
}
fmt_p <- function(p) ifelse(p < .001, "< 0,001", fmt(p, 3))
# Interrompe a execução se alguma verificação falhar; devolve o registro para a tabela.
checar <- function(lista) {
  falhas <- names(lista)[!vapply(lista, isTRUE, logical(1))]
  if (length(falhas)) stop("Verificação falhou: ", paste(falhas, collapse = " | "))
  data.frame(verificacao = names(lista), resultado = "ok")
}

# 2. Carregar a cópia preservada e o dicionário ---------------------------------
# A base é apenas lida. Este script não escreve na pasta dados/.
md5_base <- unname(tools::md5sum(arquivo_base))
base <- readRDS(arquivo_base)
dicionario <- read.csv(arquivo_dicionario, encoding = "UTF-8", stringsAsFactors = FALSE)

dependente <- "education"
vars_m1 <- "distance"
vars_m2 <- c(vars_m1, "income", "fcollege", "mcollege")
vars_m3 <- c(vars_m2, "score", "gender", "ethnicity", "urban", "region")
vars_usadas <- c(dependente, vars_m3)
vars_numericas <- c("education", "distance", "score")
# A primeira categoria de cada fator é a referência. A ordem original é mantida
# e conferida aqui, para que uma mudança na base não troque a referência em silêncio.
niveis_esperados <- list(
  income = c("low", "high"), fcollege = c("no", "yes"), mcollege = c("no", "yes"),
  gender = c("male", "female"), ethnicity = c("other", "afam", "hispanic"),
  urban = c("no", "yes"), region = c("other", "west"))
vars_categoricas <- names(niveis_esperados)
referencias <- vapply(niveis_esperados, `[`, character(1), 1)

# 3. Conferir tipos, categorias, ausentes, não finitos e dicionário -------------
descricao_dic <- setNames(dicionario$descricao, dicionario$variavel)
unidade_dic <- setNames(dicionario$unidade_ou_categorias, dicionario$variavel)
validacao_dados <- checar(c(
  list("Todas as variáveis dos modelos existem na base" = all(vars_usadas %in% names(base)),
    "Todas as variáveis dos modelos constam no dicionário" = all(vars_usadas %in% dicionario$variavel),
    "Dicionário: distance em dezenas de milhas" = grepl("Dezenas de milhas", unidade_dic[["distance"]], fixed = TRUE),
    "Dicionário: income é faixa categórica" = grepl("US$ 25.000", unidade_dic[["income"]], fixed = TRUE),
    "Dicionário: fcollege indica pai graduado" = grepl("Pai graduado", descricao_dic[["fcollege"]], fixed = TRUE),
    "Dicionário: mcollege indica mãe graduada" = grepl("Mãe graduada", descricao_dic[["mcollege"]], fixed = TRUE),
    "Variáveis numéricas têm tipo numérico" = all(vapply(base[vars_numericas], is.numeric, logical(1))),
    "Variáveis categóricas são fatores não ordenados" = all(vapply(base[vars_categoricas],
      function(x) is.factor(x) && !is.ordered(x), logical(1))),
    "Categorias e referências são as esperadas" = identical(lapply(base[vars_categoricas], levels), niveis_esperados),
    "Distância não negativa" = all(base$distance >= 0, na.rm = TRUE))))

modelo_entrada <- function(v) {
  if (v == dependente) "Dependente" else if (v %in% vars_m1) "Modelos 1, 2 e 3"
  else if (v %in% vars_m2) "Modelos 2 e 3" else "Modelo 3"
}
verificacao_variaveis <- do.call(rbind, lapply(vars_usadas, function(v) {
  x <- base[[v]]
  numerica <- is.numeric(x)
  data.frame(variavel = v, entrada = modelo_entrada(v), significado = descricao_dic[[v]],
    unidade_ou_categorias = unidade_dic[[v]], tipo = paste(class(x), collapse = "/"),
    n_total = length(x), n_ausentes = sum(is.na(x)),
    n_nao_finitos = if (numerica) sum(!is.finite(x) & !is.na(x)) else NA_integer_,
    minimo = if (numerica) min(x, na.rm = TRUE) else NA_real_,
    maximo = if (numerica) max(x, na.rm = TRUE) else NA_real_,
    categorias_e_n = if (numerica) NA_character_ else
      paste(paste0(levels(x), "=", as.integer(table(x))), collapse = "; "),
    categoria_referencia = if (numerica) NA_character_ else referencias[[v]])
}))
exportar(verificacao_variaveis, "09_regressao_variaveis")

# 4. Definir a amostra comum a partir das variáveis do Modelo 3 -----------------
# Os zeros de distância e os valores extremos são preservados; distância entra em nível.
tem_ausente <- !complete.cases(base[vars_usadas])
tem_nao_finito <- Reduce(`|`, lapply(base[vars_numericas], function(x) !is.finite(x) & !is.na(x)))
manter <- !tem_ausente & !tem_nao_finito
amostra <- base[manter, vars_usadas]
n_inicial <- nrow(base)
n_final <- nrow(amostra)
exportar(data.frame(
  etapa = c("Observações na base preservada", "Excluídas por valor ausente",
    "Excluídas por valor não finito", "Excluídas por valor extremo",
    "Amostra comum final", "Distâncias iguais a zero na amostra final"),
  n = c(n_inicial, sum(tem_ausente), sum(tem_nao_finito & !tem_ausente), 0L,
    n_final, sum(amostra$distance == 0))), "10_regressao_amostra")

# 5. Estimar os três modelos ----------------------------------------------------
# Todos têm intercepto. na.fail impede que o lm() descarte linhas em silêncio.
modelo_1 <- lm(education ~ distance, data = amostra, na.action = na.fail)
modelo_2 <- lm(education ~ distance + income + fcollege + mcollege,
               data = amostra, na.action = na.fail)
modelo_3 <- lm(education ~ distance + income + fcollege + mcollege + score + gender +
                 ethnicity + urban + region, data = amostra, na.action = na.fail)
modelos <- list("Modelo 1" = modelo_1, "Modelo 2" = modelo_2, "Modelo 3" = modelo_3)
vars_modelos <- list("Modelo 1" = vars_m1, "Modelo 2" = vars_m2, "Modelo 3" = vars_m3)
saveRDS(modelo_1, file.path(modelos_dir, "modelo_1.rds"))
saveRDS(modelo_2, file.path(modelos_dir, "modelo_2.rds"))
saveRDS(modelo_3, file.path(modelos_dir, "modelo_3.rds"))

# 6. Inferência convencional e robusta HC3 --------------------------------------
# Convenção única: teste bilateral com t de Student e gl = n - k, nos dois tipos
# de erro padrão. IC de 95% = coeficiente +/- t(0,975; n - k) x erro padrão.
# Só a matriz de variância muda. A convencional supõe homocedasticidade; a HC3 não.
inferencia <- function(m, V, sufixo) {
  b <- coef(m)
  ep <- sqrt(diag(V))
  t <- b / ep
  critico <- qt(.975, df.residual(m))
  x <- data.frame(ep = ep, t = t, p = 2 * pt(abs(t), df.residual(m), lower.tail = FALSE),
    ic95_inf = b - critico * ep, ic95_sup = b + critico * ep)
  names(x) <- paste0(names(x), "_", sufixo)
  x
}
vcovs_hc3 <- lapply(modelos, sandwich::vcovHC, type = "HC3")

# Traduz o nome de cada coeficiente em variável, categoria e referência.
descrever_termos <- function(m, vars) {
  do.call(rbind, lapply(names(coef(m)), function(termo) {
    if (termo == "(Intercept)") {
      base_grupo <- vapply(vars, function(v) {
        if (v %in% vars_categoricas) paste0(v, "=", referencias[[v]]) else paste0(v, "=0")
      }, character(1))
      return(data.frame(termo = termo, variavel = "Intercepto", categoria = NA_character_,
        categoria_referencia = paste0("Grupo-base: ", paste(base_grupo, collapse = "; "))))
    }
    if (termo %in% vars) {
      return(data.frame(termo = termo, variavel = termo, categoria = NA_character_,
        categoria_referencia = "Não se aplica (variável numérica)"))
    }
    v <- vars_categoricas[startsWith(termo, vars_categoricas)]
    data.frame(termo = termo, variavel = v, categoria = sub(v, "", termo, fixed = TRUE),
      categoria_referencia = referencias[[v]])
  }))
}
coeficientes <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  data.frame(modelo = nome, descrever_termos(m, vars_modelos[[nome]]), coeficiente = coef(m),
    inferencia(m, vcov(m), "convencional"), inferencia(m, vcovs_hc3[[nome]], "hc3"),
    gl_residuos = df.residual(m),
    distribuicao_referencia = paste0("t bilateral, gl = ", df.residual(m)),
    row.names = NULL)
}))
exportar(coeficientes, "11_regressao_coeficientes")

ajuste <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  data.frame(modelo = nome,
    especificacao = paste(deparse(formula(m), width.cutoff = 500L), collapse = " "),
    n_observacoes = nobs(m), n_parametros = length(coef(m)), gl_residuos = df.residual(m),
    r2 = summary(m)$r.squared, r2_ajustado = summary(m)$adj.r.squared)
}))
exportar(ajuste, "12_regressao_ajuste")

# Comparação de distance. Uma unidade da variável equivale a 10 milhas.
# Sem teste formal da diferença entre modelos: as variações são descritivas.
quartis_dist <- unname(quantile(amostra$distance, c(.25, .75)))
amplitude_iq <- quartis_dist[2] - quartis_dist[1]
dp_dist <- sd(amostra$distance)
dp_educ <- sd(amostra$education)
comp_dist <- coeficientes[coeficientes$termo == "distance", ]
b_dist <- setNames(comp_dist$coeficiente, comp_dist$modelo)
comparacao_distance <- data.frame(
  modelo = comp_dist$modelo, n_observacoes = n_final,
  coeficiente_anos_por_10_milhas = comp_dist$coeficiente,
  meses_por_10_milhas = 12 * comp_dist$coeficiente,
  anos_entre_p25_e_p75_da_distancia = amplitude_iq * comp_dist$coeficiente,
  variacao_vs_modelo_1 = comp_dist$coeficiente - b_dist[["Modelo 1"]],
  variacao_percentual_vs_modelo_1 = 100 * (comp_dist$coeficiente / b_dist[["Modelo 1"]] - 1),
  comp_dist[grep("_(convencional|hc3)$", names(comp_dist))],
  gl_residuos = comp_dist$gl_residuos, row.names = NULL)
exportar(comparacao_distance, "13_regressao_distance")

# 7. Validar modelos, tabelas e objetos salvos ----------------------------------
ler_tabela <- function(nome) {
  read.csv(file.path(tabelas, paste0(nome, ".csv")), encoding = "UTF-8", stringsAsFactors = FALSE)
}
coef_csv <- ler_tabela("11_regressao_coeficientes")
ajuste_csv <- ler_tabela("12_regressao_ajuste")
dist_csv <- ler_tabela("13_regressao_distance")
salvos <- list("Modelo 1" = readRDS(file.path(modelos_dir, "modelo_1.rds")),
  "Modelo 2" = readRDS(file.path(modelos_dir, "modelo_2.rds")),
  "Modelo 3" = readRDS(file.path(modelos_dir, "modelo_3.rds")))
linhas <- lapply(modelos, function(m) rownames(model.frame(m)))
para_todos <- function(f) all(vapply(names(modelos), f, logical(1)))
coluna_csv <- function(nome, coluna) coef_csv[coef_csv$modelo == nome, coluna]

validacao_modelos <- checar(list(
  "Amostra sem ausentes e sem não finitos" = !anyNA(amostra) &&
    all(vapply(amostra[vars_numericas], function(x) all(is.finite(x)), logical(1))),
  "Zeros de distância preservados" = sum(amostra$distance == 0) == sum(base$distance == 0, na.rm = TRUE),
  "Todas as categorias têm observações na amostra" = all(vapply(amostra[vars_categoricas],
    function(x) all(table(x) > 0), logical(1))),
  "Três modelos usam exatamente as mesmas linhas" = identical(linhas[[1]], linhas[[2]]) &&
    identical(linhas[[2]], linhas[[3]]) && identical(linhas[[1]], rownames(amostra)),
  "Número de observações igual à amostra comum" = all(vapply(modelos, nobs, numeric(1)) == n_final),
  "Especificações contêm exatamente as variáveis definidas" = para_todos(function(nome)
    setequal(attr(terms(modelos[[nome]]), "term.labels"), vars_modelos[[nome]])),
  "Três modelos têm intercepto" = para_todos(function(nome)
    attr(terms(modelos[[nome]]), "intercept") == 1L),
  "Nenhum coeficiente não identificado" = para_todos(function(nome)
    !anyNA(coef(modelos[[nome]])) && modelos[[nome]]$rank == length(coef(modelos[[nome]]))),
  "Nenhuma alavancagem igual a 1, o que invalidaria a HC3" = para_todos(function(nome)
    max(hatvalues(modelos[[nome]])) < 1),
  "Erros padrão HC3 finitos e positivos" = para_todos(function(nome) {
    ep <- sqrt(diag(vcovs_hc3[[nome]])); all(is.finite(ep)) && all(ep > 0)
  }),
  "Categorias de referência fora dos coeficientes" = !any(paste0(names(referencias), referencias) %in% coeficientes$termo),
  "Coeficientes e erro convencional iguais ao summary()" = para_todos(function(nome) {
    s <- coef(summary(modelos[[nome]]))
    isTRUE(all.equal(coluna_csv(nome, "coeficiente"), unname(s[, 1]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "ep_convencional"), unname(s[, 2]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "t_convencional"), unname(s[, 3]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "p_convencional"), unname(s[, 4]), tolerance = 1e-10))
  }),
  "IC convencional igual ao confint()" = para_todos(function(nome) {
    ic <- confint(modelos[[nome]])
    isTRUE(all.equal(coluna_csv(nome, "ic95_inf_convencional"), unname(ic[, 1]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "ic95_sup_convencional"), unname(ic[, 2]), tolerance = 1e-10))
  }),
  "Inferência HC3 igual a lmtest com gl = n - k" = para_todos(function(nome) {
    m <- modelos[[nome]]
    teste <- lmtest::coeftest(m, vcov. = vcovs_hc3[[nome]], df = df.residual(m))
    ic <- lmtest::coefci(m, vcov. = vcovs_hc3[[nome]], df = df.residual(m))
    isTRUE(all.equal(coluna_csv(nome, "ep_hc3"), unname(teste[, 2]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "t_hc3"), unname(teste[, 3]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "p_hc3"), unname(teste[, 4]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "ic95_inf_hc3"), unname(ic[, 1]), tolerance = 1e-10)) &&
      isTRUE(all.equal(coluna_csv(nome, "ic95_sup_hc3"), unname(ic[, 2]), tolerance = 1e-10))
  }),
  "Tabela de ajuste igual aos objetos" = isTRUE(all.equal(ajuste_csv$r2,
      unname(vapply(modelos, function(m) summary(m)$r.squared, numeric(1))), tolerance = 1e-10)) &&
    isTRUE(all.equal(ajuste_csv$r2_ajustado,
      unname(vapply(modelos, function(m) summary(m)$adj.r.squared, numeric(1))), tolerance = 1e-10)) &&
    all(ajuste_csv$n_observacoes == n_final),
  "Tabela de distance igual aos objetos" = isTRUE(all.equal(dist_csv$coeficiente_anos_por_10_milhas,
    unname(vapply(modelos, function(m) coef(m)[["distance"]], numeric(1))), tolerance = 1e-10)),
  "Objetos salvos iguais aos estimados" = para_todos(function(nome)
    isTRUE(all.equal(coef(salvos[[nome]]), coef(modelos[[nome]]))) &&
      identical(rownames(model.frame(salvos[[nome]])), linhas[[nome]])),
  "Base preservada não foi alterada" = identical(unname(tools::md5sum(arquivo_base)), md5_base)))

# Afirmações fixas da nota dependem destes resultados. Se mudarem, o script para,
# em vez de publicar um texto que não corresponde aos números.
dist_hc3_sup <- comp_dist$ic95_sup_hc3
dist_conv_sup <- comp_dist$ic95_sup_convencional
linha_coef <- function(modelo, termo) coeficientes[coeficientes$modelo == modelo & coeficientes$termo == termo, ]
urban_m3 <- linha_coef("Modelo 3", "urbanyes")
region_m3 <- linha_coef("Modelo 3", "regionwest")
validacao_texto <- checar(list(
  "Texto: coeficiente de distance negativo nos três modelos" = all(b_dist < 0),
  "Texto: magnitude de distance diminui a cada bloco" = abs(b_dist[[1]]) > abs(b_dist[[2]]) &&
    abs(b_dist[[2]]) > abs(b_dist[[3]]),
  "Texto: IC de distance exclui zero nas duas inferências" = all(dist_hc3_sup < 0) && all(dist_conv_sup < 0),
  "Texto: R² do Modelo 1 abaixo de 1%" = ajuste$r2[1] < .01,
  "Texto: IC HC3 de urban e region no Modelo 3 inclui zero" =
    urban_m3$ic95_inf_hc3 < 0 && urban_m3$ic95_sup_hc3 > 0 &&
    region_m3$ic95_inf_hc3 < 0 && region_m3$ic95_sup_hc3 > 0))
exportar(rbind(validacao_dados, validacao_modelos, validacao_texto), "14_regressao_validacao")

# 8. Nota de leitura e registro do ambiente -------------------------------------
n4 <- function(x) fmt(x, 4)
linha_tabela <- function(i) {
  d <- comparacao_distance[i, ]
  paste0("| ", d$modelo, " | ", n4(d$coeficiente_anos_por_10_milhas), " | ",
    fmt(d$meses_por_10_milhas, 2), " | ", n4(d$ep_hc3), " | ",
    "[", n4(d$ic95_inf_hc3), "; ", n4(d$ic95_sup_hc3), "] | ", fmt_p(d$p_hc3), " | ",
    n4(d$ep_convencional), " | [", n4(d$ic95_inf_convencional), "; ", n4(d$ic95_sup_convencional), "] | ",
    fmt_p(d$p_convencional), " | ", fmt(ajuste$r2[i], 3), " | ", fmt(ajuste$r2_ajustado[i], 3), " |")
}
d3 <- comparacao_distance[3, ]
reducao <- function(i) fmt(-comparacao_distance$variacao_percentual_vs_modelo_1[i], 0)
nota <- c("# Leitura das regressões por MQO", "",
  "Esta nota é gerada por `02_regressoes.R`. Não substitui o relatório final do trabalho.", "",
  "## Síntese", "",
  paste0("Na amostra, 10 milhas a mais até a faculdade de quatro anos se associam a ",
    fmt(abs(b_dist[[1]]), 3), " ano a menos de escolaridade sem controles e a ",
    fmt(abs(b_dist[[3]]), 3), " ano a menos (cerca de ", fmt(abs(d3$meses_por_10_milhas), 1),
    " mês) com todos os controles. O sinal se mantém e o intervalo de 95% exclui zero nos três modelos, ",
    "mas a magnitude cai ", reducao(3), "% e fica pequena. O resultado descreve uma associação, não um efeito causal."), "",
  "## Amostra e convenção de inferência", "",
  paste0("- Amostra comum: ", fmt(n_inicial, 0), " observações iniciais e ", fmt(n_final, 0),
    " finais; ", n_inicial - n_final, " exclusões. Os três modelos usam as mesmas linhas."),
  paste0("- As ", sum(amostra$distance == 0), " observações com distância zero e os valores extremos foram mantidos. Distância entra em nível."),
  paste0("- Referências: ", paste(paste0("`", names(referencias), "` = ", referencias), collapse = "; "), "."),
  paste0("- Inferência: teste bilateral com t de Student e gl = n - k, nos erros convencionais e HC3. ",
    "O IC de 95% é coeficiente ± t(0,975; n - k) × erro padrão. A nota destaca HC3 porque esse erro padrão não supõe ",
    "homocedasticidade; nenhum teste de heterocedasticidade foi feito nesta etapa. As duas inferências estão na tabela abaixo."),
  "- Valor-p igual a 0 nas tabelas indica valor menor que o menor número representável pelo computador, não probabilidade exatamente nula.", "",
  "## O que cada modelo procura medir", "",
  "As justificativas abaixo são hipóteses econômicas para incluir cada bloco. Não são resultados das regressões.", "",
  "- **Modelo 1: `distance`.** Associação bruta: compara a escolaridade média de estudantes a distâncias diferentes, sem ajuste. Distância pode refletir o custo de frequentar a faculdade (deslocamento ou moradia).",
  "- **Modelo 2: acrescenta `income`, `fcollege` e `mcollege`.** Compara estudantes com a mesma faixa de renda familiar (até ou acima de US$ 25 mil por ano) e a mesma condição de graduação do pai e da mãe. Renda pode refletir restrição de financiamento. A graduação dos pais pode refletir informação, preferências e recursos familiares. Esses fatores também podem estar ligados ao local onde a família mora.",
  "- **Modelo 3: acrescenta `score`, `gender`, `ethnicity`, `urban` e `region`.** Compara também estudantes com a mesma nota no teste do último ano do ensino médio, do mesmo sexo e grupo étnico, com escola na mesma condição urbana e na mesma região (West ou outra). A nota aproxima o preparo acadêmico prévio; as variáveis demográficas e locais captam diferenças de trajetória e de contexto.", "",
  "## Magnitude e incerteza da associação", "",
  "Uma unidade de `distance` corresponde a 10 milhas. Os coeficientes estão em anos de escolaridade por 10 milhas.", "",
  "| Modelo | Coeficiente | Meses | EP HC3 | IC 95% HC3 | p HC3 | EP conv. | IC 95% conv. | p conv. | R² | R² ajust. |",
  "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
  linha_tabela(1), linha_tabela(2), linha_tabela(3), "",
  paste0("No Modelo 3, o IC HC3 vai de ", fmt(abs(12 * d3$ic95_sup_hc3), 2), " a ", fmt(abs(12 * d3$ic95_inf_hc3), 2),
    " mês a menos por 10 milhas. Os dois tipos de erro padrão levam à mesma conclusão sobre `distance` a 5%; as diferenças entre eles são pequenas."), "",
  "## Como a associação muda entre os modelos", "",
  paste0("- Do Modelo 1 para o Modelo 2, o coeficiente passa de ", n4(b_dist[[1]]), " para ", n4(b_dist[[2]]),
    " (magnitude ", reducao(2), "% menor)."),
  paste0("- Do Modelo 1 para o Modelo 3, chega a ", n4(b_dist[[3]]), " (magnitude ", reducao(3), "% menor)."),
  paste0("- O R² sobe de ", fmt(ajuste$r2[1], 3), " para ", fmt(ajuste$r2[2], 3), " e ", fmt(ajuste$r2[3], 3),
    ". Sozinha, a distância explica menos de 1% da variação da escolaridade na amostra."),
  "- A amostra é a mesma, logo a mudança não vem da composição das observações. Pela álgebra do MQO, ela reflete a correlação de `distance` com os controles adicionados e a relação desses controles com `education`.",
  "- Os modelos não mostram qual mecanismo está por trás dessa queda nem separam a contribuição individual de cada controle. A diferença entre coeficientes também não foi testada formalmente: as comparações são descritivas.",
  paste0("- Nenhuma variável foi escolhida por valor-p. `urban` e `region` permanecem no Modelo 3 embora seus ICs HC3 incluam zero (p = ",
    fmt_p(urban_m3$p_hc3), " e ", fmt_p(region_m3$p_hc3), "). Isso não demonstra que seus coeficientes sejam nulos."), "",
  "## Controles e causalidade", "",
  "Controlar por desempenho inicial e características familiares muda a comparação realizada: o Modelo 3 compara estudantes parecidos nas variáveis observadas. Isso não demonstra causalidade nem elimina automaticamente a endogeneidade.", "",
  "- Fatores não observados, como motivação, qualidade da escola e características da comunidade, podem estar ligados à distância e à escolaridade. Famílias também podem escolher onde morar, o que tornaria a distância endógena.",
  "- Um controle pode não ser neutro. Se a distância ou fatores ligados a ela influenciarem a nota antes do teste, controlar por `score` retira parte da associação total. A queda do coeficiente não indica, por si só, que o modelo com mais controles esteja mais perto de um efeito causal.",
  "- O enunciado cita o uso da distância como variável instrumental em equações de salário. Isso supõe condições que estas regressões não testam; os resultados aqui não validam esse uso.", "",
  "## Significância estatística e relevância econômica", "",
  paste0("São coisas diferentes. No Modelo 3, a associação é estatisticamente distinta de zero a 5% (p HC3 = ", fmt_p(d3$p_hc3),
    "), mas a estimativa é pequena: entre o primeiro e o terceiro quartis da distância (", fmt(10 * quartis_dist[1], 0), " e ",
    fmt(10 * quartis_dist[2], 0), " milhas), a diferença prevista é de ", fmt(abs(d3$anos_entre_p25_e_p75_da_distancia), 3),
    " ano, ou ", fmt(abs(12 * d3$anos_entre_p25_e_p75_da_distancia), 1), " mês. Isso equivale a ",
    fmt(abs(d3$anos_entre_p25_e_p75_da_distancia) / dp_educ, 3), " desvio padrão da escolaridade (",
    fmt(dp_educ, 2), " anos). O desvio padrão da distância é de ", fmt(10 * dp_dist, 0), " milhas."), "",
  "A amostra grande ajuda a detectar associações pequenas. A base não traz custos e benefícios monetários, então estes números não bastam para concluir se a distância importa para uma política educacional.", "",
  "## Limitações", "",
  "- `education` é uma escala construída: 12 anos para todos os alunos do último ano do ensino médio, mais anos adicionais e valores atribuídos por diploma (13 para formação vocacional, 14 para AA, 16 para BA, 17 para pós-graduação incompleta e 18 para pós-graduação completa). O mínimo é 12, portanto o coeficiente não informa sobre abandono antes dessa etapa.",
  "- A pesquisa cobriu cerca de 1.100 escolas, mas a base não identifica a escola. Estudantes do mesmo local podem ter resíduos correlacionados. Nem o erro convencional nem o HC3 tratam isso, e a incerteza pode estar subestimada.",
  "- Não há pesos amostrais. A amostra é de estudantes americanos do ensino médio de 1980, com acompanhamento em 1986; os resultados não se estendem automaticamente a outras populações ou épocas.",
  "- `income` é uma faixa binária, e `fcollege` e `mcollege` indicam apenas graduação. Dentro de cada categoria ainda há diferenças que os modelos não capturam.",
  "- Forma funcional e hipóteses do MQO ainda não foram avaliadas. A linearidade em nível é uma escolha desta etapa, não uma conclusão. O intercepto do Modelo 3 corresponde a `score` = 0, fora da faixa observada, e não tem leitura substantiva.", "",
  "Fonte: documentação de AER::CollegeDistance; tabelas 09 a 14 em `resultados/tabelas/`; modelos em `resultados/modelos/`.")
writeLines(nota, file.path(pasta, "resultados/LEITURA_DAS_REGRESSOES.md"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(modelos_dir, "sessionInfo_regressoes.txt"))

print(comparacao_distance[, c("modelo", "n_observacoes", "coeficiente_anos_por_10_milhas",
  "ep_hc3", "ic95_inf_hc3", "ic95_sup_hc3", "p_hc3", "ep_convencional", "p_convencional")], row.names = FALSE)
print(ajuste[, c("modelo", "n_observacoes", "n_parametros", "r2", "r2_ajustado")], row.names = FALSE)
message("Etapa 2 concluída. ", nrow(validacao_dados) + nrow(validacao_modelos) + nrow(validacao_texto),
  " verificações aprovadas. Resultados em: ", file.path(pasta, "resultados"))
