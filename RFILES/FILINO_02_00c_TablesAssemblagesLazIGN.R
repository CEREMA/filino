FILINO_00c_TA=function(dsnlayerTA,nomlayerTA,extension,paramXYTA)
{
  cat("\014")
  cat("FILINO_02_00c_TablesAssemblagesLazIGN.R\n")
  
  cat("Recherche parfois longue des fichiers ",extension,"\n")
  cat("Répertoire",dsnlayerTA,"\n")
  listeLAZ=list.files(dsnlayerTA,pattern=extension,recursive="TRUE")
  
  if (as.numeric(paramXYTA$Yfin)==0)
  {
    nx=as.numeric(paramXYTA$Xdeb)
    ny=as.numeric(paramXYTA$Ydeb)
    nsaut=as.numeric(paramXYTA$Xfin)
    icar_deb=1
    icar_fin=min(nchar(listeLAZ))-3
  }else{
    nx=as.numeric(paramXYTA$Xfin)-as.numeric(paramXYTA$Xdeb)
    ny=as.numeric(paramXYTA$Yfin)-as.numeric(paramXYTA$Ydeb)
    nsaut=as.numeric(paramXYTA$Ydeb)-as.numeric(paramXYTA$Xfin)
    icar_deb=as.numeric(paramXYTA$Xdeb)
    icar_fin=icar_deb
  }
  
  MutliTA=list()
  iTA=1
  for (icar in icar_deb:icar_fin)
  {
    cat(icar)
    ici=which(is.na(as.numeric(substr(basename(listeLAZ),icar,icar+nx-1)))==F &
                is.na(as.numeric(substr(basename(listeLAZ),icar+nx+nsaut,icar+nx+ny+nsaut-1)))==F)
    if (length(ici)>0)
    {
      Xdeb=ifelse(as.numeric(paramXYTA$Yfin)!=0,as.numeric(paramXYTA$Xdeb),icar)
      Xfin=ifelse(as.numeric(paramXYTA$Yfin)!=0,as.numeric(paramXYTA$Xfin),icar+nx-1)
      Ydeb=ifelse(as.numeric(paramXYTA$Yfin)!=0,as.numeric(paramXYTA$Ydeb),icar+nx+nsaut)
      Yfin=ifelse(as.numeric(paramXYTA$Yfin)!=0,as.numeric(paramXYTA$Yfin),icar+nx+ny+nsaut-1)
      
      cat(" Touché\n")
      
      listeLAZ_=listeLAZ[ici]
      listeLAZ=listeLAZ[-ici]
      
      if (exists("paramXYTA$COPC"))
      {
        if (paramXYTA$COPC==0)
        {
          # cela devrait planter la dedans
          indcopc=grep(listeLAZ_,pattern="copc")
          if( length(indcopc)>0){listeLAZ_=listeLAZ_[-indcopc]}
          listeLAZ_=listeLAZ_[nchar(basename(listeLAZ_))==paramXYTA$NbreCaratere]
        }
      }
      Res=list()
      tour=list()
      
      for (i in 1:length(listeLAZ_)[1])
      {  
        NLaz=basename(listeLAZ_[i])
        
        if (i==1)
        {
          cat("Vérification que vous avez bien paramétrer la position des X et Y de vos noms de fichiers\n")
          cat("Après le nom du fichier, vous devez avoir 2 nombre à 4 chiffres qui apparaissent\n")
          cat("Si ce n'est pas le cas, il vous faut modifier votre variable paramTALidar ou paramTARaster\n")
          
          cat(NLaz," ",
              substr(NLaz,Xdeb,Xfin)," ",
              substr(NLaz,Ydeb,Yfin),"\n")
        }
        xt=as.numeric(substr(NLaz,Xdeb,Xfin))
        yt=as.numeric(substr(NLaz,Ydeb,Yfin))
        xabs=1000*c(xt,xt,xt+largdalle/1000,xt+largdalle/1000,xt)
        yabs=1000*c(yt,yt-largdalle/1000,yt-largdalle/1000,yt,yt)
        tour[[1]]=matrix(c(xabs,yabs),5,2)
        
        
        if (extension==".laz$")
        {
          Res[[i]]=st_sf(data.frame(ID=i,
                                    CHEMIN=file.path(dsnlayerTA,dirname(listeLAZ_[i])),
                                    DOSSIER=dirname(listeLAZ_[i]),
                                    NOM=basename(listeLAZ_[i])),
                         "geometry" =st_sfc(st_polygon(tour,dim="XY")),
                         crs=nEPSG)
          
        }else{
          Res[[i]]=st_sf(data.frame(ID=i,
                                    CHEMIN=file.path(dsnlayerTA,dirname(listeLAZ_[i])),
                                    DOSSIERASC=dirname(listeLAZ_[i]),
                                    NOM_ASC=basename(listeLAZ_[i])),
                         "geometry" =st_sfc(st_polygon(tour,dim="XY")),
                         crs=nEPSG)
        }
      }
      
      cat(i,length(Res),"fusion","\n")
      # Gagne = do.call(rbind, Res) # Très long, remplacé par ligne ci-dessous!
      Gagne=dplyr::bind_rows(Res, .id = NULL)
      MutliTA[[iTA]]=Gagne
      iTA=iTA+1
      
      
      
    }else{
      cat("\n")
    }
  }
  Gagne_MultiTA=dplyr::bind_rows(MutliTA, .id = NULL)
  if (length(MutliTA)>0)
  {
    st_write(Gagne_MultiTA,file.path(dsnlayerTA,nomlayerTA), delete_layer=T, quiet=T)
    Nom_qml <- if (extension == ".laz$") "TA_ACTION_LAZ.qml" else "TA_Raster.qml"
    
    file.copy(file.path(dsnlayer,NomDirSIGBase,Nom_qml),
              file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-4),".qml")),
              overwrite = T)
    file.copy(file.path(dsnlayer,NomDirSIGBase,Nom_qml),
              file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-5),".qml")),
              overwrite = T)
  }
}