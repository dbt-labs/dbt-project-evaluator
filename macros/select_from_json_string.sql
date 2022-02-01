{% macro select_from_json_string(json_string,columns) %}
  {{ return(adapter.dispatch('select_from_json_string')(json_string,columns)) }}
{% endmacro %}


{% macro snowflake__select_from_json_string(json_string,columns) %}

    with source as (
        select parse_json(column1) as src
            from values ('{{ json_string }}')
    )

    , flattened_json as (
        select 
            {% for column in columns %}
            value['{{ column }}']::string as {{ column }} {% if not loop.last %}, {% endif %}
            {% endfor %}
        from source
        , lateral flatten(input => src)
    )

    select * from flattened_json

{% endmacro %}



{% macro bigquery__select_from_json_string(json_string,columns) %}

    with source as (
        select json_extract_array('{{ json_string }}')
        as json_data
    )

    , unnested as (
        select 
            json_data
        from source,
        unnest(json_data) json_data
    )

    select 
        {% for column in columns %}
        json_extract_scalar(json_data, "$.{{column}}") as {{column}} {% if not loop.last %}, {% endif %}
        {% endfor %}
    from unnested

{% endmacro %}