library(sf)
library(mapview)

listings_locations_sf <- st_as_sf(
  #mews location data to sf object
  x = listings_locations,
  coords = c("longitude", "latitude"),
  crs = 4326
)

map <- leaflet::leaflet() %>%
  leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron) %>%
  leaflet::addCircles(data = listings_locations_sf)
