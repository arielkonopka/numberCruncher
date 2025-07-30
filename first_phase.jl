using CSV
using DataFrames
using DelayEmbeddings
using DynamicalSystemsBase
using PlotlyJS
using Statistics
using RecurrenceAnalysis

"""
Loads data from a CSV file into a DataFrame

Parameters:
- filename::AbstractString: path to the CSV file

Returns:
- DataFrame: loaded data
"""
function load_data(filename::AbstractString)
    rawFile = CSV.File(filename)
    return DataFrame(rawFile)
end

"""
Adds delta columns (price changes) to the DataFrame

Parameters:
- df::DataFrame: input DataFrame with 'open' and 'close' columns

Returns:
- DataFrame: modified DataFrame with added 'deltaO' and 'deltaC' columns
"""
function add_deltas!(df::DataFrame)
    df[!, :deltaO] = vcat([df.open[i+1] - df.open[i] for i in 1:(nrow(df)-1)], missing)
    df[!, :deltaC] = vcat([df.close[i+1] - df.close[i] for i in 1:(nrow(df)-1)], missing)
    return df
end

"""
Creates a phase space from the deltaO column using time delay embedding

Parameters:
- df::DataFrame: input DataFrame with 'deltaO' column
- sample_size::Int=1000: number of points to use (default: 1000)
- tau::Int=43: time delay for embedding (default: 43)
- n::Int=3: embedding dimension (default: 3)

Returns:
- StateSpaceSet: embedded time series in phase space
"""
function create_phase_space(df::DataFrame; sample_size::Int=1000, tau::Int=43, n::Int=3)
    dO = skipmissing(vec(df.deltaO)) |> collect
    
    # Wybieramy próbkę danych
    half_idx = Int(floor(length(dO)/4)) + 1
    dO_selected = dO[half_idx:(half_idx + sample_size)]
    
    # Tworzymy embedding
    embedded = embed(dO_selected, n, tau)
    
    return embedded
end

"""
Creates automatic embedding using PECUZAL algorithm

Parameters:
- data::Vector{Float64}: input time series
- Tmax::Int=200: maximum time delay to consider
- theiler::Int=10: Theiler window (optionally automatically estimated)

Returns:
- Y::StateSpaceSet: embedded time series
- τ_vals::Vector{Int}: optimal time delays
- ts_vals::Vector{Int}: time series indices
- Ls::Vector{Float64}: L-statistics
- εs::Vector{Float64}: threshold values

Notes:
- Uses the second half of the data with added small random noise
- Automatically estimates optimal time delay using mutual information method
"""
function create_automatic_embedding(data::Vector{Float64}; Tmax::Int=200)

    theiler=estimate_delay(data,"mi_min")
    println("Estimated Theiler window: ", theiler)
    Y, τ_vals, ts_vals, Ls, εs = pecuzal_embedding(data; τs = 0:Tmax, w = theiler, econ = true)
    # Print embedding information
    println("Optimal time delays (τ_vals) = ", τ_vals)
    println("L-statistics = ", Ls)
    
    return Y, τ_vals, ts_vals, Ls, εs
end


"""
Creates visualization plots: 3D phase space and recurrence matrix

Parameters:
- embedded::StateSpaceSet: embedded time series data

Returns:
- Tuple(Plot, Plot): phase space plot and recurrence plot
"""
function create_plots(embedded::StateSpaceSet)
    # 3D phase space plot
    scatter_plot = scatter3d(
        x=embedded[:,1], y=embedded[:,2], z=embedded[:,3],
        mode="lines+markers",
        marker=attr(color="blue"),
        name="Points"
    )

    layout = Layout(
        title="Embedding: tau=43, n=3",
        scene=attr(
            camera=attr(
                up=attr(x=0, y=0, z=1),
                center=attr(x=0, y=0, z=0),
                eye=attr(x=1.5, y=1.5, z=1.5)
            )
        )
    )
    phase_space_plot = plot(scatter_plot, layout)

    # Recurrence matrix and heatmap
    epsilon = 0.1 * std(Matrix(embedded))
    R = RecurrenceMatrix(embedded, RecurrenceThreshold(epsilon))
    Rg = grayscale(R; width=500, height=500)

    heatmap_plot = heatmap(
        z=Rg, 
        colorscale="Viridis", 
        showscale=true,
        colorbar=attr(title="Recurrence")
    )
    recurrence_plot = plot(
        [heatmap_plot], 
        Layout(
            title="Recurrence Matrix (heatmap)", 
            xaxis=attr(title="Point index"), 
            yaxis=attr(title="Point index")
        )
    )

    return phase_space_plot, recurrence_plot
end

# Main function that performs the complete analysis
function main(embed::Bool=false)
    # Load data
    filename = "./raw_Data_2024-09-30.csv"
    df = load_data(filename)
    
    # Add delta columns
    add_deltas!(df)
    
    # Get data for embedding
    dO = skipmissing(vec(df.deltaO)) |> collect
    if embed == true  
          half_idx = Int(floor(length(dO)/3)) + 1
          dO_jittered = dO[half_idx:end] .+ 1e-12 .* randn(length(dO[half_idx:end]))
    # Get optimal embedding parameters using PECUZAL
          embedded, τ_vals, ts_vals, Ls, εs = create_automatic_embedding(dO_jittered)
    else
          embedded = create_phase_space(df, tau=43, n=3)
    end

    # Create plots
    phase_plot, rec_plot = create_plots(embedded)
    
    # Display plots
    display(phase_plot)
    display(rec_plot)
    
    readline()
end

# Run the analysis
main(true)
