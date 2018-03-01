
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Using files
use STD.standard.severity_level;
use STD.textio.all;
use ieee.std_logic_textio.all;

package logger_pkg is

    type logger_t is protected

        procedure log_failure(message: string := "");
        procedure log_error(message : string := "");
        procedure log_warning(message: string := "");
        procedure log_note(message: string := "");

        procedure final_report;

        procedure enable_write_on_file;
        procedure disable_write_on_file;
        procedure set_log_file_name(l_file: string := "log.txt");
        procedure set_severity_level(level: severity_level := note);

    end protected logger_t;

end logger_pkg;


package body logger_pkg is

    type logger_t is protected body
        type string_ptr_t is access string;
        variable nb_errors     : integer := 0;
        variable nb_warnings   : integer := 0;
        variable write_on_file : boolean := false;
        variable log_file_name : string_ptr_t := new string'("default.txt");
        file     log_file      : text;
        variable v_OLINE       : line;
        variable var_sev_lvl   : severity_level := note;
        variable first_write_on_file : boolean := true;

        procedure enable_write_on_file is
        begin
          write_on_file := true;
        end enable_write_on_file;

        procedure disable_write_on_file is
        begin
          write_on_file := false;
        end disable_write_on_file;

        procedure set_log_file_name(l_file: string := "log.txt") is
        begin
            DEALLOCATE(log_file_name);
            log_file_name := new string'(l_file);
        end set_log_file_name;

        procedure set_severity_level(level: severity_level := note) is
        begin
          var_sev_lvl := level;
        end set_severity_level;

        procedure log(message: string := ""; level: severity_level := note) is
        begin
          report message severity level;

          if write_on_file = true then
            if first_write_on_file = false then
              file_open(log_file, log_file_name.all,  append_mode);
            else
              file_open(log_file, log_file_name.all,  write_mode);
              first_write_on_file := false;
            end if;
            write(v_OLINE, message);
            writeline(log_file, v_OLINE);

            file_close(log_file);
          end if;
        end log;

        procedure log_failure(message: string := "") is
        begin
          log(message => "[FAILURE] " & message, level => failure);
          -- report "Nb errors = " & integer'image(nb_errors)
        end log_failure;

        procedure log_error(message: string := "") is
        begin
          nb_errors := nb_errors + 1;
          if var_sev_lvl < failure then
            log(message => "[ERROR] " & message, level => error);
          end if;
          -- report "Nb errors = " & integer'image(nb_errors)
        end log_error;

        procedure log_warning(message: string := "") is
        begin
          nb_warnings := nb_warnings + 1;
          if var_sev_lvl < error then
            log(message => "[WARNING] " & message, level => warning);
          end if;
        end log_warning;

        procedure log_note(message: string := "") is
        begin
          if var_sev_lvl = note then
            log(message => "[NOTE] " & message, level => note);
          end if;
        end log_note;

        procedure final_report is
        begin
            log("Nb of warning : " & integer'image(nb_warnings));
            log("Nb of errors : " & integer'image(nb_errors));
        end final_report;

    end protected body logger_t;
end logger_pkg;
