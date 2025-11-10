
/* ETL Process */
PROC SQL;
   CREATE TABLE WORK.MergedTables AS 
   SELECT t1.PlayerID, 
          t1.TheoWin, 
          t1.CoinIn, 
          t1.Win, 
          t1.EndTime, 
          t1.GamingArea1, 
          t1.'Gaming Area 2'n, 
          t2.Nationality, 
          /* GameType */
            (CASE
              WHEN t1.GamingArea1 LIKE '%Table%' THEN 'Table'
              WHEN t1.GamingArea1 LIKE '%Slot%' THEN 'Slot'
              WHEN t1.GamingArea1 LIKE '%ETG%' THEN 'ETG' ELSE ''
            END) AS GameType, 
          /* Period */
            (CASE
             WHEN DATEPART(t1.EndTime) = '12FEB2025'D THEN 'Yesterday'
             WHEN DATEPART(t1.EndTime) = '05FEB2025'D THEN 'P1W'
             WHEN DATEPART(t1.EndTime) = '29JAN2025'D THEN 'P2W'
             WHEN DATEPART(t1.EndTime) = '22JAN2025'D THEN 'P3W' ELSE 'NA'
            END) AS Period, 
          /* NationalityGroup */
            (CASE
             WHEN t2.Nationality = 'Philippines' then 'Philippines'
             WHEN t2.Nationality = 'USA' then 'USA' else 'Others'
            END) AS NationalityGroup
      FROM WORK.GAMINGSESSION t1
           LEFT JOIN (WORK.PLAYER t3
           LEFT JOIN WORK.NATIONALITY t2 ON (t3.NationalityCode = t2.NationalityCode)) ON (t1.PlayerID = t3.PlayerID);
QUIT;

/* Aggregate */
PROC SQL;
   CREATE TABLE WORK.R1 AS 
   SELECT t1.Period, 
          t1.NationalityGroup, 
          /* UniquePlayer */
            (COUNT(DISTINCT(t1.PlayerID))) FORMAT=COMMA21. AS UniquePlayer, 
          /* TheoWin */
            (SUM(t1.TheoWin)) FORMAT=COMMA21. AS TheoWin, 
          /* CoinIn */
            (SUM(t1.CoinIn)) FORMAT=COMMA21. AS CoinIn, 
          /* ActualWin */
            (SUM(t1.Win)) FORMAT=COMMA21. AS ActualWin
      FROM WORK.MERGEDTABLES t1
      WHERE (t1.Period NOT = 'NA')
      GROUP BY t1.Period,
               t1.NationalityGroup
      ORDER BY t1.NationalityGroup;
QUIT;


/* Transpose Program */
proc transpose data=work.R1 out=work.R2 ;
    by NationalityGroup;
    id Period;
    var UniquePlayer CoinIn ActualWin TheoWin;
run;

/* Program for Email sending with embedded report */

options emailhost=
(
	"mail.sample.com"
	port=587 STARTTLS
	auth=plain
	id="sample@email.com"
	pw="mypassword"
);
 
options emailsys=smtp;


filename msg email
   to="HarryF@email.com"
   from="sample@email.com"
   subject="Daily Gaming Performance"
   type="text/html";
 


ods html file=msg;
ods escapechar='^';

ods html text="
<html>
<body style='font-size: 12px;'>
   <h1 style='color: #4CAF50;'>Hi Team!</h1>
   <p style='font-size: 12px;'>Attached here is the Gaming Performance for today.</p>
";
proc report data=work.R3 nowd;
	column Category NationalityGroup Yesterday P1W P2W P3W ((''('YESTERDAY VS.' 'VS P1W'n 'VS P2W'n 'VS P3W'n))) ;
    define Category / group 'Category' style={font_weight=bold textalign=center};
    define Yesterday / analysis sum 'YESTERDAY' style={font_weight=bold textalign=center};
	define P1W / analysis sum 'P1W' style={font_weight=bold textalign=center};
	define P2W / analysis sum 'P2W' style={font_weight=bold textalign=center};
	define P3W / analysis sum 'P3W' style={font_weight=bold textalign=center};
    define 'vs P1W'n / analysis sum 'P1W (%)' style={font_weight=bold textalign=center} format=percent8.1;
	define 'vs P2W'n / analysis sum 'P2W (%)' style={font_weight=bold textalign=center} format=percent8.1;
	define 'vs P3W'n / analysis sum 'P3W (%)' style={font_weight=bold textalign=center} format=percent8.1;

break after Category / summarize style={font_weight=bold};
   
compute after Category;
	Category = '';
	NationalityGroup = 'Total';
        line '';
    endcomp;
 
run;

ods html text="
   <br>
   <p style='font-size: 12px;'>Best regards,
   <br style='font-size: 12px;'>Harry F.</p>
</body>
</html>
";
ods html close;






