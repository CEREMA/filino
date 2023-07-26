# FILINO
FILINO FIgnolage des données Lidar pour les INOdations

## Version
1er référencement

## Contenu
Code source en langage R nommée FILINO_xxx.R

Voir les releases pour des docs de présentations
Rapport d'étude "FILINO - FILINO Fignolage des données LIdar pour les INOdations - Juillet 2023"
Présentation club Modélisation Juin 2023
Vidéo Hérault

## Objet de FILINO
Le programme LidarHD porté par l’IGN vise à couvrir la France entière avec des données topographiques de précision d’ici 2025 (https://geoservices.ign.fr/lidarhd).
Les routines FILINO permettent d'automatiser le calcul des limites Terre/Eau sur 4 grands types d'objets, la mer, les plans d'eau, les canaux et les grands cours d'eau, travail chronophage souvent réalisé par des opérateurs.
Des ébauches d’idées pour le travail sur les fonds de thalwegs secs sont aussi présentes.
Les Lidar anciens peuvent aussi être utilisés pour combler les manques du LidarHD sous fort couvert végétal.
Les résultats de FILINO sont la réalisation de points virtuels numérotés en fonction des types d'objets traités (mer, plans d'eau, canaux, grands cours d'eau, petits cours d'eau, souscouvertvégétal).
L'ajout des points virtuels FILINO aux points Lidar initiaux classifiés permet d'augmenter grandement la qualité du MNT final en particulier pour les inondations.

## Description
Ce dépôt contient l’ensemble des scripts R pour faire tourner FILINO.

FILINO pour « FIgnolage des données Lidar pour les INONDations » rassemble des routines permettant d'automatiser le calcul des limites Terre/Eau à partir de Lidar classifié.
4 grands types d'objets, la mer, les plans d'eau, les canaux et les grands cours d'eau sont actuellement traités.
Des ébauches d’idées pour le travail sur les fonds de thalwegs secs sont aussi présentes mais non abouties.

FILINO est développé dans le cadre de l'ANR MUFFINS (Projet-ANR-21-CE04-0021) et des conventions de R&D dans le cadre du PAPI 3 sur le Vistre (Secteur de Nîmes), de l’expérimentation de la cartographie Nationale pour les inondations (DGPR).

FILINO a fait l'objet d'un dépôt à l'Agence de Protection des Programmes (APP) en Juin 2023:
https://secure2.iddn.org/app.server/certificate/?sn=2023240031000&key=f1b340d417b4cbd12af52d26f7bdacee869d9477484e00c394e699e761733d67&lang=fr).

L'originalité vient de l’automatisation de ces calculs terre/mer s'appuyant sur la création de masques de vides, d'eau, de sol issus de la classification du LidarHD.

D’autres applications comme la gestion de plusieurs sources de Lidar, l’interpolation des nuages de points pour la réalisation du MNT sont aussi fournis mais ne présentent pas le même caractère innovant. 

Ces travaux sont issus de nombreux échanges avec l'IGN, de l'université Gustave Eiffel et de l’INRAE en particulier dans le cadre du programme LidarHD IGN (https://geoservices.ign.fr/lidarhd).

La configuration matérielle nécessaire est un PC Windows 10 – 8 à 16 Go RAM.

Il existe des dépendances par rapport à des librairies R, les logiciels PDAL, GRASS et Qgis.

La phase de développement est en cours, le dépôt sera amené à évoluer.
Cependant, les auteurs ne s’engagent pas à la prise en compte de demandes externes et ne sont pas responsables des données produites par des utilisateurs.

Dernière mise à jour : 26/07/2023
