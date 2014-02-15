require 'puppet'
Puppet::Type.type(:rabbitmq_queue).provide(:rabbitmqadmin) do

  commands :rabbitmqadmin => '/usr/local/bin/rabbitmqadmin'
  defaultfor :feature => :posix

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@')[1]
    end
  end

  def self.instances
    resources = []
    rabbitmqadmin('list', 'queues').split(/\n/)[3..-2].collect do |line|
      if line =~ /^\|\s+(\S+)\s+\|\s+(\S+)\s+\|(\s+([^|]+)\s+\|){12}$/
        entry = {
          :ensure => :present,
          :name   => "%s@%s" % [$2, $1]
        }
        resources << new(entry)
      else
        raise Puppet::Error, "Cannot parse invalid queue line: #{line}"
      end
    end
    resources
  end


  def self.prefetch(resources)
    packages = instances
    resources.keys.each do |name|
      if provider = packages.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    rabbitmqadmin('declare', 'queue', vhost_opt, "name=#{name}")
    @property_hash[:ensure] = :present
  end

  def destroy
    vhost_opt = should_vhost ? "--vhost=#{should_vhost}" : ''
    name = resource[:name].split('@')[0]
    rabbitmqadmin('delete', 'exchange', vhost_opt, "name=#{name}")
    @property_hash[:ensure] = :absent
  end

end