FILINO_03_01a_Job=function(iLAZ,TA_tmp,dimTA1,NomLaz,reso,largdalle,paramXYTA,iTA,dsnTALidar,dsnlayer)
{
  NomLaz=basename(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
  ChemLaz=dirname(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
  
  
  decalgrille=reso
  Ouest=largdalle*as.numeric(substr(NomLaz,paramXYTA[2],paramXYTA[3]))
  Nord=largdalle*as.numeric(substr(NomLaz,paramXYTA[4],paramXYTA[5]))
  Est=as.character(Ouest+largdalle)
  Sud=as.character(Nord-largdalle)
  # ancien 05/08/2025
  # Est=as.character(Ouest+largdalle+decalgrille)
  # Sud=as.character(Nord-largdalle-decalgrille)
  # Ouest=as.character(Ouest-decalgrille)
  # Nord=as.character(Nord+decalgrille)
  
  raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
  
  cat("###############################################################\n")
  cat("TA",iTA,"/",length(dsnTALidar)," - Passage R",iLAZ,"sur", dimTA1,"\n")
  cat("------------------ VIDE et EAU  -------------------------------\n")
  cat(ChemLaz,"\n")
  cat(NomLaz,"\n")
  cat("###############################################################\n")
  ChemNomLaz=file.path(ChemLaz,NomLaz)
  
  NomTXT    =file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Cerema.txt"))
  NomTXT_old=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Cerema_old.txt"))
  if (file.exists(NomTXT)==T){file.copy(NomTXT,NomTXT_old)}
  
  
  Ch_Classif=paste0("Classification[",ClassDeb,":6],Classification[17:17],Classification[64:64],Classification[67:67],Classification[202:202]")
  write(Ch_Classif,NomTXT)
  Alancer=1
  if (file.exists(NomTXT_old)==T)
  {
    # Charger le contenu des deux fichiers texte
    fichier1 <- readLines(NomTXT)
    fichier2 <- readLines(NomTXT_old)
    
    # Comparer les fichiers
    differences <- setdiff(fichier1, fichier2)
    
    # Vérifier s'il y a des différences
    if (length(differences) == 0) {
      cat("Les fichiers paramètres sont équivalents.\n")
      Alancer=0
    } else {
      cat("Les fichiers paramètres sont différents:\n")
      Alancer=1
    }
    Sys.sleep(1);unlink(NomTXT_old)
  }
  
  if (Alancer==0 &
      ((file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque1.gpkg")))==T & 
        file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque2.gpkg")))==T) |
       file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque2.vide")))==T|
       file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque2.eau")))==T))
  {
    cat("MASQUE VIDE_EAU déjà fait ",
        file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque1.gpkg")),
        "\n")
  }else{
    if (Alancer==0)
    {
      cat("_Masque1.gpkg: ",file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque1.gpkg"))),"\n")
      cat("_Masque2.gpkg: ",file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque2.gpkg"))),"\n")
      cat("_Masque2.vide: ",file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque2.vide"))),"\n")
      cat("_Masque2.eau:  ",file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"_Masque2.eau "))),"\n")
    }
    #---------------------------------------------------------------------------------------------------------------
    # Creation d'un pipeline pdal pour avoir les zones sans retour lidar en ecluant dès le début les zones en eau
    # zones en eau, si plusieurs vol, la zone en eau risque parfois d'inonder des points sol d'un autre vol
    # mais d'un autre coté la zone en eau peut être vu sous des arbres (jamais vu pour l'instant)
    nom_method="min"
    nom_Rast_INV_VIDEetEAU=paste0(raci,"_","INV_VIDEetEAU_AJeter",".tif")
    
    nomjson=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"1_MyScript.json"))
    nominput=file.path(ChemLaz,NomLaz)
    Ch_Classif=paste0("Classification[",ClassDeb,":6],Classification[17:17],Classification[64:64],Classification[67:67],Classification[202:202]")
    
    
    FILINO_writers_gdal(nomjson,nominput,Ch_Classif,nom_method,reso,Ouest,Est,Sud,Nord,nom_Rast_INV_VIDEetEAU)
    
    if (PDAL_EAU==1)
    {
      #---------------------------------------------------------------------------------------------------------------
      # Creation d'un pipeline pdal pour avoir les zones en eau
      # zones en eau, si plusieurs vol, la zone en eau risque parfois d'inonder des points sol d'un autre vol
      # mais d'un autre coté la zone en eau peut être vu sous des arbres (jamais vu pour l'instant)
      nom_method="min"
      nom_RastEAU=paste0(raci,"_","EAU_AJeter",".tif")
      
      
      nomjson=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"2_MyScript.json"))
      nominput=file.path(ChemLaz,NomLaz)
      Ch_Classif="Classification[9:9]"
      
      FILINO_writers_gdal(nomjson,nominput,Ch_Classif,nom_method,reso,Ouest,Est,Sud,Nord,nom_RastEAU)
      
      #---------------------------------------------------------------------------------------------------------------
      # Creation d'un pipeline pdal pour avoir les points sol afin de ne garder les zones en eau hors des points sol
      # zones en eau, si plusieurs vol, la zone en eau risque parfois d'inonder des points sol d'un autre vol
      # mais d'un autre coté la zone en eau peut être vu sous des arbres (jamais vu pour l'instant)
      nom_method="min"
      nom_RastSOL=paste0(raci,"_","SOL_AJeter",".tif")
      
      
      
      nomjson=file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,paste0(raci,"3_MyScript.json"))
      nominput=file.path(ChemLaz,NomLaz)
      Ch_Classif="Classification[2:2]"
      
      FILINO_writers_gdal(nomjson,nominput,Ch_Classif,nom_method,reso,Ouest,Est,Sud,Nord,nom_RastSOL)
      
      
      #Creation d'un monde GRASS
      SecteurGRASS=paste0(dirname(SecteurGRASS_),"_",iLAZ,"_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
      system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
      system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
      
      # Ancien
      FILINO1a_Vide_Grass(iLAZ,NomLaz,nom_Rast_INV_VIDEetEAU,nom_RastEAU,nom_RastSOL,SecteurGRASS,Nord,Sud,Est,Ouest)
      # Nouveau du 05/08/2025 voir si cela ne plante pas pour d'autres choix que reso 0.5...
      # FILINO1a_Vide_Grass(iLAZ,NomLaz,nom_Rast_INV_VIDEetEAU,nom_RastEAU,nom_RastSOL,SecteurGRASS,as.numeric(Nord)-reso,as.numeric(Sud)+reso,as.numeric(Est)-reso,as.numeric(Ouest)+reso)
      
      Sys.sleep(1);unlink(dirname(SecteurGRASS),recursive=TRUE)
      cat("\014")
    }
    cat("\n")
  }
  cat("###############################################################\n")
  cat("TA",iTA,"/",length(dsnTALidar)," - Passage R",iLAZ,"sur", dimTA1,"\n")
  cat("------------------ PONTS --------------------------------------\n")
  cat(ChemLaz,"\n")
  cat(NomLaz,"\n")
  cat("###############################################################\n")
  if (file.exists(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,paste0(raci,"_Empr_PONT.gpkg")))==T | 
      file.exists(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,paste0(raci,".pasdepont")))==T)
  {
    cat("PONT déjà fait ",
        file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,paste0(raci,"_Empr_PONT.gpkg")),
        "\n")
  }else{
    #---------------------------------------------------------------------------------------------------------------
    # Creation d'un pipeline pdal pour avoir les points PONT 
    nom_method="max"
    
    nom_RastPONT=paste0(raci,"_","PONT",".tif")
    
    
    
    nomjson=file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,paste0(raci,"3_MyScript.json"))
    nominput=file.path(ChemLaz,NomLaz)
    Ch_Classif="Classification[17:17]"
    
    FILINO_writers_gdal(nomjson,nominput,Ch_Classif,nom_method,reso,Ouest,Est,Sud,Nord,nom_RastPONT)
    
    #Creation d'un monde GRASS
    SecteurGRASS=paste0(dirname(SecteurGRASS_),"_",iLAZ,"_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
    system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
    system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
    
    # source(file.path(chem_routine,"FILINO_03_01a_MasquePont_Grass.R"),encoding = "utf-8")
    FILINO1a_Pont_Grass(iLAZ,NomLaz,nom_RastPONT,SecteurGRASS,Nord,Sud,Est,Ouest)
    
    Sys.sleep(1);unlink(dirname(SecteurGRASS),recursive=TRUE)
    cat("\014")
  }
  
  
  cat("###############################################################\n")
  cat("TA",iTA,"/",length(dsnTALidar)," - Passage R",iLAZ,"sur", dimTA1,"\n")
  cat("------------------ VEGETATION DENSE-----------------------------------\n")
  cat(ChemLaz,"\n")
  cat(NomLaz,"\n")
  
  nom_masque_gpkg=paste0(raci,"_VegeTropDense.gpkg")
  nommasqueveget =file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,nom_masque_gpkg)
  nom_masque_vide=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci,"_VegeTropDense.vide"))
  cat("###############################################################\n")
  if (file.exists(nommasqueveget)==T | 
      file.exists(nom_masque_vide)==T)
  {
    cat("VEGE déjà fait ",
        nommasqueveget,
        "\n")
  }else{
    cat("###############################################################\n")
    ChemNomLaz=file.path(ChemLaz,NomLaz)
    
    #ToutSaufVegetation
    nom_method="min"
    nom_RastTSF=paste0(raci,"_","ToutSaufVege",".tif")
    nomjson=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci,"TSF_MyScript.json"))
    
    nominput=file.path(ChemLaz,NomLaz)
    Ch_Classif="Classification[1:2],Classification[6:100]"
    
    FILINO_writers_gdal(nomjson,nominput,Ch_Classif,nom_method,Mult_Reso*reso,Ouest,Est,Sud,Nord,nom_RastTSF)
    
    #HorsForet
    nom_method="min"
    nom_Rast_VEGE=paste0(raci,"_","Vege",".tif")
    # setwd(ChemLaz)
    nomjson=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci,"SV_MyScript.json"))
    
    
    nominput=file.path(ChemLaz,NomLaz)
    Ch_Classif="Classification[3:5]"
    FILINO_writers_gdal(nomjson,nominput,Ch_Classif,nom_method,Mult_Reso*reso,Ouest,Est,Sud,Nord,nom_Rast_VEGE)
    
    if (file.exists(file.path(dirname(nomjson),nom_RastTSF))==T)
    {
      #Creation d'un monde GRASS
      SecteurGRASS=paste0(dirname(SecteurGRASS_),"_",iLAZ,"_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
      system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
      system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
      
      source(file.path(chem_routine,"FILINO_03_01a_MasqueVEGE_Grass.R"),encoding = "utf-8")
      nommasqueveget=FILINO1a_Vege_Grass(iLAZ,NomLaz,nom_RastTSF,nom_Rast_VEGE,SecteurGRASS,Nord,Sud,Est,Ouest)
      print(nommasqueveget)
      Sys.sleep(1);unlink(dirname(SecteurGRASS),recursive=TRUE)
      cat("\014")
      if (Nettoyage==1)
      {
        if (file.exists(nomjson)){Sys.sleep(1);unlink(nomjson)}
        if (file.exists(nom_RastTSF)){Sys.sleep(1);unlink(nom_RastTSF)}
        # if (exists("nom_Rast2")==T){if (file.exists(nom_Rast2)){unlink(nom_Rast2)}}
      }
    }
    # }else{
    #   cat("Masque végétation déjà présent ",basename(nommasqueveget),"\n")
    # }
  }
}
