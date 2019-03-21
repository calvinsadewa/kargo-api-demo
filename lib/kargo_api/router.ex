defmodule KargoApi.Router do
  use Plug.Router
  alias KargoApi.Model, as: KM

  plug(:match)
  plug(:dispatch)

  get "/list/posted_job/:shipper_id" do
    {sid,_} = Integer.parse(shipper_id)
    result = KM.list_posted_job(sid, "budget DSC")
    z = conn
    |> put_resp_content_type("application/json")
    case result do
      {:ok, data} -> send_resp(z, 200, Poison.encode!(data))
      {:error, message} -> send_resp(z, 400, message)
      _ -> send_resp(z, 500, "")
    end
  end

  defp message(id) do
    %{
      response_type: "in_channel",
      text: "Hello from BOT :) #{id}"
    }
  end
end
