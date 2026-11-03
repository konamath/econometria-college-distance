# COLLEGEDISTANCE | Etapa 4: comparação exploratória de formas funcionais
# Compara alternativas ao Modelo 3, motivadas pelos diagnósticos já observados.
# O objetivo não é tornar distance significativo nem fazer os testes deixarem de rejeitar.
# Nenhuma transformação demonstra causalidade nem corrige dependência entre estudantes.
# Execução no terminal: Rscript --vanilla 04_formas_funcionais.R
# Execução no console R ou RStudio: source("04_formas_funcionais.R", encoding = "UTF-8")

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
if (!file.exists(file.path(pasta, "04_formas_funcionais.R"))) {
  stop("Abra a pasta CollegeDistance_v1 e execute o script completo.")
}
for (p in c("ggplot2", "car", "lmtest", "sandwich", "gtable")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Falta o pacote ", p, ". Execute 00_preparar_ambiente.R primeiro.")
  }
}
library(ggplot2)
if (getOption("contrasts")[["unordered"]] != "contr.treatment") {
  stop("Use contrastes de tratamento: options(contrasts = c('contr.treatment', 'contr.poly')).")
}

# Tudo o que este script escreve fica em resultados/formas_funcionais/.
saida <- file.path(pasta, "resultados/formas_funcionais")
tabelas <- file.path(saida, "tabelas")
graficos <- file.path(saida, "graficos")
modelos_dir <- file.path(saida, "modelos")
for (d in c(tabelas, graficos, modelos_dir)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
exportar <- function(x, nome) {
  write.csv(x, file.path(tabelas, paste0(nome, ".csv")), row.names = FALSE,
            fileEncoding = "UTF-8", na = "")
}
ler_saida <- function(nome) {
  read.csv(file.path(tabelas, paste0(nome, ".csv")), encoding = "UTF-8", stringsAsFactors = FALSE)
}
fmt <- function(x, digitos = 2) {
  formatC(x, format = "f", digits = digitos, decimal.mark = ",", big.mark = ".")
}
fmt_p <- function(p) ifelse(p < .001, "< 0,001", fmt(p, 3))
checar <- function(lista) {
  falhas <- names(lista)[!vapply(lista, isTRUE, logical(1))]
  if (length(falhas)) stop("Verificação falhou: ", paste(falhas, collapse = " | "))
  length(lista)
}
iguais <- function(a, b) isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = 1e-8))

# 2. Conferir os resultados anteriores e carregar a base ------------------------
arquivo_base <- file.path(pasta, "dados/CollegeDistance_original.rds")
arquivo_m3 <- file.path(pasta, "resultados/modelos/modelo_3.rds")
arquivo_coef <- file.path(pasta, "resultados/tabelas/11_regressao_coeficientes.csv")
arquivo_reset <- file.path(pasta, "resultados/diagnosticos/tabelas/02_reset.csv")
arquivo_bp <- file.path(pasta, "resultados/diagnosticos/tabelas/04_breusch_pagan.csv")
anteriores <- c(arquivo_base, arquivo_m3, arquivo_coef, arquivo_reset, arquivo_bp)
for (a in anteriores) {
  if (!file.exists(a)) stop("Arquivo não encontrado: ", a, ". Execute as etapas anteriores.")
}
md5_antes <- unname(tools::md5sum(anteriores))
base <- readRDS(arquivo_base)
modelo_3_salvo <- readRDS(arquivo_m3)
coef_etapa2 <- read.csv(arquivo_coef, encoding = "UTF-8", stringsAsFactors = FALSE)
reset_etapa3 <- read.csv(arquivo_reset, encoding = "UTF-8", stringsAsFactors = FALSE)
bp_etapa3 <- read.csv(arquivo_bp, encoding = "UTF-8", stringsAsFactors = FALSE)
n_total <- nrow(base)

# Referências do Modelo 3, preservadas. Os nomes das linhas são os identificadores do AER.
referencias <- c(income = "low", fcollege = "no", mcollege = "no", gender = "male",
                 ethnicity = "other", urban = "no", region = "other")

# 3. Preparar as variáveis ------------------------------------------------------
# Centralização nas médias da amostra completa, apenas nos modelos quadráticos.
# Assim, o coeficiente linear é a associação marginal na média da variável,
# e os valores ajustados são idênticos aos do polinômio sem centralizar.
media_distance <- mean(base$distance)
media_score <- mean(base$score)
dados <- base
dados$distance_c <- dados$distance - media_distance
dados$score_c <- dados$score - media_score
exportar(data.frame(variavel = c("distance", "score"), constante_subtraida = c(media_distance, media_score),
  nova_variavel = c("distance_c", "score_c"), unidade = c("Dezenas de milhas", "Pontos"),
  definicao = "Média na amostra completa"), "01_constantes_centralizacao")

# A análise logarítmica de distância usa só distâncias positivas. Não é limpeza de
# dados: log(0) não existe, e esses estudantes continuam em A, B, C, D e E.
positiva <- dados$distance > 0
dados_pos <- dados[positiva, ]

# 4. Comparação principal: amostra completa ---------------------------------------
modelo_A <- lm(education ~ distance + income + fcollege + mcollege + score + gender +
                 ethnicity + urban + region, data = dados, na.action = na.fail)
modelo_B <- lm(education ~ distance + income + fcollege + mcollege + score_c + I(score_c^2) + gender +
                 ethnicity + urban + region, data = dados, na.action = na.fail)
modelo_C <- lm(education ~ distance_c + I(distance_c^2) + income + fcollege + mcollege + score + gender +
                 ethnicity + urban + region, data = dados, na.action = na.fail)
modelo_D <- lm(education ~ distance_c + I(distance_c^2) + income + fcollege + mcollege + score_c + I(score_c^2) +
                 gender + ethnicity + urban + region, data = dados, na.action = na.fail)
modelo_E <- lm(log(education) ~ distance + income + fcollege + mcollege + score + gender +
                 ethnicity + urban + region, data = dados, na.action = na.fail)

# 5. Comparação complementar: distância estritamente positiva ---------------------
modelo_P1 <- lm(education ~ distance + income + fcollege + mcollege + score + gender +
                  ethnicity + urban + region, data = dados_pos, na.action = na.fail)
modelo_P2 <- lm(education ~ log(distance) + income + fcollege + mcollege + score + gender +
                  ethnicity + urban + region, data = dados_pos, na.action = na.fail)
modelo_P3 <- lm(log(education) ~ distance + income + fcollege + mcollege + score + gender +
                  ethnicity + urban + region, data = dados_pos, na.action = na.fail)
modelo_P4 <- lm(log(education) ~ log(distance) + income + fcollege + mcollege + score + gender +
                  ethnicity + urban + region, data = dados_pos, na.action = na.fail)

completos <- list(A = modelo_A, B = modelo_B, C = modelo_C, D = modelo_D, E = modelo_E)
positivos <- list(P1 = modelo_P1, P2 = modelo_P2, P3 = modelo_P3, P4 = modelo_P4)
modelos <- c(completos, positivos)
for (nome in names(modelos)) saveRDS(modelos[[nome]], file.path(modelos_dir, paste0("modelo_", nome, ".rds")))

descricao <- c(A = "Modelo 3 original", B = "A + score²", C = "A + distance²", D = "A + score² + distance²",
  E = "log(education), explicativas de A", P1 = "education ~ distance", P2 = "education ~ log(distance)",
  P3 = "log(education) ~ distance", P4 = "log(education) ~ log(distance)")
amostra_de <- function(nome) if (nome %in% names(completos)) "Completa" else "Distância positiva"
dep_log <- function(m) identical(deparse(formula(m)[[2]]), "log(education)")
dependente_de <- function(m) if (dep_log(m)) "log(education)" else "education"
vcovs <- lapply(modelos, sandwich::vcovHC, type = "HC3")

# Amostras: o que sai só da análise complementar, e quão diferentes são esses estudantes.
exportar(data.frame(
  etapa = c("Observações na base preservada", "Comparação principal (A a E)", "Distâncias iguais a zero",
    "Retiradas apenas da análise complementar", "Análise complementar (P1 a P4)", "Excluídas da comparação principal"),
  n = c(n_total, nobs(modelo_A), sum(!positiva), sum(!positiva), nobs(modelo_P1), 0L)), "02_amostras")
exportar(data.frame(id_original = rownames(base)[!positiva], linha_na_base = which(!positiva),
  base[!positiva, c("education", "distance", "score", "urban", "region")], row.names = NULL), "03_ids_distancia_zero")
media_grupos <- function(rotulo, x) {
  data.frame(medida = rotulo, distancia_zero = mean(x[!positiva]), distancia_positiva = mean(x[positiva]))
}
perfil_zeros <- rbind(media_grupos("education (anos)", base$education), media_grupos("score (pontos)", base$score),
  media_grupos("Proporção income = high", base$income == "high"),
  media_grupos("Proporção fcollege = yes", base$fcollege == "yes"),
  media_grupos("Proporção mcollege = yes", base$mcollege == "yes"),
  media_grupos("Proporção ethnicity = afam", base$ethnicity == "afam"),
  media_grupos("Proporção ethnicity = hispanic", base$ethnicity == "hispanic"),
  media_grupos("Proporção urban = yes", base$urban == "yes"),
  media_grupos("Proporção region = west", base$region == "west"))
perfil_zeros$diferenca <- perfil_zeros$distancia_zero - perfil_zeros$distancia_positiva
exportar(perfil_zeros, "04_perfil_distancia_zero")

# 6. Coeficientes e inferência HC3 -------------------------------------------------
# Convenção igual à das etapas anteriores: teste bilateral com t de Student e
# gl = n - k. IC de 95% = coeficiente +/- t(0,975; n - k) x erro padrão HC3.
# Testes conjuntos: Wald com matriz HC3, F(q, n - k).
leitura_termo <- function(termo) {
  switch(termo,
    "(Intercept)" = "Grupo-base; sem leitura substantiva isolada",
    "distance" = "Variação por 10 milhas, constante em distance",
    "distance_c" = paste0("Associação marginal por 10 milhas apenas em distance = ", fmt(media_distance, 3), " (média); não é associação constante"),
    "I(distance_c^2)" = "Curvatura; associação marginal = b_linear + 2 x b_quadrado x (distance - média)",
    "log(distance)" = "Variação por unidade de log(distance); ver a nota para a leitura",
    "score" = "Variação por ponto, constante em score",
    "score_c" = paste0("Associação marginal por ponto apenas em score = ", fmt(media_score, 3), " (média); não é associação constante"),
    "I(score_c^2)" = "Curvatura; associação marginal = b_linear + 2 x b_quadrado x (score - média)",
    "Diferença em relação à categoria de referência")
}
referencia_termo <- function(termo) {
  v <- names(referencias)[startsWith(termo, names(referencias))]
  if (length(v)) referencias[[v]] else "Não se aplica"
}
coeficientes <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  b <- coef(m)
  ep <- sqrt(diag(vcovs[[nome]]))
  gl <- df.residual(m)
  critico <- qt(.975, gl)
  data.frame(modelo = nome, descricao = descricao[[nome]], amostra = amostra_de(nome), dependente = dependente_de(m),
    termo = names(b), categoria_referencia = vapply(names(b), referencia_termo, character(1)),
    coeficiente = b, ep_hc3 = ep, t_hc3 = b / ep, p_hc3 = 2 * pt(abs(b / ep), gl, lower.tail = FALSE),
    ic95_inf_hc3 = b - critico * ep, ic95_sup_hc3 = b + critico * ep, gl_residuos = gl,
    leitura = vapply(names(b), leitura_termo, character(1)), row.names = NULL)
}))
exportar(coeficientes, "05_coeficientes_hc3")
linha_coef <- function(modelo, termo) coeficientes[coeficientes$modelo == modelo & coeficientes$termo == termo, ]

# R² só dentro de grupos com a mesma dependente e a mesma amostra.
grupos_r2 <- list("Amostra completa, education" = c("A", "B", "C", "D"), "Amostra completa, log(education)" = "E",
  "Distância positiva, education" = c("P1", "P2"), "Distância positiva, log(education)" = c("P3", "P4"))
ajuste <- do.call(rbind, lapply(names(grupos_r2), function(g) {
  do.call(rbind, lapply(grupos_r2[[g]], function(nome) {
    m <- modelos[[nome]]
    s <- summary(m)
    ref <- summary(modelos[[grupos_r2[[g]][1]]])
    data.frame(grupo_comparavel = g, modelo = nome, descricao = descricao[[nome]], n_observacoes = nobs(m),
      n_parametros = length(coef(m)), r2 = s$r.squared, r2_ajustado = s$adj.r.squared,
      r2_menos_primeiro_do_grupo = s$r.squared - ref$r.squared,
      r2_ajustado_menos_primeiro_do_grupo = s$adj.r.squared - ref$adj.r.squared)
  }))
}))
exportar(ajuste, "06_ajuste_grupos_comparaveis")

# Testes dos termos adicionais: individuais (F = t²) e conjunto no Modelo D.
wald_hc3 <- function(nome, termos) {
  m <- modelos[[nome]]
  V <- vcovs[[nome]][termos, termos, drop = FALSE]
  b <- coef(m)[termos]
  f <- drop(t(b) %*% solve(V) %*% b) / length(termos)
  data.frame(modelo = nome, termos_testados = paste(termos, collapse = " e "), q = length(termos),
    estatistica_f = f, gl2 = df.residual(m), valor_p = pf(f, length(termos), df.residual(m), lower.tail = FALSE))
}
q_d <- "I(distance_c^2)"
q_s <- "I(score_c^2)"
testes_termos <- rbind(wald_hc3("B", q_s), wald_hc3("C", q_d), wald_hc3("D", q_d), wald_hc3("D", q_s), wald_hc3("D", c(q_d, q_s)))
exportar(testes_termos, "07_testes_termos_adicionais")

# 7. Associação marginal de distance em pontos representativos ---------------------
# Cada associação é uma combinação linear g'b, com EP = raiz de g'Vg e V HC3 completa.
# Nos modelos com log da dependente, g'b está em log-pontos por 10 milhas. A coluna
# em anos multiplica pela média prevista em anos naquele ponto (com smearing), tratada
# como fixa: é uma aproximação para comparar escalas, sem incorporar a incerteza dela.
termos_distance <- function(nome) {
  if (nome %in% c("C", "D")) {
    list(valores = function(d) c("distance_c" = d - media_distance, "I(distance_c^2)" = (d - media_distance)^2),
         derivada = function(d) c("distance_c" = 1, "I(distance_c^2)" = 2 * (d - media_distance)))
  } else if (nome %in% c("P2", "P4")) {
    list(valores = function(d) c("log(distance)" = log(d)), derivada = function(d) c("log(distance)" = 1 / d))
  } else {
    list(valores = function(d) c("distance" = d), derivada = function(d) c("distance" = 1))
  }
}
fator_smearing <- function(m) mean(exp(resid(m)))
# Média prevista em anos com distance = d para todos, mantendo os demais regressores de cada estudante.
media_anos_em <- function(m, valores) {
  X <- model.matrix(m)
  eta <- drop(X %*% coef(m))
  deslocamento <- drop(sweep(-X[, names(valores), drop = FALSE], 2, valores, "+") %*% coef(m)[names(valores)])
  mean(exp(eta + deslocamento)) * fator_smearing(m)
}
associacao_em <- function(nome, d) {
  m <- modelos[[nome]]
  t_d <- termos_distance(nome)
  g <- setNames(rep(0, length(coef(m))), names(coef(m)))
  g[names(t_d$derivada(d))] <- t_d$derivada(d)
  est <- sum(g * coef(m))
  ep <- sqrt(drop(t(g) %*% vcovs[[nome]] %*% g))
  gl <- df.residual(m)
  fator <- if (dep_log(m)) media_anos_em(m, t_d$valores(d)) else 1
  data.frame(est = est, ep = ep, t = est / ep, p = 2 * pt(abs(est / ep), gl, lower.tail = FALSE),
    inf = est - qt(.975, gl) * ep, sup = est + qt(.975, gl) * ep, fator = fator)
}
pontos_de <- function(x) {
  q <- quantile(x, c(.25, .5, .75, .9, .95, .99))
  data.frame(ponto = c("Mínimo", "p25", "p50", "p75", "p90", "p95", "p99", "Máximo"), d = c(min(x), q, max(x)), row.names = NULL)
}
pontos_completa <- pontos_de(dados$distance)
pontos_positiva <- pontos_de(dados_pos$distance)
marginais <- do.call(rbind, lapply(names(modelos), function(nome) {
  pts <- if (nome %in% names(completos)) pontos_completa else pontos_positiva
  amostra_d <- if (nome %in% names(completos)) dados$distance else dados_pos$distance
  do.call(rbind, lapply(seq_len(nrow(pts)), function(i) {
    a <- associacao_em(nome, pts$d[i])
    data.frame(modelo = nome, descricao = descricao[[nome]], amostra = amostra_de(nome), ponto = pts$ponto[i],
      distance = pts$d[i], milhas = 10 * pts$d[i], n_ate_5_milhas_do_ponto = sum(abs(amostra_d - pts$d[i]) <= .5),
      escala_propria = if (dep_log(modelos[[nome]])) "Log-pontos por 10 milhas" else "Anos por 10 milhas",
      associacao = a$est, ep_hc3 = a$ep, t_hc3 = a$t, p_hc3 = a$p, ic95_inf_hc3 = a$inf, ic95_sup_hc3 = a$sup,
      media_prevista_anos_usada = if (dep_log(modelos[[nome]])) a$fator else NA_real_,
      equivalente_anos_por_10_milhas = a$est * a$fator, equivalente_anos_ic95_inf = a$inf * a$fator,
      equivalente_anos_ic95_sup = a$sup * a$fator)
  }))
}))
exportar(marginais, "08_associacao_marginal_distance")
marg <- function(modelo, ponto) marginais[marginais$modelo == modelo & marginais$ponto == ponto, ]

# Pontos de inversão: x* = média - b_linear / (2 x b_quadrado), com EP pelo método delta.
inversao <- function(nome, var, media, linear, quadrado, janela) {
  m <- modelos[[nome]]
  b1 <- coef(m)[[linear]]
  b2 <- coef(m)[[quadrado]]
  x <- dados[[var]]
  estrela <- media - b1 / (2 * b2)
  g <- c(-1 / (2 * b2), b1 / (2 * b2^2))
  ep <- sqrt(drop(t(g) %*% vcovs[[nome]][c(linear, quadrado), c(linear, quadrado)] %*% g))
  critico <- qt(.975, df.residual(m))
  no_suporte <- estrela >= min(x) && estrela <= max(x)
  data.frame(modelo = nome, variavel = var, tipo = if (b2 > 0) "Mínimo da curva" else "Máximo da curva",
    ponto_inversao = estrela, ep_delta_hc3 = ep, ic95_inf = estrela - critico * ep, ic95_sup = estrela + critico * ep,
    minimo_observado = min(x), maximo_observado = max(x), no_suporte = no_suporte,
    n_abaixo = sum(x < estrela), n_acima = sum(x > estrela), percentual_acima = 100 * mean(x > estrela),
    janela = janela, n_na_janela = sum(abs(x - estrela) <= janela))
}
inversoes <- rbind(inversao("C", "distance", media_distance, "distance_c", q_d, 1),
  inversao("D", "distance", media_distance, "distance_c", q_d, 1),
  inversao("B", "score", media_score, "score_c", q_s, 5), inversao("D", "score", media_score, "score_c", q_s, 5))
exportar(inversoes, "09_pontos_inversao")

# Suporte de distance. Sem excluir nem reestimar: pelo teorema de Frisch-Waugh, o peso
# de cada observação na identificação de um coeficiente é o quadrado do seu regressor
# residualizado nos demais, dividido pela soma desses quadrados.
peso_identificacao <- function(m, termo) {
  X <- model.matrix(m)
  r <- lm.fit(X[, colnames(X) != termo, drop = FALSE], X[, termo])$residuals
  r^2 / sum(r^2)
}
peso_linear_A <- peso_identificacao(modelo_A, "distance")
peso_quad_C <- peso_identificacao(modelo_C, q_d)
peso_log_P2 <- peso_identificacao(modelo_P2, "log(distance)")
cortes_dist <- c(0, .0001, .5, 1, 2, 5, 10, 20)
rotulos_dist <- c("0", "Até 5 milhas", "5 a 10 milhas", "10 a 20 milhas", "20 a 50 milhas", "50 a 100 milhas", "100 a 200 milhas")
faixa_dist <- cut(dados$distance, cortes_dist, labels = rotulos_dist, include.lowest = TRUE)
suporte <- data.frame(faixa_distancia = rotulos_dist, n = as.integer(table(faixa_dist)),
  percentual = 100 * as.integer(table(faixa_dist)) / n_total,
  peso_no_coef_linear_modelo_A = 100 * as.numeric(tapply(peso_linear_A, faixa_dist, sum)),
  peso_no_termo_quadratico_modelo_C = 100 * as.numeric(tapply(peso_quad_C, faixa_dist, sum)),
  peso_no_log_distance_modelo_P2 = 100 * as.numeric(tapply(peso_log_P2, faixa_dist[positiva], sum)))
exportar(suporte, "10_suporte_distance")
cauda <- dados$distance > 10
acima_inversao <- dados$distance > inversoes$ponto_inversao[1]

# Mudança de amostra separada de mudança de forma: mesma especificação, duas amostras.
termos_A <- names(coef(modelo_A))
mudanca_amostra <- data.frame(termo = termos_A, coef_A_completa = coef(modelo_A), ep_hc3_A_completa = sqrt(diag(vcovs$A)),
  coef_A_positiva = coef(modelo_P1)[termos_A], ep_hc3_A_positiva = sqrt(diag(vcovs$P1))[termos_A],
  diferenca = coef(modelo_P1)[termos_A] - coef(modelo_A), row.names = NULL)
mudanca_amostra$diferenca_percentual <- 100 * mudanca_amostra$diferenca / mudanca_amostra$coef_A_completa
exportar(mudanca_amostra, "11_mudanca_de_amostra_modelo_A")

# 8. Diagnósticos direcionados -----------------------------------------------------
# RESET robusto como em 03_diagnosticos.R: ŷ² e ŷ³ na auxiliar, Wald F com HC3.
# ŷ está na escala da dependente de cada modelo, então a estatística não é uma nota
# comparável entre níveis e logs. O Breusch-Pagan usa os regressores de cada modelo.
reset_robusto <- function(m) {
  y <- model.response(model.frame(m))
  z <- as.numeric(scale(fitted(m)))
  A <- cbind(model.matrix(m), z2 = z^2, z3 = z^3)
  auxiliar <- lm(y ~ A - 1)
  novos <- c("Az2", "Az3")
  V <- sandwich::vcovHC(auxiliar, type = "HC3")[novos, novos]
  b <- coef(auxiliar)[novos]
  f <- drop(t(b) %*% solve(V) %*% b) / 2
  c(f = f, gl2 = df.residual(auxiliar), p = pf(f, 2, df.residual(auxiliar), lower.tail = FALSE))
}
diagnosticos <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  r <- reset_robusto(m)
  bp <- lmtest::bptest(m, studentize = TRUE)
  data.frame(modelo = nome, descricao = descricao[[nome]], amostra = amostra_de(nome), dependente = dependente_de(m),
    reset_robusto_f = r[["f"]], reset_gl2 = r[["gl2"]], reset_p = r[["p"]],
    bp_studentizado_lm = unname(bp$statistic), bp_gl = unname(bp$parameter), bp_p = unname(bp$p.value),
    alavancagem_maxima = max(hatvalues(m)))
}))
exportar(diagnosticos, "12_reset_breusch_pagan")
diag_de <- function(nome) diagnosticos[diagnosticos$modelo == nome, ]

# Previsões em anos. Com dependente em log, exp(previsão) NÃO estima a média condicional:
# sob erros simétricos, aproxima a mediana. A média usa o fator de smearing de Duan,
# que supõe distribuição do erro sem relação com os regressores; é, portanto, aproximada.
linha_previsao <- function(nome, versao, previsto, y) {
  data.frame(modelo = nome, descricao = descricao[[nome]], amostra = amostra_de(nome), versao = versao,
    n = length(previsto), n_abaixo_de_12 = sum(previsto < 12), n_acima_de_18 = sum(previsto > 18),
    previsto_minimo = min(previsto), previsto_maximo = max(previsto), media_prevista = mean(previsto),
    media_observada = mean(y), raiz_erro_quadratico_medio_anos = sqrt(mean((y - previsto)^2)))
}
previsoes <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  y <- model.frame(m)$`education`
  if (dep_log(m)) {
    y <- exp(model.response(model.frame(m)))
    rbind(linha_previsao(nome, "exp(previsão em log)", exp(fitted(m)), y),
      linha_previsao(nome, "Média com smearing de Duan", exp(fitted(m)) * fator_smearing(m), y))
  } else {
    linha_previsao(nome, "Previsão direta em anos", fitted(m), y)
  }
}))
previsoes$fator_smearing <- vapply(previsoes$modelo, function(nome) {
  if (dep_log(modelos[[nome]])) fator_smearing(modelos[[nome]]) else NA_real_
}, numeric(1))
exportar(previsoes, "13_previsoes_em_anos")
prev_de <- function(nome, i = 1) previsoes[previsoes$modelo == nome, ][i, ]

# 9. Gráficos ----------------------------------------------------------------------
azul <- "#245B78"
laranja <- "#BA642E"
cinza <- "#24333B"
verde <- "#3F7D58"
roxo <- "#7A5C99"
cinza_medio <- "#6B7780"
tema <- theme_minimal(base_size = 13, base_family = "sans") +
  theme(plot.title = element_text(face = "bold", size = 19, color = cinza),
    plot.subtitle = element_text(size = 11, color = "#52616B", margin = margin(b = 12)),
    plot.caption = element_text(size = 9, hjust = 0, margin = margin(t = 12)),
    panel.grid.minor = element_blank(), axis.title = element_text(size = 12),
    plot.margin = margin(14, 24, 10, 18), legend.position = "top", legend.justification = "left",
    legend.title = element_blank(), legend.key.width = unit(2, "lines"))
rodape <- "Fonte: AER::CollegeDistance | Exploratório: alternativas motivadas por diagnósticos já observados."
vir <- function(digitos) function(x) fmt(x, digitos)
salvar <- function(p, nome, largura = 10, altura = 7) {
  ggsave(file.path(graficos, paste0(nome, ".png")), p, width = largura, height = altura,
         units = "in", dpi = 180, bg = "white")
}
# Curva na parte de cima, distribuição da variável embaixo, com o mesmo eixo horizontal.
com_distribuicao <- function(p_curva, p_dist) {
  g <- rbind(ggplotGrob(p_curva), ggplotGrob(p_dist), size = "max")
  paineis <- unique(g$layout$t[grepl("panel", g$layout$name)])
  g$heights[paineis] <- unit(c(3, 1), "null")
  g
}
histograma <- function(x, limites, largura, rotulo_x, legenda, rotular_de) {
  d <- data.frame(x = x)
  ggplot(d, aes(x)) +
    geom_histogram(binwidth = largura, boundary = limites[1], closed = "left", fill = azul, color = "white") +
    stat_bin(binwidth = largura, boundary = limites[1], closed = "left", geom = "text", size = 2.9, vjust = -.4, color = cinza,
      aes(label = ifelse(after_stat(count) > 0 & after_stat(x) >= rotular_de, after_stat(count), ""))) +
    coord_cartesian(xlim = limites) +
    scale_x_continuous(labels = vir(0)) + scale_y_continuous(labels = vir(0), expand = expansion(mult = c(0, .22))) +
    labs(x = rotulo_x, y = "Estudantes", caption = legenda) + tema
}
# Curvas ajustadas. Nos modelos em nível: demais regressores nas médias amostrais,
# inclusive as indicadoras (composição média), com IC HC3 pela matriz completa.
# Nos modelos em log: média em anos, com smearing, fixando distance ou score para
# todos e mantendo os demais regressores de cada estudante; sem faixa de IC.
curva <- function(nome, grade, termos) {
  m <- modelos[[nome]]
  x_medio <- colMeans(model.matrix(m))
  do.call(rbind, lapply(grade, function(v) {
    t_v <- termos(v)
    if (dep_log(m)) {
      return(data.frame(modelo = nome, x = v, ajuste = media_anos_em(m, t_v), inf = NA_real_, sup = NA_real_))
    }
    g <- x_medio
    g[names(t_v)] <- t_v
    est <- sum(g * coef(m))
    ep <- sqrt(drop(t(g) %*% vcovs[[nome]] %*% g))
    critico <- qt(.975, df.residual(m))
    data.frame(modelo = nome, x = v, ajuste = est, inf = est - critico * ep, sup = est + critico * ep)
  }))
}
nota_curvas <- paste0("Curvas limitadas à faixa observada. Modelos em nível: demais regressores nas médias amostrais, com IC de 95% HC3 sombreado em A e C.\n",
  "Modelo em log: média em anos com smearing, sem faixa de IC. Os números acima das barras são contagens por classe de 10 milhas.")
grade_d <- seq(0, max(dados$distance), by = .1)
curvas_d <- do.call(rbind, lapply(c("A", "C", "D", "E"), function(nome) {
  curva(nome, grade_d, termos_distance(nome)$valores)
}))
cores_d <- c(A = azul, C = laranja, D = roxo, E = cinza_medio)
linhas_d <- c(A = "solid", C = "solid", D = "dashed", E = "dotted")
rotulos_d <- c(A = "A: linear", C = "C: distance²", D = "D: distance² e score²", E = "E: log(education)")
faixa_ic <- subset(curvas_d, modelo %in% c("A", "C"))
limites_d <- c(0, 20)
p1a <- ggplot(curvas_d, aes(x, ajuste, color = modelo, linetype = modelo)) +
  geom_ribbon(data = faixa_ic, aes(ymin = inf, ymax = sup, fill = modelo), color = NA, alpha = .16, show.legend = FALSE) +
  geom_line(linewidth = .9) +
  scale_color_manual(values = cores_d, labels = rotulos_d) + scale_fill_manual(values = cores_d) +
  scale_linetype_manual(values = linhas_d, labels = rotulos_d) +
  coord_cartesian(xlim = limites_d) + scale_x_continuous(labels = vir(0)) + scale_y_continuous(labels = vir(1)) +
  labs(title = "Escolaridade prevista conforme a distância", subtitle = "Amostra completa, 4.739 estudantes",
       x = NULL, y = "Escolaridade prevista (anos)") + tema
p1b <- histograma(dados$distance, limites_d, 1, "Distância (dezenas de milhas; 1 unidade = 10 milhas)",
  paste0(rodape, "\n", nota_curvas), 0)
salvar(com_distribuicao(p1a, p1b), "01_curvas_distancia")

# Associação marginal em anos por 10 milhas ao longo da distância.
marginal_grade <- do.call(rbind, lapply(c("A", "C"), function(nome) {
  a <- do.call(rbind, lapply(grade_d, function(v) associacao_em(nome, v)))
  data.frame(modelo = nome, x = grade_d, est = a$est, inf = a$inf, sup = a$sup)
}))
# P2 começa em 5 milhas: abaixo disso a inclinação local cresce sem limite e sairia da escala.
grade_log <- grade_d[grade_d >= .5]
marginal_log <- data.frame(modelo = "P2", x = grade_log,
  est = vapply(grade_log, function(v) associacao_em("P2", v)$est, numeric(1)))
cores_m <- c(A = azul, C = laranja, P2 = verde)
rotulos_m <- c(A = "A: linear", C = "C: distance²", P2 = "P2: log(distance), sem os zeros")
p2a <- ggplot(marginal_grade, aes(x, est, color = modelo)) +
  geom_hline(yintercept = 0, color = cinza, linewidth = .4) +
  geom_ribbon(aes(ymin = inf, ymax = sup, fill = modelo), color = NA, alpha = .16, show.legend = FALSE) +
  geom_line(aes(linetype = modelo), linewidth = .9) +
  geom_line(data = marginal_log, aes(linetype = modelo), linewidth = .9) +
  scale_color_manual(values = cores_m, labels = rotulos_m) + scale_fill_manual(values = cores_m) +
  scale_linetype_manual(values = c(A = "solid", C = "solid", P2 = "dashed"), labels = rotulos_m) +
  coord_cartesian(xlim = limites_d) + scale_x_continuous(labels = vir(0)) + scale_y_continuous(labels = vir(2)) +
  labs(title = "Associação marginal de distância com escolaridade",
    subtitle = paste0("A inversão no Modelo C (cerca de ", fmt(10 * inversoes$ponto_inversao[1], 0), " milhas) deixa ",
      sum(acima_inversao), " estudantes acima dela"), x = NULL, y = "Anos por 10 milhas adicionais") + tema
p2b <- histograma(dados$distance, limites_d, 1, "Distância (dezenas de milhas; 1 unidade = 10 milhas)",
  paste0(rodape, "\nFaixas: IC de 95% com a matriz HC3 completa, em A e C. P2 a partir de 5 milhas, sem faixa. Limitado à faixa observada.\nNúmeros: contagens por classe de 10 milhas."), 0)
salvar(com_distribuicao(p2a, p2b), "02_associacao_marginal_distancia")

# Curvas em score.
termos_score <- function(nome) {
  if (nome %in% c("B", "D")) {
    function(s) c("score_c" = s - media_score, "I(score_c^2)" = (s - media_score)^2)
  } else {
    function(s) c("score" = s)
  }
}
grade_s <- seq(min(dados$score), max(dados$score), length.out = 100)
curvas_s <- do.call(rbind, lapply(c("A", "B", "D"), function(nome) curva(nome, grade_s, termos_score(nome))))
cores_s <- c(A = azul, B = verde, D = roxo)
linhas_s <- c(A = "solid", B = "solid", D = "dashed")
rotulos_s <- c(A = "A: linear", B = "B: score²", D = "D: distance² e score²")
limites_s <- range(dados$score)
p3a <- ggplot(curvas_s, aes(x, ajuste, color = modelo, linetype = modelo)) +
  geom_hline(yintercept = 12, color = cinza, linewidth = .4) +
  annotate("text", x = limites_s[2], y = 12, label = "Piso da escala: 12 anos", hjust = 1, vjust = -.5, size = 3.3, color = cinza) +
  geom_line(linewidth = .9) +
  scale_color_manual(values = cores_s, labels = rotulos_s) + scale_linetype_manual(values = linhas_s, labels = rotulos_s) +
  coord_cartesian(xlim = limites_s) + scale_x_continuous(labels = vir(0)) + scale_y_continuous(labels = vir(0)) +
  labs(title = "Escolaridade prevista conforme o desempenho inicial", subtitle = "Amostra completa, 4.739 estudantes",
       x = NULL, y = "Escolaridade prevista (anos)") + tema
p3b <- histograma(dados$score, limites_s, 2.5, "Nota no teste do último ano do ensino médio (pontos)",
  paste0(rodape, "\nCurvas com os demais regressores nas médias amostrais, limitadas à faixa observada. Barras: classes de 2,5 pontos."), Inf)
salvar(com_distribuicao(p3a, p3b), "03_curvas_score")

# Comparação na subamostra positiva, em anos.
grade_p <- seq(min(dados_pos$distance), max(dados_pos$distance), by = .1)
curvas_p <- do.call(rbind, lapply(names(positivos), function(nome) curva(nome, grade_p, termos_distance(nome)$valores)))
cores_p <- c(P1 = azul, P2 = laranja, P3 = cinza_medio, P4 = roxo)
linhas_p <- c(P1 = "solid", P2 = "solid", P3 = "dotted", P4 = "dashed")
rotulos_p <- c(P1 = "P1: nível-nível", P2 = "P2: nível-log", P3 = "P3: log-nível", P4 = "P4: log-log")
p4a <- ggplot(curvas_p, aes(x, ajuste, color = modelo, linetype = modelo)) + geom_line(linewidth = .9) +
  scale_color_manual(values = cores_p, labels = rotulos_p) + scale_linetype_manual(values = linhas_p, labels = rotulos_p) +
  coord_cartesian(xlim = limites_d) + scale_x_continuous(labels = vir(0)) + scale_y_continuous(labels = vir(1)) +
  labs(title = "Distância em nível e em log, só com distâncias positivas",
    subtitle = paste0(fmt(nrow(dados_pos), 0), " estudantes | ", sum(!positiva), " com distância zero ficam fora só desta comparação"),
    x = NULL, y = "Escolaridade prevista (anos)") + tema
p4b <- histograma(dados_pos$distance, limites_d, 1, "Distância (dezenas de milhas; a curva começa em 1 milha)",
  paste0(rodape, "\nP1 e P2: demais regressores nas médias. P3 e P4: média em anos com smearing. Sem faixas de IC. Números: contagens por classe de 10 milhas."), 0)
salvar(com_distribuicao(p4a, p4b), "04_curvas_subamostra_positiva")

# Resíduos em anos: no Modelo E, observado menos média prevista com smearing.
residuo_anos <- function(nome) {
  m <- modelos[[nome]]
  if (dep_log(m)) dados$education - exp(fitted(m)) * fator_smearing(m) else resid(m)
}
residuos_longos <- rbind(
  do.call(rbind, lapply(c("A", "B", "D", "E"), function(nome) {
    data.frame(modelo = nome, painel = "Resíduos contra score (pontos)", x = dados$score, residuo = residuo_anos(nome))
  })),
  do.call(rbind, lapply(c("A", "C", "D", "E"), function(nome) {
    data.frame(modelo = nome, painel = "Resíduos contra distance (dezenas de milhas)", x = dados$distance, residuo = residuo_anos(nome))
  })))
cores_r <- c(A = azul, B = verde, C = laranja, D = roxo, E = cinza_medio)
linhas_r <- c(A = "solid", B = "solid", C = "solid", D = "dashed", E = "dotted")
rotulos_r <- c(A = "A", B = "B: score²", C = "C: distance²", D = "D: ambos", E = "E: log(education)")
p5 <- ggplot(residuos_longos, aes(x, residuo, color = modelo, linetype = modelo)) +
  geom_hline(yintercept = 0, color = cinza, linewidth = .4) +
  geom_smooth(method = "loess", formula = y ~ x, span = .75, se = FALSE, linewidth = .9) +
  facet_wrap(~painel, scales = "free_x") +
  scale_color_manual(values = cores_r, labels = rotulos_r) + scale_linetype_manual(values = linhas_r, labels = rotulos_r) +
  scale_x_continuous(labels = vir(0)) + scale_y_continuous(labels = vir(1)) +
  labs(title = "Padrão médio dos resíduos em cada alternativa",
    subtitle = "Curvas LOESS; os pontos foram omitidos para permitir a comparação",
    x = NULL, y = "Resíduo médio local (anos)",
    caption = paste0(rodape, "\nResíduos em anos; no Modelo E, com a média prevista por smearing. Em cada painel, só as alternativas pertinentes. Curva apenas descritiva.")) +
  tema + theme(strip.text = element_text(face = "bold", size = 12, color = cinza), panel.spacing = unit(1.4, "lines"))
salvar(p5, "05_residuos_loess", largura = 12, altura = 6)

# 10. Conferir amostras e cálculos -------------------------------------------------
ler_coef <- ler_saida("05_coeficientes_hc3")
ler_marg <- ler_saida("08_associacao_marginal_distance")
ler_diag <- ler_saida("12_reset_breusch_pagan")
ler_ajuste <- ler_saida("06_ajuste_grupos_comparaveis")
m3_etapa2 <- coef_etapa2[coef_etapa2$modelo == "Modelo 3", ]
reset3 <- reset_etapa3[reset_etapa3$modelo == "Modelo 3" & grepl("Robusta", reset_etapa3$versao), ]
polinomio_cru <- lm(education ~ distance + I(distance^2) + income + fcollege + mcollege + score + I(score^2) + gender +
                      ethnicity + urban + region, data = dados)
lh <- function(nome, termos) car::linearHypothesis(modelos[[nome]], paste0(termos, " = 0"), vcov. = vcovs[[nome]], test = "F")
lh_conjunto <- lh("D", c(q_d, q_s))
d_teste <- pontos_completa$d[pontos_completa$ponto == "p75"]
passo <- 1e-4
numerico_C <- (curva("C", d_teste + passo, termos_distance("C")$valores)$ajuste -
  curva("C", d_teste - passo, termos_distance("C")$valores)$ajuste) / (2 * passo)
lc_C <- car::deltaMethod(setNames(coef(modelo_C), paste0("b", seq_along(coef(modelo_C)))),
  paste0("b2 + 2 * b3 * ", d_teste - media_distance), vcov. = vcovs$C)
total_checagens <- checar(list(
  "Modelo A igual ao Modelo 3 salvo" = isTRUE(all.equal(coef(modelo_A), coef(modelo_3_salvo))) &&
    identical(rownames(model.frame(modelo_A)), rownames(model.frame(modelo_3_salvo))),
  "Modelo A igual à tabela 11, inclusive HC3" = iguais(coef(modelo_A), m3_etapa2$coeficiente) &&
    iguais(sqrt(diag(vcovs$A)), m3_etapa2$ep_hc3),
  "RESET e Breusch-Pagan de A iguais aos da etapa 3" = iguais(diag_de("A")$reset_robusto_f, reset3$estatistica_f) &&
    iguais(diag_de("A")$bp_studentizado_lm, bp_etapa3$estatistica_lm[bp_etapa3$modelo == "Modelo 3"]),
  "A a E usam as mesmas linhas e mantêm os zeros" = all(vapply(completos, function(m)
    identical(rownames(model.frame(m)), rownames(base)) && sum(model.frame(m)[["distance"]] == 0, na.rm = TRUE) %in% c(0L, sum(!positiva)), logical(1))) &&
    all(vapply(completos, nobs, numeric(1)) == n_total),
  "P1 a P4 usam as mesmas linhas, todas com distance positiva" = all(vapply(positivos, function(m)
    identical(rownames(model.frame(m)), rownames(base)[positiva]), logical(1))) && all(dados_pos$distance > 0),
  "Número de retiradas igual ao de zeros" = n_total - nobs(modelo_P1) == sum(base$distance == 0),
  "Sem log de zero nem valores não finitos" = all(is.finite(log(dados_pos$distance))) && all(is.finite(log(dados$education))) &&
    all(vapply(modelos, function(m) all(is.finite(fitted(m))), logical(1))),
  "Nenhum coeficiente não identificado" = all(vapply(modelos, function(m)
    !anyNA(coef(m)) && m$rank == length(coef(m)), logical(1))),
  "Alavancagem abaixo de 1 em todos os modelos" = all(diagnosticos$alavancagem_maxima < 1),
  "Centralizar não muda os valores ajustados" = isTRUE(all.equal(fitted(modelo_D), fitted(polinomio_cru), check.attributes = FALSE, tolerance = 1e-8)),
  "Wald conjunto igual ao car::linearHypothesis" = iguais(testes_termos$estatistica_f[5], lh_conjunto$F[2]) &&
    iguais(testes_termos$valor_p[5], lh_conjunto$`Pr(>F)`[2]),
  "F individual igual a t²" = iguais(testes_termos$estatistica_f[2], linha_coef("C", q_d)$t_hc3^2),
  "Marginal analítica igual à derivada numérica da curva" = abs(numerico_C - marg("C", "p75")$associacao) < 1e-6,
  "Marginal e EP iguais ao car::deltaMethod" = iguais(lc_C$Estimate, marg("C", "p75")$associacao) &&
    iguais(lc_C$SE, marg("C", "p75")$ep_hc3),
  "Pesos de identificação somam 1" = iguais(sum(peso_quad_C), 1) && iguais(sum(peso_linear_A), 1),
  "Tabelas exportadas iguais aos objetos" = iguais(ler_coef$coeficiente, coeficientes$coeficiente) &&
    iguais(ler_coef$ep_hc3, coeficientes$ep_hc3) && iguais(ler_marg$associacao, marginais$associacao) &&
    iguais(ler_diag$reset_robusto_f, diagnosticos$reset_robusto_f) && iguais(ler_ajuste$r2, ajuste$r2),
  "Modelos salvos iguais aos estimados" = all(vapply(names(modelos), function(nome) isTRUE(all.equal(
    coef(readRDS(file.path(modelos_dir, paste0("modelo_", nome, ".rds")))), coef(modelos[[nome]]))), logical(1))),
  "Cinco gráficos gerados" = length(list.files(graficos, pattern = "[.]png$")) == 5,
  "Arquivos anteriores não foram alterados" = identical(unname(tools::md5sum(anteriores)), md5_antes)))

# Afirmações fixas da nota dependem destes resultados. Se mudarem, o script para,
# em vez de publicar um texto que não corresponde aos números.
t_quad_c <- linha_coef("C", q_d)
t_quad_b <- linha_coef("B", q_s)
peso_cauda_C <- 100 * sum(peso_quad_C[cauda])
peso_cauda_A <- 100 * sum(peso_linear_A[cauda])
peso_inversao_C <- 100 * sum(peso_quad_C[acima_inversao])
peso_cauda_P2 <- 100 * sum(peso_log_P2[dados_pos$distance > 10])
acima_50 <- dados$distance > 5
peso_50_A <- 100 * sum(peso_linear_A[acima_50])
fator_quadrado <- abs(t_quad_c$t_hc3) / qt(.975, df.residual(modelo_C))
total_checagens <- total_checagens + checar(list(
  "Texto: score² sem evidência a 5% em B e D" = t_quad_b$p_hc3 > .05 && testes_termos$valor_p[4] > .05,
  "Texto: distance² positivo e com IC acima de zero em C" = t_quad_c$coeficiente > 0 && t_quad_c$ic95_inf_hc3 > 0,
  "Texto: inversão de distance no suporte, com poucos acima" = inversoes$no_suporte[1] && inversoes$percentual_acima[1] < 3,
  "Texto: cauda pesa muito em A e C, pouco em P2" = peso_cauda_A > 30 && peso_cauda_C > 30 && peso_cauda_P2 < peso_cauda_A / 2,
  "Texto: C e P2 próximos na mediana e acima de A em módulo" = abs(marg("C", "p50")$associacao - marg("P2", "p50")$associacao) < .01 &&
    abs(marg("P2", "p50")$associacao) > 2 * abs(linha_coef("A", "distance")$coeficiente),
  "Texto: IC de P2 na mediana inclui o coeficiente de A" = marg("P2", "p50")$ic95_inf_hc3 < linha_coef("A", "distance")$coeficiente &&
    marg("P2", "p50")$ic95_sup_hc3 > linha_coef("A", "distance")$coeficiente,
  "Texto: inversão de score fora do suporte" = !inversoes$no_suporte[3] && !inversoes$no_suporte[4],
  "Texto: RESET robusto rejeita a 5% em todos" = all(diagnosticos$reset_p < .05),
  "Texto: Breusch-Pagan rejeita a 5% em todos" = all(diagnosticos$bp_p < .05),
  "Texto: ganho de R² ajustado abaixo de 0,001 em cada grupo" = max(abs(ajuste$r2_ajustado_menos_primeiro_do_grupo)) < .001,
  "Texto: IC marginal de C exclui zero até p95 e inclui em p99" = all(vapply(c("Mínimo", "p25", "p50", "p75", "p90", "p95"), function(p)
    marg("C", p)$ic95_sup_hc3 < 0, logical(1))) && marg("C", "p99")$ic95_inf_hc3 < 0 && marg("C", "p99")$ic95_sup_hc3 > 0,
  "Texto: coeficiente de distance em nível muda pouco com a amostra" =
    abs(mudanca_amostra$diferenca_percentual[mudanca_amostra$termo == "distance"]) < 5,
  "Texto: coeficiente de log(distance) negativo em P2 e P4, com IC abaixo de zero" =
    linha_coef("P2", "log(distance)")$ic95_sup_hc3 < 0 && linha_coef("P4", "log(distance)")$ic95_sup_hc3 < 0,
  "Texto: E, em anos, próximo de A" = abs(marg("E", "p50")$equivalente_anos_por_10_milhas / linha_coef("A", "distance")$coeficiente - 1) < .05,
  "Texto: exp subestima a média observada; smearing fica próximo" =
    prev_de("E", 1)$media_prevista < prev_de("E", 1)$media_observada - .05 && abs(prev_de("E", 2)$media_prevista - prev_de("E", 2)$media_observada) < .01,
  "Texto: nenhuma previsão acima de 18" = all(previsoes$n_acima_de_18 == 0),
  "Texto: todos os modelos preveem abaixo de 12" = all(previsoes$n_abaixo_de_12 > 0)))

# 11. Nota de leitura e registro do ambiente --------------------------------------
peso_faixa <- function(f) suporte$peso_no_termo_quadratico_modelo_C[suporte$faixa_distancia == f]
linha_comp <- function(nome) {
  c_d <- if (nome %in% c("C", "D")) linha_coef(nome, "distance_c") else linha_coef(nome, "distance")
  d <- diag_de(nome)
  a <- ajuste[ajuste$modelo == nome, ]
  paste0("| ", nome, " | ", descricao[[nome]], " | ", fmt(c_d$coeficiente, 4), " | [", fmt(c_d$ic95_inf_hc3, 4), "; ", fmt(c_d$ic95_sup_hc3, 4), "] | ",
    fmt(a$r2_ajustado, 4), " | ", fmt(d$reset_robusto_f, 2), " (", fmt_p(d$reset_p), ") | ", fmt(d$bp_studentizado_lm, 1), " (", fmt_p(d$bp_p), ") |")
}
linha_marg <- function(ponto) {
  a <- marg("A", ponto); c_ <- marg("C", ponto); e <- marg("E", ponto)
  paste0("| ", ponto, " | ", fmt(a$milhas, 0), " | ", a$n_ate_5_milhas_do_ponto, " | ", fmt(a$associacao, 3),
    " [", fmt(a$ic95_inf_hc3, 3), "; ", fmt(a$ic95_sup_hc3, 3), "] | ", fmt(c_$associacao, 3), " [", fmt(c_$ic95_inf_hc3, 3), "; ", fmt(c_$ic95_sup_hc3, 3), "] | ",
    fmt(e$equivalente_anos_por_10_milhas, 3), " |")
}
linha_pos <- function(nome) {
  termo <- if (nome %in% c("P2", "P4")) "log(distance)" else "distance"
  x <- linha_coef(nome, termo)
  d <- diag_de(nome)
  a <- ajuste[ajuste$modelo == nome, ]
  paste0("| ", nome, " | ", descricao[[nome]], " | ", fmt(x$coeficiente, 4), " | [", fmt(x$ic95_inf_hc3, 4), "; ", fmt(x$ic95_sup_hc3, 4), "] | ", fmt(x$p_hc3, 3), " | ",
    fmt(a$r2, 4), " | ", fmt(a$r2_ajustado, 4), " | ", fmt(d$reset_robusto_f, 2), " (", fmt_p(d$reset_p), ") |")
}
linha_prev <- function(i) {
  x <- previsoes[i, ]
  paste0("| ", x$modelo, " | ", x$versao, " | ", x$n_abaixo_de_12, " | ", x$n_acima_de_18, " | ", fmt(x$previsto_minimo, 2), " | ", fmt(x$previsto_maximo, 2), " | ",
    fmt(x$media_prevista, 3), " | ", fmt(x$media_observada, 3), " | ", fmt(x$raiz_erro_quadratico_medio_anos, 3), " |")
}
perfil <- function(medida, coluna) perfil_zeros[perfil_zeros$medida == medida, coluna]
p2 <- linha_coef("P2", "log(distance)")
p3 <- linha_coef("P3", "distance")
p4 <- linha_coef("P4", "log(distance)")
e_d <- linha_coef("E", "distance")
a_d <- linha_coef("A", "distance")
m_dist <- mudanca_amostra[mudanca_amostra$termo == "distance", ]
marg_pos <- function(modelo, ponto) marg(modelo, ponto)$equivalente_anos_por_10_milhas
nota <- c("# Comparação exploratória de formas funcionais", "",
  "Esta nota é gerada por `04_formas_funcionais.R`. É uma comparação exploratória, motivada por diagnósticos já observados nos mesmos dados: os valores-p não têm o significado de hipóteses fixadas antes de olhar os resultados. Nenhuma transformação demonstra causalidade ou corrige automaticamente a dependência dos erros entre estudantes.", "",
  "## Síntese", "",
  "**Recomendação provisória: manter A (Modelo 3, linear) como especificação principal, sem apresentá-la sozinha: C (com distance²) e P2 (log de distance, sem os zeros) devem aparecer ao lado.** A evidência não distingue claramente as alternativas: a diferença de R² ajustado é inferior a 0,001 em cada comparação, e o RESET e o Breusch-Pagan continuam rejeitando em todas.",
  "",
  paste0("O que muda a leitura é a magnitude em distâncias típicas. O coeficiente de A (", fmt(a_d$coeficiente, 3), " ano por 10 milhas) é um resumo muito influenciado por distâncias longas: os ", sum(acima_50), " estudantes acima de 50 milhas (", fmt(100 * mean(acima_50), 1), "% da amostra) têm ", fmt(peso_50_A, 0), "% do peso nele. Na distância mediana (", fmt(marg("A", "p50")$milhas, 0), " milhas), C e P2 indicam inclinações mais fortes, de ", fmt(marg("C", "p50")$associacao, 3), " e ", fmt(marg("P2", "p50")$associacao, 3), ", mas com intervalos largos. O sinal negativo em distâncias típicas se mantém; a magnitude depende da forma."), "",
  "## O que motivou cada alternativa", "",
  "- **B (score²):** a etapa de diagnósticos encontrou valores ajustados abaixo de 12 anos nas notas baixas e resíduos positivos nessa faixa.",
  "- **C (distance²):** o RESET rejeitou no Modelo 1, em que ŷ é função só de `distance`, e os resíduos do Modelo 3 sobem na cauda de distância.",
  "- **D:** reúne B e C, para avaliar os dois termos em conjunto.",
  "- **E (log de education):** é forma exigida pelo enunciado. A motivação empírica já era fraca, porque a faixa de 12 a 18 anos é estreita.",
  "- **P1 a P4 (log de distance):** a concentração em distâncias curtas e a cauda longa sugerem que 10 milhas podem pesar mais perto da faculdade. Só podem ser comparados com distâncias positivas.", "",
  paste0("Centralização: B, C e D usam `distance_c = distance - ", fmt(media_distance, 5), "` e `score_c = score - ", fmt(media_score, 4), "` (médias da amostra completa; tabela 01). Os ajustes são iguais aos do polinômio sem centralizar. O coeficiente linear passa a ser a associação marginal na média da variável, e só ali."), "",
  "## Convenção de inferência", "",
  "Erros padrão HC3. Testes bilaterais com t de Student e gl = n - k; IC de 95% = coeficiente ± t(0,975; n - k) × EP. Testes conjuntos: Wald F(q, n - k) com a matriz HC3. Associações marginais: EP = √(g'Vg), com a matriz V completa. Pontos de inversão: método delta. É a mesma convenção das etapas anteriores.", "",
  "## O que mudou nos resultados e diagnósticos", "",
  "### Amostra completa (4.739 estudantes, incluindo as 94 distâncias zero)", "",
  "| Modelo | Especificação | Coef. linear de distance | IC 95% HC3 | R² ajust. | RESET robusto F (p) | BP LM (p) |", "|---|---|---:|---:|---:|---:|---:|",
  linha_comp("A"), linha_comp("B"), linha_comp("C"), linha_comp("D"), linha_comp("E"), "",
  "Em C e D, o coeficiente linear vale só na média de distância (cerca de 18 milhas); não é comparável diretamente ao de A. Em E, está em log-pontos. O R² ajustado de E não pode ser comparado com o dos demais, porque a dependente é outra; a tabela o mostra apenas para registro.", "",
  paste0("- **`score²`:** sem evidência de curvatura em B (b = ", fmt(t_quad_b$coeficiente, 5), ", p = ", fmt_p(t_quad_b$p_hc3), ") nem em D (p = ", fmt_p(testes_termos$valor_p[4]), "). A inversão calculada fica fora da faixa observada (", fmt(inversoes$ponto_inversao[3], 0),
    " pontos em B, contra mínimo de ", fmt(min(dados$score), 1), "), então a curva é monótona no suporte e a estimativa da inversão não tem leitura útil. Os casos previstos abaixo de 12 caem de ", prev_de("A")$n_abaixo_de_12, " para ", prev_de("B")$n_abaixo_de_12, ", sem desaparecer. A motivação indicada na etapa de diagnósticos como a mais direta não se confirmou."),
  paste0("- **`distance²`:** positivo em C (b = ", fmt(t_quad_c$coeficiente, 4), ", IC [", fmt(t_quad_c$ic95_inf_hc3, 4), "; ", fmt(t_quad_c$ic95_sup_hc3, 4), "], p = ", fmt_p(t_quad_c$p_hc3), "). O teste conjunto dos dois quadrados em D dá F = ", fmt(testes_termos$estatistica_f[5], 2), " (p = ", fmt_p(testes_termos$valor_p[5]), ")."),
  paste0("- **Diagnósticos:** o RESET robusto rejeita em todas as especificações, e nenhuma alternativa o reduz de forma decisiva (F de ", fmt(min(diagnosticos$reset_robusto_f[1:5]), 2), " a ", fmt(max(diagnosticos$reset_robusto_f[1:5]), 2), "; em C sobe de ", fmt(diag_de("A")$reset_robusto_f, 2), " para ", fmt(diag_de("C")$reset_robusto_f, 2), "). O Breusch-Pagan também rejeita em todas. As estatísticas não servem de nota entre especificações: os regressores auxiliares mudam, e nos modelos em log a escala também."),
  paste0("- **R²:** entre A e D, com mesma dependente e mesma amostra, o R² ajustado passa de ", fmt(ajuste$r2_ajustado[1], 4), " para ", fmt(ajuste$r2_ajustado[4], 4), ". A diferença é pequena demais para decidir."),
  paste0("- **Alavancagem:** o quadrado de distância eleva a alavancagem máxima de ", fmt(diag_de("A")$alavancagem_maxima, 3), " para ", fmt(diag_de("C")$alavancagem_maxima, 3), ", um sinal do peso da cauda."),
  "- **Resíduos:** C reduz o desvio positivo dos resíduos na cauda de distância, sem eliminá-lo. B e D reduzem pouco o desvio nas notas muito baixas, e E praticamente repete A contra distância.",
  "- [Curvas por distância](graficos/01_curvas_distancia.png), [curvas por score](graficos/03_curvas_score.png) e [resíduos](graficos/05_residuos_loess.png).", "",
  "### Previsões fora da faixa observada", "",
  "| Modelo | Versão | < 12 | > 18 | Mín. | Máx. | Média prevista | Média observada | REQM (anos) |", "|---|---|---:|---:|---:|---:|---:|---:|---:|",
  vapply(seq_len(6), linha_prev, character(1)), "",
  paste0("Exponenciar a previsão em log e estimar a média condicional em anos são operações diferentes. `exp(previsão)` aproxima a mediana se os erros forem simétricos e aqui subestima a média (", fmt(prev_de("E", 1)$media_prevista, 3), " contra ", fmt(prev_de("E", 1)$media_observada, 3),
    "). A média usa o fator de smearing de Duan (", fmt(prev_de("E", 1)$fator_smearing, 4), "), que supõe erro sem relação com os regressores; como o Breusch-Pagan rejeita, é só uma aproximação. O log impede previsões negativas, não previsões abaixo de 12. O REQM é descritivo, dentro da amostra."), "",
  "### Subamostra de distância positiva", "",
  paste0("Foram retiradas ", sum(!positiva), " observações, apenas desta análise complementar: os estudantes com distância zero, para os quais log(distance) não existe (identificadores na tabela 03). Isso não é limpeza de dados nem solução neutra. Esses estudantes diferem dos demais: em média têm ", fmt(perfil("education (anos)", "distancia_zero"), 2), " anos de escolaridade (contra ", fmt(perfil("education (anos)", "distancia_positiva"), 2),
    "), ", fmt(100 * perfil("Proporção fcollege = yes", "distancia_zero"), 0), "% com pai graduado (contra ", fmt(100 * perfil("Proporção fcollege = yes", "distancia_positiva"), 0), "%) e ", fmt(100 * perfil("Proporção ethnicity = afam", "distancia_zero"), 0), "% na categoria afam (contra ", fmt(100 * perfil("Proporção ethnicity = afam", "distancia_positiva"), 0), "%) (tabela 04). As conclusões de P1 a P4 valem só para estudantes com distância registrada acima de zero."), "",
  paste0("**Mudança de amostra:** com a mesma especificação, o coeficiente de `distance` passa de ", fmt(m_dist$coef_A_completa, 4), " (completa) para ", fmt(m_dist$coef_A_positiva, 4), " (positiva), variação de ", fmt(abs(m_dist$diferenca_percentual), 1), "% (tabela 11). A retirada dos zeros, portanto, muda pouco esse coeficiente, e as diferenças entre P1 e P2 refletem a forma funcional."), "",
  "| Modelo | Especificação | Coef. da distância | IC 95% HC3 | p | R² | R² ajust. | RESET robusto F (p) |", "|---|---|---:|---:|---:|---:|---:|---:|",
  linha_pos("P1"), linha_pos("P2"), linha_pos("P3"), linha_pos("P4"), "",
  paste0("R² só pode ser comparado entre P1 e P2 (education) e entre P3 e P4 (log(education)). O log de distância ajusta um pouco melhor em cada par (R² ajustado de ", fmt(ajuste$r2_ajustado[ajuste$modelo == "P1"], 4), " para ", fmt(ajuste$r2_ajustado[ajuste$modelo == "P2"], 4), " e de ", fmt(ajuste$r2_ajustado[ajuste$modelo == "P3"], 4), " para ", fmt(ajuste$r2_ajustado[ajuste$modelo == "P4"], 4), "), diferença pequena demais para decidir. [Curvas](graficos/04_curvas_subamostra_positiva.png)."), "",
  "## Como interpretar a associação de distância", "",
  "### Quadráticos: não há associação constante", "",
  "A associação marginal é b_linear + 2 × b_quadrado × (distance - média). Abaixo, em anos por 10 milhas, com IC de 95% HC3 obtido com a matriz completa. Em E, o valor é o equivalente aproximado em anos.", "",
  "| Ponto | Milhas | n até 5 milhas | A | C | E (aprox.) |", "|---|---:|---:|---:|---:|---:|",
  vapply(pontos_completa$ponto, linha_marg, character(1)), "",
  paste0("- **Faixa bem sustentada:** do mínimo a p95 (", fmt(marg("C", "p95")$milhas, 0), " milhas), o IC de C exclui zero, e a associação enfraquece de ", fmt(marg("C", "Mínimo")$associacao, 3), " para ", fmt(marg("C", "p95")$associacao, 3), " ano por 10 milhas."),
  paste0("- **Inversão:** a curva de C tem mínimo em ", fmt(10 * inversoes$ponto_inversao[1], 0), " milhas (IC delta de ", fmt(10 * inversoes$ic95_inf[1], 0), " a ", fmt(10 * inversoes$ic95_sup[1], 0), "). O ponto está no suporte, mas só ", inversoes$n_acima[1], " estudantes (", fmt(inversoes$percentual_acima[1], 1), "%) estão acima dele e ", inversoes$n_na_janela[1], " estão a até 10 milhas dele."),
  paste0("- **Cauda:** C dá sinal positivo no máximo (200 milhas), onde só ", marg("C", "Máximo")$n_ate_5_milhas_do_ponto, " estudantes estão a até 5 milhas desse valor. Isso não basta para afirmar que maior distância se associe a mais escolaridade: o trecho crescente pode ser consequência de impor uma parábola à cauda."),
  paste0("- **Peso da cauda:** os ", sum(cauda), " estudantes acima de 100 milhas têm ", fmt(peso_cauda_C, 0), "% do peso na identificação do termo quadrático de C, ", fmt(peso_cauda_A, 0), "% no coeficiente de A e ", fmt(peso_cauda_P2, 0), "% no de log(distance) em P2 (tabela 10). O peso é calculado com o regressor residualizado (Frisch-Waugh), sem excluir nem reestimar. Portanto, a dependência da cauda não é um problema só de C: a inclinação de A também vem em grande parte dela. P2 é a forma menos dependente da cauda."),
  paste0("- **Convergência só perto da mediana:** C e P2 têm dependências muito diferentes da cauda e ainda assim dão inclinações parecidas em ", fmt(marg("C", "p50")$milhas, 0), " milhas. Em ", fmt(marg("C", "p75")$milhas, 0), " milhas já se separam (", fmt(marg("C", "p75")$associacao, 3), " em C, ", fmt(marg("P2", "p75")$associacao, 3), " em P2), e P2 fica próxima de zero nas distâncias longas. Isso sugere que A subestima a magnitude perto da mediana, mas não o demonstra: o IC de P2 nesse ponto inclui o coeficiente de A, e ambas as formas impõem concavidade."),
  "- [Gráfico da associação marginal](graficos/02_associacao_marginal_distancia.png).", "",
  "### Logaritmos: cada transformação tem sua leitura", "",
  paste0("- **E e P3 (log-nível):** 10 milhas a mais se associam a uma escolaridade ", fmt(abs(100 * (exp(e_d$coeficiente) - 1)), 2), "% menor em E e ", fmt(abs(100 * (exp(p3$coeficiente) - 1)), 2), "% menor em P3, usando 100 × (exp(b) - 1). Em E, isso equivale a cerca de ", fmt(marg("E", "p50")$equivalente_anos_por_10_milhas, 3), " ano, quase o mesmo que A."),
  paste0("- **P2 (nível-log):** 1% a mais de distância se associa a ", fmt(p2$coeficiente / 100, 5), " ano. Dobrar a distância se associa a b × ln 2 = ", fmt(p2$coeficiente * log(2), 3), " ano, em qualquer ponto. Por 10 milhas, a inclinação é b/distance: ", fmt(marg_pos("P2", "p25"), 3), " em ", fmt(marg("P2", "p25")$milhas, 0), " milhas, ", fmt(marg_pos("P2", "p50"), 3), " em ", fmt(marg("P2", "p50")$milhas, 0), " e ", fmt(marg_pos("P2", "p90"), 3), " em ", fmt(marg("P2", "p90")$milhas, 0), ". Isso é a inclinação local expressa por 10 milhas, não o resultado de um salto real de 10 milhas, sobretudo em distâncias muito curtas. A forma impõe associação sempre negativa e decrescente em módulo, sem inversão."),
  paste0("- **P4 (log-log):** o coeficiente é uma elasticidade: 1% a mais de distância se associa a uma escolaridade ", fmt(abs(p4$coeficiente), 4), "% menor; dobrar a distância, a cerca de ", fmt(abs(100 * (2^p4$coeficiente - 1)), 2), "% menor."),
  "- A unidade de `distance` não altera o coeficiente de log(distance), só o intercepto. Nenhuma dessas formas diz algo sobre quem está a distância zero.", "",
  "## Recomendação provisória", "",
  "**Principal: A, lida como resumo linear e não como inclinação típica. Ao lado: C, lida só até p95 (60 milhas), e P2, deixando claro que exclui as distâncias zero.** E, B e D não acrescentam o suficiente para ficar na apresentação principal.", "",
  paste0("- **Interpretação econômica:** rendimentos decrescentes da distância são plausíveis, e C e P2 os expressam. C também produz um trecho crescente na cauda, sem sustentação; P2 não comporta os zeros. A é a mais simples, mas seu número único esconde essa possível diferença entre distâncias curtas e longas."),
  "- **Parcimônia:** A e P2 têm o mesmo número de parâmetros, e C tem um a mais. `score²` não se justifica, e E, em anos, é quase igual a A, com leitura menos direta.",
  paste0("- **Suporte dos dados:** A usa todos os estudantes, mas ", fmt(peso_50_A, 0), "% do peso de sua inclinação vem de ", fmt(100 * mean(acima_50), 1), "% da amostra. C usa todos, com ", fmt(peso_cauda_C, 0), "% do peso do termo quadrático em ", fmt(100 * mean(cauda), 1), "%. P2 depende menos da cauda, mas perde as ", sum(!positiva), " distâncias zero, que diferem das demais."),
  "- **Diagnósticos:** nenhuma alternativa elimina as rejeições, então eles não apontam vencedor.",
  paste0("- **Por que não trocar A por C ou P2 agora:** A foi definida antes desta exploração. O termo quadrático tem p = ", fmt_p(t_quad_c$p_hc3), ", mas veio de uma busca motivada pelos mesmos dados e deixaria de ser significativo a 5% com um erro padrão ", fmt(100 * (fator_quadrado - 1), 0), "% maior, algo possível sob correlação dentro de escolas. O ganho de ajuste é mínimo. Mudar a especificação principal com base nisso seria escolher por valor-p."),
  paste0("- **Risco desta escolha:** A pode subestimar a magnitude em distâncias típicas. Por isso, o relatório deve dar uma faixa na mediana, de ", fmt(a_d$coeficiente, 3), " (A) a ", fmt(marg("C", "p50")$associacao, 3), " (C), com ", fmt(marg("P2", "p50")$associacao, 3), " em P2, e não um único número. Se o grupo priorizar a distância típica acima da simplicidade, C lida até p95 é uma alternativa defensável."),
  "- A associação é negativa e pequena em distâncias curtas e típicas em todas as formas. A evidência não distingue a magnitude com clareza, e o relatório deve dizer isso.", "",
  "## Limitações que permanecem", "",
  "- **Exploração:** as alternativas foram escolhidas depois de ver diagnósticos nos mesmos dados, e vários testes foram feitos sem ajuste. Não há amostra separada para confirmação.",
  "- **Causalidade:** nenhuma forma funcional resolve endogeneidade. Escolha do local de moradia, motivação e qualidade da escola seguem como possíveis fontes de viés.",
  "- **Dependência dos erros:** HC3 não corrige correlação dentro de escolas ou localidades, e a base não identifica a escola. Os ICs podem estar estreitos demais em todas as especificações, inclusive nos testes dos quadrados.",
  "- **Natureza de `education`:** nenhuma das formas respeita o piso de 12 anos nem trata a variável como discreta. Isso pode explicar parte das rejeições persistentes do RESET, mas esta etapa não demonstra essa causa. Modelos para variável discreta e limitada estão fora do escopo do enunciado.",
  "- **Distâncias zero:** não há tratamento neutro. Somar 1 ou trocar o zero por outro valor mudaria a leitura e não foi feito; retirá-los muda a população comparada.",
  "- **Curvas:** fixam os demais regressores nas médias, ou em cada estudante nos modelos em log, e descrevem o ajuste, não o que aconteceria se um estudante fosse deslocado. A retransformação por smearing é aproximada.", "",
  "Fonte: tabelas, gráficos e modelos em `resultados/formas_funcionais/`; documentação de AER::CollegeDistance.")
writeLines(nota, file.path(saida, "LEITURA_DAS_FORMAS_FUNCIONAIS.md"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(saida, "sessionInfo_formas_funcionais.txt"))

print(testes_termos, row.names = FALSE)
print(inversoes[, c("modelo", "variavel", "ponto_inversao", "ic95_inf", "ic95_sup", "no_suporte", "n_acima", "n_na_janela")], row.names = FALSE)
print(suporte, row.names = FALSE)
print(diagnosticos[, c("modelo", "reset_robusto_f", "reset_p", "bp_studentizado_lm", "bp_p", "alavancagem_maxima")], row.names = FALSE)
message("Etapa 4 concluída. ", total_checagens, " verificações aprovadas. Resultados em: ", saida)
