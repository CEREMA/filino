#### On a euun bug sur les données troncons hydro de type Retenue-barrage
#### A voir si on doit l'intégrer ici

cat("\014")
cat("FILINO_04_01b_MasqueEau.R - Etap1b[1]\n")

# lecture des zones militaires pour les exclure
ZICAD=st_transform(
  st_read(nomZICAD),
  st_crs(nEPSG))

# Contour des Départements
Departement=st_read(nomDpt)

#Département Mer, pour tester si on est en mer ou à terre
Dpt_Inv_Mer=st_read(nomBuf_pour_mer)

# Gestion pour la limitation de l'import
bbox=st_bbox(ZONE)
bbox$xmin=floor(bbox$xmin/1000)*1000
bbox$xmax=ceiling(bbox$xmax/1000)*1000
bbox$ymin=floor(bbox$ymin/1000)*1000
bbox$ymax=ceiling(bbox$ymax/1000)*1000

bbox_wkt <- paste0("POLYGON((",bbox$xmin, " ",bbox$ymin, ",",bbox$xmax, " ",bbox$ymin, ",",bbox$xmax, " ",bbox$ymax, ",",bbox$xmin, " ",bbox$ymax, ",",bbox$xmin, " ",bbox$ymin, "))")

setwd(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles))

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  # réduction sur les dalles electionnées
  TA=TA[n_int,]
  
  if (Etap1b[1]==1)
  {
    
    cat("\014")
    cat("FILINO_04_01b_MasqueEau.R - Etap1b[1]\n")
    Masques1=FILINO_FusionMasque(NomDirMasqueVIDE,TA,"Masque",1)
    Masques1=Masques1[order(Masques1$Aire,decreasing=TRUE),]
    Masques1$Id=1:dim(Masques1)[1]
    st_write(Masques1,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.gpkg"), delete_layer=T, quiet=T)
    
    ##############################################################
    Masques2=FILINO_FusionMasque(NomDirMasqueVIDE,TA,"Masque",2)
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg"), delete_layer=T, quiet=T)
  }
  
  if (Etap1b[2]==1)
  {  
    cat("\014")
    cat("FILINO_04_01b_MasqueEau.R - Etap1b[2]\n")
    # Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.gpkg"))
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg"))
    
    # Intersection des départements
    nb=st_intersects(Departement,Masques2)
    n_int = which(sapply(nb, length)>0)
    Dpt=Departement[n_int,]
    
    # Boucle sur les départements qui intersectent la donnée
    LSH=list()
    LTr=list()
    LCS=list()
    
    # fusion des divers départements intersecté
    # la BDTopo n'a pas la même structure, on doit gérer les champs...
    for (iDpt in 1:dim(Dpt)[1])
    {
      # ouverture de la BDTopo
      listeDpt=list.files(dsnDepartement,pattern=paste0("_D",ifelse(nchar(Dpt$INSEE_DEP[iDpt])==2,paste0("0",Dpt$INSEE_DEP[iDpt]),Dpt$INSEE_DEP[1]),"-"),recursive=T)
      listeDpt=file.path(dsnDepartement,listeDpt[grep(listeDpt,pattern=".gpkg")])
      if (length(listeDpt)==0)
      {
        cat("BDTopo non présente ",Dpt$INSEE_DEP[iDpt]," Merci de la télécharger\n")
        Badaboom=boom
      }
      
      dsnlayerCE=dirname(listeDpt)
      nomgpkgCE=basename(listeDpt)
      ######################################################################################
      ##### Lecture des surfaces hydrographiques
      nomlayer="surface_hydrographique"
      cat("Si vous avez une erreur - (Erreur dans if (nchar(dsn) < 1) stop(dsn must point to a source, not an empty string.)\n" )
      cat("Cela veut dire que vous n'arrivez pas à récupérer des données de la BDTopo avec le découpage de votre zone de travail, agrandissez ou reduisez là!\n" )
      surfhydro=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer,wkt_filter = bbox_wkt)
      st_geometry(surfhydro)="geometry"
      LSH[[iDpt]]=surfhydro[,cbind("cleabs","nature")]
      # cat(nomlayer,dim(surfhydro),"\n")
      
      ######################################################################################
      ##### Lecture des troncons hydrographiques
      nomlayer="troncon_hydrographique"
      cat("Si vous avez une erreur - (Erreur dans if (nchar(dsn) < 1) stop(dsn must point to a source, not an empty string.)\n" )
      cat("Cela veut dire que vous n'arrivez pas à récupérer des données de la BDTopo avec le découpage de votre zone de travail, agrandissez ou reduisez là!\n" )
      trhydro=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer,wkt_filter = bbox_wkt)
      st_geometry(trhydro)="geometry"
      # cleabs nature sens_de_l_ecoulement liens_vers_cours_d_eau
      LTr[[iDpt]]=trhydro[,cbind("cleabs","nature","position_par_rapport_au_sol","sens_de_l_ecoulement","liens_vers_cours_d_eau")]
      # cat(nomlayer,dim(trhydro),"\n")
      
      ######################################################################################
      ##### Lecture des constructions hydrographiques
      nomlayer="construction_surfacique"
      cat("Si vous avez une erreur - (Erreur dans if (nchar(dsn) < 1) stop(dsn must point to a source, not an empty string.)\n" )
      cat("Cela veut dire que vous n'arrivez pas à récupérer des données de la BDTopo avec le découpage de votre zone de travail, agrandissez ou reduisez là!\n" )
      constsurf=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer,wkt_filter = bbox_wkt)
      st_geometry(constsurf)="geometry"
      LCS[[iDpt]]=constsurf[,cbind("cleabs","nature")]
    }
    
    # Fusion et nettoyage des doublons de deux départements...
    surfhydro=do.call(rbind, LSH)
    surfhydro=surfhydro[order(surfhydro$cleabs),]
    surfhydro$doublons=0
    for (i in 2:dim(surfhydro)[1])
    {
      if (surfhydro$cleabs[i]==surfhydro$cleabs[i-1]){surfhydro$doublons[i]=1}
    }
    surfhydro=surfhydro[which(surfhydro$doublons==0),]
    
    # Fusion et nettoyage des doublons de deux départements...
    trhydro=do.call(rbind, LTr)
    trhydro=trhydro[order(trhydro$cleabs),]
    trhydro$doublons=0
    for (i in 2:dim(trhydro)[1])
    {
      if (trhydro$cleabs[i]==trhydro$cleabs[i-1]){trhydro$doublons[i]=1}
    }
    trhydro=trhydro[which(trhydro$doublons==0),]
    
    # Fusion et nettoyage des doublons de deux départements...
    constsurf=do.call(rbind, LCS)
    constsurf=constsurf[order(constsurf$cleabs),]
    if (dim(constsurf)[1]>1)
    {
      constsurf$doublons=0
      constsurf$doublons=0
      for (i in 2:dim(constsurf)[1])
      {
        if (constsurf$cleabs[i]==constsurf$cleabs[i-1]){constsurf$doublons[i]=1}
      }
      constsurf=constsurf[which(constsurf$doublons==0),]
    }
    # Intersection des 
    nbMSh=st_intersects(Masques2,surfhydro)
    n_intMSh = which(sapply(nbMSh, length)>0)
    
    # units(seuilSup1)="m^2"
    
    # Travail sur les gros masques
    # Masques2$QUOI="GROS"
    # Masques2$QUOI[n_intMSh]="SurfaceHydro"
    # Masques2$QUOI[which(Masques2$Aire>seuilSup1)]="GROSetSurfaceHydro"
    Masques2=Masques2[unique(c(n_intMSh,which(Masques2$Aire>seuilSup1))),]
    
    Masques2=st_cast(Masques2,"POLYGON")##### voir si OK 05/03/2024
    # ajout de l'aire et travail par ordre decroissant
    Masques2=Masques2[order(Masques2$Aire,decreasing=TRUE),] 
    
    ##### Codification
    Masques2$Id=1:dim(Masques2)[1]
    
    # if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Masques2_Gros_et_SurfEauBDTopo",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
    # if (verif==1){
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo.gpkg"), delete_layer=T, quiet=T)
    # }
    
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial surfhydro restant\n")
    st_write(surfhydro,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.gpkg"),delete_layer=T, quiet=T)
    cmd <- paste0(qgis_process, " run native:createspatialindex",
                  " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                  " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.gpkg")))
    system(cmd)
    
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Trhydro restant\n")
    st_write(trhydro,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg"),delete_layer=T, quiet=T)
    cmd <- paste0(qgis_process, " run native:createspatialindex",
                  " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                  " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg")))
    system(cmd)
    trhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg"))
    
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial constsurf restant\n")
    st_write(constsurf,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"constsurf_tmp.gpkg"),delete_layer=T, quiet=T)
    cmd <- paste0(qgis_process, " run native:createspatialindex",
                  " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                  " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"constsurf_tmp.gpkg")))
    system(cmd)
    
    cat("Etape1b_2 terminée")
    # Rprof(NULL)
    # summaryRprof()
  }
  
  if (Etap1b[3]==1)
  {  
    cat("\014")
    cat("FILINO_04_01b_MasqueEau.R - Etap1b[3]\n")
    # Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.gpkg"))
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo.gpkg"))
    Masques2=arrange(Masques2,Id)
    #### initialisation
    ngros=data.frame(Gros=which(Masques2$Aire>=seuilSup2),Tour=0)
    units(seuilSup3)="m"
    it=0
    
    #### bug constaté le 05/03/2024
    while(max(ngros$Tour)>=it)
    {
      cat("#####################\n")
      it=it+1
      cat("Tour ",it,"\n")
      
      #### boucle
      # npetit=which(Masques2$Id>(max(ngros$Gros)+1))
      npetit=which(Masques2$Id>(max(ngros$Gros))) # modif du 05/03/2024
      
      for (ip in which(ngros$Tour==(it-1)))
      {
        cat("Tour ",it," - Masque - ",ip)
        if (ngros$Tour[ip]>=it-1)
        {
          ngp=st_intersects(Masques2[npetit,1],st_buffer(st_as_sfc(st_bbox(Masques2[ngros$Gros[ip],1])),10))
          nint_ngp=which(sapply(ngp, length)>0)
          
          # st_write(Masques2[npetit[nint_ngp],1],file.path(dsnlayer,NomDirMasqueVIDE,paste0("petiti",".gpkg")), delete_layer=T, quiet=T)
          # st_write(Masques2[ngros$Gros[ip],1],file.path(dsnlayer,NomDirMasqueVIDE,paste0("grios",".gpkg")), delete_layer=T, quiet=T)
          # st_write(st_buffer(st_as_sfc(st_bbox(Masques2[ngros$Gros[ip],1])),10),file.path(dsnlayer,NomDirMasqueVIDE,paste0("buffons",".gpkg")), delete_layer=T, quiet=T)
          
          if(length(nint_ngp)>0)
          {
            valeurs=st_distance(Masques2[ngros$Gros[ip],1],Masques2[npetit[nint_ngp],1])
            lala=which(valeurs<seuilSup3)
            if (length(lala)>0)
            {
              # cat("valeurs",round(valeurs,1),"\n")
              cat(" - Indices a modifer",Masques2[npetit[nint_ngp[lala]],]$Id)
              Masques2[npetit[nint_ngp[lala]],]$Id=ip
              ngros$Tour[ip]=it
            }
          }
        }
        cat("\n")
      }
      if (max(ngros$Tour)==it)
      {
        # st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Masques2_Gros_et_SurfEauBDTopo_Indices",it,"_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)
        cat("#####################\n")
        cat("Fusion des géométries avec même indice\n")
        
        cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Début de fusion des masques Qgis","\n")
        nomMasque2_tmp=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_tmp.gpkg"))
        nomMasque2_tmp2=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_tmp2.gpkg"))
        st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_tmp.gpkg")), delete_layer=T, quiet=T)
        
        cmd=paste0(qgis_process, " run native:collect",
                   " --INPUT=",shQuote(nomMasque2_tmp),
                   " --FIELD=Id",
                   " --OUTPUT=",shQuote(nomMasque2_tmp2))
        system(cmd)
        # Masques2_Qgis=st_read(nomMasque2_tmp2)
        Masques2=st_read(nomMasque2_tmp2)
        Masques2=arrange(Masques2,Id)
        cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin de fusion des masques Qgis","\n")
        
        Masques2$Aire=round(st_area(Masques2),0)
        
        if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion",it-1,".gpkg")), delete_layer=T, quiet=T)}
      }else{
        if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion",it-1,".gpkg")), delete_layer=T, quiet=T)}
      }
    }
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion.gpkg")), delete_layer=T, quiet=T)
    # On peut se demander pourquoi ne pas garder les petits masques qui intersectent des tronçons hydro
    # Il semble plus pertinent de faire une autre routine (Filino3)
  }
  
  if (Etap1b[4]==1)
  { 
    cat("\014")
    cat("FILINO_04_01b_MasqueEau.R - Etap1b[4]\n")
    # Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.gpkg"))
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo_IndicesFusion.gpkg"))
    st_geometry(Masques2)="geometry"
    surfhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.gpkg"))
    trhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg"))
    
    constsurf=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"constsurf_tmp.gpkg"))
    
    # # on en garde que les gros masques et les petits dans des surfaces en eau "planes"
    # # Intersection des 
    # st_write(surfhydro[which(surfhydro$nature!="Ecoulement naturel"),1],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp_EN.gpkg"), delete_layer=T, quiet=T)
    # 
    # nomA=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo_IndicesFusion.gpkg")
    # nomB=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp_EN.gpkg")
    # nomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp.csv")
    # liaison=FILINO_Intersect_Qgis(nomA,nomB,nomC)
    # Masques2=Masques2[unique(liaison$fid),]
    
    # 20240524 SUPPRESSION HAZARDEUSE
    nbMSh=st_intersects(Masques2,surfhydro[which(surfhydro$nature!="Ecoulement naturel"),1])
    # nbMSh=st_intersects(Masques2,surfhydro[,1])
    # 20240524 SUPPRESSION HAZARDEUSE
    n_intMSh = which(sapply(nbMSh, length)>0) 
    # Modif du 10/01/2024, on peut essayer de garder les petits dans les surfaces en eau
    Masques2=Masques2[unique(rbind(as.matrix(which(Masques2$Aire>seuilSup1)),as.matrix(n_intMSh))),]
    
    
    # trois lignes ci-dessous non concluantes
    # units(seuilSup2)="m2"
    # n_intMGros=which(st_area(Masques2)>seuilSup2)
    # Masques2=Masques2[unique(rbind(as.matrix(which(Masques2$Aire>seuilSup1)),as.matrix(n_intMSh),as.matrix(n_intMGros))),]
    
    Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
    Masques2$Id=1:dim(Masques2)[1]
    
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_Petits_SurfEauBDTopo_Plane.gpkg"), delete_layer=T, quiet=T)
    
    nomA=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.gpkg")
    # nomB=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_Petits_SurfEauBDTopo_Plane.gpkg")
    nomB=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg")
    nomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.csv")
    liaison=FILINO_Intersect_Qgis(nomA,nomB,nomC)
    
    surfhydro=surfhydro[unique(liaison$fid),]
    surfhydro$F_Sh="PlanEau"
    ici=grep(surfhydro$nature,pattern="Ecoul")
    if (length(ici)>0) {surfhydro[ici,]$F_Sh="Ecoulement"}
    ici=grep(surfhydro$nature,pattern="Canal")
    if (length(ici)>0) {surfhydro[ici,]$F_Sh="Canal"}
    
    st_write(surfhydro,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro.gpkg"), delete_layer=T, quiet=T)
    
    # Appareillage des types de surfaces en eau sur les masques
    Masques2$PlanEau=""
    ici=which(surfhydro$F_Sh=="PlanEau")
    if (length(ici)>0)
    {
      nbShM=st_intersects(Masques2,surfhydro[ici,1])
      n_intShM = which(sapply(nbShM, length)>0)
      if (length(n_intShM)>0)
      {
        Masques2[n_intShM,]$PlanEau="PlanEau"
      }
      # Masques2[which(sapply(nbShM, length)>0),]$PlanEau="PlanEau"
    }
    
    Masques2$Canal=""
    ici=which(surfhydro$F_Sh=="Canal")
    if (length(ici)>0)
    {
      nbShM=st_intersects(Masques2,surfhydro[ici,1])
      n_intShM = which(sapply(nbShM, length)>0)
      if (length(n_intShM)>0)
      {
        Masques2[n_intShM,]$Canal="Canal"
      }
      # Masques2[which(sapply(nbShM, length)>0),]$Canal="Canal"   
    }
    
    Masques2$Ecoulement=""
    ici=which(surfhydro$F_Sh=="Ecoulement")
    if (length(ici)>0)
    {
      nbShM=st_intersects(Masques2,surfhydro[ici,1])
      n_intShM = which(sapply(nbShM, length)>0)
      if (length(n_intShM)>0)
      {
        Masques2[n_intShM,]$Ecoulement="Ecoulement"
      }
    }
    
    Masques2$F_Sh=paste0(Masques2$PlanEau,Masques2$Canal,Masques2$Ecoulement)
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEau.gpkg"), delete_layer=T, quiet=T)
    
    ######################################################################################
    ##### Lecture des troncons hydrographiques
    # Intersection des masques et troncon hydro ene au
    
    # cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masques2 restant\n")
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp.gpkg"),delete_layer=T, quiet=T)
    nomA=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg")
    # nomB=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp.gpkg")
    nomB=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg")
    nomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.csv")
    liaison=FILINO_Intersect_Qgis(nomA,nomB,nomC)
    
    
    if (dim(liaison)[1]>0)
    {
      # récupération des cours d'eau qui croisent des masques
      trhydro_=trhydro[unique(liaison$fid),]
      
      # Rajout des tronçons de cours d'eau nommés qui ne croisent pas (éviter d'avoir un troncon coupé en deux pour un même masque)
      nomCE=unique(trhydro_$liens_vers_cours_d_eau)
      if (length(which(is.na(nomCE)==F))>0)
      {
        nomCE=nomCE[which(is.na(nomCE)==F)]
        voila=lapply(nomCE, function(x) {trhydro[which(trhydro$liens_vers_cours_d_eau==x),]})
        trhydro=rbind(trhydro_,do.call(rbind, voila))
      }
      
      trhydro=trhydro[order(trhydro$cleabs),]
      trhydro$doublons=0
      for (i in 2:dim(trhydro)[1])
      {
        if (trhydro$cleabs[i]==trhydro$cleabs[i-1]){trhydro$doublons[i]=1}
      }
      trhydro=trhydro[which(trhydro$doublons==0),]
      st_write(trhydro,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_peutetremieux.gpkg"),delete_layer=T, quiet=T)
      
      trhydro$F_Tr=""
      ici=grep(trhydro$nature,pattern="Ecoul")
      if (length(ici)>0) {trhydro[ici,]$F_Tr="Ecoulement"}
      ici=grep(trhydro$nature,pattern="Reten")
      if (length(ici)>0) {trhydro[ici,]$F_Tr="Ecoulement"}
      ici=grep(trhydro$nature,pattern="Canal")
      if (length(ici)>0) {trhydro[ici,]$F_Tr="Canal"}
      ici=grep(trhydro$sens_de_l_ecoulement,pattern="Double sens")
      if (length(ici)>0) {trhydro[ici,]$F_Tr=""}
      ici=which(is.na(trhydro$liens_vers_cours_d_eau))
      if (length(ici)>0) {trhydro[ici,]$F_Tr=""}
      # st_write(trhydro,file.path(dsnlayer,NomDirMasqueVIDE,paste0("trhydro_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)
      st_write(trhydro,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg"), delete_layer=T, quiet=T)
      
      trhydro=trhydro[which(nchar(trhydro$F_Tr)>0),]
      
      # suppression des masques ecoulement si aucun troncon hyhdro ecoulement
      nbtrM=st_intersects(Masques2,trhydro[which(trhydro$F_Tr=="Ecoulement"),1])
      ici=which(sapply(nbtrM, length)>0)
      if (length(ici)>0 & length(ici)!=dim(Masques2)[1]){Masques2[-ici,]$Ecoulement=""}
      
      # suppression des masques canal si aucun troncon hyhdro ecoulement
      nbtrM=st_intersects(Masques2,trhydro[which(trhydro$F_Tr=="Canal" ),1])
      ici=which(sapply(nbtrM, length)>0)
      if (length(ici)>0 & length(ici)!=dim(Masques2)[1]){Masques2[-ici,]$Canal=""}
      
      # suppression des masques canal si aucun troncon hyhdro ecoulement
      nbtrM=st_intersects(Masques2,trhydro[,1])
      ici=which(sapply(nbtrM, length)>0)
      # rajouter test pour voir si plan eau vide, et ne remplir que les vides
      if (length(ici)>0 & length(ici)!=dim(Masques2)[1])
      {
        # Masques2[-ici,]$PlanEau="PlanEau_Tr"
        iciPlanEau=which(Masques2[-ici,]$PlanEau=="")
        if (length(iciPlanEau)>0)
        {
          Masques2[-ici,][iciPlanEau,]$PlanEau="PlanEau_Tr"
        }
      }
    }else{
      cat("Pas de troncons hydro dans vos masques - Export d'un fichier vide - Attente 10s")
      var=1:dim(trhydro)[1]
      trhydro=st_cast(trhydro[-var,],"MULTILINESTRING")
      st_write(trhydro,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg"), delete_layer=T, quiet=T)
      # sys.sleep(10)
    }
    # test pour enlever les types de surfaces en eau qui seraient avec des tronçons supprimé précédement
    Masques2$F_Sh_Tr=paste0(Masques2$PlanEau,Masques2$Canal,Masques2$Ecoulement)
    
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydro.gpkg"), delete_layer=T, quiet=T)
    
    
    for (iFShTr in cbind("Canal","Ecoulement"))
    {
      cat("Association des petits morceaux de ",iFShTr)
      
      if (iFShTr=="Ecoulement")
      {
        nbFShFr=which(Masques2$F_Sh_Tr==iFShTr)
        distbufAsso=15
      }
      
      if (iFShTr=="Canal")
      {
        nbFShFr=which(Masques2$F_Sh=="Canal" & (Masques2$F_Sh_Tr=="Canal" | Masques2$F_Sh_Tr=="PlanEau_Tr"))
        distbufAsso=10
      }
      
      print(length(nbFShFr))
      if (length(nbFShFr)>1)
      {
        polygones=Masques2[nbFShFr,]
        
        # Créer des buffers de 5 mètres autour de chaque polygone
        cat("Début du buffer proposé Mistral, à voir si pas trop long")
        buffers <- st_buffer(polygones, dist = distbufAsso)
        # Fusionner tous les buffers qui se chevauchent
        buffers_fusionnes <- st_cast(st_union(buffers),"POLYGON")
        st_write(buffers,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"buffers.gpkg"), delete_layer=T, quiet=T)
        cat("Fin du buffern")
        
        # Trouver l'intersection entre les polygones d'origine et les buffers fusionnés
        polygones_associes <- st_intersection(st_union(polygones), buffers_fusionnes)
        st_write(polygones_associes,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"polygones_associes.gpkg"), delete_layer=T, quiet=T)
        
        DF=polygones
        st_geometry(DF)=NULL
        
        remplace=st_sf(data.frame(
          cat=2,
          Aire=-9999,
          # QUOI=paste0("fusion",iFShTr),
          Id=0,
          PlanEau="",
          Canal="",
          Ecoulement="",
          F_Sh="",
          F_Sh_Tr=iFShTr
        ),
        geometry=polygones_associes)
        print(sort(unique(colnames(remplace))))
        print(sort(unique(colnames(Masques2[-nbFShFr,]))))
        
        Masques2=rbind(Masques2[-nbFShFr,],remplace[,colnames(Masques2)])
      }
    }
    
    ##################################################
    ##### travail sur la mer
    
    ## Détéction des masques touchant la mer
    Masques2$F_Sh_Tr_Me=Masques2$F_Sh_Tr
    iMer=st_contains_properly(Dpt_Inv_Mer,Masques2)
    if (dim(Masques2[-iMer[[1]],])[1]>0) {Masques2[-iMer[[1]],]$F_Sh_Tr_Me="Mer"}
    
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer.gpkg"), delete_layer=T, quiet=T)
    
  }
  
  # etape qui peut conduire à des bugs SIG, on peut travailler à partir de la donnée précédente mais plus de découpes manuelles
  if (Etap1b[5]==1)
  { 
    cat("\014")
    cat("FILINO_04_01b_MasqueEau.R - Etap1b[5]\n")
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer.gpkg"))
    st_geometry(Masques2)="geometry"
    surfhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro.gpkg"))
    trhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg"))
    # constsurf=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"constsurf_tmp.gpkg"))
    ## Pour chaque masque qui touche la mer
    # Recherche des surfaces en eau qui touchent la mer et des troncons hydro
    
    IndMasq=max(Masques2$Id)
    
    # Boucle sur tous les morceaux de mer
    for (im in which(Masques2$F_Sh_Tr_Me=="Mer"))
    {
      nomA=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro.gpkg")
      nomB=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_im.gpkg")
      st_write(Masques2[im,],nomB,delete_layer=T, quiet=T)
      nomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.csv")
      liaison=FILINO_Intersect_Qgis(nomA,nomB,nomC)
      # On ne garde que les surface hydro qui croisent la mer
      surfhydro_tmp=surfhydro[unique(liaison$fid),]
      
      # On cherche à ne garder que les surfaces en mer qui sont aussi des cours d'eau
      # sinon, c'est de la mer
      trhydro_croi=trhydro
      nici=which(trhydro_croi$position_par_rapport_au_sol>-10)
      if (length(nici>0)){trhydro_croi=trhydro_croi[nici,]}
      
      st_write(trhydro_croi,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_croi.gpkg"), delete_layer=T, quiet=T)
      
      # On n'intersecte qu'avec les troncons hydro de position par rapport au sol >-1
      # en gros on ne va pas intersecter avec des ouvrages  enterrés
      nbms=st_intersects(surfhydro_tmp,trhydro_croi)
      n_int_ms = which(sapply(nbms, length)>0)
      if (length(n_int_ms)>0)
      {
        surfhydro_tmp=surfhydro_tmp[n_int_ms,]
        if (verif==1){st_write(surfhydro_tmp,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.gpkg"), delete_layer=T, quiet=T)}
        
        # On intersecte pour ne garder que ceux qui ont un croisement avec une rivière important
        trhydro_croi=st_intersection(trhydro_croi,surfhydro_tmp)
        trhydro_croi$longueur=st_length(trhydro_croi)
        units(trhydro_croi$longueur)=NULL
        
        trhydro_croi=trhydro_croi[which(trhydro_croi$longueur>=seuillgtrhydrodanssurface),]
        # browser()
        if (dim(trhydro_croi)[1]>0)
        {
          # On ne garde que les surface hydro qui ont un troncon hydro un peu long...
          nbms2=st_intersects(surfhydro_tmp,trhydro_croi)
          n_int_ms2 = which(sapply(nbms2, length)>0)
          if (length(n_int_ms2)>0)
          {
            surfhydro_tmp=surfhydro_tmp[n_int_ms2,]
            ##### PARAMETRES SUBJECTIF ATTENTION
            bufMer=10
            
            # Récupération de la partie estuaire
            Estuaires=st_intersection(Masques2[im,], st_buffer(surfhydro_tmp,bufMer))
            if (verif==1){st_write(Estuaires,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Estuaires.gpkg"), delete_layer=T, quiet=T)}
            Estuaires=Estuaires[,colnames(Masques2)]
            
            # Codification des estuaires en recroisant avec les surface en eau
            for (iest in 1:dim(Estuaires)[1])
            {
              # browser()
              nbiest=st_intersects(surfhydro_tmp,Estuaires[iest,1])
              n_int_iest = which(sapply(nbiest, length)>0)
              Estuaires$F_Sh_Tr_Me[iest]=paste0(ifelse(length(grep(surfhydro_tmp$nature[n_int_iest],pattern="Ecoul"))>0,
                                                       "Ecoulement","PlanEau"),"Estuaire")
              
              IndMasq=IndMasq+1
              Estuaires[iest,]$Id=IndMasq
            }
            
            # Récupération de la partie Mer
            Mer2=st_difference(Masques2[im,],st_union(Estuaires))
            if (verif==1){st_write(Mer2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Mer2.gpkg"), delete_layer=T, quiet=T)}
            # browser()
            
            # 2024 05 21
            # je ne sais plus pourquoi j'éclatais et je changeais de codification, à revoir mais
            # Gestion pour vérifier que l'on ne prend en compte que la grosse mer, pas les petits morceaux associés
            # Mer2b=st_cast(Mer2,"POLYGON")
            # Mer2b$Aire=st_area(Mer2b)
            # Mer2=Mer2b[which(Mer2b$Aire==max(Mer2b$Aire)), ]
            # browser()
            # if (dim(Mer2b)[1]>1)
            # {
            #   Mer2b=Mer2b[-which(Mer2b$Aire==max(Mer2b$Aire)), ]
            #   dat=Estuaires[1,]
            #   st_geometry(dat)=NULL
            #   st_geometry(Estuaires)="geometry"
            #   st_geometry(Mer2b)="geometry"
            #   Estuaires=st_cast(
            #     st_sf(dat,geometry=st_cast(st_union(rbind(Estuaires,Mer2b)),"MULTIPOLYGON")),
            #     "POLYGON")
            #   Estuaires$Aire=st_area(Estuaires)
            # }
            # browser()
            # 
            # # browser()
            # if (dim(Estuaires)[1]>1)
            # {
            #   autres=which(Estuaires$Aire!=max(Estuaires$Aire))
            #   Estuaires$F_Sh_Tr_Me[autres]="PlanMerEcoulementEstuaire"
            # }
            
            # Estuaires$F_Sh_Tr=""
            # for (ime in 1:dim(Estuaires)[2])
            # {
            #   IndMasq=IndMasq+1
            #   Estuaires[ime,]$Id=IndMasq
            # }
            
            if (im==8)
            {
              # browser()
            }
            
            Mer2=Mer2[,colnames(Masques2)]
            if (dim(Mer2)[1]>0)
            {
              Mer2$F_Sh_Tr_Me="Mer"
              Mer2$F_Sh_Tr=""
              IndMasq=IndMasq+1
              Mer2$Id=IndMasq
              # modification des attributs
              Masques2[im,]$F_Sh_Tr_Me="VieuxMer"
              #ATTENTION, il faudrait éclater en morceaux et regrouper si on va d'un estuaire à l'autre...
              
              st_geometry(Masques2)="geometry"
              st_geometry(Estuaires)="geometry"
              st_geometry(Mer2)="geometry"
              Masques2=rbind(Masques2,
                             Estuaires,
                             Mer2)
              paspasse=0
            }
          }else{
            Masques2[im,]$F_Sh_Tr_Me="Mer"
          }
        }else{
          Masques2[im,]$F_Sh_Tr_Me="Mer"
        }
      }else{
        Masques2[im,]$F_Sh_Tr_Me="Mer"
      }
    }
    
    ####################################################
    ###### MATHIEU A TESTER SUR MAMP 19/04/2024
    ######################################################
    # si ca bugge mettre en commentaire jusqu'au prochain MATHIEU
    
    # Redecoupage du masque mer pour limiter sa taille
    
    if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_avantgrille.gpkg"), delete_layer=T, quiet=T)}
    
    nMerADecouper=which(Masques2$F_Sh_Tr_Me=="Mer")
    if (length(nMerADecouper)>0)
    {
      nomMerADecouper=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"MerADecouper.gpkg")
      nomMerDecoupee =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"MerDecoupee.gpkg" )
      nomMerDecoupee2=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"MerDecoupeeC.gpkg" )
      nomMerDecoupee3=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"MerDecoupeeCF.gpkg" )
      st_write(Masques2[nMerADecouper,],nomMerADecouper, delete_layer=T, quiet=T)
      
      # qgis_process run native:intersection 
      # --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 
      # --INPUT='C:/AFFAIRES/FILINO_Travail/01a_MASQUE_VIDEetEAU/TA_HD/Masques2_Seuil1000m2.gpkg|layername=Masques2_Seuil1000m2' --OVERLAY='E:/LidarHD_DC/TA_HD.shp' --OVERLAY_FIELDS_PREFIX= --OUTPUT=TEMPORARY_OUTPUT
      cmd <- paste0(qgis_process, " run native:intersection",
                    " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                    " --INPUT=",shQuote(nomMerADecouper),
                    " --OVERLAY=",shQuote(file.path(dsnTALidar,nomTALidar)),
                    " --OVERLAY_FIELDS_PREFIX=",
                    " --OUTPUT=",shQuote(nomMerDecoupee))
      system(cmd)
      MerDecoupee=st_cast(st_read(nomMerDecoupee),"POLYGON")
      st_geometry(MerDecoupee)="geometry"
      MerDecoupee=MerDecoupee[,colnames(Masques2)]
      
      # Faire une boucle pour coller les éléments jusqu'à une aire de XXX
      
      MerDecoupee$Aire=st_area(MerDecoupee)
      units(MerDecoupee$Aire)=NULL
      
      while (min(MerDecoupee$Aire)<seuilmerdec)
      {
        
        npetit=which(MerDecoupee$Aire==min(MerDecoupee$Aire))[1]
        MersansPetit=MerDecoupee[-npetit,]
        nbmdp=st_intersects(MersansPetit,MerDecoupee[npetit,])
        n_intnbmdp <-  which(sapply(nbmdp, length) > 0)
        cat("Fusion des petits découpages mer",dim(MerDecoupee)," ",length(n_intnbmdp)," ",min(MerDecoupee$Aire),"\n")
        
        if (length(n_intnbmdp)>1)
        {
          # browser()
        }
        if (length(n_intnbmdp)>0)
        {
          # il faut fusionner avec les voisins
          FusionPetitsVoisins=st_union(MerDecoupee[npetit,],st_union(MersansPetit[n_intnbmdp,],))
          FusionPetitsVoisins=FusionPetitsVoisins[,colnames(Masques2)]
          # FusionPetitsVoisins=st_union(FusionPetitsVoisins)
          FusionPetitsVoisins$Aire=st_area(FusionPetitsVoisins)
          units(FusionPetitsVoisins$Aire)=NULL
          MerDecoupee=rbind(MersansPetit[-n_intnbmdp,],FusionPetitsVoisins)
        }else{
          
          MerDecoupee$Aire[npetit]=seuilmerdec
        }
      }
      
      verif=1
      if (verif==1){st_write(MerDecoupee,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"MerDecoupee.gpkg"), delete_layer=T, quiet=T)}
      
      # browser()
      nNRacc=which(MerDecoupee$Aire==seuilmerdec)
      ngrosmer=dim(MerDecoupee[-nNRacc,1])[1]
      if (length(nNRacc)>0)
      {
        
        GrosseMer=MerDecoupee[-nNRacc,]
        PetiteMer=MerDecoupee[nNRacc,]
        distaC=st_distance(PetiteMer,GrosseMer)
        GrosseMer$Id=1:ngrosmer
        
        PetiteMer$Id=0
        for (ifmer in 1:length(nNRacc))
        {
          PetiteMer[ifmer,]$Id=GrosseMer[which(distaC[ifmer,]==min(distaC[ifmer,])),]$Id
        }
        if (verif==1)
        {
          st_write(PetiteMer,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"PetiteMer.gpkg"), delete_layer=T, quiet=T)
          st_write(GrosseMer,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"GrosseMer.gpkg"), delete_layer=T, quiet=T)
        }
        GrosseMer2=rbind(GrosseMer,PetiteMer)
        GrosseMer2DF=GrosseMer2
        st_geometry(GrosseMer2DF)=NULL
        GrosseMer2=do.call(rbind,
                           lapply(1:ngrosmer,
                                  function(x) {st_sf(data.frame(GrosseMer2DF[x,]),
                                                     geometry=st_cast(st_union(GrosseMer2[which(GrosseMer2$Id==x),]),"MULTIPOLYGON"))}))
        
        # st_sf(data.frame(liens_vers_cours_d_eau =x),
        #       geometry=st_line_merge(st_cast(st_union(trhydro_tmp[which(trhydro_tmp$liens_vers_cours_d_eau ==x),]),"MULTILINESTRING")))})))
        
        if (verif==1)
        {
          
          st_write(GrosseMer2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"GrosseMer2.gpkg"), delete_layer=T, quiet=T)
        }
        
        GrosseMer2$Aire=st_area(GrosseMer2)
        units(GrosseMer2$Aire)=NULL
        Masques2=Masques2[-nMerADecouper,]
        Masques2=rbind(Masques2,GrosseMer2[,colnames(Masques2)])
      }
      Masques2=Masques2[order(Masques2$Aire),]
      
    }
    ####################################################
    ###### MATHIEU A TESTER SUR MAMP 19/04/2024
    ######################################################
    
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer2.gpkg"), delete_layer=T, quiet=T)
    
  } 
  if (Etap1b[6]==1)
  { 
    cat("\014")
    cat("FILINO_04_01b_MasqueEau.R - Etap1b[6]\n")
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer2.gpkg"))
    surfhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro.gpkg"))
    trhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg"))
    
    IndMasq=max(Masques2$Id)
    
    ##################################################
    ##### travail sur les écoulements
    Masques2$F_Sh_Tr_Me_Co=Masques2$F_Sh_Tr_Me
    
    cat("Boucle for (im in which(Masques2$F_Sh_Tr_Me_Co== & Masques2$Aire>seuilSup1))")
    for (im in which(Masques2$F_Sh_Tr_Me_Co=="" & Masques2$Aire>seuilSup1))
    {
      cat(im," ")
      nbmtr=st_intersects(trhydro[,1],Masques2[im,])
      n_int_mtr = which(sapply(nbmtr, length)>0)
      if (length(n_int_mtr)>0){Masques2[im,]$F_Sh_Tr_Me_Co="Ecoulement"}
    }
    cat("\n")
    
    # 20230709 ca bugge par là
    # il faut traiter les endroits identifiés écouleemnt en surface en eau et les grands sans conenxion avec des surfaces en eau
    cat("for (im in which(Masques2$F_Sh_Tr_Me_Co==Ecoulement))")
    for (im in which(Masques2$F_Sh_Tr_Me_Co=="Ecoulement"))
    {
      cat(im," ")
      if (verif==1){st_write(Masques2[im,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_im.gpkg"), delete_layer=T, quiet=T)}
      nbmtr=st_intersects(trhydro[,1],Masques2[im,])
      n_int_mtr = which(sapply(nbmtr, length)>0)
      if (length(n_int_mtr)!=0)
      {
        trhydro_tmp=trhydro[n_int_mtr,]
        
        # fusion des géométrie par cours d'eau
        trhydro_tmp2=st_zm(do.call(rbind,
                                   lapply(sort(unique(trhydro_tmp$liens_vers_cours_d_eau )),
                                          function(x) {st_sf(data.frame(liens_vers_cours_d_eau =x),
                                                             geometry=st_line_merge(st_cast(st_union(trhydro_tmp[which(trhydro_tmp$liens_vers_cours_d_eau ==x),]),"MULTILINESTRING")))})))
        
        # Récuperation des troncons hydro qui intersectent
        
        if (verif==1){st_write(trhydro_tmp,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg"), delete_layer=T, quiet=T)}
        
        
        nb_tmp2=st_intersects(trhydro_tmp2,Masques2[im,]) #pas besoin de rajouter
        
        trhydro_tmp2=st_intersection(trhydro_tmp2,Masques2[im,]) # old 20240306
        
        
        if (verif==1){st_write(trhydro_tmp2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp2.gpkg"), delete_layer=T, quiet=T)}
        
        # gestion des géométrie bizarre (geometrie collection qui pose pb)
        nicitrh=which(st_is(trhydro_tmp2, c("MULTILINESTRING", "LINESTRING")))
        
        if (length(nicitrh)>1)#20240306
        {
          trhydro_tmp2=trhydro_tmp2[nicitrh,]
          if (dim(trhydro_tmp2)[1]>2)
          {
            Masques2[im,]$F_Sh_Tr_Me_Co="Trop de rivières - Reprise manuelle"
          }else{
            Masques2[im,]$F_Sh_Tr_Me_Co="2 rivières"
            
            # recuperation de la jonction
            coord=round(st_coordinates(st_line_sample(st_cast(trhydro_tmp,"LINESTRING"),sample=c(0,1)))[,c(1,2,3)],2)
            doublons=sapply(1:dim(coord)[1], function(x) {length(which((coord[,1]==coord[x,1])&(coord[,2]==coord[x,2])))})
            jonction=coord[which(doublons==max(doublons))[1],1:2]
            jonction_sf=st_sfc(st_point(jonction),crs=nEPSG)
            
            # recuperation de la plus grosse partie qui est sur la jonction
            Masques2_tmp=st_cast(Masques2[im,],"POLYGON")
            nbmtr2=st_intersects(Masques2_tmp,st_buffer(jonction_sf,5))
            n_int_mtr2 = which(sapply(nbmtr2, length)>0)  
            if (length(n_int_mtr2)==1)
            {
              Masques2_tmp=Masques2_tmp[n_int_mtr2,]
              if (verif==1){st_write(Masques2_tmp,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp.gpkg"), delete_layer=T, quiet=T)}
              trhydro_tmp3=st_cast(st_intersection(trhydro_tmp2,Masques2_tmp),"MULTILINESTRING")
              
              coord=st_coordinates(trhydro_tmp3)
              n1=which(coord[,4]==1)
              n2=which(coord[,4]==2)
              if (length(n1)==0 | length(n2)==0)
              {
                Masques2[im,]$F_Sh_Tr_Me_Co="Trop de rivières - Reprise manuelle"
              }else{
                coord=coord[c(n1[1],n1[length(n1)],n2[1],n2[length(n2)]),]
                
                # coord=round(st_coordinates(st_line_sample(st_cast(trhydro_tmp2,"LINESTRING"),sample=c(0,1)))[,c(1,2,3)],2)
                diff=(coord[,1]-jonction[1])^2+(coord[,2]-jonction[2])^2
                
                naffluent=coord[which(diff==min(diff)),4]
                # coord=round(st_coordinates(st_line_sample(st_cast(trhydro_tmp2,"LINESTRING"),sample=c(0,1)))[,c(1,2,3)],2)
                coord=coord[-which(diff==min(diff)),]
                distances=sapply(1:dim(coord)[1], function(x) {((coord[x,1]-jonction[1])^2+(coord[x,2]-jonction[2])^2)^0.5})
                #Paramètre
                reduction=95/100
                
                distbuffok=min(distances[which(distances>0)])*reduction
                
                
                
                tampon=st_buffer(jonction_sf,distbuffok)
                # if (verif==1){st_write(tampon,file.path(dsnlayer,NomDirMasqueVIDE,paste0("tampon",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                if (verif==1){st_write(tampon,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"tampon.gpkg"), delete_layer=T, quiet=T)}
                
                Morc1=st_intersection(Masques2[im,],tampon)[,1]
                Morc2=st_intersection(surfhydro,tampon)[,1]
                st_geometry(Morc1)="geometry"
                st_geometry(Morc2)="geometry"
                colnames(Morc1)[1]="Id"
                colnames(Morc2)[1]="Id"
                Fusio=st_sf(st_cast(st_union(rbind(Morc1,Morc2)),"POLYGON"))
                
                
                nbmf=st_intersects(Fusio,Masques2[im,])
                n_int_mf = which(sapply(nbmf, length)>0)
                Fusio=Fusio[n_int_mf,]
                # if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Fusio",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Fusio.gpkg"), delete_layer=T, quiet=T)}
                
                Fusio=st_cast(Fusio,"LINESTRING")
                Fusio$PERIM=st_length(Fusio)
                Fusio=Fusio[which(Fusio$PERIM==max(Fusio$PERIM)),]
                # if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Fusio2",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Fusio2.gpkg"), delete_layer=T, quiet=T)}
                
                distbuffok=distbuffok*reduction
                tampon=st_sfc(st_buffer(st_point(jonction),distbuffok),crs=nEPSG)
                Bords=st_cast(st_intersection(Fusio,tampon),"LINESTRING")
                st_length(Bords)
                
                TestInters=st_intersection(Fusio,tampon)
                if (dim(TestInters)[1]>0)
                {
                  Bords=st_cast(st_line_merge(st_cast(st_intersection(Fusio,tampon),'MULTILINESTRING')),"LINESTRING")
                  Bords$PERIM=st_length(Bords)
                  if (dim(Bords)[1]>=3)
                  {
                    # Bords=Bords[order(Bords$PERIM,decreasing = TRUE)[1:3],]
                    Bords=Bords[order(Bords$PERIM,decreasing = TRUE),]
                    
                    if (verif==1){st_write(Bords,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Bords.gpkg"), delete_layer=T, quiet=T)}
                    
                    Confluence=st_buffer(jonction_sf,1/reduction*max(st_distance(jonction_sf,Bords)))
                    # if (verif==1){st_write(Confluence,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Confluence",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                    if (verif==1){st_write(Confluence,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Confluence.gpkg"), delete_layer=T, quiet=T)}
                    
                    Affluent=st_cast(st_difference(Masques2[im,],Confluence),"POLYGON")
                    nbmtro=st_intersects(Affluent,trhydro_tmp2[naffluent,1])
                    n_int_mtro = which(sapply(nbmtro, length)>0)
                    Affluent=Affluent[n_int_mtro,]
                    Affluent=st_sf(data.frame(Affluent)[1,1:(dim(Affluent)[2]-1)],geometry=st_combine(Affluent))
                    
                    # if (verif==1){st_write(Affluent,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Affluent",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                    if (verif==1){st_write(Affluent,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Affluent.gpkg"), delete_layer=T, quiet=T)}
                    
                    
                    # modification des attributs
                    # browser()
                    Masques2[im,]$F_Sh_Tr_Me_Co="VieuxEcoulement"
                    Affluent$F_Sh_Tr_Me_Co="EcoulementAffluent"
                    IndMasq=IndMasq+1
                    Affluent$Id=IndMasq
                    
                    # Récupération de la partie pricniaple
                    IndMasq=IndMasq+1
                    Principal=st_sf(data.frame(cat=-1,Id=IndMasq,Aire=0,PlanEau="",Canal="",Ecoulement="",F_Sh="",F_Sh_Tr="",F_Sh_Tr_Me="",F_Sh_Tr_Me_Co="EcoulementPrincipal"),
                                    geometry=st_difference(st_union(Masques2[im,]),st_union(Affluent)))
                    Principal=st_cast(Principal,"MULTIPOLYGON")
                    
                    # Gestion des petits morceaux 20240312
                    units(seuilSup3)="m"
                    Principal_=st_cast(Principal,"POLYGON")
                    DistPrin=st_distance(Principal_)
                    diag(DistPrin)=max(DistPrin)
                    apply(DistPrin, 2, max)
                    lalala=which(apply(DistPrin, 2, min)>unclass(seuilSup3)[1])
                    if (length(lalala)>0)
                    {
                      Affluent_=rbind(Affluent,
                                      Principal_[lalala,])
                      Affluent_$F_Sh_Tr_Me_Co="EcoulementAffluent"
                      st_geometry(Affluent)=st_union(st_cast(Affluent_,"MULTIPOLYGON"))
                    }
                    
                    lalala=which(apply(DistPrin, 2, min)<=unclass(seuilSup3)[1])
                    if (length(lalala)>0)
                    {
                      Principal_=rbind(Principal_[lalala,])
                      Principal_$F_Sh_Tr_Me_Co="EcoulementPrincipal"
                      st_geometry(Principal)=st_union(st_cast(Principal_,"MULTIPOLYGON"))
                    }
                    
                    # if (verif==1){st_write(Principal,file.path(dsnlayer,NomDirMasqueVIDE,paste0("Principal",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                    if (verif==1){st_write(Principal,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Principal.gpkg"), delete_layer=T, quiet=T)}
                    
                    #ATTENTION, il faudrait éclater en morceaux et regrouper si on va d'un estuaire à l'autre...
                    st_geometry(Masques2)="geometry"
                    st_geometry(Principal)="geometry"
                    st_geometry(Affluent)="geometry"
                    
                    Masques2=rbind(Masques2,
                                   Principal,
                                   Affluent)
                  }else{
                    Masques2[im,]$F_Sh_Tr_Me_Co="Ecou - 2 rivières mais affluent absent ou très court"
                  }  
                }else{
                  Masques2[im,]$F_Sh_Tr_Me_Co="2 rivières - Reprise manuelle - Bords complexes"
                }
              }
            }
            
          }
          cat("\n")
        }
      }
    }
    
    
    Masques2$Aire=round(st_area(Masques2),0)
    Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
    
    ##### Codification
    Masques2$Id=FILINO_NomMasque(Masques2)
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMerConf.gpkg"), delete_layer=T, quiet=T)
    
    constsurf=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"constsurf_tmp.gpkg"))
    ecluse=constsurf[which(constsurf$nature=="Ecluse"),]
    necl=st_intersects(Masques2,ecluse)
    n_intecl = which(sapply(necl, length)>0)
    Masques2$VIGILANCE=""
    if (length(n_intecl)>0)
    {
      Masques2[n_intecl,]$VIGILANCE="Ecluse"
      Masques2[n_intecl,]$F_Sh_Tr_Me_Co=paste(Masques2[n_intecl,]$F_Sh_Tr_Me_Co,"Ecluse")
    }
    
    print(sort(unique(Masques2$F_Sh_Tr_Me_Co)))
    Masques2$Commentaires=""
    
    Masques2$FILINO=Masques2$F_Sh_Tr_Me_Co
    
    units(seuilSup4)="m^2"
    Masques2=Masques2[which(Masques2$Aire>seuilSup4),]
    
    Masques2$ValPlanEAU=ValPlanEAU
    Masques2$CE_BalPas=CE_BalPas
    Masques2$CE_BalFen=CE_BalFen
    Masques2$CE_PenteMax=CE_PenteMax
    Masques2$NumCourBox=NumCourBox
    
    st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg")), delete_layer=T, quiet=T)
    
    file.copy(file.path(dsnlayer,NomDirSIGBase,"Masques.qgz"),
              file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques.qgz"),
              overwrite = T)
    
    if (Nettoyage==1)
    {
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMerConf.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_tmp.gpkg")))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion.gpkg")))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Gros_et_Petits_SurfEauBDTopo_Plane.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEau.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEau.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydro.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_im.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer2.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMerConf.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"surfhydro_tmp.csv"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.csv"))
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_tmp2.gpkg")) )
    }
  }
}
