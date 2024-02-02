cat("\014")
cat("FILINO_06_02ab_ExtraitLazGrosMasquesEau\n")

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))


# Il manque intersection masques2filino et zone en qgis

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  if (Supp_PtsVirt_copc_laz==1)
  {
    Liste_PtsVirt_copc_laz=list.files(file.path(dsnlayer,NomDirSurfEAU,racilayerTA),pattern="SurfEAU_PtsVirt.copc.laz",full.names = TRUE,recursive=T)
    unlink(Liste_PtsVirt_copc_laz)
  }  
  
  cat("##################################################################\n")
  cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
  cat("##################################################################\n")
  TA=TA[n_int,]
  
  # On ne prend pas le masque de chaque TA car les objets 'auront pas la même numérotation
  # travail à faire pour mieux gérer cette problématique
  Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_FILINO",".gpkg")))
  
  NbCharIdGlobal=nchar(Masques2$IdGlobal[1])
  
  nvieux=grep(Masques2$FILINO,pattern="Vieux")
  if (length(nvieux)>0) {Masques2=Masques2[-nvieux,]}
  
  # Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,paste0("Masques1_FILINO","_",racilayerTA,".gpkg")))
  Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1_FILINO.gpkg"))
  
  nb=st_intersects(TA,Masques2)
  n_int = which(sapply(nb, length)>0)
  TA=TA[n_int,]
  
  if (Etap2[1]==1)
  {
    cat("\014")
    cat("FILINO_06_02ab_ExtraitLazGrosMasquesEau - Etap2[1]\n")
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
        cat("Nombre de masques des VIDE/EAU à traiter:",length(n_int),"\n")
        cat("Indices",n_int,"\n")
        # st_write(Masques2[n_int,],file.path(dsnlayer,"fred.shp"), delete_layer=T, quiet=T)
        
        for (iMasq in n_int)
        {
          # Croisement des masques avec la table d'assemblage
          # Selection des sections dans le Lidar
          Masq_tmp=Masques2[iMasq,]
          
          # raciMasq=paste0(raciSurfEau,formatC(Masq_tmp$IdGlobal,width=5, flag="0"),"_",racilayerTA)
          raciMasq=paste0(raciSurfEau,Masq_tmp$IdGlobal)
          raci=paste0(raciMasq,"_",substr(NomLaz,1,nchar(NomLaz)-4))
          
          # setwd(ChemLaz)
          
          NomLaz_tmp=ifelse(substr(raci,nchar(raci)-4,nchar(raci))==".copc",
                            paste0(raci,".laz"),
                            paste0(raci,".copc.laz"))
          
          # nouveau 07/02/2023
          # rep_COURSEAU=file.path(dsnlayer,NomDirSurfEAU,paste0(racilayerTA,raciSurfEau,formatC(Masq_tmp$IdGlobal,width=5, flag="0")))
          rep_COURSEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,Masq_tmp$IdGlobal),NomDossDalles)
          
          # if (file.exists(rep_COURSEAU)==F){dir.create(rep_COURSEAU)}
          rep_COURSEAU=file.path(rep_COURSEAU)
          # if (file.exists(rep_COURSEAU)==F){dir.create(rep_COURSEAU)}
          FILINO_Creat_Dir(rep_COURSEAU)
          nomjson=file.path(rep_COURSEAU,paste0(raci,"06_02ab_MyScript.json"))
          NomLaz_tmp=file.path(rep_COURSEAU,NomLaz_tmp)
          if (file.exists(NomLaz_tmp)==F & file.exists(file.path(rep_COURSEAU,paste0(raci,".vide")))==F)
          {
            # Creation d'un pipeline pdal pour extraire les points autour du masque
            cat("------------------------------------------------------------------\n")
            cat(NomLaz_tmp,"\n")
            write("[",nomjson)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(file.path(ChemLaz,NomLaz)),","),nomjson,append=T)
            write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
            write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
            # write(paste0("       ",shQuote("limits"),":",shQuote("Classification[1:2],Classification[9:9]")),nomjson,append=T)
            write(paste0("       ",shQuote("limits"),":",shQuote("Classification[2:2],Classification[9:9]")),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
            write(paste0("       ",shQuote("polygon"),":",shQuote(st_as_text(st_geometry(Masq_tmp)))),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","),nomjson,append=T)
            write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
            write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
            write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
            write("    }",nomjson,append=T)
            write("]",nomjson,append=T)
            
            cmd=paste(pdal_exe,"pipeline",nomjson)
            system(cmd)
            if (Nettoyage==1){unlink(nomjson)}
            
            if (file.exists(NomLaz_tmp)==F)
            {
              write("VIDE",file.path(rep_COURSEAU,paste0(raci,".vide")))
            }
            
          }else{
            if (file.exists(NomLaz_tmp)==T)  cat("Déjà présent: ",NomLaz_tmp,"\n") else cat("VIDE: ",file.path(rep_COURSEAU,paste0(raci,".vide")),"\n")
          }
          
        }
      }
    }
  }
  if (Etap2[2]==1 | Etap2[3]==1)
  {
    cat("\014")
    cat("FILINO_06_02ab_ExtraitLazGrosMasquesEau - Etap2[2]==1 | Etap2[3]==1\n")
    
    # for (iMasq in ListeRaciLAZ[1:length(ListeRaciLAZ)])
    for (iMasq in paste0(raciSurfEau,Masques2$IdGlobal))
    {
      cat("On en est où ",iMasq,which(iMasq==paste0(raciSurfEau,Masques2$IdGlobal)),"\n")
      # setwd(file.path(dsnlayer,NomDirSurfEAU,racilayerTA))
      
      NomLaz_tmp=paste0(raciSurfEau,".copc.laz")
      
      cat("###############################################################\n")
      cat(iMasq,NomLaz_tmp,"\n")
      
      # Recup du masque
      idglo=substr(iMasq,nchar(raciSurfEau)+1,nchar(raciSurfEau)+NbCharIdGlobal)
      Masque2=Masques2[which(Masques2$IdGlobal==idglo),]
      # Lecture du cas à traiter dans Masque2$FILINO, ordre important
      Cas=0
      if (substr(Masque2$FILINO,1,3)=="Mer")   {Cas=1}
      if (substr(Masque2$FILINO,1,3)=="Eco")   {Cas=4}
      if (substr(Masque2$FILINO,1,3)=="Can")   {Cas=3}
      if (substr(Masque2$FILINO,1,3)=="Pla")   {Cas=2}
      
      rep_COURSEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,iMasq)
      
      if (Cas==4)
      {
        raci_exp=paste(basename(rep_COURSEAU),racilayerTA,"Cas",CodeVirtuels[Cas,1],CodeVirtuels[Cas,2],sep="_")
      }else{
        raci_exp=paste(basename(rep_COURSEAU),racilayerTA,"Cas",CodeVirtuels[Cas,1],CodeVirtuels[Cas,2],PourcPtsBas*100,"pcbas",sep="_")
      }
      NomLaz_tmp=file.path(rep_COURSEAU,NomLaz_tmp)
      nomcsv=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-9),".csv")
      nomPtsVirt=file.path(rep_COURSEAU,paste0(raciSurfEau,"_PtsVirt.csv"))
      if (file.exists(file.path(rep_COURSEAU,paste0(raciSurfEau,"_PtsVirt.copc.laz")))==T & file.exists(paste0(raci_exp,'.jpg'))==T)
      {
        cat(raciSurfEau," déjà traité","\n")
      }else{
        
        if (file.exists(file.path(rep_COURSEAU,paste0(raci_exp,'.jpg')))==F)
        {
          FILINO_Creat_Dir(rep_COURSEAU)
          # if (file.exists(rep_COURSEAU)==F){dir.create(rep_COURSEAU)}
          
          
          # nmasq=grep(NOMLAZMasq,pattern=iMasq)
          nmasq=list.files(file.path(dsnlayer,NomDirSurfEAU,racilayerTA,iMasq,NomDossDalles),pattern="laz",recursive=TRUE)
          if (length(nmasq)!=0)
          {
            if (file.exists(nomcsv)==F)
            {
              
              # Creation d'un pipeline pdal pour fusionner les différents fichiers et exporter en csv pour un traitement R
              cat("Plusieurs",nmasq,"\n")
              nomjson=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,iMasq,paste0(iMasq,"_MyScript.json"))
              
              write("[",nomjson)
              for (iNOMLAZMasq in nmasq)
              {
                write(paste0("       ",shQuote(file.path(dsnlayer,NomDirSurfEAU,racilayerTA,iMasq,NomDossDalles,iNOMLAZMasq)),","),nomjson,append=T)
              }
              if (length(nmasq)>1)
              {
                write("    {",nomjson,append=T)
                write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
                write("    },",nomjson,append=T)
              }
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp)),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("writers.text"),","),nomjson,append=T)
              write(paste0("       ",shQuote("format"),":",shQuote("csv"),","),nomjson,append=T)
              write(paste0("       ",shQuote("order"),":",shQuote("X,Y,Z,Classification"),","),nomjson,append=T)
              write(paste0("       ",shQuote("keep_unspecified"),":",shQuote("false"),","),nomjson,append=T)
              
              write(paste0("       ",shQuote("filename"),":",shQuote(nomcsv)),nomjson,append=T)
              write("    }",nomjson,append=T)
              write("]",nomjson,append=T)
              cmd=paste(pdal_exe,"pipeline",nomjson)
              
              if (Etap2[2]==1)
              {
                cat("FILINO_06_02ab_ExtraitLazGrosMasquesEau - Etap2[2]==1\n")
                cat(nomcsv,"\n")
                system(cmd)
                atte=1
              }
              
              if (Nettoyage==1){unlink(nomjson)}
              
              
              
              st_write(Masques1[which(Masques1$IdGlobal==idglo),],
                       file.path(rep_COURSEAU,"Masque1.gpkg"), delete_layer=T, quiet=T)
              idglo=substr(iMasq,nchar(raciSurfEau)+1,nchar(raciSurfEau)+NbCharIdGlobal)
              
              st_write(Masques2[which(Masques2$IdGlobal==idglo),],
                       file.path(rep_COURSEAU,"Masque2.gpkg"), delete_layer=T, quiet=T)
              # Copie d'un projet Qgis pour une visu rapide
              file.copy(file.path(dsnlayer,NomDirSIGBase,"ProjetQgis_SurfEau.qgz"),
                        file.path(rep_COURSEAU,"ProjetQgis_SurfEau.qgz"),
                        overwrite = T)
            }
            if (file.exists(nomcsv)==T & Etap2[3]==1)
            {
              # cat("\014")
              # cat("FILINO_06_02ab_ExtraitLazGrosMasquesEau - Etap2[3]==1\n")
              source(paste(chem_routine,"\\FILINO_06_02c_creatPtsVirtuels.R", sep = ""),encoding = "utf-8")
              atte=1
            }else{
              cat("Pas de csv ",nomcsv,"ou Etap2[3]==0\n")
            }
          }else{
            cat("déjà traité ",nomcsv,"\n")}
          
          
        }else{cat("Fichier jpg déjà présent",nomcsv,"\n")}
        
        ###########################################################
        # Travail commun quand on a créé les points virtuels pour les basculer en Laz
        if (Cas>0)
        {
          
          cat("nomPtsVirt\n")
          zzzz=1
          if (file.exists(nomPtsVirt)==T)
          {
            nomPtsVirtLaz=file.path(rep_COURSEAU,paste0(raciSurfEau,"_PtsVirt.copc.laz"))
            # write.csv(PtsVirtuels,file=nomPtsVirt,quote=FALSE,row.names = FALSE)
            
            nomjson=file.path(rep_COURSEAU,paste0(raciSurfEau,"_",racilayerTA,"_PtsVirt.json"))
            cat("###############################################################\n")
            write("[",nomjson)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("readers.text"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(nomPtsVirt),","),nomjson,append=T)
            write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG))),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(nomPtsVirtLaz),","),nomjson,append=T)
            write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
            write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
            write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
            write("    }",nomjson,append=T)
            write("]",nomjson,append=T)
            
            cmd=paste(pdal_exe,"pipeline",nomjson)
            system(cmd)
            
            if (Nettoyage==1){unlink(nomjson)}
          }
        }
      }
    }
  }
  
}