def create_job(us_job_data, shipper_id) do
  result = with
  {:ok, s_job_data} <- sanitize_job_data(us_job_data)
  {:ok, _} <- ensure_shipper_exist(shipper_id)
  do
    insert_to_job_db(to_model(s_job_data))
  end

  case result do
    {:ok,_} -> JSON.OK()
    {:error, :strange_job_data, message} -> JSON.BadRequest(message)
    {:error, :shipper_not_exist} -> JSON.BadRequest("Shipper not exist")
    _ -> JSON.InternalServerError()
  end
end

def bid_job(us_bid_info) do
  result = with
    {:ok, s_bid_info} <- validate_bid_info(bid_info)
    {:ok, _} <- ensure_exist_job_and_transporter(bid_info.job_id, bid_info.transporter_id)
    {:ok, _} <- ensure_job_open(bid_info.job_id)
    {:ok, _} <- is_unique_bid_for_job(bid_info.job_id, bid_info.transporter_id)
   do: insert_to_bid_db(to_model(bid_info))

  case result do
    {:ok, _} -> JSON.OK()
    {:error, :strange_bid_info, message} -> JSON.BadRequest(message)
    {:error, :not_exist_job_transporter, message} -> JSON.BadRequest(message)
    {:error, :job_not_open} -> JSON.BadRequest("Job not open")
    {:error, :not_unique_bid} -> JSON.BadRequest("Bid is duplicate (already bid)")
    _ -> JSON.InternalServerError()
  end
end

def list_posted_job(shipper_id, us_sort_param) do
  result = with
    {:ok, s_sort_param} <- parse_sort_param(us_sort_param),
  do
    fetch_enriched_job_db(%{sort: s_sort_param, filter: %{id: shipper_id}})
  end

  case result do
    {:ok, jobs} -> JSON.OK(jobs)
    {:error, :strange_sort_param, message} -> JSON.BadRequest(message)
    _ -> JSON.InternalServerError()
  end
end

def list_available_job(us_sort_param) do
  result = with
    {:ok, s_sort_param} <- parse_sort_param(us_sort_param),
  do
    fetch_enriched_job_db(%{sort: s_sort_param, filter: %{status: "open"}})
  end

  case result do
    {:ok, jobs} -> JSON.OK(jobs)
    {:error, :strange_sort_param, message} -> JSON.BadRequest(message)
    _ -> JSON.InternalServerError()
  end
end

def get_info(user_id) do
  result = with
    {:ok, user} <- fetch_user(user_id)
    {:ok, er_user} <- case user.type do
      "shipper" <- enrich_shipper(user)
      "transporter" <- enrich_transporter(user)
    end
  do: {:ok, er_user}

  case result do
    {:ok, er_user} -> JSON.OK(er_user)
    {:error, :user_not_exist} -> JSON.BadRequest("User no exist")
    _ -> JSON.InternalServerError()
  end
end

def list_bid_for_job(job_id, us_sort_param) do
  result = with
    {:ok, s_sort_param} <- parse_sort_param(us_sort_param),
  do
    fetch_enriched_bid_db(%{sort: s_sort_param, filter: %{job_id: job_id}})
  end

  case result do
    {:ok, jobs} -> JSON.OK(jobs)
    {:error, :strange_sort_param, message} -> JSON.BadRequest(message)
    _ -> JSON.InternalServerError()
  end
end
