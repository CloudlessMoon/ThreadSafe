Pod::Spec.new do |s|
    s.name                  = "ThreadSafe"
    s.version               = "1.2.6"
    s.summary               = "ThreadSafe"
    s.homepage              = "https://github.com/CloudlessMoon/ThreadSafe"
    s.license               = "MIT"
    s.author                = "CloudlessMoon"
    s.source                = { :git => "https://github.com/CloudlessMoon/ThreadSafe.git", :tag => "#{s.version}" }
    s.platform              = :ios, "13.0"
    s.swift_versions        = ["5.1"]
    s.requires_arc          = true

    s.default_subspec = "Core"
    s.subspec "Core" do |ss|
        ss.source_files = "Sources/Core/**/*.{swift}"
    end
end
