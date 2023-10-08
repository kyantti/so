echo "Introduce el nombre del fichero para visualizarlo"
read file
if test -f $file
then cat $file
else echo "El fichero no existe"
fi
