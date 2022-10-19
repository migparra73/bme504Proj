/* VIRTUAL_MUSCLE_SFUNCTION.C
 * Synopsis: Implements 3 different Virtual Muscle models based on recruitment
 *                  (1) Natural Discrete
 *                  (2) Natural Continuous
 *                  (3) Intramuscular FES   
 *
 * Comments: Please refer the user manual & paper (song et al) for 
 *          detailed explanation of the the algorithms
 *
 * Date: 01-08-08, Version: 1.0 (For Virtual Muscle 4.0)
 *
 *
 * Authors: Mehdi Khachani, Giby Raphael, Dan Song
 *
 * Known Issues: 
 */

// S_FUNCTION_NAME is the name of the S-function as it appears in the Simulink model
#define S_FUNCTION_NAME  Virtual_Muscle_SFunction
#define S_FUNCTION_LEVEL 2

// simstruc.h defines of the SimStruct and its associated macro definitions.
#include "simstruc.h"
#include "math.h"

//#define U(element) (*uPtrs[element])  /* Pointer to Input Port0 */

// parameters passed to the s-function

#define TOFMUSFIB_IDX 0 //Number of muscle fiber types
#define TOFMUSFIB_PARAM(S) ssGetSFcnParam(S,TOFMUSFIB_IDX)

//Generic parameters to all muscle fiber types
#define SARCLEN_IDX 1 //Optimal sarcomere length (um)
#define SARCLEN_PARAM(S) ssGetSFcnParam(S,SARCLEN_IDX)

#define SPTEN_IDX 2 //Specific Tension (N/cm2)
#define SPTEN_PARAM(S) ssGetSFcnParam(S,SPTEN_IDX)

#define VISC_IDX 3 //Viscosity (part of FPE1)
#define VISC_PARAM(S) ssGetSFcnParam(S,VISC_IDX)

#define C1_IDX 4 //FPE1 
#define C1_PARAM(S) ssGetSFcnParam(S,C1_IDX)

#define K1_IDX 5 //FPE1 
#define K1_PARAM(S) ssGetSFcnParam(S,K1_IDX)

#define LR1_IDX 6 //FPE1 
#define LR1_PARAM(S) ssGetSFcnParam(S,LR1_IDX)

#define C2_IDX 7 //FPE2 
#define C2_PARAM(S) ssGetSFcnParam(S,C2_IDX)

#define K2_IDX 8 //FPE2 
#define K2_PARAM(S) ssGetSFcnParam(S,K2_IDX)

#define LR2_IDX 9 //FPE2 
#define LR2_PARAM(S) ssGetSFcnParam(S,LR2_IDX)

#define CT_IDX 10 //FSE 
#define CT_PARAM(S) ssGetSFcnParam(S,CT_IDX)

#define KT_IDX 11 //FSE 
#define KT_PARAM(S) ssGetSFcnParam(S,KT_IDX)

#define LRT_IDX 12 //FSE 
#define LRT_PARAM(S) ssGetSFcnParam(S,LRT_IDX)


//Specific parameters to each muscle fiber type
#define RRANK_IDX 13 //Recruitment Rank
#define RRANK_PARAM(S) ssGetSFcnParam(S,RRANK_IDX)
 
#define V05_IDX 14 //V0.5(Lo/s)
#define V05_PARAM(S) ssGetSFcnParam(S,V05_IDX)

#define F05_IDX 15 //f0.5(pps)
#define F05_PARAM(S) ssGetSFcnParam(S,F05_IDX)

#define FMIN_IDX 16 //fmin(f0.5)
#define FMIN_PARAM(S) ssGetSFcnParam(S,FMIN_IDX)

#define FMAX_IDX 17 //fmax(f0.5)
#define FMAX_PARAM(S) ssGetSFcnParam(S,FMAX_IDX)

#define FLOMEGA_IDX 18 //  FL_omega
#define FLOMEGA_PARAM(S) ssGetSFcnParam(S,FLOMEGA_IDX)

#define FLBETA_IDX 19 //FL_beta
#define FLBETA_PARAM(S) ssGetSFcnParam(S,FLBETA_IDX)

#define FLRHO_IDX 20 //FL_rho
#define FLRHO_PARAM(S) ssGetSFcnParam(S,FLRHO_IDX)

#define VMAX_IDX 21 //Vmax
#define VMAX_PARAM(S) ssGetSFcnParam(S,VMAX_IDX)

#define CV0_IDX 22 //cV0
#define CV0_PARAM(S) ssGetSFcnParam(S,CV0_IDX)

#define CV1_IDX 23 //cV1
#define CV1_PARAM(S) ssGetSFcnParam(S,CV1_IDX)

#define AV0_IDX 24 //aV0
#define AV0_PARAM(S) ssGetSFcnParam(S,AV0_IDX)

#define AV1_IDX 25 //aV1
#define AV1_PARAM(S) ssGetSFcnParam(S,AV1_IDX)

#define AV2_IDX 26 //aV2
#define AV2_PARAM(S) ssGetSFcnParam(S,AV2_IDX)

#define BV_IDX 27 //bV
#define BV_PARAM(S) ssGetSFcnParam(S,BV_IDX)

#define AF_IDX 28 //aF
#define AF_PARAM(S) ssGetSFcnParam(S,AF_IDX)

#define NF0_IDX 29 //nf0
#define NF0_PARAM(S) ssGetSFcnParam(S,NF0_IDX)

#define NF1_IDX 30 //nf1
#define NF1_PARAM(S) ssGetSFcnParam(S,NF1_IDX)

#define TL_IDX 31 //TL
#define TL_PARAM(S) ssGetSFcnParam(S,TL_IDX)

#define TF1_IDX 32 //Tf1
#define TF1_PARAM(S) ssGetSFcnParam(S,TF1_IDX)

#define TF2_IDX 33 //Tf2
#define TF2_PARAM(S) ssGetSFcnParam(S,TF2_IDX)

#define TF3_IDX 34 //Tf3
#define TF3_PARAM(S) ssGetSFcnParam(S,TF3_IDX)

#define TF4_IDX 35 //Tf4
#define TF4_PARAM(S) ssGetSFcnParam(S,TF4_IDX)

#define AS1_IDX 36 //AS1
#define AS1_PARAM(S) ssGetSFcnParam(S,AS1_IDX)

#define AS2_IDX 37 //AS2
#define AS2_PARAM(S) ssGetSFcnParam(S,AS2_IDX)

#define TS_IDX 38 //TS
#define TS_PARAM(S) ssGetSFcnParam(S,TS_IDX)

#define CY_IDX 39 //cY
#define CY_PARAM(S) ssGetSFcnParam(S,CY_IDX)

#define VY_IDX 40 //VY
#define VY_PARAM(S) ssGetSFcnParam(S,VY_IDX)

#define TY_IDX 41 //TY
#define TY_PARAM(S) ssGetSFcnParam(S,TY_IDX)

#define CH0_IDX 42 //ch0
#define CH0_PARAM(S) ssGetSFcnParam(S,CH0_IDX)

#define CH1_IDX 43 //ch1
#define CH1_PARAM(S) ssGetSFcnParam(S,CH1_IDX)

#define CH2_IDX 44 //ch2
#define CH2_PARAM(S) ssGetSFcnParam(S,CH2_IDX)

#define CH3_IDX 45 //ch3
#define CH3_PARAM(S) ssGetSFcnParam(S,CH3_IDX)


/*Muscle parameters*/

// Muscle model parameters (generic to all muscles)
#define RTYPE_IDX 46 //Recruitment Type (2-Natural, 3-Natural continuous 4-Intramuscular FES)
#define RTYPE_PARAM(S) ssGetSFcnParam(S,RTYPE_IDX)
                                                                     //---------------------------| 
                                                                     // [1] - None                | 
#define ADDPORTS_IDX 47 //Additional ports besides Force(N)          // [2] - Activation          |
#define ADDPORTS_PARAM(S) ssGetSFcnParam(S,ADDPORTS_IDX)             // [3] - Force (F0)          |
                                                                     // [4] - Fascicle Length     |     
//Muscle morphometry values                                          // [5] - Fascicle Velocity   |
#define MMASS_IDX 48 //Muscle mass                                   //---------------------------|    
#define MMASS_PARAM(S) ssGetSFcnParam(S,MMASS_IDX)

#define FASCL0_IDX 49 //Fascicle length
#define FASCL0_PARAM(S) ssGetSFcnParam(S,FASCL0_IDX)

#define TENDL0T_IDX 50 //Tendon length
#define TENDL0T_PARAM(S) ssGetSFcnParam(S,TENDL0T_IDX)

#define LPATH_IDX 51 //Maximum path length
#define LPATH_PARAM(S) ssGetSFcnParam(S,LPATH_IDX)

#define UR_IDX 52 //Maximum recruitment activation
#define UR_PARAM(S) ssGetSFcnParam(S,UR_IDX)

#define NUMOFUNITS_IDX 53 //Number of motor units in each muscle fiber type
#define NUMOFUNITS_PARAM(S) ssGetSFcnParam(S,NUMOFUNITS_IDX)

#define FPCSA_IDX 54 //Fractional PCSA for each muscle fiber type
#define FPCSA_PARAM(S) ssGetSFcnParam(S,FPCSA_IDX)

#define UPCSA_IDX 55 //Unit PCSA for each motor unit (depends on apportion method)
#define UPCSA_PARAM(S) ssGetSFcnParam(S,UPCSA_IDX)
                                                                        //------------------------------|
#define APPORTMTD_IDX 56 //Apportion method for each muscle type        // [1] - Manual                 |
#define APPORTMTD_PARAM(S) ssGetSFcnParam(S,APPORTMTD_IDX)              // [2] - Default Algorithm      |
                                                                        // [3] - Equal sizes            |
#define GEOPCSA_IDX 57 //Fractional increase in geometric unit PCSA     // [4] - Geometric Algorithm    |
#define GEOPCSA_PARAM(S) ssGetSFcnParam(S,GEOPCSA_IDX)                  //------------------------------|

#define NPARAMS 58

#define max(a,b) a > b ? a : b
#define min(a,b) ((a) > (b) ? (a) : (b)

/*Work Vector variables
 [0]                                           - MUSCPCSA; //Muscle PCSA(cm^2)
 [1]                                           - MUSCF0; // Muscle Fo (N)
 [2]                                           - FASCLMAX; // Fascicle LMax (Lo)
 [3]                                           - MUSCDENSITY; //muscle density = 1.06
 [4]                                           - UnitPCSA_Offset; //# of MU in muscle
 [5]                                           - ...UnitPCSA values 
 [5+UnitPCSA_Offset]                           - Recruitment_Offset //# of MU in muscle
 [5+UnitPCSA_Offset+1]                         - ...Recruitment output values (fent) of each MU 
 [5+UnitPCSA_Offset+1+Recruitment_Offset]      - Activatoin_Offset//Af_op for each motor unit
 [5+UnitPCSA_Offset+1+Recruitment_Offset+1]    - ...Af_op for each MU
 [5+UnitPCSA_Offset+1+Recruitment_Offset+1+Activatoin_Offset]    - Fse (Series elastic element output)
 [5+UnitPCSA_Offset+1+Recruitment_Offset+1+Activatoin_Offset+1]    - ...dAf_op/dLce for each MU
 [5+UnitPCSA_Offset+1+Recruitment_Offset+1+Activatoin_Offset+1+dActivation_Offset]    - Kce <DSadd3>
 */

/* Function: mdlCheckParameters 
*  Description: Validates parameters: verifies if parameters are double and whether they include only one element
*/
#define MDL_CHECK_PARAMETERS
#if defined(MDL_CHECK_PARAMETERS) && defined(MATLAB_MEX_FILE)

static void mdlCheckParameters(SimStruct *S)
  {
      
      int_T            TypesOf_fibers           = (int_T) *mxGetPr(TOFMUSFIB_PARAM(S));
      real_T*           NumOf_MUnits            = mxGetPr(NUMOFUNITS_PARAM(S));
      int_T             i                       = 0;
      int_T             Total_MUnits            = 0;;
        
      /*Generic Parameters*/
      /* Check 0th parameter: TOFMUSFIB parameter - Types of Muscle fibers */
      {
          if (!mxIsDouble(TOFMUSFIB_PARAM(S)) ||
              mxGetNumberOfElements(TOFMUSFIB_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"TOFMUSFIB parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
 
      /* Check 1st parameter: SARCLEN parameter - Optimal Sacromere length */
      {
          if (!mxIsDouble(SARCLEN_PARAM(S)) ||
              mxGetNumberOfElements(SARCLEN_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"SARCLEN parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
 
      /* Check 2nd parameter: SPTEN parameter - Specific tension */
      {
          if (!mxIsDouble(SPTEN_PARAM(S)) ||
              mxGetNumberOfElements(SPTEN_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"SPTEN parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 3rd parameter: VISC parameter - Viscosity */
      {
          if (!mxIsDouble(VISC_PARAM(S)) ||
              mxGetNumberOfElements(VISC_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"VISC parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 4th parameter: C1 parameter - FPE1 */
      {
          if (!mxIsDouble(C1_PARAM(S)) ||
              mxGetNumberOfElements(C1_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"C1 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 5th parameter: K1 parameter - FPE1 */
      {
          if (!mxIsDouble(K1_PARAM(S)) ||
              mxGetNumberOfElements(K1_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"K1 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 6th parameter: LR1 parameter - FPE1 */
      {
          if (!mxIsDouble(LR1_PARAM(S)) ||
              mxGetNumberOfElements(LR1_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"LR1 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      
      /* Check 7th parameter: C2 parameter - FPE2 */
      {
          if (!mxIsDouble(C2_PARAM(S)) ||
              mxGetNumberOfElements(C2_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"C2 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 8th parameter: K2 parameter - FPE2 */
      {
          if (!mxIsDouble(K2_PARAM(S)) ||
              mxGetNumberOfElements(K2_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"K2 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 9th parameter: LR2 parameter - FPE2 */
      {
          if (!mxIsDouble(LR2_PARAM(S)) ||
              mxGetNumberOfElements(LR2_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"LR2 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      
      /* Check 10th parameter: CT parameter - FSE */
      {
          if (!mxIsDouble(CT_PARAM(S)) ||
              mxGetNumberOfElements(CT_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"CT parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 11th parameter: KT parameter - FSE */
      {
          if (!mxIsDouble(KT_PARAM(S)) ||
              mxGetNumberOfElements(KT_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"KT parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 12th parameter: LRT parameter - FSE */
      {
          if (!mxIsDouble(LRT_PARAM(S)) ||
              mxGetNumberOfElements(LRT_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"LRT parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      
      /*Specific parameter to each Muscle fiber*/
      /* Check 13th parameter: RRANK parameter - Recruitment rank */
      {
          if (!mxIsDouble(RRANK_PARAM(S)) ||
              mxGetNumberOfElements(RRANK_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in RRANK do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 14th parameter: V05 parameter - V0.5(Lo/s) */
      {
          if (!mxIsDouble(V05_PARAM(S)) ||
              mxGetNumberOfElements(V05_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in V05 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 15th parameter: F05 parameter - f0.5(pps) */
      {
          if (!mxIsDouble(F05_PARAM(S)) ||
              mxGetNumberOfElements(F05_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in F05 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 16th parameter: FMIN parameter - fmin(f0.5) */
      {
          if (!mxIsDouble(FMIN_PARAM(S)) ||
              mxGetNumberOfElements(FMIN_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in FMIN do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 17th parameter: FMAX parameter - fmax(f0.5) */
      {
          if (!mxIsDouble(FMAX_PARAM(S)) ||
              mxGetNumberOfElements(FMAX_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in FMAX do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 18th parameter: FLOMEGA parameter - FL_omega */
      {
          if (!mxIsDouble(FLOMEGA_PARAM(S)) ||
              mxGetNumberOfElements(FLOMEGA_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in FLOMEGA do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 19th parameter: FLBETA parameter - FL_beta */
      {
          if (!mxIsDouble(FLBETA_PARAM(S)) ||
              mxGetNumberOfElements(FLBETA_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in FLBETA do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 20th parameter: FLRHO parameter - FL_rho */
      {
          if (!mxIsDouble(FLRHO_PARAM(S)) ||
              mxGetNumberOfElements(FLRHO_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in FLRHO do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 21th parameter: VMAX parameter - Vmax */
      {
          if (!mxIsDouble(VMAX_PARAM(S)) ||
              mxGetNumberOfElements(VMAX_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in VMAX do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 22th parameter: CV0 parameter - cV0 */
      {
          if (!mxIsDouble(CV0_PARAM(S)) ||
              mxGetNumberOfElements(CV0_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CV0 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 23th parameter: CV1 parameter - cV1 */
      {
          if (!mxIsDouble(CV1_PARAM(S)) ||
              mxGetNumberOfElements(CV1_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CV1 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 24th parameter: AV0 parameter - aV0 */
      {
          if (!mxIsDouble(AV0_PARAM(S)) ||
              mxGetNumberOfElements(AV0_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in AV0 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 25th parameter: AV1 parameter - aV1 */
      {
          if (!mxIsDouble(AV1_PARAM(S)) ||
              mxGetNumberOfElements(AV1_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in AV1 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 26th parameter: AV2 parameter - aV2 */
      {
          if (!mxIsDouble(AV2_PARAM(S)) ||
              mxGetNumberOfElements(AV2_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in AV2 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 27th parameter: BV parameter - bV */
      {
          if (!mxIsDouble(BV_PARAM(S)) ||
              mxGetNumberOfElements(BV_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in BV do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 28th parameter: AF parameter - aF*/
      {
          if (!mxIsDouble(AF_PARAM(S)) ||
              mxGetNumberOfElements(AF_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in AF do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 29th parameter: NF0 parameter - nf0 */
      {
          if (!mxIsDouble(NF0_PARAM(S)) ||
              mxGetNumberOfElements(NF0_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in NF0 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 30th parameter: NF1 parameter - nf1 */
      {
          if (!mxIsDouble(NF1_PARAM(S)) ||
              mxGetNumberOfElements(NF1_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in NF1 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 31th parameter: TL parameter - TL */
      {
          if (!mxIsDouble(TL_PARAM(S)) ||
              mxGetNumberOfElements(TL_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TL do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 32th parameter: TF1 parameter - Tf1 */
      {
          if (!mxIsDouble(TF1_PARAM(S)) ||
              mxGetNumberOfElements(TF1_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TF1 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 33th parameter: TF2 parameter - Tf2 */
      {
          if (!mxIsDouble(TF2_PARAM(S)) ||
              mxGetNumberOfElements(TF2_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TF2 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 34th parameter: TF3 parameter - Tf3 */
      {
          if (!mxIsDouble(TF3_PARAM(S)) ||
              mxGetNumberOfElements(TF2_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TF3 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 35th parameter: TF4 parameter - Tf4 */
      {
          if (!mxIsDouble(TF4_PARAM(S)) ||
              mxGetNumberOfElements(TF4_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TF4 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 36th parameter: AS1 parameter - AS1 */
      {
          if (!mxIsDouble(AS1_PARAM(S)) ||
              mxGetNumberOfElements(AS1_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in AS1 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 37th parameter: AS2 parameter - AS2 */
      {
          if (!mxIsDouble(AS2_PARAM(S)) ||
              mxGetNumberOfElements(AS2_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in AS2 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 38th parameter: TS parameter - TS */
      {
          if (!mxIsDouble(TS_PARAM(S)) ||
              mxGetNumberOfElements(TS_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TS do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 39th parameter: CY parameter - cY*/
      {
          if (!mxIsDouble(CY_PARAM(S)) ||
              mxGetNumberOfElements(CY_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CY do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 40th parameter: VY parameter - VY */
      {
          if (!mxIsDouble(VY_PARAM(S)) ||
              mxGetNumberOfElements(VY_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in VY do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 41th parameter: TY parameter - TY */
      {
          if (!mxIsDouble(TY_PARAM(S)) ||
              mxGetNumberOfElements(TY_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in TY do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 42th parameter: CH0 parameter - ch0 */
      {
          if (!mxIsDouble(CH0_PARAM(S)) ||
              mxGetNumberOfElements(CH0_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CH0 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 43th parameter: CH1 parameter - ch1 */
      {
          if (!mxIsDouble(CH1_PARAM(S)) ||
              mxGetNumberOfElements(CH1_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CH1 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 44th parameter: CH2 parameter - ch2 */
      {
          if (!mxIsDouble(CH2_PARAM(S)) ||
              mxGetNumberOfElements(CH2_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CH2 do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 45th parameter: CH3 parameter - ch3 */
      {
          if (!mxIsDouble(CH3_PARAM(S)) ||
              mxGetNumberOfElements(CH3_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in CH3 do not correspond to number of inputs");
              return;
          }
      }    
      
      
      /*Muscle Parameters*/      
      /* Check 46th parameter: RTYPE parameter - Recruitment Type (0-Natural, 1-Intramuscular FES) */
      {
          if (!mxIsDouble(RTYPE_PARAM(S)) ||
              mxGetNumberOfElements(RTYPE_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"RTYPE parameter to S-function must be a "
                               "scalar");
              return;
          }
      }  
      
       /* Check 47th parameter: ADDPORTS parameter - (1-none, 2-Act, 3-Force, 4-Lce, 5-Vce) */
       {
           if (!mxIsDouble(ADDPORTS_PARAM(S)) ||
               mxGetNumberOfElements(ADDPORTS_PARAM(S)) != 5) { 
               ssSetErrorStatus(S,"Number of parameters in ADDPORTS wrong");
               return;
           }
       }
      
      /* Check 48th parameter: MMASS parameter - Muscle mass */
      {
          if (!mxIsDouble(MMASS_PARAM(S)) ||
              mxGetNumberOfElements(MMASS_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"MMASS parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 49th parameter: FASCL0 parameter - Fascicle length */
      {
          if (!mxIsDouble(FASCL0_PARAM(S)) ||
              mxGetNumberOfElements(FASCL0_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"FASCL0 parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
       /* Check 50th parameter: TENDL0T parameter - Tendon length */
      {
          if (!mxIsDouble(TENDL0T_PARAM(S)) ||
              mxGetNumberOfElements(TENDL0T_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"TENDL0T parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
       /* Check 51th parameter: LPATH parameter - Maximum path length */
      {
          if (!mxIsDouble(LPATH_PARAM(S)) ||
              mxGetNumberOfElements(LPATH_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"LPATH parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 52th parameter: UR parameter - Maximum recruitment activation */
      {
          if (!mxIsDouble(UR_PARAM(S)) ||
              mxGetNumberOfElements(UR_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"UR parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 53th parameter: NUMOFUNITS parameter - Number of motor units in each muscle fiber type*/
      {
           if (!mxIsDouble(NUMOFUNITS_PARAM(S)) ||
              mxGetNumberOfElements(NUMOFUNITS_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in NUMOFUNITS do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 54th parameter: FPCSA parameter - Fractional PCSA for each muscle fiber type */
      {
          if (!mxIsDouble(FPCSA_PARAM(S)) ||
              mxGetNumberOfElements(FPCSA_PARAM(S)) != *mxGetPr(TOFMUSFIB_PARAM(S))) {
              ssSetErrorStatus(S,"Number of parameters in FPCSA do not correspond to number of inputs");
              return;
          }
      }
      
      /* Check 55th parameter: UPCSA parameter - Unit PCSA for each motor unit (depends on apportion method) */
      {          
          for(i=0; i<TypesOf_fibers; i++) {
            Total_MUnits += NumOf_MUnits[i];
          }
          if (!mxIsDouble(UPCSA_PARAM(S)) ||
              mxGetNumberOfElements(UPCSA_PARAM(S)) != Total_MUnits) {
              ssSetErrorStatus(S,"Number of parameters in UPCSA do not correspond to number of inputs");
              return;
          }
      }


      /* Check 56th parameter: APPORTMTD parameter - PCSA apportion method */
      {
          if (!mxIsDouble(APPORTMTD_PARAM(S)) ||
              mxGetNumberOfElements(APPORTMTD_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"APPORTMTD parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
      
      /* Check 57th parameter: GEOPCSA parameter - Fractional increase in PCSA in Geometric apportion method */
      {
          if (!mxIsDouble(GEOPCSA_PARAM(S)) ||
              mxGetNumberOfElements(GEOPCSA_PARAM(S)) != 1) {
              ssSetErrorStatus(S,"GEOPCSA parameter to S-function must be a "
                               "scalar");
              return;
          }
      }
               
  }
  
#endif 



/* Function: mdlInitializeSizes 
 * Description: This function checks the number of parameters, sets the number of continuous states using parameters, sets
 *              number and size of input and output ports, directfeedthrough property, and number of sample times. 
 *              ssSetOptions specifies that there are no exception used in this code. 
 */
static void mdlInitializeSizes(SimStruct *S)
{

    int_T TypesOf_fibers        =  (int_T) *mxGetPr(TOFMUSFIB_PARAM(S));
    real_T* Num_of_Munits       =  mxGetPr(NUMOFUNITS_PARAM(S));
    real_T* Outputports         =  mxGetPr(ADDPORTS_PARAM(S));  
    int_T  Recruitment_Type     = (int_T)*mxGetPr(RTYPE_PARAM(S));
    int_T Total_OutPorts        = 0;
    int_T UnitPCSA_Offset      = 0;
    int_T Recruitment_Offset   = 0;
    int_T Activation_Offset    = 0;
    int_T Total_Munits         = 0;
    int_T i                    = 0;
    int_T j                    = 0;
    
        
    // Check the number of parameters
    ssSetNumSFcnParams(S, NPARAMS);  
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        ssSetErrorStatus(S,"Missing parameters");        
        return;
    }

    // Set number of continuous states each motor unit
    //Find total number of motor units
    Total_Munits = 0;
    for(i=0; i<TypesOf_fibers; i++){
        for(j=0; j<Num_of_Munits[i]; j++){
            Total_Munits ++;
        }
    }
    
    //[0] - Yield
    //[1] - Sag
    //[2] - fint
    //[3] - feff_tmp	<DSaddcomment> the actual feff state var
    //[4] - feff		<DSaddcomment> intermediate used for feff'>=0 or <0 check
    //[0+Total_Munits*5] - Vce
    //[1+Total_Munits*5] - Lce
    //[2+Total_Munits*5] - Ulevel <DSadd22> Ulevel is state of Act input    
    ssSetNumContStates(S, (Total_Munits*5)+3);//<DSadd22> before is +2;
         
    //Set the number of input signals and the width of those inputs
    if (Recruitment_Type == 4) { //FES
        if (!ssSetNumInputPorts(S, 3)) return;
        ssSetInputPortWidth(S, 0, 1); //[0] Input Activation
        ssSetInputPortWidth(S, 1, 1); //[1] Path length
        ssSetInputPortWidth(S, 2, 1); //[2] Frequency (pps) for FES recruitment
    }
    else { //Natural
        if (!ssSetNumInputPorts(S, 2)) return;
        ssSetInputPortWidth(S, 0, 1); //[0] Input Activation
        ssSetInputPortWidth(S, 1, 1); //[1] Path length
    }
    
    
    //DirectFeedthrough is activated because input value are used in mdlOutput method
    ssSetInputPortDirectFeedThrough(S, 0, 1);
	ssSetInputPortDirectFeedThrough(S, 1, 1);
    if (Recruitment_Type == 4) {
        ssSetInputPortDirectFeedThrough(S, 2, 1);
    }
    
    
    //Find the total number of additional port asked for
    Total_OutPorts = 1; //Default [Force]
    for(i=1; i<5; i++){ //[0]-None
        Total_OutPorts += Outputports[i];
    }
    
    // Set number of output signals and dimension
    //start of set the outputport dynamically <DSadd26>
    if (!ssSetNumOutputPorts(S, Total_OutPorts)) return;
    for (i=0; i<Total_OutPorts; i++){
        ssSetOutputPortWidth(S, i, 1);
    }
    //end of set the outputport dynamically <DSadd26>
   
    //Set number of work vectors -- REFER HEADER ABOVE FOR ALLOCATION
    UnitPCSA_Offset = 0;
    Recruitment_Offset = 0;
    Activation_Offset = 0;
    for(i=0; i<TypesOf_fibers; i++){
        for(j=0; j<Num_of_Munits[i]; j++){
            UnitPCSA_Offset++; //total number of motor units in muscle
            Recruitment_Offset++;
            Activation_Offset++;
        }
    }
    ssSetNumRWork(S, (5+UnitPCSA_Offset+1+Recruitment_Offset+1+Activation_Offset+1));
    // Set number of sample time to be used
    ssSetNumSampleTimes(S, 1);
    
    // Specify that there are no execptions in the code. This makes the simulation execute faster
    ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE); 
}



/* Function: mdlInitializeSampleTimes 
 * Description: This function specifies that the S-function block runs in continuous time
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, CONTINUOUS_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S); 
}




/* Function: mdlInitializeConditions 
*  Description: This function is call at the start of the simulation. The function is called
*              to initialize the continuous state vector after calling the ssGetContStates() method.
*/
#define MDL_INITIALIZE_CONDITIONS   
#if defined(MDL_INITIALIZE_CONDITIONS)
static void mdlInitializeConditions(SimStruct *S)
{
    real_T *Work_vect   = ssGetRWork(S);
    real_T MUSCPCSA     = 0.0;
    real_T MUSCF0       = 0.0;      
    real_T FASCLMAX     = 0.0;
    real_T MUSCDENSITY  = 1.06;
    
    real_T *x0 = ssGetContStates(S);
    
    InputRealPtrsType PathPtrs    = ssGetInputPortRealSignalPtrs(S,1);
    //InputRealPtrsType uPtrs = ssGetInputPortRealSignalPtrs(S,0);
    
    real_T PathVar          = *PathPtrs[0];
    //real_T PathVar          = U(2);
    
    real_T Musc_Mass        = *mxGetPr(MMASS_PARAM(S));
    real_T L0               = *mxGetPr(FASCL0_PARAM(S));
    real_T Sp_Tension       = *mxGetPr(SPTEN_PARAM(S));
    real_T c1               = *mxGetPr(C1_PARAM(S));        
    real_T k1               = *mxGetPr(K1_PARAM(S));
    real_T Lr1              = *mxGetPr(LR1_PARAM(S));
    real_T kT               = *mxGetPr(KT_PARAM(S));
    real_T cT               = *mxGetPr(CT_PARAM(S));        
    real_T LrT              = *mxGetPr(LRT_PARAM(S));
    real_T L0T              = *mxGetPr(TENDL0T_PARAM(S));
    real_T Lpath            = *mxGetPr(LPATH_PARAM(S));
    real_T Lmax             = FASCLMAX;
    
    int_T Apportion_mtd     = (int_T)*mxGetPr(APPORTMTD_PARAM(S));
    int_T TypesOf_fibers    = (int_T)*mxGetPr(TOFMUSFIB_PARAM(S));
    real_T* Num_of_Munits   =  mxGetPr(NUMOFUNITS_PARAM(S));
    real_T Geometric_fr     = *mxGetPr(GEOPCSA_PARAM(S));
    real_T* Fract_PCSA      =  mxGetPr(FPCSA_PARAM(S));    
    real_T* Unit_PCSA       =  mxGetPr(UPCSA_PARAM(S));        
    real_T* Recruit_Rank    =  mxGetPr(RRANK_PARAM(S));
  
    real_T Passive_Force        = 0;
    real_T Normalized_SE_Length = 0;
    real_T SE_Length            = 0;
    real_T Total_FPCSA          = 0;
    int_T Total_Munits          = 0;    
   

    int_T  i                    = 0;
    int_T  j                    = 0;
    real_T denominator          = 0.0; 
    real_T correction           = 0.0;
    real_T  total               = 0.0;
    int_T  offset               = 0;
    
    //Initialize Work Vector variables
    MUSCPCSA                = Musc_Mass/MUSCDENSITY/L0;
    MUSCF0                  = MUSCPCSA * Sp_Tension;    
    
    Work_vect[0]            = MUSCPCSA;
    Work_vect[1]            = MUSCF0;
    Work_vect[3]            = MUSCDENSITY;
    ssSetRWorkValue(S,0,Work_vect[0]); //MUSCPCSA
    ssSetRWorkValue(S,1,Work_vect[1]); //MUSCF0
    ssSetRWorkValue(S,3,Work_vect[3]); //MUSCDENSITY
    
    Passive_Force           = c1*k1*log( exp( (1-Lr1)/k1 )+1 ); //Passive force of a muscle stretched to its anatomical maximum
    Normalized_SE_Length    = kT*log( exp(Passive_Force/cT/kT)-1 )+ LrT; //normalized length of SE stretched by that force 
    SE_Length               = L0T*Normalized_SE_Length; //length of SE stretched by passive force
    FASCLMAX                = (Lpath-SE_Length)/L0; 
    Lmax                    = FASCLMAX;

    Work_vect[2]            = FASCLMAX;
    ssSetRWorkValue(S,2,Work_vect[2]); //FASCLMAX
    
    //Check fractional PCSA values to see if it adds up to 1, else ERROR
    for(i=0; i<TypesOf_fibers; i++) {
        Total_FPCSA += Fract_PCSA[i];
        if(Total_FPCSA > 1){
            ssSetErrorStatus(S,"Error in Fractional PCSA allocation");
            //return;
        }
    }
    
    //Initialize Unit PCSA values based on Apportion method (0:Manual, 1:Default, 2:Geometric, 3:Equal)
    switch (Apportion_mtd) {
    
        case 1: //Manaul- do nothig, User sets unit PCSA            
            break;
        case 2: //Default
            offset = 0;            
            for(i=0; i<TypesOf_fibers; i++){
                denominator = 0;
                for(j=0; j<Num_of_Munits[i]; j++){
                    denominator += Recruit_Rank[i] + j + 1;
                }
                for(j=0; j<Num_of_Munits[i]; j++){
                    Unit_PCSA[offset]= Fract_PCSA[i] * (Recruit_Rank[i]+j+1 ) / denominator; 
                    offset++;
                }                
            }
            break;
        case 4: //Geometric 
            offset = 0;
            for(i=0; i<TypesOf_fibers; i++){
                for(j=0; j<Num_of_Munits[i]; j++){
                    total += pow((1+Geometric_fr),(j+1-1));
                   
                }
                
                correction = Fract_PCSA[i]/total;
                for(j=0; j<Num_of_Munits[i]; j++){
                    Unit_PCSA[offset]= pow((1+Geometric_fr),(j+1-1)) * correction; 
                    offset++;
                }
            }
            break;
        case 3: //Equal
            offset = 0;
            for(i=0; i<TypesOf_fibers; i++){
                for(j=0; j<Num_of_Munits[i]; j++){
                    Unit_PCSA[offset]= Fract_PCSA[i]/Num_of_Munits[i]; 
                    offset++;  
                }
            }

            break;
    }
        
    //Fill the unit PCSA values in work vectors
    offset = 0;
    for(i=0; i<TypesOf_fibers; i++){
        for(j=0; j<Num_of_Munits[i]; j++){
            Work_vect[5+offset] = Unit_PCSA[offset];
            ssSetRWorkValue(S,(5+offset),Work_vect[5+offset]);//UNIT_PCSA values
            offset++;
        }
    }

    /*State Variables*/
    //Find total number of motor units
    Total_Munits = 0;
    for(i=0; i<TypesOf_fibers; i++){
        for(j=0; j<Num_of_Munits[i]; j++){
            Total_Munits++;
        }
    }
    
    //Initialize UnitPCSA_offset and Recruitment_offset in work vector array
    Work_vect[4] = Total_Munits;
    ssSetRWorkValue(S,4,Work_vect[4]);//UNIT_PCSA offset
    Work_vect[5+Total_Munits] = Total_Munits;
    ssSetRWorkValue(S,(5+Total_Munits),Work_vect[5+Total_Munits]);//Recruitement offset
    Work_vect[5+Total_Munits+1+Total_Munits] = Total_Munits;
    ssSetRWorkValue(S,(5+Total_Munits+1+Total_Munits),Work_vect[5+Total_Munits+1+Total_Munits]);//Activation offset
 
    
    // Initialize states
    for(i=0; i<Total_Munits;i++)
    {
      x0[0+5*i] = 1;  //Yield   default: 1       
      x0[1+5*i] = *mxGetPr(AS1_PARAM(S));;    //Sag     default: as1 same as parameter AS1_PARAM (slow-twitch 1, fast-twitch 1.76)     
      x0[2+5*i] = 0.0;   //fint    default: 0.0    
      x0[3+5*i] = 0.0;  //feff_tmp default: 0.0		the actual feff state var    
      x0[4+5*i] = 0.0; //feff intermediate used for feff'>=0 or <0 check      
    }      
  
    x0[Total_Munits*5]   = 0.0;  //Vce state unit is (m/s) default: 0
    x0[Total_Munits*5+1] = (((*PathPtrs[0])*100) -(-L0T*(kT/k1*Lr1-LrT-kT*log(c1/cT*k1/kT))))/(100*(1+kT/k1*L0T/Lmax*1/L0)); //Lce 
    x0[Total_Munits*5+2] = 0.0; //<DSadd22> Ulevel from Act input is zero initially (eql to fint)
}  
#endif /* MDL_INITIALIZE_CONDITIONS */



/* Function: mdlStart 
*  Description: This function is called only once and can be used for states 
*              that do not need to be initialize another time. 
*/
#define MDL_START  
#if defined(MDL_START) 
static void mdlStart(SimStruct *S){
}
#endif /*  MDL_START */



/* Function: mdlOutputs =======================================================
 * Description: This function estimates the output using the states values and 
 *              input signals.
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{    
    real_T *Work_vect           = ssGetRWork(S);
    int_T  UnitPCSA_Offset      = Work_vect[4]; 
    int_T  Recruitment_Offset   = UnitPCSA_Offset; 
    int_T  Activation_Offset    = UnitPCSA_Offset; 
    real_T MUSCPCSA             = Work_vect[0];
    real_T MUSCF0               = Work_vect[1];      
    real_T FASCLMAX             = Work_vect[2];
    real_T MUSCDENSITY          = Work_vect[3];

    real_T *x                   = ssGetContStates(S);
    
    // Access to input signals
    InputRealPtrsType ActPtrs       = ssGetInputPortRealSignalPtrs(S,0);
    InputRealPtrsType PathPtrs      = ssGetInputPortRealSignalPtrs(S,1);    
    InputRealPtrsType FreqPtrs      = 0;
    
    // Recruitment block variables   
    real_T* Unit_PCSA       =  mxGetPr(UPCSA_PARAM(S));  
    real_T* Fract_PCSA      =  mxGetPr(FPCSA_PARAM(S));
    real_T* Num_of_Munits   =  mxGetPr(NUMOFUNITS_PARAM(S));
    real_T* Fmax            =  mxGetPr(FMAX_PARAM(S));
    real_T* Fmin            =  mxGetPr(FMIN_PARAM(S));
    int_T  Recruitment_Type = (int_T)*mxGetPr(RTYPE_PARAM(S));
    int_T TypesOf_fibers    = (int_T)*mxGetPr(TOFMUSFIB_PARAM(S));
    real_T Ur               = *mxGetPr(UR_PARAM(S));
    real_T* f05             =  mxGetPr(F05_PARAM(S));
    
    //<DSadd22> add MUCR (case2)
    real_T Threshold_TypeArray[10]; //Works for 10 fiber types
    
    real_T Threshold        = 0.0;
    real_T PCSA_Sum         = 0.0;
    int_T offset            = 0;
    int_T offset_M          = 0;
    int_T Total_Munits      = 0;
    int_T min_Index         = 0;
    real_T min_Val          = 0.0;            
    int_T k                 = 0;
    int_T Munit_index       = 0;
    int_T Min_PCSA          = 0;
    int_T j_index           = 0;

    // Fascicle block variables
    real_T* Tf1                         =  mxGetPr(TF1_PARAM(S));        
    real_T* Tf2                         =  mxGetPr(TF2_PARAM(S));
    real_T* Tf3                         =  mxGetPr(TF3_PARAM(S));
    real_T* Tf4                         =  mxGetPr(TF4_PARAM(S));
    real_T* cY                          =  mxGetPr(CY_PARAM(S));
    real_T* nf0                         =  mxGetPr(NF0_PARAM(S));
    real_T* nf1                         =  mxGetPr(NF1_PARAM(S));
    real_T* af                          =  mxGetPr(AF_PARAM(S));
    real_T* aS1                         =  mxGetPr(AS1_PARAM(S));
    real_T* aS2                         =  mxGetPr(AS2_PARAM(S));

    real_T Yield_Munit                  = 0.0;
    real_T Sag_Munit                    = 0.0;
    real_T invTf1                       = 0.0;
    real_T invTf2                       = 0.0;
    real_T nf                           = 0.0; 
    real_T Af_op                        = 0.0;
    real_T Af_op1                       = 0.0; 
    //Muscle Mass variables
    real_T Lce              = 0.0;
    real_T Vce              = 0.0;
    
    //Series Elastic Element variables
    real_T L0T              = *mxGetPr(TENDL0T_PARAM(S));
    real_T L0               = *mxGetPr(FASCL0_PARAM(S));
    real_T kT               = *mxGetPr(KT_PARAM(S));
    real_T cT               = *mxGetPr(CT_PARAM(S));        
    real_T LrT              = *mxGetPr(LRT_PARAM(S));
    
    real_T prov             = 0.0;
    real_T Fse              = 0.0;

    
    //FES recruitment (works for 20 fiber types)
    //     real_T Running_Total[20]; //TODO: Make it dynamic

    //Temp variables
    int_T i                 = 0;
    int_T j                 = 0;
    int_T ii =0; //<DSadd26> 
    int_T jj =0; //<DSadd26>

    
    // Access output signal //<DSadd26>
    real_T* Outputports       =  mxGetPr(ADDPORTS_PARAM(S));  //<DSadd26>    
    real_T *FsePtrs           = ssGetOutputPortRealSignal(S,0); //<DSadd26> the Force (N) exist by default
    int_T Total_Outports      = 0;
    real_T *ActoutPtrs; //2
    real_T *FseF0Ptrs;  //3
    real_T *LcePtrs;    //4
    real_T *VcePtrs;    //5
    
    //Extract work vector values
    //Modify Unit_PCSA based on the values calculated in mdlInitializeConditions()
    offset = 0;
    Total_Munits = 0;
    for(i=0; i<TypesOf_fibers; i++){
        for(j=0; j<Num_of_Munits[i]; j++){
            Unit_PCSA[offset] = Work_vect[5+offset];
            offset++;
            Total_Munits ++;
        }
    } 
           
    //Call mdlInitializeConditions if PathPtrs read zero on the first iteration    
    if (x[Total_Munits*5+1] <= 0.0) {
        mdlInitializeConditions(S);
    }
        
     //Define Input ports //<DSaddd26>
     if (Recruitment_Type == 4) { //FES
         FreqPtrs      = ssGetInputPortRealSignalPtrs(S,2);
     }
    
    //Define Output ports //<DSadd26>
    j=1;
    if (Outputports[1]){
        ActoutPtrs = ssGetOutputPortRealSignal(S,j); j++;
    }
    if (Outputports[2]){
        FseF0Ptrs  = ssGetOutputPortRealSignal(S,j); j++;
    }
    if (Outputports[3]){
        LcePtrs    = ssGetOutputPortRealSignal(S,j); j++;
    }
    if (Outputports[4]){
        VcePtrs    = ssGetOutputPortRealSignal(S,j); j++;
    }
      
    
    /*Implement Recruitment Block*/   
    
    switch(Recruitment_Type){

        case 2: //Natural
            offset = 0;
            PCSA_Sum = 0.0;
            for(i=0; i<TypesOf_fibers; i++){
                for(j=0; j<Num_of_Munits[i]; j++){
                    PCSA_Sum += Unit_PCSA[offset];
                    Threshold = max((PCSA_Sum * Ur), 0.001);                
                    if((*ActPtrs[0]) >= Threshold) {
                        Work_vect[5+UnitPCSA_Offset+1 + offset] = ((Fmax[i]-Fmin[i])/(1-Threshold)) * ((*ActPtrs[0])-Threshold) + Fmin[i]; 
                        ssSetRWorkValue(S,(5+UnitPCSA_Offset+1 + offset),Work_vect[5+UnitPCSA_Offset+1 + offset]);                        
                    }
                    else {
                        Work_vect[5+UnitPCSA_Offset+1 + offset] = 0.0;
                        ssSetRWorkValue(S,(5+UnitPCSA_Offset+1 + offset),Work_vect[5+UnitPCSA_Offset+1 + offset]);
                    }
                    offset++;
                }
            }            
            
            break;
            
         case 3: //<DSadd22> get one more case for contineous recruitment
            //Calculate Threshold_TypeArray for each fiber type (i)
            PCSA_Sum = 0.0;      
            Threshold_TypeArray[0]=0.001;
            for(i=0; i<TypesOf_fibers; i++){
                PCSA_Sum += Unit_PCSA[i];
                Threshold_TypeArray[i+1] = max((PCSA_Sum * Ur), 0.001);
            }
            //Calculate fenv for each fiber type use the fomula: Y=(Fmax-Fmin)*X+Fmin
            for(i=0; i<TypesOf_fibers; i++){
                    if((*ActPtrs[0]) >= Threshold_TypeArray[i]) {
                        Work_vect[5+UnitPCSA_Offset+1 + i] = ((Fmax[i]-Fmin[i])/(1-Threshold_TypeArray[i])) * ((*ActPtrs[0])-Threshold_TypeArray[i]) + Fmin[i]; 
                        ssSetRWorkValue(S,(5+UnitPCSA_Offset+1 + i),Work_vect[5+UnitPCSA_Offset+1 + i]);                        
                    }
                   else {
                        Work_vect[5+UnitPCSA_Offset+1 + i] = 0.0;
                        ssSetRWorkValue(S,(5+UnitPCSA_Offset+1 + i),Work_vect[5+UnitPCSA_Offset+1 + i]);
                    }
                }
                
            break;      
            
        case 4: //Intramuscular FES 
            offset = 0;                 
            for(i=0; i<TypesOf_fibers; i++){ 
                for(j=0; j<Num_of_Munits[i]; j++){
                    Work_vect[5+UnitPCSA_Offset+1 + offset] = (*FreqPtrs[0])* (1/f05[i]);                       
                    ssSetRWorkValue(S,(5+UnitPCSA_Offset+1 + offset),Work_vect[5+UnitPCSA_Offset+1 + offset]);                     
                                  
                    offset++;                 
                    
                }               
            }                                       
            break;    

    }    
            
    /*Implement Muscle Mass*/    
    Lce = (1/(L0/100))*x[1+(Total_Munits*5)];
    Vce = (1/(L0/100))*x[0+(Total_Munits*5)];  
    
    /*Implement Series Elastic Element*/
    prov = (1/L0T)*(((*PathPtrs[0])*100) - L0 * Lce); 
    Fse = cT*kT*log( exp((prov-LrT)/kT) + 1)*MUSCF0;

    //Link output port name to output signal
    //<DSadd26>
     FsePtrs[0]=Fse;//-1
     if (Outputports[1]){        
        ActoutPtrs[0]=*ActPtrs[0];
     }
     if (Outputports[2]){
        FseF0Ptrs[0]=Fse/MUSCF0;
     }
     if (Outputports[3]){
        LcePtrs[0]=Lce;
     }
     if (Outputports[4]){
        VcePtrs[0]=Vce;
     }       
  
    /*Implement Fascicles (A)*/
    if (Recruitment_Type == 4){ //Intramuscular FES 
        offset_M = 0;
        offset = 0;
        for(i=0; i<TypesOf_fibers; i++){   //one unit per fiber type    
            if(cY[i] > 0.0)
                Yield_Munit = x[0+offset_M]; //Only slow fibers have yield
            else
                Yield_Munit = 1.0;  //u1
            
            nf = nf0[i]+nf1[i]*((1/Lce)-1); //u2
            
            if(aS1[i] == aS2[i]) //u4
               Sag_Munit = 1.0; //No sag slow fibers
            else
               Sag_Munit = x[1+offset_M]; //Only fast fibers have sag
           
            //u3 is fenv input -> f05 output of (unit) recruiment 
            
            Af_op = 1-exp(-pow((Yield_Munit*Sag_Munit*(Work_vect[5+UnitPCSA_Offset+1 + offset])/(af[i]*nf)),nf));
            Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset] = Af_op;
            ssSetRWorkValue(S,(5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset),Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset]);
            
            offset_M += 5;
            offset++;          
        }//end for i        
    } //end if Intramuscular FES
    else {
    offset_M = 0;
    offset = 0;
    for(i=0; i<TypesOf_fibers; i++){
        
        //Motorunit specific things (find Af_op)
        for(j=0; j<Num_of_Munits[i]; j++){            
            
            if(cY[i] > 0.001)
                Yield_Munit = x[0+offset_M]; //Only slow fibers have yield
            else
                Yield_Munit = 1.0;  
            
            invTf1 = 1/((Tf1[i]/1000)*pow(Lce,2)+(Tf2[i]/1000)*(Work_vect[5+UnitPCSA_Offset+1 + offset])); //feff'>0
            invTf2 = Lce/((Tf3[i]/1000)+(Tf4[i]/1000)*Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset]); //feff'<0
            
            if((x[2+offset_M]-x[3+offset_M])>=0)
                x[4+offset_M] = invTf1;
            else 
                x[4+offset_M] = invTf2;
        
            nf = nf0[i]+nf1[i]*((1/Lce)-1);
            
            if(aS1[i] == aS2[i]){ 
               Sag_Munit = 1.0; //No sag slow fibers
            }
            else{
                Sag_Munit = x[1+offset_M]; //Only fast fibers have sag
            }
            Af_op1=Yield_Munit*Sag_Munit*x[3+offset_M]/(af[i]*nf); ////<DSadd3> YSfeff/afnf
            Af_op = 1-exp(-pow(Af_op1,nf));//<DSaddcomment> Af equation before scaled by unitPCSA
            Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset] = Af_op;
            ssSetRWorkValue(S,(5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset),Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset]);
            
            offset_M += 5;
            offset++; //would indicate the total # of MU
                       
        }
   }

} //end for else

    /* Implement rise and fall block for Intramuscular FES */
    if (Recruitment_Type == 4){ //Intramuscular FES
        offset   = 0;
        offset_M = 0;
        for(i=0; i<TypesOf_fibers; i++){            
            //u1--Lce, u2--fenv, u3 -- 1 / 0
            if ((*ActPtrs[0]) > 0) 
                invTf2 = Lce/((Tf3[i]/1000)+(Tf4[i]/1000)*1); //feff'<0
            else 
                invTf2 = Lce/((Tf3[i]/1000)+(Tf4[i]/1000)*0); //feff'<0
            
            invTf1 = 1/((Tf1[i]/1000)*pow(Lce,2)+(Tf2[i]/1000)*(Work_vect[5+UnitPCSA_Offset+1 + offset])); //feff'>0
                        
            if((x[2+offset_M]-x[3+offset_M])>=0) 
                x[4+offset_M] = invTf1;
            else 
                x[4+offset_M] = invTf2;                       
            
            offset_M += 5;
            offset++;         
        }//end for
    }//end if    
    
} //mdlOutputs

#define MDL_DERIVATIVES  
#if defined(MDL_DERIVATIVES)
/* Function: mdlDerivatives =================================================
*  Description: This method is used to update derivatives of continuous states.
*              Derivatives correpond to integrators'inputs 
*/
  static void mdlDerivatives(SimStruct *S)
  {
    real_T *dx                  = ssGetdX(S);
    real_T *x                   = ssGetContStates(S);
    
    real_T *Work_vect           = ssGetRWork(S);
    real_T MUSCPCSA             = Work_vect[0];
    real_T MUSCF0               = Work_vect[1];      
    real_T FASCLMAX             = Work_vect[2];
    real_T MUSCDENSITY          = Work_vect[3];
    int_T  UnitPCSA_Offset      = Work_vect[4]; 
    int_T  Recruitment_Offset   = UnitPCSA_Offset; 
    int_T  Activation_Offset    = UnitPCSA_Offset; 
 
    
     // Access to input signals
    InputRealPtrsType ActPtrs       = ssGetInputPortRealSignalPtrs(S,0);
    InputRealPtrsType PathPtrs      = ssGetInputPortRealSignalPtrs(S,1);
    InputRealPtrsType FreqPtrs      = 0;
 

    // Access output signal 
    real_T *FsePtrs             = ssGetOutputPortRealSignal(S,0);
    
    //Fascicles 
    real_T Viscocity                    = *mxGetPr(VISC_PARAM(S));
    real_T c1                           = *mxGetPr(C1_PARAM(S));
    real_T k1                           = *mxGetPr(K1_PARAM(S));
    real_T Lr1                          = *mxGetPr(LR1_PARAM(S));
    real_T c2                           = *mxGetPr(C2_PARAM(S));
    real_T k2                           = *mxGetPr(K2_PARAM(S));
    real_T Lr2                          = *mxGetPr(LR2_PARAM(S));
    real_T* bV                          =  mxGetPr(BV_PARAM(S));
    real_T* aV0                         =  mxGetPr(AV0_PARAM(S));
    real_T* aV1                         =  mxGetPr(AV1_PARAM(S));
    real_T* aV2                         =  mxGetPr(AV2_PARAM(S));
    real_T* Vmax                        =  mxGetPr(VMAX_PARAM(S));
    real_T* cV0                         =  mxGetPr(CV0_PARAM(S));
    real_T* cV1                         =  mxGetPr(CV1_PARAM(S));
    real_T* FL_beta                     =  mxGetPr(FLBETA_PARAM(S));
    real_T* FL_omega                    =  mxGetPr(FLOMEGA_PARAM(S));
    real_T* FL_rho                      =  mxGetPr(FLRHO_PARAM(S));

    real_T Total_Force_Munits           = 0.0;
    real_T Fpe                          = 0.0;
    real_T Fpe1                         = 0.0;
    real_T Fpe2                         = 0.0;
    real_T Force_Munits                 = 0.0;
 
    /*Note: The virtual muscle currently takes in 10 types of fibers
          : If you need more increase 10 below */
    real_T Force_TypesofFibers[10];    // TODO: make it dynamic
    real_T Force_NumofFibers[10];      // TODO: make it dynamic    
    real_T FVlengthen[10];             // TODO: make it dynamic    
    real_T FVshorten[10];              // TODO: make it dynamic    
    real_T FL[10];                     // TODO: make it dynamic
    real_T FV[10];                     // TODO: make it dynamic
    real_T PEpFLtFV[10];               // TODO: make it dynamic
    
    // <DSadd22> MUCR 
    real_T Threshold_TypeArray[10];    //max 10 fiber types
    real_T U_deno              = 0.0;  //
    real_T Total_Af            = 0.0;  //if 3 fiber types: Total_Af=(Af1*(U-U1)/U_deno + Af2*(U-U2)/U_deno + Af3*(U-U3)/U_deno);
    real_T Total_PEpFLtFV      = 0.0;  //if 3 fiber types:  Total_PEpFLFV = (PEpFLFV1*(U-U1)/U_deno + PEpFLFV2*(U-U2)/U_deno + PEpFLFV3*(U-U3)/U_deno);
    real_T Total_Af_PEpFLtFV   = 0.0;  //<DSadd24>
    int_T  Recruitment_Type    = (int_T)*mxGetPr(RTYPE_PARAM(S));
    real_T PCSA_Sum            = 0.0;
    real_T* Unit_PCSA          =  mxGetPr(UPCSA_PARAM(S));
    real_T Ur                  = *mxGetPr(UR_PARAM(S));
    real_T* Fract_PCSA         =  mxGetPr(FPCSA_PARAM(S));    
   
    
    // Parameters
    real_T TypesOf_fibers   = *mxGetPr(TOFMUSFIB_PARAM(S));
    real_T* Num_of_Munits   =  mxGetPr(NUMOFUNITS_PARAM(S));
    real_T* cY              =  mxGetPr(CY_PARAM(S));
    real_T* VY              =  mxGetPr(VY_PARAM(S));
    real_T* Ts              =  mxGetPr(TS_PARAM(S));
    real_T* aS1             =  mxGetPr(AS1_PARAM(S));
    real_T* aS2             =  mxGetPr(AS2_PARAM(S));
    real_T Mass             = *mxGetPr(MMASS_PARAM(S));
    real_T L0               = *mxGetPr(FASCL0_PARAM(S));
 
    // Variables
    real_T Ftotal           = 0.0;
    real_T Fse              = 0.0;
    real_T Fce              = 0.0;
    real_T Lce              = 0.0;
    real_T Vce              = 0.0;   
    int_T Total_Munits      = 0;
    
    int_T i                 = 0;
    int_T j                 = 0;
    real_T temp             = 0.0;
    int_T offset            = 0;
    int_T offset_M          = 0;

    real_T* Fmin            =  mxGetPr(FMIN_PARAM(S)); //<DSadd15>
    
    //<DSadd25> He's variables:
    real_T ActF             = 0.0;
    real_T Af[20];
    real_T F0[20];
    
    //FES input port
    if (Recruitment_Type == 4) { //FES
         FreqPtrs      = ssGetInputPortRealSignalPtrs(S,2);
     }

    
    //Find total number of motor units
    Total_Munits = 0;
    for(i=0; i<TypesOf_fibers; i++){
        for(j=0; j<Num_of_Munits[i]; j++){
            Total_Munits ++;
        }
    }

    //Muscle Mass
    //duplicate it here to avoid storing Vce and Lce
    Lce = (1/(L0/100))*x[1+(Total_Munits*5)];
    Vce = (1/(L0/100))*x[0+(Total_Munits*5)]; 
    
    //Fascicles - Upto 10 types of muscle fibers; Increase value 10 if needed
     for(i=0; i<10; i++){     //TODO: Make it dynamic
        Force_TypesofFibers[i]  = 0.0;
        Force_NumofFibers[i]    = 0.0;
        FVlengthen[i]           = 0.0;
        FVshorten[i]            = 0.0;
        FL[i]                   = 0.0;
        FV[i]                   = 0.0;
        PEpFLtFV[i]             = 0.0;
        
    }
    
    Fpe1 = Viscocity*Vce+c1*k1*log(exp((Lce/FASCLMAX-Lr1)/k1)+1);
    Fpe2 = c2*(exp(k2*(Lce-Lr2))-1);

    if(Fpe2>0)
        Fpe2 = 0.0;
    
    offset_M = 0;
    offset = 0;
    for(i=0; i<TypesOf_fibers; i++){
        
        FVlengthen[i] = (bV[i]-(aV0[i]+aV1[i]*Lce+(aV2[i])*pow(Lce,2))*Vce)/(bV[i]+Vce);
        FVshorten[i] = (Vmax[i]-Vce)/(Vmax[i]+(cV0[i]+cV1[i]*Lce)*Vce);
        
        temp = (pow(Lce,FL_beta[i])-1)/FL_omega[i];
       
        if(temp<0.0)
            temp = -temp;
        FL[i] = exp(-pow(temp,FL_rho[i])); 
        
        if(Vce>0)
            FV[i] = FVlengthen[i];
        else 
            FV[i] = FVshorten[i];
            
        if (Recruitment_Type == 4) //IntraFES
            PEpFLtFV[i] = FL[i]*FV[i];
        else 
            PEpFLtFV[i] = Fpe2+(FL[i]*FV[i]); 
        //Activation[]
   }
    
//Start of switch for adding one more recruitment MUCR (case2) //<DSadd22>
   //Calculate total forces based on Recruitment_Type (case2 MUCR, case 0 and 1 original)
    switch(Recruitment_Type){
        case 3: //<DSadd22> Af_opth*percent of Uth taken of input U
            //Calculate Threshold_TypeArray for each fiber type (i)
            PCSA_Sum = 0.0;      
            Threshold_TypeArray[0]=0.001;
            for(i=0; i<TypesOf_fibers; i++){
                PCSA_Sum += Unit_PCSA[i];
                Threshold_TypeArray[i+1] = max((PCSA_Sum * Ur), 0.001);       
                
            }
  
            //Add up the denominator of (U-U1)+(U-U2)+(U-U3)
            U_deno=0;
            for(i=0; i<TypesOf_fibers; i++)
                U_deno +=(x[2+(Total_Munits*5)]-Threshold_TypeArray[i])*(x[2+(Total_Munits*5)]>=Threshold_TypeArray[i]);//<DSadd22>
            //To avoid divided by 0, reset U_deno=0 when U<Uth1
            if (U_deno==0)
                U_deno=1; 
            //Add up all fiber type forces = Total_Af*U*Total_PEpFLFV
            Total_Af = 0.0; //if 3 fiber types: Total_Af=(Af1*(U-U1)/U_deno + Af2*(U-U2)/U_deno + Af3*(U-U3)/U_deno);
            Total_PEpFLtFV = 0.0; //if 3 fiber types:  Total_PEpFLFV = (PEpFLFV1*(U-U1)/U_deno + PEpFLFV2*(U-U2)/U_deno + PEpFLFV3*(U-U3)/U_deno);
            Total_Af_PEpFLtFV = 0.0; //<DSadd24> sum of Weight_j*[Af_j*(FlFV+fpe2)_j]
            for(i=0; i<TypesOf_fibers; i++){
                Total_Af += Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + i]*(x[3+(Total_Munits*5)]-Threshold_TypeArray[i])/U_deno; 
                Total_PEpFLtFV += PEpFLtFV[i]*(x[2+(Total_Munits*5)]>=Threshold_TypeArray[i])*(x[2+(Total_Munits*5)]-Threshold_TypeArray[i])/U_deno;
                Total_Af_PEpFLtFV += Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + i]*PEpFLtFV[i]*(x[2+(Total_Munits*5)]>=Threshold_TypeArray[i])*(x[2+(Total_Munits*5)]-Threshold_TypeArray[i])/U_deno;
             }
             Total_Force_Munits = Total_Af_PEpFLtFV * x[2+(Total_Munits*5)]; // <DSadd24>
            Fce = MUSCF0 * (Fpe1 + Total_Force_Munits); 
        break;
       

        
        case 2: //Force and Stiffness calculation Before DSadd22-add MUCR
            //Add up all motor unit forces based on PCSA
            offset = 0;
            Total_Force_Munits = 0.0;

            for(i=0; i<TypesOf_fibers; i++){
                Force_Munits = 0.0; //Af_type <DSaddcomment> 
                for(j=0; j<Num_of_Munits[i]; j++){
                    Force_Munits += Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset]*Work_vect[5+ offset]; //Af_op*Fpcsa
                    offset++;
                }
                Force_Munits = Force_Munits * PEpFLtFV[i];// Af*(Fpe2+FL*FV)

                Total_Force_Munits += Force_Munits;
            }
            Fce = MUSCF0 * (Fpe1 + Total_Force_Munits); 

          break;
          
        case 4: //Force and Stiffness calculation Before DSadd22-add MUCR
            //Add up all motor unit forces based on PCSA
            offset = 0;
            Total_Force_Munits = 0.0;
            for(i=0; i<TypesOf_fibers; i++){
                Force_Munits = 0.0; //Af_type <DSaddcomment> 
                for(j=0; j<Num_of_Munits[i]; j++){
                   Force_Munits += Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1 + offset]*Fract_PCSA[i]; 
                   Af[i] = Force_Munits;
                   offset++;
                }
                Force_Munits = Force_Munits * PEpFLtFV[i];// Af*(Fpe2+FL*FV)
                Force_Munits *= MUSCF0;
                Fpe += Af[i]*Fpe2;  
                F0[i] = Force_Munits;
            }
            Fpe = (Fpe+Fpe1)*MUSCF0; 
            if (Fpe < 0) 
                Fpe = 0.0;     
                offset_M = 0;
            for(i=0; i<TypesOf_fibers; i++){   
                //each fiber type (unit)'s feff times each fiber type's F0 output, respectively
                ActF += x[3+offset_M]* F0[i];
                offset_M += 5;           
            } 
          Fce = ActF + Fpe;
          break;

    }
    
    //End of switch for adding one more recruitment MUCR (case2)

   if(Fce < 0.0) {
       Fce = 0.0;
   }
   
    Lce = (1/(L0/100))*x[1+(Total_Munits*5)];
    Fse = FsePtrs[0]; //<DSadd3>??? Where did Fse is assigned to Work_vect[5+UnitPCSA_Offset+1+Recruitment_Offset+1+Activation_Offset]
    Ftotal = Fse - Fce;
    
    dx[0+(Total_Munits*5)] = Ftotal * (1/(Mass/2000)); //Vce = Int(Acc)
    dx[1+(Total_Munits*5)] = x[0+(Total_Munits*5)]; //Lce = Int(Vce)
    //start <DSadd22>Integrate the state Ulevel if RTYPE=3, dUlevel=(Act-Ulevel)/Tao
    if(Recruitment_Type==3){
            if((*ActPtrs[0])-x[2+(Total_Munits*5)]>=0)
                dx[2+(Total_Munits*5)] = ((*ActPtrs[0])-x[2+(Total_Munits*5)])*1/0.03; //<DSadd23> different tao
            else 
                dx[2+(Total_Munits*5)] = ((*ActPtrs[0])-x[2+(Total_Munits*5)])*1/0.15;
    }
    else 
        dx[2+(Total_Munits*5)] = 0.0;       
    //end <DSadd22>Integrate the state Ulevel if RTYPE=3   
       
    offset_M = 0;
    offset = 0;
    for(i=0; i<TypesOf_fibers; i++) {
        for(j=0; j<Num_of_Munits[i]; j++){
            if(cY[i] > 0){ //yield (only for slow fibers)
                if(Vce>=0) 
                    dx[0+offset_M] = 5*((1-cY[i]*(1-exp(-Vce/VY[i])))-x[0+offset_M]);                    
                else
                    dx[0+offset_M] = 5*((1-cY[i]*(1-exp(Vce/VY[i])))-x[0+offset_M]);            
            }
            else
                dx[0+offset_M] = 0.0;
            
            if(aS1[i] != aS2[i]){
                if( ((Recruitment_Type!=4)&&(x[3+offset_M]>0.1)) || ((Recruitment_Type == 4)&&(Work_vect[5+UnitPCSA_Offset+1 + offset]>0.1)))
                    dx[1+offset_M] = (1/(Ts[i]/1000))*(aS2[i]-x[1+offset_M]); //sag (only for fast fibers)
                else 
                    dx[1+offset_M] = (1/(Ts[i]/1000))*(aS1[i]-x[1+offset_M]);
            }
            else
                dx[1+offset_M] = 0.0;
            
            if (Recruitment_Type == 4) 
                dx[2+offset_M] = ((*ActPtrs[0])-x[2+offset_M])*x[4+offset_M]; //d(fint)
            else
                dx[2+offset_M] = ((Work_vect[5+UnitPCSA_Offset+1 + offset])-x[2+offset_M])*x[4+offset_M]; //d(fint)
            dx[3+offset_M] = (x[2+offset_M]-x[3+offset_M])*x[4+offset_M]; //d(feff_tmp)
            dx[4+offset_M] = 0.0; //d(feff)
            
            offset_M +=5;
            offset++;
            
        }
    }
        
  
  }
#endif /* MDL_DERIVATIVES */



/* Function: mdlTerminate 
 * Description: This method is called at the end of a simulation.
 */
static void mdlTerminate(SimStruct *S)
{
}



#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif

