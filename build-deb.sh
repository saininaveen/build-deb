WORKSPACE="/home/tigerlake/Downloads/exp/tmp"

rm -rf $WORKSPACE
mkdir -p $WORKSPACE


# build configuration
DEFAULT_DISTRO=hirsute

# obtain version string , distro string, for source package generation 
# cd source
git log -1

Source_Str="$(dpkg-parsechangelog -S source)"

DEB_Version_Str="$(dpkg-parsechangelog -S version)"
DEB_No_Epoch_Version_Str="$(echo ${DEB_Version_Str} | cut -d: -f2- )"
DEB_Upstream_Version_Str="$(echo ${DEB_No_Epoch_Version_Str} | cut -d~ -d- -f1 )"

DEB_Distribution_Str="$(dpkg-parsechangelog -S distribution)"
DEB_No_Epoch_Distribution_Str="$(echo ${DEB_Distribution_Str} | cut -d: -f2- )"

if [ "$DEB_No_Epoch_Distribution_Str" == "UNRELEASED" ]; then
	DISTRO=$DEB_No_Epoch_Distribution_Str
else
	DISTRO=$DEFAULT_DISTRO
fi
rm -rf .[^.] .??* 
# create source tarball from git repo
tar -zcvf ../"$Source_Str"_"$DEB_Upstream_Version_Str".orig.tar.gz --exclude=./debian --exclude=./.git .
#tar -zcvf $WORKSPACE/"$Source_Str"_"$DEB_Upstream_Version_Str".orig.tar.gz --exclude=./debian --exclude=./.git .

# generate only the .dsc file
dpkg-source -b .

#cd $WORKSPACE


#localimage=" --basetgz ${WORKSPACE}/../${DISTRO}_image.tgz "
localimage=" --basetgz ${WORKSPACE}/${DISTRO}_image.tgz "

# the jenkins WORKSPACE are mounted to pbuilder chroot at /PPA
# path file:/PPA${WORKSPACE}/../PPA should refer to the workspace for sibling job name "PPA" 
# uncomment below to use local PPA for build
#OTHERMIRROR="--override-config --othermirror \"deb [trusted=yes] file:/PPA${WORKSPACE}/../PPA/ ./|deb http://archive.ubuntu.com/ubuntu/ ${DISTRO}-backports universe multiverse  main restricted |deb http://archive.ubuntu.com/ubuntu/ ${DISTRO}-updates universe multiverse  main restricted  \" "
OTHERMIRROR="--override-config --othermirror \"deb http://archive.ubuntu.com/ubuntu/ ${DISTRO}-backports universe multiverse  main restricted |deb http://archive.ubuntu.com/ubuntu/ ${DISTRO}-updates universe multiverse  main restricted  \" "

# create pbuilder
eval pbuilder-dist $DISTRO create $OTHERMIRROR $localimage

# update pbuilder
eval pbuilder-dist $DISTRO update $OTHERMIRROR $localimage

# build the debian package
eval pbuilder-dist $DISTRO build \
$OTHERMIRROR $localimage  \
--buildresult $WORKSPACE/binaries \
../"$Source_Str"_"$DEB_No_Epoch_Version_Str".dsc

#eval pbuilder-dist $DISTRO build \
#$OTHERMIRROR $localimage  \
#--buildresult $WORKSPACE/binaries \
#$WORKSPACE/"$Source_Str"_"$DEB_No_Epoch_Version_Str".dsc

