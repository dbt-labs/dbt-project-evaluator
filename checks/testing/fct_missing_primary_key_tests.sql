-- resources (of `enforced_primary_key_node_types`) where no column (or, for model-level tests,
-- the resource itself) carries every test of one of the `primary_key_test_macros` sets
with resources as (
    {%- for view in ['models', 'seeds', 'snapshots', 'sources'] %}
    select unique_id, name, resource_type, package_name, original_file_path from {{ info_schema(view) }}
    {%- if not loop.last %} union all{% endif %}
    {%- endfor %}
),

tests as (
    select node_unique_id, column_name,
           coalesce(nullif(test_definition_package, ''), 'dbt') || '.test_' || test_name as full_test_name
    from {{ info_schema('data_tests') }}
    where test_name is not null
)

select unique_id, name, resource_type
from resources
where {{ evaluator_check_in_scope('resources') }}
  and resource_type in ('{{ var("enforced_primary_key_node_types") | join("', '") }}')
  and unique_id not in (
      select node_unique_id
      from tests
      group by node_unique_id, column_name
      having
          {%- for test_set in var('primary_key_test_macros') %}
          count(distinct full_test_name) filter (where full_test_name in ('{{ test_set | join("', '") }}')) = {{ test_set | length }}
          {%- if not loop.last %} or{% endif %}
          {%- endfor %}
  )
