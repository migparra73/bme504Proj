%%CreateSimulinkBlock_sfun     Version 4.0
%Creates muscle blocks in Simuilnk for s-functions

% Authors: Giby Raphael & Dan Song (1-8-8) 

function systemname=CreateSimulinkBlock_sfun(sfunParameters, musclenumber)
global Muscle_Morph Muscle_Model_Parameters

Recruitment_sfunc=[{'Natural'} {'Natural Discrete (s-function)'} {'Natural Continuous (s-function)'} {'Intramuscular FES (s-function)'}]; 

systemhandle=new_system;	
systemname=get_param(systemhandle,'name');	
sys=[systemname,'/',[Muscle_Morph(musclenumber).Muscle_Name]];

%Create muscle block
add_block('built-in/S-Function',sys);
open_system(sys);
set_param(sys,'FunctionName','Virtual_Muscle_SFunction');
set_param(sys,'Position',[185 90 420 200]);

%create mask
set_param(sys,'mask','on');
set_param(sys,'MaskType','Virtual Muscle Parameters');

%set parameters                        
set_param(sys,'Parameters',['TOFMUSFIB SARCLEN SPTEN VISC C1 K1 LR1 C2 K2 '...
                            'LR2 CT KT LRT RRANK V05 F05 FMIN FMAX FLOMEGA '...
                            'FLBETA FLRHO VMAX CV0 CV1 AV0 AV1 AV2 BV AF '...
                            'NF0 NF1 TL TF1 TF2 TF3 TF4 AS1 AS2 TS CY VY '...
                            'TY CH0 CH1 CH2 CH3 RTYPE ADDPORTS MMASS FASCL0 '...
                            'TENDL0T LPATH UR NUMOFUNITS FPCSA UPCSA '...
                            'APPORTMTD GEOPCSA']); %Total 58 parameters


set_param(sys,'MaskPromptString',['Recruitment Type (2-Natural Discrete, 3-Natural Continuous, 4-Intramuscular FES)|'...
                                  'Additional Outputs|'...
                                  'Optimal Fascicle Length (cm)|'...
                                  'Optimal Tendon Length (cm)|'...
                                  'Maximum Path Length (cm)|'...
                                  'Muscle Mass (g)|'...
                                  'Maximum Recruitment Activation (Ur)|'...
                                  'Specific Tension (N/cm2)|'...
                                  'Viscosity (part of FPE1)|'...
                                  'Optimal sarcomere length (um)|'...                                  
                                  'C1 (FPE1)|K1 (FPE1)|LR1 (FPE1)|'...
                                  'C2 (FPE2)|K2 (FPE2)|LR2 (FPE2)|'...
                                  'CT (FSE)|KT (FSE)|LRT (FSE)|'...
                                  'Number of Fiber Types|'...
                                  'Fractional PCSA for Each Muscle Fiber Type|'...
                                  'Number of motor units in each muscle fiber type|'...
                                  'Apportion Method (1-Manual, 2-Default, 3-Geometric, 4-Equal)|'...
                                  'Fractional increase in PCSA for Geometric Apportion Method|'...
                                  'PCSA for Each Motor Unit (Manual changes effective only for Apportion Method 1|'...
                                  'Recruitment Rank|'...
                                  'V0.5 (L0/s)|f0.5 (pps)|'...
                                  'fmin (f0.5)|fmax (f0.5)|'...
                                  'FL_omega|FL_beta|FL_rho|'...
                                  'Vmax|cV0|cV1|'...
                                  'aV0|aV1|aV2|bV|'...
                                  'aF|nf0|nf1|'...
                                  'TL|Tf1|Tf2|Tf3|Tf4|'...
                                  'AS1|AS2|TS|CY|VY|TY|'...
                                  'ch0|ch1|ch2|ch3|']);


%set mask style
set_param(sys,'MaskStyleString',['edit,edit,edit,edit,edit,edit,edit,edit,edit,edit,'...
                                'edit,edit,edit,edit,edit,edit,edit,edit,edit,edit,'...
                                'edit,edit,edit,edit,edit,edit,edit,edit,edit,edit,'...
                                'edit,edit,edit,edit,edit,edit,edit,edit,edit,edit,'...
                                'edit,edit,edit,edit,edit,edit,edit,edit,edit,edit,'...
                                'edit,edit,edit,edit,edit,edit,edit,edit']);
                            
set_param(sys,'MaskTunableValueString',['on,on,on,on,on,on,on,on,on,on,'...
                                       'on,on,on,on,on,on,on,on,on,on,'...
                                       'on,on,on,on,on,on,on,on,on,on,'...
                                       'on,on,on,on,on,on,on,on,on,on,'...
                                       'on,on,on,on,on,on,on,on,on,on,'...
                                       'on,on,on,on,on,on,on,on']);    
                                   
%Note, Recruitment Type, Additional ports, Apportin methods, and Unit PCSA 
%coorespionding to the Apportion methods are not editable
%Use rebuild option to edit Recruitment Type, Additional ports, and Aportion methods
set_param(sys,'MaskEnableString',['off,off,on,on,on,on,on,on,on,on,'...
                                 'on,on,on,on,on,on,on,on,on,on,'...
                                 'on,on,on,on,on,on,on,on,on,on,'...
                                 'on,on,on,on,on,on,on,on,on,on,'...
                                 'on,on,on,on,on,on,on,on,on,on,'...
                                 'on,on,on,on,on,on,on,on']);
  % <DSadd6> Note Continuous Recruitment (Recruitment Type is 3), Number of Motor
  % Units is always one for each fiber type,so it's not editable                          
%   RType=strmatch(Muscle_Model_Parameters.Recruitment_Type,Recruitment_sfunc,'exact');
%   if RType==3
%       set_param(sys,'MaskEnableString',['off,off,on,on,on,on,on,on,on,on,'...
%                                  'on,on,on,on,on,on,on,on,on,on,'...
%                                  'on,on,on,on,on,on,on,on,on,on,'...
%                                  'on,on,on,on,on,on,on,on,on,on,'...
%                                  'on,on,on,on,on,on,on,on,on,on,'...
%                                  'on,on,on,off,on,on,on,on']);
%   end
                                   
set_param(sys,'MaskVisibilityString',['on,on,on,on,on,on,on,on,on,on,',...
                                     'on,on,on,on,on,on,on,on,on,on,',...
                                     'on,on,on,on,on,on,on,on,on,on,',...
                                     'on,on,on,on,on,on,on,on,on,on,',...
                                     'on,on,on,on,on,on,on,on,on,on,',...
                                     'on,on,on,on,on,on,on,on']);    
                                 

set_param(sys,'MaskVariables',['RTYPE=@1;ADDPORTS=@2;FASCL0=@3;TENDL0T=@4;LPATH=@5;'...
                            'MMASS=@6;UR=@7;SPTEN=@8;VISC=@9;SARCLEN=@10;C1=@11;K1=@12;'...
                            'LR1=@13;C2=@14;K2=@15;LR2=@16;CT=@17;'...
                            'KT=@18;LRT=@19;TOFMUSFIB=@20;FPCSA=@21;NUMOFUNITS=@22;'...
                            'APPORTMTD=@23;GEOPCSA=@24;UPCSA=@25;RRANK=@26;V05=@27;F05=@28;'...
                            'FMIN=@29;FMAX=@30;FLOMEGA=@31;FLBETA=@32;FLRHO=@33;VMAX=@34;'...
                            'CV0=@35;CV1=@36;AV0=@37;AV1=@38;AV2=@39;BV=@40;'...
                            'AF=@41;NF0=@42;NF1=@43;TL=@44;TF1=@45;TF2=@46;'...
                            'TF3=@47;TF4=@48;AS1=@49;AS2=@50;TS=@51;CY=@52;'...
                            'VY=@53;TY=@54;CH0=@55;CH1=@56;CH2=@57;CH3=@58;']); %Total 58 parameters                        
                            
                        
%pass values to parameters
set_param(sys,'MaskValueString',sfunParameters);

%display mask name
RType=strmatch(Muscle_Model_Parameters.Recruitment_Type,Recruitment_sfunc,'exact');
switch RType
    case 2
        blockName = 'disp(''Natural \n Discrete \n (S-Function)'') ';
    case 3
        blockName = 'disp(''Natural \n Continuous \n (S-Function)'') ';
    case 4
        blockName = 'disp(''Intramuscular \n FES \n (S-Function)'') ';
end

%name ports
%input ports
if RType == 4
    iPort = ['port_label(''input'', 1,''Activation'') '...
             'port_label(''input'', 2,''MT path length (m)'') '...
             'port_label(''input'', 3,''Frequency (pps)'') '];
else
    iPort = ['port_label(''input'', 1, ''Activation'') '...
             'port_label(''input'', 2, ''MT path length (m)'') '];
end


%output ports
oPortnum = 1;
oPort = 'port_label(''output'',1,''Force (N)'') ';

if strmatch('Activation', Muscle_Model_Parameters.Additional_Outports, 'exact')
    oPortnum = oPortnum + 1;
    oPort = [oPort 'port_label(''output'',' num2str(oPortnum) ',''Activation Out'') '];
end

if strmatch('Force (Fo)', Muscle_Model_Parameters.Additional_Outports, 'exact')
    oPortnum = oPortnum + 1;
    oPort = [oPort 'port_label(''output'',' num2str(oPortnum) ',''Force (F0)'') '];
end

if strmatch('Fascicle Length (Lo)', Muscle_Model_Parameters.Additional_Outports, 'exact')
    oPortnum = oPortnum + 1;
    oPort = [oPort 'port_label(''output'',' num2str(oPortnum) ',''Lce (L0)'') '];
end

if strmatch('Fascicle Velocity (Lo/s)', Muscle_Model_Parameters.Additional_Outports, 'exact')
    oPortnum = oPortnum + 1;
    oPort = [oPort 'port_label(''output'',' num2str(oPortnum) ',''Vce (L0/s)'') '];
end

mdisplay = [iPort oPort blockName];

%wait for user to click OK
for i=1:600
    pause(1);
    prts=get_param(sys,'Ports');
    if prts(1)>1
       break;
    end
end

%you have to set display after user input to get both ports!
set_param(sys,'MaskDisplay',mdisplay);



        



    
    
    
    


            
           
            
        
        
      	
