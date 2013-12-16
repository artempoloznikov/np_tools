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

# Update /etc/resolv.conf
log "  Configure /etc/resolv.conf"
nameserver=`cat /etc/resolv.conf  | grep -v '^#' | grep nameserver | awk '{print $2}'`
if nameserver != ""
  nameserver="nameserver #{nameserver}"
end

if "#{node.np_tools.domain_name}" != ""
  domain = "domain #{node.np_tools.domain_name}"
end

if "#{node.np_tools.search_suffix}" != ""
  search = "search #{node.np_tools.search_suffix}"
end

template "/etc/resolv.conf" do
  source "resolv.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :nameserver => nameserver,
    :domain => domain,
    :search => search
  )
end

# Call hostname command.
log "  Setting hostname."
if platform?('centos', 'redhat')
  bash "set_hostname" do
    flags "-ex"
    code <<-EOH
      sed -i "s/HOSTNAME=.*/HOSTNAME=#{hostname}/" /etc/sysconfig/network
      hostname #{hostname}
    EOH
  end
else
  bash "set_hostname" do
    flags "-ex"
    code <<-EOH
      hostname #{hostname}
    EOH
  end
end

# Call domainname command.
if "#{node.np_tools.domain_name}" != ""
  log "  Running domainname"
  bash "set_domainname" do
    flags "-ex"
    code <<-EOH
      domainname #{node.np_tools.domain_name}
    EOH
  end
end

# Restart hostname services on appropriate platforms.
if platform?('ubuntu')
  log "  Starting hostname service."
  service "hostname" do
    service_name "hostname"
    supports :restart => true, :status => true, :reload => true
    action :restart
  end
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

# get tags 
# If mongodb already installed, exit
#r = rightscale_server_collection :my_tags do
#  tags "server:private_ip_0=#{node[:cloud][:private_ips][0]}"
#  action :nothing
#end

#r.run_action(:load)
#node[:server_collection][:my_tags].each do |id, tags|
#  tags.each do |t|
#  if t == "loadbalancer:default=lb"
#    Chef::Log.info "TEST --- TEST --- TEST ======= #{t}, #{id}, #{tags}"
#       return
#    end
#  end
#end

static_hosts = []
node[:server_collection][:config_servers].each do |id, tags|
  private_ip_0 = tags.detect{ |t| t =~ /server:private_ip_0/ }.split("=")[1]
  public_ip_0 = tags.detect{ |t| t =~ /server:public_ip_0/ }.split("=")[1]
  node_hostname = tags.detect{ |t| t =~ /node:hostname/ }.split("=")[1]
  static_hosts << "#{private_ip_0} #{node_hostname}"
end

