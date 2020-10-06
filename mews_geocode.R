# Get location data from mwes postcodes and route map

#source(mews_postcodes.R)
library(PostcodesioR)

#function that ignores postcode lookup errors (DEBUG)
mews_lookup_postcode <- function(x) {
  try({
    y <- as.data.table(postcode_lookup(x))
    y <-
      y[, .(longitude, latitude)]
    return(y)
  })
}

# Look up latitude and longitude
listings_latlon <- lapply(listings_locations$postcode,
                          mews_lookup_postcode)

# List errors
listings_locations$postcode[
  sapply(listings_latlon, class) == 'try-error']
#"Westminster" "W9 3NY"      "W1T 4AA"     NA            "WC1N 3EH"    "N16 7 UT"    "W1G 9EE"

##MANUAL CLEAN
#Replace postcodes that postcodes.io doesn't know
listings_locations[postcode == "Westminster", postcode:='W1G 8PD']
listings_locations[is.na(postcode), postcode:='W1K 2QE']
listings_locations[postcode == "W9 3NY", postcode:='W9 3NZ']
listings_locations[postcode == "W1T 4AA", postcode:='W1T 4AB']
listings_locations[postcode == "WC1N 3EH", postcode:='WC1N 3EN']
listings_locations[postcode == "N16 7 UT", postcode:='N16 7UT']
listings_locations[postcode == "W1G 9EE", postcode:='W1G 9EF']

listings_latlon <- lapply(listings_locations$postcode,
                          mews_lookup_postcode)

## Check for errors, 
#listings_locations$postcode[
#sapply(listings_latlon, class) == 'try-error']
## NONE!

listings_latlon <- rbindlist(listings_latlon)

listings_locations <- cbind(listings_locations,
                            listings_latlon)
listings_locations[,listing_id:=.I]
setkey(listings_locations,listing_id)

# Clean up environment
rm(list=setdiff(ls(), "listings_locations"))
