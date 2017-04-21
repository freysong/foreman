-----
##SN脚本
-----
-------
alter table hosts add column sn varchar(255);
-------
create table host_fact as (SELECT
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
)
-------
UPDATE
 hosts a,
 host_fact b
SET a.sn = b.fact_value
WHERE
	a.id = b.host_id
	and
	b.`fact_name` = 'serialnumber'
-------
DELIMITER |

DROP TRIGGER IF EXISTS t_afterinsert_on_host_fact ||
CREATE TRIGGER t_afterinsert_on_host_fact
AFTER INSERT ON host_fact
FOR EACH ROW BEGIN
declare c varchar(255);
set c = (select fact_value from host_fact where host_id=new.host_id and fact_name = 'serialnumber');
update hosts set sn = c where id = new.host_id;
END

|
-------
DELIMITER |

DROP TRIGGER IF EXISTS t_afterinsert_on_fact_values ||
CREATE TRIGGER t_afterinsert_on_fact_values
AFTER INSERT ON fact_values
FOR EACH ROW BEGIN

declare hf_hostname varchar(255);
declare hf_fact_name varchar(255);
declare hf_fact_name_id INT;

set hf_hostname = (select hosts.name from hosts where hosts.id = NEW.host_id);
set hf_fact_name = (SELECT fact_names.name FROM fact_names where fact_names.id = NEW.fact_name_id);
set hf_fact_name_id = (SELECT fact_names.id FROM fact_names where fact_names.id = NEW.fact_name_id);


INSERT INTO host_fact(host_id,hostname,fact_name,fact_name_id,fact_value,fact_value_id,created_at,updated_at) values(NEW.host_id,hf_hostname,hf_fact_name,hf_fact_name_id,NEW.value,NEW.id,NEW.created_at,NEW.updated_at);

END

|

-------
DELIMITER |

DROP TRIGGER IF EXISTS t_afterdelete_on_fact_values ||
CREATE TRIGGER t_afterdelete_on_fact_values
AFTER DELETE ON fact_values
FOR EACH ROW BEGIN

DELETE FROM host_fact WHERE host_fact.fact_value_id = OLD.id;

END

|
------