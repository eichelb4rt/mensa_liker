#!/bin/bash

# sleep time in seconds
sleep_time=0.5
# appropriate mensa website of your choice
mensa_page="https://www.stw-thueringen.de/mensen/jena/mensa-ernst-abbe-platz.html"

# constants for the lynx output
n_lines_per_options=6
rscid_offset=1
proddat_offset=2
gebinde_offset=3
name_offset=5

# read the options from the website
options=$(lynx --dump "$mensa_page" -connect_timeout=10 | grep -P '^\s*\d\d\d\d-\d\d-\d\d' -B 2 -A 3)
n_lines=$(echo "$options" | wc -l)
# the number of options is the number of lines (+ 1 extra seperator) divided by the number of lines per options (+ the separators)
n_options=$((("$n_lines" + 1) / ("$n_lines_per_options" + 1)))
# split options into lines
mapfile -t lines <<<"$options"
# print all the numbers
for ((i = 0; i < "$n_options"; i++)); do
    food_index=$((("$n_lines_per_options" + 1) * "$i" + "$name_offset"))
    food=$(echo "${lines["$food_index"]}" | xargs)
    echo "$i: $food"
done

# read what they want to like
echo ""
echo "Which option do you want to like (0 - $(("$n_options" - 1))): "
read -r liked_option

# get the indices of stuff
rscid_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$rscid_offset"))
proddat_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$proddat_offset"))
gebinde_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$gebinde_offset"))
name_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$name_offset"))
# get the actual values
rscid=$(echo "${lines["$rscid_index"]}" | xargs)
proddat=$(echo "${lines["$proddat_index"]}" | xargs)
gebinde=$(echo "${lines["$gebinde_index"]}" | xargs)
name=$(echo "${lines["$name_index"]}" | xargs)
echo ""
echo -e "You chose: $name\nrscid: $rscid\nproddat: $proddat\ngebinde: $gebinde"

# how many times do they want to like it?
echo ""
echo "How many times do you want to like it: "
read -r wanted_likes
echo ""

# like the stuff
for ((i = 0; i < "$wanted_likes"; i++)); do
    current_likes=$(curl -s \
        --data-urlencode "essenname=$name" \
        --data-urlencode "rscid=$rscid" \
        --data-urlencode "proddat=$proddat" \
        --data-urlencode "gebinde=$gebinde" \
        --data-urlencode "symbols=" \
        --data-urlencode "context=" \
        -X POST https://www.stw-thueringen.de/xhr/quicklike.html --compressed)
    echo "current likes: $current_likes (likes left: $(("$wanted_likes" - "$i" - 1)))"
    sleep "$sleep_time"
done
