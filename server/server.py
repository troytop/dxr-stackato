#!/usr/bin/env python

print "Starting server...."

import os
from wsgiref.simple_server import make_server
import sys
from os.path import dirname, join

import_path = join(dirname(__file__), "dxr")
sys.path.insert(0, import_path)
try:
    from dxr.app import make_app
finally:
    sys.path.remove(import_path)

def application(environ, start_response):
    print "Making new app"
    return make_app(os.environ["DXR_FOLDER"])(environ, start_response)
make_server("", int(os.environ["VCAP_APP_PORT"]), application).serve_forever()