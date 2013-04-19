# Syntax: sh webfontmaker.sh [x.xxx]
# x.xxx is an optional version number

# Remove files from previous iterations:
rm *.eot
rm *.ttf
rm *.svg

# Check if a version number was passed as argument:
if [[ $1 ]]; then
	version=$1
else
	# default = 1.001
	version="1.001"
fi

# If Meta.xml contains the string "x.xxx",
# attempt to insert the version number there:
metadataSRC="Meta.xml"
metadata="makeweb$metadataSRC"
sed 's/x.xxx/$version/' $metadataSRC > $metadata

# Create the fontforge script for later,
# unfortunately, fontforge -c seems to be broken...?
printf 'Open($1)¥nGenerate($1:r + ".svg")¥nScaleToEm(2048)¥nRoundToInt()¥nGenerate($1:r + ".ttf")' > makeweb.pe


# Process all OTFs in the folder:
for file in *.otf; do
	
	# Strip the ".otf" extension
	# and calculate the other names:
	basename=`echo "$file" | sed -e "s/¥.otf//"`
	otfFont="$basename.otf"
	ttfFont="$basename.ttf"
	eotFont="$basename.eot"
	ttfAHFont="$basename-autohinted.ttf"
	eotAHFont="$basename-autohinted.eot"
	woffFont="$basename.woff"
	svgFont="$basename.svg"

	echo
	echo Processing $basename ...
	
	# Make SVG and TTF:
	echo
	echo Creating $ttfFont and $svgFont ...
	fontforge -script makeweb.pe $otfFont
	
	# Fix SVG files:
	echo
	echo Fixing $svgFont ...
	sed '/^Created by .*$/d' $svgFont > tmp.svg; mv tmp.svg $svgFont
	sed 's/^<svg>/<svg xmlns="http:¥/¥/www.w3.org¥/2000¥/svg">/' $svgFont > tmp.svg; mv tmp.svg $svgFont
	
	# Autohint TTF:
	echo
	echo Creating $ttfAHFont ...
	ttfautohint $ttfFont $ttfAHFont
	
	# Make EOT:
	echo
	echo Creating $eotFont and $eotAHFont ...
	java -jar /Applications/sfntly/java/dist/tools/sfnttool/sfnttool.jar -e -x $ttfFont $eotFont
	java -jar /Applications/sfntly/java/dist/tools/sfnttool/sfnttool.jar -e -x $ttfAHFont $eotAHFont

	# Make WOFF:
	echo
	echo Creating $woffFont ...
	sfnt2woff -v $version -m $metadata $otfFont
	# woff-all $woffFont

done

# Clean up:
rm $metadata
rm makeweb.pe

echo
