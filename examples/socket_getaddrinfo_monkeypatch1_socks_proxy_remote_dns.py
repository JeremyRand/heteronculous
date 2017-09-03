#!/usr/bin/env python3

import socket
import socks

socks.set_default_proxy(socks.SOCKS5, "127.0.0.1", 9050)
socket.socket = socks.socksocket

print("Looking up Google...")
socket.getaddrinfo("www.google.com", 443)
print("Looked up Google.")
