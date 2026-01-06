# LidarHD_IGN Site https://geoservices.ign.fr/lidarhd

cat("\014")
cat("FILINO_01_00b_DownloadSiteIGN.R\n")
TA_SiteIGN=st_read(file.path(dsnlayerTA,nomTA_SiteIGN))

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA_SiteIGN,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA_SiteIGN_tmp=TA_SiteIGN[n_int,]
  
  # TA_SiteIGN=TA_SiteIGN[which(TA_SiteIGN$Chargement==0),]
  
  if (dim(TA_SiteIGN_tmp)[1]>0)
  {
    nomf=TA_SiteIGN_tmp$name[1]
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
    # url=TA_SiteIGN_tmp[inc,]$url_telech
    url=TA_SiteIGN_tmp[inc,]$url
    
    # nomf=TA_SiteIGN_tmp[inc,]$nom_pkk
    nomf=TA_SiteIGN_tmp[inc,]$name
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
}
# }