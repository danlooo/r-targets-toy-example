#!/usr/bin/env R

# ensure tidyverse overwrites base masking
library(base)
library(tidyverse)
library(targets)

# load library scripts
list.files("src", recursive = TRUE, pattern = ".R$", full.names = TRUE) |>
  discard(~ .x == "src/_targets.R") |>
  walk(source)
