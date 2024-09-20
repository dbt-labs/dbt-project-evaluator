with sources as (
    select
        resource_name,
        case 
            -- if you're using databricks but not the unity catalog, database will be null
            when database is NULL then {{ dbt.concat(["schema", "'.'", "identifier"]) }} 
            else {{ dbt.concat(["database", "'.'", "schema", "'.'", "identifier"]) }} 
        end as source_db_location 
    from {{ ref('int_all_graph_resources') }}
    where resource_type = 'source'
    and not is_excluded
    -- we order the CTE so that listagg returns values correctly sorted for some warehouses
    order by 1, 2
),

source_duplicates as (
    select
        source_db_location,
        {{ dbt.listagg(
            measure = 'resource_name', 
            delimiter_text = "', '", 
            order_by_clause = 'order by resource_name' if target.type in ['snowflake','redshift','duckdb','trino'])
        }} as source_names
    from sources
    group by source_db_location
    having count(*) > 1
)

select * from source_duplicates

{{ filter_exceptions() }}
