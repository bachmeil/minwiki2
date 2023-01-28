app:
	ldmd2 wiki.d markdown/*.d cgi.d
	mv wiki ~/bin/wiki
	rm *.o
