## Scrape names of mews from Everchanging Mews and geocode

library(rvest)
library(stringr)
library(data.table)

#Read html from each page of original / survings listings list
listpage_root_url <-
        'https://everchangingmews.com/listings/original-surviving/'
pages <- 2:8
listpage_urls <- paste0(listpage_root_url, 'page/', pages)
listpage_urls <- c(listpage_root_url, listpage_urls)
listpage_html <- lapply(listpage_urls, read_html)

# get the web link for each listing
listings_urls <-
        # pull the li   nk nodes from each listing page with
        lapply(listpage_html,
               rvest::html_nodes,
               css = '#listing_ajax_container > div > div > h4 > a') %>%
        #extract href element
        lapply(html_attr, 'href') %>%
        unlist()

#Read each listings page
listings_html <- lapply(listings_urls, read_html)

#Get listings names
listings_names <-
        lapply(listings_html,
               html_nodes,
               xpath = '//*[@id="all_wrapper"]/div[1]/div[5]/div/h1') %>%
        sapply(function(x) {
                x <- xml_text(x) %>% trimws
        })

# Get listings location data
listings_locations <-
        lapply(listings_html,
               html_nodes,
               xpath = '//*[@id="collapseTwo"]/div/div') %>%
        lapply(function(x) {
                x <- xml_text(x)
                x <- paste(x, collapse = ",")
                as.list(x)
        })
 

# Convert to data.table
listings_locations <- rbindlist(listings_locations)
listings_locations[, url := listings_urls]
listings_locations[, name := listings_names]

# Extract address elements into columns
# Quick function to match regex string
mews_regex <- function(string,regex_pattern) {
        str_match(string, regex_pattern)[, 2] %>% trimws
}
listings_locations[, c('street', 'area', 'postcode', 'V1') :=
                           .(
                                   mews_regex(V1,'Address:(.*?),'),
                                   mews_regex(V1,'Area:(.*?),'),
                                   mews_regex(V1,'Zip:(.*?),'),
                                   NULL
                           )]
