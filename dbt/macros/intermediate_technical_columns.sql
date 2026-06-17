{#-
    SELF-SERVE TECHNICAL COLUMNS (Data Mesh Principle 3).
    The eight standard technical columns every intermediate model carries. raw_hash (Snowflake
    HASH of business columns) is the change-detection / implicit-versioning signal.

        select ...business columns...,
            {{ intermediate_technical_columns(hash_columns=['entity_code','entity_value']) }}
        from ...
-#}
{% macro intermediate_technical_columns(hash_columns, sync_expression='sync_datetime', source_creation_expr=none, source_update_expr=none) %}
    cast(true as boolean)                                   as is_active,
    {{ sync_expression }}                                   as sync_datetime,
    'sap'                                     as source_system,
    {{ source_creation_expr if source_creation_expr is not none else 'cast(null as timestamp_ntz)' }}
                                                            as source_system_creation_datetime,
    {{ source_update_expr if source_update_expr is not none else sync_expression }}
                                                            as source_system_update_datetime,
    hash({{ hash_columns | join(', ') }})                   as raw_hash,
    current_timestamp()                                     as creation_datetime,  -- preserved across incremental merges via merge_exclude_columns
    current_timestamp()                                     as update_datetime
{% endmacro %}
