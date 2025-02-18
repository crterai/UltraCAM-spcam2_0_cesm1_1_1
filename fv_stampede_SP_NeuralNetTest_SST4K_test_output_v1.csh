#!/bin/csh

# This is the most general form of the build/submit script for SP/UP model.
# HP has also made other versions of this script for simpler model configurations.
# Questions? Please contact h.parish@uci.edu at UC Irvine ESS.

set run_time       = 02:00:00
set queue          = skx-normal
set account        = TG-ATM190002
set priority       = normal 
set run_start_date = "2008-10-10"
set start_tod      = "00000"
#set start_tod      = "43200"
set Np             = 216
set Np_else        = 54 

## ====================================================================
#   define case
## ====================================================================

setenv CCSMTAG     UltraCAM-spcam2_0_cesm1_1_1
setenv CASE        TimestepOutput_SST_4Kp_Neuralnet_SPCAM_test_output_v5_$Np
#setenv CASE        AeroPD_nudgEns31_4x5_m2005_32x1CRM4000m_L30_MultiBase_0Z_$Np
setenv CASESET     F_2000_SPCAM_sam1mom_SP
#setenv CASESET     F_AMIP_SPCAM_sam1mom_shortcrm 
#setenv CASESET     F_2000_SPCAM_m2005_ECPP
#setenv CASESET     F_2000_SPCAM_sam1mom
#setenv CASERES     f09_g16
setenv CASERES     f19_g16
#setenv CASERES     f45_f45
setenv PROJECT     TG-ATM190002

## ====================================================================
#   define directories
## ====================================================================

setenv MACH      stampede2-skx
setenv CCSMROOT  $HOME/repositories/$CCSMTAG
setenv CASEROOT  /scratch/07088/tg863871/SPCAM_case/$CASE
setenv PTMP      $SCRATCH/
setenv RUNDIR    $PTMP/$CASE/run
setenv ARCHDIR   $PTMP/archive/$CASE
#setenv DATADIR   /scratch/projects/xsede/CESM/inputdata
#setenv DIN_LOC_ROOT_CSMDATA $DATADIR
setenv DATADIR   /scratch/07088/tg863871/SPCAM_input
setenv DIN_LOC_ROOT_CSMDATA /scratch/07088/tg863871/SPCAM_input
setenv DIN_LOC_ROOT_CLMFORC /scratch/07088/tg863871/SPCAM_input

#setenv mymodscam $HOME/mymods/$CCSMTAG/CAM
#mkdir -p $mymodscam

## ====================================================================
#   create new case, configure, compile and run
## ====================================================================

rm -rf $CASEROOT
rm -rf $PTMP/$CASE
#rm -rf $PTMP/$CASE

#------------------
## create new case
#------------------

cd  $CCSMROOT/scripts

./create_newcase -case $CASEROOT -mach $MACH -res $CASERES -compset $CASESET -compiler intel -v

#------------------
## set environment
#------------------

cd $CASEROOT

#set ntasks = $Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ATM  -val=$Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_LND  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ICE  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_OCN  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_CPL  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_GLC  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ROF  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  TOTALPES    -val=$Np

set-run-opts:
cd $CASEROOT

./xmlchange  -file env_run.xml -id  RESUBMIT      -val '19'
./xmlchange  -file env_run.xml -id  STOP_N        -val '40'
./xmlchange  -file env_run.xml -id  STOP_OPTION   -val 'ndays'
#./xmlchange  -file env_run.xml -id  REST_N        -val '6'
./xmlchange  -file env_run.xml -id  REST_OPTION   -val 'ndays'       # 'nhours' 'nmonths' 'nsteps' 'nyears' 
./xmlchange -file env_run.xml -id REST_N           -val '7'
./xmlchange  -file env_run.xml -id  RUN_STARTDATE -val $run_start_date
./xmlchange  -file env_run.xml -id  START_TOD     -val $start_tod
./xmlchange  -file env_run.xml -id  DIN_LOC_ROOT  -val $DATADIR
./xmlchange  -file env_run.xml -id  DOUT_S_ROOT   -val $ARCHDIR
./xmlchange  -file env_run.xml -id  RUNDIR        -val $RUNDIR
./xmlchange -file env_run.xml -id SSTICE_DATA_FILENAME           -val '/scratch/07088/tg863871/SPCAM_input/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029_v5.nc'
./xmlchange  -file env_run.xml -id  DOUT_S_SAVE_INT_REST_FILES     -val 'TRUE'
./xmlchange  -file env_run.xml -id  DOUT_L_MS                      -val 'FALSE'

./xmlchange  -file env_run.xml -id  ATM_NCPL              -val '96'    
#./xmlchange  -file env_run.xml -id  SSTICE_DATA_FILENAME  -val '$DATADIR/atm/cam/sst/sst_HadOIBl_bc_1x1_1850_2013_c140701.nc' 

cat <<EOF >! user_nl_cam


&camexp
npr_yz = 8,2,2,8
!npr_yz = 32,2,2,32
!prescribed_aero_model='bulk'
/


ch4vmr = 1760.0e-9
co2vmr = 367.0e-6
f11vmr = 653.45e-12
f12vmr = 535.0e-12
n2ovmr = 316.0e-9
/



&cam_inparm
phys_loadbalance = 2

ncdata = '/work/00993/tg802402/stampede2/UP_init_files/L30_f19_g16/1.9x2.5_L30_Sc1_20081010_YOTC.cam2.i.2008-10-10-00000.nc'

iradsw = 2 
iradlw = 2
!iradae = 4 

!empty_htapes = .true.
!fincl1 = 'cb_ozone_c', 'MSKtem', 'VTH2d', 'UV2d', 'UW2d', 'U2d', 'V2d', 'TH2d', 'W2d', 'UTGWORO'

!fincl1='cb_ozone_c'
fincl2 = 'T:I','Q:I','QAP:I','QBP:I','QBP:I','TBP:I','VAP:I','CRM_VTEND:I','PS:I','SHFLX:I','LHFLX:I','PTTEND:I','PTEQ:I','SOLIN:I','FSNT:I','FSNS:I','FLNT:I','FLNS:I','U10:I','FLDS:I','FSDS:I','PRECT:I'
fincl2 = 'NN2L_DSTDRY4:I','NN2L_DSTWET4:I','NN2L_DSTDRY3:I','NN2L_DSTWET3:I','NN2L_DSTDRY2:I','NN2L_DSTWET2:I','NN2L_DSTDRY1:I','NN2L_DSTWET1:I','NN2L_OCPHODRY:I','NN2L_OCPHIDRY:I','NN2L_OCPHIWET:I','NN2L_BCPHODRY:I','NN2L_BCPHIDRY:I','NN2L_BCPHIWET:I','NN2L_PSL:I','NN2L_CO2DIAG:I','NN2L_CO2PROG:I','NN2L_SRFRAD:I','NN2L_THBOT:I','NN2L_SOLSD:I','NN2L_SOLLD:I','NN2L_SOLS:I','NN2L_SOLL:I','NN2L_PRECL:I','NN2L_PRECC:I','NN2L_PRECSL:I','NN2L_PRECSC:I','NN2L_FLWDS:I','NN2L_NETSW:I','NN2L_TBOT:I','NN2L_ZBOT:I','NN2L_UBOT:I','NN2L_VBOT:I','NN2L_QBOT:I','NN2L_PBOT:I','NN2L_RHO:I'

nhtfrq = 0,1
mfilt  = 0,16

/
EOF

cat <<EOF >! user_nl_clm
&clmexp
!finidat = '/work/00993/tg802402/stampede2/UP_init_files/NOSP_4x5_CTRL_eds_r2_25y_512.clm2.r.2025-01-01-00000.nc'

hist_empty_htapes = .true.
hist_fincl1 = 'QSOIL:A', 'QVEGE:A', 'QVEGT:A', 'QIRRIG:A', 'FCEV:A', 'FCTR:A', 'FGEV:A', 'H2OCAN:A', 'H2OSOI:A', 'QDRIP:A', 'QINTR:A', 'QOVER:A', 
              'SOILICE:A', 'SOILLIQ:A', 'TSA:A', 'Q2M:A', 'RH2M:A' 
hist_nhtfrq = 96 
hist_mfilt  = 6 
/
EOF

cat <<EOF >! user_nl_cice
stream_fldfilename = '/scratch/07088/tg863871/SPCAM_input/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029_v5.nc'
EOF


cat <<EOF >! user_docn.streams.txt.prescribed
      <dataSource>
         GENERIC
      </dataSource>
      <domainInfo>
         <variableNames>
            time    time
            xc      lon
            yc      lat
            area    area
            mask    mask
         </variableNames>
         <filePath>
            /scratch/07088/tg863871/SPCAM_input/ocn/docn7
         </filePath>
         <fileNames>
            domain.ocn.1x1.111007.nc
         </fileNames>
      </domainInfo>
      <fieldInfo>
         <variableNames>
            SST_cpl    t
         </variableNames>
         <filePath>
            /scratch/07088/tg863871/SPCAM_input/atm/cam/sst
         </filePath>
         <fileNames>
            sst_HadOIBl_bc_1x1_clim_c101029_v5.nc
         </fileNames>
         <offset>
            0
         </offset>
      </fieldInfo>

EOF

#------------------
## configure
#------------------

config:
cd $CASEROOT
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT -val $PTMP/$CASE/bld

modify:
cd $CASEROOT
#if (-e $mymodscam) then
#    ln -s $mymodscam/* SourceMods/src.cam
#endif
#------------------
##  Interactively build the model
#------------------

build:
cd $CASEROOT
./$CASE.build

cd  $CASEROOT
sed -i 's/^#SBATCH --time=.*/#SBATCH --time='$run_time' /' $CASE.run
sed -i 's/^#SBATCH -p .*/#SBATCH -p '$queue' /' $CASE.run
sed -i 's/^#SBATCH --qos .*/#SBATCH --qos '$priority' /' $CASE.run
sed -i 's/^#SBATCH -A .*/#SBATCH -A '$account' /' $CASE.run

cd  $CASEROOT
set bld_cmp   = `grep BUILD_COMPLETE env_build.xml`
set split_str = `echo $bld_cmp | awk '{split($0,a,"="); print a[3]}'`
set t_or_f    = `echo $split_str | cut -c 2-5`

if ( $t_or_f == "TRUE" ) then
    #sbatch $CASE.run
    echo '-------------------------------------------------'
    #echo '----Build and compile is GOOD, job submitted!----'
    echo '----Build and compile is GOOD, job NOT submitted!----'
else
    set t_or_f = `echo $split_str | cut -c 2-6`
    echo 'Build not complete, BUILD_COMPLETE is:' $t_or_f
endif

# NOTE for documenting this case
cat <<EOF >> $CASEROOT/README.case

---------------------------------
USER NOTE (by hparish)
---------------------------------

--- Modifications:

EOF
