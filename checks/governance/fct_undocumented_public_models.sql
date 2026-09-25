-- public models missing a description, or with undocumented (or no) columns
select model.unique_id,
       model.name,
       model.is_documented as is_described_model,
       count(col.column_name) as total_defined_columns,
       count(col.column_name) filter (where {{ evaluator_is_documented('col.description') }}) as total_described_columns
from {{ evaluator_models() }} model
left join {{ info_schema('node_columns') }} col on col.node_unique_id = model.unique_id
where model.access = 'public'
group by all
having not is_described_model
    or total_defined_columns = 0
    or total_described_columns < total_defined_columns
