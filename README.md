# A0B ATSAM3X8E High Precision Timer on top of TC5

This crate provides platform dependent implementation of the [A0B Timer](https://github.com/godunko/a0b-timer) on top of TC5 of the ATSAM3X8E MCU.

To initialize timer call `A0B.ATSAM3X8E.TC5_Timer.Initialize` subprogram:

```ada
   A0B.ATSAM3X8E.TC5_Timer.Initialize
     (84_000_000, A0B.ATSAM3X8E.TC5_Timer.MCK_32);
   --  Configure timer's tick duration to be MCK/32 (381 ns for CPU running at
   --  84MHz).
```
