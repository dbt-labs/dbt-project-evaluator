{% set violations %}
-- resources (of `enforced_primary_key_node_types`) where no column (or, for model-level tests,
-- the resource itself) carries every test of one of the `primary_key_test_macros` sets
with resources as (
    {%- for view in ['models', 'seeds', 'snapshots', 'sources'] %}
    select unique_id, name, resource_type, package_name, original_file_path from {{ info_schema(view) }} where enabled
    {%- if not loop.last %} union all{% endif %}
    {%- endfor %}
),

tests as (
    select coalesce(test.node_unique_id, edge.parent_unique_id) as node_unique_id, test.column_name,
           coalesce(nullif(test.test_definition_package, ''), 'dbt') || '.test_' || test.test_name as full_test_name
    from {{ evaluator_data_tests() }} test
    -- the tests of a source table have no node_unique_id: their edge in the DAG points at the source.
    -- Workaround for dbt-labs/dbt#16794: remove this join once data_tests.node_unique_id is set for source tests.
    -- A test with several source parents (e.g. `relationships` between two sources) counts for each of them;
    -- this makes no difference for single-parent tests such as `unique` and `not_null`.
    left join {{ info_schema('edges') }} edge
        on test.node_unique_id is null
       and edge.child_unique_id = test.unique_id
       and edge.parent_unique_id like 'source.%'
    -- singular tests have no node_unique_id, which would make the `not in` below match nothing
    where test.test_name is not null and coalesce(test.node_unique_id, edge.parent_unique_id) is not null
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
{% endset %}

{{ evaluator_exceptions('fct_missing_primary_key_tests', violations) }}
