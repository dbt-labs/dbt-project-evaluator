{#
    Formatting helper macros for converting agate table data to various output formats.
    These are used by print_dbt_project_evaluator_issues when native agate printing is disabled
    (e.g., in dbt Cloud CLI, dbt Cloud IDE, or Fusion with CSV format).
#}


{# -------- TABLE FORMAT -------- #}

{% macro table_to_string(data, max_rows=20, max_columns=6, max_column_width=20, ellipsis="…", truncation="…", h_line="-", v_line="|") %}
{#
    Print a text-based view of the data in a table.

    The output of this macro is GitHub Flavored Markdown (GFM) compatible.

    Parameters:
        data: The table data object with rows, columns and column_names properties
        max_rows: The maximum number of rows to display before truncating the data.
                 Defaults to 20 to prevent accidental printing of the entire table.
                 Pass None to disable the limit.
        max_columns: The maximum number of columns to display before truncating the data.
                    Defaults to 6 to prevent wrapping in most cases.
                    Pass None to disable the limit.
        max_column_width: Truncate all columns to at most this width. The remainder will be
                         replaced with ellipsis.
        ellipsis: Characters to use for indicating truncated columns
        truncation: Characters to use for indicating truncated text
        h_line: Character to use for horizontal lines
        v_line: Character to use for vertical lines
#}

{% set ns = namespace() %}

{%- set rows = data.rows -%}
{%- set columns = data.columns -%}
{%- set column_names = data.column_names -%}

{%- set output = "" -%}

{%- if max_rows is none -%}
    {%- set max_rows = rows|length -%}
{%- endif -%}

{%- if max_columns is none -%}
    {%- set max_columns = columns|length -%}
{%- endif -%}

{%- set rows_truncated = max_rows < rows|length -%}
{%- set columns_truncated = max_columns < column_names|length -%}

{%- set display_column_names = [] -%}
{%- for name in column_names[:max_columns] -%}
    {%- if max_column_width is not none and name|length > max_column_width -%}
        {%- set _ = display_column_names.append(name[:max_column_width - truncation|length] + truncation) -%}
    {%- else -%}
        {%- set _ = display_column_names.append(name) -%}
    {%- endif -%}
{%- endfor -%}

{%- if columns_truncated -%}
    {%- set _ = display_column_names.append(ellipsis) -%}
{%- endif -%}

{%- set ns.widths = [] -%}
{%- for name in display_column_names -%}
    {%- set _ = ns.widths.append(name|length) -%}
{%- endfor -%}

{%- set formatted_data = [] -%}

{# Format data and calculate column widths #}
{%- for i in range(rows|length) if i < max_rows -%}
    {%- set row = rows[i] -%}
    {%- set formatted_row = [] -%}

    {%- for j in range(row|length) -%}
        {%- if j >= max_columns -%}
            {%- set v = ellipsis -%}
        {%- else -%}
            {%- set v = row[j] -%}
            {%- if v is none -%}
                {%- set v = '' -%}
            {%- else -%}
                {%- set v = v|string -%}
            {%- endif -%}

            {%- if max_column_width is not none and v|length > max_column_width -%}
                {%- set v = v[:max_column_width - truncation|length] + truncation -%}
            {%- endif -%}

            {%- if v|length > ns.widths[j] -%}
                {%- set ns.widths = ns.widths[:j] + [v|length] + ns.widths[j+1:] -%}
            {%- endif -%}
        {%- endif -%}

        {%- set _ = formatted_row.append(v) -%}

        {%- if j >= max_columns -%}
            {%- break -%}
        {%- endif -%}
    {%- endfor -%}

    {%- set _ = formatted_data.append(formatted_row) -%}
{%- endfor -%}

{# Print the table header #}
{% set ns.first_line = "" %}
{% for name in display_column_names %}
    {% set ns.first_line = ns.first_line ~ v_line ~ " " ~ "{:{width}}".format(name, width=ns.widths[loop.index0]) ~ " " %}
{% endfor %}
{% set ns.first_line = ns.first_line ~ v_line %}

{% set ns.second_line = "" %}
{% for  width in ns.widths %}
    {% set ns.second_line = ns.second_line ~ v_line ~ " " ~ h_line * width ~ " " %}
{% endfor %}
{% set ns.second_line = ns.second_line ~ v_line %}

{# Print the table data #}
{% set ns.data_lines = [] %}
{%- for row in formatted_data -%}
    {%- set ns.row_output = v_line -%}
    {%- for cell in row -%}
        {%- set ns.row_output = ns.row_output ~ " " ~ "{:{width}}".format(cell, width=ns.widths[loop.index0]) ~ " " ~ v_line -%}
    {%- endfor -%}
    {%- set _ = ns.data_lines.append(ns.row_output) -%}
{%- endfor -%}

{%- set ns.last_line = "" -%}
{%- if rows_truncated -%}
    {%- set ns.last_line = v_line -%}
    {%- for width in ns.widths -%}
        {%- set ns.last_line = ns.last_line ~ " " ~ "{:^{width}}".format(ellipsis, width=width) ~ " " ~ v_line -%}
    {%- endfor -%}
{%- endif -%}

{{ return(([""] + [ns.first_line] + [ns.second_line] + ns.data_lines + [ns.last_line]) | join ("\n")) }}
{% endmacro %}


{% macro print_table_jinja(data, max_rows=20, max_columns=6, max_column_width=20, ellipsis="…", truncation="…", h_line="-", v_line="|") %}
    {{ print(dbt_project_evaluator.table_to_string(data, max_rows, max_columns, max_column_width, ellipsis, truncation, h_line, v_line)) }}
{% endmacro %}


{# -------- CSV FORMAT -------- #}

{% macro csv_escape_field(value) %}
{#
    Escape a field value for CSV output following RFC 4180.

    Rules:
    - Fields containing commas, double quotes, or newlines must be enclosed in double quotes
    - Double quotes within a field must be escaped by doubling them (" -> "")
#}
    {%- set v = value if value is not none else '' -%}
    {%- set v = v | string -%}

    {#- Check if the field needs quoting -#}
    {%- set needs_quoting = (',' in v) or ('"' in v) or ('\n' in v) or ('\r' in v) -%}

    {%- if needs_quoting -%}
        {#- Escape double quotes by doubling them -#}
        {%- set v = v | replace('"', '""') -%}
        {{- return('"' ~ v ~ '"') -}}
    {%- else -%}
        {{- return(v) -}}
    {%- endif -%}
{% endmacro %}


{% macro table_to_csv(data) %}
{#
    Convert table data to CSV format following RFC 4180.

    Parameters:
        data: The table data object with rows, columns and column_names properties

    Returns:
        A string containing the CSV representation of the data
#}
    {%- set ns = namespace() -%}
    {%- set ns.lines = [] -%}

    {%- set rows = data.rows -%}
    {%- set column_names = data.column_names -%}

    {#- Build header row -#}
    {%- set header_fields = [] -%}
    {%- for name in column_names -%}
        {%- set _ = header_fields.append(dbt_project_evaluator.csv_escape_field(name)) -%}
    {%- endfor -%}
    {%- set _ = ns.lines.append(header_fields | join(',')) -%}

    {#- Build data rows -#}
    {%- for row in rows -%}
        {%- set row_fields = [] -%}
        {%- for value in row -%}
            {%- set _ = row_fields.append(dbt_project_evaluator.csv_escape_field(value)) -%}
        {%- endfor -%}
        {%- set _ = ns.lines.append(row_fields | join(',')) -%}
    {%- endfor -%}

    {{- return(ns.lines | join('\n')) -}}
{% endmacro %}


{% macro print_csv_jinja(data) %}
    {{ print(dbt_project_evaluator.table_to_csv(data)) }}
{% endmacro %}


{# -------- JSON FORMAT -------- #}

{% macro json_serialize_value(value) %}
{#
    Convert a value to a JSON-serializable type.
    Handles datetime, Decimal, and other non-serializable types.
#}
    {%- if value is none -%}
        {{- return(none) -}}
    {%- elif value is boolean -%}
        {{- return(value) -}}
    {%- elif value is integer -%}
        {{- return(value) -}}
    {%- elif value is float -%}
        {{- return(value) -}}
    {%- elif value is string -%}
        {{- return(value) -}}
    {%- elif value is iterable and value is not string -%}
        {{- return(value | list) -}}
    {%- else -%}
        {#- For Decimal, datetime, and other non-serializable types, convert to string -#}
        {{- return(value | string) -}}
    {%- endif -%}
{% endmacro %}


{% macro agate_to_list(data) %}
{#
    Convert agate table data to a list of dictionaries.

    Parameters:
        data: The agate table data object with rows and column_names properties

    Returns:
        A list of dictionaries, where each dictionary represents a row
        with column names as keys. All values are JSON-serializable.
#}
    {%- set ns = namespace() -%}
    {%- set ns.rows_list = [] -%}

    {%- set rows = data.rows -%}
    {%- set column_names = data.column_names -%}

    {%- for row in rows -%}
        {%- set row_dict = {} -%}
        {%- for i in range(column_names | length) -%}
            {%- set serialized_value = dbt_project_evaluator.json_serialize_value(row[i]) -%}
            {%- set _ = row_dict.update({column_names[i]: serialized_value}) -%}
        {%- endfor -%}
        {%- set _ = ns.rows_list.append(row_dict) -%}
    {%- endfor -%}

    {{- return(ns.rows_list) -}}
{% endmacro %}
