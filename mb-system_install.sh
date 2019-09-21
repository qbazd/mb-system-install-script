#!/bin/bash



required_packages_list="git ghostscript build-essential cmake libnetcdf-dev libgdal-dev libfftw3-dev libpcre3-dev"
#required_packages_list="build-essential cmake gdal-bin gdal-dev gfortran ghostscript git gv libfftw3-3 libfftw3-dev libfftw3-dev libgdal-dev libmotif-dev libmotif4 libnetcdf-dev libnetcdf-dev libpcre3-dev libsdl-image1.2-dev libsdl1.2-dev libxp-dev mesa-common-dev netcdf-bin xorg-dev "

MB_INSTALL_PREFIX=$HOME/mb-system
gmt_ver="5.4.5"
gshhg="gshhg-gmt-2.3.7"
dcw="dcw-gmt-1.1.4"
mb_system_ver="5.7.5"
GSHHG_PATH=$MB_INSTALL_PREFIX/gshhg
DCW_PATH=$MB_INSTALL_PREFIX/dcw
CDIR=`pwd`
INSTALLED_PKGS=`dpkg -s $required_packages_list 2>&1 >/dev/null && echo ok`

mkdir -p tmp 

echo "MB System user Install script by Jakub Zdroik 2019"
echo "MB-System $mb_system_ver"
echo "Install to: $MB_INSTALL_PREFIX"
echo "Enter to continue or Ctr+C to cancel"

read

if [ "$INSTALLED_PKGS" != "ok" ] ; then 
    echo "Install required libraries please"
    echo "# sudo apt install $required_packages_list"
    exit 1
fi

if [ ! -f tmp/gmt-$gmt_ver-src.tar.gz ] ; then 
    echo "Downloading gmt..."
    wget https://github.com/GenericMappingTools/gmt/archive/$gmt_ver.tar.gz -O tmp/gmt-$gmt_ver-src.tar.gz~ && mv tmp/gmt-$gmt_ver-src.tar.gz~ tmp/gmt-$gmt_ver-src.tar.gz
    [ ! -f tmp/gmt-$gmt_ver-src.tar.gz ] && exit
fi 

if [ ! -f tmp/$gshhg.tar.gz ] ; then 
    echo "Downloading gmt gshhg..."
    wget ftp://ftp.soest.hawaii.edu/gshhg/$gshhg.tar.gz -O tmp/$gshhg.tar.gz~ && mv tmp/$gshhg.tar.gz~ tmp/$gshhg.tar.gz
    [ ! -f tmp/$gshhg.tar.gz ] && exit
fi

if [ ! -f tmp/$dcw.tar.gz ] ; then 
    echo "Downloading gmt dcw..."
    wget ftp://ftp.soest.hawaii.edu/dcw/$dcw.tar.gz -O tmp/$dcw.tar.gz~ && mv tmp/$dcw.tar.gz~ tmp/$dcw.tar.gz
    [ ! -f tmp/$dcw.tar.gz ] && exit
fi

if [ ! -f tmp/MB-System-$mb_system_ver.tar.gz ] ; then 
    wget https://github.com/dwcaress/MB-System/archive/$mb_system_ver.tar.gz -O tmp/MB-System-$mb_system_ver.tar.gz~ && mv tmp/MB-System-$mb_system_ver.tar.gz~ tmp/MB-System-$mb_system_ver.tar.gz
    [ ! -f tmp/MB-System-$mb_system_ver.tar.gz ] && exit
fi

# unpack software
cd $CDIR/tmp 
for i in *.tar.gz; do tar -xvzf $i; done 

# install GMT
if [ ! -f $MB_INSTALL_PREFIX/bin/gmt ]; then

mkdir -p $CDIR/tmp/gmt-${gmt_ver}_build
cd $CDIR/tmp/gmt-${gmt_ver}_build

cmake -DCMAKE_INSTALL_PREFIX=$MB_INSTALL_PREFIX -DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DGSHHG_PATH=`pwd`/../$gshhg -DCOPY_GSHHG=TRUE \
-DDCW_PATH=`pwd`/../$dcw -DCOPY_DCW=TRUE \
../gmt-5.4.5

make -j4 && make install 


fi

if [ ! -f $MB_INSTALL_PREFIX/bin/mbinfo ]; then

cd $CDIR/tmp/MB-System-$mb_system_ver
./configure --prefix=$MB_INSTALL_PREFIX --with-gmt-config=$MB_INSTALL_PREFIX/bin && make -j8 && make install 

fi 

mkdir -p $MB_INSTALL_PREFIX/share/gmt
#echo GMT_CUSTOM_LIBS = $MB_INSTALL_PREFIX/lib/mbsystem.so > $MB_INSTALL_PREFIX/lib/gmt/gmt.conf
echo GMT_CUSTOM_LIBS = $MB_INSTALL_PREFIX/lib/mbsystem.so > $HOME/gmt.conf

echo "Gmt Tests:"

export PATH=$MB_INSTALL_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$MB_INSTALL_PREFIX/lib

cd $CDIR

gmt pscoast -R-130/-30/-50/50 -Jm0.025i -B30g30:.Mercator: -Di -W > tmp/mercator.ps

echo "Check versions of gmt mbsystem.so and if it's working"

gmt mbcontour --help |& grep "Plot swath bathymetry"
gmt mbswath --help |& grep "Plot swath bathymetry"
gmt mbgrdtiff --help |& grep "Project grids"

echo "Check mbinfo "
mbinfo 

echo 
echo "Append lines to and of $HOME/.profile file ; logout and login to .profile to work "
echo 
echo "export PATH=$MB_INSTALL_PREFIX/bin:\$PATH"
echo "export LD_LIBRARY_PATH=$MB_INSTALL_PREFIX/lib"

echo 
echo "All done!"


