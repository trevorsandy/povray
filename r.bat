SET POV_BUILD_PKG=yes
IF /I "%POV_BUILD_PKG%" EQU "yes" (
	CD windows\vs2015
	autobuild -allcui -allins
) ELSE (
	CD windows\vs2015
	autobuild x86 -chk
	autobuild x86_64 -chk
)