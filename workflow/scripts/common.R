#########################################
# Common functions and resources
#########################################

# The labels to use for fields
field_labels <- function() {
  c("Soc & Hum",
    "Bio & Health",
    "Phys & Engr",
    "Life & Earth",
    "Math & Comp"
  )
}

# The order of labels to use
field_levels <- function() {
  c("Soc & Hum",
    "Bio & Health",
    "Life & Earth",
    "Phys & Engr",
    "Math & Comp"
  )
}

# Set the names of the columns to use
columns <- c("weight<Share results 56: no consensus + studies>",
             "weight<Share results 57: no consensus + results>",
             "weight<Share results 58: no consensus + methods>",
             "weight<Share results 59: no consensus + ideas>",
             "weight<Share results 60: no consensus + standalone>",
             "weight<Share results 51: debat* + studies>",
             "weight<Share results 52: debat* + results>",
             "weight<Share results 53: debat* + methods>",
             "weight<Share results 55: debat* + standalone>",
             "weight<Share results 07: contradict* + results>",
             "weight<Share results 06: contradict* + studies>",
             "weight<Share results 21: conflict* + studies>",
             "weight<Share results 22: conflict* + results>",
             "weight<Share results 36: controvers* + studies>",
             "weight<Share results 37: controvers* + results>",
             "weight<Share results 38: controvers* + methods>",
             "weight<Share results 39: controvers* + ideas>",
             "weight<Share results 40: controvers* + standalone>",
             "weight<Share results 26: disagree* + studies>",
             "weight<Share results 27: disagree* + results>",
             "weight<Share results 17: contrary + results>",
             "weight<Share results 41: disprov* + studies>",
             "weight<Share results 63: questionable + methods>"
             )

# And the levels of the final, formatted columns
levs <- c("conflict* + studies", "conflict* + results",
          "contradict* + studies", "contradict* + results",
          "contrary + results",
          "controvers*", "controvers* + studies", "controvers* + ideas", "controvers* + methods", "controvers* + results",
          "no consensus", "no consensus + studies", "no consensus + methods", "no consensus + results",
          "debat*", "debat* + studies", "debat* + methods", "debat* + results",
          "disagree* + studies", "disagree* + results",
          "disprov* + studies",
          "questionable + methods"
          )
