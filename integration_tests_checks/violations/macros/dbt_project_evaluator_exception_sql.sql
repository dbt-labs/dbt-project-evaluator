{# accepts the violations of the resources that list the check in their meta:
   meta: {dbt_project_evaluator: {exceptions: [fct_root_models]}} #}
{% macro default__dbt_project_evaluator_exception_sql(check_name) %}
violation.unique_id in (
    {% for relation in ['models', 'sources', 'snapshots'] %}
    select unique_id
    from {{ info_schema(relation) }}
    where list_contains(
        coalesce(from_json(json_extract(meta, '$.dbt_project_evaluator.exceptions'), '["VARCHAR"]'), []),
        '{{ check_name }}'
    )
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)
{% endmacro %}
