#!/usr/bin/env python3

import socket
import socks

socks.set_default_proxy(socks.SOCKS5, "127.0.0.1", 9050)
socket.socket = socks.socksocket

# Magic!  https://web.archive.org/web/20161211104525/http://fitblip.pub/2012/11/13/proxying-dns-with-python/
def getaddrinfo(*args):
    return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', (args[0], args[1]))]
socket.getaddrinfo = getaddrinfo

print("Looking up Google...")
socket.getaddrinfo("www.google.com", 443)
print("Looked up Google.")
