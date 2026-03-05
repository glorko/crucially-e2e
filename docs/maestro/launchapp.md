launchApp | API Reference | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsCommands overviewCommands availableaddMediaassertNoDefectsWithAIassertNotVisibleassertScreenshotassertTrueassertVisibleassertWithAIbackclearKeychainclearStatecopyTextFromdoubleTapOneraseTextevalScriptextendedWaitUntilextractTextWithAIhideKeyboardinputTextkillApplaunchApplongPressOnopenLinkpasteTextpressKeyrepeatretryrunFlowrunScriptscrollscrollUntilVisiblesetAirplaneModesetClipboardsetLocationsetOrientationsetPermissionsstartRecordingstopAppstopRecordingswipetakeScreenshottapOntoggleAirplaneModetravelwaitForAnimationToEndSelectorsWorkspace configurationPowered by GitBookOn this pageAskCommands availablelaunchAppLaunch an app with optional permission configuration and clear state.Launches an application on the target device (Android, iOS, or Web). By default, this command stops the running app before launching it again.ParametersThe launchApp command accepts the following parameters in a map:ParameterDescriptionappIdOptional. The package name (Android) or bundle ID (iOS) of the app to launch. If not specified, Maestro launches the app under test using the appId defined at the top of the YAML file.clearStateOptional. If true, clears the app's state before launch.clearKeychainOptional. If true, clears the entire iOS Keychain.stopAppOptional. If false, the command brings a backgrounded app to the foreground without restarting it. Defaults to true.permissionsOptional. A map of permissions to grant, deny, or unset. By default, all permissions are allowed.argumentsOptional. A map of key-value pairs to pass as launch arguments to the app. Supports string, boolean, double, and integer values.Usage examplesLaunch an appTo launch the app under test:Copy- launchAppTo launch a different app by its ID:Copy- launchApp: com.example.appWhen testing web applications, using launchApp redirects the test to the website defined at the top of the Flow. In the following example, after navigating through the Maestro documentation, launchApp is used to return to the documentation homepage:Copyurl: https://docs.maestro.dev/
---
- launchApp
- openLink:
    link: https://maestro.dev/cloud
- tapOn:
    text: Start Your Free Trial
    index: 2
- launchAppLaunch with a clean stateTo clear all app data before launch use clearState: true:Manage a running appTo bring a backgrounded app to the foreground without restarting it:To restart an already running app, run launchApp without parameters, as stopApp defaults to true:Set permissions on launchTo deny all permissions:To set specific permissions, add each one independently:Pass launch argumentsThis example passes arguments of various types to the application on launch.Receiving launch argumentsThe following examples show how to receive the arguments passed with the launchApp command in your application code.AndroidiOSReact NativeFlutterRelated contentLearn how to use permissions on iOS and Android apps on flows.PreviouskillAppNextlongPressOnLast updated 10 days agoParametersUsage examplesReceiving launch argumentsRelated contentCopy- launchApp:
    appId: "com.example.app"
    clearState: true
    clearKeychain: true # OptionalCopy- launchApp:
    stopApp: falseCopy- launchAppCopy- launchApp:
    permissions: 
      all: denyCopy- launchApp:
    permissions:
        notifications: unset
        android.permission.ACCESS_FINE_LOCATION: denyCopy- launchApp:
    appId: "com.example.app"
    arguments: 
       foo: "This is a string"
       isFooEnabled: false
       fooValue: 3.24
       fooInt: 3Copyintent.extras?.getBoolean("isFooEnabled")?.let {
    // Do something with isFooEnabled
}

intent.extras?.getString("foo")?.let {
    // Do something with foo
}Copyif ProcessInfo.processInfo.arguments.contains("isFooEnabled") {
    // Do something with isFooEnabled
}

// By default all the values received here would be string
let standardDefaultsDict = UserDefaults.standard.dictionaryRepresentation()
let foo = (standardDefaultsDict["foo"] as? String) ?? "defaultValue"Copyimport { LaunchArguments } from 'react-native-launch-arguments'

export const isFooEnabled = () => {
  try {
    const foo = LaunchArguments.value().isFooEnabled
    return !!foo
  } catch (e) {
    return false
  }
}Copyimport 'package:flutter_launch_arguments/flutter_launch_arguments.dart';

Future<void> getArguments() async {
  final fla = FlutterLaunchArguments();

  final foo = await fla.getString('foo');
  final isFooEnabled = await fla.getBool('isFooEnabled');
  final fooValue = await fla.getDouble('fooValue');
  final fooInt = await fla.getInt('fooInt');
}
