#----------------------------------------------------------------------------------------
FILINO_06_02ab_Job1=function(iLAZ,TA_tmp,TA,Masques2,NomDirTmp,raciTmp,ClassTmp)
{
  # if (is.null(TA_tmp$CHEMIN))
  # {
  # Lidar Hd 
  NomLaz=basename(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
  ChemLaz=dirname(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
  # }else{
  #   # Lidar HD classif
  #   NomLaz=TA_tmp$NOM
  #   ChemLaz=TA_tmp$CHEMIN
  # }
  
  cat("###############################################################\n")
  cat("Passage R",iLAZ,"sur", dim(TA)[1],"\n")
  cat("#######################",TA_tmp$NOM,"\n")
  nb=st_intersects(Masques2,TA_tmp)
  n_int = which(sapply(nb, length)>0)
  
  if (length(n_int)>0)
  {  
    cat("Nombre de masques des VIDE/EAU à traiter:",length(n_int),"\n")
    cat("Indices",n_int,"\n")
    
    Masq_tmp=Masques2[n_int,]
    ValUserData=99
    Masq_tmp$UserData=ValUserData
    Masq_tmp=Masq_tmp[,"UserData"]
    
    cat(TA_tmp$NOM,"\n")
    
    rep_COURSEAU=Func_RepSurfCoursEau(st_bbox(TA_tmp),TA_tmp$NOM,dsnlayer,NomDirSurfEAU,racilayerTA,raciSurfEau)
    
    nomMasq_tmp=file.path(rep_COURSEAU,paste0(basename(rep_COURSEAU),"Masq2_ajeter.gpkg"))
    
    raci=paste0(raciTmp,"_",basename(rep_COURSEAU))
    
    NomLaz_tmp=ifelse(substr(raci,nchar(raci)-4,nchar(raci))==".copc",
                      paste0(raci,".laz"),
                      paste0(raci,".copc.laz"))
    
    nomjson=file.path(rep_COURSEAU,paste0(raci,"06_02ab_1.json"))
    NomLaz_tmp=file.path(rep_COURSEAU,NomLaz_tmp)
    if (file.exists(NomLaz_tmp)==F & file.exists(file.path(rep_COURSEAU,paste0(raci,".vide")))==F)
    {  
      FILINO_Creat_Dir(rep_COURSEAU) 
      st_write(Masq_tmp,nomMasq_tmp,driver = "GPKG",delete_dsn = TRUE,delete_layer = TRUE)
      
      cat("------------------------------------------------------------------\n")
      cat(NomLaz_tmp,"\n")
      write("[",nomjson)
      write("    {",nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
      write(paste0("       ",shQuote("filename"),":",shQuote(file.path(ChemLaz,NomLaz)),","),nomjson,append=T)
      write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
      write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
      write("    },",nomjson,append=T)
      if (is.null(ClassTmp)==F)
      {
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        write(paste0("       ",shQuote("limits"),":",shQuote(ClassTmp)),nomjson,append=T)
        write("    },",nomjson,append=T)
      }
      # Le filter.crop est moins précis que le overlay, bcp plus de points débordent du masque2...
      # write("    {",nomjson,append=T)
      # write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
      # write(paste0("       ",shQuote("polygon"),":",shQuote(st_as_text(st_geometry(st_union(Masq_tmp))))),nomjson,append=T)
      # write("    },",nomjson,append=T)
      write("    {",nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("filters.overlay"),","),nomjson,append=T)
      write(paste0("       ",shQuote("column"),":",shQuote("UserData"),","),nomjson,append=T)
      write(paste0("       ",shQuote("datasource"),":",shQuote(nomMasq_tmp),","),nomjson,append=T)
      write(paste0("       ",shQuote("dimension"),":",shQuote("UserData")),nomjson,append=T)
      write("    },",nomjson,append=T)
      write("    {",nomjson,append=T)
      write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
      write(paste0("       ",shQuote("limits"),":",shQuote(paste0("UserData[",ValUserData,":",ValUserData,"]"))),nomjson,append=T)
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
      toto=system(cmd)
      if (Nettoyage==1){
        unlink(nomjson)
        unlink(nomMasq_tmp)
      }
      
      if (file.exists(NomLaz_tmp)==F)
      {
        write("VIDE",file.path(rep_COURSEAU,paste0(raci,".vide")))
      }
      
    }else{
      if (file.exists(NomLaz_tmp)==T)  cat("Déjà présent: ",NomLaz_tmp,"\n") else cat("VIDE: ",file.path(rep_COURSEAU,paste0(raci,".vide")),"\n")
    }
  }
}

#----------------------------------------------------------------------------------------
FILINO_06_02ab_Job23=function(iMasq,Masques1,Masques2,NbCharIdGlobal,NomDirTmp,raciTmp,TA)
{
  # browser()
  ValUserData=98
  
  NomLaz_tmp=paste0(raciTmp,".copc.laz")
  
  cat("###############################################################\n")
  cat(iMasq,NomLaz_tmp,"\n")
  idglo=substr(iMasq,nchar(raciTmp)+1,nchar(iMasq))
  Masque2=Masques2[which(Masques2$IdGlobal==idglo),]
  
  cat("On en est où ",iMasq,which(iMasq==paste0(raciTmp,Masque2$IdGlobal)),"\n")
  cat(Masque2$IdGlobal)
  
  if (Masque2$IdGlobal=="001_000000kmX0874500Y6262500"){browser()}#arrêt sur une surface en eau coquine
  
  # Lecture du cas à traiter dans Masque2$FILINO, ordre important
  Cas=0
  cat(Masque2$IdGlobal,"\n")
  # if (nchar(Masque2$FILINO)>0)
  
  if (substr(Masque2$FILINO,1,3)=="Mer")   {Cas=1}
  if (substr(Masque2$FILINO,1,3)=="Eco")   {Cas=4}
  if (substr(Masque2$FILINO,1,3)=="Can")   {Cas=3}
  if (substr(Masque2$FILINO,1,3)=="Pla")   {Cas=2}
  
  
  raciMasq=paste0(raciSurfEau,Masque2$IdGlobal)
  TA_tmp=TApourFunc_RepSurfCoursEau(TA,Masque2)
  
  
  rep_COURSEAU=Func_RepSurfCoursEau(st_bbox(Masque2),TA_tmp$NOM,dsnlayer,NomDirSurfEAU,racilayerTA,raciSurfEau)
  rep_COURSEAU=file.path(rep_COURSEAU,raciMasq)
  cat(rep_COURSEAU,"\n")
  if (Cas==4)
  {
    raci_exp=paste(basename(rep_COURSEAU),racilayerTA,"Cas",CodeVirtuels[Cas,1],CodeVirtuels[Cas,2],sep="_")
  }else{
    raci_exp=paste(basename(rep_COURSEAU),racilayerTA,"Cas",CodeVirtuels[Cas,1],CodeVirtuels[Cas,2],PourcPtsBas*100,"pcbas",sep="_")
  }
  NomLaz_tmp=file.path(rep_COURSEAU,NomLaz_tmp)
  nomcsv=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-9),".csv")
  nomPtsVirt=file.path(rep_COURSEAU,paste0(raciTmp,"_PtsVirt.csv"))
  if (file.exists(file.path(rep_COURSEAU,paste0(raciTmp,"_PtsVirt.copc.laz")))==T & file.exists(paste0(raci_exp,'.jpg'))==T)
  {
    cat(raciTmp," déjà traité","\n")
  }else{
    if (file.exists(file.path(rep_COURSEAU,paste0(raci_exp,'.jpg')))==F)
    {
      # browser()
      FILINO_Creat_Dir(rep_COURSEAU)
      
      rep_tmp=sapply(strsplit(TA_tmp$NOM,"\\."), function(x) {x[[1]][1]})
      nom_tmp=paste0(raciSurfEau,"_",TA_tmp$NOM)
      nmasq=file.path(dsnlayer,NomDirTmp,racilayerTA,rep_tmp,nom_tmp)
      nici=file.exists(nmasq)
      if (length(nici)>0)
      {
        nmasq=nmasq[nici]
        
        if (length(nmasq)!=0)
        {
          if (file.exists(nomcsv)==F)
          { 
            # Creation d'un pipeline pdal pour fusionner les différents fichiers et exporter en csv pour un traitement R
            cat("Plusieurs",basename(nmasq),"\n")
            nomjson=file.path(rep_COURSEAU,paste0(iMasq,"2.json"))
            
            write("[",nomjson)
            for (iNOMLAZMasq in nmasq)
            {
              # write(paste0("       ",shQuote(file.path(rep_COURSEAU,NomDossDalles,iNOMLAZMasq)),","),nomjson,append=T)
              write(paste0("       ",shQuote(iNOMLAZMasq),","),nomjson,append=T)
            }
            
            if (length(nmasq)>1)
            {
              # coupure avec overlay
              nomMasq_tmp=file.path(rep_COURSEAU,paste0(basename(rep_COURSEAU),"Masq2_ajeter.gpkg"))
              Masq_tmp=Masque2
              Masq_tmp$UserData=ValUserData
              Masq_tmp=Masq_tmp[,"UserData"]
              st_write(Masq_tmp,nomMasq_tmp,driver = "GPKG",delete_dsn = TRUE,delete_layer = TRUE)
              
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.overlay"),","),nomjson,append=T)
              write(paste0("       ",shQuote("column"),":",shQuote("UserData"),","),nomjson,append=T)
              write(paste0("       ",shQuote("datasource"),":",shQuote(nomMasq_tmp),","),nomjson,append=T)
              write(paste0("       ",shQuote("dimension"),":",shQuote("UserData")),nomjson,append=T)
              write("    },",nomjson,append=T)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
              write(paste0("       ",shQuote("limits"),":",shQuote(paste0("UserData[",ValUserData,":",ValUserData,"]"))),nomjson,append=T)
              write("    },",nomjson,append=T)
              
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
              write("    },",nomjson,append=T)
            }else{
              # coupure avec crop (sans doute plus petit)
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
              write(paste0("       ",shQuote("polygon"),":",shQuote(st_as_text(st_geometry(st_union(Masque2))))),nomjson,append=T)
              write("    },",nomjson,append=T)
            }
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp)),nomjson,append=T)
            write("    },",nomjson,append=T)
            
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("writers.text"),","),nomjson,append=T)
            write(paste0("       ",shQuote("format"),":",shQuote("csv"),","),nomjson,append=T)
            #Hydrométrie
            # if (file.exists(file.path(rep_COURSEAU,"StHydro.gpkg"))==T)
            # {
            write(paste0("       ",shQuote("order"),":",shQuote("X,Y,Z,Classification,GpsTime"),","),nomjson,append=T)
            # }else{
            #   write(paste0("       ",shQuote("order"),":",shQuote("X,Y,Z,Classification"),","),nomjson,append=T)
            # }
            write(paste0("       ",shQuote("keep_unspecified"),":",shQuote("false"),","),nomjson,append=T)
            
            write(paste0("       ",shQuote("filename"),":",shQuote(nomcsv)),nomjson,append=T)
            write("    }",nomjson,append=T)
            write("]",nomjson,append=T)
            cmd=paste(pdal_exe,"pipeline",nomjson)
            
            if (Etap2[2]==1)
            {
              cat("FILINO_06_02ab_ExtraitLazMasquesEau - Etap2[2]==1\n")
              cat(nomcsv,"\n")
              toto=system(cmd)
              atte=1
            }
            
            if (Nettoyage==1){unlink(nomjson)}
            
            
            # browser()
            st_write(Masques1[which(Masques1$IdGlobal==idglo),],
                     file.path(rep_COURSEAU,"Masque1.gpkg"), delete_layer=T, quiet=T)
            idglo=substr(iMasq,nchar(raciTmp)+1,nchar(raciTmp)+NbCharIdGlobal)
            
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
            # cat("FILINO_06_02ab_ExtraitLazMasquesEau - Etap2[3]==1\n")
            nomcsv
            # source(paste(chem_routine,"\\FILINO_06_02c_creatPtsVirtuels.R", sep = ""),encoding = "utf-8")
            FILINO_06_02c_creatPtsVirtuels(nomcsv,rep_COURSEAU,Cas,raci_exp,nomPtsVirt)
            atte=1
          }else{
            cat("Pas de csv ",nomcsv,"ou Etap2[3]==0\n")
          }
        }else{
          cat("déjà traité ",nomcsv,"\n")}
        
        
      }else{cat("Fichier jpg déjà présent",nomcsv,"\n")}
    }
    ###########################################################
    # Travail commun quand on a créé les points virtuels pour les basculer en Laz
    if (Cas>0)
    {
      
      cat("nomPtsVirt\n")
      zzzz=1
      if (file.exists(nomPtsVirt)==T)
      {
        nomPtsVirtLaz=file.path(rep_COURSEAU,paste0(raciTmp,"_PtsVirt.copc.laz"))
        # write.csv(PtsVirtuels,file=nomPtsVirt,quote=FALSE,row.names = FALSE)
        if (file.exists(nomPtsVirtLaz)==F)
        {
          nomjson=file.path(rep_COURSEAU,paste0(raciTmp,"_",racilayerTA,"_PtsVirt3.json"))
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
          toto=system(cmd)
          
          if (Nettoyage==1){unlink(nomjson)}
        }else{
          cat("Pas de ",nomPtsVirtLaz,"\n")
        }
      }else{
        cat("Pas de ",nomPtsVirt,"\n")
      }
    }
  }
  
}