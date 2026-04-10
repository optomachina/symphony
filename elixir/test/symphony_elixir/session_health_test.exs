defmodule SymphonyElixir.SessionHealthTest do
  use SymphonyElixir.TestSupport

  alias SymphonyElixir.SessionHealth

  describe "session_age_days/1" do
    test "returns nil when path is nil" do
      assert SessionHealth.session_age_days(nil) == nil
    end

    test "returns nil when the file does not exist" do
      assert SessionHealth.session_age_days("/nonexistent/path/state.json") == nil
    end

    test "returns a non-negative float for an existing file" do
      path = Path.join(System.tmp_dir!(), "session-health-test-#{System.unique_integer([:positive])}.json")
      File.write!(path, "{}")

      on_exit(fn -> File.rm(path) end)

      age = SessionHealth.session_age_days(path)
      assert is_float(age)
      assert age >= 0.0
    end
  end

  describe "xometry_session/0" do
    setup do
      original = System.get_env("XOMETRY_STORAGE_STATE_PATH")
      on_exit(fn -> restore_env("XOMETRY_STORAGE_STATE_PATH", original) end)
      :ok
    end

    test "returns {nil, nil} when env var is not set" do
      System.delete_env("XOMETRY_STORAGE_STATE_PATH")
      assert {nil, nil} = SessionHealth.xometry_session()
    end

    test "returns {path, nil} when env var is set but file does not exist" do
      System.put_env("XOMETRY_STORAGE_STATE_PATH", "/nonexistent/xometry.json")
      assert {"/nonexistent/xometry.json", nil} = SessionHealth.xometry_session()
    end

    test "returns {path, age_days} when env var is set and file exists" do
      path = Path.join(System.tmp_dir!(), "xometry-session-#{System.unique_integer([:positive])}.json")
      File.write!(path, "{}")
      on_exit(fn -> File.rm(path) end)

      System.put_env("XOMETRY_STORAGE_STATE_PATH", path)
      assert {^path, age_days} = SessionHealth.xometry_session()
      assert is_float(age_days)
      assert age_days >= 0.0
    end
  end

  describe "warn_if_stale/1" do
    setup do
      original = System.get_env("XOMETRY_STORAGE_STATE_PATH")
      on_exit(fn -> restore_env("XOMETRY_STORAGE_STATE_PATH", original) end)
      :ok
    end

    test "does not log when env var is not set" do
      System.delete_env("XOMETRY_STORAGE_STATE_PATH")

      log = capture_log(fn -> SessionHealth.warn_if_stale() end)
      refute log =~ "Xometry session"
    end

    test "does not log when session file is fresh" do
      path = Path.join(System.tmp_dir!(), "xometry-fresh-#{System.unique_integer([:positive])}.json")
      File.write!(path, "{}")
      on_exit(fn -> File.rm(path) end)

      System.put_env("XOMETRY_STORAGE_STATE_PATH", path)

      log = capture_log(fn -> SessionHealth.warn_if_stale(365) end)
      refute log =~ "Xometry session"
    end

    test "logs a warning when the session is stale" do
      path = Path.join(System.tmp_dir!(), "xometry-stale-#{System.unique_integer([:positive])}.json")
      File.write!(path, "{}")
      on_exit(fn -> File.rm(path) end)

      System.put_env("XOMETRY_STORAGE_STATE_PATH", path)

      log = capture_log(fn -> SessionHealth.warn_if_stale(0) end)
      assert log =~ "Xometry session"
      assert log =~ "consider re-authenticating"
    end
  end
end
