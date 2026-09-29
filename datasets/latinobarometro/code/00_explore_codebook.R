# ============================================================================
# Latinobarometro Exploration Script
# Purpose: Build searchable codebook, compare waves, map thematic variables
# ============================================================================

library(here)
library(tidyverse)
library(haven)
library(sjlabelled)
library(openxlsx)

# --- Configuration ------------------------------------------------------------
DATA_DIR <- here("latinobarometro")
OUTPUT_DIR <- here("latinobarometro", "output")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

FILES <- list(
  y2015 = file.path(DATA_DIR, "Latinobarometro_2015_Eng.sav"),
  y2023 = file.path(DATA_DIR, "Latinobarometro_2023_Eng_Spss_v1_0.sav")
)

COUNTRY_CODES <- c(
  `32` = "Argentina", `68` = "Bolivia", `76` = "Brazil", `152` = "Chile",
  `170` = "Colombia", `188` = "Costa Rica", `214` = "Dominican Rep.",
  `218` = "Ecuador", `222` = "El Salvador", `320` = "Guatemala",
  `340` = "Honduras", `484` = "Mexico", `558` = "Nicaragua",
  `591` = "Panama", `600` = "Paraguay", `604` = "Peru",
  `858` = "Uruguay", `862` = "Venezuela"
)

# --- Helper: extract codebook from a haven-labelled tibble --------------------
build_codebook <- function(df, wave_name) {
  vars <- names(df)
  
  out <- map_dfr(vars, function(v) {
    x <- df[[v]]
    lab <- attr(x, "label")
    if (is.null(lab)) lab <- NA_character_
    
    val_labs <- attr(x, "labels")
    if (!is.null(val_labs)) {
      val_lab_str <- paste(
        paste(val_labs, names(val_labs), sep = " = "),
        collapse = " | "
      )
    } else {
      val_lab_str <- NA_character_
    }
    
    tibble(
      wave = wave_name,
      variable = v,
      label = lab,
      type = class(x)[1],
      n_distinct = length(unique(x)),
      n_miss = sum(is.na(x)),
      value_labels = val_lab_str
    )
  })
  out
}

# --- Load data ----------------------------------------------------------------
cat("Loading waves...\n")
df_2015 <- read_sav(FILES$y2015)
df_2023 <- read_sav(FILES$y2023)

cat("2015:", nrow(df_2015), "rows x", ncol(df_2015), "cols\n")
cat("2023:", nrow(df_2023), "rows x", ncol(df_2023), "cols\n")

# --- Quick country summary ----------------------------------------------------
country_summary <- bind_rows(
  df_2015 %>% count(IDENPA, name = "n_2015"),
  df_2023 %>% count(IDENPA, name = "n_2023")
) %>%
  mutate(
    country = COUNTRY_CODES[as.character(IDENPA)],
    .after = IDENPA
  ) %>%
  arrange(IDENPA)

print(country_summary)

# --- Build codebooks ----------------------------------------------------------
cb_2015 <- build_codebook(df_2015, "2015")
cb_2023 <- build_codebook(df_2023, "2023")

codebook_all <- bind_rows(cb_2015, cb_2023)

# --- Cross-wave variable comparison -------------------------------------------
variable_comparison <- full_join(
  cb_2015 %>% select(variable, label, value_labels),
  cb_2023 %>% select(variable, label, value_labels),
  by = "variable",
  suffix = c("_2015", "_2023")
) %>%
  mutate(
    in_2015 = !is.na(label_2015),
    in_2023 = !is.na(label_2023),
    in_both = in_2015 & in_2023,
    label_changed = in_both & (label_2015 != label_2023),
    values_changed = in_both & (value_labels_2015 != value_labels_2023)
  )

cat("\nVariable overlap:\n")
cat("  Only 2015:", sum(variable_comparison$in_2015 & !variable_comparison$in_2023), "\n")
cat("  Only 2023:", sum(variable_comparison$in_2023 & !variable_comparison$in_2015), "\n")
cat("  Both waves:", sum(variable_comparison$in_both), "\n")
cat("  Labels changed (both waves):", sum(variable_comparison$label_changed, na.rm = TRUE), "\n")

# --- Thematic keyword search --------------------------------------------------
# These are heuristic keywords to help you browse by topic.
# Run this section, then open the Excel output and filter by theme.

theme_keywords <- list(
  democracy = c("democra", "gobierno", "government", "satis", "satisfied",
                "autorita", "dictad", "authorit", "regimen", "regime"),
  economy = c("econom", "econo", "situac", "situation", "personal",
              "pais", "country", "ingreso", "income", "trabajo", "work"),
  trust = c("confianza", "trust", "confia", "instituc", "instit"),
  corruption = c("corrupt", "corrupc", "soborn", "bribe"),
  vote = c("voto", "vote", "elec", "partido", "party", "politico", "politic"),
  media = c("medios", "media", "period", "newspaper", "radio", "tv", "internet"),
  social = c("religion", "religio", "dios", "god", "mujer", "woman", "hombre",
             "man", "toleran", "toleran", "homosex", "gay"),
  identity = c("nacional", "national", "orgullo", "proud", "identid", "identity")
)

add_themes <- function(cb) {
  cb %>%
    mutate(
      theme = map_chr(label, function(lab) {
        if (is.na(lab)) return(NA_character_)
        lab_lower <- str_to_lower(lab)
        matches <- map_lgl(theme_keywords, function(kws) {
          any(str_detect(lab_lower, kws))
        })
        if (!any(matches)) return(NA_character_)
        paste(names(theme_keywords)[matches], collapse = "; ")
      })
    )
}

cb_2015_themed <- add_themes(cb_2015)
cb_2023_themed <- add_themes(cb_2023)

# --- Export to Excel (multi-sheet workbook) -----------------------------------
wb <- createWorkbook()

addWorksheet(wb, "variable_comparison")
writeData(wb, "variable_comparison", variable_comparison)

addWorksheet(wb, "codebook_2015")
writeData(wb, "codebook_2015", cb_2015_themed)

addWorksheet(wb, "codebook_2023")
writeData(wb, "codebook_2023", cb_2023_themed)

addWorksheet(wb, "country_summary")
writeData(wb, "country_summary", country_summary)

addWorksheet(wb, "both_waves_vars")
writeData(wb, "both_waves_vars", filter(variable_comparison, in_both == TRUE))

saveWorkbook(wb, file.path(OUTPUT_DIR, "latinobarometro_codebook.xlsx"), overwrite = TRUE)

cat("\nExcel codebook saved to:", file.path(OUTPUT_DIR, "latinobarometro_codebook.xlsx"), "\n")

# --- Print sample of themed variables -----------------------------------------
cat("\n--- Sample themed variables (2023) ---\n")
cb_2023_themed %>%
  filter(!is.na(theme)) %>%
  select(variable, label, theme) %>%
  slice_sample(n = 20) %>%
  print(n = 20)

# --- Save R objects for downstream analysis -----------------------------------
save(df_2015, df_2023, cb_2015_themed, cb_2023_themed, variable_comparison,
     file = file.path(OUTPUT_DIR, "latinobarometro_exploration.RData"))

cat("\nDone. Open the Excel file and use filters to browse variables by theme.\n")
