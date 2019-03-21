defmodule KargoApiTest do
  use ExUnit.Case
  doctest KargoApi

  test "greets the world" do
    assert KargoApi.hello() == :world
  end
end
