# Execute este arquivo uma vez em cada computador do grupo.
# Os pacotes vêm do CRAN. A análise não depende de extensões do editor.
options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 300)

# Usar a biblioteca pessoal evita alterar a instalação central do R.
biblioteca <- path.expand(Sys.getenv("R_LIBS_USER"))
if (!nzchar(biblioteca)) stop("A biblioteca pessoal R_LIBS_USER não está definida.")
dir.create(biblioteca, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(biblioteca, .libPaths()))

# AER fornece os dados; ggplot2 gera os gráficos; languageserver ajuda o VS Code.
pacotes <- c("AER", "ggplot2", "languageserver")
faltantes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) install.packages(faltantes, lib = biblioteca)
stopifnot(all(vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)))
print(data.frame(pacote = pacotes, versao = vapply(
  pacotes, function(p) as.character(packageVersion(p)), character(1)
)))
message("Ambiente pronto. Execute 01_descritiva.R a partir da pasta do projeto.")
