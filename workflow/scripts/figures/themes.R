theme_dakota <- function() {
  require(ggplot2)
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    legend.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    legend.background = element_rect(size = 0.5),
    legend.text = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 14),
    plot.title = element_text(size = 14, face = "bold")
  )
}

theme_fieldmap <- function() {
  require(ggplot2)
  theme_dakota() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    legend.position = "bottom",
    legend.title = element_text(size = 14, face = "bold"),
    legend.text = element_text(size = 12, face = "bold"),
    legend.key.width = unit(2, "cm")
  )
}

# The bottom-end of the ratio gradient for fieldmap
gradient.low <- function() {
  "dodgerblue4"
}

# The high-end of the gradient to use for the fieldmap
gradient.high <- function() {
  "firebrick"
}

# The middle-color for the gradient
gradient.mid <- function() {
  "white"
}

# Colors of fields
field_colors <- function() {
  c("#fdcb6e",
    "#d63031",
    "#00b894",
    "#0984e3",
    "#6c5ce7")
}

cluster2color <- function(clu) {
  switch(as.character(clu),
         "Soc & Hum" = "#fdcb6e",
         "Bio & Health" = "#d63031",
         "Phys & Engr" = "#0984e3",
         "Life & Earth" = "#00b894",
         "Math & Comp" = "#6c5ce7")
}
