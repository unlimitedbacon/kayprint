#!/bin/python

# Simulates a printer by responding "ok" to every line sent over serial

import socket

host = "127.0.0.1"
port = 2023

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((host, port))

while (True):
    data = sock.recv(1024)
    print(data.decode(), end="", flush=True)
    if (b'\r' in data) or (b'\n' in data):
        sock.send(b"ok\n")
        print()
        print("ok")

    if len(data) == 0:
        break