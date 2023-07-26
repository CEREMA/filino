# Initialisation des chemins et variables
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))
# Initialisation des chemins et variables
unlink(dirname(SecteurGRASS),recursive=TRUE)
system(paste0(BatGRASS," -c EPSG:2154 ",dirname(SecteurGRASS)," --text"))
system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))

if (exists("I_Lidar")==F){I_Lidar=c(3,5)}

Classe_Old=10
Classe_New=88

# Recuperation des parametres de la table d'assemblage LidarHD
dsnTALidarHDCla =paramTALidar[I_Lidar[1],2]
nomTALidarHDCla =paramTALidar[I_Lidar[1],3]
resoTALidarHDCla=paramTALidar[I_Lidar[1],4]
reso=2*as.numeric(resoTALidarHDCla)
paramXYTALidarHDCla=paramTALidar[I_Lidar[1],5:9]
raciTALidarHDCla=substr(nomTALidarHDCla,1,nchar(nomTALidarHDCla)-4)
# Lecture de la table d'assemblage LidarHD
TAHDCla=st_read(file.path(dsnTALidarHDCla,nomTALidarHDCla))

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TAHDCla,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  cat("##################################################################\n")
  cat("Travail sur la TAHDCla:",file.path(dsnTALidarHDCla,nomTALidarHDCla),"\n")
  cat("##################################################################\n")
  
  TAHDCla=TAHDCla[n_int,]
  
  # # Recuperation des parametres de la table d'assemblage NUALID ou 2 pts/m²
  dsnTALidarOld =paramTALidar[I_Lidar[2],2]
  nomTALidarOld =paramTALidar[I_Lidar[2],3]
  # Lecture de la table d'assemblage LidarHD
  TA_Old=st_read(file.path(dsnTALidarOld,nomTALidarOld))
  
  nb=st_intersects(TAHDCla,TA_Old)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TAHDCla=TAHDCla[n_int,]
    
    # Boucle sur les fichiers Laz
    for (iLAZ in 1:dim(TAHDCla)[1])
    {
      # Gestion des noms de champs de mes tables d'assemblage
      TAHDCla_tmp=TAHDCla[iLAZ,]
      if (is.null(TAHDCla_tmp$CHEMIN))
      {
        # Lidar Hd brut
        NomLaz=basename(file.path(dsnTALidarHDCla,TAHDCla_tmp$DOSSIER,TAHDCla_tmp$NOM))
        ChemLaz=dirname(file.path(dsnTALidarHDCla,TAHDCla_tmp$DOSSIER,TAHDCla_tmp$NOM))
      }else{
        # Lidar HD classif
        NomLaz=TAHDCla_tmp$NOM
        ChemLaz=TAHDCla_tmp$CHEMIN
      }
      raci=paste0(substr(NomLaz,1,nchar(NomLaz)-4))
      
      NomFinal_Laz_tmp= file.path(dsnlayer,NomDirForet,raciTALidarHDCla,paste0(raci,"_SolSsVegDens_PtsVirt.laz"))
      
      if (file.exists(NomFinal_Laz_tmp)==F)
      {
        cat("###############################################################\n")
        cat("TAHDCla"," - Passage R",iLAZ,"sur", dim(TAHDCla)[1],"\n")
        cat(ChemLaz,"\n")
        cat(NomLaz,"\n")
        cat("###############################################################\n")
        ChemNomLaz=file.path(ChemLaz,NomLaz)
        
        # Recupération des limites
        Ouest=largdalle*as.numeric(substr(NomLaz,paramXYTALidarHDCla[2],paramXYTALidarHDCla[3]))
        Nord=largdalle*as.numeric(substr(NomLaz,paramXYTALidarHDCla[4],paramXYTALidarHDCla[5]))
        Est=as.character(Ouest+largdalle)
        Sud=as.character(Nord-largdalle)
        Ouest=as.character(Ouest)
        Nord=as.character(Nord)
        
        #ToutSaufVegetation
        nom_method="min"
        
        nom_Rast1=paste0(raci,"_","ToutSaufVege",".tif")
        setwd(ChemLaz)
        nomjson=paste0(raci,"_MyScript.json")
        NomLaz_tmp=NomLaz
        write("[",nomjson)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","),nomjson,append=T)
        write(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","),nomjson,append=T)
        write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        #### différence par rapport au prochain si on veut faire des fonctions pour optimiser le code
        write(paste0("       ",shQuote("limits"),":",shQuote("Classification[1:2],Classification[6:100]")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","),nomjson,append=T)
        write(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","),nomjson,append=T)
        write(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","),nomjson,append=T)
        write(paste0("       ",shQuote("resolution"),": ",reso,","),nomjson,append=T)
        write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est)-reso,"],[",Sud,",",as.numeric(Nord)-reso,"])")),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(nom_Rast1)),nomjson,append=T)
        write("    }",nomjson,append=T)
        write("]",nomjson,append=T)
        
        cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
        system(cmd)
        if (Nettoyage==1){unlink(nomjson)}
        
        #HorsForet
        nom_method="min"
        raci=paste0(substr(NomLaz,1,nchar(NomLaz)-4))
        nom_Rast2=paste0(raci,"_","Vege",".tif")
        setwd(ChemLaz)
        nomjson=paste0(raci,"_MyScript.json")
        NomLaz_tmp=NomLaz
        write("[",nomjson)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","),nomjson,append=T)
        write(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","),nomjson,append=T)
        write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        write(paste0("       ",shQuote("limits"),":",shQuote("Classification[3:5]")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","),nomjson,append=T)
        write(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","),nomjson,append=T)
        write(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","),nomjson,append=T)
        write(paste0("       ",shQuote("resolution"),": ",reso,","),nomjson,append=T)
        write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",Ouest,",",as.numeric(Est)-reso,"],[",Sud,",",as.numeric(Nord)-reso,"])")),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(nom_Rast2)),nomjson,append=T)
        write("    }",nomjson,append=T)
        write("]",nomjson,append=T)
        
        cmd=paste("C:\\OSGeo4W\\bin\\pdal.exe pipeline",nomjson)
        system(cmd)
        if (Nettoyage==1){unlink(nomjson)}
        
        if (file.exists(file.path(ChemLaz,nom_Rast1))==T)
        {
          source(file.path(chem_routine,"FILINO_5a_SolVieuxLazSousVege_Grass.R"),encoding = "utf-8")
          # nommasqueveget=withr::with_envvar(new = list_env,code = FILINO5a_Grass(iLAZ))
          nommasqueveget=FILINO5a_Grass(iLAZ)
          if (Nettoyage==1)
          {
            unlink(nomjson)
            unlink(nom_Rast1)
            unlink(nom_Rast2)
          }
          
          ###### Liaison pour aller récupérer les points sol des vieux Lidar
          nb=st_intersects(TA_Old,st_buffer(TAHDCla_tmp,-10))
          n_int = which(sapply(nb, length)>0)
          if (length(n_int)>0)
          {
            TA_Old_tmp=TA_Old[n_int,]
            NomOld=file.path(TA_Old_tmp$CHEMIN,TA_Old_tmp$NOM)
            
            tampon=st_union(st_read(nommasqueveget))
            
            Polygon_Contour=st_as_text(st_geometry(tampon))
            
            nomjson=    file.path(dsnlayer,NomDirForet,raciTALidarHDCla,paste0(raci,"_VegeTropDense.json"))
            NomLaz_tmp= file.path(dsnlayer,NomDirForet,raciTALidarHDCla,paste0(raci,"_SolSsVegDens_PtsVirt.laz"))
            cat("###############################################################\n")
            print(NomLaz_tmp)
            write("[",nomjson)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(NomOld),","),nomjson,append=T)
            write(paste0("       ",shQuote("override_srs"),":",shQuote("EPSG:2154"),","),nomjson,append=T)
            write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
            write(paste0("       ",shQuote("limits"),":",shQuote("Classification[2:2],Classification[10:10]")),nomjson,append=T) # 2 pour Lidar2m nimes et 10 pour NUALID, on s'y perd...
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
            write(paste0("       ",shQuote("polygon"),":",shQuote(Polygon_Contour)),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.assign"),","),nomjson,append=T)
            # write(paste0("       ",shQuote("assignment"),":",shQuote("Classification[10:10]=88"),","),nomjson,append=T)
            write(paste0("       ",shQuote("assignment"),":",shQuote(paste0("Classification[",Classe_Old,":",Classe_Old,"]=",Classe_New))),nomjson,append=T)
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
          }
        }
        
      }else{
        cat("déjà fait ",NomFinal_Laz_tmp,"\n")
      }
    }
  }
}