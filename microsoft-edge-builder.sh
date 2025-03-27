#!/bin/sh

APP=microsoft-edge

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
	chmod a+x ./appimagetool
fi

# CREATE CHROME BROWSER APPIMAGES

_create_edge_appimage(){
	if wget --version | head -1 | grep -q ' 1.'; then
		wget -q --no-verbose --show-progress --progress=bar "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-$CHANNEL/$(curl -Ls https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-"$CHANNEL"/ | grep -Po '(?<=href=")[^"]*' | sort --version-sort | tail -1)"
	else
		wget "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-$CHANNEL/$(curl -Ls https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-"$CHANNEL"/ | grep -Po '(?<=href=")[^"]*' | sort --version-sort | tail -1)"
	fi
	ar x ./*.deb
	tar xf ./data.tar.xz
	mkdir "$APP".AppDir
	mv ./opt/microsoft/msed*/* ./"$APP".AppDir/
	[ ! -f ./"$APP".AppDir/*.desktop ] && mv ./usr/share/applications/*.desktop ./"$APP".AppDir/
	if [ "$CHANNEL" = "stable" ]; then
		cp ./"$APP".AppDir/"$APP" ./"$APP".AppDir/AppRun
		cp ./"$APP".AppDir/*128.png ./"$APP".AppDir/"$APP".png
	else
		cp ./"$APP".AppDir/"$APP"-"$CHANNEL" ./"$APP".AppDir/AppRun
		cp ./"$APP".AppDir/*128*png ./"$APP".AppDir/"$APP"-"$CHANNEL".png
	fi
	tar xf ./control.tar.xz
	VERSION=$(cat control | grep Version | cut -c 10-)
	ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|MS-Edge-appimage|continuous|*-$CHANNEL-*x86_64.AppImage.zsync" \
	./"$APP".AppDir Microsoft-Edge-"$CHANNEL"-"$VERSION"-x86_64.AppImage || exit 1
}

CHANNEL="stable"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_edge_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="beta"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_edge_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="dev"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_edge_appimage
cd ..
mv ./"$CHANNEL"/*.AppImage* ./

cd ..
mv ./tmp/*.AppImage* ./
