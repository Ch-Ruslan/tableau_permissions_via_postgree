-- View: public.get_workbook_permissions

-- DROP VIEW public.get_workbook_permissions;

CREATE OR REPLACE VIEW public.get_workbook_permissions
 AS
 SELECT DISTINCT t.workbook_id,
    t.project_id,
    t.user_name,
    t.user_id
   FROM ( WITH users AS (
                 SELECT system_users.name AS user_name,
                    users.id AS user_id,
                    groups.id AS group_id,
                    groups.name AS group_name
                   FROM system_users,
                    public.users,
                    group_users,
                    groups
                  WHERE ((users.system_user_id = system_users.id) AND (group_users.user_id = users.id) AND (group_users.group_id = groups.id))
                )
         SELECT DISTINCT COALESCE(ngp.authorizable_type, ngp2.authorizable_type) AS authorizable_type,
            pr.name AS project,
            w.name AS workbook,
            w.id AS workbook_id,
            pr.id AS project_id,
            pr.parent_project_id,
                CASE
                    WHEN ((COALESCE(ngp2.grantee_type, ngp.grantee_type))::text = 'Group'::text) THEN u.group_name
                    ELSE NULL::character varying
                END AS group_name,
            ngp.grantee_type,
            u.user_name,
            u.user_id,
            c.name AS permission_type,
                CASE
                    WHEN (
                    CASE
                        WHEN (pr.controlled_permissions_enabled = true) THEN ngp2.permission
                        ELSE ngp.permission
                    END = ANY (ARRAY[1, 3])) THEN 1
                    ELSE 0
                END AS allow,
                CASE
                    WHEN (
                    CASE
                        WHEN (pr.controlled_permissions_enabled = true) THEN ngp2.permission
                        ELSE ngp.permission
                    END = ANY (ARRAY[2, 4])) THEN 1
                    ELSE 0
                END AS deny
           FROM (((((workbooks w
             JOIN projects pr ON ((pr.id = w.project_id)))
             LEFT JOIN next_gen_permissions ngp ON (((ngp.authorizable_id = w.id) AND ((ngp.authorizable_type)::text = 'Workbook'::text))))
             LEFT JOIN next_gen_permissions ngp2 ON (((ngp2.authorizable_id = pr.id) AND ((ngp2.authorizable_type)::text = 'Project'::text) AND (pr.controlled_permissions_enabled = true) AND ((ngp2.grantee_type)::text = ANY ((ARRAY['User'::character varying, 'Group'::character varying])::text[])))))
             JOIN users u ON ((((COALESCE(ngp2.grantee_id, ngp.grantee_id) = u.group_id) AND ((COALESCE(ngp2.grantee_type, ngp.grantee_type))::text = 'Group'::text)) OR ((COALESCE(ngp2.grantee_id, ngp.grantee_id) = u.user_id) AND ((COALESCE(ngp2.grantee_type, ngp.grantee_type))::text = 'User'::text)))))
             JOIN capabilities c ON ((COALESCE(ngp2.capability_id, ngp.capability_id) = c.id)))
          WHERE ((u.user_name)::text <> 'guest'::text)) t
  WHERE ((t.allow = 1) AND (t.deny = 0) AND (((t.group_name)::text <> 'All Users'::text) OR (t.group_name IS NULL)));

ALTER TABLE public.get_workbook_permissions
    OWNER TO readonly;