{%- macro calculate_rfm_score(column_name, thresholds, score_name) -%}
    CASE
        {%- for threshold in thresholds %}
        WHEN {{ column_name }} <= {{ threshold[0] }} THEN {{ threshold[1] }}
        {%- endfor %}
        ELSE 1
    END as {{ score_name }}
{%- endmacro -%}