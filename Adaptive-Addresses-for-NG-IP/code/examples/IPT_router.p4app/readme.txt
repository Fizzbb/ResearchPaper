#h1 is level network host, h2 is normal IPv6

# use the following the start runtime CLI
>docker exec -t -i $docker_id simple_switch_CLI

# check/list entries in a table
> table_dump switch_config_params

# clear all the entry in a table
>table_clear switch_config_params

# add again/modify values
>table_add switch_config_params set_params  => 4 0 0 3

# if use mininet target, the log location is not under /tmp, it is under /var/log
>runn h1 cat /var/log/vla_router.p4.log
