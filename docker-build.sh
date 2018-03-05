#!/bin/bash

set -euo pipefail
basedir=$(pwd)

cp ./lumpy-smoother /usr/local/bin
cp ./smoove /usr/local/bin
chmod +x /usr/local/bin/lumpy-smoother
chmod +x /usr/local/bin/smoove

# used by Dockerfile
apt-get update
apt-get -qy install \
    zlib1g-dev \
    make build-essential cmake libncurses-dev ncurses-dev g++ gcc \
    python python-dev python-pip nfs-common \
    pigz bedtools gawk curl fuse wget git mdadm time \
    libbz2-dev lzma-dev liblzma-dev \
    syslog-ng libssl-dev libtool autoconf automake \
    libcurl4-openssl-dev libffi-dev libblas-dev liblapack-dev libatlas-base-dev

git clone --recursive https://github.com/samtools/htslib.git
git clone --recursive https://github.com/samtools/samtools.git
git clone --recursive https://github.com/samtools/bcftools.git
cd htslib && git checkout 1.7 && autoheader && autoconf && ./configure --enable-libcurl
cd .. && make -j4 -C htslib install
cd $basedir
cd samtools && git checkout 1.7
autoreconf && ./configure && make -j4 install
cd $basedir && cp ./samtools/samtools /usr/local/bin/

cd bcftools && git checkout 1.6
make -j4
cp ./bcftools /usr/local/bin
cd $basedir

wget -qO /usr/bin/batchit https://github.com/base2genomics/batchit/releases/download/v0.4.1/batchit
chmod +x /usr/bin/batchit

pip install -U awscli cython slurmpy toolshed awscli-cwlogs pyvcf pyfaidx cyvcf2 pip

git clone https://github.com/hall-lab/svtyper
cd svtyper && python setup.py install

wget -qO /usr/local/bin/mosdepth https://github.com/brentp/mosdepth/releases/download/v0.2.1/mosdepth
chmod +x /usr/local/bin/mosdepth
wget -qO /usr/bin/gsort https://github.com/brentp/gsort/releases/download/v0.0.6/gsort_linux_amd64
chmod +x /usr/bin/gsort

wget -qO /usr/bin/gargs https://github.com/brentp/gargs/releases/download/v0.3.9/gargs_linux
chmod +x /usr/bin/gargs

git clone --single-branch --recursive --depth 1 https://github.com/arq5x/lumpy-sv
cd lumpy-sv
make -j 3
cp ./bin/* /usr/local/bin/


apt-get -qy install libroot-math-mathmore-dev                              
export CPLUS_INCLUDE_PATH=/usr/include/root/

## CNVnator stuffs
#git clone --depth 1 http://root.cern.ch/git/root.git
#mkdir root/ibuild
#cd root/ibuild
#cmake -D x11=OFF ../
#make -j4 install
#cd $basedir
#rm -rf root

# YEPP not working even after patching cnvnator. just stalls at partition step.
#cd /
#wget -q http://bitbucket.org/MDukhan/yeppp/downloads/yeppp-1.0.0.tar.bz2
#tar xjvf yeppp-1.0.0.tar.bz2
#rm yeppp-1.0.0.tar.bz2
#export LD_LIBRARY_PATH=/yeppp-1.0.0/binaries/linux/x86_64/
#echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /etc/bash.bashrc
#echo "/yeppp-1.0.0/binaries/linux/x86_64/" >> /etc/ld.so.conf

cd $basedir

git clone --depth 1 -b stdin https://github.com/brentp/CNVnator
cd CNVnator
pwd
ln -s $basedir/samtools/ .
ln -s $basedir/htslib/ .
#make -j4 HTSDIR=htslib/ LIBS="-llzma -lbz2 -lz -lcurl -lssl -lcrypto" YEPPPLIBDIR=$basedir/yeppp-1.0.0/binaries/linux/x86_64/ YEPPPINCLUDEDIR=$basedir/yeppp-1.0.0/library/headers
make -j4 HTSDIR=htslib/ LIBS="-llzma -lbz2 -lz -lcurl -lssl -lcrypto"

cp ./cnvnator /usr/local/bin
cd $basedir
rm -rf CNVnator
rm -rf lumpy-sv
rm -rf bcftools

ldconfig

rm -rf /var/lib/apt/lists/*
