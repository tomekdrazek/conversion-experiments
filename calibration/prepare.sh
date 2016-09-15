for f in *.tiff; do
  convert "$f" -fx C "$f.c.tif"
  convert "$f" -fx M "$f.m.tif"
  convert "$f" -fx Y "$f.y.tif"
  convert "$f" -fx K "$f.k.jpg"
  convert "$f.c.tif" "$f.m.tif" "$f.y.tif" -set colorspace RGB -combine "$f.cmy.jpg"
done
