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
    type Message_Array is array (Positive range <>) of Message__;

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
        Finish          : F.inish_Reason := Unknown;
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
    procedure Add_Message (R : in out Request; Msg : Message__);
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

    function Make_User_Message (Content : String) return Message__;
    function Make_Assistant_Message (Content : String) return Message__;
    function Make_System_Message (Content : String) return Message__;
    function Make_Tool_Result
       (Tool_Call_Id, Content : String) return Message__;
    function Make_Tool_Def
       (Name, Desc, Params_Json : String) return Tool_Def__;

    procedure Print_Stats (Resp : Response__; Output : Ada.Text_IO.File_Type);

private

    use type AWS.Client.HTTP_Connection;

    type Header_Pair is record
        Key   : Unbounded_String;
        Value : Unbounded_String;
    end record;

    type Header_List is array (Positive range <>) of Header_Pair;

    type Client is tagged record
        Provider            : Provider_Kind := OpenAI;
        Api_Key             : Unbounded_String;
        Base_URL            : Unbounded_String;
        Model               : Unbounded_String;
        Timeout_Seconds     : Positive := 30;
        Max_Retries         : Natural := 3;
        Retry_Delay_Ms      : Natural := 1000;
        Retry_Delay_Max_Ms  : Natural := 30000;
        Retry_Backoff_Mult  : Float := 2.0;
        Retry_On_Rate_Limit : Boolean := True;
        Verbosity           : Natural := 0;
        Verify_SSL          : Boolean := True;
        Proxy               : Unbounded_String;
        Org_Id              : Unbounded_String;
        Project_Id          : Unbounded_String;
        Headers             : Header_List (1 .. 32);
        Header_Count        : Natural := 0;
    end record;

    Max_Messages : constant := 256;
    Max_Tools    : constant := 64;
    Max_Stops    : constant := 16;

    type Request is tagged record
        Messages          : Message_Array (1 .. Max_Messages);
        Message_Count     : Natural := 0;
        Model             : Unbounded_String;
        Max_Tokens        : Positive := 4096;
        Temperature       : Float := 1.0;
        Top_P             : Float := 1.0;
        Top_K             : Natural := 0;
        Frequency_Penalty : Float := 0.0;
        Presence_Penalty  : Float := 0.0;
        Stop_Seqs         : Unbounded_String (1 .. Max_Stops);
        Stop_Count        : Natural := 0;
        Stream            : Boolean := False;
        Stream_CB         : Stream_Callback;
        Stream_User_Data  : System.Address := System.Null_Address;
        Tools             : Tool_Def_Array (1 .. Max_Tools);
        Tools_Count       : Natural := 0;
        Tool_Choice       : Unbounded_String;
        System_Prompt     : Unbounded_String;
        Json_Mode         : Boolean := False;
        Seed              : Integer := 0;
        Use_Seed          : Boolean := False;
        User_Data         : System.Address := System.Null_Address;
    end record;

    type Response_Access_Array is array (Positive range <>) of Response_Access;

    -- Helper: convert Unbounded_String to/from String
    function "+" (S : String) return Unbounded_String
    renames To_Unbounded_String;
    function "+" (U : Unbounded_String) return String renames To_String;

end Adallm;
