*******************************************************
** Emily Mitchell
** 12/18/2017
** Testing code output from MEPS summary tables app
*******************************************************;
ods graphics off;

ods html close; *ods html;
%macro run_sas(app);
	%let dirname = C:\Users\emily.mitchell\Desktop\GitHub\meps_JS\_check\test_code;
	%let code_dir = &dirname\&app\sas_codes;
	%let csv_dir = &dirname\&app\sas_results;

	%let rc = %sysfunc(filename(filrf,&code_dir));
	%let did = %sysfunc(dopen(&filrf));   

	%do i = 1 %to %sysfunc(dnum(&did));

		%let name = %qsysfunc(dread(&did,&i));
		%let outname = %substr(&name,1,%length(&name)-4);
		%let file_exists = %sysfunc(fileexist("&csv_dir\&outname..csv"));

%put file existenvce is &file_exists;
%put name of file is &name;

		/* Only run if results do not exist */
		%if &file_exists = 0 %then %do;
			%include "&code_dir\&name" ;

			%let stat = %scan(&outname, 1, "_");
			%let grp1 = %scan(&outname, 2, "_");
			%let grp2 = %scan(&outname, 3, "_");
			%let is_evt = %eval(&grp1 = event or &grp2 = event);
			
			%if &stat = avgEVT and &is_evt = 1 %then %do;
				%put Combining event datas;
				data out ;
					set out_RX out_DV out_IP out_ER out_HH 
						out_OB out_OBD out_OBO out_OP out_OPY out_OPZ indsname=dsn;
					event = scan(dsn, 2, "_");
				run;
			%end;

			proc sql;
				select count(*) into :nobs from out;
			quit;

			%if &nobs > 0 %then %do;
				PROC EXPORT DATA= WORK.OUT
					OUTFILE= "&csv_dir\&outname..csv" 
					DBMS=CSV REPLACE;
					PUTNAMES=YES;
				RUN;
			%end;

			PROC DATASETS library = work kill;
			run;
			quit;
		
		%end; 
	%end;
%mend;

/* May need to run multiple times -- due to permission issues in loop */
%run_sas(use);
%run_sas(ins);
%run_sas(care);
%run_sas(pmed);
%run_sas(cond);

%let i = 1;
%let app = use;
%let name = avgEVT_event_employed_2004.sas;
