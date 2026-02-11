# Initialisation des chemins et variables
chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
source(file.path(chem_routine,"FILINO_0_Initialisation.R"))

# Boucle sur les différentes tables d'assemblage
for (iTA in 1:length(dsnTALidar))
{
  # Recuperation des parametres de chaque table d'assemblage
  dsnlayerTA=dsnTALidar[iTA]
  nomlayerTA=nomTALidar[iTA]
  reso=as.numeric(resoTALidar[iTA])
  # paramXYTA=as.numeric(paraXYLidar[iTA,])
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  
  # Lecture de la table d'assemblage
  TA=st_read(file.path(dsnlayerTA,nomlayerTA))
  
  # Limitation de la table d'assemblage aux zones à traiter
  nb=st_intersects(TA,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    cat("##################################################################\n")
    cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
    cat("##################################################################\n")
    TA=TA[n_int,]
    
    for (iLAZ in 1:dim(TA)[1])
    {
      TA_tmp=TA[iLAZ,]
      
      if (is.null(TA_tmp$CHEMIN))
      {
        # Lidar Hd brut
        NomLaz=basename(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
        ChemLaz=dirname(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
      }else{
        # Lidar HD classif
        NomLaz=TA_tmp$NOM
        ChemLaz=TA_tmp$CHEMIN
      }
      
      cat("###############################################################\n")
      cat("Passage R",iLAZ,"sur", dim(TA)[1],"\n")
      cat("#######################",TA_tmp$NOM,"\n")
      
      raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
      
      cat("###############################################################\n")
      
      FILINO_Creat_Dir(file.path(dsnlayer,NomDirPonts,racilayerTA))
      
      # Creation d'un pipeline pdal pour fusionner les différents fichiers et exporter en csv pour un traitement R
      cat("","\n")
      nomjson=file.path(dsnlayer,NomDirPonts,racilayerTA,paste0(raci,"_",racilayerTA,"_MyScript.json"))
      
      
      write("[",nomjson)
      write("    {",nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
      write(paste0("       ",shQuote("filename"),":",shQuote(file.path(ChemLaz,NomLaz)),","),nomjson,append=T)
      write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
      write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
      write("    },",nomjson,append=T)
      write("    {",nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
      write(paste0("       ",shQuote("limits"),":",shQuote("Classification[17:17]")),nomjson,append=T)
      write("    },",nomjson,append=T)
      write("    {",nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("writers.text"),","),nomjson,append=T)
      write(paste0("       ",shQuote("format"),":",shQuote("csv"),","),nomjson,append=T)
      write(paste0("       ",shQuote("order"),":",shQuote("X,Y,Z,Classification"),","),nomjson,append=T)
      write(paste0("       ",shQuote("keep_unspecified"),":",shQuote("false"),","),nomjson,append=T)
      nomcsv=file.path(dsnlayer,NomDirPonts,racilayerTA,paste0(raci,racilayerTA,"_Ponts.csv"))
      write(paste0("       ",shQuote("filename"),":",shQuote(nomcsv)),nomjson,append=T)
      write("    }",nomjson,append=T)
      write("]",nomjson,append=T)
      cmd=paste(pdal_exe,"pipeline",nomjson)
      
      system(cmd)
      if (Nettoyage==1){Sys.sleep(0.1);unlink(nomjson)}
      
      PtsCSV=read.csv(nomcsv)
      if (dim(PtsCSV)[1]>0)
      {
        PtsCSV_sf=st_sf(cbind(PtsCSV,geometry=st_cast(st_sfc(geometry=st_multipoint(x = as.matrix(PtsCSV[,1:3]), dim = "XYZ")),"POINT")))
        nomPonts=file.path(dsnlayer,NomDirPonts,racilayerTA,paste0(raci,racilayerTA,"_Ponts.gpkg"))
        Ponts=st_buffer(st_union(st_buffer(PtsCSV_sf[,4],reso)),-reso)
        st_write(Ponts,nomPonts, delete_layer=T, quiet=T)
      }
    }
  }
}
