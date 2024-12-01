[![Build and Release](https://github.com/saeedkhatami/http/actions/workflows/build-and-release.yml/badge.svg?branch=main)](https://github.com/saeedkhatami/http/actions/workflows/build-and-release.yml)

# HTTP

## Overview
This is a minimal HTTP server implemented in pure x86-64 assembly language, demonstrating low-level network programming and system calls.

## Features
- Basic HTTP GET and POST request handling
- Routing for different endpoints
- Manual memory management
- Direct system call interactions

## Endpoints

### GET Requests
- `/`: Returns a welcome message
- `/about`: Displays information about the server
- `/contact`: Shows contact page details

### POST Requests
- `/`: Echoes back the POST request body
- `/contact`: Processes and returns contact form data

## Example Interactions

### Using curl for GET Requests
```bash
curl 127.0.0.1:8080/

curl 127.0.0.1:8080/about

curl 127.0.0.1:8080/contact

curl -X POST -d "ASD" 127.0.0.1:8080/

curl -X POST -d "name=ASD&email=ASD@ASD.ASD" 127.0.0.1:8080/contact
```

### Using Browser 

just go to one of this pages:

- [127.0.0.1:8080/contact](http://127.0.0.1:8080/contact)

- [127.0.0.1:8080/about](http://127.0.0.1:8080/about)

- [127.0.0.1:8080/](http://127.0.0.1:8080/)

## Performance Characteristics
- Minimal memory overhead
- Direct syscall usage
- No external library dependencies
- Low latency response handling

## Technical Details
- Assembler: NASM
- Architecture: x86-64
- Operating System: Linux
- Syscalls used: `socket()`, `bind()`, `listen()`, `accept()`, `read()`, `write()`, `close()`

## Limitations
- Basic error handling
- No SSL/TLS support
- Single-threaded
- Minimal request parsing

## LICENSE

```LICENSE
MIT License

Copyright (c) 2024 Saeed Khatami

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
