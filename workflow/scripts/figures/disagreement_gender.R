#
# disagreement_gender.R
#
# author: Dakota Murray
#
# Plots a barchoart of the gender differences in disagreement
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT <- 6
FIG.WIDTH <- 5

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing disagreement by gender data"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the gender data (obtained from the SQL server) and
# filter to the appropriate validity threshold, citation sentence
# type, and measure.
gender <- read_csv(opt$input, col_types = cols()) %>%
  filter(type == "citances") %>%
  filter(threshold == 80)

#
# The code here is a little messy, but basically we need two seaprate
# dataframes, one for the 'count', and the other for the share of disagreement
counts <- gender %>%
  filter(measure == "n_citances_valid") %>%
  gather(key, n_intext, F1, F2, M1, M2)

# Now, the second (disagreement) data frame
disagreement <- gender %>%
  filter(measure == "perc_citances_valid") %>%
  gather(key, perc_intext, F1, F2, M1, M2) %>%
  left_join(counts, by = c("LR_main_field", "key")) %>%
  mutate(
    key = recode(key,
                 'F1' = 'female first',
                 'F2' = 'female last',
                 'M1' = 'male first',
                 'M2' = 'male last'
    ),
    perc_intext = perc_intext * 100
  ) %>%
  separate(key,  into = c("gender", "authorship")) %>%
  mutate(
    authorship = recode(authorship,
                        "first" = "First Author",
                        "last" = "Last Author"),
    field = factor(LR_main_field, levels = field_long_levels()),
    field = factor(field, labels = field_long_labels()),
    gender = factor(gender, levels = c("male", "female"), labels = c("men", "women"))
  ) %>%
  filter(field != "All") %>%
  group_by(authorship, field) %>%
  mutate(
    # Calculate the ratio of the share of disagreement between
    # the genders
    ratio = lag(perc_intext) / (perc_intext)
  )

# Build the plot
plot <- disagreement %>%
  ggplot(aes(x = gender, y = perc_intext, fill = field, group = interaction(authorship, field))) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", aes(alpha = gender)) +
  geom_text(aes(label = ifelse(is.na(ratio), NA, paste0(sprintf("%.2f", round(ratio, 2)), "x"))),
            position = position_dodge(width = 0.9),
            vjust = -1.5, hjust = -0.5
  ) +
  # Add the number of disagreement citances
  geom_text(position = position_dodge(width = 0.9),
            aes(label = formatC(n_intext, format = "d", big.mark = ","),
                y = 0,
                group = interaction(authorship, field)),
            vjust = -0.5,
            alpha = 1,
            size = 3
  ) +
  facet_grid(field~authorship, switch = "y", scales = "free") +
  scale_y_continuous(expand = expand_scale(mult = c(0, .5)), position = "right") +
  scale_alpha_manual(values = c(0.1, 1)) +
  scale_fill_manual(values = tail(field_long_colors(), 5)) +
  guides(fill = F, alpha = F) +
  theme_dakota() +
  theme(
    axis.title.x = element_blank(),
    panel.border = element_rect(size = 0.5, fill = NA),
    axis.title.y = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    strip.text.y.left = element_text(angle = 0, hjust = 0),
    axis.text.x = element_text(face = "bold", angle = 45, hjust = 1),
  ) +
  ylab("% disagreement")

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
