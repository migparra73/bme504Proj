%BuildFiberTypes     Generates fiber types and saves them to a .MAT file
%   Last modified Jan. 30, 2001
%TO DO:
%   Check if I need to change all graphic units to points for cross-platform compatibility?
%   Update the URL in the About function

% The way that this program is currently organized (Feb. 29/00) is that it calls itself with 
% various arguments to do different things.  Callback routines cannot recognize functions within m-files, 
% they can only recognize m-files.  So, the only other way to write this program would be 
% to have many m-files.  Alternatively, one could have set a global variable with the Callback routine and 
% have this main program continually execute a while loop looking for changes, but then you would lose
% 'control' over Matlab (i.e. the command line is not available while an m-file is running continuously)

% 	The main structure is: BFT_Fiber_Type_Database.  The parameters stored here are fiber-type specific.
%	It is a vector (each element is one fiber-type) with the following fields.  

% .Fiber_Type_Name	
% .Recruitment_Rank	{The ranks are used by BuildMuscles to determine in which order motor units
%							 of different types get recruited}
% .F0_5					{firing frequency (pps) which produces 0.5 maximal, isometric tetanic tension}
% .V0_5					{shortening velocity at which 0.5 maximal, isometric tetanic tension is produced
% .Fmax, .Fmin			{Fmin is the firing freq. at which motor units of this type get recruited,
%							 Fmax is the freq. at which motor units fire at maximal activation. Both in units of f0.5}
% .Comments				{any comments that are fibertype specific which the user wishes to input}
% .FL_omega    .FL_beta		.FL_rho	{constants for the CONTRACTILE force element FL}
% .Vmax  .cV0  .cV1						{constants for the CONTRACTILE force element FV - shortening}
% .aV0   .aV1  .aV2	.bV				{constants for the CONTRACTILE force element FV - lengthening}
% .af    .nf0 	.nf1						{constants for the CONTRACTILE force element Af - Activation-Frequency}
% .TL											{constants for the CONTRACTILE force element L => Leff (time lag)}
% .Tf1	.Tf2	.Tf3	.Tf4				{constants for the CONTRACTILE force element f => feff (rise/fall times)}
% .aS1   .aS2 	.TS						{constants for the CONTRACTILE force element SAG}
% .cY		.VY	.TY						{constants for the CONTRACTILE force element YIELD}
% .ch0	.ch1	.ch2	.ch3				{constants for the energy rate equation}

% The other main structure is BFT_FTD_General_Parameters.  The parameters stored here are generic 
% for all fiber types within a given database.  It has the following fields.
% .Sarcomere_Length	{optimal sarcomere length in um.  This value is assumed to be the same for all fiber
%							 types in each database}
% .Specific_Tension	{This is the specific Tension in N/cm2.  
%							It defaults to 31.8 N/cm based on Scott et al., 1996 and Brown et al., 1998} 
% .c1    .k1   .Lr1	{constants for the passive force element PE1}
% .c2    .k2   .Lr2	{constants for the passive force element PE2}
% .cT		.kT	.LrT	{parameters for tendon series elasticity}
% .Viscosity			{default is 1%.  this is passive and applies to all fiber types in a database file} 
% .Comments				{any comments that are database specific}
% .Version				{version of BuildFiberTypes for which this database was made}

function BuildFiberTypes(todo, fibernumber)
global BFT_Version	BFT_Coefficient_Window		BFT_Generic_Window	BFT_Fiber_Type_Database

BFT_Version='3.1.5';		%This is the version of the BuildFibertypes program.

if nargin==0,todo='initialize';end
drawnow;			%update figure before you do anything else. 

switch todo
case 'initialize',						Initialize, 						Refresh;							
case 'make main figure',				Make_Main_Figure,					Refresh;
case 'change V0.5', 						Change_V0_5(fibernumber), 		Refresh;
case 'Change f0.5', 						Change_f0_5(fibernumber), 		Refresh;
case 'load',								Load_FTD_File,						Refresh;
case 'save',								Save_FTD_File,						Refresh;
case 'copy',								Copy_Fiber_Type;					Refresh;
case 'paste',								Paste_Fiber_Type;					Refresh;
case 'cut',									Cut_Fiber_Type;					Refresh;
case 'delete', 							Delete_Fiber_Type, 				Refresh;
case 'insert',								Insert_Fiber_Type, 				Refresh;
case 'import',								Import_Fiber_Type, 				Refresh;
case 'edit FT coefficients',			Edit_Fiber_Coefficients, 		Refresh;
case 'edit generic coefficients',	Edit_Generic_Coefficients,		Refresh;
case 'change SL',							Change_SL,					 		Refresh;
case 'co-efficients updated', 		BFT_Fiber_Type_Database=Update_FTD(BFT_Fiber_Type_Database);
   													Make_Main_Figure,			Refresh;
case 'refresh',							Refresh;
case 'help', 								Help_Dialog;
case 'help scaling',						Help_Scaling_Dialog;
case 'definitions', 						Definitions_Dialog;
case 'about', 								About;
case 'clean up'
	%QUITTING PROGRAM, KILL GLOBAL VARIABLES and delete the window
	if ishandle(BFT_Coefficient_Window), delete(BFT_Coefficient_Window);  end
	if ishandle(BFT_Generic_Window), delete(BFT_Generic_Window);  end
   clear global BFT_Fiber_Type_Database   BFT_Default_Fiber_Type   BFT_Old_F0_5	BFT_Old_V0_5;
   clear global BFT_Clipboard_Fiber   BFT_First_Fiber    BFT_Coefficient_Fiber;
   clear global BFT_Save_File    BFT_Save_Path    BFT_Main_Fiber_Labels;
   clear global BFT_Main_Window    BFT_Main_Menu    BFT_Main_ETB    BFT_Main_Button;
   clear global BFT_Coefficient_Window   BFT_Coefficient_Menu    BFT_Coefficient_ETB   BFT_Coefficient_Button;
   clear global BFT_Generic_Window	BFT_Generic_Menu    BFT_Generic_ETB;
   clear global BFT_Main_Vars   BFT_Coefficient_Vars	BFT_Generic_Vars;   
end


%INTIALIZE GLOBAL VARIABLES, BFT stands for Build_Fiber_Type (i.e. this m-file)
function Initialize
global BFT_First_Fiber   BFT_Save_File   BFT_Save_Path   BFT_Main_Vars   BFT_Coefficient_Vars
global BFT_Main_Window   BFT_Generic_Vars   BFT_FTD_General_Parameters
	%Don't recreate elements if figure already exists
   if ~isempty(findobj('tag','FTD_BFT_Main_Window'))
      set(0,'currentfigure',BFT_Main_Window, 'visible', 'on');
      figure(BFT_Main_Window);
      return
   end
   %Init global variables
   BFT_FTD_General_Parameters=Init_General_Parameters;
   BFT_First_Fiber=0;
   BFT_Save_File='untitled.mat';
   BFT_Save_Path='';
   BFT_Main_Vars={'Comments' 'Fmax' 'Fmin' 'F0_5' 'V0_5' 'Recruitment_Rank' 'Fiber_Type_Name'};
   BFT_Coefficient_Vars={...
         'FL_omega' 'FL_beta' 'FL_rho' '';...
         'Vmax' 'cV0' 'cV1' '';...
         'aV0' 'aV1' 'aV2' 'bV';...
         'af' 'nf0' 'nf1' '';...
         'TL' '' '' '';...
         'Tf1' 'Tf2' '' '';...
         'Tf3' 'Tf4' '' '';...
         'aS1' 'aS2' 'TS' '';...
         'cY' 'VY' 'TY' '';...     
         'ch0' 'ch1' 'ch2' 'ch3'};     
   BFT_Generic_Vars={...
         'Specific_Tension' '' '';...
         'Viscosity' '' '';...
         'c1' 'k1' 'Lr1';...
         'c2' 'k2' 'Lr2';...
         'cT' 'kT' 'LrT'};   
   Make_Main_Figure; 
   
   
   
%Initialize the FTD_General_Parameters.  This is called at the beginning of the program and 
%also if an FTD is loaded up with any general parameters.
function [GP]=Init_General_Parameters	
global BFT_Version
   GP.Sarcomere_Length=2.4;
   GP.Specific_Tension=31.8;
   GP.Viscosity=0.01;
   GP.c1=23;		GP.k1=0.046;		GP.Lr1=1.17;
   GP.c2=-0.02;	GP.k2=-18.7;		GP.Lr2=0.79;
   GP.cT=27.8;		GP.kT=0.0047;		GP.LrT=0.964;
   GP.Comments='';
   GP.Version=BFT_Version;
   
   

%INITIALIZE FIBER_TYPE_DATABASE INDEX TO ZEROES AND ''
function Initialize_Fiber_Type(fibernumber)
global BFT_Fiber_Type_Database BFT_Coefficient_Vars;
	BFT_Fiber_Type_Database(fibernumber).Fiber_Type_Name='';
	BFT_Fiber_Type_Database(fibernumber).Recruitment_Rank=0;
	BFT_Fiber_Type_Database(fibernumber).V0_5=0;
	BFT_Fiber_Type_Database(fibernumber).F0_5=0;
	BFT_Fiber_Type_Database(fibernumber).Fmax=2;
	BFT_Fiber_Type_Database(fibernumber).Fmin=0.5;
	BFT_Fiber_Type_Database(fibernumber).Comments='';
	for rows=1:size(BFT_Coefficient_Vars,1)
      for cols=1:size(BFT_Coefficient_Vars,2)
         FTD_field=BFT_Coefficient_Vars{rows,cols};
         if ~isempty(FTD_field)
            BFT_Fiber_Type_Database=setfield(BFT_Fiber_Type_Database,{fibernumber},FTD_field,0);
	      end
	   end
   end
   
   

%MAKE GUI ELEMENTS of main figure that shows the main fiber type properties.
function Make_Main_Figure
global BFT_Main_Window   BFT_Clipboard_Label   BFT_Main_Vars   BFT_Main_ETB
   closerequestfunction=['selection = questdlg(''Exit BuildFiberTypes? Unsaved information will be lost!'','...
            '''Close Window?'',''Exit'',''Cancel'',''Cancel'');'...
            'switch selection, case ''Exit'', BuildFiberTypes(''clean up'');delete(gcf);'...
            'case ''Cancel'', return, end'];
   if isempty(findobj('tag','FTD_BFT_Main_Window'))
      bkcolor=get(0,'defaultuicontrolbackgroundcolor');
      screen=get(0,'screensize');
      mainwindowwidth=750;	mainwindowheight=600;
      mainwindowpos=[(screen(3)-mainwindowwidth)/2 (screen(4)-mainwindowheight)/2 mainwindowwidth mainwindowheight];
      BFT_Main_Window=figure(...
         	'name','BuildFiberTypes: untitled.mat', 			'color',bkcolor,...
         	'menubar','none', 			'tag','FTD_BFT_Main_Window',...
         	'closerequestfcn',closerequestfunction,		'position',mainwindowpos,...
         	'resize','off',		'numbertitle','off',			'visible','off');
      BFT_Clipboard_Label=uicontrol(...   %Make clipboard label
	      	'style','text',			'backgroundcolor',bkcolor,...
         	'horizontalalignment','left',			'position',[5 mainwindowheight-30 150 20]);
   	%put label and text box for sarcomere length
   	txt=uicontrol(...%Do sarcomere length label along left side of figure
            'style','text',			'string','Optimal Sarcomere Length (um)',...
            'backgroundcolor',bkcolor,			'horizontalalignment','left',...
            'position',[10 530 200 20]);
		BFT_Main_ETB(length(BFT_Main_Vars)+2,1)=uicontrol(... %Editable text box for sarcomere length
            'style','edit',			'backgroundcolor',[1 1 1],...
            'position',[200 530 120 20]);
   	%put label and text box for database related comments
   	txt=uicontrol(...%Do label along left side of figure
            'style','text',			'string','Additional Comments',...
            'backgroundcolor',bkcolor,			'horizontalalignment','left',...
            'position',[10 200 120 30]);
		BFT_Main_ETB(length(BFT_Main_Vars)+3,1)=uicontrol(... %Editable text box for additional comments
            'style','edit',			'backgroundcolor',[1 1 1], 'max',2,...
            'position',[125 40 620 190],		'horizontalalignment','left');
      Make_Main_Window_Menus_Buttons_and_ETBs;
   end
   set(BFT_Main_Window,'visible','on');
   
   
   
%Make editable text boxes within the main figure.  The callback routines for these textboxes are set
%in the Refresh function
function Make_Main_Window_Menus_Buttons_and_ETBs;
global BFT_Main_Button   BFT_Main_Window   BFT_Main_Menu
global BFT_Main_Vars   BFT_Main_Fiber_Labels   BFT_First_Fiber   BFT_Main_ETB
	bkcolor=get(0,'defaultuicontrolbackgroundcolor');
	%First make the menus
   BFT_Main_Menu=Make_Menus(BFT_Main_Window, {'&File' '&Edit' '&Fiber Properties' '&Help'},{},{}); 
   BFT_Main_Menu(1).submenu=Make_Menus(BFT_Main_Menu(1).menu,...
      	{'&Open Database' '&Save Database' '&Close Program'},{'off' 'off' 'on'},...
      	{'BuildFiberTypes(''load'')' 'BuildFiberTypes(''save'')' 'global BFT_Main_Window;close(BFT_Main_Window)'}); 
   BFT_Main_Menu(2).submenu=Make_Menus(BFT_Main_Menu(2).menu,...
      	{'Cu&t Fiber To Clipboard' '&Copy Fiber To Clipboard' '&Paste Fiber From Clipboard' '&Import Fiber'...
      	'I&nsert (empty) Fiber Type' '&Delete Fiber Type'},{'off' 'off' 'off' 'on' 'on' 'off'},...
      	{'BuildFiberTypes(''cut'')' 'BuildFiberTypes(''copy'')' 'BuildFiberTypes(''paste'')'...
      	'BuildFiberTypes(''import'')' 'BuildFiberTypes(''insert'')' 'BuildFiberTypes(''delete'')'}); 
   BFT_Main_Menu(3).submenu=Make_Menus(BFT_Main_Menu(3).menu,...
      	{'&Edit Fiber Type Specific Coefficients' '&Edit Generic Coefficients (e.g. SE, PE)'},{},...
      	{'BuildFiberTypes(''edit FT coefficients'')' 'BuildFiberTypes(''edit generic coefficients'')'}); 
   BFT_Main_Menu(4).submenu=Make_Menus(BFT_Main_Menu(4).menu,...
      	{'&General Help' '&Definitions of Terms' '&Scaling with sarcomere length, V0.5 and f0.5' '&About'},...
         {'off' 'off' 'off' 'on' 'off' 'off'}, {'BuildFiberTypes(''help'')'...
         'BuildFiberTypes(''definitions'')' 'BuildFiberTypes(''help scaling'')' 'BuildFiberTypes(''about'')'}); 
   %Make the buttons
   buttonwidth=90;		buttonheight=20;
   buttonnames={'Prev 5 Fibers' 'Next 5 Fibers'};
   buttoncallbackstrings={'global BFT_First_Fiber;BFT_First_Fiber=BFT_First_Fiber-5;BuildFiberTypes(''refresh'')',...
         'global BFT_First_Fiber;BFT_First_Fiber=BFT_First_Fiber+5;BuildFiberTypes(''refresh'')'};
   BFT_Main_Button=Make_Buttons(BFT_Main_Window, buttonnames, buttoncallbackstrings, buttonwidth, buttonheight);
	%Make the Editable Text Boxes (and labels)
   commentsheight=80;
	numrows=length(BFT_Main_Vars);
   xsize=120;		xpos=(1:5)*(xsize+5);											xsize=xsize+zeros(size(xpos));											
   ysize=20;		ypos=(1:numrows+1)*(ysize+5)+commentsheight+210;			ysize=ysize+zeros(size(ypos));	
   ypos(1)=ypos(1)-commentsheight;		ysize(1)=ysize(1)+commentsheight;	%Make the comments ETB larger
   mainlabels={'Comments' 'fmax (f0.5)' 'fmin (f0.5)' 'f0.5 (pps)' 'V0.5 (L0/s)' 'Recruitment rank' 'Fiber type name'};
   for rows=1:(numrows)	%Do labels along left side of figure
      txt=uicontrol(...
         'style','text',			'string', mainlabels{rows},		'backgroundcolor',bkcolor,...
         'horizontalalignment','left', 	'position',[10 ypos(rows) xsize(1)+80 ysize(rows)]);
   end
   for cols=1:5	%Labels along top of figure
      BFT_Main_Fiber_Labels(cols)=uicontrol(...
         'style','text',		'string',['Fiber #' num2str(BFT_First_Fiber+cols)],...
         'position',[xpos(cols) ypos(numrows+1) xsize(cols) ysize(numrows+1)]);
   end
   for cols=1:5	%Table of Editable text boxes
      for rows=1:length(BFT_Main_Vars)
         BFT_Main_ETB(rows,cols)=uicontrol(...
            'style','edit',  'backgroundcolor',[1 1 1],	'position',[xpos(cols) ypos(rows) xsize(cols) ysize(rows)]);
         if rows==1,		set(BFT_Main_ETB(rows,cols),'max',2);  end		%Make the comments a multi-line ETB
      end
   end
         
         
         
%MAKE FIBER COEFFICIENTS WINDOW
%Create a new window (temporarily make the main window invisible) and allow the user to directly
%edit the coefficients describing the basic contractile properties of a fiber types
function Edit_Fiber_Coefficients()
global BFT_Fiber_Type_Database   BFT_Coefficient_Fiber   BFT_Coefficient_Window   BFT_Main_Window
global BFT_Coefficient_Menu
   str={BFT_Fiber_Type_Database.Fiber_Type_Name};
   [selection,ok]=listdlg('promptstring','Select fiber to edit','selectionmode','single','liststring',str);
   if ~ok,		return;   end;
   BFT_Coefficient_Fiber=selection;
   set(BFT_Main_Window,'visible','off');
   bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   if isempty(findobj('tag','FTD_BFT_Coefficient_Window'))%Don't recreate elements if figure already exists
      screen=get(0,'screensize');
      mainwindowwidth=450;	mainwindowheight=450;
      mainwindowpos=[(screen(3)-mainwindowwidth)/2 (screen(4)-mainwindowheight)/2 mainwindowwidth mainwindowheight];
      BFT_Coefficient_Window=figure(...
         'name',['Coefficients for Fiber #' num2str(BFT_Coefficient_Fiber) ': '...
            	BFT_Fiber_Type_Database(BFT_Coefficient_Fiber).Fiber_Type_Name],...
         'color',bkcolor,			'menubar','none',...
         'tag','FTD_BFT_Coefficient_Window',...
         'closerequestfcn','set(gcf,''visible'',''off'');BuildFiberTypes(''co-efficients updated'');',...
         'position',mainwindowpos,			'resize','off',...
         'numbertitle','off',			'visible','off');
      Make_Edit_Coefficients_Menus_Buttons_and_ETBs;
   end
   set(BFT_Coefficient_Window,'visible','on');
   
   
   
%create the text boxes for the edit coefficients window
function Make_Edit_Coefficients_Menus_Buttons_and_ETBs
global BFT_Coefficient_Menu
global BFT_Coefficient_Vars   BFT_Coefficient_ETB   BFT_Coefficient_Button   BFT_Coefficient_Window
	bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   %Make Menus
   BFT_Coefficient_Menu=Make_Menus(BFT_Coefficient_Window, {'&File' '&Help'},{},{}); 
   BFT_Coefficient_Menu(1).submenu=Make_Menus(BFT_Coefficient_Menu(1).menu,...
      	{'&Edit another fiber' '&Back to Main Dialog'},{},...
      	{'BuildFiberTypes(''edit FT coefficients'')' 'eval(get(gcf,''closerequestfcn''))'}); 
   BFT_Coefficient_Menu(2).submenu=Make_Menus(BFT_Coefficient_Menu(2).menu,...
      	{'&Help' '&Definitions'},{},{'BuildFiberTypes(''help'')' 'BuildFiberTypes(''definitions'')'}); 
   %Make buttons
   buttonwidth=90;		buttonheight=20;
	buttonnames={'Edit Prev Fiber' 'Edit Next Fiber'};
	buttoncallbackstrings={'drawnow;global BFT_Coefficient_Fiber;BFT_Coefficient_Fiber=BFT_Coefficient_Fiber-1;BuildFiberTypes(''refresh'')',...
   			'drawnow;global BFT_Coefficient_Fiber;BFT_Coefficient_Fiber=BFT_Coefficient_Fiber+1;BuildFiberTypes(''refresh'')'};  
   BFT_Coefficient_Button=Make_Buttons(BFT_Coefficient_Window, buttonnames,buttoncallbackstrings, buttonwidth, buttonheight);
   %Make Editable Text Boxes (ETBs)
   coefficientlabels={...
         'FL(L)';		'FV(V,L)';		'';...
         'Af(feff,Leff,Y,S)';		'Leff(t)';		'fint(t,fenv,L)'; ...
         'feff(t,fint,L)';		'S(t,feff)';		'Y(t)';		'Energy Rate'};
   xsize=80;	xpos=(1:size(BFT_Coefficient_Vars,2)+1)*(xsize+2)-50;
   ysize=20;	ypos=(size(BFT_Coefficient_Vars,1):-1:1)*(ysize+20)+10;;
   for rows=1:size(BFT_Coefficient_Vars,1)
      txt=uicontrol(...%Do labels along left side of figure
      	   'style','text',		'string',coefficientlabels{rows},...
         	'backgroundcolor',bkcolor,			'position',[xpos(1)-30 ypos(rows)-ysize+5 xsize+40 ysize]);
      for cols=1:size(BFT_Coefficient_Vars,2)
         if ~isempty(BFT_Coefficient_Vars{rows,cols})
            txt=uicontrol('style','text',		'string',BFT_Coefficient_Vars{rows,cols},...
               	'position',[xpos(cols+1) ypos(rows) xsize ysize]);
            %Editable text boxes (ETB)
            BFT_Coefficient_ETB(rows,cols)=uicontrol('style','edit',		'backgroundcolor',[1 1 1],...
               	'position',[xpos(cols+1) ypos(rows)-ysize+5 xsize ysize]);
         end
      end
   end



%MAKE GENERIC COEFFICIENTS WINDOW
%Create a new window (temporarily make the main window invisible) and allow the user to directly
%edit the generic coefficients 
function Edit_Generic_Coefficients()
global BFT_Fiber_Type_Database   BFT_Generic_Window   BFT_Main_Window   BFT_Save_File
   set(BFT_Main_Window,'visible','off');
   bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   if isempty(findobj('tag','Generic_BFT_Coefficient_Window'))%Don't recreate elements if figure already exists
      screen=get(0,'screensize');
      mainwindowwidth=420;	mainwindowheight=250;
      mainwindowpos=[(screen(3)-mainwindowwidth)/2 (screen(4)-mainwindowheight)/2 mainwindowwidth mainwindowheight];
      BFT_Generic_Window=figure(...
         'name',['Generic Coefficients for ' BFT_Save_File],...
         'color',bkcolor,			'menubar','none',...
         'tag','Generic_BFT_Coefficient_Window',...
         'closerequestfcn','set(gcf,''visible'',''off'');BuildFiberTypes(''make main figure'');',...
         'position',mainwindowpos,			'resize','off',...
         'numbertitle','off',			'visible','off');
      Make_Generic_Coefficients_Menus_Buttons_and_ETBs;
   end
   set(BFT_Generic_Window,'visible','on');
   
   
   
%create the text boxes for the edit coefficients window
function Make_Generic_Coefficients_Menus_Buttons_and_ETBs
global BFT_Generic_Vars   BFT_Generic_ETB   BFT_Generic_Menu   BFT_Generic_Window
	bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   %Make Menus
   BFT_Generic_Menu=Make_Menus(BFT_Generic_Window, {'&File' '&Help'},{},{}); 
   BFT_Generic_Menu(1).submenu=Make_Menus(BFT_Generic_Menu(1).menu,...
      	{'&Back to Main Dialog'},{},{'eval(get(gcf,''closerequestfcn''))'}); 
   BFT_Generic_Menu(2).submenu=Make_Menus(BFT_Generic_Menu(2).menu,...
      	{'&Help' '&Definitions'},{},{'BuildFiberTypes(''help'')' 'BuildFiberTypes(''definitions'')'}); 
  	%Make Editable Text Boxes (ETBs)
   coefficientlabels={...
         'Specific Tension (N/cm2)';		'Viscosity (part of FPE1)';		'FPE1';		'FPE2';		'FSE'};
   xsize=80;	xpos=(1:size(BFT_Generic_Vars,2)+1)*(xsize+2);
   ysize=20;	ypos=(size(BFT_Generic_Vars,1):-1:1)*(ysize+20);
   for rows=1:size(BFT_Generic_Vars,1)
      txt=uicontrol(...%Do labels along left side of figure
      	   'style','text',		'string', coefficientlabels{rows},...
         	'backgroundcolor',bkcolor,			'position',[xpos(1)-xsize ypos(rows)-ysize-5 xsize+80 ysize+10]);
      for cols=1:size(BFT_Generic_Vars,2)
         if ~isempty(BFT_Generic_Vars{rows,cols})
            if rows>2
	            txt=uicontrol('style','text',		'string',BFT_Generic_Vars{rows,cols},...
                  'position',[xpos(cols+1) ypos(rows) xsize ysize]);
            end
            %Editable text boxes (ETB)
            BFT_Generic_ETB(rows,cols)=uicontrol('style','edit',		'backgroundcolor',[1 1 1],...
               	'position',[xpos(cols+1) ypos(rows)-ysize+5 xsize ysize]);
         end
      end
   end
   


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
function [button]=Make_Buttons(Window, buttonnames,callbackstrings, buttonwidth, buttonheight)
   bkcolor=get(0,'defaultuicontrolbackgroundcolor');
   for i=1:length(buttonnames)
    	button(i)=uicontrol(Window, 'style','pushbutton',	'string',buttonnames{i},...
          'backgroundcolor',bkcolor,'position',[10+(i-1)*(buttonwidth+5) 10 buttonwidth buttonheight],...
          'callback',callbackstrings{i});
   end
    
     
      
%REFRESH either the BFT_Main_Window or the BFT_Coefficient_Window
function Refresh()  
global BFT_Main_Window   BFT_Coefficient_Window   BFT_Generic_Window
	if ~isempty(findobj('tag','FTD_BFT_Main_Window'))
 		if strcmp(get(BFT_Main_Window,'visible'),'on')%check if it is visible
          Refresh_Main_Window;
       end
   end   
   if ~isempty(findobj('tag','FTD_BFT_Coefficient_Window'))
		if strcmp(get(BFT_Coefficient_Window,'visible'),'on')%check if it is visible
   	   Refresh_Coefficients_Window;
      end
   end
   if ~isempty(findobj('tag','Generic_BFT_Coefficient_Window'))
		if strcmp(get(BFT_Generic_Window,'visible'),'on')%check if it is visible
   	   Refresh_Generic_Window;
      end
   end
   
   
   
%REFRESH the Build_Fiber_Types Main_Window 
%this function enables the appropriate buttons and menu items and updates the callback routines
%associated with the text boxes.
function Refresh_Main_Window()
global BFT_Main_Window   BFT_First_Fiber   BFT_Main_Button   BFT_Clipboard_Fiber   BFT_Main_Menu
global BFT_Clipboard_Label   BFT_Main_Fiber_Labels   BFT_Main_Vars   BFT_Fiber_Type_Database
global BFT_Main_ETB   BFT_FTD_General_Parameters
   if BFT_First_Fiber<=0		%Check out of bounds fiber number
      BFT_First_Fiber=0;
      set(BFT_Main_Button(1),'enable','off');
   else
      set(BFT_Main_Button(1),'enable','on');
   end
   if isempty(BFT_Clipboard_Fiber)	%Check if something has been copied yet
      set(BFT_Main_Menu(2).submenu(3).menu,'enable','off');
      set(BFT_Clipboard_Label,'string','Clipboard contents: Empty');
   else
      set(BFT_Main_Menu(2).submenu(3).menu,'enable','on');
      set(BFT_Clipboard_Label,'string',['Clipboard contents: ' BFT_Clipboard_Fiber.Fiber_Type_Name]);
   end
   if BFT_First_Fiber+5>=size(BFT_Fiber_Type_Database,2)%Make defaults for figure if they don't exist
      for fibernumber=BFT_First_Fiber+5:-1:size(BFT_Fiber_Type_Database,2)+1
         Initialize_Fiber_Type(fibernumber);
      end
   end
   for cols=1:5
      set(BFT_Main_Fiber_Labels(cols),'string',['Type #' num2str(BFT_First_Fiber+cols)]);
      for rows=1:length(BFT_Main_Vars)
         temp=getfield(BFT_Fiber_Type_Database(BFT_First_Fiber+cols),BFT_Main_Vars{rows});
         if isnumeric(temp),temp=num2str(temp);end
         if rows==1|rows==7%If one of the text string rows
            callbackstring=['global BFT_Fiber_Type_Database;BFT_Fiber_Type_Database('...
               num2str(BFT_First_Fiber+cols) ').' BFT_Main_Vars{rows} '=get(gcbo,''string'');'];
         elseif rows==4%If f0.5 row, force f0.5 to be positive, copy old f0.5, set new f0.5
            callbackstring=['global BFT_Old_F0_5 BFT_Fiber_Type_Database;'...
               'F0_5=abs(str2num(get(gcbo,''string''))); set(gcbo,''string'',num2str(F0_5));'...
               'fibernumber=' num2str(BFT_First_Fiber+cols) ';'...
               'BFT_Old_F0_5=BFT_Fiber_Type_Database(fibernumber).' BFT_Main_Vars{rows} ';'...
               'BFT_Fiber_Type_Database(fibernumber).' BFT_Main_Vars{rows} '=F0_5;'...
               'BuildFiberTypes(''Change f0.5'',fibernumber)'];
         elseif rows==5%If V0_5 row, force V0.5 to be negative copy old V0.5, set new V0.5
            callbackstring=['global BFT_Old_V0_5 BFT_Fiber_Type_Database;'... 
               'V0_5=-abs(str2num(get(gcbo,''string''))); set(gcbo,''string'',num2str(V0_5));'...
               'fibernumber=' num2str(BFT_First_Fiber+cols) ';'...
               'BFT_Old_V0_5=BFT_Fiber_Type_Database(fibernumber).' BFT_Main_Vars{rows} ';'...
               'BFT_Fiber_Type_Database(fibernumber).' BFT_Main_Vars{rows} '=V0_5;'...
					'BuildFiberTypes(''change V0.5'',fibernumber)'];
         else%If a normal numeric input row   
            callbackstring=['global BFT_Fiber_Type_Database;BFT_Fiber_Type_Database('...
                  num2str(BFT_First_Fiber+cols) ').' BFT_Main_Vars{rows}...
                  '=str2num(get(gcbo,''string''));'];
         end   
         set(BFT_Main_ETB(rows,cols),'string',temp,'callback',callbackstring);   
      end
   end  
   sarcomerelength=num2str(BFT_FTD_General_Parameters.Sarcomere_Length);
   callbackstring=['global BFT_Old_SL BFT_FTD_General_Parameters;'... 
               'BFT_Old_SL=BFT_FTD_General_Parameters.Sarcomere_Length;'...
               'BFT_FTD_General_Parameters.Sarcomere_Length=str2num(get(gcbo,''string''));'...
					'BuildFiberTypes(''change SL'')'];
   set(BFT_Main_ETB(length(BFT_Main_Vars)+2,1),'string',sarcomerelength,'callback', callbackstring);
   comments=BFT_FTD_General_Parameters.Comments;
   callbackstring=['global BFT_FTD_General_Parameters;'... 
               'BFT_FTD_General_Parameters.Comments=get(gcbo,''string'');'];
   set(BFT_Main_ETB(length(BFT_Main_Vars)+3,1),'string',comments,'callback', callbackstring);
   
   
   
%REFRESH the Build_Fiber_Types Edit_Coefficients_Window
%This function enables/disables the appropriate buttons and resets the callback routines
%associated with the text boxes
function Refresh_Coefficients_Window()
global BFT_Fiber_Type_Database   BFT_Coefficient_ETB
global BFT_Coefficient_Window   BFT_Coefficient_Vars   BFT_Coefficient_Fiber   BFT_Coefficient_Button
	for rows=1:size(BFT_Coefficient_Vars,1)%Always set, even if window already exists
      for cols=1:size(BFT_Coefficient_Vars,2)
         if ~isempty(BFT_Coefficient_Vars{rows,cols})
            callbackstring=['global BFT_Fiber_Type_Database;BFT_Fiber_Type_Database('...
                  num2str(BFT_Coefficient_Fiber) ').' BFT_Coefficient_Vars{rows,cols}...
                  '=str2num(get(gcbo,''string''));'];
            set(BFT_Coefficient_ETB(rows,cols),'callback',callbackstring,'string',...
 	               num2str(eval(['BFT_Fiber_Type_Database(' num2str(BFT_Coefficient_Fiber) ').'...
                  BFT_Coefficient_Vars{rows,cols}])));
         end
      end
   end
   if BFT_Coefficient_Fiber<=1
      set(BFT_Coefficient_Button(1),'enable','off');
   else
      set(BFT_Coefficient_Button(1),'enable','on');
   end
   if BFT_Coefficient_Fiber>=length(BFT_Fiber_Type_Database)
      set(BFT_Coefficient_Button(2),'enable','off');
   else
      set(BFT_Coefficient_Button(2),'enable','on');
   end
   set(BFT_Coefficient_Window,'name',['Coefficients for Fiber #' num2str(BFT_Coefficient_Fiber)...
         ': ' BFT_Fiber_Type_Database(BFT_Coefficient_Fiber).Fiber_Type_Name]);
   
   
   
%REFRESH the Build_Fiber_Types Edit_GENERIC_Coefficients_Window
%This function resets the callback routines associated with the text boxes
function Refresh_Generic_Window()
global BFT_FTD_General_Parameters   BFT_Generic_ETB   BFT_Generic_Window   BFT_Generic_Vars
	for rows=1:size(BFT_Generic_Vars,1)%Always set, even if window already exists
      for cols=1:size(BFT_Generic_Vars,2)
         if ~isempty(BFT_Generic_Vars{rows,cols})
            callbackstring=['global BFT_FTD_General_Parameters;BFT_FTD_General_Parameters.'...
                  BFT_Generic_Vars{rows,cols} '=str2num(get(gcbo,''string''));'];
            set(BFT_Generic_ETB(rows,cols),'callback',callbackstring,'string',...
 	               num2str(eval(['BFT_FTD_General_Parameters.' BFT_Generic_Vars{rows,cols}])));
         end
      end
   end
   
   
   
%LOAD A FTD (Fiber_Type_Database) and replace the current one in memory with the one that is opened
function Load_FTD_File
global BFT_Fiber_Type_Database    BFT_Main_Window   BFT_Save_Path   BFT_Save_File   BFT_FTD_General_Parameters
	[Fiber_Type_Database, FTD_General_Parameters, filename, pathname, error]=Open_FTD_File;
   if strcmp(error, 'false')
      BFT_Fiber_Type_Database=Fiber_Type_Database;
      BFT_Save_File=filename;
      BFT_Save_Path=pathname;
      if ~isempty(FTD_General_Parameters)
  	      BFT_FTD_General_Parameters=FTD_General_Parameters;
      end
      set(BFT_Main_Window,'name',['BuildFiberTypes: ' BFT_Save_File]);
   end
   
   

%OPEN A FTD (Fiber_Type_Database) FILE and return the FTD from the file
function [loaded_FTD, loaded_general_Param, filename, pathname, error]=Open_FTD_File
global BFT_Fiber_Type_Database   BFT_Save_Path   BFT_FTD_General_Parameters
	loaded_FTD=[];		loaded_general_Param=[];	error='true';   filename='';		pathname='';
	[filename pathname]=uigetfile([BFT_Save_Path '*.mat'],'Choose a fiber_type_database.mat file');
   if ~(filename==0)
      %This loads two structures (if they exist) call Fiber_Type_Database & FTD_General_Parameters
      load ([pathname filename]);		
      if exist('Fiber_Type_Database')
         error='false';
         if exist('FTD_General_Parameters')
		      %initialize all general parameters, and then replace those that were found in the new file.
		      %This ensures that all currently required fields are present in this structure and that new fields
		      %(which are initialized by this program) stay initialized
            loaded_general_Param=Init_General_Parameters;
	      	commonfields=intersect(fieldnames(FTD_General_Parameters),fieldnames(loaded_general_Param));
	         for i=1:length(commonfields)
	     			newdata=getfield(FTD_General_Parameters,commonfields{i});
	     	      loaded_general_Param=setfield(loaded_general_Param,commonfields{i},newdata);
            end
            %The following parameters are new to version 3.0.3
            New_Generic_Vars={'c1' 'k1' 'Lr1' 'c2' 'k2' 'Lr2'};   
            for i=1:length(New_Generic_Vars)
               newfield=New_Generic_Vars{i};
               if and(isempty(strmatch(newfield, commonfields, 'exact')), isfield(Fiber_Type_Database, newfield))
                  %get these values from the first fibertype
						newdata=getfield(Fiber_Type_Database(1),newfield);
                  loaded_general_Param=setfield(loaded_general_Param,newfield,newdata);
               end   
            end
	      end
         %remove legacy fields that are no longer used
         legacy_fields=setdiff(fieldnames(Fiber_Type_Database),fieldnames(BFT_Fiber_Type_Database));
	      if ~isequal(legacy_fields,{''})
		   	for i=1:size(legacy_fields,1)
		      	Fiber_Type_Database=rmfield(Fiber_Type_Database,legacy_fields{i});	%Remove legacy fields no longer used
	         end
	      end
         loaded_FTD=Update_FTD(Fiber_Type_Database);
      else
         msgbox('The file you selected was not a valid Fiber_Type_Database file.');
	   end   
   end

   

%This function calculates V0.5 
function [new_FTD] = Update_FTD(loaded_FTD)
   %always calculate V0.5 from Vmax
   temp=[loaded_FTD.Vmax]./([loaded_FTD.cV0]+[loaded_FTD.cV1]+2);
   temp=num2cell(temp);								%must convert vector to cells so that they can be 'dealt'
   [loaded_FTD.V0_5]=deal(temp{:});				%copies V0.5 values for all fibers at once.
   new_FTD=loaded_FTD;								%copy over new FTD for return from this function
   
   
   
%SAVE FTD FILE (save the FTD currently in memory)
function Save_FTD_File
global BFT_Fiber_Type_Database   BFT_Save_File   BFT_Save_Path   BFT_Main_Window   BFT_FTD_General_Parameters
	for i = length(BFT_Fiber_Type_Database):-1:1%Strip trailing empty entries from structure
      if isempty(BFT_Fiber_Type_Database(i).Fiber_Type_Name)
         BFT_Fiber_Type_Database(i)=[];
      else
         break
      end
   end
   for i = 1:length(BFT_Fiber_Type_Database)-1%Check that all fiber types have unique names
      for j = i+1:length(BFT_Fiber_Type_Database)
         if strcmp(BFT_Fiber_Type_Database(i).Fiber_Type_Name,BFT_Fiber_Type_Database(j).Fiber_Type_Name)
            buttonname=questdlg('All fiber types must have unique names! Please check and fix before saving!',...
               'Non-unique names detected!','Ok','Ok');
            return
         end
      end
   end
   if isempty(BFT_Save_File)
      BFT_Save_File='*.mat';
   end
   [filename pathname]=uiputfile([BFT_Save_Path BFT_Save_File],'Save fiber_type_database.mat file as...');
   %Can't check the following until AFTER the name has been entered, because Matlab doesn't update
   %the Editable Text Boxes (ETBs) until after a 'return' has been entered.
   if BFT_FTD_General_Parameters.Sarcomere_Length<=0
      buttonname=questdlg('Sarcomere Length must be > 0! Please check and fix before saving!',...
         'Inappropriate Sarcomere Length!','Ok','Ok');
      return
   end
   if BFT_FTD_General_Parameters.Specific_Tension<=0
      buttonname=questdlg('Specific Tension must be > 0! Please check and fix before saving!',...
         'Inappropriate Specific Tension!','Ok','Ok');
      return
   end
   if ~(filename==0)
      Fiber_Type_Database=BFT_Fiber_Type_Database;
      FTD_General_Parameters=BFT_FTD_General_Parameters;
      save ([pathname filename],'Fiber_Type_Database', 'FTD_General_Parameters');
      BFT_Save_File=filename;
      BFT_Save_Path=pathname;
      set(BFT_Main_Window,'name',['BuildFiberTypes: ' filename]);
   else
      %disp('Didn''t want to save, eh?');
   end



%CUT Fiber Type.  Copy a selected fiber type onto a 'clipboard' and remove it from the current database
function Cut_Fiber_Type()
global BFT_Fiber_Type_Database   BFT_Clipboard_Fiber
   str={BFT_Fiber_Type_Database.Fiber_Type_Name};
   [selection,ok]=listdlg('promptstring','Select fiber to cut','selectionmode','single','liststring',...
      str,'name','Cut fiber');
   if ok
      BFT_Clipboard_Fiber=BFT_Fiber_Type_Database(selection);
      Initialize_Fiber_Type(selection);
   end



%COPY Fiber Type  Copy a selected fiber type onto a 'clipboard' but DO NOT remove it from the current FTD
function Copy_Fiber_Type()
global BFT_Fiber_Type_Database   BFT_Clipboard_Fiber
   str={BFT_Fiber_Type_Database.Fiber_Type_Name};
   [selection,ok]=listdlg('promptstring','Select fiber to copy','selectionmode','single','liststring',...
      str,'name','Copy fiber');
   if ok
      BFT_Clipboard_Fiber=BFT_Fiber_Type_Database(selection);
   end



%PASTE Fiber Type.  Paste the fiber type currently in the 'clipboard' into a selected spot in the current FTD
function Paste_Fiber_Type(fiber_type)
global BFT_Fiber_Type_Database   BFT_Clipboard_Fiber
   fibernumber=inputdlg('Fiber number to paste into:','Paste from clipboard',1);
   if ~isempty(fibernumber) & ~isempty(str2num(char(fibernumber)))
      BFT_Fiber_Type_Database(str2num(char(fibernumber)))=BFT_Clipboard_Fiber;
   end
   
   
   
%DELETE FIBER TYPE FROM LIST.  Delete a selected fiber type from the current FTD
function Delete_Fiber_Type
global BFT_Fiber_Type_Database
   str={BFT_Fiber_Type_Database.Fiber_Type_Name};
   [selection,ok]=listdlg('promptstring','Select fiber type to delete','selectionmode','single','liststring',...
      str,'name','Delete fiber');
   if ok
      for i=selection:length(BFT_Fiber_Type_Database)-1
         BFT_Fiber_Type_Database(i)=BFT_Fiber_Type_Database(i+1);
      end
      %I changed the following because it didn't appear to make sense and because it
      %did cause errors when deleting the last 1 or 2 fiber types April, 2000
      %Initialize_Fiber_Type(length(BFT_Fiber_Type_Database)-1);  
      Initialize_Fiber_Type(length(BFT_Fiber_Type_Database));
	   Refresh;
   end



%INSERT (empty) Fiber Type into the current FTD (i.e. make an empty space).
function Insert_Fiber_Type()
global BFT_Fiber_Type_Database
   str={BFT_Fiber_Type_Database.Fiber_Type_Name};
   [selection,ok]=listdlg('promptstring','Insert blank before which fiber type','selectionmode',...
      'single','liststring',str,'name','Insert blank fiber');
   if ok
      for i=length(BFT_Fiber_Type_Database)-1:-1:selection
         BFT_Fiber_Type_Database(i+1)=BFT_Fiber_Type_Database(i);
      end
      Initialize_Fiber_Type(selection);
   end



%IMPORT A FIBER TYPE FROM ANOTHER FILE
%Open another FTD, select one of the fiber types in it and paste that fiber type into the 'clipboard'
function Import_Fiber_Type()
global BFT_Clipboard_Fiber   BFT_Fiber_Type_Database   BFT_FTD_General_Parameters
	[Fiber_Type_Database, FTD_General_Parameters, filename, pathname, error]=Open_FTD_File;
   if strcmp(error,'false')
 		str={Fiber_Type_Database.Fiber_Type_Name};
   	[selection,ok]=listdlg('promptstring','Select fiber to import','selectionmode','single','liststring',...
   	   str,'name','Import fiber');
   	if ok
         Fiber_Type_Database=Update_FTD(Fiber_Type_Database);
         if (FTD_General_Parameters.Sarcomere_Length~=BFT_FTD_General_Parameters.Sarcomere_Length) &...
               (BFT_FTD_General_Parameters.Sarcomere_Length~=0)
            answer=questdlg('The sarcomere length of the imported fiber type is different from current sarcomere length.  Scale the imported fiber types''s FL and PE2?',...
               'Scale FL?', 'OK', 'No', 'OK');
            if strcmp(answer,'OK')
               Fiber_Type_Database=Scale_FL(Fiber_Type_Database,...
                  BFT_FTD_General_Parameters.Sarcomere_Length, FTD_General_Parameters.Sarcomere_Length);
            end
         end
         BFT_Clipboard_Fiber=Fiber_Type_Database(selection);
         Paste_Fiber_Type;
   	end   
   end
   
   

% change sarcomere length.  Query if user wants to scale FL relationship
% This function is called with the sarcomere length is changed in the main window.  The user
% has the option of scaling the tetanic FL relationship in proportion to the change in 
% sarcomere length
function Change_SL
global BFT_Fiber_Type_Database   BFT_Old_SL   BFT_FTD_General_Parameters
	if BFT_Old_SL==0
      stop='true';
   else
      stop='false';
   end
   while strcmp(stop, 'false')
      buttonpushed=questdlg('Do you wish to scale the tetanic Force-Length relationships and Passive forces (component 2) for ALL fibers in proportion to optimal sarcomere length?',...
   		'Scale FL and PE2 relationships?',...
   	   'Scale FL and PE2 relationship', 'Don''t Scale',  'Help', ...
         'Scale FL and PE2 relationship');
      stop='true';
      if strcmp(buttonpushed,'Scale FL and PE2 relationship')
         BFT_New_SL=BFT_FTD_General_Parameters.Sarcomere_Length;
         BFT_Fiber_Type_Database=Scale_FL(BFT_Fiber_Type_Database, BFT_New_SL, BFT_Old_SL);
		   %do NOT calculate new PE1 coefficients, PE1 is in units of Lmax and is probably affected by
		   %endomysial crap, so it isn't affect by changing SL
		   %calculate new PE2 coefficients
		   ratio=BFT_New_SL/BFT_Old_SL;
		   BFT_FTD_General_Parameters.Lr2=BFT_FTD_General_Parameters.Lr2/ratio;
		   BFT_FTD_General_Parameters.k2=BFT_FTD_General_Parameters.k2*ratio;
      elseif strcmp(buttonpushed,'Help')
         Help_Scaling_Dialog;
   	   stop='false';		%return to while loop to find answer
      end
   end
   
   
   
%This function scales the FL relationship of Fiber_Type_Database according to the new and old SLs passed in.  
function [Fiber_Type_Database]=Scale_FL(Fiber_Type_Database, newSL, oldSL)
   force=0.9;		%the estimate of the d omega/dL derivative is calculated at this force level.
   omega=[Fiber_Type_Database.FL_omega];
   beta=[Fiber_Type_Database.FL_beta];
   rho=[Fiber_Type_Database.FL_rho];
   % replace zeros with 1 so that we don't get div/0 errors 
   omega=(omega==0)+omega;
   beta=(beta==0)+beta;
   rho=(rho==0)+rho;
   temp=(-log(force)).^(1./rho);
   %actual lengths at force level (1st length is the shorter one)
   length1=(1-omega.*temp).^(1./beta);
   length2=(omega.*temp+1).^(1./beta);
   %derivatives of dw/dL at force level
   domega_dlength1=-(beta.*length2.^(beta-1))./temp;
   domega_dlength2=(beta.*length1.^(beta-1))./temp;
   %theoretical changes in Length at force level
   zdisk_length=0.1;		%estimated length of z-disks per sarcomere in um
   empty_thick_filament_length=0.17;	%estimated length of thick filament with no cross-bridge sites (um)
   thick_filament_length=1.6;				%estimated length of thick filament (um)
   old_thin_filament_length=0.5*(oldSL-zdisk_length-empty_thick_filament_length/2);
   new_thin_filament_length=0.5*(newSL-zdisk_length-empty_thick_filament_length/2);
   %first one assumes an ascending slope of 0.28 F0/um from Herzog et al. 1992
   slope=0.28;
   oldlength=2*old_thin_filament_length+0.1-(1-force)/slope;	% in um
   newlength=2*new_thin_filament_length+0.1-(1-force)/slope;	% in um
   dlength1=newlength/newSL - oldlength/oldSL;
   %second, one assumes zero force at 2*thin_filament_length+thick_filament_length + Z-disks.
   slope=1/thick_filament_length;	% in F0/um
   oldlength=2*old_thin_filament_length + empty_thick_filament_length + zdisk_length +(1-force)*slope;	% in um
   newlength=2*new_thin_filament_length + empty_thick_filament_length + zdisk_length +(1-force)*slope;	% in um
   dlength2=newlength/newSL - oldlength/oldSL;
   %estimate average change in omega
   domega=0.5*(domega_dlength1.*dlength1 + domega_dlength2.*dlength2);
   %to avoid div0 errors, I replaced 0's with 0.1 up above.  I don't want to put a non-zero omega
   %back into what was originally a 0, so in the new omega vector, make sure that zeros are correct
   temp=(omega+domega).*([Fiber_Type_Database.FL_omega]~=0);	
   temp=num2cell(temp);									%must convert vector to cells so that they can be 'dealt'
	[Fiber_Type_Database.FL_omega]=deal(temp{:});		%copies V0.5 values for all fibers at once.
   
   
   
%QUERY IF USER WANTS TO SCALE ALL FREQ (and possibly velocity) RELATED CONSTANTS
%This function is called when f0.5 is changed in the main window.  The user has the option 
%of scaling rise and fall times constants by the inverse amount that f0.5 was changed by
%and also of scaling v0.5 and the FV relationship by the same amount.
function Change_f0_5(fibernumber)
global BFT_Old_F0_5   BFT_Fiber_Type_Database
	if BFT_Old_F0_5==0
   	stop='true';
   else
      stop='false';
   end
   while strcmp(stop, 'false')
      buttonpushed=questdlg(['Do you wish to scale any terms in proportion to f0.5 (e.g. rise and fall time constants, V0.5 etc. ) for fibertype # '...
   	   num2str(fibernumber) '?' ],...
   		'Scale f0.5 related terms?',...
   	   'Scale Terms?', 'Don''t Scale Any Other Terms',  'Help', ...
         'Scale Terms?');
      stop='true';
   	if strcmp(buttonpushed,'Scale Terms?')
		   ratio=BFT_Fiber_Type_Database(fibernumber).F0_5/BFT_Old_F0_5;
   	   buttonpushed=questdlg(['Which terms do you wish to scale for fiber # ' num2str(fibernumber) '?' ],...
  			 	'Scale f0.5 related terms?',...
   	   	'Time Constants and V0.5?', 'Time Constants only?',  'Neither', ...
   	   	'Time Constants and V0.5?');
			if strcmp (buttonpushed, 'Time Constants and V0.5?')
		      Scale_Rise_and_Fall_Times(ratio, fibernumber);
   	      Scale_FV_Relationship(ratio, fibernumber);
   	      BFT_Fiber_Type_Database(fibernumber).V0_5=BFT_Fiber_Type_Database(fibernumber).V0_5*ratio;
		   elseif strcmp(buttonpushed,'Time Constants only?')
   	      Scale_Rise_and_Fall_Times(ratio, fibernumber);
   	   end
   	elseif strcmp(buttonpushed,'Help')
   	   questdlg('Scaling the time constants will automatically rescale the terms Tf1, Tf2, Tf3 and Tf4 by the ratio 1/f0.5.  Thus increaseing f0.5 will decrease the time constants (thus making it ''faster'').  Scaling V0.5 will scale the FV relationship''s bV and Vmax in proportion to V0.5 as well as the energy rate constants ch0 and ch3.  Thus increasing f0.5 will stretch the FV relationship (making it ''faster'').',...
            'Help', 'OK', 'OK');
   	   stop='false';		%return to while loop to find answer
      end
   end
  
   
   
%QUERY IF USER WANTS TO SCALE FREQUENCY RELATED CONSTANTS AS WELL
%this is called if V0.5 is changed in the main window.  The user can scale only the FV relationship by
%the amount that V0.5 is changed, or they can also scale f0.5 and the rise and fall time constants by
%the same amount
function Change_V0_5(fibernumber)
global BFT_Old_V0_5 BFT_Fiber_Type_Database
	if BFT_Old_V0_5==0
   	stop='true';
   else
      stop='false';
   end
   while strcmp(stop,'false')
      buttonpushed=questdlg(['The FV relationship and energy rate equations will be scaled in proportion to V0.5 for fibertype # '...
      	num2str(fibernumber) '.  Would you also like f0.5 and the rise and fall times scaled in proportion to 1/V0.5 ?'],...
	 		'Scale V0.5 related terms?',...
      	'Scale f0.5 and Time constants as well', 'FV & energy rates only?',  'Help', ...
      	'Scale f0.5 and Time constants as well');
      ratio=BFT_Fiber_Type_Database(fibernumber).V0_5/BFT_Old_V0_5;
      stop='true';
   	if strcmp(buttonpushed,'Scale f0.5 and Time constants as well')
      	Scale_Rise_and_Fall_Times(ratio, fibernumber);
      	BFT_Fiber_Type_Database(fibernumber).F0_5=BFT_Fiber_Type_Database(fibernumber).F0_5*ratio;
         Scale_FV_Relationship(ratio, fibernumber);
   	elseif strcmp(buttonpushed,'FV & energy rates only?')
   	   Scale_FV_Relationship(ratio, fibernumber);
   	elseif strcmp(buttonpushed,'Help')
         questdlg(['Scaling the time constants will automatically rescale the terms Tf1, Tf2, Tf3 and Tf4 ' ...
               'by the ratio 1/V0.5.  Thus increasing V0.5 will decrease the time constants '...
               '(making the fiber ''faster'').  Scaling the FV relationship will scale bV and '...
               'Vmax in proportion to V0.5.  Thus increasing V0.5 will stretch the FV relationship '... 
               '(making it ''faster'').'],'Help','Ok','Ok');
         stop='false';
      end
   end
   
   
   
%Scale the rise and fall time constants by 1/ratio (ratio is new_V0.5/old_V0.5 or new_f0.5/old_f0.5).
function Scale_Rise_and_Fall_Times(ratio, fibernumber)
global BFT_Fiber_Type_Database
	BFT_Fiber_Type_Database(fibernumber).Tf1=BFT_Fiber_Type_Database(fibernumber).Tf1/ratio;
   BFT_Fiber_Type_Database(fibernumber).Tf2=BFT_Fiber_Type_Database(fibernumber).Tf2/ratio;
   BFT_Fiber_Type_Database(fibernumber).Tf3=BFT_Fiber_Type_Database(fibernumber).Tf3/ratio;
   BFT_Fiber_Type_Database(fibernumber).Tf4=BFT_Fiber_Type_Database(fibernumber).Tf4/ratio;
   
   
   
%Scale the FV relationship AND ENERGY RATE CONSTANTS!!! by ratio (ratio is new_V0.5/old_V0.5 or new_f0.5/old_f0.5)
function Scale_FV_Relationship(ratio, fibernumber)
global BFT_Fiber_Type_Database
   BFT_Fiber_Type_Database(fibernumber).bV = BFT_Fiber_Type_Database(fibernumber).bV*ratio;
   BFT_Fiber_Type_Database(fibernumber).Vmax = BFT_Fiber_Type_Database(fibernumber).Vmax*ratio;
   BFT_Fiber_Type_Database(fibernumber).ch0 = BFT_Fiber_Type_Database(fibernumber).ch0*ratio;
   BFT_Fiber_Type_Database(fibernumber).ch3 = BFT_Fiber_Type_Database(fibernumber).ch3*ratio;
   
   
   
% Help DIALOG BOX 
function Help_Dialog()
global BFT_Main_Window   BFT_Coefficient_Window   BFT_Generic_Window
   %Is the main BFT_Main_Window open and visible?
   if ~isempty(findobj('tag','FTD_BFT_Main_Window'))
      if strcmp(get(BFT_Main_Window,'visible'),'on')
         s=strvcat(...
            'This program allows a user to store and manipulate fiber types in a database format.',...
            ' ',...
        		'The basic things that can be done to the database include loading/saving entire databases, importing single fiber types from another database, adding/deleting fiber types and editing current fiber type properties.',...
            ' ',...
            'Editing the fiber type properties can be done at two levels.  At the ''higher'' level, the items listed on this main window can be edited (e.g. f0.5, V0.5), while at a ''lower'' level you can edit the co-efficients for each contractile property (e.g. FL, FV).',...
            ' ',...
            'Editing some of the properties on this main ''higher'' level, can be used to scale automatically the parameters in the ''lower'' level.  See Help => Definitions for more details on this.',...
            ' ',...
            'The definitions for the various properties listed on this page can be found in the ''definitions'' help function.');
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-25 b(2)-25 b(3)+50 b(4)+20]);
      end
   end
   %Is the Edit_Coefficients_Window open and visible?
   if ~isempty(findobj('tag','FTD_BFT_Coefficient_Window'))
      if strcmp(get(BFT_Coefficient_Window,'visible'),'on')
         s=strvcat(...
            'The Edit Coefficients Window allows the user to directly change the coeffiecients of the various functions.',...
            ' ',...
            'At this stage, we have not implemented a visual aid to demonstrate the effects of these changes.  The exact equations used can be found in the publications by Brown et al. (1999), Brown and Loeb (2000) and Cheng et al. (2000) - first two in the J. Muscle Res. Cell Motil., last one in J. Neurosci. Meth.',...
            ' ',...
            'Any changes to the shortening half of the FV relationship will automatically be updated/reflected in V0.5');      
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-10 b(2)-25 b(3)+20 b(4)+20]);   
      end
   end
   %Is the Edit_Generic_Window open and visible?
   if ~isempty(findobj('tag','Generic_BFT_Coefficient_Window'))
      if strcmp(get(BFT_Generic_Window,'visible'),'on')
         s=strvcat(...
            'The Edit Generic Coefficients Window allows the user to directly change the coeffiecients of the various functions that affect ALL fiber types in a given database.',...
            ' ',...
            'These parameters only have an effects on Simulink blocks produced in the BuildMuscles funtion.',...
            ' ',...
            'At this stage, we have not implemented a visual aid to demonstrate the effects of change the SE parameters .  The exact equation used can be found in the publication Brown et al. (1999) in J. Muscle Res. Cell Motil.');   
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-10 b(2)-25 b(3)+20 b(4)+20]);   
      end
   end



%Definitions DIALOG BOX
function Definitions_Dialog()
global BFT_Main_Window   BFT_Coefficient_Window   BFT_Generic_Window
   %Is the main BFT_Main_Window open and visible?
   if ~isempty(findobj('tag','FTD_BFT_Main_Window'))
      if strcmp(get(BFT_Main_Window,'visible'),'on')
         s=strvcat(...
            'Optimal Sarcomere Length is the length (in um) at which maximal, isometric, tetanic force is elicited.  Changing this value can be used to scale the FL and PE2 relationships.',...
            ' ',...
            'Specific Tension: This value is used by the BuildMuscles function to calculate Maximal force for a given cross-section.  A value of 31.8 N/cm2 is appropriate for feline muscle.',...
            ' ',...
            'Fiber type name: Input a _unique_ name for the fiber type (e.g. SS, FR, FF)',...
            ' ',...
            'Recruitment rank: Lower numbers are recruited first in a muscle composed of more than one fiber type; this value also affects the auto-distribution of PCSA by motor units in the BuildMuscles function',...
            ' ',...
            'V0.5: Shortening velocity at which half of maximal tetanic force is obtained (at 1.0 L0 and tetanic stimulation; units of L0/s).  Changing this will rescale the FV relationship and, if requested, f0.5 and rise and fall times.  This number should be -''ve',...
            ' ',...
            'f0.5: Frequency at which half of maximal tetanic force is obtained (isometric at 1.0 L0). Changing this value will, if requested, rescale rise and fall times and/or V0.5 and the FV relationship.',...
            ' ',...
            'fmin: The frequency at which a recruited motor unit of this fiber type begins firing, in units of f0.5.  When a Simulink block is created for a ''real'' muscle from the BuildMuscles function it includes a sub-block which parses the activation between various motor units.  When a given motor unit is first turned on, fmin is the frequency at which it starts to fire.',...
            ' ',...
            'fmax: The maximal frequency at which a recruited motor unit of this fiber type fires. This value is also only used by the BuildMuscles function.  Motor units are assumed to increase their firing rate as activation to the muscle increases until maximal activation (i.e. when activation equals 1). (Note: if activation is allowed to exceed 1 by the user, then this firing frequency will be exceeded).',...
            ' ',...
            'Comments: Any additional comments you wish to enter on the muscle');
         a=helpdlg(s,'Help');
         b=get(a,'position');
      end
   end
   %Is the Edit_Coefficients_Window open and visible?
   if ~isempty(findobj('tag','FTD_BFT_Coefficient_Window'))
      if strcmp(get(BFT_Coefficient_Window,'visible'),'on')
         s=strvcat(...
            'FL: Force-length',...
            'FV: Force-velocity',...
            'Af: Effective activation',...
            'Leff: Activation delay',...
            'fint and feff: Rise and fall times',...
            'S: Sag',...
            'Y: Yield');      
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-10 b(2)-25 b(3)+20 b(4)+20]);   
      end
   end
   %Is the Edit_Coefficients_Window open and visible?
   if ~isempty(findobj('tag','Generic_BFT_Coefficient_Window'))
      if strcmp(get(BFT_Generic_Window,'visible'),'on')
         s=strvcat(...
            'Specific Tension: This is the maximal isometric force producing at the optimal length per unit unit cross-sectional area.  Default of 31.8 N/cm2 (Scott et al., 1996 J Muscle Res. Cell Motil.; Brown et al., 1998, Exp Brain Res.).',...
            ' ',...
            'Viscosity: We include a nominal viscosity (default of 0.01) in parallel with the passive elements.  This has little effect on force but is crucial for stabilization of models',...
            ' ',...
            'Fpe1: Passive force component 1.  Parallel elastic element',...
            ' ',...
            'Fpe2: Passive force component 2.  Thick filament compression',...
             ' ',...
           'FSE: These are the parameters for the series elasticity (tendon and aponeurosis).');      
         a=helpdlg(s,'Help');
         b=get(a,'position');
         set(a,'position',[b(1)-10 b(2)-25 b(3)+20 b(4)+20]);   
      end
   end


%Help Scaling DIALOG
%This function puts the help dialog up scaling FL, V0.5 and f0.5
function Help_Scaling_Dialog
   s=strvcat(...
      ' ',...
      'Changing sarcomere length gives the user the option to automatically scale the FL and PE2 relationships.  Optimal sarcomere lengths for frog, cat and human are 2.2, 2.4 and 2.7 um respectively (Herzog et al., 1992).',...
      ' ',...
      'We have assumed that the thick filament length is constant at 1.6 um (Herzog et al., J. Biomech. 1992; 25:945) and that changes in optimal sarcomere length reflect changes in thin filament length.  ', ...
      ' ',...
      'Scaling the FL relationship automatically rescales ''FL_omega'' to widen or narrow the FL relationship.  The new FL_omega is estimated by',... 
      '(1) calculating domega/dL for F=0.9 for both the ascending and descending regions.  ',...
      '(2) calculating the theoretical change in L at F=0.9 for both regions.',...
      '(3) Taking the average change in omega produced by those changes.',...
      ' ',...
      'The Change in PE2 is done by assuming that it is caused by thick filament compression and that this is always the same in units of um.  Thus with longer optimal sarcomere lengths, the length (in units of L0) at which PE2 begins decreases and the slopes are steeper.', ...
      ' ',...
      '--------------------',...
      ' ',...
      'The FV relationship is scaled by assuming the the lengthening and shortening halves scale proportionally with V0.5, as appears to be the case for feline muscle (Brown et al., 1999)',...
      ' ',...
      '--------------------',...
      ' ',...
      'The rise and fall time constants are directly proportional to the rise and fall times of stimulus trains.  These appear to be proportional to f0.5 (see Brown and Loeb, 2000) and so the rise and fall time constants are all scaled in proportion to f0.5',...
      ' ',...
      '--------------------',...
      ' ',...
      'Two energy rate constants (ch1 and ch3) are directly proportional V0.5. ');
   questdlg(s,'Help','OK','OK');
   
   
   
%ABOUT THIS MARVELOUS PROGRAM
function About()
global BFT_Version
   s=strvcat(...
      ['Version ', BFT_Version],...
      'This program is written by Ernest Cheng, Ian Brown and Jerry Loeb.',...
      'For updates and documentation, please go to',...
      'http://ami.usc.edu/projects/ami/projects/bion/musculoskeletal/virtual_muscle.html');
   msgbox(s);
