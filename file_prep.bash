#!/bin/bash

# Remove 'EXTR_' prefixes
rename 's/^(EXTR_)//' ./data/*

# Loop through all of the files and put them in a database

# Uses csvkit, decided to set password in ~/.pgpass file on client instead
# echo -n "Enter database password"
# read -s PASSWORD

for csv_file in `ls ./data/*.csv`; do
    TABLE_NAME="$(basename "$csv_file" .csv)"
    echo -n
    # echo -n "$TABLE_NAME"
    SQL=`csvsql -i postgresql -e "latin1" --tables "$TABLE_NAME" $csv_file`
    SQL="SET search_path TO 'assessor_data'; "$SQL" \COPY \""$TABLE_NAME"\" FROM '"$csv_file"' DELIMITER ',' CSV HEADER QUOTE '\"' ENCODING 'latin1';"
    echo "$SQL" | psql -h "handelstaccato.homenet.org" -p 5432 -U gavin king_county
    # "postgresql://gavin:$PASSWORD@handelstaccato.homenet.org:5432/king_county"
    echo -n "$SQL"
    echo -n
done
