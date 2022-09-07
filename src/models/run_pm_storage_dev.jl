function read_time_series(json_path)
    time_series = Dict()
    open(json_path, "r") do f
        time_series = JSON.parse(f)  # parse and transform data
    end
    return time_series
end

function set_pq_values_from_timeseries(mn, time_series)
    # This function iterates over multinetwork entries and sets p, q values
    # of loads and "sgens" (which are loads with negative P and Q values)

    # iterate over networks (which represent the time steps)
    for (t, network) in mn["nw"]
        t_j = string(parse(Int64,t) - 1)
        # iterate over all loads for this network
        for (i, load) in network["load"]
            # update variables from time series here
#             print("\nload before: ")
#             print(load["pd"])
            load["pd"] = time_series[t_j][parse(Int64,i)] / mn["baseMVA"]
#             print("\nload after: ")
#             print(load["pd"])
        end
    end

    return mn
end

# function run_powermodels_storage(json_path)
#     # load converted pandapower network
#     pm = load_pm_from_json(json_path)
#     # model = get_model(pm["pm_model"])
#
#     solver = get_solver(pm["pm_solver"], pm["pm_nl_solver"], pm["pm_mip_solver"],
#     pm["pm_log_level"], pm["pm_time_limit"], pm["pm_nl_time_limit"], pm["pm_mip_time_limit"])
#
#     # copy network n_time_steps time step times
#     n_time_steps = pm["n_time_steps"]
#     mn = PowerModels.replicate(pm, pm["n_time_steps"])
#     mn["time_elapsed"] = pm["time_elapsed"]
#     # set P, Q values of loads and generators from time series
#     if isfile("/tmp/timeseries.json")
#         time_series = read_time_series("/tmp/timeseries.json")
#         mn = set_pq_values_from_timeseries(mn, time_series)
#     else
#         print("Running storage without time series")
#     end
#
#     ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, print_level = 1)
#
#     # run multinetwork storage opf
#     result = PowerModels.run_mn_opf_strg(mn, model, solver)#(mn, PowerModels.ACPPowerModel, ipopt_solver)
#     print_summary(result)
#     return result
# end


function run_powermodels_storage(json_path)
    # load converted pandapower network
    pm = load_pm_from_json(json_path)
    # active_powermodels_silence!(pm)
    model = get_model(pm["pm_model"])
    solver = get_solver(pm)

    # copy network n_time_steps time step times
    n_time_steps = pm["n_time_steps"]
    pm["p_loss"] = 1e-8
    mn = _PM.replicate(pm, pm["n_time_steps"])
    mn["time_elapsed"] = pm["time_elapsed"]
    # set P, Q values of loads and generators from time series
    if isfile("/tmp/timeseries.json")
        time_series = read_time_series("/tmp/timeseries.json")
        mn = set_pq_values_from_timeseries(mn, time_series)
    else
        print("Running storage without time series")
    end

    ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, print_level = 1)

    # run multinetwork storage opf
    result = PowerModels.run_mn_opf_strg(mn, model, solver)#(mn, PowerModels.ACPPowerModel, ipopt_solver)
    print_summary(result)
    return result
end
