#
# process_vosviewer_mapdata.R
#
# author: Dakota Murray
#
# Process the vosviewer map data, converting into a better and
# easier-to-work with format
#

library(readr)
library(tidyr)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Used to clean tags from the string
cleanFun <- function(htmlString) {
  return(gsub("<.*?>", "", htmlString))
}

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type="character",
              help="Path to file containing vosviewer-style map data"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the map file
map <- read_delim(opt$input, col_types = cols(), delim = "\t")

# Select the top journals per meso-field
map <- map %>%
  rowwise() %>%
  mutate(
    # Remove the tags separating items in the description
    journals = unlist(strsplit(cleanFun(description), ":"))[4],
    # Get the first three journals represented in the data
    select.journal = paste0(unlist(strsplit(journals, ";")), collapse = ";"),
    # Abbreviate common terms in the journal
    select.journal = gsub("journal", "j.", select.journal, fixed = T),
    select.journal = gsub("review", "rev.", select.journal, fixed = T),
    select.journal = gsub("proceedings", "proc.", select.journal, fixed = T),
    # Generate the final label
    lab = paste0(strwrap(select.journal, width = 36), collapse = "\n")
)

# Now calculate the main scores
map <- map %>%
  ungroup() %>%
  mutate(
    # Ratio of the share of disagreement in each meso-field given
    # average across all fields
    score.all = `weight<Share results 00: valid queries>` /
                  mean(`weight<Share results 00: valid queries>`, na.rm = T),
  ) %>%
  group_by(cluster) %>%
  mutate(
    # Same ratio, but comparing only within the main field
    score.field = `weight<Share results 00: valid queries>` /
                    mean(`weight<Share results 00: valid queries>`, na.rm = T),
  )

# Save the data
write_csv(map, opt$output)
