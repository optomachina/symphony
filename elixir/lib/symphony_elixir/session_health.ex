defmodule SymphonyElixir.SessionHealth do
  @moduledoc """
  Reports the age of vendor session files (e.g. Xometry Playwright storage state)
  as a health signal, so operators can detect stale credentials before a live
  quote run fails.
  """

  require Logger

  @default_stale_threshold_days 7

  @doc """
  Returns the age in fractional days of the file at `path`, or `nil` if `path`
  is `nil` / the file does not exist / stat fails.
  """
  @spec session_age_days(String.t() | nil) :: float() | nil
  def session_age_days(nil), do: nil

  def session_age_days(path) when is_binary(path) do
    case File.stat(path, time: :posix) do
      {:ok, %{mtime: mtime}} ->
        now_s = System.os_time(:second)
        age_s = max(now_s - mtime, 0)
        age_s / 86_400

      {:error, _reason} ->
        nil
    end
  end

  @doc """
  Reads `XOMETRY_STORAGE_STATE_PATH` from the environment and returns
  `{path, age_days}` where `age_days` may be `nil` when the variable is unset
  or the file cannot be stat'd.
  """
  @spec xometry_session() :: {String.t() | nil, float() | nil}
  def xometry_session do
    path = System.get_env("XOMETRY_STORAGE_STATE_PATH")
    {path, session_age_days(path)}
  end

  @doc """
  Logs a warning if the Xometry session file is older than `threshold_days`
  (default #{@default_stale_threshold_days}).  Silently returns `:ok` when the
  env var is not set.
  """
  @spec warn_if_stale(pos_integer()) :: :ok
  def warn_if_stale(threshold_days \\ @default_stale_threshold_days) do
    case xometry_session() do
      {_path, nil} ->
        :ok

      {_path, age_days} when age_days >= threshold_days ->
        Logger.warning(
          "Xometry session is #{round(age_days)} days old — consider re-authenticating"
        )

      {_path, _age_days} ->
        :ok
    end
  end
end
