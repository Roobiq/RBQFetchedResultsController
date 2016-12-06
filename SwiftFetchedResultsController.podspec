Pod::Spec.new do |s|
  s.name         = "SwiftFetchedResultsController"
  s.version      = "5.0.0"
  s.summary      = "Swift drop-in replacement for NSFetchedResultsController backed by Realm"
  s.description  = <<-DESC
                    The FetchedResultsController (FRC) is a Swift replacement for NSFetchedResultsController when used in conjunction with the ChangeLogger class. The controller and delegate follow the same paradigm as NSFetchedResultsController, and allow the developer to monitor changes of a Realm Swift Object subclass.

                    FetchedResultsController supports tableview sections and implements a drop-in replacement delegate to pass the changes to the tableview for section and row animations.
                   DESC

  s.homepage     = "http://github.com/Roobiq/RBQFetchedResultsController"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Roobiq" => "support@roobiq.com" }
  s.social_media_url   = "http://twitter.com/Roobiq"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Roobiq/RBQFetchedResultsController.git", :tag => "v#{s.version}", :submodules => true }
  s.source_files  = [
    "RBQFetchedResultsController/Source/Swift/*.{h,swift}",
    "RBQFetchedResultsController/Source/RBQSafeRealmObject/*.{swift}"
  ]
  s.requires_arc = true
  s.dependency "RealmSwift", ">=1.0.0"
  s.dependency "RBQFetchedResultsController", ">=#{s.version}"
  s.dependency "SafeRealmObject"
end
