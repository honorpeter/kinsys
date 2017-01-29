synth:
	vivado -mode batch -source synth.tcl | sed -e '/^\#/d'

impl:
	vivado -mode batch -source impl.tcl | sed -e '/^\#/d'

build:
	vivado -mode batch -source build.tcl | sed -e '/^\#/d'

clean:
	rm -f *.log *.jou *.str
	rm -rf top reports results
	rm -f usage_*
