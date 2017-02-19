RAND = ruby ../utils/rand.rb

data:
	$(RAND) 1024 > ../data/renkon/input_linebuf.dat
	$(RAND) 25000 > ../data/renkon/input_conv_tree25.dat
	$(RAND) 25000 > ../data/renkon/filter_conv_tree25.dat

compile:
	(cd gobou; make)
	(cd renkon; make)

