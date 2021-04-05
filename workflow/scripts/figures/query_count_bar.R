#
# query_count_bar.R
#
# author: Dakota Murray
#
# Plot a vertical, and very thin barchart that will sit
# next to the representation plot
#
source("scripts/figures/themes.R")

FIG.WIDTH = 1.5
FIG.HEIGHT = 11

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing coded sentences"),
  make_option(c("--counts"), action="store", default=NA, type='character',
              help="Path to file containing query counts"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the dataset
agreement <- read_csv(opt$input, col_types = cols()) %>%
  filter(signal_name != "AVERAGE") %>%
  filter(filter_name != "AVERAGE") %>%
  filter(type == "validity") # Limit to validity to order

# Load the counts of citances returned by each query
counts <- read_csv(opt$counts, col_types = cols())

print(head(agreement))
# Build the plotdata from the agreement data. While we don't
# actually plot this information, we need to arrange the bars
# to match the validity plot
plotdata <- agreement %>%
  left_join(counts, by = c("signal_name", "filter_name")) %>%
  mutate(
    filter_name = ifelse(filter_name == "standalone", "", paste0("+", filter_name)),
  ) %>%
  unite(query, c("signal_name", "filter_name"), sep = " ") %>%
  spread(type, value) %>%
  mutate(
    query = factor(query),
    query = reorder(query, (validity))
  ) %>%
  arrange(desc(query)) %>%
  mutate(
    prop = All / sum(All),
    cumulative = cumsum(All) / sum(All) * 100
  )

#
# labels <- plotdata %>%
#   filter(row_number() %in% c(10, 20, 30, 40,  50, 60)) %>%
#   mutate(text = paste0(round(cumulative, 1), "%"))


plot <- plotdata %>%
  ggplot(aes(x = query, y = log10(All), group = 1, fill = log10(All))) +
  geom_bar(stat = "identity") +
  coord_flip() +
  # geom_text(data = labels,
  #           aes(label = text, y = cumulative + 20)
  #           ) +
  scale_x_discrete(breaks = c(5, 10)) +
  scale_y_continuous(
    limits = c(0, 7),
    breaks = c(1, 7),
    expand = c(0, 0),
    labels = function(x) { parse(text=paste0("10^", x)) },
  ) +
  scale_fill_gradient(name = "# Citances ",
                       low = "#dfe6e9", high = "#2d3436",
                       breaks = c(2, 4, 6),
                       labels = function(x) { parse(text=paste0("10^", x)) },
                       limits = c(1, 7)) +
  guides(fill = F) +
  theme_dakota() +
  theme(
    axis.title.y = element_blank(),
    panel.grid = element_blank(),
    axis.text.y = element_blank(),
    axis.text.x = element_text(hjust = 1),
    axis.line = element_line(colour = "black", size = 0.25)
  ) +
  ylab("# Citances")

# save the output
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
