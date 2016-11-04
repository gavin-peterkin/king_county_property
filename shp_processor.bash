#!/bin/bash

# Iterate through *.shp files and send to the database
# Makes use of 'postgis'

for shp_file in `ls ./data/gis/property/*.shp`; do
    TABLE_NAME="$(basename "$shp_file" .shp)"
    echo -n "$TABLE_NAME"
    # SRID: 2926
    # according to http://prj2epsg.org/search
    shp2pgsql -s 2926 "$shp_file" gis."$TABLE_NAME" >> "./data/gis/property/$TABLE_NAME.sql"
    cat "./data/gis/property/$TABLE_NAME.sql" | psql -h "handelstaccato.homenet.org" -p 5432 -U gavin king_county
done
