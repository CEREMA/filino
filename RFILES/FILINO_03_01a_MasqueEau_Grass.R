FILINO1a_Vide_Grass =   function(iLAZ,NomLaz,nom_Rast_INV_VIDEetEAU,nom_RastEAU,nom_RastSOL,SecteurGRASS,Nord,Sud,Est,Ouest)
{
  raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
  # Récupération du raster, création d'un masque inversé
  nomMNT=paste0("MNT",iLAZ)
  nomMNTEAU=paste0("MNTEAU",iLAZ)
  nomMNTSOL=paste0("MNTSOL",iLAZ)
  nom_masque=paste0(raci,"_masque")
  
  nombat="myscriptgrass.bat"
  
  # VIDE et EAU
  #################################################\n")
  if (file.exists(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_Rast_INV_VIDEetEAU))==T)
  {
    # Suppression du masque (s'il existe)
    # cmd=paste0("r.mask -r")
    # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Import du raster
    cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_Rast_INV_VIDEetEAU)," output=",nomMNT)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --quiet --overwrite raster=",nomMNT," n=",Nord," s=",Sud," e=",Est," w=",Ouest," res=",as.character(reso))
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
    # NomUnivar=file.path(dsnlayer,paste0(raci,"_runivarE1.txt"))
    # cmd=paste0("r.univar --quiet --overwrite map=",nomMNT," output=",NomUnivar)
    # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    #     #Lancement GRASS externe
    # # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    # nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
    # unlink(NomUnivar)
    
    # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
    cmd=paste0("r.univar --quiet --overwrite map=",nomMNT)
    print(cmd);toto=system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd),intern=T)
    nlig=grep(toto,pattern="n: ")[1]
    nvaleur=as.numeric(strsplit(toto[nlig],":")[[1]][2])
    cat(toto[nlig],"\n")
    cat("Nombre de valeur: ",nvaleur, "\n")
    
    # S'il y a plus d'une valeur non nulle...
    if (nvaleur>0)
    {
      # Création d'un masque inversé
      cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNT)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      nomMNTMasque1=paste0("MNT_Masque1_",iLAZ)
      # Creation d'un raster remplissant le masque inversé
      
      cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNTMasque1)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # # vérification qu'il y a un secteur touché
      # NomUnivar=file.path(dsnlayer,paste0(raci,"_runivarE2.txt"))
      # cmd=paste0("r.univar --quiet --overwrite map=",nomMNTMasque1," output=",NomUnivar)
      # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      #       # print(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec="."))
      # nvaleur2=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
      # unlink(NomUnivar)
      
      cmd=paste0("r.univar --quiet --overwrite map=",nomMNTMasque1)
      print(cmd);toto=system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd),intern=T)
      nlig=grep(toto,pattern="n: ")[1]
      nvaleur2=as.numeric(strsplit(toto[nlig],":")[[1]][2])
      cat(toto[nlig],"\n")
      cat("Nombre de valeur2: ",nvaleur2, "\n")
      
      # Suppression du masque
      cmd=paste0("r.mask -r")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      if (nvaleur2>0)
      {
        if (PDAL_EAU==1)
        {
          # Import du raster
          cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_RastEAU)," output=",nomMNTEAU)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Mise à la valeur 1
          nomMNTMasque1EAU=paste0("MNT_Masque1EAU_",iLAZ)
          cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomMNTMasque1EAU,"=if(",nomMNTEAU,">",-99,",1,null())")))
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          cmd=paste0("r.mask -r")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # maximum du masque 1 et EAU
          nomMNTMasque1etEAU=paste0("MNT_Masque1_et_EAU_",iLAZ)
          cmd=paste0("r.series --quiet --overwrite input=",nomMNTMasque1,",",nomMNTMasque1EAU," output=",nomMNTMasque1etEAU," method=maximum")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Création d'un masque inversé
          cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTMasque1etEAU)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Creation d'un raster remplissant le masque inversé
          nomMNTMasque1etEAUinv=paste0("MNT_Masque1_et_EAU_inv_",iLAZ)
          cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNTMasque1etEAUinv)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Suppression du masque
          cmd=paste0("r.mask -r")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Buffer sur le raster de 1 fois la résolution mise en paramètre 
          nomMNTMasque1etEAUinvBuf=paste0("MNT_Masque1_et_EAU_inv_buf_",iLAZ)
          cmd=paste0("r.buffer --quiet --overwrite input=",nomMNTMasque1etEAUinv," output=",nomMNTMasque1etEAUinvBuf," distance=",2^0.5*reso)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          
          # Création d'un masque inversé
          cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTMasque1etEAUinvBuf)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Creation d'un raster remplissant le masque inversé
          nomMNTMasque1etEAUinvBufinv=paste0("MNT_Masque1_et_EAU_inv_buf_inv",iLAZ)
          cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNTMasque1etEAUinvBufinv)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # Suppression du masque
          cmd=paste0("r.mask -r")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # maximum du masque 1 et EAU
          nomMNTMasque1etEAUfin=paste0("MNT_Masque1_et_EAU_fin_",iLAZ)
          cmd=paste0("r.series --quiet --overwrite input=",nomMNTMasque1,",",nomMNTMasque1etEAUinvBufinv," output=",nomMNTMasque1etEAUfin," method=maximum")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          nomMNTMasque1=nomMNTMasque1etEAUfin
        }
        
        nomMNTMasque1Buf=paste0("MNT_Masque1_",iLAZ,"Buf")
        nomMNTMasque2=paste0("MNT_Masque2_",iLAZ)
        # Buffer sur le raster de deux fois la résolution mise en paramètre 
        cmd=paste0("r.buffer --quiet --overwrite input=",nomMNTMasque1," output=",nomMNTMasque1Buf," distance=",2*reso)
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        # Raster buffre mis  à 1
        cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomMNTMasque2,"=if(",nomMNTMasque1Buf,">",-99,",1,null())")))
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        if (PDAL_EAU==1)
        {
          # Import du raster
          cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_RastSOL)," output=",nomMNTSOL)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          # Création d'un masque inversé
          cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNTSOL)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        }
        # Conversion de masques et masque buffer en vecteur
        cmd=paste0("r.to.vect --quiet --overwrite input=",nomMNTMasque1," output=",nomMNTMasque1," type=area")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        # Suppression du masque
        if (PDAL_EAU==1)
        {
          cmd=paste0("r.mask -r")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        }
        cmd=paste0("r.to.vect --quiet --overwrite input=",nomMNTMasque2," output=",nomMNTMasque2," type=area")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        # cela peut planter s'il n'y a pas un seul trou dans une dalle, il faudrait vérifier avec le nombre de pixel... r.univar
        
        #######################################################################
        ## IL MANQUE UN NETTOYAGE DES PIXELS ISOLES POUR LE LIDAR 2D AVEC UN NEIGHBORS ET IL EN FAUT 4
        ## A GARDER POUR LA SUITE
        #######################################################################
        
        
        # export si nettoyage =0
        FILINO_Creat_Dir(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA))
        
        cat("##################################################################\n")
        nom_masque_gpkg=paste0(raci,"_Masque1.gpkg")
        cat("Export des masques",nom_masque_gpkg,"\n")
        cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNTMasque1," output=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_masque_gpkg)," format=GPKG")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        nom_masque_gpkg=paste0(raci,"_Masque2.gpkg")
        cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNTMasque2," output=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_masque_gpkg)," format=GPKG")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        if (Nettoyage==1)
        {
          liste=ifelse(PDAL_EAU==1,
                       paste(nomMNT,paste0("MNT_Masque1_",iLAZ),nomMNTEAU,nomMNTMasque1EAU,nomMNTMasque1etEAU,nomMNTSOL,
                             nomMNTMasque1etEAUinv,nomMNTMasque1etEAUinvBuf,nomMNTMasque1etEAUinvBufinv,nomMNTMasque1etEAUfin,
                             nomMNTMasque1,nomMNTMasque1Buf,nomMNTMasque2,sep=","),
                       paste(nomMNT,nomMNTMasque1,nomMNTMasque1,nomMNTMasque1Buf,nomMNTMasque2,sep=","))
          #---- Suppression des rasters intermédiaires
          cmd=paste0("g.remove --quiet -f type=raster name=",liste)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          liste=paste(nomMNTMasque1,nomMNTMasque2,sep=",")
          #---- Suppression des vecteurs intermédiaires
          cmd=paste0("g.remove --quiet -f type=vector name=",liste)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        }
      }else{
        cat("##################################################################\n")
        cat("Pas de masques","\n")
        nom_masque_vide=paste0(raci,"_Masque2.eau")
        write("VIDE",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_masque_vide))
        
        #---- Suppression des rasters intermédiaires
        if (Nettoyage==1)
        {
          liste=paste(nomMNT,nomMNTMasque1,sep=",")
          cmd=paste0("g.remove --quiet -f --quiet type=raster name=",liste)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        }
      }
    }else{
      cat("##################################################################\n")
      cat("Pas de masques","\n")
      nom_masque_vide=paste0(raci,"_Masque2.eau")
      write("VIDE",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_masque_vide))
      if (Nettoyage==1)
      {
        cmd=paste0("g.remove --quiet -f --quiet type=raster name=",nomMNT)
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      }
    }
    
    # Réalisation des minimum "SOL et EAU" et "INV_VIDEetEAU et EAU"
    CalcMini=rbind(
      cbind(nomMNTSOL,nomMNTEAU,"_SOLetEAU_min"),
      cbind(nomMNT   ,nomMNTEAU,"_TOUT_min")
    )
    
    for (imini in 1:2)
    {
      nomMNTMasque1etEAU=paste0("MNT_Masque1_et_EAU_",iLAZ)
      nomMini="CalculMini"
      nomoutput=file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles, paste0(raci,CalcMini[imini,3],".gpkg"))
      
      cmd=paste0("r.series --quiet --overwrite input=",CalcMini[imini,1],",",CalcMini[imini,2]," output=",nomMini," method=minimum")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      cmd=paste0("g.region --overwrite --quiet"," zoom=",nomMini)
      cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomMini," output=",nomoutput," type=Float32 format=GPKG nodata=-9999")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    }
    
    if (Nettoyage==1)
    {
      
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_Rast_INV_VIDEetEAU))
      if (PDAL_EAU==1)
      {
        unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_RastEAU))
        unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_RastSOL))
      }
    }
  }
}
