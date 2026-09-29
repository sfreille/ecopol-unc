library(here)
library(haven)
library(tidyverse)

project_dir <- here()
output_dir <- here("output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

wave_files <- tribble(
  ~wave, ~file,
  1995, "Latinobarometro_1995_data_english_spss_v2014_06_27.sav",
  1996, "Latinobarometro_1996_datos_english_spss_v2014_06_27.sav",
  1997, "Latinobarometro_1997_datos_english_spss_v2014_06_27.sav",
  1998, "Latinobarometro_1998_datos_english_v2014_06_27.sav",
  2000, "Latinobarometro_2000_datos_eng_v2014_06_27.sav",
  2001, "Latinobarometro_2001_datos_english_v2014_06_27.sav",
  2002, "Latinobarometro_2002_datos_eng_v2014_06_27.sav",
  2003, "Latinobarometro_2003_datos_eng_v2014_06_27.sav",
  2004, "Latinobarometro_2004_datos_eng_v2014_06_27.sav",
  2005, "Latinobarometro_2005_datos_eng_v2014_06_27.sav",
  2006, "Latinobarometro_2006_datos_eng_v2014_06_27.sav",
  2007, "Latinobarometro_2007_datos_eng_v2014_06_27.sav",
  2008, "Latinobarometro_2008_datos_eng_v2014_06_27.sav",
  2009, "Latinobarometro_2009_datos_eng_v2014_06_27.sav",
  2010, "Latinobarometro_2010_datos_eng_v2014_06_27.sav",
  2011, "Latinobarometro_2011_eng.sav",
  2013, "Latinobarometro2013Eng.sav",
  2015, "Latinobarometro_2015_Eng.sav",
  2016, "Latinobarometro2016Eng_v20170205.sav",
  2017, "Latinobarometro2017Eng_v20180117.sav",
  2018, "Latinobarometro_2018_Eng_Spss_v20190303.sav",
  2020, "Latinobarometro_2020_Eng_Spss_v1_0.sav",
  2023, "Latinobarometro_2023_Eng_Spss_v1_0.sav"
) %>% mutate(path = file.path(project_dir, file))

normalize_text <- function(x) {
  x %>%
    replace_na("") %>%
    iconv(to = "ASCII//TRANSLIT") %>%
    str_to_lower() %>%
    str_replace_all("^[[:space:]]*(p|q|pregunta|question)?[[:space:]]*[0-9]+[a-z]?([._-][0-9a-z]+)*[).:_ -]*", "") %>%
    str_replace_all("[^a-z0-9]+", " ") %>%
    str_squish()
}

themes <- list(
  polarization = c("left right", "ideolog", "political scale", "extrem", "division", "polariz", "party closeness", "vote for"),
  corruption = c("corrupt", "bribe", "bribery", "dishonest", "transparen"),
  meritocracy = c("merit", "effort", "hard work", "connections", "family background", "equal opportun", "success in life", "social mobility"),
  tax_tolerance = c("tax", "taxes", "fiscal", "evad", "pay more", "public services"),
  interpersonal_trust = c("most people", "people can be trusted", "interpersonal trust", "trust other people"),
  democracy = c("democra", "authoritarian", "dictatorship", "military government", "satisfaction with democracy"),
  institutional_confidence = c("confidence in", "trust in", "institution", "congress", "parliament", "judiciary", "political parties", "armed forces", "police"),
  ideology = c("left right", "ideolog", "socialism", "capitalism", "market economy", "private enterprise", "state ownership", "political scale")
)

tag_themes <- function(text) {
  map_chr(text, function(item) {
    hits <- names(keep(themes, ~ any(str_detect(item, fixed(.x)))))
    if (length(hits) == 0) NA_character_ else paste(hits, collapse = "; ")
  })
}

extract_wave <- function(wave, path) {
  message("Reading ", wave, ": ", basename(path))
  dat <- read_sav(path)
  cb <- map_dfr(names(dat), function(variable) {
    x <- dat[[variable]]
    label <- attr(x, "label") %||% ""
    value_labels <- attr(x, "labels")
    value_text <- if (is.null(value_labels)) "" else {
      paste(paste(unname(value_labels), names(value_labels), sep = "="), collapse = " | ")
    }
    tibble(
      wave = wave,
      variable = variable,
      label = as.character(label),
      normalized_label = normalize_text(as.character(label)),
      value_labels = value_text,
      storage_type = class(x)[1],
      n_distinct = n_distinct(x, na.rm = TRUE),
      missing_share = mean(is.na(x))
    )
  }) %>% mutate(theme = tag_themes(paste(normalized_label, normalize_text(variable))))

  possible_country <- cb %>%
    filter(str_detect(str_to_lower(paste(variable, label)), "idenpa|country|pais")) %>%
    pull(variable) %>% first()
  countries <- if (!is.na(possible_country) && length(possible_country) == 1) {
    n_distinct(dat[[possible_country]], na.rm = TRUE)
  } else NA_integer_

  weight_vars <- cb %>%
    filter(str_detect(str_to_lower(paste(variable, label)), "weight|ponder|factor de ponder")) %>%
    pull(variable) %>% paste(collapse = "; ")

  list(
    inventory = cb,
    wave = tibble(
      wave = wave, observations = nrow(dat), variables = ncol(dat),
      countries = countries, country_variable = possible_country %||% NA_character_,
      weight_variables = weight_vars, file = basename(path)
    )
  )
}

results <- map2(wave_files$wave, wave_files$path, extract_wave)
variable_inventory <- map_dfr(results, "inventory")
wave_inventory <- map_dfr(results, "wave")

continuity <- variable_inventory %>%
  filter(normalized_label != "") %>%
  group_by(normalized_label) %>%
  summarise(
    label_example = first(label),
    first_wave = min(wave), last_wave = max(wave),
    n_waves = n_distinct(wave),
    waves = paste(sort(unique(wave)), collapse = ", "),
    variable_names = paste(sort(unique(variable)), collapse = "; "),
    response_schemes = n_distinct(value_labels),
    themes = paste(sort(unique(na.omit(unlist(str_split(theme, "; "))))), collapse = "; "),
    .groups = "drop"
  ) %>% arrange(desc(n_waves), normalized_label)

thematic_inventory <- variable_inventory %>%
  filter(!is.na(theme)) %>%
  arrange(theme, normalized_label, wave)

write_csv(wave_inventory, file.path(output_dir, "wave_inventory.csv"), na = "")
write_csv(variable_inventory, file.path(output_dir, "variable_inventory.csv"), na = "")
write_csv(continuity, file.path(output_dir, "exact_wording_continuity.csv"), na = "")
write_csv(thematic_inventory, file.path(output_dir, "thematic_inventory.csv"), na = "")

message("Wrote inventories to ", output_dir)
