#!/bin/sh
# 
###############################################################################################
# Jenkins-Buildscript zu erstellung der Images
# 
# Dieses Script wird nach jedem Push auf dem Freifunk Buildserver ausgf�hrt 
# und erstelt die Images komplett neu.
# 
# Durch den Jenkins-Server werden folgende Systemvariablem gesetzt:
# $WORKSPACE - Arbeitsverzeichnis, hierhin wurde dieses repo geclont 
# $JENKINS_HOME - TBD 
# $BUILD_NUMBER - Nummer des aktuellen Buildvorganges (wird in der site.conf verwendet)
# 
###############################################################################################

# Globale Einstellungen 
export GLUON_URL=https://github.com/freifunk-gluon/gluon.git
export GLUON_COMMIT=02fb2817f36a949c6b01e36703b5e761ca314242
export GLUON_RELEASE=0.4.2+$BUILD_NUMBER


# Verzeichnis f�r Gluon-Repo erstellen und initialisieren   

if [ ! -d "$WORKSPACE/gluon" ]; then
  mkdir -r $WORKSPACE/gluon
  git clone $GLUON_URL $WORKSPACE/gluon
fi


# Gluon Repo aktualisieren 

cd $WORKSPACE/gluon
git fetch 
git checkout $GLUON_COMMIT

# Dateien in das Gluon-Repo kopieren
# In der site.conf werden hierbei Umgebungsvariablen durch die aktuellen Werte ersetzt

if [ -d $WORKSPACE/gluon/site  ]; then
  rm -r $WORKSPACE/gluon/site
fi

mkdir $WORKSPACE/gluon/site 

cp $WORKSPACE/modules $WORKSPACE/gluon/site 
cp $WORKSPACE/site.mk $WORKSPACE/gluon/site 
cp $WORKSPACE/site.conf $WORKSPACE/gluon/site 


# Gluon Pakete aktualisieren und Build ausf�hren 
cd $WORKSPACE/gluon
make update GLUON_RELEASE=$GLUON_RELEASE  
make clean GLUON_RELEASE=$GLUON_RELEASE 
make GLUON_RELEASE=$GLUON_RELEASE 


# Manifest f�r Autoupdater erstellen und mit den Key des Servers unterschreiben 
# Der private Schl�ssel des Servers muss in $JENKINS_HOME/secret liegen und das 
# Tools 'ecdsasign' muss auf dem Server verf�gbar sein.
# Repo: https://github.com/tcatm/ecdsautils

cd $WORKSPACE/gluon

make manifest GLUON_RELEASE=$GLUON_RELEASE GLUON_BRANCH=experimental 
make manifest GLUON_RELEASE=$GLUON_RELEASE GLUON_BRANCH=beta 
make manifest GLUON_RELEASE=$GLUON_RELEASE GLUON_BRANCH=stable 

sh contrib/sign.sh $JENKINS_HOME/secret images/sysupgrade/experimental.manifest
sh contrib/sign.sh $JENKINS_HOME/secret images/sysupgrade/beta.manifest
sh contrib/sign.sh $JENKINS_HOME/secret images/sysupgrade/stable.manifest
