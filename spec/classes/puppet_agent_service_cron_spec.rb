require 'spec_helper'

describe 'puppet::agent::service::cron' do
  on_supported_os.each do |os, os_facts|
    next if only_test_os() and not only_test_os.include?(os)
    next if exclude_test_os() and exclude_test_os.include?(os)
    context "on #{os}" do
      let (:default_facts) do
        os_facts.merge({
          :clientcert     => 'puppetmaster.example.com',
          :concat_basedir => '/nonexistant',
          :fqdn           => 'puppetmaster.example.com',
          :puppetversion  => Puppet.version,
      }) end

      if Puppet.version < '4.0'
        confdir = '/etc/puppet'
        bindir = '/usr/bin'
        additional_facts = {}
      else
        confdir = '/etc/puppetlabs/puppet'
        bindir = '/opt/puppetlabs/bin'
        additional_facts = {:rubysitedir => '/opt/puppetlabs/puppet/lib/ruby/site_ruby/2.1.0'}
      end

      if os_facts[:osfamily] == 'FreeBSD'
        bindir = '/usr/local/bin'
        confdir = '/usr/local/etc/puppet'
      end

      let :facts do
        default_facts.merge(additional_facts)
      end

      describe 'when runmode is not cron' do
        let :pre_condition do
          "class {'puppet': agent => true}"
        end

        it { should contain_cron('puppet').with_ensure('absent') }
      end

      describe 'when runmode => cron' do
        let :pre_condition do
          "class {'puppet': agent => true, runmode => 'cron'}"
        end

        it do
          should contain_cron('puppet').with({
            :command  => "#{bindir}/puppet agent --config #{confdir}/puppet.conf --onetime --no-daemonize",
            :user     => 'root',
            :minute   => ['15','45'],
            :hour     => '*',
          })
        end
      end
    end
  end
end
