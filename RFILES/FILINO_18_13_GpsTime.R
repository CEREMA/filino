FILINO_18_13_GpsTime_Job=function(idalle,TA_)
{
  NomLaz=basename(file.path(dsnlayerTA,TA_$DOSSIER,TA_$NOM))[idalle]
  ChemLaz=dirname(file.path(dsnlayerTA,TA_$DOSSIER,TA_$NOM))[idalle]
  
  raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
  
  nomjson=file.path(dsnlayer,NomDirGpsTime,racilayerTA,NomDossDalles,paste0(raci,"_GpsTime.json"))
  nom_Rast_diff=file.path(dirname(nomjson),paste0(raci,"_","GpsTime_","Diff",".tif"))
  if (file.exists(nom_Rast_diff)==F)
  {
    decalgrille=resoGpsTime
    Ouest=largdalle*as.numeric(substr(NomLaz,paramXYTA[2],paramXYTA[3]))
    Nord=largdalle*as.numeric(substr(NomLaz,paramXYTA[4],paramXYTA[5]))
    Est=as.character(Ouest+largdalle-decalgrille)
    Sud=as.character(Nord-largdalle)
    Ouest=as.character(Ouest)
    Nord=as.character(Nord-decalgrille)
    # cat(Ouest," ",Est," ",Sud," ",Nord,"\n")
    
    
    nominput=file.path(ChemLaz,NomLaz)
    for (nom_method in cbind("min","max"))
    {
      nom_Rast=file.path(dirname(nomjson),paste0(raci,"_","GpsTime_",nom_method,"AJeter",".tif"))
      write(paste0("["),nomjson)
      write(paste0("    {"),nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
      write(paste0("       ",shQuote("filename"),":",shQuote(nominput),","),nomjson,append=T)
      write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
      write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
      write(paste0("    },"),nomjson,append=T)
      write(paste0("    {"),nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
      write(paste0("       ",shQuote("limits"),":",shQuote("GpsTime[1:1000000000]")),nomjson,append=T)
      write(paste0("    },"),nomjson,append=T)
      write(paste0("    {"),nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","),nomjson,append=T)
      write(paste0("       ",shQuote("dimension"),":",shQuote("GpsTime"),","),nomjson,append=T)
      write(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","),nomjson,append=T)
      write(paste0("       ",shQuote("resolution"),": ",resoGpsTime,","),nomjson,append=T)
      write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est),"],[",Sud,",",as.numeric(Nord),"])")),","),nomjson,append=T)
      write(paste0("       ",shQuote("filename"),":",shQuote(nom_Rast)),nomjson,append=T)
      write(paste0("    }"),nomjson,append=T)
      write(paste0("]"),nomjson,append=T)
      
      cmd=paste(pdal_exe,"pipeline",nomjson)
      cat("---------------------------------------------\n")
      cat("PDAL ",basename(NomLaz)," GpsTime ",nom_method,"\n")
      toto=system(cmd)

      # Test pour voir si Pdal passe, si ce n'est pas le cas, grande chance que le fichier soit corrompu
      if (toto!=0){file.create(paste0(nominput,"BUG"))}
      
      if (Nettoyage==1){unlink(nomjson)}
      
      # Lire le raster
      nomTps <- raster(nom_Rast)
      
      
      # Convertir le raster en points
      points <- rasterToPoints(nomTps, spatial = TRUE)
      # browser()
      # Convertir les points en un objet sf
      # points_sf <- st_as_sf(points, crs = st_crs(nomTps))
      points_sf <- st_as_sf(points, crs = st_crs(nEPSG))
      
      # Définir la date de référence LidazrHD
      debGpsTimeLidar="14/09/2011 00:00:00"
      date_reference <- strptime(debGpsTimeLidar,format="%d/%m/%Y %H:%M:%S")
      
      # Convertir les secondes en dates
      # Convertir les valeurs de temps en secondes en une date au format AAMMJJHHMMSS
      colnames(points_sf)[1]="val"
      dates <- date_reference + points_sf$val
      
      # Formater les dates en AAMMJJHHMMSS
      dates_formatted <- format(dates, "%y%m%d%H%M%S")
      
      # Ajouter les dates formatées aux points sf
      points_sf$date_formatted <- as.numeric(dates_formatted)
      # st_write(points_sf,file.path(dirname(nomjson),paste0(raci,"_","GpsTime_",nom_method,"_pts.gpkg")), delete_layer=T, quiet=T)
      
      # On a un nombre limité
      dates_formatted <- format(dates, "%y%m%d%H")
      dates_formatted=substr(dates_formatted,1,nchar(dates_formatted)-1)
      points_sf$date_formatted <- as.numeric(dates_formatted)
      print(sort(unique(points_sf$date_formatted)))
      
      # Créer un raster vide avec les mêmes dimensions et résolution que le raster original
      raster_template <- raster(nomTps)
      
      crs(raster_template)=nEPSG
      # raster_template[] <- NA
      
      # Remplir le raster avec les valeurs formatées
      for (i in 1:nrow(points_sf)) 
      {
        raster_template[i] <-points_sf$date_formatted[i]
      }
      
      # Exporter le nouveau raster en fichier raster
      # nom_Rast_ok=file.path(dirname(nomjson),paste0(raci,"_","GpsTime_",nom_method,".gpkg"))
      # writeRaster(raster_template, nom_Rast_ok, format = "GPKG", overwrite = TRUE, datatype="FLT4S")
      nom_Rast_ok=file.path(dirname(nomjson),paste0(raci,"_","GpsTime_",nom_method,".tif"))
      writeRaster(raster_template, nom_Rast_ok, format = "Gtiff", overwrite = TRUE)
    }
    
    # browser()
    # Différence de raster
    nom_Rast1=file.path(dirname(nomjson),paste0(raci,"_","GpsTime_","min","AJeter",".tif"))
    nomTpsMin <- raster(nom_Rast1)
    crs(nomTpsMin)=nEPSG
    
    nom_Rast2=file.path(dirname(nomjson),paste0(raci,"_","GpsTime_","max","AJeter",".tif"))
    nomTpsMax <- raster(nom_Rast2)
    crs(nomTpsMax)=nEPSG
    
    Diff=round(nomTpsMax-nomTpsMin,1)
    
    writeRaster(Diff, nom_Rast_diff, format = "Gtiff", overwrite = TRUE, datatype="FLT8S")
    
    file.copy(file.path(dsnlayer,NomDirSIGBase,"GpsTime_Diff.qml"),
              paste0(substr(nom_Rast_diff,1,nchar(nom_Rast_diff)-4),".qml"),
              overwrite = T)
    
    unlink(nom_Rast1)
    unlink(nom_Rast2)
  }
}