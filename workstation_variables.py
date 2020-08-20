#!/usr/bin/env python

import os, os.path, sys
from distutils.spawn import find_executable

# Set out version and hash
MONGO_GIT_HASH = "unknown"
MONGO_VERSION = "0.0.0"

# Set a variety of nice to have variables
CXXFLAGS = ' '.join([
    '-fPIC',
    '-fno-var-tracking'
])

# Use icecc unless someoone says otherwise
if os.environ.get("USE_ICECC", "yes") != "no":
    ICECC = find_executable('icecc')

# Set a GB limit on cache size
CACHE_SIZE = 10
