pofw.js
---

A simple port-forwarding program written in CoffeeScript.

It is inspired by the [pofw](https://github.com/m13253/pofw) project by @m13253. This program is no more than a node.js version of the `pofw` project plus the statistics functionality.

It listens on some TCP(UDP) ports and forwards packets to some other hosts' TCP(UDP) ports.

Installation
---

To install globally

```bash
npm install -g pofw.js
```

To install locally

```bash
npm install pofw.js
```

Or you may repackage this module and install it using the package manager of your system.

Usage
---

```
Usage: pofwjs -c [config] -s [statistics] -w [port]

Options:
  -c, --config      Path to the configuration file in JSON format
                                  [required] [default: "config.json"]
  -s, --statistics  Path to the statistics file where the program
                    will write usage statistics into
                              [required] [default: "statistics.json"]
  -w, --web         Web server port for showing statistics page (0 =
                    disable)    [number] [required] [default: "8080"]
  -h, --help        Show help                               [boolean]
```

See the `example` directory for details on the configuration file.

Supported protocols

1. tcp, tcp4, tcp6
2. udp, udp4, udp6

where `tcp4`, `tcp6` are only aliases of `tcp` and `udp` is an alias of `udp4`. This rule is inherited from the node.js standard library.

__CONVERSION BETWEEN TCP AND UDP IS NOT SUPPORTED__

Statistics
---

`pofwjs` will record the usage statistics in the file which is assigned by the `-s` or `--statistics` argument (by default it will be `statistics.json` in the current directory). And if the port is set to an non-zero number, say, `8080`, then a web frontend will be present at `127.0.0.1:8080`. Visit that address in your browser and a table with the usage statistics will be shown. The program also exposes an API `/backend/reset` which can reset all the statistics to 0 on receiving a `GET` request.

The web interface listens only on the loopback address `127.0.0.1`. If you want to access it over Internet, use Nginx as a reverse proxy. Remember to set up an authentication method like HTTP basic auth at least on the `/backend/` subdirectory.

The program stores the statistics in-memory and writes them into disk every minute or when killed with the signal `SIGINT`.

To get monthly usage statistics, you can combine the `/backend/reset` API with `curl` or similar tools and a `timer` utility like `systemd-timer`

License
---

```
Copyright © 2016 Peter Cai <peter at typeblog dot net>
This program is free software. It comes without any warranty, to the
extent permitted by applicable law. You can redistribute it and/or
modify it under the terms of the Do What The Fuck You Want To Public
License, Version 2, as published by Sam Hocevar. See the license below
for more details.
```

```
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
            Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

    DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO.
```
