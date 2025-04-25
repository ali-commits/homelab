# RustDesk Research (Server Component)

## Description
RustDesk is an open-source remote desktop application designed for self-hosting, serving as an alternative to TeamViewer. The RustDesk Server is the component that allows users to run their own signaling and relay server.

## Main Features (RustDesk Server)
- Self-hostable signaling and relay server
- Enables remote access and control
- Supports secure file transfer and remote session recording (features of the overall RustDesk solution, enabled by the server)

## Source Code Link (RustDesk Server)
https://github.com/rustdesk/rustdesk-server

## Docker Image Links (RustDesk Server)
- Main: rustdesk/rustdesk-server
- linuxserver.io: [Not the server, seems to be a client in a container]
- Alternative: [Not found in search]

## Requirements (RustDesk Server)
- Docker and Docker Compose
- Persistent storage for data
- Exposed ports for hbbs and hbbr services (e.g., 21115, 21116, 21117, 21118, 21119)
- RustDesk client applications to connect to the server
