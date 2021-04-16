---
name: Problems with parsing .env files
about: Compatibility with other dotenv implementations
title: ''
labels: ''
assignees: ''

---

**Which dotenv is not compatible with?**

Only incompatibilities with other dotenv implementations will be fixed (except for `posix` dialect).

NOTE: Problems with the default `posix` dialect will not be accepted if they violate the posix shell specification. Ref. [POSIX-compliant .env syntax specification](https://github.com/ko1nksm/shdotenv/blob/main/docs/specification.md)

**Why do we need that compatibility?**

Since there is no official specification for the syntax of .env, we do not aim for full compatibility. If possible, please modify .env.
