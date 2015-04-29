Gem::Specification.new do |s|
  s.name        = 'yellow-sdk'
  s.summary     = 'Yellow SDK'
  s.version     = '0.0.4'
  s.licenses    = ['Apache 2.0']
  s.description = "Yellow SDK. A ruby module to easily integrate with the Yellow bitcoin payments API."
  s.summary     = "Yellow SDK. A ruby module to easily integrate with the Yellow bitcoin payments API."
  s.authors     = ["Eslam A. Hefnawy"]
  s.email       = 'eslam@yellowpay.co'
  s.files       = Dir["{lib}/**/*"] + %w(README.md)
  s.homepage    = 'http://yellowpay.co'
  s.add_runtime_dependency "always_verify_ssl_certificates"
end