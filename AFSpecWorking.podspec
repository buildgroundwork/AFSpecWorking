Pod::Spec.new do |s|
  s.name     = 'AFSpecWorking'
  s.version  = '0.1'
  s.license  = 'MIT'
  s.summary  = 'A delightful collection of helpers for testing network calls'
  s.homepage = 'https://github.com/orchardpie/AFSpecWorking'
  s.social_media_url = 'https://www.orchardpie.com'
  s.authors  = { 'Adam Milligan' => 'adam@orchardpie.com' }
  s.source   = { git: 'https://github.com/orchardpie/AFSpecWorking.git' }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'

  s.public_header_files = 'SpecHelpers/*.h'
  s.source_files = 'SpecHelpers/*.{h,m}'
end

