# filino
FILINO Fignolage des données LIdar pour les INOdations

## Version
1er référencement

## Contenu du dossier
Code source en langage R nommée FILINO_xxx.R
Rapport d'étude "FILINO - FILINO Fignolage des données LIdar pour les INOdations - Juin 2023 - Version dépôt Agence de Protection des Programmes"

## Objet de FILINO
Le programme LidarHD porté par l’IGN vise à couvrir la France entière avec des données topographiques de précision d’ici 2025 (https://geoservices.ign.fr/lidarhd).
Les routines FILINO permettent d'automatiser le calcul des limites Terre/Eau sur 4 grands types d'objets, la mer, les plans d'eau, les canaux et les grands cours d'eau, travail chronophage souvent réalisé par des opérateurs.
Des ébauches d’idées pour le travail sur les fonds de thalwegs secs sont aussi présentes.
Les Lidar anciens peuvent aussi être utilisés pour combler les manques du LidarHD sous fort couvert végétal.
Les résultats de FILINO sont la réalisation de points virtuels numérotés en fonction des types d'objets traités (mer, plans d'eau, canaux, grands cours d'eau, petits cours d'eau, souscouvertvégétal).
L'ajout des points virtuels FILINO aux points Lidar initiaux classifiés permet d'augmenter grandement la qualité du MNT final en particulier pour les inondations.
