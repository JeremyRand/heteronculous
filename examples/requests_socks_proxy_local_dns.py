#!/usr/bin/env python3

import requests

proxies = {
    'http': 'socks5://127.0.0.1:9050',
    'https': 'socks5://127.0.0.1:9050'
}

print("Getting Google...")
requests.get('https://www.google.com/', proxies=proxies)
print("Got Google.")
