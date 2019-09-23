#!/bin/bash

required_packages_list="git ghostscript build-essential cmake gdal-bin gfortran gv libnetcdf-dev netcdf-bin libgdal-dev libfftw3-3 libfftw3-dev libpcre3-dev libmotif-dev libx11-dev freeglut3-dev"

COMPILE_MBSYETEM_FROM_GIT=NO
MB_INSTALL_PREFIX=$HOME/mb-system
mb_system_ver="5.7.5"

gmt_ver="5.4.5"
gshhg="gshhg-gmt-2.3.7"
dcw="dcw-gmt-1.1.4"

GSHHG_PATH=$MB_INSTALL_PREFIX/gshhg
DCW_PATH=$MB_INSTALL_PREFIX/dcw

CDIR=`pwd`

echo "MB-System user install script by Jakub Zdroik 2019"

if [ "$1" == "git" ]; then 
    COMPILE_MBSYETEM_FROM_GIT=YES
    echo "MB-System GIT version"
elif [ "$1" == "stable" ]; then 
    COMPILE_MBSYETEM_FROM_GIT=NO
    echo "MB-System version $mb_system_ver"
else
    echo "usage: $0 git|stable"
    exit 1
fi

echo "Install to: $MB_INSTALL_PREFIX"
echo "Enter to continue or Ctr+C to cancel"

INSTALLED_PKGS=`dpkg -s $required_packages_list 2>&1 >/dev/null && echo ok`

mkdir -p tmp 

read

set -e
# libraries check
if [ "$INSTALLED_PKGS" != "ok" ] ; then 
    read -p "Install required libraries as root? [yn]" -n 1 -r
    echo 
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        sudo apt install $required_packages_list || (echo "Packages installation failed" ; exit 1)
    else
    echo "Install required libraries please and re run script"
    echo "# sudo apt install $required_packages_list"
    exit 1
    fi
else 
    echo "All system dependencies installed OK"
fi

# download all stuff
cd tmp

if [ ! -f gmt-$gmt_ver-src.tar.gz ] ; then 
    echo "Downloading gmt..."
    wget https://github.com/GenericMappingTools/gmt/archive/$gmt_ver.tar.gz -O gmt-$gmt_ver-src.tar.gz~ && mv gmt-$gmt_ver-src.tar.gz~ gmt-$gmt_ver-src.tar.gz
    [ ! -f gmt-$gmt_ver-src.tar.gz ] && (echo "Error downloading GMT source" ; exit 1)
fi 

[ ! -d gmt-$gmt_ver ] && tar -xf gmt-$gmt_ver-src.tar.gz 


if [ ! -f $gshhg.tar.gz ] ; then 
    echo "Downloading gmt gshhg..."
    wget ftp://ftp.soest.hawaii.edu/gshhg/$gshhg.tar.gz -O $gshhg.tar.gz~ && mv $gshhg.tar.gz~ $gshhg.tar.gz
    [ ! -f $gshhg.tar.gz ] && (echo "Error downloading GSHHG data for GMT" ; exit 1)
fi


[ ! -d gshhg-gmt-2.3.7 ] && tar -xf $gshhg.tar.gz 


if [ ! -f $dcw.tar.gz ] ; then 
    echo "Downloading gmt dcw..."
    wget ftp://ftp.soest.hawaii.edu/dcw/$dcw.tar.gz -O $dcw.tar.gz~ && mv $dcw.tar.gz~ $dcw.tar.gz
    [ ! -f $dcw.tar.gz ] && (echo "Error downloading DCW data for GMT" ; exit 1)
fi


[ ! -d dcw-gmt-1.1.4 ] && tar -xf $dcw.tar.gz 

#download stable version
if [ ! -f MB-System-$mb_system_ver.tar.gz ] ; then 
    wget https://github.com/dwcaress/MB-System/archive/$mb_system_ver.tar.gz -O MB-System-$mb_system_ver.tar.gz~ && mv MB-System-$mb_system_ver.tar.gz~ MB-System-$mb_system_ver.tar.gz
    [ ! -f MB-System-$mb_system_ver.tar.gz ] && exit
fi

[ ! -d MB-System-$mb_system_ver ] && tar -xf MB-System-$mb_system_ver.tar.gz 

# clone MB-system from git 
if [ ! -d MB-System-git ] ; then
    git clone https://github.com/dwcaress/MB-System.git MB-System-git || (echo Error cloning from git repo ; exit 1)
fi

cd $CDIR

# install GMT
if [ ! -f $MB_INSTALL_PREFIX/bin/gmt ]; then

mkdir -p $CDIR/tmp/gmt-${gmt_ver}_build
cd $CDIR/tmp/gmt-${gmt_ver}_build

cmake -DCMAKE_INSTALL_PREFIX=$MB_INSTALL_PREFIX -DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DGSHHG_PATH=`pwd`/../$gshhg -DCOPY_GSHHG=TRUE \
-DDCW_PATH=`pwd`/../$dcw -DCOPY_DCW=TRUE \
../gmt-5.4.5 | tee ../gmt-5.4.5_configure.log

make -j8 && make install 

if [ ! -f $MB_INSTALL_PREFIX/bin/gmt ]; then
    echo "Error GMT library not installed!"
    exit 1
fi

fi


# build and install mb-system
if [ "$COMPILE_MBSYETEM_FROM_GIT" == "NO" ] ; then 
    cd $CDIR/tmp/MB-System-$mb_system_ver
else 
    cd $CDIR/tmp/MB-System-git
fi

[ -f $MB_INSTALL_PREFIX/bin/mbinfo ] && rm $MB_INSTALL_PREFIX/bin/mbinfo

./configure --prefix=$MB_INSTALL_PREFIX --with-gmt-config=$MB_INSTALL_PREFIX/bin | tee $CDIR/tmp/mb-system_configure.log 

make -j8 && make install

# check if installed
if [ ! -f $MB_INSTALL_PREFIX/bin/mbinfo ]; then
    echo "Error MB-System not installed!"
    exit 1
fi

#mkdir -p $MB_INSTALL_PREFIX/share/gmt
#echo GMT_CUSTOM_LIBS = $MB_INSTALL_PREFIX/lib/mbsystem.so > $MB_INSTALL_PREFIX/lib/gmt/gmt.conf
echo GMT_CUSTOM_LIBS = $MB_INSTALL_PREFIX/lib/mbsystem.so > $HOME/gmt.conf

echo "#!/bin/bash" > $MB_INSTALL_PREFIX/mb-system_env.sh
echo "export PATH=$MB_INSTALL_PREFIX/bin:\$PATH" >> $MB_INSTALL_PREFIX/mb-system_env.sh
echo "export LD_LIBRARY_PATH=$MB_INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH" >> $MB_INSTALL_PREFIX/mb-system_env.sh

sed -i '/#MB-SYSTEM ENV/d' $HOME/.profile
echo "source $MB_INSTALL_PREFIX/mb-system_env.sh #MB-SYSTEM ENV" >> $HOME/.profile

export PATH=$MB_INSTALL_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$MB_INSTALL_PREFIX/lib

echo "Instalation Tests:"

cd $CDIR

gmt pscoast -R-130/-30/-50/50 -Jm0.025i -B30g30:.Mercator: -Di -W > tmp/mercator.ps

if [ "`which gmt`" != "$MB_INSTALL_PREFIX/bin/gmt" ] ; then 
echo "Error: GMT not availble at $MB_INSTALL_PREFIX/bin/gmt"
exit 1
fi 

if [ "`gmt mbcontour --help |& grep "Plot swath bathymetry"`" == "" ] ; then 
echo "Error: GMT does not work with MB-system"
exit 1
fi
echo -e "\e[93m"
echo "Added MB-system environment to ~/.profile !!!"
echo "Remember to logout and login again to ~/.profile file to work!"
echo -e "\e[0m"
echo 
echo "All done!"

