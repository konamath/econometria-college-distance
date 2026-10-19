# COLLEGEDISTANCE | V1: preparação e análise descritiva
# Pergunta: como distância e condições familiares se relacionam com escolaridade?
# Esta versão não estima regressões nem identifica efeitos causais.
# Execução no terminal: Rscript --vanilla 01_descritiva.R
# Execução no console R: source("01_descritiva.R", encoding = "UTF-8")

# 1. Localizar o projeto e verificar dependências -------------------------------
argumento <- grep("^--file=", commandArgs(), value = TRUE)
arquivo_source <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
if (length(argumento)) {
  pasta <- dirname(normalizePath(sub("^--file=", "", argumento[1])))
} else if (!is.null(arquivo_source)) {
  pasta <- dirname(normalizePath(arquivo_source))
} else {
  pasta <- getwd()
}
if (!file.exists(file.path(pasta, "01_descritiva.R"))) {
  stop("Abra a pasta CollegeDistance_v1 e execute o script completo.")
}
for (p in c("AER", "ggplot2")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Falta o pacote ", p, ". Execute 00_preparar_ambiente.R primeiro.")
  }
}
library(ggplot2)
options(scipen = 999)
for (p in c("dados", "resultados/tabelas", "resultados/graficos")) {
  dir.create(file.path(pasta, p), recursive = TRUE, showWarnings = FALSE)
}
tabelas <- file.path(pasta, "resultados/tabelas")
graficos <- file.path(pasta, "resultados/graficos")
exportar <- function(x, nome) {
  write.csv(x, file.path(tabelas, paste0(nome, ".csv")), row.names = FALSE,
            fileEncoding = "UTF-8", na = "")
}
fmt <- function(x, digitos = 2) {
  formatC(x, format = "f", digits = digitos, decimal.mark = ",", big.mark = ".")
}

# 2. Carregar a base do pacote e preservar uma cópia original ------------------
data("CollegeDistance", package = "AER")
base_original <- CollegeDistance
base <- base_original
stopifnot(nrow(base) > 0, all(c("education", "distance", "income") %in% names(base)))
saveRDS(base_original, file.path(pasta, "dados/CollegeDistance_original.rds"))
write.csv(base_original, file.path(pasta, "dados/CollegeDistance_original.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# Não excluímos observações, não imputamos dados e não convertemos fatores
# em códigos numéricos. As 14 variáveis mantêm sua codificação original.
numericas <- names(base)[vapply(base, is.numeric, logical(1))]
categoricas <- names(base)[vapply(base, is.factor, logical(1))]
fonte <- "https://cran.r-universe.dev/AER/doc/manual.html#CollegeDistance"
dicionario <- data.frame(
  variavel = names(base),
  descricao = c("Sexo registrado", "Grupo étnico registrado", "Nota em testes no ano inicial",
    "Pai graduado", "Mãe graduada", "Família possui imóvel próprio",
    "Escola em área urbana", "Desemprego no condado em 1980",
    "Salário industrial estadual por hora em 1980", "Distância até faculdade de quatro anos",
    "Custo médio de faculdade de quatro anos no estado", "Anos de escolaridade",
    "Faixa de renda familiar anual", "Região"),
  unidade_ou_categorias = c("male; female", "other; afam; hispanic", "Pontos",
    "no; yes", "no; yes", "no; yes", "no; yes", "%", "US$/hora",
    "Dezenas de milhas", "Milhares de US$", "Anos",
    "low: até US$ 25.000; high: acima de US$ 25.000", "other; west"),
  observacao = c("Categoria original da pesquisa", "Categorias nominais, sem ordenação",
    "Medida observada de desempenho prévio, não habilidade inata",
    "Indicador, não anos de estudo do pai", "Indicador, não anos de estudo da mãe",
    "Não é o valor do patrimônio", "Localização da escola",
    "Característica local", "Não é o salário individual do estudante",
    "1 unidade corresponde a 10 milhas; zeros são preservados",
    "Característica estadual, não gasto individual", "Codificação educacional descrita pelo AER",
    "Variável categórica, não renda contínua", "Base inclui West e other"),
  fonte = fonte
)
exportar(dicionario, "01_dicionario")

# 3. Qualidade e tamanho da amostra --------------------------------------------
qualidade <- data.frame(
  variavel = names(base),
  tipo = vapply(base, function(x) paste(class(x), collapse = "/"), character(1)),
  n_total = nrow(base),
  n_validos = vapply(base, function(x) sum(!is.na(x)), integer(1)),
  n_ausentes = vapply(base, function(x) sum(is.na(x)), integer(1)),
  n_valores_distintos = vapply(base, function(x) length(unique(x[!is.na(x)])), integer(1))
)
exportar(qualidade, "02_qualidade_por_variavel")
checagens <- data.frame(
  verificacao = c("Observações", "Variáveis", "Células ausentes", "Linhas com algum ausente",
    "Linhas inteiramente repetidas", "Distância zero", "Distância negativa",
    "Escolaridade não positiva", "Valores numéricos não finitos, exceto NA", "Linhas excluídas"),
  quantidade = c(nrow(base), ncol(base), sum(is.na(base)), sum(!complete.cases(base)),
    sum(duplicated(base)), sum(base$distance == 0, na.rm = TRUE),
    sum(base$distance < 0, na.rm = TRUE), sum(base$education <= 0, na.rm = TRUE),
    sum(vapply(base[numericas], function(x) sum(!is.finite(x) & !is.na(x)), integer(1))), 0)
)
exportar(checagens, "03_checagens_amostra")

# 4. Estatísticas numéricas e frequências --------------------------------------
# Variância e desvio padrão são amostrais (denominador n-1).
descritivas <- do.call(rbind, lapply(numericas, function(v) {
  x <- base[[v]]
  q <- quantile(x, c(.25, .5, .75), na.rm = TRUE)
  data.frame(variavel = v, n_validos = sum(!is.na(x)), n_ausentes = sum(is.na(x)),
    media = mean(x, na.rm = TRUE), mediana = q[2], variancia_amostral = var(x, na.rm = TRUE),
    desvio_padrao = sd(x, na.rm = TRUE), minimo = min(x, na.rm = TRUE),
    p25 = q[1], p75 = q[3], maximo = max(x, na.rm = TRUE),
    n_fora_1_5_iqr = sum(x < q[1] - 1.5 * IQR(x, na.rm = TRUE) |
                          x > q[3] + 1.5 * IQR(x, na.rm = TRUE), na.rm = TRUE))
}))
rownames(descritivas) <- NULL
exportar(descritivas, "04_descritivas_numericas")
# O critério IQR apenas sinaliza extremos, não justifica sua exclusão.
frequencias <- do.call(rbind, lapply(categoricas, function(v) {
  t <- table(base[[v]], useNA = "ifany")
  data.frame(variavel = v, categoria = names(t), n = as.integer(t),
             percentual_total = 100 * as.integer(t) / nrow(base), denominador = nrow(base))
}))
exportar(frequencias, "05_frequencias_categoricas")

# Pearson só entre variáveis numéricas originais, usando uma amostra comum.
amostra_cor <- base[complete.cases(base[numericas]), numericas]
correlacoes <- cor(amostra_cor, method = "pearson")
exportar(data.frame(variavel = rownames(correlacoes), correlacoes, row.names = NULL),
         "06_correlacoes_pearson")
exportar(data.frame(criterio = "Casos completos nas variáveis numéricas",
                    n = nrow(amostra_cor)), "06b_amostra_correlacoes")

# Comparações brutas de escolaridade, sem ajuste e sem interpretação causal.
por_grupo <- do.call(rbind, lapply(c("income", "fcollege", "mcollege", "urban"), function(v) {
  do.call(rbind, lapply(levels(base[[v]]), function(g) {
    x <- base$education[which(base[[v]] == g)]
    data.frame(variavel_grupo = v, categoria = g, n_grupo = length(x),
      n_escolaridade_valida = sum(!is.na(x)), media_escolaridade = mean(x, na.rm = TRUE),
      mediana_escolaridade = median(x, na.rm = TRUE), dp_escolaridade = sd(x, na.rm = TRUE))
  }))
}))
exportar(por_grupo, "07_escolaridade_por_grupo")

# 5. Quatro gráficos descritivos -----------------------------------------------
azul <- "#245B78"
laranja <- "#BA642E"
cinza <- "#24333B"
tema <- theme_minimal(base_size = 13, base_family = "sans") +
  theme(plot.title = element_text(face = "bold", size = 19, color = cinza),
    plot.subtitle = element_text(size = 11, color = "#52616B", margin = margin(b = 16)),
    plot.caption = element_text(size = 9, hjust = 0, margin = margin(t = 14)),
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    axis.title = element_text(size = 12), plot.margin = margin(18, 24, 18, 18),
    legend.position = "none")
rodape <- "Fonte: AER::CollegeDistance | High School and Beyond, 1980 e acompanhamento em 1986."
subtitulo <- paste0("Amostra completa: ", fmt(nrow(base), 0), " estudantes | Sem exclusões")
salvar <- function(p, nome) {
  ggsave(file.path(graficos, paste0(nome, ".png")), p, width = 10, height = 6,
         units = "in", dpi = 180, bg = "white")
}

contagem_educ <- as.data.frame(table(base$education))
names(contagem_educ) <- c("escolaridade", "n")
contagem_educ$escolaridade <- as.numeric(as.character(contagem_educ$escolaridade))
contagem_educ$percentual <- 100 * contagem_educ$n / nrow(base)
exportar(contagem_educ, "08_distribuicao_escolaridade")
p1 <- ggplot(contagem_educ, aes(escolaridade, n)) +
  geom_col(fill = azul, width = .7) +
  geom_text(aes(label = paste0(fmt(percentual, 1), "%")), vjust = -.5, size = 4) +
  scale_x_continuous(breaks = contagem_educ$escolaridade) +
  scale_y_continuous(expand = expansion(mult = c(0, .14)), labels = function(x) fmt(x, 0)) +
  labs(title = "Distribuição dos anos de escolaridade", subtitle = subtitulo,
    x = "Escolaridade (anos)", y = "Número de estudantes",
    caption = paste0(rodape, "\nRótulos: percentual da amostra total.")) + tema
salvar(p1, "01_escolaridade")

p2 <- ggplot(base, aes(distance)) +
  geom_histogram(binwidth = 1, boundary = 0, closed = "left", fill = azul, color = "white") +
  scale_x_continuous(breaks = seq(0, max(base$distance), 2), expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(expand = expansion(mult = c(0, .08)), labels = function(x) fmt(x, 0)) +
  labs(title = "Distribuição da distância até a faculdade", subtitle = subtitulo,
    x = "Distância (dezenas de milhas; 1 unidade = 10 milhas)", y = "Número de estudantes",
    caption = paste0(rodape, "\nClasses de 10 milhas; ", sum(base$distance == 0),
      " distâncias iguais a zero preservadas. Faixa completa exibida.")) + tema
salvar(p2, "02_distancia")

medias_renda <- subset(por_grupo, variavel_grupo == "income")
rotulos_renda <- setNames(paste0(c("Até US$ 25 mil/ano", "Acima de US$ 25 mil/ano"),
  "\n", "n = ", fmt(medias_renda$n_grupo, 0)), medias_renda$categoria)
p3 <- ggplot(base, aes(income, education)) +
  geom_boxplot(aes(fill = income), width = .4, alpha = .35, outlier.shape = 1) +
  geom_point(data = medias_renda, aes(categoria, media_escolaridade),
    inherit.aes = FALSE, shape = 18, size = 4, color = cinza) +
  scale_fill_manual(values = c(low = azul, high = laranja)) +
  scale_x_discrete(labels = rotulos_renda) +
  scale_y_continuous(breaks = 12:18) +
  labs(title = "Escolaridade por faixa de renda familiar", subtitle = subtitulo,
    x = NULL, y = "Escolaridade (anos)",
    caption = paste0(rodape, "\nCaixa: quartis; linha: mediana; losango: média. Comparação bruta, sem controles.")) + tema
salvar(p3, "03_escolaridade_renda")

# As duas medidas têm valores repetidos. O deslocamento é apenas visual.
# Semente fixa garante o mesmo gráfico em cada execução.
p4 <- ggplot(base, aes(distance, education)) +
  geom_point(position = position_jitter(width = .04, height = .10, seed = 314),
             color = azul, alpha = .16, size = 1.4) +
  scale_x_continuous(breaks = seq(0, max(base$distance), 2)) +
  scale_y_continuous(breaks = 12:18) +
  labs(title = "Escolaridade e distância até a faculdade", subtitle = subtitulo,
    x = "Distância (dezenas de milhas)", y = "Escolaridade (anos)",
    caption = paste0(rodape,
      "\nCada ponto representa um estudante; pequeno deslocamento visual para reduzir sobreposição.",
      "\nOs dados originais não foram alterados. Associação bruta, sem ajuste por outras variáveis.")) + tema
salvar(p4, "04_escolaridade_distancia")

# 6. Registrar resultados, fontes e ambiente ----------------------------------
media_baixa <- medias_renda$media_escolaridade[medias_renda$categoria == "low"]
media_alta <- medias_renda$media_escolaridade[medias_renda$categoria == "high"]
leitura <- c("# Leitura inicial dos resultados", "",
  "Esta nota é gerada pelo script. Não substitui o relatório final do trabalho.", "",
  paste0("- Amostra: ", fmt(nrow(base), 0), " estudantes e ", ncol(base), " variáveis."),
  paste0("- Células ausentes: ", sum(is.na(base)), "; linhas totalmente repetidas: ", sum(duplicated(base)), "."),
  "- Nenhuma observação foi excluída ou imputada. Não há ponderação amostral nesta análise.",
  paste0("- Escolaridade média: ", fmt(mean(base$education)), " anos; mediana: ",
    fmt(median(base$education), 0), " anos."),
  paste0("- Distância média: ", fmt(mean(base$distance)), " dezenas de milhas (",
    fmt(10 * mean(base$distance)), " milhas)."),
  paste0("- Distâncias iguais a zero: ", sum(base$distance == 0),
    ". O logaritmo da distância não está definido nessas observações."),
  paste0("- Escolaridade média por renda: ", fmt(media_baixa), " anos na categoria low e ",
    fmt(media_alta), " anos na categoria high; diferença bruta: ", fmt(media_alta - media_baixa), " ano."),
  paste0("- Correlação de Pearson entre distância e escolaridade: ",
    fmt(correlacoes["distance", "education"], 3), " (", nrow(amostra_cor), " casos completos)."),
  paste0("- Correlação de Pearson entre nota inicial e escolaridade: ",
    fmt(correlacoes["score", "education"], 3), "."), "",
  "## Como interpretar", "",
  "As comparações são descritivas, sem controles ou testes de significância. Não demonstram causalidade.",
  "A correlação simples não mede a relação parcial após controlar renda, desempenho e contexto familiar.",
  "A amostra é histórica e de estudantes do ensino médio; não representa automaticamente todos os jovens, o Brasil ou a população atual.",
  "income é uma categoria; wage é salário industrial estadual; urban se refere à escola.",
  "Valores extremos foram mantidos. A sinalização pelo intervalo interquartil não é prova de erro.", "",
  "## Próxima etapa", "",
  "Revisar as distribuições e definir os modelos de regressão e seus controles. A V1 encerra na descrição.", "",
  paste0("Fonte: [documentação CollegeDistance/AER](", fonte, ")."),
  paste0("Versão do AER: ", packageVersion("AER"), "."))
writeLines(leitura, file.path(pasta, "resultados/LEITURA_DOS_RESULTADOS.md"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(pasta, "resultados/sessionInfo.txt"))
capture.output(citation("AER"), file = file.path(pasta, "resultados/referencia_AER.txt"))
writeLines(c(paste("Base: AER::CollegeDistance; AER", packageVersion("AER")),
  paste("Documentação:", fonte), "Pesquisa: High School and Beyond, 1980 e acompanhamento em 1986.",
  "Amostra: ambas as regiões da versão AER; unidade: estudante; análise sem pesos.",
  "Tratamento: nenhuma exclusão, imputação ou mudança na codificação das variáveis originais."),
  file.path(pasta, "dados/PROVENIENCIA.txt"), useBytes = TRUE)
stopifnot(identical(base, base_original), sum(contagem_educ$n) == nrow(base),
  all(is.finite(correlacoes)), length(list.files(graficos, pattern = "[.]png$")) == 4)
cat(paste(leitura[4:14], collapse = "\n"), "\n\n")
message("V1 concluída. Tabelas e quatro gráficos estão em: ", file.path(pasta, "resultados"))
