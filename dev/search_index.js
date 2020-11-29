var documenterSearchIndex = {"docs":
[{"location":"matter/#Matter-and-Coordinates","page":"matter","title":"Matter and Coordinates","text":"","category":"section"},{"location":"matter/","page":"matter","title":"matter","text":"Atoms and Charges are the building blocks of Crystals and Molecules in Xtals.jl. Each have coordinates in both Cartesian and Fractional space (associated with unit cell information, i.e., a Box).","category":"page"},{"location":"matter/#Coordinates","page":"matter","title":"Coordinates","text":"","category":"section"},{"location":"matter/","page":"matter","title":"matter","text":"we store coordinates as an abstract Coords type that has two subtypes: Cart and Frac for Cartesian and Fractional, respectively. see the Wikipedia page on fractional coordinates, which are defined in the context of a periodic system, e.g. within a crystal.","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"construct coordinates of n particles by passing a n by 3 array","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"coord = Cart([1.0, 2.0, 5.0])  # construct cartesian coordinate of a particle\ncoord.x                        # 3 x 1 array, [1, 2, 3]\n\ncoord = Frac([0.1, 0.2, 0.5])  # construct fractional coordinate of a particle\ncoord.xf                       # 3 x 1 array, [0.1, 0.2, 0.3]","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"the coordinates of multiple particles are stored column-wise:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"coords = Cart(rand(3, 5))      # five particles at uniform random coordinates","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"many Array operations work on Coords, such as:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"coords[2]                      # coordinate of 2nd particle\ncoords[2:3]                    # (slicing by index) coords of particles 2 and 3\ncoords[[1, 2, 5]]              # (slicing by index) coords of particles 1, 2, and 5\ncoords[rand(Bool, 5)]          # (boolean slicing) coords, selected at random\nlength(coords)                 # number of particles, (5)","category":"page"},{"location":"matter/#manipulating-coordinates","page":"matter","title":"manipulating coordinates","text":"","category":"section"},{"location":"matter/","page":"matter","title":"matter","text":"Coords are immutable:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"coords.x = rand(3, 3)          # fails! coordinates are immutable","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"but we can manipulate the values of Array{Float64, 2} where coordinates (through coords.x or coords.xf) are stored:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"coords.x[2, 3] = 100.0         # successful!\ncoords.x[:] = rand(3, 3)       # successful! (achieves the above, but need the [:] to say \"overwrite all of the elements\"","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"fractional coordinates can be wrapped to be inside the unit cell box:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"coords = Frac([1.2, -0.3, 0.9])\nwrap!(coords)\ncoords.xf                      # [0.2, 0.7, 0.9]","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"we can translate coordinates by a vector dx:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"dx = Cart([1.0, 2.0, 3.0])\ncoords = Cart([1.0, 0.0, 0.0])  \ntranslate_by!(coords, dx)\ncoords.x                        # [2.0, 2.0, 3.0]","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"if dx::Frac and coords::Cart, translate_by! requires a Box to convert between fractional and cartesian, as the last argument:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"dx = Frac([0.1, 0.2, 0.3])\nbox = unit_cube()\ncoords = Cart([1.0, 0.0, 0.0])\ntranslate_by!(coords, dx)       # fails! need to know Box...\ntranslate_by!(coords, dx, box)\ncoords.x                        # [1.1, 0.2, 0.3]","category":"page"},{"location":"matter/#Atoms","page":"matter","title":"Atoms","text":"","category":"section"},{"location":"matter/","page":"matter","title":"matter","text":"an atom is specified by its coordinates and atomic species. we can construct a set of atoms (perhaps, comprising a molecule or crystal) as follows.","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"species = [:O, :H, :H]            # atomic species are represnted with Symbols\ncoords = Cart([0.0 0.757 -0.757;  # coordinates of each\n               0.0 0.586  0.586;\n               0.0 0.0    0.0   ]\n             )\natoms = Atoms(species, coords)    # 3 atoms comprising water\natoms.n                           # number of atoms, 3\natoms.coords                      # coordinates; atoms.coords.x gives the array of coords\natoms.species                     # array of species\natoms::Atoms{Cart}                # successful type assertion, as opposed to atoms::Atoms{Frac}","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"the last line illustrates the two subtypes of Atoms, depending on whether the Coords are stored as Fractional or Cartesian.","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"we can slice atoms, such as:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"atoms[1]                         # 1st atom\natoms[2:3]                       # 2nd and 3rd atom","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"and combine them:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"atoms_combined = atoms[1] + atoms[2:3]   # combine atoms 1, 2, and 3\nisapprox(atoms, atoms_combined)          # true","category":"page"},{"location":"matter/#Charges","page":"matter","title":"Charges","text":"","category":"section"},{"location":"matter/","page":"matter","title":"matter","text":"Charges, well, point charges, work analogously to atoms, except instead of species, the values of the point charges are stored in an array, q.","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"q = [-1.0, 0.5, 0.5]              # values of point charges, units: electrons\ncoords = Cart([0.0 0.757 -0.757;  # coordinates of the point charges\n               0.0 0.586  0.586;\n               0.0 0.0    0.0   ]\n             )\ncharges = Charges(q, coords)      # 3 point charges\ncharges.n                         # number of charges, 3\ncharges.coords                    # retreive coords\ncharges.q                         # retreive q\ncharges::Charges{Cart}            # successful type assertion, as opposed to charges::Charges{Frac}","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"we can determine if the set of point charges comprise a charge-neutral system by:","category":"page"},{"location":"matter/","page":"matter","title":"matter","text":"net_charge(charges)                 # 0.0\nneutral(charges)                    # true","category":"page"},{"location":"matter/#detailed-docs","page":"matter","title":"detailed docs","text":"","category":"section"},{"location":"matter/","page":"matter","title":"matter","text":"    Coords\n    Frac\n    Cart\n    Atoms\n    Charges\n    net_charge\n    neutral\n    translate_by!","category":"page"},{"location":"matter/#Xtals.Coords","page":"matter","title":"Xtals.Coords","text":"abstract type for coordinates.\n\n\n\n\n\n","category":"type"},{"location":"matter/#Xtals.Cart","page":"matter","title":"Xtals.Cart","text":"cartesian coordinates, a subtype of Coords.\n\nconstruct by passing an Array{Float64, 2} whose columns are the coordinates.\n\ne.g.\n\nc_coords = Cart(rand(3, 2))  # 2 particles\nc_coords.x                   # retreive cartesian coords\n\n\n\n\n\n","category":"type"},{"location":"matter/#Xtals.Atoms","page":"matter","title":"Xtals.Atoms","text":"used to represent a set of atoms in space (their atomic species and coordinates).\n\nstruct Atoms{T<:Coords} # enforce that the type specified is `Coords`\n    n::Int # how many atoms?\n    species::Array{Symbol, 1} # list of species\n    coords::T # coordinates\nend\n\nhere, T is Frac or Cart.\n\nhelper constructor (infers n):\n\nspecies = [:H, :H]\ncoords = Cart(rand(3, 2))\natoms = Atoms(species, coords)\n\n\n\n\n\n","category":"type"},{"location":"matter/#Xtals.Charges","page":"matter","title":"Xtals.Charges","text":"used to represent a set of partial point charges in space (their charges and coordinates).\n\nstruct Charges{T<:Coords} # enforce that the type specified is `Coords`\n    n::Int\n    q::Array{Float64, 1}\n    coords::T\nend\n\nhere, T is Frac or Cart.\n\nhelper constructor (infers n):\n\nq = [0.1, -0.1]\ncoords = Cart(rand(3, 2))\ncharges = Charges(q, coords)\n\n\n\n\n\n","category":"type"},{"location":"matter/#Xtals.net_charge","page":"matter","title":"Xtals.net_charge","text":"nc = net_charge(charges)\nnc = net_charge(crystal)\nnc = net_charge(molecule)\n\nfind the sum of charges in charges::Charges or charges in crystal::Crystal or molecule::Molecule. (if there are no charges, the net charge is zero.)\n\n\n\n\n\n","category":"function"},{"location":"matter/#Xtals.neutral","page":"matter","title":"Xtals.neutral","text":"neutral(charges, tol) # true or false. default tol = 1e-5\nneutral(crystal, tol) # true or false. default tol = 1e-5\n\ndetermine if a set of charges::Charges (charges.q) sum to an absolute value less than tol::Float64. if crystal::Crystal is passed, the function looks at the crystal.charges. i.e. determine the absolute value of the net charge is less than tol.\n\n\n\n\n\n","category":"function"},{"location":"matter/#Xtals.translate_by!","page":"matter","title":"Xtals.translate_by!","text":"translate_by!(coords, dx)\ntranslate_by!(coords, dx, box)\ntranslate_by!(molecule, dx)\ntranslate_by!(molecule, dx, box)\n\ntranslate coords by the vector dx. that is, add the vector dx.\n\nthis works for any combination of Frac and Cart coords.\n\nmodifies coordinates in place.\n\nbox is needed when mixing Frac and Cart coords.\n\nnote that periodic boundary conditions are not subsequently applied here.\n\nif applied to a molecule::Molecule, the coords of atoms, charges, and center of mass are all translated.\n\n\n\n\n\n","category":"function"},{"location":"distance/#Distances","page":"computing distances","title":"Distances","text":"","category":"section"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"The distance between two Atoms in a Crystal is central to many operations within Xtals.jl.  The distance function calculates the Cartesian displacement between the Coords (Cart or Frac) of two points, i and j, within a given box.","category":"page"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"xtal = Crystal(\"Co-MOF-74.cif\")\ndistance(xtal.atoms.coords, xtal.box, 1, 2, false) # 23.2 Å","category":"page"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"The apply_pbc argument allows for calculation of distances across the periodic boundaries of the box.","category":"page"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"distance(xtal.atoms.coords, xtal.box, 1, 2, true) # 3.34 Å","category":"page"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"distance also works on Atoms and Charges.","category":"page"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"distance(xtal.atoms, xtal.box, 3, 5, true)","category":"page"},{"location":"distance/#docs","page":"computing distances","title":"docs","text":"","category":"section"},{"location":"distance/","page":"computing distances","title":"computing distances","text":"    distance","category":"page"},{"location":"distance/#Xtals.distance","page":"computing distances","title":"Xtals.distance","text":"r = distance(coords, box, i, j, apply_pbc)\nr = distance(atoms, box, i, j, apply_pbc) # atoms i and j\nr = distance(charges, box, i, j, apply_pbc) # atoms i and j\n\ncalculate the (Cartesian) distance between particles i and j.\n\napply periodic boundary conditions if and only if apply_pbc is true.\n\narguments\n\ncoords::Coords: the coordinates (Frac>:Coords or Cart>:Coords)\natoms::Atoms: atoms\ncharges::charges: atoms\nbox::Box: unit cell information\ni::Int: index of the first particle\nj::Int: Index of the second particle\napply_pbc::Bool: true if we wish to apply periodic boundary conditions, false otherwise\n\n\n\n\n\n","category":"function"},{"location":"box/#The-Spatial-Box","page":"boxes","title":"The Spatial Box","text":"","category":"section"},{"location":"box/","page":"boxes","title":"boxes","text":"Within Xtals.jl, the 3D space in which all Coords are located is the Box.  Each Crystal has its own Box, equivalent to the unit cell of a material, containing as attributes the unit cell edge lengths (a b c), crystallographic dihedral angles (α β γ), volume, conversion factors for translating between Fractional and Cartesian coordinates, and the reciprocal (Fourier transform) vectors for the Bravais lattice.","category":"page"},{"location":"box/#defining-a-box","page":"boxes","title":"defining a box","text":"","category":"section"},{"location":"box/","page":"boxes","title":"boxes","text":"A Box is most conveniently constructed from its basic spatial data (a b c α β γ).  For example, given the unit cell of Co-MOF-74, we can define its Box:","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"a = 26.13173 # Å\nb = 26.13173\nc = 6.722028\nα = π/2 # radians\nβ = π/2\nγ = 2*π/3\nbox = Box(a, b, c, α, β, γ)","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"A Box may also be defined by providing only the Fractional-to-Cartesian conversion matrix:","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"box = Box([26.1317 -13.0659 0; 0 22.6307 0; 0 0 6.72203])","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"To quickly get a simple unit-cubic Box, use the unit_cube function.","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"@info unit_cube()\n#┌ Info: Bravais unit cell of a crystal.\n#│       Unit cell angles α = 90.000000 deg. β = 90.000000 deg. γ = 90.000000 deg.\n#│       Unit cell dimensions a = 1.000000 Å. b = 1.000000 Å, c = 1.000000 Å\n#└       Volume of unit cell: 1.000000 Å³","category":"page"},{"location":"box/#transforming-coordinates","page":"boxes","title":"transforming coordinates","text":"","category":"section"},{"location":"box/","page":"boxes","title":"boxes","text":"Conversions are provided for switching between Fractional and Cartesian Coords using the Box (works for Atoms and Charges, too)","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"xtal = Crystal(\"Co-MOF-74.cif\")\nCart(xtal.atoms.coords, xtal.box)\n#Cart([-5.496156112249995 7.181391379950001 … 15.131970232450003 2.4686645331000063;\n# 22.270234304380295 2.8331425940892103 … 0.7607701110682343 22.13256395706254;\n# 1.231811631 0.32198514120000005 … 6.2082409932000004 2.2119953472])","category":"page"},{"location":"box/#replicating-a-box","page":"boxes","title":"replicating a box","text":"","category":"section"},{"location":"box/","page":"boxes","title":"boxes","text":"For simulations in larger volumes than a single crystallograhic unit cell, the Box may be replicated along each or any of the three crystallographic axes.","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"replicated_box = replicate(box, (2,2,2))","category":"page"},{"location":"box/#exporting-a-box","page":"boxes","title":"exporting a box","text":"","category":"section"},{"location":"box/","page":"boxes","title":"boxes","text":"For visualization of the unit cell boundaries, the Box may be written out to a .vtk file for use in Visit","category":"page"},{"location":"box/","page":"boxes","title":"boxes","text":"write_vtk(box, \"box.vtk\")","category":"page"},{"location":"box/#detailed-docs","page":"boxes","title":"detailed docs","text":"","category":"section"},{"location":"box/","page":"boxes","title":"boxes","text":"    Box\n    unit_cube\n    replicate\n    write_vtk\n    Frac","category":"page"},{"location":"box/#Xtals.Box","page":"boxes","title":"Xtals.Box","text":"box = Box(a, b, c, α, β, γ, volume, f_to_c, c_to_f, reciprocal_lattice)\nbox = Box(a, b, c, α, β, γ)\nbox = Box(a, b, c) # α=β=γ=π/2 assumed.\nbox = Box(f_to_c)\n\nData structure to describe a unit cell box (Bravais lattice) and convert between fractional and Cartesian coordinates.\n\nAttributes\n\na,b,c::Float64: unit cell dimensions (units: Angstroms)\nα,β,γ::Float64: unit cell angles (units: radians)\nΩ::Float64: volume of the unit cell (units: cubic Angtroms)\nf_to_c::Array{Float64,2}: the 3x3 transformation matrix used to map fractional\n\ncoordinates to cartesian coordinates. The columns of this matrix define the unit cell axes. Columns are the vectors defining the unit cell box. units: Angstrom\n\nc_to_f::Array{Float64,2}: the 3x3 transformation matrix used to map Cartesian\n\ncoordinates to fractional coordinates. units: inverse Angstrom\n\nreciprocal_lattice::Array{Float64, 2}: the rows are the reciprocal lattice vectors.\n\nThis choice was made (instead of columns) for speed of Ewald Sums.\n\n\n\n\n\n","category":"type"},{"location":"box/#Xtals.unit_cube","page":"boxes","title":"Xtals.unit_cube","text":"uc = unit_cube()\n\nThis function generates a unit cube, each side is 1.0 Angstrom long, and all the corners are right angles.\n\n\n\n\n\n","category":"function"},{"location":"box/#Xtals.replicate","page":"boxes","title":"Xtals.replicate","text":"new_box = replicate(original_box, repfactors)\n\nReplicates a Box in positive directions to construct a new Box representing a supercell. The original_box is replicated according to the factors in repfactors. Note replicate(original_box, repfactors=(1, 1, 1)) returns same Box. The new fractional coordinates as described by f_to_c and c_to_f still ∈ [0, 1].\n\nArguments\n\noriginal_box::Box: The box that you want to replicate\nrepfactors::Tuple{Int, Int, Int}: The factor you want to replicate the box by\n\nReturns\n\nbox::Box: Fully formed Box object\n\n\n\n\n\nreplicated_crystal = replicate(crystal, repfactors)\n\nreplicate the atoms and charges in a Crystal in positive directions to construct a new Crystal. Note replicate(crystal, (1, 1, 1)) returns the same Crystal. the fractional coordinates will be rescaled to be in [0, 1].\n\narguments\n\ncrystal::Crystal: The crystal to replicate\nrepfactors::Tuple{Int, Int, Int}: The factors by which to replicate the crystal structure in each crystallographic direction (a, b, c).\n\nreturns\n\nreplicated_frame::Crystal: replicated crystal\n\n\n\n\n\n","category":"function"},{"location":"box/#Xtals.write_vtk","page":"boxes","title":"Xtals.write_vtk","text":"write_vtk(box, filename; verbose=true, center_at_origin=false)\nwrite_vtk(framework)\n\nWrite a Box to a .vtk file for visualizing e.g. the unit cell boundary of a crystal. If a Framework is passed, the Box of that framework is written to a file that is the same as the crystal structure filename but with a .vtk extension.\n\nAppends \".vtk\" extension to filename automatically if not passed.\n\nArguments\n\nbox::Box: a Bravais lattice\nfilename::AbstractString: filename of the .vtk file output (absolute path)\nframework::Framework: A framework containing the crystal structure information\ncenter_at_origin::Bool: center box at origin if true. if false, the origin is the corner of the box.\n\n\n\n\n\n","category":"function"},{"location":"box/#Xtals.Frac","page":"boxes","title":"Xtals.Frac","text":"fractional coordinates, a subtype of Coords.\n\nconstruct by passing an Array{Float64, 2} whose columns are the coordinates.\n\ngenerally, fractional coordinates should be in [0, 1] and are implicitly associated with a Box to represent a periodic coordinate system.\n\ne.g.\n\nf_coords = Frac(rand(3, 2))  # 2 particles\nf_coords.xf                  # retreive fractional coords\n\n\n\n\n\n","category":"type"},{"location":"#Xtals.jl","page":"Xtals","title":"Xtals.jl","text":"","category":"section"},{"location":"","page":"Xtals","title":"Xtals","text":"A pure-Julia package for representation of porous crystals such as metal-organic frameworks (MOFs).","category":"page"},{"location":"","page":"Xtals","title":"Xtals","text":"In development, please contribute, post issues 🐛, and improve!","category":"page"},{"location":"#Installation","page":"Xtals","title":"Installation","text":"","category":"section"},{"location":"","page":"Xtals","title":"Xtals","text":"Download and install the Julia programming language,","category":"page"},{"location":"","page":"Xtals","title":"Xtals","text":"v1.5 or higher.","category":"page"},{"location":"","page":"Xtals","title":"Xtals","text":"In Julia, open the package manager (using ]) and enter the following:","category":"page"},{"location":"","page":"Xtals","title":"Xtals","text":"pkg> add Xtals","category":"page"},{"location":"","page":"Xtals","title":"Xtals","text":"In Julia, load all functions in Xtals.jl into the namespace:","category":"page"},{"location":"","page":"Xtals","title":"Xtals","text":"julia> using Xtals # that's it","category":"page"},{"location":"#Tests","page":"Xtals","title":"Tests","text":"","category":"section"},{"location":"","page":"Xtals","title":"Xtals","text":"Run the tests in the script tests/runtests.jl manually or by ] test Xtals in the Julia REPL.","category":"page"},{"location":"crystal/#Crystals","page":"crystals","title":"Crystals","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"Xtals.jl maintains a data structure Crystal that stores information about a crystal structure file.","category":"page"},{"location":"crystal/#reading-in-a-crystal-structure-file","page":"crystals","title":"reading in a crystal structure file","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"Currently, the crystal structure file reader accepts .cif and .cssr file formats. Xtals.jl looks for the crystal structure files in Xtals.PATH_TO_CRYSTALS which is by default ./data/crystals. By typing set_path_to_crystals(\"my_crystal_dir\"), Xtals.jl now looks for the crystal structure file in my_crystal_dir. The files can be read as:","category":"page"},{"location":"crystal/","page":"crystals","title":"crystals","text":"xtal = Crystal(\"IRMOF-1.cif\")       # The crystal reader stores the information in xtal\nxtal.name                           # The name of the crystal structure file\nxtal.box                            # The unit cell information\nxtal.atoms                          # The atom coordinates (in fractional space) and the atom identities\nxtal.charges                        # The charge magnitude and coordinates (in fractional space)\nxtal.bonds                          # Bonding information in the structure. By default this is an empty graph,\n                                    #  but use `read_bonds_from_file=true` argument in `Crystal` to read from crystal structure file\nxtal.symmetry                       # Symmetry information of the crystal. By default converts the symmetry to P1 symmetry.\n                                    #  Use `convert_to_p1=false` argument in `Crystal` to keep original symmetry","category":"page"},{"location":"crystal/#fixing-atom-species","page":"crystals","title":"fixing atom species","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"Often, the atoms species are appended by numbers. This messes with the internal workings of Xtals.jl. To circumvent this problem, the function strip_numbers_from_atom_labels!(xtal) removes the appending numbers. It is important to use this function prior to GCMC or Henry coefficient calculations.","category":"page"},{"location":"crystal/","page":"crystals","title":"crystals","text":"xtal.atoms.species              # [:C1, :C2, :O1, ...]\nstrip_numbers_from_atom_labels!(xtal)\nxtal.atoms.species              # [:C, :C, :O, ...]","category":"page"},{"location":"crystal/#converting-the-coordinates-to-cartesian-space","page":"crystals","title":"converting the coordinates to cartesian space","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"The coordinates of the crystals are stored in fractional coordinates. If one needs to analyze the cartesian coordinates of the crystal, that can be done by using the unit cell information of the crystal.","category":"page"},{"location":"crystal/","page":"crystals","title":"crystals","text":"xtal.atoms.coords.xf                                    # array of fractional coordinates\ncart_coords = xtal.box.f_to_c * xtal.atoms.coords.xf    # array of cartesian coordinates","category":"page"},{"location":"crystal/#creating-a-super-cell","page":"crystals","title":"creating a super cell","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"For many simulations, one needs to replicate the unit cell multiple times to create a bigger super cell.","category":"page"},{"location":"crystal/","page":"crystals","title":"crystals","text":"super_xtal = replicate(xtal, (2,2,2))       # Replicates the original unit cell once in each dimension","category":"page"},{"location":"crystal/#finding-other-properties","page":"crystals","title":"finding other properties","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"rho = crystal_density(xtal)         # Crystal density of the crystal in kg/m^2\nmw = molecular_weight(xtal)         # The molecular weight of the unit cell in amu\nformula = chemical_formula(xtal)    # The irreducible chemical formula of the crystal","category":"page"},{"location":"crystal/#assigning-new-charges","page":"crystals","title":"assigning new charges","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"If the crystal structure file does not contains partial charges, we provide methods to assign new charges to the crystal","category":"page"},{"location":"crystal/","page":"crystals","title":"crystals","text":"species_to_charges = Dict(:Ca => 2.0, :C => 1.0, :H => -1.0)                # This method assigns a static charge to atom species\ncharged_xtal = assign_charges(xtal, species_to_charge, 1e-5)                # This function creates a new charged `Crystal` object.\n                                                                            #   The function checks for charge neutrality with a tolerance of 1e-5\nnew_charges = Charges([2.0, 1.0, -1.0, -1.0, ...], xtal.atoms.coords)\nother_charged_xtal = Crystal(xtal.name, xtal.box, xtal.atoms,               # Here we create a new `Charges` object using an array of new charges.\n                             new_charges, xtal.bonds, xtal.symmetry)        #   The number of charges in the array has to be equal to the number of atoms\n                                                                            #   and finally a new `Crystal` object is manually created","category":"page"},{"location":"crystal/#writing-crystal-files","page":"crystals","title":"writing crystal files","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"We provide methods to write both .xyz and .cif files","category":"page"},{"location":"crystal/","page":"crystals","title":"crystals","text":"write_cif(xtal, \"my_new_cif_file.cif\")      # Stored in the current directory\nwrite_xyz(xtal, \"my_new_xyz_file.xyz\")      # stored in the current directory","category":"page"},{"location":"crystal/#detailed-docs","page":"crystals","title":"detailed docs","text":"","category":"section"},{"location":"crystal/","page":"crystals","title":"crystals","text":"    Crystal\n    SymmetryInfo\n    set_path_to_data\n    set_path_to_crystals\n    strip_numbers_from_atom_labels!\n    replicate\n    molecular_weight\n    crystal_density\n    chemical_formula\n    assign_charges\n    write_cif\n    write_xyz\n    read_xyz\n    read_mol","category":"page"},{"location":"crystal/#Xtals.Crystal","page":"crystals","title":"Xtals.Crystal","text":"crystal = Crystal(filename;\n    check_neutrality=true, net_charge_tol=1e-4,\n    check_overlap=true, overlap_tol=0.1,\n    convert_to_p1=true, read_bonds_from_file=false, wrap_coords=true,\n    include_zero_charges=false,\n    remove_duplicates=false,\n    species_col=[\"_atom_site_label\", \"_atom_site_type_symbol\"]\n    ) # read from file\n\ncrystal = Crystal(name, box, atoms, charges) # construct from matter, no bonds, P1-symmetry assumed\n\nRead a crystal structure file (.cif or .cssr) and populate a Crystal data structure, or construct a Crystal data structure directly.\n\nArguments\n\nfilename::String: the name of the crystal structure file (include \".cif\" or \".cssr\") read from PATH_TO_CRYSTALS.\ncheck_neutrality::Bool: check for charge neutrality\nnet_charge_tol::Float64: when checking for charge neutrality, throw an error if the absolute value of the net charge is larger than this value.\ncheck_overlap::Bool: throw an error if overlapping atoms are detected.\nconvert_to_p1::Bool: If the structure is not in P1 it will be converted to   P1 symmetry using the symmetry rules from the _symmetry_equiv_pos_as_xyz list in the .cif file.   (We do not use the space groups name to look up symmetry rules).\nread_bonds_from_file::Bool: Whether or not to read bonding information from   cif file. If false, the bonds can be inferred later. note that, if the crystal is not in P1 symmetry, we cannot both read bonds and convert to P1 symmetry.\nwrap_coords::Bool: if true, enforce that fractional coords of atoms and charges are in [0,1]³ by mod(x, 1)\ninclude_zero_charges::Bool: if false, do not include in crystal.charges atoms which have zero charges, in order to speed up the electrostatic calculations.   If true, include the atoms in crystal.charges that have zero charge, ensuring that the number of atoms is equal to the number of charges and that crystal.charges.coords.xf and crystal.atoms.coords.xf are the same.\nremove_duplicates::Bool: remove duplicate atoms and charges. an atom is duplicate only if it is the same species.\nspecies_col::Array{String}: which column to use for species identification for crystal.atoms.species. we use a priority list:   we check for the first entry of species_col in the .cif file; if not present, we then use the second entry, and so on.\ninfer_bonds::Union{Symbol, Missing}: if set, bonds are inferred according to the chosen method (:cordero or :voronoi). If set, must specify periodic_boundaries. By default, bonds are not inferred.\nperiodic_boundaries::Union{Bool, Missing}: use with infer_bonds to specify treatment of the unit cell boundary.  Set true to treat the unit cell edge as a periodic boundary (allow bonds across it); set false to restrict bonding to within the local unit cell.\n\nacross periodic unit cell boundaries; if false, bonds are only inferred within the local unit cell; if missing (default), bonds are not inferred.\n\nReturns\n\ncrystal::Crystal: A crystal containing the crystal structure information\n\nAttributes\n\nname::AbstractString: name of crystal structure\nbox::Box: unit cell (Bravais Lattice)\natoms::Atoms: list of Atoms in crystal unit cell\ncharges::Charges: list of point charges in crystal unit cell\nbonds::SimpleGraph: Unweighted, undirected graph showing all of the atoms   that are bonded within the crystal\nsymmetry::SymmetryInfo: symmetry inforomation\n\n\n\n\n\n","category":"type"},{"location":"crystal/#Xtals.set_path_to_data","page":"crystals","title":"Xtals.set_path_to_data","text":"set_path_to_data(\"../data/\")\n\nset the PATH_TO_DATA or PATH_TO_CRYSTALS variable. by default, sets PATH_TO_DATA to path, and PATH_TO_CRYSTALS to path/crystals.\n\nArguments\n\npath::String The path to use for setting the environment variable.\nrelpath_xtals::Bool Specify true to update path to crystals relative to new data path.\nprint::Bool Specify true to print path variables.\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.set_path_to_crystals","page":"crystals","title":"Xtals.set_path_to_crystals","text":"set_path_to_crystals(\"../other_crystals/\")\n\nset Xtals.PATH_TO_CRYSTALS.\n\nArguments\n\npath::String The path to use for setting the environment variable.\nprint::Bool Specify true to print path variables.\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.strip_numbers_from_atom_labels!","page":"crystals","title":"Xtals.strip_numbers_from_atom_labels!","text":"strip_numbers_from_atom_labels!(crystal)\n\nStrip numbers from labels for crystal.atoms. Precisely, for atom in crystal.atoms, find the first number that appears in atom. Remove this number and all following characters from atom. e.g. C12 –> C \t Ba12A_3 –> Ba\n\nArguments\n\ncrystal::Crystal: The crystal containing the crystal structure information\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.molecular_weight","page":"crystals","title":"Xtals.molecular_weight","text":"mass_of_crystal = molecular_weight(crystal)\n\nCalculates the molecular weight of a unit cell of the crystal in amu using information stored in data/atomicmasses.csv.\n\nArguments\n\ncrystal::Crystal: The crystal containing the crystal structure information\n\nReturns\n\nmass_of_crystal::Float64: The molecular weight of a unit cell of the crystal in amu\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.crystal_density","page":"crystals","title":"Xtals.crystal_density","text":"ρ = crystal_density(crystal) # kg/m²\n\nCompute the crystal density of a crystal. Pulls atomic masses from read_atomic_masses.\n\nArguments\n\ncrystal::Crystal: The crystal containing the crystal structure information\n\nReturns\n\nρ::Float64: The crystal density of a crystal in kg/m³\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.chemical_formula","page":"crystals","title":"Xtals.chemical_formula","text":"formula = chemical_formula(crystal, verbose=false)\n\nFind the irreducible chemical formula of a crystal structure.\n\nArguments\n\ncrystal::Crystal: The crystal containing the crystal structure information\nverbose::Bool: If true, will print the chemical formula as well\n\nReturns\n\nformula::Dict{Symbol, Int}: A dictionary with the irreducible chemical formula of a crystal structure\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.assign_charges","page":"crystals","title":"Xtals.assign_charges","text":"crystal_with_charges = assign_charges(crystal, species_to_charge, net_charge_tol=1e-5)\n\nassign charges to the atoms present in the crystal based on atom type. pass a dictionary species_to_charge that maps atomic species to a charge.\n\nif the crystal already has charges, the charges are removed and new charges are added. a warning is thrown if this is the case.\n\nchecks for charge neutrality in the end.\n\nreturns a new crystal.\n\nExamples\n\nspecies_to_charge = Dict(:Ca => 2.0, :C => 1.0, :H => -1.0)\ncrystal_with_charges = assign_charges(crystal, species_to_charge, 1e-7)\ncrystal_with_charges = assign_charges(crystal, species_to_charge) # tol 1e-5 default\n\nArguments\n\ncrystal::Crystal: the crystal\nspecies_to_charge::Dict{Symbol, Float64}: a dictionary that maps atomic species to charge\nnet_charge_tol::Float64: the net charge tolerated when asserting charge neutrality of\n\nthe resulting crystal\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.write_cif","page":"crystals","title":"Xtals.write_cif","text":"write_cif(crystal, filename; fractional_coords=true, number_atoms=true)\nwrite_cif(crystal) # writes to file crystal.name\n\nWrite a crystal::Crystal to a .cif file.\n\narguments\n\ncrystal::Crystal: crystal to write to file\nfilename::String: the filename of the .cif file. if \".cif\" is not included as an extension, it will automatically be appended to the filename string.\nfractional_coords::Bool=true: write the coordinates of the atoms as fractional coords if true. if false, write Cartesian coords.\nnumber_atoms::Bool=true: write the atoms as \"C1\", \"C2\", \"C3\", ..., \"N1\", \"N2\", ... etc. to give each atom a unique identifier\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.write_xyz","page":"crystals","title":"Xtals.write_xyz","text":"write_xyz(atoms, filename; comment=\"\")\nwrite_xyz(crystal; comment=\"\", center_at_origin=false)\nwrite_xyz(molecules, box, filename; comment=\"\") # fractional\nwrite_xyz(molecules, box, filename; comment=\"\") # Cartesian\n\nwrite atoms to an .xyz file.\n\nArguments\n\natoms::Atoms: the set of atoms.\nfilename::AbstractString: the filename (absolute path) of the .xyz file. (\".xyz\" appended automatically\n\nif the extension is not provided.)\n\ncomment::AbstractString: comment if you'd like to write to the file.\ncenter_at_origin::Bool: (for crystal only) if true, translate all coords such that the origin is the center of the unit cell.\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.read_xyz","page":"crystals","title":"Xtals.read_xyz","text":"atoms = read_xyz(\"molecule.xyz\")\n\nread a list of atomic species and their corresponding coordinates from an .xyz file.\n\nArguments\n\nfilename::AbstractString: the path to and filename of the .xyz file\n\nReturns\n\natoms::Atoms{Cart}: the set of atoms read from the .xyz file.\n\n\n\n\n\n","category":"function"},{"location":"crystal/#Xtals.read_mol","page":"crystals","title":"Xtals.read_mol","text":"atoms, bonds = read_mol(\"molecule.mol\")\n\nread a .mol file, which contains info about both atoms and bonds. see here for the anatomy of a .mol file.\n\nArguments\n\nfilename::AbstractString: the path to and filename of the .mol file (must pass extension)\n\nReturns\n\natoms::Atoms{Cart}: the set of atoms read from the .mol file.\nbonds::SimpleGraph: the bonding graph of the atoms read from the .mol file.\nbond_types::Array{Int, 1}: the array of bond types.\n\n\n\n\n\n","category":"function"}]
}
