cd ./swf_scanner
gcc -x c swf_scanner.c adler32.c crc32.c inffast.c inflate.c inftrees.c zutil.c -o swf_scanner.exe -static-libgcc