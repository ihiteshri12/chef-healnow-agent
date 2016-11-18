#
# Cookbook Name:: healnow-agent
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'cloudcli'

apt_package 'build-essential'
apt_package 'libaio1'

cloudcli_aws_s3_file "/tmp/#{node['healnow-agent']['deb']}" do
  bucket "#{node['healnow-agent']['deb_s3_bucket']}"
  key "#{node['healnow-agent']['deb_s3_key']}/#{node['healnow-agent']['deb']}"
end

dpkg_package 'healnow-agent' do
  source "/tmp/#{node['healnow-agent']['deb']}"
  action :install
end

ruby_block "get_hostname" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
        command = 'curl -s http://169.254.169.254/latest/meta-data/instance-id'
        command_out = shell_out(command)
        node.set['host_name'] = command_out.stdout
    end
    action :create
end

ruby_block "get_host_ip" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
        command = 'curl -s http://169.254.169.254/latest/meta-data/local-ipv4'
        command_out = shell_out(command)
        node.set['host_ip'] = command_out.stdout
    end
    action :create
end

template '/opt/shs-client/conf/serf_config.json' do
  source 'serf_config.json.erb'
  owner 'root'
  group 'root'
  mode '0666'
end

ruby_block "modify_ssh_handler_file" do
  block do
    fe = Chef::Util::FileEdit.new("/opt/shs-client/bin/shs_handler.sh")
    fe.search_file_replace(/\$1/,"#{node['healnow-agent']['healnow_server_ip']}")
    fe.write_file
  end
end

service 'start healnow agent' do
  service_name 'shs-client'
  action :start
end
