select 
    * 
from {{ ref('fct_model_9') }}
-- inner join {{ ref('fct_model_6') }}
-- on fct_model_9.join_field = fct_model_6.join_field
-- where fct_model_9.id is distinct from fct_model_6.id