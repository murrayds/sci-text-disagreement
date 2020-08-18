theme_dakota <- function() {
  require(ggplot2)
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    legend.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    legend.background = element_rect(size = 0.5),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
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
    legend.title = element_blank(),
    legend.text = element_text(size = 12, face = "bold"),
    legend.key.width = unit(2, "cm")
  )
}
