# LidarHD_IGN Site https://geoservices.ign.fr/lidarhd
print(dsnlayerTA)
# cat("\014")

dosssortie="D:\\Filino_Pour_Nabil_Nimes"
dosssortie="D:\\Filino_Pour_Nassim_Mosson"
dosssortie="C:\\LidarNonHD"

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA_tmp=TA[n_int,]
  print(TA_tmp)
  liste_BDDLidar=list.files(dsnlayerTA,recursive=T)
  
  liste_Filino=list.files(dsnlayer,recursive = T)
  
  for (inom in TA_tmp$NOM)
  {
    print(inom)
    # Récupération des données LAZ
    
    nb1=which(basename(liste_BDDLidar)==inom)
    if (length(nb1)>0)
    {
      dir_export=file.path(dosssortie,"LIDAR",basename(dsnlayerTA))
      FILINO_Creat_Dir(file.path(dir_export,dirname(liste_BDDLidar[nb1])))
      if (file.exists(file.path(dir_export,liste_BDDLidar[nb1]))==F)
      {
        cat(liste_BDDLidar[nb1]," Copie\n")
        file.copy(file.path(dsnlayerTA,liste_BDDLidar[nb1]),
                  file.path(dir_export,liste_BDDLidar[nb1]))
      }else{   cat(liste_BDDLidar[nb1]," Présent\n")}
    }
    
    # récupération du travail FILINO
    
    lg=nchar(TA_tmp$NOM)-9
    compa=substr(inom,1,lg)
    
    nb2=which(substr(basename(liste_Filino),1,lg)==compa)
    
    for (iidoos in unique(dirname(liste_Filino[nb2])))
    {
      FILINO_Creat_Dir(file.path(dosssortie,basename(dsnlayer),iidoos))
    }
    cat(liste_Filino[nb2][1]," copie\n")
    file.copy(file.path(dsnlayer,liste_Filino[nb2]),file.path(dosssortie,basename(dsnlayer),liste_Filino[nb2]))
  }
}
file.copy(nom_Manuel,file.path(dosssortie,basename(dsnlayer),basename(nom_Manuel)))
file.copy(file.path(dsnlayer,"BUG_Classif_LidarHDIGN.gpkg"),
          file.path(dosssortie,basename(dsnlayer),"BUG_Classif_LidarHDIGN.gpkg"))
