{% macro print_dbt_project_evaluator_issues(format='table', quote="") %}

  {%- if flags.WHICH in ["build","test"] -%}

    {#- Skip header for JSON format to allow piping to jq -#}
    {% if format != 'json' %}
      {{ print("\n### List of issues raised by dbt_project_evaluator ###") }}
    {% endif %}

    {#-
      if you create custom dbt_project_evaluator rules on your package using the test `dbt_project_evaluator.is_empty`,
      the test name should start with the same name as the default.
    -#}
    {% set test_name_prefix_of_custom_rules = var(
      "test_name_prefix_of_custom_rules",
      default="dbt_project_evaluator_is_empty_",
    ) %}

    {#-
      use_native_agate_printing: set to false for dbt Cloud CLI/IDE,
      or for Fusion when using format='csv'
    -#}
    {% set use_native_agate = var("use_native_agate_printing", default=true) %}

    {#- For JSON format, collect all results first then print as single array -#}
    {% set ns = namespace(json_results=[]) %}

    {% for result in results | selectattr('failures') | selectattr('failures', '>', 0) %}

      {% set is_test = result.node.config.materialized == "test" %}
      {% set package_name = result.node.package_name %}
      {% set resource_name = result.node.name %}
      {% if is_test and (
        package_name == "dbt_project_evaluator"
        or resource_name.startswith(test_name_prefix_of_custom_rules)
      ) %}

        {% set test_name = result.node.fqn | join(".") %}
        {% set unique_id_model_checked = result.node.depends_on.nodes[0] %}
        {% set model_details = graph["nodes"][unique_id_model_checked] %}

        {% set sql_statement %}
        select * from {{ model_details.relation_name }}
        {% endset %}

        {% set query_results = run_query(sql_statement) %}

        {% if format == 'json' %}
          {#- Collect results for JSON, will print at the end -#}
          {% set rows_as_dicts = dbt_project_evaluator.agate_to_list(query_results) %}
          {% do ns.json_results.append({"test_name": test_name, "results": rows_as_dicts}) %}
        {% elif format == 'table' %}
          {{ print("\n-- " ~ test_name ~ " --") }}
          {% if use_native_agate %}
            {{ print(query_results.print_table(max_column_width=80, max_rows=1000) or "") }}
          {% else %}
            {{ dbt_project_evaluator.print_table_jinja(query_results, max_column_width=80, max_rows=1000) }}
          {% endif %}
        {% elif format == 'csv' %}
          {{ print("\n-- " ~ test_name ~ " --") }}
          {% if use_native_agate %}
            {{ print(query_results.print_csv() or "") }}
          {% else %}
            {{ dbt_project_evaluator.print_csv_jinja(query_results) }}
          {% endif %}
        {% else %}
            {%- do exceptions.raise_compiler_error("format can only be 'table', 'csv', or 'json'") -%}
        {% endif %}


      {% endif %}

    {% endfor %}

    {% if format == 'json' %}
      {{ print(tojson(ns.json_results)) }}
    {% else %}
      {{ print("\n") }}
    {% endif %}
  {%- endif %}

{% endmacro %}
