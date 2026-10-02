{# overrides the (empty) default of the package: this project accepts the violations below #}
{% macro default__dbt_project_evaluator_exceptions() %}
{% set exceptions %}
fct_undocumented_models:
  - int_chain_%               # name pattern: int_chain_1 .. int_chain_7
fct_unused_sources:
  - raw_shop.unused_table     # source.table
fct_model_naming_conventions:
  - model.%.orders_summary    # pattern on the whole unique_id
fct_root_models:
  - no_such_model_%           # matches nothing: other violations are untouched
{% endset %}
{{ return(fromyaml(exceptions)) }}
{% endmacro %}
