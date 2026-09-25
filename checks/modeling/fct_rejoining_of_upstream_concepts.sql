-- A -> B -> C where C also selects from A directly and B is only used by C.
-- unique_id is B, which can usually be folded into C as a CTE.
with edges as (
    select * from {{ evaluator_edges() }}
    where parent_resource_type not in ('exposure', 'metric')
      and child_resource_type not in ('exposure', 'metric')
)

select b.parent_unique_id as unique_id,
       a_b.parent_name as parent,
       b.parent_name as parent_and_child,
       b.child_name as child
from edges a_b
join edges b on b.parent_unique_id = a_b.child_unique_id
join edges a_c on a_c.parent_unique_id = a_b.parent_unique_id and a_c.child_unique_id = b.child_unique_id
where b.parent_unique_id in (select parent_unique_id from edges group by all having count(*) = 1)
