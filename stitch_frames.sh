#!/bin/bash

ffmpeg -framerate 60 -i frames/frame_%05d.png -c:v ffv1 screensaver60.mkv
