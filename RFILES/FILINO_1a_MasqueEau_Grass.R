FILINO1a_Grass =
  function(iLAZ) {
    # Récupération du raster, création d'un masque inversé
    nomMNT=paste0("MNT",iLAZ)
    nom_masque=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_masque")
    
    nombat="myscriptgrass.bat"
    #################################################\n")
    if (file.exists(file.path(ChemLaz,nom_Rast))==T)
    {
      # Suppression du masque (s'il existe)
      cmd=paste0("r.mask -r")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Import du raster
      cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(ChemLaz,nom_Rast)," output=",nomMNT)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Limitation de la région de travail et gestion de la résolution
      cmd=paste0("g.region --quiet --overwrite raster=",nomMNT," n=",Nord," s=",Sud," e=",Est," w=",Ouest," res=",as.character(reso))
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
      NomUnivar=file.path(dsnlayer,paste0(raci,"_runivar.txt"))
      cmd=paste0("r.univar --quiet --overwrite map=",nomMNT," output=",NomUnivar)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      #Lancement GRASS externe
      # system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
      unlink(NomUnivar)
      
      # S'il y a plus d'une valeur non nulle...
      if (nvaleur>0)
      {
        # Création d'un masque inversé
        cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNT)
        system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        nomMNTMasque1=paste0("MNT_Masque1_",iLAZ)
        # Creation d'un raster remplissant le masque inversé
        
        cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNTMasque1)
        system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        # vérification qu'il y a un secteur touché
        NomUnivar=file.path(dsnlayer,paste0(raci,"_runivar2.txt"))
        cmd=paste0("r.univar --quiet --overwrite map=",nomMNTMasque1," output=",NomUnivar)
        system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        # print(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec="."))
        nvaleur2=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
        unlink(NomUnivar)
        
        # Suppression du masque
        cmd=paste0("r.mask -r")
        system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        if (nvaleur2>0)
        {
          if (PDAL_EAU==1)
          {
            # Import du raster
            nomMNTEAU=paste0("MNTEAU",iLAZ)
            cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(ChemLaz,nom_RastEAU)," output=",nomMNTEAU)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Mise à la valeur 1
            nomMNTMasque1EAU=paste0("MNT_Masque1EAU_",iLAZ)
            cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomMNTMasque1EAU,"=if(",nomMNTEAU,">",-99,",1,null())")))
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            cmd=paste0("r.mask -r")
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # maximum du masque 1 et EAU
            nomMNTMasque1etEAU=paste0("MNT_Masque1_et_EAU_",iLAZ)
            cmd=paste0("r.series --quiet --overwrite input=",nomMNTMasque1,",",nomMNTMasque1EAU," output=",nomMNTMasque1etEAU," method=maximum")
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Création d'un masque inversé
            cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTMasque1etEAU)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Creation d'un raster remplissant le masque inversé
            nomMNTMasque1etEAUinv=paste0("MNT_Masque1_et_EAU_inv_",iLAZ)
            cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNTMasque1etEAUinv)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Suppression du masque
            cmd=paste0("r.mask -r")
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Buffer sur le raster de 1 fois la résolution mise en paramètre 
            nomMNTMasque1etEAUinvBuf=paste0("MNT_Masque1_et_EAU_inv_buf_",iLAZ)
            cmd=paste0("r.buffer --quiet --overwrite input=",nomMNTMasque1etEAUinv," output=",nomMNTMasque1etEAUinvBuf," distance=",2^0.5*reso)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            
            # Création d'un masque inversé
            cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTMasque1etEAUinvBuf)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Creation d'un raster remplissant le masque inversé
            nomMNTMasque1etEAUinvBufinv=paste0("MNT_Masque1_et_EAU_inv_buf_inv",iLAZ)
            cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNTMasque1etEAUinvBufinv)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # Suppression du masque
            cmd=paste0("r.mask -r")
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            # maximum du masque 1 et EAU
            nomMNTMasque1etEAUfin=paste0("MNT_Masque1_et_EAU_fin_",iLAZ)
            cmd=paste0("r.series --quiet --overwrite input=",nomMNTMasque1,",",nomMNTMasque1etEAUinvBufinv," output=",nomMNTMasque1etEAUfin," method=maximum")
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            nomMNTMasque1=nomMNTMasque1etEAUfin
          }
          
          nomMNTMasque1Buf=paste0("MNT_Masque1_",iLAZ,"Buf")
          nomMNTMasque2=paste0("MNT_Masque2_",iLAZ)
          # Buffer sur le raster de deux fois la résolution mise en paramètre 
          cmd=paste0("r.buffer --quiet --overwrite input=",nomMNTMasque1," output=",nomMNTMasque1Buf," distance=",2*reso)
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Raster buffre mis  à 1
          cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomMNTMasque2,"=if(",nomMNTMasque1Buf,">",-99,",1,null())")))
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          if (PDAL_EAU==1)
          {
            # Import du raster
            nomMNTSOL=paste0("MNTSOL",iLAZ)
            cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(ChemLaz,nom_RastSOL)," output=",nomMNTSOL)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            # Création d'un masque inversé
            cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTSOL)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          }
          # Conversion de masques et masque buffer en vecteur
          cmd=paste0("r.to.vect --quiet --overwrite input=",nomMNTMasque1," output=",nomMNTMasque1," type=area")
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          # Suppression du masque
          if (PDAL_EAU==1)
          {
            cmd=paste0("r.mask -r")
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          }
          cmd=paste0("r.to.vect --quiet --overwrite input=",nomMNTMasque2," output=",nomMNTMasque2," type=area")
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          # cela peut planter s'il n'y a pas un seul trou dans une dalle, il faudrait vérifier avec le nombre de pixel... r.univar
          
          #######################################################################
          ## IL MANQUE UN NETTOYAGE DES PIXELS ISOLES POUR LE LIDAR 2D AVEC UN NEIGHBORS ET IL EN FAUT 4
          ## A GARDER POUR LA SUITE
          #######################################################################
          
          
          # export si nettoyage =0
          if (file.exists(file.path(dsnlayer,NomDirMasque,racilayerTA))==F){dir.create(file.path(dsnlayer,NomDirMasque,racilayerTA))}
          cat("##################################################################\n")
          nom_masque_gpkg=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque1.gpkg")
          cat("Export des masques",nom_masque_gpkg,"\n")
          cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNTMasque1," output=",file.path(dsnlayer,NomDirMasque,racilayerTA,nom_masque_gpkg)," format=GPKG")
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          nom_masque_gpkg=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque2.gpkg")
          cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNTMasque2," output=",file.path(dsnlayer,NomDirMasque,racilayerTA,nom_masque_gpkg)," format=GPKG")
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          if (Nettoyage==1)
          {
            liste=ifelse(PDAL_EAU==1,
                         paste(nomMNT,paste0("MNT_Masque1_",iLAZ),nomMNTEAU,nomMNTMasque1EAU,nomMNTMasque1etEAU,nomMNTSOL,
                               nomMNTMasque1etEAUinv,nomMNTMasque1etEAUinvBuf,nomMNTMasque1etEAUinvBufinv,nomMNTMasque1etEAUfin,
                               nomMNTMasque1,nomMNTMasque1Buf,nomMNTMasque2,sep=","),
                         paste(nomMNT,nomMNTMasque1,nomMNTMasque1,nomMNTMasque1Buf,nomMNTMasque2,sep=","))
            #---- Suppression des rasters intermédiaires
            cmd=paste0("g.remove --quiet -f type=raster name=",liste)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
            
            liste=paste(nomMNTMasque1,nomMNTMasque2,sep=",")
            #---- Suppression des vecteurs intermédiaires
            cmd=paste0("g.remove --quiet -f type=vector name=",liste)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          }
        }else{
          cat("##################################################################\n")
          cat("Pas de masques","\n")
          nom_masque_vide=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque2.eau")
          write("VIDE",file.path(dsnlayer,NomDirMasque,racilayerTA,nom_masque_vide))
          
          #---- Suppression des rasters intermédiaires
          if (Nettoyage==1)
          {
            liste=paste(nomMNT,nomMNTMasque1,sep=",")
            cmd=paste0("g.remove --quiet -f --quiet type=raster name=",liste)
            system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          }
        }
      }else{
        cat("##################################################################\n")
        cat("Pas de masques","\n")
        nom_masque_vide=paste0(substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4),"_Masque2.eau")
        write("VIDE",file.path(dsnlayer,NomDirMasque,racilayerTA,nom_masque_vide))
        if (Nettoyage==1)
        {
          cmd=paste0("g.remove --quiet -f --quiet type=raster name=",nomMNT)
          system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        }
      }
      
      if (Nettoyage==1)
      {
        unlink(nomjson)
        unlink(nom_Rast)
        if (PDAL_EAU==1)
        {
          unlink(nom_RastEAU)
          unlink(nom_RastSOL)
        }
      }
    }
  }
