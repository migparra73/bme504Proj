%CreateSimulinkBlock     Version 3.1.5

%Creates a single muscle block in Simuilnk

%There are two main structures that store the USER DATA: Muscle_Morph and Muscle_Model_Parameters
%These are described in BuildMuscles.m

%CREATE one NEW SIMULINK Muscle_Block
%This function creates all aspects of a MUSCLE BLOCK, including all sub-blocks

function systemname=CreateSimulinkBlock(musclenumber)
global Muscle_Morph   BM_Fiber_Type_Database   Muscle_Model_Parameters
	
    systemhandle=new_system;				   %Make main system
	systemname=get_param(systemhandle,'name');	%open_system(systemhandle);
    sys=[systemname,'/',Muscle_Morph(musclenumber).Muscle_Name];
   
    add_block('built-in/SubSystem',sys);
	set_param(sys,'Location',[50,150,1000,700])
    
	%Make stuff inside main system
    Create_Whole_Muscle_Mass_Block([sys,'/muscle mass'], musclenumber);
  	set_param([sys,'/muscle mass'],'orientation','down','position',[590,255,665,430]);

    Create_Whole_Muscle_CE_Block([sys,'/fascicles (CE & PE)'], musclenumber);
 	set_param([sys,'/fascicles (CE & PE)'],'position',[355,162,535,218]);
    
    Create_Whole_Muscle_SE_Block([sys,'/series elastic element'], musclenumber);
 	set_param([sys,'/series elastic element'],'orientation','left','position',[660,160,760,210]);
      
    specialportname=Create_Whole_Muscle_Recruitment([sys,'/Recruitment'],musclenumber);
    set_param([sys,'/Recruitment'], 'position', [150,120,320,170]);
    
    %Modified by Giby to convert input port reading from m to cm 2/18/8
    add_block('built-in/Gain',[sys,'/Convert m to cm'])
    set_param([sys,'/Convert m to cm'],...
           'orientation','left',...
		   'Gain',num2str(100),...
		   'position',[860,155,900,195]);

          
    %the order in which there ports are created is important, because the 'special' port pushes the other
    %2 down one if it is created.
    add_block('built-in/Inport',[sys,'/Activation'])
	set_param([sys,'/Activation'],...
			'Port','1',...
         'position',[80,135,100,155])

    add_block('built-in/Inport',[sys,['/MT path length (m)']])
	set_param([sys,['/MT path length (m)']],...
			'orientation','left',...
			'Port','2',...
         'position',[960,165,980,185],...
         'nameplacement', 'alternate')
	
   if ~strcmp(specialportname,'unused')		%only add this port if it will be used
	   add_block('built-in/Inport',[sys,'/' specialportname]);
		set_param([sys,'/' specialportname],...
				'Port','1',...
	         'position',[80,180,100,200]);
  		add_line(sys,[specialportname '/1'],'Recruitment/2');
   	set_param([sys,'/Recruitment'], 'position', [150,120,320,210]);
   end
      
	add_block('built-in/Outport',[sys,'/Force (N)'])
	set_param([sys,'/Force (N)'],...
			'orientation','right',...
			'position',[700,115,720,135])
      
	if strmatch('Activation', Muscle_Model_Parameters.Additional_Outports, 'exact')
 		add_block('built-in/Outport',[sys,'/Activation Out'])
		set_param([sys,'/Activation Out'],...
			'orientation','right',...
         'position',[150,65,170,85],...
         'nameplacement', 'alternate');
      add_line(sys,'Activation/1','Activation Out/1');			%Activation to ...
   end
   
   if strmatch('Force (Fo)', Muscle_Model_Parameters.Additional_Outports, 'exact')
     	add_block('built-in/Gain',[sys,'/Convert to F0'])
		set_param([sys,'/Convert to F0'],...
		   'Gain',num2str(1/Muscle_Morph(musclenumber).F0),...
         'position',[700,60,780,90],...
         'nameplacement', 'alternate');
 		add_block('built-in/Outport',[sys,'/Force (F0)'])
		set_param([sys,'/Force (F0)'],...
			'orientation','right',...
			'position',[820,65,840,85],...
	      'nameplacement', 'alternate');
		add_line(sys,[630,190;630,125;630,75;700,75])	% to converter
		add_line(sys,'Convert to F0/1','Force (F0)/1')	% to Force (F0)
   end
   
	if strmatch('Fascicle Length (Lo)', Muscle_Model_Parameters.Additional_Outports, 'exact')
 		add_block('built-in/Outport',[sys,'/Lce (L0)'])
		set_param([sys,'/Lce (L0)'],...
			'orientation','down',...
         'position',[640,480,660,500],...
         'nameplacement', 'normal');
      add_line(sys,'muscle mass/2','Lce (L0)/1');		
   end
         
	if strmatch('Fascicle Velocity (Lo/s)', Muscle_Model_Parameters.Additional_Outports, 'exact')
 		add_block('built-in/Outport',[sys,'/Vce (L0//s)'])
		set_param([sys,'/Vce (L0//s)'],...
			'orientation','down',...
	      'position',[600,480,620,500],...
	      'nameplacement', 'alternate');
	   add_line(sys,'muscle mass/1','Vce (L0//s)/1');		
   end
   
 	if strmatch('Rate of Energy Consumption (W)', Muscle_Model_Parameters.Additional_Outports, 'exact')
 		add_block('built-in/Outport',[sys,'/Energy Rate(W)'])
		set_param([sys,'/Energy Rate(W)'],...
			'orientation','down',...
	      'position',[530,250,550,270],...
	      'nameplacement', 'alternate');
	   add_line(sys,'fascicles (CE & PE)/2','Energy Rate(W)/1');		
   end
   
 	if strmatch('Power produced by Muscle (W)', Muscle_Model_Parameters.Additional_Outports, 'exact')
 		add_block('built-in/Product',[sys,'/Power'])
      set_param([sys,'/Power'],...
			'orientation','down',...
         'position',[550,315,570,335]);
 		add_block('built-in/Gain',[sys,'/Lo to m'])
      set_param([sys,'/Lo to m'],...
         'Gain',num2str(Muscle_Morph(musclenumber).L0/100),...
         'position',[450,285,500,315]);
 		add_block('built-in/Outport',[sys,'/Power (W)'])
		set_param([sys,'/Power (W)'],...
			'orientation','down',...
	      'position',[550,370,570,390],...
	      'nameplacement', 'alternate');
   	add_line(sys,[340,300;450,300])   	%MM Velocity to CE and PE
	   add_line(sys,'fascicles (CE & PE)/1','Power/2');		
	   add_line(sys,'Lo to m/1','Power/1');		
	   add_line(sys,'Power/1','Power (W)/1');		
   end
   
   %set the size of muscle block to accomodate the number of ports
   numports=get_param(sys,'ports');
   size=max(numports(1), numports(2));
   switch size
      case 2
         set_param(sys,'position',[150,130,350,170])
      case 3
         set_param(sys,'position',[150,130,350,190])
      case 4
         set_param(sys,'position',[150,130,350,200])
      case 5
         set_param(sys,'position',[150,130,350,210])
      case 6
         set_param(sys,'position',[150,130,350,220])
      case 7
         set_param(sys,'position',[150,130,350,240])
      otherwise
         set_param(sys,'position',[150,130,350,170])
      end
         
   %connect all sub-blocks together
    add_line(sys,[960,175;900,175])	%Modified by Giby to convert input port reading from m to cm 2/18/8
	add_line(sys,[660,190;630,190])				%SE to ...
	add_line(sys,[630,190;630,250])				% to Muscle Mass
	add_line(sys,[630,190;630,125;700,125])	% to Force (N)
   
   add_line(sys,'fascicles (CE & PE)/1','muscle mass/1')
   
   add_line(sys,[650,435;650,455])						%MM length to ...
   add_line(sys,[650,455;330,455;330,190;350,190])	% to CE and PE
   add_line(sys,[650,455;790,455;790,200;760,200])	% to SE
   
   add_line(sys,[610,435;610,445;340,445;340,300])   	%MM Velocity to CE and PE
   add_line(sys,[340,300;340,210;350,210])   			%MM Velocity to CE and PE
   add_line(sys,'Recruitment/1','fascicles (CE & PE)/1')			%Recruitment to ...
	add_line(sys,[860,175;820,175])							%Path length to ...
   add_line(sys,[820,175;760,175])							%to SE
   add_line(sys,[820,175;820,235;655,235;655,250])		%to MM
   
   add_line(sys,'Activation/1','Recruitment/1')			%Activation to ...
   
   blocklist=find_system(systemname);
	for blocknumber=2:length(blocklist)
	   set_param(blocklist{blocknumber},'fontsize','12');
    end
    
   %set_param(sys,'Name','Giby');
    
	%Done all sub-systems
    %End of CreateSimulinkBlock
   
   

%CREATE one NEW SIMULINK Recruitment Block
%This function creates all aspects of a Recruitment BLOCK, including all sub-blocks
function [specialportname]=Create_Whole_Muscle_Recruitment(sys,musclenumber)
global Muscle_Morph   BM_Fiber_Type_Database   Muscle_Model_Parameters
   add_block('built-in/SubSystem',sys);
   
   TotalNumberUnits=sum(Muscle_Morph(musclenumber).Number_Units);
   top=TotalNumberUnits*32+45;
   
   add_block('built-in/Inport',[sys,'/Activation'])
	set_param([sys,'/Activation'],...
			   'position',[40,top-20,60,top])
         
   add_block('built-in/Outport',[sys,'/Frequencies (f0.5)'])
	set_param([sys,'/Frequencies (f0.5)'],...
			'orientation','right',...
			'position',[600,top,620,top+20])
      
   %CREATE SIMULINK BLOCKS FOR EACH FiberType within a whole-muscle CE
   %For each new Recruitment Type, the following conventions must be used.
   %1) specialportname must be named
   %2) naming of motor units must be ['Type ' ftdtype ' Motor Unit ' num2str(currentUnit)]
   %   in which ftdtype is the fibertype name, and current Unit is the unit number of THAT fiber type
   %   (The reason for this convention, is that the motor units are multiplexed according to those names
   %    here in this simulink block, and then demuxed elsewhere in the Contractile Element block)
   %3)  Each MU must be created, positioned and attached to the inputs
   % Note: the order in which the units are recruited is irrelevant, because they are positioned elsewhere
   
   switch Muscle_Model_Parameters.Recruitment_Type
   case 'Intramuscular FES',				specialportname='frequency (pps)';
   otherwise,     							specialportname='unused';
   end
   
   if ~strcmp(specialportname,'unused')		%only add this port if it will be used
      add_block('built-in/Inport',[sys '/' specialportname])
		set_param([sys '/' specialportname],...
	   		'Port','2',...
            'position',[40,top+60,60,top+80])
   end
            
   [temp,FTDindex]=sort([BM_Fiber_Type_Database.Recruitment_Rank]);
   switch Muscle_Model_Parameters.Recruitment_Type
   case 'Natural'
      prevpcsa=0;
   	for i=1:length(FTDindex)		%cycle through each fiber type in FT database, in order of natural recruitment
   	   ftdtype=BM_Fiber_Type_Database(FTDindex(i)).Fiber_Type_Name;
   	   %find the Muscle Model index of the fiber type with the lowest recruitment rank
   	   mmdindex=strmatch(ftdtype, Muscle_Model_Parameters.Fiber_Type_Names,'exact');
		   for currentUnit=1:Muscle_Morph(musclenumber).Number_Units(mmdindex)
		      prevpcsa=prevpcsa+Muscle_Morph(musclenumber).Unit_PCSA(currentUnit,mmdindex);%To allow setting of motor unit recruitment thresholds relative to Ur
            MUname=['Type ' ftdtype ' Motor Unit ' num2str(currentUnit)];
   	      Create_MU_Natural_Recruit_Block([sys '/' MUname], BM_Fiber_Type_Database(FTDindex(i)), prevpcsa, musclenumber);
		   	add_line(sys,'Activation/1',[MUname '/1']);
		   end
   	end%Done making all Units
   case 'Intramuscular FES'
      prevpcsa=0;   numberfibertypes=0;
   	for i=1:length(FTDindex)		%cycle through each fiber type in FT database, in order of natural recruitment
   	   ftdtype=BM_Fiber_Type_Database(FTDindex(i)).Fiber_Type_Name;
   	   %find the Muscle Model index of the fiber type with the lowest recruitment rank
         mmdindex=strmatch(ftdtype, Muscle_Model_Parameters.Fiber_Type_Names,'exact');
         if Muscle_Morph(musclenumber).Number_Units(mmdindex)>0
            numberfibertypes=numberfibertypes+1;
            MUdata(numberfibertypes).ftdtype=ftdtype;
            MUdata(numberfibertypes).ftdindex=FTDindex(i);
            %Remove trailing zeros in Unit_PCSA's vector
            tempnum=Muscle_Morph(musclenumber).Number_Units(mmdindex);
            MUdata(numberfibertypes).Unit_PCSA=Muscle_Morph(musclenumber).Unit_PCSA(1:tempnum,mmdindex);
            MUdata(numberfibertypes).Fractional_PCSA=Muscle_Morph(musclenumber).Fractional_PCSA(mmdindex);
            MUdata(numberfibertypes).Runningtotal=0;		%Value between 0 and 1 of current fraction of given
            															% fibertype PCSA that has already been allocated
            MUdata(numberfibertypes).CurrentUnit=0;
         end
    end
      for i=1:TotalNumberUnits
         [temp,index]=min(cat(1,MUdata.Runningtotal));
         MUdata(index).CurrentUnit=MUdata(index).CurrentUnit+1; %Number of PCSA that has already being used
         [minPCSA,minindex]=min(MUdata(index).Unit_PCSA);		%find the smallest unit of that PCSA
		 prevpcsa=prevpcsa+minPCSA;      %To allow setting of motor unit recruitment thresholds relative to Ur
         MUname=['Type ' MUdata(index).ftdtype ' Motor Unit ' num2str(MUdata(index).CurrentUnit)];
         
         %Create the blocks in Simulink      
         Create_MU_Intramuscular_FES_Recruit_Block([sys '/' MUname], BM_Fiber_Type_Database(MUdata(index).ftdindex), prevpcsa, musclenumber);
		 add_line(sys,'Activation/1',[MUname '/1']);
         add_line(sys,[specialportname '/1'],[MUname '/2']);
         
         MUdata(index).Unit_PCSA(minindex)=[];		%clear this unit's data so that it doesn't get used again
         MUdata(index).Runningtotal+minPCSA/MUdata(index).Fractional_PCSA
         MUdata(index).Runningtotal=MUdata(index).Runningtotal+minPCSA/MUdata(index).Fractional_PCSA;
   	end%Done making all Units
   end
   
   %MAKE STUFF INSIDE MAIN SYSTEM
   %add a block to Mux the frequency outputs from all of the units together
   numberfibertypes=sum(Muscle_Morph(musclenumber).Number_Units>0);
   add_block('built-in/Mux',[sys,'/Mux all Units'])
	set_param([sys,'/Mux all Units'],...
   	'inputs',num2str(numberfibertypes),...
   	'position',[540,70,545,TotalNumberUnits*65+30])
	%Connect the outputs of all Motor Units to each MUX properly.
   %First, all motor units of a given type are MUXed together, then the MUXed freq values are MUXed together
   %for the output.  The order of MUXing is by (natural) recruitment order because this is the order in 
   %which the motor units are arranged later in the Contractile Element (CE)
   createdUnits=0;	createdFTs=0;
  	for i=1:length(FTDindex)
  	   ftdtype=BM_Fiber_Type_Database(FTDindex(i)).Fiber_Type_Name;
  	   %find the Muscle Model index of the fiber type with the lowest recruitment rank
      mmdindex=strmatch(ftdtype, Muscle_Model_Parameters.Fiber_Type_Names,'exact');
      numberunits=Muscle_Morph(musclenumber).Number_Units(mmdindex);
      if numberunits>0
         createdFTs=createdFTs+1;
	      MUXname=['Mux all ' ftdtype ' Units'];
	     	add_block('built-in/Mux',[sys '/' MUXname])		%Create one Mux for each fiber type
			set_param([sys '/' MUXname],...
			   	'inputs',num2str(numberunits),...
			   	'position',[420,createdUnits*65+70,425,(numberunits+createdUnits)*65+30])
	      for currentUnit=1:Muscle_Morph(musclenumber).Number_Units(mmdindex)
		      createdUnits=createdUnits+1;	%For proper sequential naming of each motor unit
            MUname=['Type ' ftdtype ' Motor Unit ' num2str(currentUnit)];
            %set position of motor unit recruitment block here
   			set_param([sys '/' MUname],'position',[200,createdUnits*65,350,createdUnits*65+35])
		   	add_line(sys,[MUname '/1'],[MUXname '/' num2str(currentUnit)]);
         end
         add_line(sys,[MUXname '/1'],['Mux all Units/' num2str(createdFTs)]);
      end
   end%Done connecting all Units
   
	add_line([sys,''],'Mux all Units/1','Frequencies (f0.5)/1');
   set_param(sys,'Location',[50,50,750,TotalNumberUnits*65+150])
   %Finished Create_Whole_Muscle_Recruitment



%This function builds a single NATURAL Recruit block for a motor unit which is positioned and attached
%to the rest of the SIMULINK blocks elsewhere.
function Create_MU_Natural_Recruit_Block(sys, FTproperties, PCSA, musclenumber);
global Muscle_Morph

   add_block('built-in/subsystem',sys)
   set_param(sys,'Location',[100,300,900,600])
  
   add_block('built-in/Outport',[sys '/Frequency (f0.5)'])
   set_param([sys '/Frequency (f0.5)'],...
         'Port','1',...
         'position',[600,135,620,155])
      
   add_block('built-in/Inport',[sys '/Activation'])
   set_param([sys '/Activation'],...
         'port','1',...
         'position',[35,135,55,155])
      
   threshold=PCSA*Muscle_Morph(musclenumber).Ur;
   add_block('built-in/Switch',[sys '/Reached recruitment threshold?'])
   set_param([sys '/Reached recruitment threshold?'],...
         'threshold',num2str(max(0.001,threshold)),...
         'position',[480,115,500,175])
      
   add_block('built-in/Fcn',[sys '/determine frequency'])
   set_param([sys '/determine frequency'],...
      'Expr',['((' num2str(FTproperties.Fmax) '-' num2str(FTproperties.Fmin) ')/(1-('...
         	num2str(threshold) ')))*(u(1)-(' num2str(threshold) '))+' num2str(FTproperties.Fmin)],...
      'position',[130,100,440,125])
      
   add_block('built-in/Constant',[sys '/zero'])
   set_param([sys '/zero'],...
         'Value','0',...
         'position',[265,160,285,180])
      
   add_line(sys,'Activation/1','Reached recruitment threshold?/2')
   add_line(sys,'Activation/1','determine frequency/1')
   add_line(sys,'Reached recruitment threshold?/1','Frequency (f0.5)/1');
   add_line(sys,'determine frequency/1','Reached recruitment threshold?/1');
   add_line(sys,'zero/1','Reached recruitment threshold?/3');
	%Finished Create_MU_Natural_Recruit_Block
   
   
   
%This function builds a single Intramuscular FES Recruit block for a motor unit which is positioned and attached
%to the rest of the SIMULINK blocks elsewhere.
function Create_MU_Intramuscular_FES_Recruit_Block(sys, FTproperties, PCSA, musclenumber);
global Muscle_Morph
    
   add_block('built-in/subsystem',sys)
   set_param(sys,'Location',[100,300,900,600])
  
   add_block('built-in/Outport',[sys '/Frequency (f0.5)'])
   set_param([sys '/Frequency (f0.5)'],...
         'Port','1',...
         'position',[600,135,620,155])
      
   add_block('built-in/Inport',[sys '/Activation'])
   set_param([sys '/Activation'],...
         'port','1',...
         'position',[235,135,255,155])
      
   add_block('built-in/Inport',[sys '/Freq. (pps)'])
   set_param([sys '/Freq. (pps)'],...
         'port','2',...
         'position',[295,100,315,120])
      
   add_block('built-in/Gain',[sys '/convert frequency'])
   set_param([sys '/convert frequency'],...
         'Gain',num2str(1/(FTproperties.F0_5)),...
         'position',[370,95,440,125])
      
   add_block('built-in/Switch',[sys '/Reached recruitment threshold?'])
   set_param([sys '/Reached recruitment threshold?'],...
         'threshold',num2str(PCSA),...
         'position',[480,115,500,175])
      
   add_block('built-in/Constant',[sys '/zero'])
   set_param([sys '/zero'],...
         'Value','0',...
         'position',[365,155,385,175])
      
   add_line(sys,'Activation/1','Reached recruitment threshold?/2')
   add_line(sys,'Freq. (pps)/1','convert frequency/1')
   add_line(sys,'Reached recruitment threshold?/1','Frequency (f0.5)/1');
   add_line(sys,'convert frequency/1','Reached recruitment threshold?/1');
   add_line(sys,'zero/1','Reached recruitment threshold?/3');
	%Finished Create_MU_FES_Recruit_Block
   
   
   
%This function makes the Simulink Block for the Whole Muscle mass Element
function Create_Whole_Muscle_Mass_Block(sys, musclenumber)
global Muscle_Morph   BM_Fiber_Type_Database   Muscle_Model_Parameters   BM_FTD_General_Parameters
	add_block('built-in/subsystem',sys)
	set_param(sys,'Location',[250,350,900,550])
  
   add_block('built-in/Inport',[sys,'/Fse (N)'])
	set_param([sys,'/Fse (N)'],...
		   'Port','2',...
			'position',[120,50,140,70])

	add_block('built-in/Inport',[sys,'/Path length [for init] (cm)'])
	set_param([sys,'/Path length [for init] (cm)'],...
			'Port','3',...
			'position',[80,130,100,150])
      
   % The following calculation is for the estimation of the initial muscle mass position
   % It is an ugly equation, and is based on the assumption (which is true for feline muscles)
   % that anywhere in the ROM, the passive force of the muscle is likely to be small.
   % A few tests showed that this estimation is correct with 0.5% at the worst.
   c1=BM_FTD_General_Parameters.c1;
   k1=BM_FTD_General_Parameters.k1;
   Lr1=BM_FTD_General_Parameters.Lr1;
   cT=BM_FTD_General_Parameters.cT;
   kT=BM_FTD_General_Parameters.kT;
   LrT=BM_FTD_General_Parameters.LrT;
   L0=Muscle_Morph(musclenumber).L0;
   L0T=Muscle_Morph(musclenumber).L0T;
   Lmax=Muscle_Morph(musclenumber).Lmax;
   numerator=-L0T*(kT/k1*Lr1-LrT-kT*log(c1/cT*k1/kT));
   denominator=1+kT/k1*L0T/Lmax*1/L0;
	denominator=denominator*100;		%	convert from cm to m...
   
   add_block('built-in/Fcn',[sys,'/Path to init muscle mass position (m)'])
	set_param([sys,'/Path to init muscle mass position (m)'],...
         'Expr',['(u-' num2str(numerator) ')/' num2str(denominator)],...
         'position',[220,130,350,150])
      
	add_block('built-in/Outport',[sys,'/Vce (L0//s)'])
	set_param([sys,'/Vce (L0//s)'],...
			'Port','1',...
			'position',[590,110,610,130])

	add_block('built-in/Outport',[sys,'/Lce (L0)'])
	set_param([sys,'/Lce (L0)'],...
			'Port','2',...
			'position',[590,40,610,60])

	add_block('built-in/Inport',[sys,'/Fce (N)'])
	set_param([sys,'/Fce (N)'],...
			'Port','1',...
			'position',[120,30,140,50])    
            
            
	add_block('built-in/Integrator',[sys,'/Vel to Pos'])%Convert L0 from cm to m
	set_param([sys,'/Vel to Pos'],...
		   'initialconditionsource','external',...
		   'position',[415,40,435,60])

	add_block('built-in/Integrator',[sys,'/Acc to Vel'])
	set_param([sys,'/Acc to Vel'],...
			'position',[325,40,345,60])

	add_block('built-in/Gain',[sys,'/Normalize to L0//s'])%Convert L0 from cm to m
	set_param([sys,'/Normalize to L0//s'],...
			'Gain',['1/' num2str((Muscle_Morph(musclenumber).L0/100))],...
			'position',[490,98,545,142])

	add_block('built-in/Gain',[sys,'/Normalize to L0'])
	set_param([sys,'/Normalize to L0'],...
			'Gain',['1/' num2str((Muscle_Morph(musclenumber).L0/100))],...
			'position',[490,30,545,70])

	add_block('built-in/Gain',[sys,'/Force//Mass=Accel'])%Divide mass by two, and then convert from g to kg
	set_param([sys,'/Force//Mass=Accel'],...
			'Gain',['1/' num2str((Muscle_Morph(musclenumber).Mass/2000))],...
			'position',[230,29,295,71])

	add_block('built-in/Sum',[sys,'/Ftotal'])
	set_param([sys,'/Ftotal'],...
			'inputs','-+',...
			'position',[170,32,200,68])
   %connect all of the block together
   add_line(sys,[205,50;225,50])
	add_line(sys,[300,50;320,50])
	add_line(sys,'Acc to Vel/1','Vel to Pos/1')
	add_line(sys,'Acc to Vel/1','Normalize to L0//s/1')
	add_line(sys,'Path length [for init] (cm)/1','Path to init muscle mass position (m)/1')
	add_line(sys,'Path to init muscle mass position (m)/1','Vel to Pos/2')
	add_line(sys,[440,50;490,50])
	add_line(sys,[145,40;165,40])
	add_line(sys,[545,50;590,50])
	add_line(sys,[145,60;165,60])
	add_line(sys,[545,120;590,120])
	%Finished composite block 'some_muscle/muscle mass'.
      


%This function makes the Simulink Block for the Whole Muscle Series Elastic Element
function Create_Whole_Muscle_SE_Block(sys, musclenumber)
global Muscle_Morph   Muscle_Model_Parameters   BM_FTD_General_Parameters
	add_block('built-in/subsystem',sys)
	set_param(sys,'Location',[65,310,803,510])
	
	add_block('built-in/Inport',[sys,'/Path (cm)'])
	set_param([sys,'/Path (cm)'],...
		   'position',[80,60,100,80])
	
	add_block('built-in/Gain',[sys,'/Convert to N'])
	set_param([sys,'/Convert to N'],...
		   'Gain',num2str(Muscle_Morph(musclenumber).F0),...
		   'position',[605,83,645,107])
	
	add_block('built-in/Gain',[sys,'/Normalize to L0T'])
	set_param([sys,'/Normalize to L0T'],...
		   'Gain',['1/' num2str(max(0.1,Muscle_Morph(musclenumber).L0T))],...
		   'position',[245,81,305,109])
	
	add_block('built-in/Sum',[sys,'/Convert Lce to Lse'])
	set_param([sys,'/Convert Lce to Lse'],...
		   'inputs','+-',...
		   'position',[155,77,185,108])
	
	add_block('built-in/Outport',[sys,'/Fse (N)'])
	set_param([sys,'/Fse (N)'],...
		   'position',[680,85,700,105])
	
	add_block('built-in/Fcn',[sys,'/Fse'])
	set_param([sys,'/Fse'],...
		   'Expr',[num2str(BM_FTD_General_Parameters.cT) '*' num2str(BM_FTD_General_Parameters.kT) '*log(exp((u(1)-' num2str(BM_FTD_General_Parameters.LrT) ')/' num2str(BM_FTD_General_Parameters.kT) ')+1)'],...
		   'position',[325,76,575,114])
	
	add_block('built-in/Gain',[sys,'/Convert to cm'])
	set_param([sys,'/Convert to cm'],...
		   'Gain',num2str(Muscle_Morph(musclenumber).L0),...
		   'position',[70,96,105,124])

	add_block('built-in/Inport',[sys,'/Lce (L0)'])
	set_param([sys,'/Lce (L0)'],...
		   'Port','2',...	
		   'position',[15,100,35,120])
      
   add_line([sys,''],[580,95;600,95])
	add_line([sys,''],[310,95;320,95])
	add_line([sys,''],[190,95;240,95])
	add_line([sys,''],[650,95;675,95])
	add_line([sys,''],[40,110;65,110])
	add_line([sys,''],[110,110;125,110;125,100;150,100])
	add_line([sys,''],[105,70;120,70;120,85;150,85])
	%Finished Create_Whole_Muscle_SE_Block
   
   

%This function makes the Simulink Block for the Whole Muscle fascicles (CE & PE)
function Create_Whole_Muscle_CE_Block(sys, musclenumber);
global Muscle_Morph   BM_Fiber_Type_Database   Muscle_Model_Parameters   BM_FTD_General_Parameters
   add_block('built-in/subsystem',sys)

	add_block('built-in/Inport',[sys,'/Length (L0)'])
   set_param([sys,'/Length (L0)'],...
			'Port','2',...
			'position',[35,80,55,100])

	add_block('built-in/Inport',[sys,'/Frequencies (f0.5)'])
   set_param([sys,'/Frequencies (f0.5)'],...
	      'nameplacement', 'alternate',...
			'position',[250,235,270,255])

	add_block('built-in/Inport',[sys,'/Velocity (L0//s)'])
	set_param([sys,'/Velocity (L0//s)'],...
			'Port','3',...
			'position',[135,40,155,60])

	add_block('built-in/Outport',[sys,'/Force (N)'])
	set_param([sys,'/Force (N)'],...
    	   'position',[1015,90,1035,110])
   
   add_block('built-in/Mux',[sys '/V,L'])
   set_param([sys '/V,L'],...
  	      'inputs','2',...
  	      'position',[310,30,340,110])
      
   GP=BM_FTD_General_Parameters;
   
   add_block('built-in/Fcn',[sys '/Fpe1'])
   set_param([sys '/Fpe1'],...
         'Expr',[num2str(GP.Viscosity) '*u(1)+' num2str(GP.c1) '*' num2str(GP.k1) '*log(exp((u(2)/' num2str(Muscle_Morph(musclenumber).Lmax) '-' num2str(GP.Lr1) ')/' num2str(GP.k1) ')+1)'],...
         'position',[400,55,730,86])
      
   add_block('built-in/Fcn',[sys '/Fpe2'])
   set_param([sys '/Fpe2'],...
         'Expr',[num2str(GP.c2) '*(exp(' num2str(GP.k2) '*(u-' num2str(GP.Lr2) '))-1)'],...
         'position',[75,120,290,150])
      
   add_block('built-in/MinMax',[sys '/Min'])
   set_param([sys '/Min'],...
      	'function','Min',...
      	'Inputs','2',...
         'position',[310,120,340,180])
      
   add_block('built-in/Constant',[sys '/zero2'])
   set_param([sys '/zero2'],...
         'Value','0',...
      	'position',[270,155,290,175])
  
	add_block('built-in/Gain',[sys,'/Convert F0 to N'])
	set_param([sys,'/Convert F0 to N'],...
			'Gain',[num2str(Muscle_Morph(musclenumber).F0)],...
	      'nameplacement', 'alternate',...
			'position',[830,73,890,107])

	add_block('built-in/MinMax',[sys,'/Force>0'])
   set_param([sys,'/Force>0'],...
      	'function','Max',...
      	'Inputs','2',...
      	'position',[930,80,970,120])

   add_block('built-in/Constant',[sys '/zero'])
   set_param([sys '/zero'],...
         'Value','0',...
      	'position',[890,100,910,120])
  
   %CREATE SIMULINK BLOCKS FOR EACH FiberType within whole-muscle CE
   [temp,ftdindex]=sort([BM_Fiber_Type_Database.Recruitment_Rank]);
   numberFiberTypesUsed=0;   numberUnits=[];
   for i=1:length(ftdindex)
      ftdtype=BM_Fiber_Type_Database(ftdindex(i)).Fiber_Type_Name;
      %find the Muscle Model index of the fiber type with the lowest recruitment rank
      mmdindex=strmatch(ftdtype, Muscle_Model_Parameters.Fiber_Type_Names,'exact');
      if Muscle_Morph(musclenumber).Number_Units(mmdindex)>0
         numberFiberTypesUsed=numberFiberTypesUsed+1;
         numberUnits(numberFiberTypesUsed)=Muscle_Morph(musclenumber).Number_Units(mmdindex);
         blockname{numberFiberTypesUsed}=['Type ' ftdtype ' Motor Units'];
         newsys=[sys '/' blockname{numberFiberTypesUsed}];
         Create_Single_FiberType_CE_Block(newsys, musclenumber, ftdindex(i), mmdindex)
  			set_param(newsys,'position',[450,numberFiberTypesUsed*65+150,550,numberFiberTypesUsed*65+185]);
      end
   end%Done making all Units
   
	%add a block to Demux the frequency inputs for the motor units
	add_block('built-in/Demux',[sys,'/Demux all Units'])
	set_param([sys,'/Demux all Units'],...
   			'outputs', ['[' num2str(numberUnits) ']'],...
   			'position',[335,190,340,numberFiberTypesUsed*65+190])

   %add a block to sum the forces from all of the units together
	add_block('built-in/Sum',[sys,'/Sum all Units (F0)'])
	set_param([sys,'/Sum all Units (F0)'],...
   			'inputs',repmat(['+'],1,numberFiberTypesUsed),...
   			'position',[600,200,610,numberFiberTypesUsed*65+200])

   %add a block to sum the active and passive forces together
	add_block('built-in/Sum',[sys,'/Sum Forces (F0)'])
	set_param([sys,'/Sum Forces (F0)'],...
   			'inputs','2',...
      		'nameplacement', 'alternate',...
   			'position',[770,50,780,120])

   for block=1:numberFiberTypesUsed
	   add_line(sys,['Demux all Units/' num2str(block)],[blockname{block} '/1']);
	   add_line(sys,'V,L/1',[blockname{block} '/2']);
	   add_line(sys,'Min/1',[blockname{block} '/3']);
	   add_line(sys,[blockname{block} '/1'],['Sum all Units (F0)/' num2str(block)]);
   end
   add_line(sys,'Length (L0)/1','Fpe2/1');
   add_line(sys,'Velocity (L0//s)/1','V,L/1');
   add_line(sys,'Length (L0)/1','V,L/2');
   add_line(sys,'Fpe2/1','Min/1');
   add_line(sys,'zero2/1','Min/2');
   add_line(sys,'V,L/1','Fpe1/1');
	add_line(sys,'Frequencies (f0.5)/1','Demux all Units/1');
	add_line(sys,'Convert F0 to N/1','Force>0/1');
	add_line(sys,'zero/1','Force>0/2');
	add_line(sys,'Force>0/1','Force (N)/1');
	add_line(sys,'Fpe1/1','Sum Forces (F0)/1');
	add_line(sys,'Sum all Units (F0)/1','Sum Forces (F0)/2');
	add_line(sys,'Sum Forces (F0)/1','Convert F0 to N/1');
   
  	if strmatch('Rate of Energy Consumption (W)', Muscle_Model_Parameters.Additional_Outports, 'exact')
		%add a block to Demux the frequency inputs for the motor units
		add_block('built-in/Demux',[sys,'/Force, Energy'])
		set_param([sys,'/Force, Energy'],...
   				'outputs', '2',...
   				'position',[650,215,700,235])
		add_block('built-in/Gain',[sys,'/Convert F0*Lo//s to W'])
		set_param([sys,'/Convert F0*Lo//s to W'],...
				'Gain',[num2str(Muscle_Morph(musclenumber).F0*Muscle_Morph(musclenumber).L0/100)],...
				'position',[830,215,890,245])
 	 	add_block('built-in/Outport',[sys,'/Energy Rate (W)'])
		set_param([sys,'/Energy Rate (W)'],...
    		   'position',[1015,220,1035,240])
      delete_line(sys,'Sum all Units (F0)/1','Sum Forces (F0)/2');
      	add_line(sys,'Sum all Units (F0)/1','Force, Energy/1');
      	add_line(sys,'Force, Energy/1','Sum Forces (F0)/2');
		add_line(sys,'Force, Energy/2','Convert F0*Lo//s to W/1');
		add_line(sys,'Convert F0*Lo//s to W/1','Energy Rate (W)/1');
   end 
   
   %Size and Position of this block (needs to be at end so the numberFiberTypesUsed exists)
	set_param(sys,'Location',[5,255,1100,numberFiberTypesUsed*65+500])
	%Finished Create_Whole_Muscle_CE_Block
  


%CREATE A BLOCK FOR all Motor units of a single fiber type 
function Create_Single_FiberType_CE_Block(sys, musclenumber, ftdindex, mmdindex)
global Muscle_Morph   BM_Fiber_Type_Database   Muscle_Model_Parameters   BM_FTD_General_Parameters

	add_block('built-in/subsystem',sys)
   set_param(sys,'Location',[10,45,1200,700])
   
	add_block('built-in/Inport',[sys,'/fenv'])
	set_param([sys,'/fenv'],...
			'position',[615,195,635,215])

   add_block('built-in/Inport',[sys,'/V,L'])
	set_param([sys,'/V,L'],...
      	'Port','2',...
			'position',[10,270,30,290])

	add_block('built-in/Inport',[sys,'/Fpe2'])
	set_param([sys,'/Fpe2'],...
			'Port','3',...
			'position',[240,20,260,40])

	add_block('built-in/Outport',[sys,'/F (Fo)'])
	set_param([sys,'/F (Fo)'],...
    	   'position',[1150,35,1170,55])
       
   numberUnits=Muscle_Morph(musclenumber).Number_Units(mmdindex);
	%add a block to Demux the frequency inputs for the motor units
	add_block('built-in/Demux',[sys,'/Demux all Units'])
	set_param([sys,'/Demux all Units'],...
   		'outputs',num2str(numberUnits),...
   		'position',[665,110,670,numberUnits*65+110])
   
   %add a block to sum the forces from all of the units together
	add_block('built-in/Sum',[sys,'/Sum all Units'])
	set_param([sys,'/Sum all Units'],...
   		'inputs',repmat(['+'],1,numberUnits),...
   		'position',[980,120,990,numberUnits*65+120])

   %Create the model elements that are common to all motor units of a single fiber type.
   FTproperties=BM_Fiber_Type_Database(ftdindex);
   
   add_block('built-in/Fcn',[sys '/FL'])
   set_param([sys '/FL'],...
  	      'Expr',['exp(-abs((u^' num2str(FTproperties.FL_beta) '-1)/' num2str(FTproperties.FL_omega) ')^' num2str(FTproperties.FL_rho) ')'],...
  	      'position',[170,230,200,260])
      
   add_block('built-in/Demux',[sys '/split V,L'])
   set_param([sys '/split V,L'],...
  	      'outputs','2',...
  	      'position',[50,220,110,250])
      
   add_block('built-in/Fcn',[sys '/FV (lengthen)'])
   set_param([sys '/FV (lengthen)'],...
         'Expr',['(' num2str(FTproperties.bV) '-(' num2str(FTproperties.aV0) '+' num2str(FTproperties.aV1) '*u(2)+' num2str(FTproperties.aV2) '*u(2)^2)*u(1))/(' num2str(FTproperties.bV) '+u(1))'],...
         'position',[50,40,130,70])
      
   add_block('built-in/Fcn',[sys '/FV (shorten)'])
   set_param([sys '/FV (shorten)'],...
  	      'Expr',['(' num2str(FTproperties.Vmax) '-u(1))/(' num2str(FTproperties.Vmax) '+(' num2str(FTproperties.cV0) '+' num2str(FTproperties.cV1) '*u(2))*u(1))'],...
  	      'position',[50,125,130,155])
        
   add_block('built-in/Switch',[sys '/v > 0?'])
   set_param([sys '/v > 0?'],...
  	      'position',[170,115,200,145])
      
   add_block('built-in/Product',[sys '/FL*FV'])
   set_param([sys '/FL*FV'],...
         'inputs','2',...
         'position',[260,120,300,150])
      
   add_block('built-in/Sum',[sys '/PE+FL*FV'])
   set_param([sys '/PE+FL*FV'],...
         'inputs','++',...
         'position',[320,20,370,55])
      
   add_block('built-in/Mux',[sys '/Y,L'])
   set_param([sys '/Y,L'],...
  	      'inputs','2',...
  	      'position',[620,55,670,100])
        
   add_block('built-in/Product',[sys '/Af*(FL*FV+PE2)'])
   set_param([sys '/Af*(FL*FV+PE2)'],...
         'inputs','2',...
         'position',[1020,30,1100,55])
      
   %If cY=0, then there is no yielding in this fiber, so dont' include that element     
   if FTproperties.cY==0	
		add_block('built-in/Constant',[sys '/Constant'])
	   set_param([sys '/Constant'],...
	         'value', '1',...
	         'position',[525,355,550,375])
   		add_line(sys,'Constant/1','Y,L/1');
   else
	   add_block('built-in/Fcn',[sys '/yield'])
	   set_param([sys '/yield'],...
	  	      'Expr',['1-' num2str(FTproperties.cY) '*(1-exp(-abs(u)/' num2str(FTproperties.VY) '))'],...
	  	      'position',[190,345,370,375])
	        
	   add_block('built-in/Sum',[sys '/newY-oldY'])
	   set_param([sys '/newY-oldY'],...
	         'inputs','+-',...
	         'position',[400,355,420,375])
	      
	   add_block('built-in/Gain',[sys '/1//Ty'])
	   set_param([sys '/1//Ty'],...
	         'Gain',num2str(1/(FTproperties.TY/1000)),...
	         'position',[440,345,510,385])
	      
		add_block('built-in/Integrator',[sys '/y''->y'])
	   set_param([sys '/y''->y'],...
	         'InitialCondition','1',...
	         'position',[525,355,550,375])
      
      add_line(sys,'split V,L/1','yield/1');
 		add_line(sys,'yield/1','newY-oldY/1');
  		add_line(sys,'newY-oldY/1','1//Ty/1');
   	add_line(sys,'1//Ty/1','y''->y/1');
   	add_line(sys,[555,365;555,395;385,395;390,370])	%from y'=>y to +-
   	add_line(sys,'y''->y/1','Y,L/1');
   end
         
   %create all motor units of the current fiber type
   for currentUnit=1:numberUnits
      MUsys=[sys,'/Motor Unit ' num2str(currentUnit)];
      Create_MU_CE_Block(MUsys, FTproperties, musclenumber);     
    	set_param(MUsys,'position',[730,currentUnit*65+70,850,currentUnit*65+105])
      %Scale force output of each block by its PCSA
      add_block('built-in/Gain',[sys,'/PCSA ' num2str(currentUnit)])
  	   set_param([sys,'/PCSA ' num2str(currentUnit)],...
  	   	   'gain',num2str(Muscle_Morph(musclenumber).Unit_PCSA(currentUnit,mmdindex)),...
     	   		'position',[870,currentUnit*65+70,950,currentUnit*65+105])
		add_line(sys,'Y,L/1',['Motor Unit ' num2str(currentUnit) '/2']);
	   add_line(sys,['Demux all Units/' num2str(currentUnit)],['Motor Unit ' num2str(currentUnit) '/1']);
	   add_line(sys,['Motor Unit ' num2str(currentUnit) '/1'],['PCSA ' num2str(currentUnit) '/1']);
	   add_line(sys,['PCSA ' num2str(currentUnit) '/1'],['Sum all Units/' num2str(currentUnit)]);
   end%Done making motor units of current fiber type
   
   %connect all of the blocks together
  	add_line(sys,'Fpe2/1','PE+FL*FV/1');
	add_line(sys,'V,L/1','FV (lengthen)/1');
	add_line(sys,'V,L/1','FV (shorten)/1');
	add_line(sys,'V,L/1','split V,L/1');
 	add_line(sys,'FV (lengthen)/1','v > 0?/1');
  	add_line(sys,'FV (shorten)/1','v > 0?/3');
   add_line(sys,'split V,L/2','FL/1');
  	add_line(sys,'FL/1','FL*FV/2');
  	add_line(sys,'split V,L/1','v > 0?/2');
  	add_line(sys,'v > 0?/1','FL*FV/1');
  	add_line(sys,'FL*FV/1','PE+FL*FV/2');
  	add_line(sys,'PE+FL*FV/1','Af*(FL*FV+PE2)/1');
   add_line(sys,[115,245;115,430;605,430;615,95])	%from splitV, L to Mux(PE+FL,FV,L)
   add_line([sys,''],'fenv/1','Demux all Units/1');
	add_line(sys,'Sum all Units/1','Af*(FL*FV+PE2)/2');
	add_line(sys,'Af*(FL*FV+PE2)/1','F (Fo)/1');
   
   if strmatch('Rate of Energy Consumption (W)', Muscle_Model_Parameters.Additional_Outports, 'exact')
	   add_block('built-in/Mux',[sys '/FV, FL, V, L'])
	   set_param([sys '/FV, FL, V, L'],...
            'inputs', '3',...
            'DisplayOption','bar',...
	  	      'position',[260,195,265,295])
	   add_block('built-in/Switch',[sys '/V > 0?'])
   		set_param([sys '/V > 0?'],...
  	   	   'position',[470,200,500,230])
	   add_block('built-in/Fcn',[sys '/Energy (lengthen)'])
	   set_param([sys '/Energy (lengthen)'],...
	         'Expr',['(' num2str(FTproperties.bV) '-(' num2str(FTproperties.aV0) '+' num2str(FTproperties.aV1) '*u(2)+' num2str(FTproperties.aV2) '*u(2)^2)*u(1))/(' num2str(FTproperties.bV) '+u(1))'],...
	         'position',[320,190,430,220])
   		add_block('built-in/Fcn',[sys '/Energy (shorten)'])
		set_param([sys '/Energy (shorten)'],...
  	   	   'Expr',['(' num2str(FTproperties.Vmax) '-u(1))/(' num2str(FTproperties.Vmax) '+(' num2str(FTproperties.cV0) '+' num2str(FTproperties.cV1) '*u(2))*u(1))'],...
  	   	   'position',[320,260,430,290])
	   add_block('built-in/Mux',[sys '/Force & Energy'])
	   set_param([sys '/Force & Energy'],...
            'inputs', '2',...
            'DisplayOption','bar',...
	  	      'position',[550,20,555,50])
	  	add_line(sys,'v > 0?/1','FV, FL, V, L/1');
	  	add_line(sys,'FL/1','FV, FL, V, L/2');
	  	add_line(sys,'V,L/1','FV, FL, V, L/3');
	   add_line(sys,'FV, FL, V, L/1','Energy (lengthen)/1')				
	   add_line(sys,'FV, FL, V, L/1','Energy (shorten)/1')				
	   add_line(sys,'Energy (lengthen)/1', 'V > 0?/1')					
   	add_line(sys,[115,230;175,175;435,175;470,215])	%from splitV, L to Mux(PE+FL,FV,L)
	   add_line(sys,'Energy (shorten)/1', 'V > 0?/3')				
	  	delete_line(sys,'PE+FL*FV/1','Af*(FL*FV+PE2)/1');
	  	add_line(sys,'PE+FL*FV/1','Force & Energy/1');
	   add_line(sys,'V > 0?/1','Force & Energy/2')				
	  	add_line(sys,'Force & Energy/1','Af*(FL*FV+PE2)/1');
   end 
  	%Finish Creating a single fiber type CE block
     


%CREATE a single MOTOR UNIT 'fascicles (CE & PE)'
%This function creates all of the sub-elements that are specific to a each motor unit, 
%such as rise/fall times, and puts the appropriate parameters in and connects of them together.  
function	Create_MU_CE_Block(sys, FTproperties, musclenumber);
global Muscle_Morph   Muscle_Model_Parameters
	add_block('built-in/subsystem',sys)
   set_param(sys,'Location',[5,100,1020,650])
   
   add_block('built-in/Inport',[sys '/fenv'])
   set_param([sys '/fenv'],...
         'Port','1',...
         'position',[50,415,70,435])
      
   add_block('built-in/Inport',[sys '/Y,L'])
   set_param([sys '/Y,L'],...
      		'orientation','down',...
         'Port','2',...
         'position',[10,20,30,40])
      
   add_block('built-in/Outport',[sys '/A'])
   set_param([sys '/A'],...
         'position',[965,195,985,215])
      
   add_block('built-in/Demux',[sys '/demux Y,L'])
   set_param([sys '/demux Y,L'],...
      		'outputs', '2',...
         'position',[35,100,40,155])
      
   add_block('built-in/Mux',[sys '/Leff,L,',13,' Af,fenv'])
   set_param([sys '/Leff,L,',13,' Af,fenv'],...
  	      'position',[90,327,125,363])
      
   add_block('built-in/Fcn',[sys '/1//Tf (feff'' < 0)'])
   set_param([sys '/1//Tf (feff'' < 0)'],...
         'Expr',['u(2)/(' num2str(FTproperties.Tf3/1000) '+' num2str(FTproperties.Tf4/1000) '*u(3))'],...
         'position',[165,330,355,360])
      
   add_block('built-in/Fcn',[sys '/1//Tf (feff'' > 0)'])
   set_param([sys '/1//Tf (feff'' > 0)'],...
         'Expr',['1/(' num2str(FTproperties.Tf1/1000) '*u(2)^2+' num2str(FTproperties.Tf2/1000) '*u(4))'],...
         'position',[165,259,355,291])
      
   add_block('built-in/Sum',[sys '/fenv-fint'])
   set_param([sys '/fenv-fint'],...
         'inputs','+-',...
         'position',[120,420,140,440])
      
   add_block('built-in/Product',[sys '/fint'''])
   set_param([sys '/fint'''],...
         'position',[180,407,210,438])
     
   add_block('built-in/Integrator',[sys '/fint''->fint'])
   set_param([sys '/fint''->fint'],...
         'position',[240,415,265,435])
      
   add_block('built-in/Sum',[sys '/fint-feff'])
  	set_param([sys '/fint-feff'],...
         'inputs','+-',...
     	   'position',[325,420,345,440])
      
   add_block('built-in/Switch',[sys '/feff'' > 0?'])
   set_param([sys '/feff'' > 0?'],...
         'position',[390,320,420,350])
	      
   add_block('built-in/Product',[sys '/feff'''])
   set_param([sys '/feff'''],...
         'position',[440,407,470,438])
      
   add_block('built-in/Integrator',[sys '/feff''->feff'])
   set_param([sys '/feff''->feff'],...
         'position',[490,413,515,437])
      
   add_block('built-in/Fcn',[sys '/Leff'''])
   set_param([sys '/Leff'''],...
  	      'Expr',['(u(2)-u(1))^3/((1-u(3))*' num2str(FTproperties.TL/1000) ')'],...
  	      'position',[165,181,340,219])
      
   add_block('built-in/Integrator',[sys '/Leff''->Leff'])
   set_param([sys '/Leff''->Leff'],...
         'InitialCondition','1',...
         'position',[360,185,385,215])
	      
   add_block('built-in/Fcn',[sys '/nf'])
   set_param([sys '/nf'],...
         'Expr',[num2str(FTproperties.nf0) '+' num2str(FTproperties.nf1) '*(1/u-1)'],...
         'position',[425,181,535,219])
      
   add_block('built-in/Fcn',[sys '/Af'])
   set_param([sys '/Af'],...
         'Expr',['1-exp(-(u(1)*u(4)*u(3)/(' num2str(FTproperties.af) '*u(2)))^u(2))'],...
         'position',[650,185,900,225])
      
   add_block('built-in/Mux',[sys '/Y,nf,feff,S'])
   set_param([sys '/Y,nf,feff,S'],...
         'position',[595,187,630,223])
      
   %connect all of the blocks together
   add_line(sys,'Y,L/1','demux Y,L/1')
   add_line(sys,[45,115;580,115;585,190])							%demux to Mux (Y,nf,feff,S)
   add_line(sys,'demux Y,L/2',['Leff,L,',13,' Af,fenv/2'])
   add_line(sys,['Leff,L,',13,' Af,fenv/1'],'1//Tf (feff'' < 0)/1')	%Mux (Leff, L, Af, fenv) to 1/Tf (feff' <0)
   add_line(sys,[140,345;140,200;160,200])						%Mux (Leff, L, Af, fenv) to Leff')
   add_line(sys,[140,275;160,275])									%Mux (Leff, L, Af, fenv) to 1/Tf (feff' >0)
   add_line(sys,'1//Tf (feff'' > 0)/1','feff'' > 0?/1')		
   add_line(sys,'1//Tf (feff'' < 0)/1','feff'' > 0?/3')		
   add_line(sys,'fenv/1','fenv-fint/1')							%fenv to fenv-fint
   add_line(sys,'fenv-fint/1','fint''/2')							%fenv-fint to fint'
   add_line(sys,'fint''/1','fint''->fint/1')						%fint' to fint'->fint
   add_line(sys,'fint''->fint/1','fint-feff/1')					%fint'=>fint to fint-feff
   add_line(sys,[270,425;270,460;100,460;100,435;115,435])	%fint'->fint to fenv-fint
   add_line(sys,'fint-feff/1','feff''/2')							%fint-feff to feff'
   add_line(sys,[365,430;365,335;385,335])						%fint-feff to feff'>0?
   add_line(sys,'feff'' > 0?/1','feff''/1')						%feff'>0 to feff'
   add_line(sys,[425,335;425,375;165,375;175,415])				%feff'>0 to fint'
   add_line(sys,'feff''/1','feff''->feff/1')						%feff' to feff'->feff
   add_line(sys,[520,425;550,425;550,210;590,210])				%feff'->feff to Mux (Y,nf,feff,S)
   add_line(sys,[550,425;550,460;310,460;320,435])				%feff'->feff to fint-feff
   add_line(sys,'Y,nf,feff,S/1','Af/1')							%Mux (Y,nf,feff,S) to AF
   add_line(sys,[905,205;905,490;30,490;30,350;85,350])		%Af to Mux (Leff, L, Af, fenv)
   add_line(sys,'Leff''/1','Leff''->Leff/1')						%Leff' to Leff'->Leff
   add_line(sys,[390,200;405,200;405,150;75,150;85,330])		%Leff'->Leff to Mux (Leff, L, Af, fenv)
   add_line(sys,'Leff''->Leff/1','nf/1')							%Leff'->Leff to nf
   add_line(sys,'nf/1','Y,nf,feff,S/2')							%nf to Mux (Y,nf,feff,S)
   add_line(sys,'fenv/1',['Leff,L,',13,' Af,fenv/4'])			%fenv to Mux (Leff, L, Af, fenv)
   add_line(sys,'Af/1','A/1')											
   
   %If aS1==aS2, then there is no SAG in this fiber, so dont' include that element     
   if FTproperties.aS1==FTproperties.aS2	
      add_block('built-in/Constant',[sys '/aS'])
	   set_param([sys '/aS'],...
	  	      'Value','1',...
	  	      'position',[570,346,610,364])
	   add_line(sys,'aS/1','Y,nf,feff,S/4')						%aS to Mux
   else
      add_block('built-in/Constant',[sys '/aS1'])
	   set_param([sys '/aS1'],...
	  	      'Value',num2str(FTproperties.aS1),...
	  	      'position',[570,346,610,364])
   	   
	   add_block('built-in/Constant',[sys '/aS2'])
	   set_param([sys '/aS2'],...
	  	      'Value',num2str(FTproperties.aS2),...
	  	      'position',[570,291,610,309])
      
	   add_block('built-in/Switch',[sys '/feff>0.1?'])
	   set_param([sys '/feff>0.1?'],...
         	'Threshold', '0.1',...
	  	      'position',[645,305,675,335])
	 	   
	   add_block('built-in/Sum',[sys '/S and old S diff'])
	   set_param([sys '/S and old S diff'],...
	  	      'inputs','-+',...
	  	      'position',[710,305,730,325])
	      
	   add_block('built-in/Gain',[sys '/1//Ts'])
	   set_param([sys '/1//Ts'],...
	  	      'Gain',num2str(1/(FTproperties.TS/1000)),...
	  	      'position',[750,291,820,339])
	      
	   add_block('built-in/Integrator',[sys '/s''->s'])
	   set_param([sys '/s''->s'],...
	  	      'InitialCondition',num2str(FTproperties.aS1),...
	  	      'position',[840,305,865,325])
	   add_line(sys,[550,320;640,320])									%feff'->feff to feff>0.1?
	   add_line(sys,'aS2/1','feff>0.1?/1')								%aS2 to feff>0.1?
	   add_line(sys,'aS1/1','feff>0.1?/3')								%aS1 to feff>0.1?
	   add_line(sys,'feff>0.1?/1','S and old S diff/2')				%feff>0.1 to -+
	   add_line(sys,'S and old S diff/1','1//Ts/1')					%-+ to 1/Ts
	   add_line(sys,'1//Ts/1','s''->s/1')								%1/Ts to s'->s
	   add_line(sys,[870,315;880,315;880,255;695,255;705,310])		%s'->s to -+
	   add_line(sys,[695,255;570,255;570,220;590,220])				%s'->s to Mux (Y,nf,feff,S)
   end
 	%Finished Create_MU_CE_Block
   

