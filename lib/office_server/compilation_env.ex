defmodule OfficeServer.CompilationEnv do
  @moduledoc """
  For the purposes of injecting testing seams or otherwise
  """

  @doc """
  Should we be in a genuine test environment?
  True if environment is `test` and target is not `elixir_ls`. Note that the
  target has to be set in VS Code etc preferences

  Note the parameters are for testing only
  eg
  iex> OfficeServer.CompilationEnv.testing?(:dev, nil)
  false

  iex> OfficeServer.CompilationEnv.testing?(:dev, :anything)
  false

  iex> OfficeServer.CompilationEnv.testing?(:prod, nil)
  false

  iex> OfficeServer.CompilationEnv.testing?(:test, :elixir_ls)
  false

  iex> OfficeServer.CompilationEnv.testing?(:test, :anything_else)
  true
  """
  @mix_env Mix.env()
  @mix_target Mix.target()
  def testing?(env \\ @mix_env, target \\ @mix_target)

  def testing?(_, :elixir_ls), do: false
  def testing?(:test, _), do: true
  def testing?(_, _), do: false
end
