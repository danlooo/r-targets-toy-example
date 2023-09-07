#!/usr/bin/env R

# ensure tidyverse overwrites base masking
library(base)
library(tidyverse)
library(targets)

# load library scripts
list.files("src", recursive = TRUE, pattern = ".R$", full.names = TRUE) |>
  discard(~ .x == "src/_targets.R") |>
  walk(source)

# List of targets
list(
  # import external raw data files ----
  tar_target(samples_file, "raw/samples.csv", format = "file"),
  tar_target(taxa_file, "raw/taxa.csv", format = "file"),
  tar_target(abundances_file, "raw/abundances.csv", format = "file"),
  tar_target(samples, read_csv(samples_file)),
  tar_target(taxa, read_csv(taxa_file)),
  tar_target(abundances, {
    abundances_file |>
      read_csv() |>
      # normalize to 3NF aka tidy data in long format
      # this allows better plotting and joining of tables
      pivot_longer(-otu_id, names_to = "SampleID", values_to = "abundance") |>
      filter(abundance != 0)
  }),

  # Calculate pooled taxon abundance ----
  tar_target(
    name = species_abundances,
    command = {
      abundances |>
        inner_join(taxa) |>
        group_by(SampleID, Species) |>
        summarise(abundance = sum(abundance))
    }
  ),
  tar_target(species_abundances_plt, {
    species_abundances |>
      ggplot(aes(Species, SampleID, fill = abundance)) +
      geom_tile()
  }),

  # Pool counts to a given taxonomic rank
  # This is a generalization of target species_abundances
  tar_target(taxa_ranks, c("Kingdom", "Phylum")),
  tar_target(
    name = taxa_rank_abundances,
    pattern = map(taxa_ranks),
    command = {
      abundances |>
        inner_join(taxa) |>
        group_by_at(c("SampleID", taxa_ranks)) |>
        summarise(abundance = sum(abundance)) |>
        ungroup() |>
        # Ensure column names are the same for every branch
        rename_at(taxa_ranks, ~"Taxon") |>
        # ensure one row per branch output with meta data
        nest() |>
        mutate(rank = taxa_ranks)
    }
  ),

  # Perform shell commands ----
  tar_target(
    name = shell_calls,
    pattern = head(samples, 3), # for each first 3 samples
    # Use column names in the syntax of str_glue to create shell commands
    command = shell_call(samples, "echo {SampleID} > name.txt; hostname > host.txt", docker = "ubuntu:22.04")
  ),

  # summarize results of shell commands
  tar_target(
    name = shell_written_lines_count,
    command = {
      shell_calls$work_dir |>
        map(~ list.files(.x, recursive = TRUE, full.names = TRUE)) |>
        unlist() |>
        map_int(~ .x |>
          read_lines() |>
          length()) |>
        sum()
    }
  )
)
