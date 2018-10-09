Pod::Spec.new do |s|
  s.name         = "HTTPSpider"
  s.version      = "0.1.1"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.summary      = "Clear HTTP Networking in Swift"
  s.homepage     = "https://github.com/isxq/HTTPSpider"
  s.source       = { :git => "https://github.com/isxq/HTTPSpider.git", :tag => "#{s.version}" }
  s.source_files = "Source/*.swift"
  s.requires_arc = true
  s.platform     = :ios, "9.0"
  s.author             = { "申小强" => "shen_x_q@163.com" }
  s.social_media_url   = "http://isxq.github.io"

end
