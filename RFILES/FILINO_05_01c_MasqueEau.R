cat("\014")

nomMasque2Seuil=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg"))
nomMasque1     =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.gpkg")
nomMasque2     =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg")

cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 1\n")
Masques1=st_read(nomMasque1)
st_geometry(Masques1)="geometry"

# Sauvegarde du fichier d'entree en OLD
nom_copy=paste0(substr(nomMasque2Seuil,1,nchar(nomMasque2Seuil)-5),"_",format(Sys.time(),format="%Y%m%d_%H%M"),".gpkg")
file.copy(nomMasque2Seuil,nom_copy,overwrite = TRUE)

# Fusion des objets par un même numéro d'entité (utile avant mais ? depuis la méthode manuelle)
# oui si on veut bouger la valeur que dans le fichier seuil et pas avoir le fichier Travail Manuel mais inefficace
cmd=paste0(qgis_process, " run native:collect",
           " --INPUT=",shQuote(nom_copy),
           " --FIELD=Id",
           " --OUTPUT=",shQuote(nomMasque2Seuil))
system(cmd)

# Lecture du Masque 2 Seuil automatique 
cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
Masques2Seuil=st_read(nomMasque2Seuil)
st_geometry(Masques2Seuil)="geometry"

################################################################################
############ Intégration du travail manuel
if (Opt_Manuel==1)
{
  if (file.exists(nom_Manuel))
  {
    # Lectue du fichier de travail manuel
    Manuel=st_read(nom_Manuel)
    nom_Manuel_tmp=nom_Manuel
    
    # Intersection du Masque2Seuil avec ce fichier
    NomA=nomMasque2Seuil
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2Vieux.csv")
    liaison=FILINO_Intersect_Qgis(NomA,nom_Manuel_tmp,NomC)
    
    NIDVieux=unique(liaison$Id)
    
    # Suppression des calculs obsolètes (points virtuel, images mais on conserve le dossier si on doit revenir dessus!
    for (IDVieux in NIDVieux)
    {
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
    
    # Récupération des masques 2 auto qui croisent la travail manuel
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2SeuilrecupManu.gpkg")
    FILINO_Intersect_Qgis(NomA,nom_Manuel2,NomC)
    M2SeuilrecupManu=st_read(NomC)
    
    # Récupération des masques 2 initiaux qui croisent la travail manuel
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2recupManu.gpkg")
    FILINO_Intersect_Qgis(nomMasque2,nom_Manuel2,NomC)
    Masque2recupManu=st_read(NomC)
    
    # Enlever les vieux Mer...
    nvieux=grep(M2SeuilrecupManu$FILINO,pattern="Vieu")
    if (length(nvieux)>0){M2SeuilrecupManu=M2SeuilrecupManu[-nvieux,]}
    
    
    
    
    
    ############################################################################
    ##### Travail géométrique des découpes et de suppression de polygones
    ############################################################################
    # Etap1c
    ###### Travail de COUPE 
    nCoupe=which(Manuel$FILINO=="COUPE")
    if (length(nCoupe>0))
    {
      ################################################################
      # Travail sur les masques 2 initial sans appareillage
      Masque2recupManu=st_difference(Masque2recupManu,st_union(Manuel[nCoupe,]))
      types_geometrie <- st_geometry_type(Masque2recupManu)
      Masque2recupManu=st_cast(Masque2recupManu[which(types_geometrie=="POLYGON" | types_geometrie=="MULTIPOLYGON"),])
      
      Masque2recupManu=st_cast(Masque2recupManu,"POLYGON")
      if (verif==1){st_write(Masque2recupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu","Coupe",".gpkg")), delete_layer=T, quiet=T)}
      
      ################################################################
      # Travail sur les masques 2 AUTO avec appareillage
      # boucle sur tous les endroits à couper
      for (iCoupe in nCoupe)
      {
        PasFusion=0
        # croisement avec l'objet Masques2Auto
        nbiCoupe=st_intersects(M2SeuilrecupManu,Manuel[iCoupe,1])
        n_nbiCoupe = which(sapply(nbiCoupe, length)>0)
        
        if (length(n_nbiCoupe)>0)
        {
          # Travail une découpe par masque touché
          M2SeuilrecupManu_i=st_difference(M2SeuilrecupManu[n_nbiCoupe,],Manuel[iCoupe,1])
          types_geometrie <- st_geometry_type(M2SeuilrecupManu_i)
          M2SeuilrecupManu_i=st_cast(M2SeuilrecupManu_i[which(types_geometrie=="POLYGON" | types_geometrie=="MULTIPOLYGON"),])
          M2SeuilrecupManu_i=st_cast(M2SeuilrecupManu_i,"POLYGON")
          if (dim(M2SeuilrecupManu_i)[1]==0)
          {
            st_write(Manuel[iCoupe,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManuelCoupeTOUT_AMETTREEN_SUPP",".gpkg")), delete_layer=T, quiet=T)
            Badaboom=Voir_fichier_ManuelCoupeTOUT_AMETTREEN_SUPP
          }
          M2SeuilrecupManu_i=st_cast(M2SeuilrecupManu_i,"POLYGON")
          
          if (dim(M2SeuilrecupManu_i)[1]==1){Rien_a_faire=1}
          
          # S'il y a plus de deux objets, on va regarder l'objet à droite et à gauche
          # puis raccroché les autres objets
          if (dim(M2SeuilrecupManu_i)[1]>1)
          {
            # On regarde ceux qui touche et on récupère leurs indices
            nbDrGa=st_intersects(M2SeuilrecupManu_i,st_buffer(Manuel[iCoupe,1],0.1))
            n_nbDrGa = which(sapply(nbDrGa, length)>0)
            if (length(n_nbDrGa)>1)
            {
              # On regarde s'il y en a d'autres que ceux qui touchent
              if (dim(M2SeuilrecupManu_i)[1]>length(n_nbDrGa))
              {
                NonColles=M2SeuilrecupManu_i[-n_nbDrGa,]
                M2SeuilrecupManu_i=M2SeuilrecupManu_i[n_nbDrGa,]
                for (iDrGa in 1:dim(M2SeuilrecupManu_i)[1])
                {
                  PasFusion=1
                  distance=st_distance(M2SeuilrecupManu_i[iDrGa,],NonColles)
                  # boucle pour coller les petits morceaux
                  
                  seuil_tmp=seuilSup3
                  distbufAsso=c(15, # Ecoulemnt
                                10) # Canal
                  
                  if (substr(M2SeuilrecupManu$FILINO[iDrGa],1,4)=="Cana"){seuil_tmp=2*distbufAsso[1]}
                  if (substr(M2SeuilrecupManu$FILINO[iDrGa],1,4)=="Ecou"){seuil_tmp=2*distbufAsso[2]}
                  seuil_tmp=15
                  
                  units(seuil_tmp)="m"
                  while(min(distance)<=1.5*seuil_tmp & dim(NonColles)[1]>0)
                  {
                    nacoller=which(distance<=seuil_tmp)
                    
                    DF=M2SeuilrecupManu_i[iDrGa,]
                    st_geometry(DF)=NULL
                    M2SeuilrecupManu_i[iDrGa,]=st_sf(DF,
                                                     st_geometry=st_union(st_union(M2SeuilrecupManu_i[iDrGa,]),st_union(NonColles[nacoller,])))
                    
                    NonColles=NonColles[-nacoller,]
                    if (dim(NonColles)[1]>0)
                    {
                      distance=st_distance(M2SeuilrecupManu_i[iDrGa,],NonColles)
                    }else{
                      distance=seuil_tmp*2
                    }
                  }
                }
                if (dim(NonColles)[1]>0)
                {
                  st_write(NonColles,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("NonColles",".gpkg")), delete_layer=T, quiet=T)
                  BUG=TOUTNAPASETERECOLLE
                }
              }
              
              # On reassemble ceux qui doivent l'être
              if (dim(M2SeuilrecupManu_i)[1]>0 & PasFusion==0)
              {
                DF=M2SeuilrecupManu_i[1,]
                st_geometry(DF)=NULL
                M2SeuilrecupManu_i=st_sf(DF,geom=st_union(M2SeuilrecupManu_i))
              }
            }
          }
          M2SeuilrecupManu=rbind(M2SeuilrecupManu[-n_nbiCoupe,],M2SeuilrecupManu_i[,colnames(M2SeuilrecupManu)])
          
        }
        # if (verif==1){st_write(M2SeuilrecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2SeuilrecupManu","Coupe",".gpkg")), delete_layer=T, quiet=T)}
      } 
      M2SeuilrecupManu$Id=FILINO_NomMasque(M2SeuilrecupManu)
      if (verif==1)
      {
        st_write(M2SeuilrecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2SeuilrecupManu","_APRES_COUPE",".gpkg")), delete_layer=T, quiet=T)
      }
    }
    
    ##################### MSUPP #################################
    # Suppression des objets touchés avec un ou plusieurs polygoens dans l'objet
    nMSUPP=which(Manuel$FILINO=="MSUPP")
    if (length(nMSUPP)>0)
    {
      # croisement avec l'objet Masques2Auto
      nb_MSUPP=st_intersects(M2SeuilrecupManu,Manuel[nMSUPP,1])
      n_nb_MSUPP = which(sapply(nb_MSUPP, length)>0)
      print(n_nb_MSUPP)
      if (length(n_nb_MSUPP)>0)
      {
        M2SeuilrecupManu=M2SeuilrecupManu[-n_nb_MSUPP,]
      }
      if (verif==1)
      {
        st_write(M2SeuilrecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2SeuilrecupManu","_APRES_COUPE_MSUPP",".gpkg")), delete_layer=T, quiet=T)
      }
    }
    
    ##################### SUPP #################################
    # Suppression des objets touchés avec un ou plusieurs polygoens dans l'objet
    nSUPP=which(Manuel$FILINO=="SUPP")
    if (length(nSUPP)>0)
    {
      # croisement avec l'objet Masques2Auto
      nb_SUPP=st_intersects(M2SeuilrecupManu,Manuel[nSUPP,1])
      n_nb_SUPP = which(sapply(nb_SUPP, length)>0)
      print(n_nb_SUPP)
      if (length(n_nb_SUPP)>0)
      {
        # Boucle sur chaque objet pour aller voir si'l contient plusieurs polygones
        for (isupp in n_nb_SUPP)
        {
          M2Seuil_tmp=st_cast(M2SeuilrecupManu[isupp,],"POLYGON")
          if (dim(M2Seuil_tmp)[1]==1)
          {
            # S'il n'y a qu'un objet, on supprime direct
            M2SeuilrecupManu[isupp,]$FILINO="SUPP"
          }else{
            nb_SUPP_i=st_intersects(M2Seuil_tmp,Manuel[nSUPP,1])
            n_nb_SUPP_i = which(sapply(nb_SUPP_i, length)>0)
            print(n_nb_SUPP_i)
            if (length(n_nb_SUPP)==1)
            {
              M2SeuilrecupManu[isupp,]$FILINO="SUPP"
            }else{
              M2Seuil_tmp=M2Seuil_tmp[-n_nb_SUPP_i,]
              DF=M2Seuil_tmp[1,]
              st_geometry(DF)=NULL
              M2Seuil_tmp=st_sf(DF,geom=st_union(M2Seuil_tmp))
              M2SeuilrecupManu[isupp,]=M2Seuil_tmp
            }
          }
        }
      }
      niciSUPP=which(M2SeuilrecupManu$FILINO=="SUPP")
      if (length(niciSUPP)>0){M2SeuilrecupManu=M2SeuilrecupManu[-niciSUPP,]}
      if (verif==1)
      {
        st_write(M2SeuilrecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2SeuilrecupManu","_APRES_COUPE_MSUPP_SUPP",".gpkg")), delete_layer=T, quiet=T)
      }
    }
    
    ####################################################################################################
    ###### Affectation Manuelle de nouveaux types
    iAutre=which(Manuel$FILINO=="COUPE" | Manuel$FILINO=="MSUPP" | Manuel$FILINO=="SUPP")
    if (length(iAutre)<dim(Manuel)[1])
    {
      Manuel_Affec=Manuel[-iAutre,]
      st_write(Manuel_Affec,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Manuel_Affecquicroise",".gpkg")), delete_layer=T, quiet=T)
      
      nbMC=st_intersects(M2SeuilrecupManu,st_geometry(Manuel_Affec))
      n_intMC = which(sapply(nbMC, length)>0)
      MSeuilFini_SansRegroupement=NaN
      MSeuil_BesoinRegroupement=NaN
      # Si aucun croisement on garde tout
      if (length(n_intMC)==0)
      {
        MSeuilFini_SansRegroupement=M2SeuilrecupManu
      }
      # Si croisment, on garde ceux qui ne croisent pas
      # et on mets ceux qui croisent avec les masques initiaux
      
      if (length(n_intMC)>0)
      {
        MSeuilFini_SansRegroupement=M2SeuilrecupManu[-n_intMC,]
        if (dim(MSeuilFini_SansRegroupement)[1]==0)
        {
          
          MSeuilFini_SansRegroupement=NaN
        }
        
        MSeuil_BesoinRegroupement=M2SeuilrecupManu[n_intMC,]
      }
      if (verif==1)
      {
        st_write(MSeuilFini_SansRegroupement,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("MSeuilFini_SansRegroupement",".gpkg")), delete_layer=T, quiet=T)
      }
      
      if (is.na(MSeuilFini_SansRegroupement)[1]==F)
      {
        st_geometry(MSeuilFini_SansRegroupement)="geometry"
        Masques2Seuil=rbind(Masques2Seuil,MSeuilFini_SansRegroupement)
      }
      
      # Suppression des Masques2 originaux qui touchent les automatiques sans problème...
      nbenleveM2=st_intersects(Masque2recupManu,Masques2Seuil)
      n_intenleveM2 = which(sapply(nbenleveM2, length)>0)
      if (length(n_intenleveM2)>0)
      {
        if (verif==1)
        {
          st_write(Masque2recupManu[n_intenleveM2,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu_lesmorceauxenlever",".gpkg")), delete_layer=T, quiet=T)
          st_write(Masque2recupManu[-n_intenleveM2,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu_a_ajouter_pour_chgt_type",".gpkg")), delete_layer=T, quiet=T)
        }
        Masque2recupManu=Masque2recupManu[-n_intenleveM2,] 
      }
      
      if (dim(Masque2recupManu)[1]==0)
      {
        Masque2recupManu=M2SeuilrecupManu[,colnames(Masque2recupManu)]
      }else{
        Masque2recupManu=rbind(Masque2recupManu,M2SeuilrecupManu[,colnames(Masque2recupManu)])
      }
      if (verif==1)
      {
        st_write(Masque2recupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu_et_M2SeuilrecupManu",".gpkg")), delete_layer=T, quiet=T)
      }
      
      # Vérification qu'il n'y ait pas un objet de masques 2 touchés par plusieurs zones utilisateur
      nbMC=st_intersects(Masque2recupManu,st_geometry(Manuel_Affec))
      n_intMC = which(sapply(nbMC, length)>1) # attention >1 pour en avoir 2
      if (length(n_intMC)>0)
      {
        Masques2troptouche=Masque2recupManu[n_intMC,1]
        plot(Masques2troptouche)
        st_write(Masques2troptouche,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2troptouche",".gpkg")), delete_layer=T, quiet=T)
        
        nbMC=st_intersects(Manuel_Affec,Masques2troptouche)
        n_intMC = which(sapply(nbMC, length)>0)
        ManuelMauvais=Manuel_Affec[n_intMC,]
        
        plot(ManuelMauvais[,1])
        st_write(ManuelMauvais,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltouchetropMasques2",".gpkg")), delete_layer=T, quiet=T)
        
        cat("les masques de ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masque2recupManu","Coupe",".gpkg"))," \n")
        cat("touchent plusieurs de vos zones ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltouchetropMasques2",".gpkg"))," \n")
        BOOM=BOOOM
      }
    }
    
    #########################################################################
    ############## Affectation des nouveaux types ###########################
    #########################################################################
    motclesMRM=cbind("Eco","Pla","Can","Mer","MPl")
    incAj=1
    for (imotcle in motclesMRM)
    {
      
      indMotcle=which(substr(Manuel$FILINO,1,3)==imotcle)
      if (length(indMotcle)>0)
      { 
        cat("Affectation des nouveaux types: ",imotcle,"\n")
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
            
            # Si c'est du multiplan, on éclate
            if (imotcle=="MPl")
            {
              MasqueIm$FILINO="PlanM"
              MasqueIm=st_cast(MasqueIm,"POLYGON")
            }
            
            Masques2Seuil=rbind(Masques2Seuil,MasqueIm)
          }
        }
      } 
      
    }
    
    
    iAJOUT=which(Manuel$FILINO=="AJOUT")
    if (length(iAJOUT>0))
    {
      # Il faudrait garder que les ajouts qui sont dans la st_box de Masques1 et Masques2 +/- qqch
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
          Masques1=rbind(Masques1[,colnames(Masque1Im)],Masque1Im)
        }
      } 
      
    }else{
      
    }
  }
}

# Export du masques 2 FILINO
Masques2=Masques2Seuil
# Calcul de l'aire
Masques2$Aire=round(st_area(Masques2),0)
# Renumérotation
Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
##### Codification
Masques2$Id=FILINO_NomMasque(Masques2)
Masques2$IdGlobal=Masques2$Id

# Export du nouveau fichier
nomMasques2_FILINO=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_FILINO",".gpkg"))
st_write(Masques2,nomMasques2_FILINO, delete_layer=T, quiet=T)

###########################################################################
###### Appareillage des Masques 1 sur les Masques 2 FILINO
#######################################################################
# Etap1c
cat("Appareillage des Masques 1 sur les Masques 2 FILINO","\n")

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
    cat("\n Masque1 n°",i_Interi, " est à l'intérieur du/des ")
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

# Export du nouveau fichier
nomMasques1_FILINO=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques1_FILINO",".gpkg"))
st_write(Masques1L,nomMasques1_FILINO, delete_layer=T, quiet=T)

#############################################################################
####################  Copie des tronçons de cours d'eau associés aux masques
#############################################################################
####

cat("Copie des tronçons de cours d'eau associés aux masques","\n")

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
      trhydro_surf=trhydro[ncle,]
      # Rajout des tronçons de cours d'eau nommés qui ne croisent pas (éviter d'avoir un troncon coupé en deux pour un même masque)
      nomCE=unique(trhydro_surf$liens_vers_cours_d_eau)
      if (length(which(is.na(nomCE)==F))>0)
      {
        trhydro_=trhydro_surf
        nomCE=nomCE[which(is.na(nomCE)==F)]
        voila=lapply(nomCE, function(x) {trhydro[which(trhydro$liens_vers_cours_d_eau==x),]})
        
        trhydro_2=do.call(rbind, voila)
        # ne prendre que ceux dans la bbox
        
        nbtm=st_intersects(trhydro_2, st_buffer(st_as_sfc(st_bbox(Masques2[which(Masques2$IdGlobal==imasq),])),500))
        n_intnbtm <-  which(sapply(nbtm, length) > 0)
        trhydro_2 <- trhydro_2[n_intnbtm,]
        
        trhydro_surf=rbind(trhydro_,trhydro_2)
        
        
        trhydro_surf=trhydro_surf[order(trhydro_surf$cleabs),]
        trhydro_surf$doublons=0
        
        for (i in 2:dim(trhydro_surf)[1])
        {
          if (trhydro_surf$cleabs[i]==trhydro_surf$cleabs[i-1]){trhydro_surf$doublons[i]=1}
        }
        trhydro_surf=trhydro_surf[which(trhydro_surf$doublons==0),]
      }
      
      rep_SURFEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,imasq))
      FILINO_Creat_Dir(rep_SURFEAU)
      st_write(trhydro_surf,file.path(rep_SURFEAU,"trhydro.gpkg"), delete_layer=T, quiet=T)
    }
  }
  setTxtProgressBar(pgb, Compl)
}
cat("\n",format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin\n")

# unlink(nom_Manuel_tmp)
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
