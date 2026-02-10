cat("\014")
cat("FILINO_16_11_VRTGPKG.R\n")

for (ita in 1:dim(paramTARaster)[1])
{
  if (dim(paramTARaster)[1]==1)
  {
    dossierRast=paramTARaster$Doss
    extensionRast=paramTARaster$extension
    nomTARast=paramTARaster$NomTA
  }else{
    dossierRast=paramTARaster$Doss[ita]
    extensionRast=paramTARaster$extension[ita]
    nomTARast=paramTARaster$NomTA[ita]
  }
  
  TA=st_read(file.path(dossierRast,nomTARast))
  
  nb=st_intersects(TA,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    cat("##################################################################\n")
    cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
    cat("##################################################################\n")
    
    TA=TA[n_int,]
    for (iZone in 1:dim(ZONE)[1])
    {
      
      nb=st_intersects(TA,ZONE[iZone,])
      n_int = which(sapply(nb, length)>0)
      
      TA_Zone=TA[n_int,]
      
      listeRast=file.path(dossierRast,TA_Zone$DOSSIERASC,TA_Zone$NOM_ASC)
      
      nom_vrt = file.path(dossierRast, "listepourvrt.txt")
      racivrt=        gsub(".tif","",
                           gsub(".gpkg","",
                                extensionRast
                           ))
      racivrt=substr(racivrt,1,nchar(racivrt)-1)
      
      vrtfile=file.path(dossierRast,paste0(ZONE$ZONE[iZone],"_",racivrt,"_",strsplit(nomTARast,"\\.")[[1]][1],".vrt"))
      
      file.create(nom_vrt)
      write(listeRast, file = nom_vrt, append = T)
      cmd = paste(shQuote(OSGeo4W_path),"gdalbuildvrt",vrtfile,"-input_file_list",nom_vrt)
      print(cmd);system(cmd)
      unlink(nom_vrt)
      
      if (nCalcVRTtoGPKG==1)
      {
        ConvertGPKG(vrtfile,1)
      }
    }
  }
}
cat("\n")
cat("\n")
cat("########################################################################################################\n")
cat("######################### FILINO A LIRE SVP ###############################################################\n")
cat("---------------- ETAPE FILINO_16_11_VRTGPKG.R #######################################\n")
cat("\n")
cat("\ Ouvrir le gpkg qui commence comme:  ",vrtfile,"    \n")
cat("\n")
cat("Ensuite, vous pouvez appliquer des styles prédéfinis\n")
cat("\n")
cat("######################### Fin FILINO A LIRE ###############################################################\n")
cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
cat("\n")
