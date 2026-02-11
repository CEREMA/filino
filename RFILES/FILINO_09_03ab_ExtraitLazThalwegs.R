library(dplyr)
library(jpeg)

chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
# Initialisation des chemins et variables
source(file.path(chem_routine,"FILINO_0_Initialisation.R"))

if (exists("Etap3")==F){Etap3=c(1,1)}

# Contour des Départements
Departement=st_read(file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT.shp"))

# Boucle sur les différentes tables d'assemblage
for (iTA in 1:length(dsnTALidar))
{
  # Recuperation des parametres de chaque table d'assemblage
  dsnlayerTA=dsnTALidar[iTA]
  nomlayerTA=nomTALidar[iTA]
  # reso=as.numeric(resoTALidar[iTA])
  # paramXYTA=as.numeric(paraXYLidar[iTA,])
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  
  # Lecture de la table d'assemblage
  TA=st_read(file.path(dsnlayerTA,nomlayerTA))
  
  # Limitation de la table d'assemblage aux zones à traiter
  nb=st_intersects(TA,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TA=TA[n_int,]
    
    cat("##################################################################\n")
    cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
    cat("##################################################################\n")
    
    MasquesBuf=st_read(file.path(dsnlayer,NomDirMasqueVIDE,paste0("Masques1_",racilayerTA,".gpkg")))
    
    # Intersection des départements
    nb=st_intersects(Departement,TA)
    
    n_int = which(sapply(nb, length)>0)
    
    if (Etap3[1]==1)
    {
      
      Dpt=Departement[n_int,]
      # Boucle sur les départements qui intersectent la donnée
      for (iDpt in 1:dim(Dpt)[1])
      {
        # ouverture de la BDTopo
        listeDpt=list.files(dsnDepartement,pattern=paste0("_D",ifelse(nchar(Dpt$INSEE_DEP[iDpt])==2,paste0("0",Dpt$INSEE_DEP[iDpt]),Dpt$INSEE_DEP[1]),"-"),recursive=T)
        listeDpt=file.path(dsnDepartement,listeDpt[grep(listeDpt,pattern=".gpkg")])
        
        dsnlayerCE=dirname(listeDpt)
        nomgpkgCE=basename(listeDpt)
        ######################################################################################
        ##### Lecture des troncon_de_route
        nomlayer="troncon_hydrographique"
        
        trhydro=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer)
        cat(dim(trhydro),"\n")
        # Ne choisir que le terme écoulements dans le champ NATURE
        trhydro=trhydro[grep(trhydro$nature,pattern="Ecoulement"),]
        cat(dim(trhydro),"\n")
        # travauiler avec position par rapport au sol 0, on ne travaille pas sur enterreé ou aérien
        trhydro=trhydro[grep(trhydro$position_par_rapport_au_sol,pattern="0"),]
        cat(dim(trhydro),"\n")
        # classe de largeur et précision plani pour le buffer
        print(unique(trhydro$classe_de_largeur))
        # On chositi la classe de largeur, les rivières étroites (grosses gerées en amsque mais à vérifier plus tard)
        # [1] "Entre 0 et 5 m" "Entre 5 et 15 m" "Entre 15 et 50 m" "En attente de mise à jour" "Plus de 50 m" "Sans objet"  [7] NA  
        
        # IMPORTANT avoir comment gérer
        # trhydro=rbind(trhydro[grep(trhydro$classe_de_largeur,pattern="Entre 0 et 5 m"),],
        #               trhydro[grep(trhydro$classe_de_largeur,pattern="Entre 5 et 15 m"),])
        
        trhydro=rbind(trhydro[grep(trhydro$classe_de_largeur,pattern="Entre 0 et 5 m"),],
                      trhydro[grep(trhydro$classe_de_largeur,pattern="Entre 5 et 15 m"),],
                      trhydro[grep(trhydro$classe_de_largeur,pattern="Entre 15 et 50 m"),])
        print(unique(trhydro$classe_de_largeur))
        cat(dim(trhydro),"\n")
        # travail que sur les tronons de cours d'eau
        trhydro$liens_vers_cours_d_eau
        # Ne chosiir que les écoulements
        trhydro=trhydro[grep(trhydro$liens_vers_cours_d_eau,pattern="COURDEAU"),]
        cat(dim(trhydro),"\n")
        
        # Intersection des 
        nb=st_intersects(TA,trhydro)
        
        st_write(trhydro,
                 file.path(dsnlayer,"trhydro.gpkg"), delete_layer=T, quiet=T)
        
        n_int2 = sort(which(sapply(nb, length)>0))
        
        for (iLAZ in n_int2)#dim(TA)[1])
        {
          TA_tmp=TA[iLAZ,]
          if (is.null(TA_tmp$CHEMIN))
          {
            # Lidar Hd brut
            NomLaz=basename(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
            ChemLaz=dirname(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
          }else{
            # Lidar HD classif
            NomLaz=TA_tmp$NOM
            ChemLaz=TA_tmp$CHEMIN
          }
          
          cat("###############################################################\n")
          cat("Passage R",iLAZ,"sur", dim(TA)[1],"\n")
          cat("#######################",TA_tmp$NOM,"\n")
          nb=st_intersects(trhydro,TA_tmp)
          n_int = which(sapply(nb, length)>0)
          
          if (length(n_int)>0)
          {   
            print(n_int)
            for (i_trhydro in n_int)
            {
              
              # Croisement des masques avec la table d'assemblage
              # Selection des sections dans le Lidar
              trhydro_tmp=trhydro[i_trhydro,]
              if (nchar(trhydro_tmp$liens_vers_cours_d_eau)>nchar(basename(trhydro_tmp$liens_vers_cours_d_eau)))
              {
                trhydro_tmp$liens_vers_cours_d_eau=basename(trhydro_tmp$liens_vers_cours_d_eau)
                # jenecomprendpastoutilfautmettrelebonnomcourseau
              }
              
              rep_COURSEAU=file.path(dsnlayer,NomDirCoursEAU,basename(trhydro_tmp$liens_vers_cours_d_eau))
              FILINO_Creat_Dir(rep_COURSEAU)      
              nomhydro=file.path(rep_COURSEAU,paste0(trhydro_tmp$cleabs,"_hydro.gpkg"))
              # unlink(nomtampon)
              st_write(trhydro_tmp,nomhydro, delete_layer=T, quiet=T)
              
              raci=paste0(basename(trhydro_tmp$liens_vers_cours_d_eau),"_",trhydro_tmp$cleabs,"_",substr(NomLaz,1,nchar(NomLaz)-4))
              
              # BufIncertitude=1.5
              if (trhydro_tmp$classe_de_largeur=="Entre 0 et 5 m"){largCE=10}
              if (trhydro_tmp$classe_de_largeur=="Entre 5 et 15 m"){largCE=20}      
              if (trhydro_tmp$classe_de_largeur=="Entre 15 et 50 m"){largCE=60}  
              largbuffer=trhydro_tmp$precision_planimetrique+largCE
              
              # Creation d'un répertoire
              
              tampon=st_buffer(trhydro_tmp,largbuffer,endCapStyle="FLAT")
              nomtampon=file.path(rep_COURSEAU,paste0(trhydro_tmp$cleabs,"_tampon.gpkg"))
              # unlink(nomtampon)
              st_write(tampon,nomtampon, delete_layer=T, quiet=T)
              
              Polygon_Contour_CE=st_as_text(st_geometry(tampon))
              
              setwd(ChemLaz)
              nomjson=paste0(raci,"_MyScript.json")
              NomLaz_tmp=paste0(raci,"_",
                                racilayerTA,
                                ".copc.laz")
              cat("###############################################################\n")
              print(NomLaz_tmp)
              write("[",nomjson)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz),","),nomjson,append=T)
              write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
              write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
              write(paste0("       ",shQuote("limits"),":",shQuote("Classification[1:2],Classification[6:6],Classification[9:9],Classification[17:17]")),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
              write(paste0("       ",shQuote("polygon"),":",shQuote(Polygon_Contour_CE)),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(file.path(rep_COURSEAU,NomLaz_tmp)),","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
              write("    }",nomjson,append=T)
              write("]",nomjson,append=T)
              
              cmd=paste(pdal_exe,"pipeline",nomjson)
              system(cmd)
              
              if (Nettoyage==1){Sys.sleep(0.1);unlink(nomjson)}
            }
          }
        }
      }
    }
    if (Etap3[2]==1)
    {
      listeLAZCoursEau=list.files(file.path(dsnlayer,NomDirCoursEAU),pattern="laz",recursive=TRUE)
      opt_grep=grep(listeLAZCoursEau,pattern="copc")
      if (length(opt_grep)>1){listeLAZCoursEau=listeLAZCoursEau[-opt_grep]}
      opt_grep=grep(basename(listeLAZCoursEau),pattern="COURDEAU")
      listeLAZCoursEau=listeLAZCoursEau[opt_grep]
      NOMLAZCoursEau=basename(listeLAZCoursEau)
      for (i_CoursEau in sort(unique(substr(NOMLAZCoursEau,1,24))))
        # for (i_CoursEau in c("COURDEAU0000002000888894"))
        # for (i_CoursEau in c("COURDEAU0000002000804233"))
        # for (i_CoursEau in c("COURDEAU0000002000804226"))
      {
        setwd(dsnlayer)
        
        # Creation d'un répertoire
        rep_COURSEAU=file.path(NomDirCoursEAU,i_CoursEau)
        FILINO_Creat_Dir(file.path(dsnlayer,rep_COURSEAU))
        setwd(file.path(dsnlayer,rep_COURSEAU))
        
        # NomLaz_tmp=file.path(rep_COURSEAU,paste0(i_CoursEau,"_",racilayerTA,".laz"))
        # NomLaz_tmp=file.path(rep_COURSEAU,paste0(raciPCoursEau,"_",racilayerTA,".laz"))
        NomLaz_tmp=paste0(raciPCoursEau,"_",racilayerTA,".copc.laz")
        cat("###############################################################\n")
        print(NomLaz_tmp)
        
        # Cours Eau ligne
        # a modifier fusionner dans kle répertoire
        Nomhydro=list.files(pattern="_hydro.gpkg")
        ListHydro=lapply(Nomhydro, function(x) {st_read(x)})
        Tronhydro=do.call(rbind, ListHydro)
        
        Tronhydro=Tronhydro %>%
          group_by(liens_vers_cours_d_eau ) %>%
          summarize()
        
        if (as.character(st_geometry_type(Tronhydro))=="MULTILINESTRING"){Tronhydro=st_line_merge(Tronhydro)}
        Tronhydro=st_cast(Tronhydro,"LINESTRING")
        
        
        st_write(Tronhydro,
                 file.path(dsnlayer,rep_COURSEAU,paste0("Tron_hydro","_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)
        # Buffer
        Nomtampon=list.files(pattern="_tampon.gpkg")
        Listtampon=lapply(Nomtampon, function(x) {st_read(x)})
        Trontampon= do.call(rbind, Listtampon)
        
        Trontampon=Trontampon %>%
          group_by(liens_vers_cours_d_eau ) %>%
          summarize()
        
        st_write(Trontampon,
                 file.path(dsnlayer,rep_COURSEAU,paste0("Tron_tampon","_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)
        
        # voir si on fusionne
        #Recupération des zones sans retour
        nb=st_intersects(MasquesBuf,Trontampon)
        n_int = which(sapply(nb, length)>0)
        if (length(n_int>0)){st_write(MasquesBuf[n_int,],
                                      file.path(dsnlayer,rep_COURSEAU,paste0("ZonesBlanches","_",racilayerTA,".gpkg")), delete_layer=T, quiet=T)}
        
        nCoursEau=grep(NOMLAZCoursEau,pattern=i_CoursEau)
        nCoursEau=nCoursEau[grep(NOMLAZCoursEau[nCoursEau],pattern=paste0(racilayerTA,".laz"))]
        # if (length(nCoursEau)>0)
        # {
        #   if (length(nCoursEau)==1)
        #     # il n'y a qu'un fichier
        #   {
        #     cat("Un seul",NOMLAZCoursEau[nCoursEau],"\n")
        #     file.copy(listeLAZCoursEau[nCoursEau],NomLaz_tmp)
        #   }else{
        #     # il faut fusionner plusieurs fichiers
        #     cat("Plusieurs",NOMLAZCoursEau[nCoursEau],"\n")
        nomjson=paste0(i_CoursEau,"_MyScript.json")
        write("[",nomjson)
        #OLD
        for (iNOMLAZCoursEau in nCoursEau)
        {
          write(paste0("       ",shQuote(basename(listeLAZCoursEau[iNOMLAZCoursEau])),","),nomjson,append=T)
        }
        # #NEW
        # write("    {",nomjson,append=T)
        # write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
        # for (iNOMLAZCoursEau in nCoursEau)
        # {
        #   write(paste0("       ",shQuote(basename(listeLAZCoursEau[iNOMLAZCoursEau])),","),nomjson,append=T)
        # }
        # write("    },",nomjson,append=T)
        
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp)),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.text"),","),nomjson,append=T)
        write(paste0("       ",shQuote("format"),":",shQuote("csv"),","),nomjson,append=T)
        write(paste0("       ",shQuote("order"),":",shQuote("X,Y,Z,Classification"),","),nomjson,append=T)
        write(paste0("       ",shQuote("keep_unspecified"),":",shQuote("false"),","),nomjson,append=T)
        nomcsv=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-3),"csv")
        write(paste0("       ",shQuote("filename"),":",shQuote(nomcsv)),nomjson,append=T)
        write("    }",nomjson,append=T)
        write("]",nomjson,append=T)
        cmd=paste(pdal_exe,"pipeline",nomjson)
        system(cmd)
        if (Nettoyage==1){Sys.sleep(0.1);unlink(nomjson)}
        # }
        
        file.copy(file.path(dsnlayer,NomDirSIGBase,"ProjetQgis_CoursEau.qgz"),
                  file.path(dsnlayer,rep_COURSEAU,"ProjetQgis_CoursEau.qgz"),
                  overwrite = T)
        
        # Calcul de st_distance à faire
        if (file.exists(nomcsv)==T)
        {
          PtsCSV=read.csv(nomcsv)
          if (dim(PtsCSV)[1]!=0)
          {
            # envoi vers la fonction où on travaille le fond en R
            source(paste(chem_routine,"\\FILINO_3c_ExtraitLazThalwegs_TravailFondLit.R", sep = ""),encoding = "utf-8")
          }
        }
      }
    }
  }
}
# }
#
