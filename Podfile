source 'https://github.com/CocoaPods/Specs'

project 'RBQFetchedResultsController'
workspace 'RBQFetchedResultsController'
platform :ios, '8.0'

abstract_target 'Shared' do

  pod 'RBQSafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'SafeRealmObject', path: '../RBQSafeRealmObject'
  pod 'RealmUtilities'

  target 'RBQFetchedResultsController' do
    use_frameworks!

    target 'RBQFetchedResultsControllerTests' do
      inherit! :search_paths
    end
  end

  target 'SwiftFetchedResultsController' do
    use_frameworks!
  end

end
