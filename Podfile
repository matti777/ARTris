platform :ios, '11.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/qvik/qvik-podspecs.git'

def all_pods
    #pod 'QvikSwift', '~> 4.0'
    pod 'QvikSwift', :path => '../qvik-swift-ios/'
    pod 'XCGLogger', '~> 6.0'
    pod 'Toast-Swift', '~> 3'
    pod 'SwiftLint'
end

target 'ARTris' do
  all_pods
end

target 'ARTrisTests' do
  all_pods
end

