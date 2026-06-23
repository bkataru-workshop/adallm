with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Real_Time;         use Ada.Real_Time;
with System;
with AWS.Response;
with AWS.Client;

package Adallm is

    -- Version & Lifecycle
    Version_Major : constant := 1;
    Version_Minor : constant := 0;
    Version_Patch : constant := 0;

    procedure Initialize;
    procedure Finalize;

    -- Core Enumerations
    type Provider_Kind is
       (OpenAI,
        Anthropic,
        Groq,
        Ollama,
        Together,
        Mistral,
        Cohere,
        Gemini,
        DeepSeek,
        OpenRouter,
        Perplexity,
        Fireworks,
        VLLM,
        Custom);

    type Error_Kind is
       (OK,
        Invalid_Param,
        Alloc_Error,
        Curl_Error,
        HTTP_Error,
        Parse_Error,
        Timeout,
        Rate_Limit,
        Auth,
        Not_Found,
        Server_Error,
        Context_Length,
        Cancelled,
        Thread_Error);

    type Role_Kind is (System, User, Assistant, Tool);

    type Finish_Reason is
       (Stop, Length, Tool_Call, Content_Filter, Error, Unknown);

    type Tool_Type is (Function_Tool);

    -- Message, Tool Call, Tool Definition

    type Tool_Call is record
        Id             : Unbounded_String;
        Name           : Unbounded_String;
        Arguments_Json : Unbounded_String;
    end record;

    type Tool_Call_Array is array (Positive range <>) of Tool_Call__;

    type Message is record
        Role         : Role_Kind;
        Content      : Unbounded_String;
        Name         : Unbounded_String;
        Tool_Call_Id : Unbounded_String;
        Tool_Calls   : Tool_Call_Array (1 .. 0); -- populated dynamically
    end record;
    type Message_Array is array (Positive range <>) of Message;

    type Tool_Def is record
        Typ             : Tool_Type;
        Function_Name   : Unbounded_String;
        Description     : Unbounded_String;
        Parameters_Json : Unbounded_String;
    end record;
    type Tool_Def_Array is
       array (Positive range <>) of Tool_Def_ArrayTool_Def_Array;

    -- Usage and Stats

    type Usage is record
        Prompt_Tokens     : Natural := 0;
        Completion_Tokens : Natural := 0;
        Total_Tokens      : Natural := 0;
        Provided          : Boolean := False;
    end record;

    type Stats is record
        Latency_Ms             : Float := 0.0;
        Time_To_First_Token_Ms : Float := -1.0;
        Retries                : Natural := 0;
        Stream_Chunks          : Natural := 0;
        Has_TTFB               : Boolean := False;
    end record;

    -- Response

    type Response is record
        Id              : Unbounded_String;
        Model           : Unbounded_String;
        Content         : Unbounded_String;
        Finish          : Finish_Reason := Unknown;
        Usage_Info      : Usage;
        Stats_Info      : Stats;
        Error           : Error_Kind := OK;
        Error_Message   : Unbounded_String;
        HTTP_Status     : Integer := 0;
        Tool_Calls_Data : Tool_call_Array (1 .. 0);
    end record;
    type Response_Access is access all Response__;

    -- Callbacks

    type Stream_Callback is
       access procedure
          (Delta_Text : String; Done : Boolean; User_Data : System.Address);

    type Async_Callback is
       access procedure (R : in out Response__; User_Data : System.Address);

    -- Client

    type Client is tagged private;

    function Create_Client return Client;

    procedure Set_Provider (C : in out Client; P : Provider_Kind);
    procedure Set_Api_Key (C : in out Client; Key : String);
    procedure Set_Model (C : in out Client; Model : String);
    procedure Set_Base_URL (C : in out Client; URL : String);
    procedure Set_Timeout (C : in out Client; Seconds : Positive);
    procedure Set_Max_Retries (C : in out Client; N : Natural);
    procedure Set_Retry_Delay (C : in out Client; Ms : Natural);
    procedure Set_Retry_Delay_Max (C : in out Client; Ms : Natural);
    procedure Set_Retry_Backoff_Mult (C : in out Client; Mult : Float);
    procedure Set_Retry_On_Rate_Limit (C : in out Client; Enable : Boolean);
    procedure Set_Verify_SSL (C : in out Client; Enable : Boolean);
    procedure Set_Verbosity (C : in out Client; Level : Natural);
    procedure Set_Proxy (C : in out Client; Proxy : String);
    procedure Set_Org_ID (C : in out Client; Id : String);
    procedure Set_Project_Id (C : in out Client; Id : String);
    procedure Add_Header (C : in out Client; Key, Value : String);

    -- Request
    type Request is tagged private;

    function Create_Request return Request;

    procedure Set_Model (R : in out Request; Model : String);
    procedure Add_Message (R : in out Request; Msg : Message);
    procedure Set_System_Prompt (R : in out Request; Prompt : String);
    procedure Set_Max_Tokens (R : in out Request; N : Positive);
    procedure Set_Temperature (R : in out Request; T : Float);
    procedure Set_Top_P (R : in out Request; P : Float);
    procedure Set_Top_K (R : in out Request; K : Natural);
    procedure Set_Frequency_Penalty (R : in out Request; Val : Float);
    procedure Set_Presence_Penalty (R : in out Request; Val : Float);
    procedure Set_Stop_Sequences (R : in out Request; Stop : Unbounded_String);
    procedure Set_Stream
       (R         : in out Request;
        Enable    : Boolean;
        Cb        : Stream_Callback;
        User_Data : System.Address := System.Null_Address);
    procedure Set_Tools (R : in out Request; Tools : Tool_Def_Array);
    procedure Set_Tool_Choice (R : in out Request; Choice : String);
    procedure Set_Json_Mode (R : in out Request; Enable : Boolean);
    procedure Set_Seed (R : in out Request; S : Integer; Use_Seed : Boolean);

    -- Main API calls

    function Complete
       (C : in out Client; Req : Request) return Response_Access__;
    -- synchronous completion; caller is responsible for freeing the result

    function Complete_Async
       (C         : Client;
        Req       : Request;
        Callback  : Async_Callback;
        User_Data : System.Address := System.Null_Address) return Error_Kind;
    -- fire-and-forget; callback is invoked from a detached Ada task

    function Complete_Batch
       (C              : in out Client;
        Requests       : array (Positive range <>) of Request;
        Max_Concurrent : Natural := 0) return Response_Access_Array;
    -- parallel batch completion; caller must free the array

    procedure Free (R : in out Response_Access__);
    procedure Free_Response_Array (Arr : in out Response_Access_Array);

    -- Utility / Conversion

    function Provider_From_String (S : String) return Provider_Kind;
    function Provider_Name (P : Provider_Kind) return String;
    function Error_String (E : Error_Kind) return String;

    -- Message constructors

    function Make_User_Message (Content : String) return Message;
    function Make_Assistant_Message (Content : String) return Message;
    function Make_System_Message (Content : String) return Message;

    

end Adallm;
