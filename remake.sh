#!/bin/bash
cd ..
make distclean; ./configure --prefix= --enable-json --enable-debugg && make
#make distclean; ./configure --prefix= --enable-json && make
#cp ~/srv_emulate_2.sh ./test/

