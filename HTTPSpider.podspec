Pod::Spec.new do |s|
  s.name         = "HTTPSpider"
  s.version      = "0.2.0"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.summary      = "Clear HTTP Networking in Swift"
  s.homepage     = "https://github.com/isxq/HTTPSpider"
  s.source       = { :git => "https://github.com/isxq/HTTPSpider.git", :tag => s.version }

  swift_version = '4.2'

  s.source_files = "Source/*.swift"
  s.platform = :ios, "9.0"

  s.author             = { "申小强" => "shen_x_q@163.com" }
  s.social_media_url   = "http://isxq.github.io"

end
