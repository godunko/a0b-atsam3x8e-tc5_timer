--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Implementation of the TImer on top of ATSAM3X8E TC5.
--
--  Note, this packahe exports TC5_Handler symbol to setup interrupt handler.

pragma Restrictions (No_Elaboration_Code);

private with A0B.Time;
with A0B.Types;

package A0B.ATSAM3X8E.TC5_Timer
  with Preelaborate
is

   type Timer_Clock_Source is (MCK_2, MCK_8, MCK_32, MCK_128);

   procedure Initialize
     (Master_Clock_Frequency : A0B.Types.Unsigned_32;
      Source                 : Timer_Clock_Source);

private

   procedure Internal_Request_Tick;

   procedure Internal_Set_Next
     (Span    : A0B.Time.Time_Span;
      Success : out Boolean);

end A0B.ATSAM3X8E.TC5_Timer;