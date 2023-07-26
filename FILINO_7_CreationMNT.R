library("sf")

# Initialisation des chemins et variables
chem_routine = R.home(component = "cerema")
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))

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
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  reso=as.numeric(resoTALidar[iTA])
  
  TAHDCla=st_read(file.path(dsnlayerTA,nomlayerTA))
  
  TAPtsVirtu=st_read(file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")))
  
  listeMasq2=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("Masques2_Seuil",seuilSup1,"m2",".gpkg"))
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
  Masques2=st_read(file.path(dsnlayer,NomDirMasque,racilayerTA,listeMasq2[1]))
  # On ne garde que les masques 2 en bord de mer! pour un nettoyage
  Masques2=Masques2[which(substr(Masques2$FILINO,1,3)=="Mer"),]
  
  nb=st_intersects(TAHDCla,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TAHDCla=TAHDCla[n_int,]
    
    for (idalle in 1:dim(TAHDCla)[1])
    {
      print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
      racidalle=TAHDCla[idalle,]$NOM
      racidalle=substr(racidalle,1,nchar(racidalle)-4)  
      cat(racidalle)
      NomTIF=file.path(dsnlayer,NomDirMNT,racilayerTA,paste0(racidalle,"_Cerema.tif"))
      
      if (file.exists(NomTIF)==T)
      {
        cat(" déjà fait","\n")
      }else{
        cat("Procédure PDAL","\n")
        
        Tampon=st_buffer(TAHDCla[idalle,1],100)
        Polygon_Contour_CE=st_as_text(st_geometry(Tampon))
        
        # Intersection entre cette dalle et la table initiale
        # Selection des sections dans le Lidar
        nb=st_intersects(TAHDCla,Tampon)
        n_intHD = which(sapply(nb, length)>0)
        print(TAHDCla[n_intHD,])
        
        # Intersection entre cette dalle et la table initiale
        # Selection des sections dans le Lidar
        nb=st_intersects(TAPtsVirtu,Tampon)
        n_intVirt = which(sapply(nb, length)>0)
        print(TAPtsVirtu[n_intVirt,])
        
        # Creation d'un pipeline pdal
        nomjson=file.path(dsnlayer,NomDirMNT,paste0(racidalle,"_Cerema.json"))
        NomLaz_tmp=file.path(dsnlayer,NomDirMNT,paste0(racidalle,"_Cerema.laz"))
        if (file.exists(file.path(dsnlayer,NomDirMNT,racilayerTA))==F){dir.create(file.path(dsnlayer,NomDirMNT,racilayerTA))}
        
        write("[",nomjson)
        
        ############### Import des fichiers Laz IGN
        for (NOMLAZ in file.path(TAHDCla[n_intHD,]$CHEMIN,TAHDCla[n_intHD,]$NOM))
        {
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
          write(paste0("       ",shQuote("filename"),":",shQuote(NOMLAZ),","),nomjson,append=T)
          write(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","),nomjson,append=T)
          write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
          write("    },",nomjson,append=T)
        } 
        
        ################ Import des fichiers Laz virtuels Cerema
        for (NOMLAZ in file.path(TAPtsVirtu[n_intVirt,]$CHEMIN,TAPtsVirtu[n_intVirt,]$NOM))
        {
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
          write(paste0("       ",shQuote("filename"),":",shQuote(NOMLAZ),","),nomjson,append=T)
          write(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","),nomjson,append=T)
          write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
          write("    },",nomjson,append=T)
        } 
        
        ############## On ne garde que les classification sol, les 60 et + de 'IGN et 80 et plus du Cerema
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        write(paste0("       ",shQuote("limits"),":",shQuote("Classification[2:2],Classification[66:66],Classification[81:90]")),nomjson,append=T)
        write("    },",nomjson,append=T)
        
        ############# Fusion des fichiers
        if ((length(n_intHD)+length(n_intVirt))>1)
        {
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
          write("    },",nomjson,append=T)
        }
        
        ############# Découpage à 100m autour
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
        write(paste0("       ",shQuote("polygon"),":",shQuote(Polygon_Contour_CE)),nomjson,append=T)
        write("    },",nomjson,append=T)
        
        ############### Filtre delaunay
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.delaunay")),nomjson,append=T)
        write("    },",nomjson,append=T)
        
        ############## Interpolation
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.faceraster"),","),nomjson,append=T)
        write(paste0("       ",shQuote("resolution"),":",reso,","),nomjson,append=T) 
        write(paste0("       ",shQuote("width"),":",1000/reso,","),nomjson,append=T) 
        write(paste0("       ",shQuote("height"),":",1000/reso,","),nomjson,append=T) 
        Boite=st_bbox(TAHDCla[idalle,])
        write(paste0("       ",shQuote("origin_x"),":",Boite[1],","),nomjson,append=T) 
        write(paste0("       ",shQuote("origin_y"),":",Boite[2]),nomjson,append=T) 
        write("    },",nomjson,append=T)
        
        ################# Export
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.raster"),","),nomjson,append=T)
        write(paste0("       ",shQuote("gdaldriver"),":",shQuote("GTiff"),","),nomjson,append=T)
        write(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","),nomjson,append=T)  
        write(paste0("       ",shQuote("filename"),":",shQuote(NomTIF)),nomjson,append=T)
        write("    }",nomjson,append=T)
        write("]",nomjson,append=T)
        cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
        
        system(cmd)
        avoir=1
        if (Nettoyage==1){unlink(nomjson)}
        
        # Gestion du bord de mer si nécesaire
        if (dim(Masques2)[1]>0)
        {
          nbMasq=st_intersects(Masques2,TAHDCla[idalle,])
          
          n_intMasq = which(sapply(nbMasq, length)>0)
          if (length(n_intMasq)>0)
          {
            MasqMer=Masques2[n_intMasq,]
            if (dim(MasqMer)[1]>1){browser()}# gérer plusieurs niveaux marins sur une même dalle à supprimer!
            nomType=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,MasqMer$IdGlobal),"Type_Mer.txt")
            if (file.exists(nomType)==T & file.exists(NomTIF)==T)
            {
              # Lecture de l'altitiude de la mer
              Val=read.csv(nomType,header = F)
              
              source(file.path(chem_routine,"FILINO_7_CreationMNT_Grass.R"),encoding = "utf-8")
              FILINO_7_CreationMNT_Grass(NomTIF,Val,reso)
            }
          }
        }
      }
    }
  }
}