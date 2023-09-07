#!/usr/bin/env R

source(".Rprofile")

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
    # Usdata:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAkCAYAAAD7PHgWAAADFklEQVR42u3Y20+SYRwHcGvddOn/0VX32tE5y2WrvLCVtjbbLGuZm4Iu8VBoaSwttRTUFwQ5iUoK4llzLkvJA6h4yNzMY8KLTrxq354X2sIDIqhJG7/tO+CG98PzPu/zex4CAvzlL3/5a8diiT8G+iwuTdpalKnsAPOaLtWd8jlgalUzRpY2wO8eB/M+VaYL9ikgW9IE/dw6ZENmvOuaQApBJoubI3wCx+FwjrPEOvT9cAClg2aUdE+DLSFIUWP0v0G0t59giesDXYUtadkErBpcQWnPDFjiFiRS2vsHBkmgGrITKA1NAuckCrVIJrfRVdLkbdBvAUoGViD4NIskgn8s1CQdCPBReQNtWl6HkUx4A8nwoiNDizYMLtgwMG8jc81mn2/9TAiKGTnmc9f02jYgk7LeOfIjWkG+m7NvYLxATQ/MraHpmxXaSSs0E1Y0jFtRP07jg4mGeoxG3SiNmlELVCMWVBstUBosUBjMkA+bdwSKv66g/PMCQbbhoUCdsy9gXKn6l3HJBp0bYO1uwCEHsMoJWElCfVlEsrQDcfy6V14D772vhXF5A41T7oE1HgIr9T9B9S2BJetCbEltgVfAu8U124ETW4Bjf4EqF0CpC6DIjlxGiqIH5FqFkTz5SY+AMYXVHgOZUXQGytwAhf2OPFX1IrpI+cQj4K0ChQugdVegkgAVBCjfA1BEcFT/MthkFG/nKx94BIx6LfsDXD00oJDc4kRJJ27my94yXcgjYCRPeqjACvIkx1MtuMGT5Xv1kFzLk+wONLkBDjsBBzcDmbUwlq8FuUae18tMxEvxZuCkKyDtAI7sDSjonUdMsRpXcyXcfS3U4TkiskivHiiwpGcWUQUqhL8Q7b/VXeYKiy5xhfAmGoLfCizuniHzTY4wrjDpSPeEoc8r7BsH5378pnMKV3IlCH1GxR/5pvViVvkmIK/VhLBsEUIyy+/4xK76fEYZur+v2YHZjQaEZFXgXIbgus+cSc6mC+ztLl2tJ7AyEv4Fnzo0BXH4RWcIMpjDRxCn7LRvHo7tbQvH/H9h+Ot/r98AkmxTZNPwmwAAAABJRU5ErkJggg==e pattern=map(SampleID) here e.g. if the data is stored in an individual file per sample
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
