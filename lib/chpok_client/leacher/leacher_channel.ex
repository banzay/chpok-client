defmodule ChpokClient.LeacherChannel do
  use PhoenixChannelClient

  def handle_in("join", _resp, state) do
    {:noreply, state}
  end

  @doc """
  Handle Seeder's response
  """
  def handle_in("new:" <> path, %{"msg" => msg, "leacher" => leacher, "seeder" => seeder}, state) do

    IO.puts("[INFO] Handling file #{path}")
    dir = Application.get_env(:chpok_client, :dir)
    name = Application.get_env(:chpok_client, :name)

    {:ok, decoded_msg} = Base.decode64(msg)
    case File.write(dir <> path, decoded_msg) do
      :ok ->
        spawn_link(fn ->
          ChpokClient.LeacherChannel.push("ack:" <> path, %{seeder: seeder})
        end)
        IO.puts("!!! \nFile #{path} fetched\n!!!")
      {:error, reason} -> IO.puts("FileSaver error: #{reason}")
    end

    {:noreply, state}
  end

  def handle_reply({:leaching_request_handled, "leachers:" <> _name, _resp, _ref}, state) do
    {:noreply, state}
  end

  def handle_reply({:ok, :join, _resp, _ref}, state) do
    {:noreply, state}
  end

  def handle_reply({:timeout, :join, _ref}, state) do
    {:noreply, state}
  end

  def handle_close(_reason, state) do
    :timer.send_after(5000, {:rejoin, state})
    {:noreply, %{}}
  end
end
