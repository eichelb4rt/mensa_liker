#!/bin/bash

lynx -dump "https://www.stw-thueringen.de/mensen/jena/mensa-ernst-abbe-platz.html" -connect_timeout=10 | tail -n +210 | head -n -332 | grep -P '^\s*\d\d\d\d-\d\d-\d\d' -B 2 -A 3