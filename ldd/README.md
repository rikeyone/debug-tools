# Description

ldd script can find what libraries a binary is linked to. It is useful to found binary link error.

# Download

```
./download.sh
```
This command will clone a ldd git repo which include two versions of ldd.

linux-x86: this version is run on x86 platform.
arm64: this version could be run on arm64 platform.


# Port

ldd script can be port to other platforms by these three steps:

 - change first line *#!/bin/bash* to local shell interpreter, such as *#!/bin/sh*
 - change *RTLDLIST="/lib64/ld-linux-x86-64.so.2"* to the right ld-linux so location, such as *RTLDLIST="/lib/ld-linux-aarch64.so.1"*
 - put ldd to */bin* directory
