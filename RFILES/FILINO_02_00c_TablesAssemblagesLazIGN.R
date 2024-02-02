FILINO_00c_TA=function(dsnlayerTA,nomlayerTA,extension,paramXYTA)
{
  cat("\014")
  cat("FILINO_02_00c_TablesAssemblagesLazIGN.R\n")
  
  cat("Recherche parfois longue des fichiers ",extension,"\n")
  cat("Répertoire",dsnlayerTA)
  listeLAZ=list.files(dsnlayerTA,pattern=extension,recursive="TRUE")
  
  ici=which(is.na(as.numeric(substr(basename(listeLAZ),paramXYTA$Xdeb,paramXYTA$Xfin)))==F &
    is.na(as.numeric(substr(basename(listeLAZ),paramXYTA$Ydeb,paramXYTA$Yfin)))==F)
  if (length(ici)>0){listeLAZ=listeLAZ[ici]}else{}
  
  if (length(listeLAZ)>0)
  {
    if (exists("paramXYTA$COPC"))
    {
      if (paramXYTA$COPC==0)
      {
        # cela devrait planter la dedans
        indcopc=grep(listeLAZ,pattern="copc")
        if( length(indcopc)>0){listeLAZ=listeLAZ[-indcopc]}
        listeLAZ=listeLAZ[nchar(basename(listeLAZ))==paramXYTA$NbreCaratere]
      }
    }
    Res=list()
    tour=list()
    for (i in 1:length(listeLAZ)[1])
    {  
      NLaz=basename(listeLAZ[i])
      
      if (i==1)
      {
        cat("Vérification que vous avez bien paramétrer la position des X et Y de vos noms de fichiers\n")
        cat("Après le nom du fichier, vous devez avoir 2 nombre à 4 chiffres qui apparaissent\n")
        cat("Si ce n'est pas le cas, il vous faut modifier votre variable paramTALidar ou paramTARaster\n")
        
        cat(NLaz," ",
            substr(NLaz,paramXYTA$Xdeb,paramXYTA$Xfin)," ",
            substr(NLaz,paramXYTA$Ydeb,paramXYTA$Yfin),"\n")
      }
      xt=as.numeric(substr(NLaz,paramXYTA$Xdeb,paramXYTA$Xfin))
      yt=as.numeric(substr(NLaz,paramXYTA$Ydeb,paramXYTA$Yfin))
      xabs=1000*c(xt,xt,xt+largdalle/1000,xt+largdalle/1000,xt)
      yabs=1000*c(yt,yt-largdalle/1000,yt-largdalle/1000,yt,yt)
      tour[[1]]=matrix(c(xabs,yabs),5,2)
      
      
      if (extension==".laz$")
      {
        Res[[i]]=st_sf(data.frame(ID=i,
                                  CHEMIN=file.path(dsnlayerTA,dirname(listeLAZ[i])),
                                  DOSSIER=dirname(listeLAZ[i]),
                                  NOM=basename(listeLAZ[i])),
                       "geometry" =st_sfc(st_polygon(tour,dim="XY")),
                       crs=nEPSG)
        
      }else{
        Res[[i]]=st_sf(data.frame(ID=i,
                                  CHEMIN=file.path(dsnlayerTA,dirname(listeLAZ[i])),
                                  DOSSIERASC=dirname(listeLAZ[i]),
                                  NOM_ASC=basename(listeLAZ[i])),
                       "geometry" =st_sfc(st_polygon(tour,dim="XY")),
                       crs=nEPSG)
      }
    }
    
    cat(i,length(Res),"fusion","\n")
    # Gagne = do.call(rbind, Res) # Très long, remplacé par ligne ci-dessous!
    Gagne=dplyr::bind_rows(Res, .id = NULL)
    
    st_write(Gagne,file.path(dsnlayerTA,nomlayerTA), delete_layer=T, quiet=T)
    
    Nom_qml <- if (extension == ".laz$") "TA_ACTION_LAZ.qml" else "TA_Raster.qml"
    
    file.copy(file.path(dsnlayer,NomDirSIGBase,Nom_qml),
              file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-4),".qml")),
              overwrite = T)
    file.copy(file.path(dsnlayer,NomDirSIGBase,Nom_qml),
              file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-5),".qml")),
              overwrite = T)
  }
}