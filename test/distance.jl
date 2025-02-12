module Distance_Test

using Xtals
using Test
using LinearAlgebra

@testset "Distance Tests" begin
    dxf = [-0.8, -0.4, 0.7]
    nearest_image!(dxf)
    @test isapprox(dxf, [0.2, -0.4, -0.3])

    dxf = [-0.3, -0.1, -0.9]
    nearest_image!(dxf)
    @test isapprox(dxf, [-0.3, -0.1, 0.1])

    # distance (fractional)
    f = Frac([0.2 0.4;
              0.1 0.8;
              0.8 0.6]
              )
    box = unit_cube()
    @test isapprox(distance(f, box, 1, 2, false),  norm(f.xf[:, 1] - f.xf[:, 2]))
    @test isapprox(distance(f, box, 2, 2, false), 0.0)
    @test isapprox(distance(f, box, 2, 1, false), distance(f, box, 1, 2, false))
    @test isapprox(distance(f, box, 1, 2, true),  norm(f.xf[:, 1] - [0.4, -0.2, 0.6]))
    box = Box(1.0, 10.0, 100.0)
    @test isapprox(distance(f, box, 1, 2, false),  norm([0.2, 1.0, 80.0] - [0.4, 8.0, 60.0]))
    @test isapprox(distance(f, box, 2, 1, true),  norm([0.2, 1.0, 80.0] - [0.4, -2.0, 60.0]))

    # distance (Cartesian)
    c = Cart([0.2 0.4;
              0.1 0.8;
              0.8 0.6]
              )
    box = unit_cube()
    @test isapprox(distance(c, box, 1, 2, false),  norm(c.x[:, 1] - c.x[:, 2]))
    @test isapprox(distance(c, box, 2, 2, false), 0.0)
    @test isapprox(distance(c, box, 2, 1, false), distance(c, box, 1, 2, false))
    @test isapprox(distance(c, box, 1, 2, true),  norm(c.x[:, 1] - [0.4, -0.2, 0.6]))
    box = Box(10.0, 1.0, 100.0)
    @test isapprox(distance(c, box, 1, 2, false), norm(c.x[:, 1] - c.x[:, 2]))
    @test isapprox(distance(c, box, 2, 1, true),  norm([0.2, 0.1, 0.8] - [0.4, -0.2, 0.6]))

    # distance (Tests from Avogadro measurement tool)
    crystal = Crystal("distance_test.cif")
    @test isapprox(distance(crystal.atoms, crystal.box, 1, 3, false), 12.334, atol=0.001) # C- Ca
    @test isapprox(distance(crystal.atoms, crystal.box, 1, 2, false), 14.355, atol=0.001) # C-S
    @test isapprox(distance(crystal.atoms, crystal.box, 1, 2, true), 8.841, atol=0.001) # C-S
    @test isapprox(distance(crystal.atoms, crystal.box, 2, 3, false), 6.292, atol=0.001) # S-Ca

    # overlap
    box = unit_cube()
    f = Frac([0.2 0.4 0.6 0.401;
              0.1 0.8 0.7 0.799;
              0.8 0.6 0.5 0.602]
              )
    o_flag, o_ids = overlap(f, box, true, tol=0.01)
    @test o_flag
    @test o_ids == [(2, 4)]

    f = Frac([0.2 0.4 0.6 0.2;
              0.1 0.8 0.7 0.1;
              0.99 0.6 0.5 0.01]
              )
    o_flag, o_ids = overlap(f, box, true, tol=0.03)
    @test o_flag
    @test o_ids == [(1, 4)]
    o_flag, o_ids = overlap(f, box, false, tol=0.03)
    @test !o_flag
    @test o_ids == []

    xtal = Crystal("IRMOF-1.cif")
    @test !overlap(xtal, true)[1]
    xtal = Crystal("IRMOF-1_overlap.cif", check_overlap=false)
    @test overlap(xtal, true)[1]

    # test distance function (via Avogadro)
    crystal = Crystal("simple_test.cif", check_overlap=false)
    @test distance(crystal.atoms, crystal.box, 1, 1, true) == 0.0
    @test isapprox(distance(crystal.atoms, crystal.box, 2, 5, true), 4.059, atol=0.001)
    @test isapprox(distance(crystal.atoms, crystal.box, 2, 5, false), 4.059, atol=0.001)
    @test isapprox(distance(crystal.atoms, crystal.box, 1, 5, false), 17.279, atol=0.001)
    @test isapprox(distance(crystal.atoms, crystal.box, 1, 5, true), 1.531, atol=0.001)
    @test isapprox(distance(Cart(crystal.atoms, crystal.box), 1, 5), 17.279, atol=0.001)

    ###
    #   remove duplicates
    ###
    atoms = Crystal("SBMOF-1.cif").atoms
    box = Crystal("SBMOF-1.cif").box
    # no duplicates in SBMOF-1
    atoms_dm = remove_duplicates(atoms, box, true)
    @test isapprox(atoms, atoms_dm)
    # if atoms overlap but not same species, not duplicate
    atoms.coords.xf[:, 5] = atoms.coords.xf[:, end] # atoms 5 and end now overlap, but 5 is C and end is Ca
    atoms_dm = remove_duplicates(atoms, box, true)
    @test isapprox(atoms, atoms_dm)
    # finally introduce overlap between atom 5, 6, 7, all C
    atoms.coords.xf[:, 6] = atoms.coords.xf[:, 5] # atoms 5 and 7 now overlap
    atoms.coords.xf[:, 7] = atoms.coords.xf[:, 5] # atoms 5 and 7 now overlap
    atoms_dm = remove_duplicates(atoms, box, true)
    @test atoms_dm.n == atoms.n - 2
    @test isapprox(atoms[1:5], atoms_dm[1:5])
    @test isapprox(atoms[8:end], atoms_dm[6:end])

    ###
    # pairwise distances
    ###
    coords = Crystal("distance_tester.cif").atoms.coords
    box = Crystal("distance_tester.cif").box
    pd = Xtals.pairwise_distances(coords, box, true)
    @test isapprox(pd[2, 2], 0.0) # zero on diag
    @test isapprox(pd[1, 2], pd[2, 1]) # symmetry
    @test isapprox(pd[1, 2], 2.835, atol=0.01) # calculated in avogadro
    @test isapprox(pd[3, 2], 6.031, atol=0.01) # calculated in avogadro
    pd = Xtals.pairwise_distances(coords, box, false)
    @test isapprox(pd[3, 2], 17.31, atol=0.01) # calculated in avogadro

    ###
    # vector-column distances
    ###
    coords = Crystal("distance_tester.cif").atoms.coords
    box = Crystal("distance_tester.cif").box

    function check_vector_indices(coords, box, Is, Js, apply_pbc = true)
      d = distance(coords, box, Is, Js, apply_pbc)

      # force using distance(::Coords, ::Box, ::Integer, ::Integer)
      d_elementwise = distance.(Ref(coords), Ref(box), Is, Js, apply_pbc)

      # CartesianIndex is implicity a 1-vector
      if Is isa CartesianIndices
          d_elementwise = first.(d_elementwise)
      end

      @test d ≈ d_elementwise
    end

    # different types of indices
    Is = (1:5, rand(1:5, 5), CartesianIndices((1:5))) 
    Js = (1:5, rand(1:5, 5), CartesianIndices((1:5)))

    for (I, J) in zip(Is, Js), pbc in (true, false)
        check_vector_indices(coords, box, I, J, pbc)
    end
end
end
