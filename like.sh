#!/bin/bash

# sleep time in seconds
sleep_time=0.5
# appropriate mensa website of your choice
mensa_page="https://www.stw-thueringen.de/mensen/jena/mensa-ernst-abbe-platz.html"

# possible lines for the food name
possible_name_lines=3

# constants for the lynx output
# before date: tags, rscid
grep_before=2
# after date: gebinde, flags, name
grep_after=$((2 + "$possible_name_lines"))
n_lines_per_options=$(("$grep_before" + "$grep_after" + 1))
rscid_offset=1
proddat_offset=2
gebinde_offset=3
name_start_offset=5

read_name() {
    # reads the name of option number "$1"
    name_start_index=$((("$n_lines_per_options" + 1) * "$1" + "$name_start_offset"))
    # it is assumed that lines are only split where spaces orginally were
    joined=$(echo "${lines["$name_start_index"]}" | xargs)
    for ((name_line_index = 1; name_line_index < "$possible_name_lines"; name_line_index++)); do
        # see if there is the keyword "Zusatzstoffe" in the current line. if there is, the name stopped
        current_line_index=$((("$n_lines_per_options" + 1) * "$1" + "$name_start_offset" + "$name_line_index"))
        current_line=$(echo "${lines["$current_line_index"]}" | xargs)
        if [[ "$current_line" =~ "Zusatzstoffe" ]]; then
            break
        fi
        # line did not contain "Zusatzstoffe", so the name continues.
        joined+=" $current_line"
    done
    echo "$joined"
}

# read the options from the website
options=$(lynx --dump "$mensa_page" -connect_timeout=10 | grep -P '^\s*\d\d\d\d-\d\d-\d\d' -B "$grep_before" -A "$grep_after") || exit 1
n_lines=$(echo "$options" | wc -l)
# the number of options is the number of lines (+ 1 extra seperator) divided by the number of lines per options (+ the separators)
n_options=$((("$n_lines" + 1) / ("$n_lines_per_options" + 1)))
# split options into lines
mapfile -t lines <<<"$options"
# print all the numbers
for ((i = 0; i < "$n_options"; i++)); do
    name=$(read_name "$i")
    echo "$i: $name"
done

# read what they want to like
echo ""
echo "Which option do you want to like (0 - $(("$n_options" - 1))): "
read -r liked_option

# make sure the input is correct
if ! [[ "$liked_option" =~ ^[0-9]+$ ]]; then
    echo "error: id must be a number" >&2
    exit 1
fi
if [[ "$liked_option" -lt 0 ]] || [[ "$liked_option" -ge "$n_options" ]]; then
    echo "error: id must be between 0 and $(("$n_options" - 1))." >&2
    exit 1
fi

# get the indices of stuff
rscid_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$rscid_offset"))
proddat_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$proddat_offset"))
gebinde_index=$((("$n_lines_per_options" + 1) * "$liked_option" + "$gebinde_offset"))
# get the actual values
rscid=$(echo "${lines["$rscid_index"]}" | xargs)
proddat=$(echo "${lines["$proddat_index"]}" | xargs)
gebinde=$(echo "${lines["$gebinde_index"]}" | xargs)
name=$(read_name "$liked_option")
echo ""
echo -e "You chose: $name\nrscid: $rscid\nproddat: $proddat\ngebinde: $gebinde"

# how many times do they want to like it?
echo ""
echo "How many times do you want to like it: "
read -r wanted_likes

# make sure the number of times is a number
if ! [[ "$wanted_likes" =~ ^[0-9]+$ ]]; then
    echo "error: amount of likes must be a number" >&2
    exit 1
fi

# like the stuff
echo ""
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
