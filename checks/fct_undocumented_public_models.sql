with column_coverage as (
    select node_unique_id,
           count(*) as total_defined_columns,
           count(*) filter (
               where nullif(trim(description), '') is not null
           ) as total_described_columns
    from {{ info_schema('node_columns') }}
    group by node_unique_id
)
select m.unique_id, m.name, m.access,
       m.description,
       coalesce(c.total_defined_columns, 0) as total_defined_columns,
       coalesce(c.total_described_columns, 0) as total_described_columns
from {{ info_schema('models') }} m
left join column_coverage c on c.node_unique_id = m.unique_id
where {{ evaluator_check_in_scope('m') }}
  and m.access = 'public'
  and (
      nullif(trim(m.description), '') is null
      or coalesce(c.total_defined_columns, 0) = 0
      or c.total_described_columns < c.total_defined_columns
  )
