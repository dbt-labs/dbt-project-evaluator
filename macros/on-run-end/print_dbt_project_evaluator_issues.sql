{% macro print_dbt_project_evaluator_issues(format='table') %}

  {%- if flags.WHICH in ["build","test"] -%}
    {{ print("\n### List of issues raised by dbt_project_evaluator ###") }}

    {% for result in results | selectattr('failures') | selectattr('failures', '>', 0) %}
      
      {% if result.node.fqn[0] == "dbt_project_evaluator" %}
        
        {{ print("\n-- " ~ result.node.alias ~ " --") }}

        {% set unique_id_model_checked = result.node.depends_on.nodes[0] %}

        {% set model_details = graph["nodes"][unique_id_model_checked] %}
        {% set name_model_checked = model_details.alias %}
        {% set model_schema = model_details.schema %}
        {% set model_database = model_details.database %}
        {% set db_schema = model_database ~ "." ~ model_schema if model_database else model_schema %}

        {% set sql_statement %}
        select * from {{db_schema}}.{{name_model_checked}}
        {% endset %}

        {% set query_results = run_query(sql_statement) %}
        {% if format == 'table' %}
          {{ print(query_results.print_table(max_column_width=80, max_rows=1000) or "") }}
        {% elif format == 'csv' %}  
          {{ print(query_results.print_csv() or "") }}
        {% else %}
            {%- do exceptions.raise_compiler_error("format can only be 'table' or 'csv'") -%}
        {% endif %}


      {% endif %}

    {% endfor %}

    {{ print("\n") }}
  {%- endif %}

{% endmacro %}