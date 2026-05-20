with sources as (
    select
        resource_name,
        case 
            -- if you're using databricks but not the unity catalog, database will be null
            when {{ dbt_project_evaluator.quote_identifier('database') }} is NULL then {{ dbt.concat([dbt_project_evaluator.quote_identifier('schema'), "'.'", "identifier"]) }}
            else {{ dbt.concat([dbt_project_evaluator.quote_identifier('database'), "'.'", dbt_project_evaluator.quote_identifier('schema'), "'.'", "identifier"]) }}
        end as source_db_location 
    from {{ ref('int_all_graph_resources') }}
    where resource_type = 'source'
    and is_excluded = cast(0 as {{ dbt.type_boolean() }})
    {% if target.type not in ['fabric'] %}
    -- we order the CTE so that listagg returns values correctly sorted for some warehouses
    order by 1, 2
    {% endif %}
),

source_duplicates as (
    select
        source_db_location,
        {{ dbt.listagg(
            measure = 'resource_name',
            delimiter_text = "', '",
            order_by_clause = 'order by resource_name' if target.type in ['snowflake','redshift','duckdb','trino','fabric'])
        }} as source_names
    from sources
    group by source_db_location
    having count(*) > 1
)

select * from source_duplicates

{{ filter_exceptions() }}
