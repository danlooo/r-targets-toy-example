# R targets toy example

This project provides a minimal working example to demonstrate multi-step analyses using R targets.

## Features

- Write a complex analysis workflow, one step at a time
- Apply a function across all samples
- Combine results from multiple samples into a single plot
- Run shell commands as targets, also with docker

## Get Started

```bash
git clone https://github.com/danlooo/r-targets-toy-example/
cd r-targets-toy-example
make
```

Open The R project at the root directory and this repository e.g. with RStudio and run the following code in the R console:

```r
library(targets)
library(tidyverse)

tar_make()
tar_read(samples)
```
