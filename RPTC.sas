*********************************************************************
*  Assignment:    RPTC                          
*                                                                    
*  Description:   PROC REPORT 
*
*  Name:          Joyce Choe
*
*  Date:          4/5/2024                                        
*------------------------------------------------------------------- 
*  Job name:      RPTC2.sas   
*
*  Purpose:       Generate macro table (Part A) and customize table (Part B); 
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         'Customize comparison tables for clinical studies' Baseline MACRO, 
*				  RPTC data set
*
*  Output:        RTF file
*                                                                    
********************************************************************;
options nodate mergenoby=warn varinitchk=warn nofullstimer;
options orientation=portrait;
libname ref "~/BIOS669/Data" access=readonly;
libname lib '~/BIOS669/Data/Macro';


/* Part A */
%include '~/BIOS669/Demo/Compare_baseline_669.sas';

%Compare_baseline_669 
(_DATA_IN=ref.rptc, 
_DATA_OUT=lib.rptc_macro, 
_NUMBER=1,
_group=trt, 
_predictors=race1 gender BMI cholesterol age heartrate,
_categorical=race1 gender,
_countable=Age HeartRate, 
_title1=Compare_baseline_characteristics macro,
_ID=BID);


/* Part B */ 
ods escapechar='#'; /*for indent space- see RPTC*/

proc format;
    value pvalue2_best   0-<0.001='<0.001'
                         0.001-<0.005=[5.3]
                         0.005-<0.045=[5.2]
                         0.045-<0.055=[5.3]
                         other=[5.2];
run;

%let st=style(column)=[just=center vjust=bottom font_size=9.5 pt]
        style(header)=[just=center font_size=9.5 pt];
 

proc sql noprint;
    select count(*) into :overall trimmed from ref.rptc; 
    select count(*) into :metN    trimmed from ref.rptc where trt='A';
    select count(*) into :placebo trimmed from ref.rptc where trt='B';
quit;
%put count_overall=&overall  count_A=&metN  count_b=&placebo;

        
data display;
    set lib.rptc_macro;
    
    length text $250;
    if _n_=1 then do;
        text='Baseline Characteristics';
        pvalue=.;
    end;
    
    if label='' and upcase(variable)="RACE1" then do;
        text="Race";
        order=5;
    end;
    *set pvalue to missing if you don't want it displayed;
    if strip(label)='- Black' then do;
        *indenting 5 spaces;
        text="#{nbspace 5}" || "Black";
        pvalue=.;
        order=6;
    end;
    
    if strip(label)='- Other' then do;
        text="#{nbspace 5}" || "Other";
        pvalue=.;
        order=8;
    end;
    
    if strip(label)='- White' then do;
        pvalue=.;
        order=7;
        text="#{nbspace 5}" || "White";

    end;
    if strip(label)='Age' then do;
        text='Age (years)';
        order=1;
    end;
    if strip(label)='Sex' then do;
        text=label;
        order=2;
    end;
    if strip(label)='Cholesterol(mg/dL)' then do;
        text='Cholesterol (mg/dL)';
        order=10;
    end;
        
    if strip(label)='Heart Rate (beats/min)' then do;
        text='Heart Rate (bpm)';
        order=11;
    end;
    
    if strip(label)='- F' then do;
        text="#{nbspace 5}" || "Female";
        pvalue=.;
        order=3;
    end;
    
    if strip(label)='- M' then do;
        text="#{nbspace 5}" || "Male";
        pvalue=.;
        order=4;
    end;
    
    if variable='BMI' then do;
        text="{BMI (kg/m\super 2}{)}";
        order=9;
    end;
run;
proc print data=display;
run;


ods rtf file="~/BIOS669/Output/RPTC_customised_table.RTF" style=journal bodytitle; 
ods listing close;
options missing=' ';

title1 j=c height=12pt
font='Arial' bold "Final Results Publication";
title2 j=c height=11pt bold font='Arial' "{Table 1. Characteristics of the METS Participants by Treatment Group}";
footnote1 j=l "{Note: Values expressed as N(%), mean }#{unicode '000B1'x}{ standard deviation, or median (25\super th}{,75\super th} {percentiles)}";
footnote2 j=l "P-values comparisons across treatment groups are based on chi-square.";
footnote3 j=l "P-values for continuous variables are based on ANOVA or Kruskal-Wallis test for median.";
footnote4 j=r "Created by &job._&onyen..sas on &sysdate at &systime";

%let st=style(column)=[just=center cellwidth=2.8 cm vjust=bottom font_size=8.5 pt]
style(header)=[just=center font_size=8.5 pt];
 
*Create the actual report with proc report;
options nodate nonumber orientation=landscape missing='';
ods escapechar='#';
proc report data=display nowd split='*';
    columns order text ('Treatment Group' column_1 column_2 column_overall) pvalue;
    define order/order noprint;
    define text/display "" style=[Asis=on];
    define pvalue/"P-value" center format=pvalue2_best. style(column)=[just=right cellwidth=2 cm vjust=bottom font_size=8.5 pt] 
							style(header)=[just=right cellwidth=2 cm font_size=8.5 pt];
    define column_1/"Metformin*(N=&metN)" center &st;
    define column_2/"Placebo*(N=&placebo)" center &st;
    define column_overall/"Overall*(N=&overall)" center &st;
run;

ods rtf close;
ods listing;
    
