# R targets toy example

This project provides a minimal working example to demonstrate multi-step analyses using R targets.

## Features

- Write a complex analysis workflow, one step at a time
- Apply a function across all samples
- Combine results from multiple samples into a single plot

## Get Started

Open The R project at the root directory and this repository e.g. with RStudio and run the following code in the R console:

```r
library(targets)
library(tidyverse)

tar_make()
tar_read(samples)
```
