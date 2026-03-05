Workspace configuration | API Reference | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsCommands overviewCommands availableSelectorsWorkspace configurationPowered by GitBookOn this pageAskWorkspace configurationReference for all config.yaml properties: appId, flows, env, and platform settings.This page provides a technical reference for all properties you can set in the config.yaml file. The configuration is structured into Global, Execution, Platform-specific, and Cloud sections.Global workspace settingsThese settings define the identity of your application and how Maestro discovers your Flow files.KeyDescriptionappIdRequired. The unique identifier for your app. Use the Bundle ID for iOS, Package Name for Android, or the starting URL for Web.flowsGlob patterns defining which files to include in a test suite. Defaults to * (only YAML files in the root folder). Use ** for recursive discovery.envGlobal key-value pairs accessible as variables (e.g., ${MY_VAR}) within your Flows.testOutputDirCustom directory where screenshots, logs, and metadata are saved. Defaults to ~/.maestro/tests/.Execution and filteringUse these keys to control the order and selection of tests during a suite run.KeyDescriptionincludeTagsOnly executes Flows that contain at least one of these tags in their internal configuration.excludeTagsSkips any Flows that contain one or more of these tags.executionOrder(Local-only). A nested object used to force a specific sequence of Flows. This property does not apply to Maestro Cloud.executionOrder.continueOnFailureIf false, Maestro stops the sequential execution immediately if a Flow fails. Default is true.executionOrder.flowsOrderThe ordered list of Flow names or filenames (without .yaml) to execute sequentially.Platform configurationPlatform-specific settings allow you to optimize the environment for Android or iOS.Key (iOS specifics)DescriptiondisableAnimations(Cloud only) Enables Reduce Motion on the iOS Simulator to prevent flakiness caused by system-level animations.snapshotKeyHonorModalViewsYou can use this key when running tests locally or on the cloud.If false, Maestro includes elements from the background hierarchy even when a modal is present. Useful for certain custom UI frameworks. This helps capture elements that have absolute positioning into the hierarchy.Key (Android specifics)DescriptiondisableAnimations(Cloud only) Disables system-level window, transition, and animator animations on the Android Emulator.Maestro cloud configurationThese properties are used only when running tests on Maestro Cloud.KeyDescriptionbaselineBranchDefines the source-of-truth branch (e.g., main) for PR comparisons.disableAnimations(Cloud-only). Disables system-level animations to prevent flakiness. 

This only affects system-level animations. Custom animations like those powered by Lottie won't be disabled.notificationsConfigures automated alerts upon test completion.notifications.email.enabledSet to true to enable email notifications.notifications.email.recipientsA list of email addresses to receive the test reports.notifications.slack.endpointThe Webhook URL for posting results directly to a Slack channel.Usage exampleThe following example shows a typical Maestro workspace configuration file. This file must be named config.yaml. You can place it at the root of your project or in the .maestro directory:PreviousDimension matchersLast updated 10 days agoGlobal workspace settingsUsage exampleCopy# config.yaml
flows:
  - 'subFolder/*'
  - 'anotherSubfolder/**'
includeTags:
  - tagNameToInclude
excludeTags:
  - tagNameToExclude
executionOrder:
  continueOnFailure: false # default is true
  flowsOrder:
    - flowA
    - flowB

# Customised test output directory
testOutputDir: test_output_directory

# Cloud only config options
baselineBranch: main
notifications:
  email:
    enabled: true
    recipients:
      - [email protected]

# Platform Configuration
platform:
  ios:
    snapshotKeyHonorModalViews: false
    disableAnimations: true
  android:
    disableAnimations: true
