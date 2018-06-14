

Pod::Spec.new do |s|
  s.name         = "UPlatform"
  s.version      = "1.0.0"
  s.summary      = "A short description of UPlatform."
  s.homepage     = "https://github.com/TintGit/UPlatform"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "醒来－技术" => "1020166296@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/TintGit/UPlatform.git", :tag => "#{s.version}" }
  s.source_files  = "UPlatform/Core/*.swift","UPlatform/Framework/*.h"
  s.resources    = ['UPlatform/Framework/*.{bundle}']
  s.requires_arc = true
  s.dependency "Spec"

end
