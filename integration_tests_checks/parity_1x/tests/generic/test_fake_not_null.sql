{% test fake_not_null(model, column_name) %}

    select FALSE limit 0

{% endtest %}
