-- resources (of the types in `enforced_primary_key_node_types`) without a primary key test:
-- no column (or, for model-level tests, the resource itself) carries every test of one of
-- the `primary_key_test_macros` sets.
with resources as (
    select unique_id, name, resource_type, package_name, original_file_path
    from {{ info_schema('models') }}
    union all
    select unique_id, name, resource_type, package_name, original_file_path
    from {{ info_schema('seeds') }}
    union all
    select unique_id, name, resource_type, package_name, original_file_path
    from {{ info_schema('snapshots') }}
    union all
    select unique_id, source_name || '.' || name, resource_type, package_name, original_file_path
    from {{ info_schema('sources') }}
),

tests as (
    select node_unique_id,
           column_name,
           coalesce(nullif(test_definition_package, ''), 'dbt') || '.test_' || test_name as full_test_name
    from {{ info_schema('data_tests') }}
    where node_unique_id is not null
      and test_name is not null
),

primary_key_columns as (
    select node_unique_id
    from tests
    group by node_unique_id, column_name
    having
        {%- for test_set in var('primary_key_test_macros') %}
        count(distinct case
            when full_test_name in ({% for test_name in test_set %}'{{ test_name }}'{% if not loop.last %}, {% endif %}{% endfor %})
            then full_test_name
        end) >= {{ test_set | length }}
        {%- if not loop.last %} or{% endif %}
        {%- endfor %}
),

test_counts as (
    select node_unique_id, count(*) as number_of_tests
    from tests
    group by node_unique_id
)

select resources.unique_id,
       resources.name,
       resources.resource_type,
       coalesce(test_counts.number_of_tests, 0) as number_of_tests
from resources
left join test_counts on test_counts.node_unique_id = resources.unique_id
where {{ evaluator_check_in_scope('resources') }}
  and resources.resource_type in ({% for resource_type in var('enforced_primary_key_node_types') %}'{{ resource_type }}'{% if not loop.last %}, {% endif %}{% endfor %})
  and resources.unique_id not in (select node_unique_id from primary_key_columns)
