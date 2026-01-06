FILINO_00c_TA=function(dsnlayerTA,nomlayerTA,extension,paramXYTA,qgis_process,Doss_ExpRastCount,pdal_exe)
{
  cat("\014")
  cat("FILINO_02_00c_TablesAssemblagesLazIGN.R\n")
  cat("Nettoyage des anciennes TA\n")
  nomTAexp=file.path(dsnlayerTA,nomlayerTA)
  debraciTA=substr(nomTAexp,1,nchar(nomTAexp)-1-nchar(strsplit(nomTAexp,"\\.")[[1]][length(strsplit(nomTAexp,"\\.")[[1]])]))
  nomTAexpbuf=paste0(debraciTA,"buf.gpkg")
  nomTAexprempli=paste0(debraciTA,"rempli.gpkg")
  nomTAexpvide=paste0(debraciTA,"vide.gpkg")
  unlink(nomTAexp)
  unlink(nomTAexpbuf)
  unlink(nomTAexprempli)
  unlink(nomTAexpvide)
  cat("Fin de Nettoyage des anciennes TA\n")
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," - Recherche parfois longue des fichiers ",extension,"\n")
  cat("Répertoire",dsnlayerTA,"\n")
  listeLAZ=list.files(dsnlayerTA,pattern=extension,recursive="TRUE")
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," - Fin Recherche des fichiers ",extension,"\n")
  
  if (length(listeLAZ)>0)
  {
    
    n_Reso=which(substr(listeLAZ,1,5)=="_Reso")
    if (length(listeLAZ)>length(n_Reso) & length(n_Reso)>0)
    {
      cat("Suppression des fichiers avec sous_dossier reso car il ya plusiuers tyes")
      listeLAZ=listeLAZ[-n_Reso]
    }
    
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
        Opt_TA_Geo=1
        
        cat("Création de la géométrie ",format(Sys.time(),format="%Y-%m-%d_%H:%M:%S"),"\n")
        if (Opt_TA_Geo==0)
        {
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
        }else{
          NLaz=basename(listeLAZ_)
          
          cat("Vérification que vous avez bien paramétrer la position des X et Y de vos noms de fichiers\n")
          cat("Après le nom du fichier, vous devez avoir 2 nombre à 4 chiffres qui apparaissent\n")
          cat("Si ce n'est pas le cas, il vous faut modifier votre variable paramTALidar ou paramTARaster\n")
          
          cat(NLaz[1]," ",
              substr(NLaz[1],Xdeb,Xfin)," ",
              substr(NLaz[1],Ydeb,Yfin),"\n")
          
          xt=as.numeric(substr(NLaz,Xdeb,Xfin))
          yt=as.numeric(substr(NLaz,Ydeb,Yfin))
          
          xabs=1000*(xt+largdalle/1000/2)
          yabs=1000*(yt-largdalle/1000/2)
          
          # #allemagne
          # yabs=yabs+1000
          # nEPSG=25832
          # suisse
          # yabs=yabs+1000
          # nEPSG=2056
          # luxembourg
          # nEPSG=2169
          # BelgFlandres
          # nEPSG=31370
          #BelgWall
          # nEPSG=3812
          
          # Créer des points à partir des coordonnées et les écrire dans un fichier GeoPackage
          Pts <- st_cast(st_sfc(st_multipoint(x = as.matrix(cbind(xabs,yabs)), dim = "XY")), "POINT")
          st_crs(Pts) <- st_crs(nEPSG)
          
          # Créer des carrés à partir des points et les écrire dans un fichier GeoPackage
          Carre <- st_buffer(Pts, endCapStyle = "SQUARE", dist = largdalle/2)
          # st_write(Carre, nomcarre, delete_layer = T, quiet = T)
          
          if (extension==".laz$")
          {
            Gagne=st_sf(data.frame(ID=1:length(listeLAZ_),
                                   CHEMIN=file.path(dsnlayerTA,dirname(listeLAZ_)),
                                   DOSSIER=dirname(listeLAZ_),
                                   NOM=basename(listeLAZ_),
                                   geometry=Carre))
            
          }else{
            Gagne=st_sf(data.frame(ID=1:length(listeLAZ_),
                                   CHEMIN=file.path(dsnlayerTA,dirname(listeLAZ_)),
                                   DOSSIERASC=dirname(listeLAZ_),
                                   NOM_ASC=basename(listeLAZ_),
                                   geometry=Carre))
          }
        }
        cat("Fin Création de la géométrie ",format(Sys.time(),format="%Y-%m-%d_%H:%M:%S"),"\n")
        MutliTA[[iTA]]=Gagne
        iTA=iTA+1
        
      }else{
        cat("\n")
      }
    }
    
    Gagne_MultiTA=dplyr::bind_rows(MutliTA, .id = NULL)
    if (length(MutliTA)>0)
    {
      CalcPixel=0 # Si 1 calcul du nombre de pixels par dalles
      if (CalcPixel==1 & (length(grep(Gagne_MultiTA$NOM_ASC,pattern=paste0(TypeTIN[1],".gpkg","|",TypeTIN[2],".gpkg")))==nrow(Gagne_MultiTA)))
      {
        Gagne_MultiTA$Pixels=0
        # pb <- txtProgressBar(min = 0, max = nrow(Gagne_MultiTA), style = 3)
        #   
        # for (iasc in 1:nrow(Gagne_MultiTA))
        # {
        #   setTxtProgressBar(pb, iasc)
        nb_proc=nb_proc_Filino_[13]
        cat("## ------ ",nrow(Gagne_MultiTA)," dalles à analyser -------------##\n")
        cat("------ ",nb_proc            ," CALCULS MODE PARALLELE -------------\n")
        require(foreach)
        cl <- parallel::makeCluster(nb_proc)
        registerDoParallel(cl)
        foreach(iasc = 1:nrow(Gagne_MultiTA),
                .combine = 'c',
                .inorder = FALSE) %dopar% 
          {
            NomASC=file.path(Gagne_MultiTA$CHEMIN[iasc],Gagne_MultiTA$NOM_ASC[iasc])
            nomTXT= paste0(strsplit(NomASC, "\\.")[[1]][1],".txt")
            cmd <- paste0(qgis_process, " run native:rasterlayerstatistics",
                          " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                          " --INPUT=",NomASC,
                          " --BAND=1",
                          " --OUTPUT_HTML_FILE=",nomTXT)
            print(cmd); system(cmd)
          }
        stopCluster(cl)
        # Lignes=readLines(nomTXT)
        # Gagne_MultiTA$Pixels[iasc]=as.numeric(strsplit(strsplit(Lignes[3], ":")[[1]][2],"<")[[1]][1])
        # }
        cat("------  MODE PARALLELE FINI-------------\n")
        pb <- txtProgressBar(min = 0, max = nrow(Gagne_MultiTA), style = 3)
        for (iasc in 1:nrow(Gagne_MultiTA))
        {
          setTxtProgressBar(pb, iasc)
          NomASC=file.path(Gagne_MultiTA$CHEMIN[iasc],Gagne_MultiTA$NOM_ASC[iasc])
          nomTXT= paste0(strsplit(NomASC, "\\.")[[1]][1],".txt")
          Lignes=readLines(nomTXT)
          Gagne_MultiTA$Pixels[iasc]=as.numeric(strsplit(strsplit(Lignes[3], ":")[[1]][2],"<")[[1]][1])
          unlink(nomTXT)
        }
      }
      
      CalcNptsLAZ=1
      # Reflexion pour calculer le nombre de point à comparer au calcul raster
      
      st_write(Gagne_MultiTA,nomTAexp, delete_dsn = T,delete_layer = T, quiet = T)
      
      if (CalcNptsLAZ==1 & substr(Gagne_MultiTA$NOM[1],nchar(Gagne_MultiTA$NOM[1])-3,nchar(Gagne_MultiTA$NOM[1]))==".laz")
      {
        # browser()
        nb_proc=max(nb_proc_Filino_[2],1)
        cat("## ------ CalcNptsLAZ ",nrow(Gagne_MultiTA)," dalles à analyser -------------##\n")
        # cat("------ ",nb_proc            ," CALCULS MODE PARALLELE -------------\n")
        # require(foreach)
        # cl <- parallel::makeCluster(nb_proc, outfile='')
        # registerDoParallel(cl)
        # foreach(ilaz = 1:nrow(Gagne_MultiTA)) %dopar%
        # foreach::foreach(ilaz = 1:nrow(Gagne_MultiTA),
        #                  .combine = 'c',
        #                  .inorder = FALSE,
        #                  .packages = c("sf","raster")) %dopar%
        pb <- txtProgressBar(min = 0, max = nrow(Gagne_MultiTA), style = 3)
        for (ilaz in 1:nrow(Gagne_MultiTA))
        {
          setTxtProgressBar(pb, ilaz)
          # Chemin du fichier de sortie
          racidalle=Gagne_MultiTA$NOM[ilaz]
          racidalle=gsub(".copc","_copc",substr(racidalle,1,nchar(racidalle)-4))
          # Doss_ExpRastCount=file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles)
          NomTIF=file.path(Doss_ExpRastCount,paste0(racidalle,"_","NbrePOINTS","_","count",".tif"))
          if (file.exists(Doss_ExpRastCount)==F){dir.create(Doss_ExpRastCount,recursive=T)}
          if (!file.exists(NomTIF))
          {
            library(sf)
            library(raster)
            nomlaz=file.path(Gagne_MultiTA$CHEMIN[ilaz],Gagne_MultiTA$NOM[ilaz])
            cmd=paste0(shQuote(pdal_exe)," info ",nomlaz," --summary")
            toto=system(cmd,intern=T)
            
            # Utiliser la fonction grep pour trouver la ligne contenant "num_points"
            num_points_line <- grep("num_points", toto, value = TRUE)
            
            # Extraire la valeur numérique
            num_points_value <- as.numeric(sub(".*\"num_points\": ([0-9]+),.*", "\\1", num_points_line))
            if (is.na(num_points_value)){num_points_value=as.numeric(strsplit(num_points_line,":")[[1]][2])}
            # Définir les paramètres du raster
            
            bbox=st_bbox(Gagne_MultiTA[ilaz,])
            resolution <- 1000
            extent <- extent(c(xmin = bbox[1], xmax = bbox[3], ymin = bbox[2], ymax = bbox[4]))  # Étendue de 1 km²
            # Créer un raster vide
            POINTS_count <- raster(nrows = 1, ncols = 1, ext = extent, res = resolution)
            POINTS_count[1]=num_points_value
            
            # Exporter le raster
            writeRaster(POINTS_count, filename = NomTIF, format = "GTiff", overwrite = TRUE)
          }
        }
        # stopCluster(cl)
        
        cat("------  MODE PARALLELE FINI-------------\n")
      }
      
      
      # nomTAexp=file.path(dsnlayerTA,nomlayerTA)
      # debraciTA=substr(nomTAexp,1,nchar(nomTAexp)-1-nchar(strsplit(nomTAexp,"\\.")[[1]][length(strsplit(nomTAexp,"\\.")[[1]])]))
      # nomTAexpbuf=paste0(debraciTA,"buf.gpkg")
      # nomTAexprempli=paste0(debraciTA,"rempli.gpkg")
      # nomTAexpvide=paste0(debraciTA,"vide.gpkg")
      st_write(Gagne_MultiTA,nomTAexp, delete_dsn = T,delete_layer = T, quiet = T)
      Nom_qml <- if (extension == ".laz$") "TA_ACTION_LAZ.qml" else "TA_Raster.qml"
      
      # Recherche des vides
      # qgis_process run native:buffer --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 --INPUT='G:/LidarHD_MNTIGN_V_0_1/LidarHD_MNTIGN_V_0_1.gpkg|layername=LidarHD_MNTIGN_V_0_1' --DISTANCE=1 --SEGMENTS=5 --END_CAP_STYLE=0 --JOIN_STYLE=0 --MITER_LIMIT=2 --DISSOLVE=true --SEPARATE_DISJOINT=false --OUTPUT=TEMPORARY_OUTPUT
      
      cmd=paste0(qgis_process, " run native:buffer",
                 " --INPUT=",nomTAexp,
                 " --DISTANCE=1 --SEGMENTS=5 --END_CAP_STYLE=0 --JOIN_STYLE=0 --MITER_LIMIT=2 --DISSOLVE=True",
                 " --OUTPUT=",nomTAexpbuf)
      print(cmd);system(cmd)
      
      # Enlever les petits trous
      cmd <- paste0(qgis_process, " run native:deleteholes",
                    " --INPUT=", nomTAexpbuf,
                    " --MIN_AREA=", 0,
                    " --OUTPUT=", nomTAexprempli)
      print(cmd); system(cmd)
      
      cmd <- paste0(qgis_process, " run native:difference",
                    " --INPUT=",nomTAexprempli,
                    " --OVERLAY=",nomTAexpbuf,
                    " --OUTPUT=",nomTAexpvide,
                    " --GRID_SIZE=None")
      print(cmd);system(cmd)
      
      
      file.copy(file.path(dsnlayer,NomDirSIGBase,Nom_qml),
                file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-4),".qml")),
                overwrite = T)
      file.copy(file.path(dsnlayer,NomDirSIGBase,Nom_qml),
                file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-5),".qml")),
                overwrite = T)
      file.copy(file.path(NomDirSIGBase),
                file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-4),".qml")),
                overwrite = T)
      file.copy(file.path(NomDirSIGBase),
                file.path(dsnlayerTA,paste0(substr(nomlayerTA,1,nchar(nomlayerTA)-5),".qml")),
                overwrite = T)
    }
  }
}