-- resources (of the types in `enforced_primary_key_node_types`) without a primary key test.
-- A column counts as a primary key when it carries every test in one of the
-- `primary_key_test_macros` sets, or a unique test plus a not_null constraint.
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
           coalesce(test_definition_package, 'dbt') || '.test_' || test_name as full_test_name
    from {{ info_schema('data_tests') }}
    where node_unique_id is not null
      and test_name is not null
),

column_constraints as (
    select node_unique_id,
           column_name,
           coalesce(constraints, '') like '%not_null%' as has_not_null_constraint,
           case
               when constraints is null or constraints = '' then 0
               else coalesce(json_array_length(constraints), 0)
           end as constraint_count
    from {{ info_schema('node_columns') }}
),

primary_key_columns as (
    select tests.node_unique_id
    from tests
    left join column_constraints
      on column_constraints.node_unique_id = tests.node_unique_id
     and column_constraints.column_name = tests.column_name
    group by tests.node_unique_id, tests.column_name
    having
        {%- for test_set in var('primary_key_test_macros') %}
        count(distinct case
            when full_test_name in ({% for test_name in test_set %}'{{ test_name }}'{% if not loop.last %}, {% endif %}{% endfor %})
            then full_test_name
        end) >= {{ test_set | length }}
        or
        {%- endfor %}
        (bool_or(full_test_name = 'dbt.test_unique') and bool_or(coalesce(has_not_null_constraint, false)))
),

test_counts as (
    select node_unique_id, count(*) as number_of_tests_on_model
    from tests
    group by node_unique_id
),

constraint_counts as (
    select node_unique_id, sum(constraint_count) as number_of_constraints_on_model
    from column_constraints
    group by node_unique_id
)

select resources.unique_id,
       resources.name,
       resources.resource_type,
       coalesce(test_counts.number_of_tests_on_model, 0) as number_of_tests_on_model,
       coalesce(constraint_counts.number_of_constraints_on_model, 0) as number_of_constraints_on_model
from resources
left join test_counts on test_counts.node_unique_id = resources.unique_id
left join constraint_counts on constraint_counts.node_unique_id = resources.unique_id
where {{ evaluator_check_in_scope('resources') }}
  and resources.resource_type in ({% for resource_type in var('enforced_primary_key_node_types') %}'{{ resource_type }}'{% if not loop.last %}, {% endif %}{% endfor %})
  and resources.unique_id not in (select node_unique_id from primary_key_columns)
