#
# aggregate_coded_sentences.r
#
# author: Dakota Murray
#
# Take all of the raw coded sentences, aggregate into a single file
#

library(readr)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type="character",
              help="Path to directory containing coded sentences"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Query each person's path in turn
# First get Kevin's sentences
cassidy <- list.files(paste0(opt$input, "/Cassidy/"), pattern = "\\.xlsx", full.name = T)

cassidy.list <- lapply(cassidy, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "cassidy",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})

# Get Dakota's sentences
dakota <- list.files(paste0(opt$input, "/Dakota/"), pattern = "\\.xlsx", full.name = T)

dakota.list <- lapply(dakota, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "dakota",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})


# Get Kevin's sentences
kevin <- list.files(paste0(opt$input, "/Kevin/"), pattern = "\\.xlsx", full.name = T)

kevin.list <- lapply(kevin, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "kevin",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    rename(code_1 = Boyack) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})

# Get Wout's sentences
wout <- list.files(paste0(opt$input, "/Wout/"), pattern = "\\.xlsx", full.name = T)

wout.list <- lapply(wout, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "wout",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})

# Get Vincent's sentences
vincent <- list.files(paste0(opt$input, "/Vincent/"), pattern = "\\.xlsx", full.name = T)

vincent.list <- lapply(vincent, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "vincent",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})

# Get Ludo's sentences
ludo <- list.files(paste0(opt$input, "/Ludo/"), pattern = "\\.xlsx", full.name = T)

ludo.list <- lapply(ludo, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "ludo",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})

# Get Nees' sentences
nees <- list.files(paste0(opt$input, "/Nees/"), pattern = "\\.xlsx", full.name = T)

nees.list <- lapply(nees, function(file) {
  xl <- readxl::read_excel(file) %>%
    mutate(coder = "nees",
           id = row_number(),
           signal_name = tolower(signal_name),
           filter_name = tolower(filter_name)) %>%
    arrange(fulltext_idx) %>%
    select(fulltext_idx, signal_name, filter_name, code_1, id, coder, text, doi)
})

# Combine all into a single dataframe
coded <- data.table::rbindlist(c(cassidy.list,
                                 dakota.list,
                                 kevin.list,
                                 wout.list,
                                 vincent.list,
                                 ludo.list,
                                 nees.list)) %>%
  rename(label = code_1) %>%
  mutate(label = ifelse(as.numeric(label) %in% c(0, 1), label, NA))

print(dim(coded))
# Construct the final dataframe
coded.final <- coded %>%
  group_by(fulltext_idx, signal_name, filter_name) %>%
  arrange(fulltext_idx, signal_name, filter_name, coder) %>%
  mutate(
    code1 = first(label),
    code2 = last(label),
    coder1 = first(coder),
    coder2 = last(coder)
  ) %>%
  slice(1) %>%
  select(fulltext_idx, signal_name, filter_name, code1, code2, coder1, coder2, text, doi) %>%
  filter(!is.na(code1) & !is.na(code2)) %>%
  ungroup() %>%
  # Now add a row index which will be used to filter the first n coded values
  group_by(signal_name, filter_name) %>%
  arrange(fulltext_idx) %>%
  mutate(
    index = row_number()
  ) %>%
  arrange(signal_name, filter_name, index)

# Some quereis were over-coded, meaning that more than 50 were coded. For
# the sake of consistency, we use only the first 50 coded results for each
# query and ignore the rest
#
# For example, if person A coded 60 and person B coded 75 sentences, then only
# the first 50 of each (as per the random order assigned from the qeury) would
# be kept for subsequent analysis
coded.final <- coded.final %>% filter(index <= 50)


# Save the data
readr::write_csv(coded.final, opt$output)
