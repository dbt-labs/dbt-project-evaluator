{% macro find_all_hard_coded_references(node) %}
    {{ return(adapter.dispatch('find_all_hard_coded_references', 'dbt_project_evaluator')(node)) }}
{% endmacro %}

{% macro default__find_all_hard_coded_references(node) %}

    {%- set all_hard_coded_references_list = [] -%}

    {% if node.resource_type == 'model' and node.language == "sql" %}

        {% if execute %}
        {%- set model_raw_sql = node.raw_sql or node.raw_code -%}
        {%- else -%}
        {%- set model_raw_sql = '' -%}
        {%- endif -%}

        {# we remove the comments that start with -- , or other characters configured #}
        {%- set re = modules.re -%}
        {%- set comment_chars_match = "(" ~ var('comment_chars') | join("|") ~ ").*" -%}
        {%- set model_raw_sql_no_comments = re.sub(comment_chars_match, '', model_raw_sql) -%}

        {#-
            REGEX Explanations
            
            # from_var_1
            - matches (from or join) followed by some spaces and then {{var(<something>)}}
            
            # from_var_2
            - matches (from or join) followed by some spaces and then {{var(<something>,<something_else>)}}
            
            # from_table_1
            - matches (from or join) followed by some spaces and then <something>.<something_else>
              where each <something> is enclosed by (` or [ or " or ' or nothing)
            
            # from_table_2
            - matches (from or join) followed by some spaces and then <something>.<something_else>.<something_different>
              where each <something> is enclosed by (` or [ or " or ' or nothing)
            
            # from_table_3
            - matches (from or join) followed by some spaces and then <something>
              where <something> is enclosed by (` or [ or " or ')

            # notes
            - all regex matches exclude text that immediately follows "distinct "

        -#}

        {%- set re = modules.re -%}

        {%- set from_hard_coded_references = {
            'from_var_1':
                '(?ix)

                # NOT following "distinct "
                (?<!distinct\s)

                # first matching group
                # from or join followed by at least 1 whitespace character
                (from|join)\s+

                # second matching group
                # opening {{, 0 or more whitespace character(s), var, 0 or more whitespace character(s), an opening parenthesis, 0 or more whitespace character(s), 1 or 0 quotation mark
                ({{\s*var\s*\(\s*[\'\"]?)

                # third matching group
                # at least 1 of anything except a parenthesis or quotation mark
                ([^)\'\"]+)

                # fourth matching group
                # 1 or 0 quotation mark, 0 or more whitespace character(s)
                ([\'\"]?\s*)

                # fifth matching group
                # a closing parenthesis, 0 or more whitespace character(s), closing }}
                (\)\s*}})

                ',
            'from_var_2':
                '(?ix)

                # NOT following "distinct "
                (?<!distinct\s)

                # first matching group
                # from or join followed by at least 1 whitespace character
                (from|join)\s+

                # second matching group
                # opening {{, 0 or more whitespace character(s), var, 0 or more whitespace character(s), an opening parenthesis, 0 or more whitespace character(s), 1 or 0 quotation mark
                ({{\s*var\s*\(\s*[\'\"]?)

                # third matching group
                # at least 1 of anything except a parenthesis or quotation mark            
                ([^)\'\"]+)

                # fourth matching group
                # 1 or 0 quotation mark, 0 or more whitespace character(s)
                ([\'\"]?\s*)

                # fifth matching group
                # a comma
                (,)

                # sixth matching group
                # 0 or more whitespace character(s), 1 or 0 quotation mark            
                (\s*[\'\"]?)

                # seventh matching group
                # at least 1 of anything except a parenthesis or quotation mark            
                ([^)\'\"]+)

                # eighth matching group
                # 1 or 0 quotation mark, 0 or more whitespace character(s)            
                ([\'\"]?\s*)

                # ninth matching group
                # a closing parenthesis, 0 or more whitespace character(s), closing }}            
                (\)\s*}})

                ',
            'from_table_1':
                '(?ix)

                # NOT following "distinct "
                (?<!distinct\s)

                # first matching group
                # from or join followed by at least 1 whitespace character            
                (from|join)\s+

                # second matching group
                # 1 or 0 of (opening bracket, backtick, or quotation mark)
                ([\[`\"\']?)

                # third matching group
                # at least 1 word character
                (\w+-?\w*)

                # fouth matching group
                # 1 or 0 of (closing bracket, backtick, or quotation mark)
                ([\]`\"\']?)

                # fifth matching group
                # a period
                (\.)

                # sixth matching group
                # 1 or 0 of (opening bracket, backtick, or quotation mark)
                ([\[`\"\']?)

                # seventh matching group
                # at least 1 word character
                (\w+-?\w*)

                # eighth matching group
                # 1 or 0 of (closing bracket, backtick, or quotation mark) folowed by a whitespace character or end of string
                ([\]`\"\']?)(?=\s|$)

                ',
            'from_table_2':
                '(?ix)

                # NOT following "distinct "
                (?<!distinct\s)

                # first matching group
                # from or join followed by at least 1 whitespace character
                (from|join)\s+

                # second matching group
                # 1 or 0 of (opening bracket, backtick, or quotation mark)
                ([\[`\"\']?)

                # third matching group
                # at least 1 word character
                (\w+-?\w*)

                # fouth matching group
                # 1 or 0 of (closing bracket, backtick, or quotation mark)
                ([\]`\"\']?)

                # fifth matching group
                # a period
                (\.)

                # sixth matching group
                # 1 or 0 of (opening bracket, backtick, or quotation mark)
                ([\[`\"\']?)

                # seventh matching group
                # at least 1 word character
                (\w+-?\w*)

                # eighth matching group
                # 1 or 0 of (closing bracket, backtick, or quotation mark)
                ([\]`\"\']?)

                # ninth matching group
                # a period
                (\.)

                # tenth matching group
                # 1 or 0 of (closing bracket, backtick, or quotation mark)
                ([\[`\"\']?)

                # eleventh matching group
                # at least 1 word character
                (\w+-?\w*)

                # twelfth matching group
                # 1 or 0 of (closing bracket, backtick, or quotation mark) followed by a whitespace character or end of string
                ([\]`\"\']?)(?=\s|$)

                ',
            'from_table_3':
                '(?ix)

                # NOT following "distinct "
                (?<!distinct\s)

                # first matching group
                # from or join followed by at least 1 whitespace character
                (from|join)\s+

                # second matching group
                # 1 of (opening bracket, backtick, or quotation mark)
                ([\[`\"\'])

                # third matching group
                # at least 1 word character
                (\w+-?\w+)
                
                # fourth matching group
                # 1 of (closing bracket, backtick, or quotation mark) folowed by a whitespace character or end of string
                ([\]`\"\'])(?=\s|$)

                '
        } -%}

        {%- for regex_name, regex_pattern in from_hard_coded_references.items() -%}

            {%- set all_regex_matches = re.findall(regex_pattern, model_raw_sql_no_comments) -%}
                
                {%- for match in all_regex_matches -%}

                    {%- set raw_reference = match[1:]|join()|trim -%}

                    {%- do all_hard_coded_references_list.append(raw_reference) -%}

                {%- endfor -%}
        
        {%- endfor -%}

    {% endif %}
    
    {% set all_hard_coded_references = set(all_hard_coded_references_list)|sort|join(', ')|trim %}

    {{ return(all_hard_coded_references) }}

{% endmacro %}
