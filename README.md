Kayprint
========
![Kayprint-Wordmark_4k](https://github.com/unlimitedbacon/kayprint/assets/8570835/1ea73ef3-7c34-4140-b101-2aa621d6b807)

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
