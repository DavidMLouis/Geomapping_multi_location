/*Author: David M Louis*/
/*Contact: dmlouis87@gmail.com*/

proc sql;
	create table pharm_sub as
	select x AS long_2 LABEL='', y AS lat_2 LABEL='', Provider_Pin LABEL='' /*adjust data so it must state ID*/
	from pharm_ll;

proc sql;
	create table ltc_sub as
	select x AS long_1 LABEL='', y AS lat_1 LABEL='', Facility_ID LABEL='' /*adjust data so it must state ID*/
	from ltc_ll;

data inter;
  set ltc_sub;
  do _i=1 to _nobs;
    set pharm_sub nobs=_nobs point=_i;
    distance=geodist(lat_1, long_1, lat_2, long_2, 'm');
    output;
  end;
run;

/*proc sort data=inter;*/
/*  by Facility_ID distance;*/
/*run;*/
/**/
/*data want;*/
/*  set inter;*/
/*  by Facility_ID distance;*/
/*  if first.Facility_ID then n=1;*/
/*  else n+1;*/
/*  if n<=3 then output;*/
/*run;*/


data _null_;
call symputx('nlls',obs);
stop;
set inter nobs=obs; 
run;
 
* create a macro that contains a loop to access Google Maps multiple time;
%macro distance_time;

/* clear the log on each iteration */
dm 'clear log';

* delete any data set named DISTANCE_TIME that might exist in the WORK library;
proc datasets lib=work nolist;
delete distance_time;
quit;
 
%do j=1 %to &nlls;
data _null_;
nrec = &j;
set inter point=nrec;
call symputx('ll2', catx(',',lat_2,long_2));
call symputx('ll1', catx(',',lat_1,long_2));
stop;
run;

* lat/long of centroid of zip 12203 hard-coded as part of the URL;
%put &ll1 &ll2;
filename x url "https://www.google.com/maps/dir/&ll1/&ll2/?force=lite";
filename z temp;
 
* same technique used in the example with a pair of lat/long coodinates;
data _null_; 
infile x recfm=f lrecl=1 end=eof; 
file z recfm=f lrecl=1;
input @1 x $char1.; 
put @1 x $char1.;
if eof;
call symputx('filesize',_n_);
run;
 
* drive time as a numeric variable;
data temp;
infile z recfm=f lrecl=&filesize. eof=done;
input @ 'miles' +(-15) @ '"' distance :comma12. text $30.;
units    = scan(text,1,'"');
text     = scan(text,3,'"');
* convert times to seconds;
  select;
* combine days and hours;
   when (find(text,'d') ne 0) time = sum(86400*input(scan(text,1,' '),best.), 
                                        3600*input(scan(text,3,' '),best.));
* combine hours and minutes;
   when (find(text,'h') ne 0) time = sum(3600*input(scan(text,1,' '),best.), 
                                        60*input(scan(text,3,' '),best.));
* just minutes;
   otherwise                  time = 60*input(scan(text,1,' '),best.);
  end;
output; 
keep distance time;
stop;
done:
output;
run;
 
filename z clear;
filename x clear;

* add an observation to the data set DISTANCE_TIME;
proc append base=distance_time data=temp;

run;
%end;
%mend;
 
* use the macro;
%distance_time;

data distance_time;
format time time6.;
set distance_time;
set inter point=_n_;
run;


proc sort data=distance_time;
  by Facility_ID distance;
run;

data want;
  set distance_time;
  by Facility_ID distance;
  if first.Facility_ID then n=1;
  else n+1;
  if n<=3 then output;
run;

proc export data=want
	outfile=""
	dbms=xlsx;
run;


