cat("\014")

listeMasq2S=list.files(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA),pattern=paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg"))
listeMasq1=list.files(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA),pattern=paste0("Masques1",".gpkg"))

cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 1\n")
Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq1[1]))[,c(1,3)]
st_geometry(Masques1)="geometry"

# Sauvegarde du fichier d'entree en OLD
nom_copy=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,
                   paste0(substr(listeMasq2S[1],1,nchar(listeMasq2S[1])-5),"_",format(Sys.time(),format="%Y%m%d_%H%M"),".gpkg"))
file.copy(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq2S[1]),
          nom_copy,overwrite = TRUE)

cmd=paste0(qgis_process, " run native:collect",
           " --INPUT=",shQuote(nom_copy),
           " --FIELD=Id",
           " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq2S[1])))
system(cmd)

cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
Masques2Seuil=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq2S[1]))
st_geometry(Masques2Seuil)="geometry"
# Ajout du 10/01/2024 pour intégrer un croisement avec une couche manuelle
# Cette couche "polygone" comporte un champ majeur avec le choix
# COUPE
# AJOUTE
# Ecou
# Plan
# Canal
# Mer
# L'objectif est de lire cette couche, mettre en vieux les masques2_seuil touché et d'intégrer les masques2.gpkg touché avec la codification adéquate

if (Opt_Manuel==1)
{
  if (file.exists(nom_Manuel))
  {
    Manuel=st_read(nom_Manuel)
    iTIN=which(Manuel$FILINO=="TIN") #### ON PEUT RAJOUTER AJOUT?
    if (length(iTIN>0))
    {
      nom_Manuel_tmp=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"ManuelsansTIN.gpkg")
      st_write(Manuel[-iTIN,],nom_Manuel_tmp, delete_layer=T, quiet=T)
    }else{
      nom_Manuel_tmp=nom_Manuel
    }
    
    NomA=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq2S)
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2Vieux.csv")
    liaison=FILINO_Intersect_Qgis(NomA,nom_Manuel_tmp,NomC)
    
    NIDVieux=unique(liaison$Id)
    
    for (IDVieux in NIDVieux)
    {
      # Suppression des calculs obsolètes (points virtuel, images mais on conserve le dossier si on doit revenir dessus!
      repVieux=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,IDVieux))
      unlink(file.path(repVieux,paste0(raciSurfEau,"_PtsVirt_copc.laz")))
      unlink(file.path(repVieux,paste0(raciSurfEau,"_PtsVirt_csv")))
      VieuxJpg=list.files(repVieux,pattern=paste0(raciSurfEau,IDVieux,"_",racilayerTA))
      if (length(VieuxJpg)>0){unlink(file.path(repVieux,VieuxJpg))}   
      
      # Modification du champ FILINO des masques seuillé
      Masques2Seuil[which(Masques2Seuil$Id==IDVieux),]$FILINO="VieuxManuel"
    }
    #---------------------------------------------------------------------------------------------------------------
    # Intégration des éléments de masques 2 dans le masque seuil
    
    Manuel=st_read(nom_Manuel_tmp)
    # Remplissage des champs vides
    if (length(which(is.na(Manuel$ValPlanEAU)))>0) {Manuel[which(is.na(Manuel$ValPlanEAU)) ,]$ValPlanEAU =ValPlanEAU}
    if (length(which(is.na(Manuel$CE_BalPas)))>0)  {Manuel[which(is.na(Manuel$CE_BalPas))  ,]$CE_BalPas  =CE_BalPas}
    if (length(which(is.na(Manuel$CE_BalFen)))>0)  {Manuel[which(is.na(Manuel$CE_BalFen))  ,]$CE_BalFen  =CE_BalFen}
    if (length(which(is.na(Manuel$CE_PenteMax)))>0){Manuel[which(is.na(Manuel$CE_PenteMax)),]$CE_PenteMax=CE_PenteMax}
    if (length(which(is.na(Manuel$NumCourBox)))>0) {Manuel[which(is.na(Manuel$NumCourBox)), ]$NumCourBox =NumCourBox}
    
    
    nom_Manuel2=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"ManuelFusion.gpkg")
    st_write(st_union(Manuel),nom_Manuel2, delete_layer=T, quiet=T)
    
    listeMasq2I=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg") 
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2recupManu.gpkg")
    
    
    FILINO_Intersect_Qgis(listeMasq2I,nom_Manuel2,NomC)
    Masque2recupManu=st_read(NomC)
    
    #COUPE
    # browser()
    iCoupe=which(Manuel$FILINO=="COUPE")
    if (length(iCoupe>0))
    {
      Masque2recupManu=st_difference(Masque2recupManu,st_union(Manuel[iCoupe,]))
      types_geometrie <- st_geometry_type(Masque2recupManu)
      
      # for (itype in unique(st_geometry_type(Masque2recupManu)))
      # {
      #  plot(Masque2recupManu[which(types_geometrie==itype),1],main=itype)
      # }
      Masque2recupManu=st_cast(Masque2recupManu[which(types_geometrie=="POLYGON" | types_geometrie=="MULTIPOLYGON"),])
      # Masque2recupManu
      # 
      Masque2recupManu=st_cast(Masque2recupManu,"POLYGON")
      if (verif==1){st_write(Masque2recupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu","Coupe",".gpkg")), delete_layer=T, quiet=T)}
    }
    
    # Vérification qu'il n'y ait pas un objet de masques 2 touchés par plusieurs zones utilisateur
    iAutre=which(Manuel$FILINO!="COUPE")
    if (length(iCoupe)>0 & length(iCoupe)!=dim(Manuel)[1])
    {
      Manuel=Manuel[iAutre,]
      nbMC=st_intersects(Masque2recupManu,st_geometry(Manuel))
      n_intMC = which(sapply(nbMC, length)>1)
      
      if (length(n_intMC)>0)
      {
        Masques2troptouche=Masque2recupManu[n_intMC,1]
        plot(Masques2troptouche)
        st_write(Masques2troptouche,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2troptouche",".gpkg")), delete_layer=T, quiet=T)
        
        
        nbMC=st_intersects(Manuel,Masques2troptouche)
        n_intMC = which(sapply(nbMC, length)>0)
        ManuelMauvais=Manuel[n_intMC,]
        # par(new=TRUE)
        plot(ManuelMauvais[,1])
        st_write(ManuelMauvais,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltouchetropMasques2",".gpkg")), delete_layer=T, quiet=T)
        
        cat("les masques de ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu","Coupe",".gpkg"))," \n")
        cat("touchent plusieurs de vos zones ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltouchetropMasques2",".gpkg"))," \n")
        BOOM=BOOOM
      }
    }
    
    motclesMRM=cbind("Eco","Pla","Can","Mer")
    incAj=1
    for (imotcle in motclesMRM)
    {
      indMotcle=which(substr(Manuel$FILINO,1,3)==imotcle)
      if (length(indMotcle)>0)
      {
        for (im in indMotcle)
        {
          nbMC=st_intersects(Masque2recupManu,st_geometry(Manuel[im,]))
          n_intMC = which(sapply(nbMC, length)>0)
          if (length(n_intMC)>0)
          {
            incAj=incAj+1
            # On va fusionner tous les petits masques et leur mettre les bons attributs
            MasqueIm=st_sf(data.frame(
              cat="0",
              Aire="-99",
              Id=dim(Masques2Seuil)[1]+incAj,
              PlanEau="-99",
              Canal="-99",
              Ecoulement="-99",
              F_Sh="-99",
              F_Sh_Tr="-99",
              F_Sh_Tr_Me="-99",
              F_Sh_Tr_Me_Co="-99",
              VIGILANCE="-99",
              Commentaires=nom_Manuel,
              FILINO=Manuel[im,]$FILINO,
              ValPlanEAU=Manuel[im,]$ValPlanEAU,
              CE_BalPas=Manuel[im,]$CE_BalPas,
              CE_BalFen=Manuel[im,]$CE_BalFen,
              CE_PenteMax=Manuel[im,]$CE_PenteMax,
              NumCourBox=Manuel[im,]$NumCourBox),
              geometry=st_union(Masque2recupManu[n_intMC,]))
            Masques2Seuil=rbind(Masques2Seuil,MasqueIm)
          }
        }
      } 
      
    }
  }
  
  iAJOUT=which(Manuel$FILINO=="AJOUT")
  if (length(iAJOUT>0))
  {
    for (im in iAJOUT)
    {
      if (Manuel[im,]$ValPlanEAU!=ValPlanEAU)
      {
        incAj=incAj+1
        
        MasqueIm=st_sf(data.frame(
          cat="0",
          Aire="-99",
          Id=dim(Masques2Seuil)[1]+incAj,
          PlanEau="-99",
          Canal="-99",
          Ecoulement="-99",
          F_Sh="-99",
          F_Sh_Tr="-99",
          F_Sh_Tr_Me="-99",
          F_Sh_Tr_Me_Co="-99",
          VIGILANCE="-99",
          Commentaires=paste0(nom_Manuel,"ajout"),
          FILINO="Plan",
          ValPlanEAU=Manuel[im,]$ValPlanEAU,
          CE_BalPas=Manuel[im,]$CE_BalPas,
          CE_BalFen=Manuel[im,]$CE_BalFen,
          CE_PenteMax=Manuel[im,]$CE_PenteMax,
          NumCourBox=Manuel[im,]$NumCourBox),
          geometry=st_union(Manuel[im,]))
        # print(Masques2Seuil)
        # plot(MasqueIm[,1])
        Masques2Seuil=rbind(Masques2Seuil,MasqueIm)
        
        # Creation d'un masque1
        Masque1Im=st_sf(data.frame(
          cat=1,
          Id=dim(Masques1)[1]+1),
          geometry=st_buffer(st_geometry(MasqueIm),-reso/10))
        Masques1=rbind(Masques1,Masque1Im)
      }
    } 
    
    
    
    
  }else{
    
  }
}
Masques2=Masques2Seuil

# Calcul de l'aire
Masques2$Aire=round(st_area(Masques2),0)
# Renumérotation
Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
##### Codification
Masques2$Id=FILINO_NomMasque(Masques2)
Masques2$IdGlobal=Masques2$Id

# Export du nouveau fichier
listeMasq2F=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_FILINO",".gpkg"))
st_write(Masques2,listeMasq2F, delete_layer=T, quiet=T) ##### FILINO

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
st_write(Masques1L,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp.gpkg"),delete_layer=T, quiet=T)
cmd <- paste0(qgis_process, " run native:createspatialindex",
              " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
              " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp.gpkg")))
system(cmd)

cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque2\n")
st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg"),delete_layer=T, quiet=T)

cmd <- paste0(qgis_process, " run native:createspatialindex",
              " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
              " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg")))
system(cmd)

cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Jointure spatiale des Masques1 inclus complètement dans un Masque2 unique\n")
cmd <- paste0(qgis_process, " run native:joinattributesbylocation",
              " --distance_units=meters",
              " --area_units=m2",
              " --ellipsoid=EPSG:7019 ",
              "--INPUT=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp.gpkg"),
              " --PREDICATE=5",
              " --JOIN=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg")),
              " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=false --PREFIX=",
              " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masque1LIdGlobal.gpkg")))
system(cmd)

dimMasq1=dim(Masques1L)[1]
Masques1L=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masque1LIdGlobal.gpkg"))

if (dimMasq1!=dim(Masques1L)[1]){BADABOUM=PASLEEMENOMBREDOBKET_BUG}

# Recehcrhe des masques 1 non traités
nM1b=which(is.na(Masques1L$IdGlobal))
Masques1L$FILINO="Vide"
Masques1L$FILINO[-nM1b]="Direct"
if (Nettoyage==1)
{
  unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp.gpkg"))
  # unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg"))
  unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masque1LIdGlobal.gpkg"))
}


# Intersection des masques 1 non traités avec les masques 2
cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," %%% JOINTURE spatiale des Masques1 restant croisant un ou plusieurs Masques2\n")
cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque1 restant\n")
st_write(Masques1L[nM1b,"Id"],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp2.gpkg"),delete_layer=T, quiet=T)
cmd <- paste0(qgis_process, " run native:createspatialindex",
              " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
              " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp2.gpkg")))
system(cmd)

cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
              " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
              " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp2.gpkg")),
              " --PREDICATE=0",
              " --JOIN=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg")),
              " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
              " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.csv")))
system(cmd)

liaison=read.csv(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.csv"))



if (dim(liaison)[1]>0)
{
  liaison=liaison[order(liaison$Id,liaison$IdGlobal),]
  # Boucle sur les morceau 1
  # for (i_Inter in which(sapply(n_Inter, length)>0))
  
  Iav=0
  Compl=max(1,length(unique(liaison$Id)))
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
            st_geometry(Coupons[idb,])=st_simplify(st_sfc(st_linestring(coord[2:(dim(coord)[1]-1),1:2]),crs=nEPSG),preserveTopology =TRUE,dTolerance =0)
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
      #          file.path(dsnlayer,NomDirMasqueVIDE,"Coupons.gpkg"), delete_layer=T, quiet=T)
      
      #rajout des morceaux
      Masques1L=rbind(Masques1L,Coupons)
    }
    cat("\n")
  }
}
st_write(Masques1L,
         file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1_FILINO.gpkg"), delete_layer=T, quiet=T)
####
if (file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg"))==TRUE)
{
  trhydro=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg"))
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Troncons Hydro",dim(trhydro),"\n")
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial Masque2 sans les vieux\n")
  st_write(Masques2,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp2.gpkg"),delete_layer=T, quiet=T)
  cmd <- paste0(qgis_process, " run native:createspatialindex",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp2.gpkg")))
  system(cmd)
  
  cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro.gpkg")),
                " --PREDICATE=0",
                " --JOIN=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp2.gpkg")),
                " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
                " --OUTPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.csv")))
  system(cmd)
  
  liaison2=read.csv(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.csv"))
  
  Iav=0
  Compl=max(1,length(unique(liaison2$IdGlobal)))
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
      FILINO_Creat_Dir(rep_SURFEAU)
      st_write(trhydro[ncle,],file.path(rep_SURFEAU,"trhydro.gpkg"), delete_layer=T, quiet=T)
    }
  }
  setTxtProgressBar(pgb, Compl)
}
cat("\n",format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin\n")

unlink(nom_Manuel_tmp)
unlink(nom_Manuel2)
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu","Coupe",".gpkg")))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2troptouche",".gpkg")))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltouchetropMasques2",".gpkg")))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp.gpkg"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_Seuil1000m2_tmp.gpkg"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1L_tmp2.gpkg"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_tmp2.gpkg"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2Vieux.csv"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.csv"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.csv"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masque1LIdGlobal.gpkg"))
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2recupManu.gpkg"))
