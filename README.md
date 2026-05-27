# Decache
Decache is a specialized web cache scanner for Windows XP+. All items are reliably compared against metadata for pieces of lost media, with a focus on deleted YouTube videos.

## Command-line usage
You can side-step the file explorer window by supplying the path to your computer as a command-line argument, like so:
`start_decache.bat "E:\Backups\Old Laptop"`

Alternatively, you may scan multiple computers by supplying a text file with a path on every line:
`start_decache.bat computers.txt`

There are also 2 command-line switches:

`start_decache.bat /keepall`: save all unindexed videos to the "Unverified" folder.

`start_decache.bat /silence:1`: ignore all errors; make no action.

`start_decache.bat /silence:2`: ignore all errors, but always make one attempt to claim ownership of a directory you've been denied access to.

All these can be used alongside one-another.

## Binaries
FFmpeg binary compiled under the LGPL license: https://github.com/FFmpeg/FFmpeg/tree/b4bcd1e2f1d603419ea9d4fdaab400b1ad35e58c
