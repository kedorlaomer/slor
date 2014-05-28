case $1 in
	*.zeit.de*)
	echo $1/komplettansicht
	echo $1
	;;
	
	*.faz.net*)
	echo $1'?printPagedArticle=true'
	echo $1
	;;

	faz.net*)
	echo $1'?printPagedArticle=true'
	echo $1
	;;

	*.handelsblatt.com*)
	echo $1 | sed s/.html$/-all.html/
	echo $1
	;;

	*)
	echo $1
	;;
esac
