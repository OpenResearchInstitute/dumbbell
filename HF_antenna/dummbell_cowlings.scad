
//cowling brace piece for outdoor impelementations of the dummbell antenna
//by Abraxas3d 6 August 2023 for Open Research Institute
//CC by 4.0 
//https://creativecommons.org/licenses/by/4.0/

// A cynlinder, with rectangular gear teeth added at intervals appropriate 
// for winding the wires in the dumbbell-type shortened HF antenna.
// In that type of antenna, there is an inductive load section of the 
// half-wave dipole. Two of these disks will allow the inductive load to be
// formed around a cylindrical shape to make it easier to deploy outdoors. 

$fn = 100;
optimized_diameter = 82.2; //mm
outside_diameter = 107.6; //mm
disk_thickness = 20; //mm
integerNumHumps = 5;
subtended = 360/(2*integerNumHumps); //in degrees


union()
{
cylinder(h = disk_thickness, r1 = optimized_diameter/2, r2 = optimized_diameter/2);

for (i =[1:integerNumHumps])
{
rotate([0,0,(2*i-1)*subtended])
rotate_extrude(angle=subtended)
translate([optimized_diameter/2,0,0])
square([outside_diameter/10,disk_thickness]);
}

}