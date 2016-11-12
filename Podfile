source 'https://github.com/CocoaPods/Specs'

project 'RBQFetchedResultsController'
workspace 'RBQFetchedResultsController'
platform :ios, '8.0'

target 'RBQFetchedResultsController' do
  use_frameworks!

  pod 'RBQSafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'SafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'RealmUtilities'

  target 'RBQFetchedResultsControllerTests' do
    inherit! :search_paths
  end
end

target 'SwiftFetchedResultsController' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'RBQSafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'SafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'RealmUtilities'
end
