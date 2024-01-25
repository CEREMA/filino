cat("\014")
cat("FILINO_16_11_VRTGPKG.R\n")

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))
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
    
    for (ita in 1:dim(paramTARaster)[1])
    {
      if (dim(paramTARaster)[1]==1)
      {
        dossierRast=paramTARaster$Doss
        extensionRast=paramTARaster$extension
      }else{
        dossierRast=paramTARaster$Doss[ita]
        extensionRast=paramTARaster$extension[ita]
      }
      listeRast=file.path(dossierRast,list.files(dossierRast,pattern=extensionRast,recursive=T))
      
      raciHD=TA_Zone$NOM
      raciHD=gsub(".copc.laz","",raciHD)
      
      longHD=nchar(raciHD)
      
      if (length(unique(longHD))==1)
      {
        listeRast=listeRast[which(is.na(match(substr(basename(listeRast),1,longHD),raciHD))==FALSE)]
        
        nom_vrt = file.path(dossierRast, "listepourvrt.txt")
        racivrt=        gsub(".tif","",
                             gsub(".gpkg","",
                                  extensionRast
                             ))
        racivrt=substr(racivrt,1,nchar(racivrt)-1)
        
        vrtfile=file.path(dossierRast,paste0(ZONE$ZONE[iZone],"_",racivrt,".vrt"))
        
        file.create(nom_vrt)
        write(listeRast, file = nom_vrt, append = T)
        cmd = paste(shQuote(OSGeo4W_path),"gdalbuildvrt",vrtfile,"-input_file_list",nom_vrt)
        print(cmd);system(cmd)
        unlink(nom_vrt)
        
        if (nCalcVRTtoGPKG==1)
        {
          ConvertGPKG(vrtfile,0)
        }
      }
    }
  }
}