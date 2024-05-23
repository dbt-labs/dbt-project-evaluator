{% macro calculate_sql_complexity(node) %}
    {{ return(adapter.dispatch('calculate_sql_complexity', 'dbt_project_evaluator')(node)) }}
{% endmacro %}

{% macro default__calculate_sql_complexity(node) %}

    {% if node.resource_type == 'model' and node.language == 'sql' %}

        {% if execute %}
        {%- set model_raw_sql = node.raw_sql or node.raw_code -%}
        {%- else -%}
        {%- set model_raw_sql = '' -%}
        {%- endif -%}

        {%- set re = modules.re -%}
        {%- set ns = namespace(complexity = 0) -%}

        {# we remove the comments that start with -- , or other characters configured #}
        {%- set comment_chars_match = "(" ~ var('comment_chars') | join("|") ~ ").*" -%}
        {%- set model_raw_sql_no_comments = re.sub(comment_chars_match, '', model_raw_sql) -%}

        {%- for token, token_cost in var('token_costs').items() -%}

            {# this is not 100% perfect but it checks more or less if the token exists as a word by itself or followed by "("" like for least()/greatest() #}
            {%- set token_with_boundaries = "\\b" ~ token ~ "[\\t\\r\\n (]" -%}
            {%- set all_regex_matches = re.findall(token_with_boundaries, model_raw_sql_no_comments, re.IGNORECASE) -%}
            {%- set ns.complexity = ns.complexity + token_cost * (all_regex_matches | length) -%}

        {%- endfor -%}

        {{ return(ns.complexity) }}

    {% endif %}

    {{ return(0) }}

{% endmacro %}
