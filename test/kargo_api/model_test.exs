defmodule KargoApi.ModelTest do
  use ExUnit.Case, async: true
  alias KargoApi.Model, as: KM

  test "goodly parse correct sort param" do
    parse_res = KM.parse_sort_param("ORDER ASC, SHIP_DATE DSC")
    {:ok, s_sort_param} = parse_res
    [fir,snd] = s_sort_param
    assert fir == {"ORDER","ASC"}
    assert snd == {"SHIP_DATE","DSC"}
  end

  test "badly parse incorrect sort param" do
    this_is_incorrect = fn incorrect_s ->
      {:error,:strange_sort_param, _} = KM.parse_sort_param(incorrect_s)
    end
    this_is_incorrect.("ORDER ASC, SHIP_DATE DSC,")
    this_is_incorrect.("ASC")
    this_is_incorrect.("ORDER ASCA")
    this_is_incorrect.("ORDER ASC, SHIP_DATE DESC,")
    this_is_incorrect.("ORDER ASC, SHIP_DATE ")
  end

  test "correctly sort order Jobs" do
    {:ok, [%KM.Job{budget: 2000} | _]} = KM.list_posted_job(0, "budget DSC")
    {:ok, [%KM.Job{ship_date: "2019-10-08"} | _]} = KM.list_posted_job(1, "budget DSC")
  end

  test "error when sort order malformed Jobs" do
    this_is_incorrect = fn incorrect_s ->
      {:error, _} = KM.list_posted_job(0, incorrect_s)
    end
    this_is_incorrect.("ORDER ASC, SHIP_DATE DSC,")
    this_is_incorrect.("ASC")
    this_is_incorrect.("ORDER ASCA")
    this_is_incorrect.("ORDER ASC, SHIP_DATE DESC,")
    this_is_incorrect.("ORDER ASC, SHIP_DATE ")
  end

  test "correctly sort order Bids" do
    {:ok, [%KM.Bid{job_id: 0, vehicle: "CDD"} | _]} = KM.list_bid_for_job(0, "vehicle ASC")
    {:ok, [%KM.Bid{job_id: 1, vehicle: "CDE"} | _]} = KM.list_bid_for_job(1, "vehicle DSC")
  end
end
