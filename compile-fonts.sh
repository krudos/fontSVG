#!/usr/bin/env bash
#https://github.com/gsandf/svg-to-ttf
set -eu -o pipefail

__dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

createConfiguration() {
	local input="$1"
	local fileCount="$(ls ${input} | wc -l)"
	local startUnicode=59905
	local endUnicode=$(( startUnicode + fileCount - 1 ))
	local currentUnicode=$startUnicode

	echo '{'

	for file in ${input}; do
		iconName="$(basename "$file" .svg)"
		printf '  "%s": %d' "$iconName" "$currentUnicode"
		if [[ "$currentUnicode" != "$endUnicode" ]]; then
			echo ','
		else
			echo
		fi
		currentUnicode=$(( currentUnicode + 1 ))
	done

	echo '}'
}

main() {
	local name
	local inputSVGs
	local config
	local fontFile

	while (( $# > 0 )); do
		arg="$1"

		case $arg in
			-n|--name) name=$2; shift;;
			-s|--svgs) inputSVGs=$2; shift;;
			-c|--config) config=$2; shift;;
			-f|--font) fontFile=$2; shift;;
			*) echo "Error: unrecognized argument '$1'" >&2; exit 1;
		esac

		shift
	done
	local tmpFontFile="$(mktemp || exit 1)"

	trap "{ rm -f ${tmpFontFile}; }" EXIT

	createConfiguration "$inputSVGs" > "$config"

	npx svgicons2svgfont --fontname "$name" -o "$tmpFontFile" "$inputSVGs" -h 1001 -n
	npx svg2ttf "$tmpFontFile" "${fontFile}/${name}.ttf"
	cp "${fontFile}/${name}.ttf" "../android/app/src/main/assets/fonts"
}

main "$@"
