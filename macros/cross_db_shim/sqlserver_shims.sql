{#-- dbt-sqlserver ships sqlserver__array_construct (JSON_ARRAY) but not array_append.
-- Same implementation as dbt-fabric. Can be removed once dbt-msft/dbt-sqlserver#861 is released. --#}
{% macro sqlserver__array_append(array, new_element) -%}
    JSON_MODIFY({{ array }}, 'append $', {{ new_element }})
{%- endmacro %}
