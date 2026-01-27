dsnlayer=("J:\\SMMAR_Orb2D")
dsnlayer_exp=("J:\\NIMES")

dsnlayer=("J:\\NIMES")
dsnlayer_exp=("J:\\MAMP")

listDossFILINO=list.files(dsnlayer,recursive=T)
listDossFILINOIni=listDossFILINO

listDossFILINO=listDossFILINOIni
nombase=basename(listDossFILINO)

############################################
# Cas où on copie en fonction des abscisses
CasAbs=0
if (CasAbs==1)
{
  Absc=as.numeric(substr(nombase,9,12))
  nb=which(is.na(Absc)==F)
  Absc=Absc[nb]
  listDossFILINO=listDossFILINO[nb]
  nb=which(Absc>768)
  listDossFILINO=listDossFILINO[nb]
}

############################################
# Cas où on copie en fonction du NOM
CasNOM=1
if (CasNOM==1)
{
  browser()
  nb=grep(nombase,pattern="MAMP")
  listDossFILINO=listDossFILINO[nb]
}

for (idir in unique(dirname(listDossFILINO)))
{
  dir.create(file.path(dsnlayer_exp,idir),recursive=T)
}
browser()
file.rename(file.path(dsnlayer,listDossFILINO),file.path(dsnlayer_exp,listDossFILINO))
