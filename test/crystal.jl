module Crystal_Test

using Xtals
using LinearAlgebra
using Test
using MetaGraphs, Graphs

# for test only
# if the multi sets are equal, then when you remove duplicates,
#  you will be left with ac1.
function equal_multisets(ac1::Union{Atoms{Frac}, Charges{Frac}},
                         ac2::Union{Atoms{Frac}, Charges{Frac}},
                         box::Box)
    ac = ac1 + ac2
    ac_dm = remove_duplicates(ac, box, true)
    return isapprox(ac_dm, ac1)
end

@testset "Crystal Tests" begin
    xtal = Crystal("SBMOF-1.cif")
    @test Xtals.vtk_filename(xtal) == "SBMOF-1.vtk"
    xtal = Crystal("ATIBOU01_clean.cssr")
    @test Xtals.vtk_filename(xtal) == "ATIBOU01_clean.vtk"

    # cif reader
    xtal = Crystal("test_structure2.cif")
    strip_numbers_from_atom_labels!(xtal)
    @test xtal.name == "test_structure2.cif"
    @test isapprox(xtal.box, Box(10.0, 20.0, 30.0, 90*π/180, 45*π/180, 120*π/180))
    @test xtal.atoms.n == 2
    @test isapprox(xtal.atoms, Atoms([:Ca, :O], Frac([0.2 0.6; 0.5 0.3; 0.7 0.1])))
    @test isapprox(xtal.charges, Charges([1.0, -1.0], Frac([0.2 0.6; 0.5 0.3; 0.7 0.1])))
    @test xtal.symmetry.is_p1
    @test Xtals.strip_number_from_label(:C) == :C
    @test Xtals.strip_number_from_label(:C232) == :C
    @test Xtals.strip_number_from_label(:Ca232) == :Ca
    @test Xtals.strip_number_from_label(:Cad) == :Cad

    # assign charges function
    xtal = Crystal("test_structure3.cif", include_zero_charges=false)
    @test xtal.charges.n == 0
    strip_numbers_from_atom_labels!(xtal)
    xtal2 = assign_charges(xtal, Dict(:Ca => -2.0, :O => 2.0))
    @test isapprox(xtal2.charges, Charges([-2.0, 2.0], Frac([0.2 0.6; 0.5 0.3; 0.7 0.1])))
    @test ! neutral(assign_charges(xtal, Dict(:Ca => 2.0, :O => 2.0), 100.0)) # not charge neutral
    @test_throws ErrorException assign_charges(xtal, Dict(:Ca => 2.0, :O => 2.0)) # not charge neutral
    @test chemical_formula(xtal) == Dict(:Ca => 1, :O => 1)
    @test molecular_weight(xtal) ≈ 15.9994 + 40.078
    xtal3 = assign_charges(xtal2, Dict(:Ca => -2.0, :O => 2.0))
    @test isapprox(xtal2.charges, xtal3.charges)

    # overlap checker, charge neutrality checker, wrap coords checker
    @test_throws ErrorException Crystal("test_structure2B.cif", check_overlap=true, check_neutrality=false)
    @test_throws ErrorException Crystal("test_structure2B.cif", check_overlap=false, check_neutrality=true)
    xtal = Crystal("test_structure2B.cif", check_overlap=false, check_neutrality=false, wrap_coords=true)
    f = Frac([0.2 0.5 0.7;
              0.2 0.5 0.7;
              0.6 0.3 0.1;
              0.9 0.24 0.15]')

    @test isapprox(xtal.atoms, Atoms([:Ca, :Ca, :O, :C], f))
    @test isapprox(net_charge(xtal), 2.0)
    @test chemical_formula(xtal) == Dict(:Ca => 2, :O => 1, :C => 1)
    infer_bonds!(xtal, true)
    @test_throws ErrorException Xtals.remove_duplicate_atoms_and_charges(xtal)

    # xyz writer
    xtal = Crystal("SBMOF-1.cif")
    xtal_xyz_filename = replace(replace(xtal.name, ".cif" => ""), ".cssr" => "") * ".xyz"
    write_xyz(xtal)
    atoms_read = read_xyz(xtal_xyz_filename) # Atoms{Cart}
    atoms_read_f = Frac(atoms_read, xtal.box) # Atoms{Frac}
    @test isapprox(atoms_read_f, xtal.atoms, atol=0.001)
    write_xyz(xtal, center_at_origin=true, comment="blah") #center coords
    atoms_read = read_xyz(xtal_xyz_filename) # Atoms{Cart}
    atoms_read_f = Frac(atoms_read, xtal.box) # Atoms{Frac}
    @test isapprox(atoms_read_f.coords.xf, xtal.atoms.coords.xf .- [0.5, 0.5, 0.5], atol=0.001)
    rm(xtal_xyz_filename) # clean up

    # test .cif writer; write, read in, assert equal
    crystal = Crystal("SBMOF-1.cif")
    rewrite_filename = "rewritten.cif"
    write_cif(crystal, joinpath(rc[:paths][:crystals], rewrite_filename))
    crystal_reloaded = Crystal(rewrite_filename)
    strip_numbers_from_atom_labels!(crystal_reloaded) # TODO Arthur remove this necessity from write_cif
    @test isapprox(crystal, crystal_reloaded, atol=0.0001)
    write_cif(crystal, joinpath(rc[:paths][:crystals], rewrite_filename), fractional_coords=false) # cartesian
    crystal_reloaded = Crystal(rewrite_filename)
    strip_numbers_from_atom_labels!(crystal_reloaded) # TODO Arthur remove this necessity from write_cif
    @test isapprox(crystal, crystal_reloaded, atol=0.0001)
    rewrite_filename = "rewritten.cif"
    write_cif(crystal, joinpath(rc[:paths][:crystals], rewrite_filename), number_atoms=false)
    crystal_reloaded = Crystal(rewrite_filename)
    @test isapprox(crystal, crystal_reloaded, atol=0.0001)
    crystal = Crystal("ATIBOU01_clean.cssr", include_zero_charges=false)
    @test_throws ErrorException write_cif(crystal)
    crystal = assign_charges(crystal, Dict(:Mn => 2.0, :O => -2.0, :H => 0.0, :C => 0.0), Inf)
    write_cif(crystal)
    @test isfile("ATIBOU01_clean.cif")

    ### apply_symmetry_operations
    # test .cif reader for non-P1 symmetry
    #   no atoms should overlap
    #   should place atoms in the same positions as the P1 conversion using
    #       openBabel
    #  test wraps coords to [0, 1] for symmetry ops
    xtal = Crystal("symmetry_test_structure.cif", wrap_coords=false)
    @test any(xtal.atoms.coords.xf .> 1.0)
    xtal = Crystal("symmetry_test_structure.cif", wrap_coords=true) # default
    @test all(xtal.atoms.coords.xf .< 1.0) && all(xtal.atoms.coords.xf .> 0.0)
    xtal = Crystal("symmetry_test_structure_charges.cif")
    @test xtal.charges.n == xtal.atoms.n
    @test !any(isnan.(xtal.charges.q))

    non_P1_crystal = Crystal("symmetry_test_structure.cif") # not in P1 original
    strip_numbers_from_atom_labels!(non_P1_crystal)

    P1_crystal = Crystal("symmetry_test_structure_P1.cif") # in P1 originally
    strip_numbers_from_atom_labels!(P1_crystal)

    @test isapprox(non_P1_crystal.box, P1_crystal.box)
    @test equal_multisets(non_P1_crystal.atoms, P1_crystal.atoms, P1_crystal.box)
    @test equal_multisets(non_P1_crystal.charges, P1_crystal.charges, P1_crystal.box)

    non_P1_cartesian = Crystal("symmetry_test_structure_cartn.cif") # not in P1 originally
    strip_numbers_from_atom_labels!(non_P1_cartesian)

    @test isapprox(non_P1_crystal.box, non_P1_cartesian.box)
    @test equal_multisets(non_P1_crystal.atoms, non_P1_cartesian.atoms, P1_crystal.box)
    @test equal_multisets(non_P1_crystal.charges, non_P1_cartesian.charges, non_P1_cartesian.box)

    # test that incorrect file formats throw proper errors
    @test_throws ErrorException Crystal("non_P1_no_symmetry.cif")
    # test that a file with no atoms throws error
    @test_throws ErrorException Crystal("no_atoms.cif")
    # should all be in P1 now.
    @test non_P1_crystal.symmetry.is_p1
    @test non_P1_cartesian.symmetry.is_p1
    @test P1_crystal.symmetry.is_p1

    # test reading in non-P1 then applying symmetry later
    # read in the same files as above, then convert to P1, then compare
    non_P1_xtal = Crystal("symmetry_test_structure.cif", convert_to_p1=false)
    strip_numbers_from_atom_labels!(non_P1_xtal)
    non_P1_xtal_cartesian = Crystal("symmetry_test_structure_cartn.cif", convert_to_p1=false)
    strip_numbers_from_atom_labels!(non_P1_xtal_cartesian)

    # make sure these crystals are not in P1 symmetry when convert_to_p1 is
    #   set to false
    @test ! non_P1_xtal.symmetry.is_p1
    @test ! non_P1_xtal_cartesian.symmetry.is_p1

    hk = Crystal("HKUST-1_low_symm.cif", remove_duplicates=true)
    strip_numbers_from_atom_labels!(hk)
    hk_p1 = Crystal("HKUST-1_P1.cif") # from avogadro
    strip_numbers_from_atom_labels!(hk_p1)
    @test equal_multisets(hk.atoms, hk_p1.atoms, hk.box)

    # test write_cif in non_p1 symmetry
    write_cif(non_P1_xtal, joinpath("data", "crystals", "rewritten_symmetry_test_structure.cif"))
    # keep this in cartesian to test both
    write_cif(non_P1_xtal_cartesian, joinpath("data", "crystals", "rewritten_symmetry_test_structure_cartn.cif"), fractional_coords=false)
    rewritten_non_p1_fractional = Crystal("rewritten_symmetry_test_structure.cif"; convert_to_p1=false)
    strip_numbers_from_atom_labels!(rewritten_non_p1_fractional) # TODO remove
    rewritten_non_p1_cartesian = Crystal("rewritten_symmetry_test_structure_cartn.cif"; convert_to_p1=false)
    strip_numbers_from_atom_labels!(rewritten_non_p1_cartesian)

    @test isapprox(rewritten_non_p1_fractional, non_P1_xtal, atol=0.0001)
    @test isapprox(rewritten_non_p1_cartesian, non_P1_xtal_cartesian, atol=0.0001)

    non_P1_xtal = Crystal("symmetry_test_structure.cif", convert_to_p1=true)
    strip_numbers_from_atom_labels!(non_P1_xtal)
    non_P1_xtal_cartesian = Crystal("symmetry_test_structure_cartn.cif", convert_to_p1=true)
    strip_numbers_from_atom_labels!(non_P1_xtal_cartesian)
    @test non_P1_xtal.symmetry.is_p1
    @test non_P1_xtal_cartesian.symmetry.is_p1

    # test that same structure is created when reading and converting to P1 and
    #   when reading then converting to P1
    @test isapprox(non_P1_crystal, non_P1_xtal)
    @test isapprox(non_P1_cartesian, non_P1_xtal_cartesian)

    # test .cssr reader too; test_structure2.{cif,cssr} designed to be the same.
    xtal_cssr = Crystal("test_structure2.cssr")
    strip_numbers_from_atom_labels!(xtal_cssr)
    xtal_cif = Crystal("test_structure2.cif")
    strip_numbers_from_atom_labels!(xtal_cif)
    @test isapprox(xtal_cif, xtal_cssr)

    da_xtalname = "ATIBOU01_clean"
    xtal_cif = Crystal(da_xtalname * ".cif", include_zero_charges=true)
    write_cssr(xtal_cif)
    write_cssr(xtal_cif, joinpath(rc[:paths][:crystals], da_xtalname * ".cssr"))
    xtal_cssr = Crystal(da_xtalname * ".cssr", include_zero_charges=true)
    @test isapprox(xtal_cssr, xtal_cif, atol=0.0001)

    # sanity checks on replicate crystal
    sbmof = Crystal("SBMOF-1.cif")
    strip_numbers_from_atom_labels!(sbmof)
    replicated_sbmof = replicate(sbmof, (1, 1, 1))
    @test isapprox(sbmof, replicated_sbmof)
    @test isapprox(2 * 2 * molecular_weight(sbmof), molecular_weight(replicate(sbmof, (2, 2, 1))))
    @test isapprox(2 * sbmof.box.a, replicate(sbmof, (2, 3, 4)).box.a)

    repfactors = Xtals.replication_factors(sbmof.box, 14.0)
    replicated_sbmof = replicate(sbmof, repfactors)
    @test Xtals.replication_factors(replicated_sbmof.box, 14.0) == (1, 1, 1)
    @test isapprox(sbmof.atoms.coords.xf[:, 1] ./ repfactors, replicated_sbmof.atoms.coords.xf[:, 1])
    @test isapprox(replicated_sbmof.box.reciprocal_lattice, 2 * π * inv(replicated_sbmof.box.f_to_c))
    @test chemical_formula(sbmof) == chemical_formula(replicated_sbmof)
    @test isapprox(crystal_density(sbmof), crystal_density(replicated_sbmof), atol=1e-7)

    sbmof1 = Crystal("SBMOF-1.cif")
    rbox = replicate(sbmof1.box, (2, 3, 4))
    @test rbox.Ω ≈ sbmof1.box.Ω * 2 * 3 * 4
    @test all(rbox.c_to_f * sbmof1.box.f_to_c * [1.0, 1.0, 1.0] .≈ [1/2, 1/3, 1/4])


    # test crystal addition
    c1 = Crystal("crystal 1", unit_cube(), Atoms([:a, :b],
                                                 Frac([1.0 4.0;
                                                       2.0 5.0;
                                                       3.0 6.0]
                                                     )
                                                ),
                                            Charges([0.1, 0.2],
                                                    Frac([1.0 4.0;
                                                          2.0 5.0;
                                                          3.0 6.0]
                                                        )
                                                   )
                )
    c2 = Crystal("crystal 2", unit_cube(), Atoms([:c, :d],
                                                 Frac([7.0 10.0;
                                                       8.0 11.0;
                                                       9.0 12.0]
                                                     ),
                                                ),
                                           Charges([0.3, 0.4],
                                                   Frac([7.0 10.0;
                                                        8.0 11.0;
                                                        9.0 12.0]
                                                       )
                                                  )
                )
    c = c1 + c2
    @test_throws AssertionError c1 + sbmof # only allow crystals with same box
    @test isapprox(c1.box, c.box)
    @test isapprox(c2.box, c.box)
    @test isapprox(c1.atoms + c2.atoms, c.atoms)
    @test isapprox(c1.charges + c2.charges, c.charges)
    @test isapprox(c[1:2], c1) # indexing test
    @test isapprox(c[3:4], c2) # indexing test

    # test overlap crystal addition
    c_overlap = +(c1, c2, c; check_overlap=false)
    @test isapprox(c_overlap.box, c.box)
    @test isapprox(c_overlap.atoms, c1.atoms + c2.atoms + c.atoms)
    @test isapprox(c_overlap.charges, c1.charges + c2.charges + c.charges)
    @test_throws AssertionError +(c1, c2, c) # by default, do not let crystal additions result in overlap

    # bond addition
    xtal = Crystal("SBMOF-1.cif")
    xtal2 = deepcopy(xtal)
    infer_bonds!(xtal, true)
    infer_bonds!(xtal2, true)
    xtal3 = +(xtal, xtal2; check_overlap=false)
    @test ne(xtal3.bonds) == ne(xtal.bonds) + ne(xtal2.bonds)

    # more xtal tests
    sbmof1 = Crystal("SBMOF-1.cif", include_zero_charges=false)
    @test ! has_charges(sbmof1)
    @test isapprox(sbmof1.box.reciprocal_lattice, 2 * π * inv(sbmof1.box.f_to_c))
    @test sbmof1.box.Ω ≈ det(sbmof1.box.f_to_c) # sneak in crystal test
    @test isapprox(crystal_density(sbmof1), 1570.4, atol=0.5) # kg/m3

    # indexing
    sbmof1_sub = sbmof1[10:15]
    @test sbmof1_sub.atoms.n == 6
    @test sbmof1_sub.charges.n == 0
    @test sbmof1_sub.atoms.species == sbmof1.atoms.species[10:15]
    @test sbmof1_sub.atoms.coords.xf == sbmof1.atoms.coords.xf[:, 10:15]
    unequal_n_q = Crystal("symmetry_test_structure_charges.cif", include_zero_charges=false)
    @test_throws ErrorException lastindex(unequal_n_q)
    @test_throws ErrorException unequal_n_q[[1]]
    
    @test !isapprox(unequal_n_q, Crystal("symmetry_test_structure.cif"))

    # including zero charges or not, when reading in a .cif `include_zero_charges` flag to Crystal constructor
    frame1 = Crystal("ATIBOU01_clean.cif", include_zero_charges=false) # has four zero charges in it
    @test ! any(frame1.charges.q .== 0.0)
    @test frame1.charges.n == frame1.atoms.n - 4 # 4 charges are zero
    frame2 = Crystal("ATIBOU01_clean.cif")
    @test frame2.charges.n == frame2.atoms.n
    @test isapprox(frame2.charges.coords, frame2.atoms.coords)

    crystal = replicate(Crystal("CAXVII_clean.cif"), (2, 2, 2))
    @test isapprox(sum(crystal.charges.q), 0.0, atol=0.001)

    # high-precision charges in write_cif
    crystal = Crystal("ADARAA_clean.cif")
    @test all(crystal.charges.q .!= 0.0) # has charges...
    @test neutral(crystal, Xtals.NET_CHARGE_TOL) # is neutral...
    write_cif(crystal, joinpath(rc[:paths][:crystals], "high_precision_charges_test.cif")) # should write charges with more decimals
    crystal_reloaded = Crystal("high_precision_charges_test.cif")
    @test isapprox(crystal.charges.q, crystal_reloaded.charges.q, atol=1e-8) # would not hv this precision if didn't write high-precision charges for this one.
    crystal_not_neutral = crystal.charges.q .= round.(crystal.charges.q, digits=6) # this is what charges would be if stored 6 decimals in .cif and threw away the rest
    write_cif(crystal, joinpath(rc[:paths][:crystals], "high_precision_charges_test_not_neutral.cif"))
    @test ! neutral(Crystal("high_precision_charges_test_not_neutral.cif", check_neutrality=false), Xtals.NET_CHARGE_TOL) # not gonna be neutral
    @test_throws ErrorException Crystal("high_precision_charges_test_not_neutral.cif") # should throw error b/c not charge neutral
    # tests for species_from_col:
      # 1.  Make sure a .cif loads a Crystal with bad labels as default;
      #     fixed labels with species_column="_atom_site_type_symbol".
      # 2.  Make sure a .cif w/ good labels loads to an identical Crystal with
      #     and without species_column="_atom_site_type_symbol".
      # 3.  Make sure a bogus species_column throws an exception.
    xtal = Crystal("SBMOF-1_bad_labels.cif", species_col=["_atom_site_label"])
    @test xtal.atoms.species[1] == :C1A

    xtal = Crystal("SBMOF-1_bad_labels.cif", species_col=["_atom_site_type_symbol"])
    @test xtal.atoms.species[1] == :C

    xtal1 = Crystal("SBMOF-1.cif")
    xtal2 = Crystal("SBMOF-1.cif")
    @test xtal1.atoms.species == xtal2.atoms.species

    @test_throws KeyError Crystal("SBMOF-1.cif", species_col=["bogus_column"])

    # overlap tests
    @test_throws ErrorException Crystal("SBMOF-1_overlap.cif")
    xtal1 = Crystal("SBMOF-1_overlap.cif", remove_duplicates=true)
    @test isapprox(xtal1, Crystal("SBMOF-1.cif"))
    @test_throws ErrorException Crystal("SBMOF-1_overlap_diff_atom.cif", remove_duplicates=true) # duplicate but diff atom, so not repairable

    @test_throws ErrorException Crystal("example.mol")
    @test_throws ErrorException Crystal("SBMOF-1.cif", infer_bonds=true)
    infer_bonds!(xtal1, true)
    @test_throws ErrorException replicate(xtal1, (1,1,1))

    # test verbose printing in chemical_formula
    Xtals.chemical_formula(xtal1, verbose=true)
    @test true

    @test xtal1 == apply_symmetry_operations(xtal1)

    println(xtal1)
    @test true
    
    # slicing
    xtal = Crystal("SBMOF-1.cif")
    infer_bonds!(xtal, false)
    set_prop!(xtal.bonds, 1, 5, :bogus, "hi")
    ids = [1, 2, 5]
    xtal_sliced = xtal[ids]
    @test xtal_sliced.atoms.species == xtal.atoms.species[ids]
    @test isapprox(xtal_sliced.atoms.coords, xtal.atoms.coords[ids])
    @test has_edge(xtal_sliced.bonds, 1, 3)
    @test nv(xtal_sliced.bonds) == 3
    ids = falses(xtal.atoms.n)
    ids[1] = ids[2] = ids[5] = true
    @test isapprox(xtal_sliced, xtal[ids])
    xtal = Crystal("IRMOF-1.cif")
    @test lastindex(xtal) == xtal.atoms.n == 424

    # charge/atom count mismatch tests for isapprox
    xtal = Crystal("SBMOF-1.cif")
    xtal2 = Crystal("IRMOF-1.cif")
    @test !isapprox(xtal, xtal2) # different atoms.n
    xtal2 = assign_charges(xtal, Dict(:Ca => -2.0, :O => 2.0, :S => 2.0, :C => 0.0, :H => 0.0), Inf)
    @test !isapprox(xtal, xtal2) # different charges.n

    # make sure that CIF files with tabs in the _symmetry_equiv_pos_as_xyz blocks load w/o error
    xtal = Crystal("xtal_w_tabs.cif", check_overlap=false)
    @test true
end
end
