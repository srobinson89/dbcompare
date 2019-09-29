/dbcompare.q
/functions to compare every element of two tables
/TODO - convert all string columns to symbol type
/TODO - add more type checks

\d .dbcompare

sortcols:enlist ` /columns to sort two input tables
matchcols:enlist ` /define which records to check

/globals to store missing records
missing_t1:()
missing_t2:()

configure:{[sortcls;matchcls]
 `sortcols set sortcls
 `matchcols set matchcls
  }
  
run:{[t1;t2] 
  /check config has been set up
  if[all null .dbcompare.matchcols;-1"[ERROR] Must configure sortcols and matchcols first";:()]; 
  -1"[INFO] Running table comparisons";
  -1"[INFO] Count of table 1: ",string count t1;  
  -1"[INFO] Count of table 2: ",string count t2;
  
  -1"[INFO] Sub-selecting matching records by columns: ","," sv string matchcols;
  //pull out any records which don't exist in both tables
  c1:?[t1;();0b;{x!x}matchcols];
  c2:?[t2;();0b;{x!x}matchcols];
  missing_t1,:t1 miss_t1_idx:where not c1 in c2;
  missing_t2,:t2 miss_t2_idx:where not c2 in c1;
  t1cmp:t1 where c1 in c2;
  t2cmp:t2 where c2 in c1;
 
  /Print count of records not in each 
  -1 "[INFO] ",string[count[miss_t1_idx]]," records from t1 not in t2. Saved to .dbcompare.missing_t1";
  -1 "[INFO] ",string[count[miss_t2_idx]]," records from t2 not in t1. Saved to .dbcompare.missing_t2";

  /sort matching records prior to comparison
  t1cmp:sortcols xasc t1cmp;
  t2cmp:sortcols xasc t2cmp;
  
  -1"[INFO] Comparing tables using t1=t2 operator";
  /comparison metrics
  diffd:flip t1cmp=t2cmp;
  diffd0:{where not x}each diffd;
  diffd1:{sum where not x}each diffd;
  mismatchedCols:where 0<diffd1;
  indicies:diffd0 where 0<diffd1;
  nvalues:count[t1]*count[cols[t1]]; /total number of values in table
  percentageMatch:100*(nvalues-count[indicies])%nvalues;
  -1"[INFO] Percentage match, after record exclusion is: ",string[percentageMatch],"%";
 
  /select col c from t1 & t2, and i in ids
  diffsbycol:{[t1;t2;c;ids] 
  cnames:`$("t1_",string[c];"t2_",string[c]);
  r:([]t1val:?[t1;enlist(in;`i;ids);();c];  
       t2val:?[t2;enlist(in;`i;ids);();c]);  
  cnames xcol r
  }[t1cmp;t2cmp;;]'[mismatchedCols;value mismatchedCols#diffd0];

  ([]colName:mismatchedCols;indicies:indicies;valdiff:diffsbycol)
  
  }
  
\d . 

/testing
/.dbcompare.matchcols:.dbcompare.sortcols:enlist `time
/t1:([]time:2019.01.01D00:00+01:00*til 5;sym:`a`b`c`d`e;price:10 22 30 40 50f;qty:10 20 30 40 50);
/t2:([]time:2019.01.01D01:00+01:00*til 5;sym:`b`c`d`e`f;price:20 30 40 51 60f;qty:20 30 42 50 50);