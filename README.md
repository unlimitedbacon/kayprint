Kayprint
========

Running a 3D printer with an 80s retro computer. This program is for controlling a 3D printer over serial with a Kaypro II running CPM.

Assembling
----------

This program is written in Z80 assembly. We use the modern [scas](https://github.com/KnightOS/scas) assembler, but it should work with others.

```
scas kayprint.asm kayprint.com
```

Running (on Kaypro)
-------------------

```
kayprint file.gco
```
