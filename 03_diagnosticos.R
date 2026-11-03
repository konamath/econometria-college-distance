# COLLEGEDISTANCE | Etapa 3: diagnósticos econométricos dos modelos por MQO
# Foco no Modelo 3, com comparação com os Modelos 1 e 2 quando pertinente.
# Esta etapa não altera especificações, não exclui observações, não reestima
# os modelos sem observações e não implementa formas funcionais alternativas.
# Execução no terminal: Rscript --vanilla 03_diagnosticos.R
# Execução no console R ou RStudio: source("03_diagnosticos.R", encoding = "UTF-8")

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
if (!file.exists(file.path(pasta, "03_diagnosticos.R"))) {
  stop("Abra a pasta CollegeDistance_v1 e execute o script completo.")
}
for (p in c("ggplot2", "car", "lmtest", "sandwich")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Falta o pacote ", p, ". Execute 00_preparar_ambiente.R primeiro.")
  }
}
library(ggplot2)
if (getOption("contrasts")[["unordered"]] != "contr.treatment") {
  stop("Use contrastes de tratamento: options(contrasts = c('contr.treatment', 'contr.poly')).")
}

# Tudo o que este script escreve fica em resultados/diagnosticos/.
saida <- file.path(pasta, "resultados/diagnosticos")
tabelas <- file.path(saida, "tabelas")
graficos <- file.path(saida, "graficos")
dir.create(tabelas, recursive = TRUE, showWarnings = FALSE)
dir.create(graficos, recursive = TRUE, showWarnings = FALSE)
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
iguais <- function(a, b) isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = 1e-10))

# 2. Carregar modelos e base e conferir a correspondência ------------------------
arquivo_base <- file.path(pasta, "dados/CollegeDistance_original.rds")
arquivos_modelos <- file.path(pasta, "resultados/modelos", paste0("modelo_", 1:3, ".rds"))
arquivo_coef <- file.path(pasta, "resultados/tabelas/11_regressao_coeficientes.csv")
for (a in c(arquivo_base, arquivos_modelos, arquivo_coef)) {
  if (!file.exists(a)) stop("Arquivo não encontrado: ", a, ". Execute 02_regressoes.R primeiro.")
}
md5_antes <- unname(tools::md5sum(c(arquivo_base, arquivos_modelos, arquivo_coef)))
base <- readRDS(arquivo_base)
modelos <- setNames(lapply(arquivos_modelos, readRDS), paste("Modelo", 1:3))
coef_etapa2 <- read.csv(arquivo_coef, encoding = "UTF-8", stringsAsFactors = FALSE)
m3 <- modelos[["Modelo 3"]]
vars_modelos <- list("Modelo 1" = "distance",
  "Modelo 2" = c("distance", "income", "fcollege", "mcollege"),
  "Modelo 3" = c("distance", "income", "fcollege", "mcollege", "score", "gender",
                 "ethnicity", "urban", "region"))
n <- nrow(base)

# Os nomes das linhas são os identificadores originais do AER. Não são sequenciais
# (há valores como 5441 e 11110), portanto não equivalem à posição na base.
correspondencia <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  mf <- model.frame(m)
  refeito <- lm(formula(m), data = base, na.action = na.fail)
  data.frame(modelo = nome, n_observacoes = nobs(m), n_parametros = length(coef(m)),
    especificacao_igual_a_definida = setequal(attr(terms(m), "term.labels"), vars_modelos[[nome]]),
    ids_iguais_aos_da_base = identical(rownames(mf), rownames(base)),
    valores_iguais_aos_da_base = all(vapply(names(mf), function(v)
      identical(as.vector(mf[[v]]), as.vector(base[[v]])), logical(1))),
    coeficientes_reproduzidos_com_a_base = isTRUE(all.equal(coef(refeito), coef(m))),
    coeficientes_iguais_a_tabela_11 = iguais(coef(m), coef_etapa2$coeficiente[coef_etapa2$modelo == nome]),
    sem_coeficiente_nao_identificado = !anyNA(coef(m)))
}))
exportar(correspondencia, "01_correspondencia_modelos_dados")
total_checagens <- checar(c(
  list("Identificadores originais são únicos" = !anyDuplicated(rownames(base))),
  setNames(lapply(split(correspondencia[-(1:3)], correspondencia$modelo), function(x) all(unlist(x))),
           paste("Correspondência com a base:", correspondencia$modelo))))

# 3. Resíduos e forma funcional --------------------------------------------------
# RESET de Ramsey: education ~ regressores do modelo + ŷ² + ŷ³; H0: os dois
# coeficientes adicionais são nulos. Versão clássica: F de lmtest::resettest.
# Versão robusta: Wald com matriz HC3 na mesma regressão auxiliar, F(2, n - k - 2).
# Na versão robusta, ŷ é padronizado só para estabilidade numérica; como ŷ pertence
# ao espaço dos regressores, isso não muda o teste. A regressão auxiliar é usada
# apenas no teste, não é modelo alternativo e não é salva.
reset_robusto <- function(m) {
  y <- model.response(model.frame(m))
  z <- as.numeric(scale(fitted(m)))
  A <- cbind(model.matrix(m), z2 = z^2, z3 = z^3)
  auxiliar <- lm(y ~ A - 1)
  novos <- c("Az2", "Az3")
  V <- sandwich::vcovHC(auxiliar, type = "HC3")[novos, novos]
  b <- coef(auxiliar)[novos]
  f <- drop(t(b) %*% solve(V) %*% b) / 2
  list(f = f, gl2 = df.residual(auxiliar), p = pf(f, 2, df.residual(auxiliar), lower.tail = FALSE))
}
reset <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  classico <- lmtest::resettest(m, power = 2:3, type = "fitted")
  robusto <- reset_robusto(m)
  data.frame(modelo = nome, regressores_adicionados = "ŷ², ŷ³",
    versao = c("Clássica (F, lmtest::resettest)", "Robusta (Wald F com HC3)"),
    estatistica_f = c(unname(classico$statistic), robusto$f), gl1 = 2,
    gl2 = c(unname(classico$parameter[2]), robusto$gl2),
    valor_p = c(unname(classico$p.value), robusto$p))
}))
exportar(reset, "02_reset")

# Médias de resíduos por faixa: descrição do padrão visto nos gráficos, não teste.
# O IC aproximado supõe observações independentes e serve só como escala de ruído.
resumir_faixas <- function(m, nome, eixo, x, cortes) {
  faixa <- cut(x, cortes, include.lowest = TRUE, dig.lab = 4)
  e <- resid(m)
  do.call(rbind, lapply(levels(faixa), function(f) {
    r <- e[faixa == f]
    meia <- qt(.975, length(r) - 1) * sd(r) / sqrt(length(r))
    data.frame(modelo = nome, eixo = eixo, faixa = f, n = length(r), media_residuo = mean(r),
      ic95_aprox_inf = mean(r) - meia, ic95_aprox_sup = mean(r) + meia, media_residuo_quadrado = mean(r^2))
  }))
}
decis <- function(x) unique(quantile(x, 0:10 / 10))
faixas <- rbind(
  do.call(rbind, lapply(names(modelos), function(nome) {
    resumir_faixas(modelos[[nome]], nome, "Decis de valores ajustados", fitted(modelos[[nome]]),
                   decis(fitted(modelos[[nome]])))
  })),
  resumir_faixas(m3, "Modelo 3", "Distância (dezenas de milhas)", base$distance, c(0, .0001, .5, 1, 2, 3, 5, 10, 20)),
  resumir_faixas(m3, "Modelo 3", "Decis de score", base$score, decis(base$score)))
exportar(faixas, "03_residuos_por_faixa")

# 4. Heterocedasticidade ---------------------------------------------------------
# Breusch-Pagan studentizado (Koenker, 1981): LM = n x R² da regressão de e² nos
# regressores do próprio modelo; qui-quadrado com gl = k - 1.
bp <- do.call(rbind, lapply(names(modelos), function(nome) {
  teste <- lmtest::bptest(modelos[[nome]], studentize = TRUE)
  data.frame(modelo = nome, versao = "Studentizada (Koenker), lmtest::bptest(studentize = TRUE)",
    regressores_da_variancia = "Regressores do próprio modelo",
    estatistica_lm = unname(teste$statistic), gl = unname(teste$parameter), valor_p = unname(teste$p.value))
}))
exportar(bp, "04_breusch_pagan")

# A comparação parte da tabela da etapa 2 e confere que a HC3 continua reproduzível.
erros_padrao <- data.frame(
  coef_etapa2[c("modelo", "termo", "ep_convencional", "ep_hc3")],
  razao_hc3_sobre_convencional = coef_etapa2$ep_hc3 / coef_etapa2$ep_convencional,
  t_convencional = coef_etapa2$t_convencional, t_hc3 = coef_etapa2$t_hc3,
  p_convencional = coef_etapa2$p_convencional, p_hc3 = coef_etapa2$p_hc3)
exportar(erros_padrao, "05_erros_padrao_convencional_hc3")

# 5. Multicolinearidade ----------------------------------------------------------
# Escalas: para termo com 1 gl, GVIF = VIF e GVIF^(1/(2 gl)) = raiz do VIF, fator
# de inflação do erro padrão. Para fator com vários gl, o GVIF cresce com gl e não
# é comparável ao VIF; a versão ajustada é. Seu quadrado volta à escala do VIF.
tabela_vif <- function(m, nome) {
  if (length(attr(terms(m), "term.labels")) < 2) {
    return(data.frame(modelo = nome, termo = attr(terms(m), "term.labels"), gl = 1, gvif = 1,
      gvif_ajustado = 1, nota = "Um único regressor: VIF = 1 por definição"))
  }
  v <- car::vif(m)
  if (!is.matrix(v)) v <- cbind(GVIF = v, Df = 1, sqrt(v))
  data.frame(modelo = nome, termo = rownames(v), gl = v[, 2], gvif = v[, 1], gvif_ajustado = v[, 3],
    nota = ifelse(v[, 2] > 1, "GVIF conjunto do fator; comparar pela versão ajustada", "1 gl: GVIF = VIF"),
    row.names = NULL)
}
vif <- do.call(rbind, lapply(names(modelos), function(nome) tabela_vif(modelos[[nome]], nome)))
vif$gvif_ajustado_ao_quadrado <- vif$gvif_ajustado^2
exportar(vif[c("modelo", "termo", "gl", "gvif", "gvif_ajustado", "gvif_ajustado_ao_quadrado", "nota")],
         "06_vif_gvif")

# 6. Observações influentes ------------------------------------------------------
# Limiares de triagem, não regras de exclusão:
# alavancagem > 2k/n; |resíduo studentizado externo| > 3; distância de Cook > 4/n.
influencia <- function(m) {
  k <- length(coef(m))
  data.frame(alavancagem = hatvalues(m), residuo_studentizado = rstudent(m), cook = cooks.distance(m),
    limiar_alavancagem = 2 * k / n, limiar_residuo = 3, limiar_cook = 4 / n)
}
medidas <- lapply(modelos, influencia)
influencia_resumo <- do.call(rbind, lapply(names(modelos), function(nome) {
  d <- medidas[[nome]]
  k <- length(coef(modelos[[nome]]))
  data.frame(modelo = nome, n = n, k = k, limiar_alavancagem_2k_n = 2 * k / n, limiar_cook_4_n = 4 / n,
    n_alavancagem_acima_2k_n = sum(d$alavancagem > 2 * k / n),
    n_alavancagem_acima_3k_n = sum(d$alavancagem > 3 * k / n),
    n_residuo_abs_acima_3 = sum(abs(d$residuo_studentizado) > 3),
    n_cook_acima_4_n = sum(d$cook > 4 / n), n_cook_acima_1 = sum(d$cook > 1),
    n_sinalizadas_algum_criterio = sum(d$alavancagem > 2 * k / n | abs(d$residuo_studentizado) > 3 | d$cook > 4 / n),
    alavancagem_maxima = max(d$alavancagem), residuo_abs_maximo = max(abs(d$residuo_studentizado)),
    cook_maximo = max(d$cook),
    p_bonferroni_maior_residuo = min(1, n * 2 * pt(-max(abs(d$residuo_studentizado)), n - k - 1)))
}))
exportar(influencia_resumo, "07_influencia_resumo")

d3 <- medidas[["Modelo 3"]]
alta_alav <- d3$alavancagem > d3$limiar_alavancagem
alto_res <- abs(d3$residuo_studentizado) > d3$limiar_residuo
alto_cook <- d3$cook > d3$limiar_cook
sinalizadas <- which(alta_alav | alto_res | alto_cook)
criterios_texto <- apply(cbind(ifelse(alta_alav, "alavancagem > 2k/n", NA),
  ifelse(alto_res, "|resíduo studentizado| > 3", NA), ifelse(alto_cook, "Cook > 4/n", NA)),
  1, function(x) paste(x[!is.na(x)], collapse = "; "))
influentes <- data.frame(modelo = "Modelo 3", id_original = rownames(base), linha_na_base = seq_len(n),
  criterios = criterios_texto, d3, sinal_alavancagem = alta_alav, sinal_residuo = alto_res, sinal_cook = alto_cook,
  valor_ajustado = fitted(m3), residuo = resid(m3),
  base[c("education", vars_modelos[["Modelo 3"]])], row.names = NULL)[sinalizadas, ]
influentes <- influentes[order(-influentes$cook), ]
exportar(influentes, "08_influentes_modelo_3")

# 7. Distribuição dos resíduos e limites dos valores ajustados --------------------
distribuicao <- do.call(rbind, lapply(names(modelos), function(nome) {
  m <- modelos[[nome]]
  s <- rstandard(m)
  q <- quantile(s, c(.01, .05, .5, .95, .99))
  data.frame(modelo = nome, n = n, assimetria = mean((s - mean(s))^3) / sd(s)^3,
    curtose_excedente = mean((s - mean(s))^4) / sd(s)^4 - 3,
    p01 = q[[1]], p05 = q[[2]], p50 = q[[3]], p95 = q[[4]], p99 = q[[5]],
    ajustado_minimo = min(fitted(m)), ajustado_maximo = max(fitted(m)),
    n_ajustado_abaixo_de_12 = sum(fitted(m) < 12), n_ajustado_acima_de_18 = sum(fitted(m) > 18))
}))
exportar(distribuicao, "09_distribuicao_residuos")

# 8. Gráficos --------------------------------------------------------------------
azul <- "#245B78"
laranja <- "#BA642E"
cinza <- "#24333B"
tema <- theme_minimal(base_size = 13, base_family = "sans") +
  theme(plot.title = element_text(face = "bold", size = 19, color = cinza),
    plot.subtitle = element_text(size = 11, color = "#52616B", margin = margin(b = 16)),
    plot.caption = element_text(size = 9, hjust = 0, margin = margin(t = 14)),
    panel.grid.minor = element_blank(), axis.title = element_text(size = 12),
    plot.margin = margin(18, 24, 18, 18), legend.position = "none")
rodape <- "Fonte: AER::CollegeDistance | Modelos de 02_regressoes.R, sem exclusões."
nota_loess <- "Curva: LOESS com faixa de 95%, apenas descritiva."
salvar <- function(p, nome, largura = 10, altura = 6) {
  ggsave(file.path(graficos, paste0(nome, ".png")), p, width = largura, height = altura,
         units = "in", dpi = 180, bg = "white")
}
residuos_contra <- function(d, rotulo_x, titulo, subtitulo, nota_extra, digitos_x = 0) {
  ggplot(d, aes(x, residuo)) +
    geom_hline(yintercept = 0, color = cinza, linewidth = .4) +
    geom_point(color = azul, alpha = .16, size = 1.1) +
    geom_smooth(method = "loess", formula = y ~ x, span = .75, se = TRUE,
                color = laranja, fill = laranja, alpha = .25, linewidth = .9) +
    scale_x_continuous(labels = function(x) fmt(x, digitos_x)) +
    scale_y_continuous(labels = function(x) fmt(x, 1)) +
    labs(title = titulo, subtitle = subtitulo, x = rotulo_x, y = "Resíduo (anos)",
         caption = paste0(rodape, "\n", nota_loess, " ", nota_extra)) + tema
}
dados_ajustados <- do.call(rbind, lapply(names(modelos), function(nome) {
  data.frame(modelo = nome, x = fitted(modelos[[nome]]), residuo = resid(modelos[[nome]]))
}))
p1 <- residuos_contra(dados_ajustados, "Valor ajustado (anos)", "Resíduos contra valores ajustados",
    paste0(fmt(n, 0), " estudantes em cada modelo | Eixos horizontais em escalas próprias"),
    "Faixas diagonais decorrem de education ser discreta.", digitos_x = 1) +
  facet_wrap(~modelo, scales = "free_x") +
  theme(strip.text = element_text(face = "bold", size = 12, color = cinza), panel.spacing = unit(1.2, "lines"))
salvar(p1, "01_residuos_ajustados_modelos", largura = 12, altura = 6)

dados_m3 <- data.frame(residuo = resid(m3), distance = base$distance, score = base$score)
p2 <- residuos_contra(transform(dados_m3, x = distance), "Distância (dezenas de milhas; 1 unidade = 10 milhas)",
  "Modelo 3: resíduos contra distância", paste0("Poucas observações na cauda: ",
    sum(base$distance > 10), " estudantes acima de 100 milhas"),
  "Colunas verticais refletem valores repetidos de distância.")
salvar(p2, "02_residuos_distancia_modelo_3")
p3 <- residuos_contra(transform(dados_m3, x = score), "Nota no teste do último ano do ensino médio (pontos)",
  "Modelo 3: resíduos contra desempenho inicial", "Desempenho inicial medido por score",
  "A faixa densa inferior reúne estudantes com 12 anos, o piso da escala.")
salvar(p3, "03_residuos_score_modelo_3")

padronizados <- sort(rstandard(m3))
p4 <- ggplot(data.frame(teorico = qnorm(ppoints(n)), observado = padronizados), aes(teorico, observado)) +
  geom_abline(slope = 1, intercept = 0, color = laranja, linewidth = .8) +
  geom_point(color = azul, alpha = .35, size = 1) +
  scale_x_continuous(labels = function(x) fmt(x, 0)) + scale_y_continuous(labels = function(x) fmt(x, 0)) +
  labs(title = "Modelo 3: gráfico Q-Q dos resíduos", subtitle = "Resíduos padronizados contra quantis da normal",
    x = "Quantil teórico da normal padrão", y = "Quantil do resíduo padronizado",
    caption = paste0(rodape, "\nLinha: referência y = x. Afastar-se dela não implica viés do MQO.")) + tema
salvar(p4, "04_qq_modelo_3")

dados_inf <- transform(d3, grupo = ifelse(cook > limiar_cook, "Cook > 4/n", "Cook ≤ 4/n"))
p5 <- ggplot(dados_inf[order(dados_inf$cook), ], aes(alavancagem, residuo_studentizado, color = grupo)) +
  geom_vline(xintercept = d3$limiar_alavancagem[1], linetype = "dashed", color = cinza, linewidth = .4) +
  geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = cinza, linewidth = .4) +
  geom_point(alpha = .55, size = 1.3) +
  scale_color_manual(values = c("Cook ≤ 4/n" = azul, "Cook > 4/n" = laranja), name = NULL) +
  scale_x_continuous(labels = function(x) fmt(x, 3)) + scale_y_continuous(labels = function(x) fmt(x, 0)) +
  annotate("text", x = d3$limiar_alavancagem[1], y = -3.75, hjust = -.05, size = 3.4, color = cinza, label = "2k/n") +
  annotate("text", x = max(d3$alavancagem), y = 3.2, hjust = 1, size = 3.4, color = cinza, label = "resíduo = 3") +
  labs(title = "Modelo 3: alavancagem, resíduos e distância de Cook",
    subtitle = paste0(nrow(influentes), " observações sinalizadas para triagem | Nenhuma foi excluída"),
    x = "Alavancagem", y = "Resíduo studentizado externo",
    caption = paste0(rodape, "\nLimiares são instrumentos de triagem, não regras de exclusão.")) +
  tema + theme(legend.position = "top", legend.justification = "left")
salvar(p5, "05_influencia_modelo_3")

# 9. Conferir tabelas exportadas contra os objetos calculados --------------------
reset_csv <- ler_saida("02_reset")
bp_csv <- ler_saida("04_breusch_pagan")
vif_csv <- ler_saida("06_vif_gvif")
resumo_csv <- ler_saida("07_influencia_resumo")
influentes_csv <- ler_saida("08_influentes_modelo_3")
X3 <- model.matrix(m3)
sem_inter <- X3[, -1]
R <- cor(sem_inter)
eth <- grep("^ethnicity", colnames(sem_inter))
gvif_eth <- det(R[eth, eth]) * det(R[-eth, -eth]) / det(R)
aux_dist <- summary(lm(sem_inter[, "distance"] ~ sem_inter[, colnames(sem_inter) != "distance"]))$r.squared
aux_bp <- lm(resid(m3)^2 ~ sem_inter)
vif_m3 <- function(termo) vif$gvif[vif$modelo == "Modelo 3" & vif$termo == termo]
total_checagens <- total_checagens + checar(list(
  "RESET exportado igual ao lmtest" = all(vapply(names(modelos), function(nome) {
    t <- lmtest::resettest(modelos[[nome]], power = 2:3, type = "fitted")
    iguais(reset_csv$estatistica_f[reset_csv$modelo == nome][1], t$statistic) &&
      iguais(reset_csv$valor_p[reset_csv$modelo == nome][1], t$p.value)
  }, logical(1))),
  "Breusch-Pagan exportado igual ao lmtest" = iguais(bp_csv$estatistica_lm,
    vapply(modelos, function(m) unname(lmtest::bptest(m, studentize = TRUE)$statistic), numeric(1))),
  "Breusch-Pagan do Modelo 3 igual a n x R² da auxiliar" = iguais(bp$estatistica_lm[3], n * summary(aux_bp)$r.squared),
  "HC3 da etapa 2 reproduzida" = iguais(coef_etapa2$ep_hc3,
    unlist(lapply(modelos, function(m) sqrt(diag(sandwich::vcovHC(m, type = "HC3")))))),
  "VIF de distance igual a 1/(1 - R²)" = iguais(vif_m3("distance"), 1 / (1 - aux_dist)),
  "GVIF de ethnicity igual à fórmula de determinantes" = iguais(vif_m3("ethnicity"), gvif_eth),
  "VIF exportado igual ao car::vif" = iguais(vif_csv$gvif[vif_csv$modelo == "Modelo 3"], car::vif(m3)[, 1]),
  "Tabela de influentes contém todas as sinalizadas" = nrow(influentes_csv) == length(sinalizadas) &&
    setequal(influentes_csv$id_original, rownames(base)[sinalizadas]) &&
    resumo_csv$n_sinalizadas_algum_criterio[3] == length(sinalizadas),
  "Identificadores dos influentes apontam para os dados corretos" =
    all(base[as.character(influentes_csv$id_original), "education"] == influentes_csv$education) &&
    iguais(cooks.distance(m3)[as.character(influentes_csv$id_original)], influentes_csv$cook),
  "Cinco gráficos gerados" = length(list.files(graficos, pattern = "[.]png$")) == 5,
  "Base, modelos e tabela da etapa 2 não foram alterados" =
    identical(unname(tools::md5sum(c(arquivo_base, arquivos_modelos, arquivo_coef))), md5_antes)))

# Afirmações fixas da nota dependem destes resultados. Se mudarem, o script para,
# em vez de publicar um texto que não corresponde aos números.
p_reset <- function(nome, i) reset$valor_p[reset$modelo == nome][i]
p_bp <- setNames(bp$valor_p, bp$modelo)
faixa_dist <- faixas[faixas$eixo == "Distância (dezenas de milhas)", ]
cauda_dist <- faixa_dist[nrow(faixa_dist), ]
decis_m3 <- faixas[faixas$eixo == "Decis de valores ajustados" & faixas$modelo == "Modelo 3", ]
decis_score <- faixas[faixas$eixo == "Decis de score", ]
ep3 <- erros_padrao[erros_padrao$modelo == "Modelo 3", ]
ep_dist <- erros_padrao[erros_padrao$termo == "distance", ]
inf3 <- influencia_resumo[3, ]
dist3 <- distribuicao[3, ]
vif3 <- vif[vif$modelo == "Modelo 3", ]
abaixo_12 <- fitted(m3) < 12
fator_limite <- abs(ep_dist$t_hc3[3]) / qt(.975, df.residual(m3))
fator_limite_conv <- abs(ep_dist$t_convencional[3]) / qt(.975, df.residual(m3))
perfis_locais <- table(do.call(paste, base[c("distance", "unemp", "wage", "tuition", "urban", "region")]))
total_checagens <- total_checagens + checar(list(
  "Texto: RESET rejeita a 5% nos Modelos 1 e 3, nas duas versões" = max(p_reset("Modelo 1", 1:2), p_reset("Modelo 3", 1:2)) < .05,
  "Texto: RESET não rejeita a 5% no Modelo 2" = min(p_reset("Modelo 2", 1:2)) > .05,
  "Texto: Breusch-Pagan rejeita a 5% nos Modelos 1 e 3, não no 2" =
    p_bp[["Modelo 1"]] < .05 && p_bp[["Modelo 3"]] < .05 && p_bp[["Modelo 2"]] > .05,
  "Texto: HC3 menor que convencional em distance nos três modelos" = all(ep_dist$razao_hc3_sobre_convencional < 1),
  "Texto: GVIF ajustado ao quadrado abaixo de 1,5" = max(vif$gvif_ajustado_ao_quadrado) < 1.5,
  "Texto: Cook máximo abaixo de 0,01 nos Modelos 2 e 3" = max(influencia_resumo$cook_maximo[2:3]) < .01,
  "Texto: nenhum Cook acima de 1" = all(influencia_resumo$n_cook_acima_1 == 0),
  "Texto: p de Bonferroni igual a 1 nos três modelos" = all(influencia_resumo$p_bonferroni_maior_residuo == 1),
  "Texto: maiores resíduos do Modelo 3 são positivos" = all(d3$residuo_studentizado[alto_res] > 0),
  "Texto: assimetria positiva e curtose excedente negativa" = dist3$assimetria > 0 && dist3$curtose_excedente < 0,
  "Texto: cauda esquerda mais curta que a normal; direita próxima" = dist3$p01 > qnorm(.01) + .3 && abs(dist3$p99 - qnorm(.99)) < .2,
  "Texto: e² médio maior no centro que nas pontas" = which.max(decis_m3$media_residuo_quadrado) %in% 2:9,
  "Texto: primeiro decil de ajustados com IC acima de zero" = decis_m3$ic95_aprox_inf[1] > 0,
  "Texto: IC do primeiro decil de score inclui zero" = decis_score$ic95_aprox_inf[1] < 0 && decis_score$ic95_aprox_sup[1] > 0,
  "Texto: ajustados abaixo de 12 estão no primeiro decil de score" = all(base$score[abaixo_12] <= quantile(base$score, .1)),
  "Texto: maior alavancagem na distância máxima" = base$distance[which.max(d3$alavancagem)] == max(base$distance),
  "Texto: ajustados abaixo de 12, nenhum acima de 18" = dist3$n_ajustado_abaixo_de_12 > 0 && dist3$n_ajustado_acima_de_18 == 0,
  "Texto: IC da cauda de distância inclui zero" = cauda_dist$ic95_aprox_inf < 0 && cauda_dist$ic95_aprox_sup > 0))

# 10. Nota de leitura e registro do ambiente -------------------------------------
linha_testes <- function(nome) {
  r <- reset[reset$modelo == nome, ]
  b <- bp[bp$modelo == nome, ]
  paste0("| ", nome, " | ", fmt(r$estatistica_f[1], 2), " | ", fmt_p(r$valor_p[1]), " | ", fmt(r$estatistica_f[2], 2), " | ",
    fmt_p(r$valor_p[2]), " | ", fmt(b$estatistica_lm, 2), " (", b$gl, ") | ", fmt_p(b$valor_p), " |")
}
linha_ep <- function(i) {
  d <- ep_dist[i, ]
  paste0("| ", d$modelo, " | ", fmt(d$ep_convencional, 4), " | ", fmt(d$ep_hc3, 4), " | ",
    fmt(d$razao_hc3_sobre_convencional, 3), " | ", fmt_p(d$p_convencional), " | ", fmt_p(d$p_hc3), " |")
}
linha_vif <- function(i) {
  d <- vif3[i, ]
  paste0("| `", d$termo, "` | ", d$gl, " | ", fmt(d$gvif, 3), " | ", fmt(d$gvif_ajustado, 3), " | ",
    fmt(d$gvif_ajustado_ao_quadrado, 3), " |")
}
vif_termo <- function(modelo, termo) vif$gvif[vif$modelo == modelo & vif$termo == termo]
nota <- c("# Leitura dos diagnósticos econométricos", "",
  "Esta nota é gerada por `03_diagnosticos.R`. Nenhuma especificação foi alterada e nenhuma observação foi excluída.", "",
  "## Síntese", "",
  paste0("No Modelo 3, os testes apontam possível inadequação da especificação (RESET, p robusto ", fmt_p(p_reset("Modelo 3", 2)),
    ") e heterocedasticidade (Breusch-Pagan studentizado, p ", fmt_p(p_bp[["Modelo 3"]]), "). A multicolinearidade é baixa, e nenhuma observação isolada se destaca como ",
    "muito influente. A associação estimada para `distance` continua pequena, e sua significância a 5% é a parte mais frágil: bastaria um erro padrão ",
    fmt(100 * (fator_limite - 1), 0), "% maior que o HC3 para o intervalo incluir zero. Esses procedimentos não comprovam exogeneidade, ausência de variáveis omitidas ou independência entre estudantes."), "",
  "## Como os diagnósticos foram feitos", "",
  "- **RESET:** regressão auxiliar `education ~ regressores do modelo + ŷ² + ŷ³`, com H0 de que os dois coeficientes adicionais são nulos. A versão clássica usa `lmtest::resettest(power = 2:3, type = \"fitted\")`. Como ela supõe homocedasticidade, também é reportado um F de Wald com matriz HC3 na mesma auxiliar.",
  "- **Breusch-Pagan:** versão studentizada de Koenker, `lmtest::bptest(studentize = TRUE)`, com os regressores do próprio modelo. A estatística é n × R² da regressão de e² nesses regressores.",
  "- **VIF e GVIF:** `car::vif`. Ver a explicação de escalas abaixo.",
  "- **Triagem de influência:** alavancagem acima de 2k/n; resíduo studentizado externo acima de 3 em valor absoluto; distância de Cook acima de 4/n. São instrumentos de triagem, não regras de exclusão.",
  "- Os modelos carregados correspondem à base preservada: mesmos identificadores, mesmos valores e coeficientes reproduzidos (tabela 01).", "",
  "## Evidência encontrada", "",
  "### Resíduos e forma funcional", "",
  "| Modelo | RESET F clássico | p | RESET F HC3 | p | BP LM (gl) | p |",
  "|---|---:|---:|---:|---:|---:|---:|",
  linha_testes("Modelo 1"), linha_testes("Modelo 2"), linha_testes("Modelo 3"), "",
  "- O RESET rejeita a 5% nos Modelos 1 e 3 e não rejeita no Modelo 2. No Modelo 1, ŷ é função linear de `distance`, então o teste equivale a perguntar se potências de `distance` acrescentam poder explicativo.",
  paste0("- No Modelo 3, ", dist3$n_ajustado_abaixo_de_12, " valores ajustados ficam abaixo de 12 anos, o mínimo possível da escala (`score` médio de ", fmt(mean(base$score[abaixo_12]), 1), " nesse grupo, contra ", fmt(mean(base$score), 1),
    " na amostra). A forma linear não respeita esse piso em toda a amostra."),
  paste0("- Por decis de valores ajustados, a média dos resíduos do Modelo 3 varia de ", fmt(min(decis_m3$media_residuo), 3), " a ", fmt(max(decis_m3$media_residuo), 3),
    " ano e alterna sinais, sem curva única. O desvio mais visível está no início da faixa: no primeiro decil, a média é ", fmt(decis_m3$media_residuo[1], 3), " ano, com IC aproximado acima de zero (tabela 03)."),
  paste0("- Contra `score`, a curva LOESS é quase plana e sobe abaixo de cerca de 36 pontos, justamente onde ficam os valores ajustados abaixo de 12. No primeiro decil de `score`, a média é de ", fmt(decis_score$media_residuo[1], 3),
    " ano, com IC aproximado de [", fmt(decis_score$ic95_aprox_inf[1], 3), "; ", fmt(decis_score$ic95_aprox_sup[1], 3), "]. A faixa densa e descendente nesse gráfico reúne estudantes com 12 anos, o piso da escala."),
  paste0("- Nas distâncias acima de 100 milhas, a média dos resíduos é de ", fmt(cauda_dist$media_residuo, 3), " ano, com apenas ", cauda_dist$n, " estudantes e IC aproximado de [",
    fmt(cauda_dist$ic95_aprox_inf, 3), "; ", fmt(cauda_dist$ic95_aprox_sup, 3), "], que inclui zero. A curva LOESS é quase plana até cerca de 100 milhas e depois sobe, mas se apoia em poucas observações."),
  "- O gráfico contra valores ajustados mostra faixas diagonais paralelas. Elas são mecânicas: cada faixa reúne estudantes com o mesmo valor de `education`, que é discreta. Não devem ser lidas como padrão econômico.",
  "- Gráficos: [valores ajustados](graficos/01_residuos_ajustados_modelos.png), [distância](graficos/02_residuos_distancia_modelo_3.png) e [desempenho inicial](graficos/03_residuos_score_modelo_3.png).", "",
  "### Heterocedasticidade", "",
  paste0("- O Breusch-Pagan rejeita homocedasticidade nos Modelos 1 (p = ", fmt_p(p_bp[["Modelo 1"]]), ") e 3 (p ", fmt_p(p_bp[["Modelo 3"]]), "). No Modelo 2, não rejeita (p = ", fmt_p(p_bp[["Modelo 2"]]),
    "). Isso não prova homocedasticidade nesse modelo: o teste procura variância linear nos regressores e pode não detectar outros formatos."),
  paste0("- No Modelo 3, a média de e² por decil de valores ajustados vai de ", fmt(decis_m3$media_residuo_quadrado[1], 2), " no primeiro decil a ", fmt(max(decis_m3$media_residuo_quadrado), 2),
    " nos decis centrais e ", fmt(decis_m3$media_residuo_quadrado[nrow(decis_m3)], 2), " no último. Variância menor nas pontas é compatível com uma variável limitada entre 12 e 18, embora o teste não identifique essa causa."),
  paste0("- Rejeitar homocedasticidade não significa que todo erro HC3 seja maior. No Modelo 3, a razão HC3/convencional vai de ", fmt(min(ep3$razao_hc3_sobre_convencional), 3), " a ", fmt(max(ep3$razao_hc3_sobre_convencional), 3),
    ". O teste indica que há heterocedasticidade, mas não mede quanto ela altera cada erro padrão. Para `distance`, o HC3 é menor nos três modelos:"), "",
  "| Modelo | EP conv. de `distance` | EP HC3 | Razão | p conv. | p HC3 |", "|---|---:|---:|---:|---:|---:|",
  linha_ep(1), linha_ep(2), linha_ep(3), "",
  "### Multicolinearidade", "",
  "As escalas diferem. Para termo com 1 grau de liberdade, GVIF = VIF, e GVIF^(1/(2gl)) é a raiz do VIF: o fator que multiplica o erro padrão. Para `ethnicity`, com 2 graus de liberdade, o GVIF é conjunto e não é comparável diretamente a um VIF. A comparação deve usar a coluna ajustada, ou seu quadrado, que volta à escala do VIF.", "",
  "| Termo (Modelo 3) | gl | GVIF | GVIF^(1/(2gl)) | Ajustado ao quadrado |", "|---|---:|---:|---:|---:|",
  vapply(seq_len(nrow(vif3)), linha_vif, character(1)), "",
  paste0("O maior valor na escala do VIF é o de `", vif3$termo[which.max(vif3$gvif_ajustado_ao_quadrado)], "` (", fmt(max(vif3$gvif_ajustado_ao_quadrado), 3),
    "), o que corresponde a um erro padrão cerca de ", fmt(100 * (max(vif3$gvif_ajustado) - 1), 0), "% maior do que sem correlação com os demais regressores. O VIF de `distance` sobe de ",
    fmt(vif_termo("Modelo 2", "distance"), 3), " no Modelo 2 para ", fmt(vif_termo("Modelo 3", "distance"), 3), " no Modelo 3. Nada aqui recomenda excluir controles: controles entram por motivo econômico, não por limiar."), "",
  "### Observações influentes", "",
  paste0("- No Modelo 3, ", nrow(influentes), " de ", fmt(n, 0), " observações são sinalizadas por algum critério (tabela 08): ", inf3$n_alavancagem_acima_2k_n, " por alavancagem, ",
    inf3$n_residuo_abs_acima_3, " por resíduo e ", inf3$n_cook_acima_4_n, " por Cook; uma observação pode atender a mais de um. Nenhuma foi excluída. A tabela traz o identificador original do AER, que não coincide necessariamente com a posição na base (o caso de maior Cook tem identificador ",
    influentes$id_original[1], " e está na linha ", influentes$linha_na_base[1], ")."),
  paste0("- A distância de Cook máxima é ", fmt(inf3$cook_maximo, 4), ", muito abaixo de 1 (", fmt(influencia_resumo$cook_maximo[1], 4), " no Modelo 1 e ", fmt(influencia_resumo$cook_maximo[2], 4), " no Modelo 2). O limiar 4/n fica muito baixo em amostra grande (", fmt(4 / n, 5), ") e sinaliza ", fmt(100 * inf3$n_cook_acima_4_n / n, 1), "% da amostra: serve para ordenar casos, não para indicar problema."),
  paste0("- O maior resíduo studentizado é ", fmt(inf3$residuo_abs_maximo, 2), " e todos os acima de 3 são positivos: estudantes com escolaridade bem acima da prevista. Com correção de Bonferroni, o maior deles não se destaca (p = 1)."),
  paste0("- ", sum(alta_alav & base$distance > 10), " das ", sum(alta_alav), " observações de alta alavancagem têm distância acima de 100 milhas. A maior alavancagem é ", fmt(inf3$alavancagem_maxima, 4), ", no valor máximo de distância (200 milhas)."),
  "- [Gráfico de influência](graficos/05_influencia_modelo_3.png). Valores extremos não são prova de erro; a tabela serve para conferir os registros.", "",
  "### Distribuição dos resíduos", "",
  paste0("- O [gráfico Q-Q](graficos/04_qq_modelo_3.png) se afasta da reta. A assimetria é ", fmt(dist3$assimetria, 2), " e a curtose excedente, ", fmt(dist3$curtose_excedente, 2), ". O desvio principal está na cauda esquerda, mais curta que a da normal (percentil 1 de ", fmt(dist3$p01, 2), ", contra ", fmt(qnorm(.01), 2), "). A cauda direita fica próxima da reta (percentil 99 de ", fmt(dist3$p99, 2), ")."),
  paste0("- Esse afastamento é esperado: `education` é discreta, limitada entre 12 e 18 e concentrada em 12 anos (", fmt(100 * mean(base$education == 12), 1), "% da amostra). A cauda esquerda curta é compatível com o piso de 12 anos. Resíduos de uma variável assim não podem ser exatamente normais. Com n = ", fmt(n, 0),
    ", um teste formal tenderia a rejeitar mesmo desvios pequenos, então a leitura se apoia no gráfico e nos números."), "",
  "## Consequência prática", "",
  "- **Não viés:** a normalidade dos resíduos não é condição para o MQO ser não viesado. O não viés depende de linearidade nos parâmetros, amostragem aleatória, ausência de colinearidade perfeita e média condicional do erro igual a zero. A normalidade só daria distribuição exata a t e F em amostra finita. Aqui a inferência se apoia em aproximação de amostra grande, que também pressupõe dependência limitada entre observações.",
  "- **Erro padrão:** a rejeição no Modelo 3 sustenta manter HC3 como referência nesse modelo, sem descartar a convencional. Para `distance`, as duas levam à mesma conclusão a 5%.",
  paste0("- **`distance`:** o intervalo HC3 do Modelo 3 termina perto de zero. O erro padrão precisaria ser ", fmt(fator_limite, 2), " vez o HC3 (ou ", fmt(fator_limite_conv, 2), " vez o convencional) para o IC de 95% incluir zero. A conclusão de significância deve ser apresentada com essa cautela. Esse número é uma conta de sensibilidade, não uma estimativa da correlação dentro de escolas."),
  "- **Forma funcional:** o coeficiente de `distance` deve ser lido como a inclinação de uma aproximação linear, não como uma mudança igual em qualquer distância. As rejeições do RESET justificam comparar formas funcionais na próxima etapa.",
  "- **RESET:** o teste pode apontar inadequação da especificação, mas não identifica sozinho a causa nem a transformação correta. A rejeição pode refletir não linearidade, variável omitida ou os limites de `education`.",
  "- **Multicolinearidade:** não é o que limita a precisão de `distance`, e não há motivo para retirar controles por esse diagnóstico.",
  "- **Influência:** os dados não indicam que poucas observações dominem os resultados pelas medidas examinadas. Não houve reestimação sem elas, portanto esta etapa não mede quanto os coeficientes mudariam.",
  "- **Escolha de modelo:** os diagnósticos não elegem um modelo, e significância ou R² também não bastam para isso. A não rejeição do RESET e do Breusch-Pagan no Modelo 2 não o torna preferível: ele responde a outra comparação, sem desempenho inicial e sem controles demográficos e locais.", "",
  "## Limitações que esses diagnósticos não resolvem", "",
  "- **Exogeneidade e variáveis omitidas:** nenhum destes procedimentos comprova exogeneidade ou ausência de variáveis omitidas. Resíduos do MQO são ortogonais aos regressores por construção, então gráficos de resíduos não podem revelar correlação entre o erro verdadeiro e `distance`. A escolha do local de moradia, a motivação e a qualidade da escola seguem como possíveis fontes de endogeneidade.",
  paste0("- **Independência entre estudantes:** estes procedimentos também não comprovam independência. HC3 não corrige correlação dos erros dentro de escolas ou localidades. A pesquisa cobriu cerca de 1.100 escolas, e a base não identifica a escola. Há ", fmt(length(perfis_locais), 0),
    " combinações distintas de variáveis locais na base (`distance`, `unemp`, `wage`, `tuition`, `urban`, `region`), com média de ", fmt(n / length(perfis_locais), 1), " estudantes por combinação. Isso sugere agrupamento, mas essas combinações não são identificadores de escola."),
  "- **Causalidade:** passar ou não em um teste não transforma associação em efeito causal.",
  "- **Poder e formato dos testes:** o RESET usa só potências de ŷ, e o Breusch-Pagan, só uma relação linear com os regressores. Não rejeitar não confirma a especificação.",
  "- **Múltiplos testes:** os testes foram feitos em três modelos, sem ajuste para comparações múltiplas. Os modelos também são aninhados, portanto os resultados não são independentes.",
  "- **Medida da variável dependente:** nenhuma correção foi feita para a escala construída de `education`. Pesos amostrais continuam ausentes.", "",
  "## O que estes achados motivam na comparação de formas funcionais", "",
  "A comparação ainda não foi feita. Os diagnósticos apenas indicam o que vale examinar:", "",
  "- **Quadrática em `distance`:** o RESET rejeita no Modelo 1, em que ŷ é função só de `distance`. No Modelo 3, a evidência é mais fraca: a curva de resíduos é quase plana até cerca de 100 milhas, e a média acima disso é positiva, mas imprecisa.",
  "- **Quadrática em `score`:** é a motivação mais direta no Modelo 3. Os valores ajustados abaixo do piso estão todos no primeiro decil de `score`, e a curva de resíduos sobe nessa faixa. É uma hipótese a testar: o desvio se concentra em uma ponta e pode refletir o piso, não uma parábola.",
  paste0("- **Logaritmo de `distance` (log-log):** a concentração em distâncias curtas e a cauda longa motivam a comparação. As ", sum(base$distance == 0), " distâncias iguais a zero exigem decisão explícita, sem exclusão silenciosa, para que os modelos comparados usem as mesmas observações."),
  paste0("- **Logaritmo de `education` (log-linear):** o enunciado pede essa forma, mas a evidência a favor é fraca. A faixa de 12 a 18 anos é estreita, então a transformação muda pouco a forma da variável e não elimina a discretização nem o piso. R² com variáveis dependentes diferentes não é comparável diretamente."),
  "- Nenhuma dessas formas resolve endogeneidade ou correlação dentro de escolas. A escolha final deve considerar interpretação, justificativa econômica e os diagnósticos, não apenas significância ou R².", "",
  "Fonte: tabelas e gráficos em `resultados/diagnosticos/`; modelos em `resultados/modelos/`; documentação de AER::CollegeDistance.")
writeLines(nota, file.path(saida, "LEITURA_DOS_DIAGNOSTICOS.md"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(saida, "sessionInfo_diagnosticos.txt"))

print(reset[, c("modelo", "versao", "estatistica_f", "gl2", "valor_p")], row.names = FALSE)
print(bp[, c("modelo", "estatistica_lm", "gl", "valor_p")], row.names = FALSE)
print(influencia_resumo[, c("modelo", "n_alavancagem_acima_2k_n", "n_residuo_abs_acima_3", "n_cook_acima_4_n", "n_sinalizadas_algum_criterio", "cook_maximo")], row.names = FALSE)
message("Etapa 3 concluída. ", total_checagens, " verificações aprovadas. Resultados em: ", saida)
