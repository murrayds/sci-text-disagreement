#
# disagreement_selfcitation.R
#
# author: Dakota Murray
#
# barchart showing differences in disagreement between
# self-citation and non-self citation
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT <- 6
FIG.WIDTH <- 8

# Controls how far the "arrow" is from the top and bottom of
# each bar
upper.arrow.weight <- 0.99
lower.arrow.weight <- 1.06


library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing disagreement by gender data"),
  make_option(c("--facet"), action="store", default=NA, type="character",
              help="Whether to facet data, 'none', or 'filter'"),
  make_option(c("--validity"), action="store", default=NA, type="integer",
              help="Validity threshold to use"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the data on self-citation (sourced from separate SQL queries)
selfcite <- read_csv(opt$input, col_types = cols()) %>%
filter(threshold == opt$validity) %>%
  mutate(
    share_disagreement = share_disagreement * 100,
    field = factor(LR_main_field,
                   levels = c("All publications",
                              "Social sciences and humanities",
                              "Biomedical and health sciences",
                              "Life and earth sciences",
                              "Physical sciences and engineering",
                              "Mathematics and computer science"),
                  labels = field_long_labels()
                   ),
    self_cit = ifelse(self_cit == 0, "Not self citation", "Self citation"),
    filter_name = factor(filter_name,
                         levels = filter_term_levels(),
                         labels = filter_term_labels())
  )

# if the faceting option is set, then filter to the apprioriate data
if (opt$facet == "none") {
  selfcite <- selfcite %>%
    filter(filter_name == "Overall")
} else if (opt$facet == "filter") {
  # Do nothing for now
}

# Calculate the ratio of change between the share of disagreement
# in the self-citation and non-self-citation
change <- selfcite %>%
  select(filter_name, field, share_disagreement, self_cit) %>%
  spread(self_cit, share_disagreement) %>%
  mutate(
    `Not self citation` = `Not self citation`,
    `Self citation` = `Self citation`,
    perc.change = (`Not self citation` - `Self citation`) / abs(`Self citation`),
    ratio = `Not self citation` / `Self citation`
  )

# Build the plot, use the code from `snippets.R`
plot <- selfcite %>%
  ggplot(aes(x = self_cit, y = share_disagreement,
             fill = field, alpha = self_cit, shape = self_cit)) +
  geom_bar(stat = "identity",
           color = "black",
           position = position_dodge(width = 0.9)) +
  geom_point(position = position_dodge(0.9), size = NA, alpha = 1, aes(group = self_cit)) +
  geom_text(position = position_dodge(width = 0.9),
            aes(label = formatC(n_citations_disagreement, format = "d", big.mark = ","),
                y = 0,
                group = self_cit),
            vjust = -0.5,
            alpha = 1,
            size = 3
  ) +
  facet_wrap(~field, scales = "free") +
  scale_shape_manual(values = c(22, 0)) +
  scale_fill_manual(values = field_long_colors()) +
  scale_alpha_manual(values = c(0.9, 0.4)) +
  scale_y_continuous(
    limits = c(0, NA),
    expand = expand_scale(mult = c(0.05, .3)),
    position = ifelse(opt$facet == "none", "left", "right")
  ) +
  guides(alpha = F, fill = F,
         shape = guide_legend(override.aes = list(fill = "darkgrey", size = 5))
  ) +
  theme_dakota() +
  theme(
    panel.border = element_rect(size = 0.5, fill = NA),
    panel.grid.major.x = element_blank(),
    legend.background = element_rect(size = 0.5, fill = "white"),
    legend.title = element_blank(),
    axis.title.x = element_blank(),
    legend.position = "none",
    axis.text.x = element_text(face = "bold"),
    strip.text = element_text(size = 14),
    strip.text.y.left = element_text(size = 14, angle = 0, hjust = 1)
  ) +
  ylab("% disagreement")

# Check faceting again, if set, then add the facet_wrap
if (opt$facet == "none") {
  plot <- plot +
    # Add the "arrow" between the bars that helps to highlight
    # the ratio difference
    geom_segment(data = change,
                 aes(x = 2, xend = 2,
                     y = `Not self citation` * upper.arrow.weight, yend = `Self citation` * lower.arrow.weight,
                     group = NULL, shape = NULL, alpha = NULL),
                 size = 0.5,
                 color = "darkgrey",
                 arrow = arrow(length=unit(0.20, "cm"), ends="both", type = "closed")) +
    # Add the labels that will show the ratio difference, positioned in the
    # middle of the "arrow"
    geom_label(data = change,
                aes(x = 2,
                    y = `Self citation` * lower.arrow.weight + (0.5 * (`Not self citation` * upper.arrow.weight - `Self citation` * lower.arrow.weight)),
                    group = NULL, shape = NULL, alpha = NULL, fill = NULL,
                    label = paste0(round(ratio, 1), "x")),
               size = 4,
               label.size = 0
    )
} else if (opt$facet == "filter") {
  plot <- plot +
    geom_label(data = change,
                aes(x = 2,
                    y = `Self citation`,
                    group = NULL, shape = NULL, alpha = NULL, fill = NULL,
                    label = paste0(round(ratio, 1), "x")),
                  size = 4,
                  vjust = -0.8,
                label.size = 0
    ) +
    facet_grid(filter_name~field, scale = "free", switch = "y") +
    theme(
      axis.text.x = element_text(face = "bold", angle = 45, hjust = 1),
    )

    FIG.WIDTH <- 12
    FIG.HEIGHT <- 8
}

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
