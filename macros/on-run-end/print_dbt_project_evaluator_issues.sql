{% macro print_dbt_project_evaluator_issues(format='table', quote="") %}

  {%- if flags.WHICH in ["build","test"] -%}
    {{ print("\n### List of issues raised by dbt_project_evaluator ###") }}

    {#-
      if you create custom dbt_project_evaluator rules on your package using the test `dbt_project_evaluator.is_empty`,
      the test name should start with the same name as the default.
    -#}
    {% set test_name_prefix_of_custom_rules = var(
      "test_name_prefix_of_custom_rules",
      default="dbt_project_evaluator_is_empty_",
    ) %}

    {% for result in results | selectattr('failures') | selectattr('failures', '>', 0) %}
      
      {% set is_test = result.node.config.materialized == "test" %}
      {% set package_name = result.node.package_name %}
      {% set resource_name = result.node.name %}
      {% if is_test and (
        package_name == "dbt_project_evaluator"
        or resource_name.startswith(test_name_prefix_of_custom_rules)
      ) %}
        
        {{ print("\n-- " ~ result.node.fqn | join(".") ~ " --") }}

        {% set unique_id_model_checked = result.node.depends_on.nodes[0] %}
        {% set model_details = graph["nodes"][unique_id_model_checked] %}

        {% set sql_statement %}
        select * from {{ model_details.relation_name }}
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
