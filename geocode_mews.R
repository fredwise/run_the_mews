library(data.table)
library(stringr)
library(ggmap)

register_google(key = "AIzaSyAw1q3Kjn8fgnVe-vJUOcuuwQ0ejMsfXu4")

mews <- fread('mews_original_surviving.csv', header = F)
names(mews) <- 'mews_name'

#Clean up names extracted from Everchanging Mews and add London suffix
mews[,
     mews_clean := mews_name %>%
       stringr::str_replace_all(pattern = '-',
                                replacement = ' '
                                ) %>%
       stringr::str_to_title() %>%
       paste0(', London')
       ]
mews_latlon <- geocode(mews$mews_clean, output='more')

mews <- cbind(mews,mews_latlon)
fwrite(mews,'mews_locations.csv')
