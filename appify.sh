#!/bin/bash

author="appify"
icon=""
id=""
name="My Application"
version="1.0"
menubar=0

# check getopt
getoptVersion=$(getopt --version)
if [ "$getoptVersion" = " --" ]; then
	echo "It seems getopt is not GNU version, please install it first"
	exit
fi

opts=$(getopt -o a:c:hi:mn:v: --long author:,icon:,help,id:,menubar,name:,version: -n $(basename "$0") -- "$@")

eval set --$opts

showHelp=0
while [[ $# -gt 0 ]]; do
	case "$1" in
	-a | --author)
		author=$2
		shift 2
		;;
	-c | --icon)
		icon=$2
		shift 2
		;;
	-h | --help)
		showHelp=1
		shift
		;;
	-i | --id)
		id=$2
		shift 2
		;;
	-m | --menubar)
		menubar=1
		shift
		;;
	-n | --name)
		name=$2
		shift 2
		;;
	-v | --version)
		version=$2
		shift 2
		;;
	*)
		break
		;;
	esac
done

if [[ $# -ne 2 || $showHelp -eq 1 ]]; then
	cat <<EOF
Usage: $0 [options] executable-file
  -a, --author string
    	author (default "appify")
  -c, --icon string
    	icon image file (.iconset|.icns|.png|.jpg|.jpeg)
  -h, --help
        print this help info
  -i, --id string
    	bundle identifier
  -m, --menubar
        for menu bar only app
  -n, --name string
    	app name (default "My Application")
  -v, --version string
    	app version (default "1.0")
EOF
	exit
fi

targetFile=$2
if [ ! -f "$targetFile" ]; then
	echo "$targetFile not exists."
	exit
fi

# echo "author:$author,icon:$icon,id:$id,name:$name,version:$version"

appName="${name}.app"
mkdir -p "${appName}/Contents/MacOS"
chmod +x "${appName}/Contents/MacOS"
mkdir -p "${appName}/Contents/Resources"

cp "$targetFile" "${appName}/Contents/MacOS/${appName}"
chmod +x "${appName}/Contents/MacOS/${appName}"

if [ "$id" = "" ]; then
	id="${author}.${name}"
fi

if [ "$icon" != "" ]; then
	suffix="${icon##*.}"
	case "$suffix" in
	"png" | "jpg" | "jpeg")
		iconName="${icon%.*}"
		setName="${iconName}.iconset"
		mkdir "$setName"
		arr=(16 32 64 128 256 512)

		for i in ${arr[@]}; do
			let ttt=i*2
			sips -z $ttt $ttt "$icon" -o "$setName"/icon_${i}x${i}@2x.png >/dev/null
		done
		iconutil -c icns "$setName" -o "${appName}/Contents/Resources/icon.icns"
		rm -rf "$setName"
		;;

	"icns")
		cp "$icon" "${appName}/Contents/Resources/icon.icns"
		;;
	"iconset")
		iconutil -c icns "$icon" -o "${appName}/Contents/Resources/icon.icns"
		;;

	*)
		echo "unsupported icon file format $suffix"
		exit
		;;
	esac
fi

cat >"${appName}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>6.0</string>
		<key>CFBundleName</key>
		<string>$name</string>
		<key>CFBundleExecutable</key>
		<string>MacOS/${appName}</string>
		<key>CFBundleIdentifier</key>
		<string>$id</string>
		<key>CFBundleVersion</key>
		<string>$version</string>
		<key>CFBundleGetInfoString</key>
		<string>$name by $author</string>
		<key>CFBundleShortVersionString</key>
		<string>$version</string>
EOF

if [ "$icon" != "" ]; then
	cat >>"${appName}/Contents/Info.plist" <<EOF
		<key>CFBundleIconFile</key>
		<string>icon.icns</string>
EOF
fi

if [ $menubar -eq 1 ]; then
	cat >>"${appName}/Contents/Info.plist" <<EOF
		<key>LSUIElement</key>
		<true/>
EOF
fi

cat >>"${appName}/Contents/Info.plist" <<EOF
	</dict>
</plist>
EOF

cat >"${appName}/Contents/README" <<EOF
Made with appify

https://github.com/kumakichi/appify
EOF
