-------------------------------------------------------------------------------
--    Copyright 2015 HES-SO HEIG-VD REDS
--    All Rights Reserved Worldwide
--
--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at
--
--        http://www.apache.org/licenses/LICENSE-2.0
--
--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
--    limitations under the License.
-------------------------------------------------------------------------------
--
-- File        : simulation_end_pkg.vhd
-- Description : This package offers the mechanism to listen to objections and
--               the heartbeat in order to detect the simulation end.
--               It offers a component that takes care of it and that will
--               call a procedure just before finishing the simulation.
--               It requires two packages:
--                   - objection_env_pkg
--                       To observe the fact that there is no more objections
--                   - heartbeat_env_pkg
--                       To observe the fact that the simulation seems stuck
--                       somewhere without nothing more happening, even if
--                       objections are still raised.
--
-- Author      : Yann Thoma
-- Team        : REDS institute
-- Date        : 30.10.15
--
--
--| Modifications |------------------------------------------------------------
-- Ver  Date      Who   Description
-- 1.0  30.10.15  YTA   First version
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use std.env.all;

library tlmvm;
use tlmvm.objection_env_pkg.all;
use tlmvm.heartbeat_env_pkg.all;

package simulation_end_pkg is

    -- This type allows the reporting function to know why the simulation ended:
    -- Because of:
    --     - No objection raised any more and drain time elapsed
    --     - No beat event so the simulation seems to be stuck somewhere
    --     - None of the above, should not occur
    type finish_status_t is (NO_OBJECTION, NO_BEAT, UNKNOWN_ENDING);

    -- This component can simply be instanciated at any location in the
    -- testbench hierarchy. It will automatically launch the procedure
    -- monitor_simulation, wait for it to detect the end of the simulation,
    -- then call the final_reporting function and finally call finish to
    -- end up and quit the simulation.
    component simulation_monitor is
    generic (
        DRAIN_TIME : time := 0 ns; -- Drain time for objections
        BEAT_TIME  : time := 0 ns; -- Beat time for the heartbeat
        procedure final_reporting(finish_status: finish_status_t); -- Function
                  -- called at the end of the simulation
        should_finish : boolean := true); -- If yes, then the simulator exits
                  -- when the simulation is over
    end component;

    -- This procedure sets the drain time and beat time, and then observes the 
    -- singleton objection and the singleton heartbeat to detect the simulation
    -- end. It then returns the information about the finish status
    procedure monitor_simulation(drain_time : time:=0 ns;
                                 beat_time : time := 0 ns;
                                 status: out finish_status_t);

    -- This procedure generates a clock signal with a certain period and a phase shift
    -- It can be called as a concurrent procedure.
    procedure clock_generator(signal clk : out std_logic;
                              constant clk_period : time;
                              constant phi : time := 0 ns);

    -- This procedure generates a simple reset at the beginning of a simulation,
    -- asserting the reset for a certain time.
    -- It can be called as a concurrent procedure.
    procedure simple_startup_reset(signal rst : out std_logic;
                                   constant reset_time : time);

end simulation_end_pkg;

package body simulation_end_pkg is

    procedure monitor_simulation(drain_time : time:=0 ns;
                                 beat_time : time := 0 ns;
                                 status: out finish_status_t) is
        variable waiting_time : time;
    begin
        set_drain_time(drain_time);
        set_beattime(beat_time);
        loop
            if get_drain_time < get_beattime then
                waiting_time := get_drain_time;
            else
                waiting_time := get_beattime;
            end if;
            if waiting_time < 10 ns then
                waiting_time := 10 ns;
            end if;
            wait for waiting_time;
            if objections_end_of_simulation or heartbeat_end_of_simulation then
                report "Finishing at time " & to_String(now);
                if objections_end_of_simulation then
                    report "Ending status: Because of no more objections";
                    status := NO_OBJECTION;
                elsif heartbeat_end_of_simulation then
                    report "Ending status: Because of no more heart beat";
                    status := NO_BEAT;
                else
                    report "Ending status: Because of an unknown ending";
                    status := UNKNOWN_ENDING;
                end if;
                exit;
            end if;
        end loop;
    end monitor_simulation;

    procedure clock_generator(signal clk : out std_logic;
                              clk_period : time;
                              phi : time := 0 ns) is
    begin
        clk <= '0';
        wait for phi;
        loop
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
            clk <= '0';
        end loop;
    end clock_generator;

    procedure simple_startup_reset(signal rst : out std_logic;
                                   reset_time : time) is
    begin
        rst <= '1';
        wait for reset_time;
        rst <= '0';
    end simple_startup_reset;

end simulation_end_pkg;

use std.env.all;
use work.simulation_end_pkg.all;

entity simulation_monitor is
generic (
    DRAIN_TIME    : time := 0 ns;
    BEAT_TIME     : time := 0 ns;
    procedure final_reporting(finish_status: finish_status_t);
    should_finish : boolean := true);
end simulation_monitor;

architecture behave of simulation_monitor is
begin
    monitor_proc: process is
        variable status: finish_status_t;
    begin
        monitor_simulation(DRAIN_TIME,BEAT_TIME,status);
        final_reporting(status);
        if should_finish then
        	finish;
        else
            stop;
        end if;
        wait;
    end process;
end behave;

