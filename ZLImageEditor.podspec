Pod::Spec.new do |s|
  s.name                  = 'ZLImageEditor'
  s.version               = '3.0.6'
  s.summary               = 'A powerful image editor framework. Supports graffiti, cropping, mosaic, text stickers, picture stickers, filters, adjust.'

  s.homepage              = 'https://github.com/virtualspirit/ZLImageEditor'
  s.license               = { :type => "MIT", :file => "LICENSE" }

  s.author                = {'virtualspirit' => 'virtualspirit@virtualspirit.me'}
  s.source                = {:git => 'https://github.com/virtualspirit/ZLImageEditor.git', :tag => s.version}

  s.ios.deployment_target = '10.0'

  s.swift_versions        = ['5.0', '5.1', '5.2']

  s.requires_arc          = true
  s.frameworks            = 'UIKit', 'Accelerate'

  s.resources             = 'Sources/*.{png,bundle}'
  
  s.dependency 'SDWebImage'

  s.subspec "Core" do |sp|
    sp.source_files       = ["Sources/**/*.{swift,h,m}", "Sources/ZLImageEditor.h"]
    sp.exclude_files      = ["Sources/General/ZLWeakProxy.swift"]
  end

end
