source 'https://github.com/CocoaPods/Specs'
platform :ios, '8.0'

project 'RBQFetchedResultsController'
workspace 'RBQFetchedResultsController'

abstract_target 'Shared' do

  pod 'RBQSafeRealmObject'
  pod 'SafeRealmObject'
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
