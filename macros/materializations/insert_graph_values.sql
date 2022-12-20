{% materialization insert_graph_values, default %}

  {%- set existing_relation = load_cached_relation(this) -%}
  {%- set target_relation = this.incorporate(type='table') %}
  {%- set intermediate_relation = make_intermediate_relation(target_relation) -%}
  -- the intermediate_relation should not already exist in the database; get_relation
  -- will return None in that case. Otherwise, we get a relation that we can drop
  -- later, before we try to use this name for the current operation
  {%- set preexisting_intermediate_relation = load_cached_relation(intermediate_relation) -%}
  /*
      See ../view/view.sql for more information about this relation.
  */
  {%- set backup_relation_type = 'table' if existing_relation is none else existing_relation.type -%}
  {%- set backup_relation = make_backup_relation(target_relation, backup_relation_type) -%}
  -- as above, the backup_relation should not already exist
  {%- set preexisting_backup_relation = load_cached_relation(backup_relation) -%}
  -- grab current tables grants config for comparision later on
  {% set grant_config = config.get('grants') %}

  -- get the list of values to insert
  {% set resource = config.get('resource') %}
  {% set relationships = config.get('relationships') %}
  {% set values = get_resource_values(resource, relationships) %}

  -- drop the temp relations if they exist already in the database
  -- also drop the real relation -- this will need to be full-refreshed every time
  {{ drop_relation_if_exists(preexisting_intermediate_relation) }}
  {{ drop_relation_if_exists(preexisting_backup_relation) }}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- build initial model with datatypes
  {% call statement('main') -%}
    create table {{ intermediate_relation }} (
        {{ sql }}
    );

  {%- set values_length = values | length -%}
  {%- set loop_count = (values_length / 100) | round(0, 'ceil') | int -%}
  
  {% set insert_statements = [] -%}
    {%- for loop_number in range(loop_count) -%}
        {%- set lower_bound = loop.index0 * 100 -%}
        {%- set upper_bound = (loop.index * 100) - 1 -%}
        {# TODO handle end of range #}
        {%- set values_subset = values[lower_bound : upper_bound] %}
        {%- set values_list_of_strings = [] -%}
        {%- for indiv_values in values_subset %}
            {%- do values_list_of_strings.append( indiv_values | join(", \n")) -%}
        {%- endfor -%}
        {%- set values_string = '(' ~ values_list_of_strings | join("), \n\n(") ~ ')' %}
        {%- set insert_statement = "insert into " ~ intermediate_relation ~ " values \n" ~  values_string ~ ";"%}
        {%- do insert_statements.append(insert_statement) -%}
    {% endfor %}
    
  {% for insert_statement in insert_statements %}
    {{ insert_statement }}
  {% endfor %}
  
  {%- endcall %}

  -- cleanup
  {% if existing_relation is not none %}
      {{ adapter.rename_relation(existing_relation, backup_relation) }}
  {% endif %}

  {{ adapter.rename_relation(intermediate_relation, target_relation) }}

  {% do create_indexes(target_relation) %}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  -- `COMMIT` happens here
  {{ adapter.commit() }}

  -- finally, drop the existing/backup relation after the commit
  {{ drop_relation_if_exists(backup_relation) }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}