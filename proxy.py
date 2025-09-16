#!/usr/bin/env python3

import argparse
import json

from http.server import BaseHTTPRequestHandler, HTTPServer


class SimpleHTTPHandler(BaseHTTPRequestHandler):
    def __init__(self, url_map, *args, **kwargs):
        self.url_map = url_map
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        host = self.headers['Host']
        path = self.path

        if urls := self.url_map.get(host):
            if file := urls.get(path):
                self.send_response(200)
                self.end_headers()
                
                with open(file, 'rb') as f:
                    self.write(write(f.read()))

                return

        self.send_error(404, "Not found in HTTP proxy")
    

def main():
    parser = argparse.ArgumentParser(prog='http proxy dummy')
    parser.add_argument('config')

    args = parser.parse_args()

    url_map = json.load(open(args.config, 'rb'))
    
    port = 1337
    server = HTTPServer(('', port), lambda *args, **kwargs: SimpleHTTPHandler(url_map, *args, **kwargs))
    server.serve_forever()



if __name__ == "__main__":
    main()
