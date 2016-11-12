source 'https://github.com/CocoaPods/Specs'

project 'RBQFetchedResultsController'
workspace 'RBQFetchedResultsController'
platform :ios, '8.0'

def shared_pods
  pod 'RBQSafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'SafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'RealmUtilities'
end

target 'RBQFetchedResultsController' do
  use_frameworks!
  shared_pods

  target 'RBQFetchedResultsControllerTests' do
    inherit! :search_paths
  end
end

target 'SwiftFetchedResultsController' do
  use_frameworks!
  shared_pods

  pod 'RBQSafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'SafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'RealmUtilities'
end
