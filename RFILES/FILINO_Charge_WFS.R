library(httr)
library(xml2)
library(sf)

# URL GetCapabilities
url <- "https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities"

# layer_names[490]
layer_name <- "IGNF_NUAGES-DE-POINTS-LIDAR-HD:dalle"

# Export
dsnexport="C:\\StockageLIDAR\\TA_IGN_WFS\\TA_Lidar"

# Télécharger le document de capacités
res <- httr::GET(url)
xml <- xml2::read_xml(content(res, "text"))

ns <- xml2::xml_ns(xml)
print(ns)

layers <- xml2::xml_find_all(
  xml,
  ".//wfs:FeatureType/wfs:Name",
  ns = ns
)
print(layers)

layer_names <- xml2::xml_text(layers)
print(layer_names)

wfs_dsn <- "WFS:https://data.geopf.fr/wfs/ows"
dalles_lidar <- st_read(
  dsn   = wfs_dsn,
  layer = layer_name,
  quiet = FALSE
)

dim(dalles_lidar)

cat("# Recupération de la couche WFS\n")
nomexport=paste0(dsnexport,format(Sys.time(),format="%Y%m%d_%H%M%S"),"_IGN.gpkg")
st_write(dalles_lidar,nomexport, delete_dsn = T,delete_layer = T, quiet = T)

# triturage du lidarHD - inutile pour d'autres couches

cat("# Recupération des URL identiques\n")
dalles_lidar=dalles_lidar[order(dalles_lidar$url),]
nb=which(dalles_lidar$url[-1]==dalles_lidar$url[-nrow(dalles_lidar)])
dalles_lidar$url_IDEM=0
dalles_lidar$url_IDEM[nb]=1

cat("# Recuperation des noms identiques")
dalles_lidar=dalles_lidar[order(dalles_lidar$name),]
nb=which(dalles_lidar$name[-1]==dalles_lidar$name[-nrow(dalles_lidar)])
dalles_lidar$name_IDEM=0
dalles_lidar$name_IDEM[nb]=1

cat("# Affichage")
dalles_lidar=dalles_lidar[order(dalles_lidar$id),]
dalles_lidar$Affichage=as.numeric(dalles_lidar$name_IDEM)+as.numeric(dalles_lidar$url_IDEM)

nomexport=paste0(dsnexport,format(Sys.time(),format="%Y%m%d_%H%M%S"),"_Doublons.gpkg")
st_write(dalles_lidar,nomexport, delete_dsn = T,delete_layer = T, quiet = T)