#!/usr/bin/env python3

from urllib import request
import socket
import socks

socks.set_default_proxy(socks.SOCKS5, "127.0.0.1", 9050)
socket.socket = socks.socksocket

print("Opening Google...")
request.urlopen("https://www.google.com/")
print("Opened Google.")
