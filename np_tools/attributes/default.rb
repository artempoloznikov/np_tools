#
# Cookbook Name:: np_tools
#

# Optional attributes

# Short hostname
default[:np_tools][:short_hostname] = ""
# Domain name
default[:np_tools][:domain_name] = ""
# Domain search suffix
default[:np_tools][:search_suffix] = ""
# Tag for servers must be included as static records in file /etc/hosts 
default[:np_tools][:static_hosts_tag] = ""
