# Initialisation des chemins et variables
chem_routine = R.home(component = "cerema")
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))

if (exists("Etap2")==F){Etap2=c(1,1,1)}

# #Département Mer, pour tester si on est en mer ou à terre
# Dpt_Inv_Mer=st_read(file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT_Buf_pour_mer.shp"))

# Boucle sur les différentes tables d'assemblage
for (iTA in 1:length(dsnTALidar))
{
  # Recuperation des parametres de chaque table d'assemblage
  dsnlayerTA=dsnTALidar[iTA]
  nomlayerTA=nomTALidar[iTA]
  reso=as.numeric(resoTALidar[iTA])
  # paramXYTA=as.numeric(paraXYLidar[iTA,])
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  
  # Lecture de la table d'assemblage
  TA=st_read(file.path(dsnlayerTA,nomlayerTA))
  
  # Limitation de la table d'assemblage aux zones à traiter
  nb=st_intersects(TA,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    cat("##################################################################\n")
    cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
    cat("##################################################################\n")
    TA=TA[n_int,]
    
    # Masques2=st_read(file.path(dsnlayer,NomDirMasque,paste0("Masques2_Seuil",seuilSup1,"m2_",racilayerTA,".gpkg")))
    # On ne prend pas le masque de chaque TA car les objets 'auront pas la même numérotation
    # travail à faire pour mieux gérer cette problématique
    # Masques2=st_read(file.path(dsnlayer,NomDirMasque,paste0("Masques2_Seuil",seuilSup1,"m2_",racilayerTA,".gpkg")))
    Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg")))
    
    NbCharIdGlobal=nchar(Masques2$IdGlobal[1])
    
    nvieux=grep(Masques2$FILINO,pattern="Vieux")
    if (length(nvieux)>0) {Masques2=Masques2[-nvieux,]}
    
    # Masques1=st_read(file.path(dsnlayer,NomDirMasque,paste0("Masques1_FILINO","_",racilayerTA,".gpkg")))
    Masques1=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,"Masques1_FILINO.gpkg"))
    
    nb=st_intersects(TA,Masques2)
    n_int = which(sapply(nb, length)>0)
    TA=TA[n_int,]
    
    if (Etap2[1]==1)
    {
      for (iLAZ in 1:dim(TA)[1])
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
        nb=st_intersects(Masques2,TA_tmp)
        n_int = which(sapply(nb, length)>0)
        
        if (length(n_int)>0)
        {   
          print(n_int)
          # st_write(Masques2[n_int,],file.path(dsnlayer,"fred.shp"), delete_layer=T, quiet=T)
          
          for (iMasq in n_int)
          {
            # Croisement des masques avec la table d'assemblage
            # Selection des sections dans le Lidar
            Masq_tmp=Masques2[iMasq,]
            
            # raciMasq=paste0(raciSurfEau,formatC(Masq_tmp$IdGlobal,width=5, flag="0"),"_",racilayerTA)
            raciMasq=paste0(raciSurfEau,Masq_tmp$IdGlobal)
            raci=paste0(raciMasq,"_",substr(NomLaz,1,nchar(NomLaz)-4))
            
            setwd(ChemLaz)
            nomjson=paste0(raci,"_MyScript.json")
            NomLaz_tmp=ifelse(substr(raci,nchar(raci)-4,nchar(raci))==".copc",
                              paste0(substr(raci,1,nchar(raci)-5),".laz"),
                              paste0(raci,".laz"))
            
            # nouveau 07/02/2023
            # rep_COURSEAU=file.path(dsnlayer,NomDirSurfEAU,paste0(racilayerTA,raciSurfEau,formatC(Masq_tmp$IdGlobal,width=5, flag="0")))
            rep_COURSEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,Masq_tmp$IdGlobal))
            if (file.exists(rep_COURSEAU)==F){dir.create(rep_COURSEAU)}
            rep_COURSEAU=file.path(rep_COURSEAU,"Dalles")
            if (file.exists(rep_COURSEAU)==F){dir.create(rep_COURSEAU)}
            NomLaz_tmp=file.path(rep_COURSEAU,NomLaz_tmp)
            if (file.exists(NomLaz_tmp)==F)
            {
              # Creation d'un pipeline pdal pour extraire les points autour du masque
              cat("###############################################################\n")
              print(NomLaz_tmp)
              write("[",nomjson)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz),","),nomjson,append=T)
              write(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","),nomjson,append=T)
              write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
              write(paste0("       ",shQuote("limits"),":",shQuote("Classification[1:2],Classification[9:9]")),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
              write(paste0("       ",shQuote("polygon"),":",shQuote(st_as_text(st_geometry(Masq_tmp)))),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("writers.las"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
              write("    }",nomjson,append=T)
              write("]",nomjson,append=T)
              
              cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
              system(cmd)
              if (Nettoyage==1){unlink(nomjson)}
              
            }else{
              cat("Déjà présent: ",NomLaz_tmp,"\n")
            }
            
          }
        }
      }
    }
    if (Etap2[2]==1 | Etap2[3]==1)
    {
      # Fusion des divers points récupérés par table d'assemblage sur chaque masque
      # listeLAZMasq=list.files(file.path(dsnlayer,NomDirSurfEAU),pattern="laz",recursive=TRUE)
      listeLAZMasq=list.files(file.path(dsnlayer,NomDirSurfEAU,racilayerTA),pattern="laz",recursive=TRUE)
      
      opt_grep=grep(racilayerTA,pattern="copc")
      if (length(opt_grep)>0)
      {
        opt_grep=grep(listeLAZMasq,pattern="copc")
        if (length(opt_grep)>1){listeLAZMasq=listeLAZMasq[-opt_grep]}
      }
      
      opt_grep=grep(basename(listeLAZMasq),pattern=raciSurfEau)
      listeLAZMasq=listeLAZMasq[opt_grep]
      # opt_grep=grep(basename(listeLAZMasq),pattern=racilayerTA)
      # listeLAZMasq=listeLAZMasq[opt_grep]
      
      opt_grep=grep(listeLAZMasq,pattern=paste0(raciSurfEau,".laz"))
      if (length(opt_grep)>0){listeLAZMasq=listeLAZMasq[-opt_grep]}
      opt_grep=grep(listeLAZMasq,pattern=paste0(raciSurfEau,".copc.laz"))
      if (length(opt_grep)>0){listeLAZMasq=listeLAZMasq[-opt_grep]}
      
      NOMLAZMasq=basename(listeLAZMasq)
      ListeRaciLAZ=sort(unique(substr(NOMLAZMasq,1,nchar(raciSurfEau)+NbCharIdGlobal)),decreasing=TRUE)
      
      # Travail que sur les fichiers par dalle, on enleve les fichiers regroupés
      nepasgarder=grep(ListeRaciLAZ,pattern="TA")
      if (length(nepasgarder)>0){ListeRaciLAZ=ListeRaciLAZ[-nepasgarder]}
      
      nepasgarder=grep(ListeRaciLAZ,pattern="_PtsVirt.laz")
      if (length(nepasgarder)>0){ListeRaciLAZ=ListeRaciLAZ[-nepasgarder]}
      
      for (iMasq in ListeRaciLAZ)
      {
        setwd(file.path(dsnlayer,NomDirSurfEAU,racilayerTA))
        
        NomLaz_tmp=paste0(raciSurfEau,".laz")
        
        cat("###############################################################\n")
        cat(iMasq,NomLaz_tmp,"\n")
        
        rep_COURSEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,iMasq)
        if (file.exists(file.path(rep_COURSEAU,paste0(raciSurfEau,"_PtsVirt.laz")))==T)
        {
          cat(raciSurfEau," déjà traité","\n")
        }else{
          if (file.exists(rep_COURSEAU)==F){dir.create(rep_COURSEAU)}
          NomLaz_tmp=file.path(rep_COURSEAU,NomLaz_tmp)
          
          nmasq=grep(NOMLAZMasq,pattern=iMasq)
          
          # Creation d'un pipeline pdal pour fusionner les différents fichiers et exporter en csv pour un traitement R
          cat("Plusieurs",NOMLAZMasq[nmasq],"\n")
          nomjson=paste0(iMasq,"_MyScript.json")
          
          write("[",nomjson)
          for (iNOMLAZMasq in nmasq)
          {
            write(paste0("       ",shQuote(listeLAZMasq[iNOMLAZMasq]),","),nomjson,append=T)
          }
          if (length(nmasq)>1)
          {
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
            write("    },",nomjson,append=T)
          }
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("writers.las"),","),nomjson,append=T)
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
          cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
          
          if (Etap2[2]==1){system(cmd)}
          
          if (Nettoyage==1){unlink(nomjson)}
          
          # Recup du masque
          idglo=substr(iMasq,nchar(raciSurfEau)+1,nchar(raciSurfEau)+NbCharIdGlobal)

          st_write(Masques1[which(Masques1$IdGlobal==idglo),],
                   file.path(rep_COURSEAU,"Masque1.gpkg"), delete_layer=T, quiet=T)
          idglo=substr(iMasq,nchar(raciSurfEau)+1,nchar(raciSurfEau)+NbCharIdGlobal)

                    st_write(Masques2[which(Masques2$IdGlobal==idglo),],
                   file.path(rep_COURSEAU,"Masque2.gpkg"), delete_layer=T, quiet=T)
          # Copie d'un projet Qgis pour une visu rapide
          file.copy(file.path(dsnlayer,NomDirSIGBase,"ProjetQgis_SurfEau.qgz"),
                    file.path(rep_COURSEAU,"ProjetQgis_SurfEau.qgz"),
                    overwrite = T)
          
          if (file.exists(nomcsv)==T & Etap2[3]==1)
          {
            source(paste(chem_routine,"\\FILINO_2c_creatPtsVirtuels.R", sep = ""),encoding = "utf-8")
          }else{
            cat("Pas de csv ",nomcsv,"\n")
          }
        }
      }
    }
  }
}