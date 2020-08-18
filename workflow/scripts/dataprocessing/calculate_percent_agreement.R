#
# calculate_percent_agreement.R
#
# author: Dakota Murray
#
# Take all of the raw coded sentences, aggregate into a single file
#

library(readr)
library(tidyr)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type="character",
              help="Path to file containing coded sentences"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the dataset
coded.final <- readr::read_csv(opt$input, col_types = readr::cols())

agreement = coded.final %>%
  group_by(signal_name, filter_name) %>%
  summarize(
    # Calculate the percent agreement
    agreement = sum(code1 == code2) / n() * 100,
    # Calculate the validity
    validity = sum(code1 == 1 & code2 == 1) / n() * 100
  ) %>%
  ungroup() %>%
  gather(type, value, agreement, validity)

# Calculate the mean values across signal and
# filter terms
mean.signal <- agreement %>%
  group_by(type, signal_name) %>%
  summarize(
    filter_name = "AVERAGE",
    value = mean(value)
  )

mean.filter <- agreement %>%
  group_by(type, filter_name) %>%
  summarize(
    signal_name = "AVERAGE",
    value = mean(value)
  )

# Merge into a single dataframe
agreement.all <- data.table::rbindlist(list(agreement,
                                            mean.signal,
                                            mean.filter),
                                       use.names = T)

# Save the data
readr::write_csv(agreement.all, opt$output)
