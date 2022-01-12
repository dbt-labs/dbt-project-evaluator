{% test is_empty(model) %}

    {{ config (
        severity = 'warn',
        fail_calc = "n_records"
    ) }}

    select count(*) as n_records
    from {{ model }}

{% endtest %}