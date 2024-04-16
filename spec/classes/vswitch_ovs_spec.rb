require 'spec_helper'

describe 'vswitch::ovs' do

  shared_examples_for 'vswitch::ovs' do
    context 'default parameters' do

      it 'contains the ovs class' do
        is_expected.to contain_class('vswitch::ovs')
      end

      it 'clears hw-offload option' do
        is_expected.to contain_vs_config('other_config:hw-offload').with(
          :ensure => 'absent', :restart => true, :wait => true,
        )
      end

      it 'configures disable_emc option to false' do
        is_expected.to contain_vs_config('other_config:emc-insert-inv-prob').with(
          :ensure => 'absent', :wait => false
        )
      end

      it 'clears vlan-limit option' do
        is_expected.to contain_vs_config('other_config:vlan-limit').with(
          :value => nil, :wait => true,
        )
      end

      it 'configures service' do
        is_expected.to contain_service('openvswitch').with(
          :ensure => true,
          :enable => true,
          :name   => platform_params[:ovs_service_name],
          :tag    => 'openvswitch'
        )
      end

      it 'install package' do
        is_expected.to contain_package('openvswitch').with(
          :name   => platform_params[:ovs_package_name],
          :ensure => 'present',
          :before => 'Service[openvswitch]',
          :tag    => 'openvswitch'
        )
      end

      it 'restarts the service when needed' do
        is_expected.to contain_exec('restart openvswitch').with(
          :path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
          :command     => ['systemctl', '-q', 'restart', "#{platform_params[:ovs_service_name]}.service"],
          :refreshonly => true
        )
      end
    end

    context 'custom parameters' do
      let :params do
        {
          :package_ensure    => 'latest',
          :enable_hw_offload => true,
          :disable_emc       => true,
          :vlan_limit        => 2,
        }
      end
      it 'installs correct package' do
        is_expected.to contain_package('openvswitch').with(
          :name   => platform_params[:ovs_package_name],
          :ensure => 'latest',
          :before => 'Service[openvswitch]',
          :tag    => 'openvswitch'
        )
      end
      it 'configures hw-offload option' do
          is_expected.to contain_vs_config('other_config:hw-offload').with(
            :value  => true, :restart => true, :wait => true,
          )
      end
      it 'configures disable_emc option' do
          is_expected.to contain_vs_config('other_config:emc-insert-inv-prob').with(
            :value  => 0, :wait => false,
          )
      end
      it 'configures vlan-limit option' do
          is_expected.to contain_vs_config('other_config:vlan-limit').with(
            :value  => 2, :wait => true,
          )
      end

    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({ :ovs_version => '1.4.2' }))
      end

      let (:platform_params) do
        case facts[:os]['family']
        when 'Debian'
          if facts[:os]['name'] == 'Debian'
            {
              :ovs_package_name  => 'openvswitch-switch',
              :ovs_service_name  => 'openvswitch-switch',
            }
          elsif facts[:os]['name'] == 'Ubuntu'
            {
              :ovs_package_name  => 'openvswitch-switch',
              :ovs_service_name  => 'openvswitch-switch',
            }
          end
        when 'RedHat'
          {
            :ovs_package_name => 'openvswitch',
            :ovs_service_name => 'openvswitch',
          }
        end
      end

      it_behaves_like "vswitch::ovs"
    end
  end

end
