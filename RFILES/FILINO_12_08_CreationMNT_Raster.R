FILINO_12_08_CreationMNT_Raster_Job=function(idalle)
{
  # print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
  racidalle=TAHDCla[idalle,]$NOM
  racidalle=gsub(".copc","_copc",substr(racidalle,1,nchar(racidalle)-4))
  cat(round(100*idalle/dim(TAHDCla)[1]), "% " ,racidalle,"\n")
  for (igdal in 1:dim(ClassPourMNTGDAL)[1])
  {
    NomTIF=file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles,paste0(racidalle,"_",ClassPourMNTGDAL[igdal,3],"_",ClassPourMNTGDAL[igdal,2],".tif"))
    NomGPKG=paste0(substr(NomTIF,1,nchar(NomTIF)-4),".gpkg")
    
    if (file.exists(NomGPKG)==T)
    {
      cat("Déjà fait GPKG",NomGPKG,"\n")
    }else{
      # cat("\014")
      # cat(round(100*idalle/dim(TAHDCla)[1]), "% " ,racidalle)
      if (file.exists(NomTIF)==T)
      {
        cat(" déjà fait TIF","\n")
      }else{
        cat("Procédure PDAL",ClassPourMNTGDAL[igdal,],"\n")
        
        NLaz=racidalle
        Ouest=largdalle*as.numeric(substr(NLaz,paramXYTA$Xdeb,paramXYTA$Xfin))
        Nord=largdalle*as.numeric(substr(NLaz,paramXYTA$Ydeb,paramXYTA$Yfin))
        Est=as.character(Ouest+largdalle)
        Sud=as.character(Nord-largdalle)
        Ouest=as.character(Ouest)
        Nord=as.character(Nord)
        
        NomLaz=file.path(dsnlayerTA,TAHDCla[idalle,]$DOSSIER,TAHDCla[idalle,]$NOM)
        
        nomjson=file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles,paste0(racidalle,"MNT_Raster.json"))
        FILINO_Creat_Dir(dirname(nomjson))
        
        FILINO_writers_gdal(nomjson,NomLaz,ClassPourMNTGDAL[igdal,1],ClassPourMNTGDAL[igdal,2],reso,Ouest,Est,Sud,Nord,basename(NomTIF))
        
        # #####
        # 
        # nomlaz_tmp=basename(NomLaz)
        # write("[",nomjson)
        # write("    {",nomjson,append=T)
        # write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
        # write(paste0("       ",shQuote("filename"),":",shQuote(file.path(dsnlayerTA,TAHDCla[idalle,]$DOSSIER,nomlaz_tmp)),","),nomjson,append=T)
        # write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG))),nomjson,append=T)
        # write("    },",nomjson,append=T)
        # 
        # write("    {",nomjson,append=T)
        # write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        # write(paste0("       ",shQuote("limits"),":",shQuote(ClassPourMNTGDAL[igdal,1])),nomjson,append=T)
        #         write("    },",nomjson,append=T)
        # 
        # write("    {",nomjson,append=T)
        # write(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","),nomjson,append=T)
        # write(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","),nomjson,append=T)
        # write(paste0("       ",shQuote("output_type"),":",shQuote(ClassPourMNTGDAL[igdal,2]),","),nomjson,append=T)
        # write(paste0("       ",shQuote("resolution"),":"," ",reso,","),nomjson,append=T)
        # write(paste0("       ",shQuote("radius"),":"," ",sqrt(reso),","),nomjson,append=T)
        # write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est)-0.5,"],[",Sud,",",as.numeric(Nord)-0.5,"])")),","),nomjson,append=T)
        # write(paste0("       ",shQuote("filename"),":",shQuote(NomTIF)),nomjson,append=T)
        # write("    }",nomjson,append=T)
        # write("]",nomjson,append=T)
        # 
        # cmd=paste("C:\\QGIS\\bin\\pdal.exe pipeline",nomjson)
        # 
        # system(cmd)
      }
      
      ConvertGPKG(NomTIF,1)
      
      # cmd = paste0(shQuote(OSGeo4W_path)," gdal_translate ", "-of GPKG ","--config OGR_SQLITE_SYNCHRONOUS OFF ", "-co  APPEND_SUBDATASET=YES ", "-co TILE_FORMAT=PNG_JPEG ",shQuote(NomTIF)," ",shQuote(NomGPKG))
      # system(cmd)
      # 
      # cmd = paste0(shQuote(OSGeo4W_path)," gdaladdo ","--config OGR_SQLITE_SYNCHRONOUS OFF ", "-r AVERAGE ",NomGPKG," 2 4 8 16 32 64 128 256")
      # system(cmd)
      
      Sys.sleep(1);unlink(NomTIF)
    }
  }
}