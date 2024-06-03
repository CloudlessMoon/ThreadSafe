Pod::Spec.new do |s|
    s.name                  = "ThreadSafe"
    s.version               = "1.0.4"
    s.summary               = "ThreadSafe"
    s.homepage              = "https://github.com/jiasongs/ThreadSafe"
    s.license               = "MIT"
    s.author                = { "ruanmei" => "jiasong@ruanmei.com" }
    s.source                = { :git => "https://github.com/jiasongs/ThreadSafe.git", :tag => "#{s.version}" }
    s.platform              = :ios, "13.0"
    s.cocoapods_version     = ">= 1.11.0"
    s.swift_versions        = ["5.1"]
    s.static_framework      = true
    s.requires_arc          = true
    s.pod_target_xcconfig   = { 
        'SWIFT_INSTALL_OBJC_HEADER' => 'NO'
    }

    s.default_subspec = "Core"
    s.subspec "Core" do |ss|
        ss.source_files = "Sources/Core/**/*.{swift}"
    end
end
