--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  All TCs of ATSAM3X8E has the same characteristics, however, best candidates
--  for Arduino Due are TC3/TC4/TC5, because their TIOA/TIOB pins are not
--  connected. TC5 is used.

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with A0B.ARMv7M.NVIC_Utilities; use A0B.ARMv7M.NVIC_Utilities;
with A0B.ATSAM3X8E.SVD.PMC;     use A0B.ATSAM3X8E.SVD.PMC;
with A0B.ATSAM3X8E.SVD.TC;      use A0B.ATSAM3X8E.SVD.TC;
with A0B.Timer.Internals;

package body A0B.ATSAM3X8E.TC5_Timer is

   procedure TC5_Handler
     with Export, Convention => C, External_Name => "TC5_Handler";

   Mul : A0B.Types.Unsigned_32;
   Div : constant A0B.Types.Unsigned_32 := 1_000_000_000;
   --  Multiplier and divider to convert time span in nanoseconds to the number
   --  of timer's ticks.

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Master_Clock_Frequency : A0B.Types.Unsigned_32;
      Source                 : Timer_Clock_Source)
   is
      use type A0B.Types.Unsigned_32;

      TCCLKS : CMR0_TCCLKS_Field;

   begin
      --  Compute timer's clock frequency
      --
      --  Reminder of the typical frequency of the Master Clock (84 MHz)
      --  divided by the clock divisor is zero. So, just precompute it and
      --  use later as multiplier in time span to ticks conversion.
      --
      --  Divisor in time span to ticks conversion is fixed to the number
      --  of nanoseconds in the second.

      case Source is
         when MCK_2 =>
            --  Internal MCK/2 clock signal (from PMC)

            TCCLKS := TIMER_CLOCK1;
            Mul    := Master_Clock_Frequency / 2;

         when MCK_8 =>
            --  Internal MCK/8 clock signal (from PMC)

            TCCLKS := TIMER_CLOCK2;
            Mul    := Master_Clock_Frequency / 8;

         when MCK_32 =>
            --  Internal MCK/32 clock signal (from PMC)

            TCCLKS := TIMER_CLOCK3;
            Mul    := Master_Clock_Frequency / 32;

         when MCK_128 =>
            --  Internal MCK/128 clock signal (from PMC)

            TCCLKS := TIMER_CLOCK4;
            Mul    := Master_Clock_Frequency / 128;
      end case;

      --  Enable peripheral clock

      PMC_Periph.PMC_PCER1 :=
        (PID    =>
           (As_Array => True,
            Arr      => [Timer_Counter_Channel_5 => True, others => False]),
         others => <>);

      --  Disable TC to be able to configure it

      TC1_Periph.CCR2 :=
        (CLKEN  => False,
         CLKDIS => True,
         SWTRG  => False,
         others => <>);

      --  Configure TC in capture mode

      TC1_Periph.CMR2 :=
        (TCCLKS  => TCCLKS,  --  Clock selected
         CLKI    => False,
         --  Counter is incremented on rising edge of the clock.
         BURST   => NONE,
         --  The clock is not gated by an external signal.
         LDBSTOP => False,
         --  Counter clock is not stopped when RB loading occurs.
         LDBDIS  => False,
         --  Counter clock is not disabled when RB loading occurs.
         ETRGEDG => NONE,
         --  The clock is not gated by an external signal.
         ABETRG  => False,   --  irrelevant
         --  TIOB is used as an external trigger.
         CPCTRG  => False,
         --  RC Compare has no effect on the counter and its clock.
         WAVE    => False,   --  Caprure mode is enabled
         LDRA    => NONE,
         LDRB    => NONE,
         others  => <>);

      --  Enable TC but don't start counter

      TC1_Periph.CCR2 :=
        (CLKEN  => True,
         CLKDIS => False,
         SWTRG  => False,
         others => <>);

      --  Disable all TC's interrupts.

      TC1_Periph.IDR2 :=
        (COVFS  => True,
         LOVRS  => True,
         CPAS   => True,
         CPBS   => True,
         CPCS   => True,
         LDRAS  => True,
         LDRBS  => True,
         ETRGS  => True,
         others => <>);

      --  Reset status register.

      declare
         SR : constant SR_Register := TC1_Periph.SR2 with Unreferenced;

      begin
         null;
      end;

      --  Clear pending interrupt request in NVIC and enable NVIC interrupt
      --  line.

      Clear_Pending (Timer_Counter_Channel_5);
      Enable_Interrupt (Timer_Counter_Channel_5);

      --  Initialize A0B Timer.

      A0B.Timer.Internals.Initialize;
   end Initialize;

   ---------------------------
   -- Internal_Request_Tick --
   ---------------------------

   procedure Internal_Request_Tick is
   begin
      --  Request TC interrupt to execute callback/schedule timer.

      Set_Pending (Timer_Counter_Channel_5);
   end Internal_Request_Tick;

   -----------------------
   -- Internal_Set_Next --
   -----------------------

   procedure Internal_Set_Next
     (Span    : A0B.Time.Time_Span;
      Success : out Boolean)
   is
      use type A0B.Types.Unsigned_64;

      Ticks : constant A0B.Types.Unsigned_64 :=
        A0B.Types.Unsigned_64 (A0B.Time.To_Nanoseconds (Span))
          * A0B.Types.Unsigned_64 (Mul)
          / A0B.Types.Unsigned_64 (Div);

   begin
      if Ticks = 0 then
         --  Delay interval is not distinguishable by the timer.

         Success := False;

         return;

      elsif Ticks <= A0B.Types.Unsigned_64 (A0B.Types.Unsigned_32'Last) then
         --  Time stamp is achivable inside timer's counter range, configure
         --  compare register and wait till match of the counter and given
         --  value.

         TC1_Periph.RC2       := A0B.Types.Unsigned_32 (Ticks);
         TC1_Periph.IER2.CPCS := True;

      else
         --  Time stamp is far than timer's counter cycle, wait till counter
         --  overflow.

         TC1_Periph.IER2.COVFS := True;
      end if;

      TC1_Periph.CCR2 := (SWTRG => True, others => <>);
      Success         := True;
   end Internal_Set_Next;

   -----------------
   -- TC5_Handler --
   -----------------

   procedure TC5_Handler is
      Status : constant SR_Register  := TC1_Periph.SR2 with Unreferenced;
      --  Read register to cleanup interrupt request.

   begin
      --  Disable all TC's interrupts use by the code. Necessary interrupt
      --  will be enabled by the Dequeue subprogram when needed.

      TC1_Periph.IDR2 :=
        (COVFS  => True,
         CPCS   => True,
         others => <>);

      A0B.Timer.Internals.On_Tick;
   end TC5_Handler;

end A0B.ATSAM3X8E.TC5_Timer;
