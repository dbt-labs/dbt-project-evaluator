{% materialization insert_graph_values, adapter = 'databricks' %}

  {%- set identifier = model['alias'] -%}
  {%- set grant_config = config.get('grants') -%}

  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier,
                                                schema=schema,
                                                database=database,
                                                type='table') -%}
  -- get the list of values to insert
  {% set resource = config.get('resource') %}
  {% set relationships = config.get('relationships') %}
  {% set values = get_resource_values(resource, relationships) %}
  {% set insert_statements = generate_insert_statements(target_relation, values) %}

  {{ run_hooks(pre_hooks) }}

  -- setup: if the target relation already exists, drop it
  -- in case if the existing and future table is delta, we want to do a
  -- create or replace table instead of dropping, so we don't have the table unavailable
  {% if old_relation and not (old_relation.is_delta and config.get('file_format', default='delta') == 'delta') -%}
    {{ adapter.drop_relation(old_relation) }}
  {%- endif %}

  -- build model
  {% call statement('create_table') -%}
    create or replace table {{ target_relation }} (
        {{ sql }}
    );
  {%- endcall %}
  {% for insert_statement in insert_statements %}
    {% call statement('main') -%}
        {{ insert_statement }}
    {%- endcall %}
  {% endfor %}

  {% set should_revoke = should_revoke(old_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  {% do persist_constraints(target_relation, model) %}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]})}}

{% endmaterialization %}