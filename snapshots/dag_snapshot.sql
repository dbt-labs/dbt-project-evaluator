{% snapshot dag_snapshot %}

{{
    config(
      unique_key='path',
      target_schema= var('snapshot_schema'),
      strategy='check',
      check_cols='all',
      invalidate_hard_deletes=True
    )
}}

select * from {{ ref('int_all_dag_relationships') }}

{% endsnapshot %}
