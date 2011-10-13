BOOST_VERSION=1_47_0

if [ $# -eq 0 ]; then
	prefix=`pwd`
else 
	prefix=`readlink -m $1`
fi

echo "Installing boost at " $prefix

BOOST_SRC=$prefix
#BOOST_SRC=/c/Home

if ( (python --version) );then
	PYTHON_ROOT=`python -c "import sys; print sys.prefix.replace(\"\\\\\\\\\",\"/\")"`
	echo "... found at $PYTHON_ROOT, good"
else
	echo "need > python2.7 installation"
	echo "get one from http://www.python.org/"
	echo "if allready done, ensure python26 installation directory is in your PATH"
	exit
fi

# fixing python2.7 win64 installation -- there is a file missing
if [ ! -f $PYTHON_ROOT/libs/libpython27.a ]; then
	echo missing $PYTHON_ROOT/libs/libpython27.a
	echo "try creating them"
	# http://wiki.cython.org/InstallingOnWindows?action=AttachFile&do=get&target=python27.def
	# pexports python24.dll > python24.def 

	dlltool --dllname python27.dll --def libgimli/trunk/external/patches/python27.def --output-lib $PYTHON_ROOT/libs/libpython27.a
fi

BOOST_SRC_DIR=$BOOST_SRC/boost_$BOOST_VERSION
GCCVER=mingw-`gcc -v 2>&1 | tail -n1 | cut -d' ' -f3`

arch=`python -c 'import platform; print platform.architecture()[0]'`
if [ "$arch" == "64bit" ]; then
	ADRESSMODEL=64
else
	ADRESSMODEL=32
fi

pushd $BOOST_SRC_DIR

	DISTDIR=$BOOST_SRC_DIR/boost_$BOOST_VERSION-$GCCVER

	echo Calling from $OLDDIR
	echo Installing at $DISTDIR

	if [ ! -f ./bjam.exe ]; then
		./bootstrap.sh --with-toolset=mingw 
	fi

	# if you experience bjam complains something like founding no python
	# edit ./tools/build/v2/tools/python.jam:486 (comment out line to disable quotation adding)
	# edit ./tools/build/v2/tools/python-config.jam:12 (add 2.7 2.6 2.5) but not necessary

	./bootstrap.sh --prefix=$DISTDIR --with-bjam=./bjam.exe --with-toolset=gcc \
		--with-python-root=$PYTHON_ROOT --with-libraries=python,system,thread,regex
	
	./b2 install -d+2 --prefix=$DISTDIR --layout=tagged \
			address-model=$ADRESSMODEL variant=release link=shared \
			threading=multi
			
	mkdir -p ../boost
	cp -r $DISTDIR/include ../boost
	cp -r $DISTDIR/lib ../boost
popd
