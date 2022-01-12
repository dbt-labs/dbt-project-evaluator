{{ audit_helper.compare_relations(
    a_relation=ref('stg_dag_relationships'),
    b_relation=ref('stg_dag_relationships_2'),
    primary_key="unique_id"
) }}