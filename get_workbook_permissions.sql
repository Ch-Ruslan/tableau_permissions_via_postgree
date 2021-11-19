-- select permissions from dba by script

select distinct t.authorizable_type, t.project, t.workbook, t.workbook_id, t.project_id, t.group_name, t.grantee_type,
  t.user_name, t.user_id, t.Permission_type, t.deny, t.allow

from (
with users as (
	SELECT system_users.name as user_name, users.id as user_id,
                    groups.id as group_id, groups.name as group_name 
            FROM    system_users, users, group_users, groups
            WHERE   users.system_user_id = system_users.id
                    and group_users.user_id = users.id
                    and group_users.group_id = groups.id
	 ) 

SELECT distinct 
COALESCE (ngp.authorizable_type,ngp2.authorizable_type) authorizable_type,
pr.name as project, 
w.name as workbook,
w.id as workbook_id,
pr.id as project_id, 
pr.parent_project_id,
case when COALESCE (ngp2.grantee_type,ngp.grantee_type) = 'Group' then u.group_name else null end as group_name,
COALESCE(ngp2.grantee_type,ngp.grantee_type) as grantee_type,	
u.user_name, 
u.user_id,	
c.name as Permission_type, 
CASE WHEN case when pr.controlled_permissions_enabled=true then ngp2.permission else ngp.permission end in (1,3) THEN 1 else 0 end as allow,
CASE WHEN case when pr.controlled_permissions_enabled=true then ngp2.permission else ngp.permission end in (2,4) THEN 1 else 0 end as deny
FROM public.workbooks w 
join public.projects pr ON pr.id=w.project_id
left JOIN public.next_gen_permissions ngp ON ngp.authorizable_id=w.id and ngp.authorizable_type = 'Workbook'	
left join public.next_gen_permissions ngp2 on ngp2.authorizable_id=pr.id and ngp2.authorizable_type = 'Project'	
											 and pr.controlled_permissions_enabled=true 
											 and ngp2.grantee_type in ('User','Group')
join users u  ON (( COALESCE(ngp2.grantee_id,ngp.grantee_id)=u.group_id and COALESCE(ngp2.grantee_type,ngp.grantee_type) = 'Group')
			or (COALESCE(ngp2.grantee_id,ngp.grantee_id)=u.user_id and COALESCE(ngp2.grantee_type,ngp.grantee_type) = 'User')
			  )
JOIN capabilities c ON (COALESCE(ngp2.capability_id,ngp.capability_id) = c.id)	
WHERE u.user_name <> 'guest'
) t 
