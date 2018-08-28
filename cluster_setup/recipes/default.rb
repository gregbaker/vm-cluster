HADOOP_VERSION = '3.1.1'
SPARK_VERSION = '2.3.1'
SPARK_HADOOP_COMPAT = '2.7'

UBUNTU_MIRROR = 'http://mirror.its.sfu.ca/mirror/ubuntu/'
UBUNTU_SECURITY_MIRROR = 'http://mirror.its.sfu.ca/mirror/ubuntu/'
APACHE_MIRROR = "http://mirror.csclub.uwaterloo.ca/apache/"

HADOOP_TARFILE = "hadoop-#{HADOOP_VERSION}.tar.gz"
HADOOP_APACHE_PATH = "hadoop/common/hadoop-#{HADOOP_VERSION}/#{HADOOP_TARFILE}"
HADOOP_INSTALL = "/opt/hadoop-#{HADOOP_VERSION}"

SPARK_TARFILE = "spark-#{SPARK_VERSION}-bin-hadoop#{SPARK_HADOOP_COMPAT}.tgz"
SPARK_APACHE_PATH = "spark/spark-#{SPARK_VERSION}/#{SPARK_TARFILE}"
SPARK_INSTALL = "/opt/spark-#{SPARK_VERSION}-bin-hadoop#{SPARK_HADOOP_COMPAT}"

num_workers = node['num_workers']
cores_per_node = node['cores_per_node']
memory_per_node = node['memory_per_node']
hdfs_replication = num_workers > 3 ? 3 : 2

username = node['username']
user_home = '/home/' + username
ubuntu_release = node['ubuntu_release']

# apt sources
template "/etc/apt/sources.list" do
    mode '0644'
    variables({ubuntu_mirror: UBUNTU_MIRROR, ubuntu_security_mirror: UBUNTU_SECURITY_MIRROR, ubuntu_release: ubuntu_release})
    notifies :run, 'execute[apt-get update]', :immediately
end
execute 'apt-get update' do
    action :nothing
end

# hadoop user
user 'hadoop' do
    home '/home/hadoop'
    shell '/bin/bash'
    system true
end
group 'supergroup' do
  members ['hadoop', username]
  append true
end


# hostnames
delete_lines 'remove local name' do
  path '/etc/hosts'
  pattern /^127\.0\.1\.1.*\.local.*/
end
append_if_no_line "master host" do
    path "/etc/hosts"
    line "192.168.7.100 master master.local"
end
(1..num_workers).each do |i|
    append_if_no_line "hadoop#{i} host" do
        path "/etc/hosts"
        line "192.168.7.#{100+i} hadoop#{i} hadoop#{i}.local"
    end
end


# SSH keys: uses same unsafe key for main user and hadoop
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

directory '/home/hadoop/.ssh/' do
    owner 'hadoop'
    mode '0700'
    recursive true
end
cookbook_file '/home/hadoop/.ssh/id_rsa' do
    owner 'hadoop'
    mode '0600'
end
cookbook_file '/home/hadoop/.ssh/id_rsa.pub' do
    owner 'hadoop'
    mode '0600'
end
cookbook_file '/home/hadoop/.ssh/config' do
    source 'ssh-config'
    owner 'hadoop'
    mode '0600'
end
execute 'ssh_authorize_hadoop' do
    command "echo >> /home/hadoop/.ssh/authorized_keys && cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys"
    not_if "grep -q 'cluster user key' /home/hadoop/.ssh/authorized_keys"
end


# hadoop data dirs
['tmp', 'namenode', 'datanode'].each do |d|
    directory '/hadoop/'+d do
        owner 'hadoop'
        group 'hadoop'
        mode '0750'
        recursive true
    end
end


# Hadoop and Spark install files
directory '/opt/' do
    owner 'hadoop'
    group 'hadoop'
    mode '0755'
end
execute 'copy_install_files' do
    # If we can get the files from master, then do it.
    command "rsync -a hadoop@master.local:/opt/#{HADOOP_TARFILE} hadoop@master.local:/opt/#{SPARK_TARFILE} /opt/ || true"
    user 'hadoop'
    not_if "test -f /opt/#{HADOOP_TARFILE} -a -f /opt/#{SPARK_TARFILE}"
end
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


# hadoop tools
package ['openjdk-8-jre', 'openjdk-8-jdk', 'python', 'python3']

execute 'untar hadoop' do
    command "tar zxf /opt/#{HADOOP_TARFILE}"
    cwd "/opt/"
    creates "#{HADOOP_INSTALL}/bin/hadoop"
end
execute 'owner hadoop' do
    command "chown hadoop -R #{HADOOP_INSTALL}"
    not_if "stat -c %U #{HADOOP_INSTALL}/bin/hadoop | grep -q hadoop"
end
link '/opt/hadoop' do
    to HADOOP_INSTALL
end

execute 'untar spark' do
    command "tar zxf /opt/#{SPARK_TARFILE}"
    cwd "/opt/"
    creates "#{SPARK_INSTALL}/bin/spark-submit"
end
execute 'owner spark' do
    command "chown hadoop -R #{SPARK_INSTALL}"
    not_if "stat -c %U #{SPARK_INSTALL}/bin/spark-submit | grep -q hadoop"
end
link '/opt/spark' do
    to SPARK_INSTALL
end


# hadoop config
workers_content = (1..num_workers).map { |i| "hadoop#{i}.local" }.join("\n")
template_vars = {
    num_workers: num_workers,
    cores_per_node: cores_per_node,
    total_cores: num_workers*cores_per_node,
    memory_per_node: memory_per_node,
	hdfs_replication: hdfs_replication,
    spark_install: SPARK_INSTALL,
    username: username,
}
file "#{HADOOP_INSTALL}/etc/hadoop/workers" do
    content workers_content
    owner 'hadoop'
end
['core-site.xml', 'hdfs-site.xml', 'yarn-site.xml', 'mapred-site.xml'].each do |f|
    template "#{HADOOP_INSTALL}/etc/hadoop/#{f}" do
        mode '0644'
        owner 'hadoop'
        variables(template_vars)
    end
end
replace_or_add "hadoop JAVA_HOME" do
    path "#{HADOOP_INSTALL}/etc/hadoop/hadoop-env.sh"
    pattern /export JAVA_HOME=.*/
    line "export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')"
end
replace_or_add "hadoop HADOOP_HEAPSIZE" do
    path "#{HADOOP_INSTALL}/etc/hadoop/hadoop-env.sh"
    pattern /#?export HADOOP_HEAPSIZE=.*/
    line "export HADOOP_HEAPSIZE=256"
end
template "#{SPARK_INSTALL}/conf/spark-defaults.conf" do
    mode '0644'
    owner 'hadoop'
    variables(template_vars)
end
template "/etc/profile.d/cluster-environment.sh" do
    mode '0755'
    variables(template_vars)
end
package ['make', 'unzip']
template user_home + '/Makefile' do
    mode '0755'
    owner username
    variables(template_vars)
end

# scripts
directory user_home+'/bin' do
    owner username
    mode '0755'
end
['start-all.sh', 'stop-all.sh', 'dfs-format.sh', 'clear-dfs.sh', 'nuke-dfs.sh', 'halt-all.sh', 'exec-all.sh', 'hdfs-balance.sh'].each do |f|
    f_no_ext = f.sub('.sh', '')
    cookbook_file "/home/#{username}/bin/#{f_no_ext}" do
        source f
        owner username
        mode '0755'
    end
end
