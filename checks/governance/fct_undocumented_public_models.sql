-- public models missing a model description, or with any undocumented (or no) columns
with column_coverage as (
    select node_unique_id,
           count(*) as total_defined_columns,
           count(*) filter (where {{ evaluator_is_documented('description') }}) as total_described_columns
    from {{ info_schema('node_columns') }}
    group by node_unique_id
)

select model.unique_id,
       model.name,
       {{ evaluator_is_documented('model.description') }} as is_described_model,
       coalesce(column_coverage.total_defined_columns, 0) as total_defined_columns,
       coalesce(column_coverage.total_described_columns, 0) as total_described_columns
from {{ info_schema('models') }} model
left join column_coverage on column_coverage.node_unique_id = model.unique_id
where {{ evaluator_check_in_scope('model') }}
  and model.access = 'public'
  and (
      not {{ evaluator_is_documented('model.description') }}
      or coalesce(column_coverage.total_defined_columns, 0) = 0
      or column_coverage.total_described_columns < column_coverage.total_defined_columns
  )
