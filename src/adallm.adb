with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with Ada.Strings.Maps;  _    use Ada.Strings.Maps;
with Ada.Real_Time;         use Ada.Real_Time;
with Ada.Task_Identification;
with Ada.Unchecked_Deallocation;
with System;

with AWS.Client;   use AWS.Client;
with AWS.Response; use AWS.Response;
with AWS.Headers;  use AWS.Headers;
with AWS.Net;      use AWS.Net;
with AWS.Config;   use AWS.Config;

with JSON.Parsers;
with JSON.Types;

package body Adallm is

    -- Per-module JSON instantiation

    package JT is new JSON.Types (Long_Integer, Long_Float);
    package JP is new JSON.Parsers (JT);

    use JT;

    -- Convenience conversions

    function "+" (S : String) return Unbounded_String
    renames To_Unbounded_String;
    function "+" (U : Unbounded_String) return String renames To_String;

    -- Logging helper

    procedure Log (C : Client; Level : Natural; Msg : String) is
    begin
        if C.Verbosity >= Level then
            Put_Line (Standard_Error, Msg);
        end if;
    end Log;

    -- JSON body builders
    function Escape_Json (S : String) return String is
        Result : Unbounded_String;
    begin
        Append (Result, '"');
        for C of S loop
            case C is
                when '"' => Append (Result, "\""");
                when '\' => Append (Result, "\\");
                when ASCII.LF => Append (Result, "\n");
                when ASCII.CR => Append (Result, "\r");
                when ASCII.HT => Append (Result, "\t");
                when others => Append (Result, C);
            end case;
        end loop;
        Append (Result, '"');
        return +Result;
    end Escape_Json;

    function Build_OpenAI_Body (C : Client; R : Request) return String is
        B : Unbounded_String;
        Model_Name : constant String := (if R.Model /= Null_Unbounded_String then +R.Model
                                        elsif C.Model /= Null_Unbounded_String then +C.Model
                                        else "gpt-4o");
    begin
        Append (B, "{""model"":" & Escape_Json (Model_Name));
        Append (B, ",""max_tokens"":" & R.Max_Tokens'Image);
        Append (B, ",""temperature"":" & R.Temperature'Image);
        if R.Top_P /= 1.0 then Append (B, ",""top_p"":" & R.Top_P'Image); end if;
        if R

    end Build_OpenAI_Body;

end Adallm;
