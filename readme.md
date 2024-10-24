# Simple HTTP Server in Assembly and C (x86_64)

This project is a basic HTTP server written in **x86_64 Assembly** and a splash of **C** for extra flavor!. It currently supports `GET`.

Other HTTP methods (`POST`, `PUT`, `DELETE`, etc.) are not currently supported and will return **404 Not Found**.

**Note**: This project is under development, and many features will be added soon.

## Features

- Supports HTTP methods: `GET`
- Routes:
  - `/` - Root (Welcome)
  - `/about` - About page

## Setup

1. Clone and navigate to the project:
    ```bash
    git clone https://github.com/saeedkhatami/http.git
    cd http
    ```

2. Compile and run:
    ```bash
    make
    ./http_server
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
<<<<<<< HEAD
```
=======
```

### NOTE

This README was generated with the assistance of AI, ensuring it's clear and easy to follow.
>>>>>>> 81581bf35e2abd63b712d5d6a563e752d932ca6d
