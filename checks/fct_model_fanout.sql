with leaf_models as (
    select m.unique_id
    from {{ info_schema('models') }} m
    left join {{ info_schema('edges') }} outgoing on outgoing.parent_unique_id = m.unique_id
    where {{ evaluator_check_in_scope('m') }}
    group by m.unique_id
    having count(outgoing.child_unique_id) = 0
),
fanout as (
    select e.parent_unique_id as unique_id,
           count(distinct e.child_unique_id) as leaf_children
    from {{ info_schema('edges') }} e
    join leaf_models leaf on leaf.unique_id = e.child_unique_id
    group by e.parent_unique_id
)
select * from fanout
where leaf_children >= {{ var('models_fanout_threshold', 3) }}
