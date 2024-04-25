--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.CMSIS;

with A0B.ATSAM3X8E.TC5_Timer.Internals;

separate (A0B.Timer)
package body Platform is

   ----------------------------
   -- Enter_Critical_Section --
   ----------------------------

   procedure Enter_Critical_Section
     renames A0B.ARMv7M.CMSIS.Disable_Interrupts;

   ----------------------------
   -- Leave_Critical_Section --
   ----------------------------

   procedure Leave_Critical_Section
     renames A0B.ARMv7M.CMSIS.Enable_Interrupts;

   ------------------
   -- Request_Tick --
   ------------------

   procedure Request_Tick
     renames A0B.ATSAM3X8E.TC5_Timer.Internals.Request_Tick;

   --------------
   -- Set_Next --
   --------------

   procedure Set_Next
     (Span    : A0B.Time.Time_Span;
      Success : out Boolean)
        renames A0B.ATSAM3X8E.TC5_Timer.Internals.Set_Next;

end Platform;
