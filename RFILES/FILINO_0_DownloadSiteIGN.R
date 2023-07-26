# LidarHD_IGN
# Site https://geoservices.ign.fr/lidarhd
library(sf)
# Il faut créer un champ Chargement dans qgis et mettre 0 pour ceux que l'on veut charger
destfileRaci="F:\\LidarHD_DC\\LAZ"
dsnlayerLidar="F:\\LidarHD_DC\\0_0_TA_IGN_7z"
nomTA="TA_diff_pkk_lidarhd_classe.shp"
TA=st_read(file.path(dsnlayerLidar,nomTA))

TA=TA[which(TA$Chargement==0),]

for (inc in 1:dim(TA)[1])
{
  url=TA[inc,]$url_telech
  
  
  nomf=TA[inc,]$nom_pkk
  if (substr(nomf,nchar(nomf)-8,nchar(nomf))==".copc.laz")
  {
  }else{
    nomf=paste0(substr(nomf,1,nchar(nomf)-4),".copc.laz")
  }
  
  destfile=file.path(destfileRaci,
                     nomf)
  
  if (file.exists(destfile)==F)
  {
    cat("Nouveau",url,"\n")
    try(download.file(url, destfile, method="curl", quite =TRUE))
    # try(download.file(url, destfile, quite =TRUE))
    test=file.info(destfile)
    if (test$size<1000){unlink(destfile)}
    # download.file(url, destfile,mode="wb")
  }else{
    cat("Present",url,"\n")
  }
}
