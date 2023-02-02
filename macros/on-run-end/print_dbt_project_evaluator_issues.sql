{% macro _return_list_header_rows(query) %}

    {%- call statement('get_query_results', fetch_result=True,auto_begin=false) -%}

        {{ query }}

    {%- endcall -%}

    {% set sql_results=[] %}

    {%- if execute -%}
        {% set sql_results_table = load_result('get_query_results').table %}
        {% do sql_results.append(sql_results_table.column_names) %}
        {% for row_data in sql_results_table.rows %}
            {% do sql_results.append(row_data.values()) %}
        {% endfor %}
    {%- endif -%}

    {{ return(sql_results) }}

{% endmacro %}


{% macro print_dbt_project_evaluator_issues() %}

  {%- if flags.WHICH in ["build","test"] -%}
    {{ print("\n### List of issues raised by dbt_project_evaluator ###") }}

    {% for result in results | selectattr('failures') | selectattr('failures', '>', 0) %}
      
      {% if result.node.fqn[0] == "dbt_project_evaluator" %}
        
        {{ print("\n-- " ~ result.node.alias ~ " --") }}

        {% set model_checked = result.node.depends_on.nodes[0].split('.')[-1] %}
        {% set model_details = graph.nodes.values() | selectattr("name","==",model_checked) | first %}
        {% set model_schema = model_details.schema %}
        {% set model_database = model_details.database %}
        {% set db_schema = model_database ~ "." ~ model_schema if model_database else model_schema %}

        {% set sql_statement %}
        select * from {{db_schema}}.{{model_checked}}
        {% endset %}

        {%- set failures = dbt_project_evaluator._return_list_header_rows(sql_statement) -%}
        {% for row in failures %}
          {{ print(row | join(", ")) }}
        {% endfor %}

      {% endif %}

    {% endfor %}

    {{ print("\n") }}
  {%- endif %}

{% endmacro %}