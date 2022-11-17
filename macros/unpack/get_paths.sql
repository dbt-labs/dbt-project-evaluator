{%- macro get_paths(dbt_project_evaluator_path_pattern) -%}
  {% if execute %} 
  {# Get all paths for nodes that match a regex pattern #}
    {% set paths = [] -%}
    {# Is just the nodes graph enough? #}
    {% for path in graph.nodes.values() -%}
      {%- if modules.re.match(dbt_project_evaluator_path_pattern, path.path) is not none -%} {%-do paths.append(path.path) -%} {% endif %}
    {%- endfor %}
  {% endif %}
{%- endmacro -%}
