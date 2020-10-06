# Pass mews locations to graphopper route optimisation API

library(httr)
library(jsonlite)

# Randomly group mews into fives
num_listings <- nrow(listings_locations)
set.seed(123)
route_id <-
  sample(ceiling(1:nrow(listings_locations) / 5), num_listings)
num_routes <- max(route_id)
listings_locations[, route_id := route_id]

#Graphopper key
gh_key <- 'f8e5d7c0-3712-46f8-874b-ef6fc6d94d4a'
gh_url <- 'https://graphhopper.com/api/1/route?key='
gh_url <- paste0(gh_url, gh_key)

# define start location
start_location <- list(c(-0.186493, 51.523656))
ghopper_request_body <- function(route_num, data) {
  # Generate a json request body for the GraphHopper Route API
  # using rows sampled from run_the_mews locations
  mews_datatable <- data[route_id == route_num]
  gh_list <- list(
    points = c(start_location,
               lapply(1:nrow(mews_datatable),
                      function(x) {
                        c(mews_datatable[x]$longitude,
                          mews_datatable[x]$latitude)
                        
                      }),
               start_location),
    vehicle = 'foot',
    details = list('distance'),
    optimize = 'true',
    points_encoded	= F
  )
  gh_req_json <- toJSON(gh_list,
                        auto_unbox = TRUE,
                        pretty = T)
  return(gh_req_json)
}

gh_request_list <- lapply(1:max(listings_locations$route_id),
                          ghopper_request_body,
                          listings_locations)

# post requests GraphHopper API
gh_response_list <- lapply(gh_request_list,
                           function(x) {
                             y <- POST(gh_url,
                                       body = x,
                                       content_type('application/json'))
                             y <- fromJSON(rawToChar(y$content))
                             return(y)
                           })

# Co-ordinates of gh response
gh_response_coords <- lapply(1:num_routes, function(x) {
  gh_response_list[[x]][["paths"]][["points"]][["coordinates"]][[1]]
})

gh_response_sf <- lapply(gh_response_coords, function(x) {
  lstr <- sf::st_linestring(x)
  sfc_lstr <- sf::st_sfc(lstr , crs = 4326)
  sf <- sf::st_as_sf(sfc_lstr)
  return(sf)
})

gh_response_distances <- sapply(1:num_routes, function(x) {
  gh_response_list[[x]][["paths"]][["distance"]]
  
})


# Draw a map of the routes with the mews locations
pal <- leaflet::colorNumeric("magma", 1:num_routes)
map <- leaflet::leaflet() %>%
  leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron) %>%
  leaflet::addCircles(data = listings_locations_sf)

for (i in 1:num_routes) {
  map <-
    map %>%
    leaflet::addPolylines(
      data = gh_response_sf[[i]],
      weight = 2,
      opacity = 0.3,
      group = paste('Day', i),
      color = pal(i)
      , popup = paste0('Day ', i,
                     ' ',
                     paste(
                       listings_locations[route_id == i]$name,
                           collapse = ','),
                     ' ',
                     formatC(gh_response_distances[i]/1000),
                     'km'
                     )
      )
}
map <- map %>%
  leaflet::addLayersControl(
    overlayGroups = paste('Day', 1:num_routes),
    options = leaflet::layersControlOptions(collapsed = FALSE)
  ) %>%
  leaflet::hideGroup(paste('Day', 10:num_routes))

htmlwidgets::saveWidget(map,'index.html')


# Save to GPX
lapply(1:num_routes, function(x) {
  sf::st_write(gh_response_sf[[x]],
               dsn = paste0('GPX/',
                            paste0(
                              'Day ', x, ' ',
                              paste(listings_locations[route_id == x]$name,
                                    collapse = ',')
                            ),
                            '.gpx'),
               driver = 'GPX')
})
