# Initialisation des chemins et variables
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))
source(file.path(chem_routine,"FILINO_Utils.R"))

for (iTA in 1:length(dsnTALidar))
{
  
  # Recuperation des parametres de chaque table d'assemblage
  nomlayerTA=nomTALidar[iTA]
  # paramXYTA=as.numeric(ifelse(length(dsnTALidar)==1,paraXYLidar,))
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  reso=as.numeric(resoTALidar[iTA])
  
  dir.create(file.path(dsnlayer,NomDirSurfEAU,racilayerTA))
  
  listeMasq2=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg"))
  listeMasq1=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("Masques1",".gpkg"))
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 1\n")
  Masques1=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,listeMasq1[1]))[,c(1,3)]
  
  # Sauvegarde du fichier d'entree en OLD
  nom_copy=file.path(dsnlayer,NomDirMasque,racilayerTA,
                     paste0(substr(listeMasq2[1],1,nchar(listeMasq2[1])-5),"_",format(Sys.time(),format="%Y%m%d_%H%M"),".gpkg"))
  file.copy(file.path(dsnlayer,NomDirMasque,racilayerTA,listeMasq2[1]),
            nom_copy,overwrite = TRUE)
  
  cmd=paste0(qgis_process, " run native:collect",
             " --INPUT=",shQuote(nom_copy),
             " --FIELD=Id",
             " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,listeMasq2[1])))
  system(cmd)
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
  Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,listeMasq2[1]))
  
  # Calcul de l'aire
  Masques2$Aire=round(st_area(Masques2),0)
  # Renumérotation
  Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
  ##### Codification
  Masques2$Id=FILINO_NomMasque(Masques2)
  Masques2$IdGlobal=Masques2$Id
  
  # Export du nouveau fichier
  st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,listeMasq2[1]), delete_layer=T, quiet=T)
  
  # On ne travaille que sur les nouveaux masques
  ici=grep(Masques2$FILINO,pattern="Vieux")
  if (length(ici)>0){Masques2=Masques2[-ici,]}
  print(unique(Masques2$FILINO))
  
  # Conversion des surfaces en lignes
  Masques1L=st_cast(Masques1,"LINESTRING")
  Masques1L$Id=1:dim(Masques1L)
  
  # Recherche des masques1 contenus masques 2
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," %%%%% Jointure spatiale des Masques1 inclus complètement dans un Masque2 unique\n")
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque1\n")
  st_write(Masques1L,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp.gpkg"),delete_layer=T, quiet=T)
  cmd <- paste0(qgis_process, " run native:createspatialindex",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp.gpkg")))
  system(cmd)
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque2\n")
  st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg"),delete_layer=T, quiet=T)
  
  cmd <- paste0(qgis_process, " run native:createspatialindex",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg")))
  system(cmd)
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Jointure spatiale des Masques1 inclus complètement dans un Masque2 unique\n")
  cmd <- paste0(qgis_process, " run native:joinattributesbylocation",
                " --distance_units=meters",
                " --area_units=m2",
                " --ellipsoid=EPSG:7019 ",
                "--INPUT=",file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp.gpkg"),
                " --PREDICATE=5",
                " --JOIN=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg")),
                " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=false --PREFIX=",
                " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masque1LIdGlobal.gpkg")))
  system(cmd)
  
  dimMasq1=dim(Masques1L)[1]
  Masques1L=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masque1LIdGlobal.gpkg"))
  
  if (dimMasq1!=dim(Masques1L)[1]){BADABOUM=PASLEEMENOMBREDOBKET_BUG}
  
  # Recehcrhe des masques 1 non traités
  nM1b=which(is.na(Masques1L$IdGlobal))
  Masques1L$FILINO="Vide"
  Masques1L$FILINO[-nM1b]="Direct"
  if (Nettoyage==1)
  {
    unlink(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp.gpkg"))
    # unlink(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg"))
    unlink(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masque1LIdGlobal.gpkg"))
  }
  
  
  # Intersection des masques 1 non traités avec les masques 2
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," %%% JOINTURE spatiale des Masques1 restant croisant un ou plusieurs Masques2\n")
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque1 restant\n")
  st_write(Masques1L[nM1b,"Id"],file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp2.gpkg"),delete_layer=T, quiet=T)
  cmd <- paste0(qgis_process, " run native:createspatialindex",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp2.gpkg")))
  system(cmd)
  
  cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1L_tmp2.gpkg")),
                " --PREDICATE=0",
                " --JOIN=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg")),
                " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
                " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1.csv")))
  system(cmd)
  
  liaison=read.csv(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1.csv"))
  
  
  
  if (dim(liaison)[1]>0)
  {
    liaison=liaison[order(liaison$Id,liaison$IdGlobal),]
    # Boucle sur les morceau 1
    # for (i_Inter in which(sapply(n_Inter, length)>0))
    
    Iav=0
    Compl=length(unique(liaison$Id))
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S"),"Découpe des masques 1  croisant plusieurs masques 2\n")
    pgb <- txtProgressBar(min = 0, max = Compl,style=3)
    
    print( unique(liaison$Id))  
    for (i_Interi in unique(liaison$Id))
    {   
      setTxtProgressBar(pgb, Iav)
      Iav=Iav+1
      i_Inter=which(Masques1L$Id==i_Interi)
      cat("\n Masque1 n°",i_Interi)
      # plot(Masques1L[nM1b[i_Inter],1])
      # Boucle sur les divers morceaux de masques 2
      # for (i_InterM2 in n_Inter[[i_Inter]])
      cat(" Masque2")
      for (i_InterM2i in liaison[which(liaison$Id==i_Interi),]$IdGlobal)
      {
        cat(" n°",i_InterM2i)
        i_InterM2=which(Masques2$IdGlobal==i_InterM2i)
        Coupons=st_intersection(st_segmentize(Masques1L[i_Inter,1],1.01*reso),Masques2[i_InterM2,"Id"])
        
        Masques2$IdGlobal
        Masques1L[i_Inter,]$FILINO="Vieux"
        Coupons=st_line_merge(st_cast(Coupons,"MULTILINESTRING"))
        
        # Travail pour nettoyer les bords sinon le conatins marche pas et on aurait 2 points virtuels au même endroit
        frontiere=st_intersection(Masques2[i_InterM2,1])
        frontiere=frontiere[which(st_is(frontiere, c("MULTILINESTRING", "LINESTRING"))),1]
        frontiere=st_buffer(frontiere,reso/2)
        
        if (dim(frontiere)[1]>0)
        {
          Coupons=st_difference(Coupons,st_geometry(frontiere))
        }else{
          Coupons=st_cast(Coupons,"LINESTRING")
          # Suppression du 1er et dernier point des géométries 
          # dans la méthode si on a des lignes droites, on perd un peu trop...
          for (idb in 1:dim(Coupons)[1])
          {
            coord=st_coordinates(Coupons[idb,])
            if (dim(coord)[1]<=3)
            {
              long=st_length(st_geometry(Coupons[idb,]))
              longUnit=0
              units(longUnit)="m"
              if (long>longUnit)
              {
                st_geometry(Coupons[idb,])=st_geometry(st_segmentize((Coupons[idb,]),long/7))
                coord=st_coordinates(Coupons[idb,])
              }
            }
            if (dim(coord)[1]>3)
            {
              st_geometry(Coupons[idb,])=st_simplify(st_sfc(st_linestring(coord[2:(dim(coord)[1]-1),1:2]),crs=2154),preserveTopology =TRUE,dTolerance =0)
            }
          }
        }
        Indic=st_contains(Masques2,Coupons)
        
        #Ajout du champ global de laiison entre Masques1 et 2
        Coupons$IdGlobal=0
        Coupons$FILINO="Vide"
        for (iM2 in which(sapply(Indic, length)>0))
        {
          Coupons[Indic[[iM2]],]$IdGlobal=Masques2[iM2,]$IdGlobal
          Coupons[Indic[[iM2]],]$FILINO="Nouveau"
        }
        
        # st_write(Coupons,
        #          file.path(dsnlayer,NomDirMasque,"Coupons.gpkg"), delete_layer=T, quiet=T)
        
        #rajout des morceaux
        Masques1L=rbind(Masques1L,Coupons)
      }
      cat("\n")
    }
  }
  st_write(Masques1L,
           file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1_FILINO.gpkg"), delete_layer=T, quiet=T)
  ####
  if (file.exists(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro.gpkg"))==TRUE)
  {
    trhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro.gpkg"))
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Troncons Hydro",dim(trhydro),"\n")
    
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque2 sans les vieux\n")
    st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_tmp2.gpkg"),delete_layer=T, quiet=T)
    cmd <- paste0(qgis_process, " run native:createspatialindex",
                  " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                  " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_tmp2.gpkg")))
    system(cmd)
    
    cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
                  " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                  " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro.gpkg")),
                  " --PREDICATE=0",
                  " --JOIN=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_tmp2.gpkg")),
                  " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
                  " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2.csv")))
    system(cmd)
    
    liaison2=read.csv(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2.csv"))
    
    Iav=0
    Compl=length(unique(liaison2$IdGlobal))
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Copie de chaque morceau de tronçon hydro dans le dossier Surfacexxx correspondant\n")
    cat("Cela peut être très long si on copie à nouveau le trhydro sur ceux existant, quand tout est vide, c'est rapide...")
    pgb <- txtProgressBar(min = 0, max = Compl,style=3)
    for (imasq in unique(liaison2$IdGlobal))
    {
      setTxtProgressBar(pgb, Iav)
      Iav=Iav+1
      ntr=unique(liaison2[which(liaison2$IdGlobal==imasq),]$cleabs)
      
      if (length(ntr)>0)
      {
        ncle=sapply(ntr, function(x) {which(trhydro$cleabs==x)})
        rep_SURFEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,imasq))
        if (file.exists(rep_SURFEAU)==F){dir.create(rep_SURFEAU)}
        st_write(trhydro[ncle,],file.path(rep_SURFEAU,"trhydro.gpkg"), delete_layer=T, quiet=T)
      }
    }
    setTxtProgressBar(pgb, Compl)
  }
  cat("\n",format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin\n")
}
