%BuildMuscles     Generates fiber types and saves them to a .MAT file
%KNOWN ISSUES:
%  In order for changes in an editable text box string to be evaluated, the user must either press 
%	return, TAB or somehow else change the active focus in the window to somewhere else (by clicking
%	anywhere else in the window or on another window for example).
%	However, in one specific case,
%	ie clicking on and selecting a menu item, the editable text box string change will not yet be
%	evalutated.  This can cause unusual behaviour; for example, changing the name of a muscle, then
%	going directly to the menu without first pressing enter or clicking elsewhere and choosing Cut
%	Muscle; the list dialog for this will not list the updated change. As soon as the user clicks
%  OK, the changes register. This does not cause any real problems, ie, when saving, although the
%	changes to the last text box have not registered when you go to the menu and choose save, as soon
%	as you click OK or press enter or anything to select the save file name, the changes are registered
%  and the file is saved with the correct data. The only case this causes an issue is with incorrect
%	names being displayed in the list dialog boxes.  Mathworks has recognized this issue (see the help
%	file on UICONTROL, under EDITABLE TEXT BOX), but does not plan to change this behaviour.

%	There are two main structures that store the USER DATA: Muscle_Morph and Muscle_Model_Parameters
%	Muscle_Morph(n) contains the relevant morphometry values for muscle 'n' in the database.  
%	The fields of this structure include:
%  .Muscle_Name		{name of each muscle}
%  .Mass					{mass in g}
%  .L0T					{optimal length of tendon in cm - i.e. length when stressed by 1.0 F0)
%  .L0					{optimal length of fascicles in cm - i.e. length at which 1.0 F0 is produced isometrically}
%  .Muscle_PCSA		{Physiological Cross-sectional area in cm^2- computed from Lo, mass and assumed density of 1.06 g.cm3}
%  .F0					{Optimal isometric force in N- computed from PCSA and specific tension (see Muscle Model Parameters)}
%  .Lpath				{Maximal length of entire MusculoTendon path in cm, limited by anatomical constraints}
%  .Lmax					{Maximal length of fascicles in L0 when whole muscle is at Lpath}
%  .Ur					{Activaiton level at which all motor units in a muscle are recruited (further increase
%						 	in activation result only in increases in firing rate)
%  .Number_Units		{VECTOR: Number of motor units of each fiber types in the muscle}
%  .Fractional_PCSA	{VECTOR: Fraction of total PCSA for each fiber type}
%  .Unit_PCSA			{Array: Fraction of total PCSA for each motor unit (each column represents a single fibertyep)}
%  .Apportion_Method	{VECTOR: Method to apportion the PCSA amongst units of this type}

%	Muscle_Model_Parameters contains information relevant to ALL muscles, including:
%  .Fiber_Type_Database_File
%  .Fiber_Type_Names			{vector of cells}
%	.Recruitment_Type		
%	.Additional_Outports		{Cell array}
%  .Comments
%  .Default_Apportion_Method

%There are two main structures loaded up by Muscle Model which describe the Fiber Type database.

% BM_Fiber_Type_Database contains the FTD information.  These fields are:
% Fiber_Type_Name	
% Recruitment_Rank	{The ranks are used by BuildMuscles to determine in which order motor units
%							 of different types get recruited}
% F0_5					{firing frequency (pps) which produces 0.5 maximal, isometric tetanic tension}
% V0_5					{shortening velocity at which 0.5 maximal, isometric tetanic tension is produced
% Fmax    Fmin			{Fmin is the firing freq. at which motor units of this type get recruited,
%							 Fmax is the freq. at which motor units fire at maximal activation. Both in units of f0.5}
% Comments				{any comments the user wishes to input}
% FL_omega		FL_beta	FL_rho		{constants for the CONTRACTILE force element FL}
% Vmax   cV0	cV1						{constants for the CONTRACTILE force element FV - shortening}
% aV0    aV1	aV2	bV					{constants for the CONTRACTILE force element FV - lengthening}
% af		nf0	nf1						{constants for the CONTRACTILE force element Af - Activation-Frequency}
% TL											{constants for the CONTRACTILE force element L => Leff (time lag)}
% Tf1    Tf2   Tf3	Tf4				{constants for the CONTRACTILE force element f => feff (rise/fall times)}
% aS1    aS2   TS							{constants for the CONTRACTILE force element SAG}
% cY  	VY		TY							{constants for the CONTRACTILE force element YIELD}
% ch0		ch1	ch2	ch3				{constants for the energy rate equation}

% The other main structure is BM_FTD_General_Parameters.  It has the following fields
% Sarcomere_Length	{optimal sarcomere length in um.  This value is assumed to be the same for all fiber
%							 types in each database}
% Specific_Tension	{This is the specific Tension in N/cm2.  
%							It defaults to 31.8 N/cm based on Scott et al., 1996 and Brown et al., 1998} 
% c1    k1    Lr1		{constants for the passive force element PE1}
% c2    k2    Lr2		{constants for the passive force element PE2}
% cT, kT & LrT			{parameters for tendon series elasticity}
% Viscosity				{default is 1%.  this is passive and applies to all fiber types in a database file} 
% Comments				{any comments that are database specific}
% Version				(Version of Buildmuscles last used to create/alter the database)

% Modified by Giby Raphael & Dan Song (1-8-8) (Current Version 4.0) 

function BuildMuscles(todo)
global BM_Version	  BM_Distribute_Window 

BM_Version='4.0';		%This is the version of the BuildMuscles program.

if nargin==0,todo='initialize';end

drawnow;		%ensure the figure is updated before doing anything to it

switch todo
case 'initialize',						Initialize;  
case 'make main figure',				Make_Main_Figure;
case 'load',								Load;
case 'save',								Save;
case 'select ftd',						Select_FTD;
case 'cut',									Cut;
case 'copy',								Copy;
case 'paste',								Paste;   
case 'delete',								Delete;
case 'insert',								Insert;
case 'manually distribute',			Manually_Distribute;
case 'auto distribute equal',			Auto_Distribute('equal');		
case 'auto distribute default',		Auto_Distribute('default');	
case 'auto distribute geometric',	Auto_Distribute('geometric');
case 'import',								Import;
case 'Set Recruitment',					Set_Recruitment;
case 'Set Block Outputs',				Set_Block_Outputs;
case 'create',								Create;   
case 'rebuild',							Rebuild;   
case 'help',								Help;   
case 'definitions', 						Definitions_Dialog;
case 'help Natural Discrete (Brown & Cheng)', Help_Natural_Discrete_BrownCheng_Recruitment_Algorithm;%<DSadd5>
case 'help Natural Discrete (s-function)',    Help_Natural_Discrete_Recruitment_Algorithm; %<DSadd5>
case 'help Natural Continuous (s-function)',  Help_Natural_Continuous_Recruitment_Algorithm; %<DSadd5>
case 'help Intramuscular FES (s-function)',	  Help_Intramuscular_FES_Algorithm;
case 'help distribute PCSAs',			Help_Distribute_PCSAs;
case 'about',								About;   
case 'parse Unit',						Parse_Motor_Units;
case 'update fractional PCSA',		Update_Fractional_PCSA;
case 'refresh',							Refresh;
case 'clean up'
    %QUITTING PROGRAM, KILL GLOBAL VARIABLES and delete the window
   if ishandle(BM_Distribute_Window),delete(BM_Distribute_Window);end
   clear global Muscle_Morph   Muscle_Model_Parameters;
   clear global BM_Fiber_Type_Database   BM_FTD_General_Parameters;
   clear global BM_First_Fiber   BM_First_Muscle   BM_First_Unit   Distribute_BM_First_Fiber;
   clear global BM_Save_File;
   clear global BM_Main_Vars   BM_Distribute_Vars;
   clear global BM_Clipboard_Muscle   BM_Distribute_Muscle;
   clear global BM_Main_Window   BM_Main_ETB   BM_Main_Menu   BM_Main_Muscle_Labels   BM_Main_Button   
   clear global BM_Main_Fiber_Labels   BM_Fiber_Type_Database_Label   BM_Clipboard_Label;
   clear global BM_Distribute_Window   BM_Distribute_ETB   BM_Distribute_Menu   
   clear global BM_Distribute_Fiber_Labels   BM_Distribute_Unit_Labels   BM_Distribute_Button;
otherwise
   'No Case selected!!!!'
end



%INTIALIZE GLOBAL VARIABLES
function Initialize
global BM_Main_Window   BM_First_Fiber   BM_First_Muscle
global BM_Save_File   BM_Save_Path   BM_Main_Vars sfunc_increase numberfibertypes_sfunc
	if ~isempty(findobj('tag','MMD_BM_Main_Window'))%Don't recreate elements if figure already exists
      set(0,'currentfigure',BM_Main_Window, 'visible', 'on');
      figure(BM_Main_Window);
      return
   end
   %Init global variables
   BM_First_Fiber=0;			BM_First_Muscle=0; sfunc_increase=0; Totalnumberfibertypes_sfunc=0;
   Init_General_Parameters;
   BM_Save_File='untitled.mat';
   BM_Save_Path='';
   BM_Main_Vars={'Muscle_Name' 'Mass' 'L0' 'Muscle_PCSA' 'F0' 'L0T' 'Lpath' 'Lmax' 'Ur'};%+5 more ETB for the fiber types
   Make_Main_Figure;
   
   
   
%Initialize the FTD_General_Parameters.  This is called at the beginning of the program and 
%also if an FTD is loaded up with any general parameters.
function Init_General_Parameters
global Muscle_Model_Parameters   BM_Version
   Muscle_Model_Parameters.Fiber_Type_Database_File='';
   Muscle_Model_Parameters.Fiber_Type_Names={};
   Muscle_Model_Parameters.Recruitment_Type='Natural';
   Muscle_Model_Parameters.Additional_Outports={};
   Muscle_Model_Parameters.Comments='';
   Muscle_Model_Parameters.Version=BM_Version;
    Muscle_Model_Parameters.Default_Apportion_Method={'default'};



%INITIALIZE Muscle Morphometry_DATABASE INDEX TO ZEROES AND '' for a SINGLE muscle
function Initialize_Muscle(musclenumber)
global Muscle_Morph    Muscle_Model_Parameters Totalnumberfibertypes_sfunc;
	Muscle_Morph(musclenumber).Muscle_Name='';
	Muscle_Morph(musclenumber).Mass=0;
	Muscle_Morph(musclenumber).L0T=0;
	Muscle_Morph(musclenumber).L0=0;
	Muscle_Morph(musclenumber).Muscle_PCSA=0;
	Muscle_Morph(musclenumber).F0=0;
	Muscle_Morph(musclenumber).Lpath=0;
	Muscle_Morph(musclenumber).Lmax=0;
	Muscle_Morph(musclenumber).Ur=0.8;    
	Muscle_Morph(musclenumber).Number_Units=[];
	Muscle_Morph(musclenumber).Fractional_PCSA=[];          %Vector of number of PCSA indexed by Muscle_Model_Parameters.Fiber_Type_Names
	Muscle_Morph(musclenumber).Unit_PCSA=[];                %Matrix of PCSAs within indexed by (Unit number,Muscle_Model_Parameters.Fiber_Type_Names)

   %	Subsequent old statement worked in Version 5.3, but not in 6.0
   %  Muscle_Morph(musclenumber).Apportion_Method=[];
	clear Muscle_Morph(musclenumber).Apportion_Method;      %Vector of apportioning method indexed by Muscle_Model_Parameters.Fiber_Type_Names
   if ~isempty(Muscle_Model_Parameters.Fiber_Type_Names)   %To initialize if an FTD has already been loaded 
	   numberfibertypes=length(Muscle_Model_Parameters.Fiber_Type_Names);
       Totalnumberfibertypes_sfunc=numberfibertypes; 
	   Muscle_Morph(musclenumber).Number_Units(1:numberfibertypes)=0;
	   Muscle_Morph(musclenumber).Fractional_PCSA(1:numberfibertypes)=0;
      Muscle_Morph(musclenumber).Unit_PCSA(1:numberfibertypes)=0;
      Muscle_Morph(musclenumber).Apportion_Method(1:numberfibertypes)=Muscle_Model_Parameters.Default_Apportion_Method;
	end



%MAKE GUI ELEMENTS for the main figure (window) of the BuildMuscles function
function Make_Main_Figure
global BM_Main_Window   BM_Fiber_Type_Database_Label   BM_Clipboard_Label   BM_Main_Menu   
global BM_Main_Vars   BM_Main_ETB
   bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   closerequestfunction=['selection = questdlg(''Exit BuildMuscles? Unsaved information will be lost!'','...
         '''Close Window?'',''Exit'',''Cancel'',''Cancel'');'...
         'switch selection, case ''Exit'','...
         'clear selection;if exist(''BuildMuscles'',''file''),BuildMuscles(''clean up'');end,delete(gcf);'...
         'case ''Cancel'', return, end'];
   screen=get(0,'screensize');
   windowwidth=965;		windowhieght=610;      
   mainwindowpos=[(screen(3)-windowwidth)/2 (screen(4)-windowhieght)/2 windowwidth windowhieght];
   BM_Main_Window=figure(...
      'name','BuildMuscles: untitled.mat',...
      'color',bkcolor,...
      'menubar','none',...
      'tag','MMD_BM_Main_Window',...
      'closerequestfcn',closerequestfunction,...
      'position',mainwindowpos,...
      'resize','off',...
      'numbertitle','off',...
      'visible','off');
   BM_Fiber_Type_Database_Label=uicontrol(...   %Make FTD label, the string is set in Refresh function
      'style','text',...
      'backgroundcolor',bkcolor,...
      'horizontalalignment','left',...
      'string','Fiber Type Database: Please select a database before proceeding',...   
      'position',[5 575 500 25]);
   BM_Clipboard_Label=uicontrol(...   %Make clipboard label, the string is set in Refresh function
      'style','text',...
      'backgroundcolor',bkcolor,...
      'horizontalalignment','left',...
      'string','Clipboard contents: Empty',...   
      'position',[5 560 500 20]);
   frame=uicontrol(...	%frame to separate the motor unit/PCSA stuff from the rest of the data
      'style','frame',...
      'position',[657 230 302 355]);      
   txt=uicontrol(...%Label for fiber types
      'style','text',...
      'backgroundcolor',bkcolor,...
      'string','Fiber type distribution (PCSA/#_Units)',...
      'position',[710 545 135 30]); %<DSadd2>      
   Make_Main_Window_Menus_Buttons_and_ETBs;
   %put label and text box for database related comments
   txt=uicontrol(...%Do label along left side of figure
         'style','text',			'string','Comments',...
         'backgroundcolor',bkcolor,			'horizontalalignment','left',...
         'position',[10 205 65 20]);
	BM_Main_ETB(length(BM_Main_Vars)+6,1)=uicontrol(... %Editable text box for additional comments (
         'style','edit',			'backgroundcolor',[1 1 1], 'max',2,...
         'position',[80 35 880 190],		'horizontalalignment','left');
   set(BM_Main_Menu(2).submenu(3).menu,'enable','off');%Set PASTE to disabled by default
   set(BM_Main_Window,'visible','on');
   Refresh;
      
   
%Make the menus, buttons and Editable Text Boxes for the Main Window
function Make_Main_Window_Menus_Buttons_and_ETBs()
global BM_Main_Window   BM_Main_Menu   BM_Main_Button   BM_Main_Vars
global BM_Main_ETB   BM_Main_Fiber_Labels   BM_Main_Muscle_Labels
	%first make the menus
   BM_Main_Menu=Make_Menus(BM_Main_Window, {'&File' '&Edit' '&Muscles' 'M&odel' '&Help'},{},{}); 
   BM_Main_Menu(1).submenu=Make_Menus(BM_Main_Menu(1).menu, {'&Open Muscle Database' '&Save Muscle Database'...
         'Select &Fiber Type Database' '&Close Program'},{'off' 'off' 'on' 'on' 'off'},...
      	{'BuildMuscles(''load'')' 'BuildMuscles(''save'')'...
         'BuildMuscles(''select ftd'')' 'global BM_Main_Window;close(BM_Main_Window)'}); 
   BM_Main_Menu(2).submenu=Make_Menus(BM_Main_Menu(2).menu, {'Cu&t Muscle to Clipboard'...
         '&Copy Muscle to Clipboard' '&Paste Muscle from Clipboard' '&Import Muscle to Clipboard'...
         'I&nsert (empty) muscle' '&Delete muscle'}, {'off' 'off' 'off' 'on' 'on' 'off'},...
      	{'BuildMuscles(''cut'')' 'BuildMuscles(''copy'')' 'BuildMuscles(''paste'')'...
      	'BuildMuscles(''import'')' 'BuildMuscles(''insert'')' 'BuildMuscles(''delete'')'}); 
   BM_Main_Menu(3).submenu=Make_Menus(BM_Main_Menu(3).menu, {'Manually Distribute Motor Unit PCSA'...
         '&Automatically distribute motor unit PCSA'},{},...
      	{'BuildMuscles(''manually distribute'')' ''}); 
   BM_Main_Menu(4).submenu=Make_Menus(BM_Main_Menu(4).menu, {'Set Recruitment Strategy'...
         'Set additional SIMULINK block outputs' '&Create SIMULINK Muscle_Block' '&Rebuild existing SIMULINK model' },...
      	{'off' 'off' 'on' 'off'},...
         {'BuildMuscles(''Set Recruitment'')' 'BuildMuscles(''Set Block Outputs'')'...
         'BuildMuscles(''create'')' 'BuildMuscles(''rebuild'')'}); 
   BM_Main_Menu(5).submenu=Make_Menus(BM_Main_Menu(5).menu, {'&Help' '&Definitions of Terms',...
         'Natural Discrete (Brown & Cheng) Recruitment Algorithm' 'Natural Discrete Recruitment Algorithm' 'Natural Continuous Recruitment Algorithm' 'Intramuscular FES Recruitment Algorithm'...
         'Automatically Distribute Motor-unit PCSAs'...
         '&About'},		{'off' 'off' 'off' 'off' 'off' 'off' 'off' 'on'},...
      	{'BuildMuscles(''help'')' 'BuildMuscles(''definitions'')' 'BuildMuscles(''help Natural Discrete (Brown & Cheng)'')'...
         'BuildMuscles(''help Natural Discrete (s-function)'')' 'BuildMuscles(''help Natural Continuous (s-function)'')'...
         'BuildMuscles(''help Intramuscular FES (s-function)'')' 'BuildMuscles(''help distribute PCSAs'')'...
         'BuildMuscles(''about'')'});      
    
   %Sub-menus for autodistribution
   BM_Main_Menu(3).submenu(2).submenu=Make_Menus(BM_Main_Menu(3).submenu(2).menu,...
	      {'Different sizes (Default Algorithm)' 'Different sizes (Geometric Algorithm)' 'Equal Sizes'}, {},...
         {'BuildMuscles(''auto distribute default'')'...
         'BuildMuscles(''auto distribute geometric'')' 'BuildMuscles(''auto distribute equal'')'});
   %Make the buttons
   buttonwidth=120;		buttonheight=20;
	buttonnames={'Prev 10 Muscles' 'Next 10 Muscles' 'Prev 5 Fibers' 'Next 5 Fibers'};
	buttoncallbackstrings={'global BM_First_Muscle;BM_First_Muscle=BM_First_Muscle-10;BuildMuscles(''refresh'')',...
         'global BM_First_Muscle;BM_First_Muscle=BM_First_Muscle+10;BuildMuscles(''refresh'')',...
         'global BM_First_Fiber;BM_First_Fiber=BM_First_Fiber-5;BuildMuscles(''refresh'')',...
      	'global BM_First_Fiber;BM_First_Fiber=BM_First_Fiber+5;BuildMuscles(''refresh'')'};  
	BM_Main_Button=Make_Buttons(BM_Main_Window, buttonnames,buttoncallbackstrings, buttonwidth, buttonheight);
   %Last make the ETBs
   numETBcols=length(BM_Main_Vars)+5;
   %first xpos is the label, second is muscle name; first ypos is label
   
   xsize=55;	ETBxpos=[5 80 (2:numETBcols)*(xsize+5)+60];			ETBxsize=[15 40 zeros(1,numETBcols-1)]+xsize;
   ysize=20;	ETBypos=[233+10*(ysize+5) (10:-1:1)*(ysize+5)+210];	ETBysize=[43 zeros(1,numETBcols-1)]+ysize;
   ETBColLabelstrings={'Muscle name' 'Muscle mass (g)' 'Fascicle Lo (cm)' 'Muscle PCSA (cm^2)' 'Muscle Fo (N)'...
         'Tendon LoT (cm)' 'Whole muscle LMax (cm)' 'Fascicle LMax (Lo)' 'Ur' '' '' '' '' ''};%+5 more ETB for the fiber types
   for rows=1:length(ETBypos)-1;		ETBRowLabelstrings{rows}=['Muscle #' num2str(rows)];	end;
	[BM_Main_ETB, BM_Main_Fiber_Labels, BM_Main_Muscle_Labels]=Make_ETB(...
      		BM_Main_Window, ETBxpos, ETBxsize, ETBypos, ETBysize, ETBColLabelstrings, ETBRowLabelstrings);

      
%MAKE MANUALLY DISTRIBUTE WINDOW
%This function switches too (or creates if necessary) the new window in which the user can manually 
%distribute the fractional PCSA amongst the various motor units of different fiber types.
function Manually_Distribute
global BM_Distribute_Muscle   Muscle_Morph   BM_Main_Window   Distribute_BM_First_Fiber
global BM_First_Unit   BM_Distribute_Window   BM_Distribute_Menu 

	closerequestfcn=['drawnow;selection = questdlg(''Done distributing?'','...
         '''Close Window?'','...
     	   '''Finished'',''No'',''No'');'...
        	'switch selection,'...
        	'case ''Finished'','...
         'clear selection; set(gcf,''visible'',''off'');global BM_Main_Window;set(BM_Main_Window,''visible'',''on'');BuildMuscles(''refresh'');'...
        	'case ''No'','...
        	'return,'...
           'end'];
	if isempty(BM_Distribute_Muscle)%So we can call this with a predetermined BM_Distribute_Muscle
      str={Muscle_Morph.Muscle_Name};
      [selection,ok]=listdlg('promptstring','Select muscle to redistribute','selectionmode','single','liststring',str,'name','Manually distribute');
      if ~ok
         return
      end
      BM_Distribute_Muscle=selection;
   end
   set(BM_Main_Window,'visible','off');
   Distribute_BM_First_Fiber=0;
   BM_First_Unit=0;
   bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   if isempty(findobj('tag','MMD_BM_Distribute_Window'))%Don't recreate elements if figure already exists
      screen=get(0,'screensize');
      windowwidth=755;		windowheight=400;
      mainwindowpos=[(screen(3)-windowwidth)/2 (screen(4)-windowheight)/2 windowwidth windowheight];
      BM_Distribute_Window=figure(...
            'color',bkcolor,...
            'menubar','none',...
            'tag','MMD_BM_Distribute_Window',...
            'closerequestfcn',closerequestfcn,...
            'position',mainwindowpos,...
            'resize','off',...
            'numbertitle','off',...
            'visible','off');
   	Make_Distribute_Window_Menus_Buttons_and_ETBs;
   end
   set(BM_Distribute_Window,'visible','on');
   Refresh;



%Make the menus, buttons and Editable Text Boxes (ETBs) for the Manually Distribute Window
function Make_Distribute_Window_Menus_Buttons_and_ETBs
global BM_Distribute_Window   BM_Distribute_Menu   BM_Distribute_Button
global BM_Distribute_Fiber_Labels   BM_Distribute_Unit_Labels   BM_Distribute_ETB
	%First make the menus
   BM_Distribute_Menu=Make_Menus(BM_Distribute_Window, {'&Muscles' '&Help'},{},{}); 
   BM_Distribute_Menu(1).submenu=Make_Menus(BM_Distribute_Menu(1).menu,...
      	{'Automatically distribute PCSA (Default algorithm) amongst motor units'...
		 	'Automatically distribute PCSA (geometric algorithm) amongst motor units'...
			'Automatically distribute PCSA (equally) amongst motor units'...
			'&Close window'},{},...
      	{'BuildMuscles(''auto distribute default'')' 'BuildMuscles(''auto distribute geometric'')' ...
		 	'BuildMuscles(''auto distribute equal'')' 'eval(get(gcf,''closerequestfcn''))'}); 
   BM_Distribute_Menu(2).submenu=Make_Menus(BM_Distribute_Menu(2).menu,...
         {'&Help' 'Automatically Distribute (Algorithm 1)'}, {},	{'BuildMuscles(''help'')'...
	 		'BuildMuscles(''help algorithm (default)'')'}); 
   %Make the buttons   
   buttonwidth=100;		buttonheight=20;
	buttonnames={'Prev 10 Units' 'Next 10 Units' 'Prev 10 Fibers' 'Next 10 Fibers' 'Edit Prev Musc' 'Edit Next Musc'};
   buttoncallbackstrings={...
         'global BM_First_Unit;BM_First_Unit=BM_First_Unit-10;BuildMuscles(''refresh'')',...
         'global BM_First_Unit;BM_First_Unit=BM_First_Unit+10;BuildMuscles(''refresh'')',...
         'global Distribute_BM_First_Fiber;Distribute_BM_First_Fiber=Distribute_BM_First_Fiber-10;BuildMuscles(''refresh'')',...
         'global Distribute_BM_First_Fiber;Distribute_BM_First_Fiber=Distribute_BM_First_Fiber+10;BuildMuscles(''refresh'')',...
         'global Distribute_BM_First_Fiber BM_First_Unit BM_Distribute_Muscle;BM_First_Unit=0;Distribute_BM_First_Fiber=0;BM_Distribute_Muscle=BM_Distribute_Muscle-1;BuildMuscles(''refresh'')',...
      	'global Distribute_BM_First_Fiber BM_First_Unit BM_Distribute_Muscle;BM_First_Unit=0;Distribute_BM_First_Fiber=0;BM_Distribute_Muscle=BM_Distribute_Muscle+1;BuildMuscles(''refresh'')'};  
   BM_Distribute_Button=Make_Buttons(BM_Distribute_Window, buttonnames,buttoncallbackstrings, buttonwidth, buttonheight);
   %Make the ETBs
	xsize=55;	ETBxpos=(0:10)*(xsize+5)+55;			ETBxsize=ones(size(ETBxpos))*xsize;				
   ysize=20;	ETBypos=([12:-1:0])*(ysize+5)+55;	ETBysize=ones(size(ETBypos))*ysize;
   ETBxsize(1)=ETBxsize(1)+45;	ETBxpos(1)=ETBxpos(1)-50;
   ETBypos(1:3)=ETBypos(1:3)+15;		%move the column labels, 'PCSA/# units' and 'Apportioning Method' up
   for i=1:(length(ETBxpos)-1),	ETBColLabelstrings{i}='Nothing';	end;
   for i=2:(length(ETBypos)-1),	ETBRowLabelstrings{i}='Nothing'; end;
   ETBRowLabelstrings{1}=['PCSA/# units'];
   ETBRowLabelstrings{2}=['Apportioning Method'];
   [BM_Distribute_ETB, BM_Distribute_Fiber_Labels, BM_Distribute_Unit_Labels]=Make_ETB(...
      		BM_Distribute_Window, ETBxpos, ETBxsize, ETBypos, ETBysize, ETBColLabelstrings, ETBRowLabelstrings);
   
   
   
% Make menus and set callback routines for all windows
%This is a generic function for ALL windows in this m-file
function [menuhandle]=Make_Menus(parent, menulabels, menuseparatorflag, menucallbackstring)
   for i=1:length(menulabels)
      menuhandle(i).menu=uimenu(parent,'label',menulabels{i});
      if ~isempty(menuseparatorflag)
         set(menuhandle(i).menu,'separator',menuseparatorflag{i});
      end
      if ~isempty(menucallbackstring)
         set(menuhandle(i).menu,'callback',menucallbackstring{i});
      end
   end
   
   
   
%Make buttons for figures here.
%This is a generic function for ALL windows in this m-file
function [button]=Make_Buttons(Window, buttonnames, buttoncallbackstrings, buttonwidth, buttonheight)
   bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   for i=1:length(buttonnames)
    	button(i)=uicontrol(Window, 'style','pushbutton',	'string',buttonnames{i},...
          'backgroundcolor',bkcolor,'position',[10+(i-1)*(buttonwidth+5) 10 buttonwidth buttonheight],...
          'callback', buttoncallbackstrings{i});
   end
 
   

%create the ETB (Editable Text Boxes) and their labels
%This is a generic function for ALL windows in this m-file
%The label positions and sizes are stored in the first index of each position and size vector
function [ETB, ColLabels, RowLabels]=Make_ETB(Window, xpos, xsize, ypos, ysize, ColLabelstrings, RowLabelstrings)
	bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   for cols=2:length(xpos)
      ColLabels(cols-1)=uicontrol(Window,...%Do labels along top side of figure
            'style','text',...
            'backgroundcolor',bkcolor,...
            'string',ColLabelstrings(cols-1),...
            'position',[xpos(cols) ypos(1) xsize(cols) ysize(1)]);
   end
   for rows=2:length(ypos)
      RowLabels(rows-1)=uicontrol(Window,...%Do labels along left side of the figure
            'style','text',...
            'backgroundcolor',bkcolor,...
          	'horizontalalignment','right',...
            'string',RowLabelstrings(rows-1),...
            'position',[xpos(1) ypos(rows)-2 xsize(1) ysize(rows)]);
   end
   for cols=2:length(xpos)
      for rows=2:length(ypos)
        	ETB(rows-1,cols-1)=uicontrol(Window,...%Editable text boxes, callback is set below, not in (only if window doesn't exist) loop
           	   'style','edit',...
              	'backgroundcolor',[1 1 1],...
               'position',[xpos(cols) ypos(rows) xsize(cols) ysize(rows)]);
      end
   end
   
   
   
%REFRESH the windows, but find out which one to refresh here
function Refresh
global BM_Main_Window   BM_Distribute_Window
   if ~isempty(findobj('tag','MMD_BM_Main_Window'))%Refresh BM_Main_Window if that is the window that is open
	   if strcmp(get(BM_Main_Window,'visible'),'on')%and if it is visible
        Refresh_Main_Window;
      end
   end
	if ~isempty(findobj('tag','MMD_BM_Distribute_Window'))%Refresh coefficient window if that is open
   	if strcmp(get(BM_Distribute_Window,'visible'),'on')%and if it is visible
         Refresh_MU_PCSA_Window;
      end
   end
   
   
   
%REFRESH ALL THE ETB (Editable Text Box) FIELDS in the main BUILDMUSCLES window
%ALL CALLBACKS are set HERE, AS WELL AS DISTRIBUTING THE NAMES OF THE FIBER TYPES AND THE COLUMNS BENEATH THEM
function Refresh_Main_Window  
global BM_Distribute_Muscle   Muscle_Morph   BM_First_Muscle   BM_Main_Button   Muscle_Model_Parameters
global BM_Main_ETB   BM_Clipboard_Muscle   BM_Clipboard_Label   BM_Main_Vars   BM_Main_Muscle_Labels
global BM_Main_Fiber_Labels   BM_First_Fiber   BM_Main_Menu   BM_FTD_General_Parameters
	bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   %Assume we are coming back from manually distributing; need to check that manually 
   %reapportioning of motor units totals the correct amounts
   if ~isempty(BM_Distribute_Muscle)
      todo=Check_Fiber_Type_PCSA_Apportioning(BM_Distribute_Muscle);
      if strcmp(todo,'readjust PCSAs')
         Manually_Distribute;
         return;
      end
   end
   BM_Distribute_Muscle=[];%Clear so it won't check out of bounds EVERY time
   %Enable/Disable buttons
   for i=1:4	
      set(BM_Main_Button(i),'enable','on');		%default value is on
   end
   if BM_First_Muscle<=0								%Check out of bound muscle number
      BM_First_Muscle=0;
      set(BM_Main_Button(1),'enable','off');
   end
   if BM_First_Muscle+10>length(Muscle_Morph)	%Initialize muscles if they don't exist already
      for newmusclenumber=BM_First_Muscle+10:-1:length(Muscle_Morph)+1
         Initialize_Muscle(newmusclenumber);
      end
   end
   if isempty(Muscle_Model_Parameters.Fiber_Type_Database_File)
      set(BM_Main_Button(2),'enable','off');
   end
   if BM_First_Fiber<=0%Check out of bounds fiber number
      BM_First_Fiber=0;
      set(BM_Main_Button(3),'enable','off');
   end
   if BM_First_Fiber+5>=length(Muscle_Model_Parameters.Fiber_Type_Names)
      set(BM_Main_Button(4),'enable','off')
   end
   %Enable/Disable menu items
   if ~isempty(Muscle_Model_Parameters.Fiber_Type_Database_File)%Check that an FTD is loaded; if so, enable all menus and controls
      enablestatus='on';		tempcolor=[1 1 1];
   else
      enablestatus='off';		tempcolor=bkcolor;
   end
   if isempty(BM_Clipboard_Muscle)%Check if something has been copied yet
      set(BM_Main_Menu(2).submenu(3).menu,'enable','off');
      set(BM_Clipboard_Label,'string','Clipboard contents: Empty');
   else
      set(BM_Main_Menu(2).submenu(3).menu,'enable','on');
      set(BM_Clipboard_Label,'string',['Clipboard contents: ' BM_Clipboard_Muscle.Muscle_Name]);
   end
   for cols=[2 3 4]
      set(BM_Main_Menu(cols).menu,'enable',enablestatus);
   end
   %Enable/Disable ETBs (Editable Text Boxes)
   for rows=1:10
      for cols=[1:3 6:7 9:length(BM_Main_Vars)]
         set(BM_Main_ETB(rows,cols),'enable',enablestatus,'backgroundcolor',tempcolor);
      end
      for cols=[4 5 8]
         set(BM_Main_ETB(rows,cols),'enable','off');
      end
   end
   %Recalculate PCSA and F0 for all muscles
   muscledensity=1.06;						%g/cm^3
	for musclenumber=1:length(Muscle_Morph)
      if ~Muscle_Morph(musclenumber).L0==0
      	Muscle_Morph(musclenumber).Muscle_PCSA=Muscle_Morph(musclenumber).Mass/muscledensity/Muscle_Morph(musclenumber).L0;
         Muscle_Morph(musclenumber).F0=Muscle_Morph(musclenumber).Muscle_PCSA*BM_FTD_General_Parameters.Specific_Tension;
         FTD=BM_FTD_General_Parameters;				
         Passive_Force=FTD.c1*FTD.k1*log( exp( (1-FTD.Lr1)/FTD.k1 )+1 );		%Passive force of a muscle stretched to its anatomical maximum
         normalized_SE_length=FTD.kT*log( exp(Passive_Force/FTD.cT/FTD.kT)-1 )+FTD.LrT;		%normalized length of SE stretched by that force 
         SE_length=Muscle_Morph(musclenumber).L0T*normalized_SE_length;			%length of SE stretched by passive force
     		Muscle_Morph(musclenumber).Lmax=(Muscle_Morph(musclenumber).Lpath-SE_length)/Muscle_Morph(musclenumber).L0;
      end
    end
   
   %Set callbacks and strings for BM_Main_Vars ETBs (i.e not the ETB beneath the fiber type headings
   for rows=1:10
      for cols=1:length(BM_Main_Vars)
         switch cols%Callback depends on the column
         case 1%It's a string
            callbackstring=['global Muscle_Morph;Muscle_Morph(' num2str(BM_First_Muscle+rows) ').' BM_Main_Vars{cols} '=get(gcbo,''string'');'];
            string=getfield(Muscle_Morph(BM_First_Muscle+rows), BM_Main_Vars{cols});
         case {2 3 6 7 9 10}%Set number and calc PCSA/F0
            callbackstring=['global Muscle_Morph;Muscle_Morph(' num2str(BM_First_Muscle+rows) ').' BM_Main_Vars{cols} '=str2num(get(gcbo,''string''));BuildMuscles(''refresh'');'];
            string=num2str(getfield(Muscle_Morph(BM_First_Muscle+rows), BM_Main_Vars{cols}));   
         case {4 5 8}%Can't edit these columns
            callbackstring='';
            string=num2str(getfield(Muscle_Morph(BM_First_Muscle+rows), BM_Main_Vars{cols}));   
         end
         set(BM_Main_ETB(rows,cols),'callback',callbackstring,'string',string);
      end
   end
   callbackstring=['BuildMuscles(''parse Unit'');'];   
   %Fill in strings and set headings for fiber types and enable ETBs if req'd for fiber type boxes
   for rows=1:10
      for cols=1:5
         if BM_First_Fiber+cols<=length(Muscle_Model_Parameters.Fiber_Type_Names)
            set(BM_Main_ETB(rows,length(BM_Main_Vars)+cols),'callback',callbackstring,...
               'enable','on','backgroundcolor',[1 1 1],'string',...
               [num2str(Muscle_Morph(BM_First_Muscle+rows).Fractional_PCSA(BM_First_Fiber+cols)) '/' num2str(Muscle_Morph(BM_First_Muscle+rows).Number_Units(BM_First_Fiber+cols))]);
         else   
            set(BM_Main_ETB(rows,length(BM_Main_Vars)+cols),'callback',callbackstring,'enable','off',...
               'backgroundcolor',bkcolor,'string','-');
         end
      end
   end
   %Set muscle labels
   for rows=1:10
      set(BM_Main_Muscle_Labels(rows),'string',['Muscle #' num2str(BM_First_Muscle+rows)]);
   end
   %Set headings for fiber types
   for cols=1:5
      string='';		%default is empty ''
      if BM_First_Fiber+cols<=length(Muscle_Model_Parameters.Fiber_Type_Names)
         string=Muscle_Model_Parameters.Fiber_Type_Names(BM_First_Fiber+cols);
      end
      set(BM_Main_Fiber_Labels(length(BM_Main_Vars)+cols),'string',string);
   end                  
   comments=Muscle_Model_Parameters.Comments;
   callbackstring=['global Muscle_Model_Parameters;'... 
               'Muscle_Model_Parameters.Comments=get(gcbo,''string'');'];
   set(BM_Main_ETB(length(BM_Main_Vars)+6,1),'string',comments,'callback', callbackstring);
   
   

%REFRESH ALL THE ETB (Editable Text Box) FIELDS in the Motor Unit PCSA distribution window
%ALL CALLBACKS are set HERE, AS WELL AS DISTRIBUTING THE NAMES OF THE FIBER TYPES AND THE COLUMNS BENEATH THEM
function Refresh_MU_PCSA_Window
global BM_Distribute_Window   Muscle_Morph   BM_Distribute_Muscle   BM_First_Unit   BM_Distribute_Button
global Distribute_BM_First_Fiber   Muscle_Model_Parameters   BM_Distribute_Fiber_Labels
global BM_Distribute_ETB   BM_Distribute_Unit_Labels
	bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   set(BM_Distribute_Window,'name',['Fractional PCSA of each motor unit belonging to Muscle #' num2str(BM_Distribute_Muscle) ': ' Muscle_Morph(BM_Distribute_Muscle).Muscle_Name]);
   %default value for buttons is 'enabled'
   for i=1:6
      set(BM_Distribute_Button(i),'enable','on');
   end
   if BM_First_Unit<=0%Set up the scroll buttons
      BM_First_Unit=0;
      set(BM_Distribute_Button(1),'enable','off');
   end
   if BM_First_Unit+10>=size(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA,1)
      set(BM_Distribute_Button(2),'enable','off');
   end
   if Distribute_BM_First_Fiber<=0
      Distribute_BM_First_Fiber=0;
      set(BM_Distribute_Button(3),'enable','off');
   end
   if Distribute_BM_First_Fiber+10>=size(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA,2)
      set(BM_Distribute_Button(4),'enable','off');
   end
   if BM_Distribute_Muscle<=1
      set(BM_Distribute_Button(5),'enable','off');
   end
   if BM_Distribute_Muscle>=length(Muscle_Morph)
      set(BM_Distribute_Button(6),'enable','off');
   end
   %Set up and relabel the labels for the rows
   for rows=1:10
      set(BM_Distribute_Unit_Labels(rows+2),'visible','off');		%default is not visible
      if BM_First_Unit+rows<=size(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA,1)
         set(BM_Distribute_Unit_Labels(rows+2),'string',['Unit #' num2str(BM_First_Unit+rows)],'visible','on');
      end
   end
   %Set up all the ETB (Editable Text Box) string and callbacks as well as column labels
   numberfibertypes=size(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA,2);
   for cols=1:10
      set(BM_Distribute_Fiber_Labels(cols),'visible','off');   %default is not visible
      set(BM_Distribute_ETB(:,cols),'visible','off');		%default is not visible
      if Distribute_BM_First_Fiber+cols<=numberfibertypes;		%don't bother with fibertypes that don't exist
         %set the column labels
         set(BM_Distribute_Fiber_Labels(cols),'string',Muscle_Model_Parameters.Fiber_Type_Names{Distribute_BM_First_Fiber+cols},'visible','on');
         %set the total PCSA/# units
         callbackstring=['BuildMuscles(''parse Unit'');'];   
			PCSA=Muscle_Morph(BM_Distribute_Muscle).Fractional_PCSA(Distribute_BM_First_Fiber+cols);
         Number_Units=Muscle_Morph(BM_Distribute_Muscle).Number_Units(Distribute_BM_First_Fiber+cols);
         set(BM_Distribute_ETB(1,cols),'string', [num2str(PCSA) '/' num2str(Number_Units)],'visible','on','callback',callbackstring);
         %set the apportioning type
         set(BM_Distribute_ETB(2,cols),'string',Muscle_Morph(BM_Distribute_Muscle).Apportion_Method(Distribute_BM_First_Fiber+cols),...
            	'enable','off','visible','on');
         %set the rest of the PCSA ETBs
         for rows=1:10
            if BM_First_Unit+rows<=Muscle_Morph(BM_Distribute_Muscle).Number_Units(Distribute_BM_First_Fiber+cols)
         		callbackstring=['BuildMuscles(''update fractional PCSA'');'];   
               set(BM_Distribute_ETB(rows+2,cols),'string',...
                   	num2str(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA(BM_First_Unit+rows,Distribute_BM_First_Fiber+cols)),...
                   	'visible','on','callback',callbackstring);
            end
         end	%end for rows...
      end	%end if
   end	%end for cols
   
   
   
%LOAD A MMD (Muscle_Model_Database) FILE
%This file provides the user interface for loading a Muscle_Model_Database
function Load
global BM_Save_Path   Muscle_Morph   Muscle_Model_Parameters   BM_Save_File   BM_Save_Path
global BM_Main_Window   BM_Fiber_Type_Database   BM_Fiber_Type_Database_Label   BM_FTD_General_Parameters
	[filename pathname]=uigetfile([BM_Save_Path '*.mat'],'Load muscle_model_database.mat file');
   if ~(filename==0)
      tempMMD=load([pathname filename]);
      %check to see if it is an actual Muscle Model Database
      if ~isfield(tempMMD,'Muscle_Morph')|~isfield(tempMMD,'Muscle_Model_Parameters')
         msgbox('Not a valid Muscle_Model_Database file');
         return
      end
      %temporarily update the global parameters    
      old_Muscle_Morph=Muscle_Morph;
      old_Muscle_Model_Parameters=Muscle_Model_Parameters;
      %Because there are new fields for Muscle_Model_Parameters not present in the old versions we need to ensure they are here...
      %This section needs to be before the FTD is chosen because if a different FTD is chosen then its name gets updated below
      Init_General_Parameters;
     	fields=fieldnames(tempMMD.Muscle_Model_Parameters);
      for i=1:length(fields)
         %only set those fields which were defined in the loaded database AND in the new structure, so that new ones set by Init_... do not get erased/overwritten
    	   if isfield(Muscle_Model_Parameters,fields{i})
     			newdata=getfield(tempMMD.Muscle_Model_Parameters,fields{i});
     	      Muscle_Model_Parameters=setfield(Muscle_Model_Parameters,fields{i},newdata);
     	   end
      end
      Muscle_Morph=[];
      numbermuscles=length(tempMMD.Muscle_Morph);
      for j=1:numbermuscles
         Initialize_Muscle(j)
      end
     	fields=fieldnames(tempMMD.Muscle_Morph);
      for i=1:length(fields)
         %only set those fields which were defined in the loaded database AND in the new structure, so that new ones set by Init_... do not get erased/overwritten
    	   if isfield(Muscle_Morph,fields{i})
      		for j=1:numbermuscles
     				newdata=getfield(tempMMD.Muscle_Morph(j),fields{i});
            	Muscle_Morph(j)=setfield(Muscle_Morph(j),fields{i},newdata);
				end
     	   end
      end
      
      %even if this file does not get used, update the path now so that if you need to select a different FTD, you start in the same path.
      BM_Save_Path=pathname;
      %load the FiberTypeDatabase which is associated with the just-opened MMD
      FTD_filename=[pathname tempMMD.Muscle_Model_Parameters.Fiber_Type_Database_File];
      if exist(FTD_filename,'file')
         tempFTD=load(FTD_filename);
         state=Check_FTD_Version(tempFTD, FTD_filename);
         if strcmp(state,'ok')
            state=Compare_New_And_Old_FTDs(tempFTD.Fiber_Type_Database, filename);
            if strcmp(state,'ok')
      			Use_New_FTD_Database(tempFTD);
            end
         end
      else
         buttonname=questdlg(['Could not find the Fiber_Type_Database file (named '''...
               tempMMD.Muscle_Model_Parameters.Fiber_Type_Database_File...
               ''') in either the current path or the directory that the Muscle_Model_Database'...
               'was located in. Please find it or choose a new one before continuing'],...
            	'Error loading database file!','Ok','Ok');
         state='error';
      end
      while strcmp(state,'error')
         state=Select_FTD;
      end
      if strcmp(state,'canceled')
         Muscle_Morph=old_Muscle_Morph;
	      Muscle_Model_Parameters=old_Muscle_Model_Parameters;
         return
      end
      BM_Save_File=filename;
      set(BM_Main_Window,'name',['BuildMuscles: ' filename]);
     	set(BM_Fiber_Type_Database_Label,'string',['Fiber Type Database: ' Muscle_Model_Parameters.Fiber_Type_Database_File]);
   end
   Refresh;
   
   
   
% The new FiberType database has been chosen and accepted, so use it.
function Use_New_FTD_Database(tempFTD);
global BM_Fiber_Type_Database   BM_FTD_General_Parameters
	BM_Fiber_Type_Database=tempFTD.Fiber_Type_Database;
  	BM_FTD_General_Parameters=tempFTD.FTD_General_Parameters;
 	Erase_Unused_Fiber_Types;
	Replace_Missing_Fiber_Types;			%Does nothing if there are none to replace
	Add_Additional_Fiber_Types;
	Sort_Fiber_Types;



%SAVE MMD FILE
%This file provides the user interface for saving a Muscle Model Database
function Save
global Muscle_Morph   BM_Save_File   BM_Save_Path   BM_Main_Window   Muscle_Model_Parameters
   for i=length(Muscle_Morph):-1:1%Strip trailing empty entries from structure
      if isempty(Muscle_Morph(i).Muscle_Name)
         Muscle_Morph(i)=[];
      else
         break
      end
   end
   if isempty(BM_Save_File)%Get save file name: moved before Fractional PCSA check b/c of ETB callbacks not executing until button press
      [filename pathname]=uiputfile('*.mat','Save muscle_model_database.mat file as...');
   else
      [filename pathname]=uiputfile([BM_Save_Path BM_Save_File],'Save muscle_model_database.mat file as...');
   end
   ok=Check_Names;%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
   if ~ok
      return
   end
   if ~(filename==0)
      save ([pathname filename],'Muscle_Morph','Muscle_Model_Parameters');
   	BM_Save_File=filename;		BM_Save_Path=pathname;
      set(BM_Main_Window,'name',['BuildMuscles: ' filename]);
   else
      %disp('Save cancelled');
   end
   Refresh;
   
   

%SELECT FTD FILE
%This function loads a Fiber Type Database into memory, to serve as the repository of fiber types upon
%which muscles in the Muscle Morph Database must be based. Note that if there already exists a Muscle
%Model Database, then it checks to make sure that the appropriate fiber types are present in the new
%FTD.
function [state]=Select_FTD
global BM_Save_Path   Muscle_Morph   Muscle_Model_Parameters   BM_Fiber_Type_Database
global BM_Fiber_Type_Database_Label   BM_FTD_General_Parameters
	state='ok';
   [filename pathname]=uigetfile([BM_Save_Path '*.mat'],'Load fiber_type_database.mat file');
   if ~(filename==0)
      tempFTD=load([pathname filename]);
   else
      state='canceled';
      return %No file selected
   end 
   state=Check_FTD_Version(tempFTD, filename);
   if strcmp(state,'error')
      return
   end
   if isempty(Muscle_Morph)
      BM_Fiber_Type_Database=tempFTD.Fiber_Type_Database;
   else
      %Have to check that all required fiber types exist if we are loading a new FTD with an existing MMD
      state=Compare_New_And_Old_FTDs(tempFTD.Fiber_Type_Database, filename);
   	if strcmp(state,'error')
         return;
   	end
      Use_New_FTD_Database(tempFTD);
   end
   Muscle_Model_Parameters.Fiber_Type_Database_File=filename;
   set(BM_Fiber_Type_Database_Label,'string',['Fiber Type Database: ' filename]);
   if isempty(BM_Save_Path)		
      BM_Save_Path=pathname;
   end
   Refresh;   
   

%check to ensure that the FiberTypeDatabase file loaded is a current version
function [state]=Check_FTD_Version(tempstructures, FTD_filename)
	state='ok';
   if ~isfield(tempstructures,'Fiber_Type_Database')
      state='error';
   end
   if ~isfield(tempstructures,'FTD_General_Parameters')
      state='error';
   else
      currentrequiredfields={'Specific_Tension' 'Viscosity' 'c1' 'k1' 'Lr1' 'c2' 'k2' 'Lr2' 'cT' 'kT' 'LrT'};
      ok=1;
      for i=1:length(currentrequiredfields)
         ok=and(ok,isfield(tempstructures.FTD_General_Parameters,currentrequiredfields{i}));
      end
      if ~ok
      	state='error';
      end
   end
   if strcmp(state,'error')
      buttonname=questdlg({['The Fiber_Type_Database file named ''' FTD_filename '''',...
            ' is not valid or it is an old version.'],... 
            ' ',...
            'You will next be prompted to select a new Fiber_Type_Database before continuing.',...
            ' ',...
            ['Alternatively you can cancel at the next prompt and then update the old database file by ',...
            'simply opening and saving  the old database file in BuildFiberTypes.']},...
         'Error loading database file!','Ok','Ok');
   end 
        
   

%this function compares the fibertypes in the MMD (i.e. in the structure Muscle_Model_Parameters) with the
%fibertypes in the FTD passed to this function
%It makes sure that if there are any MMD fibertypes that are NOT in the FTD, then either
%the new FTD is not used, or the problematic fibertypes are replaced by new ones from the new FTD or from 
%unused ones.  An error is returned if this function or the user decides not to use this FTD
function [state]=Compare_New_And_Old_FTDs(Fiber_Type_Database, filename);
global Muscle_Morph   BM_Fiber_Type_Database
	state='ok';				%set default
   [missingfibertypes, unusedfibertypes]=Check_For_Required_Fiber_Types(Fiber_Type_Database);
   missingnames=missingfibertypes;					%for listing the names, separate by commas (except last one)
   for i=1:(length(missingfibertypes)-1)
      missingnames{i}=[missingfibertypes{i} ', '];		
   end
   if length(missingfibertypes)>0
      if length(missingfibertypes)<=length(unusedfibertypes)
      	buttonname=questdlg(['Could not find fibertype(s) named ''' missingnames{:} ''' listed in ''' filename '''.  Would you like to replace these missing fiber types with new ones?'],...
            						'Error loading database file','Ok','Cancel','Ok');
         if ~strcmp(buttonname,'Ok')
	         state='error';
            return;
         end
      else
      	buttonname=questdlg(['Could not find fibertype(s) named ''' missingnames{:} ''' listed in ''' filename ''' and there are not enough new/unused fibertypes to replace the current ones.  Please select a new Fiber Type Database'],...
         							'Error loading database file','Ok','Ok');
	      state='error';
      	return
      end
   end

   

% Check and compare fiber types in the MMD and FTD passed to this function.
% 2 cell arrays are returned:
% missingfibertypes: ones that the MMD uses (i.e. they have >0 motor units) but are not in the FTD
% unusedfibertypes: ones that FTD contains but MMD does not use (i.e. not in MMD or 0 motor units in MMD)
function [missingfibertypes, unusedfibertypes]=Check_For_Required_Fiber_Types(Fiber_Type_Database)
global Muscle_Model_Parameters   Muscle_Morph
	missingfibertypes={};		newfibertypes={};		unusedfibertypes={};			%initialize
   if length(Muscle_Morph)==1		%if Muscle_Morph has only 1 muscle, then the summation produces one number, and not a vector
      sum_units_each_fiber_type=(cat(1,Muscle_Morph.Number_Units));
   else
      sum_units_each_fiber_type=sum(cat(1,Muscle_Morph.Number_Units));
   end 
	for fibertypenumber=1:length(Muscle_Model_Parameters.Fiber_Type_Names)
      fibertypename=Muscle_Model_Parameters.Fiber_Type_Names{fibertypenumber};
      %check to see if MMD FiberType exists in the FTD
      if (strmatch(fibertypename,{Fiber_Type_Database.Fiber_Type_Name}, 'exact'))
         %Note: if there are 0 motor units, PCSA is 0 as well due to error checking elsewhere...
         if sum_units_each_fiber_type(fibertypenumber)==0 %this fibertype exists but is NOT used by the MMD
         	unusedfibertypes=cat(1,unusedfibertypes,{fibertypename});		
         end
      else
         if sum_units_each_fiber_type(fibertypenumber)~=0 %this fibertype is missing and is required by the MMD
            missingfibertypes=cat(1,missingfibertypes,{fibertypename});  		
         end
      end
   end
	FTD_fibertypenames={Fiber_Type_Database.Fiber_Type_Name};
   for fibertype=1:length(FTD_fibertypenames)
      %check to see if there are any new fibertypes in FTD that aren't in MMD
      fibertypeexist=strmatch(FTD_fibertypenames(fibertype),Muscle_Model_Parameters.Fiber_Type_Names, 'exact');
      if isempty(fibertypeexist)
         unusedfibertypes=cat(1,unusedfibertypes, FTD_fibertypenames(fibertype));
      end
   end
   
   
   
% Erase all fibertypes, if any, from the MMD that are NOT used by it
% (i.e. if total number of units in ALL muscles for that fiber type is 0, then erase it)
% Thus function is called only when a new fibertype database is chosen
function Erase_Unused_Fiber_Types
global Muscle_Model_Parameters    Muscle_Morph
   if length(Muscle_Morph)==1		%if Muscle_Morph has only 1 muscle, then the summation produces one number, and not a vector
      sum_units_each_fiber_type=(cat(1,Muscle_Morph.Number_Units));
   else
      sum_units_each_fiber_type=sum(cat(1,Muscle_Morph.Number_Units));
   end 
   %search starting from the last one to
	for fibertypenumber=length(Muscle_Model_Parameters.Fiber_Type_Names):-1:1
      if sum_units_each_fiber_type(fibertypenumber)==0	
         Muscle_Model_Parameters.Fiber_Type_Names(fibertypenumber)=[];
       	for musclenumber=1:length(Muscle_Morph)
            Muscle_Morph(musclenumber).Number_Units(fibertypenumber)=[];
           	Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)=[];
           	Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber)=[];
           	Muscle_Morph(musclenumber).Apportion_Method(fibertypenumber)=[];
         end
      end
   end
  
   
   
% Replace all fibertypes in the MMD which are not in the FTD.  
function Replace_Missing_Fiber_Types;
global Muscle_Morph   Muscle_Model_Parameters   BM_Fiber_Type_Database
	[missingfibertypes, unusedfibertypes]=Check_For_Required_Fiber_Types(BM_Fiber_Type_Database);
   original_MMD_Paramters=Muscle_Model_Parameters;
   while length(missingfibertypes)>0
		[selection,ok]=listdlg('promptstring',{[missingfibertypes{1} ' is not in the new Fiber Type Database.'],...
      		'Please select one of the following new/unused fiber types to replace it',...
            ' ', ' ', ' '},...   %stupid spaces are there to ensure proper spacing on the dialog
	        	'selectionmode','single','listsize', [300 300], 'liststring',unusedfibertypes,'name','Replace FiberType Used in Old Muscle Model');
      if ok
	      missingfiberindex=strmatch(missingfibertypes{1},Muscle_Model_Parameters.Fiber_Type_Names, 'exact');
         Muscle_Model_Parameters.Fiber_Type_Names(missingfiberindex)=unusedfibertypes(selection);
      else
   		Muscle_Model_Parameters=original_MMD_Paramters;			%if operation canceled, revert to original.
         return;
      end 
		[missingfibertypes, unusedfibertypes]=Check_For_Required_Fiber_Types(BM_Fiber_Type_Database);
   end
   


% The new BM_Fiber_Type_Database has been determined to have all the necessary fiber types for the MMD; 
% however, it may have more fiber types than MMD knows about so add these to the MMD list
function Add_Additional_Fiber_Types
global Muscle_Morph   Muscle_Model_Parameters   BM_Fiber_Type_Database
	FTD_fibertypenames={BM_Fiber_Type_Database.Fiber_Type_Name};
   for fibertype=1:length(FTD_fibertypenames)%Add any new fiber types to the existing database at the end of the Number_Units and Fractional_PCSA fields
      if isempty(strmatch(FTD_fibertypenames(fibertype),Muscle_Model_Parameters.Fiber_Type_Names, 'exact'))%There is a new fibertype to add
         Muscle_Model_Parameters.Fiber_Type_Names(length(Muscle_Model_Parameters.Fiber_Type_Names)+1)=FTD_fibertypenames(fibertype);
         %Enlarge vector size of all fiber type related variables
         for musclenumber=1:length(Muscle_Morph)
	         MMDcurrentnumberFT=length(Muscle_Morph(musclenumber).Number_Units);
            Muscle_Morph(musclenumber).Number_Units(MMDcurrentnumberFT+1)=0;
            Muscle_Morph(musclenumber).Fractional_PCSA(MMDcurrentnumberFT+1)=0;
            Muscle_Morph(musclenumber).Unit_PCSA(1,MMDcurrentnumberFT+1)=0;
      		Muscle_Morph(musclenumber).Apportion_Method(MMDcurrentnumberFT+1)=Muscle_Model_Parameters.Default_Apportion_Method;
         end
      end
   end



% The new BM_Fiber_Type_Database has been determined to have all the necessary fiber types for the MMD; 
% Now sort the FiberTypes (in the MMD) according to the rank of their recruitment
function Sort_Fiber_Types
global Muscle_Morph   Muscle_Model_Parameters   BM_Fiber_Type_Database
   recruitmentranks=[BM_Fiber_Type_Database.Recruitment_Rank];
   sortedrecruitmentranks=sort(recruitmentranks);
   for i=1:length(BM_Fiber_Type_Database)
	   ftdindex=min(find(sortedrecruitmentranks(i)==recruitmentranks));%Uses min in case two have the same rank
      sortedFTnames{i}=BM_Fiber_Type_Database(ftdindex).Fiber_Type_Name;
      recruitmentranks(ftdindex)=-1;	%Set it to a value that will not match up with any sortedrecruitmentranks
   end
   for i=1:length(BM_Fiber_Type_Database)
      mmdindex=strmatch(sortedFTnames{i},Muscle_Model_Parameters.Fiber_Type_Names, 'exact');
      temp_MM_Parameters.Fiber_Type_Names{i}=Muscle_Model_Parameters.Fiber_Type_Names{mmdindex};
      for musclenumber=1:length(Muscle_Morph)
         temp_MM(musclenumber).Number_Units(i)=Muscle_Morph(musclenumber).Number_Units(mmdindex);
         temp_MM(musclenumber).Fractional_PCSA(i)=Muscle_Morph(musclenumber).Fractional_PCSA(mmdindex);
         temp_MM(musclenumber).Unit_PCSA(:,i)=Muscle_Morph(musclenumber).Unit_PCSA(:,mmdindex);
      end
   end
   Muscle_Model_Parameters.Fiber_Type_Names=temp_MM_Parameters.Fiber_Type_Names;
   [Muscle_Morph.Number_Units]=deal(temp_MM.Number_Units);
   [Muscle_Morph.Fractional_PCSA]=deal(temp_MM.Fractional_PCSA);
   [Muscle_Morph.Unit_PCSA]=deal(temp_MM.Unit_PCSA);
   


%CUT TO CLIPBOARD
function Cut
global Muscle_Morph   BM_Clipboard_Muscle
   str={Muscle_Morph.Muscle_Name};
   [selection,ok]=listdlg('promptstring','Select muscle to cut','selectionmode','single','liststring',str,'name','Cut muscle');
   if ok
      BM_Clipboard_Muscle=Muscle_Morph(selection);
      Initialize_Muscle(selection);
   end
   Refresh;



%COPY a muscle TO CLIPBOARD
function Copy
global Muscle_Morph   BM_Clipboard_Muscle
   str={Muscle_Morph.Muscle_Name};
   [selection,ok]=listdlg('promptstring','Select muscle to copy','selectionmode','single','liststring',str,'name','Copy muscle');
   if ok
      BM_Clipboard_Muscle=Muscle_Morph(selection);
   end
   Refresh;
   
   

%PASTE a muscle FROM CLIPBOARD
function Paste
global Muscle_Morph   BM_Clipboard_Muscle
   musclenumber=inputdlg('Muscle number to paste into:','Paste from clipboard',1);
   if ~isempty(musclenumber)
      if ~isempty(str2num(char(musclenumber)))
         Muscle_Morph(str2num(char(musclenumber)))=BM_Clipboard_Muscle;
      end
   end
   Refresh;
   
   
   
%DELETE MUSCLE FROM database 
function Delete
global Muscle_Morph
	str={Muscle_Morph.Muscle_Name};
   [selection,ok]=listdlg('promptstring','Select muscle to delete','selectionmode','single','liststring',str,'name','Delete muscle');
   if ok
      for i=selection:length(Muscle_Morph)-1
         Muscle_Morph(i)=Muscle_Morph(i+1);
      end
      Initialize_Muscle(length(Muscle_Morph));
   end
   Refresh;



%INSERT (empty) MUSCLE into database
function Insert
global Muscle_Morph
   str={Muscle_Morph.Muscle_Name};
   [selection,ok]=listdlg('promptstring','Insert blank before which muscle','selectionmode','single','liststring',str,'name','Insert blank');
   if ok
      for i=length(Muscle_Morph)-1:-1:selection
         Muscle_Morph(i+1)=Muscle_Morph(i);
      end
      Initialize_Muscle(selection);
   end
   Refresh;



%IMPORT A MUSCLE FROM ANOTHER FILE
function Import
global BM_Clipboard_Muscle   BM_Save_Path
   [filename pathname]=uigetfile([BM_Save_Path '*.mat'],'Load muscle_model_database.mat file');
   if ~(filename==0)
      temp=load([pathname filename],'Muscle_Morph');
   else
      return
   end
   str={temp.Muscle_Morph.Muscle_Name};
   [selection,ok]=listdlg('promptstring','Select muscle to import','selectionmode','single','liststring',str,'name','Import muscle');
   if ok
      BM_Clipboard_Muscle=temp.Muscle_Morph(selection);
      Refresh;
   else
      return
   end   
   Refresh;



%AUTODISTRIBUTE PCSA amongst motor units, but decide whether this is for whole muscles or single muscles
function Auto_Distribute(algorithm)
global BM_Main_Window   BM_Distribute_Window sfunc_increase

	increase=0;		%initialize
    sfunc_increase =0;
   if strcmp(algorithm, 'geometric')
	   tempincrease=inputdlg('Enter the fractional increase in PCSA you would like between motor units','Fractional Increase');
   	if isempty(tempincrease)	return;	end;
		increase=str2num(tempincrease{1});
        sfunc_increase = increase;
      if increase<=0		return;	end
      algorithm=[num2str(increase) '-geometric'];
   end	
   if strcmp(get(BM_Main_Window,'visible'),'on')%Multiple muscle distribution from MAIN window
      Auto_Distribute_Whole_Muscle(algorithm, increase);
   elseif strcmp(get(BM_Distribute_Window,'visible'),'on')%Multiple Fiber-Types distribution from PCSA window
      Auto_Distribute_Multiple_Fiber_Types(algorithm, increase);
   end
   Refresh;
   
   

%AUTODISTRIBUTE PCSA amongst motor units FOR SELECTED MUSCLE(S)
function Auto_Distribute_Whole_Muscle(algorithm, increase)
global Muscle_Morph   Muscle_Model_Parameters
	str={Muscle_Morph.Muscle_Name};
   for i=length(str):-1:1
      if strcmp(str(i),'')
         str(i)='';
      end
   end
   [selection,ok]=listdlg('promptstring',{'Select muscle PCSA(s) to ', 'auto-distribute (CTRL for multiple)', ['(' algorithm ' algorithm)'], ' '},...
      	'selectionmode','multiple','liststring',str,'name','Auto distribute');
   if ok
      if length(str)==length(selection)	%if all muscles selected, then set all muscle apportioning to {algorithm}, including muscles not yet used
         Muscle_Model_Parameters.Default_Apportion_Method={algorithm};
         for i=1:length(Muscle_Morph)
            Muscle_Morph(i).Apportion_Method(1:length(Muscle_Model_Parameters.Fiber_Type_Names))={algorithm};
         end
      end 
      for i=1:length(selection)
         for j=1:length(Muscle_Model_Parameters.Fiber_Type_Names)
            Auto_Distribute_Fiber_Type(algorithm, increase, selection(i),j);
         end
      end
   end



%AUTODISTRIBUTE PCSA amongst motor units FOR SELECTED FIBERTYPE(S)
function Auto_Distribute_Multiple_Fiber_Types(algorithm, increase)
global Muscle_Morph   Muscle_Model_Parameters   BM_Distribute_Muscle
	str=Muscle_Model_Parameters.Fiber_Type_Names;
   for i=length(str):-1:1
      if Muscle_Morph(BM_Distribute_Muscle).Number_Units(i)==0
         str(i)='';
      end
   end
   [selection,ok]=listdlg('promptstring',{'Select Fibertype(s) to ', 'auto-distribute (CTRL for multiple)', ['(' algorithm ' algorithm)'], ' '},...
      	'selectionmode','multiple','liststring',str,'name','Auto distribute');
   if ok
      if length(str)==length(selection)	%if all fibertypes selected, then set all fibertype apportioning to {algorithm}, including fibertypes not yet used
         Muscle_Morph(BM_Distribute_Muscle).Apportion_Method(1:length(Muscle_Model_Parameters.Fiber_Type_Names))={algorithm};
      end 
      for i=1:length(selection)
         fibertypename=strmatch(str{selection(i)},Muscle_Model_Parameters.Fiber_Type_Names,'exact');
         Auto_Distribute_Fiber_Type(algorithm, increase, BM_Distribute_Muscle, fibertypename);
      end
   end



%AUTODISTRIBUTE motor unit PCSAs FOR A SINGLE GIVEN FIBER Type within a given muscle
%There are several options for this autodistribution. 
function Auto_Distribute_Fiber_Type(algorithm, increase, musclenumber, fibertypenumber)
global Muscle_Morph    Muscle_Model_Parameters    BM_Fiber_Type_Database ;
  
	Muscle_Morph(musclenumber).Apportion_Method{fibertypenumber}=algorithm;
	if Muscle_Morph(musclenumber).Number_Units(fibertypenumber)>0%Auto distribute
      %Find the recruitment rank for the appropriate fiber type
      allfibertypenames={BM_Fiber_Type_Database(:).Fiber_Type_Name};
      ftdindex=strmatch(Muscle_Model_Parameters.Fiber_Type_Names(fibertypenumber), allfibertypenames, 'exact');
      recruitmentrank=BM_Fiber_Type_Database(ftdindex).Recruitment_Rank;
		numberunits= Muscle_Morph(musclenumber).Number_Units(fibertypenumber);
      switch algorithm
      case 'manual'
			newTotalPCSA=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber);
			oldTotalPCSA=sum(Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber));
		   for currentunit=1:Muscle_Morph(musclenumber).Number_Units(fibertypenumber) 
				oldPCSA=Muscle_Morph(musclenumber).Unit_PCSA(currentunit,fibertypenumber);
				Muscle_Morph(musclenumber).Unit_PCSA(currentunit,fibertypenumber)=oldPCSA*newTotalPCSA/oldTotalPCSA;
			end
		case 'equal', 
			PCSA=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)/numberunits;
		   for currentunit=1:Muscle_Morph(musclenumber).Number_Units(fibertypenumber) 
				Muscle_Morph(musclenumber).Unit_PCSA(currentunit,fibertypenumber)=PCSA;
			end
		case 'default',
         %This distribution scheme works by giving various motor units of a specific fiber types,
         %different PCSAs.  The first one (which will be the first one recruited in Simulink) has
         %the smallest and the last motor unit the largest.  The exact distribution depends upon
         %recruitment rank.  The higher the recruitment rank for motor units of a given fiber type,
         %the less the difference in motor unit sizes of motor units of that fiber type
      	denominator=sum(recruitmentrank+[1:Muscle_Morph(musclenumber).Number_Units(fibertypenumber)]);
		   for currentunit=1:Muscle_Morph(musclenumber).Number_Units(fibertypenumber)
	      	Muscle_Morph(musclenumber).Unit_PCSA(currentunit,fibertypenumber)=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)*(recruitmentrank+currentunit)/denominator;
         end
      otherwise
         startchar=findstr('geometric', algorithm);
         if startchar
            increase=str2num(algorithm(1:(startchar-2)));
		   	for currentunit=1:Muscle_Morph(musclenumber).Number_Units(fibertypenumber)
   	    		Muscle_Morph(musclenumber).Unit_PCSA(currentunit,fibertypenumber)=(1+increase)^(currentunit-1);
      	  	end
        		total=sum(Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber));
      		correction=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)/total;
            Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber)=Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber)*correction;
         end
		end %end the case statement
	end
   %Trim all trailing motor units with a zero PCSA
   for trimindex=size(Muscle_Morph(musclenumber).Unit_PCSA,1):-1:max(max(Muscle_Morph(musclenumber).Number_Units)+1,2)
	   Muscle_Morph(musclenumber).Unit_PCSA(trimindex,:)=[];
	end



%PARSE information in FIBERTYPE Unit ETBs BACK INTO Muscle_Morph structure
%ALSO RECALC PCSA/F0 AND DO AUTO-DISTRIBUTION
%This function is only called when one of the ETBs in EITHER the Main window or the Manually Distribute window is edited.
function Parse_Motor_Units
global BM_Main_ETB   BM_Distribute_ETB   BM_First_Muscle   BM_First_Fiber   BM_Main_Vars   Muscle_Morph
global BM_Main_Window   BM_Distribute_Window  BM_Distribute_Muscle   Distribute_BM_First_Fiber
	if strcmp(get(BM_Main_Window,'visible'),'on')%if Main window is open
   	[rows,cols]=find(gco==BM_Main_ETB);
   	string=get(BM_Main_ETB(rows,cols),'string');
      musclenumber=BM_First_Muscle+rows;
      fibertypenumber=BM_First_Fiber+cols-length(BM_Main_Vars);
   elseif strcmp(get(BM_Distribute_Window,'visible'),'on')%if Manually Distribute window is visible
   	[rows,cols]=find(gco==BM_Distribute_ETB);
   	string=get(BM_Distribute_ETB(rows,cols),'string');
      musclenumber=BM_Distribute_Muscle;
      fibertypenumber=Distribute_BM_First_Fiber+cols;
   end
   loc=findstr(string,'/');
   if length(loc)~=1
      msgbox('You must input Unit data in the form xx/yy, where xx is the fraction of PCSA apportioned to that fiber type and yy is the number of Units');
      return
   elseif ~isnumeric(str2num(string(1:loc(1)-1)))|~isnumeric(str2num(string(loc(1)+1:length(string))))
      msgbox('You must input Unit data in the form xx/yy, where xx is the fraction of PCSA apportioned to that fiber type and yy is the number of Units');
      return
   else%A valid string was put into the field!
      oldpcsa=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber);
      oldunits=Muscle_Morph(musclenumber).Number_Units(fibertypenumber);
      Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)=str2num(string(1:loc(1)-1));
      Muscle_Morph(musclenumber).Number_Units(fibertypenumber)=str2num(string(loc(1)+1:length(string)));
      %Some error checking on number of motor units input
      if (Muscle_Morph(musclenumber).Number_Units(fibertypenumber)==0)&(Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)~=0)
         button=questdlg('Number of motor units cannot be zero with a non-zero assigned PCSA!','Error','Ok','Ok');
         Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)=oldpcsa;
         Muscle_Morph(musclenumber).Number_Units(fibertypenumber)=oldunits;
         Refresh;
         return
      elseif (round(Muscle_Morph(musclenumber).Number_Units(fibertypenumber))~=Muscle_Morph(musclenumber).Number_Units(fibertypenumber))|(Muscle_Morph(musclenumber).Number_Units(fibertypenumber)<0)
         button=questdlg('Number of motor units must be a positive integer!','Error','Ok','Ok');
         Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)=oldpcsa;
         Muscle_Morph(musclenumber).Number_Units(fibertypenumber)=oldunits;
         Refresh;
         return
      end
      %If user has increased number of units, then make sure there are new indexes inserted into the Unit_PCSA matrix
      if Muscle_Morph(musclenumber).Number_Units(fibertypenumber)>oldunits
         Muscle_Morph(musclenumber).Unit_PCSA(oldunits+1:Muscle_Morph(musclenumber).Number_Units(fibertypenumber),fibertypenumber)=0;
      else%Zero out deleted units if user has decreased the number of units
         Muscle_Morph(musclenumber).Unit_PCSA(Muscle_Morph(musclenumber).Number_Units(fibertypenumber)+1:oldunits,fibertypenumber)=0;
      end
      max_number_units=max([Muscle_Morph(musclenumber).Number_Units]);
      Muscle_Morph(musclenumber).Unit_PCSA=Muscle_Morph(musclenumber).Unit_PCSA(1:max_number_units,:);
      
      %***ERROR from Francisco
      
      algorithm=Muscle_Morph(musclenumber).Apportion_Method{fibertypenumber};
      Auto_Distribute_Fiber_Type(Muscle_Morph(musclenumber).Apportion_Method{fibertypenumber}, 0, musclenumber, fibertypenumber);
   end
   Refresh;
   
   
   
%Using the PCSA values for individual units, update the fractional PCSA alloted to a single fibertype
%This function is only called when one of the ETBs in the Manually Distribute window is edited.
function Update_Fractional_PCSA
global BM_Distribute_ETB   Muscle_Morph   BM_First_Unit
global BM_Distribute_Window  BM_Distribute_Muscle   Distribute_BM_First_Fiber
	[rows,cols]=find(gco==BM_Distribute_ETB);
	string=get(BM_Distribute_ETB(rows,cols),'string');
	fibertypenumber=Distribute_BM_First_Fiber+cols;
	unitnumber=BM_First_Unit+rows-2;
   Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA(unitnumber,fibertypenumber)=str2num(string);
   TotalPCSA=sum(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA(:,fibertypenumber));
   Muscle_Morph(BM_Distribute_Muscle).Fractional_PCSA(fibertypenumber)=TotalPCSA;
   %Muscle_Morph(BM_Distribute_Muscle).Apportion_Method(fibertypenumber)={'manual'};
   numberfibertypes=size(Muscle_Morph(BM_Distribute_Muscle).Unit_PCSA,2);
   Muscle_Morph(BM_Distribute_Muscle).Apportion_Method(1:numberfibertypes)={'manual'};
   Refresh;

   

%Check Muscle Names to ensure that there are no duplicates and that all fibertypes taht are supposed to be
%there, are present.  THIS IS CALLED WHEN SAVING, BUILDING A BLOCK OR REBUILDING THE MODEL
function [ok]=Check_Names
global Muscle_Morph   BM_Fiber_Type_Database   BM_Distribute_Muscle   Muscle_Model_Parameters
	ok=1;%By default, say that it is ok to proceed
   %Check to see if all req'd fibertypes are actually present.
   for i=1:length(BM_Fiber_Type_Database)
      ftdtype=BM_Fiber_Type_Database(i).Fiber_Type_Name;
      mmdindex=strmatch(ftdtype, Muscle_Model_Parameters.Fiber_Type_Names,'exact');
      if mmdindex==0
         disp(['Could not find a referenced fiber type (' ftdtype ') in the Muscle_Morph file']);
         return;
      end
   end
   %Check that all muscles have unique names
   allmusclenames={Muscle_Morph(:).Muscle_Name};
	for numberofmuscles=length(Muscle_Morph):-1:1		%Strip trailing empty entries from structure
	   if ~isempty(Muscle_Morph(numberofmuscles).Muscle_Name),   break,   end
	end
	for i = 1:numberofmuscles-1
  		if length(strmatch(Muscle_Morph(i).Muscle_Name, allmusclenames, 'exact'))>1
         buttonname=questdlg('All muscles must have unique names! Please check and fix before proceeding!','Non-unique names detected!','Ok','Ok');
	      ok=0;
	      return
	   end
	end
   
   
   
%CHECK PCSAs to make sure that they add up to correct amounts
%and check Muscle Names to ensure that there are no duplicates
%THIS IS CALLED WHEN BUILDING A BLOCK OR REBUILDING THE MODEL
function [ok]=Check_PCSA(selection)
global Muscle_Morph   BM_Fiber_Type_Database   BM_Distribute_Muscle
   ok=1;					%By default, say that it is ok to proceed
   if nargin==0		%if nargin=0, then check all muscles (i.e. set 'selection' to all musclenumbers
   	for i=length(Muscle_Morph):-1:1%Strip trailing empty muscle entries from structure
      	if ~isempty(Muscle_Morph(i).Muscle_Name),   break,   end
		end
      selection=[1:i];
   end
   for i=1:length(selection)
      musclenumber=selection(i);
   	%For EACH muscle, check that the total PCSA for all motor units of each fiber type
   	%is the same as the fraction of total PCSA alloted to motor units of that fiber type 
      todo=Check_Fiber_Type_PCSA_Apportioning(musclenumber);
      if strcmp(todo,'readjust PCSAs')
         ok=0;
         BM_Distribute_Muscle=musclenumber;
         Manually_Distribute;
         return;
      end
   	%For each muscle check that the total PCSA from all fiber types is within 1% of 1.00
	   totalpcsa=sum(Muscle_Morph(musclenumber).Fractional_PCSA);
	   if (totalpcsa<0.99)|(totalpcsa>1.01)%Not within 1%; give prompt
	      selection=questdlg(['Fractional PCSA for ' Muscle_Morph(musclenumber).Muscle_Name ' totals ' num2str(totalpcsa) '; it should total 1.0'],...
	         'Error in Fractional PCSA',...
	         'Rescale maintaining current ratios','Accept current values','Cancel and manually readjust','Rescale keeping same PCSA ratios');
         switch selection
         case 'Rescale maintaining current ratios'
            if isfield(Muscle_Morph, 'Fractional_PCSA')
               total_PCSA=sum(Muscle_Morph(musclenumber).Fractional_PCSA);
               if total_PCSA>0
	         		coefficient=1/total_PCSA;
	         		Muscle_Morph(musclenumber).Fractional_PCSA=Muscle_Morph(musclenumber).Fractional_PCSA*coefficient;
                  Muscle_Morph(musclenumber).Unit_PCSA=Muscle_Morph(musclenumber).Unit_PCSA*coefficient;
               end
            end
	      case 'Accept current values'
	      case 'Cancel and manually readjust'
            ok=0;
	         return%Return to calling function
	      end
	   end
   	%For EACH muscle, check to see if any motor unit PCSA's are zero.
      Number_Units=sum(Muscle_Morph(musclenumber).Number_Units);
      Number_Units_PCSA_Above_Zero=sum(sum(Muscle_Morph(musclenumber).Unit_PCSA>0));
      if Number_Units>Number_Units_PCSA_Above_Zero
   	   todo=questdlg(['One or more motor units of muscle ''' Muscle_Morph(musclenumber).Muscle_Name,...
            ''' has 0 PCSA.'],  '0 PCSA warning!', 'Continue','readjust PCSAs', 'Continue');
      	if strcmp(todo,'readjust PCSAs')
         	BM_Distribute_Muscle=musclenumber;
            Manually_Distribute;
            ok=0;
	         return%Return to calling function
      	end
      end
   end
   Refresh;

   
   
%For each fiber type in ONE given muscle, check that the total PCSA for all motor units of that fiber type
%is the same as the fraction of total PCSA alloted to motor units of that fiber type for that muscle
function [todo]=Check_Fiber_Type_PCSA_Apportioning(musclenumber)
global Muscle_Morph   BM_Distribute_Muscle
	todo='nothing';		%set default
	for fibertypenumber=1:size(Muscle_Morph(musclenumber).Unit_PCSA,2)
      totalpcsa=sum(Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber));
      if (totalpcsa>Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)*1.01)|(totalpcsa<Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)*.99)
         selection=questdlg(['Fractional PCSA for ' Muscle_Morph(musclenumber).Muscle_Name...
               ', motor units of fiber type #' num2str(fibertypenumber) ' totals ' num2str(totalpcsa)...
               '; should total ' num2str(Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber))],...
            	'Error in Unit PCSA','Rescale keeping same PCSA ratios','Leave as is','Cancel and manually readjust','Rescale keeping same PCSA ratios');
         coefficient=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)/totalpcsa;
         switch selection
         case 'Rescale keeping same PCSA ratios'
            Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber)=Muscle_Morph(musclenumber).Unit_PCSA(:,fibertypenumber)*coefficient;
         case 'Leave as is'
            Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)=Muscle_Morph(musclenumber).Fractional_PCSA(fibertypenumber)/coefficient;
         case 'Cancel and manually readjust'
            todo='readjust PCSAs';
         end
      end
   end
   
   
   
%Check Muscle Names to ensure that there are no duplicates and that all fibertypes taht are supposed to be
%there, are present.  THIS IS CALLED WHEN SAVING, BUILDING A BLOCK OR REBUILDING THE MODEL
function [ok]=Check_Other_Parameters(selection)
global Muscle_Morph   BM_Fiber_Type_Database   BM_Distribute_Muscle   Muscle_Model_Parameters
   ok=1;					%By default, say that it is ok to proceed
   if nargin==0		%if nargin=0, then check all muscles (i.e. set 'selection' to all musclenumbers
   	for i=length(Muscle_Morph):-1:1%Strip trailing empty muscle entries from structure
      	if ~isempty(Muscle_Morph(i).Muscle_Name),   break,   end
		end
      selection=[1:i];
   end
   for i=1:length(selection)
      musclenumber=selection(i);
      if Muscle_Morph(musclenumber).Mass<=0
	      selection=msgbox(['Mass of ' Muscle_Morph(musclenumber).Muscle_Name ' <= 0.  It must be > 0 to continue'],'Error in Mass','Error');
         ok=0;
         break
      end
      if Muscle_Morph(musclenumber).L0<=0
	      selection=msgbox(['Lo for ' Muscle_Morph(musclenumber).Muscle_Name ' <= 0.  It must be > 0 to continue'],'Error in Lo','Error');
         ok=0;
         break
      end
      if Muscle_Morph(musclenumber).L0T<=0
	      selection=msgbox(['LoT for ' Muscle_Morph(musclenumber).Muscle_Name ' <= 0.  It must be > 0 to continue'],'Error in LoT','Error');
         ok=0;
         break
      end
      if Muscle_Morph(musclenumber).Lpath<=0
	      selection=msgbox(['Whole-muscle (i.e. path length) Lmax for ' Muscle_Morph(musclenumber).Muscle_Name ' <= 0.  It must be > 0 to continue'],'Error in Lmax','Error');
         ok=0;
         break
      end
   end
   
         
   
%This function sets the recruitment type to be used for the SIMULINK blocks.   
function Set_Recruitment
global Muscle_Model_Parameters
	prompt='Select Recruitment Strategy';
	str={'Natural' 'Natural Discrete (s-function)' 'Natural Continuous (s-function)' 'Intramuscular FES (s-function)'};%<DSadd1>
    strshow={'Natural Discrete (Brown & Cheng)' 'Natural Discrete (s-function)' 'Natural Continuous (s-function)' 'Intramuscular FES (s-function)'};%<DSadd1>
	init=strmatch(Muscle_Model_Parameters.Recruitment_Type,str,'exact');
	[selection,ok]=listdlg('promptstring',prompt,'selectionmode','single','liststring',strshow,'InitialValue', init, 'name','Recruitment Strategy');
   if ok
      Muscle_Model_Parameters.Recruitment_Type=str{selection};
   end




%This function sets the recruitment type to be used for the SIMULINK blocks.   
function Set_Block_Outputs
global Muscle_Model_Parameters
	prompt={'Select SIMULINK block outputs', 'in addition to Force (N).  The' , '<none> selection is ignored if', 'more than one selection is made.', ' ', ' '};
   %*** for next version with energetics and power
   %str={'<none>' 'Activation' 'Force (Fo)' 'Fascicle Length (Lo)' 'Fascicle Velocity (Lo/s)' 'Rate of Energy Consumption (W)' 'Power produced by Muscle (W)'};
   str={'<none>' 'Activation' 'Force (Fo)' 'Fascicle Length (Lo)' 'Fascicle Velocity (Lo/s)'};
   init=1;
   for i=1:length(Muscle_Model_Parameters.Additional_Outports)
      init(i)=strmatch(Muscle_Model_Parameters.Additional_Outports{i},str,'exact');
   end
    
   [selection,ok]=listdlg('promptstring',prompt,'selectionmode','multiple','liststring',str,...
      	'InitialValue', init, 'name','Additional Output Blocks', 'ListSize', [200 300]);
   if ok
      %if more than one choice has been selected, then ignore the <none> choice
      if and(length(selection)>1, selection(1)==1)
         selection(1)=[];
      end
      Muscle_Model_Parameters.Additional_Outports=str(selection);
   end


% CREATE SIMULINK Muscle_Block Using S-function
%<DSadd1> 12/2007 - Modification for adding s-function to VM 
function systemname = Create_sfun(selection)
global Muscle_Morph   Muscle_Model_Parameters  BM_FTD_General_Parameters BM_Fiber_Type_Database Totalnumberfibertypes_sfunc sfunc_increase 
            
    % Extract number of fiber types and index of fiber types:     
    aa=(Muscle_Morph(selection).Fractional_PCSA(1:Totalnumberfibertypes_sfunc)~=zeros(size(Muscle_Morph(selection).Fractional_PCSA(1:Totalnumberfibertypes_sfunc))));
    index_sfunc=[];
    for ii=1:length(aa)
        if aa(ii)
        index_sfunc=[index_sfunc ii];
        end
    end
    numberfibertypes_sfunc=length(index_sfunc);

    % Extract parameters to be passed to the S-Function (Total Parameters - 58)
    % Note: - Refer Virtual_Muscle_SFunction.c for the list of parameters - 

    bb1=[BM_Fiber_Type_Database.Recruitment_Rank];
    bb2=[BM_Fiber_Type_Database.V0_5];
    bb3=[BM_Fiber_Type_Database.F0_5];
    bb4=[BM_Fiber_Type_Database.Fmin];
    bb5=[BM_Fiber_Type_Database.Fmax];
    bb6=[BM_Fiber_Type_Database.FL_omega];
    bb7=[BM_Fiber_Type_Database.FL_beta];
    bb8=[BM_Fiber_Type_Database.FL_rho];	
    bb9=[BM_Fiber_Type_Database.Vmax];
    bb10=[BM_Fiber_Type_Database.cV0];	
    bb11=[BM_Fiber_Type_Database.cV1];	
    bb12=[BM_Fiber_Type_Database.aV0];
    bb13=[BM_Fiber_Type_Database.aV1];
    bb14=[BM_Fiber_Type_Database.aV2];
    bb15=[BM_Fiber_Type_Database.bV];
    bb16=[BM_Fiber_Type_Database.af];
    bb17=[BM_Fiber_Type_Database.nf0];
    bb18=[BM_Fiber_Type_Database.nf1];
    bb19=[BM_Fiber_Type_Database.TL];
    bb20=[BM_Fiber_Type_Database.Tf1];
    bb21=[BM_Fiber_Type_Database.Tf2];
    bb22=[BM_Fiber_Type_Database.Tf3];
    bb23=[BM_Fiber_Type_Database.Tf4];
    bb24=[BM_Fiber_Type_Database.aS1];
    bb25=[BM_Fiber_Type_Database.aS2];
    bb26=[BM_Fiber_Type_Database.TS];
    bb27=[BM_Fiber_Type_Database.cY];
    bb28=[BM_Fiber_Type_Database.VY];
    bb29=[BM_Fiber_Type_Database.TY];
    bb30=[BM_Fiber_Type_Database.ch0];
    bb31=[BM_Fiber_Type_Database.ch1];
    bb32=[BM_Fiber_Type_Database.ch2];
    bb33=[BM_Fiber_Type_Database.ch3];
    bb34=[Muscle_Morph(selection).Number_Units];
    bb35=[Muscle_Morph(selection).Fractional_PCSA];        
    bb36=[];
    bb36T=[Muscle_Morph(selection).Unit_PCSA];
    for iii=1:numberfibertypes_sfunc
        bb36=[bb36;bb36T(1:bb34(index_sfunc(iii)),index_sfunc(iii))];
    end
    bb36=bb36'; 

    Recruitment_sfunc=[{'Natural'} {'Natural Discrete (s-function)'} {'Natural Continuous (s-function)'} {'Intramuscular FES (s-function)'}]; %compare to Muscle_Model_Parameters.Recruitment_Type
    if strmatch(Muscle_Model_Parameters.Recruitment_Type,Recruitment_sfunc,'exact')==3; %%<DSadd6>: make sure when Continuous, #MUs=1 for each fiber type
%         if sum(bb34==ones(size(bb34)))~=length(bb34) %can give a warning
%         in GUI inputs, but following statement gurrantees the parameter
%         passed into S-function is correct
        bb34=ones(size(bb34));
        bb36=bb35(index_sfunc);
    end

    bb38 = [1 0 0 0 0]; %Additional Ports
    pstr={'<none>' 'Activation' 'Force (Fo)' 'Fascicle Length (Lo)' 'Fascicle Velocity (Lo/s)'};              
    for z=1:length(Muscle_Model_Parameters.Additional_Outports)
       bb38T=strmatch(Muscle_Model_Parameters.Additional_Outports{z},pstr,'exact');
       switch bb38T 
           case 2
               bb38(1)=0; bb38(2)=1;
           case 3
               bb38(1)=0; bb38(3)=1;
           case 4
               bb38(1)=0; bb38(4)=1;
           case 5
               bb38(1)=0; bb38(5)=1;
       end                                             
    end

    bb39 = 0; %Apportion Method              
    algstr={'manual' 'default' 'equal' 'geometric'};
    bb37 = strmatch(Muscle_Morph(selection).Apportion_Method(1),algstr);
    if isempty(bb37)
      bb37 = 4;
      algorithm = char(Muscle_Morph(selection).Apportion_Method(1));                  
      startchar=findstr('geometric', algorithm);
      if startchar
          bb39=str2num(algorithm(1:(startchar-2)));
      end
    end

    % - Assign values to all parameters passed to the S-Function (Total Parameters - 58) 
    % Note, the order of parameters below corresponds to the order in the mask NOT the
    % order in the s-function!
                                     
    sfunParameters = [[num2str(strmatch(Muscle_Model_Parameters.Recruitment_Type,Recruitment_sfunc,'exact')) '|']... %Recruitment Type (s)
          ['[' num2str(bb38) ']|']... %Additional Ports (v)
          [num2str(Muscle_Morph(selection).L0) '|']... %Optimal Fascicle Length (s)
          [num2str(Muscle_Morph(selection).L0T) '|']... %Optimal Tendon Length (s)
          [num2str(Muscle_Morph(selection).Lpath) '|']... %Maximum Path Length (s)
          [num2str(Muscle_Morph(selection).Mass) '|']... %Muscle Mass (s)
          [num2str(Muscle_Morph(selection).Ur) '|']... %Maximum Recruitment Activation (s)
          [num2str(BM_FTD_General_Parameters.Specific_Tension) '|']... %Specific Tension (s)
          [num2str(BM_FTD_General_Parameters.Viscosity) '|']... %Viscosity (s)
          [num2str(BM_FTD_General_Parameters.Sarcomere_Length) '|']... %Optimal Sacrcomere Length (s)
          [num2str(BM_FTD_General_Parameters.c1) '|']... %C1 (s)
          [num2str(BM_FTD_General_Parameters.k1) '|']... %K1 (s)
          [num2str(BM_FTD_General_Parameters.Lr1) '|']... %LR1 (s)
          [num2str(BM_FTD_General_Parameters.c2) '|']... %C2 (s)
          [num2str(BM_FTD_General_Parameters.k2) '|']... %K2 (s)
          [num2str(BM_FTD_General_Parameters.Lr2) '|']... %LR2 (s)
          [num2str(BM_FTD_General_Parameters.cT) '|']... %CT (s)
          [num2str(BM_FTD_General_Parameters.kT) '|']... %KT (s)
          [num2str(BM_FTD_General_Parameters.LrT) '|']... %LRT (s)
          [num2str(numberfibertypes_sfunc) '|']... %Number of fiber Types (S)
          ['[' num2str(bb35(index_sfunc)) ']|']... %Fractional PCSA for each motor fiber type (v)
          ['[' num2str(bb34(index_sfunc)) ']|']... %Number of motor units in each muscle fiber type (v)
          [num2str(bb37) '|']... %Apportion method (s)
          [num2str(bb39) '|']... %Fractoinal increase in PCSA for Geometric Aportion method (s)
          ['[' num2str(bb36) ']|']... %PCSA for each motor unit (v)
          ['[' num2str(bb1(index_sfunc)) ']|']... %Recruitment Rank (v)
          ['[' num2str(bb2(index_sfunc)) ']|']...%V0.5 (v)
          ['[' num2str(bb3(index_sfunc)) ']|']...%f0.5(v)
          ['[' num2str(bb4(index_sfunc)) ']|']...%fmin (v)
          ['[' num2str(bb5(index_sfunc)) ']|']...%fmax (v)
          ['[' num2str(bb6(index_sfunc)) ']|']...%FL_omega (v)
          ['[' num2str(bb7(index_sfunc)) ']|']...%FL_beta (v)
          ['[' num2str(bb8(index_sfunc)) ']|']...%FL_rho (v)
          ['[' num2str(bb9(index_sfunc)) ']|']...%Vmax (v)
          ['[' num2str(bb10(index_sfunc)) ']|']...%CV0 (v)
          ['[' num2str(bb11(index_sfunc)) ']|']...%cV1 (v)
          ['[' num2str(bb12(index_sfunc)) ']|']...%aV0 (v)
          ['[' num2str(bb13(index_sfunc)) ']|']... %aV1 (v)
          ['[' num2str(bb14(index_sfunc)) ']|']...%aV2 (v)
          ['[' num2str(bb15(index_sfunc)) ']|']...%bV (v)
          ['[' num2str(bb16(index_sfunc)) ']|']...%aF (v)
          ['[' num2str(bb17(index_sfunc)) ']|']...%nf0 (v)
          ['[' num2str(bb18(index_sfunc)) ']|']...%nf1 (v)
          ['[' num2str(bb19(index_sfunc)) ']|']...%TL (v)
          ['[' num2str(bb20(index_sfunc)) ']|']...%Tf1 (v)
          ['[' num2str(bb21(index_sfunc)) ']|']...%Tf2 (v)
          ['[' num2str(bb22(index_sfunc)) ']|']...%Tf3 (v)
          ['[' num2str(bb23(index_sfunc)) ']|']...%Tf4 (v)
          ['[' num2str(bb24(index_sfunc)) ']|']...%AS1 (v)
          ['[' num2str(bb25(index_sfunc)) ']|']...%AS2 (v)
          ['[' num2str(bb26(index_sfunc)) ']|']...%TS (v)
          ['[' num2str(bb27(index_sfunc)) ']|']...%cY (v)
          ['[' num2str(bb28(index_sfunc)) ']|']...%VY (v)
          ['[' num2str(bb29(index_sfunc)) ']|']...%TY (v)
          ['[' num2str(bb30(index_sfunc)) ']|']...%ch0(v)
          ['[' num2str(bb31(index_sfunc)) ']|']...%ch1 (v)
          ['[' num2str(bb32(index_sfunc)) ']|']...%ch2 (v)
          ['[' num2str(bb33(index_sfunc)) ']']]; %ch3 (v)                                          
              
       % Create Simulink Block
       % Note: - Refer CreateSimulinkBlock_sfun.m       
       systemname = CreateSimulinkBlock_sfun(sfunParameters,selection);

       
%<DSadd1> 12/2007 - End of Create_sfun

    
%CREATE SIMULINK Muscle_Block(s)? 
%This function queries the user for which muscles to create Simulink blocks for and then creates them
function Create
global Muscle_Morph   Muscle_Model_Parameters  BM_FTD_General_Parameters BM_Fiber_Type_Database Totalnumberfibertypes_sfunc sfunc_increase 
    
   str={Muscle_Morph.Muscle_Name};
   for i=length(str):-1:1
      if strcmp(str(i),'')
         str(i)='';
      else
         break
      end
   end
   [selection,ok]=listdlg('promptstring','Select muscle(s) to create block of (CTRL for multiple)','selectionmode','multiple','liststring',str,'name','Create block');
   ok2=Check_Names;%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
   if ~ok2,	return,   end
   ok2=Check_PCSA(selection);%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
   if ~ok2,	return,   end
   ok2=Check_Other_Parameters(selection);%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
   if ~ok2,	return,   end
   if ok
        pleasewaitmsgbox = msgbox('Creating Simulink Muscle Blocks.  Please wait...');
        pause(0.1);		%This pause is necessary to ensure that the dialog box actually displays...
          
        for i=1:length(selection)        
              if strcmp(Muscle_Model_Parameters.Recruitment_Type,'Natural')
                  systemname=CreateSimulinkBlock(selection(i));
                   open_system(systemname);
              else
                  systemname=Create_sfun(selection(i));  %<DSadd1> 12/2007 - Modification for adding s-function to VM    
                  open_system(systemname);
              end

        end
    
        if ishandle(pleasewaitmsgbox),	delete(pleasewaitmsgbox), 	end
        tempmsgbox=msgbox('Done creating muscle blocks!');
        pause(0.5);
        if ishandle(tempmsgbox), 			delete(tempmsgbox),			end;
   end



%REBUILD EXISTING SIMULINK MODEL?
%This function goes through a previous simulink model and replaces all (muscle) blocks with names 
%that are the same as muscles in the Muscle_Morph_Database currently in memory.
function Rebuild
global Muscle_Morph   BM_Save_Path   Muscle_Model_Parameters
   [filename pathname]=uigetfile([BM_Save_Path '*.mdl'],'Load existing SIMULINK model');
   if (filename==0)
      return
   end
   ok2=Check_Names;%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
   if ~ok2,	return,   end
   ok2=Check_PCSA;%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
   if ~ok2,	return,   end
   ok2=Check_Other_Parameters;%Sadly we have to put this after the get file name call; this is because MATLAB doesn't process ETB callbacks until after focus leaves the ETB; uimenu selection doesn't do this
  
   if ~ok2,	return,   end
	oldsystemname=filename(1:length(filename)-4);
   if isempty(find_system('name',oldsystemname))
      open_system([pathname,filename]);
   else
      open_system([filename]);
   end
    
   pleasewaitmsgbox = msgbox('Replacing Simulink Muscle Blocks.  Please wait...');
   pause(0.1);		%This pause is necessary to ensure that the dialog box actually displays...
   
   for currentmuscle=1:length(Muscle_Morph)%Replace any existing muscles in the model      
      oldmusclearray=find_system(oldsystemname,'LookUnderMasks','on','name',Muscle_Morph(currentmuscle).Muscle_Name);     
      if ~isempty(oldmusclearray)          
            %<DSadd1> 12/2007 - Modification for adding s-function to VM  
            Recruitment_sfunc=[{'Natural'} {'Natural Discrete (s-function)'} {'Natural Continuous (s-function)'} {'Intramuscular FES (s-function)'}]; %compare to Muscle_Model_Parameters.Recruitment_Type
            RType=strmatch(Muscle_Model_Parameters.Recruitment_Type,Recruitment_sfunc,'exact');
            if RType == 1
                systemname=CreateSimulinkBlock(currentmuscle);            	            	                                      
            else %S-Function                
                systemname=Create_sfun(currentmuscle);
            end % end of RType else
            
            newmuscle=[systemname '/' Muscle_Morph(currentmuscle).Muscle_Name];
            
            for i=1:length(oldmusclearray)
                oldmuscle=oldmusclearray{i};                      
                newposition=get_param(newmuscle, 'position');
                oldposition=get_param(oldmuscle, 'position');
                relativedifference=[0 ((newposition(4)-newposition(2))-(oldposition(4)-oldposition(2))) 0 0 ];
                finalposition=oldposition-relativedifference;
                set_param(oldmuscle,'position',finalposition+[0 10000 0 10000]);
            end

            %Replace blocks & rename
            replace_block(oldsystemname,'name',Muscle_Morph(currentmuscle).Muscle_Name,newmuscle,'noprompt');
            
            %move all newly replaced blocks to their appropriate positions
            for i=1:length(oldmusclearray)
                position=get_param(oldmusclearray{i},'position');
                set_param(oldmusclearray{i},'position',position-[0 10000 0 10000]);
            end
            
            close_system(systemname,0);         
                                               
      end  % end of ~isempty(oldmusclearray) 
   end % end of currentmuscle=1:length(Muscle_Morph)
   
   if ishandle(pleasewaitmsgbox), 	delete(pleasewaitmsgbox),  end;
   tempmsgbox=msgbox('Done replacing muscle blocks!');
   pause(1);
   if ishandle(tempmsgbox), 			delete(tempmsgbox),			end;
   
   

%HELP DIALOG BOX
function Help
global BM_Main_Window   BM_Distribute_Window
   if ~isempty(findobj('tag','MMD_BM_Main_Window'))%is this window that is open
      if strcmp(get(BM_Main_Window,'visible'),'on')%and is it visible?
         s=strvcat(...
            ['This function is used to describe the muscles in your simulation.  Muscles are built from ',...
               '''motor-units'' of different fiber types acting in parallel.  In order to use this function ',...
               'the user must first select a valid Fiber Type Database file.',...
            	' ',...
               'Once a valid Fiber Type Database has been chosen, the user can create muscles, entering ',...
               'in the relevant anatomical data for the muscles.  The fractional PCSA apportioned to each ',...
               'fiber type is chosen here on the main window, along with the # of motor units that will be ',...
               'used to simulate each fiber type.  Initially, the distribution of PCSA amongst motor-units ',...
               'within a fiber type is distributed automatically, but this can be overriden manually using ',...
               'Edit Motor Unit PCSA Distribution menu selection.',...
            	' ',...
               'If the user wants the current muscle descriptions to be associated with a different fiber ',...
               'type database, this can be done - however, the new Fiber Type Database must have at least ',...
               'as many fiber types as are currently used by the Muscle Model description.  The fiber type ',...
               'names do not have to the same because the user will be prompted for ''replacement'' ',...
               'choices if there are differences.',...
            	' ',...
               'Once a Muscle Model description has been completed (and saved, etc.), Simulink blocks can ',...
               'be generated automatically.  Furthermore, existing Simulink blocks can be replaced by new ',...
               'ones automatically.  This latter functionality (called REBUILD) requires that the muscle ',...
               'names be the same.  This function works by searching the selected Simulink file for all',...
               'block (of type block diagram) that have the same names as muscles in the database.  Note ',...
               'that all levels of the Simulink diagram are searched for blocks with the appropriate names.',...
            	' ',...
            	'As with the BuildFiberTypes function, basic functions such as copy, replace, and import exist.']);
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-25 b(2)-25 b(3)+50 b(4)+20]);   
      end
   end
   if ~isempty(findobj('tag','MMD_BM_Distribute_Window'))%is this window that is open
      if strcmp(get(BM_Distribute_Window,'visible'),'on')%and is it visible?
         s=strvcat(...
            'PCSA assigned to each motor unit (in rows) for each fiber type (in columns).',...
            ' ',...
            'You can manually redistribute the sizes of each motor units by changing the numbers in these edit boxes.',...
            ' ',...
            'Note that total PCSA for each fiber type should match the total PCSA assigned in the main window. If this number does not match, you will be prompted to automatically redistribute the PCSA in the same proportions or to leave the PCSA as is.',...
            ' ',...
            'Changes made IN THE MAIN WINDOW to the PCSA assigned to each fiber type or the number of motor units will re-distribute automatically the PCSA assigned to motor units for that fiber type of that muscle, and will overwrite your manually entered changes.');
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-25 b(2)-25 b(3)+50 b(4)+20]);   
      end
   end
   
   
   
%Definitions DIALOG BOX
function Definitions_Dialog()
global BM_Main_Window   BM_Distribute_Window
   if ~isempty(findobj('tag','MMD_BM_Main_Window'))%Refresh BM_Main_Window if that is the window that is open
      if strcmp(get(BM_Main_Window,'visible'),'on')%and if it is visible
         s=strvcat(' ',...
            'Muscle name: A _unique_ name for the muscle. In your SIMULINK model, blocks with this name will be search and replaced if you use the Rebuild SIMULINK Model command, so ensure no other blocks share this name.',...
            ' ',...
            'Muscle mass: Mass of muscle',...
            ' ',...
            'Fascicle Lo: Optimal fascicle length (i.e., muscle is able to produce maximal, isometric tetanic force at this length).',...
            ' ',...
            'Muscle PCSA: Physiological cross-sectional area of muscle, computed from density_of_muscle*Muscle mass/Fascicle Lo. (non-editable)',...
            ' ',...
            'Muscle Fo: Maximal tetanic force of muscle, computed from PCSA and specific tension of muscle. The latter is specified in the BuildFiberTypes function. (non-editable)',...
            ' ',...
            'Tendon LoT: Length of tendon+aponeurosis when muscle is producing maximal tetanic force.',...
            ' ',...
            'Whole muscle Lmax: Maximal length of musculotendon path at the extreme anatomical limit of the joint(s).',...
            ' ',...
            'Fascicle Lmax: Used to scale passive force in the fascicles, computed from (Whole muscle Lmax-Tendon_Length_at_Lmax)/Fascicle Lo. Tendon_Length_at_Lmax is calculated from the fibertype parameters and equations so that passive force=series elastic force (typically it is between 0.95-0.96 LoT).  Typically Lmax is between 1.1 and 1.4. (non-editable)',...
            ' ',...
            'Ur: Activation level at which all motor units have been recruited, and additional activation increases result only in frequency modulation of force.  In other words it is the threshold for the last motor unit.',...
            ' ',...
            'Fiber type distribution: Fraction of total PCSA assigned to each fiber type and the number of motor units used in the simulation of each fiber type. Changes to these fields will automatically redistribute motor unit PCSA according to recruitment rank and the number of motor units to be modelled.  This automatic distribution will override manual changes.');
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-25 b(2)-25 b(3)+50 b(4)+20]);   
      end
   end
   
   
   
%Explain the Natural Discrete Recruitment Algorithm with Leff by Brown and Cheng
function Help_Natural_Discrete_BrownCheng_Recruitment_Algorithm
s=strvcat(' ', ' ', ' ',...		%These spaces are necessary on some computers so that all of the text is visible.
   	['This recruitment algorithm is based upon the what would be expected given a realistic '...
      'number motor units and the size principle.  Typically this has resulted in recruitment of slow '...
      'twitch motor units first from smallest to largest, followed by recruitment of fast twitch motor '...
      'units from smallest to largest.  ']...
      ,' ',...
      ['We implement the algorithm the following way.  Recruitment order is first determined by the '...
      'recruitment rank set by the user in the BuildFiberTypes function.  All units of the fiber type '...
      'with the lowest recruitment rank are recruited prior to the recruitment of any other units.  The '...
      'units of the next lowest recruitment rank are then all recruited prior to the recruitment of units '...
      'from the fiber type with the next lowest recruitment rank.  Within each fiber type, units are '...
      'recruited according to the order in which they are listed in the Muscle Morphometry database.  '...
      'The <autodistribute> function automatically distributes PCSA amongst units, listing them '...
      'from smallest to largest, however, if the user enters in different unit PCSAs, then recruitment '...
      'will not necessarily be from smallest to largest (because recruitment of units will simply follow '...
      'the order in which they are listed). ']...
	   ,' ',...
      ['Units are recruited when the activation input reaches a threshold.  Thresholds are determined '...
      'from the PCSA and Ur (Ur is set here in BuildMuscles and is the activation level at which the'...
      'all units are recruited [i.e. it is the threshold for the last unit).  The equation for the '...
      'threshold is (cumulative_PCSA_of_all_prior_recruited_&_current_units_)*Ur.']...
	   ,' ',...
   	['The frequency output (in units of f0.5) is set by the activation input, fmin and fmax (fmin and '... 
      'fmax are set in the BuildFiberTypes function).  Frequency is calculated by assuming a linear '...
      'relationship between activation and frequency, with the initial frequency equal to fmin when '...
      'the unit is first recruited, and a maximal frequency of fmax when activation=1']...%   	,' ',...
  		,' ',...
   	['Motor units in the model are recruited in an all-or-none fashion.  ']...
  		,' ',...
    ['Note: 1. The model with this recruitment method includes effective length (Leff) modeling the'... 
    'delayed length dependency of activation-frequency relationship;  2. The  model is implemented by'...
    'interconnected Simulink basic-blocks']);
	helpdlg(s,'Help Natural Discrete (Brown & Cheng)');
   

%Explain the Natural Discrete Recruitment Algorithm implemented in s-fun
%and removed Leff
function Help_Natural_Discrete_Recruitment_Algorithm
s=strvcat(' ', ' ', ' ',...		%These spaces are necessary on some computers so that all of the text is visible.
   	['This recruitment algorithm is a CMEX S-function implementation of the Natural Discrete recruitment method  '...
      'developed by Brown and Cheng. The only difference is that the effective length (Leff) that originally was '...
      'introduced to model delayed effect of length dependency is removed to resulve the inherent instability']...
  		,' ',...
   	['Note: 1. The model with this recruitment method has effective length (Leff) removed;'...
    ' 2.The model is implemented by state-space based CMEX s-function.']);
	helpdlg(s,'Help Natural Discrete (s-function)');
    
%Explain the Natural Continuous Recruitment Algorithm implemented in s-fun
function Help_Natural_Continuous_Recruitment_Algorithm
s=strvcat(' ', ' ', ' ',...		%These spaces are necessary on some computers so that all of the text is visible.
   	['This recruitment algorithm is a continuous version of natural recruitment algorithm. Instead of  '...
      'modeling multiple motor units explicitly, the continous version lumps the units according to the '...
      'corresponding fiber types. The recruitment order for different fiber types (fast twitch following the slow)'...
      'still hold. The continuous feature of the algorithm is imbeded essentially in the two aspects: 1. the total'...
      'muscle activation and contraction dynamics depend on the proportions of slow and fast fibers; 2. the natural force'...
      'modulation by recruitment/derecruitment of motor unit through an "additive" natural algorithm is replaced by'...
      'a "multiplicative" algorithm by a new term "effective activation level, Ueff"']...     
      ,' ',...
      ['We implement the algorithm the following way.  Recruitment order is still first determined by the '...
      'recruitment rank set by the user in the BuildFiberTypes function.  Each fiber type only contains one '...
      'motor unit, and each unit becomes active at a threshold that depends on the fiber type fractional PCSA  '...
      'and its recruitment order: (cumulative_PCSA_of_all_prior_recruited_&_current_units_)*Ur.']...
	   ,' ',...
   	['The frequency output is modulated in the same manner as the natural algorithm: The frequency output'...
      '(in units of f0.5) is set by the activation input, fmin and fmax (fmin and '... 
      'fmax are set in the BuildFiberTypes function).  Frequency is calculated by assuming a linear '...
      'relationship between activation and frequency, with the initial frequency equal to fmin when '...
      'the unit is first recruited, and a maximal frequency of fmax when activation=1']...
  		,' ',...
   	['Note: 1. The number of motor units for each fiber type is always "1" in fiber type distribution panel;'...
    ' 2.The model is implemented by state-space based CMEX s-function.']);
	helpdlg(s,'Help Natural Continuous (s-function)');

%Explain the Intramuscular FES Recruitment Algorithm
function Help_Intramuscular_FES_Algorithm
s=strvcat(' ', ' ', ' ',...		%These spaces are necessary on some computers so that all of the text is visible.
		['This algorithm for intramuscular FES recruitment is based upon the assumption that '...
      'motor axon branchlets within a muscle belly are not recruited in any preferential fiber type '...
      'order (this assumption is based on the Data of Singh et al., submitted???).']...
      ,' ',...
      ['The algorithm recruits a fraction of the muscle''s PCSA equal to the activation input.  '...
      'It attempts to keep the recruited fraction of each fiber type equal.  Consider, for example, a muscle '...
      'composed of 100 units, all of equal PCSA, with 30 of them slow-twich and 70 of the fast-twitch.  '...
      'Imagine an activation input of 0.1.  10% of the total muscle will become recruited.  This will be '...
      'composed of 10% of the slow units and 10% of the fast units (i.e. 3 slow units and 7 fast units). ']...
      ,' ',...
      ['For each iterative step, the algorithm determines which fiber type has the smallest fraction (by '...
      'PCSA) of its units recruited.  The next motor unit recruited will be of that fiber type.  It will '...
      'become recruited when the activation reaches a threshold equal the total muscle fractional PCSA '...
      'that will be recruited (including the current unit). ']...
	   ,' ',...
      ['Frequency of FES recruited units is set by a second input to each motor unit, which is the '...
      'stimulus frequency applied by the user (the algorithm converts from pps input to f0.5).']...
      ,' ',...
   	['Motor units in the model are recruited in an all-or-none fashion.  ']);
	helpdlg(s,'Help Intramuscular FES (s-function)');
   


%Explain how autodistribute of unit PCSAs works
function Help_Distribute_PCSAs
	s=strvcat(' ', ' ',...		%These spaces are necessary on some computers so that all of the text is visible.
	   'DEFAULT MOTOR-UNIT PCSA DISTRUBTION ALGORITHM',...
   	' ',...
   	['This algorithm makes the different motor units different sizes with an explicit '...
      'arrangement of smallest to largest within each fiber type.   We have also included '...
      'a factor such that the range between the smallest and largest unit within each fibertype '...
      'is greater for fibertypes with a lower recruitment rank as compared to units with a '...
      'higher recruitment rank.  '],...
      ' ',...
      ['Define RR as the Recruitment rank.  Define fracPCSA as the fraction of total PCSA '...
      'for the fibertype in question.  Define currUnit is the number of the current unit (of '...
      'this fibertype).  Define the SUM as the SUM of i=1 to N, where N is the number of '...
      'motor units of this fibertype.  A single motor unit''s PCSA is then calculated via the '...
      'following algorithm: fracPCSA*(RR+currUnit)/SUM(RR+i).'],...
   	' ',...
   	' ',...
	   'GEOMETRIC MOTOR-UNIT PCSA DISTRUBTION ALGORITHM',...
   	' ',...
		['This algorithm makes the different motor units different sizes with an explicit '...
      'arrangement of smallest to largest within each fiber type.   The scheme is simple, with the '...
      'increase in size following a geometric sequence (the user determines fractional increase).'],...
   	' ',...
   	' ',...
	   'EQUAL MOTOR-UNIT PCSA DISTRUBTION ALGORITHM',...
   	' ',...
		['This algorithm makes the different motor units within each fiber type all the same size.']);
	helpdlg(s,'Help autodistribution');
   
   

%ABOUT THIS MARVELOUS PROGRAM
function About
global BM_Version
	s=strvcat(...
      ['Virtual Muscle ', BM_Version],...
      'Software for Modeling and Simulation of Skeletal Muscles',...
      'Copyright © 2000-2008 AMI-USC',...
      'Alfred Mann Institute for Biomedical Engineering, University of Southern California',...
      '         ',...
      'Project Leader: Gerald E. Loeb',...
      '         ',...
      'Virtual Muscle 1.0 to 3.1.5: Developed by Ian Brown and Ernest Cheng and was based on muscle physiology and modeling research by Jiping He, Steven Scott, and Andrew Rindos.',...
      '         ',...
      'Virtual Muscle 4.0: New recruitment algorithms were developed by Dan Song (Natural continuous and Natural discrete without Leff) and Peman Montazemi (Intramuscular FES). The new implementation using CMEX S-Functions and the new GUI for Simulink model creation were developed by Giby Raphael, Mehdi Khachani, He Zheng, Dan Song, and Rahman Davoodi. Funding was provided by Alfred Mann Institute for Biomedical Engineering at University of Southern California and the NSF Engineering Research Center for Biomimetic MicroElectronic Systems. Dan Song’s work on new recruitment algorithms were funded by an NSF grant (IOS #0352117) to Ning Lan.',...
      '         ',...
      'Downloads and updates: ',...
      'http://ami.usc.edu/projects/ami/projects/bion/musculoskeletal/virtual_muscle.html');

  msgbox(s);



