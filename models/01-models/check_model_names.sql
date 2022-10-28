{% if execute %}

    {% do log("------------ dbt Learn: Let's see how you did with chapter 1 -----------------", True) %}

    {% set my_nodes = graph.nodes.values() %}

    {% set grade = namespace(score=0) %}

    {% set max_score = 5 %}

    {% set expected_models = ['stg_payments','stg_orders','stg_customers','fct_orders','dim_customers'] %}

    {% do log("📋 Ch1 - Model Naming dbt is checking your model names:", True) %}

    -- Loop through the list to find a match
    {% for model in expected_models %}

        {% set is_match = namespace(found_it=false) %}

        -- Loop through all the models in the graph
        {% for node in my_nodes | selectattr("resource_type", "equalto", "model") %}

            {% if node.name.endswith(model) %}

                {% do log("✅ We found " ~ model, True) %}

                {% set grade.score = grade.score + 1 %}

                {% set is_match.found_it=true %}

            {% endif %}

        {% endfor %}

        {% if not is_match.found_it %}

            {% do log("❌ We did not find " ~ model ~ " | Check to make sure you have this model in your models directory.", True) %}

        {% endif %}

    {% endfor %}

    {% if (grade.score == max_score) %}

        {% do log("💯 Model Naming Score: " ~ grade.score ~ "/" ~ max_score, True) %}

    {% else %}

        {% do log("🚧 Model Naming Score: " ~ grade.score ~ "/" ~ max_score, True) %}

    {% endif %}

    {% do log("------------------------------------------------------------------------------", True) %}

{% endif %}

select 1 as test_column from raw.jaffle_shop.customers