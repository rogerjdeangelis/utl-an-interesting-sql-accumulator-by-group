An interesting sql accumulator by group

github
https://github.com/rogerjdeangelis/utl-an-interesting-sql-accumulator-by-group

SAS Forum
https://tinyurl.com/ycnfzy3p
https://communities.sas.com/t5/SAS-Programming/how-to-do-age-cumulative-sum-in-sashelp-class-in-sql/m-p/523867

PG Stats {rofile
https://communities.sas.com/t5/user/viewprofilepage/user-id/462

Whats important is understanding the operational order of SQL clauses

  1. From
  2. Where
  3. Group
  4. Having
  5. Select    ** way down here
  6. Distinct
  7. Union
  8. Order


INPUT  (Data does not have to be sorted - sorted for easy explanation)
=====

'Wouldn't quite work if there existed two students with same name, age and sex'
Should work with any primary key like 'Name'.
Generally SQL does not lend itself to cumulative sums.


WORK.HAVE total obs=19         | RULES
                               |
Obs    NAME       SEX    AGE   | cumAge
                               |
  1    Alice       F      13   |    13
  2    Barbara     F      13   |    26
  3    Carol       F      14   |    40
  4    Jane        F      12   |    52
  5    Janet       F      15   |    67
  6    Joyce       F      11   |    78
  7    Judy        F      14   |    92
  8    Louise      F      12   |   104
  9    Mary        F      15   |   119
                               |
 10    Alfred      M      14   |    14
 11    Henry       M      14   |    28
 12    James       M      12   |    40
 13    Jeffrey     M      13   |    53
 14    John        M      12   |    65
 15    Philip      M      16   |    81
 16    Robert      M      12   |    93
 17    Ronald      M      15   |   108
 18    Thomas      M      11   |   119
 19    William     M      15   |   134


EXAMPLE OUTPUT
--------------

 NAME      SEX       AGE     cumAge
 ----------------------------------
 Alice     F          13         13
 Barbara   F          13         26
 Carol     F          14         40
 Jane      F          12         52
 Janet     F          15         67
 Joyce     F          11         78
 Judy      F          14         92
 Louise    F          12        104
 Mary      F          15        119
 Alfred    M          14         14
 Henry     M          14         28
 James     M          12         40
 Jeffrey   M          13         53
 John      M          12         65
 Philip    M          16         81
 Robert    M          12         93
 Ronald    M          15        108
 Thomas    M          11        119
 William   M          15        134


PROCESS
=======

proc sql;
select
    a.name,
    a.sex,
    a.age,
    sum(b.age) as cumAge
from
    have as a left join
    have as b on a.sex=b.sex and a.name ge b.name
group by a.sex, a.name, a.age;
quit;


/* T1009630 Operational order of sql statements

github
https://github.com/rogerjdeangelis/utl_sql_operational_order_of_sql_statements

Probably not totally accurate for SAS 'proc sql' but is still helpful

ORDER OF SQL OPERATIONS

From      Where    Group    Having   Select    Distinct   Union  Order
FLORIDIAN WARRIORS GATHER   HAPPY    SEAWEED   DRIED      UNDER  OWNINGS

Inspired by
https://goo.gl/Nq3kzA
https://dzone.com/articles/a-beginners-guide-to-the-true-order-of-sqlnbspoper?edition=254681&utm_source=Daily%20Dest&utm_medium=email&utm_campan=dd%202016-1

Example
proc sql;
SELECT distinct(substr(name,1,2)), count(*) FROM sashelp.class WHERE name eqt 'J' GRPUP BY substr(name,1,2)  having count(*)>1
;quit;


The logical order of operations is the following (for “simplicity” I’m leaving out vendor specific
things like CONNECT BY, MODEL, MATCH_RECOGNIZE, PIVOT, UNPIVOT and all the others):

FROM: This is actually the first thing that happens, logically. Before anything else, we’re loading all
  the rows from all the tables and join them. Before you scream and get mad: Again, this is what happens
  first logically, not actually. The optimiser will very probably not do this operation first, that would
  be silly, but access some index based on the WHERE clause. But again, log
  ically, this happens first. Also: all the JOIN clauses are actually part of this FROM clause. JOIN is
  an operator in relational algebra. Just like + and - are operators in arithmetics.
  It is not an independent clause, like SELECT or FROM

WHERE: Once we have loaded all the rows from the tables above, we can now throw them away again using WHERE

GROUP BY: If you want, you can take the rows that remain after WHERE and put them in groups or buckets,
  where each group contains the same value for the GROUP BY expression (and all the other rows are put in a
  list for that group). In Java, you would get something like: Map<String, List<Row>>. If you do specify a
  GROUP BY clause, then your actual rows contain only the group columns
  , no longer the remaining columns, which are now in that list. Those columns in the list are only visible to
  aggregate functions that can operate upon that list. See below.
  aggregations: This is important to understand. No matter where you put your aggregate function syntactically
  (i.e. in the SELECT clause, or in the ORDER BY clause), this here is the step where aggregate functions are
  calculated. Rht after GROUP BY. (remember: logically. Clever databases may have calculated them before, actually).
  This explains why you cannot put an aggregate func
  tion in the WHERE clause, because its value cannot be accessed yet. The WHERE clause logically happens before
  the aggregation step. Aggregate functions can access columns that you have put in “this list” for each group, above.
  After aggregation, “this list” will disappear and no longer be available. If you don’t have a GROUP BY clause,
  there will just be one b group without any k
  ey, containing all the rows.
HAVING: … but now you can access aggregation function values. For instance, you can check that count(*) > 1
  in the HAVING clause. Because HAVING is after GROUP BY (or implies GROUP BY), we can no longer access columns
  or expressions that were not GROUP BY columns.
  WINDOW: If you’re using the awesome window function feature, this is the step where they’re all calculated.
  Only now. And the cool thing is, because we have already calculated (logically!) all the aggregate functions,
  we can nest aggregate functions in window functions. It’s thus perfectly fine to write things like sum(count(*))
  OVER () or row_number() OVER (ORDER BY count(*)). Win
  dow functions being logically calculated only now also explains why you can put them only in the SELECT or
  ORDER BY clauses. They’re not available to the WHERE clause, which happened before. Note that PostgreSQL and Sybase
  SQL Anywhere have an actual WINDOW clause!
SELECT: Finally. We can now use all the rows that are produced from the above clauses and create new rows / tuples
  from them using SELECT. We can access all the window functions that we’ve calculated, all the aggregate functions
  that we’ve calculated, all the grouping columns that we’ve specified, or if we didn’t group/aggregate, we can use
  all the columns from our FROM clause. Rem
  ember: Even if it looks like we’re aggregating stuff inside of SELECT, this has happened long ago, and the sweet
  sweet count(*) function is nothing more than a reference to the result.
DISTINCT: Yes! DISTINCT happens afterSELECT, even if it is put before your SELECT column list, syntax-wise. But
  think about it. It makes perfect sense. How else can we remove distinct rows, if we don’t know all the rows (and their columns) yet?
UNION, INTERSECT, EXCEPT: This is a no-brainer. A UNION is an operator that connects two subqueries. Everything
  we’ve talked about thus far was a subquery. The output of a union is a new query containing the same row types (i.e. same columns)
  as the first subquery. Usually. Because in wacko Oracle, the penultimate subquery
  is the rht one to define the column name. Oracle database
  , the syntactic troll
ORDER BY: It makes total sense to postpone the decision of ordering a result until the end, because all other
  operations mht use hashmaps, internally, so any intermediate order mht be lost again. So we can now order
  the result. Normally, you can access a lot of rows from the ORDER BY clause, including rows (or expressions)
  that you did not SELECT. But when you specified DISTINC
  T, before, you can no longer order by rows / expressions that were not selected. Why? Because the ordering would be quite undefined.












