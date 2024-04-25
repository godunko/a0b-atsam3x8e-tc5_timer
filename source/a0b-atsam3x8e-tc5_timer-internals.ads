--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Time;

package A0B.ATSAM3X8E.TC5_Timer.Internals
  with Preelaborate
is

   procedure Set_Next
     (Span    : A0B.Time.Time_Span;
      Success : out Boolean);

   procedure Request_Tick;

private

   procedure Request_Tick renames Internal_Request_Tick;

   procedure Set_Next
     (Span    : A0B.Time.Time_Span;
      Success : out Boolean) renames Internal_Set_Next;

end A0B.ATSAM3X8E.TC5_Timer.Internals;
