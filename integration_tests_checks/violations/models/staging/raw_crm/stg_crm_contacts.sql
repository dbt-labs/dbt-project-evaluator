select * from {{ source('raw_crm', 'contacts') }} join {{ source('raw_crm', 'accounts') }} using (id)  -- multiple sources
