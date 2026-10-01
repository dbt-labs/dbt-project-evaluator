-- Test for issue #552: Multi-ref Tests Troubles
-- This test verifies that is_primary_relationship is correctly set for column-level relationships tests
-- Expected behavior:
--   - The model being tested (stg_model_1) should have is_primary_relationship = TRUE
--   - The referenced model (stg_model_2) should have is_primary_relationship = FALSE
--
-- Current (buggy) behavior:
--   - The model being tested (stg_model_1) incorrectly has is_primary_relationship = FALSE
--   - The referenced model (stg_model_2) incorrectly has is_primary_relationship = TRUE

with base_node_relationships as (
    select * from {{ ref('base_node_relationships') }}
),

-- Find the relationships test on stg_model_1 that references stg_model_2
test_relationships as (
    select
        resource_id,
        direct_parent_id,
        is_primary_relationship
    from base_node_relationships
    where resource_id like 'test.dbt_project_evaluator_integration_tests.relationships_stg_model_1%'
),

-- The model being tested (stg_model_1) should be primary
incorrect_primary_for_model_being_tested as (
    select *
    from test_relationships
    where direct_parent_id = 'model.dbt_project_evaluator_integration_tests.stg_model_1'
      and is_primary_relationship = FALSE  -- This is the bug!
),

-- The referenced model (stg_model_2) should NOT be primary
incorrect_primary_for_referenced_model as (
    select *
    from test_relationships
    where direct_parent_id = 'model.dbt_project_evaluator_integration_tests.stg_model_2'
      and is_primary_relationship = TRUE  -- This is also the bug!
)

-- Return rows if either condition is incorrect
select
    'stg_model_1 incorrectly marked as non-primary' as error,
    *
from incorrect_primary_for_model_being_tested

union all

select
    'stg_model_2 incorrectly marked as primary' as error,
    *
from incorrect_primary_for_referenced_model
