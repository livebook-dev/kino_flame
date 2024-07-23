defmodule KinoFLAME.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(KinoFLAME.RunnerCell)

    children = []
    opts = [strategy: :one_for_one, name: KinoFLAME.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
