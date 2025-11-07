{% macro generate_audit_columns() %}
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at,
    CURRENT_USER as updated_by
{% endmacro %}