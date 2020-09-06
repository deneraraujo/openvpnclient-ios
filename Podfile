# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def shared_pods
  use_frameworks!
  pod 'OpenVPNAdapter', :git => 'https://github.com/deneraraujo/OpenVPNAdapter.git'
end

target 'VPNClient' do
  shared_pods
end

target 'TunnelProvider' do
  shared_pods
end