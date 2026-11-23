Pod::Spec.new do |s|
  s.name           = 'T3ComposerEditor'
  s.version        = '1.0.0'
  s.summary        = 'Native attributed composer editor for T3 Code mobile.'
  s.description    = 'UIKit-backed rich text composer with atomic skill and file tokens.'
  s.author         = 'T3 Tools'
  s.homepage       = 'https://t3tools.com'
  s.platforms      = {
    :ios => '16.4',
  }
  s.source         = { :path => '.' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  azookey = File.expand_path('../../../../../.t3/azookey-ios', __dir__)
  if File.directory?(azookey)
    require 'digest'
    expected = '0e90cf9d673dc8edfcf13360e340ed537342c918733cc6b62f3b881ce0348dd8'
    actual = Digest::SHA256.file(File.join(azookey, 'Sources/SwiftUtils/Debug.swift')).hexdigest
    abort 'Unverified azooKey debug behavior; run prepare-azookey-ios.sh in a fresh checkout' unless actual == expected
    spm_dependency(
      s, url: azookey, requirement: {}, products: ['KanaKanjiConverterModuleWithDefaultDictionary']
    )
  end
  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end
