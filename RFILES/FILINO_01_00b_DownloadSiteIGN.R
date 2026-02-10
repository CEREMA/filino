# LidarHD_IGN Site https://geoservices.ign.fr/lidarhd

cat("\014")
cat("FILINO_01_00b_DownloadSiteIGN.R\n")
TA_SiteIGN=st_read(file.path(dsnlayerTA,nomTA_SiteIGN))

ZONE_=st_transform(ZONE,st_crs(TA_SiteIGN))

nom_exp_tmp1=file.path(dsnlayerTA,"Zone_Pour_Chargement.gpkg")
st_write(ZONE_,
         nom_exp_tmp1,
         delete_dsn=F,delete_layer=T,quiet=T)

# Limitation de la table d'assemblage aux zones à traiter
nom_exp_tmp2=file.path(dsnlayerTA,"Dalles_a_charger.csv")
cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
              " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
              " --INPUT=",file.path(dsnlayerTA,nomTA_SiteIGN),
              " --PREDICATE=0",
              " --JOIN=",nom_exp_tmp1,
              " --JOIN_FIELDS=IdGlobal --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
              " --OUTPUT=",nom_exp_tmp2)
system(cmd)

TA_SiteIGN_tmp=read.csv(nom_exp_tmp2)

if (dim(TA_SiteIGN_tmp)[1]>0)
{
  nomf=TA_SiteIGN_tmp$name_download[1]
  if (substr(nomf,nchar(nomf)-3,nchar(nomf))==".laz")
  {
    nomCharg="LAZ"
    
  }
  if (substr(nomf,nchar(nomf)-3,nchar(nomf))==".tif")
  {
    nomCharg="TIF"
  }   
  FILINO_Creat_Dir(file.path(dsnlayerTA,nomCharg))
}

for (inc in 1:dim(TA_SiteIGN_tmp)[1])
{
  url=TA_SiteIGN_tmp[inc,]$url
  
  # nomf=TA_SiteIGN_tmp[inc,]$nom_pkk
  if (nomCharg=="LAZ")
  {
    nomf=TA_SiteIGN_tmp[inc,]$name_download 
  }else{
    nomf=TA_SiteIGN_tmp[inc,]$name
  }
  if (substr(nomf,nchar(nomf)-3,nchar(nomf))==".laz")
  {
    if (substr(nomf,nchar(nomf)-8,nchar(nomf))==".copc.laz")
    {
    }else{
      nomf=paste0(substr(nomf,1,nchar(nomf)-4),".copc.laz")
    }
  }
  
  destfile=file.path(dsnlayerTA,nomCharg,nomf)
  
  cat(round(100*inc/dim(TA_SiteIGN_tmp)[1]),"% -",inc,"sur",dim(TA_SiteIGN_tmp)[1])
  if (file.exists(destfile)==F)
  {
    cat(" Nouveau",url,"\n")
    
    # # Nabil
    # cmd <- paste0("curl -# ",url," --output ",destfile)
    # print(paste0("Téléchargement de : ",destfile));system(cmd)
    
    # Vieille méthode
    try(download.file(url, destfile, method="curl", quite =TRUE))
    # try(download.file(url, destfile, quite =TRUE))
    test=file.info(destfile)
    if (is.na(test$size)==T)
    {
      {unlink(destfile)}
    }else{
      if (test$size<1000)
      {unlink(destfile)}  
    } 
    # download.file(url, destfile,mode="wb")
  }else{
    cat(" Present",url,"\n")
  }
}
cat("\n")
cat("\n")
cat("########################################################################################################\n")
cat("######################### FILINO A LIRE SVP ###############################################################\n")
cat("---------------- ETAPE FILINO_01_00b_DownloadSiteIGN.R #######################################\n")
cat("\n")
cat("Vous avez télécharger vos données\n")
cat("Passez aux étapes suivantes\n")
cat("\n")
cat("######################### Fin FILINO A LIRE ###############################################################\n")
cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
cat("\n")