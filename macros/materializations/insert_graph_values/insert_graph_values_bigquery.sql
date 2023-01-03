{% materialization insert_graph_values, adapter='bigquery' -%}

  {%- set identifier = model['alias'] -%}
  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set exists_not_as_table = (old_relation is not none and not old_relation.is_table) -%}
  {%- set target_relation = api.Relation.create(database=database, schema=schema, identifier=identifier, type='table') -%}

  -- get the list of values to insert
  {% set resource = config.get('resource') %}
  {% set relationships = config.get('relationships') %}
  {% set values = get_resource_values(resource, relationships) %}
  {% set insert_statements = generate_insert_statements(target_relation, values) %}

  -- grab current tables grants config for comparision later on
  {%- set grant_config = config.get('grants') -%}

  {{ run_hooks(pre_hooks) }}

  {#
      We only need to drop this thing if it is not a table.
      If it _is_ already a table, then we can overwrite it without downtime
      Unlike table -> view, no need for `--full-refresh`: dropping a view is no big deal
  #}
  {%- if exists_not_as_table -%}
      {{ adapter.drop_relation(old_relation) }}
  {%- endif -%}

  -- build model
  {%- set raw_partition_by = config.get('partition_by', none) -%}
  {%- set partition_by = adapter.parse_partition_by(raw_partition_by) -%}
  {%- set cluster_by = config.get('cluster_by', none) -%}
  {% if not adapter.is_replaceable(old_relation, partition_by, cluster_by) %}
    {% do log("Hard refreshing " ~ old_relation ~ " because it is not replaceable") %}
    {% do adapter.drop_relation(old_relation) %}
  {% endif %}
  {% call statement('main') -%}
    create or replace table {{ target_relation }} (
        {{ sql }}
    );
    {% for insert_statement in insert_statements %}
        {{ insert_statement }}
    {% endfor %}

  {% endcall -%}

  {{ run_hooks(post_hooks) }}

  {% set should_revoke = should_revoke(old_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}