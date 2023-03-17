defmodule UryiTest do
  use ExUnit.Case
  alias Uryi.TDNif

  test "tdlib works" do
    assert {:ok, td} = TDNif.create()

    assert :ok =
             TDNif.send(
               td,
               Jason.encode_to_iodata!(%{
                 "@extra" => "log",
                 "@type" => "setLogVerbosityLevel",
                 "@args" => %{"new_verbosity_level" => 0}
               })
             )

    assert messages = recv_all(td)

    assert messages == [
             %{
               "@type" => "updateOption",
               "name" => "version",
               "value" => %{"@type" => "optionValueString", "value" => "1.8.12"}
             },
             %{
               "@type" => "updateOption",
               "name" => "commit_hash",
               "value" => %{
                 "@type" => "optionValueString",
                 "value" => "70bee089d492437ce931aa78446d89af3da182fc"
               }
             },
             %{
               "@type" => "updateAuthorizationState",
               "authorization_state" => %{"@type" => "authorizationStateWaitTdlibParameters"}
             },
             %{"@extra" => "log", "@type" => "ok"}
           ]
  end

  def recv_all(td) do
    case TDNif.recv(td, 0.0) do
      {:ok, message} when is_binary(message) ->
        [Jason.decode!(message) | recv_all(td)]

      {:ok, nil} ->
        []
    end
  end
end
