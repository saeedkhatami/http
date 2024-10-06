# Simple HTTP Server in Assembly (x86_64)

This project is a basic HTTP server written in x86_64 Assembly. It currently supports `GET`, `POST`, `PUT`, and `DELETE` methods, with proper error handling for `404 Not Found` and `405 Method Not Allowed`. The server uses `epoll` for efficient connection handling and operates with non-blocking I/O.

**Note**: This project is under development, and many features will be added soon.

## Features

- Supports HTTP methods: `GET`, `POST`, `PUT`, `DELETE`
- Routes:
  - `/` - Root (Welcome)
  - `/about` - About page
  - `/contact` - Contact page
- Error responses: `404 Not Found` and `405 Method Not Allowed`
- Non-blocking sockets using `epoll`

## Setup

1. Clone and navigate to the project:
    ```bash
    git clone https://github.com/saeedkhatami/http.git
    cd http
    ```

2. Compile and run:
    ```bash
    nasm -f elf64 HTTP.asm -o HTTP.o
    ld HTTP.o -o HTTP
    ./HTTP
    ```

3. Test the server using `curl`:
    ```bash
    curl http://localhost:8080/
    curl -X POST http://localhost:8080/
    ```

## License

MIT [License](LICENSE)

```text
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

### NOTE

This README was generated with the assistance of AI, ensuring it's clear and easy to follow.