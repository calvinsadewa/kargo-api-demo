defmodule KargoApi.Model do

  defmodule Job do
    defstruct origin: "JKT", destination: "BDG", ship_date: "2019-09-08", budget: 0, shipper_id: 0
  end

  defmodule Bid do
    defstruct transporter_id: 0, vehicle: "CDD", price: 1000, desc: "", job_id: 0
  end

  defmodule DB do
    use Agent
    def start_link(opts) do
      {initial_data, opts} = Keyword.pop(opts, :initial_data, [])
      Agent.start_link(fn -> initial_data end, opts)
    end

    def get_all(db) do
      Agent.get(db, &(&1))
    end
  end

  defmodule DBSupervisor do
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, :ok, opts)
    end

    def init(:ok) do
      job_dummy = [
        %Job{},
        %Job{destination: "BLI", budget: 1000},
        %Job{budget: 2000},
        %Job{ship_date: "2019-10-08", shipper_id: 1},
      ]

      bid_dummy = [
        %Bid{price: 1},
        %Bid{price: 2, vehicle: "CDE"},
        %Bid{price: 3},
        %Bid{price: 4, vehicle: "CDE"},
        %Bid{job_id: 1, price: 5},
        %Bid{job_id: 1, price: 6, vehicle: "CDE"},
        %Bid{job_id: 1, price: 7},
      ]

      children = [
        Supervisor.child_spec({KargoApi.Model.DB, name: KargoApi.Model.JobDB, initial_data: job_dummy}, id: KargoApi.Model.JobDB),
        Supervisor.child_spec({KargoApi.Model.DB, name: KargoApi.Model.BidDB, initial_data: bid_dummy}, id: KargoApi.Model.BidDB)
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  @typedoc ~S"""
  string, format of parameter ASC|DSC, joined by ","
  examp;e "ORDER ASC, SHIP_DATE DSC"
  """
  @type us_sort_param_t :: String.t

  @type s_sort_param_t :: list({String.t,String.t})

  @spec parse_sort_param(us_sort_param_t) :: {:ok,s_sort_param_t} | {:error,:strange_sort_param, String.t}
  def parse_sort_param(us_sort_param) do
    part_with_parse_results = String.split(us_sort_param,",")
      |> Enum.map(fn part_s -> {part_s, part_s |> String.trim |> String.split(" ")} end)
      |> Enum.map(fn {s, ls} -> {s, parse_helper(ls)} end)

    check_parts = fn part_with_parse ->
      case part_with_parse do
        {_, :error} -> true
        _ -> false
      end
    end

    anomalies = Enum.filter(part_with_parse_results, check_parts)
    case anomalies do
      [{fir_s, :error} | _] -> {:error, :strange_sort_param, fir_s}
      _ -> {:ok, part_with_parse_results |> Enum.map(fn {_, t} -> t end)}
    end
  end

  defp parse_helper([s,"ASC" = d]) do
    {s,d}
  end

  defp parse_helper([s,"DSC" = d]) do
    {s,d}
  end

  defp parse_helper(_) do
    :error
  end

  def list_posted_job(shipper_id, us_sort_param) do
    result = with {:ok, s_sort_param} <- parse_sort_param(us_sort_param)
    do
      fetch_enriched_job_db(%{sort: s_sort_param, filter: %{shipper_id: shipper_id}})
    end

    case result do
      {:ok, jobs} -> {:ok, jobs}
      {:error, :strange_sort_param, message} -> {:error,message}
      _ -> {:error, :internal_server_error}
    end
  end

  def list_bid_for_job(job_id, us_sort_param) do
    result = with {:ok, s_sort_param} <- parse_sort_param(us_sort_param)
    do
      fetch_enriched_bid_db(%{sort: s_sort_param, filter: %{job_id: job_id}})
    end

    case result do
      {:ok, jobs} -> {:ok,jobs}
      {:error, :strange_sort_param, message} -> {:error,"Strange job param: " <> message}
      _ -> {:error, :internal_server_error}
    end
  end

  defp fetch_enriched_job_db(param) do
    fetch_enriched_db(param, KargoApi.Model.JobDB)
  end

  defp fetch_enriched_bid_db(param) do
    fetch_enriched_db(param, KargoApi.Model.BidDB)
  end

  defp fetch_enriched_db(%{sort: s_sort_param, filter: %{} = filter}, db) do
    all_data = DB.get_all(db)
    sort_by = fn {key, order}, data ->
      sort_fn = case order do
        "ASC" -> &<=/2
        "DSC" -> &>=/2
      end
      Enum.sort_by(data,&Map.get(&1, String.to_atom(key)), sort_fn)
    end

    filter_kv = Map.keys(filter) |> Enum.map(fn k -> {k, filter[k]} end)

    sorted = Enum.reduce(s_sort_param, all_data, sort_by)
    filter_by = fn {key, value}, data ->
      Enum.filter(data, fn d_el -> Map.get(d_el,key) == value end)
    end
    filtered = Enum.reduce(filter_kv, sorted, filter_by)
    {:ok, filtered}
  end
end
