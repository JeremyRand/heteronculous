#!/usr/bin/env python3

import socket

print("Looking up Google...")
socket.getaddrinfo("www.google.com", 443)
print("Looked up Google.")
