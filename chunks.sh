#!/bin/bash

find example/chunks -type f -name "*.svg" -exec build/example2 {} \;

