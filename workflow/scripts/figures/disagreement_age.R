#
# disagreement_age.R
#
# author: Dakota Murray
#
# Shows disagreement by age of the cited paper
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT <- 5.5
FIG.WIDTH <- 8.5

library(dplyr)
library(ggplot2)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing disagreement by gender data"),
  make_option(c("--facet"), action="store", default=NA, type="character",
              help="Whether to facet data, 'none', or 'filter'"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the data, originally sourced from the SQL server
age <- read_csv(opt$input, col_types = cols()) %>%
  mutate(
    share_disagreement = share_disagreement * 100,
    field = factor(LR_main_field,
                        levels = c("All publications",
                                   "Social sciences and humanities",
                                   "Biomedical and health sciences",
                                   "Life and earth sciences",
                                   "Physical sciences and engineering",
                                   "Mathematics and computer science"),
                        labels = c(field_long_labels())
                   ),
    filter_name = factor(filter_name, levels = filter_term_levels(), labels = filter_term_labels()),
    citation_window_bin = factor(citation_window_bin,
                                 levels = c("00-05", "05-09", "10-14", "15-19", "20+"),
                                 labels = c("00-04", "05-09", "10-14", "15-19", "20+"))
  )

# Check if the faceting option is set.
# If so, then limit to the necessary filter terms
if (opt$facet == "none") {
  age <- age %>% filter(filter_name == "Overall")
} else if (opt$facet == "filter") {
  age <- age %>% filter(filter_name != "Overall")
}

# Build the plot
#
# There are some extra calculations here because originally I had been calculated
# The ratio change between each pair of age bins, but this proved not very useful.
# Still, I think its a good idea to keep this code here should it become useful
# in the future
plot <- age %>%
  group_by(field, filter_name) %>%
  arrange(citation_window_bin) %>%
  mutate(
    change = share_disagreement - lag(share_disagreement),
    perc.change = (share_disagreement - lag(share_disagreement)) / share_disagreement,
    ratio = (share_disagreement) / lag(share_disagreement)
  ) %>%
  ggplot(aes(x = citation_window_bin, y = share_disagreement, group = field, fill = field, alpha = citation_window_bin)) +
  geom_bar(stat = "identity", color = "black") +
  geom_text(aes(y = 0, label = formatC(n_citations_disagreement, format = "d", big.mark = ",")),
            vjust = -0.5,
            size = 2.75,
            color = "black",
            alpha = 1) +
  scale_fill_manual(values = field_long_colors()) +
  scale_alpha_manual(values = c(0.2, 0.4, 0.6, 0.8, 1.0)) +
  scale_y_continuous(limits = c(0, NA),
                     expand = expand_scale(mult = c(0, .5)),
                     position = ifelse(opt$facet == "none", "left", "right")) +
  guides(alpha = F, fill = F) +
  theme_dakota() +
  theme(
    panel.grid.major.x = element_blank(),
    panel.border = element_rect(size = 0.5, fill = NA),
    legend.background = element_rect(size = 0.5, fill = "white"),
    legend.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(size = 14),
    strip.text.y.left = element_text(size = 14, angle = 0, hjust = 1)
  ) +
  xlab("Age of cited paper (years)") +
  ylab("% disagreement")

# Check the faceting variable again, and apply the appropriate
# faceting and themes
if (opt$facet == "none") {
  plot <- plot +
    facet_wrap(~field, scales = "free_y")
} else if (opt$facet == "filter") {
  plot <- plot +
    facet_grid(field~filter_name, scale = "free_y", switch = "y")

  FIG.HEIGHT <- 8
  FIG.WIDTH = 14
}


# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
