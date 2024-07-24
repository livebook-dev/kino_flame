defmodule KinoFLAME.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "FLAME integration with Livebook"

  def project do
    [
      app: :kino_flame,
      version: @version,
      description: @description,
      name: "KinoFLAME",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      mod: {KinoFLAME.Application, []}
    ]
  end

  defp deps do
    [
      {:kino, "~> 0.13"},
      # TODO: bump once the next version is released
      {:flame, github: "phoenixframework/flame"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "components",
      source_url: "https://github.com/livebook-dev/kino_flame",
      source_ref: "v#{@version}",
      extras: ["guides/components.livemd"]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/livebook-dev/kino_flame"
      }
    ]
  end
end
