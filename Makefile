.PHONY: main
main:
	 R -e "renv::restore(); targets::tar_make()"