with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Ada.Real_Time;          use Ada.Real_Time;
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
    type Provider_Kind is (OpenAI, Anthropic, Groq, Ollama, Together, Mistral,
                           Cohere, Gemini, DeepSeek, OpenRouter, Perplexity,
                           Fireworks, VLLM, Custom);

    type Error_Kind is (OK,
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

    type Finish_Reason is (Stop, Length, Tool_Call, Content_Filter, Error, Unknown);

    type Tool_Type is (Function_Tool);

    -- Message, Tool Call, Tool Definition

    type Tool_Call is record
        Id : Unbounded_String;
        Name : Unbounded_String;
        Arguments_Json : Unbounded_String;
    end record;

    a

end Adallm;
