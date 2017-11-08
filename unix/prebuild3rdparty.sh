#!/bin/sh

###############################################################################
# prebuild3rdparty.sh script (maintainers only)
# Written by Nicolas Calimet and Christoph Hormann
# Modified by Trevor SANDY <trevor.sandy@gmiil.com>
#
# This prebuild.sh script prepares the source tree for building the
# Unix/Linux version of LPub3D-Trace.  Unlike the former versions, the
# prebuild procedure does not change the directory structure, so that
# the overall layout of the UNIX source distribution remains consistent
# with the other supported architectures (namely Windows and Macintosh).
# Yet, some "standard" files such as configure, README, INSTALL, etc.
# are placed in the root directory to give the expected GNUish look to
# the distribution.
#
# The purpose of this script is to create the 'configure' and various
# 'Makefile.am' shell scripts, as well as modify/update some generic files
# (e.g. doc).
#
# Running prebuild.sh requires:
#   1) GNU autoconf >= 2.59 and GNU automake >= 1.9
#   2) perl and m4 (should be on any system, at least Linux is okay)
#   3) Run from the unix/ directory where the script is located.
#
# Prepare all but the doc/ directory using:
#   % ./prebuild3rdparty.sh
#
# Clean up all files and folders created by this script (but docs):
#   % ./prebuild.sh clean
#
# The unix-specific documentation is created seperately since it requires
# lots of processing time as well as a bunch of other programs such as PHP.
# See ../documentation/povdocgen.doc for details.
# The "all" option builds all docs, otherwise only html docs are created.
# Any other option (e.g. "skip ta") replaces the default.
#   % ./prebuild.sh doc(s) [option]
#
# Clean up the docs:
#   % ./prebuild3rdparty.sh doc(s)clean
#
#
# Note that the 'clean' and 'doc(s)(clean)' options are mutually exclusive.
#
###############################################################################

umask 022

pov_version_base=`cat ./VERSION | sed 's,\([0-9]*.[0-9]*\).*,\1,g'`
pov_config_bugreport="LPub3D-Trace issue tracker at https://github.com/trevorsandy/povray/issues"

# documentation
timestamp=`date +%Y-%m-%d`
build="./docs_$timestamp"
builddoc="$build/documentation"

required_autoconf="2.69"
required_automake="1.9"


###############################################################################
# Setup
###############################################################################

# Prevents running from another directory.
if test x"`dirname $0`" != x"." && test x"${PWD##*/}" != x"unix"; then
	echo "$0: must run from LPub3D-Trace's unix/ directory."
	exit 1
fi

# Check optional argument.
case "$1" in
	""|clean|doc|docs|docclean|docsclean) ;;
	*) echo "$0: error: unrecognized option '$1'"; exit ;;
esac

# Check whether 'cp -u' is supported.
if test x"`cp -u ./prebuild3rdparty.sh /dev/null 2>&1`" = x""; then
	cp_u='cp -u'
else
	cp_u='cp'
fi

# Check for autoconf/automake presence and version.
if test x"$1" = x""; then
	if autoconf --version > /dev/null 2>&1; then
		autoconf=`autoconf --version | grep autoconf | sed s,[^0-9.]*,,g`
		echo "Detected autoconf $autoconf"
		autoconf=`echo $autoconf | sed -e 's,\([0-9]*\),Z\1Z,g' -e 's,Z\([0-9]\)Z,Z0\1Z,g' -e 's,[^0-9],,g'`
		required=`echo $required_autoconf | sed -e 's,\([0-9]*\),Z\1Z,g' -e 's,Z\([0-9]\)Z,Z0\1Z,g' -e 's,[^0-9],,g'`
		expr $autoconf \>= $required > /dev/null || autoconf=""
	fi
	if test x"$autoconf" = x""; then
		echo "$0: error: requires autoconf $required_autoconf or above"
		exit 1
	fi

	if automake --version > /dev/null 2>&1; then
		automake=`automake --version | grep automake | sed s,[^0-9.]*,,g`
		echo "Detected automake $automake"
		automake=`echo $automake | sed -e 's,\([0-9]*\),Z\1Z,g' -e 's,Z\([0-9]\)Z,Z0\1Z,g' -e 's,[^0-9],,g'`
		required=`echo $required_automake | sed -e 's,\([0-9]*\),Z\1Z,g' -e 's,Z\([0-9]\)Z,Z0\1Z,g' -e 's,[^0-9],,g'`
		expr $automake \>= $required > /dev/null || automake=""
	fi
	if test x"$automake" = x""; then
		echo "$0: error: requires automake $required_automake or above"
		exit 1
	fi
fi

###############################################################################
# Copying and generating standard/additional files
###############################################################################

case "$1" in

	# Cleanup all files not in the repository
	clean)
	if test -f ../Makefile; then
		makeclean=`\
cd .. ; \
echo "make clean" 1>&2  &&  make clean 1>&2 ; \
echo "make maintainer-clean" 1>&2  &&  make maintainer-clean 1>&2 ; \
` 2>&1
	fi

	# backward-compatible cleanup
	for file in \
		acinclude.m4 acx_pthread.m4 AUTHORS ChangeLog config/ configure.ac \
		COPYING INSTALL NEWS README CUI_README \
		icons/ include/ ini/ povray.1 povray.conf \
		povray.ini.in scenes/ scripts/ VERSION
	do
		rm -r ../$file 2> /dev/null  &&  echo "Cleanup ../$file"
	done
	# cleanup stuff added by automake
	for file in config.guess config.sub compile depcomp install-sh missing
	do
		rm config/$file 2> /dev/null  &&  echo "Cleanup config/$file"
	done
	;;


	# Cleanup documentation
	doc*clean)
	for file in ../doc/ $build; do
		rm -r $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;


	# Generate the documentation (adapted from C.H. custom scripts)
	doc|docs)
	echo "Generate docs"
	log_file="makedocs.log"
	cat /dev/null > $log_file

	# cleanup or create the ../doc folder.
	if ! test -d ../doc; then
		echo "Create ../doc" | tee -a $log_file
		mkdir ../doc
		echo "Create ../doc/html" | tee -a $log_file
		mkdir ../doc/html
	else
		echo "Cleanup ../doc" | tee -a $log_file
		rm -f -r ../doc/*
		mkdir ../doc/html
	fi

	# create build folder and documentation.
	if ! test -d $build; then
		echo "Create $build" | tee -a $log_file
		mkdir $build
		echo "Create $build/distribution" | tee -a $log_file
		echo "Copy distribution" | tee -a $log_file
		$cp_u -f -R ../distribution $build/
	fi
	if ! test -d $builddoc; then
		echo "Create $builddoc" | tee -a $log_file
		mkdir $builddoc
	fi
	if test x"../documentation" != x"$builddoc"; then
		echo "Copy documentation" | tee -a $log_file
		$cp_u -f -R ../documentation/* $builddoc/
		chmod -f -R u+rw $builddoc/
	fi
	chmod -R u+rw $build/*

	# run makedocs script.
	# The default "skip ta" does not build latex nor archive files.
	# Yet some GIF images from the output/final/tex/images directories are needed;
	# for simplicity this directory is a symlink to output/final/machelp/images
	# (do not symlink with output/final/unixhelp/images).
	echo "Run makedocs" | tee -a $log_file
	rootdir=`pwd`
	cd $builddoc
	docopts="skip ta"
	case "$2" in
		all) docopts=;;
		.*)  docopts="$2";;
	esac
	test -d ./output/final/tex/  ||  mkdir -p ./output/final/tex/
	skipt=`echo "$docopts" | grep 'skip.*t'`
	test x"$skipt" != x""  &&  test -d ./output/final/tex/images  ||  ln -s ../machelp/images ./output/final/tex/images
	sh makedocs.script $docopts | tee -a $rootdir/$log_file
	test x"$skipt" != x""  &&  test -d ./output/final/tex/images  &&  rm -f ./output/final/tex/images
	cd $rootdir

	# post-process HTML files in several steps.
	echo "Process unixhelp HTML files" | tee -a $log_file
	files=`find $builddoc/output/final/unixhelp/ -name "*.html"`

	# add document type
	# replace &trade; characters
	# remove (often misplaced) optional </p> tags
	# remove empty strong's
	# reorganise section link and add 'id' attribute
	for htmlfile in $files ; do
		mv -f $htmlfile $htmlfile.temp
		echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">' > $htmlfile
		cat $htmlfile.temp | sed \
			-e 's,&trade;,<sup>TM</sup>,g' \
			-e 's,&amp;trade;,<sup>TM</sup>,g' \
			-e 's,</p>,,g' \
			-e 's,<strong>[[:space:]]*</strong>,,g' \
			-e 's,<a name="\([^"]*\)">\([0-9.]* \)</a>,<a id="\1" name="\1"></a>\2,g' \
			>> $htmlfile
	done

	# add link targets for index keywords
	idx="$builddoc/output/final/unixhelp/idx.html"
	mv -f $idx $idx.temp
	cat $idx.temp | sed \
		'/<!-- keyword -->/ N; s,<!-- keyword -->\(<dt>\)\n\s*\(.*\),\1<a id="\2" name="\2"></a>\2,' \
		> $idx

	# replace invalid caracters in 'id' and 'name' attributes; needs seperate steps.
	for htmlfile in $files ; do  # comma+space -> dot
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			':BEGIN; s/id="\([^,"]*\), \([^"]*\)" name="\([^,"]*\), \([^"]*\)"/id="\1.\2" name="\3.\4"/g; tBEGIN' \
			> $htmlfile
	done
	for htmlfile in $files ; do  # slash -> dot
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			':BEGIN; s/id="\([^\/"]*\)\/\([^"]*\)" name="\([^\/"]*\)\/\([^"]*\)"/id="\1.\2" name="\3.\4"/g; tBEGIN' \
			> $htmlfile
	done
	for htmlfile in $files ; do  # spaces -> dots
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			':BEGIN; s/id="\([^ "]*\) \([^"]*\)" name="\([^ "]*\) \([^"]*\)"/id="\1.\2" name="\3.\4"/g; tBEGIN' \
			> $htmlfile
	done
	for htmlfile in $files ; do  # hash character -> H
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			':BEGIN; s/id="\([^#"]*\)#\([^"]*\)" name="\([^#"]*\)#\([^"]*\)"/id="\1H\2" name="\3H\4"/g; tBEGIN' \
			> $htmlfile
	done
	for htmlfile in $files ; do  # first plus sign -> P
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			':BEGIN; s/id="\([^+"]*\)+\([^"]*\)" name="\([^+"]*\)+\([^"]*\)"/id="\1P\2" name="\3P\4"/; tBEGIN' \
			> $htmlfile
	done
	for htmlfile in $files ; do  # first minus sign -> M
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			':BEGIN; s/id="\([^"-]*\)-\([^"]*\)" name="\([^"-]*\)-\([^"]*\)"/id="\1M\2" name="\3M\4"/; tBEGIN' \
			> $htmlfile
	done

	# add keyword list on top of the index, using alphabetical folded sublists
	idx="$builddoc/output/final/unixhelp/idx.html"
	rm -f $idx.list
	echo "<br><div style=\"text-align:left;\">" > $idx.list
	for car in \# + - A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
		firsttarget=`grep -i "</a>$car" $idx | head -n 1 | sed "s,\s*<dt><a id=\"\(.*\)\" name=.*></a>\(.*\),<a href=\"#\1\"><strong>$car</strong></a>,"`
		echo "&nbsp;&nbsp;&nbsp;$firsttarget&nbsp;<span class=\"menuEntry\" onclick=\"MenuToggle(event);\">&raquo;</span><div class=\"menuSection\" style=\"display:none;\"><blockquote class=\"Note\">" >> $idx.list
		grep -i "</a>$car" $idx | sed \
			's,\s*<dt><a id="\(.*\)" name=.*></a>\(.*\),<a href="#\1">\2</a>\&nbsp;\&nbsp;,' \
			>> $idx.list
		echo "</blockquote></div>" >> $idx.list
	done
	echo "</div><hr>" >> $idx.list
	mv -f $idx $idx.temp
	cat $idx.temp | sed "/<!-- list -->/ r $idx.list" > $idx
	rm -f $idx.list

	# improve navigation from the keyword index by placing all link targets
	# directly in the heading section on the previous line
	for htmlfile in $files ; do
		mv -f $htmlfile $htmlfile.temp
		cat $htmlfile.temp | sed \
			'/<h[1-5]><a/ { N; s,\(<h[1-5]><a.*</a>\)\(.*\)\(</h[1-5]>\)\n\(<a id=.* name=.*></a>\)*,<!-- \2 -->\n\1\4\2\3,g }' \
			> $htmlfile
	done

	# unfold the chapter entries in menu.html.
	menu="$builddoc/output/final/unixhelp/menu.html"
	mv -f $menu $menu.temp
	cat $menu.temp | sed \
		-e 's,^  \(<span.*>\)\(<ul.*>\),  <div>\2,' \
		-e 's,^    \(<span.*\)raquo\(.*display:\)none\(.*\),    \1laquo\2block\3,' \
		> $menu

	# finally make a clean copy of the documentation.
	echo "Cleanup" | tee -a $log_file
	rm -f -r $builddoc/output/final/unixhelp/*.html.temp
	rm -f    $builddoc/output/final/unixhelp/template*
	rm -f    $builddoc/output/final/unixhelp/README
	rm -f    $builddoc/output/final/unixhelp/images/README
	rm -f    $builddoc/output/final/unixhelp/images/reference/README
	rm -f    $builddoc/output/final/unixhelp/images/reference/colors/README
	rm -f    $builddoc/output/final/unixhelp/images/tutorial/README
	rm -f -r $builddoc/output/final/unixhelp/images/unix/
	rm -f    $builddoc/output/final/unixhelp/unix_splash.html
	rm -f    $builddoc/output/final/unixhelp/unix_frame.html

	echo "Copy documentation in ../doc/" | tee -a $log_file
	$cp_u -f -R   $builddoc/output/final/unixhelp/* ../doc/html/
	chmod -R u+rw ../doc/html/
	mv -f         ../doc/html/*.txt ../doc/
	mv -f         ../doc/html/*.doc ../doc/
	$cp_u -f      README.unix ../doc/
	chmod -R u+rw ../doc/

	# [C.H.]
	# povlegal.doc contains 0x99, which is a TM character under Windows.
	# Converting to "[tm]".
	echo "Copy licence files in ../doc/"
	perl -e 'while (<>) {s/\x99/[tm]/g; print;}' ../distribution/povlegal.doc \
		> ../doc/povlegal.doc || echo "povlegal.doc not created !"
	$cp_u -f ../distribution/agpl-3.0.txt ../doc/ \
		|| echo "agpl-3.0.txt not copied !"

	# log tracing.
	$cp_u -f   $log_file docs_$timestamp.log
	chmod u+rw docs_$timestamp.log
	$cp_u -f   $builddoc/output/log.txt docs_internal_$timestamp.log
	chmod u+rw docs_internal_$timestamp.log
	rm -f      $log_file

	exit
	;;


	# Copy files
	*)
	# some shells seem unable to expand properly wildcards in the list entries
	# (e.g. ../distribution/in*/).
	for file in \
		AUTHORS ChangeLog configure.ac COPYING NEWS \
		README CUI_README VERSION \
		povray.1 \
		scripts \
		../distribution/ini ../distribution/include ../distribution/scenes
	do
		out=`basename $file`
		echo "Create ../$out`test -d $file && echo /`"
		$cp_u -f -R $file ../  ||  echo "$file not copied !"
		chmod -f -R u+rw ../$out
	done

	# special cases:

	# INSTALL
	echo "Create ../INSTALL"
	$cp_u -f install.txt ../INSTALL  ||  echo "INSTALL not copied !"
	chmod -f u+rw ../INSTALL

	# icons/
	# don't copy the icons/source directory
	mkdir -p ../icons
	files=`find icons -maxdepth 1 -name \*.png`
	for file in $files ; do
		echo "Create ../$file"
		$cp_u -f $file ../$file  ||  echo "$file not copied !"
		chmod -f -R u+rw ../$file
	done

	echo "Create ../doc/html"
	mkdir -p ../doc/html  # required to build without existing docs
	;;

esac


###############################################################################
# Creation of supporting unix-specific files
###############################################################################


###
### ./Makefile.am
###

makefile="./Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	echo "Create $makefile.am"
	cat Makefile.header > $makefile.am
	cat << pbEOF >> $makefile.am

# Makefile.am for the source distribution of LPub3D-Trace $pov_version_base for UNIX
# Please report bugs to $pov_config_bugreport

# Programs to build.
bin_PROGRAMS = lpub3d_trace_cui

# Source files.
lpub3d_trace_cui_SOURCES = \\
	disp.h \\
	disp_sdl.cpp disp_sdl.h \\
	disp_text.cpp disp_text.h

cppflags_platformcpu =
ldadd_platformcpu =
if BUILD_x86
cppflags_platformcpu += -I\$(top_srcdir)/platform/x86
ldadd_platformcpu += \$(top_builddir)/platform/libx86.a
endif
if BUILD_x86avx
ldadd_platformcpu += \$(top_builddir)/platform/libx86avx.a
endif
if BUILD_x86avxfma4
ldadd_platformcpu += \$(top_builddir)/platform/libx86avxfma4.a
endif
if BUILD_x86avx2fma3
ldadd_platformcpu += \$(top_builddir)/platform/libx86avx2fma3.a
endif

# Include paths for headers.
AM_CPPFLAGS = \\
	-I\$(top_srcdir)/unix/povconfig \\
	-I\$(top_srcdir) \\
	-I\$(top_srcdir)/source \\
	-I\$(top_builddir)/source \\
	-I\$(top_srcdir)/platform/unix \\
	\$(cppflags_platformcpu) \\
	-I\$(top_srcdir)/vfe \\
	-I\$(top_srcdir)/vfe/unix

LDADD =
if USE_SDL2_SRC
# Set SDL2 static lib and cflags arguments
sdl2_builddir = \$(top_builddir)/libraries/sdl2
sdl2_srcdir = \$(top_srcdir)/libraries/sdl2
sdl2_libs_cfg_in := \$(shell \$(sdl2_builddir)/sdl2-config --static-libs 2> /dev/null)
sdl2_libs_config := \$(filter-out -lSDL2,\$(sdl2_libs_cfg_in))
AM_CPPFLAGS += -I\$(sdl2_builddir)/include -I\$(sdl2_srcdir)/include -D_REENTRANT
LIBS += \$(sdl2_libs_config)
LDADD += \\
	\$(sdl2_builddir)/build/lib/libSDL2.a \\
	\$(sdl2_builddir)/build/lib/libSDL2main.a
endif

# Libraries to link with.
# Beware: order does matter!
# TODO - Having vfe/libvfe.a twice in this list is a bit of a hackish way to cope with cyclic dependencies.
LDADD += \\
	\$(top_builddir)/vfe/libvfe.a \\
	\$(top_builddir)/source/libpovray.a \\
	\$(top_builddir)/vfe/libvfe.a \\
	\$(top_builddir)/platform/libplatform.a \\
	\$(ldadd_platformcpu)
pbEOF
	;;
esac



##### Root directory ##########################################################


###
### ../kde_install.sh
###

file="../kde_install.sh"

case "$1" in
	clean)
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	;;

	doc*)
	;;

	*)
		echo "Create $file"
		echo "#!/bin/sh
# ==================================================================
# LPub3D-Trace $pov_version_base - Unix source version - KDE install script
# ==================================================================
# written July 2003 - March 2004 by Christoph Hormann
# Based on parts of the Linux binary version install script
# This file is part of LPub3D-Trace and subject to the LPub3D-Trace licence
# see POVLEGAL.DOC for details.
# ==================================================================

" > "$file"

		grep -A 1000 -E "^#.*@@KDE_BEGIN@@" "./install" | grep -B 1000 -E "^#.*@@KDE_END@@" >> "$file"

		echo "

kde_install
"  >> "$file"

	chmod +x $file
	;;
esac


###
### ../povray.ini.in (template for ../povray.ini)
###

ini="../povray.ini"

case "$1" in
	clean)
	for file in $ini $ini.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	# __POVLIBDIR__ will be updated at make time.
	echo "Create $ini.in"
	cat ../distribution/ini/povray.ini | sed \
		's/C:.POVRAY3 drive and/__POVLIBDIR__/' > $ini.in
	cat << pbEOF >> $ini.in

; Search path for #include source files or command line ini files not
; found in the current directory.  New directories are added to the
; search path, up to a maximum of 25.

Library_Path="__POVLIBDIR__"
Library_Path="__POVLIBDIR__/ini"
Library_Path="__POVLIBDIR__/include"

; File output type control.
;     T    Uncompressed Targa-24
;     C    Compressed Targa-24
;     P    UNIX PPM
;     N    PNG (8-bits per colour RGB)
;     Nc   PNG ('c' bit per colour RGB where 5 <= c <= 16)

Output_to_File=true
Output_File_Type=N8             ; (+/-Ftype)
pbEOF
	;;
esac


###
### ../povray.conf.in (template for ../povray.conf)
###

conf="../povray.conf"

case "$1" in
	clean)
	for file in $conf $conf.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	# __HOME__, __POVUSER__, __POVUSERDIR__ and __POVSYSDIR__ will be updated at make time.
	echo "Create $conf.in"
	cat ../distribution/povray.conf | sed \
		's/C:.POVRAY3 drive and/__POVSYSDIR__/' > $conf.in
	cat << pbEOF >> $conf.in

; Default (hard coded) paths:
; HOME        = __HOME__
; INSTALLDIR  = __POVSYSDIR__
; SYSCONF     = __POVSYSDIR__/resources/config/povray.conf
; SYSINI      = __POVSYSDIR__/resources/config/povray.ini
; USERCONF    = %HOME%/__POVUSERDIR__/config/povray.conf
; USERINI     = %HOME%/__POVUSERDIR__/config/povray.ini

; This example shows how to qualify path names containing space(s):
; read = "%HOME%/this/directory/contains space characters"

; You can use %HOME%, %INSTALLDIR% and $PWD (working directory) as the origin to define permitted paths:

; %HOME% is hard-coded to the $USER environment variable.
read* = "%HOME%/__POVUSERDIR__/config"

read* = "__POVSYSDIR__/resources/include"
read* = "__POVSYSDIR__/resources/ini"
read* = "%HOME%/LDraw/lgeo/ar"
read* = "%HOME%/LDraw/lgeo/lg"
read* = "%HOME%/LDraw/lgeo/stl"

; %INSTALLDIR% is hard-coded to the default LPub3D installation path - see default paths above.

; The $PWD (working directory) is where LPub3D-Trace is called from.
; read* = "../../distribution/ini"
; read* = "../../distribution/include"
; read* = "../../distribution/scenes"

read+write* = .
pbEOF
	;;
esac


###
### ../Makefile.am
###

makefile="../Makefile"

case "$1" in
	clean)
	for file in $makefile.am; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	scriptfiles=`find scripts -type f`

	echo "Create $makefile.am"
	cat Makefile.header > $makefile.am
	cat << pbEOF >> $makefile.am

# Makefile.am for the source distribution of LPub3D-Trace $pov_version_base for UNIX
# Please report bugs to $pov_config_bugreport

# Directories.
povbase = \$(prefix)/@PACKAGE@-@VERSION_BASE@
povlibdir = \$(povbase)/resources
povconfdir = \$(povlibdir)/config
povdocdir = \$(povbase)/docs
povmandir = \$(povlibdir)/man
povuser = \$(povlibdir)
povconfuser = \$(povuser)/config
povbinbase = \$(povbase)/bin
povbin = \$(povbinbase)/@host_platform@
povinstall = \$(top_builddir)/install.log
povowner = @povowner@
povgroup = @povgroup@

# Povray conf and ini paths
if MACOS_BUILD
datapath = Library/Application\ Support/LPub3D\ Software/LPub3D/3rdParty
sysapppath = /Applications/LPub3D.app/Contents/3rdParty
else
datapath = .local/share/LPub3D\ Software/LPub3D/3rdParty
sysapppath = /usr/share/lpub3d/3rdParty
endif
userdatapath = \$(HOME)/\$(datapath)
lpub3duserdir = \$(datapath)/@PACKAGE@-@VERSION_BASE@
lpub3dsysdir = \$(sysapppath)/@PACKAGE@-@VERSION_BASE@
lpub3dlibdir = \$(lpub3dsysdir)/resources

# Directories to build.
SUBDIRS = source vfe platform unix

# Additional files to distribute.
EXTRA_DIST = \\
	bootstrap kde_install.sh \\
	doc icons include ini scenes scripts \\
	povray.ini.in changes.txt revision.txt

# Additional files to clean with 'make distclean'.
DISTCLEANFILES = \$(top_builddir)/povray.ini
CONFIG_CLEAN_FILES =

# Test scene display status
pov_xwin_msg = @pov_xwin_msg@

# Render a test scene for 'make check'.
# This will run before 'make install'.
check: all
	@echo "Generating build check povray.conf and povray.ini files..."; \\
	cat \$(top_srcdir)/povray.conf.in | sed -e "s,__HOME__,\\\$(HOME),g" -e "s,__POVSYSDIR__,\$(lpub3dsysdir),g" -e "s,__POVUSERDIR__,\$(lpub3duserdir),g" > \$(lpub3duserdir)/config/povray.conf; \\
	cat \$(top_srcdir)/povray.ini.in | sed "s,__POVLIBDIR__,\$(lpub3dlibdir),g" > \$(lpub3duserdir)/config/povray.ini
	@echo "Executing render output file check..."; \\
	\$(top_builddir)/unix/\$(PACKAGE) +i\$(top_srcdir)/scenes/advanced/biscuit.pov +O\$(top_srcdir)/biscuit.pov.cui.png +w320 +h240 +UA +A \\
	+L\$(top_srcdir)/ini +L\$(top_srcdir)/include +L\$(top_srcdir)/scenes
	@if ! test "\$(CI)" = "true"; then \\
		echo "Executing the render display window check..."; \\
		case "\$(pov_xwin_msg)" in \\
			*enabled*) \\
			\$(top_builddir)/unix/\$(PACKAGE) +i\$(top_srcdir)/scenes/advanced/biscuit.pov -f +d +p +v +w320 +h240 +a0.3 \\
			+L\$(top_srcdir)/ini +L\$(top_srcdir)/include +L\$(top_srcdir)/scenes; \\
			;; \\
		esac ; \\
	fi

# Install scripts in povlibdir.
nobase_povlib_SCRIPTS = `echo $scriptfiles`

# Install documentation in povdocdir.
povdoc_DATA = AUTHORS ChangeLog NEWS CUI_README LICENSE

# Install configuration and INI files in povconfdir.
dist_povconf_DATA = povray.conf
povray.conf:
	cat \$(top_srcdir)/povray.conf.in | sed -e "s,__HOME__,\\\$(HOME),g" -e "s,__POVSYSDIR__,\$(lpub3dsysdir),g" -e "s,__POVUSERDIR__,\$(lpub3duserdir),g" > \$(top_builddir)/povray.conf

povconf_DATA = povray.ini
povray.ini:
	cat \$(top_srcdir)/povray.ini.in | sed "s,__POVLIBDIR__,\$(lpub3dlibdir),g" > \$(top_builddir)/povray.ini

# Install man page in povmandir.
dist_povman_DATA = povray.1

# Remove all unwanted files for 'make dist(check)'.
# Make all files user read-writeable.
dist-hook:
	chmod -R u+rw \$(distdir)
	chmod 755 \$(distdir)/scripts/*
	rm -f    \`find \$(distdir) -name "*.h.in~"\`
	rm -f -r \`find \$(distdir) -name autom4te.cache\`
	rm -f -r \`find \$(distdir) -name .libs\`

# Manage various data files for 'make install'.
# Creates an install.log file to record created folders and files.
# Folder paths are prepended (using POSIX printf) to ease later removal in 'make uninstall'.
# Don't be too verbose so as to easily spot possible problems.
install-data-local:
	cat /dev/null > \$(povinstall);
	@echo "Creating data directories..."; \\
	list='\$(top_srcdir)/icons \$(top_srcdir)/include \$(top_srcdir)/ini \$(top_srcdir)/scenes'; \\
	dirlist=\`find \$\$list -type d | sed s,\$(top_srcdir)/,,\`; \\
	for p in "" \$\$dirlist ; do \\
		\$(mkdir_p) \$(DESTDIR)\$(povlibdir)/\$\$p && chown \$(povowner) \$(DESTDIR)\$(povlibdir)/\$\$p && chgrp \$(povgroup) \$(DESTDIR)\$(povlibdir)/\$\$p && printf "%s\\n" "\$(DESTDIR)\$(povlibdir)/\$\$p" "\`cat \$(povinstall)\`" > \$(povinstall); \\
	done; \\
	echo "Copying data files..."; \\
	filelist=\`find \$\$list -type f | sed s,\$(top_srcdir)/,,\`; \\
	for f in \$\$filelist ; do \\
		\$(INSTALL_DATA) \$(top_srcdir)/\$\$f \$(DESTDIR)\$(povlibdir)/\$\$f && chown \$(povowner) \$(DESTDIR)\$(povlibdir)/\$\$f && chgrp \$(povgroup) \$(DESTDIR)\$(povlibdir)/\$\$f && echo "\$(DESTDIR)\$(povlibdir)/\$\$f" >> \$(povinstall); \\
	done
	@echo "Creating documentation directories..."; \\
	dirlist=\`find \$(top_srcdir)/doc/ -type d | sed s,\$(top_srcdir)/doc/,,\`; \\
	for p in "" \$\$dirlist ; do \\
		\$(mkdir_p) \$(DESTDIR)\$(povdocdir)/\$\$p && chown \$(povowner) \$(DESTDIR)\$(povdocdir)/\$\$p && chgrp \$(povgroup) \$(DESTDIR)\$(povdocdir)/\$\$p && printf "%s\\n" "\$(DESTDIR)\$(povdocdir)/\$\$p" "\`cat \$(povinstall)\`" > \$(povinstall); \\
	done
	@echo "Copying documentation files..."; \\
	filelist=\`find \$(top_srcdir)/doc/ -type f | sed s,\$(top_srcdir)/doc/,,\`; \\
	for f in \$\$filelist ; do \\
		\$(INSTALL_DATA) \$(top_srcdir)/doc/\$\$f \$(DESTDIR)\$(povdocdir)/\$\$f && chown \$(povowner) \$(DESTDIR)\$(povdocdir)/\$\$f && chgrp \$(povgroup) \$(DESTDIR)\$(povdocdir)/\$\$f && echo "\$(DESTDIR)\$(povdocdir)/\$\$f" >> \$(povinstall); \\
	done
	@echo "Creating user directories..."; \\
	for p in \$(povuser) \$(povconfuser) ; do \\
		\$(mkdir_p) \$(DESTDIR)/\$\$p && chown \$(povowner) \$(DESTDIR)/\$\$p && chgrp \$(povgroup) \$(DESTDIR)/\$\$p && printf "%s\\n" "\$(DESTDIR)/\$\$p" "\`cat \$(povinstall)\`" > \$(povinstall); \\
	done
	@echo "Copying user configuration and INI files..."; \\
	\$(INSTALL_DATA) \$(top_srcdir)/povray.conf \$(DESTDIR)\$(povconfuser)/povray.conf && chown \$(povowner) \$(DESTDIR)\$(povconfuser)/povray.conf && chgrp \$(povgroup) \$(DESTDIR)\$(povconfuser)/povray.conf && echo "\$(DESTDIR)\$(povconfuser)/povray.conf" >> \$(povinstall); \\
	\$(INSTALL_DATA) \$(top_builddir)/povray.ini \$(DESTDIR)\$(povconfuser)/povray.ini && chown \$(povowner) \$(DESTDIR)\$(povconfuser)/povray.ini && chgrp \$(povgroup) \$(DESTDIR)\$(povconfuser)/povray.ini && echo "\$(DESTDIR)\$(povconfuser)/povray.ini" >> \$(povinstall)

# Move executable to 3rd party bin location
# Set doc, man, conf and script file permissions.
install-data-hook:
	@echo "Creating 3rdParty distribution bin directory..."; \\
	for p in \$(povbinbase) \$(povbin) ; do \\
		\$(mkdir_p) \$\$p && chown \$(povowner) \$\$p && chgrp \$(povgroup) \$\$p && printf "%s\\n" "\$\$p" "\`cat \$(povinstall)\`" > \$(povinstall); \\
	done
	@echo "Copying \$(PACKAGE) executable..."; \\
	\$(INSTALL_DATA) \$(bindir)/\$(PACKAGE) \$(DESTDIR)\$(povbin)/\$(PACKAGE) && chown \$(povowner) \$(DESTDIR)\$(povbin)/\$(PACKAGE) && chgrp \$(povgroup) \$(DESTDIR)\$(povbin)/\$(PACKAGE) && echo "\$(DESTDIR)\$(povbin)/\$(PACKAGE)" >> \$(povinstall)
	@echo "Setting \$(PACKAGE) permissions..."; \\
	chmod 755 \$(DESTDIR)\$(povbin)/\$(PACKAGE) && echo "\$(DESTDIR)\$(povbin)/\$(PACKAGE)" >> \$(povinstall)
	@echo "Performing cleanup..."; \\
	rm -f \$(bindir)/\$(PACKAGE) && echo "\$(bindir)/\$(PACKAGE)" >> \$(povinstall); \\
	chown \$(povowner) \$(DESTDIR)\$(povbase) && chgrp \$(povgroup) \$(DESTDIR)\$(povbase) && echo "\$(DESTDIR)\$(povbase)" >> \$(povinstall)
	@echo "Setting doc files ownership..."; \\
	for f in AUTHORS ChangeLog NEWS CUI_README LICENSE; do \\
		chown \$(povowner) \$(DESTDIR)\$(povdocdir)/\$\$f && chgrp \$(povgroup) \$(DESTDIR)\$(povdocdir)/\$\$f && echo "\$(DESTDIR)\$(povdocdir)/\$\$f" >> \$(povinstall); \\
	done
	@echo "Setting config, man and script files ownership..."; \\
	for p in config man scripts ; do \\
		chown \$(povowner) \$(DESTDIR)\$(povlibdir)/\$\$p && chgrp \$(povgroup) \$(DESTDIR)\$(povlibdir)/\$\$p && echo "\$(DESTDIR)\$(povlibdir)/\$\$p" >> \$(povinstall); \\
		filelist=\`find \$(DESTDIR)\$(povlibdir)/\$\$p/ -type f | sed s,\$(DESTDIR)\$(povlibdir)/\$\$p/,,\`; \\
		for f in \$\$filelist ; do \\
			chown \$(povowner) \$(DESTDIR)\$(povlibdir)/\$\$p/\$\$f && chgrp \$(povgroup) \$(DESTDIR)\$(povlibdir)/\$\$p/\$\$f && echo "\$(DESTDIR)\$(povlibdir)/\$\$p/\$\$f" >> \$(povinstall); \\
		done; \\
	done; \\
	echo "\$(PACKAGE) install finished"

# Remove data, config, and empty folders for 'make uninstall'.
# Use 'hook' instead of 'local' so as to properly remove *empty* folders (e.g. scripts).
# The last echo prevents getting error from failed rmdir command.
uninstall-hook:
	@if test -f \$(top_builddir)/install.log ; then \\
		rmdir \$(DESTDIR)\$(povlibdir)/scripts; \\
		rmdir \$(DESTDIR)\$(povbin); \\
		echo "Using install info from \$(top_builddir)/install.log"; \\
		echo "Removing data, documentation, and configuration files..."; \\
		for f in \`cat \$(top_builddir)/install.log\` ; do \\
			test -f \$\$f && rm -f \$\$f ; \\
		done; \\
		echo "Removing empty directories..."; \\
		for f in \`cat \$(top_builddir)/install.log\` ; do \\
			test -d \$\$f && rmdir \$\$f ; \\
		done; \\
		echo "Removing \$(top_builddir)/install.log" && rm -f \$(top_builddir)/install.log ; \\
	else \\
		echo "Removing all data unconditionally"; \\
		rm -f    \$(DESTDIR)\$(povconfdir)/povray.ini; \\
		rmdir    \$(DESTDIR)\$(povconfdir); \\
		rm -f    \$(DESTDIR)\$(povmandir)/povray.1; \\
		rmdir    \$(DESTDIR)\$(povmandir); \\
		rm -f    \$(DESTDIR)\$(povconfuser)/povray.conf; \\
		rm -f    \$(DESTDIR)\$(povconfuser)/povray.ini; \\
		rmdir    \$(DESTDIR)\$(povconfuser); \\
		rm -f -r \$(DESTDIR)\$(povbinbase); \\
		rm -f -r \$(DESTDIR)\$(povdocdir); \\
		rm -f -r \$(DESTDIR)\$(povlibdir); \\
	fi; \\
	echo "\$(PACKAGE) uninstall finished"
pbEOF
	;;
esac


###
### ../bootstrap
###

bootstrap="../bootstrap"

case "$1" in
	clean)
	for file in $bootstrap; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	echo "Create $bootstrap"
	cat << pbEOF > $bootstrap
#!/bin/sh -x

# bootstrap for the source distribution of LPub3D-Trace $pov_version_base for UNIX
# Please report bugs to $pov_config_bugreport
# Run this script if configure.ac or any Makefile.am has changed

rm -f config.log config.status

# Create aclocal.m4 for extra automake and autoconf macros
aclocal -I .

# Create config.h.in
autoheader --warnings=all

# Create all Makefile.in's from Makefile.am's
automake --add-missing --warnings=all

# Create configure from configure.ac
autoconf --warnings=all

# Small post-fixes to 'configure'
#   add --srcdir when using --help=recursive
#   protect \$ac_(pop)dir with double quotes in cd commands
#   protect \$am_aux_dir with double quotes when looking for 'missing'
cat ./configure | sed \\
	-e 's,configure.gnu  --help=recursive,& --srcdir=\$ac_srcdir,g' \\
	-e 's,\(cd \)\(\$ac_\)\(pop\)*\(dir\),\1"\2\3\4",g' \\
	-e 's,\$am_aux_dir/missing,\\\\"\$am_aux_dir\\\\"/missing,g' \\
	> ./configure.tmp
mv -f ./configure.tmp ./configure
chmod +x ./configure

# Remove cache directory
rm -f -r ./autom4te.cache
pbEOF

	chmod 755 $bootstrap
	;;
esac



##### Source directory ########################################################


###
### ../source/Makefile.am
###

dir="../source"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	files=`find $dir -name "*.cpp" -or -name "*.h" | sed s,"$dir/",,g | sort`

	echo "Create $makefile.am"
	cat Makefile.header > $makefile.am
	cat << pbEOF >> $makefile.am

# Makefile.am for the source distribution of LPub3D-Trace $pov_version_base for UNIX
# Please report bugs to $pov_config_bugreport

# Libraries to build.
noinst_LIBRARIES = libpovray.a

# Source files.
libpovray_a_SOURCES = \\
	`echo $files`

cppflags_platformcpu =
if BUILD_x86
cppflags_platformcpu += -I\$(top_srcdir)/platform/x86
endif

# Include paths for headers.
AM_CPPFLAGS = \\
	-I\$(top_srcdir)/unix/povconfig \\
	-I\$(top_srcdir) \\
	-I\$(top_srcdir)/platform/unix \\
	\$(cppflags_platformcpu) \\
	-I\$(top_srcdir)/unix \\
	-I\$(top_srcdir)/vfe \\
	-I\$(top_srcdir)/vfe/unix
pbEOF
	;;
esac


###
### ../source/base/Makefile.am
###

dir="../source/base"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../source/frontend/Makefile.am
###

dir="../source/frontend"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac

###
### ../source/backend/Makefile.am
###

dir="../source/backend"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac



##### Supporting libraries ####################################################

###
### ../libraries/Makefile.am
###

makefile="../libraries/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac

###
### ../libraries/sdl2/Makefile.in
###

sdlPrefix="../libraries/sdl2"
makefile="$sdlPrefix/Makefile"

case "$1" in
	clean)
	for file in $makefile $makefile.in $makefile.rules ; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	for file in "$sdlPrefix/config.status" "$sdlPrefix/sdl2-config.cmake" "$sdlPrefix/SDL2.spec" \
				"$sdlPrefix/sdl2-config" "$sdlPrefix/sdl2.pc" "$sdlPrefix/config.log" "$sdlPrefix/libtool"; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -d "$sdlPrefix/include/SDL2"; then
		rm -f "$sdlPrefix/include/SDL2" 2> /dev/null && echo "Cleanup $sdlPrefix/include/SDL2 (symbolic link)";
	fi
	;;

	doc*)
	;;

	*)
	# add SDL2 SimLink
	if ! test -d "$sdlPrefix/include/SDL2"; then
		here=$PWD
		cd "$sdlPrefix/include" && ln -s . ./SDL2 2> /dev/null && cd "$here" && echo "Create $sdlPrefix/include/SDL2 symbolic link.";
	else
		echo "Create $sdlPrefix/include/SDL2 symbolic link ignored - link exist.";
	fi
	echo "Create $makefile.in"
	cat << pbEOF > $makefile.in
# Makefile to build and setup the SDL library

# This configuration uses custom libdir and includedir paths
# filled during make e.g. "make exec_prefix=/foo" or
# using AM_MAKEFLAGS = "exec_prefix=/foo" when calling from
# another makefile.
top_builddir = .
srcdir  = @srcdir@
objects = build
gen     = gen
prefix  = @prefix@
exec_prefix =  @exec_prefix@
libdir  = \${exec_prefix}/\$(objects)/lib
includedir = \${exec_prefix}/\$(objects)/include
auxdir  = @ac_aux_dir@



@SET_MAKE@
SHELL   = @SHELL@
CC      = @CC@
INCLUDE = @INCLUDE@
CFLAGS  = @BUILD_CFLAGS@
EXTRA_CFLAGS = @EXTRA_CFLAGS@
LDFLAGS = @BUILD_LDFLAGS@
EXTRA_LDFLAGS = @EXTRA_LDFLAGS@
LIBTOOL = @LIBTOOL@
INSTALL = @INSTALL@
AR      = @AR@
RANLIB  = @RANLIB@
WINDRES = @WINDRES@
LN_S    = @LN_S@

TARGET  = libSDL2.la
OBJECTS = @OBJECTS@
GEN_HEADERS = @GEN_HEADERS@
GEN_OBJECTS = @GEN_OBJECTS@
VERSION_OBJECTS = @VERSION_OBJECTS@

SDLMAIN_TARGET = libSDL2main.a
SDLMAIN_OBJECTS = @SDLMAIN_OBJECTS@

WAYLAND_SCANNER = @WAYLAND_SCANNER@

ifneq (\$V,1)
RUN_CMD_AR     = @echo "  AR    " \$@;
RUN_CMD_CC     = @echo "  CC    " \$@;
RUN_CMD_CXX    = @echo "  CXX   " \$@;
RUN_CMD_LTLINK = @echo "  LTLINK" \$@;
RUN_CMD_RANLIB = @echo "  RANLIB" \$@;
RUN_CMD_GEN    = @echo "  GEN   " \$@;
LIBTOOL += --quiet
endif

HDRS = \\
	SDL.h \\
	SDL_assert.h \\
	SDL_atomic.h \\
	SDL_audio.h \\
	SDL_bits.h \\
	SDL_blendmode.h \\
	SDL_clipboard.h \\
	SDL_cpuinfo.h \\
	SDL_egl.h \\
	SDL_endian.h \\
	SDL_error.h \\
	SDL_events.h \\
	SDL_filesystem.h \\
	SDL_gamecontroller.h \\
	SDL_gesture.h \\
	SDL_haptic.h \\
	SDL_hints.h \\
	SDL_joystick.h \\
	SDL_keyboard.h \\
	SDL_keycode.h \\
	SDL_loadso.h \\
	SDL_log.h \\
	SDL_main.h \\
	SDL_messagebox.h \\
	SDL_mouse.h \\
	SDL_mutex.h \\
	SDL_name.h \\
	SDL_opengl.h \\
	SDL_opengl_glext.h \\
	SDL_opengles.h \\
	SDL_opengles2_gl2ext.h \\
	SDL_opengles2_gl2.h \\
	SDL_opengles2_gl2platform.h \\
	SDL_opengles2.h \\
	SDL_opengles2_khrplatform.h \\
	SDL_pixels.h \\
	SDL_platform.h \\
	SDL_power.h \\
	SDL_quit.h \\
	SDL_rect.h \\
	SDL_render.h \\
	SDL_rwops.h \\
	SDL_scancode.h \\
	SDL_shape.h \\
	SDL_stdinc.h \\
	SDL_surface.h \\
	SDL_system.h \\
	SDL_syswm.h \\
	SDL_thread.h \\
	SDL_timer.h \\
	SDL_touch.h \\
	SDL_types.h \\
	SDL_version.h \\
	SDL_video.h \\
	begin_code.h \\
	close_code.h

LT_AGE      = @LT_AGE@
LT_CURRENT  = @LT_CURRENT@
LT_RELEASE  = @LT_RELEASE@
LT_REVISION = @LT_REVISION@
LT_LDFLAGS  = -no-undefined -rpath \$(DESTDIR)\$(libdir) -release \$(LT_RELEASE) -version-info \$(LT_CURRENT):\$(LT_REVISION):\$(LT_AGE)

all: \$(srcdir)/configure Makefile \$(objects) \$(objects)/\$(TARGET) \$(objects)/\$(SDLMAIN_TARGET) build-setup

\$(srcdir)/configure: \$(srcdir)/configure.in
	@echo "Warning, configure.in is out of date"
	#(cd \$(srcdir) && sh autogen.sh && sh configure)
	@sleep 3

Makefile: \$(srcdir)/Makefile.in
	\$(SHELL) config.status \$@

Makefile.in:;

\$(objects):
	\$(SHELL) \$(auxdir)/mkinstalldirs \$@

update-revision:
	\$(SHELL) \$(auxdir)/updaterev.sh

.PHONY: all update-revision build-setup clean distclean \$(OBJECTS:.lo=.d)

\$(objects)/\$(TARGET): \$(GEN_HEADERS) \$(GEN_OBJECTS) \$(OBJECTS) \$(VERSION_OBJECTS)
	\$(RUN_CMD_LTLINK)\$(LIBTOOL) --tag=CC --mode=link \$(CC) -o \$@ \$(OBJECTS) \$(GEN_OBJECTS) \$(VERSION_OBJECTS) \$(LDFLAGS) \$(EXTRA_LDFLAGS) \$(LT_LDFLAGS)

\$(objects)/\$(SDLMAIN_TARGET): \$(SDLMAIN_OBJECTS)
	\$(RUN_CMD_AR)\$(AR) cru \$@ \$(SDLMAIN_OBJECTS)
	\$(RUN_CMD_RANLIB)\$(RANLIB) \$@
	\$(SHELL) \$(auxdir)/mkinstalldirs \$(DESTDIR)\$(libdir)
	\$(INSTALL) -m 644 \$(objects)/\$(SDLMAIN_TARGET) \$(DESTDIR)\$(libdir)/\$(SDLMAIN_TARGET)
	\$(RUN_CMD_RANLIB)\$(RANLIB) \$(DESTDIR)\$(libdir)/\$(SDLMAIN_TARGET)

build-setup:
	\$(LIBTOOL) --mode=install \$(INSTALL) \$(objects)/\$(TARGET) \$(DESTDIR)\$(libdir)/\$(TARGET)
	@echo "Removing dynamic libraries..."
	@find \$(DESTDIR)\$(libdir) \\( \\
		-name '*.so*' -o \\
		-name '*.dylib' -o \\
		-name '.#*' \\) \\
	-exec rm -f {} \\;
	@echo "Done."

clean:
	rm -rf \$(objects)
	rm -rf \$(gen)

distclean: clean
	rm -f Makefile Makefile.rules sdl2-config
	rm -f config.status config.cache config.log libtool
	rm -rf \$(srcdir)/autom4te*
	if test -d include/SDL2; then rm -f include/SDL2 2> /dev/null; fi
	find \$(srcdir) \\( \\
		-name '*~' -o \\
		-name '*.bak' -o \\
		-name '*.old' -o \\
		-name '*.rej' -o \\
		-name '*.orig' -o \\
		-name '.#*' \\) \\
	-exec rm -f {} \\;
pbEOF
	;;
esac


##### Supporting libraries: PNG ###############################################

###
### ../libraries/png/configure.ac and configure.gnu
###

configure="../libraries/png/configure"

case "$1" in
	clean)
	for file in $configure.ac $configure.gnu; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -f $configure.orig; then
		echo "Restore $configure"
		mv -f $configure.orig $configure
	fi
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/png/Makefile.am
###

dir="../libraries/png"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/png/bootstrap
###

bootstrap="../libraries/png/bootstrap"

case "$1" in
	clean)
	for file in $bootstrap; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac




##### Supporting libraries: ZLIB ##############################################

###
### ../libraries/zlib/configure.ac and configure.gnu
###

configure="../libraries/zlib/configure"
makefile="../libraries/zlib/Makefile"

case "$1" in
	clean)
	for file in $configure.ac $configure.gnu; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -f $configure.orig; then
		echo "Restore $configure"
		mv -f $configure.orig $configure
	fi
	if test -f $makefile.orig; then
		echo "Restore $makefile"
		mv -f $makefile.orig $makefile
	fi
	if test -f $makefile.in.orig; then
		echo "Restore $makefile.in"
		mv -f $makefile.in.orig $makefile.in
	fi
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/zlib/Makefile.am
###

makefile="../libraries/zlib/Makefile"

case "$1" in
	clean)
	for file in $makefile.am; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -f $makefile.in.orig; then
		echo "Restore $makefile.in"
		mv -f $makefile.in.orig $makefile.in
	fi
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/zlib/bootstrap
###

bootstrap="../libraries/zlib/bootstrap"

case "$1" in
	clean)
	for file in $bootstrap; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/zlib/ config scripts
###

dir="../libraries/zlib"

# no longer distributed
rm -f $dir/mkinstalldirs

case "$1" in
	clean)
	for file in config.guess config.sub install-sh missing ; do
		rm $dir/$file 2> /dev/null  &&  echo "Cleanup $dir/$file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac




##### Supporting libraries: JPEG ##############################################

###
### ../libraries/jpeg/configure.gnu
###

configure="../libraries/jpeg/configure"

case "$1" in
	clean)
	for file in $configure.gnu; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac




##### Supporting libraries: TIFF ##############################################

###
### ../libraries/tiff/libtiff/configure.ac and configure.gnu
###

configure="../libraries/tiff/libtiff/configure"

# remove old configure.gnu
rm -f ../libraries/tiff/configure.gnu

case "$1" in
	clean)
	for file in $configure.ac $configure.gnu; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/tiff/libtiff/Makefile.am
###

makefile="../libraries/tiff/libtiff/Makefile"

case "$1" in
	clean)
	for file in $makefile.am; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -f $makefile.in.orig; then
		echo "Restore $makefile.in"
		mv -f $makefile.in.orig $makefile.in
	fi
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/tiff/libtiff/bootstrap
###

bootstrap="../libraries/tiff/libtiff/bootstrap"

case "$1" in
	clean)
	for file in $bootstrap; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/tiff/libtiff/ config scripts
###

dir="../libraries/tiff/libtiff"

case "$1" in
	clean)
	for file in config.guess config.sub install-sh missing ; do
		rm $dir/$file 2> /dev/null  &&  echo "Cleanup $dir/$file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac



##### Supporting libraries: Boost #############################################

###
### ../libraries/boost/configure.ac and configure.gnu
###

configure="../libraries/boost/configure"

case "$1" in
	clean)
	for file in $configure.ac $configure.gnu; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -f $configure.orig; then
		echo "Restore $configure"
		mv -f $configure.orig $configure
	fi
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/boost/Makefile.am
###

dir="../libraries/boost"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac

###
### ../libraries/boost/bootstrap
###

bootstrap="../libraries/boost/bootstrap"

case "$1" in
	clean)
	for file in $bootstrap; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac


###
### ../libraries/boost/ config scripts
###

dir="../libraries/boost"

case "$1" in
	clean)
	for file in config.guess config.sub install-sh missing configure ; do
		rm $dir/$file 2> /dev/null  &&  echo "Cleanup $dir/$file"
	done
	test -d $dir  &&  rm -rf $dir  &&  echo "Cleanup $dir"
	;;

	doc*)
	;;

	*)
	;;
esac




##### VFE #####################################################################

###
### ../vfe/Makefile.am
###

dir="../vfe"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	# includes the vfe/unix/ files to avoid circular dependencies when linking
	files=`find $dir $dir/unix -maxdepth 1 -name \*.cpp -or -name \*.h | sed s,"$dir/",,g | sort`

	echo "Create $makefile.am"
	cat Makefile.header > $makefile.am
	cat << pbEOF >> $makefile.am

# Makefile.am for the source distribution of LPub3D-Trace $pov_version_base for UNIX
# Please report bugs to $pov_config_bugreport

# Libraries to build.
noinst_LIBRARIES = libvfe.a

# Source files.
libvfe_a_SOURCES = \\
	`echo $files`

cppflags_platformcpu =
if BUILD_x86
cppflags_platformcpu += -I\$(top_srcdir)/platform/x86
endif

# Include paths for headers.
AM_CPPFLAGS = \\
	-I\$(top_srcdir)/unix/povconfig \\
	-I\$(top_srcdir)/platform/unix \\
	\$(cppflags_platformcpu) \\
	-I\$(top_srcdir)/vfe/unix \\
	-I\$(top_srcdir)/unix \\
	-I\$(top_srcdir)/source

if USE_SDL2_SRC
# Build the SDL2 library - if specified - before unix subdir.
AM_MAKEFLAGS =

# Include paths for headers -added when building at command line.
AM_CPPFLAGS += \\
	-I\$(top_srcdir)/libraries/sdl2/include \\
	-I\$(top_srcdir)/libraries/sdl2/include/SDL2

sdl2_builddir = \$(top_builddir)/libraries/sdl2
sdl2_abs_builddir = \$(abs_top_builddir)/libraries/sdl2

if USE_SDL2_SRC_MACOS
# Update AM_MAKEFLAGS/CC with MACOS SDK options as required
AM_MAKEFLAGS += "CC=@CC@"
endif

# Install where built to enable cross-compiling
AM_MAKEFLAGS += "exec_prefix=\$(sdl2_abs_builddir)"

all-am: sdl-build-from-source-local
sdl-build-from-source-local:
	@echo "Building SDL from source at \$(sdl2_abs_builddir)..."
	cd \$(sdl2_builddir) && \$(MAKE) \$(AM_MAKEFLAGS)
endif

# Extra definitions for compiling.
# They cannot be placed in config.h since they indirectly rely on \$prefix.
DEFS = \\
	@DEFS@ \\
	-DPOVLIBDIR=\"\$(sysuserdatapath)/@PACKAGE@-@VERSION_BASE@/resources\" \\
	-DPOVCONFDIR=\"\$(userdatapath)/@PACKAGE@-@VERSION_BASE@/resources/config\" \\
	-DPOVCONFDIR_BACKWARD=\"\$(userdatapath)/@PACKAGE@-@VERSION_BASE@/resources/config\"
pbEOF
	;;
esac




##### Platform ################################################################

###
### ../platform/Makefile.am
###

dir="../platform"
makefile="$dir/Makefile"

case "$1" in
	clean)
	for file in $makefile.am $makefile.in; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	;;

	doc*)
	;;

	*)
	files=`find $dir/unix -name "*.cpp" -or -name "*.h" | sed s,"$dir/",,g | sort`
	files_x86=`find $dir/x86 -maxdepth 1 -name "*.cpp" -or -name "*.h" | sed s,"$dir/",,g | sort`
	for ext in avx avxfma4 avx2fma3; do
		files_ext=`find $dir/x86/$ext -name "*.cpp" -or -name "*.h" | sed s,"$dir/",,g | sort`
		eval files_x86$ext='$files_ext'
	done

	echo "Create $makefile.am"
	cat Makefile.header > $makefile.am
	cat << pbEOF >> $makefile.am

# Makefile.am for the source distribution of LPub3D-Trace $pov_version_base for UNIX
# Please report bugs to $pov_config_bugreport

# Platform-specifics.
cppflags_platformcpu =
libraries_platformcpu =
if BUILD_x86
cppflags_platformcpu += -I\$(top_srcdir)/platform/x86
libraries_platformcpu += libx86.a
libx86_a_SOURCES = `echo $files_x86`
libx86_a_CXXFLAGS = \$(CXXFLAGS)
endif
if BUILD_x86avx
libraries_platformcpu += libx86avx.a
libx86avx_a_SOURCES = `echo $files_x86avx`
libx86avx_a_CXXFLAGS = \$(CXXFLAGS) -mavx
endif
if BUILD_x86avxfma4
libraries_platformcpu += libx86avxfma4.a
libx86avxfma4_a_SOURCES = `echo $files_x86avxfma4`
libx86avxfma4_a_CXXFLAGS = \$(CXXFLAGS) -mavx -mfma4
endif
if BUILD_x86avx2fma3
libraries_platformcpu += libx86avx2fma3.a
libx86avx2fma3_a_SOURCES =  `echo $files_x86avx2fma3`
libx86avx2fma3_a_CXXFLAGS = \$(CXXFLAGS) -mavx2 -mfma
endif

# Libraries to build.
noinst_LIBRARIES = \\
	libplatform.a \\
	\$(libraries_platformcpu)

# Source files.
libplatform_a_SOURCES = \\
	`echo $files`

# Include paths for headers.
AM_CPPFLAGS = \\
	-I\$(top_srcdir)/unix/povconfig \\
	-I\$(top_srcdir)/platform/unix \\
	\$(cppflags_platformcpu) \\
	-I\$(top_srcdir)/vfe \\
	-I\$(top_srcdir)/vfe/unix \\
	-I\$(top_srcdir)/unix \\
	-I\$(top_srcdir)/source

# Extra definitions for compiling.
# They cannot be placed in config.h since they indirectly rely on \$prefix.
DEFS = \\
	@DEFS@ \\
	-DPOVLIBDIR=\"\$(sysapppath)/@PACKAGE@-@VERSION_BASE@/resources\" \\
	-DPOVCONFDIR=\"\$(userdatapath)/@PACKAGE@-@VERSION_BASE@/resources/config\" \\
	-DPOVCONFDIR_BACKWARD=\"\$(userdatapath)/@PACKAGE@-@VERSION_BASE@/resources/config\"
pbEOF
	;;
esac




###############################################################################
# Bootstrapping
###############################################################################

dir=".."
case "$1" in
	clean)
	# conf.h* is for backward compatibility
	for file in aclocal.m4 autom4te.cache conf.h conf.h.in conf.h.in~ config.h config.h.in config.h.in~ configure configure.ac Makefile Makefile.am Makefile.in stamp-h1; do
		rm -r $dir/$file 2> /dev/null  &&  echo "Cleanup $dir/$file"
	done
	;;

	doc*)
	;;

	*)
	echo "Run $dir/bootstrap"
	ok=`cd $dir/; ./bootstrap`
	# post-process DIST_COMMON in unix/Makefile.in
	for file in AUTHORS COPYING NEWS README CUI_README configure.ac ChangeLog; do
		sed "s,$file,,g" ./Makefile.in > ./Makefile.in.tmp
		mv -f ./Makefile.in.tmp ./Makefile.in
	done
	echo "Finished."
	;;
esac


dir="../libraries/zlib"
case "$1" in
	clean)
	# don't remove Makefile, Makefile.in
	for file in aclocal.m4 autom4te.cache config.h config.h.in Makefile.am stamp-h1; do
		rm -r $dir/$file 2> /dev/null  &&  echo "Cleanup $dir/$file"
	done
	;;

	doc*)
	;;

	*)
	;;
esac  # zlib


dir="../libraries/boost"
case "$1" in
	clean)
	for file in aclocal.m4 autom4te.cache config.h config.h.in Makefile Makefile.am Makefile.in stamp-h1; do
		rm -r $dir/$file 2> /dev/null  &&  echo "Cleanup $dir/$file"
	done
	;;
esac  # boost
