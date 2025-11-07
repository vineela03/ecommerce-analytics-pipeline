{% macro generate_timestamp_column() %}
    CURRENT_TIMESTAMP as updated_at
{% endmacro %}