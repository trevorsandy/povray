#!/bin/sh

##### Supporting libraries: SDL2 ##############################################

###
### ../libraries/sdl2/Makefile.in
###

#sdlPrefix="../libraries/sdl2"
sdlPrefix="."
### cut below here ###

makefile="$sdlPrefix/Makefile"

case "$1" in
	clean)
	{ set +x; } 2>/dev/null
	for file in $makefile $makefile.in $makefile.rules ; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	for file in "$sdlPrefix/config.status" "$sdlPrefix/sdl2-config.cmake" "$sdlPrefix/SDL2.spec" \
				"$sdlPrefix/sdl2-config" "$sdlPrefix/sdl2.pc" "$sdlPrefix/config.log" "$sdlPrefix/libtool"; do
		rm $file 2> /dev/null  &&  echo "Cleanup $file"
	done
	if test -d include/SDL2; then
		rm -f include/SDL2 2> /dev/null && echo "Cleanup $sdlPrefix/include/SDL2 (symbolic link)";
	fi
	{ set -x; } 2>/dev/null
	;;

	doc*)
	;;

	*)
	echo "Create $makefile.in"
	cat << pbEOF > $makefile.in
# Makefile to build and setup the SDL library

top_builddir = .
srcdir  = @srcdir@
objects = build
gen = gen
prefix  = @srcdir@/\$(objects)
exec_prefix = @exec_prefix@
libdir  = @libdir@
includedir = @includedir@
auxdir  = @ac_aux_dir@

@SET_MAKE@
SHELL = @SHELL@
CC      = @CC@
INCLUDE = @INCLUDE@
CFLAGS  = @BUILD_CFLAGS@
EXTRA_CFLAGS = @EXTRA_CFLAGS@
LDFLAGS = @BUILD_LDFLAGS@
EXTRA_LDFLAGS = @EXTRA_LDFLAGS@
LIBTOOL = @LIBTOOL@
INSTALL = @INSTALL@
AR  = @AR@
RANLIB  = @RANLIB@
WINDRES = @WINDRES@

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
	@{ set +x; } 2>/dev/null
	@find \$(DESTDIR)\$(libdir) \\( \\
		-name '*.so*' -o \\
		-name '.#*' \\) \\
	-exec rm -f {} \\;
	@echo "Creating SDL2 include symbolic link..."
	@if test ! -d include/SDL2; then \\
		cd include; \\
		ln -s . ./SDL2 2> /dev/null && echo "Symbolic link \$(DESTDIR)\$(includedir)/SDL2 created."; \\
		cd ../; \\
	else \\
		echo "Ignored - SDL2 symbolic link exist."; \\
	fi
	@{ set -x; } 2>/dev/null

clean:
	rm -rf \$(objects)
	rm -rf \$(gen)

distclean: clean
	rm -f Makefile Makefile.rules sdl2-config
	rm -f config.status config.cache config.log libtool
	rm -rf \$(srcdir)/autom4te*
	if test -d include/SDL2; then
		rm -f include/SDL2 2> /dev/null && echo "Cleanup \$(DESTDIR)\$(includedir)/SDL2 (symbolic link)";
	fi
	find \$(srcdir) \\( \\
		-name '*~' -o \\
		-name '*.bak' -o \\
		-name '*.old' -o \\
		-name '*.rej' -o \\
		-name '*.orig' -o \\
		-name '.#*' \\) \\
	-exec rm -f {} \\;
pbEOF

### cut above here ###
  ;;
esac

