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
  
  FILINO_Creat_Dir(file.path(dsnlayerTA,"LAZ"))
  
  for (inc in 1:dim(TA_SiteIGN_tmp)[1])
  {
    url=TA_SiteIGN_tmp[inc,]$url_telech
    
    nomf=TA_SiteIGN_tmp[inc,]$nom_pkk
    if (substr(nomf,nchar(nomf)-8,nchar(nomf))==".copc.laz")
    {
    }else{
      nomf=paste0(substr(nomf,1,nchar(nomf)-4),".copc.laz")
    }
    
    destfile=file.path(dsnlayerTA,"LAZ",
                       nomf)
    
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