Pod::Spec.new do |s|
  s.name         = "RBQFetchedResultsController"
  s.version      = "5.0.0"
  s.summary      = "Drop-in replacement for NSFetchedResultsController backed by Realm."
  s.description  = <<-DESC
                    The RBQFetchedResultsController (FRC) is a replacement for NSFetchedResultsController when used in conjunction with RBQRealmNotificationManager and RBQRealmChangeLogger. The controller and delegate follow the same paradigm as NSFetchedResultsController, and allow the developer to monitor changes of an RLMObject subclass.

                    RBQFetchedResultsController supports tableview sections and implements a drop-in replacement delegate to pass the changes to the tableview for section and row animations.
                   DESC

  s.homepage     = "http://github.com/Roobiq/RBQFetchedResultsController"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Roobiq" => "support@roobiq.com" }
  s.social_media_url   = "http://twitter.com/Roobiq"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/Roobiq/RBQFetchedResultsController.git", :tag => "v#{s.version}", :submodules => true }
  s.source_files  = [
    "RBQFetchedResultsController/Source/**/*.{h,m}",
    "RBQFetchedResultsController/RBQFRC.h"
  ]
  s.exclude_files = "RBQFetchedResultsController/Source/Swift/*"
  s.requires_arc = true
  s.dependency "Realm", ">=1.0.0"
  s.dependency "RBQSafeRealmObject"
  s.dependency "RealmUtilities"
end
