FILINO_21_Job=function(idalle,TA_Rast_Zone,ResoNew,SecteurGRASS_,nEPSG,dsnTApRe)
{
  cat("\014") # Nettoyage de la console
  
  nomMNTinfo=file.path(dsnTApRe,TA_Rast_Zone$DOSSIERASC[idalle],paste0(strsplit(TA_Rast_Zone$NOM_ASC[idalle],"\\.")[[1]][length(strsplit(TA_Rast_Zone$NOM_ASC[idalle],"\\.")[[1]])-1],".html"))
  nomMNTdecal=file.path(dsnTApRe,TA_Rast_Zone$DOSSIERASC[idalle],paste0(strsplit(TA_Rast_Zone$NOM_ASC[idalle],"\\.")[[1]][length(strsplit(TA_Rast_Zone$NOM_ASC[idalle],"\\.")[[1]])-1],".gpkg"))
  nomMNT=file.path(dsnTApRe,TA_Rast_Zone$DOSSIERASC[idalle],TA_Rast_Zone$NOM_ASC[idalle])
  nomMNT_exp=basename(nomMNT)
  nomMNT_exp=paste0(strsplit(nomMNT_exp,"\\.")[[1]][1],".gpkg")
  nomMNTg="MNT"
  NomUnivar=file.path(dsnTApRe,TA_Rast_Zone$DOSSIERASC[idalle],paste0("runivar",idalle,".txt"))
  
  Sous_Doss=function(DOSSIERASC)
  {
    Dossrangement=""
    if (substr(basename(DOSSIERASC),1,8)=="RGEALTI_")
    {
      Dossrangement=basename(DOSSIERASC)
    }
    if (nchar((dirname(dirname(DOSSIERASC))))==2)
    {
      Dossrangement=dirname(dirname(DOSSIERASC))
    }
    return(Dossrangement)
  }
  
  Dossrangement=Sous_Doss(TA_Rast_Zone$DOSSIERASC[idalle])
  print(Dossrangement)
  
  AFAIRE=1
  for (iReso in ResoNew)
  {
    nomMNTResog=paste0("MNT",iReso)
    
    DossReso=paste0("_Reso",formatC(iReso,width=3, flag="0"))
    dirReso=file.path(dsnTApRe,DossReso,ifelse(nchar(Dossrangement)==0,DossReso,Dossrangement))
    NomGPKG=file.path(dirReso,nomMNT_exp)
    if (file.exists(NomGPKG)==F){ AFAIRE=1}
  }
  
  if (file.exists(nomMNT)==T & AFAIRE==1)
  { 
    cat("\014")
    
    #### gestion pour voir si le raster est bien aligner sur des 1000/2000/3000...
    # standard IGN génant
    cmd <- paste0(qgis_process, " run gdal:gdalinfo",
                  " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                  " --INPUT=",nomMNT,
                  " --MIN_MAX=false --STATS=true --NOGCP=false --NO_METADATA=false --EXTRA=",
                  " --OUTPUT=",nomMNTinfo)
    print(cmd); system(cmd)         
    
    # Lire le contenu du fichier
    file_content <- readLines(nomMNTinfo)
    # Extraire les valeurs des coins
    UL     <- grep("Upper Left", file_content, value = TRUE)
    LR     <- grep("Lower Right", file_content, value = TRUE)
    Taille <- grep("Size ", file_content, value = TRUE)
    
    ULLR=function(text)
      #Mistral
    {
      # Trouver les positions des parenthèses
      paren_positions <- regexpr("\\(", text)
      # Extraire les coordonnées des coins
      coords <- regmatches(text, gregexpr("\\d+\\.\\d+", text))
      # Convertir les valeurs en numérique
      coords <- as.numeric(unlist(coords))
      # Afficher les coordonnées des coins
      return(coords[1:2])
    }  
    
    LimXY=c(ULLR(UL),ULLR(LR))
    # gestion de sbugs peut être foireuse si dalle pas kilométrique
    if (LimXY[3]-LimXY[1]<1000){LimXY[1]=1000*floor((LimXY[1]+10)/1000);LimXY[3]=LimXY[1]+1000}#;browser()}
    if (LimXY[2]-LimXY[4]<1000){LimXY[4]=1000*floor((LimXY[4]+10)/1000);LimXY[2]=LimXY[4]+1000}#;browser()}
    
    reso=unique(ULLR(Taille))
    if (length(reso)>1){browser}
    
    nvaleur_   =grep("STATISTICS_VALID_PERCENT", file_content, value = TRUE)
    nvaleur__  =strsplit(nvaleur_ ,"=")[[1]][2]
    nvaleur___ =strsplit(nvaleur__,"<")[[1]][1]
    # if (nvaleur___!=100){browser()}
    nvaleur=round(as.numeric(nvaleur___)/100*(LimXY[3]-LimXY[1])*(LimXY[2]-LimXY[4])/(reso^2))
    
    cat(nvaleur)
    # Sys.sleep(5)
    
    if (max(abs(round(LimXY/1000)*1000-LimXY))>0)
    {
      if (file.exists(nomMNTdecal)==T){unlink(nomMNTdecal)}
      cmd <- paste0(qgis_process, " run gdal:translate",
                    " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                    " --INPUT=",nomMNT,
                    " --COPY_SUBDATASETS=false --OPTIONS=",
                    " --EXTRA=",shQuote(paste0("-a_ullr ",paste((round(LimXY/1000)*1000), collapse = " "))),
                    " --DATA_TYPE=0",
                    " --OUTPUT=",nomMNTdecal)
      print(cmd); system(cmd)  
      SuppMNTdecal=1
      
      nomMNT=nomMNTdecal
    }
    
    if (nvaleur>(1000000-(min(ResoNew)^2-1))/(reso^2))
    {
      for (iReso in ResoNew)
      {
        nomMNTResog=paste0("MNT",iReso)
        # dirReso=paste0(dsnTApRe,"\\_Reso",formatC(iReso,width=3, flag="0"))
        DossReso=paste0("_Reso",formatC(iReso,width=3, flag="0"))
        dirReso=file.path(dsnTApRe,DossReso,ifelse(nchar(Dossrangement)==0,DossReso,Dossrangement))
        if(dir.exists(dirReso)==F){dir.create(dirReso,recursive = T)}
        NomGPKG=file.path(dirReso,nomMNT_exp)
        if (file.exists(NomGPKG)==T){unlink(NomGPKG)}
        
        cmd <- paste0(qgis_process, " run gdal:warpreproject",
                      " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                      " --INPUT=",nomMNT,
                      " --SOURCE_CRS=",shQuote(paste0("EPSG:",nEPSG)),
                      " --TARGET_CRS=",shQuote(paste0("EPSG:",nEPSG)),
                      " --RESAMPLING=5", 
                      " --TARGET_RESOLUTION=",iReso,
                      " --OPTIONS= --DATA_TYPE=0",
                      " --TARGET_EXTENT_CRS=",shQuote(paste0("EPSG:",nEPSG)),
                      " --MULTITHREADING=false --EXTRA=",
                      " --OUTPUT=",NomGPKG
        )
        print(cmd); system(cmd) 
      }
    }else{
      # browser()
      demandemoinsproc=1
      if (demandemoinsproc==1)
      {
        ###############################################################################
        SecteurGRASS=paste0(dirname(SecteurGRASS_),format(Sys.time(),format="%Y%m%d_%H%M%S"),"_",idalle,'/',format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
        unlink(dirname(SecteurGRASS),recursive=TRUE)
        system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
        system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
        
        cat(nomMNT," à faire\n")
        
        # Import de la dalle Raster
        cmd=paste0("r.in.gdal -o --quiet --overwrite input=",nomMNT," output=",nomMNTg)
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        # Limitation de la région de travail
        cmd=paste0("g.region --quiet --overwrite raster=",nomMNTg)
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        # Test pour voir les dalles avec du vide
        # cmd=paste0("r.univar --quiet --overwrite map=",nomMNTg," output=",NomUnivar)
        # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        # nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
        # unlink(NomUnivar)
        cmd=paste0("r.univar --quiet --overwrite map=",nomMNTg)
        print(cmd);toto=system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd),intern=T)
        nlig=grep(toto,pattern="n: ")[1]
        nvaleur=as.numeric(strsplit(toto[nlig],":")[[1]][2])
        cat(toto[nlig],"\n")
        cat("Nombre de valeur: ",nvaleur, "\n")
        
        
        if (nvaleur>0)
        {
          Boite=st_bbox(TA_Rast_Zone[idalle,])
          # browser()
          
          # Gestion de la mer
          if (exists("Dpt_Inv_Mer")==F)
          {
            #Département Mer, pour tester si on est en mer ou à terre
            Dpt_Inv_Mer=st_read(nomBuf_pour_mer)
          }
          IntersTA_Dpt_Inv_Mer=st_intersection(TA_Rast_Zone[idalle,],Dpt_Inv_Mer)
          if (nrow(IntersTA_Dpt_Inv_Mer)==0){SurfTerre=0}else{SurfTerre=st_area(IntersTA_Dpt_Inv_Mer)}
          units(SurfTerre)=NULL
          print(SurfTerre)
          # n_intMer = which(sapply(nbMer, length)>0)
          # Si on est en bord de mer, on ne fait rien C2D gèrera...
          # if (length(n_intMer)==0)
          if (SurfTerre==1000000)
          {
            # 
            # Limitation de la région de travail et gestion de la résolution
            cmd=paste0("g.region --quiet --overwrite raster=",nomMNTg," n=",Boite$ymax," s=",Boite$ymin," e=",Boite$xmax," w=",Boite$xmin)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Création d'un masque inversé
            cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTg)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            nomVide="Vide"
            cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomVide)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Suppression du masque
            cmd=paste0("r.mask -r")
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Buffer sur le raster
            DistChercheMin=25
            Distg=2*floor((DistChercheMin*1/reso)/2)+1
            nomVideBuf="VideBuf"
            cmd=paste0("r.buffer --quiet --overwrite input=",nomVide," output=",nomVideBuf," distance=",Distg)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Création d'un masque 
            cmd=paste0("r.mask --quiet --overwrite raster=",nomVideBuf)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            nomMing=paste0("Min_",DistChercheMin)
            cmd=paste0("r.neighbors --quiet --overwrite input=",nomMNTg," output=",nomMing," size=",Distg," method=minimum")
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Test pour voir les dalles avec du vide
            # cmd=paste0("r.univar --quiet --overwrite map=",nomMing," output=",NomUnivar)
            # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            # Mini=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=6,nlines=1,dec=".")[2])
            # print(Mini)
            # unlink(NomUnivar)
            cmd=paste0("r.univar --quiet --overwrite map=",nomMNT)
            print(cmd);toto=system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd),intern=T)
            nlig=grep(toto,pattern="minimum: ")[1]
            Mini=as.numeric(strsplit(toto[nlig],":")[[1]][2])
            cat(toto[nlig],"\n")
            cat("Minimum: ",Mini, "\n")
            
            
            # Création de la couche des vides au niveau minimal
            nomComble="Comble"
            cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomComble," =",nomVide,"*",Mini)))
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Suppression du masque
            cmd=paste0("r.mask -r")
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Patch avec en priorite le MNT et ailleurs le comblement
            nom_MNTCg = "MNTComble"
            cmd=paste0("r.patch --quiet --overwrite ","input=",nomMNTg,",",nomComble," output=",nom_MNTCg)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd)) 
            
            dirResoini=paste0(dsnTApRe,"\\_Reso_Ini")
            if(dir.exists(dirResoini)==F){dir.create(dirResoini)}
            NomGPKGini=file.path(dirResoini,nomMNT_exp)
            cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nom_MNTCg," output=",NomGPKGini," type=Float32 format=GPKG nodata=-9999")
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            nomMNTg=nom_MNTCg
          }
          
          
          
          for (iReso in ResoNew)
          {
            nomMNTResog=paste0("MNT",iReso)
            # dirReso=paste0(dsnTApRe,"\\_Reso",formatC(iReso,width=3, flag="0"))
            DossReso=paste0("_Reso",formatC(iReso,width=3, flag="0"))
            dirReso=file.path(dsnTApRe,DossReso,ifelse(nchar(Dossrangement)==0,DossReso,Dossrangement))
            if(dir.exists(dirReso)==F){dir.create(dirReso,recursive = T)}
            NomGPKG=file.path(dirReso,nomMNT_exp)
            
            # Limitation de la région de travail et gestion de la résolution
            cmd=paste0("g.region --quiet --overwrite raster=",nomMNTg," n=",Boite$ymax," s=",Boite$ymin," e=",Boite$xmax," w=",Boite$xmin," res=",as.character(iReso))
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Modification de l résolution
            cmd=paste0("r.resamp.stats --quiet --overwrite input=",nomMNTg," output=",nomMNTResog)
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomMNTResog," output=",NomGPKG," type=Float32 format=GPKG nodata=-9999")
            print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          }
          unlink(dirname(dirname(SecteurGRASS)),recursive=TRUE)
        }
        unlink(nomMNTinfo)
        unlink(nomMNTdecal)
        
      }
    }
  }else{cat(nomMNT," déjà fait\n")}
}