# Foxentry OpenAPI specification

This repository contains the OpenAPI specification for the Foxentry API. 
The specification can be seen on the [Foxentry.dev](https://foxentry.dev) developer hub.

## Contributing
The specification is split into multiple files, the main file is `openapi.yaml`.
Most viewers and editors can handle this without any problems, but you can always bundle the files together.

To generate the bundled file, you can use [redocly-cli](https://github.com/Redocly/redocly-cli) utility, running the following command:
```bash
redocly bundle openapi.yaml -o openapi-bundled.yaml
```

You can also find the bundled file in the releases section of this repository.
