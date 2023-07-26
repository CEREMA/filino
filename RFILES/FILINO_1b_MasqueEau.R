library(dplyr)

if (exists("Etap1b")==F){Etap1b=c(0,0,0,0,0,1)}
#ATTENTION pour lancer l'étape 4, il faut aussi la 2 (recup des données surfaces en eau)

# Initialisation des chemins et variables
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))
source(file.path(chem_routine,"FILINO_Utils.R"))

# Rprof()
# lecture des zones militaires pour les exclure
ZICAD=st_transform(
  st_read(file.path(dsnlayer,NomDirSIGBase,"Arrete_ZICAD_01-2023.kml")),
  st_crs(2154))

# Contour des Départements
Departement=st_read(file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT.shp"))

#Département Mer, pour tester si on est en mer ou à terre
Dpt_Inv_Mer=st_read(file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT_Buf_pour_mer.shp"))

# Boucle sur les différentes tables d'assemblage
# Fusion du travail lancé et des fichiers déjà existants
# supprimer les z
for (iTA in 1:length(dsnTALidar))
{
  # Recuperation des parametres de chaque table d'assemblage
  dsnlayerTA=dsnTALidar[iTA]
  nomlayerTA=nomTALidar[iTA]
  
  # paramXYTA=as.numeric(ifelse(length(dsnTALidar)==1,paraXYLidar,))
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  
  # 
  setwd(file.path(dsnlayer,NomDirMasque,racilayerTA))
  
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
      Masques1=FILINO_FusionMasque(1,TA)
      Masques1=Masques1[order(Masques1$Aire,decreasing=TRUE),]
      Masques1$Id=1:dim(Masques1)[1]
      st_write(Masques1,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1.gpkg"), delete_layer=T, quiet=T)
      
      ##############################################################
      Masques2=FILINO_FusionMasque(2,TA)
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2.gpkg"), delete_layer=T, quiet=T)
    }
    
    if (Etap1b[2]==1)
    {  
      # Masques1=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1.gpkg"))
      Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2.gpkg"))
      
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
        surfhydro=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer)
        st_geometry(surfhydro)="geometry"
        LSH[[iDpt]]=surfhydro[,"nature"]
        # cat(nomlayer,dim(surfhydro),"\n")
        
        ######################################################################################
        ##### Lecture des troncons hydrographiques
        nomlayer="troncon_hydrographique"
        trhydro=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer)
        st_geometry(trhydro)="geometry"
        # cleabs nature sens_de_l_ecoulement liens_vers_cours_d_eau
        LTr[[iDpt]]=trhydro[,cbind("cleabs","nature","sens_de_l_ecoulement","liens_vers_cours_d_eau")]
        # cat(nomlayer,dim(trhydro),"\n")
        
        ######################################################################################
        ##### Lecture des constructions hydrographiques
        nomlayer="construction_surfacique"
        constsurf=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer)
        st_geometry(constsurf)="geometry"
        LCS[[iDpt]]=constsurf[,"nature"]
      }
      
      surfhydro=do.call(rbind, LSH)
      # nettoyage des doublons de deux départements...
      trhydro=do.call(rbind, LTr)
      trhydro=trhydro[order(trhydro$cleabs),]
      trhydro$doublons=0
      for (i in 2:dim(trhydro)[1])
      {
        if (trhydro$cleabs[i]==trhydro$cleabs[i-1]){trhydro$doublons[i]=1}
      }
      trhydro=trhydro[which(trhydro$doublons==0),]
      
      constsurf=do.call(rbind, LCS)
      
      # Intersection des 
      nbMSh=st_intersects(Masques2,surfhydro)
      n_intMSh = which(sapply(nbMSh, length)>0)
      
      # units(seuilSup1)="m^2"
      
      # Travail sur les gros masques
      Masques2=Masques2[unique(c(n_intMSh,which(Masques2$Aire>seuilSup1))),]
      # ajout de l'aire et travail par ordre decroissant
      Masques2=Masques2[order(Masques2$Aire,decreasing=TRUE),] 
      
      ##### Codification
      Masques2$Id=1:dim(Masques2)[1]
      
      # if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasque,paste0("Masques2_Gros_et_SurfEauBDTopo",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
      # if (verif==1){
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo.gpkg"), delete_layer=T, quiet=T)
      # }
      
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial surfhydro restant\n")
      st_write(surfhydro,file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro_tmp.gpkg"),delete_layer=T, quiet=T)
      cmd <- paste0(qgis_process, " run native:createspatialindex",
                    " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                    " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg")))
      system(cmd)
      
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Trhydro restant\n")
      st_write(trhydro,file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg"),delete_layer=T, quiet=T)
      cmd <- paste0(qgis_process, " run native:createspatialindex",
                    " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                    " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg")))
      system(cmd)
      
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial constsurf restant\n")
      st_write(constsurf,file.path(dsnlayer,NomDirMasque,racilayerTA,"constsurf_tmp.gpkg"),delete_layer=T, quiet=T)
      cmd <- paste0(qgis_process, " run native:createspatialindex",
                    " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                    " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"constsurf_tmp.gpkg")))
      system(cmd)
      
      cat("Etape1b_2 terminée")
      # Rprof(NULL)
      # summaryRprof()
    }
    
    if (Etap1b[3]==1)
    {  
      # Masques1=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1.gpkg"))
      Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo.gpkg"))
      #### initialisation
      ngros=data.frame(Gros=which(Masques2$Aire>=seuilSup1),Tour=0)
      units(seuilSup2)="m"
      
      it=0
      while(max(ngros$Tour)>=it)
      {
        cat("#####################\n")
        it=it+1
        cat("Tour ",it,"\n")
        
        #### boucle
        npetit=which(Masques2$Id>(max(ngros$Gros)+1))
        
        for (ip in which(ngros$Tour==(it-1)))
        {
          cat("Tour ",it," - Masque - ",ip)
          if (ngros$Tour[ip]>=it-1)
          {
            ngp=st_intersects(Masques2[npetit,1],st_buffer(st_as_sfc(st_bbox(Masques2[ngros$Gros[ip],1])),10))
            nint_ngp=which(sapply(ngp, length)>0)
            
            # st_write(Masques2[npetit[nint_ngp],1],file.path(dsnlayer,NomDirMasque,paste0("petiti",".gpkg")), delete_layer=T, quiet=T)
            # st_write(Masques2[ngros$Gros[ip],1],file.path(dsnlayer,NomDirMasque,paste0("grios",".gpkg")), delete_layer=T, quiet=T)
            # st_write(st_buffer(st_as_sfc(st_bbox(Masques2[ngros$Gros[ip],1])),10),file.path(dsnlayer,NomDirMasque,paste0("buffons",".gpkg")), delete_layer=T, quiet=T)
            
            if(length(nint_ngp)>0)
            {
              valeurs=st_distance(Masques2[ngros$Gros[ip],1],Masques2[npetit[nint_ngp],1])
              lala=which(valeurs<seuilSup2)
              if (length(lala)>0)
              {
                # cat("valeurs",round(valeurs,1),"\n")
                cat(" - Indices a modifer",lala)
                Masques2[npetit[nint_ngp[lala]],]$Id=ip
                ngros$Tour[ip]=it
              }
            }
          }
          cat("\n")
        }
        if (max(ngros$Tour)==it)
        {
          # st_write(Masques2,file.path(dsnlayer,NomDirMasque,paste0("Masques2_Gros_et_SurfEauBDTopo_Indices",it,"_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)
          cat("#####################\n")
          cat("Fusion des géométries avec même indice\n")
          
          cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Début de fusion des masques Qgis","\n")
          nomMasque2_tmp=file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_tmp.gpkg"))
          nomMasque2_tmp2=file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_tmp2.gpkg"))
          st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_tmp.gpkg")), delete_layer=T, quiet=T)
          
          cmd=paste0(qgis_process, " run native:collect",
                     " --INPUT=",shQuote(nomMasque2_tmp),
                     " --FIELD=Id",
                     " --OUTPUT=",shQuote(nomMasque2_tmp2))
          system(cmd)
          # Masques2_Qgis=st_read(nomMasque2_tmp2)
          Masques2=st_read(nomMasque2_tmp2)
          cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin de fusion des masques Qgis","\n")
          
          Masques2$Aire=round(st_area(Masques2),0)
          
          if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion",it-1,".gpkg")), delete_layer=T, quiet=T)}
        }else{
          if (verif==1){st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion",it-1,".gpkg")), delete_layer=T, quiet=T)}
        }
      }
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_Gros_et_SurfEauBDTopo_IndicesFusion.gpkg")), delete_layer=T, quiet=T)
      # On peut se demander pourquoi ne pas garder les petits masques qui intersectent des tronçons hydro
      # Il semble plus pertinent de faire une autre routine (Filino3)
    }
    
    if (Etap1b[4]==1)
    { 
      # Masques1=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1.gpkg"))
      Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Gros_et_SurfEauBDTopo_IndicesFusion.gpkg"))
      st_geometry(Masques2)="geometry"
      surfhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro_tmp.gpkg"))
      trhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg"))
      constsurf=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"constsurf_tmp.gpkg"))
      
      # on en garde que les gros masques et les petits dans des surfaces en eau "planes"
      # Intersection des 
      nbMSh=st_intersects(Masques2,surfhydro[which(surfhydro$nature!="Ecoulement naturel"),1])
      n_intMSh = which(sapply(nbMSh, length)>0) 
      Masques2=Masques2[unique(rbind(as.matrix(which(Masques2$Aire>seuilSup1)),as.matrix(n_intMSh))),]
      
      Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
      Masques2$Id=1:dim(Masques2)[1]
      
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Gros_et_Petits_SurfEauBDTopo_Plane.gpkg"), delete_layer=T, quiet=T)
      
      nomA=file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro_tmp.gpkg")
      nomB=file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_Gros_et_Petits_SurfEauBDTopo_Plane.gpkg")
      nomC=file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro_tmp.csv")
      liaison=FILINO_Intersect_Qgis(nomA,nomB,NomC)
      
      surfhydro=surfhydro[unique(liaison$fid),]
      
      surfhydro$F_Sh="PlanEau"
      ici=grep(surfhydro$nature,pattern="Ecoul")
      if (length(ici)>0) {surfhydro[ici,]$F_Sh="Ecoulement"}
      ici=grep(surfhydro$nature,pattern="Canal")
      if (length(ici)>0) {surfhydro[ici,]$F_Sh="Canal"}
      
      st_write(surfhydro,file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro.gpkg"), delete_layer=T, quiet=T)
      
      # Appareillage des types de surfaces en eau sur les masques
      Masques2$PlanEau=""
      ici=which(surfhydro$F_Sh=="PlanEau")
      if (length(ici)>0)
      {
        nbShM=st_intersects(Masques2,surfhydro[ici,1])
        Masques2[which(sapply(nbShM, length)>0),]$PlanEau="PlanEau"
      }
      
      Masques2$Canal=""
      ici=which(surfhydro$F_Sh=="Canal")
      if (length(ici)>0)
      {
        nbShM=st_intersects(Masques2,surfhydro[ici,1])
        Masques2[which(sapply(nbShM, length)>0),]$Canal="Canal"   
      }
      
      Masques2$Ecoulement=""
      ici=which(surfhydro$F_Sh=="Ecoulement")
      if (length(ici)>0)
      {
        nbShM=st_intersects(Masques2,surfhydro[ici,1])
        Masques2[which(sapply(nbShM, length)>0),]$Ecoulement="Ecoulement"
      }
      
      
      Masques2$F_Sh=paste0(Masques2$PlanEau,Masques2$Canal,Masques2$Ecoulement)
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEau.gpkg"), delete_layer=T, quiet=T)
      
      ######################################################################################
      ##### Lecture des troncons hydrographiques
      # Intersection des masques et troncon hydro ene au
      
      # cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masques2 restant\n")
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_tmp.gpkg"),delete_layer=T, quiet=T)
      nomA=file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg")
      nomB=file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_tmp.gpkg")
      nomC=file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.csv")
      liaison=FILINO_Intersect_Qgis(nomA,nomB,NomC)
      
      if (dim(liaison)[1]>0)
      {
        # st_write(trhydro[unique(liaison$fid),],file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_peutetre.gpkg"),delete_layer=T, quiet=T)
        trhydro=trhydro[unique(liaison$fid),]
        
        # nbTrM=st_intersects(trhydro,Masques2)
        # n_intTrM = which(sapply(nbTrM, length)>0)
        # if (length(n_intTrM)>0)
        # {
        #   trhydro=trhydro[n_intTrM,]
        
        trhydro$F_Tr=""
        ici=grep(trhydro$nature,pattern="Ecoul")
        if (length(ici)>0) {trhydro[ici,]$F_Tr="Ecoulement"}
        ici=grep(trhydro$nature,pattern="Canal")
        if (length(ici)>0) {trhydro[ici,]$F_Tr="Canal"}
        ici=grep(trhydro$sens_de_l_ecoulement,pattern="Double sens")
        if (length(ici)>0) {trhydro[ici,]$F_Tr=""}
        ici=which(is.na(trhydro$liens_vers_cours_d_eau))
        if (length(ici)>0) {trhydro[ici,]$F_Tr=""}
        # st_write(trhydro,file.path(dsnlayer,NomDirMasque,paste0("trhydro_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)
        st_write(trhydro,file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro.gpkg"), delete_layer=T, quiet=T)
        
        
        trhydro=trhydro[which(nchar(trhydro$F_Tr)>0),]
        
        # suppression des masques ecoulement si aucun troncon hyhdro ecoulement
        nbtrM=st_intersects(Masques2,trhydro[which(trhydro$F_Tr=="Ecoulement"),1])
        ici=which(sapply(nbtrM, length)>0)
        if (length(ici)>0){Masques2[-ici,]$Ecoulement=""}
        
        # suppression des masques canal si aucun troncon hyhdro ecoulement
        nbtrM=st_intersects(Masques2,trhydro[which(trhydro$F_Tr=="Canal" ),1])
        ici=which(sapply(nbtrM, length)>0)
        if (length(ici)>0){Masques2[-ici,]$Canal=""}
        
        # suppression des masques canal si aucun troncon hyhdro ecoulement
        nbtrM=st_intersects(Masques2,trhydro[,1])
        ici=which(sapply(nbtrM, length)>0)
        # rajouter test pour voir si plan eau vide, et ne remplir que les vides
        if (length(ici)>0)
        {
          # Masques2[-ici,]$PlanEau="PlanEau_Tr"
          Masques2[-ici,][which(Masques2[-ici,]$PlanEau==""),]$PlanEau="PlanEau_Tr"
        }
      }
      # test pour enlever les types de surfaces en eau qui seraient avec des tronçons supprimé précédement
      Masques2$F_Sh_Tr=paste0(Masques2$PlanEau,Masques2$Canal,Masques2$Ecoulement)
      
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydro.gpkg"), delete_layer=T, quiet=T)
      
      ##################################################
      ##### travail sur la mer
      
      ## Détéction des masques touchant la mer
      Masques2$F_Sh_Tr_Me=Masques2$F_Sh_Tr
      iMer=st_contains_properly(Dpt_Inv_Mer,Masques2)
      if (dim(Masques2[-iMer[[1]],])[1]>0) {Masques2[-iMer[[1]],]$F_Sh_Tr_Me="Mer"}
      
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer.gpkg"), delete_layer=T, quiet=T)
    }
    # etape qui peut conduire à des bugs SIG, on peut traaviller à partir de la donnée précédente mais plus de découpes manuelles
    if (Etap1b[5]==1)
    { 
      Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer.gpkg"))
      surfhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro.gpkg"))
      trhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro.gpkg"))
      # constsurf=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"constsurf_tmp.gpkg"))
      ## Pour chaque masque qui touche la mer
      # Recherche des surfaces en eau qui touchent la mer et des troncons hydro
      
      IndMasq=max(Masques2$Id)
      
      for (im in which(Masques2$F_Sh_Tr_Me=="Mer"))
      {
        nomA=file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro.gpkg")
        nomB=file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_im.gpkg")
        st_write(Masques2[im,],nomB,delete_layer=T, quiet=T)
        nomC=file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro_tmp.csv")
        liaison=FILINO_Intersect_Qgis(nomA,nomB,NomC)
        surfhydro_tmp=surfhydro[unique(liaison$fid),1]
        
        nbms=st_intersects(surfhydro_tmp,trhydro)
        n_int_ms = which(sapply(nbms, length)>0)
        if (length(n_int_ms)>0)
        {
          surfhydro_tmp=surfhydro_tmp[n_int_ms,]
          ##### PARAMETRES SUBJECTIF ATTENTION
          bufMer=10
          
          # Récuypération de la partie estuaire
          Estuaires=st_intersection(Masques2[im,], st_buffer(surfhydro_tmp,bufMer))
          if (verif==1){st_write(Estuaires,file.path(dsnlayer,NomDirMasque,racilayerTA,"Estuaires.gpkg"), delete_layer=T, quiet=T)}
          
          # Récupération de la partie mer
          Estuaires=Estuaires[,colnames(Masques2)]
          
          # Récupération de la partie Mer
          Mer2=st_difference(Masques2[im,],st_union(Estuaires))
          if (verif==1){st_write(Mer2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Mer2.gpkg"), delete_layer=T, quiet=T)}
          
          # Gestion pour vérifier que l'on ne prend en compte que la grose mer, pas les petits morceaux asociés
          Mer2b=st_cast(Mer2,"POLYGON")
          Mer2b$Aire=st_area(Mer2b)
          Mer2=Mer2b[which(Mer2b$Aire==max(Mer2b$Aire)), ]#which(colnames(Mer2b)!="Aire")
          
          if (dim(Mer2b)[1]>1)
          {
            Mer2b=Mer2b[-which(Mer2b$Aire==max(Mer2b$Aire)), ]
            dat=Estuaires[1,]
            st_geometry(dat)=NULL
            st_geometry(Estuaires)="geometry"
            st_geometry(Mer2b)="geometry"
            Estuaires=st_cast(
              st_sf(dat,geometry=st_cast(st_union(rbind(Estuaires,Mer2b)),"MULTIPOLYGON")),
              "POLYGON")
            Estuaires$Aire=st_area(Estuaires)
          }
          
          Estuaires$F_Sh_Tr_Me="EcoulementEstuaire"
          if (dim(Estuaires)[1]>1)
          {
            autres=which(Estuaires$Aire!=max(Estuaires$Aire))
            Estuaires$F_Sh_Tr_Me[autres]="PlanMerEcoulementEstuaire"
          }
          
          Estuaires$F_Sh_Tr=""
          for (ime in 1:dim(Estuaires)[2])
          {
            IndMasq=IndMasq+1
            Estuaires[ime,]$Id=IndMasq
          }
          
          Mer2=Mer2[,colnames(Masques2)]
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
        }else{
          Masques2[im,]$F_Sh_Tr_Me="Mer"
        }
      }
      st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer2.gpkg"), delete_layer=T, quiet=T)
    } 
    if (Etap1b[6]==1)
    { 
      Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMer2.gpkg"))
      surfhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"surfhydro.gpkg"))
      trhydro=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro.gpkg"))
      
      ##################################################
      ##### travail sur les écoulements
      Masques2$F_Sh_Tr_Me_Co=Masques2$F_Sh_Tr_Me
      
      cat("for (im in which(Masques2$F_Sh_Tr_Me_Co== & Masques2$Aire>seuilSup1))")
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
        if (verif==1){st_write(Masques2[im,],file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_im.gpkg"), delete_layer=T, quiet=T)}
        nbmtr=st_intersects(trhydro[,1],Masques2[im,])
        n_int_mtr = which(sapply(nbmtr, length)>0)
        trhydro_tmp=trhydro[n_int_mtr,]
        trhydro_tmp=st_line_merge(st_cast(trhydro_tmp,'MULTILINESTRING'))
        # Récuperation des troncons hydro qui intersectent
        
        if (verif==1){st_write(trhydro_tmp,file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg"), delete_layer=T, quiet=T)}
        
        # fusion en ligne continu( mêeme si ce n'est pas vraoment un belle union et regroupement par cours d'eau)
        
        st_geometry(trhydro_tmp)="geometry"
        trhydro_tmp2 = trhydro_tmp %>% 
          group_by(liens_vers_cours_d_eau) %>%
          summarize(geometry = st_union(geometry))
        
        # trhydro_tmp2=st_line_merge(st_cast(trhydro_tmp2,'MULTILINESTRING'))
        # découpe des tronçns hydro sur le masque
        trhydro_tmp2=st_line_merge(st_cast(st_cast(trhydro_tmp2,'LINESTRING'),'MULTILINESTRING'))
        
        trhydro_tmp2=st_intersection(trhydro_tmp2,Masques2[im,])
        
        if (verif==1){st_write(trhydro_tmp2,file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp2.gpkg"), delete_layer=T, quiet=T)}
        
        if (dim(trhydro_tmp2)[1]>1)
        {
          if (dim(trhydro_tmp2)[1]>2)
          {
            Masques2[im,]$F_Sh_Tr_Me_Co="Trop de rivières - Reprise manuelle"
            # browser()
          }else{
            Masques2[im,]$F_Sh_Tr_Me_Co="2 rivières"
            # recuperation de la jonction
            coord=round(st_coordinates(st_line_sample(st_cast(trhydro_tmp,"LINESTRING"),sample=c(0,1)))[,c(1,2,3)],2)
            doublons=sapply(1:dim(coord)[1], function(x) {length(which((coord[,1]==coord[x,1])&(coord[,2]==coord[x,2])))})
            jonction=coord[which(doublons==max(doublons))[1],1:2]
            jonction_sf=st_sfc(st_point(jonction),crs=2154)
            
            # recuperation de la plus grosse partie qui est sur la jonction
            Masques2_tmp=st_cast(Masques2[im,],"POLYGON")
            nbmtr2=st_intersects(Masques2_tmp,st_buffer(jonction_sf,5))
            n_int_mtr2 = which(sapply(nbmtr2, length)>0)  
            if (length(n_int_mtr2)==1)
            {
              Masques2_tmp=Masques2_tmp[n_int_mtr2,]
              if (verif==1){st_write(Masques2_tmp,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_tmp.gpkg"), delete_layer=T, quiet=T)}
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
                # if (verif==1){st_write(tampon,file.path(dsnlayer,NomDirMasque,paste0("tampon",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                if (verif==1){st_write(tampon,file.path(dsnlayer,NomDirMasque,racilayerTA,"tampon.gpkg"), delete_layer=T, quiet=T)}
                
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
                # if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasque,paste0("Fusio",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasque,racilayerTA,"Fusio.gpkg"), delete_layer=T, quiet=T)}
                
                Fusio=st_cast(Fusio,"LINESTRING")
                Fusio$PERIM=st_length(Fusio)
                Fusio=Fusio[which(Fusio$PERIM==max(Fusio$PERIM)),]
                # if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasque,paste0("Fusio2",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                if (verif==1){st_write(Fusio,file.path(dsnlayer,NomDirMasque,racilayerTA,"Fusio2.gpkg"), delete_layer=T, quiet=T)}
                
                distbuffok=distbuffok*reduction
                tampon=st_sfc(st_buffer(st_point(jonction),distbuffok),crs=2154)
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
                    
                    if (verif==1){st_write(Bords,file.path(dsnlayer,NomDirMasque,racilayerTA,"Bords.gpkg"), delete_layer=T, quiet=T)}
                    
                    Confluence=st_buffer(jonction_sf,1/reduction*max(st_distance(jonction_sf,Bords)))
                    # if (verif==1){st_write(Confluence,file.path(dsnlayer,NomDirMasque,paste0("Confluence",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                    if (verif==1){st_write(Confluence,file.path(dsnlayer,NomDirMasque,racilayerTA,"Confluence.gpkg"), delete_layer=T, quiet=T)}
                    
                    Affluent=st_cast(st_difference(Masques2[im,],Confluence),"POLYGON")
                    nbmtro=st_intersects(Affluent,trhydro_tmp2[naffluent,1])
                    n_int_mtro = which(sapply(nbmtro, length)>0)
                    Affluent=Affluent[n_int_mtro,]
                    Affluent=st_sf(data.frame(Affluent)[1,1:(dim(Affluent)[2]-1)],geometry=st_combine(Affluent))
                    # if (verif==1){st_write(Affluent,file.path(dsnlayer,NomDirMasque,paste0("Affluent",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                    if (verif==1){st_write(Affluent,file.path(dsnlayer,NomDirMasque,racilayerTA,"Affluent.gpkg"), delete_layer=T, quiet=T)}
                    
                    
                    # modification des attributs
                    Masques2[im,]$F_Sh_Tr_Me_Co="VieuxEcoulement"
                    Affluent$F_Sh_Tr_Me_Co="EcoulementAffluent"
                    IndMasq=IndMasq+1
                    Affluent$Id=IndMasq
                    
                    # Récupération de la partie pricniaple
                    IndMasq=IndMasq+1
                    Principal=st_sf(data.frame(Id=IndMasq,Aire=0,PlanEau="",Canal="",Ecoulement="",F_Sh="",F_Sh_Tr="",F_Sh_Tr_Me="",F_Sh_Tr_Me_Co="EcoulementPrincipal"),
                                    geometry=st_difference(st_union(Masques2[im,]),st_union(Affluent)))
                    
                    # if (verif==1){st_write(Principal,file.path(dsnlayer,NomDirMasque,paste0("Principal",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
                    if (verif==1){st_write(Principal,file.path(dsnlayer,NomDirMasque,racilayerTA,"Principal.gpkg"), delete_layer=T, quiet=T)}
                    
                    #ATTENTION, il faudrait éclater en morceaux et regrouper si on va d'un estuaire à l'autre...
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
    st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques2_AppareillageSurfaceEauTronconhydroMerConf.gpkg"), delete_layer=T, quiet=T)
    
    constsurf=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"constsurf_tmp.gpkg"))
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
    
    units(seuilSup3)="m^2"
    Masques2=Masques2[which(Masques2$Aire>seuilSup3),]
    
    Masques2$ValPlanEAU="-99.99"
    Masques2$CE_BalPas=5
    Masques2$CE_BalFen=50
    Masques2$CE_PenteMax=1/100
    Masques2$NumCourBox=1
    
    st_write(Masques2,file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg")), delete_layer=T, quiet=T)
    
    file.copy(file.path(dsnlayer,NomDirSIGBase,"Masques.qgz"),
              file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques.qgz"),
              overwrite = T)
  }
}