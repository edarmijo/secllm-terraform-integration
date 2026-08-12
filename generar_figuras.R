# ======================================================================
# generar_figuras.R
#
# Genera las figuras del paper y el diagrama de metodologia a partir de
# research_iac/integration/outputs_v2. Soporta las dos "epocas" del
# experimento (N=40 exploratorio y N=80 confirmatorio) via el parametro
# N_SAMPLE de abajo — antes eran dos scripts casi identicos
# (generar_todo.R y generar_figuras_N80.R) con el codigo del diagrama
# duplicado; este los reemplaza a ambos.
#
# INSTRUCCIONES:
#   1. Abre este archivo en RStudio.
#   2. Session > Set Working Directory > To Source File Location
#      (o ejecuta setwd() apuntando a la raiz del repositorio)
#   3. install.packages(c("jsonlite","ggplot2"))   # solo la primera vez
#   4. Ajusta N_SAMPLE mas abajo (80 = version vigente, 40 = exploratoria)
#   5. source("generar_figuras.R")
#
# Salidas:
#   N_SAMPLE = 80 -> paper_entrega/figures/*.pdf (version vigente del paper)
#   N_SAMPLE = 40 -> figures/*.png (reproduccion de la corrida exploratoria)
#   diagrama/diagrama_metodologia.pdf  (ambos casos)
# ======================================================================

if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
if (!requireNamespace("ggplot2",  quietly = TRUE)) install.packages("ggplot2")
library(jsonlite)
library(ggplot2)

# ── fija directorio de trabajo a la raiz del repo ──────────────────────
if (requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

# ======================================================================
# CONFIGURACION: elegir la epoca del experimento
# ======================================================================
N_SAMPLE <- 80   # 80 = muestra confirmatoria vigente | 40 = exploratoria original
stopifnot(N_SAMPLE %in% c(40, 80))

RUTA <- "research_iac/integration/outputs_v2"
stopifnot(dir.exists(RUTA))  # si falla: Session > Set Working Directory > To Source File Location

if (N_SAMPLE == 80) {
  OUTDIR  <- "paper_entrega/figures"
  FORMATO <- "pdf"
} else {
  OUTDIR  <- "figures"
  FORMATO <- "png"
}
dir.create(OUTDIR,    showWarnings = FALSE, recursive = TRUE)
dir.create("diagrama", showWarnings = FALSE)

guardar <- function(nombre, plot, width, height) {
  archivo <- file.path(OUTDIR, paste0(nombre, ".", FORMATO))
  if (FORMATO == "png") {
    ggsave(archivo, plot, width = width, height = height, dpi = 300)
  } else {
    ggsave(archivo, plot, width = width, height = height)
  }
  cat("  ", archivo, "\n")
}

# ── modelos y etiquetas (orden fijo en todo el paper) ──────────────────
MODELOS   <- c("llama3_1_8b", "granite-code_8b", "codegemma_7b", "codellama_7b")
ETIQUETAS <- c("llama3.1\n8b", "granite-code\n8b", "codegemma\n7b", "codellama\n7b")

# ── colores y tema IEEE ─────────────────────────────────────────────────
COL_P0 <- "#4477AA"   # azul — paleta apta para daltonismo
COL_P1 <- "#EE6677"   # rojo

TEMA <- theme_minimal(base_family = "serif", base_size = 9) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "top",
    legend.title       = element_blank(),
    axis.title.x       = element_blank()
  )

# ── helpers de lectura ──────────────────────────────────────────────────
leer_iac <- function(model, cond)
  fromJSON(file.path(RUTA, model, cond, "iac_eval_results.json"))

leer_sec <- function(model, cond)
  fromJSON(file.path(RUTA, model, cond, "secllm_results.json"))

sc_vec <- function(sec_df) {
  files <- unique(sec_df$PATH)
  v <- sapply(files, function(f) sum(sec_df$SMELL[sec_df$PATH == f] != "none"))
  idx <- as.integer(sub("question_(\\d+)\\.tf", "\\1", files))
  setNames(v, idx)
}

is_offline <- function(err)
  grepl("AuthFailure", err) | (grepl("api error", err) & grepl("StatusCode", err))

# ── carga JSON de estadisticas agregadas ───────────────────────────────
rq2 <- fromJSON(file.path(RUTA, "stats_rq2.json"))
rq3 <- fromJSON(file.path(RUTA, "stats_rq3.json"))

cat("Generando figuras (N =", N_SAMPLE, ") en", OUTDIR, "...\n")

# ======================================================================
# FIGURA — pass@1 por modelo
# ======================================================================
d_pass <- data.frame(
  modelo    = factor(rep(ETIQUETAS, 2), levels = ETIQUETAS),
  condicion = rep(c("P0 (baseline)", "P1 (security-oriented)"), each = 4),
  pass1     = c(
    sapply(MODELOS, function(m) rq2[[m]]$Fc_rate_P0 * 100),
    sapply(MODELOS, function(m) rq2[[m]]$Fc_rate_P1 * 100)
  )
)

g_pass <- ggplot(d_pass, aes(modelo, pass1, fill = condicion)) +
  geom_col(position = position_dodge(0.8), width = 0.7,
           colour = "black", linewidth = 0.2) +
  geom_text(aes(label = sprintf("%.1f%%", pass1),
                y     = pmax(pass1, 1.0)),
            position = position_dodge(0.8), vjust = -0.35, size = 2.2,
            family = "serif") +
  scale_fill_manual(values = c(COL_P0, COL_P1)) +
  scale_y_continuous(limits = c(0, 21), expand = c(0, 0),
                     labels = function(x) paste0(x, "%")) +
  labs(y = sprintf("pass@1 (%%, N=%d per cell)", N_SAMPLE)) +
  TEMA
guardar("fig_pass1_by_model", g_pass, width = 3.5, height = 2.4)

# ======================================================================
# FIGURA — modos de fallo
# ======================================================================
fm_data <- lapply(seq_along(MODELOS), function(i) {
  m <- MODELOS[i]
  iac <- rbind(leer_iac(m, "P0"), leer_iac(m, "P1"))

  n_fc1 <- sum(iac$opa_evaluation_result == "Success")
  n_opa <- sum(iac$terraform_plan_success &
                 iac$opa_evaluation_result != "Success")
  n_off <- sum(!iac$terraform_plan_success &
                 is_offline(iac$terraform_plan_error))
  n_gen <- sum(!iac$terraform_plan_success &
                 !is_offline(iac$terraform_plan_error))

  data.frame(
    modelo  = ETIQUETAS[i],
    outcome = c("Functionally correct", "Intent (OPA) failure",
                "Genuine plan failure", "Offline artifact"),
    n       = c(n_fc1, n_opa, n_gen, n_off)
  )
})
d_fm <- do.call(rbind, fm_data)
d_fm$modelo  <- factor(d_fm$modelo,  levels = ETIQUETAS)
d_fm$outcome <- factor(d_fm$outcome,
                       levels = c("Offline artifact", "Functionally correct",
                                  "Intent (OPA) failure", "Genuine plan failure"))

g_fm <- ggplot(d_fm, aes(modelo, n, fill = outcome)) +
  geom_col(width = 0.65, colour = "black", linewidth = 0.2) +
  geom_text(aes(label = ifelse(n >= 10, as.character(n), "")),
            position = position_stack(vjust = 0.5),
            size = 2.3, family = "serif", colour = "white", fontface = "bold") +
  scale_fill_manual(values = c("#999999", "#66CCEE", "#CCBB44", "#AA3377")) +
  scale_y_continuous(limits = c(0, N_SAMPLE * 2.2), expand = c(0, 0)) +
  labs(y = sprintf("Scripts (P0+P1 pooled, n=%d per model)", N_SAMPLE * 2)) +
  TEMA +
  guides(fill = guide_legend(nrow = 2))
guardar("fig_failure_modes", g_fm, width = 3.5, height = 2.8)

# ======================================================================
# FIGURA — media Sc P0 vs P1
# ======================================================================
d_sc <- data.frame(
  modelo    = factor(rep(ETIQUETAS, 2), levels = ETIQUETAS),
  condicion = rep(c("P0 (baseline)", "P1 (security-oriented)"), each = 4),
  sc        = c(
    sapply(MODELOS, function(m) rq2[[m]]$Sc_mean_P0),
    sapply(MODELOS, function(m) rq2[[m]]$Sc_mean_P1)
  )
)

g_sc <- ggplot(d_sc, aes(modelo, sc, fill = condicion)) +
  geom_col(position = position_dodge(0.8), width = 0.7,
           colour = "black", linewidth = 0.2) +
  geom_text(aes(label = sprintf("%.3f", sc)),
            position = position_dodge(0.8), vjust = -0.35, size = 2.0,
            family = "serif") +
  scale_fill_manual(values = c(COL_P0, COL_P1)) +
  scale_y_continuous(limits = c(0, 2.3), expand = c(0, 0)) +
  labs(y = expression(bar(Sc) ~ "(mean smell count per script)")) +
  TEMA

if (N_SAMPLE == 80) {
  # significancia Holm (calculada por analisis_mcnemar.R / tests pareados)
  # llama p_holm=0.016*, granite p_holm=0.253, codegemma p_holm=0.045*, codellama p_holm=0.028*
  holm_sig <- c(TRUE, FALSE, TRUE, TRUE)   # orden: llama, granite, codegemma, codellama
  sig_labels <- data.frame(
    modelo = factor(ETIQUETAS, levels = ETIQUETAS),
    y      = sapply(MODELOS, function(m) rq2[[m]]$Sc_mean_P0) + 0.16,
    sig    = ifelse(holm_sig, "*", "")
  )
  g_sc <- g_sc +
    geom_text(data = sig_labels, aes(x = modelo, y = y, label = sig),
              inherit.aes = FALSE, size = 4.5, colour = "#CC3311") +
    annotate("text", x = 3.95, y = 2.2,
             label = "* p < 0.05 after Holm correction",
             size = 1.9, family = "serif", hjust = 1, colour = "#CC3311")
}
guardar("fig_sc_p0_p1", g_sc, width = 3.5, height = 2.6)

# ======================================================================
# FIGURA — transiciones de Sc por escenario (Sc(P1) - Sc(P0))
# ======================================================================
trans_data <- lapply(seq_along(MODELOS), function(i) {
  m   <- MODELOS[i]
  sc0 <- sc_vec(leer_sec(m, "P0"))
  sc1 <- sc_vec(leer_sec(m, "P1"))
  ids <- intersect(names(sc0), names(sc1))
  delta <- sc1[ids] - sc0[ids]
  cat_d <- ifelse(delta < 0, "Improved (P1 < P0)",
            ifelse(delta > 0, "Worsened (P1 > P0)", "Unchanged"))
  data.frame(modelo = ETIQUETAS[i], scenario = as.integer(ids),
             delta = delta, categoria = cat_d)
})
d_trans <- do.call(rbind, trans_data)
d_trans$modelo    <- factor(d_trans$modelo, levels = ETIQUETAS)
d_trans$categoria <- factor(d_trans$categoria,
                             levels = c("Improved (P1 < P0)", "Unchanged",
                                        "Worsened (P1 > P0)"))

g_trans <- ggplot(d_trans, aes(x = delta, fill = categoria)) +
  geom_histogram(binwidth = 1, colour = "black", linewidth = 0.15,
                 position = "identity", alpha = 0.85) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40",
             linewidth = 0.4) +
  facet_wrap(~ modelo, nrow = 1) +
  scale_fill_manual(values = c("#66CCEE", "#DDDDDD", "#EE6677")) +
  scale_x_continuous(breaks = seq(-6, 4, 2)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.13))) +
  labs(x = expression(Delta * Sc ~ "(P1 - P0, per scenario)"),
       y = "Number of scenarios") +
  theme_minimal(base_family = "serif", base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position  = "top",
    legend.title     = element_blank(),
    strip.text       = element_text(family = "serif", size = 7.5),
    panel.spacing    = unit(0.4, "lines")
  )
guardar("fig_transitions_sc", g_trans, width = 7.0, height = 2.6)

# ======================================================================
# FIGURA — smells detectados en scripts Fc=1 (P0)
# ======================================================================
n_fc1_p0 <- sum(sapply(MODELOS, function(m)
  sum(leer_iac(m, "P0")$opa_evaluation_result == "Success")))

dist <- rq3$smell_distribution_fc1
etiq_smells <- c(
  admin_by_default   = "Admin by Default",
  hard_coded_secret  = "Hard-coded Secret",
  suspicious_comment = "Suspicious Comment"
)
d_smells <- data.frame(
  smell = etiq_smells[names(dist)],
  n     = as.integer(unlist(dist))
)
d_smells$smell <- reorder(d_smells$smell, d_smells$n)

g_smells <- ggplot(d_smells, aes(n, smell)) +
  geom_col(fill = COL_P0, colour = "black", linewidth = 0.2, width = 0.55) +
  geom_text(aes(label = n), hjust = -0.3, size = 2.6, family = "serif") +
  scale_x_continuous(limits = c(0, max(d_smells$n) + 3), expand = c(0, 0)) +
  labs(x = sprintf("Detections in Fc=1 scripts (P0 condition, n=%d scripts)", n_fc1_p0),
       y = NULL) +
  theme_minimal(base_family = "serif", base_size = 9) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank())
guardar("fig_smells_fc1", g_smells, width = 3.5, height = 1.8)

# ======================================================================
# DIAGRAMA DE METODOLOGIA — diagrama/diagrama_metodologia.pdf
# ======================================================================
cat("Generando diagrama/diagrama_metodologia.pdf ...\n")

caja <- function(x, y, w, h, titulo, cuerpo, fill) {
  list(
    annotate("rect", xmin = x - w/2, xmax = x + w/2, ymin = y - h/2, ymax = y + h/2,
             fill = fill, colour = "grey25", linewidth = 0.35),
    annotate("text", x = x, y = y + h/2 - 0.32, label = titulo,
             family = "serif", fontface = "bold", size = 3.1),
    annotate("text", x = x, y = y - 0.2, label = cuerpo,
             family = "serif", size = 2.5, lineheight = 0.95)
  )
}
flecha <- function(x, y1, y2)
  annotate("segment", x = x, xend = x, y = y1, yend = y2,
           linewidth = 0.4, colour = "grey25",
           arrow = arrow(length = unit(1.6, "mm"), type = "closed"))

# descripcion de la muestra estratificada: constante de diseno por epoca,
# no se puede derivar de N_SAMPLE solo
muestreo_txt <- if (N_SAMPLE == 80) {
  paste0("Two-stage stratified sample N = 80 (seed=42, n1=40; seed=43, n2=40),\n",
         "allocation {1:8, 2:16, 3:20, 4:10, 5:12, 6:14} — offline evaluation")
} else {
  paste0("Stratified random sample N = 40 (seed = 42),\n",
         "allocation {1:4, 2:8, 3:10, 4:5, 5:6, 6:7} — offline evaluation")
}
total_obs   <- N_SAMPLE * 2 * 4        # N x prompts(P0,P1) x modelos
audit_calls <- N_SAMPLE * 2 * 4 * 8    # + reglas de smell (8)

W <- 11; H <- 2.6; X <- 5
ys <- seq(14.4, by = -(H + 0.55), length.out = 5)

p_diag <- ggplot() +
  caja(X, ys[1], W, H, "A. Experimental Design",
       paste0("Factors: Model M (llama3.1:8b, granite-code:8b, codegemma:7b, codellama:7b)\n",
              "× Prompt P (P0 baseline, P1 security-oriented) — within-subjects\n",
              sprintf("Metrics: Fc (pass@1), Sp, Sc, St — 4 × 2 × %d = %d observations",
                      N_SAMPLE, total_obs)),
       "#EAF2F8") +
  caja(X, ys[2], W, H, "B. Dataset Preparation and Sampling",
       paste0("IaC-Eval benchmark (458 scenarios, AWS, 6 difficulty levels)\n", muestreo_txt),
       "#E8F6EF") +
  caja(X, ys[3], W, H, "C. Code Generation and Functional Evaluation",
       paste0("Ollama (temp = 0.2), HCL extraction, context purged per task\n",
              "terraform init/plan (technical) + OPA/Rego (intent) -> Fc per script\n",
              sprintf("Failure-mode categorization (%d scripts)", total_obs)),
       "#FDF2E9") +
  caja(X, ys[4], W, H, "D. Security Auditing",
       paste0("SecLLM adapted to Terraform/HCL — 8 smell rules (CWE-mapped)\n",
              "Common external auditor: qwen2.5-coder:7b (temp = 0.0)\n",
              sprintf("-> Sp, Sc, St per script (%s audit calls)",
                      formatC(audit_calls, big.mark = ","))),
       "#F4ECF7") +
  caja(X, ys[5], W, H, "E. Statistical Analysis",
       paste0(sprintf("RQ1: Spearman rho / Kendall tau (Fc-Sc, N=%d/model), ", N_SAMPLE),
              sprintf("RQ2: paired Wilcoxon (Sc, N=%d),\n", N_SAMPLE),
              "exact McNemar (Fc, Sp), RQ3: descriptive on Fc=1\n",
              "Holm-Bonferroni (confirmatory), Benjamini-Hochberg (exploratory)"),
       "#FDEDEC")

for (i in 1:4)
  p_diag <- p_diag + flecha(X, ys[i] - H/2, ys[i + 1] + H/2 + 0.06)

p_diag <- p_diag +
  coord_cartesian(xlim = c(-0.6, 10.6), ylim = c(-0.4, 16), expand = FALSE) +
  theme_void()

ggsave("diagrama/diagrama_metodologia.pdf", p_diag, width = 7.0, height = 4.6)

# ======================================================================
cat("\n=== LISTO ===\n")
cat("Figuras generadas en", OUTDIR, "\n")
cat("Diagrama: diagrama/diagrama_metodologia.pdf\n")
