# Ceci est la routine FILINO_05_01c_MasqueEau de FILINO disponible sur https://github.com/CEREMA/filino
# Est-ce que tu peux l'évaluer, l'améliorer, la rendre plus rapide, faire des sous-fonctions au besoin

# Explication de la routine
# Cette routine est la plus complexe de FILINO, elle a pour objectif de mélanger les résultats des couches
# - Masques VIDE et EAU nommé "Masque2 ou M2"
# - Masques VIDE et EAU qui ont déjà fait l'objet d'un appareillage automatique avec la BDTopo nommé "Masque2Seuil ou M2Seuil"
# avec la couche
# - Manuel qui dispose d'un travail d'un opérateur humain pour décrire si l'objet doit être 
#   - COUPE, SUPP (supprimé polygones dans les multipolygones), MSUPP (suppression des multipolygones)
#   - Changer d'affectation (Plan, Ecou, Mer, Canal)
# La difficulté du travail sur ces masques 2 est 
# - de garder le maximum du travail automatique
# - de modifier ce que l'opérateur veut modifier
#   - sur le masque automatique nommé "Masque2Seuil ou M2Seuil"
#   - en même temps que la masque2 initial nommé "Masque2 ou M2"

# La prédécoupe initiale de la mer peut parfois complexifier le sujet

# Quand tos les types de masques 2 sont affectés, les masques 1 sont appreillés pour faire la liaison entre masques 2 où on va récupérer l'altitude et masques1 où on va créer des points virtuels

# Nettoyage de la console
cat("\014")

nomMasque2Seuil=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg"))
nomMasque1     =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1.gpkg")
nomMasque2     =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2.gpkg")

#-------------------------------------------------------------------------------
# Lecture du Masque 1
cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 1\n")
Masques1=st_read(nomMasque1)
st_geometry(Masques1)="geometry"

# Sauvegarde du fichier d'entree en OLD
nom_copy=paste0(substr(nomMasque2Seuil,1,nchar(nomMasque2Seuil)-5),"_",format(Sys.time(),format="%Y%m%d_%H%M"),".gpkg")
file.copy(nomMasque2Seuil,nom_copy,overwrite = TRUE)

#-------------------------------------------------------------------------------
# Fusion des objets par un même numéro d'entité (utile avant mais ? depuis la méthode manuelle)
# oui si on veut bouger la valeur que dans le fichier seuil et pas avoir le fichier Travail Manuel mais inefficace
cmd=paste0(qgis_process, " run native:collect",
           " --INPUT=",shQuote(nom_copy),
           " --FIELD=Id",
           " --OUTPUT=",shQuote(nomMasque2Seuil))
system(cmd)

# Lecture du Masque 2 Seuil automatique 
cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
M2Seuil=st_read(nomMasque2Seuil)
st_geometry(M2Seuil)="geometry"

################################################################################
############ Intégration de la couche SIG de travail manuel si l'option et le fichier existent
if (Opt_Manuel==1)
{
  if (file.exists(nom_Manuel))
  {
    # Lecture du fichier de la couche SIG de travail manuel avec des codes comme COUP SUPP Ecou...
    Manuel=st_read(nom_Manuel)
    nom_Manuel_tmp=nom_Manuel
    
    # Intersection du Masque2Seuil avec la couche SIG de travail manuel
    NomA=nomMasque2Seuil
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2Vieux.csv")
    liaison=FILINO_Intersect_Qgis(NomA,nom_Manuel_tmp,NomC)
    
    NIDVieux=unique(liaison$Id)
    
    
    # Lecture de la table d'assemblage
    TA=st_read(file.path(dsnlayerTA,nomlayerTA))
    nb=st_intersects(TA,M2Seuil)
    n_int = which(sapply(nb, length)>0)
    TA_=TA[n_int,]
    
    # Si le travail manuel intersecte des M2Seuil_XXX, alors tous ces masques sont mis en vieux
    # Il y a aussi la suppression des calculs obsolètes (points virtuel, images mais on conserve le dossier si on doit revenir dessus! dans filino
    
    cat("liste des suppressions possibles des anciens calculs de points virtuels\n")
    for (IDVieux in NIDVieux)
    {
      #-------------------------------------------------------------------------
      Masq_tmp=M2Seuil[which(M2Seuil$Id==IDVieux),]
      
      # travail pour savoir si les surfaces en eau seront mis dans des dossiers
      # - par dalles si le masques est inclus dans une dalle
      # - par noms de surfaces en eau si le masquedépasse une dalle
      TA_tmp=TApourFunc_RepSurfCoursEau(TA_,Masq_tmp)
      
      
      rep_SURFEAU=Func_RepSurfCoursEau(st_bbox(Masq_tmp),TA_tmp$NOM,dsnlayer,NomDirSurfEAU,racilayerTA,raciSurfEau)
      raciMasq=paste0(raciSurfEau,Masq_tmp$Id)
      rep_SURFEAU=file.path(rep_SURFEAU,raciMasq)
      
      
      
      
      
      # Il y a aussi la suppression des calculs obsolètes (points virtuel, images mais on conserve le dossier si on doit revenir dessus! dans filino
      repVieux=rep_SURFEAU#file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,IDVieux))
      VieuxJpg=list.files(repVieux,pattern=paste0(raciSurfEau,IDVieux,"_",racilayerTA))
      
      NomASupp=cbind(file.path(repVieux,paste0(raciSurfEau,"_PtsVirt.copc.laz")),
                     file.path(repVieux,paste0(raciSurfEau,"_PtsVirt.csv")),
                     file.path(repVieux,VieuxJpg))
      for (iTAlaz in 1:nrow(TA_tmp))
      {
        TA_tmp_=TA_tmp[iTAlaz,]
        rep_COURSEAU=Func_RepSurfCoursEau(st_bbox(TA_tmp_),TA_tmp_$NOM,dsnlayer,NomDirSurfEAU,racilayerTA,raciSurfEau)
        raci=paste0(raciSurfEau,"_",basename(rep_COURSEAU))
        NomLaz_tmp=ifelse(substr(raci,nchar(raci)-4,nchar(raci))==".copc",
                          paste0(raci,".laz"),
                          paste0(raci,".copc.laz"))
        NomASupp=cbind(NomASupp,file.path(rep_COURSEAU,NomLaz_tmp))
      }
      
      for (iNomASupp in NomASupp)
      {
        if (file.exists(iNomASupp)==T)
        {
          unlink(iNomASupp)
          cat(iNomASupp, "supprimé\n")
        }
      }
      
      #-------------------------------------------------------------------------
      # Modification du champ FILINO des masques seuillés
      # cat("M2Seuil: ",nrow(M2Seuil),"\n")
      # Si le travail manuel intersecte des M2Seuil_XXX, alors tous ces masques sont mis en vieux
      M2Seuil$FILINO[which(M2Seuil$Id==IDVieux)]="VieuxManuel"
      # cat("M2Seuil: ",nrow(M2Seuil),"\n")
    }
    
    #---------------------------------------------------------------------------------------------------------------
    # Remplissage des champs vides de la couche SIG de travail manuel par des valeurs par défaut
    Manuel=st_read(nom_Manuel_tmp)
    if (length(which(is.na(Manuel$ValPlanEAU)))>0) {Manuel[which(is.na(Manuel$ValPlanEAU)) ,]$ValPlanEAU =ValPlanEAU}
    if (length(which(is.na(Manuel$CE_BalPas)))>0)  {Manuel[which(is.na(Manuel$CE_BalPas))  ,]$CE_BalPas  =CE_BalPas}
    if (length(which(is.na(Manuel$CE_BalFen)))>0)  {Manuel[which(is.na(Manuel$CE_BalFen))  ,]$CE_BalFen  =CE_BalFen}
    if (length(which(is.na(Manuel$CE_PenteMax)))>0){Manuel[which(is.na(Manuel$CE_PenteMax)),]$CE_PenteMax=CE_PenteMax}
    if (length(which(is.na(Manuel$NumCourBox)))>0) {Manuel[which(is.na(Manuel$NumCourBox)), ]$NumCourBox =NumCourBox}
    
    #---------------------------------------------------------------------------------------------------------------
    # Fusion de la couche SIG de travail manuel pour améliorer les temps de calculs (intersections)
    nom_Manuel2=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"ManuelFusion.gpkg")
    st_write(st_union(Manuel),nom_Manuel2, delete_layer=T, quiet=T)
    
    #---------------------------------------------------------------------------------------------------------------
    # Récupération des masques 2 seuil qui croisent la couche SIG de travail manuel 
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"M2SeuilrecupManu.gpkg")
    FILINO_Intersect_Qgis(NomA,nom_Manuel2,NomC)
    M2Seuil_RecupManu=st_read(NomC)
    
    # Récupération des masques 2 initiaux qui croisent la couche SIG de travail manuel 
    NomC=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2recupManu.gpkg")
    FILINO_Intersect_Qgis(nomMasque2,nom_Manuel2,NomC)
    M2_RecupManu=st_read(NomC)
    
    # Enlever les vieux Mer dans masques 2 seuil
    nvieux=grep(M2Seuil_RecupManu$FILINO,pattern="Vieu")
    if (length(nvieux)>0){M2Seuil_RecupManu=M2Seuil_RecupManu[-nvieux,]}
    
    
    ############################################################################
    ##### Travail géométrique des découpes et de suppression de polygones
    ############################################################################
    ###### Travail de COUPE 
    cat("---------------------------------------------------------------\n")
    cat("---------------------------------------------------------------\n")
    cat("Travail sur les objets COUPE de la couche SIG de travail manuel\n")
    nCoupe=which(Manuel$FILINO=="COUPE")
    
    if (length(nCoupe>0))
    {
      ################################################################
      # Travail sur les masques 2 initial sans appareillage
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Découpage des Masques2 qui croisent les objets COUPE de la couche SIG de travail manuel - Début\n")
      M2_RecupManu=st_difference(M2_RecupManu,st_union(Manuel[nCoupe,]))
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Découpage des Masques2 qui croisent les objets COUPE de la couche SIG de travail manuel - Fin\n")
      cat("---------------------------------------------------------------\n")
      cat("Liste à COUPER: ",nCoupe,"\n")
      if (verif==1){st_write(M2_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_RecupManu","Coupe_1",".gpkg")), delete_layer=T, quiet=T)}
      
      types_geometrie <- st_geometry_type(M2_RecupManu)
      M2_RecupManu=M2_RecupManu[which(types_geometrie=="POLYGON" | types_geometrie=="MULTIPOLYGON"),]
      M2_RecupManu=st_cast(st_cast(M2_RecupManu,"MULTIPOLYGON"),"POLYGON")
      if (verif==1){st_write(M2_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_RecupManu","Coupe_2",".gpkg")), delete_layer=T, quiet=T)}
      
      if (verif==1)
      {
        # browser()
        st_write(M2Seuil_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2Seuil_RecupManu","_AVANT_COUPE",".gpkg")), delete_layer=T, quiet=T)
      }
      
      ################################################################
      # boucle sur tous les endroits à couper
      for (iCoupe in nCoupe)
      {
        cat(format(Sys.time(),format="%Y%m%d_%H%M%S"),"- COUPE: ",iCoupe)
        # Croisement des Masques2Auto avec les objets COUP de la couche SIG de travail manuel 
        nbiCoupe=st_intersects(M2Seuil_RecupManu,Manuel[iCoupe,1])
        n_nbiCoupe = which(sapply(nbiCoupe, length)>0)
        
        if (length(n_nbiCoupe)>0)
        {
          # Boucle sur tous les multi-objets touchés
          for (i_n_nbiCoupe in n_nbiCoupe)
          {
            # Travail une découpe par masque touché
            M2Seuil_RecupManu_i=st_difference(M2Seuil_RecupManu[i_n_nbiCoupe,],Manuel[iCoupe,1])
            types_geometrie <- st_geometry_type(M2Seuil_RecupManu_i)
            M2Seuil_RecupManu_i=st_cast(M2Seuil_RecupManu_i[which(types_geometrie=="POLYGON" | types_geometrie=="MULTIPOLYGON"),])
            
            # Si COUP supprime tout l'objet, il faut choisir une autre option!
            if (dim(M2Seuil_RecupManu_i)[1]==0)
            {
              st_write(Manuel[iCoupe,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("COUCHE_SIG_Manuel_COUP_a_mettre_en_SUPP_ou_MSUPP",".gpkg")), delete_layer=T, quiet=T)
              Badaboom=Voir_fichier_COUCHE_SIG_Manuel_COUP_a_mettre_en_SUPP_ou_MSUPP
            }
            
            M2Seuil_RecupManu_i=st_cast(st_cast(M2Seuil_RecupManu_i,"MULTIPOLYGON"),"POLYGON")
            M2Seuil_RecupManu_i=st_cast(M2Seuil_RecupManu_i,"POLYGON")
            
            # Si COUP ne crée qu'un objet, il n'y a rien à faire
            if (dim(M2Seuil_RecupManu_i)[1]==1){Rien_a_faire=1}
            
            # S'il y a plus de deux objets, on va recombiner les objets pas plus proches voisins
            # aux objets qui sont sur la frontière de découpe
            if (dim(M2Seuil_RecupManu_i)[1]>1)
            {
              # On regarde ceux qui touche et on récupère leurs indices
              nb_ToucheCOUPE=st_intersects(M2Seuil_RecupManu_i,st_buffer(Manuel[iCoupe,1],0.1))
              n_nb_ToucheCOUPE = which(sapply(nb_ToucheCOUPE, length)>0)
              if (length(n_nb_ToucheCOUPE)>1)
              {
                # On regarde s'il y en a d'autres que ceux qui touchent
                if (dim(M2Seuil_RecupManu_i)[1]>length(n_nb_ToucheCOUPE))
                {
                  NonColles=M2Seuil_RecupManu_i[-n_nb_ToucheCOUPE,]  
                  M2Seuil_RecupManu_i=M2Seuil_RecupManu_i[n_nb_ToucheCOUPE,]
                  itour=0
                  cat(" - Regroupement complexe et peut-être extrêmement long - ")
                  # Boucle pour coller les morecaux qui ne touchent pas COUPE
                  while(dim(NonColles)[1]>0)
                  {
                    cat(" ",nrow(NonColles))
                    if (verif==1){
                      st_write(NonColles,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("NonColles_COUPE_",iCoupe,"_",itour,".gpkg")), delete_layer=T, quiet=T)
                      st_write(M2Seuil_RecupManu_i,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2Seuil_RecupManu_COUPE_",iCoupe,"_",itour,".gpkg")), delete_layer=T, quiet=T)
                    }
                    # On calcul la distance entre les morceaux qui touchent COUPE et les morceaux non collés
                    distanceCOUPE=st_distance(NonColles,M2Seuil_RecupManu_i)
                    # on récupère le polygone qui touche COUPE et qui a un voisin le plus proche
                    distanceCOUPE_Min=apply(distanceCOUPE, 2, min)
                    nM2Seuil_RecupManu_i_amodif=which.min(distanceCOUPE_Min)
                    nACOLLER=which.min(distanceCOUPE[,nM2Seuil_RecupManu_i_amodif])
                    
                    DF=M2Seuil_RecupManu_i[nM2Seuil_RecupManu_i_amodif,]
                    st_geometry(DF)=NULL
                    M2Seuil_RecupManu_i[nM2Seuil_RecupManu_i_amodif,]=st_sf(DF,
                                                                            st_geometry=st_union(st_union(M2Seuil_RecupManu_i[nM2Seuil_RecupManu_i_amodif,]),st_union(NonColles[nACOLLER,])))
                    NonColles=NonColles[-nACOLLER,]
                    itour=itour+1
                  }
                }
              }else{
                # browser()
                DF=M2Seuil_RecupManu_i[1,]
                st_geometry(DF)=NULL
                M2Seuil_RecupManu_i=st_sf(DF,
                                          st_geometry=st_union(M2Seuil_RecupManu_i))
                st_geometry(M2Seuil_RecupManu_i)="geom"
              }
            }
            # 
            M2Seuil_RecupManu=rbind(M2Seuil_RecupManu[-i_n_nbiCoupe,],M2Seuil_RecupManu_i[,colnames(M2Seuil_RecupManu)])
          }
          cat("\n")
        } 
        M2Seuil_RecupManu$Id=FILINO_NomMasque(M2Seuil_RecupManu)
      }
      if (verif==1)
      {
        # browser()
        st_write(M2Seuil_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2Seuil_RecupManu","_APRES_COUPE",".gpkg")), delete_layer=T, quiet=T)
      }
    }
    
    ##################### MSUPP #################################
    # Suppression des objets touchés avec un ou plusieurs polygones dans l'objet
    nMSUPP=which(Manuel$FILINO=="MSUPP")
    if (length(nMSUPP)>0)
    {
      cat("---------------------------------------------------------------\n")
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," - Gestion des MSUPP\n")
      # croisement avec l'objet Masques2Auto
      nb_MSUPP=st_intersects(M2Seuil_RecupManu,Manuel[nMSUPP,1])
      n_nb_MSUPP = which(sapply(nb_MSUPP, length)>0)
      print(n_nb_MSUPP)
      if (length(n_nb_MSUPP)>0)
      {
        M2Seuil_RecupManu=M2Seuil_RecupManu[-n_nb_MSUPP,]
      }
      if (verif==1)
      {
        # browser()
        st_write(M2Seuil_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2Seuil_RecupManu","_APRES_COUPE_MSUPP",".gpkg")), delete_layer=T, quiet=T)
      }
      cat("Fin des MSUPP\n")
    }
    
    
    ##################### SUPP #################################
    # Suppression des objets touchés avec un ou plusieurs polygones dans l'objet
    nSUPP=which(Manuel$FILINO=="SUPP")
    if (length(nSUPP)>0)
    {
      cat("---------------------------------------------------------------\n")
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," - Gestion des SUPP\n")
      cat("Parfois long si multipolygone avec bcp de données comme une mauvaise classification en mer...\n")
      # croisement avec l'objet Masques2Auto
      nb_SUPP=st_intersects(M2Seuil_RecupManu,Manuel[nSUPP,1])
      n_nb_SUPP = which(sapply(nb_SUPP, length)>0)
      print(n_nb_SUPP)
      if (length(n_nb_SUPP)>0)
      {
        # Boucle sur chaque objet pour aller voir s'il contient plusieurs polygones
        for (isupp in n_nb_SUPP)
        {
          M2Seuil_tmp=st_cast(M2Seuil_RecupManu[isupp,],"POLYGON")
          if (dim(M2Seuil_tmp)[1]==1)
          {
            # S'il n'y a qu'un objet, on supprime direct
            M2Seuil_RecupManu[isupp,]$FILINO="SUPP"
          }else{
            nb_SUPP_i=st_intersects(M2Seuil_tmp,Manuel[nSUPP,1])
            n_nb_SUPP_i = which(sapply(nb_SUPP_i, length)>0)
            print(n_nb_SUPP_i)
            if (length(n_nb_SUPP_i)==1)
            {
              M2Seuil_RecupManu[isupp,]$FILINO="SUPP"
            }else{
              M2Seuil_tmp=M2Seuil_tmp[-n_nb_SUPP_i,]
              DF=M2Seuil_tmp[1,]
              st_geometry(DF)=NULL
              M2Seuil_tmp=st_sf(DF,geom=st_union(M2Seuil_tmp))
              M2Seuil_RecupManu[isupp,]=M2Seuil_tmp
            }
          }
        }
      }
      niciSUPP=which(M2Seuil_RecupManu$FILINO=="SUPP")
      if (length(niciSUPP)>0){M2Seuil_RecupManu=M2Seuil_RecupManu[-niciSUPP,]}
      if (verif==1)
      {
        st_write(M2Seuil_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2Seuil_RecupManu","_APRES_COUPE_MSUPP_SUPP",".gpkg")), delete_layer=T, quiet=T)
      }
      cat("Fin des SUPP\n")
    }
    
    ####################################################################################################
    ###### Affectation Manuelle de nouveaux types
    iAutre=which(Manuel$FILINO=="COUPE" | Manuel$FILINO=="MSUPP" | Manuel$FILINO=="SUPP")
    if (length(iAutre)<dim(Manuel)[1])
    {
      if (length(iAutre)>0){Manuel_Affec=Manuel[-iAutre,]}else{Manuel_Affec=Manuel}
      st_write(Manuel_Affec,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Manuel_Affecquicroise",".gpkg")), delete_layer=T, quiet=T)
      cat("---------------------------------------------------------------\n")
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S"),"Intersection parfois longue pour affecter les nouveaux types - Début","\n")
      nbMC=st_intersects(M2Seuil_RecupManu,st_geometry(Manuel_Affec))
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S"),"Intersection parfois longue pour affecter les nouveaux types - Fin","\n")
      n_intMC = which(sapply(nbMC, length)>0)
      M2SeuilFini_SansRegroupement=NaN
      M2Seuil_BesoinRegroupement=NaN
      # Si aucun croisement on garde tout
      if (length(n_intMC)==0)
      {
        M2SeuilFini_SansRegroupement=M2Seuil_RecupManu
      }
      # Si croisement, on garde ceux qui ne croisent pas
      # et on mets ceux qui croisent avec les masques initiaux
      
      if (length(n_intMC)>0)
      {
        M2SeuilFini_SansRegroupement=M2Seuil_RecupManu[-n_intMC,]
        if (dim(M2SeuilFini_SansRegroupement)[1]==0)
        {
          M2SeuilFini_SansRegroupement=NaN
        }
        
        M2Seuil_BesoinRegroupement=M2Seuil_RecupManu[n_intMC,]
      }
      
      
      if (is.na(M2SeuilFini_SansRegroupement)[1]==F)
      {
        if (nrow(M2SeuilFini_SansRegroupement)>0)
        {
          if (verif==1)
          {
            st_write(M2SeuilFini_SansRegroupement,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2SeuilFini_SansRegroupement",".gpkg")), delete_layer=T, quiet=T)
          }     
          st_geometry(M2SeuilFini_SansRegroupement)="geometry"
          M2Seuil=rbind(M2Seuil,M2SeuilFini_SansRegroupement)
        }
      }
      
      if (verif==1)
      {
        st_write(M2Seuil,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2Seuil",".gpkg")), delete_layer=T, quiet=T)
      }
      
      # il faudrait aussi enlever les supp et msupp de m2direct
      #supprimer avant intersection les supp et msupp
      iAutreSupp=which(Manuel$FILINO=="MSUPP" | Manuel$FILINO=="SUPP")
      if (length(iAutreSupp)>0)
      {
        M2_SUPP_COUPE=st_intersects(M2_RecupManu,st_geometry(Manuel[iAutreSupp,]))
        nM2_SUPP_COUPE=which(sapply(M2_SUPP_COUPE, length)>0)
        if (length(nM2_SUPP_COUPE)>0)
        {
          M2_RecupManu=M2_RecupManu[-nM2_SUPP_COUPE,]
        }
      }
      
      # Suppression des Masques2 originaux qui touchent les automatiques sans problème...
      cat("---------------------------------------------------------------\n")
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S"),"Intersection parfois longue pour supprimer les masques 2 initiaux qui touchent les masques 2 seuil - Début","\n")
      cat("Appeler FP au besoin\n")
      nbenleveM2=st_intersects(M2_RecupManu,M2Seuil)
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S"),"Intersection parfois longue pour supprimer les masques 2 initiaux qui touchent les masques 2 seuil - Fin","\n")
      
      n_intenleveM2 = which(sapply(nbenleveM2, length)>0)
      if (length(n_intenleveM2)>0)
      {
        if (verif==1)
        {
          st_write(M2_RecupManu[n_intenleveM2,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_RecupManu_lesmorceauxenlever",".gpkg")), delete_layer=T, quiet=T)
          st_write(M2_RecupManu[-n_intenleveM2,],file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_RecupManu_a_ajouter_pour_chgt_type",".gpkg")), delete_layer=T, quiet=T)
        }
        M2_RecupManu=M2_RecupManu[-n_intenleveM2,]
      }
      
      if (dim(M2_RecupManu)[1]==0)
      {
        M2_et_M2Seuil_RecupManu=M2Seuil_RecupManu[,colnames(M2_RecupManu)]
      }else{
        M2_et_M2Seuil_RecupManu=rbind(M2_RecupManu,M2Seuil_RecupManu[,colnames(M2_RecupManu)])
      }
      if (verif==1)
      {
        st_write(M2_et_M2Seuil_RecupManu,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_et_M2Seuil_RecupManu",".gpkg")), delete_layer=T, quiet=T)
      }
      
      # Vérification qu'il n'y ait pas un objet de masques 2 touchés par plusieurs zones utilisateur
      nbMC=st_intersects(M2_et_M2Seuil_RecupManu,st_geometry(Manuel_Affec))
      n_intMC = which(sapply(nbMC, length)>1) # attention >1 pour en avoir 2
      if (length(n_intMC)>0)
      {
        Masques2troptouche=M2_et_M2Seuil_RecupManu[n_intMC,1]
        plot(Masques2troptouche)
        st_write(Masques2troptouche,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2toucheBCPdeManuel",".gpkg")), delete_layer=T, quiet=T)
        
        # test d'eclatement des masques 2 MULTIPOLYGON touchés plusieurs fois en POLYGON pour voir si le problème persiste
        
        Masques2troptouche=st_cast(Masques2troptouche,"POLYGON")
        nbMC_=st_intersects(Masques2troptouche,st_geometry(Manuel_Affec))
        n_intMC_ = which(sapply(nbMC_, length)>1) # attention >1 pour en avoir 2
        if (length(n_intMC_)>0)
        {
          nbMC=st_intersects(Manuel_Affec,Masques2troptouche)
          n_intMC = which(sapply(nbMC, length)>0)
          ManuelMauvais=Manuel_Affec[n_intMC,]
          
          plot(ManuelMauvais[,1])
          st_write(ManuelMauvais,file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltoucheTROPMasques2",".gpkg")), delete_layer=T, quiet=T)
          
          cat("les masques de ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_et_M2Seuil_RecupManu","Coupe",".gpkg"))," \n")
          cat("touchent plusieurs de vos zones ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("ManueltouchetropMasques2",".gpkg"))," \n")
          BOOM=BOOOM
        }else{
          M2_et_M2Seuil_RecupManu=rbind(M2_et_M2Seuil_RecupManu[-n_intMC,1],Masques2troptouche)
        }
      }
    }
    
    #########################################################################
    ############## Affectation des nouveaux types pour Masques ? ######
    #########################################################################
    cat("---------------------------------------------------------------\n")
    cat("Affectation des nouveaux types","\n")
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
          nbMC=st_intersects(M2_et_M2Seuil_RecupManu,st_geometry(Manuel[im,]))
          n_intMC = which(sapply(nbMC, length)>0)
          if (length(n_intMC)>0)
          {
            
            incAj=incAj+1
            # On va fusionner tous les petits masques et leur mettre les bons attributs
            MasqueIm=st_sf(data.frame(
              cat="0",
              Aire="-99",
              Id=dim(M2Seuil)[1]+incAj,
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
              geometry=st_union(M2_et_M2Seuil_RecupManu[n_intMC,]))
            
            # Si c'est du multiplan, on éclate
            if (imotcle=="MPl")
            {
              MasqueIm$FILINO="PlanM"
              MasqueIm=st_cast(MasqueIm,"POLYGON")
            }
            
            #GRAVE OU PAS
            M2Seuil=rbind(M2Seuil,MasqueIm)
          }
        }
      } 
      
    }
    # browser()
    
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
            Id=dim(M2Seuil)[1]+incAj,
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
          # print(M2Seuil)
          # plot(MasqueIm[,1])
          M2Seuil=rbind(M2Seuil,MasqueIm)
          
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
Masques2=M2Seuil
# Calcul de l'aire
Masques2$Aire=round(st_area(Masques2),0)
# Renumérotation
Masques2=Masques2[order(Masques2$Aire,decreasing = T),]
##### Codification
Masques2$Id=FILINO_NomMasque(Masques2)
Masques2$IdGlobal=Masques2$Id

# Export du nouveau fichier

if (exists("QueHydrometrie")==T)
{
  if (QueHydrometrie==1)
  {
    nici=which(substr(Masques2$FILINO,1,3)=="Eco")
    if (length(nici)>0)
    {
      Masques2=Masques2[nici,]
    }
  }
}

nomMasques2_FILINO=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_FILINO",".gpkg"))
st_write(Masques2,nomMasques2_FILINO, delete_layer=T, quiet=T)

###########################################################################
###### Appareillage des Masques 1 sur les Masques 2 FILINO
#######################################################################
cat("-----------------------------------------------------\n")
cat("-----------------------------------------------------\n")
cat("Appareillage des Masques 1 sur les Masques 2 FILINO","\n")

# On ne travaille que sur les nouveaux masques
ici=grep(Masques2$FILINO,pattern="Vieux")
if (length(ici)>0){Masques2=Masques2[-ici,]}
print(unique(Masques2$FILINO))

# 20290926
# Recup masque 1 qui croisent les masques 2 mer
# si il y en a
# recup table assemblage
nbMer=which(substr(Masques2$FILINO,1,3)=="Mer")
if (length(nbMer)>0)
{
  nb=st_intersects(TA,Masques2[nbMer,])
  n_int <-  which(sapply(nb, length) > 0)
  TA_Mer=TA[n_int,]
  TA_UnionLig=st_cast(TA_Mer,"MULTILINESTRING")
  TA_UnionBuf=st_union(st_buffer(TA_UnionLig,0.2))
  nomTA_UnionBuf  =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"TA_UnionBuf.gpkg")
  st_write(TA_UnionBuf,nomTA_UnionBuf,delete_layer=T, quiet=T)
  
  CoupeMasque1=st_union(st_intersection(TA_UnionBuf,Masques2[nbMer,]))
  nomdecoupe  =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"DecoupeMer_Masques1.gpkg")
  st_write(CoupeMasque1,nomdecoupe,delete_layer=T, quiet=T)
  
  nomdecoupeok=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1_Biendecouperenmer.gpkg")
  nomadecouper=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1_adecouperenmer.gpkg")
  st_write(Masques1,nomadecouper,delete_layer=T, quiet=T)
  
  
  cmd <- paste0(qgis_process, " run native:difference",
                " --INPUT=",nomadecouper,
                " --OVERLAY=",nomdecoupe,
                " --OUTPUT=",nomdecoupeok,
                " --GRID_SIZE=None")
  print(cmd);system(cmd)
  
  Masques1=st_read(nomdecoupeok)
  Masques1=st_cast(Masques1,"POLYGON")
}
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

if (dimMasq1!=dim(Masques1L)[1])
{
  doublons <- which(duplicated(Masques1L$Id))
  print(doublons)
  # plot(Masques1L[doublons,1])
  # Export du nouveau fichier
  nomMasques1_Bug=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques1_Doublons_BUG",".gpkg"))
  st_write(Masques1L[doublons,1],nomMasques1_Bug, delete_layer=T, quiet=T)
  cat("Voir le fichier: ",nomMasques1_Bug,"\n")
  BADABOUM=IL_Y_A_UN_PROBLEME_DE_COHERENCE_ENTRE_LE_MASQUES2_ET_1_PASLEEMENOMBREDOBKET_BUG
}

# Recherche des masques 1 non traités
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
    cat("\n Masque1 n°",i_Interi, " est à l'intérieur du/des \n")
    # plot(Masques1L[nM1b[i_Inter],1])
    # Boucle sur les divers morceaux de masques 2
    # for (i_InterM2 in n_Inter[[i_Inter]])
    cat(" Masque2")
    for (i_InterM2i in liaison[which(liaison$Id==i_Interi),]$IdGlobal)
    {
      cat(" n°",i_InterM2i)
      i_InterM2=which(Masques2$IdGlobal==i_InterM2i)
      Coupons=st_intersection(st_segmentize(Masques1L[i_Inter,1],1.01*reso),Masques2[i_InterM2,"Id"])
      
      types_geometrie <- st_geometry_type(Coupons)
      Coupons=Coupons[which(types_geometrie=="MULTILINESTRING" | types_geometrie=="LINESTRING"),]
      
      if (nrow(Coupons)>0)
      {
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
        Masques1L=rbind(Masques1L[,colnames(Coupons)],Coupons)
      }
      cat("\n")
    }
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
  
  # Lecture de la table d'assemblage
  TA=st_read(file.path(dsnlayerTA,nomlayerTA))
  nb=st_intersects(TA,trhydro)
  n_int = which(sapply(nb, length)>0)
  TA_=TA[n_int,]
  
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
  
  #Hydrométrie
  if (exists("QueHydrometrie")==T)
  {
    if (QueHydrometrie==1)
    {
      StHydro=st_read(NomStHydro)
    }
  }
  
  
  
  for (imasq in unique(liaison2$IdGlobal))
  {
    setTxtProgressBar(pgb, Iav)
    Iav=Iav+1
    ntr=unique(liaison2[which(liaison2$IdGlobal==imasq),]$cleabs)
    
    if (length(ntr)>0)
    {
      Masq_tmp=Masques2[which(Masques2$IdGlobal==imasq),]
      Bbox_SurfEau=st_bbox(Masq_tmp)
      
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
        
        nbtm=st_intersects(trhydro_2, st_buffer(st_as_sfc(Bbox_SurfEau),500))
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
      
      # travail pour savoir si les surfaces en eau seront mis dans des dossiers
      # - par dalles si le masques est inclus dans une dalle
      # - par noms de surfaces en eau si le masquedépasse une dalle
      
      TA_tmp=TApourFunc_RepSurfCoursEau(TA_,Masq_tmp)
      cat("\n")
      rep_SURFEAU=Func_RepSurfCoursEau(st_bbox(Masq_tmp),TA_tmp$NOM,dsnlayer,NomDirSurfEAU,racilayerTA,raciSurfEau)
      # if (length(rep_SURFEAU)>1){browser()}
      raciMasq=paste0(raciSurfEau,Masq_tmp$IdGlobal)
      rep_SURFEAU=file.path(rep_SURFEAU,raciMasq)
      
      for (irep_SURFEAU in rep_SURFEAU)
      {
        FILINO_Creat_Dir(irep_SURFEAU)
        st_write(trhydro_surf,file.path(irep_SURFEAU,"trhydro.gpkg"), delete_layer=T, quiet=T)
        
        if (exists("QueHydrometrie")==T)
        {
          if (QueHydrometrie==1)
          {
            dMasqbuffer=50
            distStH=st_distance(StHydro,Masq_tmp)
            units(distStH)=NULL
            n_inth <-  which(distStH<dMasqbuffer)
            if (length(n_inth)>0)
            {
              StHydro_ <- StHydro[n_inth,]
              st_write(StHydro_,file.path(irep_SURFEAU,"StHydro.gpkg"), delete_layer=T, quiet=T)
            }
          }
        }
      }
    }
  }
  setTxtProgressBar(pgb, Compl)
}
cat("\n",format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin\n")

# unlink(nom_Manuel_tmp)
unlink(nom_Manuel2)
unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("M2_RecupManu","Coupe",".gpkg")))
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

cat("\n")
cat("\n")
cat("########################################################################################################\n")
cat("######################### FILINO A LIRE SVP ###############################################################\n")
cat("---------------- ETAPE FILINO_04_01b_MasqueEau.R #######################################\n")
cat("\n")
cat("\ Ouvrir :  ",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques.qgz"),"    \n")
cat("\n")
cat("\ Plus de couches peuvent s'ouvrir mais pas toutes comme 'point virtuel'...\n")
cat("\ Adaptez certains chemin si vous avez changé le nom de Zone_A_Traiter...\n")
cat("\n")
cat("\ Vous pouvez enregistrer le fichier Masques.qgz avec vos préférences de couleurs...  ...\n")
cat("\ et le remettre dans le dossier ",file.path(dsnlayer,NomDirSIGBase)," ...\n")
cat("\n")
cat("\ Fermer le projet Qgis avant de lancer la suite! ...\n")
cat("\n")
cat("######################### Fin FILINO A LIRE ###############################################################\n")
cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
cat("\n")