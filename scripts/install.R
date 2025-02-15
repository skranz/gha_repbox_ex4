# Here we can add some custom package installations

library(remotes)
quiet = TRUE
#remotes::install_github("repboxr/sourcemodify", upgrade="never", force=TRUE)
#remotes::install_github("repboxr/ExtractSciTab", upgrade="never", force=TRUE)
# remotes::install_github("repboxr/repboxUtils", upgrade="never", force=TRUE, quiet=quiet)
remotes::install_github("repboxr/repboxReg", upgrade="never", force=TRUE, quiet=quiet)
# remotes::install_github("repboxr/repboxStata", upgrade="never", force=TRUE, quiet=quiet)
remotes::install_github("repboxr/repboxArt", upgrade="never", force=TRUE, quiet=quiet)
# remotes::install_github("repboxr/repboxRun", upgrade="never", force=TRUE, quiet=quiet)
