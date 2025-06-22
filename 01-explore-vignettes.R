# If 'remotes' is not installed
install.packages('remotes')

# Use remotes::install_github to obtain the PSInetR package directly from GH
# Make sure to grab the vignettes as well
remotes::install_github("PSInetRCN/PSInetR", build_vignettes = TRUE)

# Load the PSInetR package
library(PSInetR)

# Add other packages here as needed (some you may need to install)
library(DBI)
library(duckdb)
library(dplyr)
library(dbplyr)


#### First vignette ####
vignette("getting-started", package = "PSInetR")


#### Second vignette ####
vignette("data-analysis-examples", package = "PSInetR")



#### Third vignette ####
vignette("working-with-duckdb", package = "PSInetR")


