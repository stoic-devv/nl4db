CREATE OR REPLACE FUNCTION load_csv_file(
    target_table text,
    csv_path text,
    col_count integer)
  RETURNS void AS
$BODY$

declare

iter integer; -- dummy integer to iterate columns with
col text; -- variable to keep the column name at each iteration
col_first text; -- first column name, e.g., top left corner on a csv file or spreadsheet

begin
    set schema 'public';

    create table temp_table ();

    -- add just enough number of columns
    for iter in 1..col_count
    loop
        execute format('alter table temp_table add column col_%s text;', iter);
    end loop;

    -- copy the data from csv file
    execute format('copy temp_table from %L with delimiter '','' quote ''"'' csv ', csv_path);

    iter := 1;
    col_first := (select col_1 from temp_table limit 1);

    -- update the column names based on the first row which has the column names
    for col in execute format('select unnest(string_to_array(trim(temp_table::text, ''()''), '','')) from temp_table where col_1 = %L', col_first)
    loop
        execute format('alter table temp_table rename column col_%s to %s', iter, col);
        iter := iter + 1;
    end loop;

    -- delete the columns row
    execute format('delete from temp_table where %s = %L', col_first, col_first);

    -- change the temp table name to the name given as parameter, if not blank
    if length(target_table) > 0 then
        execute format('alter table temp_table rename to %I', target_table);
    end if;

end;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION load_csv_file(text, text, integer)
  OWNER TO postgres;


-- select load_csv_file('arrests','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Arrests.csv',24);
-- select load_csv_file('chi_pub_school','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Chicago_Public_Schools_-_School_Profile_Information_SY1617.csv',91);
-- select load_csv_file('violence_reduction','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Violence_Reduction_-_Victims_of_Homicides_and_Non-Fatal_Shootings.csv',38);
-- select load_csv_file('crimes','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Crimes_-_2001_to_Present.csv',22);
-- select load_csv_file('life_exp_by_race','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Public_Health_Statistics_-_Life_Expectancy_By_Race_Ethnicity_-_Historical.csv',11);
-- select load_csv_file('life_exp_by_comm_area','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Public_Health_Statistics_-_Life_Expectancy_By_Community_Area_-_Historical.csv',11);
-- select load_csv_file('population_census_by_block','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Population_by_2010_Census_Block.csv',3);
-- select load_csv_file('public_health_indicators_by_comm_area','/Users/adityakanthale/Documents/padhai/cs597/data/chicago-open-data/Public_Health_Statistics_-_Selected_public_health_indicators_by_Chicago_community_area_-_Historical.csv',29);