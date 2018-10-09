Pod::Spec.new do |s|
  s.name         = "HTTPSpider" # 项目名称
  s.version      = "0.1.0"        # 版本号 与 你仓库的 标签号 对应
  s.license      = { :type => "MIT", :file => "LICENSE" }          # 开源证书
  s.summary      = "Clear HTTP Networking in Swift" # 项目简介

  s.homepage     = "https://github.com/isxq/HTTPSpider" # 仓库的主页
  s.source       = { :git => "https://github.com/isxq/HTTPSpider.git", :tag => "#{s.version}" }#你的仓库地址，不能用SSH地址
  s.source_files = "Source/*.swift" # 你代码的位置
  s.requires_arc = true # 是否启用ARC
  s.platform     = :ios, "9.0" #平台及支持的最低版本
  s.frameworks   = "UIKit", "Foundation" #支持的框架

  # User
  s.author             = { "申小强" => "shen_x_q@163.com" } # 作者信息
  #s.social_media_url   = "http://isxq.github.io" # 个人主页

end
