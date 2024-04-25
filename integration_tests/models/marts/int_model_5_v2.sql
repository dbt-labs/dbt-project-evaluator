select 1 as id
-- from {{ ref('int_model_4') }}
-- inner join {{ ref('stg_model_1') }}
-- on int_model_4.join_field = stg_model_1.join_field
-- where int_model_4.id is distinct from stg_model_1.id