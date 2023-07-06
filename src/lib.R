#!/usr/bin/env R

shell_call <- function(x, ...) {
  UseMethod("shell_call", x)
}

shell_call.default <- function(
    command, name = targets::tar_name("shell_target"), store = paste0(getwd(), "/out/shell_targets"),
    docker = NULL,
    intern = TRUE, ...) {
  work_dir <- str_glue("{store}/{name}") |> normalizePath()
  
  unlink(work_dir, recursive = TRUE)
  dir.create(work_dir, recursive = TRUE)
  
  shell_command <- str_glue(
    ifelse(!is.null(docker), paste(
      "docker run --rm",
      "--volume", "{getwd()}:{getwd()}",
      "--user", system("id -u", intern = TRUE),
      "{docker} "), ""),
    
    # setup
    "sh -c 'cd {work_dir} && {command}; echo $? > .exitcode'"
  )

  system(shell_command, intern = intern, ...)
  
  exitcode <- str_glue("{work_dir}/.exitcode") |>
    read_lines() |>
    as.integer()
  
  sha1_checksums <- 
    list.files(work_dir, recursive = TRUE) |>
    set_names() |>
    map(~ system(paste0("sha1sum ",work_dir, "/", .x, "| cut -d \" \" -f 1"), intern = TRUE))

  list(
    name = name,
    command = command,
    work_dir = work_dir,
    exitcode = exitcode,
    sha1_checksums = sha1_checksums,
    shell_command = shell_command
  )
}

shell_call.data.frame <- function(data, command, ...) {
  data |>
    dplyr::transmute(
      shell_call = command |> stringr::str_glue() |> purrr::map(purrr::partial(shell_call, name = targets::tar_name(), ...))
    ) |>
    tidyr::unnest_wider(shell_call)
}
