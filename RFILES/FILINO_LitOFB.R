# cdstationhydro <- "O900001002"
# date_mesure=c("09/08/2023 09:53","09/08/2023 09:53")
# dt <- 3600
# 
# cdstationhydro="V300002001"
# date_mesure=c("2021-04-14 10:18:11","2021-04-14 11:16:54")
# dt=3600
# FILINO_LitOFB(cdstationhydro,date_mesure,dt)

FILINO_LitOFB=function(cdstationhydro,date_mesure,dt,AltProche)
{
  # Charger les bibliothèques nécessaires
  library(httr)
  library(readr)
  library(lubridate)
  library(dplyr)
  library(rjson)
  
  # Liste des URL des fichiers TAR et leurs plages de lettres associées
  folder_path=dirname(NomStHydro)#"C:\\BDD\\HYDROMETRIE"
  
  
  tar_list <- data.frame(
    range = c("0-9", "A-E", "F-J", "K-O", "P-T", "U-Z"),
    tar_url = c(
      "https://bnum.din.gouv.fr/mdrive/index.php/s/kNFXxqrpA4CsZfe/download/stations_09.tar",
      "https://bnum.din.gouv.fr/mdrive/index.php/s/snPkaQ5ZFpTQNCx/download/stations_AE.tar",
      "https://bnum.din.gouv.fr/mdrive/index.php/s/wH6w52YNopB8mf2/download/stations_FJ.tar",
      "https://bnum.din.gouv.fr/mdrive/index.php/s/riTXfpt79EfQ8Xj/download/stations_KO.tar",
      "https://bnum.din.gouv.fr/mdrive/index.php/s/dobGtePF6MNi8NT/download/stations_PT.tar",
      "https://bnum.din.gouv.fr/mdrive/index.php/s/n7P4QfqbyAqkdXB/download/stations_UZ.tar"
    ),
    extract_path = c(
      "stations_09", "stations_AE", "stations_FJ",
      "stations_KO", "stations_PT", "stations_UZ"
    ),
    stringsAsFactors = FALSE
  )
  
  # Fonction pour déterminer le bon fichier TAR en fonction de la première lettre du code station
  get_tar_info <- function(cdstationhydro) {
    cat("Fonction pour déterminer le bon fichier TAR en fonction de la première lettre du code station\n")
    first_char <- substr(cdstationhydro, 1, 1)
    if (grepl("[0-9]", first_char)) {
      return(tar_list[tar_list$range == "0-9", ])
    } else if (grepl("[A-E]", first_char)) {
      return(tar_list[tar_list$range == "A-E", ])
    } else if (grepl("[F-J]", first_char)) {
      return(tar_list[tar_list$range == "F-J", ])
    } else if (grepl("[K-O]", first_char)) {
      return(tar_list[tar_list$range == "K-O", ])
    } else if (grepl("[P-T]", first_char)) {
      return(tar_list[tar_list$range == "P-T", ])
    } else if (grepl("[U-Z]", first_char)) {
      return(tar_list[tar_list$range == "U-Z", ])
    } else {
      stop("Aucune plage de lettres correspondante trouvée pour le code station : ", cdstationhydro)
    }
  }
  
  # Fonction pour télécharger un fichier TAR
  download_tar_file <- function(url, destination_path) {
    cat("# Fonction pour télécharger un fichier TAR\n")
    if (!file.exists(destination_path)) {
      message(paste("Fichier en cours de téléchargement :", destination_path))
      GET(url, write_disk(destination_path, overwrite = TRUE))
      message(paste("Fichier téléchargé :", destination_path))
    } else {
      message(paste("Fichier déjà présent :", destination_path))
    }
  }
  
  # Fonction pour extraire une archive TAR
  extract_tar_file <- function(tar_path, extract_path) {
    cat("# Fonction pour extraire une archive TAR\n")
    if (!dir.exists(extract_path)) {
      message(paste("Archive en cours d'extraction :", extract_path))
      untar(tar_path, exdir = extract_path)
      message(paste("Archive extraite dans :", extract_path))
    } else {
      message(paste("Dossier déjà extrait :", extract_path))
    }
  }
  
  # Fonction pour récupérer les données de hauteur et de débit
  get_hydro_data <- function(cdstationhydro, date_mesure) {
    cat("# Fonction pour récupérer les données de hauteur et de débit\n")

    # 1. Déterminer le bon fichier TAR et le dossier d'extraction
    tar_info <- get_tar_info(cdstationhydro)
    tar_url <- tar_info$tar_url
    extract_path <- file.path(folder_path,tar_info$extract_path)
    tar_file <- file.path(dirname(extract_path), basename(tar_url))
    
    # 2. Télécharger le fichier TAR si nécessaire
    download_tar_file(tar_url, tar_file)
    
    # 3. Extraire l'archive TAR si nécessaire
    extract_tar_file(tar_file, extract_path)
    
    # 4. Construire le chemin du dossier de la station
    station_folder <- file.path(extract_path, cdstationhydro)
    
    # 6. Déterminer l'année de la date de mesure
    date_time <- ymd_hms(date_mesure[1])
    year <- year(date_time)
    
    if (is.na(year)==T)
    {
      cat("bugdedatemettre00:00:01")
      browser()
    }
    
    # 5. Lister les fichiers CSV compressés dans le dossier de la station
    # csv_files <- list.files(station_folder, pattern = "\\d{4}_H.csv.gz$", full.names = TRUE)
    csv_filesHQ <- file.path(station_folder, paste0(year,"_HQ.csv.gz"))
    csv_filesH <- file.path(station_folder, paste0(year,"_H.csv.gz"))
    csv_filesQ <- file.path(station_folder, paste0(year,"_Q.csv.gz"))
    
    # 7. Filtrer le fichier CSV correspondant à l'année
    # target_file <- grep(paste0("^", year, "_HQ.csv.gz"), basename(csv_files), value = TRUE)
    # if (length(target_file) == 0) {
    #   # stop(paste("Aucun fichier trouvé pour l'année", year, "dans le dossier", station_folder))
    #   cat("Aucun fichier trouvé pour l'année", year, "dans le dossier", station_folder,"\n")
    #   data=NA
    # }else
    if (file.exists(csv_filesHQ)==T)
    {
      target_file <- csv_filesHQ
      # 8. Lire et décompresser le fichier CSV
      data <- readr::read_delim(
        gzfile(target_file),
        delim = ";",
        skip = 1,
        col_names = c("cdentite", "dtmesure", "hauteur", "qualh", "methh", "conth", "statuth", "debit", "qualq", "methq", "contq", "statutq"),
        col_types = readr::cols(
          cdentite = readr::col_character(),
          dtmesure = readr::col_datetime(format = "%Y-%m-%d %H:%M:%S"),
          hauteur = readr::col_double(),
          qualh = readr::col_integer(),
          methh = readr::col_integer(),
          conth = readr::col_integer(),
          statuth = readr::col_integer(),
          debit = readr::col_double(),
          qualq = readr::col_integer(),
          methq = readr::col_integer(),
          contq = readr::col_integer(),
          statutq = readr::col_integer()
        )
      )
    }else{
      if (file.exists(csv_filesH)==T)
      {
        target_file <- csv_filesH
        # 8. Lire et décompresser le fichier CSV
        data <- readr::read_delim(
          gzfile(target_file),
          delim = ";",
          skip = 1,
          col_names = c("cdentite", "dtmesure", "hauteur", "qualh", "methh", "conth", "statuth", "debit", "qualq", "methq", "contq", "statutq"),
          col_types = readr::cols(
            cdentite = readr::col_character(),
            dtmesure = readr::col_datetime(format = "%Y-%m-%d %H:%M:%S"),
            hauteur = readr::col_double(),
            qualh = readr::col_integer(),
            methh = readr::col_integer(),
            conth = readr::col_integer(),
            statuth = readr::col_integer()
          )
        )
        data$debit=NA
      }else{
        if (file.exists(csv_filesQ)==T)
        {
          target_file <- csv_filesHQ
          # 8. Lire et décompresser le fichier CSV
          data <- readr::read_delim(
            gzfile(target_file),
            delim = ";",
            skip = 1,
            col_names = c("cdentite", "dtmesure", "hauteur", "qualh", "methh", "conth", "statuth", "debit", "qualq", "methq", "contq", "statutq"),
            col_types = readr::cols(
              cdentite = readr::col_character(),
              dtmesure = readr::col_datetime(format = "%Y-%m-%d %H:%M:%S"),
              debit = readr::col_double(),
              qualq = readr::col_integer(),
              methq = readr::col_integer(),
              contq = readr::col_integer(),
              statutq = readr::col_integer()
            )
          )
          data$hauteur=NA
        }else{
          message(paste("Pas de fichier :", file.path(station_folder, paste0(year,"_xxx.csv.gz"))))
          data=NA
        }
      }
    }
    # 10. Retourner les données filtrées
    return(data)
  }
  
  # Fonction pour récupérer l'altitude de référence d'une station
  get_station_altitude <- function(cdstationhydro) {
    # Construire l'URL de l'API Hubeau
    url <- paste0(
      "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations?",
      "code_station=", cdstationhydro,
      "&format=json&size=2000"
    )
    
    # Effectuer la requête GET
    response <- GET(url)
    
    # Vérifier si la requête a réussi
    if (http_status(response)$category == "Success") {
      # Extraire le contenu JSON
      content <- content(response, "text")
      data <- rjson::fromJSON(content)
      
      # Vérifier si des données ont été retournées
      if (length(data$count) > 0 && data$count > 0) {
        # Extraire l'altitude de référence
        altitude <- data$data[[1]]$altitude_ref_alti_station
        code_systeme_alti_site <- data$data[[1]]$code_systeme_alti_site
      } else {
        # stop("Aucune donnée trouvée pour le code station : ", cdstationhydro)
        cat("Aucune donnée trouvée pour le code station : ", cdstationhydro,"\n")
        altitude=NULL
        code_systeme_alti_site=NULL
      }
    } else {
      # stop("Erreur lors de la requête API pour le code station : ", cdstationhydro)
      cat("Erreur lors de la requête API pour le code station : ", cdstationhydro,"\n")
      altitude=NULL
      code_systeme_alti_site=NULL
    }
    
    return(list(altitude,code_systeme_alti_site))
  }
  
  # Exemple d'utilisation
  res_A_C <- get_station_altitude(cdstationhydro)
  altitude              =res_A_C[[1]]
  code_systeme_alti_site=res_A_C[[2]]
  print(code_systeme_alti_site)
  # Afficher le résultat
  print(altitude)
  # browser()
  if (is.null(altitude)==F)
  {
    # Référentiel alti
    # # Exemple de données
    # ratio <- c(995, 99.5, 9, 499, 49.9, 4.9,1200,800,80)
    if (is.null(AltProche)==F)
    {
      ratio=altitude/AltProche
      
      # Transformation avec case_when
      ratio_universel <- case_when(
        ratio >= 500 & ratio < 5000   ~ 1000,
        ratio >=  50 & ratio <  500   ~ 100,
        ratio >=   5 & ratio <   50   ~ 10,
        ratio >= 0.5 & ratio <    5   ~ 1,
        TRUE                          ~ as.numeric(ratio)  # Cas par défaut
      )
      if (altitude<1){ratio_universel=1}
    }else{
      ratio_universel=10^code_systeme_alti_site
      ratio_universel=1000
    }
    
    print(ratio_universel)
    print(paste("Altitude de référence pour la station", cdstationhydro, ":", altitude," - ",altitude/ratio_universel, "m NGF"))
    
    altitude=altitude/ratio_universel
    
    # Exemple d'utilisation
    hydro_data <- get_hydro_data(cdstationhydro, date_mesure)
    
    if (length(hydro_data)>1)
    {
      # Cote d'eau en NGF
      hydro_data$CoteEau_m_NGF=hydro_data$hauteur/1000+altitude
      hydro_data$debit_m3_s=hydro_data$debit/1000
      
      # 9. Filtrer les données pour récupérer les mesures dt avant et dt après la date de mesure
      # date_mesure <- lubridate::ymd_hms(date_mesure)
      # hydro_filtered_data <- hydro_data %>%
      #   filter(dtmesure >= (date_mesure[1] - dt) & dtmesure <= (date_mesure[2] + dt))
      
      nmoins=which(hydro_data$dtmesure<=ymd_hms(date_mesure[1]) - dt);nmoins=nmoins[length(nmoins)]
      nplus =which(hydro_data$dtmesure>=ymd_hms(date_mesure[2]) + dt);nplus =nplus[1]
      if (is.na(nmoins)==T | is.na(nplus)==T)
      {
        hydro_filtered_data=NA
      }else{
        hydro_filtered_data=hydro_data[nmoins:nplus,]
      }
      # Afficher les résultats
      print(hydro_filtered_data)
    }else{
      hydro_filtered_data=NA
    }
  }else{
    hydro_filtered_data=NA
  }
  return(list(altitude,hydro_filtered_data))
}
# 
# chemin="C:\\AFFAIRES\\INRAE\\Hydrometrie"
# listeStations=list.files(chemin,pattern="csv.gz",recursive=T)
# listeStations=sort(unique(basename(dirname(listeStations))))
# cat(length(listeStations), "nombre de data\n")
# Stations_sf=st_read("C:\\Users\\frederic.pons\\Downloads\\StationHydro_FXX-gpkg\\StationHydro_FXX.gpkg")
# cat(nrow(Stations_sf), "nombre de stations\n")
# commun=intersect(Stations_sf$CdStationHydro,listeStations)
# cat(length(commun), "nombre de commun\n")
# nb=which(Stations_sf$CdStationHydro %in% commun)
# Stations_sf$DataStations    ="NON"
# Stations_sf$DataStations[nb]="OUI"
# Stations_sf$DataStationsAPI ="NON"
# for (inb in nb)
# {
#   print(inb)
#   url <- paste0(
#     "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations?",
#     "code_station=", Stations_sf$CdStationHydro[inb],
#     "&format=json&size=2000"
#   )
# 
#   # Effectuer la requête GET
#   response <- GET(url)
# 
#   # Vérifier si la requête a réussi
#   if (http_status(response)$category == "Success")
#   {
#     Stations_sf$DataStationsAPI[inb]="OUI"
#   }
# }
# st_write(Stations_sf,file.path(chemin,"StationHydro_FXX.gpkg"),delete_dsn = T,delete_layer = T, quiet = T)



# Voir avec PAG
# => Intérêt de bathy inverse si petits débits...
# => voir intérêt de récupérer les débits sous forme de raster partout pour les mettre dans un graph en dessous aux diverses dates et voir si bcp de débits ou  pas