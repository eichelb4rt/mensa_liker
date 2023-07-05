#!/bin/bash

# appropriate mensa website of your choice
mensa_page="https://www.stw-thueringen.de/mensen/jena/mensa-ernst-abbe-platz.html"

lynx --dump "$mensa_page" -connect_timeout=10 | grep -P '^\s*\d\d\d\d-\d\d-\d\d' -B 2 -A 3