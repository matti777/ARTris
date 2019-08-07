platform :ios, '11.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/qvik/qvik-podspecs.git'

def all_pods
    pod 'QvikSwift', '~> 6'
    #pod 'QvikSwift', :path => '../qvik-swift-ios/'
    pod 'XCGLogger', '~> 7'
    pod 'Toast-Swift', '~> 5'
    pod 'SwiftLint'
end

target 'ARTris' do
  all_pods
end

target 'ARTrisTests' do
    all_pods
end

