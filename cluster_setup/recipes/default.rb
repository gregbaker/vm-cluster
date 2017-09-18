HADOOP_VERSION = '2.8.1'
SPARK_VERSION = '2.2.0'
SPARK_HADOOP_COMPAT = '2.7'

HADOOP_TARFILE = "hadoop-#{HADOOP_VERSION}.tar.gz"
HADOOP_APACHE_PATH = "/hadoop/common/hadoop-#{HADOOP_VERSION}/#{HADOOP_TARFILE}"
HADOOP_INSTALL = "/opt/hadoop-#{HADOOP_VERSION}"

SPARK_TARFILE = "spark-#{SPARK_VERSION}-bin-hadoop#{SPARK_HADOOP_COMPAT}.tgz"
SPARK_APACHE_PATH = "spark/spark-#{SPARK_VERSION}/#{SPARK_TARFILE}"
SPARK_INSTALL = "/opt/spark-#{SPARK_VERSION}-bin-hadoop#{SPARK_HADOOP_COMPAT}"

APACHE_MIRROR = "http://mirror.csclub.uwaterloo.ca/apache/"

num_nodes = node['num_nodes']
username = node['username']
user_home = '/home/' + username


# Hadoop and Spark install files
# TODO: cache these
remote_file "/opt/#{HADOOP_TARFILE}" do
    source APACHE_MIRROR + HADOOP_APACHE_PATH
    mode '0644'
    action :create
    not_if "test -f /opt/#{HADOOP_TARFILE}"
end
remote_file "/opt/#{SPARK_TARFILE}" do
    source APACHE_MIRROR + SPARK_APACHE_PATH
    mode '0644'
    action :create
    not_if "test -f /opt/#{SPARK_TARFILE}"
end


# hadoop user
user 'hadoop' do
    home user_home
    shell '/bin/bash'
    system true
end
group 'supergroup' do
  members ['hadoop', username]
  append true
end


# networking
append_line "/etc/hosts" do
	line "192.168.7.100 master master.local"
end
(1..num_nodes).each do |i|
    append_line "/etc/hosts" do
	    line "192.168.7.#{100+i} hadoop#{i} hadoop#{i}.local"
    end
end


# SSH keys
directory user_home+'/.ssh/' do
    owner username
    mode '0700'
end
cookbook_file user_home+'/.ssh/id_rsa' do
    owner username
    mode '0600'
end
cookbook_file user_home+'/.ssh/id_rsa.pub' do
    owner username
    mode '0600'
end
cookbook_file user_home+'/.ssh/config' do
    source 'ssh-config'
    owner username
    mode '0600'
end
execute 'ssh_authorize' do
    command "echo >> #{user_home}/.ssh/authorized_keys && cat #{user_home}/.ssh/id_rsa.pub >> #{user_home}/.ssh/authorized_keys"
    not_if "grep -q 'cluster user key' #{user_home}/.ssh/authorized_keys"
end


# hadoop data files
directory '/hadoop' do
    owner 'hadoop'
    group 'hadoop'
    mode '0755'
end


# hadoop tools
package 'openjdk-8-jdk'
package 'python3'

execute 'untar hadoop' do
    command "tar zxf /opt/#{HADOOP_TARFILE}"
    cwd "/opt/"
    creates "#{HADOOP_INSTALL}foobar"
end
execute 'untar spark' do
    command "tar zxf /opt/#{SPARK_TARFILE}"
    cwd "/opt/"
    creates "#{SPARK_TARFILE}foobar"
end