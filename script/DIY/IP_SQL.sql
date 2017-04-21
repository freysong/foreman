-----
##IP脚本
-----
-------
alter table hosts add column ip01 varchar(255);
alter table hosts add column ip02 varchar(255);

-------
create table host_ip01 as (SELECT
	a.id as host_id,
    a.`name` as hostname,
    b.`name` as fact_name,
    b.id as fact_name_id,
    c.`value` as fact_value,
    c.id as fact_value_id,
    c.created_at,
    c.updated_at
FROM
	hosts a,
	fact_names b,
	fact_values c
where a.id = c.host_id
and b.id = c.fact_name_id
and (b.`name` LIKE 'ipaddress_eth0%'
or b.`name` LIKE 'ipaddress_bond0%'
or b.`name` LIKE 'ipaddress_em1%'
or b.`name` LIKE 'ipaddress_p1p1%'
or b.`name` LIKE 'ipaddress_virbr0%')
group by host_id
order by host_id
)

-------
create table host_ip02 as (SELECT
	a.id as host_id,
    a.`name` as hostname,
    b.`name` as fact_name,
    b.id as fact_name_id,
    c.`value` as fact_value,
    c.id as fact_value_id,
    c.created_at,
    c.updated_at
FROM
	hosts a,
	fact_names b,
	fact_values c
where a.id = c.host_id
and b.id = c.fact_name_id
and (b.`name` LIKE 'ipaddress_eth1%'
or b.`name` LIKE 'ipaddress_bond1%'
or b.`name` LIKE 'ipaddress_em2%'
or b.`name` LIKE 'ipaddress_p1p2%'
or b.`name` LIKE 'ipaddress_virbr1%')
group by host_id
order by host_id
)
-------
UPDATE
 hosts a,
 host_ip01 b
SET a.ip01 = b.fact_value
WHERE
	a.id = b.host_id

-------
UPDATE
 hosts a,
 host_ip02 b
SET a.ip02 = b.fact_value
WHERE
	a.id = b.host_id
-------

DELIMITER |

DROP TRIGGER IF EXISTS t_afterinsert_on_host_fact ||
CREATE TRIGGER t_afterinsert_on_host_fact
AFTER INSERT ON host_fact
FOR EACH ROW BEGIN

declare c varchar(255);
declare ip1 varchar(255);
declare ip2 varchar(255);

set c = (select fact_value from host_fact where host_id=new.host_id and fact_name = 'serialnumber');
set ip1 = (select fact_value from host_fact where host_id=new.host_id and (fact_name LIKE 'ipaddress_eth0%' or fact_name LIKE 'ipaddress_bond0%' or fact_name LIKE 'ipaddress_em1%' or fact_name LIKE 'ipaddress_p1p1%' or fact_name LIKE 'ipaddress_virbr0%') group by host_id order by host_id);
set ip2 = (select fact_value from host_fact where host_id=new.host_id and (fact_name LIKE 'ipaddress_eth1%' or fact_name LIKE 'ipaddress_bond1%' or fact_name LIKE 'ipaddress_em2%' or fact_name LIKE 'ipaddress_p1p2%' or fact_name LIKE 'ipaddress_virbr1%') group by host_id order by host_id);

update hosts set sn = c where id = new.host_id;
update hosts set ip01 = ip1 where id = new.host_id;
update hosts set ip02 = ip2 where id = new.host_id;
END

|