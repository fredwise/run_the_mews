library(sf)
library(mapview)
# Convert mews location data to sf object
`Mews Locations` <- st_as_sf(x = listings_locations, 
                        coords = c("longitude", "latitude"),
                        crs = 4326)

# interactive map:
mapview(`Mews Locations`, zcol = 'area', label = c('name', 'street','postcode')
