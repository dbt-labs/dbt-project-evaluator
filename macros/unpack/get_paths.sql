{%- macro get_paths(path_pattern) -%}
  {% if execute %} 
  {# Get all paths for nodes that match a regex pattern #}
    {% set paths = [] -%}
    {# Is just the nodes & sources graph enough? #}
    {% for path in graph.nodes.values() -%}
      {%- if modules.re.match(path_pattern, path.original_file_path) is not none -%} {%-do paths.append(path.original_file_path) -%} {% endif %}
    {%- endfor %}
    {% for path in graph.sources.values() -%}
      {%- if modules.re.match(path_pattern, path.path) is not none -%} {%-do paths.append(path.path) -%} {% endif %}
    {%- endfor %}
  {% endif %}
  {{ return(paths) }}
{%- endmacro -%}
