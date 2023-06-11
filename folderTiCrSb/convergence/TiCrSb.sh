#!/bin/sh
module purge
module add impi sci/dft sci/qe_7.2
export MKL_NUM_THREADS=1
export ASE_ESPRESSO_COMMAND="mpirun /home/sci/opt/qe-7.2_impi/bin/pw.x -np 4 < PREFIX.pwi > PREFIX.pwo"
NAME="ecut"
declare -A energy_dict  # Declare an associative array for storing energies
declare -A cpu_dict  # Declare an associative array for storing CPU time
for CUTOFF in  60 65 70 75
do
cat > ${NAME}_${CUTOFF}.in << EOF
&CONTROL
  calculation = 'relax'
  etot_conv_thr =   4.0000000000d-05
  forc_conv_thr =   1.0000000000d-04
  outdir = './out/'
  prefix = 'aiida'
  pseudo_dir = './pseudos/'
  tprnfor = .true.
  tstress = .true.
/
&SYSTEM
  degauss =   1.4699723600d-02
  ecutrho =   3.2000000000d+02
  ecutwfc =   4.0000000000d+01
  ibrav = 0
  nat = 4
  nosym = .false.
  nspin = 2
  ntyp = 2
  occupations = 'smearing'
  smearing = 'cold'
  starting_magnetization(1) =   1.0000000000d-01
  starting_magnetization(2) =   4.1666666667d-01
/
&ELECTRONS
  conv_thr =   8.0000000000d-10
  electron_maxstep = 100
  mixing_beta =   4.0000000000d-01
/
ATOMIC_SPECIES
Sb     121.76 sb_pbe_v1.4.uspp.F.UPF
Ti     47.867 ti_pbe_v1.4.uspp.F.UPF
ATOMIC_POSITIONS crystal
Ti           0.0000000000       0.0000000000       0.0000000000 
Ti           0.0000000000       0.0000000000       0.5000000000 
Sb           0.3333300000       0.6666700000       0.2500000000 
Sb           0.6666700000       0.3333300000       0.7500000000 
K_POINTS automatic
3 3 3 0 0 0
CELL_PARAMETERS angstrom
      3.6458000000       0.0000000000       0.0000000000
     -1.8229000000       3.1573554171       0.0000000000
      0.0000000000       0.0000000000       5.0450700000
EOF

pw.x < ${NAME}_${CUTOFF}.in > ${NAME}_${CUTOFF}.out
echo ${NAME}_${CUTOFF}
grep ! ${NAME}_${CUTOFF}.out
energy=$(grep "!" "${NAME}_${CUTOFF}.out" | awk '{print $5}')  # Extract the energy value using awk
energy_dict["${CUTOFF}"]=$energy  # Store energy in the dictionary with cutoff value as key
cpu_dict["${CUTOFF}"]=$cpu_time  # Store cpu time in the dictionary with cutoff value as key
done
# Print the dictionary
for key in "${!energy_dict[@]}"; do
    echo "CUTOFF: $key, Energy: ${energy_dict[$key]}"
    echo "CUTOFF: $key, CPU TIME: ${cpu_dict[$key]}"
    # Save energies in text file with corresponding cutoff
    echo "$key ${energy_dict[$key]}" >> "energies.txt"
    echo "$key ${cpu_dict[$key]}" >> "energies.txt"
done
