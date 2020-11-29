"""
    bonding_rule = BondingRule(:Ca, :O, 0.4, 2.0)
    bonding_rules = [BondingRule(:H, :*, 0.4, 1.2),
                     BondingRule(:*, :*, 0.4, 1.9)]

A rule for determining if two atoms within a crystal are bonded.

# Attributes
-`species_i::Symbol`: One of the atoms types for this bond rule
-`species_j::Symbol`: The other atom type for this bond rule
-`min_dist`: The minimum distance between the atoms for bonding to occur
-`max_dist`: The maximum distance between the atoms for bonding to occur
"""
struct BondingRule
    species_i::Symbol
    species_j::Symbol
    min_dist::Float64
    max_dist::Float64
end


"""
    bond_rules = bondingrules()

Returns the default bonding rules. Use `append!` and/or `prepend!` to add to the default bonding rules.
Default rules are determined from the data in `cordero.csv`

# Example
```
bond_rules = bondingrules()
prepend!(bond_rules, BondingRule(:Cu, :*, 0.1, 2.6))
```

    bond_rules = bondingrules(cordero_params=cordero_params(), σ=3., min_tol=0.25)

Returns a set of bonding rules based on the given Cordero parameters and tolerances.

# Arguments

`cordero_params::Union{Dict{Symbol, Dict{Symbol, Float64}}, Nothing}`: Covalent radii and estimated uncertainty. See [`cordero_parameters()`](@ref)
`σ::Float`: Number of Cordero estimated standard deviations to use for tolerance on covalent radii.
`min_tol::Float`: Minimum tolerance for covalent radii.

# Returns
-`bondingrules::Array{BondingRule, 1}`: The default bonding rules: `[BondingRule(:*, :*, 0.4, 1.2), BondingRule(:*, :*, 0.4, 1.9)]`
"""
function bondingrules(;
        cordero_params::Union{Dict{Symbol, Dict{Symbol, Float64}}, Nothing}=nothing,
        σ::Float64=3., min_tol::Float64=0.25)::Array{BondingRule}
    if cordero_params == nothing
        cordero_params = cordero_parameters()
    end
    bondingrules = BondingRule[]
    # loop over parameterized atoms
    for (i, atom1) in enumerate(keys(cordero_params))
        # make rules for the atom with every other atom (and itself)
        for (j, atom2) in enumerate(keys(cordero_params))
            if j < i
                continue # already did this atom in outer loop (don't duplicate)
            end
            radii_sum = cordero_params[atom1][:radius_Å] + cordero_params[atom2][:radius_Å]
            margin = max(min_tol,
                σ * (cordero_params[atom1][:esd_pm] + cordero_params[atom2][:esd_pm]) / 100)
            min_dist = radii_sum - margin
            max_dist = radii_sum + margin
            push!(bondingrules, BondingRule(atom1, atom2, min_dist, max_dist))
        end
    end
    return bondingrules
end


"""
    are_atoms_bonded = is_bonded(crystal, i, j, bonding_rules=[BondingRule(:H, :*, 0.4, 1.2), BondingRule(:*, :*, 0.4, 1.9)],
                                 include_bonds_across_periodic_boundaries=true)

Checks to see if atoms `i` and `j` in `crystal` are bonded according to the `bonding_rules`.

# Arguments
-`crystal::Crystal`: The crystal that bonds will be added to
-`i::Int`: Index of the first atom
-`j::Int`: Index of the second atom
-`bonding_rules::Array{BondingRule, 1}`: The array of bonding rules that will
    be used to fill the bonding information. They are applied in the order that
    they appear.
-`include_bonds_across_periodic_boundaries::Bool`: Whether to check across the
    periodic boundary when calculating bonds

# Returns
-`are_atoms_bonded::Bool`: Whether atoms `i` and `j` are bonded according to `bonding_rules`

"""
function is_bonded(crystal::Crystal, i::Int64, j::Int64, bonding_rules::Array{BondingRule, 1};
        include_bonds_across_periodic_boundaries::Bool=true)
    species_i = crystal.atoms.species[i]
    species_j = crystal.atoms.species[j]

    r = distance(crystal.atoms, crystal.box, i, j, include_bonds_across_periodic_boundaries)

    # loop over possible bonding rules
    for br in bonding_rules
        # determine if the atom species correspond to the species in `bonding_rules`
        species_match = false
        if br.species_i == :* && br.species_j == :*
            species_match = true
        elseif br.species_i == :* && (species_i == br.species_j || species_j == br.species_j)
            species_match = true
        elseif br.species_j == :* && (species_i == br.species_i || species_j == br.species_j)
            species_match = true
        elseif (species_i == br.species_i && species_j == br.species_j) || (species_j == br.species_i && species_i == br.species_j)
            species_match = true
        end

        if species_match
            # determine if the atoms are close enough to bond
            if br.min_dist < r && br.max_dist > r
                return true
            else
                return false # found relevant bonding rule, don't apply others
            end
        end
    end
    return false # no bonding rule applied
end


"""
    remove_bonds!(crystal)

Remove all bonds from a crystal structure, `crystal::Crystal`.
"""
function remove_bonds!(crystal::Crystal)
    while ne(crystal.bonds) > 0
        rem_edge!(crystal.bonds, collect(edges(crystal.bonds))[1].src, collect(edges(crystal.bonds))[1].dst)
    end
end


"""
    infer_bonds!(crystal, include_bonds_across_periodic_boundaries,
                    bonding_rules=[BondingRule(:H, :*, 0.4, 1.2), BondingRule(:*, :*, 0.4, 1.9)])

Populate the bonds in the crystal object based on the bonding rules. If a
pair doesn't have a suitable rule then they will not be considered bonded.

`:*` is considered a wildcard and can be substituted for any species. It is a
good idea to include a bonding rule between two `:*` to allow any atoms to bond
as long as they are close enough.

The bonding rules are hierarchical, i.e. the first bonding rule takes precedence over the latter ones.

# Arguments
-`crystal::Crystal`: The crystal that bonds will be added to
-`include_bonds_across_periodic_boundaries::Bool`: Whether to check across the periodic boundary when calculating bonds
-`bonding_rules::Array{BondingRule, 1}`: The array of bonding rules that will be used to fill the bonding information. They are applied in the order that they appear.
-`cordero_params::Dict{Symbol, Dict{Symbol, Float64}}`: Cordero parameters to use for calculating bonding rules. See [`cordero_parameters`](@ref)
-`σ::Float64`: Number of Cordero estimated standard deviations to use if calculating bonding rules from covalent radii.
-`min_tol::Float64`: Minimum covalent radius tolerance if calculating bonding rules from covalent radii.
"""
function infer_bonds!(crystal::Crystal, include_bonds_across_periodic_boundaries::Bool;
        bonding_rules::Union{Array{BondingRule, 1}, Nothing}=nothing,
        cordero_params::Union{Dict{Symbol, Dict{Symbol, Float64}}, Nothing}=nothing,
        σ::Float64=3., min_tol::Float64=0.25)
    @assert ne(crystal.bonds) == 0 @sprintf("The crystal %s already has bonds. Remove them with the `remove_bonds!` function before inferring new ones.", crystal.name)
    if bonding_rules == nothing
        bonding_rules = bondingrules(cordero_params=cordero_params, σ=σ, min_tol=min_tol)
    end
    # loop over every atom
    for i in 1:crystal.atoms.n
        # loop over every unique pair of atoms
        for j in i+1:crystal.atoms.n
            if is_bonded(crystal, i, j, bonding_rules; include_bonds_across_periodic_boundaries=include_bonds_across_periodic_boundaries)
                add_edge!(crystal.bonds, i, j)
            end
        end
    end
end


"""
    cordero_params = cordero_parameters()

Create a dictionary with the Cordero covalent radius and estimated standard deviation for each element, using the data in `PATH_TO_DATA/cordero.csv`

    cordero_params = cordero_parameters("my_params.csv")

Create a dictionary with the Cordero covalent radius and estimated standard deviation for each element specified in `PATH_TO_DATA/my_params.csv`

# Arguments
-`cordero_data::String`: name of file containing covalent radii and estimated standard deviations.

# Returns
-`cordero_params::Dict{Symbol, Dict{Symbol, Float64}}`: A dictionary with elements as keys and dictionaries of respective cordero covalent radii and e.s.d.s as the values.

# Example
```julia
cordero_params = cordero_parameters()
cordero_params[:N][:radius_Å] # 0.71
cordero_params[:N][:esd_pm] # 1.0
```
"""
function cordero_parameters(; cordero_data::String="cordero.csv")
    # read Cordero data
    df = CSV.read(joinpath(PATH_TO_DATA, cordero_data), DataFrame, comment="#")
    # parse into params dict
    cordero_params = Dict{Symbol, Dict{Symbol, Float64}}()
    for atom in eachrow(df)
        cordero_params[Symbol(atom[:atom])] = Dict(:radius_Å => atom.covalent_radius_A, :esd_pm => atom.esd_pm)
    end
    # Carbon, Iron, Manganese, and Cobalt have multiple entries due to hybridization/spin
    # Generic Carbon approximation; sp3 hybridization is the largest r, sp2 is the largest esd. Mix-n-match.
    cordero_params[:C] = Dict(:radius_Å=> cordero_params[:C_sp3][:radius_Å], :esd_pm => cordero_params[:C_sp2][:esd_pm])
    # Generic Mn, Fe, Co approx's. High-spin r and esd is larger for each. Use high-spin.
    for x in [:Mn, :Fe, :Co]
        cordero_params[x] = cordero_params[Symbol(string(x) * "_hi")]
    end
    return cordero_params
end


"""
    dm = distance_matrix(crystal, apply_pbc)

Compute the distance matrix `a` of the crystal, where `a[i, j]` is the
distance between atom `i` and `j`. This matrix is symmetric. If `apply_pbc = true`,
periodic boundary conditions are applied when computing the distance.

# Arguments
-`crystal::Crystal`: crystal structure
-`apply_pbc::Bool`: whether or not to apply periodic boundary conditions when computing the distance

# Returns
-`dm::Array{Float64, 2}`: symmetric, square distance matrix with zeros on the diagonal
"""
function distance_matrix(crystal::Crystal, apply_pbc::Bool)
    dm = zeros(crystal.atoms.n, crystal.atoms.n)
    for i = 1:crystal.atoms.n
        for j = (i+1):crystal.atoms.n
            dm[i, j] = distance(crystal.atoms, crystal.box, i, j, apply_pbc)
            dm[j, i] = dm[i, j] # symmetric
        end
    end
    return dm
end


"""
    ids_neighbors, xs, rs = neighborhood(crystal, i, r, dm)

Find and characterize the neighborhood of atom `i` in the crystal `crystal`.
A neighborhood is defined as all atoms within a distance `r` from atom `i`.
The distance matrix `dm` is used to find the distances of all other atoms in the crystal from atom `i`.

# Arguments
-`crystal::Crystal`: crystal structure
-`i::Int`: Index of the atom (in `crystal`) which the neighborhood is to be characterized.
-`r::Float64`: The maximum distance the neighborhood will be characterized.
-`dm::Array{Float64, 2}`: The distance matrix, see [`distance_matrix`](@ref)

# Returns
-`ids_neighbors::Array{Int, 1}`: indices of `crystal.atoms` within the neighborhood of atom `i`.
-`xs::Array{Array{Float64, 1}, 1}`: array of Cartesian positions of the atoms surrounding atom `i`.
    The nearest image convention has been applied to find the nearest periodic image. Also, the coordinates of atom `i`
    have been subtracted off from these coordinates so that atom `i` lies at the origin of this new coordinate system.
    The first vector in `xs` is `[0, 0, 0]` corresponding to atom `i`.
    The choice of type is for the Voronoi decomposition in Scipy.
-`rs::Array{Float64, 1}`: list of distances of the neighboring atoms from atom `i`.
"""
function neighborhood(crystal::Crystal, i::Int, r::Float64, dm::Array{Float64, 2})
    # get indices of atoms within a distance r of atom i
    #  the greater than zero part is to not include itself
    ids_neighbors = findall((dm[:, i] .> 0.0) .& (dm[:, i] .< r))

    # rs is the list of distance of these neighbors from atom i
    rs = [dm[i, id_n] for id_n in ids_neighbors]
    @assert all(rs .< r)

    # xs is a list of Cartesian coords of the neighborhood
    #  coords of atom i are subtracted off
    #  first entry is coords of atom i, the center, the zero vector
    #  remaining entries are neighbors
    # this list is useful to pass to Voronoi for getting Voronoi faces
    #  of the neighborhood.
    xs = [[0.0, 0.0, 0.0]] # this way atom zero is itself
    for j in ids_neighbors
        # subtract off atom i, apply nearest image
        xf = crystal.atoms.coords.xf[:, j] - crystal.atoms.coords.xf[:, i]
        nearest_image!(xf)
        x = crystal.box.f_to_c * xf
        push!(xs, x)
    end
    return ids_neighbors, xs , rs
end


"""
    ids_shared_voro_face = _shared_voronoi_faces(ids_neighbors, xs)

Of the neighboring atoms, find those that share a Voronoi face.

# Arguments
-`ids_neighbors::Array{Int, 1}`: indices of atoms within the neighborhood of a specific atom.
-`xs::Array{Array{Float64, 1}, 1}`: array of Cartesian position of the atoms within the neighborhood of a specific atom, relative to the specific atom.

# Returns
-`ids_shared_voro_face::Array{Int, 1}`: indices of atoms that share a Voronoi face with a specific atom
"""
function _shared_voronoi_faces(ids_neighbors::Array{Int, 1}, xs::Array{Array{Float64, 1}, 1})
    scipy = pyimport("scipy.spatial")
    # first element of xs is the point itself, the origin
    @assert length(ids_neighbors) == (length(xs) - 1)

    voro = scipy.Voronoi(xs)
    rps = voro.ridge_points # connection with atom zero are connection with atom i
    ids_shared_voro_face = Int[] # corresponds to xs, not to atoms of crystal
    for k = 1:size(rps)[1]
        if sort(rps[k, :])[1] == 0 # a shared face with atom i!
            push!(ids_shared_voro_face, sort(rps[k, :])[2])
        end
    end
    # zero based indexing in Scipy accounted for since xs[0] is origin, atom i.
    return ids_neighbors[ids_shared_voro_face]
end


"""
    ids_bonded = bonded_atoms(crystal, i, dm; r=6., σ=3.)

Returns the ids of atoms that are bonded to atom `i` by determining bonds using a Voronoi method and covalent radius data (see [`cordero_parameters`](@ref))

# Arguments
-`crystal::Crystal`: Crystal structure in which the bonded atoms will be determined
-`i::Int`: Index of the atom we want to determine the bonds of
-`dm::Array{Float64, 2}`: The distance matrix, see [`distance_matrix`](@ref)
-`r::Float64`: The maximum distance used to determine the neighborhood of atom `i`
-`σ::Float64`: Sets the number of e.s.d.s for the margin of error on covalent radii
-`cordero_params::Dict{Symbol, Dict{Symbol, Float64}}`: Cordero parameter dictionary. See [`cordero_parameters`](@ref)
-`min_tol::Float64`: The minimum covalent radius tolerance in Å

# Returns
-`ids_bonded::Array{Int, 1}`: A list of indices of atoms bonded to atom `i`
"""
function bonded_atoms(crystal::Crystal, i::Int, dm::Array{Float64, 2},
        r::Float64, σ::Float64, min_tol::Float64,
        cordero_params::Dict{Symbol, Dict{Symbol, Float64}})
    species_i = crystal.atoms.species[i]
    ids_neighbors, xs, rs = neighborhood(crystal, i, r, dm)
    ids_shared_voro_faces = _shared_voronoi_faces(ids_neighbors, xs)
    ids_bonded = Int[]
    for j in ids_shared_voro_faces
        species_j = crystal.atoms.species[j]
        # sum of covalent radii
        radii_sum = cordero_params[species_j][:radius_Å] + cordero_params[species_i][:radius_Å]
        # margin = σ e.s.d.s, unless that's too small
        margin = max(min_tol,
            σ * (cordero_params[species_j][:esd_pm] + cordero_params[species_i][:esd_pm]) / 100)
        max_dist = radii_sum + margin
        min_dist = radii_sum - margin
        if dm[i, j] ≤ max_dist && dm[i, j] ≥ min_dist
            push!(ids_bonded, j)
        end
    end
    return ids_bonded
end


"""
    infer_geometry_based_bonds!(crystal, include_bonds_across_periodic_boundaries::Bool)

Infers bonds by first finding which atoms share a Voronoi face, and then bond the atoms if the distance
 between them is less than the sum of the covalent radius of the two atoms (plus a tolerance).

# Arguments
-`crystal::Crystal`: The crystal structure
-`include_bonds_across_periodic_boundaries::Bool`: Whether to check across the periodic boundaries
-`r::Float`: voronoi radius, Å
-`σ::Float`: number of estimated standard deviations to use for covalent radius tolerance
-`min_tol::Float`: minimum tolerance for calculated bond distances, Å
-`cordero_params::Dict{Symbol, Dict{Symbol, Float64}}`: See [`cordero_parameters`](@ref)
"""
function infer_geometry_based_bonds!(crystal::Crystal, include_bonds_across_periodic_boundaries::Bool;
                                     r::Float64=6., σ::Float64=3., min_tol::Float64=0.25,
                                     cordero_params::Union{Nothing, Dict{Symbol, Dict{Symbol, Float64}}}=nothing)
    @assert ne(crystal.bonds) == 0 @sprintf("The crystal %s already has bonds. Remove them with the `remove_bonds!` function before inferring new ones.", crystal.name)
    if cordero_params == nothing
        cordero_params = cordero_parameters()
    end
    dm = distance_matrix(crystal, include_bonds_across_periodic_boundaries)
    for i = 1:crystal.atoms.n
        for j in bonded_atoms(crystal, i, dm, r, σ, min_tol, cordero_params)
            add_edge!(crystal.bonds, i, j)
        end
    end
end


"""
    sane_bonds = bond_sanity_check(crystal)

Run sanity checks on `crystal.bonds`.
* is the bond graph fully connected? i.e. does every vertex (=atom) in the bond graph have at least one edge?
* each hydrogen can have only one bond
* each carbon can have a maximum of four bonds

if sanity checks fail, refer to [`write_bond_information`](@ref) to write a .vtk to visualize the bonds.

Print warnings when sanity checks fail.
Return `true` if sanity checks pass, `false` otherwise.
"""
function bond_sanity_check(crystal::Crystal)
    for a = 1:crystal.atoms.n
        ns = neighbors(crystal.bonds, a)
        # is the graph fully connected?
        if length(ns) == 0
            @warn "atom $a = $(crystal.atoms.species[a]) in $(crystal.name) is not bonded to any other atom."
            return false
        end
        # does hydrogen have only one bond?
        if (crystal.atoms.species[a] == :H) && (length(ns) > 1)
            @warn "hydrogen atom $a in $(crystal.name) is bonded to more than one atom!"
            return false
        end
        # does carbon have greater than four bonds?
        if (crystal.atoms.species[a] == :C) && (length(ns) > 4)
            @warn "carbon atom $a in $(crystal.name) is bonded to more than four atoms!"
            return false
        end
    end
    return true
end


# TODO remove? why is this needed?
"""
    bonds_equal = compare_bonds_in_crystal(crystal1, crystal2, atol=0.0)

Returns whether the bonds defined in crystal1 are the same as the bonds
defined in crystal2. It checks whether the atoms in the same positions
have the same bonds.

# Arguments
-`crystal1::Crystal`: The first crystal
-`crystal2::Crystal`: The second crystal
-`atol::Float64`: absolute tolerance for the comparison of coordinates in the crystal

# Returns
-`bonds_equal::Bool`: Wether the bonds in crystal1 and crystal2 are equal
"""
function compare_bonds_in_crystal(fi::Crystal, fj::Crystal; atol::Float64=0.0)
    if ne(fi.bonds) != ne(fj.bonds)
        return false
    end

    num_in_common = 0
    for edge_i in collect(edges(fi.bonds))
        for edge_j in collect(edges(fj.bonds))
            # either the bond matches going src-src dst-dst
            if  (fi.atoms.species[edge_i.src] == fj.atoms.species[edge_j.src] &&
                 fi.atoms.species[edge_i.dst] == fj.atoms.species[edge_j.dst] &&
                 isapprox(fi.atoms.xf[:, edge_i.src], fj.atoms.xf[:, edge_j.src]; atol=atol) &&
                 isapprox(fi.atoms.xf[:, edge_i.dst], fj.atoms.xf[:, edge_j.dst]; atol=atol)) ||
                # or the bond matches going src-dst dst-src
                (fi.atoms.species[edge_i.src] == fj.atoms.species[edge_j.dst] &&
                 fi.atoms.species[edge_i.dst] == fj.atoms.species[edge_j.src] &&
                 isapprox(fi.atoms.xf[:, edge_i.src], fj.atoms.xf[:, edge_j.dst]; atol=atol) &&
                 isapprox(fi.atoms.xf[:, edge_i.dst], fj.atoms.xf[:, edge_j.src]; atol=atol))
                num_in_common += 1
                break
            end
        end
    end
    return num_in_common == ne(fi.bonds) && num_in_common == ne(fj.bonds)
end


"""
    write_bond_information(crystal, filename)
    write_bond_information(crystal, center_at_origin=false)

Writes the bond information from a crystal to the selected filename.

# Arguments
-`crystal::Crystal`: The crystal to have its bonds written to a vtk file
-`filename::String`: The filename the bond information will be saved to. If left out, will default to crystal name.
- `center_at_origin::Bool`: center the coordinates at the origin of the crystal
"""
function write_bond_information(crystal::Crystal, filename::String; center_at_origin::Bool=false)
    if ne(crystal.bonds) == 0
        @warn("Crystal %s has no bonds present. To get bonding information for this crystal run `infer_bonds!` with an array of bonding rules\n", crystal.name)
    end
    if ! occursin(".vtk", filename)
        filename *= ".vtk"
    end

    vtk_file = open(filename, "w")

    @printf(vtk_file, "# vtk DataFile Version 2.0\n%s bond information\nASCII\nDATASET POLYDATA\nPOINTS %d double\n", crystal.name, nv(crystal.bonds))

    for i = 1:crystal.atoms.n
        if center_at_origin
            @printf(vtk_file, "%0.5f\t%0.5f\t%0.5f\n", (crystal.box.f_to_c * (crystal.atoms.coords.xf[:, i] - [0.5, 0.5, 0.5]))...)
        else
            @printf(vtk_file, "%0.5f\t%0.5f\t%0.5f\n", (crystal.box.f_to_c * crystal.atoms.coords.xf[:, i])...)
        end
    end
    @printf(vtk_file, "\nLINES %d %d\n", ne(crystal.bonds), 3 * ne(crystal.bonds))
    for edge in collect(edges(crystal.bonds))
        @printf(vtk_file, "2\t%d\t%d\n", edge.src - 1, edge.dst - 1)
    end
    close(vtk_file)
    @printf("Saving bond information for crystal %s to %s.\n", crystal.name, joinpath(pwd(), filename))
end

write_bond_information(crystal::Crystal; center_at_origin::Bool=false) = write_bond_information(crystal, split(crystal.name, ".")[1] * "_bonds.vtk", center_at_origin=center_at_origin)

# TODO remove bonds with atom i?
