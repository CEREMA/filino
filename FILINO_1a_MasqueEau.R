###################### PARAMETRES
chem_routine=R.home(component = "cerema")

# Initialisation des chemins et variables
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))

#Creation d'un monde GRASS
unlink(dirname(SecteurGRASS),recursive=TRUE)
system(paste0(BatGRASS," -c EPSG:2154 ",dirname(SecteurGRASS)," --text"))
system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))

# Boucle sur les différentes tables d'assemblage
for (iTA in 1:length(dsnTALidar))
{
  # Recuperation des parametres de chaque table d'assemblage
  dsnlayerTA=dsnTALidar[iTA]
  nomlayerTA=nomTALidar[iTA]
  reso=as.numeric(resoTALidar[iTA])
  
  # paramXYTA=as.numeric(ifelse(length(dsnTALidar)==1,paraXYLidar,))
  paramXYTA=paraXYLidar[iTA,]
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
    
    # Boucle sur les fichiers Laz
    for (iLAZ in 1:dim(TA)[1])
    {
      # Gestion des noms de champs de mes tables d'assemblage
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
      cat("TA",iTA,"/",length(dsnTALidar)," - Passage R",iLAZ,"sur", dim(TA)[1],"\n")
      cat(ChemLaz,"\n")
      cat(NomLaz,"\n")
      cat("###############################################################\n")
      ChemNomLaz=file.path(ChemLaz,NomLaz)
      
      NomLaz_tmp=NomLaz      
      if ((file.exists(file.path(dsnlayer,NomDirMasque,racilayerTA,paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque1.gpkg")))==T & 
           file.exists(file.path(dsnlayer,NomDirMasque,racilayerTA,paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque2.gpkg")))==T) |
          file.exists(file.path(dsnlayer,NomDirMasque,racilayerTA,paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque2.vide")))==T|
          file.exists(file.path(dsnlayer,NomDirMasque,racilayerTA,paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque2.eau")))==T)
      {
        cat("déjà fait ",
            file.path(dsnlayer,NomDirMasque,racilayerTA,paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque1.gpkg")),
            "\n")
      }else{
        # Recupération des limites
        decalgrille=reso
        Ouest=largdalle*as.numeric(substr(NomLaz,paramXYTA[2],paramXYTA[3]))
        Nord=largdalle*as.numeric(substr(NomLaz,paramXYTA[4],paramXYTA[5]))
        Est=as.character(Ouest+largdalle+decalgrille)
        Sud=as.character(Nord-largdalle-decalgrille)
        Ouest=as.character(Ouest-decalgrille)
        Nord=as.character(Nord+decalgrille)
        
        # Creation d'un pipeline pdal pour avoir les zones sans retour lidar en ecluant dès le début les zones en eau
        # zones en eau, si plusieurs vol, la zone en eau risque parfois d'inonder des points sol d'un autre vol
        # mais d'un autre coté la zone en eau peut être vu sous des arbres (jamais vu pour l'instant)
        nom_method="min"
        raci=paste0(substr(NomLaz,1,nchar(NomLaz)-4))
        nom_Rast=paste0(raci,"_","PourMasqueAJeter",".tif")
        setwd(ChemLaz)
        NomLaz_tmp=NomLaz
        
        nomjson=paste0(raci,"_MyScript.json")
        
        Pipeline=list()
        Pipeline[[1]]=paste0("[")
        Pipeline[[2]]=paste0("    {")
        Pipeline[[3]]=paste0(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","))
        Pipeline[[4]]=paste0(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","))
        Pipeline[[5]]=paste0(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","))
        Pipeline[[6]]=paste0(paste0("       ",shQuote("nosrs"),":",shQuote("true")))
        Pipeline[[7]]=paste0("    },")
        Pipeline[[8]]=paste0("    {")
        Pipeline[[9]]=paste0(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","))
        Pipeline[[10]]=paste0(paste0("       ",shQuote("limits"),":",shQuote(paste0("Classification[",ClassDeb,":6],Classification[17:17]"))))
        Pipeline[[11]]=paste0("    },")
        Pipeline[[12]]=paste0("    {")
        Pipeline[[13]]=paste0(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","))
        Pipeline[[14]]=paste0(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","))
        Pipeline[[15]]=paste0(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","))
        Pipeline[[16]]=paste0(paste0("       ",shQuote("resolution"),": ",reso,","))
        Pipeline[[17]]=paste0(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est)-reso,"],[",Sud,",",as.numeric(Nord)-reso,"])")),","))
        Pipeline[[18]]=paste0(paste0("       ",shQuote("filename"),":",shQuote(nom_Rast)))
        Pipeline[[19]]=paste0("    }")
        Pipeline[[20]]=paste0("]")
        
        connec=file(nomjson)
        writeLines(do.call(rbind,Pipeline), connec, sep = "\n", useBytes = FALSE)
        close(connec)
        
        cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
        cat("PDAL SansRetour")
        system(cmd)
        if (Nettoyage==1){unlink(nomjson)}
        
        
        if (PDAL_EAU==1)
        {
          # Creation d'un pipeline pdal pour avoir les zones en eau
          # zones en eau, si plusieurs vol, la zone en eau risque parfois d'inonder des points sol d'un autre vol
          # mais d'un autre coté la zone en eau peut être vu sous des arbres (jamais vu pour l'instant)
          nom_method="min"
          raci=paste0(substr(NomLaz,1,nchar(NomLaz)-4))
          nom_RastEAU=paste0(raci,"_","EAUAJeter",".tif")
          setwd(ChemLaz)
          NomLaz_tmp=NomLaz
          
          nomjson=paste0(raci,"_MyScript.json")
          
          Pipeline=list()
          Pipeline[[1]]=paste0("[")
          Pipeline[[2]]=paste0("    {")
          Pipeline[[3]]=paste0(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","))
          Pipeline[[4]]=paste0(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","))
          Pipeline[[5]]=paste0(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","))
          Pipeline[[6]]=paste0(paste0("       ",shQuote("nosrs"),":",shQuote("true")))
          Pipeline[[7]]=paste0("    },")
          Pipeline[[8]]=paste0("    {")
          Pipeline[[9]]=paste0(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","))
          Pipeline[[10]]=paste0(paste0("       ",shQuote("limits"),":",shQuote("Classification[9:9]")))
          Pipeline[[11]]=paste0("    },")
          Pipeline[[12]]=paste0("    {")
          Pipeline[[13]]=paste0(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","))
          Pipeline[[14]]=paste0(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","))
          Pipeline[[15]]=paste0(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","))
          Pipeline[[16]]=paste0(paste0("       ",shQuote("resolution"),": ",reso,","))
          Pipeline[[17]]=paste0(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est)-reso,"],[",Sud,",",as.numeric(Nord)-reso,"])")),","))
          Pipeline[[18]]=paste0(paste0("       ",shQuote("filename"),":",shQuote(nom_RastEAU)))
          Pipeline[[19]]=paste0("    }")
          Pipeline[[20]]=paste0("]")
          
          connec=file(nomjson)
          writeLines(do.call(rbind,Pipeline), connec, sep = "\n", useBytes = FALSE)
          close(connec)
          
          cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
          cat(" PDAL EAU")
          system(cmd)
          if (Nettoyage==1){unlink(nomjson)}
          
          # Creation d'un pipeline pdal pour avoir les points sol afin de ne garder les zones en eau hors des points sol
          # zones en eau, si plusieurs vol, la zone en eau risque parfois d'inonder des points sol d'un autre vol
          # mais d'un autre coté la zone en eau peut être vu sous des arbres (jamais vu pour l'instant)
          nom_method="min"
          raci=paste0(substr(NomLaz,1,nchar(NomLaz)-4))
          nom_RastSOL=paste0(raci,"_","SOLAJeter",".tif")
          setwd(ChemLaz)
          NomLaz_tmp=NomLaz
          
          nomjson=paste0(raci,"_MyScript.json")
          
          Pipeline=list()
          Pipeline[[1]]=paste0("[")
          Pipeline[[2]]=paste0("    {")
          Pipeline[[3]]=paste0(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","))
          Pipeline[[4]]=paste0(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","))
          Pipeline[[5]]=paste0(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","))
          Pipeline[[6]]=paste0(paste0("       ",shQuote("nosrs"),":",shQuote("true")))
          Pipeline[[7]]=paste0("    },")
          Pipeline[[8]]=paste0("    {")
          Pipeline[[9]]=paste0(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","))
          Pipeline[[10]]=paste0(paste0("       ",shQuote("limits"),":",shQuote("Classification[2:2]")))
          Pipeline[[11]]=paste0("    },")
          Pipeline[[12]]=paste0("    {")
          Pipeline[[13]]=paste0(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","))
          Pipeline[[14]]=paste0(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","))
          Pipeline[[15]]=paste0(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","))
          Pipeline[[16]]=paste0(paste0("       ",shQuote("resolution"),": ",reso,","))
          Pipeline[[17]]=paste0(paste0("       ",shQuote("radius"),":",reso/2*(2^0.5),","))
          Pipeline[[18]]=paste0(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est)-reso,"],[",Sud,",",as.numeric(Nord)-reso,"])")),","))
          Pipeline[[19]]=paste0(paste0("       ",shQuote("filename"),":",shQuote(nom_RastSOL)))
          Pipeline[[20]]=paste0("    }")
          Pipeline[[21]]=paste0("]")
          
          connec=file(nomjson)
          writeLines(do.call(rbind,Pipeline), connec, sep = "\n", useBytes = FALSE)
          close(connec)
          
          cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
          cat(" PDAL SOL")
          system(cmd)
          if (Nettoyage==1){unlink(nomjson)}
        }
        cat("\n")
        
        source(
          paste(
            chem_routine,
            "\\Sous_Routine_Cartino2D\\Cartino2D_Utilitaires.R",
            sep = ""
          ),
          encoding = "utf-8"
        )
        source(file.path(chem_routine,"FILINO_1a_MasqueEau_Grass.R"),encoding = "utf-8")
        FILINO1a_Grass(iLAZ)
      }
    }
  }
}