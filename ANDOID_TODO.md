DELETE ME DONT PR THIS

FIXME tabs are being copied to gist with spaces instead of tabs, ugh

- Get a reproducible build, remaining manual quirks are:
 - argp header, fix this with quilt
 - bcc patches convert from sed to quilt, one for CMakeList, one for linux/types.h
- Try building for x86_64 and aarch64
 - Generate 64 or 32 wordsize correctly for bcc bits

- Improvements
 - libelf patches convert from sed to quilt

- Cleanups
 - Do a pass on the fixmes, try and make embedded files portable to other toolchains

- Enhancements
 - embed binutils for opcodes / bfd for btf support

- Credit Michal where appropriate

- Get this running in CI

- Get this up for review
