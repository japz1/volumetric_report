#!/bin/bash

#cd $1

echo 'v:volume uv:unnormalised-volume'
echo 'carpeta  VSCALING  v-grey    uv-grey   v-white   uv-white  v-brain    uv-brain '

	
#se corre sienax
echo "$2/output_sienax"
sienax $1 -B "-f 0.42" -r -o "$2/output_sienax"

# se mete en el archivo de reporte generado por sienax

#-----------------------------------
#obtener información de un fichero de texto, este fichero tiene la 
#información de los resultados de sienax en el fichero report.sienax

#factor de escala. se busca una linea que contega la direccion VSCALING
#y guarda la salida de la columna 2 de esa fila
scale_factor=`awk '/VSCALING/ {print $2}' $2/output_sienax/report.sienax` 

# volumenes
vol_GREY=`awk '/GREY/ {print $2}' $2/output_sienax/report.sienax`
vol_u_GREY=`awk '/GREY/ {print $3}' $2/output_sienax/report.sienax`
vol_WHITE=`awk '/WHITE/ {print $2}' $2/output_sienax/report.sienax`
vol_u_WHITE=`awk '/WHITE/ {print $3}' $2/output_sienax/report.sienax`
vol_BRAIN=`awk '/BRAIN/ {print $2}' $2/output_sienax/report.sienax`
vol_u_BRAIN=`awk '/BRAIN/ {print $3}' $2/output_sienax/report.sienax`
vol_pgrey=`awk '/pgrey/ {print $2}' $2/output_sienax/report.sienax`
vol_u_pgrey=`awk '/pgrey/ {print $3}' $2/output_sienax/report.sienax`
vol_vcsf=`awk '/vcsf/ {print $2}' $2/output_sienax/report.sienax`
vol_u_vcsf=`awk '/vcsf/ {print $3}' $2/output_sienax/report.sienax`

volumenes=$scale_factor","$vol_GREY","$vol_u_GREY","$vol_pgrey","$vol_u_pgrey","$vol_WHITE","$vol_u_WHITE","$vol_BRAIN","$vol_u_BRAIN","$vol_vcsf","$vol_u_vcsf
echo $volumenes

#-----------------------------------

#Se crea el reporte .txt de todos los volumenes solo una vez
	
echo 'VSCALING,v-grey,uv-grey,v-pgrey,vu-pgrey,v-white,uv-white,v-brain,uv-brain,v-vcsf,vu-vcsf' >> $2/reporte_volumenes_sienax.csv

#Se guarda los resultados del sienax en el fichero
echo $volumenes>>$2/output_sienax/reporte_volumenes_sienax.csv #guarda en un fichero

echo "listo!"
