RTL_DIR=$(PWD)/../rtl
DESIGN=serial_vec

dc:
	#make link
	#make clock
	TMPDIR=~/tmp dc_shell -f ./dc.tcl | tee dc.log

pt:
	pt_shell -f ./pt.tcl | tee pt.log

nettran:
	nettran -verilog ./results/$(DESIGN).v \
	-cdl-a -cdl-s -sp-S -verilog-b1 VDD \
	-verilog-b0 VSS -rootCell $(DESIGN) \
	-sp /home/default/techlib/rohm18/rohm018lib/spice/ROHM18.sp \
	-outType spice -outName ./results/$(DESIGN).sp

link:
	ln -s $(RTL_DIR)/*.v .
	ln -s $(RTL_DIR)/*.vh .
	ln -s $(RTL_DIR)/*.rb .
	rm -f dep.rb

clock:
	rm -f *.const.tcl
	@for i in *.v; do \
		cp const.tcl `echo $i | awk -F . '{print $1 ".const.tcl"}'`; \
	done

clean:
	rm -f *.v *.vh *.rb
	rm -f *.pvl *.syn *.mr
	rm -f *.log *.svf
	rm -rf results reports
	rm -rf alib-*

