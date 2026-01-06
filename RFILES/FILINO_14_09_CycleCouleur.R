# chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
# nompalcoul=file.path(chem_routine,"couleurpourpalette.csv")
# Mini=-50
# Maxi=1000
# PasDz=c(0.1,0.2,0.5,1)

Couleur=read.table(nompalcoul,sep=";")
Ncouleur=dim(Couleur)[1]-2;#20

for (iPasDz in PasDz)
{
  Cycli=Ncouleur*iPasDz
  
  nompalette=file.path(chem_routine,paste0("PaletteFILINO","_Mini",Mini,"_Maxi",Maxi,"_Pas",iPasDz,".txt"))
  
  write("# Fichier d'export QGIS de palette de couleur",nompalette)
  write("INTERPOLATION:DISCRETE",nompalette,append=T)
  write(paste0(Mini,",",Couleur[1,1],",",Couleur[1,2],",",Couleur[1,3],",255,<= ",Mini),nompalette,append=T)
  
  cat(iPasDz, " \n")
  for (icycle in seq(Mini,Maxi-Cycli,Cycli))
  {
    for (icoul in 0:(Ncouleur-1))
    {
      
      # cat(icycle, " " ,icoul,"\n")
      deb=icycle+icoul*Cycli/Ncouleur
      fin=icycle+(icoul+1)*Cycli/Ncouleur
      write(paste0(icycle+icoul*Cycli/Ncouleur,",",Couleur[icoul+2,1],",",Couleur[icoul+2,2],",",Couleur[icoul+2,3],",255,",deb," - ",fin),nompalette,append=T)
    }
  }
  write(paste0("inf",",",Couleur[Ncouleur+2,1],",",Couleur[Ncouleur+2,2],",",Couleur[Ncouleur+2,3],",255,> ",Maxi),nompalette,append=T)
}
# Exemple de fichier couleurpourpalette.csv
# 48	18	59
# 61	54	140
# 68	87	201
# 71	119	239
# 65	150	255
# 46	180	242
# 27	208	213
# 27	229	181
# 55	244	146
# 100	253	106
# 146	255	71
# 180	248	54
# 211	232	53
# 235	210	57
# 251	185	56
# 254	153	44
# 249	117	29
# 236	82	15
# 217	56	7
# 191	34	2
# 159	16	1
# 122	4	3
