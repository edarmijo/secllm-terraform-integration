# ======================================================================
# analisis_mcnemar.R
# Analisis de transicion P0 vs P1 (feedback de la profesora):
#   1. McNemar exacto sobre Fc (correccion funcional) por modelo
#   2. McNemar exacto sobre Sp (script libre de smells) por modelo
#   3. Figura de transiciones por pregunta (para la seccion de Resultados)
#   4. Tablas LaTeX listas para pegar en el paper
#
# Ejecutar desde la raiz del proyecto (donde esta generar_todo.R):
#   En RStudio: Session > Set Working Directory > To Source File Location
# ======================================================================

if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
if (!requireNamespace("ggplot2",  quietly = TRUE)) install.packages("ggplot2")
library(jsonlite)
library(ggplot2)

BASE   <- "research_iac/integration/outputs_v2"
MODELS <- c("llama3_1_8b", "granite-code_8b", "codegemma_7b", "codellama_7b")
LABELS <- c("llama3.1:8b", "granite-code:8b", "codegemma:7b", "codellama:7b")
OUTDIR <- "paper_entrega/figures"
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)

# ---------- Lectura de datos por pregunta ----------

leer_fc <- function(model, cond) {
  d <- fromJSON(file.path(BASE, model, cond, "iac_eval_results.json"))
  # Fc = 1 solo si OPA == "Success" (mismo criterio del pipeline)
  setNames(as.integer(d$opa_evaluation_result == "Success"), d$file)
}

leer_sp <- function(model, cond) {
  d <- fromJSON(file.path(BASE, model, cond, "secllm_results.json"))
  files <- unique(d$PATH)
  # Sp = 1 si el archivo NO tiene ningun smell detectado (todas las filas "none")
  sp <- sapply(files, function(f) as.integer(all(d$SMELL[d$PATH == f] == "none")))
  setNames(sp, files)
}

leer_sc <- function(model, cond) {
  d <- fromJSON(file.path(BASE, model, cond, "secllm_results.json"))
  files <- unique(d$PATH)
  sc <- sapply(files, function(f) sum(d$SMELL[d$PATH == f] != "none"))
  setNames(sc, files)
}

# ---------- McNemar exacto (binomial sobre pares discordantes) ----------

mcnemar_exacto <- function(v0, v1) {
  comunes <- intersect(names(v0), names(v1))
  x0 <- v0[comunes]; x1 <- v1[comunes]
  a <- sum(x0 == 1 & x1 == 1)   # exito en ambas
  b <- sum(x0 == 1 & x1 == 0)   # solo P0
  c <- sum(x0 == 0 & x1 == 1)   # solo P1
  d <- sum(x0 == 0 & x1 == 0)   # fallo en ambas
  p <- if (b + c > 0) binom.test(b, b + c, p = 0.5)$p.value else NA
  list(a = a, b = b, c = c, d = d, n = length(comunes), p = p)
}

# ---------- 1 y 2: McNemar sobre Fc y Sp ----------

resultados <- data.frame()
for (i in seq_along(MODELS)) {
  m <- MODELS[i]
  fc <- mcnemar_exacto(leer_fc(m, "P0"), leer_fc(m, "P1"))
  sp <- mcnemar_exacto(leer_sp(m, "P0"), leer_sp(m, "P1"))
  resultados <- rbind(resultados, data.frame(
    modelo = LABELS[i],
    Fc_a = fc$a, Fc_b = fc$b, Fc_c = fc$c, Fc_d = fc$d, Fc_p = fc$p,
    Sp_a = sp$a, Sp_b = sp$b, Sp_c = sp$c, Sp_d = sp$d, Sp_p = sp$p
  ))
}

cat("==================== McNemar sobre Fc (P0 vs P1) ====================\n")
print(resultados[, 1:6], row.names = FALSE)
cat("\n==================== McNemar sobre Sp (P0 vs P1) ====================\n")
cat("(a = libre de smells en ambas, b = solo P0, c = solo P1, d = con smells en ambas)\n")
print(resultados[, c(1, 7:11)], row.names = FALSE)

# ---------- 3: Figura de transiciones de Sc por pregunta ----------

trans <- data.frame()
for (i in seq_along(MODELS)) {
  m <- MODELS[i]
  s0 <- leer_sc(m, "P0"); s1 <- leer_sc(m, "P1")
  comunes <- intersect(names(s0), names(s1))
  delta <- s1[comunes] - s0[comunes]
  trans <- rbind(trans, data.frame(
    modelo = LABELS[i],
    categoria = factor(
      ifelse(delta < 0, "Fewer smells (improved)",
      ifelse(delta > 0, "More smells (worsened)", "Unchanged")),
      levels = c("Fewer smells (improved)", "Unchanged", "More smells (worsened)"))
  ))
}

conteos <- as.data.frame(table(trans$modelo, trans$categoria))
names(conteos) <- c("modelo", "categoria", "n")

p <- ggplot(conteos, aes(x = modelo, y = n, fill = categoria)) +
  geom_col(width = 0.65, color = "grey25", linewidth = 0.3) +
  geom_text(aes(label = ifelse(n > 0, n, "")),
            position = position_stack(vjust = 0.5), size = 3.2) +
  scale_fill_manual(values = c("Fewer smells (improved)" = "#4d9970",
                               "Unchanged"               = "#d9d9d9",
                               "More smells (worsened)"  = "#c05555")) +
  labs(x = NULL, y = "Number of scenarios (N = 40)", fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank())

ggsave(file.path(OUTDIR, "fig_transitions_sc.pdf"), p, width = 6.5, height = 3.6)
cat(sprintf("\nFigura guardada en %s/fig_transitions_sc.pdf\n", OUTDIR))

# ---------- 4: Tablas LaTeX ----------

fmt_p <- function(p) ifelse(is.na(p), "1.000$^{\\dagger}$", sprintf("%.3f", p))

sink("mcnemar_tablas_latex.txt")
cat("% ===== Tabla McNemar Fc (pegar en la subseccion Statistical Analysis) =====\n")
cat("\\begin{table}[htbp]\n\\centering\\footnotesize\\setlength{\\tabcolsep}{4pt}\n")
cat("\\caption{McNemar Transition Matrices for Functional Correctness ($Fc$), P0 vs.\\ P1 ($N=40$ per model)}\n")
cat("\\label{tab:mcnemar_fc}\n\\begin{tabular}{@{}lrrrrc@{}}\n\\toprule\n")
cat("\\textbf{Model} & \\textbf{a} & \\textbf{b} & \\textbf{c} & \\textbf{d} & \\textbf{$p$} \\\\\n\\midrule\n")
for (i in 1:nrow(resultados)) {
  r <- resultados[i, ]
  cat(sprintf("%s & %d & %d & %d & %d & %s \\\\\n",
              r$modelo, r$Fc_a, r$Fc_b, r$Fc_c, r$Fc_d, fmt_p(r$Fc_p)))
}
cat("\\bottomrule\n\\end{tabular}\n\n\\vspace{2pt}\n")
cat("{\\footnotesize $a$: correct under both; $b$: correct only under P0; $c$: correct only under P1; $d$: incorrect under both. $^{\\dagger}$No discordant pairs ($b+c=0$); the exact test is undefined and $p=1$ by convention.}\n")
cat("\\end{table}\n\n")

cat("% ===== Tabla McNemar Sp =====\n")
cat("\\begin{table}[htbp]\n\\centering\\footnotesize\\setlength{\\tabcolsep}{4pt}\n")
cat("\\caption{McNemar Transition Matrices for Smell-Free Scripts ($Sp$), P0 vs.\\ P1 ($N=40$ per model)}\n")
cat("\\label{tab:mcnemar_sp}\n\\begin{tabular}{@{}lrrrrc@{}}\n\\toprule\n")
cat("\\textbf{Model} & \\textbf{a} & \\textbf{b} & \\textbf{c} & \\textbf{d} & \\textbf{$p$} \\\\\n\\midrule\n")
for (i in 1:nrow(resultados)) {
  r <- resultados[i, ]
  cat(sprintf("%s & %d & %d & %d & %d & %s \\\\\n",
              r$modelo, r$Sp_a, r$Sp_b, r$Sp_c, r$Sp_d, fmt_p(r$Sp_p)))
}
cat("\\bottomrule\n\\end{tabular}\n\n\\vspace{2pt}\n")
cat("{\\footnotesize $a$: smell-free under both; $b$: smell-free only under P0; $c$: smell-free only under P1; $d$: smells under both.}\n")
cat("\\end{table}\n")
sink()

cat("Tablas LaTeX guardadas en mcnemar_tablas_latex.txt\n")

# ---------- 5: Intervalos de confianza bootstrap (95%, percentil) ----------
# 10,000 remuestreos pareados por escenario, semilla fija para reproducibilidad.

set.seed(42)
B <- 10000

boot_ci <- function(delta) {
  n <- length(delta)
  medias <- replicate(B, mean(delta[sample.int(n, n, replace = TRUE)]))
  quantile(medias, c(0.025, 0.975))
}

cat("\n============ IC 95% bootstrap para Delta Sc_barra (P1 - P0) ============\n")
for (i in seq_along(MODELS)) {
  m <- MODELS[i]
  s0 <- leer_sc(m, "P0"); s1 <- leer_sc(m, "P1")
  comunes <- intersect(names(s0), names(s1))
  delta <- as.numeric(s1[comunes] - s0[comunes])
  ci <- boot_ci(delta)
  cat(sprintf("%-18s Delta = %+.3f   IC95%% [%+.3f, %+.3f]\n",
              LABELS[i], mean(delta), ci[1], ci[2]))
}

cat("\n============ IC 95% bootstrap para Delta pass@1 (P1 - P0) ============\n")
todos <- c()
for (i in seq_along(MODELS)) {
  m <- MODELS[i]
  f0 <- leer_fc(m, "P0"); f1 <- leer_fc(m, "P1")
  comunes <- intersect(names(f0), names(f1))
  delta <- as.numeric(f1[comunes] - f0[comunes])
  todos <- c(todos, delta)
  ci <- boot_ci(delta)
  cat(sprintf("%-18s Delta = %+.4f   IC95%% [%+.4f, %+.4f]\n",
              LABELS[i], mean(delta), ci[1], ci[2]))
}
ci <- boot_ci(todos)
cat(sprintf("%-18s Delta = %+.4f   IC95%% [%+.4f, %+.4f]\n",
            "POOLED (N=160)", mean(todos), ci[1], ci[2]))
