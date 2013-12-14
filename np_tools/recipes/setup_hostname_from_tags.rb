#
# Cookbook Name:: np_tools
#

require 'socket'

def local_ip
  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true # Turn off reverse DNS resolution temporarily.
  UDPSocket.open do |s|
    s.connect '64.233.187.99', 1
    s.addr.last
  end
ensure
  Socket.do_not_reverse_lookup = orig
end

def show_host_info
  # Display current hostname values in log.
  log "  Hostname: #{`hostname` == '' ? '<none>' : `hostname`}"
  log "  Network node hostname: #{`uname -n` == '' ? '<none>' : `uname -n`}"
  log "  Alias names of host: #{`hostname -a` == '' ? '<none>' : `hostname -a`}"
  log "  Short host name (cut from first dot of hostname): #{`hostname -s` == '' ? '<none>' : `hostname -s`}"
  log "  Domain of hostname: #{`domainname` == '' ? '<none>' : `domainname`}"
  log "  FQDN of host: #{`hostname -f` == '' ? '<none>' : `hostname -f`}"
end

# Set hostname from short or long (when domain_name set).
if "#{node.np_tools.domain_name}" != ""
  hostname = "#{node.np_tools.short_hostname}.#{node.np_tools.domain_name}"
  hosts_list = "#{node.np_tools.short_hostname}.#{node.np_tools.domain_name} #{node.np_tools.short_hostname}"
else
  hostname = "#{node.np_tools.short_hostname}"
  hosts_list = "#{node.np_tools.short_hostname}"
end

# Show current host info.
log "  Setting hostname for '#{hostname}'."
log "  == Current host/node information =="
show_host_info

# Get node IP.
node_ip = "#{local_ip}"
log "  Node IP: #{node_ip}"

# Update /etc/hosts
log "  Configure /etc/hosts"
template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :node_ip => node_ip,
    :hosts_list => hosts_list
  )
end

# Update /etc/hostname
log "  Configure /etc/hostname"
file "/etc/hostname" do
  owner "root"
  group "root"
  mode "0755"
  content "#{node.np_tools.short_hostname}"
  action :create
end

# rightlink commandline tools set tag with rs_tag
log "  Setting hostname tag."
bash "set_node_hostname_tag" do
  flags "-ex"
  code <<-EOH
    type -P rs_tag &>/dev/null && rs_tag --add "node:hostname=#{hostname}"
  EOH
end

# Show the new host/node information.
ruby_block "show_new_host_info" do
  block do
    # Show new host values from system.
    Chef::Log.info("  == New host/node information ==")
    Chef::Log.info("  Hostname: #{`hostname` == '' ? '<none>' : `hostname`}")
    Chef::Log.info("  Network node hostname: #{`uname -n` == '' ? '<none>' : `uname -n`}")
    Chef::Log.info("  Alias names of host: #{`hostname -a` == '' ? '<none>' : `hostname -a`}")
    Chef::Log.info("  Short host name (cut from first dot of hostname): #{`hostname -s` == '' ? '<none>' : `hostname -s`}")
    Chef::Log.info("  Domain of hostname: #{`domainname` == '' ? '<none>' : `domainname`}")
    Chef::Log.info("  FQDN of host: #{`hostname -f` == '' ? '<none>' : `hostname -f`}")
  end
end
